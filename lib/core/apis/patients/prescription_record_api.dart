import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import '../../../core/constants.dart';
import '../../helper/secure_storage_service.dart';

class PrescriptionRecordApi {
  Future<Map<String, String>> _getHeaders() async {
    final token = await SecureStorage.getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Accept-Language': Get.locale?.languageCode ?? 'en',
      'Authorization': 'Bearer $token',
    };
  }

  Future<http.Response> getPrescription(int recordId) async {
    final url = Uri.parse('$baseUrl/api/prescription/$recordId');
    return await http.get(url, headers: await _getHeaders()).timeout(const Duration(seconds: 15));
  }

  Future<http.Response> getMedicalRecord(int appointmentId) async {
    final url = Uri.parse('$baseUrl/api/medical-record/$appointmentId');
    return await http.get(url, headers: await _getHeaders()).timeout(const Duration(seconds: 15));
  }
}