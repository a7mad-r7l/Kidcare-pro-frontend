import 'dart:convert';
import '../../../models/home/doctor_dashboard_model.dart';
import '../../apis/home/home_api.dart';

class HomeRepo {
  final HomeApi api;
  HomeRepo({required this.api});

  // ─── الحل الجذري لمشكلة قص الـ JSON غير الصالح ───
  String _cleanJson(String response) {

    final brace = response.indexOf('{');
    final bracket = response.indexOf('[');
    // ابدأ من أول قوس يظهر فعليًا (كائن أو مصفوفة) حتى لا نقصّ مصفوفة تبدأ بـ [.
    if (bracket != -1 && (brace == -1 || bracket < brace)) {
      return response.substring(bracket);
    }
    if (brace != -1) return response.substring(brace);

    final startIndex = response.indexOf(RegExp(r'[\{\[]'));
    if (startIndex != -1) {
      return response.substring(startIndex);
    }

    return response;
  }

  Future<DoctorHomeModel> getDoctorHome() async {
    final res = await api.getDoctorHome();
    return DoctorHomeModel.fromJson(jsonDecode(_cleanJson(res)));
  }

  Future<int> getTodayAppointmentsCount() async {
    final res = await api.getTodayAppointmentsCount();
    return jsonDecode(_cleanJson(res))['count'] ?? 0;
  }

  Future<PatientModel?> getNextPatient() async {
    final res = await api.getNextPatient();
    final decoded = jsonDecode(_cleanJson(res));
    if (decoded['message'] == 'No upcoming patients') return null;
    return PatientModel.fromJson(decoded);
  }

  Future<List<PatientModel>> getRemainingPatients() async {
    final res = await api.getRemainingPatients();
    final decoded = jsonDecode(_cleanJson(res));
    if (decoded is List) {
      return decoded.map((e) => PatientModel.fromJson(e)).toList();
    }
    return [];
  }

  // ─── جلب وتحليل المواعيد حسب التاريخ للـ Picker ───
  Future<List<PatientModel>> getAppointmentsByDate(String date) async {
    final res = await api.getAppointmentsByDate(date);
    final decoded = jsonDecode(_cleanJson(res));
    if (decoded['status'] == 'success' && decoded['data'] != null && decoded['data']['appointments'] is List) {
      return (decoded['data']['appointments'] as List).map((e) => PatientModel.fromJson(e)).toList();
    }
    return [];
  }

  Future<int> getCompletedAppointmentsToday() async {
    final res = await api.getCompletedAppointmentsToday();
    return jsonDecode(_cleanJson(res))['completed_appointments'] ?? 0;
  }

  Future<double> getMonthlyRevenue() async {
    final res = await api.getMonthlyRevenue();
    return double.tryParse(jsonDecode(_cleanJson(res))['monthly_revenue']?.toString() ?? '0') ?? 0.0;
  }

  Future<String> completeAppointment(int id) async {
    final res = await api.completeAppointment(id);
    return jsonDecode(_cleanJson(res))['message'] ?? 'Success';
  }
}