import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:carbon_counter/services/api_service.dart';
import 'package:carbon_counter/models/carbon_stats.dart';
import 'package:carbon_counter/widgets/status_indicator.dart';
import 'package:carbon_counter/widgets/data_chips.dart';
import 'package:carbon_counter/widgets/stats_table.dart';
import 'package:carbon_counter/utils/constants.dart';

class CarbonDataScreen extends StatefulWidget {
  const CarbonDataScreen({super.key});

  @override
  State<CarbonDataScreen> createState() => _CarbonDataScreenState();
}

class _CarbonDataScreenState extends State<CarbonDataScreen> {
  late ApiService _apiService;
  Timer? _timer;
  List<CarbonData> _data = [];
  String _dataStatus = "Reading Data...";
  DateTime? _lastFetchTime;

  DailyStats? _dailyStats;
  WeeklyStats? _weeklyStats;
  MonthlyStats? _monthlyStats;

  bool _isLoading = true; // loading state

  @override
  void initState() {
    super.initState();
    // ensure dotenv is loaded
    final scriptUrl = dotenv.env['APPS_SCRIPT_URL'];
    if (scriptUrl == null || scriptUrl.isEmpty) {
      // handle missing URL error more gracefully
      print("ERROR: APPS_SCRIPT_URL not found in .env file.");
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showErrorDialog(
          "Configuration Error",
          "APPS_SCRIPT_URL is not set in the .env file. Please configure it and restart the app.",
        );
      });
      setState(() {
        _isLoading = false;
        _dataStatus = "Configuration Error";
      });
      return; // Stop initialization if URL is missing
    }
    _apiService = ApiService(scriptUrl);

    _fetchDataAndStats(); // Initial fetch
    _startTimer(); // Start the periodic timer
  }

  void _startTimer() {
    _timer = Timer.periodic(AppConstants.fetchInterval, (timer) {
      // Only fetch if the widget is still mounted
      if (mounted) {
        _fetchDataAndStats();
        _updateDataStatus();
      } else {
        timer.cancel(); // Cancel timer if widget is disposed
      }
    });
  }

  Future<void> _fetchDataAndStats() async {
    // Prevent concurrent fetches if one is already in progress (optional but good)
    // if (_isLoading && _data.isEmpty) return;

    if (mounted) {
      setState(() {
        // Optionally show loading indicator during refresh
        // _isLoading = _data.isEmpty;
      });
    }

    try {
      final data = await _apiService.getCarbonData();
      if (!mounted) return; // Check again after await

      final now = DateTime.now();
      _lastFetchTime = now; // Update last fetch time on success

      DailyStats? daily;
      WeeklyStats? weekly;
      MonthlyStats? monthly;

      if (data.isNotEmpty) {
        // Perform calculations (consider doing this in an isolate for large data)
        daily = _apiService.calculateDailyStats(data);
        weekly = _apiService.calculateWeeklyStats(data);
        monthly = _apiService.calculateMonthlyStats(data);
      }

      setState(() {
        _data = data;
        _dailyStats = daily;
        _weeklyStats = weekly;
        _monthlyStats = monthly;
        _isLoading = false; // Data loaded or fetch completed
      });
      _updateDataStatus(); // Update status based on new fetch time
    } catch (e) {
      print("Error fetching data and stats: $e");
      if (!mounted) return;
      setState(() {
        _dataStatus = "Not Reading Data";
        _isLoading = false; // Fetch failed
      });
      // Optionally show an error message to the user
      // _showErrorSnackbar("Failed to fetch data. Please check connection.");
    }
  }

  void _updateDataStatus() {
    if (!mounted) return;

    if (_lastFetchTime == null) {
      // If still no data after initial load attempt
      if (!_isLoading) {
        setState(() {
          _dataStatus = "Not Reading Data";
        });
      } else {
        setState(() {
          _dataStatus = "Reading Data...";
        });
      }
    } else {
      final timeSinceLastFetch = DateTime.now().difference(_lastFetchTime!);
      if (timeSinceLastFetch < AppConstants.dataStaleThreshold) {
        setState(() {
          _dataStatus = "Reading Live Data";
        });
      } else {
        setState(() {
          // If we have old data, show historic, otherwise show not reading
          _dataStatus =
              _data.isNotEmpty ? "Using Historic Data" : "Not Reading Data";
        });
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel(); // Cancel the timer safely
    super.dispose();
  }

  void _showErrorDialog(String title, String content) {
    showDialog(
      context: context,
      barrierDismissible: false, // User must acknowledge the error
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: <Widget>[
            TextButton(
              child: const Text("OK"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showErrorSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FlutterLogo(size: 30), // placeholder app logo
            SizedBox(width: 8), // spacing between logo and title
            Text('Carbon शोधक'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed:
                _isLoading ? null : _fetchDataAndStats, // Disable while loading
            tooltip: 'Refresh Data',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _openSettings(context),
            tooltip: 'Settings',
          ),
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () => _openHelp(context),
            tooltip: 'Help',
          ),
        ],
      ),
      body:
          _isLoading &&
                  _data
                      .isEmpty // Show loader only on initial load
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                // Add pull-to-refresh
                onRefresh: _fetchDataAndStats,
                child: SingleChildScrollView(
                  physics:
                      const AlwaysScrollableScrollPhysics(), // Enable scroll even when content fits
                  child: Padding(
                    padding: const EdgeInsets.all(AppConstants.screenPadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        StatusIndicator(status: _dataStatus),
                        const SizedBox(height: AppConstants.sectionSpacing),
                        Center(
                          child: DataChips(
                            data: _data.isNotEmpty ? _data.last : null,
                          ),
                        ),
                        const SizedBox(height: AppConstants.sectionSpacing * 2),
                        Text(
                          "Historical Data Statistics",
                          style: Theme.of(context).textTheme.titleMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppConstants.sectionSpacing / 2),
                        // Use the dedicated StatsTable widget
                        StatsTable(
                          dailyStats: _dailyStats,
                          weeklyStats: _weeklyStats,
                          monthlyStats: _monthlyStats,
                        ),
                        const SizedBox(
                          height: AppConstants.sectionSpacing,
                        ), // Add some bottom padding
                      ],
                    ),
                  ),
                ),
              ),
      bottomNavigationBar: BottomAppBar(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            'Copyright © ${DateTime.now().year} Carbon शोधक App', // Dynamic year
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ),
      ),
    );
  }

  // --- Dialog Methods --- (Keep them here or move to a separate dialogs utility file)

  void _openSettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Settings"),
          content: const Text("Settings options will be implemented here."),
          actions: <Widget>[
            TextButton(
              child: const Text("Close"),
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
          title: const Text("Help & Information"),
          content: const SingleChildScrollView(
            // Make content scrollable if long
            child: Text(
              "This app monitors carbon data (CO & CO2) from MQ-7 and MQ-135 sensors.\n\n"
              "Data Status:\n"
              "🟢 Reading Live Data: App is actively receiving recent data.\n"
              "🟠 Using Historic Data: Displaying older data; connection might be slow or intermittent.\n"
              "🔴 Not Reading Data: Failed to fetch data. Check network or sensor status.\n"
              "⚪ Reading Data...: Initial data load in progress.\n\n"
              "Tap the refresh icon (🔄) or pull down to manually update data.\n\n"
              "Built by Harsh Soni with 💖",
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text("Close"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
