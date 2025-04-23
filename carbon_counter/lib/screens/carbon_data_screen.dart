import 'dart:async';
import 'package:carbon_counter/screens/auth_screen.dart' show AuthScreen;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
// ... other imports ...
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
  // ... (All existing state variables and methods remain the same) ...
  late ApiService _apiService;
  Timer? _timer; // Make timer nullable
  List<CarbonData> _data = [];
  String _dataStatus = "Reading Data...";
  DateTime? _lastFetchTime;

  DailyStats? _dailyStats;
  WeeklyStats? _weeklyStats;
  MonthlyStats? _monthlyStats;

  bool _isLoading = true; // Add loading state

  @override
  void initState() {
    super.initState();
    // Ensure dotenv is loaded, though it's usually done in main.dart
    final scriptUrl = dotenv.env['APPS_SCRIPT_URL'];
    if (scriptUrl == null || scriptUrl.isEmpty) {
      // Handle missing URL error more gracefully
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
    if (mounted) {
      setState(() {
        if (_data.isEmpty) {
          _isLoading = true;
        }
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
      _showErrorSnackbar("Failed to fetch data. Please check connection.");
    }
  }

  void _updateDataStatus() {
    if (!mounted) return;

    if (_lastFetchTime == null) {
      if (!_isLoading && _dataStatus != "Configuration Error") {
        // Don't overwrite config error
        setState(() {
          _dataStatus = "Not Reading Data";
        });
      } else if (_isLoading) {
        // Only show "Reading..." when actively loading
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
    _timer?.cancel(); // Cancel the timer safely
    super.dispose();
  }

  void _showErrorDialog(String title, String content) {
    if (!mounted) return;
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
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating, // Optional: make it float
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // **** ADD PopScope HERE ****
    return PopScope(
      canPop: false, // Prevent default back navigation
      onPopInvoked: (didPop) {
        // If the pop was prevented by canPop: false, ask user to confirm exit
        if (!didPop) {
          showDialog(
            context: context,
            builder:
                (context) => AlertDialog(
                  title: const Text('Exit App?'),
                  content: const Text(
                    'Do you really want to exit Carbon Shodhak?',
                  ),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false), // Stay
                      child: const Text('No'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop(true); // Allow exit
                        // Optionally, force exit if simple pop doesn't work on web
                        // SystemNavigator.pop();
                      },
                      child: const Text('Yes'),
                    ),
                  ],
                ),
          ).then((exit) {
            // If user confirmed 'Yes', you might need this on web specifically
            // if (exit ?? false) {
            //   SystemNavigator.pop();
            // }
          });
        }
      },
      child: Scaffold(
        // Your existing Scaffold
        appBar: AppBar(
          title: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              FlutterLogo(size: 30),
              SizedBox(width: 8),
              Text('Carbon शोधक'),
            ],
          ),
          // **** REMOVE automatic back button ****
          // automaticallyImplyLeading: false, // No longer needed if stack is cleared properly
          actions: [
            // **** Add Logout Button ****
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Log Out',
              onPressed: () async {
                await FirebaseAuth.instance.signOut(); // Sign out from Firebase
                // Navigate back to Auth screen, clearing the stack
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (context) => AuthScreen(),
                  ), // Go back to AuthScreen
                  (Route<dynamic> route) => false,
                );
              },
            ),
            // Refresh button logic remains
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
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                ),
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
            _isLoading && _data.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                  onRefresh: _fetchDataAndStats,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1000),
                        child: Padding(
                          padding: const EdgeInsets.all(
                            AppConstants.screenPadding,
                          ),
                          child: Column(
                            // Column alignment default (center) is fine now
                            children: [
                              StatusIndicator(status: _dataStatus),
                              const SizedBox(
                                height: AppConstants.sectionSpacing,
                              ),
                              DataChips(
                                data: _data.isNotEmpty ? _data.last : null,
                              ),
                              const SizedBox(
                                height: AppConstants.sectionSpacing * 1.5,
                              ),
                              Text(
                                "Historical Data Statistics",
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w500),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: AppConstants.itemSpacing),
                              StatsTable(
                                dailyStats: _dailyStats,
                                weeklyStats: _weeklyStats,
                                monthlyStats: _monthlyStats,
                              ),
                              const SizedBox(
                                height: AppConstants.sectionSpacing,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
        bottomNavigationBar: BottomAppBar(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Copyright © ${DateTime.now().year} Carbon शोधक App',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
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
              "🟢 Reading Live Data: App is actively receiving recent data.\n"
              "🟠 Using Historic Data: Displaying older data; connection might be slow or intermittent.\n"
              "🔴 Not Reading Data: Failed to fetch data. Check network or sensor status.\n"
              "🔵 Reading Data...: Initial data load or refresh in progress.\n"
              "🔴 Configuration Error: Missing API URL in settings.\n\n"
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
