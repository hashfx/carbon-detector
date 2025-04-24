// lib/screens/carbon_data_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Needed for logout

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
  List<CarbonData> _data = []; // This holds the raw data
  String _dataStatus = "Reading Data...";
  DateTime? _lastFetchTime;

  DailyStats? _dailyStats;
  WeeklyStats? _weeklyStats;
  MonthlyStats? _monthlyStats;

  bool _isLoading = true;

  // ... (initState, _startTimer, _fetchDataAndStats, _updateDataStatus, dispose, dialogs - remain largely the same) ...
  @override
  void initState() {
    super.initState();
    final scriptUrl = dotenv.env['APPS_SCRIPT_URL'];
    if (scriptUrl == null || scriptUrl.isEmpty) {
      print("ERROR: APPS_SCRIPT_URL not found in .env file.");
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showErrorDialog("Configuration Error",
            "APPS_SCRIPT_URL is not set. Configure in .env and restart.");
      });
      setState(() {
        _isLoading = false;
        _dataStatus = "Configuration Error";
      });
      return;
    }
    _apiService = ApiService(scriptUrl);
    _fetchDataAndStats();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel(); // Cancel existing timer if any
    _timer = Timer.periodic(AppConstants.fetchInterval, (timer) {
      if (mounted) {
        _fetchDataAndStats();
        _updateDataStatus();
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _fetchDataAndStats() async {
    // Only show full screen loader on initial load
    if (mounted && _data.isEmpty) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final newData = await _apiService.getCarbonData();
      if (!mounted) return;

      final now = DateTime.now();
      _lastFetchTime = now;

      DailyStats? daily;
      WeeklyStats? weekly;
      MonthlyStats? monthly;

      // Sort data by time just in case it's not ordered
      newData.sort((a, b) {
        final timeA = DateTime.tryParse(a.time) ?? DateTime(1970);
        final timeB = DateTime.tryParse(b.time) ?? DateTime(1970);
        return timeA.compareTo(timeB);
      });

      if (newData.isNotEmpty) {
        daily = _apiService.calculateDailyStats(newData);
        weekly = _apiService.calculateWeeklyStats(newData);
        monthly = _apiService.calculateMonthlyStats(newData);
      }

      setState(() {
        _data = newData; // Store the fetched data
        _dailyStats = daily;
        _weeklyStats = weekly;
        _monthlyStats = monthly;
        _isLoading = false; // Loading finished
      });
      _updateDataStatus();
    } catch (e) {
      print("Error fetching data and stats: $e");
      if (!mounted) return;
      setState(() {
        _dataStatus = "Not Reading Data";
        _isLoading = false; // Fetch failed
      });
      _showErrorSnackbar("Failed to fetch data. Check connection.");
    }
  }

  void _updateDataStatus() {
    if (!mounted) return;
    // ... (status logic remains the same) ...
    if (_lastFetchTime == null) {
      if (!_isLoading && _dataStatus != "Configuration Error") {
        setState(() {
          _dataStatus = "Not Reading Data";
        });
      } else if (_isLoading) {
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
          _dataStatus =
              _data.isNotEmpty ? "Using Historic Data" : "Not Reading Data";
        });
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _showErrorDialog(String title, String content) {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: <Widget>[
            TextButton(
              child: const Text("OK"),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  void _showErrorSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // --- LOGOUT FUNCTION ---
  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      // Navigate back to AuthScreen after logout
      Navigator.of(context).pushReplacementNamed('/auth');
    } catch (e) {
      print("Error logging out: $e");
      _showErrorSnackbar("Failed to log out. Please try again.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FlutterLogo(size: 30),
            SizedBox(width: 8),
            Text('Carbon शोधक'),
          ],
        ),
        actions: [
          // --- ADD LOGOUT BUTTON ---
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
          if (!_isLoading || _data.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _fetchDataAndStats,
              tooltip: 'Refresh Data',
            )
          else
            const Padding(
              padding: EdgeInsets.only(right: 15.0),
              child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.5, color: Colors.white)),
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
      body: _isLoading && _data.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchDataAndStats,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1000),
                    child: Padding(
                      padding: const EdgeInsets.all(AppConstants.screenPadding),
                      child: Column(
                        children: [
                          StatusIndicator(status: _dataStatus),
                          const SizedBox(height: AppConstants.sectionSpacing),
                          DataChips(data: _data.isNotEmpty ? _data.last : null),
                          const SizedBox(
                              height: AppConstants.sectionSpacing * 1.5),
                          Text(
                            "Historical Data Statistics",
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w500),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppConstants.itemSpacing),
                          // **** Pass the full _data list ****
                          StatsTable(
                            allData: _data, // Pass the raw data
                            dailyStats: _dailyStats,
                            weeklyStats: _weeklyStats,
                            monthlyStats: _monthlyStats,
                          ),
                          const SizedBox(height: AppConstants.sectionSpacing),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
      bottomNavigationBar: BottomAppBar(
        // BottomAppBar remains the same
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            'Copyright © ${DateTime.now().year} Carbon शोधक App',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ),
      ),
    );
  }

  // --- Dialog Methods remain unchanged ---
  void _openSettings(BuildContext context) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Settings"),
          content: const Text("Settings options will be implemented here."),
          actions: <Widget>[
            TextButton(
              child: const Text("Close"),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  void _openHelp(BuildContext context) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Help & Information"),
          content: const SingleChildScrollView(
            child: Text(
              "This app monitors carbon data (CO & CO2) from MQ-7 and MQ-135 sensors.\n\n"
              "Data Status:\n"
              "🟢 Reading Live Data: Receiving recent data.\n"
              "🟠 Using Historic Data: Showing older data.\n"
              "🔴 Not Reading Data: Failed to fetch data.\n"
              "🔵 Reading Data...: Loading or refresh in progress.\n"
              "🔴 Configuration Error: Missing API URL.\n\n"
              "Logout (->): Sign out of the application.\n"
              "Refresh (🔄): Manually update data.\n\n"
              "Graphs show trends behind the statistics tables.\n\n"
              "Built by Harsh Soni with 💖",
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text("Close"),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }
}
