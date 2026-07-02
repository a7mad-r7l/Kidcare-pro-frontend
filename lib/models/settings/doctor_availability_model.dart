class DoctorAvailabilityModel {
  final String status;
  final String message;
  final int availabilityId;

  DoctorAvailabilityModel({
    required this.status,
    required this.message,
    required this.availabilityId,
  });

  factory DoctorAvailabilityModel.fromJson(Map<String, dynamic> json) {
    return DoctorAvailabilityModel(
      status: json['status']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      availabilityId: json['availability'] != null
          ? (json['availability']['id'] is int ? json['availability']['id'] : int.tryParse(json['availability']['id'].toString()) ?? 0)
          : 0,
    );
  }
}