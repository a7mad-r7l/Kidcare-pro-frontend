import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import '../../constants.dart';
import '../../helper/secure_storage_service.dart';

class PatientsApi {
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

  Future<String> getAllPatients({String? query}) async {
    String urlStr = '$baseUrl/api/doctor/patients';
    if (query != null && query.trim().isNotEmpty) {
      urlStr += '?search=${query.trim()}';
    }
    final url = Uri.parse(urlStr);
    final response = await http.get(url, headers: await _getHeaders());
    return response.body;
  }
}