class DoctorProfileModel {
  final String firstName;
  final String lastName;
  final String email;
  final String phoneNumber;
  final String address;
  final int experienceYears;
  final String education;
  final String? profilePicture;
  final String? cv;

  DoctorProfileModel({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phoneNumber,
    required this.address,
    required this.experienceYears,
    required this.education,
    this.profilePicture,
    this.cv,
  });

  String get fullName => '$firstName $lastName';

  factory DoctorProfileModel.fromJson(Map<String, dynamic> json) {
    final user = json['user'] ?? json;
    return DoctorProfileModel(
      firstName: user['first_name']?.toString() ?? '',
      lastName: user['last_name']?.toString() ?? '',
      email: user['email']?.toString() ?? '',
      phoneNumber: user['phone_number']?.toString() ?? '',
      address: user['address']?.toString() ?? '',
      // 👈 استخدام int.tryParse المتوافق مع باقي نماذج تطبيق الطبيب
      experienceYears: int.tryParse(user['experience_years']?.toString() ?? '0') ?? 0,
      education: user['education']?.toString() ?? '',
      profilePicture: user['profile_picture']?.toString(),
      cv: user['cv']?.toString(),
    );
  }
}