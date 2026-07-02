class DiagnosisRecordModel {
  final int id;
  final int appointmentId;
  final String diagnosis;
  final String doctorNotes;

  DiagnosisRecordModel({
    required this.id,
    required this.appointmentId,
    required this.diagnosis,
    required this.doctorNotes,
  });

  factory DiagnosisRecordModel.fromJson(Map<String, dynamic> json) {
    return DiagnosisRecordModel(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      appointmentId: json['appointment_id'] is int
          ? json['appointment_id']
          : int.tryParse(json['appointment_id']?.toString() ?? '0') ?? 0,
      diagnosis: json['diagnosis']?.toString() ?? '',
      doctorNotes: json['doctor_notes']?.toString() ?? '',
    );
  }
}
