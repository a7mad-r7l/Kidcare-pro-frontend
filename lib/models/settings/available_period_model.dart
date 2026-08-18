class AvailablePeriodModel {
  final String day;
  final String dayName;
  final List<FreePeriodModel> freePeriods;

  AvailablePeriodModel({
    required this.day,
    required this.dayName,
    required this.freePeriods,
  });

  factory AvailablePeriodModel.fromJson(Map<String, dynamic> json) {
    final list = json['free_periods'] as List? ?? [];
    return AvailablePeriodModel(
      day: json['day']?.toString() ?? '',
      dayName: json['day_name']?.toString() ?? '',
      freePeriods: list.map((e) => FreePeriodModel.fromJson(e)).toList(),
    );
  }
}

class FreePeriodModel {
  final String startTime;
  final String endTime;

  FreePeriodModel({
    required this.startTime,
    required this.endTime,
  });

  factory FreePeriodModel.fromJson(Map<String, dynamic> json) {
    return FreePeriodModel(
      // قص الثواني إن وجدت للترتيب البصري
      startTime: (json['start_time']?.toString() ?? '').split(':').take(2).join(':'),
      endTime: (json['end_time']?.toString() ?? '').split(':').take(2).join(':'),
    );
  }
}