// lib/services/settings_service.dart
import 'package:flutter/material.dart'; // Import material for ThemeMode
import 'package:shared_preferences/shared_preferences.dart';
import 'package:carbon_counter/utils/graph_display_mode.dart'; // Import the enum

class SettingsService {
  static const String _graphModeKey = 'graphDisplayMode';
  static const String _themeModeKey = 'appThemeMode'; // Key for theme

  SharedPreferences? _prefs;

  // Ensures SharedPreferences is initialized. Call this before using other methods.
  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
    print("SettingsService Initialized. Prefs instance: ${_prefs != null}");
  }

  // --- Graph Display Mode ---

  GraphDisplayMode getGraphDisplayMode() {
    _checkPrefs();
    final modeString = _prefs!.getString(_graphModeKey);
    // Default to 'behindTable' if not set
    return GraphDisplayMode.values.firstWhere(
      (e) => e.toString() == modeString,
      orElse: () => GraphDisplayMode.behindTable,
    );
  }

  Future<void> setGraphDisplayMode(GraphDisplayMode mode) async {
    await init(); // Ensure initialized
    await _prefs!.setString(_graphModeKey, mode.toString());
    print("Saved GraphDisplayMode: ${mode.toString()}");
  }

  // --- Theme Mode ---

  ThemeMode getThemeMode() {
    _checkPrefs();
    final themeString = _prefs!.getString(_themeModeKey);
    print("Read ThemeMode string: $themeString");
    switch (themeString) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system; // Default to system
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    await init(); // Ensure initialized
    String themeString;
    switch (mode) {
      case ThemeMode.light:
        themeString = 'light';
        break;
      case ThemeMode.dark:
        themeString = 'dark';
        break;
      case ThemeMode.system:
      default:
        themeString = 'system';
        break;
    }
    await _prefs!.setString(_themeModeKey, themeString);
    print("Saved ThemeMode: $themeString");
  }

  // --- Helper ---
  void _checkPrefs() {
    if (_prefs == null) {
      // Attempt to initialize if null, although init() should be called beforehand
      print("Warning: _prefs was null in _checkPrefs. Attempting late init.");
      // Throwing error might be too strict if called early in lifecycle.
      // Consider implications or ensure init() is always called first.
      // For now, let's throw to highlight the issue clearly.
      throw Exception(
          "SettingsService not initialized. Call init() first, ideally in main() before runApp.");
    }
  }
}
