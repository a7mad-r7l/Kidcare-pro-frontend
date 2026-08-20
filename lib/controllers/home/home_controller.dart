import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../core/constants.dart';
import '../../core/repos/home/home_repo.dart';
import '../../models/home/doctor_dashboard_model.dart';
import '../../service/notification_service.dart';
import '../base_controller.dart';

class HomeController extends BaseController {
  final HomeRepo repo;

  HomeController({required this.repo});
  final RxBool hasUnreadNotifications = false.obs;

  final currentIndex = 0.obs;
  final selectedDate = DateTime.now().obs;


  String get formattedSelectedDate =>
      DateFormat('yyyy-MM-dd').format(selectedDate.value);


  String get displaySelectedDate =>
      DateFormat('yyyy - MM - dd').format(selectedDate.value);

  final doctorData = Rxn<DoctorHomeModel>();
  final totalAppointments = 0.obs;
  final completedAppointments = 0.obs;
  final monthlyRevenue = 0.0.obs;
  final nextPatient = Rxn<PatientModel>();
  final remainingPatients = <PatientModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchAllDashboardData();
    NotificationService.sendFCMTokenToServer();
  }

  // دالة حل مسار الصور
  String resolveImageUrl(String path) {
    if (path.isEmpty) return '';
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    return '$baseUrl/$path';
  }


  String formatTime(String time24) {
    if (time24.isEmpty) return '';
    try {
      final parts = time24.split(':');
      int hour = int.parse(parts[0]);
      int minute = int.parse(parts[1]);

      String amPm = hour < 12 ? 'AM' : 'PM';
      if (Get.locale?.languageCode == 'ar') {
        amPm = hour < 12 ? 'ص' : 'م';
      }

      int hour12 = hour % 12;
      if (hour12 == 0) hour12 = 12;

      return '$hour12:${minute.toString().padLeft(2, '0')} $amPm';
    } catch (e) {
      return time24;
    }
  }

  Future<void> fetchAllDashboardData() async {
    showLoading();
    try {
      final now = DateTime.now();
      final isToday = selectedDate.value.year == now.year &&
          selectedDate.value.month == now.month &&
          selectedDate.value.day == now.day;

      final results = await Future.wait([
        repo.getDoctorHome(),
        repo.getTodayAppointmentsCount(),
        repo.getCompletedAppointmentsToday(),
        repo.getMonthlyRevenue(),
        repo.getNextPatient(),

        isToday ? repo.getRemainingPatients() : repo.getAppointmentsByDate(formattedSelectedDate),
      ]);

      doctorData.value = results[0] as DoctorHomeModel;
      totalAppointments.value = results[1] as int;
      completedAppointments.value = results[2] as int;
      monthlyRevenue.value = results[3] as double;
      nextPatient.value = results[4] as PatientModel?;
      remainingPatients.assignAll(results[5] as List<PatientModel>);
    } catch (e) {
      handleError(e);
    } finally {
      hideLoading();
    }
  }

  Future<void> selectCustomDate(BuildContext context) async {

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate.value,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (picked != null && picked != selectedDate.value) {
      selectedDate.value = picked;
      await fetchRemainingPatientsForSelectedDate();
    }
  }

  Future<void> fetchRemainingPatientsForSelectedDate() async {
    showLoading();
    try {
      final now = DateTime.now();
      final isToday = selectedDate.value.year == now.year &&
          selectedDate.value.month == now.month &&
          selectedDate.value.day == now.day;


      final patients = isToday
          ? await repo.getRemainingPatients()
          : await repo.getAppointmentsByDate(formattedSelectedDate);

      remainingPatients.assignAll(patients);
    } catch (e) {
      handleError(e);
    } finally {
      hideLoading();
    }
  }

  Future<void> completePatientAppointment(int appointmentId) async {
    showLoading();
    try {
      final msg = await repo.completeAppointment(appointmentId);
      showSuccess(msg);
      await fetchAllDashboardData();
    } catch (e) {
      handleError(e);
    } finally {
      hideLoading();
    }
  }
}