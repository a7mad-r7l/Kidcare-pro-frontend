class MedicalRecordModel {
  final int id;
  final int appointmentId;
  final String diagnosis;
  final String doctorNotes;

  MedicalRecordModel({
    required this.id,
    required this.appointmentId,
    required this.diagnosis,
    required this.doctorNotes,
  });

  factory MedicalRecordModel.fromJson(Map<String, dynamic> json) {
    return MedicalRecordModel(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      appointmentId: int.tryParse(json['appointment_id']?.toString() ?? '0') ?? 0,
      diagnosis: json['diagnosis']?.toString() ?? 'None',
      doctorNotes: json['doctor_notes']?.toString() ?? '',
    );
  }
}

class PrescriptionModel {
  final int recordId;
  final int appointmentId;
  final String doctorName;
  final List<MedicationItemModel> medications;

  PrescriptionModel({
    required this.recordId,
    required this.appointmentId,
    required this.doctorName,
    required this.medications,
  });

  factory PrescriptionModel.fromJson(Map<String, dynamic> json) {
    final doc = json['doctor'] ?? {};
    final medsList = json['medications'] as List? ?? [];

    return PrescriptionModel(
      recordId: int.tryParse(json['record_id']?.toString() ?? '0') ?? 0,
      appointmentId: int.tryParse(json['appointment_id']?.toString() ?? '0') ?? 0,
      doctorName: doc['name']?.toString() ?? '',
      medications: medsList.map((e) => MedicationItemModel.fromJson(e)).toList(),
    );
  }
}

class MedicationItemModel {
  final int id;
  final String name;
  final String dosage;
  final String frequency;
  final String timing;
  final String duration;

  MedicationItemModel({
    required this.id,
    required this.name,
    required this.dosage,
    required this.frequency,
    required this.timing,
    required this.duration,
  });

  factory MedicationItemModel.fromJson(Map<String, dynamic> json) {
    return MedicationItemModel(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? '',
      dosage: json['dosage']?.toString() ?? '',
      frequency: json['frequency']?.toString() ?? '',
      timing: json['timing']?.toString() ?? '',
      duration: json['duration']?.toString() ?? '',
    );
  }
}