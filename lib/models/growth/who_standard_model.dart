import '../../core/helper/json_utils.dart';

class WhoStandardModel {
  final int ageInMonths;
  final double whoMinWeight;
  final double whoIdeal;
  final double whoMaxWeight;

  const WhoStandardModel({
    required this.ageInMonths,
    required this.whoMinWeight,
    required this.whoIdeal,
    required this.whoMaxWeight,
  });

  factory WhoStandardModel.fromJson(Map<String, dynamic> json) {
    return WhoStandardModel(
      ageInMonths: toIntSafe(json['age_in_months']),
      whoMinWeight: toDoubleOrNull(json['who_min_weight']) ?? 0.0,
      whoIdeal: toDoubleOrNull(json['who_ideal']) ?? 0.0,
      whoMaxWeight: toDoubleOrNull(json['who_max_weight']) ?? 0.0,
    );
  }
}
