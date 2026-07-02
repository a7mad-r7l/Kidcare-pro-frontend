import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:get/get.dart';
import '../../constants.dart';
import '../../helper/secure_storage_service.dart';

class ExaminationApi {
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

  // المريض القادم (لبناء ترويسة المعاينة عند فتح الشاشة بدون تمرير المريض)
  Future<String> getNextPatient() async {
    return (await http.get(
      Uri.parse('$baseUrl/api/doctor/next-patient'),
      headers: await _getHeaders(),
    )).body;
  }

  // 1a) حفظ التشخيص السريري + ملاحظات الطبيب
  Future<String> saveDiagnosis(
    int appointmentId, {
    required String diagnosis,
    String? doctorNotes,
  }) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/api/doctor/$appointmentId/diagnosis'),
          headers: await _getHeaders(),
          body: jsonEncode({
            'diagnosis': diagnosis,
            'doctor_notes': doctorNotes,
          }),
        )
        .timeout(const Duration(seconds: 15));

    return response.body;
  }

  // 1b) حفظ القياسات (الطول والوزن)
  Future<String> saveGrowth(
    int appointmentId, {
    required num height,
    required num weight,
  }) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/api/doctor/$appointmentId/growth'),
          headers: await _getHeaders(),
          body: jsonEncode({'height': height, 'weight': weight}),
        )
        .timeout(const Duration(seconds: 15));

    return response.body;
  }

  // 2a) إضافة دواء واحد (يستخدم recordId الناتج عن حفظ التشخيص)
  Future<String> addMedication(
    int recordId, {
    required String name,
    required String dosage,
    required String frequency,
    required String timing,
    required String duration,
  }) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/api/doctor/$recordId/medications'),
          headers: await _getHeaders(),
          body: jsonEncode({
            'name': name,
            'dosage': dosage,
            'frequency': frequency,
            'timing': timing,
            'duration': duration,
          }),
        )
        .timeout(const Duration(seconds: 15));

    return response.body;
  }

  // 2b) طلب تحاليل وصور أشعة (نص حر — يُستخدم appointmentId لا recordId)
  Future<String> saveMedicalRequests(
    int appointmentId, {
    String? requiredTests,
    String? requiredImaging,
  }) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/api/doctor/$appointmentId/medicalRequests'),
          headers: await _getHeaders(),
          body: jsonEncode({
            'required_tests': requiredTests,
            'required_imaging': requiredImaging,
          }),
        )
        .timeout(const Duration(seconds: 15));

    return response.body;
  }

  // 2c) إنهاء المعاينة (لاحظ المسار /doctors/ وأنه GET بدون بادئة /doctor)
  Future<String> completeAppointment(int appointmentId) async {
    return (await http.get(
      Uri.parse('$baseUrl/api/doctors/$appointmentId/completeAppointment'),
      headers: await _getHeaders(),
    )).body;
  }
}
