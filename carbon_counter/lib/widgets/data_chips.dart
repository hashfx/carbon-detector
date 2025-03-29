import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;
// Ensure timezone data is initialized in main.dart or here if needed
// import 'package:timezone/data/latest.dart' as tz;

// Corrected import path
import 'package:carbon_counter/models/carbon_stats.dart';

class DataChips extends StatelessWidget {
  final CarbonData? data;

  const DataChips({super.key, required this.data});

  // Helper to format time safely
  String _formatTime(String timeString) {
    if (timeString.isEmpty) return "Invalid Time";

    try {
      // Use DateTime.parse for ISO 8601 format ('...T...Z')
      DateTime dateTimeUtc = DateTime.parse(timeString);

      // Get the IST timezone
      final ist = tz.getLocation('Asia/Kolkata');
      // Convert the parsed UTC time to IST
      final dateTimeIST = tz.TZDateTime.from(dateTimeUtc, ist);

      // Format the IST time for display
      return DateFormat('HH:mm:ss').format(dateTimeIST);
    } catch (e) {
      // Log the error if parsing fails for any reason
      print("Error parsing/formatting date chip '$timeString': $e");
      // You could try the old format as a fallback here too, if necessary
      try {
        print(
          "Warning: Chip ISO8601 parse failed for '$timeString', trying 'yyyy-MM-dd HH:mm:ss'. Error: $e",
        );
        DateTime fallbackUtc = DateFormat(
          'yyyy-MM-dd HH:mm:ss',
        ).parseUtc(timeString);
        final ist = tz.getLocation('Asia/Kolkata');
        final dateTimeIST = tz.TZDateTime.from(fallbackUtc, ist);
        return DateFormat('HH:mm:ss').format(dateTimeIST);
      } catch (e2) {
        print(
          "Error parsing chip date string with fallback: '$timeString', error: $e2",
        );
        return "Invalid Time"; // Return placeholder if all parsing fails
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (data == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20.0),
        child: Text(
          "Waiting for sensor data...",
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    String formattedTime = _formatTime(data!.time);

    return Column(
      children: [
        Chip(
          label: Text("Time (IST): $formattedTime"),
          avatar: const Icon(Icons.access_time, color: Colors.blueAccent),
          backgroundColor: Colors.blue.shade50,
        ),
        const SizedBox(height: 8),
        Chip(
          label: Text(
            "MQ-7 (CO): ${data!.mq7.toStringAsFixed(2)} ppm",
          ), // Add units
          avatar: const Icon(
            Icons.cloud_outlined,
            color: Colors.grey,
          ), // Icon for CO
          backgroundColor: Colors.grey.shade200,
        ),
        const SizedBox(height: 8),
        Chip(
          label: Text(
            "MQ-135 (CO2/Air Quality): ${data!.mq135.toStringAsFixed(2)} ppm",
          ), // Add units/context
          avatar: const Icon(
            Icons.warning_amber_rounded,
            color: Colors.orangeAccent,
          ), // Icon for Air Quality/CO2
          backgroundColor: Colors.orange.shade50,
        ),
      ],
    );
  }
}
