import 'package:flutter/material.dart';

class StatusIndicator extends StatelessWidget {
  final bool isReading;

  StatusIndicator({required this.isReading});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.circle,
            color: isReading ? Colors.green : Colors.red,
            size: 16,
          ),
          SizedBox(width: 8),
          Text(
            isReading ? "Reading Data" : "Not Reading Data",
            style: TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
}

class DataChip extends StatelessWidget {
  final String label;
  final Color color;

  DataChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label, style: TextStyle(color: Colors.white)),
      backgroundColor: color,
    );
  }
}
