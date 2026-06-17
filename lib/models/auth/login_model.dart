class LoginModel {
  final String status;
  final String message;
  final String token;

  LoginModel({
    required this.status,
    required this.message,
    required this.token,
  });

  factory LoginModel.fromJson(Map<String, dynamic> json) {
    return LoginModel(
      status: json['status']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      token: json['Token']?.toString() ?? json['token']?.toString() ?? '',
    );
  }
}