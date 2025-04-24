// lib/services/api_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart'; // Keep for formatting output
import 'package:carbon_counter/models/carbon_stats.dart';
import 'package:carbon_counter/utils/helpers.dart'; // Import the helper

class ApiService {
  final String _scriptUrl;

  ApiService(this._scriptUrl);

  // --- getCarbonData Method (Unchanged from previous version handling new schema) ---
  Future<List<CarbonData>> getCarbonData() async {
    // ... (Keep the implementation that handles the List response and skips header)
    try {
      final response = await http.get(Uri.parse(_scriptUrl)).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final decodedData = json.decode(response.body);

        if (decodedData is List) {
          if (decodedData.length < 2) {
            print("API returned insufficient data (no data rows found).");
            return [];
          }

          List<CarbonData> carbonDataList = [];
          for (var row in decodedData.skip(1)) { // Skip header row
            if (row is List && row.length >= 3) {
              String timeStr = row[0]?.toString() ?? '';
              double mq7 = double.tryParse(row[1]?.toString() ?? '0.0') ?? 0.0;
              double mq135 = double.tryParse(row[2]?.toString() ?? '0.0') ?? 0.0;

               if (timeStr.isNotEmpty) {
                 carbonDataList.add(CarbonData(
                   time: timeStr, // Store the original string time
                   mq7: mq7,
                   mq135: mq135,
                 ));
               } else {
                  print("Skipping row due to empty time string: $row");
               }
            } else {
              print("Invalid data row format skipped: $row");
            }
          }
          return carbonDataList;
        } else {
           print("Invalid response format received: Expected a List, got ${decodedData.runtimeType}");
           throw Exception('Failed to parse data: Invalid format.');
        }
      } else {
        print("API request failed with status code: ${response.statusCode}, Body: ${response.body}");
        throw Exception(
            'Failed to load data. Status code: ${response.statusCode}');
      }
    } on TimeoutException catch (e) {
        print("API request timed out: $e");
        throw Exception('Failed to load data: Request timed out.');
    } catch (e) {
       print("Error fetching carbon data: $e");
       throw Exception('Failed to load data: $e');
    }
  }

  // --- _parseDateTime removed, now using helper ---

  // --- Stat Calculation Methods (Use helper function) ---
  DailyStats? calculateDailyStats(List<CarbonData> data) {
    if (data.isEmpty) return null;
    Map<DateTime, List<CarbonData>> dailyData = {};

    for (var item in data) {
      // Use the helper function here
      DateTime? dateTime = parseIsoDateTimeString(item.time);
      if (dateTime == null) continue;
      // Ensure comparison is done with UTC dates
      DateTime dateOnlyUtc = DateTime.utc(dateTime.year, dateTime.month, dateTime.day);
      dailyData.putIfAbsent(dateOnlyUtc, () => []).add(item);
    }
    // ... rest of daily stats calculation logic remains the same ...
     if (dailyData.isEmpty) return null;

    DateTime latestDateUtc = dailyData.keys.reduce((a, b) => a.isAfter(b) ? a : b);
    List<CarbonData> latestDayData = dailyData[latestDateUtc]!;

    if (latestDayData.isEmpty) return null;

    double sumMq7 = 0, sumMq135 = 0;
    double maxMq7 = -double.infinity, maxMq135 = -double.infinity;
    double minMq7 = double.infinity, minMq135 = double.infinity;

    for (var item in latestDayData) {
      sumMq7 += item.mq7;
      sumMq135 += item.mq135;
      maxMq7 = item.mq7 > maxMq7 ? item.mq7 : maxMq7;
      maxMq135 = item.mq135 > maxMq135 ? item.mq135 : maxMq135;
      minMq7 = item.mq7 < minMq7 ? item.mq7 : minMq7;
      minMq135 = item.mq135 < minMq135 ? item.mq135 : minMq135;
    }

     if (latestDayData.length == 1) {
         minMq7 = latestDayData.first.mq7;
         minMq135 = latestDayData.first.mq135;
     }


    return DailyStats(
      date: latestDateUtc,
      avgMq7: sumMq7 / latestDayData.length,
      avgMq135: sumMq135 / latestDayData.length,
      maxMq7: maxMq7 == -double.infinity ? 0.0 : maxMq7,
      maxMq135: maxMq135 == -double.infinity ? 0.0 : maxMq135,
      minMq7: minMq7 == double.infinity ? 0.0 : minMq7,
      minMq135: minMq135 == double.infinity ? 0.0 : minMq135,
    );
  }

  WeeklyStats? calculateWeeklyStats(List<CarbonData> data) {
     if (data.isEmpty) return null;
     Map<DateTime, List<CarbonData>> weeklyData = {};

     for (var item in data) {
       // Use the helper function here
       DateTime? dateTime = parseIsoDateTimeString(item.time);
       if (dateTime == null) continue;
       // Ensure comparison is done with UTC dates
       int daysToSubtract = dateTime.weekday - DateTime.monday;
       if (daysToSubtract < 0) daysToSubtract += 7; // Handle Sunday start if needed
       DateTime firstDayOfWeekUtc = DateTime.utc(dateTime.year, dateTime.month, dateTime.day).subtract(Duration(days: daysToSubtract));
       weeklyData.putIfAbsent(firstDayOfWeekUtc, () => []).add(item);
     }
     // ... rest of weekly stats calculation logic remains the same ...
      if (weeklyData.isEmpty) return null;

     DateTime latestWeekStartUtc = weeklyData.keys.reduce((a, b) => a.isAfter(b) ? a : b);
     List<CarbonData> thisWeekData = weeklyData[latestWeekStartUtc]!;

     if (thisWeekData.isEmpty) return null;

     double sumMq7 = 0, sumMq135 = 0;
     double maxMq7 = -double.infinity, maxMq135 = -double.infinity;
     double minMq7 = double.infinity, minMq135 = double.infinity;

     for (var item in thisWeekData) {
         sumMq7 += item.mq7;
         sumMq135 += item.mq135;
         maxMq7 = item.mq7 > maxMq7 ? item.mq7 : maxMq7;
         maxMq135 = item.mq135 > maxMq135 ? item.mq135 : maxMq135;
         minMq7 = item.mq7 < minMq7 ? item.mq7 : minMq7;
         minMq135 = item.mq135 < minMq135 ? item.mq135 : minMq135;
     }

     if (thisWeekData.length == 1) {
        minMq7 = thisWeekData.first.mq7;
        minMq135 = thisWeekData.first.mq135;
     }

     DateTime weekEndDateUtc = latestWeekStartUtc.add(const Duration(days: 6));

     return WeeklyStats(
       startDate: latestWeekStartUtc,
       endDate: weekEndDateUtc,
       avgMq7: sumMq7 / thisWeekData.length,
       avgMq135: sumMq135 / thisWeekData.length,
       maxMq7: maxMq7 == -double.infinity ? 0.0 : maxMq7,
       maxMq135: maxMq135 == -double.infinity ? 0.0 : maxMq135,
       minMq7: minMq7 == double.infinity ? 0.0 : minMq7,
       minMq135: minMq135 == double.infinity ? 0.0 : minMq135,
     );
  }

  MonthlyStats? calculateMonthlyStats(List<CarbonData> data) {
     if (data.isEmpty) return null;
     Map<DateTime, List<CarbonData>> monthlyData = {};

     for (var item in data) {
       // Use the helper function here
       DateTime? dateTime = parseIsoDateTimeString(item.time);
       if (dateTime == null) continue;
       // Ensure comparison is done with UTC dates
       DateTime monthStartUtc = DateTime.utc(dateTime.year, dateTime.month, 1);
       monthlyData.putIfAbsent(monthStartUtc, () => []).add(item);
     }
    // ... rest of monthly stats calculation logic remains the same ...
     if (monthlyData.isEmpty) return null;

     DateTime latestMonthStartUtc = monthlyData.keys.reduce((a, b) => a.isAfter(b) ? a : b);
     List<CarbonData> thisMonthData = monthlyData[latestMonthStartUtc]!;

     if (thisMonthData.isEmpty) return null;

     double sumMq7 = 0, sumMq135 = 0;
     double maxMq7 = -double.infinity, maxMq135 = -double.infinity;
     double minMq7 = double.infinity, minMq135 = double.infinity;

     for (var item in thisMonthData) {
       sumMq7 += item.mq7;
       sumMq135 += item.mq135;
       maxMq7 = item.mq7 > maxMq7 ? item.mq7 : maxMq7;
       maxMq135 = item.mq135 > maxMq135 ? item.mq135 : maxMq135;
       minMq7 = item.mq7 < minMq7 ? item.mq7 : minMq7;
       minMq135 = item.mq135 < minMq135 ? item.mq135 : minMq135;
     }

      if (thisMonthData.length == 1) {
        minMq7 = thisMonthData.first.mq7;
        minMq135 = thisMonthData.first.mq135;
      }


     return MonthlyStats(
       monthDate: latestMonthStartUtc,
       avgMq7: sumMq7 / thisMonthData.length,
       avgMq135: sumMq135 / thisMonthData.length,
       maxMq7: maxMq7 == -double.infinity ? 0.0 : maxMq7,
       maxMq135: maxMq135 == -double.infinity ? 0.0 : maxMq135,
       minMq7: minMq7 == double.infinity ? 0.0 : minMq7,
       minMq135: minMq135 == double.infinity ? 0.0 : minMq135,
     );
  }
}