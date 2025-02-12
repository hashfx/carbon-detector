import 'package:flutter/material.dart';
import 'package:carbon_counter/data_model.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart';
import 'package:timezone/data/latest.dart' as tz;

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

class DataButton extends StatelessWidget {
  final CarbonData data;

  DataButton({required this.data});

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

  DataChips({required this.data});

  @override
  Widget build(BuildContext context) {
    if (data == null) {
      return Text("No real-time data available.");
    }

    DateTime dateTimeLocal; // initially parse as local DateTime
    try {
      dateTimeLocal = DateFormat('yyyy-MM-dd HH:mm:ss').parse(data!.time);
    } catch (e) {
      dateTimeLocal = DateTime.tryParse(data!.time) ?? DateTime.now();
    }

    tz.initializeTimeZones();
    final ist = getLocation('Asia/Kolkata'); // get IST timezone location
    final dateTimeIST = TZDateTime.from(
      dateTimeLocal,
      ist,
    ); // convert local DateTime to IST

    String formattedTime = DateFormat(
      'HH:mm:ss',
    ).format(dateTimeIST); // format IST time

    return Column(
      children: [
        Chip(
          label: Text(
            "Time: $formattedTime",
          ),
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
