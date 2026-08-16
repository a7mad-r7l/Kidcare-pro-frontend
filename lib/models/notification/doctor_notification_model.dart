class DoctorNotificationModel {
  final int id;
  final String title;
  final String message;
  final String createdAt;

  DoctorNotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.createdAt,
  });

  factory DoctorNotificationModel.fromJson(Map<String, dynamic> json) {
    return DoctorNotificationModel(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      title: json['title']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      createdAt: json['created_at']?.toString() ?? '',
    );
  }
}