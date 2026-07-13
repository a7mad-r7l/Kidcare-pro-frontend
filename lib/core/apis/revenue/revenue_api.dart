import 'package:http/http.dart' as http;

import 'package:get/get.dart';
import '../../constants.dart';
import '../../helper/secure_storage_service.dart';

class RevenueApi {
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

  /// GET /api/doctor/income → returns the current month's total earnings for the
  /// logged-in doctor as `{ "monthly_income": <sum of doctor_earnings> }`.
  Future<String> getMonthlyIncome() async {
    return (await http.get(Uri.parse('$baseUrl/api/doctor/income'), headers: await _getHeaders())).body;
  }

  // TODO: implement when the backend exposes these endpoints.
  Future<String> getRevenueChartData() async => '';
  Future<String> getTotalPaidVisits() async => '';
}
