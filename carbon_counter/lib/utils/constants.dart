import 'package:flutter/material.dart';

class AppConstants {
  // Durations
  static const Duration dataStaleThreshold = Duration(
    seconds: 20,
  ); // Increased threshold slightly
  static const Duration fetchInterval = Duration(seconds: 10); // Fetch interval

  // UI Layout
  static const double screenPadding = 12.0;
  static const double sectionSpacing = 16.0;
  static const double itemSpacing = 8.0;

  // Add other constants like colors, themes, text styles if needed
  // Example:
  // static const Color primaryColor = Colors.blue;
}
