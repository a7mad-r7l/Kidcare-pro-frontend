import 'dart:convert';
import '../../../models/schedule/schedule_model.dart';
import '../../apis/schedule/schedule_api.dart';

class ScheduleRepo {
  final ScheduleApi api;
  ScheduleRepo({required this.api});

  Future<ScheduleDataModel> getSchedule(String date) async {
    final res = await api.getAppointmentsByDate(date);

    String cleanRes = res;
    if (cleanRes.contains('{')) {
      cleanRes = cleanRes.substring(cleanRes.indexOf('{'));
    }

    final decoded = jsonDecode(cleanRes);

    // تم التعديل للتحقق من status: success والدخول إلى كائن data
    if (decoded['status'] == 'success' && decoded['data'] != null) {
      return ScheduleDataModel.fromJson(decoded['data']);
    } else {
      throw Exception(decoded['message'] ?? 'Failed to fetch schedule');
    }
  }

  Future<List<DateTime>> getWorkingDays() async {
    final res = await api.getUpcomingWorkingDays();

    String cleanRes = res;
    if (cleanRes.contains('{')) {
      cleanRes = cleanRes.substring(cleanRes.indexOf('{'));
    }

    final decoded = jsonDecode(cleanRes);
    if (decoded['status'] == 'success' && decoded['days'] != null) {
      final List daysList = decoded['days'];
      return daysList.map((e) => DateTime.parse(e['date'].toString())).toList();
    }
    return [];
  }
}