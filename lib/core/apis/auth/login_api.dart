import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:get/get.dart';
import '../../constants.dart';

class LoginApi {
  Future<String> login({required String phone, required String password}) async {
    final url = Uri.parse('$baseUrl/api/loginDoctor');
    final String currentLocale = Get.locale?.languageCode ?? 'en';

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Accept-Language': currentLocale,
      },

      body: jsonEncode({
        'phone_number': phone,
        'password': password,
      }),
    ).timeout(const Duration(seconds: 15));

    return response.body;
  }
}