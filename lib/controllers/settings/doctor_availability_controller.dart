import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/repos/settings/doctor_availability_repo.dart';
import '../../models/settings/availability_item_model.dart';
import '../base_controller.dart';
import '../home/home_controller.dart';

class DoctorAvailabilityController extends BaseController {
  final DoctorAvailabilityRepo repo;

  DoctorAvailabilityController({required this.repo});

  final availabilitiesList = <AvailabilityItemModel>[].obs;
  final isFetching = true.obs;

  final List<String> apiDays = [
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
    'saturday',
    'sunday',
  ];
  final selectedDay = 'monday'.obs;
  final startTime = const TimeOfDay(hour: 12, minute: 0).obs;
  final endTime = const TimeOfDay(hour: 17, minute: 0).obs;

  @override
  void onInit() {
    super.onInit();
    fetchAvailabilities();
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String get formattedStartTime => _formatTimeOfDay(startTime.value);

  String get formattedEndTime => _formatTimeOfDay(endTime.value);

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

  Future<void> fetchAvailabilities() async {
    isFetching.value = true;
    try {
      int doctorId = 0;
      if (Get.isRegistered<HomeController>()) {
        doctorId = Get.find<HomeController>().doctorData.value?.id ?? 0;
      }

      final data = await repo.getAvailabilities(doctorId);
      availabilitiesList.assignAll(data);
    } catch (e) {
      handleError(e);
    } finally {
      isFetching.value = false;
    }
  }

  Future<void> deleteDay(int id) async {
    showLoading();
    try {
      final msg = await repo.deleteAvailability(id);
      availabilitiesList.removeWhere((item) => item.id == id);
      showSuccess(msg);
    } catch (e) {
      handleError(e);
    } finally {
      hideLoading();
    }
  }

  Future<void> saveWorkingHours() async {
    showLoading();
    try {
      final result = await repo.addAvailability(
        dayOfWeek: selectedDay.value,
        startTime: formattedStartTime,
        endTime: formattedEndTime,
      );

      showSuccess(
        result.message.isNotEmpty
            ? result.message
            : 'Working hours added successfully.'.tr,
      );

      Get.back();
      fetchAvailabilities();
    } catch (e) {
      handleError(e);
    } finally {
      hideLoading();
    }
  }
}
