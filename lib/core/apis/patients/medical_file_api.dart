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
    final url = Uri.parse('$baseUrl/api/doctor/patients/$patientId/medical-file');
    final response = await http.get(url, headers: await _getHeaders());
    return response.body;
  }
}