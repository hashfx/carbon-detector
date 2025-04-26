// lib/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:carbon_counter/services/settings_service.dart'; // Import SettingsService
import 'package:carbon_counter/utils/graph_display_mode.dart'; // Import the enum
import 'package:carbon_counter/main.dart'; // Import main to access themeNotifier

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Use the global instance from main.dart or initialize locally
  final SettingsService _settingsService = settingsService;
  GraphDisplayMode _selectedGraphMode = GraphDisplayMode.behindTable;
  ThemeMode _selectedThemeMode = ThemeMode.system; // Add state for theme
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    // Ensure service is initialized (might already be by main)
    await _settingsService.init();
    if (mounted) {
      setState(() {
        _selectedGraphMode = _settingsService.getGraphDisplayMode();
        _selectedThemeMode = _settingsService.getThemeMode();
        _isLoading = false;
      });
    }
  }

  Future<void> _updateGraphMode(GraphDisplayMode? mode) async {
    if (mode != null && mode != _selectedGraphMode) {
      setState(() => _selectedGraphMode = mode);
      await _settingsService.setGraphDisplayMode(mode);
      // Optionally: Add visual feedback like a Snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Graph display updated'),
            duration: Duration(seconds: 1)),
      );
    }
  }

  // --- Update Theme ---
  Future<void> _updateThemeMode(ThemeMode? mode) async {
    if (mode != null && mode != _selectedThemeMode) {
      setState(() => _selectedThemeMode = mode);
      await _settingsService.setThemeMode(mode);
      // Update the global notifier to change theme dynamically
      themeNotifier.value = mode;
      // Optionally: Add visual feedback
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Theme updated'), duration: Duration(seconds: 1)),
      );
    }
  }

  // --- LOGOUT FUNCTION ---
  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      // Navigate back to AuthScreen after logout, removing all previous routes
      Navigator.of(context)
          .pushNamedAndRemoveUntil('/auth', (Route<dynamic> route) => false);
    } catch (e) {
      print("Error logging out from Settings: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Failed to log out. Please try again."),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  // --- Placeholder Functions ---
  void _editPersonalData() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Edit Personal Data - Not Implemented Yet")),
    );
    // Navigate to an edit profile screen if you have one
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); // Get theme for styling

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              children: [
                // --- Graph Display Settings ---
                _buildSettingsSectionTitle(context, 'Graph Display'),
                RadioListTile<GraphDisplayMode>(
                  title: const Text('Show Graph Behind Table'),
                  subtitle:
                      const Text('Overlays the graph on the statistics table.'),
                  value: GraphDisplayMode.behindTable,
                  groupValue: _selectedGraphMode,
                  onChanged: _updateGraphMode,
                  activeColor: theme.colorScheme.primary,
                ),
                RadioListTile<GraphDisplayMode>(
                  title: const Text('Show Graph Separately'),
                  subtitle: const Text('Displays the graph above the table.'),
                  value: GraphDisplayMode.standalone,
                  groupValue: _selectedGraphMode,
                  onChanged: _updateGraphMode,
                  activeColor: theme.colorScheme.primary,
                ),
                RadioListTile<GraphDisplayMode>(
                  title: const Text('Hide Graph'),
                  subtitle: const Text('Only shows the statistics table.'),
                  value: GraphDisplayMode.none,
                  groupValue: _selectedGraphMode,
                  onChanged: _updateGraphMode,
                  activeColor: theme.colorScheme.primary,
                ),

                const Divider(height: 24.0, indent: 16, endIndent: 16),

                // --- Appearance Settings ---
                _buildSettingsSectionTitle(context, 'Appearance'),
                RadioListTile<ThemeMode>(
                  title: const Text('Light Theme'),
                  value: ThemeMode.light,
                  groupValue: _selectedThemeMode,
                  onChanged: _updateThemeMode,
                  activeColor: theme.colorScheme.primary,
                ),
                RadioListTile<ThemeMode>(
                  title: const Text('Dark Theme'),
                  value: ThemeMode.dark,
                  groupValue: _selectedThemeMode,
                  onChanged: _updateThemeMode,
                  activeColor: theme.colorScheme.primary,
                ),
                RadioListTile<ThemeMode>(
                  title: const Text('System Default'),
                  subtitle: const Text('Follows your device\'s theme setting.'),
                  value: ThemeMode.system,
                  groupValue: _selectedThemeMode,
                  onChanged: _updateThemeMode,
                  activeColor: theme.colorScheme.primary,
                ),

                const Divider(height: 24.0, indent: 16, endIndent: 16),

                // --- Account Settings ---
                _buildSettingsSectionTitle(context, 'Account'),
                ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: const Text('Edit Personal Data'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _editPersonalData, // Placeholder action
                ),
                ListTile(
                  leading: Icon(Icons.logout,
                      color: theme.colorScheme.error), // Use theme error color
                  title: const Text('Logout'),
                  onTap: _logout,
                ),

                const Divider(height: 24.0, indent: 16, endIndent: 16),

                // --- About Section ---
                _buildSettingsSectionTitle(context, 'About'),
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('App Version'),
                  subtitle:
                      const Text('1.0.0'), // Replace with dynamic version later
                  onTap: () {}, // No action needed
                ),
                ListTile(
                  leading: const Icon(Icons.privacy_tip_outlined),
                  title: const Text('Privacy Policy'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // Maybe reuse the legal dialog logic from AuthScreen?
                    // Or navigate to a dedicated legal screen.
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              "Show Privacy Policy - Not Implemented Yet")),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.gavel_outlined),
                  title: const Text('Terms of Service'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              "Show Terms of Service - Not Implemented Yet")),
                    );
                  },
                ),
              ],
            ),
    );
  }

  // Helper widget for section titles
  Widget _buildSettingsSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(
          left: 16.0, right: 16.0, top: 16.0, bottom: 8.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }
}
