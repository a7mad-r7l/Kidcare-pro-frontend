// File: lib/core/apis/patients/medical_file_api.dart
import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import '../../constants.dart';
import '../../helper/secure_storage_service.dart';

class MedicalFileApi {
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

  Future<String> getMedicalFile(int patientId) async {
    // 👈 تم تحديث المسار بناءً على الـ Postman الجديد
    final url = Uri.parse('$baseUrl/api/doctor/patient-visits/$patientId');

    print('🌐 Requesting Medical File URL: $url');
    final response = await http.get(url, headers: await _getHeaders());

    return response.body;
  }
}