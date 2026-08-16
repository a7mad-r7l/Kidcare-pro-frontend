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

  Future<http.Response> addAvailability({
    required String dayOfWeek,
    required String startTime,
    required String endTime,
  }) async {
    final url = Uri.parse('$baseUrl/api/doctor-availabilities');

    final response = await http
        .post(
          url,
          headers: await _getHeaders(),
          body: jsonEncode({
            'day_of_week': dayOfWeek,
            'start_time': startTime,
            'end_time': endTime,
          }),
        )
        .timeout(const Duration(seconds: 20));

    return response;
  }

  // GET
  Future<http.Response> getAvailabilities(int doctorId) async {
    return await http
        .get(
          Uri.parse('$baseUrl/api/doctors/$doctorId/availabilities'),
          headers: await _getHeaders(),
        )
        .timeout(const Duration(seconds: 20));
  }

  // DELETE
  Future<http.Response> deleteAvailability(int id) async {
    return await http
        .delete(
          Uri.parse('$baseUrl/api/doctor/availability/$id'),
          headers: await _getHeaders(),
        )
        .timeout(const Duration(seconds: 20));
  }

  Future<http.Response> deleteAppointmentsByDate( String date) async {
    final url = Uri.parse('$baseUrl/api/doctor/appointments/cancelAppointments');
    final response = await http
        .put(
          url,
          headers: await _getHeaders(),
          body: jsonEncode({'date': date}),
        )
        .timeout(const Duration(seconds: 20));

    return response;
  }
}
