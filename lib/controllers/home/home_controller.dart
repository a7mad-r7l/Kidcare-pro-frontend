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
    try {
      final results = await Future.wait([
        repo.getDoctorHome(),
        repo.getTodayAppointmentsCount(),
        repo.getCompletedAppointmentsToday(),
        repo.getMonthlyRevenue(),
        repo.getNextPatient(),
        repo.getRemainingPatients(),
      ]);

      doctorData.value = results[0] as DoctorHomeModel;
      totalAppointments.value = results[1] as int;
      completedAppointments.value = results[2] as int;
      monthlyRevenue.value = results[3] as double;
      nextPatient.value = results[4] as PatientModel?;
      remainingPatients.assignAll(results[5] as List<PatientModel>);
    } catch (e) {
      handleError(e);
    } finally { // 👈 تم تصحيحها هنا من final إلى finally
      hideLoading();
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