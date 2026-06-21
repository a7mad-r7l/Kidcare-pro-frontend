class DoctorInfoModel {
  final int id;
  final String name;
  final String specialization;
  final String image;

  DoctorInfoModel({required this.id, required this.name, required this.specialization, required this.image});

  factory DoctorInfoModel.fromJson(Map<String, dynamic> json) {
    return DoctorInfoModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? '',
      specialization: json['specialization']?.toString() ?? '',
      image: json['image']?.toString() ?? '',
    );
  }
}