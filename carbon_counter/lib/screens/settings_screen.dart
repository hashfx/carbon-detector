import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// --- Enum for Graph Display Options ---
enum GraphDisplayMode {
  standalone, // Display graph as a separate widget
  behindTable, // Display graph behind the table (like before)
  none, // Do not display the graph
}

// --- Settings Screen Widget ---
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  GraphDisplayMode _selectedMode = GraphDisplayMode.behindTable; // Default
  bool _isLoading = true;

  // --- Shared Preferences Keys ---
  static const String _graphModeKey = 'graphDisplayMode';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  // --- Load saved settings ---
  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedModeIndex = prefs.getInt(_graphModeKey);

      if (savedModeIndex != null &&
          savedModeIndex >= 0 &&
          savedModeIndex < GraphDisplayMode.values.length) {
        _selectedMode = GraphDisplayMode.values[savedModeIndex];
      } else {
        // Set default if not found or invalid
        _selectedMode = GraphDisplayMode.behindTable;
        // Optionally save the default back
        // await prefs.setInt(_graphModeKey, _selectedMode.index);
      }
    } catch (e) {
      print("Error loading settings: $e");
      // Keep default on error
      _selectedMode = GraphDisplayMode.behindTable;
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // --- Save selected setting ---
  Future<void> _saveSetting(GraphDisplayMode mode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_graphModeKey, mode.index);
      if (mounted) {
        setState(() {
          _selectedMode = mode;
        });
        // Optionally show a confirmation snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Graph setting saved: ${mode.name}'),
            duration: const Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      print("Error saving settings: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error saving setting.'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        // Pass back the selected setting when the back button is pressed
        // Although SharedPreferences makes this less critical, it provides immediate feedback
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop(_selectedMode);
          },
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16.0),
              children: <Widget>[
                Text(
                  'Graph Display Options',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 10),
                RadioListTile<GraphDisplayMode>(
                  title: const Text('Display Graph as Standalone Widget'),
                  subtitle:
                      const Text('Shows the graph above the stats tables.'),
                  value: GraphDisplayMode.standalone,
                  groupValue: _selectedMode,
                  onChanged: (GraphDisplayMode? value) {
                    if (value != null) {
                      _saveSetting(value);
                    }
                  },
                ),
                RadioListTile<GraphDisplayMode>(
                  title: const Text('Display Graph Behind Table'),
                  subtitle:
                      const Text('Shows the graph faded behind the tables.'),
                  value: GraphDisplayMode.behindTable,
                  groupValue: _selectedMode,
                  onChanged: (GraphDisplayMode? value) {
                    if (value != null) {
                      _saveSetting(value);
                    }
                  },
                ),
                RadioListTile<GraphDisplayMode>(
                  title: const Text('Do Not Display Graph'),
                  subtitle: const Text('Hides the graph completely.'),
                  value: GraphDisplayMode.none,
                  groupValue: _selectedMode,
                  onChanged: (GraphDisplayMode? value) {
                    if (value != null) {
                      _saveSetting(value);
                    }
                  },
                ),
                const Divider(height: 30),
                // Add other settings sections here if needed in the future
              ],
            ),
    );
  }
}

// Helper function to convert enum to string for display (optional)
// String graphDisplayModeToString(GraphDisplayMode mode) {
//   switch (mode) {
//     case GraphDisplayMode.standalone:
//       return 'Standalone Widget';
//     case GraphDisplayMode.behindTable:
//       return 'Behind Table';
//     case GraphDisplayMode.none:
//       return 'No Graph';
//   }
// }
