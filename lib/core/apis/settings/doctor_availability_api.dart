import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:get/get.dart';

import '../../constants.dart';
import '../../helper/secure_storage_service.dart';



class DoctorAvailabilityApi {
  Future<Map<String, String>> _getHeaders() async {
    final token = await SecureStorage.getToken();
    final String currentLocale = Get.locale?.languageCode ?? 'en';
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Accept-Language': currentLocale,
      'Authorization': 'Bearer $token',
    };
  }

  // إرسال البيانات كـ JSON مع الحقول المطلوبة في الباك إند
  Future<http.Response> addAvailability({
    required String dayOfWeek,
    required String startTime,
    required String endTime,
  }) async {
    final url = Uri.parse('$baseUrl/api/doctor-availabilities');

    final response = await http.post(
      url,
      headers: await _getHeaders(),
      body: jsonEncode({
        'day_of_week': dayOfWeek,
        'start_time': startTime,
        'end_time': endTime,
      }),
    ).timeout(const Duration(seconds: 15));

    return response;
  }
}