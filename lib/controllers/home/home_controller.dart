import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../core/repos/home/home_repo.dart';
import '../../models/home/doctor_dashboard_model.dart';
import '../base_controller.dart';

class HomeController extends BaseController {
  final HomeRepo repo;
  HomeController({required this.repo});

  final currentIndex = 0.obs;
  final selectedDate = DateTime.now().obs;

  String get formattedSelectedDate => DateFormat('yyyy-MM-dd').format(selectedDate.value);

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
  }

  Future<void> fetchAllDashboardData() async {
    showLoading();
    // كل طلب يُعالج بشكل مستقل حتى لا يُعطّل فشل أحدها بقية لوحة التحكم.
    await Future.wait([
      _run('getDoctorHome', () async => doctorData.value = await repo.getDoctorHome()),
      _run('getTodayAppointmentsCount', () async => totalAppointments.value = await repo.getTodayAppointmentsCount()),
      _run('getCompletedAppointmentsToday', () async => completedAppointments.value = await repo.getCompletedAppointmentsToday()),
      _run('getMonthlyRevenue', () async => monthlyRevenue.value = await repo.getMonthlyRevenue()),
      _run('getNextPatient', () async => nextPatient.value = await repo.getNextPatient()),
      _run('getRemainingPatients', () async => remainingPatients.assignAll(await repo.getRemainingPatients())),
    ]);
    hideLoading();
  }

  /// ينفّذ مهمة طلب واحدة ويسجّل أي خطأ مع اسمها دون إيقاف بقية الطلبات.
  Future<void> _run(String name, Future<void> Function() task) async {
    try {
      await task();
    } catch (e) {
      debugPrint('Dashboard call failed: $name -> $e');
    }
  }

  Future<void> selectCustomDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate.value,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: context.theme.primaryColor,
              onPrimary: Colors.white,
              onSurface: context.theme.textTheme.bodyLarge?.color ?? Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != selectedDate.value) {
      selectedDate.value = picked;
      await fetchRemainingPatientsForSelectedDate();
    }
  }

  Future<void> fetchRemainingPatientsForSelectedDate() async {
    showLoading();
    try {
      final patients = await repo.getRemainingPatients();
      remainingPatients.assignAll(patients);
    } catch (e) {
      handleError(e);
    } finally { // 👈 تم تصحيحها هنا أيضاً من final إلى finally
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
    } finally { // 👈 تم تصحيحها هنا من final إلى finally
      hideLoading();
    }
  }
}