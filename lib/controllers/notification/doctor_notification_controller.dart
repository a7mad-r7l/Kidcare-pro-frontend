import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../core/repos/notification/doctor_notification_repo.dart';
import '../../models/notification/doctor_notification_model.dart';
import '../base_controller.dart';
import '../home/home_controller.dart';

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

  // 👈 الدالة المسؤولة عن التوجيه عند الضغط على إشعار من داخل التطبيق
  void handleNotificationTap(DoctorNotificationModel notification) {
    final titleLower = notification.title.toLowerCase();

    Get.offAllNamed(
      '/doctor_home',
    ); // العودة للرئيسية أولاً لضمان وجود الـ HomeController

    Future.delayed(const Duration(milliseconds: 300), () {
      if (Get.isRegistered<HomeController>()) {
        final homeCtrl = Get.find<HomeController>();
        homeCtrl.fetchAllDashboardData(); // تحديث البيانات

        // تحليل العنوان وتوجيه الطبيب للتاب المناسب
        if (titleLower.contains('cancel') ||
            titleLower.contains('appointment')) {
          homeCtrl.currentIndex.value = 1; // توجيه لتاب الجدول (Schedule)
        } else if (titleLower.contains('arrived')) {
          homeCtrl.currentIndex.value =
              0; // توجيه لتاب الرئيسية (Dashboard) لرؤية المريض المنتظر
        }
      }
    });
  }
}
