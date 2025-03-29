import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:carbon_counter/models/carbon_stats.dart';
import 'package:intl/intl.dart';

class ApiService {
  final String _scriptUrl;

  ApiService(this._scriptUrl);

  Future<List<CarbonData>> getCarbonData() async {
    try {
      final response = await http
          .get(Uri.parse(_scriptUrl))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        // Decode the JSON response body
        final decodedData = json.decode(response.body);

        if (decodedData is List) {
          // Check if the list is empty or only contains the header row
          if (decodedData.length < 2) {
            print("API returned insufficient data (no data rows found).");
            return []; // Return empty list if no actual data rows exist
          }

          List<CarbonData> carbonDataList = [];
          // Iterate through the list, SKIPPING the first element (header row)
          for (var row in decodedData.skip(1)) {
            // Validate that each row is a List and has at least 3 elements
            if (row is List && row.length >= 3) {
              // Attempt to parse values, providing defaults on failure
              String timeStr = row[0]?.toString() ?? '';
              double mq7 = double.tryParse(row[1]?.toString() ?? '0.0') ?? 0.0;
              double mq135 =
                  double.tryParse(row[2]?.toString() ?? '0.0') ?? 0.0;

              // Basic validation: Ensure time string is not empty before adding
              if (timeStr.isNotEmpty) {
                carbonDataList.add(
                  CarbonData(time: timeStr, mq7: mq7, mq135: mq135),
                );
              } else {
                print("Skipping row due to empty time string: $row");
              }
            } else {
              // Log if a row doesn't match the expected format (List with >= 3 items)
              print("Invalid data row format skipped: $row");
            }
          }
          // Return the populated list of CarbonData objects
          return carbonDataList;
        } else {
          // Handle cases where the decoded data is not a List as expected
          print(
            "Invalid response format received: Expected a List, got ${decodedData.runtimeType}",
          );
          throw Exception('Failed to parse data: Invalid format.');
        }
        
      } else {
        // Handle non-200 status codes
        print(
          "API request failed with status code: ${response.statusCode}, Body: ${response.body}",
        );
        throw Exception(
          'Failed to load data. Status code: ${response.statusCode}',
        );
      }
    } on TimeoutException catch (e) {
      print("API request timed out: $e");
      throw Exception('Failed to load data: Request timed out.');
    } catch (e) {
      // Catch other potential errors (network issues, json decoding errors)
      print("Error fetching carbon data: $e");
      // Consider checking the type of 'e' for more specific error handling if needed
      // if (e is FormatException) { ... }
      throw Exception('Failed to load data: $e');
    }
  }

  DateTime? _parseDateTime(String timeString) {
    if (timeString.isEmpty) return null;
    try {
      // Use DateTime.parse for ISO 8601 format ('...T...Z')
      // It automatically handles the 'Z' as UTC.
      return DateTime.parse(timeString);
    } catch (e) {
      // Keep a fallback for the old format just in case, but log prominently
      try {
        print(
          "Warning: Parsing ISO8601 failed for '$timeString', trying 'yyyy-MM-dd HH:mm:ss'. Error: $e",
        );
        // Attempt to parse the previously expected format as UTC
        return DateFormat('yyyy-MM-dd HH:mm:ss').parseUtc(timeString);
      } catch (e2) {
        print(
          "Error parsing date string with fallback: '$timeString', error: $e2",
        );
        return null; // Return null if both parsing attempts fail
      }
    }
  }

  DailyStats? calculateDailyStats(List<CarbonData> data) {
    if (data.isEmpty) return null;

    Map<DateTime, List<CarbonData>> dailyData = {};

    for (var item in data) {
      DateTime? dateTime;
      try {
        dateTime = DateFormat(
          'yyyy-MM-dd HH:mm:ss',
        ).parse(item.time); // parse with format
      } catch (e) {
        dateTime = DateTime.tryParse(
          item.time,
        ); // fallback to tryParse for other formats
        if (dateTime == null) {
          print("Error parsing date: ${item.time}, error: $e");
          continue; // skip if still can't parse 😏
        }
      }

      DateTime dateOnly = DateTime(dateTime.year, dateTime.month, dateTime.day);
      dailyData.putIfAbsent(dateOnly, () => []);
      dailyData[dateOnly]!.add(item);
    }

    if (dailyData.isEmpty) return null;

    DateTime latestDate = dailyData.keys.reduce((a, b) => a.isAfter(b) ? a : b);
    List<CarbonData> todayData = dailyData[latestDate]!;

    if (todayData.isEmpty) return null;

    double sumMq7 = 0, sumMq135 = 0;
    double maxMq7 = -double.infinity, maxMq135 = -double.infinity;
    double minMq7 = double.infinity, minMq135 = double.infinity;

    for (var item in todayData) {
      sumMq7 += item.mq7;
      sumMq135 += item.mq135;
      maxMq7 = item.mq7 > maxMq7 ? item.mq7 : maxMq7;
      maxMq135 = item.mq135 > maxMq135 ? item.mq135 : maxMq135;
      minMq7 = item.mq7 < minMq7 ? item.mq7 : minMq7;
      minMq135 = item.mq135 < minMq135 ? item.mq135 : minMq135;
    }

    return DailyStats(
      date: latestDate,
      avgMq7: sumMq7 / todayData.length,
      avgMq135: sumMq135 / todayData.length,
      maxMq7: maxMq7,
      maxMq135: maxMq135,
      minMq7: minMq7,
      minMq135: minMq135,
    );
  }

  WeeklyStats? calculateWeeklyStats(List<CarbonData> data) {
    if (data.isEmpty) return null;

    Map<DateTime, List<CarbonData>> weeklyData = {};

    for (var item in data) {
      DateTime? dateTime;
      try {
        dateTime = DateFormat('yyyy-MM-dd HH:mm:ss').parse(item.time);
      } catch (e) {
        dateTime = DateTime.tryParse(item.time);
        if (dateTime == null) {
          print("Error parsing date: ${item.time}, error: $e");
          continue;
        }
      }
      DateTime firstDayOfWeek = dateTime.subtract(
        Duration(days: dateTime.weekday - 1),
      );
      weeklyData.putIfAbsent(firstDayOfWeek, () => []);
      weeklyData[firstDayOfWeek]!.add(item);
    }

    if (weeklyData.isEmpty) return null;

    DateTime latestWeekStart = weeklyData.keys.reduce(
      (a, b) => a.isAfter(b) ? a : b,
    );
    List<CarbonData> thisWeekData = weeklyData[latestWeekStart]!;

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

    DateTime weekStartDate = latestWeekStart;
    DateTime weekEndDate = latestWeekStart.add(Duration(days: 6));

    return WeeklyStats(
      startDate: weekStartDate,
      endDate: weekEndDate,
      avgMq7: sumMq7 / thisWeekData.length,
      avgMq135: sumMq135 / thisWeekData.length,
      maxMq7: maxMq7,
      maxMq135: maxMq135,
      minMq7: minMq7,
      minMq135: minMq135,
    );
  }

  MonthlyStats? calculateMonthlyStats(List<CarbonData> data) {
    if (data.isEmpty) return null;

    Map<DateTime, List<CarbonData>> monthlyData = {};

    for (var item in data) {
      DateTime? dateTime;
      try {
        dateTime = DateFormat('yyyy-MM-dd HH:mm:ss').parse(item.time);
      } catch (e) {
        dateTime = DateTime.tryParse(item.time);
        if (dateTime == null) {
          print("Error parsing date: ${item.time}, error: $e");
          continue;
        }
      }
      DateTime monthStart = DateTime(dateTime.year, dateTime.month, 1);
      monthlyData.putIfAbsent(monthStart, () => []);
      monthlyData[monthStart]!.add(item);
    }

    if (monthlyData.isEmpty) return null;

    DateTime latestMonthStart = monthlyData.keys.reduce(
      (a, b) => a.isAfter(b) ? a : b,
    );
    List<CarbonData> thisMonthData = monthlyData[latestMonthStart]!;

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

    return MonthlyStats(
      monthDate: latestMonthStart,
      avgMq7: sumMq7 / thisMonthData.length,
      avgMq135: sumMq135 / thisMonthData.length,
      maxMq7: maxMq7,
      maxMq135: maxMq135,
      minMq7: minMq7,
      minMq135: minMq135,
    );
  }
}
