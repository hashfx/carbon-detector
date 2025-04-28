// lib/widgets/stats_table.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:fl_chart/fl_chart.dart'; // Import fl_chart

import 'package:carbon_counter/models/carbon_stats.dart';
import 'package:carbon_counter/utils/constants.dart';
import 'package:carbon_counter/utils/helpers.dart'; // Import helper
import 'package:carbon_counter/screens/settings_screen.dart'; // Import enum

class StatsTable extends StatelessWidget {
  final List<CarbonData> allData; // Accept the full raw data
  final DailyStats? dailyStats;
  final WeeklyStats? weeklyStats;
  final MonthlyStats? monthlyStats;
  final GraphDisplayMode graphDisplayMode; // Accept the display mode

  const StatsTable({
    super.key,
    required this.allData, // Make it required
    this.dailyStats,
    this.weeklyStats,
    this.monthlyStats,
    required this.graphDisplayMode, // Make it required
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

      final startFormat = DateFormat('dd MMM');
      final endFormat = DateFormat('dd MMM yyyy');

      if (localStartDate.year == localEndDate.year) {
        if (localStartDate.month == localEndDate.month) {
          return '${DateFormat('dd').format(localStartDate)} - ${endFormat.format(localEndDate)}';
        } else {
          return '${startFormat.format(localStartDate)} - ${endFormat.format(localEndDate)}';
        }
      } else {
        return '${startFormat.format(localStartDate)} ${localStartDate.year} - ${endFormat.format(localEndDate)}';
      }
    } catch (e) {
      print(
          "Error formatting week $utcStartDate - $utcEndDate for display: $e");
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
    final dailyTableWidget = _buildSingleStatTable(
      context: context,
      title: "Daily Statistics",
      stats: dailyStats,
      periodType: StatsPeriodType.daily,
    );

    final weeklyTableWidget = _buildSingleStatTable(
      context: context,
      title: "Weekly Statistics",
      stats: weeklyStats,
      periodType: StatsPeriodType.weekly,
    );

    final monthlyTableWidget = _buildSingleStatTable(
      context: context,
      title: "Monthly Statistics",
      stats: monthlyStats,
      periodType: StatsPeriodType.monthly,
    );

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
              Center(child: monthlyTableWidget), // Removed Expanded here
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
      switch (periodType) {
        case StatsPeriodType.daily:
          if (stats is! DailyStats) return [];
          startPeriodUtc =
              DateTime.utc(stats.date.year, stats.date.month, stats.date.day);
          endPeriodUtc = startPeriodUtc.add(const Duration(days: 1));
          break;
        case StatsPeriodType.weekly:
          if (stats is! WeeklyStats) return [];
          startPeriodUtc = stats.startDate;
          endPeriodUtc = stats.endDate.add(const Duration(days: 1));
          break;
        case StatsPeriodType.monthly:
          if (stats is! MonthlyStats) return [];
          startPeriodUtc = stats.monthDate;
          endPeriodUtc =
              DateTime.utc(startPeriodUtc.year, startPeriodUtc.month + 1, 1);
          break;
      }

      return allData.where((item) {
        final itemTime = parseIsoDateTimeString(item.time);
        if (itemTime == null) return false;
        return !itemTime.isBefore(startPeriodUtc) &&
            itemTime.isBefore(endPeriodUtc);
      }).toList();
    } catch (e) {
      print("Error filtering data for $periodType: $e");
      return [];
    }
  }

  // --- MODIFIED _buildSingleStatTable Method ---
  Widget _buildSingleStatTable({
    required BuildContext context,
    required String title,
    required dynamic stats,
    required StatsPeriodType periodType,
  }) {
    final textTheme = Theme.of(context).textTheme;
    final noDataMessage = "$title: No data available yet.";

    // Filter the data for this specific table's period
    final List<CarbonData> periodData = _filterDataForPeriod(stats, periodType);

    final Brightness brightness = Theme.of(context).brightness;
    final Color textColor =
        brightness == Brightness.dark ? Colors.white70 : Colors.black87;
    final Color titleColor =
        brightness == Brightness.dark ? Colors.white : Colors.black;

    // Determine if the background chart should be shown for this table
    final bool showBackgroundChart =
        graphDisplayMode == GraphDisplayMode.behindTable &&
            periodData.length > 1;

    return Card(
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      clipBehavior: Clip.antiAlias,
      // Make card background transparent ONLY if chart is behind it
      color: showBackgroundChart
          ? Colors.transparent
          : Theme.of(context).cardColor,
      child: Stack(
        // Use Stack ONLY if chart is behind it
        children: [
          // ---- Background Chart (Conditional) ----
          if (showBackgroundChart)
            Positioned.fill(
              child: Opacity(
                opacity: 0.9, // Keep some opacity for the chart behind
                child: _buildBackgroundChart(periodData),
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
                    color: titleColor,
                    // Add subtle shadow if chart is behind for readability
                    shadows: showBackgroundChart
                        ? [const Shadow(blurRadius: 2, color: Colors.black38)]
                        : null,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              Center(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Padding(
                    padding: const EdgeInsets.only(
                        bottom: 8.0, left: 8.0, right: 8.0),
                    child: stats == null
                        ? Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 24.0, horizontal: 16.0),
                            constraints: const BoxConstraints(minWidth: 250),
                            color: showBackgroundChart
                                ? Colors.black.withOpacity(0.15)
                                : Colors.grey.withOpacity(
                                    0.1), // Darker bg if chart behind
                            child: Text(
                              noDataMessage,
                              textAlign: TextAlign.center,
                              style:
                                  TextStyle(color: textColor.withOpacity(0.8)),
                            ),
                          )
                        : _buildDataTableContent(
                            stats: stats,
                            textColor: textColor,
                            // Add slight background to table rows ONLY if chart is behind
                            useRowBackground: showBackgroundChart,
                          ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- _buildBackgroundChart Method (Vibrant Colors, remains mostly the same) ---
  Widget _buildBackgroundChart(List<CarbonData> data) {
    if (data.length < 2) return const SizedBox.shrink();

    List<FlSpot> mq7Spots = [];
    List<FlSpot> mq135Spots = [];
    double minY = double.infinity;
    double maxY = -double.infinity;
    double? minX, maxX;

    for (var item in data) {
      final dateTime = parseIsoDateTimeString(item.time);
      if (dateTime == null) continue;

      final xValue = dateTime.millisecondsSinceEpoch.toDouble();
      final yMq7 = item.mq7;
      final yMq135 = item.mq135;

      // Basic validation: Skip potentially invalid negative points for background chart
      if (yMq7 < 0 || yMq135 < 0) continue;

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
        maxY == -double.infinity ||
        mq7Spots.length < 2) {
      return const SizedBox.shrink(); // Not enough valid data for line
    }

    // Adjust Y axis padding
    double yPadding = (maxY - minY) * 0.05; // 5% padding
    if (yPadding == 0) yPadding = 1; // Handle case where min==max
    minY -= yPadding;
    maxY += yPadding;
    if (minY < 0 && !data.any((d) => d.mq7 < 0 || d.mq135 < 0))
      minY = 0; // Don't go below 0 unless data is negative

    final mq7Color =
        Colors.blueAccent.withOpacity(0.7); // Slightly transparent blue
    final mq135Color =
        Colors.orangeAccent.withOpacity(0.7); // Slightly transparent orange

    return LineChart(
      LineChartData(
        backgroundColor: Colors.transparent,
        minX: minX,
        maxX: maxX,
        minY: minY,
        maxY: maxY,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: const FlTitlesData(show: false),
        lineTouchData: const LineTouchData(enabled: false),
        lineBarsData: [
          LineChartBarData(
            spots: mq7Spots,
            isCurved: true,
            color: mq7Color,
            barWidth: 2.5,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [mq7Color.withOpacity(0.05), mq7Color.withOpacity(0.3)],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
            ),
          ),
          LineChartBarData(
            spots: mq135Spots,
            isCurved: true,
            color: mq135Color,
            barWidth: 2.5,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  mq135Color.withOpacity(0.05),
                  mq135Color.withOpacity(0.3)
                ],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- MODIFIED _buildDataTableContent Method ---
  Widget _buildDataTableContent({
    required dynamic stats,
    required Color textColor,
    required bool useRowBackground, // New parameter
  }) {
    List<DataRow> rows = [];
    String periodLabel = 'Period';
    String periodValue = '';

    final cellTextStyle = TextStyle(color: textColor, fontSize: 13);
    final boldCellTextStyle =
        TextStyle(color: textColor, fontWeight: FontWeight.w600, fontSize: 13);

    if (stats is DailyStats) {
      periodLabel = 'Date';
      periodValue = _formatDateDisplay(stats.date);
      rows = _buildStatRows(stats.avgMq7, stats.maxMq7, stats.minMq7,
          stats.avgMq135, stats.maxMq135, stats.minMq135, cellTextStyle);
    } else if (stats is WeeklyStats) {
      periodLabel = 'Week';
      periodValue = _formatWeekDisplay(stats.startDate, stats.endDate);
      rows = _buildStatRows(stats.avgMq7, stats.maxMq7, stats.minMq7,
          stats.avgMq135, stats.maxMq135, stats.minMq135, cellTextStyle);
    } else if (stats is MonthlyStats) {
      periodLabel = 'Month';
      periodValue = _formatMonthDisplay(stats.monthDate);
      rows = _buildStatRows(stats.avgMq7, stats.maxMq7, stats.minMq7,
          stats.avgMq135, stats.maxMq135, stats.minMq135, cellTextStyle);
    }

    rows.insert(
      0,
      DataRow(
        cells: [
          DataCell(Text(periodLabel, style: boldCellTextStyle)),
          DataCell(
            Text(
              periodValue,
              style: cellTextStyle,
              overflow: TextOverflow.ellipsis,
              softWrap: true,
            ),
          ),
          DataCell(
            Text(
              periodValue,
              style: cellTextStyle,
              overflow: TextOverflow.ellipsis,
              softWrap: true,
            ),
          ), // Repeat for alignment, or adjust columns
        ],
        // Apply subtle background to period row if chart is behind
        color: useRowBackground
            ? MaterialStateProperty.all(Colors.black.withOpacity(0.15))
            : null,
      ),
    );

    // Apply background to data rows if chart is behind
    if (useRowBackground) {
      rows = rows.map((row) {
        // Skip applying background to the first (Period) row if already done
        if (rows.indexOf(row) == 0) return row;
        return DataRow(
          cells: row.cells,
          color: MaterialStateProperty.all(Colors.black.withOpacity(0.1)),
        );
      }).toList();
    }

    final headingTextStyle =
        TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 14);

    return DataTable(
      columnSpacing: 12.0, // Adjusted spacing
      headingRowHeight: 35,
      dataRowMinHeight: 30,
      dataRowMaxHeight: 60, // Allow more height for wrapping
      horizontalMargin: 8.0, // Reduced margin
      headingTextStyle: headingTextStyle, // Apply heading style globally
      dataTextStyle: cellTextStyle, // Apply default cell style globally
      columns: const [
        DataColumn(label: Text('Metric')),
        DataColumn(label: Text('MQ-7'), numeric: true),
        DataColumn(label: Text('MQ-135'), numeric: true),
      ],
      rows: rows,
    );
  }

  // --- _buildStatRows Helper (remains the same) ---
  List<DataRow> _buildStatRows(double avgMq7, double maxMq7, double minMq7,
      double avgMq135, double maxMq135, double minMq135, TextStyle textStyle) {
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

// --- Enum (remains the same) ---
enum StatsPeriodType { daily, weekly, monthly }
