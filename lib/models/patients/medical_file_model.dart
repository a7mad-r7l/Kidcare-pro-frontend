class MedicalFileModel {
  final PatientInfo patientInfo;
  final MedicalSummary summary;

  MedicalFileModel({required this.patientInfo, required this.summary});

  factory MedicalFileModel.fromJson(Map<String, dynamic> json) {
    return MedicalFileModel(
      patientInfo: PatientInfo.fromJson(json['patient_info'] ?? {}),
      summary: MedicalSummary.fromJson(json['summary'] ?? {}),
    );
  }
}

class PatientInfo {
  final int id;
  final String name;
  final int age;
  final String gender;
  final String fileNumber;
  final String image;

  PatientInfo({
    required this.id,
    required this.name,
    required this.age,
    required this.gender,
    required this.fileNumber,
    required this.image,
  });

  factory PatientInfo.fromJson(Map<String, dynamic> json) {
    String rawImage = json['image']?.toString() ?? '';
    if (rawImage.contains('http')) {
      final parts = rawImage.split('8000/');
      rawImage = parts.length > 1 ? parts.last : rawImage;
    }

    return PatientInfo(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? '',
      age: int.tryParse(json['age']?.toString() ?? '0') ?? 0,
      gender: json['gender']?.toString() ?? 'male',
      fileNumber: json['file_number']?.toString() ?? '',
      image: rawImage,
    );
  }
}

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
      weight: json['weight']?.toString() ?? '',
      weightStatus: json['weight_status']?.toString() ?? '',
      height: json['height']?.toString() ?? '',
      heightStatus: json['height_status']?.toString() ?? '',
      bloodType: json['blood_type']?.toString() ?? '',
      allergies: json['allergies']?.toString() ?? '',
      lastVisit: json['last_visit'] != null ? VisitModel.fromJson(json['last_visit']) : null,
      previousVisits: previousList.map((e) => VisitModel.fromJson(e)).toList(),
    );
  }
}

class VisitModel {
  final String date;
  final String doctorName;
  final String diagnosis;

  VisitModel({required this.date, required this.doctorName, required this.diagnosis});

  factory VisitModel.fromJson(Map<String, dynamic> json) {
    return VisitModel(
      date: json['date']?.toString() ?? '',
      doctorName: json['doctor_name']?.toString() ?? '',
      diagnosis: json['diagnosis']?.toString() ?? '',
    );
  }
}