import 'package:http/http.dart' as http;

import 'package:get/get.dart';
import '../../constants.dart';
import '../../helper/secure_storage_service.dart';

class HomeApi {
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

  Future<String> getDoctorHome() async {
    return (await http.get(Uri.parse('$baseUrl/api/doctor/home'), headers: await _getHeaders())).body;
  }

  Future<String> getTodayAppointmentsCount() async {
    return (await http.get(Uri.parse('$baseUrl/api/doctor/today-appointments-count'), headers: await _getHeaders())).body;
  }

  Future<String> getNextPatient() async {
    return (await http.get(Uri.parse('$baseUrl/api/doctor/next-patient'), headers: await _getHeaders())).body;
  }

  Future<String> getRemainingPatients() async {
    return (await http.get(Uri.parse('$baseUrl/api/doctor/remaining-patients'), headers: await _getHeaders())).body;
  }

  // ─── مسار جديد: جلب المواعيد حسب التاريخ المحدد ───
  Future<String> getAppointmentsByDate(String date) async {
    return (await http.get(Uri.parse('$baseUrl/api/doctor/appointmentsByDate?date=$date'), headers: await _getHeaders())).body;
  }

  Future<String> getCompletedAppointmentsToday() async {
    return (await http.get(Uri.parse('$baseUrl/api/doctor/completed-appointments-today'), headers: await _getHeaders())).body;
  }

  Future<String> getMonthlyRevenue() async {
    return (await http.get(Uri.parse('$baseUrl/api/doctor/monthlyRevenue'), headers: await _getHeaders())).body;
  }

  Future<String> completeAppointment(int appointmentId) async {
    return (await http.get(Uri.parse('$baseUrl/api/doctors/$appointmentId/completeAppointment'), headers: await _getHeaders())).body;
  }
  // DELETE ACCOUNT
  Future<String> deleteDoctorAccount() async {
    final response = await http.delete(
      Uri.parse('$baseUrl/api/doctor/account/terminate'),
      headers: await _getHeaders(),
    ).timeout(const Duration(seconds: 15));

    return response.body;
  }
}