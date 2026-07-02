class MedicationModel {
  final int id;
  final int recordId;
  final String name;
  final String dosage;
  final String frequency;
  final String timing;
  final String duration;

  MedicationModel({
    required this.id,
    required this.recordId,
    required this.name,
    required this.dosage,
    required this.frequency,
    required this.timing,
    required this.duration,
  });

  factory MedicationModel.fromJson(Map<String, dynamic> json) {
    return MedicationModel(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      recordId: json['record_id'] is int
          ? json['record_id']
          : int.tryParse(json['record_id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? '',
      dosage: json['dosage']?.toString() ?? '',
      frequency: json['frequency']?.toString() ?? '',
      timing: json['timing']?.toString() ?? '',
      duration: json['duration']?.toString() ?? '',
    );
  }
}
