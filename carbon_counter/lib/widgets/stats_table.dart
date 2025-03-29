import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:carbon_counter/models/carbon_stats.dart';
import 'package:carbon_counter/utils/constants.dart';
import 'package:timezone/timezone.dart' as tz;

class StatsTable extends StatelessWidget {
  final DailyStats? dailyStats;
  final WeeklyStats? weeklyStats;
  final MonthlyStats? monthlyStats;

  const StatsTable({
    super.key,
    this.dailyStats,
    this.weeklyStats,
    this.monthlyStats,
  });

  // --- Date Formatting Helpers (_formatDateDisplay, _formatWeekDisplay, _formatMonthDisplay) remain the same ---
  String _formatDateDisplay(DateTime utcDate) {
    try {
      final ist = tz.getLocation('Asia/Kolkata');
      final localDate = tz.TZDateTime.from(utcDate, ist);
      return DateFormat('yyyy-MM-dd').format(localDate);
    } catch (e) {
      print("Error formatting date $utcDate for display: $e");
      return DateFormat(
        'yyyy-MM-dd',
      ).format(utcDate); // Fallback to UTC display
    }
  }

  String _formatWeekDisplay(DateTime utcStartDate, DateTime utcEndDate) {
    try {
      final ist = tz.getLocation('Asia/Kolkata');
      final localStartDate = tz.TZDateTime.from(utcStartDate, ist);
      final localEndDate = tz.TZDateTime.from(utcEndDate, ist);

      String startDateFormatted = DateFormat('dd MMM').format(localStartDate);
      String endDateFormatted = DateFormat('dd MMM yyyy').format(localEndDate);

      return '$startDateFormatted -\n$endDateFormatted';
    } catch (e) {
      print(
        "Error formatting week $utcStartDate - $utcEndDate for display: $e",
      );

      return '${DateFormat('yyyy-MM-dd').format(utcStartDate)} - ${DateFormat('yyyy-MM-dd').format(utcEndDate)}';
    }
  }

  String _formatMonthDisplay(DateTime utcMonthDate) {
    try {
      final ist = tz.getLocation('Asia/Kolkata');
      final localDate = tz.TZDateTime.from(utcMonthDate, ist);
      return DateFormat('MMMM yyyy').format(localDate); // Example: October 2023
    } catch (e) {
      print("Error formatting month $utcMonthDate for display: $e");
      return DateFormat(
        'yyyy-MM',
      ).format(utcMonthDate); // Fallback to UTC display
    }
  }

  @override
  Widget build(BuildContext context) {
    // Build the individual table widgets once, so they can be reused in different layouts
    final dailyTableWidget = _buildSingleStatTable(
      context: context,
      title: "Daily Statistics",
      stats: dailyStats,
    );

    final weeklyTableWidget = _buildSingleStatTable(
      context: context,
      title: "Weekly Statistics",
      stats: weeklyStats,
    );

    final monthlyTableWidget = _buildSingleStatTable(
      context: context,
      title: "Monthly Statistics",
      stats: monthlyStats,
    );

    // Use LayoutBuilder to get available width and decide layout
    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxWidth = constraints.maxWidth;

        // --- Define Breakpoints (Adjust these values based on testing) ---
        // Width required for 3 tables comfortably side-by-side
        const double wideLayoutBreakpoint = 1100.0;
        // Width required for 2 tables comfortably side-by-side
        const double mediumLayoutBreakpoint = 720.0;

        // --- Determine Layout Based on Width ---

        if (maxWidth >= wideLayoutBreakpoint) {
          // Wide Screen: Layout 3 tables in a single Row
          return Row(
            crossAxisAlignment:
                CrossAxisAlignment.start, // Align cards to the top
            children: [
              Expanded(child: dailyTableWidget), // Use Expanded to divide space
              const SizedBox(width: AppConstants.sectionSpacing),
              Expanded(child: weeklyTableWidget),
              const SizedBox(width: AppConstants.sectionSpacing),
              Expanded(child: monthlyTableWidget),
            ],
          );
        } else if (maxWidth >= mediumLayoutBreakpoint) {
          // Medium Screen: Layout 2 tables in first row, 1 below
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
          // Narrow Screen: Stack all 3 tables vertically
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

  // --- _buildSingleStatTable Method (Builds one Card with a potentially scrollable DataTable) ---
  // This method remains largely the same as before, focusing on building *one* table card.
  Widget _buildSingleStatTable({
    required BuildContext context,
    required String title,
    dynamic stats,
  }) {
    final textTheme = Theme.of(context).textTheme;
    final noDataMessage = "$title: No data available yet.";

    return Card(
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      clipBehavior: Clip.antiAlias, // Clip scrolling content
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch, // Title stretches
        children: [
          Padding(
            // Title padding
            padding: const EdgeInsets.only(top: 12.0, bottom: 8.0),
            child: Text(
              title,
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          // Wrap the SingleChildScrollView with Center to center the table content
          // horizontally within the card if the table is narrower than the card.
          Center(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              // Add padding inside the scroll view IF the table content itself needs it
              // padding: EdgeInsets.symmetric(horizontal: 4.0), // Optional internal padding
              child: Padding(
                // Padding below the table content inside the scroll view
                padding: const EdgeInsets.only(bottom: 8.0),
                child:
                    stats == null
                        ? Container(
                          // Container for 'No data' message
                          padding: const EdgeInsets.symmetric(
                            vertical: 24.0,
                            horizontal: 16.0,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 250,
                          ), // Ensure min width
                          child: Text(
                            noDataMessage,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.grey),
                          ),
                        )
                        : _buildDataTableContent(
                          stats: stats,
                        ), // Build the actual DataTable
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- _buildDataTableContent Method (Builds the actual DataTable) ---
  // This method remains the same, focusing on creating the columns and rows for a given stats object.
  Widget _buildDataTableContent({required dynamic stats}) {
    List<DataRow> rows = [];
    String periodLabel = 'Period';
    String periodValue = '';
    String periodValueMq135 = '';

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
      );
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
      );
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
      );
    }

    rows.insert(
      0,
      DataRow(
        cells: [
          DataCell(
            Text(
              periodLabel,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          DataCell(Text(periodValue)),
          DataCell(Text(periodValueMq135)),
        ],
      ),
    );

    return DataTable(
      // Set minimum width for the table itself? Optional. Can help prevent excessive squashing before scrolling kicks in.
      // constraints: const BoxConstraints(minWidth: 340), // Example: Minimum width before scrolling
      columnSpacing: 15.0,
      headingRowHeight: 35,
      dataRowMinHeight: 30,
      dataRowMaxHeight: 45,
      columns: const [
        DataColumn(
          label: Text('Metric', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        DataColumn(
          label: Text('MQ-7', style: TextStyle(fontWeight: FontWeight.bold)),
          numeric: true,
        ),
        DataColumn(
          label: Text('MQ-135', style: TextStyle(fontWeight: FontWeight.bold)),
          numeric: true,
        ),
      ],
      rows: rows,
    );
  }

  // --- _buildStatRows Helper --- (Remains the same)
  List<DataRow> _buildStatRows(
    double avgMq7,
    double maxMq7,
    double minMq7,
    double avgMq135,
    double maxMq135,
    double minMq135,
  ) {
    return [
      DataRow(
        cells: [
          const DataCell(Text('Average')),
          DataCell(Text(avgMq7.toStringAsFixed(2))),
          DataCell(Text(avgMq135.toStringAsFixed(2))),
        ],
      ),
      DataRow(
        cells: [
          const DataCell(Text('Maximum')),
          DataCell(Text(maxMq7.toStringAsFixed(2))),
          DataCell(Text(maxMq135.toStringAsFixed(2))),
        ],
      ),
      DataRow(
        cells: [
          const DataCell(Text('Minimum')),
          DataCell(Text(minMq7.toStringAsFixed(2))),
          DataCell(Text(minMq135.toStringAsFixed(2))),
        ],
      ),
    ];
  }
}
