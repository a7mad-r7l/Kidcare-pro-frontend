import 'dart:convert';
import '../../../models/schedule/appointment_details_model.dart';
import '../../apis/schedule/appointment_details_api.dart';
import 'package:get/get.dart';

class AppointmentDetailsRepo {
  final AppointmentDetailsApi api;
  AppointmentDetailsRepo({required this.api});

  Future<AppointmentDetailsModel> getDetails(int id) async {
    final res = await api.getAppointmentDetails(id);

    String cleanRes = res;
    if (cleanRes.contains('{')) {
      cleanRes = cleanRes.substring(cleanRes.indexOf('{'));
    }

    final decoded = jsonDecode(cleanRes);

    if (decoded['status'] == true && decoded['data'] != null) {
      return AppointmentDetailsModel.fromJson(decoded['data']);
    } else {
      throw Exception(decoded['message'] ?? 'Failed to fetch details');
    }
  }

  // ───  إلغاء الموعد ───
  Future<String> cancelAppointment(int id) async {
    final res = await api.cancelAppointment(id);

    String cleanRes = res;
    if (cleanRes.contains('{')) {
      cleanRes = cleanRes.substring(cleanRes.indexOf('{'));
    }

    final decoded = jsonDecode(cleanRes);

    if (decoded['status'] == 'success') {
      return decoded['message'] ?? 'Appointment cancelled successfully'.tr;
    } else {
      throw Exception(decoded['message'] ?? 'Failed to cancel appointment');
    }
  }
}