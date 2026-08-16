import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import '../../constants.dart';
import '../../helper/secure_storage_service.dart';

class DoctorProfileApi {
  final http.Client client = http.Client();

  Future<String> getProfile() async {
    final token = await SecureStorage.getToken();

    final response = await client
        .get(
          Uri.parse('$baseUrl/api/doctor/profile'),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
            'Accept-Language': Get.locale?.languageCode ?? 'en',
          },
        )
        .timeout(const Duration(seconds: 15));

    return response.body;
  }

  Future<String> updateProfile(Map<String, dynamic> updatedData) async {
    final token = await SecureStorage.getToken();

    final response = await client
        .put(
          Uri.parse('$baseUrl/api/doctor/updateProfile'),
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
            'Accept-Language': Get.locale?.languageCode ?? 'en',
          },
          body: json.encode(updatedData),
        )
        .timeout(const Duration(seconds: 15));

    return response.body;
  }
}
