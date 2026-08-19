import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/repos/settings/doctor_availability_repo.dart';
import '../../models/settings/availability_item_model.dart';
import '../../models/settings/available_period_model.dart';
import '../base_controller.dart';
import '../home/home_controller.dart';

class DoctorAvailabilityController extends BaseController {
  final DoctorAvailabilityRepo repo;

  DoctorAvailabilityController({required this.repo});

  final availabilitiesList = <AvailabilityItemModel>[].obs;
  final availablePeriodsList = <AvailablePeriodModel>[].obs;
  final isFetching = true.obs;
  final selectedTab = 0.obs;

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
  final startTime = const TimeOfDay(hour: 09, minute: 0).obs;
  final endTime = const TimeOfDay(hour: 17, minute: 0).obs;

  @override
  void onInit() {
    super.onInit();
    fetchAllData();
  }

  Future<void> fetchAllData() async {
    isFetching.value = true;
    try {
      int doctorId = 0;
      if (Get.isRegistered<HomeController>()) {
        doctorId = Get.find<HomeController>().doctorData.value?.id ?? 0;
      }
      if (doctorId == 0) {
        handleError('Please wait for home data to load first'.tr);
        return;
      }

      final results = await Future.wait([
        repo.getAvailabilities(doctorId),
        repo.fetchAvailableWorkingPeriods(),
      ]);

      availabilitiesList.assignAll(results[0] as List<AvailabilityItemModel>);
      availablePeriodsList.assignAll(results[1] as List<AvailablePeriodModel>);
    } catch (e) {
      handleError(e);
    } finally {
      isFetching.value = false;
    }
  }

  void switchTab(int index) {
    selectedTab.value = index;
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

  Future<void> deleteDay(int id) async {
    showLoading();
    try {
      final msg = await repo.deleteAvailability(id);
      availabilitiesList.removeWhere((item) => item.id == id);
      showSuccess(msg);
      fetchAllData();
    } catch (e) {
      handleError(e);
    } finally {
      hideLoading();
    }
  }

  Future<void> saveWorkingHours() async {
    final startMinutes = startTime.value.hour * 60 + startTime.value.minute;
    final endMinutes = endTime.value.hour * 60 + endTime.value.minute;

    if (startMinutes >= endMinutes) {
      handleError('End time must be after start time'.tr);
      return;
    }

    showLoading();
    try {
      final result = await repo.addAvailability(
        dayOfWeek: selectedDay.value,
        startTime: formattedStartTime,
        endTime: formattedEndTime,
      );

      if (Get.isBottomSheetOpen == true) {
        Get.back();
      }

      selectedTab.value = 0;

      showSuccess(
        result.message.isNotEmpty
            ? result.message
            : 'Working hours added successfully.'.tr,
      );

      // 4. تحديث البيانات من السيرفر
      fetchAllData();
    } catch (e) {
      handleError(e);
    } finally {
      hideLoading();
    }
  }

  // دالة لتعبئة البيانات تلقائياً
  void preFillData(String day, String start, String end) {
    selectedDay.value = day.toLowerCase();

    final sParts = start.split(':');
    startTime.value = TimeOfDay(
      hour: int.parse(sParts[0]),
      minute: int.parse(sParts[1]),
    );

    final eParts = end.split(':');
    endTime.value = TimeOfDay(
      hour: int.parse(eParts[0]),
      minute: int.parse(eParts[1]),
    );
  }
}
