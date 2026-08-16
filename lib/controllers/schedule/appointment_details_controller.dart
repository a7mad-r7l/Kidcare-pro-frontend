import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:kidcare_pro/controllers/schedule/schedule_controller.dart';
import '../../core/repos/schedule/appointment_details_repo.dart';
import '../../models/schedule/appointment_details_model.dart';
import '../base_controller.dart';

class AppointmentDetailsController extends BaseController {
  final AppointmentDetailsRepo repo;

  AppointmentDetailsController({required this.repo});

  final appointmentDetails = Rxn<AppointmentDetailsModel>();
  late final int appointmentId;

  @override
  void onInit() {
    super.onInit();
    // استلام الـ ID المرسل من شاشة الجدول
    appointmentId = Get.arguments as int? ?? 0;
    if (appointmentId != 0) {
      fetchDetails();
    }
  }

  Future<void> fetchDetails() async {
    showLoading();
    try {
      final data = await repo.getDetails(appointmentId);
      appointmentDetails.value = data;
    } catch (e) {
      handleError(e);
    } finally {
      hideLoading();
    }
  }

  // ─── 1. تأكيد الإلغاء ───
  // ─── 1. إظهار نافذة تأكيد الإلغاء ───
  void confirmCancellation() {
    Get.dialog(
      AlertDialog(
        backgroundColor: Get.theme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Cancel Appointment'.tr,
          style: const TextStyle(
            color: Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text('Are you sure you want to cancel this appointment?'.tr),
        actionsPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        actions: [
          // زر الإلغاء (نظيف وبدون إطار معيب)
          TextButton(
            onPressed: () => Get.back(), // إغلاق النافذة
            style: TextButton.styleFrom(
              overlayColor: Get.theme.primaryColor.withOpacity(0.1),
            ),
            child: Text(
              'Back'.tr,
              style: TextStyle(
                color: Get.theme.primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          // زر التأكيد (أحمر)
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              Get.back(); // إغلاق النافذة
              _executeCancellation(); // استدعاء API الإلغاء
            },
            child: Text(
              'Confirm'.tr,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── 2. طلب الإلغاء ───
  Future<void> _executeCancellation() async {
    showLoading();
    try {
      final message = await repo.cancelAppointment(appointmentId);
      showSuccess(message);

      await fetchDetails();

      if (Get.isRegistered<ScheduleController>()) {
        final scheduleCtrl = Get.find<ScheduleController>();
        scheduleCtrl.fetchScheduleForDate(
          scheduleCtrl.selectedDate.value,
          showLoad: false,
        );
      }
    } catch (e) {
      handleError(e);
    } finally {
      hideLoading();
    }
  }
}
