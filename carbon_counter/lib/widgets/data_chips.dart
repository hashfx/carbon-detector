// lib/widgets/data_chips.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;

import 'package:carbon_counter/models/carbon_stats.dart';

class DataChips extends StatelessWidget {
  final CarbonData? data;

  // Define thresholds
  static const double mq7Threshold = 400.0;
  static const double mq135Threshold = 1000.0;

  const DataChips({super.key, required this.data});

  // Helper to format time safely (unchanged)
  String _formatTime(String timeString) {
    if (timeString.isEmpty) return "Invalid Time";
    try {
      DateTime dateTimeUtc = DateTime.parse(timeString);
      final ist = tz.getLocation('Asia/Kolkata');
      final dateTimeIST = tz.TZDateTime.from(dateTimeUtc, ist);
      return DateFormat('HH:mm:ss').format(dateTimeIST);
    } catch (e) {
      print("Error parsing/formatting date chip '$timeString': $e");
      try {
        DateTime fallbackUtc =
            DateFormat('yyyy-MM-dd HH:mm:ss').parseUtc(timeString);
        final ist = tz.getLocation('Asia/Kolkata');
        final dateTimeIST = tz.TZDateTime.from(fallbackUtc, ist);
        return DateFormat('HH:mm:ss').format(dateTimeIST);
      } catch (e2) {
        print(
            "Error parsing chip date string with fallback: '$timeString', error: $e2");
        return "Invalid Time";
      }
    }
  }

  // --- Helper to get color based on value and threshold ---
  Color _getChipColor(
      BuildContext context, double value, double threshold, bool isMq7) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final bool isAboveThreshold = value > threshold;

    // Define base safe/alert colors
    final Color safeColorLight = Colors.green.shade600;
    final Color safeColorDark = Colors.greenAccent.shade400;
    final Color alertColorLight = Colors.red.shade700;
    final Color alertColorDark = Colors.redAccent.shade400;

    if (isAboveThreshold) {
      // Alert colors
      return isDarkMode ? alertColorDark : alertColorLight;
    } else {
      // Safe colors
      return isDarkMode ? safeColorDark : safeColorLight;
    }
  }

  // --- Helper to get background color for the chip ---
  Color _getChipBackgroundColor(BuildContext context, Color statusColor) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    // Use a less saturated version of the status color for background
    return isDarkMode
        ? statusColor.withOpacity(0.25)
        : statusColor.withOpacity(0.15);
  }

  // --- Helper to get icon color for the chip ---
  Color _getChipIconColor(BuildContext context, Color statusColor) {
    // Use the status color directly for the icon for emphasis
    return statusColor;
  }

  // --- Helper to get text color for the chip ---
  Color _getChipTextColor(BuildContext context, Color statusColor) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    // Use primary text color, but consider status color for contrast if needed
    // For simplicity, using the theme's default text color often works well.
    return isDarkMode
        ? Colors.white.withOpacity(0.9)
        : Colors.black.withOpacity(0.85);
    // Alternative: Use the status color if contrast is good
    // return statusColor; // Test this for readability
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    // Default Time Chip colors (using theme's primary color)
    final timeChipBackground = isDarkMode
        ? theme.colorScheme.primary.withOpacity(0.3)
        : theme.colorScheme.primaryContainer;
    final timeChipIconColor = isDarkMode
        ? theme.colorScheme.primary.withOpacity(0.9)
        : theme.colorScheme.primary; // Slightly brighter in dark
    final timeChipTextColor = isDarkMode
        ? Colors.white.withOpacity(0.9)
        : Colors.black.withOpacity(0.8);

    if (data == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20.0),
        child: Text(
          "Waiting for sensor data...",
          style: TextStyle(color: theme.disabledColor),
        ),
      );
    }

    String formattedTime = _formatTime(data!.time);

    // --- Determine colors for MQ-7 and MQ-135 based on thresholds ---
    final Color mq7StatusColor =
        _getChipColor(context, data!.mq7, mq7Threshold, true);
    final Color mq135StatusColor =
        _getChipColor(context, data!.mq135, mq135Threshold, false);

    final Color mq7ChipBackground =
        _getChipBackgroundColor(context, mq7StatusColor);
    final Color mq135ChipBackground =
        _getChipBackgroundColor(context, mq135StatusColor);

    final Color mq7ChipIconColor = _getChipIconColor(context, mq7StatusColor);
    final Color mq135ChipIconColor =
        _getChipIconColor(context, mq135StatusColor);

    final Color mq7ChipTextColor = _getChipTextColor(context, mq7StatusColor);
    final Color mq135ChipTextColor =
        _getChipTextColor(context, mq135StatusColor);

    return Column(
      children: [
        // --- Time Chip ---
        Chip(
          label: Text("Time (IST): $formattedTime"),
          labelStyle: TextStyle(color: timeChipTextColor),
          avatar: Icon(Icons.access_time, color: timeChipIconColor),
          backgroundColor: timeChipBackground,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          side: BorderSide.none,
        ),
        const SizedBox(height: 8),

        // --- MQ-7 Chip (Conditional Color) ---
        Chip(
          label: Text(
            "MQ-7 (CO): ${data!.mq7.toStringAsFixed(2)} ppm",
          ),
          labelStyle: TextStyle(color: mq7ChipTextColor),
          avatar: Icon(
            Icons.cloud_outlined, // Consider Icons.masks for CO
            color: mq7ChipIconColor,
          ),
          backgroundColor: mq7ChipBackground,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          side: BorderSide.none,
        ),
        const SizedBox(height: 8),

        // --- MQ-135 Chip (Conditional Color) ---
        Chip(
          label: Text(
            "MQ-135 (CO2/Air): ${data!.mq135.toStringAsFixed(2)} ppm", // Simplified label
          ),
          labelStyle: TextStyle(color: mq135ChipTextColor),
          avatar: Icon(
            Icons.warning_amber_rounded, // Keep warning icon
            color: mq135ChipIconColor,
          ),
          backgroundColor: mq135ChipBackground,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          side: BorderSide.none,
        ),
      ],
    );
  }
}
