import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// Corrected import path
import 'package:carbon_counter/models/carbon_stats.dart';
import 'package:carbon_counter/utils/constants.dart';

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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildSingleStatTable(
          context: context,
          title: "Daily Statistics",
          stats: dailyStats,
        ),
        const SizedBox(height: AppConstants.sectionSpacing),
        _buildSingleStatTable(
          context: context,
          title: "Weekly Statistics",
          stats: weeklyStats,
        ),
        const SizedBox(height: AppConstants.sectionSpacing),
        _buildSingleStatTable(
          context: context,
          title: "Monthly Statistics",
          stats: monthlyStats,
        ),
      ],
    );
  }

  // Helper to build individual tables
  Widget _buildSingleStatTable({
    required BuildContext context,
    required String title,
    dynamic stats, // Can be DailyStats, WeeklyStats, or MonthlyStats
  }) {
    final textTheme = Theme.of(context).textTheme;
    final noDataMessage = "$title: No data available yet.";

    return Card(
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch, // Make title stretch
          children: [
            Text(
              title,
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            if (stats == null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Text(
                  noDataMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                ),
              )
            else
              _buildDataTableContent(stats: stats),
          ],
        ),
      ),
    );
  }

  // Builds the DataTable rows based on the stats type
  Widget _buildDataTableContent({required dynamic stats}) {
    List<DataRow> rows = [];
    String periodLabel = 'Period';
    String periodValue = '';

    if (stats is DailyStats) {
      periodLabel = 'Date';
      periodValue = DateFormat('yyyy-MM-dd').format(stats.date);
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
      periodValue =
          '${DateFormat('dd MMM').format(stats.startDate)} - ${DateFormat('dd MMM yyyy').format(stats.endDate)}';
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
      periodValue = DateFormat('MMMM yyyy').format(stats.monthDate);
      rows = _buildStatRows(
        stats.avgMq7,
        stats.maxMq7,
        stats.minMq7,
        stats.avgMq135,
        stats.maxMq135,
        stats.minMq135,
      );
    }

    // Add the period row at the beginning
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
          DataCell(Text(periodValue)), // Repeat for consistency, or leave empty
        ],
      ),
    );

    return DataTable(
      columnSpacing: 15.0, // Adjust spacing
      headingRowHeight: 35,
      dataRowMinHeight: 30,
      dataRowMaxHeight: 40,
      columns: const [
        DataColumn(
          label: Expanded(
            child: Text(
              'Metric',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
        DataColumn(
          label: Expanded(
            child: Text('MQ-7', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          numeric: true,
        ),
        DataColumn(
          label: Expanded(
            child: Text(
              'MQ-135',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          numeric: true,
        ),
      ],
      rows: rows,
    );
  }

  // Helper to create common stat rows
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
