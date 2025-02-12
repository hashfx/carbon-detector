class CarbonData {
  final String time;
  final double mq7;
  final double mq135;

  CarbonData({required this.time, required this.mq7, required this.mq135});
}

class DailyStats {
  final DateTime date;
  final double avgMq7;
  final double maxMq7;
  final double minMq7;
  final double avgMq135;
  final double maxMq135;
  final double minMq135;

  DailyStats({
    required this.date,
    required this.avgMq7,
    required this.maxMq7,
    required this.minMq7,
    required this.avgMq135,
    required this.maxMq135,
    required this.minMq135,
  });
}

class WeeklyStats {
  final DateTime startDate;
  final DateTime endDate;
  final double avgMq7;
  final double maxMq7;
  final double minMq7;
  final double avgMq135;
  final double maxMq135;
  final double minMq135;

  WeeklyStats({
    required this.startDate,
    required this.endDate,
    required this.avgMq7,
    required this.maxMq7,
    required this.minMq7,
    required this.avgMq135,
    required this.maxMq135,
    required this.minMq135,
  });
}

class MonthlyStats {
  final DateTime monthDate;
  final double avgMq7;
  final double maxMq7;
  final double minMq7;
  final double avgMq135;
  final double maxMq135;
  final double minMq135;

  MonthlyStats({
    required this.monthDate,
    required this.avgMq7,
    required this.maxMq7,
    required this.minMq7,
    required this.avgMq135,
    required this.maxMq135,
    required this.minMq135,
  });
}
