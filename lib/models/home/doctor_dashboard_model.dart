class DoctorHomeModel {
  final int id;
  final String name;
  final String specialization;
  final String image;

  DoctorHomeModel({required this.id, required this.name, required this.specialization, required this.image});

  factory DoctorHomeModel.fromJson(Map<String, dynamic> json) {
    return DoctorHomeModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? '',
      specialization: json['specialization']?.toString() ?? '',
      image: json['image']?.toString() ?? '',
    );
  }
}

class PatientModel {
  final int id;
  final int appointmentId;
  final String name;
  final int age;
  final String ageType;
  final String gender;
  final String image;
  final String appointmentTime;

  PatientModel({
    required this.id,
    required this.appointmentId,
    required this.name,
    required this.age,
    required this.gender,
    required this.image,
    required this.appointmentTime, required this.ageType,
  });

  factory PatientModel.fromJson(Map<String, dynamic> json) {
    return PatientModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,

      appointmentId: json['appointment_id'] is int
          ? json['appointment_id']
          : int.tryParse(json['appointment_id']?.toString() ?? '0') ?? 0,
      //name: json['name']?.toString() ?? '',

      // ─── توافقية مع مسار appointmentsByDate (patient_name) ومسار remaining (name) ───
      name: json['name']?.toString() ?? json['patient_name']?.toString() ?? '',

      age: json['age'] is int ? json['age'] : int.tryParse(json['age']?.toString() ?? '0') ?? 0,
      ageType: json['age_type']?.toString() ?? 'year',
      gender: json['gender']?.toString() ?? 'male',
      image: json['image']?.toString() ?? '',
      // ─── توافقية مع اختلاف أسماء حقول الوقت ───
      appointmentTime: json['appointment_time']?.toString() ?? json['time']?.toString() ?? '',
    );
  }
}