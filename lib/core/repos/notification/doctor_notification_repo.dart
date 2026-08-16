import 'dart:convert';
import '../../../models/notification/doctor_notification_model.dart';
import '../../apis/notification/doctor_notification_api.dart';

class DoctorNotificationRepo {
  final DoctorNotificationApi api;

  DoctorNotificationRepo({required this.api});

  String _cleanJson(String response) {
    final startIndex = response.indexOf(RegExp(r'[\{\[]'));
    if (startIndex != -1) return response.substring(startIndex);
    return response;
  }

  Future<List<DoctorNotificationModel>> getNotifications() async {
    final res = await api.getNotifications();
    final decoded = jsonDecode(_cleanJson(res));

    if (decoded['status'] == 'success' && decoded['notifications'] is List) {
      return (decoded['notifications'] as List)
          .map((item) => DoctorNotificationModel.fromJson(item))
          .toList();
    }
    return [];
  }
}
