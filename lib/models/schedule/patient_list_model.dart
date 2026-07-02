class PatientListModel {
  final int id;
  final String name;
  final int age;
  final String gender;
  final String image;
  final String parentPhone;
  final String fileNumber;

  PatientListModel({
    required this.id,
    required this.name,
    required this.age,
    required this.gender,
    required this.image,
    required this.parentPhone,
    required this.fileNumber,
  });

  factory PatientListModel.fromJson(Map<String, dynamic> json) {
    // استخراج وتنظيف مسار الصورة
    String rawImage = json['image']?.toString() ?? '';
    if (rawImage.contains('http')) {
      final parts = rawImage.split('8000/');
      rawImage = parts.length > 1 ? parts.last : rawImage;
    }

    return PatientListModel(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? '',
      age: int.tryParse(json['age']?.toString() ?? '0') ?? 0,
      gender: json['gender']?.toString() ?? 'male',
      image: rawImage,
      parentPhone: json['parent_phone']?.toString() ?? '',
      // قيمة مؤقتة لرقم الملف
      fileNumber: 'PT-2024-${json['id']}',
    );
  }
}