// lib/widgets/stats_table.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:fl_chart/fl_chart.dart'; // Import fl_chart

import 'package:carbon_counter/models/carbon_stats.dart';
import 'package:carbon_counter/utils/constants.dart';
import 'package:carbon_counter/utils/helpers.dart'; // Import helper

class StatsTable extends StatelessWidget {
  final List<CarbonData> allData; // Accept the full raw data
  final DailyStats? dailyStats;
  final WeeklyStats? weeklyStats;
  final MonthlyStats? monthlyStats;

  const StatsTable({
    super.key,
    required this.allData, // Make it required
    this.dailyStats,
    this.weeklyStats,
    this.monthlyStats,
  });

  // --- Date Formatting Helpers (remain the same) ---
  String _formatDateDisplay(DateTime utcDate) {
    try {
      final ist = tz.getLocation('Asia/Kolkata');
      final localDate = tz.TZDateTime.from(utcDate, ist);
      return DateFormat('yyyy-MM-dd').format(localDate);
    } catch (e) {
      print("Error formatting date $utcDate for display: $e");
      return DateFormat('yyyy-MM-dd').format(utcDate); // Fallback
    }
  }

  String _formatWeekDisplay(DateTime utcStartDate, DateTime utcEndDate) {
    try {
      final ist = tz.getLocation('Asia/Kolkata');
      final localStartDate = tz.TZDateTime.from(utcStartDate, ist);
      final localEndDate = tz.TZDateTime.from(utcEndDate, ist);

      // Adjust format slightly for better wrapping if needed
      final startFormat = DateFormat('dd MMM');
      final endFormat = DateFormat('dd MMM yyyy');

      // Check if start and end year are the same
      if (localStartDate.year == localEndDate.year) {
        // Check if start and end month are the same
        if (localStartDate.month == localEndDate.month) {
          // e.g., 21 - 27 Apr 2025
          return '${DateFormat('dd').format(localStartDate)} - ${endFormat.format(localEndDate)}';
        } else {
          // e.g., 28 Apr - 04 May 2025
          return '${startFormat.format(localStartDate)} - ${endFormat.format(localEndDate)}';
        }
      } else {
        // e.g., 29 Dec 2024 - 04 Jan 2025
        return '${startFormat.format(localStartDate)} ${localStartDate.year} - ${endFormat.format(localEndDate)}';
      }
    } catch (e) {
      print(
          "Error formatting week $utcStartDate - $utcEndDate for display: $e");
      // Fallback with newline for potential wrapping
      return '${DateFormat('yyyy-MM-dd').format(utcStartDate)}\n- ${DateFormat('yyyy-MM-dd').format(utcEndDate)}';
    }
  }

  String _formatMonthDisplay(DateTime utcMonthDate) {
    try {
      final ist = tz.getLocation('Asia/Kolkata');
      final localDate = tz.TZDateTime.from(utcMonthDate, ist);
      return DateFormat('MMMM yyyy').format(localDate);
    } catch (e) {
      print("Error formatting month $utcMonthDate for display: $e");
      return DateFormat('yyyy-MM').format(utcMonthDate); // Fallback
    }
  }

  // --- Build method with LayoutBuilder (remains the same) ---
  @override
  Widget build(BuildContext context) {
    // Build the individual table widgets once
    final dailyTableWidget = _buildSingleStatTable(
      context: context,
      title: "Daily Statistics",
      stats: dailyStats,
      periodType: StatsPeriodType.daily, // Pass period type
    );

    final weeklyTableWidget = _buildSingleStatTable(
      context: context,
      title: "Weekly Statistics",
      stats: weeklyStats,
      periodType: StatsPeriodType.weekly, // Pass period type
    );

    final monthlyTableWidget = _buildSingleStatTable(
      context: context,
      title: "Monthly Statistics",
      stats: monthlyStats,
      periodType: StatsPeriodType.monthly, // Pass period type
    );

    // LayoutBuilder logic remains the same
    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxWidth = constraints.maxWidth;
        const double wideLayoutBreakpoint = 1100.0;
        const double mediumLayoutBreakpoint = 720.0;

        if (maxWidth >= wideLayoutBreakpoint) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: dailyTableWidget),
              const SizedBox(width: AppConstants.sectionSpacing),
              Expanded(child: weeklyTableWidget),
              const SizedBox(width: AppConstants.sectionSpacing),
              Expanded(child: monthlyTableWidget),
            ],
          );
        } else if (maxWidth >= mediumLayoutBreakpoint) {
          return Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: dailyTableWidget),
                  const SizedBox(width: AppConstants.sectionSpacing),
                  Expanded(child: weeklyTableWidget),
                ],
              ),
              const SizedBox(height: AppConstants.sectionSpacing),
              Center(child: monthlyTableWidget),
            ],
          );
        } else {
          return Column(
            children: [
              dailyTableWidget,
              const SizedBox(height: AppConstants.sectionSpacing),
              weeklyTableWidget,
              const SizedBox(height: AppConstants.sectionSpacing),
              monthlyTableWidget,
            ],
          );
        }
      },
    );
  }

  // --- Helper to filter data for the specific period (remains the same) ---
  List<CarbonData> _filterDataForPeriod(
      dynamic stats, StatsPeriodType periodType) {
    if (stats == null || allData.isEmpty) return [];

    DateTime startPeriodUtc;
    DateTime endPeriodUtc;

    try {
      // Add try-catch for safety
      switch (periodType) {
        case StatsPeriodType.daily:
          if (stats is! DailyStats) return [];
          startPeriodUtc =
              DateTime.utc(stats.date.year, stats.date.month, stats.date.day);
          endPeriodUtc =
              startPeriodUtc.add(const Duration(days: 1)); // End is exclusive
          break;
        case StatsPeriodType.weekly:
          if (stats is! WeeklyStats) return [];
          startPeriodUtc = stats.startDate; // Already UTC
          endPeriodUtc = stats.endDate.add(const Duration(
              days: 1)); // End is exclusive (end of the last day)
          break;
        case StatsPeriodType.monthly:
          if (stats is! MonthlyStats) return [];
          startPeriodUtc = stats.monthDate; // Already UTC (first day of month)
          // Calculate end of the month (start of next month)
          endPeriodUtc =
              DateTime.utc(startPeriodUtc.year, startPeriodUtc.month + 1, 1);
          break;
      }

      return allData.where((item) {
        final itemTime = parseIsoDateTimeString(item.time); // Use helper
        if (itemTime == null) return false;
        // Check if itemTime is within [startPeriodUtc, endPeriodUtc)
        return !itemTime.isBefore(startPeriodUtc) &&
            itemTime.isBefore(endPeriodUtc);
      }).toList();
    } catch (e) {
      print("Error filtering data for $periodType: $e");
      return []; // Return empty list on error
    }
  }

  // --- MODIFIED _buildSingleStatTable Method (Opacity and Text Style) ---
  Widget _buildSingleStatTable({
    required BuildContext context,
    required String title,
    required dynamic stats,
    required StatsPeriodType periodType, // Added parameter
  }) {
    final textTheme = Theme.of(context).textTheme;
    final noDataMessage = "$title: No data available yet.";

    // Filter the data for this specific table's period
    final List<CarbonData> periodData = _filterDataForPeriod(stats, periodType);

    // Determine text color based on theme brightness for better contrast
    final Brightness brightness = Theme.of(context).brightness;
    final Color textColor =
        brightness == Brightness.dark ? Colors.white : Colors.black87;
    final Color titleColor =
        brightness == Brightness.dark ? Colors.white : Colors.black;

    return Card(
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      clipBehavior: Clip.antiAlias, // Important to clip the chart
      color: Colors
          .transparent, // Make card background transparent if desired, or keep default Card color
      child: Stack(
        // Use Stack to layer chart and table
        children: [
          // ---- Background Chart (Increased Vibrancy) ----
          if (periodData.length > 1) // Only show chart if there's data to plot
            Positioned.fill(
              child: Opacity(
                // Keep overall opacity reasonable if card color is not transparent
                opacity: 1.0, // Chart itself is fully opaque now
                child: _buildBackgroundChart(
                    periodData), // Colors inside chart adjusted
              ),
            ),

          // ---- Foreground Content (Title + Table) ----
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 12.0, bottom: 8.0),
                child: Text(
                  title,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: titleColor, // Use determined text color
                    // Optional: Add a very subtle background/shadow for extreme cases
                    // shadows: [Shadow(blurRadius: 1, color: Colors.black.withOpacity(0.5))],
                    // backgroundColor: Colors.grey.withOpacity(0.1),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              Center(
                // Center the scrollable table content
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Padding(
                    // Add some horizontal padding for table content
                    padding: const EdgeInsets.only(
                        bottom: 8.0, left: 8.0, right: 8.0),
                    child: stats == null
                        ? Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 24.0, horizontal: 16.0),
                            constraints: const BoxConstraints(minWidth: 250),
                            // Add subtle background to "No data" for readability
                            color: Colors.grey.withOpacity(0.1),
                            child: Text(
                              noDataMessage,
                              textAlign: TextAlign.center,
                              style:
                                  TextStyle(color: textColor.withOpacity(0.7)),
                            ),
                          )
                        // Pass textColor to table builder
                        : _buildDataTableContent(
                            stats: stats, textColor: textColor),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- MODIFIED _buildBackgroundChart Method (Vibrant Colors) ---
  Widget _buildBackgroundChart(List<CarbonData> data) {
    if (data.length < 2)
      return const SizedBox.shrink(); // Need at least 2 points for a line

    List<FlSpot> mq7Spots = [];
    List<FlSpot> mq135Spots = [];
    double minY = double.infinity;
    double maxY = -double.infinity;
    double? minX, maxX; // Milliseconds since epoch

    for (var item in data) {
      final dateTime = parseIsoDateTimeString(item.time);
      if (dateTime == null) continue;

      final xValue = dateTime.millisecondsSinceEpoch.toDouble();
      final yMq7 = item.mq7;
      final yMq135 = item.mq135;

      mq7Spots.add(FlSpot(xValue, yMq7));
      mq135Spots.add(FlSpot(xValue, yMq135));

      minY = (yMq7 < minY) ? yMq7 : minY;
      minY = (yMq135 < minY) ? yMq135 : minY;
      maxY = (yMq7 > maxY) ? yMq7 : maxY;
      maxY = (yMq135 > maxY) ? yMq135 : maxY;

      minX = (minX == null || xValue < minX) ? xValue : minX;
      maxX = (maxX == null || xValue > maxX) ? xValue : maxX;
    }

    if (minX == null ||
        maxX == null ||
        minY == double.infinity ||
        maxY == -double.infinity) {
      return const SizedBox.shrink(); // Not enough valid data
    }

    // Add padding to Y axis
    if (minY == maxY) {
      minY -= 1;
      maxY += 1;
    }
    if (minY > 0) {
      minY *= 0.95;
    } else {
      minY *= 1.05;
    }
    if (maxY > 0) {
      maxY *= 1.05;
    } else if (maxY < 0) {
      maxY *= 0.95;
    } else {
      maxY = 1;
    }

    // --- VIBRANT COLORS ---
    final mq7Color = Colors.blueAccent; // More vibrant blue
    final mq135Color = Colors.deepOrangeAccent; // More vibrant orange

    return LineChart(
      LineChartData(
        backgroundColor:
            Colors.transparent, // Chart background is transparent now
        minX: minX,
        maxX: maxX,
        minY: minY,
        maxY: maxY,
        gridData: FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(show: false),
        lineTouchData: LineTouchData(enabled: false),

        lineBarsData: [
          // MQ-7 Line (Vibrant Blue)
          LineChartBarData(
            spots: mq7Spots,
            isCurved: true,
            // Use a solid vibrant color or a slightly more opaque gradient
            color: mq7Color.withOpacity(0.8), // Solid color with some opacity
            // gradient: LinearGradient(
            //   colors: [mq7Color.withOpacity(0.3), mq7Color.withOpacity(0.9)],
            // ),
            barWidth: 3, // Slightly thicker
            isStrokeCapRound: true,
            dotData: FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  mq7Color.withOpacity(0.1),
                  mq7Color.withOpacity(0.4)
                ], // Stronger fill
                begin: Alignment.bottomCenter, end: Alignment.topCenter,
              ),
            ),
          ),
          // MQ-135 Line (Vibrant Orange)
          LineChartBarData(
            spots: mq135Spots,
            isCurved: true,
            // Use a solid vibrant color or a slightly more opaque gradient
            color: mq135Color.withOpacity(0.8), // Solid color with some opacity
            // gradient: LinearGradient(
            //   colors: [mq135Color.withOpacity(0.3), mq135Color.withOpacity(0.9)],
            // ),
            barWidth: 3, // Slightly thicker
            isStrokeCapRound: true,
            dotData: FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  mq135Color.withOpacity(0.1),
                  mq135Color.withOpacity(0.4)
                ], // Stronger fill
                begin: Alignment.bottomCenter, end: Alignment.topCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- MODIFIED _buildDataTableContent Method (Transparent Background, Text Color) ---
  Widget _buildDataTableContent(
      {required dynamic stats, required Color textColor}) {
    List<DataRow> rows = [];
    String periodLabel = 'Period';
    String periodValue = '';
    String periodValueMq135 = '';

    // Define Text Style for cells
    final cellTextStyle = TextStyle(color: textColor);
    final boldCellTextStyle = TextStyle(
        color: textColor, fontWeight: FontWeight.w600); // Bold for labels

    if (stats is DailyStats) {
      periodLabel = 'Date';
      periodValue = _formatDateDisplay(stats.date);
      periodValueMq135 = periodValue;
      rows = _buildStatRows(
          stats.avgMq7,
          stats.maxMq7,
          stats.minMq7,
          stats.avgMq135,
          stats.maxMq135,
          stats.minMq135,
          cellTextStyle); // Pass style
    } else if (stats is WeeklyStats) {
      periodLabel = 'Week';
      periodValue = _formatWeekDisplay(stats.startDate, stats.endDate);
      periodValueMq135 = periodValue;
      rows = _buildStatRows(
          stats.avgMq7,
          stats.maxMq7,
          stats.minMq7,
          stats.avgMq135,
          stats.maxMq135,
          stats.minMq135,
          cellTextStyle); // Pass style
    } else if (stats is MonthlyStats) {
      periodLabel = 'Month';
      periodValue = _formatMonthDisplay(stats.monthDate);
      periodValueMq135 = periodValue;
      rows = _buildStatRows(
          stats.avgMq7,
          stats.maxMq7,
          stats.minMq7,
          stats.avgMq135,
          stats.maxMq135,
          stats.minMq135,
          cellTextStyle); // Pass style
    }

    rows.insert(
        0,
        DataRow(
          cells: [
            DataCell(
                Text(periodLabel, style: boldCellTextStyle)), // Use bold style
            DataCell(
                Text(periodValue, style: cellTextStyle)), // Use normal style
            DataCell(Text(periodValueMq135,
                style: cellTextStyle)), // Use normal style
          ],
        ));

    // Define Text Style for headings
    final headingTextStyle =
        TextStyle(color: textColor, fontWeight: FontWeight.bold);

    return DataTable(
      // --- REMOVE BACKGROUND COLORS ---
      // dataRowColor: MaterialStateProperty.all(Colors.transparent), // Explicitly transparent
      // headingRowColor: MaterialStateProperty.all(Colors.transparent), // Explicitly transparent
      columnSpacing: 15.0,
      headingRowHeight: 35,
      dataRowMinHeight: 30,
      dataRowMaxHeight: 55,
      columns: [
        // Apply text style to headings
        DataColumn(label: Text('Metric', style: headingTextStyle)),
        DataColumn(label: Text('MQ-7', style: headingTextStyle), numeric: true),
        DataColumn(
            label: Text('MQ-135', style: headingTextStyle), numeric: true),
      ],
      rows: rows,
    );
  }

  // --- MODIFIED _buildStatRows Helper (Accept Text Style) ---
  List<DataRow> _buildStatRows(double avgMq7, double maxMq7, double minMq7,
      double avgMq135, double maxMq135, double minMq135, TextStyle textStyle) {
    // Apply the passed text style to all data cells
    return [
      DataRow(cells: [
        DataCell(Text('Average', style: textStyle)),
        DataCell(Text(avgMq7.toStringAsFixed(2), style: textStyle)),
        DataCell(Text(avgMq135.toStringAsFixed(2), style: textStyle)),
      ]),
      DataRow(cells: [
        DataCell(Text('Maximum', style: textStyle)),
        DataCell(Text(maxMq7.toStringAsFixed(2), style: textStyle)),
        DataCell(Text(maxMq135.toStringAsFixed(2), style: textStyle)),
      ]),
      DataRow(cells: [
        DataCell(Text('Minimum', style: textStyle)),
        DataCell(Text(minMq7.toStringAsFixed(2), style: textStyle)),
        DataCell(Text(minMq135.toStringAsFixed(2), style: textStyle)),
      ]),
    ];
  }
}

// --- Enum to help identify period type (remains the same) ---
enum StatsPeriodType { daily, weekly, monthly }
