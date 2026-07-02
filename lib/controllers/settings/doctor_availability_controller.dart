import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/repos/settings/doctor_availability_repo.dart';
import '../base_controller.dart';



class DoctorAvailabilityController extends BaseController {
  final DoctorAvailabilityRepo repo;
  DoctorAvailabilityController({required this.repo});

  // أيام الأسبوع بالإنجليزية لإرسالها للباك إند
  final List<String> apiDays = [
    'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'
  ];

  // اليوم المختار حالياً (افتراضياً الإثنين)
  final selectedDay = 'monday'.obs;

  // أوقات الدوام كـ TimeOfDay لتسهيل التعامل مع الـ Native Pickers
  final startTime = const TimeOfDay(hour: 12, minute: 0).obs;
  final endTime = const TimeOfDay(hour: 17, minute: 0).obs;

  // دالتين مساعِدتين لتحويل الوقت لصيغة HH:mm المناسبة للـ Validation في لارافيل
  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String get formattedStartTime => _formatTimeOfDay(startTime.value);
  String get formattedEndTime => _formatTimeOfDay(endTime.value);

  // فتح الـ Time Picker للمستخدم
  Future<void> pickTime(BuildContext context, bool isStartTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStartTime ? startTime.value : endTime.value,
    );
    if (picked != null) {
      if (isStartTime) {
        startTime.value = picked;
      } else {
        endTime.value = picked;
      }
    }
  }

  // إرسال الطلب وحفظ الدوام
  Future<void> saveWorkingHours() async {
    showLoading();
    try {
      final result = await repo.addAvailability(
        dayOfWeek: selectedDay.value,
        startTime: formattedStartTime,
        endTime: formattedEndTime,
      );

      showSuccess(result.message.isNotEmpty ? result.message : 'Working hours added successfully.'.tr);

      // العودة للشاشة السابقة بعد ثانية ونصف تلقائياً
      Future.delayed(const Duration(milliseconds: 1500), () => Get.back());
    } catch (e) {
      handleError(e); // سيتكفل بعرض الـ Snackbar الحمراء في حال التضارب 422
    } finally {
      hideLoading();
    }
  }
}