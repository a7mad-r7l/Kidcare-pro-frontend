import '../../core/helper/json_utils.dart';
import 'growth_record_model.dart';
import 'who_standard_model.dart';

class ChildGrowthResponseModel {
  final String childName;
  final String childGender;
  final double currentAgeMonths;
  final List<GrowthRecordModel> growthHistory;
  final List<WhoStandardModel> whoStandards;

  const ChildGrowthResponseModel({
    required this.childName,
    required this.childGender,
    required this.currentAgeMonths,
    required this.growthHistory,
    required this.whoStandards,
  });

  factory ChildGrowthResponseModel.fromJson(Map<String, dynamic> json) {
    return ChildGrowthResponseModel(
      childName: json['child_name']?.toString() ?? '',
      childGender: json['child_gender']?.toString() ?? 'male',
      currentAgeMonths: toDoubleOrNull(json['current_age_months']) ?? 0.0,
      growthHistory:
          (json['growth_history'] as List?)
              ?.map(
                (e) => GrowthRecordModel.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
      whoStandards:
          (json['who_standards'] as List?)
              ?.map((e) => WhoStandardModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
