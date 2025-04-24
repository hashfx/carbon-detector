import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:carbon_counter/models/carbon_stats.dart'; // Ensure this path is correct

class CarbonDataChart extends StatelessWidget {
  final List<CarbonData> data;

  const CarbonDataChart({super.key, required this.data});

  // Helper to parse the ISO 8601 timestamp string
  DateTime? _parseDateTime(String timeString) {
    if (timeString.isEmpty) return null;
    try {
      // Handles ISO8601 "...T...Z" format directly
      return DateTime.parse(timeString);
    } catch (e) {
      print("Error parsing chart date string: '$timeString', error: $e");
      return null;
    }
  }

  // Helper to format DateTime for tooltips (showing time in IST)
  String _formatTooltipTime(DateTime utcDate) {
    try {
      final ist = tz.getLocation('Asia/Kolkata'); // Load IST timezone
      final localDate = tz.TZDateTime.from(utcDate, ist); // Convert UTC to IST

      // Check if the data spans more than one day to decide format
      if (data.length > 1) {
        final firstDate = _parseDateTime(data.first.time);
        final lastDate = _parseDateTime(data.last.time);
        // Ensure dates are valid and check if they are different days
        if (firstDate != null &&
            lastDate != null &&
            !DateUtils.isSameDay(firstDate, lastDate)) {
          // Format with Date and Time if multi-day
          return DateFormat('dd/MM HH:mm').format(localDate);
        }
      }
      // Format with only Time if single day or few data points
      return DateFormat('HH:mm:ss').format(localDate);
    } catch (e) {
      print("Error formatting tooltip time $utcDate: $e");
      return DateFormat('HH:mm').format(utcDate); // Fallback format on error
    }
  }

  // Helper for Left Axis Titles (PPM values)
  Widget _leftTitleWidgets(double value, TitleMeta meta) {
    const style = TextStyle(
      color: Colors.grey,
      fontWeight: FontWeight.bold,
      fontSize: 10,
    );
    // Format PPM value to integer for cleaner axis
    String text = value.toInt().toString();

    // You could optionally hide the 0 label if minY is always 0
    // if (value == meta.axisMin && value == 0) {
    //   return Container();
    // }

    // Return the text widget styled and positioned
    return SideTitleWidget(
        axisSide: meta.axisSide, // Indicates it's for the left axis
        space: 5.0, // Padding between axis line and label text
        child: Text(text, style: style, textAlign: TextAlign.center));
  }

  @override
  Widget build(BuildContext context) {
    // --- 1. Data Preparation ---
    List<FlSpot> mq7Spots = [];
    List<FlSpot> mq135Spots = [];
    double minY = 0; // Minimum Y value (PPM)
    double maxY = 10; // Default maximum Y value, adjusted below
    double? minX, maxX; // Min/Max X values (time in milliseconds)

    // Iterate through the provided sensor data
    for (var item in data) {
      DateTime? dateTime = _parseDateTime(item.time); // Parse timestamp string
      if (dateTime != null) {
        double xValue =
            dateTime.millisecondsSinceEpoch.toDouble(); // Time as X coordinate

        // Basic validation: Ensure PPM values are non-negative
        if (item.mq7 >= 0 && item.mq135 >= 0) {
          mq7Spots.add(FlSpot(xValue, item.mq7)); // Add spot for MQ-7
          mq135Spots.add(FlSpot(xValue, item.mq135)); // Add spot for MQ-135

          // Update maximum Y value seen so far
          if (item.mq7 > maxY) maxY = item.mq7;
          if (item.mq135 > maxY) maxY = item.mq135;

          // Update min/max X values (time range)
          if (minX == null || xValue < minX) minX = xValue;
          if (maxX == null || xValue > maxX) maxX = xValue;
        } else {
          // Log if invalid data point is skipped
          print(
              "Skipping data point with negative value: Time=${item.time}, MQ7=${item.mq7}, MQ135=${item.mq135}");
        }
      }
    }

    // Add padding to the top of the Y axis for better visualization
    // Handle case where data exists but all values are 0
    maxY = (maxY <= 0 && (mq7Spots.isNotEmpty || mq135Spots.isNotEmpty))
        ? 10 // Set a default max if all data is 0
        : (maxY * 1.15).ceilToDouble(); // Add 15% padding and round up

    // Handle edge cases for X axis (no data, single point, etc.)
    if (mq7Spots.isEmpty && mq135Spots.isEmpty) {
      // If no valid data, display a message within the chart area
      return const SizedBox(
          height: 250, child: Center(child: Text("No chart data available.")));
    }

    // If all data points have the same timestamp or only one point exists
    if (minX == maxX || minX == null || maxX == null) {
      Duration window =
          const Duration(minutes: 10); // Create a 10-minute window
      double centerTime =
          minX ?? DateTime.now().millisecondsSinceEpoch.toDouble();
      minX = centerTime - window.inMilliseconds / 2; // 5 mins before
      maxX = centerTime + window.inMilliseconds / 2; // 5 mins after
    }

    // --- 2. Determine Bottom Title Format Based on Time Range ---
    String bottomTitleFormatPattern;
    // Calculate total duration of the data displayed on the X axis
    Duration totalDuration = Duration(milliseconds: (maxX - minX).toInt());

    // Choose date format based on the total duration
    if (totalDuration.inDays > 1) {
      bottomTitleFormatPattern = 'dd/MM'; // Show Date for multi-day spans
    } else if (totalDuration.inHours > 3) {
      bottomTitleFormatPattern =
          'HH:mm'; // Show Hour:Minute for spans > 3 hours
    } else {
      bottomTitleFormatPattern =
          'mm:ss'; // Show Minute:Second for shorter spans
    }

    // --- 3. Configure LineChartData ---
    final lineChartData = LineChartData(
      // --- Interaction ---
      lineTouchData: LineTouchData(
        handleBuiltInTouches: true, // Enable tap/hover interactions
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (LineBarSpot touchedSpot) =>
              Colors.blueGrey.withOpacity(0.8),
          // Function to build tooltip items when a spot is touched
          getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
            return touchedBarSpots.map((barSpot) {
              final flSpot = barSpot; // The specific spot touched
              String timeStr = "N/A";
              try {
                // Format the time of the touched spot
                DateTime spotTimeUtc =
                    DateTime.fromMillisecondsSinceEpoch(flSpot.x.toInt());
                timeStr = _formatTooltipTime(spotTimeUtc);
              } catch (_) {} // Ignore errors during tooltip time formatting

              // Determine sensor name and style based on which line was touched
              final String sensorName =
                  barSpot.barIndex == 0 ? 'MQ-7' : 'MQ-135';
              final Color lineColor = barSpot.bar.color ??
                  (barSpot.barIndex == 0
                      ? Colors.blueAccent
                      : Colors.orangeAccent);
              final TextStyle style = TextStyle(
                color: lineColor,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              );

              // Construct tooltip text
              final String text =
                  '$sensorName: ${flSpot.y.toStringAsFixed(2)} ppm\n$timeStr';

              return LineTooltipItem(text, style, textAlign: TextAlign.left);
            }).toList();
          },
        ),
        // Visual indicator for the touched spot
        getTouchedSpotIndicator:
            (LineChartBarData barData, List<int> spotIndexes) {
          return spotIndexes.map((spotIndex) {
            return TouchedSpotIndicatorData(
              // Vertical line indicator
              FlLine(
                color: barData.color?.withOpacity(0.7) ?? Colors.grey,
                strokeWidth: 3,
              ),
              // Dot indicator
              FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) =>
                    FlDotCirclePainter(
                  radius: 6, // Size of the indicator dot
                  color: barData.color ?? Colors.grey, // Match line color
                  strokeWidth: 2,
                  strokeColor: Colors.white, // White outline for visibility
                ),
              ),
            );
          }).toList();
        },
      ),

      // --- Grid and Border ---
      gridData: FlGridData(
        show: true, // Show grid lines
        drawVerticalLine: true, // Show vertical grid lines
        // Dynamic intervals based on calculated ranges
        horizontalInterval:
            maxY > 0 ? maxY / 4 : 1, // Interval for horizontal lines
        verticalInterval: (maxX - minX) > 0
            ? (maxX - minX) / 4
            : const Duration(minutes: 1)
                .inMilliseconds
                .toDouble(), // Interval for vertical lines
        // Style for grid lines
        getDrawingHorizontalLine: (value) =>
            const FlLine(color: Color(0xffe7e8ec), strokeWidth: 0.8),
        getDrawingVerticalLine: (value) =>
            const FlLine(color: Color(0xffe7e8ec), strokeWidth: 0.8),
      ),
      borderData: FlBorderData(
          show: false), // Hide the outer chart border (Card provides border)

      // --- Axis Boundaries ---
      minX: minX, // Minimum time value
      maxX: maxX, // Maximum time value
      minY: minY, // Minimum PPM value (0)
      maxY: maxY, // Maximum PPM value (calculated with padding)

      // --- Axis Titles (Labels) ---
      titlesData: FlTitlesData(
        // -- Bottom (Time) Axis --
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true, // Display labels on the bottom axis
            reservedSize: 30, // Space allocated for the labels below the chart
            // Use the inline function to draw labels, capturing the format pattern
            getTitlesWidget: (double value, TitleMeta meta) {
              const style = TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.bold,
                fontSize: 10,
              );
              Widget textWidget;
              try {
                // Use the format pattern determined earlier in the build method
                final format = DateFormat(bottomTitleFormatPattern);
                final dateTimeUtc =
                    DateTime.fromMillisecondsSinceEpoch(value.toInt());
                final ist = tz.getLocation(
                    'Asia/Kolkata'); // Ensure IST timezone is loaded
                final dateTimeIst = tz.TZDateTime.from(dateTimeUtc, ist);
                // Create the text label using the determined format
                textWidget = Text(format.format(dateTimeIst),
                    style: style, overflow: TextOverflow.ellipsis);
              } catch (e) {
                print(
                    "Error formatting bottom title (inline) for value $value: $e");
                textWidget =
                    const Text('', style: style); // Empty text on error
              }
              // Return the label wrapped in SideTitleWidget
              return SideTitleWidget(
                axisSide: meta.axisSide, // Specify axis side
                space: 8.0, // Padding below the axis line
                child: textWidget, // The formatted text label
              );
            },
          ),
        ),
        // -- Left (PPM) Axis --
        leftTitles: AxisTitles(
          // Optional: Add a name to the axis itself
          axisNameWidget: const Text('PPM',
              style: TextStyle(fontSize: 10, color: Colors.grey)),
          axisNameSize: 16, // Space for the axis name
          sideTitles: SideTitles(
            showTitles: true, // Display labels on the left axis
            reservedSize:
                35, // Space allocated for the labels (adjust if needed for wider numbers)
            getTitlesWidget:
                _leftTitleWidgets, // Use the helper function for PPM labels
            // interval: maxY > 0 ? (maxY / 4).roundToDouble() : 1, // Optional: Set interval manually
          ),
        ),
        // -- Hide Top and Right Axis Labels --
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),

      // --- Line Data ---
      lineBarsData: [
        // -- MQ-7 Line --
        LineChartBarData(
          spots: mq7Spots, // Data points for MQ-7
          isCurved: true, // Make the line curved
          color: Colors.blueAccent, // Line color
          barWidth: 3, // Line thickness
          isStrokeCapRound: true, // Rounded line endings
          dotData:
              const FlDotData(show: false), // Hide individual dots on the line
          belowBarData:
              BarAreaData(show: false), // Hide area fill below the line
        ),
        // -- MQ-135 Line --
        LineChartBarData(
          spots: mq135Spots, // Data points for MQ-135
          isCurved: true, // Make the line curved
          color: Colors.orangeAccent, // Line color
          barWidth: 3, // Line thickness
          isStrokeCapRound: true, // Rounded line endings
          dotData:
              const FlDotData(show: false), // Hide individual dots on the line
          belowBarData:
              BarAreaData(show: false), // Hide area fill below the line
        ),
      ],
    );

    // --- 4. Return the Chart Widget ---
    // Use AspectRatio to maintain proportions within the Card
    return AspectRatio(
      aspectRatio: 1.8, // Adjust aspect ratio (width/height) as desired
      // Add padding around the chart itself for better spacing from Card edges
      child: Padding(
        padding: const EdgeInsets.only(right: 16, top: 10, bottom: 5, left: 5),
        child: LineChart(
          lineChartData, // The configured chart data
          // duration: const Duration(milliseconds: 150), // Optional: Animate changes
        ),
      ),
    );
  }
}
