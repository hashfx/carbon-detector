// lib/screens/carbon_data_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Needed for logout
import 'package:shared_preferences/shared_preferences.dart'; // Import SharedPreferences

import 'package:carbon_counter/services/api_service.dart';
import 'package:carbon_counter/models/carbon_stats.dart';
import 'package:carbon_counter/widgets/status_indicator.dart';
import 'package:carbon_counter/widgets/data_chips.dart';
import 'package:carbon_counter/widgets/stats_table.dart';
import 'package:carbon_counter/utils/constants.dart';
import 'package:carbon_counter/widgets/carbon_data_chart.dart'; // Import chart widget
import 'settings_screen.dart'; // Import the new settings screen

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
  GraphDisplayMode _graphDisplayMode =
      GraphDisplayMode.behindTable; // Default setting

  // --- Shared Preferences Keys ---
  static const String _graphModeKey = 'graphDisplayMode';

  @override
  void initState() {
    super.initState();
    _loadSettings(); // Load settings first
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

  // --- Load Graph Display Setting ---
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedModeIndex = prefs.getInt(_graphModeKey);

      if (savedModeIndex != null &&
          savedModeIndex >= 0 &&
          savedModeIndex < GraphDisplayMode.values.length) {
        if (mounted) {
          setState(() {
            _graphDisplayMode = GraphDisplayMode.values[savedModeIndex];
          });
        }
      } else {
        // Keep default if not found or invalid
        if (mounted) {
          setState(() {
            _graphDisplayMode = GraphDisplayMode.behindTable;
          });
        }
      }
    } catch (e) {
      print("Error loading graph settings: $e");
      // Keep default on error
      if (mounted) {
        setState(() {
          _graphDisplayMode = GraphDisplayMode.behindTable;
        });
      }
    }
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
    // Only show full screen loader on initial load or if data is empty
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
      if (mounted) {
        // Check if mounted before navigating
        Navigator.of(context).pushReplacementNamed('/auth');
      }
    } catch (e) {
      print("Error logging out: $e");
      if (mounted) {
        // Check if mounted before showing snackbar
        _showErrorSnackbar("Failed to log out. Please try again.");
      }
    }
  }

  // --- MODIFIED: Navigate to Settings Screen ---
  void _openSettings(BuildContext context) async {
    if (!mounted) return;
    // Navigate and wait for a result (the new setting)
    final result = await Navigator.push<GraphDisplayMode>(
      context,
      MaterialPageRoute(builder: (context) => const SettingsScreen()),
    );

    // If a setting was changed and returned, update the state
    if (result != null && mounted) {
      // Optionally reload settings from prefs for robustness, or just use returned value
      // await _loadSettings(); // Reload from prefs
      setState(() {
        _graphDisplayMode = result; // Update state with returned value
      });
    } else if (mounted) {
      // If user just navigated back without changing anything in settings screen,
      // ensure the state reflects the latest saved preference.
      await _loadSettings();
    }
  }

  // Help Dialog remains unchanged
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
              "Settings (⚙️): Configure graph display options.\n\n" // Updated help text
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
                          if (_graphDisplayMode ==
                                  GraphDisplayMode.standalone &&
                              _data.length > 1)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: AppConstants.sectionSpacing),
                              child: Card(
                                elevation: 2.0,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8.0)),
                                clipBehavior: Clip.antiAlias,
                                child: CarbonDataChart(data: _data),
                              ),
                            ),
                          if (_graphDisplayMode ==
                                  GraphDisplayMode.standalone &&
                              _data.length <= 1)
                            const Padding(
                              padding: EdgeInsets.symmetric(
                                  vertical: AppConstants.sectionSpacing),
                              child:
                                  Text("Not enough data for standalone graph."),
                            ),
                          Text(
                            "Historical Data Statistics",
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w500),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppConstants.itemSpacing),
                          StatsTable(
                            allData: _data,
                            dailyStats: _dailyStats,
                            weeklyStats: _weeklyStats,
                            monthlyStats: _monthlyStats,
                            graphDisplayMode: _graphDisplayMode,
                          ),
                          const SizedBox(height: AppConstants.sectionSpacing),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
