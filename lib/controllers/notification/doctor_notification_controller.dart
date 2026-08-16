import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../core/repos/notification/doctor_notification_repo.dart';
import '../../models/notification/doctor_notification_model.dart';
import '../base_controller.dart';

class DoctorNotificationController extends BaseController {
  final DoctorNotificationRepo repo;

  DoctorNotificationController({required this.repo});

  final notifications = <DoctorNotificationModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchNotifications();
  }

  Future<void> fetchNotifications() async {
    showLoading();
    try {
      final list = await repo.getNotifications();
      notifications.assignAll(list);
    } catch (e) {
      handleError(e);
    } finally {
      hideLoading();
    }
  }

  String formatDateTime(String rawDate) {
    if (rawDate.isEmpty) return '';
    try {
      final parsed = DateTime.parse(rawDate).toLocal();
      return DateFormat(
        'yyyy-MM-dd • hh:mm a',
        Get.locale?.languageCode ?? 'en',
      ).format(parsed);
    } catch (_) {
      return rawDate;
    }
  }
}
