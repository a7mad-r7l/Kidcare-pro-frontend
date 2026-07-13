class AvailabilityItemModel {
  final int id;
  final int doctorId;
  final String dayOfWeek;
  final String startTime;
  final String endTime;

  AvailabilityItemModel({
    required this.id,
    required this.doctorId,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
  });

  factory AvailabilityItemModel.fromJson(Map<String, dynamic> json) {
    // دالة مساعدة لقص الثواني من الوقت القادم من لارافيل
    String formatTime(String time) {
      if (time.length >= 5) return time.substring(0, 5);
      return time;
    }

    return AvailabilityItemModel(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      doctorId: int.tryParse(json['doctor_id']?.toString() ?? '0') ?? 0,
      dayOfWeek: json['day_of_week']?.toString() ?? '',
      startTime: formatTime(json['start_time']?.toString() ?? ''),
      endTime: formatTime(json['end_time']?.toString() ?? ''),
    );
  }
}
