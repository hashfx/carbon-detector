import 'package:flutter/material.dart';
import 'package:carbon_counter/data_model.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class StatusIndicator extends StatelessWidget {
  final String status;

  const StatusIndicator({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color indicatorColor;
    if (status == "Reading Live Data") {
      indicatorColor = Colors.green;
    } else if (status == "Using Historic Data") {
      indicatorColor = Colors.orange;
    } else if (status == "Not Reading Data") {
      indicatorColor = Colors.red;
    } else {
      indicatorColor = Colors.grey; // default state
    }

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.circle, color: indicatorColor, size: 16),
          SizedBox(width: 8),
          Text(
            status, // Display the status message
            style: TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
}

class DataButton extends StatelessWidget {
  final CarbonData data;

  const DataButton({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ElevatedButton(
        onPressed: () {
          print("Time: ${data.time}, MQ7: ${data.mq7}, MQ135: ${data.mq135}");
        },
        child: Text(
          "Time: ${data.time}\nMQ7: ${data.mq7}\nMQ135: ${data.mq135}",
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class DataChips extends StatelessWidget {
  final CarbonData? data;

  const DataChips({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data == null) {
      return Text("No real-time data available.");
    }

    DateTime dateTimeLocal;
    try {
      dateTimeLocal = DateFormat('yyyy-MM-dd HH:mm:ss').parse(data!.time);
    } catch (e) {
      dateTimeLocal = DateTime.tryParse(data!.time) ?? DateTime.now();
    }

    tz.initializeTimeZones();
    final ist = tz.getLocation('Asia/Kolkata');
    final dateTimeIST = tz.TZDateTime.from(dateTimeLocal, ist);

    String formattedTime = DateFormat('HH:mm:ss').format(dateTimeIST);

    return Column(
      children: [
        Chip(
          label: Text("Time (IST): $formattedTime"),
          avatar: Icon(Icons.access_time),
        ),
        SizedBox(height: 8),
        Chip(
          label: Text("MQ7: ${data!.mq7.toStringAsFixed(2)}"),
          avatar: Icon(Icons.thermostat),
        ),
        SizedBox(height: 8),
        Chip(
          label: Text("MQ135: ${data!.mq135.toStringAsFixed(2)}"),
          avatar: Icon(Icons.thermostat),
        ),
      ],
    );
  }
}


