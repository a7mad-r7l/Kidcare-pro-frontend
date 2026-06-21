import 'dart:convert';
import '../../../models/home/doctor_dashboard_model.dart';
import '../../apis/home/home_api.dart';

class HomeRepo {
  final HomeApi api;
  HomeRepo({required this.api});

  String _cleanJson(String response) {
    if (response.contains('{')) return response.substring(response.indexOf('{'));
    if (response.contains('[')) return response.substring(response.indexOf('['));
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