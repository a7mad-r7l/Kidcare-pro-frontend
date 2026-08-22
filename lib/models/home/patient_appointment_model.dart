class PatientAppointmentModel {
  final int appointmentId; // 👈 نعتمد على هذا بعد التعديل
  final int childId;
  final String name;
  final String age;
  final String gender;
  final String image;
  final String appointmentTime;
  final String status;

  PatientAppointmentModel({
    required this.appointmentId,
    required this.childId,
    required this.name,
    required this.age,
    required this.gender,
    required this.image,
    required this.appointmentTime, required this.status,
  });

  factory PatientAppointmentModel.fromJson(Map<String, dynamic> json) {
    return PatientAppointmentModel(
      // قمت ببرمجتها بمرونة؛ لو أرسل الباك إند appointment_id سيأخذها، وإلا سيعتبر الـ id هو الموعد مؤقتاً
      appointmentId: int.tryParse(json['appointment_id']?.toString() ?? json['id']?.toString() ?? '0') ?? 0,
      childId: int.tryParse(json['child_id']?.toString() ?? json['id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? '',
      age: json['age']?.toString() ?? '',
      gender: json['gender']?.toString() ?? '',
      image: json['image']?.toString() ?? '',
      appointmentTime: json['appointment_time']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
    );
  }
}