import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:get/get.dart';
import '../../constants.dart';
import '../../helper/secure_storage_service.dart';

class InvoiceApi {
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

  // تفاصيل الموعد — منها تُقرأ أجرة الكشف والعملة (لا يوجد مسار مستقل للأجرة)
  Future<http.Response> getAppointment(int appointmentId) async {
    return await http
        .get(
          Uri.parse('$baseUrl/api/doctor/appointments/$appointmentId'),
          headers: await _getHeaders(),
        )
        .timeout(const Duration(seconds: 15));
  }

  // إضافة خدمة واحدة — لا يوجد إرسال جماعي، فكل خدمة نداء مستقل
  Future<http.Response> addAddition(
    int appointmentId, {
    required String itemName,
    required num price,
  }) async {
    return await http
        .post(
          Uri.parse('$baseUrl/api/doctor/$appointmentId/additions'),
          headers: await _getHeaders(),
          body: jsonEncode({'item_name': itemName, 'price': price}),
        )
        .timeout(const Duration(seconds: 15));
  }

  // حذف خدمة — تنبيه: المعرف في المسار هو معرف الإضافة (additions[].id)
  // وليس معرف الموعد، خلافاً لبقية مسارات هذا التدفق.
  Future<http.Response> deleteAddition(int additionId) async {
    return await http
        .delete(
          Uri.parse('$baseUrl/api/doctor/$additionId/additions'),
          headers: await _getHeaders(),
        )
        .timeout(const Duration(seconds: 15));
  }
}
