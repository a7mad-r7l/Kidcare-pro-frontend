import 'dart:convert';
import '../../apis/auth/password_reset_api.dart';

class PasswordResetRepo {
  final PasswordResetApi api;
  PasswordResetRepo({required this.api});

  String _cleanJson(String response) {
    if (response.contains('{')) return response.substring(response.indexOf('{'));
    return response;
  }

  void _handleErrorResponse(int statusCode, String body) {
    if (statusCode != 200 && statusCode != 201) {
      final decoded = jsonDecode(_cleanJson(body));
      throw Exception(decoded['message'] ?? 'An error occurred');
    }
  }

  Future<String> sendOtp(String phone) async {
    final res = await api.sendOtp(phone);
    _handleErrorResponse(res.statusCode, res.body);
    return jsonDecode(_cleanJson(res.body))['message'] ?? 'OTP sent';
  }

  Future<String> verifyOtp(String phone, String otp) async {
    final res = await api.verifyOtp(phone, otp);
    _handleErrorResponse(res.statusCode, res.body);
    return jsonDecode(_cleanJson(res.body))['message'] ?? 'Verified successfully';
  }

  Future<String> setPassword(String phone, String password, String confirmation) async {
    final res = await api.setPassword(phone, password, confirmation);
    _handleErrorResponse(res.statusCode, res.body);
    return jsonDecode(_cleanJson(res.body))['message'] ?? 'Password updated';
  }
}