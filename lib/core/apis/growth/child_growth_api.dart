// File: lib/core/apis/growth/child_growth_api.dart
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../../../core/constants.dart';
import '../../helper/secure_storage_service.dart';

class ChildGrowthApi {
  /// 1. show child growth (GET)
  Future<http.Response> getGrowthData(int childId) async {
    final token = await SecureStorage.getToken();
    if (token.isEmpty) {
      throw Exception('Session expired. Please login again.'.tr);
    }

    final url = Uri.parse('$baseUrl/api/children/$childId/growth');
    print('🌐 Requesting Growth URL: $url');

    // استخدام http.get مباشرة مع تحديد وقت أقصى (Timeout) لمنع تعليق التطبيق
    final response = await http.get(
      url,
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
        'Accept-Language': Get.locale?.languageCode ?? 'en',
      },
    ).timeout(const Duration(seconds: 15));

    print('📥 Growth Status: ${response.statusCode}');
    print('📥 Growth Body: ${response.body}');

    return response;
  }
}