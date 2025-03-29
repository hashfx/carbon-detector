import 'package:flutter/material.dart';

class StatusIndicator extends StatelessWidget {
  final String status;

  const StatusIndicator({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color indicatorColor;
    IconData indicatorIcon = Icons.circle; // Default icon

    switch (status) {
      case "Reading Live Data":
        indicatorColor = Colors.green;
        break;
      case "Using Historic Data":
        indicatorColor = Colors.orange;
        indicatorIcon = Icons.history_toggle_off; // More indicative icon
        break;
      case "Not Reading Data":
        indicatorColor = Colors.red;
        indicatorIcon = Icons.error_outline; // More indicative icon
        break;
      case "Reading Data...":
        indicatorColor = Colors.blue; // Indicate activity
        indicatorIcon = Icons.hourglass_top_rounded;
        break;
      case "Configuration Error":
        indicatorColor = Colors.red;
        indicatorIcon = Icons.settings_applications; // Icon for config error
        break;
      default:
        indicatorColor = Colors.grey;
        indicatorIcon = Icons.help_outline; // Unknown status
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Container(
        // Wrap in container for background/border if needed
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
        decoration: BoxDecoration(
          color: indicatorColor.withOpacity(0.1), // Subtle background
          borderRadius: BorderRadius.circular(20.0),
          border: Border.all(color: indicatorColor, width: 0.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min, // Take only needed width
          children: [
            Icon(indicatorIcon, color: indicatorColor, size: 18),
            const SizedBox(width: 8),
            Text(
              status,
              style: TextStyle(
                fontSize: 15,
                color: Theme.of(
                  context,
                ).textTheme.bodyLarge?.color?.withOpacity(0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
