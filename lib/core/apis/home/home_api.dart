import 'package:http/http.dart' as http;
import 'dart:convert';
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

  // 1. بيانات الطبيب العامة
  Future<String> getDoctorHome() async {
    return (await http.get(Uri.parse('$baseUrl/api/doctor/home'), headers: await _getHeaders())).body;
  }

  // 2. عدد مواعيد اليوم الكلي
  Future<String> getTodayAppointmentsCount() async {
    return (await http.get(Uri.parse('$baseUrl/api/doctor/today-appointments-count'), headers: await _getHeaders())).body;
  }

  // 3. المريض القادم (Next Patient)
  Future<String> getNextPatient() async {
    return (await http.get(Uri.parse('$baseUrl/api/doctor/next-patient'), headers: await _getHeaders())).body;
  }

  // 4. المرضى المتبقين (Remaining Patients)
  Future<String> getRemainingPatients() async {
    return (await http.get(Uri.parse('$baseUrl/api/doctor/remaining-patients'), headers: await _getHeaders())).body;
  }

  // 5. عدد المواعيد المكتملة اليوم
  Future<String> getCompletedAppointmentsToday() async {
    return (await http.get(Uri.parse('$baseUrl/api/doctor/completed-appointments-today'), headers: await _getHeaders())).body;
  }

  // 6. الأرباح الشهرية للطبيب
  Future<String> getMonthlyRevenue() async {
    return (await http.get(Uri.parse('$baseUrl/api/doctor/monthlyRevenue'), headers: await _getHeaders())).body;
  }

  // دالة إتمام الموعد
  Future<String> completeAppointment(int appointmentId) async {
    return (await http.get(Uri.parse('$baseUrl/api/doctors/$appointmentId/completeAppointment'), headers: await _getHeaders())).body;
  }
}