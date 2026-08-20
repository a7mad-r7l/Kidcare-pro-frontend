import '../../core/helper/json_utils.dart';

class GrowthRecordModel {
  final int id;
  final double height;
  final double weight;
  final String date;
  final int ageInMonths; // الباك إند يعيدها كـ double في حقل القياس
  final double bmi;
  final String statusText;
  final String statusColor;

  const GrowthRecordModel({
    required this.id,
    required this.height,
    required this.weight,
    required this.date,
    required this.ageInMonths,
    required this.bmi,
    required this.statusText,
    required this.statusColor,
  });

  factory GrowthRecordModel.fromJson(Map<String, dynamic> json) {
    return GrowthRecordModel(
      id: toIntSafe(json['id']),
      height: toDoubleOrNull(json['height']) ?? 0.0,
      weight: toDoubleOrNull(json['weight']) ?? 0.0,
      date: json['date']?.toString() ?? json['record_date']?.toString() ?? '',

      ageInMonths: toIntSafe(json['age_in_months'] ?? json['age']),
      bmi: toDoubleOrNull(json['bmi']) ?? 0.0,
      statusText: json['status_text']?.toString() ?? 'Normal',
      statusColor: json['status_color']?.toString() ?? '#4CAF50',
    );
  }
}
