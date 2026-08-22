// File: lib/models/patients/medical_file_model.dart
// 👈 تم إزالة MedicalFileModel و PatientInfo لأنها لم تعد تأتي من الخادم

class MedicalSummary {
  final String weight;
  final String weightStatus;
  final String height;
  final String heightStatus;
  final String bloodType;
  final String allergies;
  final VisitModel? lastVisit;
  final List<VisitModel> previousVisits;

  MedicalSummary({
    required this.weight,
    required this.weightStatus,
    required this.height,
    required this.heightStatus,
    required this.bloodType,
    required this.allergies,
    this.lastVisit,
    required this.previousVisits,
  });

  factory MedicalSummary.fromJson(Map<String, dynamic> json) {
    var previousList = json['previous_visits'] as List? ?? [];
    return MedicalSummary(
      // 👈 تحويل الأرقام إلى نصوص ومعالجة الـ null
      weight: json['weight']?.toString() ?? '0',
      weightStatus: json['weight_status']?.toString() ?? '',
      height: json['height']?.toString() ?? '0',
      heightStatus: json['height_status']?.toString() ?? '',
      bloodType: json['blood_type']?.toString() ?? '',
      allergies: json['allergies']?.toString() ?? 'None',
      // 👈 التحقق من وجود بيانات داخل last_visit قبل تحويلها
      lastVisit: (json['last_visit'] != null && json['last_visit']['date'] != null)
          ? VisitModel.fromJson(json['last_visit'])
          : null,
      previousVisits: previousList.map((e) => VisitModel.fromJson(e)).toList(),
    );
  }
}

class VisitModel {
  final String date;
  final String doctorName;
  final String diagnosis;
  final int recordId;      // 👈 تمت الإضافة
  final int appointmentId; // 👈 تمت الإضافة

  VisitModel({
    required this.date,
    required this.doctorName,
    required this.diagnosis,
    required this.recordId,
    required this.appointmentId,
  });

  factory VisitModel.fromJson(Map<String, dynamic> json) {
    return VisitModel(
      date: json['date']?.toString() ?? '',
      doctorName: json['doctor_name']?.toString() ?? '',
      diagnosis: json['diagnosis']?.toString() ?? 'None',
      recordId: int.tryParse(json['record_id']?.toString() ?? '0') ?? 0,
      appointmentId: int.tryParse(json['appointment_id']?.toString() ?? '0') ?? 0,
    );
  }
}