import 'dart:async';
import 'package:flutter/material.dart';
import 'package:carbon_counter/api_service.dart';
import 'package:carbon_counter/data_model.dart';
import 'package:carbon_counter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Carbon Data App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: CarbonDataScreen(),
    );
  }
}

class CarbonDataScreen extends StatefulWidget {
  @override
  _CarbonDataScreenState createState() => _CarbonDataScreenState();
}

class _CarbonDataScreenState extends State<CarbonDataScreen> {
  late ApiService _apiService;
  late Timer _timer;
  CarbonData _latestData = CarbonData(
    time: 'Loading...',
    mq7: 0.0,
    mq135: 0.0,
  ); // initial values
  bool _isReadingData = false;

  @override
  void initState() {
    super.initState();
    _apiService = ApiService(dotenv.env['APPS_SCRIPT_URL']!);

    // fetch data immediately and then periodically
    _fetchData();
    _timer = Timer.periodic(Duration(seconds: 5), (timer) {
      _fetchData();
    });
  }

  Future<void> _fetchData() async {
    try {
      final data = await _apiService.getCarbonData();
      if (data.isNotEmpty) {
        setState(() {
          _latestData = data.last; // get the last entry as the most recent
          _isReadingData = true;
        });
      }
    } catch (e) {
      setState(() {
        _isReadingData = false;
      });
      print("Error fetching data: $e");
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
      appBar: AppBar(title: Text('Carbon Data Monitor')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          StatusIndicator(isReading: _isReadingData),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              alignment: WrapAlignment.center,
              children: [
                DataChip(
                  label: "Time: ${_latestData.time}",
                  color: Colors.lightBlue,
                ),
                DataChip(
                  label: "MQ7: ${_latestData.mq7}",
                  color: Colors.orange,
                ),
                DataChip(
                  label: "MQ135: ${_latestData.mq135}",
                  color: Colors.green,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
