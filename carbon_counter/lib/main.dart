import 'dart:async';
import 'package:flutter/material.dart';
import 'package:carbon_counter/api_service.dart';
import 'package:carbon_counter/data_model.dart';
import 'package:carbon_counter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'splash_screen.dart'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Carbon Data App',
      theme: ThemeData(primarySwatch: Colors.blue),
      // home: CarbonDataScreen(), // without splash screen
      home: SplashScreen(),
    );
  }
}

class CarbonDataScreen extends StatefulWidget {
  const CarbonDataScreen({super.key});

  @override
  _CarbonDataScreenState createState() => _CarbonDataScreenState();
}

class _CarbonDataScreenState extends State<CarbonDataScreen> {
  late ApiService _apiService;
  late Timer _timer;
  List<CarbonData> _data = [];
  String _dataStatus = "Reading Data...";
  DateTime? _lastFetchTime;
  static const Duration _dataStaleThreshold = Duration(seconds: 15);
  static const Duration _fetchInterval = Duration(seconds: 5);

  DailyStats? _dailyStats;
  WeeklyStats? _weeklyStats;
  MonthlyStats? _monthlyStats;

  @override
  void initState() {
    super.initState();
    _apiService = ApiService(dotenv.env['APPS_SCRIPT_URL']!);

    _fetchDataAndStats();
    _timer = Timer.periodic(_fetchInterval, (timer) {
      _fetchDataAndStats();
      _updateDataStatus();
    });
  }

  Future<void> _fetchDataAndStats() async {
    try {
      final data = await _apiService.getCarbonData();
      setState(() {
        _data = data;
        _lastFetchTime = DateTime.now();
      });
      _updateDataStatus();

      if (_data.isNotEmpty) {
        final daily = _apiService.calculateDailyStats(_data);
        final weekly = _apiService.calculateWeeklyStats(_data);
        final monthly = _apiService.calculateMonthlyStats(_data);

        setState(() {
          _dailyStats = daily;
          _weeklyStats = weekly;
          _monthlyStats = monthly;
        });
      }
    } catch (e) {
      setState(() {
        _dataStatus = "Not Reading Data";
      });
      print("Error fetching data and stats: $e");
    }
  }

  void _updateDataStatus() {
    if (_lastFetchTime == null) {
      setState(() {
        _dataStatus = "Reading Data...";
      });
    } else {
      final timeSinceLastFetch = DateTime.now().difference(_lastFetchTime!);
      if (timeSinceLastFetch < _dataStaleThreshold) {
        setState(() {
          _dataStatus = "Reading Live Data";
        });
      } else {
        setState(() {
          _dataStatus = "Using Historic Data";
        });
      }
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FlutterLogo(
              size: 30,
            ), // placeholder app logo
            SizedBox(
              width: 8,
            ), // spacing between logo and title
            Text('Carbon शोधक'),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _fetchDataAndStats,
            tooltip: 'Refresh Data',
          ),
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              _openSettings(context);
            },
            tooltip: 'Settings',
          ),
          IconButton(
            icon: Icon(Icons.help_outline),
            onPressed: () {
              _openHelp(context);
            },
            tooltip: 'Help',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            StatusIndicator(status: _dataStatus),
            // Padding(
            //   padding: const EdgeInsets.all(8.0),
            //   child: Text(
            //     "Data from the Sheet",
            //     style: Theme.of(context).textTheme.titleMedium,
            //     textAlign: TextAlign.center,
            //   ),
            // ),
            Center(
              child:
                  _data.isEmpty
                      ? CircularProgressIndicator()
                      : DataChips(data: _data.isNotEmpty ? _data.last : null),
            ),
            SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                "Historical Data Statistics",
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
            ),
            _buildStatsTable(),
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            'Copyright © 2024 Carbon Data App',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ),
      ),
    );
  }

  void _openSettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Settings"),
          content: Text("Settings options will be implemented here."),
          actions: <Widget>[
            TextButton(
              child: Text("Close"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _openHelp(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Help & Information"),
          content: Text(
            "This app monitors carbon data from MQ-7 and MQ-135 sensors. Data is fetched from a Google Sheet. \n\n - 'Reading Live Data': App is actively receiving data.\n - 'Using Historic Data': Data might be slightly delayed.\n - 'Not Reading Data':  Data fetching is currently failing.\n\nTap 'Refresh' to manually update data. \n\n Built by Harsh Soni with 💖",
          ),
          actions: <Widget>[
            TextButton(
              child: Text("Close"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatsTable() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          _buildDataTable(title: "Daily Statistics", stats: _dailyStats),
          SizedBox(height: 16),
          _buildDataTable(title: "Weekly Statistics", stats: _weeklyStats),
          SizedBox(height: 16),
          _buildDataTable(title: "Monthly Statistics", stats: _monthlyStats),
        ],
      ),
    );
  }

  Widget _buildDataTable({required String title, dynamic stats}) {
    if (stats == null) {
      return Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            "$title: No data available yet.",
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (stats is DailyStats) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Text(title, style: Theme.of(context).textTheme.titleSmall),
              DataTable(
                columns: const [
                  DataColumn(label: Text('Metric')),
                  DataColumn(label: Text('MQ7')),
                  DataColumn(label: Text('MQ135')),
                ],
                rows: [
                  DataRow(
                    cells: [
                      DataCell(Text('Date')),
                      DataCell(
                        Text(DateFormat('yyyy-MM-dd').format(stats.date)),
                      ),
                      DataCell(
                        Text(DateFormat('yyyy-MM-dd').format(stats.date)),
                      ),
                    ],
                  ),
                  DataRow(
                    cells: [
                      DataCell(Text('Average')),
                      DataCell(Text(stats.avgMq7.toStringAsFixed(2))),
                      DataCell(Text(stats.avgMq135.toStringAsFixed(2))),
                    ],
                  ),
                  DataRow(
                    cells: [
                      DataCell(Text('Maximum')),
                      DataCell(Text(stats.maxMq7.toStringAsFixed(2))),
                      DataCell(Text(stats.maxMq135.toStringAsFixed(2))),
                    ],
                  ),
                  DataRow(
                    cells: [
                      DataCell(Text('Minimum')),
                      DataCell(Text(stats.minMq7.toStringAsFixed(2))),
                      DataCell(Text(stats.minMq135.toStringAsFixed(2))),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    } else if (stats is WeeklyStats) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Text(title, style: Theme.of(context).textTheme.titleSmall),
              DataTable(
                columns: const [
                  DataColumn(label: Text('Metric')),
                  DataColumn(label: Text('MQ7')),
                  DataColumn(label: Text('MQ135')),
                ],
                rows: [
                  DataRow(
                    cells: [
                      DataCell(Text('Week')),
                      DataCell(
                        Text(
                          '${DateFormat('yyyy-MM-dd').format(stats.startDate)} - ${DateFormat('yyyy-MM-dd').format(stats.endDate)}',
                        ),
                      ),
                      DataCell(
                        Text(
                          '${DateFormat('yyyy-MM-dd').format(stats.startDate)} - ${DateFormat('yyyy-MM-dd').format(stats.endDate)}',
                        ),
                      ),
                    ],
                  ),
                  DataRow(
                    cells: [
                      DataCell(Text('Average')),
                      DataCell(Text(stats.avgMq7.toStringAsFixed(2))),
                      DataCell(Text(stats.avgMq135.toStringAsFixed(2))),
                    ],
                  ),
                  DataRow(
                    cells: [
                      DataCell(Text('Maximum')),
                      DataCell(Text(stats.maxMq7.toStringAsFixed(2))),
                      DataCell(Text(stats.maxMq135.toStringAsFixed(2))),
                    ],
                  ),
                  DataRow(
                    cells: [
                      DataCell(Text('Minimum')),
                      DataCell(Text(stats.minMq7.toStringAsFixed(2))),
                      DataCell(Text(stats.minMq135.toStringAsFixed(2))),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    } else if (stats is MonthlyStats) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Text(title, style: Theme.of(context).textTheme.titleSmall),
              DataTable(
                columns: const [
                  DataColumn(label: Text('Metric')),
                  DataColumn(label: Text('MQ7')),
                  DataColumn(label: Text('MQ135')),
                ],
                rows: [
                  DataRow(
                    cells: [
                      DataCell(Text('Month')),
                      DataCell(
                        Text(DateFormat('yyyy-MM').format(stats.monthDate)),
                      ),
                      DataCell(
                        Text(DateFormat('yyyy-MM').format(stats.monthDate)),
                      ),
                    ],
                  ),
                  DataRow(
                    cells: [
                      DataCell(Text('Average')),
                      DataCell(Text(stats.avgMq7.toStringAsFixed(2))),
                      DataCell(Text(stats.avgMq135.toStringAsFixed(2))),
                    ],
                  ),
                  DataRow(
                    cells: [
                      DataCell(Text('Maximum')),
                      DataCell(Text(stats.maxMq7.toStringAsFixed(2))),
                      DataCell(Text(stats.maxMq135.toStringAsFixed(2))),
                    ],
                  ),
                  DataRow(
                    cells: [
                      DataCell(Text('Minimum')),
                      DataCell(Text(stats.minMq7.toStringAsFixed(2))),
                      DataCell(Text(stats.minMq135.toStringAsFixed(2))),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }
    return Container();
  }
}
