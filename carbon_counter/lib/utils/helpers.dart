// lib/utils/helpers.dart
import 'package:intl/intl.dart';

DateTime? parseIsoDateTimeString(String? timeString) {
  if (timeString == null || timeString.isEmpty) return null;
  try {
    // DateTime.parse handles ISO 8601 format ('...T...Z')
    return DateTime.parse(timeString).toUtc(); // Ensure it's UTC
  } catch (e) {
    // Fallback for the older format (less likely needed now)
    try {
      print(
          "Warning: Parsing ISO8601 failed for '$timeString', trying 'yyyy-MM-dd HH:mm:ss'. Error: $e");
      // Attempt to parse the previously expected format as UTC
      return DateFormat('yyyy-MM-dd HH:mm:ss').parseUtc(timeString);
    } catch (e2) {
      print("Error parsing date string '$timeString' with any format: $e2");
      return null; // Return null if parsing fails
    }
  }
}

// You can add other helper functions here later if needed
