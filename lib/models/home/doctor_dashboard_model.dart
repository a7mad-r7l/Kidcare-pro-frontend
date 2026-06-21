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
  final String name;
  final int age;
  final String gender;
  final String image;
  final String appointmentTime;

  PatientModel({
    required this.id,
    required this.name,
    required this.age,
    required this.gender,
    required this.image,
    required this.appointmentTime,
  });

  factory PatientModel.fromJson(Map<String, dynamic> json) {
    return PatientModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? '',
      age: json['age'] is int ? json['age'] : int.tryParse(json['age']?.toString() ?? '0') ?? 0,
      gender: json['gender']?.toString() ?? 'male',
      image: json['image']?.toString() ?? '',
      appointmentTime: json['appointment_time']?.toString() ?? '',
    );
  }
}