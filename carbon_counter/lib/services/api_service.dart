import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:carbon_counter/models/carbon_stats.dart';
import 'package:intl/intl.dart';

class ApiService {
  final String _scriptUrl;

  ApiService(this._scriptUrl);

  Future<List<CarbonData>> getCarbonData() async {
    final response = await http.get(Uri.parse(_scriptUrl));

    if (response.statusCode == 200) {
      final decodedData = json.decode(response.body);

      if (decodedData is Map &&
          decodedData.containsKey('data') &&
          decodedData['data'] is List) {
        final sheetData = decodedData['data'];

        return sheetData.map<CarbonData>((row) {
          if (row is List && row.length == 3) {
            return CarbonData(
              time: row[0].toString(),
              mq7: double.tryParse(row[1].toString()) ?? 0.0,
              mq135: double.tryParse(row[2].toString()) ?? 0.0,
            );
          } else {
            print("Invalid row format: $row");
            return CarbonData(time: '', mq7: 0.0, mq135: 0.0);
          }
        }).toList();
      } else {
        print("Invalid response format: $decodedData");
        return [];
      }
    } else {
      throw Exception(
        'Failed to load data. Status code: ${response.statusCode}',
      );
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
