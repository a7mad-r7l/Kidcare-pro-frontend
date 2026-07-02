import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:get/get.dart';
import '../../constants.dart';

class PasswordResetApi {
  Map<String, String> _getHeaders() {
    final String currentLocale = Get.locale?.languageCode ?? 'en';
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Accept-Language': currentLocale,
    };
  }

  Future<http.Response> sendOtp(String phone) async {
    return await http.post(
      Uri.parse('$baseUrl/api/sendOtpDoctor'),
      headers: _getHeaders(),
      body: jsonEncode({'phone_number': phone}),
    ).timeout(const Duration(seconds: 15));
  }

  Future<http.Response> verifyOtp(String phone, String otp) async {
    return await http.post(
      Uri.parse('$baseUrl/api/verifyOtpDoctor'),
      headers: _getHeaders(),
      body: jsonEncode({'phone_number': phone, 'otp': otp}),
    ).timeout(const Duration(seconds: 15));
  }

  Future<http.Response> setPassword(String phone, String password, String passwordConfirmation) async {
    return await http.post(
      Uri.parse('$baseUrl/api/SetPasswordDoctor'),
      headers: _getHeaders(),
      body: jsonEncode({
        'phone_number': phone,
        'password': password,
        'password_confirmation': passwordConfirmation,
      }),
    ).timeout(const Duration(seconds: 15));
  }
}