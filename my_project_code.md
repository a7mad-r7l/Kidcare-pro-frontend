# KidCare Project Code

### File: lib\controllers\auth\login_controller.dart
```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/helper/secure_storage_service.dart';
import '../../core/repos/auth/login_repo.dart';
import '../base_controller.dart';

class LoginController extends BaseController {
  final LoginRepo repo;

  LoginController({required this.repo});

  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  final loginFormKey = GlobalKey<FormState>();

  final isPasswordHidden = true.obs;

  Future<void> loginProcess() async {
    if (!loginFormKey.currentState!.validate()) return;

    showLoading();
    try {
      final result = await repo.login(
        phone: phoneController.text.trim(),
        password: passwordController.text,
      );

      if (result.token.isNotEmpty) {
        await SecureStorage.storeToken(result.token);

        hideLoading();

        showSuccess(
          result.message.isNotEmpty ? result.message : 'Logged in successfully',
        );

        // الانتقال لصفحة الطبيب الرئيسية
        Get.offAllNamed('/doctor_home');
      } else {
        hideLoading();
        Get.snackbar(
          'Error'.tr,
          result.message.isNotEmpty ? result.message : 'Login Failed',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      hideLoading();
      handleError(e);
    }
  }

  @override
  void onClose() {
    phoneController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}

```

### File: lib\controllers\auth\password_reset_controller.dart
```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/repos/auth/password_reset_repo.dart';
import '../base_controller.dart';

class PasswordResetController extends BaseController {
  final PasswordResetRepo repo;
  PasswordResetController({required this.repo});

  // إدارة شاشات الـ PageView
  final pageController = PageController();
  final currentPage = 0.obs;

  // Controllers للحقول
  final phoneController = TextEditingController();
  final otpController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  final isPasswordHidden = true.obs;
  final isConfirmHidden = true.obs;

  // ─── 1. إرسال الـ OTP ───
  Future<void> sendOtp() async {
    final phone = phoneController.text.trim();

    // Client-Side Validation لرقم الهاتف
    if (phone.length != 12 || !phone.startsWith('963')) {
      handleError('Phone number must be exactly 12 digits and start with 963'.tr);
      return;
    }

    showLoading();
    try {
      final msg = await repo.sendOtp(phone);
      showSuccess(msg);
      _nextPage();
    } catch (e) {
      handleError(e);
    } finally {
      hideLoading();
    }
  }

  // ─── 2. التحقق من الـ OTP ───
  Future<void> verifyOtp() async {
    final otp = otpController.text.trim();

    if (otp.length < 4) {
      handleError('Please enter a valid 4-digit OTP'.tr);
      return;
    }

    showLoading();
    try {
      final msg = await repo.verifyOtp(phoneController.text.trim(), otp);
      showSuccess(msg);
      _nextPage();
    } catch (e) {
      handleError(e);
    } finally {
      hideLoading();
    }
  }

  // ─── 3. تعيين كلمة المرور الجديدة ───
  Future<void> setPassword() async {
    final pass = passwordController.text;
    final confirm = confirmPasswordController.text;

    // Client-Side Validation لكلمة المرور
    if (pass.length < 6) {
      handleError('Password must be at least 6 characters long'.tr);
      return;
    }
    if (pass != confirm) {
      handleError('Passwords do not match'.tr);
      return;
    }

    showLoading();
    try {
      final msg = await repo.setPassword(phoneController.text.trim(), pass, confirm);
      showSuccess(msg);

      // طرد المستخدم للوجن بعد ثانية للنجاح
      Future.delayed(const Duration(seconds: 1), () {
        Get.offAllNamed('/login');
      });
    } catch (e) {
      handleError(e);
    } finally {
      hideLoading();
    }
  }

  void _nextPage() {
    currentPage.value++;
    pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
  }

  void previousPage() {
    if (currentPage.value > 0) {
      currentPage.value--;
      pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } else {
      Get.back();
    }
  }

  @override
  void onClose() {
    pageController.dispose();
    phoneController.dispose();
    otpController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }
}
```

### File: lib\controllers\base_controller.dart
```dart
import 'dart:convert';

import 'package:get/get.dart';
import 'package:flutter/material.dart';

import '../core/helper/secure_storage_service.dart';

class BaseController extends GetxController {
  final _isLoading = false.obs;

  bool get isLoading => _isLoading.value;

  void showLoading() => _isLoading.value = true;

  void hideLoading() => _isLoading.value = false;

  void handleError(dynamic e) {
    hideLoading();

    final errorString = e.toString();
    String message = "Something went wrong. Please try again.".tr;

    try {
      if (errorString.contains("401")) {
        message = "Incorrect phone number or password.".tr;
        SecureStorage.removeToken();
        if (Get.currentRoute != '/login') {
          Get.offAllNamed('/login');
          return;
        }
      } else if (errorString.contains('{') && errorString.contains('}')) {
        final startIndex = errorString.indexOf('{');
        final endIndex = errorString.lastIndexOf('}') + 1;
        final jsonPart = errorString.substring(startIndex, endIndex);
        final decoded = jsonDecode(jsonPart);
        if (decoded['message'] != null) {
          message = decoded['message'];
        }
      } else if (errorString.contains("Exception:")) {
        message = errorString.split("Exception:").last.trim();
      } else if (errorString.contains("SocketException")) {
        message = "No Internet connection. Please check your network.".tr;
      } else if (errorString.contains("TimeoutException")) {
        message = "Request timed out. Please try again.".tr;
      }
    } catch (_) {
      // JSON parse failed — fall through to the generic message above.
    }

    Get.snackbar(
      "Error".tr,
      message,
      backgroundColor: Colors.red.shade800,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(15),
      icon: const Icon(Icons.error_outline, color: Colors.white),
      duration: const Duration(seconds: 4),
    );
  }

  void showSuccess(String message) {
    Get.snackbar(
      "Success".tr,
      message,
      backgroundColor: Colors.green.shade700,
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
      margin: const EdgeInsets.all(15),
      icon: const Icon(Icons.check_circle_outline, color: Colors.white),
      duration: const Duration(seconds: 3),
    );
  }

  void showInfo(String message) {
    Get.snackbar(
      "Info".tr,
      message,
      backgroundColor: Colors.grey.shade700,
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
      margin: const EdgeInsets.all(15),
      duration: const Duration(seconds: 3),
    );
  }
}

```

### File: lib\controllers\examination\examination_controller.dart
```dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/repos/examination/examination_repo.dart';
import '../../models/home/doctor_dashboard_model.dart';
import '../base_controller.dart';

// حامل بسيط لحقول دواء واحد في الواجهة (إضافة دواء آخر تضيف نسخة جديدة)
class MedicationFormData {
  final nameController = TextEditingController();
  final dosageController = TextEditingController();
  final frequencyController = TextEditingController(); // الكمية
  final timingController = TextEditingController(); // التعليمات
  final durationController = TextEditingController();

  bool get isEmpty =>
      nameController.text.trim().isEmpty &&
      dosageController.text.trim().isEmpty &&
      frequencyController.text.trim().isEmpty &&
      timingController.text.trim().isEmpty &&
      durationController.text.trim().isEmpty;

  bool get isComplete =>
      nameController.text.trim().isNotEmpty &&
      dosageController.text.trim().isNotEmpty &&
      frequencyController.text.trim().isNotEmpty &&
      timingController.text.trim().isNotEmpty &&
      durationController.text.trim().isNotEmpty;

  void dispose() {
    nameController.dispose();
    dosageController.dispose();
    frequencyController.dispose();
    timingController.dispose();
    durationController.dispose();
  }
}

// نوع طلب التحاليل/الأشعة: تحليل أو صورة أشعة
enum LabRequestType { test, imaging }

// عنصر واحد في قائمة طلبات التحاليل/الأشعة (النوع + القيمة النصية)
class LabRequestItem {
  final LabRequestType type;
  final String value;

  LabRequestItem({required this.type, required this.value});
}

class ExaminationController extends BaseController {
  final ExaminationRepo repo;
  ExaminationController({required this.repo});

  // 0 = التشخيص ، 1 = الوصفة
  final selectedTab = 0.obs;

  // بطاقة القياسات القابلة للطي داخل تبويب التشخيص (اختيارية)
  final measurementsExpanded = false.obs;

  final patient = Rxn<PatientModel>();

  // recordId يُضبط بعد حفظ التشخيص، وهو مطلوب لإضافة الأدوية
  int? recordId;

  // حقول التشخيص
  final diagnosisController = TextEditingController();
  final doctorNotesController = TextEditingController();

  // حقول القياسات
  final heightController = TextEditingController();
  final weightController = TextEditingController();

  // الأدوية (تبدأ بنموذج فارغ واحد)
  final medications = <MedicationFormData>[MedicationFormData()].obs;

  // طلب تحاليل وصور أشعة — قائمة عناصر يختار الطبيب نوعها ويُدخل قيمتها
  // تُجمَّع قيم التحاليل في required_tests وقيم الأشعة في required_imaging
  final labRequests = <LabRequestItem>[].obs;

  // المؤقت التنازلي للمعاينة (للعرض فقط)
  final remainingSeconds = (15 * 60 + 30).obs;
  Timer? _timer;

  String get formattedTime {
    final total = remainingSeconds.value;
    final h = (total ~/ 3600).toString().padLeft(2, '0');
    final m = ((total % 3600) ~/ 60).toString().padLeft(2, '0');
    final s = (total % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  String get formattedPatientId {
    final id = patient.value?.id ?? 0;
    return 'PT-${DateTime.now().year}-${id.toString().padLeft(4, '0')}';
  }

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is PatientModel) {
      patient.value = args;
    } else {
      fetchNextPatient();
    }
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (remainingSeconds.value > 0) {
        remainingSeconds.value--;
      } else {
        _timer?.cancel();
      }
    });
  }

  Future<void> fetchNextPatient() async {
    showLoading();
    try {
      patient.value = await repo.getNextPatient();
    } catch (e) {
      handleError(e);
    } finally {
      hideLoading();
    }
  }

  // ─── الشاشة الأولى: حفظ وتقدم (التشخيص + القياسات) ───
  Future<void> saveAndContinue() async {
    final diagnosis = diagnosisController.text.trim();
    if (diagnosis.isEmpty) {
      selectedTab.value = 0; // البقاء في تبويب التشخيص لإظهار الحقل المطلوب
      showInfo('Please enter the diagnosis'.tr);
      return;
    }

    final heightText = heightController.text.trim();
    final weightText = weightController.text.trim();
    final hasHeight = heightText.isNotEmpty;
    final hasWeight = weightText.isNotEmpty;
    if (hasHeight != hasWeight) {
      selectedTab.value = 0; // القياسات أصبحت داخل تبويب التشخيص
      measurementsExpanded.value = true; // فتح البطاقة لإظهار الحقول
      showInfo('Please enter both height and weight'.tr);
      return;
    }

    final appointmentId = patient.value?.appointmentId ?? 0;

    showLoading();
    try {
      final record = await repo.saveDiagnosis(
        appointmentId,
        diagnosis: diagnosis,
        doctorNotes: doctorNotesController.text.trim().isEmpty
            ? null
            : doctorNotesController.text.trim(),
      );
      recordId = record.id;

      if (hasHeight && hasWeight) {
        await repo.saveGrowth(
          appointmentId,
          height: num.tryParse(heightText) ?? 0,
          weight: num.tryParse(weightText) ?? 0,
        );
      }

      hideLoading();
      showSuccess('Diagnosis saved successfully'.tr);
      selectedTab.value = 1; // الانتقال لتبويب الوصفة
    } catch (e) {
      handleError(e);
    }
  }

  void addMedicationField() {
    medications.add(MedicationFormData());
  }

  void removeMedicationField(int index) {
    if (index < 0 || index >= medications.length) return;
    medications[index].dispose();
    medications.removeAt(index);
  }

  // إضافة طلب تحليل/أشعة بعد اختيار النوع وإدخال القيمة
  void addLabRequest(LabRequestType type, String value) {
    if (value.trim().isEmpty) return;
    labRequests.add(LabRequestItem(type: type, value: value.trim()));
  }

  void removeLabRequest(int index) {
    if (index < 0 || index >= labRequests.length) return;
    labRequests.removeAt(index);
  }

  // ─── الشاشة الثانية: حفظ وإنهاء المعاينة ───
  Future<void> saveAndFinish() async {
    if (recordId == null) {
      selectedTab.value = 0; // العودة لتبويب التشخيص لحفظه أولاً
      showInfo('Please save the diagnosis first'.tr);
      return;
    }

    // أي نموذج مملوء جزئياً يعتبر خطأ؛ النماذج الفارغة تماماً تُتجاهل
    final hasPartial = medications.any((m) => !m.isEmpty && !m.isComplete);
    if (hasPartial) {
      showInfo('Please complete all medication fields'.tr);
      return;
    }

    final completeMeds = medications.where((m) => m.isComplete).toList();

    showLoading();
    try {
      for (final med in completeMeds) {
        await repo.addMedication(
          recordId!,
          name: med.nameController.text.trim(),
          dosage: med.dosageController.text.trim(),
          frequency: med.frequencyController.text.trim(),
          timing: med.timingController.text.trim(),
          duration: med.durationController.text.trim(),
        );
      }

      // طلب التحاليل/الأشعة — تُجمَّع قيم كل نوع بفاصلة وتُرسل فقط إن وُجدت
      final tests = labRequests
          .where((r) => r.type == LabRequestType.test)
          .map((r) => r.value)
          .join(', ');
      final imaging = labRequests
          .where((r) => r.type == LabRequestType.imaging)
          .map((r) => r.value)
          .join(', ');
      if (tests.isNotEmpty || imaging.isNotEmpty) {
        await repo.saveMedicalRequests(
          patient.value?.appointmentId ?? 0,
          requiredTests: tests.isEmpty ? null : tests,
          requiredImaging: imaging.isEmpty ? null : imaging,
        );
      }

      final msg = await repo.completeAppointment(patient.value?.appointmentId ?? 0);

      hideLoading();
      showSuccess(msg);
      Get.offAllNamed('/doctor_home');
    } catch (e) {
      handleError(e);
    }
  }

  @override
  void onClose() {
    _timer?.cancel();
    diagnosisController.dispose();
    doctorNotesController.dispose();
    heightController.dispose();
    weightController.dispose();
    for (final med in medications) {
      med.dispose();
    }
    super.onClose();
  }
}

```

### File: lib\controllers\home\home_controller.dart
```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../core/constants.dart';
import '../../core/repos/home/home_repo.dart';
import '../../models/home/doctor_dashboard_model.dart';
import '../base_controller.dart';

class HomeController extends BaseController {
  final HomeRepo repo;

  HomeController({required this.repo});

  final currentIndex = 0.obs;
  final selectedDate = DateTime.now().obs;

  // تنسيق للـ API (yyyy-MM-dd)
  String get formattedSelectedDate =>
      DateFormat('yyyy-MM-dd').format(selectedDate.value);

  // تنسيق للعرض في واجهة المستخدم (مثل التصميم)
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
  }

  // دالة حل مسار الصور
  String resolveImageUrl(String path) {
    if (path.isEmpty) return '';
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    return '$baseUrl/$path';
  }

  // دالة تنسيق الوقت (ص / م)
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
    } finally {
      hideLoading();
    }
  }

  Future<void> selectCustomDate(BuildContext context) async {
    // ─── تم إزالة الـ Theme الإجباري الخاطئ ليعمل التقويم بشكل سليم في كل الثيمات ───
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
      // ─── الاعتماد على دالة التاريخ الصحيحة لتحديث القائمة حسب اختيار الطبيب ───
      final patients = await repo.getAppointmentsByDate(formattedSelectedDate);
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
```

### File: lib\controllers\revenue\revenue_controller.dart
```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/repos/revenue/revenue_repo.dart';
import '../../models/revenue/transaction_model.dart';
import '../base_controller.dart';

class RevenueController extends BaseController {
  final RevenueRepo repo;
  RevenueController({required this.repo});

  final monthlyRevenue = 0.0.obs;
  final totalPaidVisits = 0.obs;
  final chartData = <double>[].obs;
  final transactions = <TransactionModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchAllRevenueData();
  }

  Future<void> fetchAllRevenueData() async {
    showLoading();
    await Future.wait([
      _run(() async => monthlyRevenue.value = await repo.getMonthlyRevenue()),
      _run(() async => totalPaidVisits.value = await repo.getTotalPaidVisits()),
      _run(() async => chartData.assignAll(await repo.getRevenueChartData())),
      _run(() async => transactions.assignAll(await repo.getTransactions())),
    ]);
    hideLoading();
  }

  Future<void> _run(Future<void> Function() task) async {
    try {
      await task();
    } catch (e) {
      debugPrint('RevenueController error: $e');
    }
  }
}

```

### File: lib\controllers\schedule\appointment_details_controller.dart
```dart
import 'package:get/get.dart';
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
}
```

### File: lib\controllers\schedule\patients_controller.dart
```dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/repos/schedule/patients_repo.dart';
import '../../models/schedule/patient_list_model.dart';
import '../base_controller.dart';

class PatientsController extends BaseController {
  final PatientsRepo repo;
  PatientsController({required this.repo});

  final patientsList = <PatientListModel>[].obs;
  final searchController = TextEditingController();
  Timer? _debounce;

  @override
  void onInit() {
    super.onInit();
    fetchPatients();
  }

  Future<void> fetchPatients({String? query}) async {
    showLoading();
    try {
      final data = await repo.getPatients(query: query);
      patientsList.assignAll(data);
    } catch (e) {
      handleError(e);
    } finally {
      hideLoading();
    }
  }

  void onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      fetchPatients(query: query);
    });
  }

  @override
  void onClose() {
    searchController.dispose();
    _debounce?.cancel();
    super.onClose();
  }
}
```

### File: lib\controllers\schedule\schedule_controller.dart
```dart
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../core/repos/schedule/schedule_repo.dart';
import '../../models/schedule/schedule_model.dart';
import '../base_controller.dart';

class ScheduleController extends BaseController {
  final ScheduleRepo repo;
  ScheduleController({required this.repo});

  final selectedDate = DateTime.now().obs;
  final scheduleData = Rxn<ScheduleDataModel>();
  final weekDates = <DateTime>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchInitialData();
  }

  // عملية جلب الأيام المتاحة والمواعيد معاً
  Future<void> fetchInitialData() async {
    showLoading();
    try {
      final days = await repo.getWorkingDays();
      weekDates.assignAll(days);

      if (weekDates.isNotEmpty) {
        // تحديد أول يوم عمل تلقائياً
        selectedDate.value = weekDates.first;
        // جلب مواعيد اليوم الأول بدون إظهار لودينج متداخل
        await fetchScheduleForDate(selectedDate.value, showLoad: false);
      } else {
        hideLoading();
      }
    } catch (e) {
      handleError(e);
      hideLoading();
    }
  }

  void onDateSelected(DateTime date) {
    selectedDate.value = date;
    fetchScheduleForDate(date);
  }

  Future<void> fetchScheduleForDate(DateTime date, {bool showLoad = true}) async {
    if (showLoad) showLoading();
    try {
      String formattedDate = DateFormat('yyyy-MM-dd').format(date);
      final data = await repo.getSchedule(formattedDate);
      scheduleData.value = data;
    } catch (e) {
      handleError(e);
      scheduleData.value = ScheduleDataModel(totalAppointments: 0, appointments: []);
    } finally {
      if (showLoad) hideLoading();
    }
  }

  String getDayName(DateTime date) {
    return DateFormat('EEEE', Get.locale?.languageCode ?? 'en').format(date);
  }

  String getMonthName(DateTime date) {
    return DateFormat('MMMM', Get.locale?.languageCode ?? 'en').format(date);
  }
}
```

### File: lib\controllers\settings\doctor_availability_controller.dart
```dart
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
```

### File: lib\controllers\settings\settings_controller.dart
```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/helper/secure_storage_service.dart';
import '../base_controller.dart';

class SettingsController extends BaseController {
  void goToAvailabilities() {
    Get.toNamed('/doctor_availability');
  }

  // ─── منطق تغيير اللغة بالخيارات الثلاثة ───
  void showLanguageDialog() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Get.theme.cardColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Language'.tr,
              style: Get.theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // 1. خيار لغة النظام
            ListTile(
              leading: Icon(Icons.brightness_auto_outlined, color: Get.theme.primaryColor),
              title: Text('System Language'.tr),
              onTap: () => _updateLanguage('system'),
            ),
            Divider(color: Get.theme.dividerColor.withOpacity(0.2), height: 1),

            // 2. خيار اللغة العربية
            ListTile(
              leading: Icon(Icons.language, color: Get.theme.primaryColor),
              title: Text('Arabic'.tr),
              onTap: () => _updateLanguage('ar'),
            ),
            Divider(color: Get.theme.dividerColor.withOpacity(0.2), height: 1),

            // 3. خيار اللغة الإنجليزية
            ListTile(
              leading: Icon(Icons.language, color: Get.theme.primaryColor),
              title: Text('English'.tr),
              onTap: () => _updateLanguage('en'),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  Future<void> _updateLanguage(String langCode) async {
    // 1. حفظ الاختيار في التخزين الآمن
    await SecureStorage.storeLanguage(langCode);
    Get.back(); // إغلاق الـ Bottom Sheet

    Locale targetLocale;

    if (langCode == 'system') {
      // جلب لغة الجهاز الحالية
      Locale? deviceLocale = Get.deviceLocale;
      if (deviceLocale != null && deviceLocale.languageCode == 'ar') {
        targetLocale = const Locale('ar', 'SY');
      } else {
        targetLocale = const Locale('en', 'US');
      }
    } else if (langCode == 'ar') {
      targetLocale = const Locale('ar', 'SY');
    } else {
      targetLocale = const Locale('en', 'US');
    }

    // 2. تحديث لغة التطبيق فوراً وبشكل حيّ
    Get.updateLocale(targetLocale);
  }

  void changePassword() {
    Get.toNamed('/password_reset');
  }
  void changeTheme() {}
  void deleteAccount() {}
}
```

### File: lib\core\apis\auth\login_api.dart
```dart
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:get/get.dart';
import '../../constants.dart';

class LoginApi {
  Future<String> login({required String phone, required String password}) async {
    final url = Uri.parse('$baseUrl/api/loginDoctor');
    final String currentLocale = Get.locale?.languageCode ?? 'en';

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Accept-Language': currentLocale,
      },

      body: jsonEncode({
        'phone_number': phone,
        'password': password,
      }),
    ).timeout(const Duration(seconds: 15));

    return response.body;
  }
}
```

### File: lib\core\apis\auth\password_reset_api.dart
```dart
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:get/get.dart';
import '../../constants.dart';

class PasswordResetApi {
  Map<String, String> _getHeaders() {
    final String currentLocale = Get.locale?.languageCode ?? 'en';
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Accept-Language': currentLocale,
    };
  }

  Future<http.Response> sendOtp(String phone) async {
    return await http.post(
      Uri.parse('$baseUrl/api/sendOtpDoctor'),
      headers: _getHeaders(),
      body: jsonEncode({'phone_number': phone}),
    ).timeout(const Duration(seconds: 15));
  }

  Future<http.Response> verifyOtp(String phone, String otp) async {
    return await http.post(
      Uri.parse('$baseUrl/api/verifyOtpDoctor'),
      headers: _getHeaders(),
      body: jsonEncode({'phone_number': phone, 'otp': otp}),
    ).timeout(const Duration(seconds: 15));
  }

  Future<http.Response> setPassword(String phone, String password, String passwordConfirmation) async {
    return await http.post(
      Uri.parse('$baseUrl/api/SetPasswordDoctor'),
      headers: _getHeaders(),
      body: jsonEncode({
        'phone_number': phone,
        'password': password,
        'password_confirmation': passwordConfirmation,
      }),
    ).timeout(const Duration(seconds: 15));
  }
}
```

### File: lib\core\apis\examination\examination_api.dart
```dart
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:get/get.dart';
import '../../constants.dart';
import '../../helper/secure_storage_service.dart';

class ExaminationApi {
  Future<Map<String, String>> _getHeaders() async {
    final token = await SecureStorage.getToken();
    final String currentLocale = Get.locale?.languageCode ?? 'en';
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Accept-Language': currentLocale,
      'Authorization': 'Bearer $token',
    };
  }

  // المريض القادم (لبناء ترويسة المعاينة عند فتح الشاشة بدون تمرير المريض)
  Future<String> getNextPatient() async {
    return (await http.get(
      Uri.parse('$baseUrl/api/doctor/next-patient'),
      headers: await _getHeaders(),
    )).body;
  }

  // 1a) حفظ التشخيص السريري + ملاحظات الطبيب
  Future<String> saveDiagnosis(
    int appointmentId, {
    required String diagnosis,
    String? doctorNotes,
  }) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/api/doctor/$appointmentId/diagnosis'),
          headers: await _getHeaders(),
          body: jsonEncode({
            'diagnosis': diagnosis,
            'doctor_notes': doctorNotes,
          }),
        )
        .timeout(const Duration(seconds: 15));

    return response.body;
  }

  // 1b) حفظ القياسات (الطول والوزن)
  Future<String> saveGrowth(
    int appointmentId, {
    required num height,
    required num weight,
  }) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/api/doctor/$appointmentId/growth'),
          headers: await _getHeaders(),
          body: jsonEncode({'height': height, 'weight': weight}),
        )
        .timeout(const Duration(seconds: 15));

    return response.body;
  }

  // 2a) إضافة دواء واحد (يستخدم recordId الناتج عن حفظ التشخيص)
  Future<String> addMedication(
    int recordId, {
    required String name,
    required String dosage,
    required String frequency,
    required String timing,
    required String duration,
  }) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/api/doctor/$recordId/medications'),
          headers: await _getHeaders(),
          body: jsonEncode({
            'name': name,
            'dosage': dosage,
            'frequency': frequency,
            'timing': timing,
            'duration': duration,
          }),
        )
        .timeout(const Duration(seconds: 15));

    return response.body;
  }

  // 2b) طلب تحاليل وصور أشعة (نص حر — يُستخدم appointmentId لا recordId)
  Future<String> saveMedicalRequests(
    int appointmentId, {
    String? requiredTests,
    String? requiredImaging,
  }) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/api/doctor/$appointmentId/medicalRequests'),
          headers: await _getHeaders(),
          body: jsonEncode({
            'required_tests': requiredTests,
            'required_imaging': requiredImaging,
          }),
        )
        .timeout(const Duration(seconds: 15));

    return response.body;
  }

  // 2c) إنهاء المعاينة (لاحظ المسار /doctors/ وأنه GET بدون بادئة /doctor)
  Future<String> completeAppointment(int appointmentId) async {
    return (await http.get(
      Uri.parse('$baseUrl/api/doctors/$appointmentId/completeAppointment'),
      headers: await _getHeaders(),
    )).body;
  }
}

```

### File: lib\core\apis\home\home_api.dart
```dart
import 'package:http/http.dart' as http;

import 'package:get/get.dart';
import '../../constants.dart';
import '../../helper/secure_storage_service.dart';

class HomeApi {
  Future<Map<String, String>> _getHeaders() async {
    final token = await SecureStorage.getToken();
    final String currentLocale = Get.locale?.languageCode ?? 'en';
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Accept-Language': currentLocale,
      'Authorization': 'Bearer $token',
    };
  }

  Future<String> getDoctorHome() async {
    return (await http.get(Uri.parse('$baseUrl/api/doctor/home'), headers: await _getHeaders())).body;
  }

  Future<String> getTodayAppointmentsCount() async {
    return (await http.get(Uri.parse('$baseUrl/api/doctor/today-appointments-count'), headers: await _getHeaders())).body;
  }

  Future<String> getNextPatient() async {
    return (await http.get(Uri.parse('$baseUrl/api/doctor/next-patient'), headers: await _getHeaders())).body;
  }

  Future<String> getRemainingPatients() async {
    return (await http.get(Uri.parse('$baseUrl/api/doctor/remaining-patients'), headers: await _getHeaders())).body;
  }

  // ─── مسار جديد: جلب المواعيد حسب التاريخ المحدد ───
  Future<String> getAppointmentsByDate(String date) async {
    return (await http.get(Uri.parse('$baseUrl/api/doctor/appointmentsByDate?date=$date'), headers: await _getHeaders())).body;
  }

  Future<String> getCompletedAppointmentsToday() async {
    return (await http.get(Uri.parse('$baseUrl/api/doctor/completed-appointments-today'), headers: await _getHeaders())).body;
  }

  Future<String> getMonthlyRevenue() async {
    return (await http.get(Uri.parse('$baseUrl/api/doctor/monthlyRevenue'), headers: await _getHeaders())).body;
  }

  Future<String> completeAppointment(int appointmentId) async {
    return (await http.get(Uri.parse('$baseUrl/api/doctors/$appointmentId/completeAppointment'), headers: await _getHeaders())).body;
  }
}
```

### File: lib\core\apis\revenue\revenue_api.dart
```dart
// TODO: implement real HTTP calls when backend is ready.
// All methods below are placeholders — the repo currently returns mock data directly.

class RevenueApi {
  Future<String> getMonthlyRevenue() async => '';
  Future<String> getRevenueChartData() async => '';
  Future<String> getTransactions() async => '';
  Future<String> getTotalPaidVisits() async => '';
}

```

### File: lib\core\apis\schedule\appointment_details_api.dart
```dart
import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import '../../constants.dart';
import '../../helper/secure_storage_service.dart';

class AppointmentDetailsApi {
  Future<Map<String, String>> _getHeaders() async {
    final token = await SecureStorage.getToken();
    final String currentLocale = Get.locale?.languageCode ?? 'en';
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Accept-Language': currentLocale,
      'Authorization': 'Bearer $token',
    };
  }

  Future<String> getAppointmentDetails(int appointmentId) async {
    final url = Uri.parse('$baseUrl/api/doctor/appointments/$appointmentId');
    final response = await http.get(url, headers: await _getHeaders());
    return response.body;
  }
}
```

### File: lib\core\apis\schedule\patients_api.dart
```dart
import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import '../../constants.dart';
import '../../helper/secure_storage_service.dart';

class PatientsApi {
  Future<Map<String, String>> _getHeaders() async {
    final token = await SecureStorage.getToken();
    final String currentLocale = Get.locale?.languageCode ?? 'en';
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Accept-Language': currentLocale,
      'Authorization': 'Bearer $token',
    };
  }

  Future<String> getAllPatients({String? query}) async {
    String urlStr = '$baseUrl/api/doctor/patients';
    if (query != null && query.trim().isNotEmpty) {
      urlStr += '?search=${query.trim()}';
    }
    final url = Uri.parse(urlStr);
    final response = await http.get(url, headers: await _getHeaders());
    return response.body;
  }
}
```

### File: lib\core\apis\schedule\schedule_api.dart
```dart
import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import '../../constants.dart';
import '../../helper/secure_storage_service.dart';

class ScheduleApi {
  Future<Map<String, String>> _getHeaders() async {
    final token = await SecureStorage.getToken();
    final String currentLocale = Get.locale?.languageCode ?? 'en';
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Accept-Language': currentLocale,
      'Authorization': 'Bearer $token',
    };
  }

  // تم تحديث الراوت ليطابق المطلوب
  Future<String> getAppointmentsByDate(String date) async {
    final url = Uri.parse('$baseUrl/api/doctor/appointmentsByDate?date=$date');
    final response = await http.get(url, headers: await _getHeaders());
    return response.body;
  }

  Future<String> getUpcomingWorkingDays() async {
    final url = Uri.parse('$baseUrl/api/doctor/upcomingWorkingDays');
    final response = await http.get(url, headers: await _getHeaders());
    return response.body;
  }
}
```

### File: lib\core\apis\settings\doctor_availability_api.dart
```dart
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:get/get.dart';

import '../../constants.dart';
import '../../helper/secure_storage_service.dart';



class DoctorAvailabilityApi {
  Future<Map<String, String>> _getHeaders() async {
    final token = await SecureStorage.getToken();
    final String currentLocale = Get.locale?.languageCode ?? 'en';
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Accept-Language': currentLocale,
      'Authorization': 'Bearer $token',
    };
  }

  // إرسال البيانات كـ JSON مع الحقول المطلوبة في الباك إند
  Future<http.Response> addAvailability({
    required String dayOfWeek,
    required String startTime,
    required String endTime,
  }) async {
    final url = Uri.parse('$baseUrl/api/doctor-availabilities');

    final response = await http.post(
      url,
      headers: await _getHeaders(),
      body: jsonEncode({
        'day_of_week': dayOfWeek,
        'start_time': startTime,
        'end_time': endTime,
      }),
    ).timeout(const Duration(seconds: 15));

    return response;
  }
}
```

### File: lib\core\constants.dart
```dart

const String baseUrl = 'http://192.168.1.8:8000';


String token = '';
```

### File: lib\core\helper\secure_storage_service.dart
```dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants.dart';

const secureStorage = FlutterSecureStorage();

class SecureStorage {
  static Future<void> removeAll() async {
    await secureStorage.delete(key: 'token');
    token = '';
    await secureStorage.delete(key: 'refreshToken');
    await secureStorage.delete(key: 'email');
  }

  static Future<void> storeToken(String token) async {
    await secureStorage.write(key: 'token', value: token);
  }

  static Future<String> getToken() async {
    return await secureStorage.read(key: 'token') ?? '';
  }

  static Future<void> removeToken() async {
    await secureStorage.delete(key: 'token');
  }

  static Future<void> storeRefreshToken(String token) async {
    await secureStorage.write(key: 'refreshToken', value: token);
  }

  static Future<String> getRefreshToken() async {
    return await secureStorage.read(key: 'refreshToken') ?? '';
  }

  static Future<void> removeRefreshToken() async {
    await secureStorage.delete(key: 'refreshToken');
  }

  // حفظ كود اللغة ('en' أو 'ar')
  static Future<void> storeLanguage(String langCode) async {
    await secureStorage.write(key: 'language', value: langCode);
  }

  // استرجاع كود اللغة
  static Future<String?> getLanguage() async {
    return await secureStorage.read(key: 'language');
  }
}

```

### File: lib\core\localization\app_translations.dart
```dart
import 'package:get/get.dart';

class AppTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
    // القاموس الإنجليزي
    'en_US': {
      // --- Login View ---
      'Doctor Login': 'Doctor Login',
      'Welcome back to Clinic Management System':
      'Welcome back to Clinic Management System',
      'Mobile Number': 'Mobile Number',
      'Please enter mobile number': 'Please enter mobile number',
      'Invalid mobile number': 'Invalid mobile number',
      'Password': 'Password',
      'Please enter password': 'Please enter password',
      'Login': 'Login',
      'Success': 'Success',
      'Error': 'Error',

      //schedule
      'Appointments Schedule': 'Appointments Schedule',
      'All': 'All',
      'minutes': 'minutes',
      'Yrs': 'Years',
      'AM': 'AM',
      'PM': 'PM',
      'No appointments for this date': 'No appointments for this date',
      'Appointment Details': 'Appointment Details',
      'Appointment Info': 'Appointment Info',
      'Parents Notes': 'Parents Notes',
      'Date': 'Date',
      'Time': 'Time',
      'Appointment Type': 'Appointment Type',
      'Payment Status': 'Payment Status',
      'Consultation Fee': 'Consultation Fee',
      'File No': 'File No',
      'Cancel Appointment': 'Cancel Appointment',
      'Start Consultation': 'Start Consultation',
      'partially_paid': 'Partially Paid',
      'paid': 'Paid Electronic',
      'unpaid': 'Unpaid',
      'Periodic checkup': 'Periodic checkup',
      'Sunday': 'Sunday', // أضف بقية الأيام
      'Monday': 'Monday',
      'Tuesday': 'Tuesday',
      'Wednesday': 'Wednesday',
      'Thursday': 'Thursday',
      'Friday': 'Friday',
      'Saturday': 'Saturday',
      'Search for patient name or file number':
      'Search for patient name or file number',
      'View Medical File': 'View Medical File',
      'Phone': 'Phone',
      'No patients found': 'No patients found',

      // --- Home View ---

      // --- Home & Dashboard View ---
      'Hello': 'Hello',
      'Today': 'Today',
      'Appointments': 'Appointments',
      'Remaining Patients': 'Remaining Patients',
      'No remaining patients for today': 'No remaining patients for today',
      'Cancel': 'Cancel',
      'Done': 'Done',
      'male': 'Male',
      'female': 'Female',
      'Total': 'Total',
      'Home': 'Home',
      'Revenue': 'Revenue',
      'Profile': 'Profile',
      "Today's Total": "Today's Total",
      'Completed': 'Completed',
      'Monthly Rev': 'Monthly Rev',
      'Schedule': 'Schedule',
      'Settings': 'Settings',
      'No remaining patients for this date':
      'No remaining patients for this date',
      'Patients': 'Patients',

      // --- Revenue View ---
      'Wallet': 'Wallet',
      'Total Monthly Income': 'Total Monthly Income',
      'SAR': 'SAR',
      'Total Paid Visits': 'Total Paid Visits',
      'Visit': 'Visit',
      'Revenue Overview': 'Revenue Overview',
      'Recent Transactions': 'Recent Transactions',
      'View All Transactions': 'View All Transactions',
      'No transactions yet': 'No transactions yet',
      'No data': 'No data',
      'May': 'May',

      // --- Examination View ---
      'Patient Examination': 'Patient Examination',
      'Measurements': 'Measurements',
      'Diagnosis': 'Diagnosis',
      'Prescription': 'Prescription',
      'Clinical Diagnosis': 'Clinical Diagnosis',
      'General Doctor Notes': 'General Doctor Notes',
      'Write the clinical diagnosis for the case':
      'Write the clinical diagnosis for the case',
      "Write any general notes about the child's condition":
      "Write any general notes about the child's condition",
      'Optional': 'Optional',
      'Height': 'Height',
      'Weight': 'Weight',
      'Medications Prescription': 'Medications Prescription',
      'Add Medication': 'Add Medication',
      'Add Another Medication': 'Add Another Medication',
      'Medicine Name': 'Medicine Name',
      'Dosage': 'Dosage',
      'Quantity': 'Quantity',
      'Instructions': 'Instructions',
      'Duration': 'Duration',
      'Lab & Imaging Requests': 'Lab & Imaging Requests',
      'Add Request': 'Add Request',
      'No requests added': 'No requests added',
      'Test': 'Test',
      'Imaging': 'Imaging',
      'Request Value': 'Request Value',
      'Add': 'Add',
      'Save & Continue': 'Save & Continue',
      'Save & Finish Examination': 'Save & Finish Examination',
      'Diagnosis saved successfully': 'Diagnosis saved successfully',
      'Please enter the diagnosis': 'Please enter the diagnosis',
      'Please enter both height and weight':
      'Please enter both height and weight',
      'Please save the diagnosis first': 'Please save the diagnosis first',
      'Please complete all medication fields':
      'Please complete all medication fields',

      // --- Settings Section (New) ---
      'Working Settings': 'Working Settings',
      'Manage working hours and availability':
      'Manage working hours and availability',
      'Change Password': 'Change Password',
      'Update your account password': 'Update your account password',
      'Language': 'Language',
      'Theme': 'Theme',
      'Customize app language and view': 'Customize app language and view',
      'Delete Account': 'Delete Account',
      'Permanently delete your account from the app':
      'Permanently delete your account from the app',

      // --- Availability View ---
      'Clinic Settings': 'Clinic Settings',
      'Enter Working Day': 'Enter Working Day',
      'Day': 'Day',
      'Start Time': 'Start Time',
      'End Time': 'End Time',
      'This day will be saved as your available working hours.':
      'This day will be saved as your available working hours.',
      'Save Working Hours': 'Save Working Hours',
      'monday': 'Monday',
      'tuesday': 'Tuesday',
      'wednesday': 'Wednesday',
      'thursday': 'Thursday',
      'friday': 'Friday',
      'saturday': 'Saturday',
      'sunday': 'Sunday',
      'System Language': 'System Language',
      'Arabic': 'Arabic',
      'English': 'English',
      'Start Examination': 'Start Examination',
      'Current Patients': 'Current Patients',
      'Yrs': 'Yrs',
      'Change Password?': 'Change Password?',
      'Enter your registered mobile number to reset your password.':
      'Enter your registered mobile number to reset your password.',
      'Phone number must be exactly 12 digits and start with 963':
      'Phone number must be exactly 12 digits and start with 963',
      'Send OTP': 'Send OTP',
      'Verify OTP': 'Verify OTP',
      'A 4-digit code has been sent to your registered number.':
      'A 4-digit code has been sent to your registered number.',
      'Please enter a valid 4-digit OTP': 'Please enter a valid 4-digit OTP',
      'Verify': 'Verify',
      'Create New Password': 'Create New Password',
      'Your new password must be different from previous ones.':
      'Your new password must be different from previous ones.',
      'New Password': 'New Password',
      'Confirm Password': 'Confirm Password',
      'Password must be at least 6 characters long':
      'Password must be at least 6 characters long',
      'Passwords do not match': 'Passwords do not match',
      'Reset Password': 'Reset Password',
    },

    // القاموس العربي
    'ar_SY': {
      // --- Login View ---
      'Doctor Login': 'تسجيل دخول الطبيب',
      'Welcome back to Clinic Management System':
      'مرحباً بك مجدداً في نظام إدارة العيادة',
      'Mobile Number': 'رقم الموبايل',
      'Please enter mobile number': 'الرجاء إدخال رقم الموبايل',
      'Invalid mobile number': 'رقم الموبايل غير صالح',
      'Password': 'كلمة المرور',
      'Please enter password': 'الرجاء إدخال كلمة المرور',
      'Login': 'تسجيل الدخول',
      'Success': 'نجاح',
      'Error': 'خطأ',

      //schedule
      'Appointments Schedule': 'جدول المواعيد',
      'All': 'الكل',
      'minutes': 'دقائق',
      'Yrs': 'سنوات',
      'AM': 'ص',
      'PM': 'م',
      'No appointments for this date': 'لا يوجد مواعيد في هذا التاريخ',
      'Appointment Details': 'تفاصيل الموعد',
      'Appointment Info': 'معلومات الموعد',
      'Parents Notes': 'ملاحظات الأهل',
      'Date': 'التاريخ',
      'Time': 'الوقت',
      'Appointment Type': 'نوع الموعد',
      'Payment Status': 'حالة الدفع',
      'Consultation Fee': 'رسوم الكشف',
      'File No': 'رقم الملف',
      'Cancel Appointment': 'إلغاء الموعد',
      'Start Consultation': 'بدء المعاينة',
      'partially_paid': 'مدفوع جزئياً',
      'paid': 'مدفوع إلكترونياً',
      'unpaid': 'غير مدفوع',
      'Periodic checkup': 'معاينة دورية',
      'Sunday': 'الأحد', //
      'Monday': 'الاثنين',
      'Tuesday': 'الثلاثاء',
      'Wednesday': 'الأربعاء',
      'Thursday': 'الخميس',
      'Friday': 'الجمعة',
      'Saturday': 'السبت',
      'Search for patient name or file number':
      'ابحث عن اسم الطفل أو رقم الملف',
      'View Medical File': 'عرض الملف الطبي',
      'Phone': 'الهاتف',
      'No patients found': 'لم يتم العثور على مرضى',

      // --- Home View ---

      // --- Home & Dashboard View ---
      'Hello': 'مرحباً',
      'Today': 'اليوم',
      'Appointments': 'مواعيد',
      'Remaining Patients': 'المرضى المتبقين',
      'No remaining patients for today': 'لا يوجد مرضى متبقين لهذا اليوم',
      'Cancel': 'إلغاء',
      'Done': 'إتمام',
      'male': 'ذكر',
      'female': 'أنثى',
      'Total': 'الكلي',
      'Home': 'الرئيسية',
      'Revenue': 'الأرباح',
      'Profile': 'الحساب',
      "Today's Total": "إجمالي اليوم",
      'Completed': 'المكتملة',
      'Monthly Rev': 'أرباح الشهر',
      'Schedule': 'الجدول',
      'Settings': 'الإعدادات',
      'No remaining patients for this date': 'لا يوجد مرضى متبقين لهذا التاريخ',
      'Patients': 'المرضى',

      // --- Revenue View ---
      'Wallet': 'المحفظة',
      'Total Monthly Income': 'إجمالي الدخل الشهري',
      'SAR': 'ريال',
      'Total Paid Visits': 'إجمالي الزيارات المدفوعة',
      'Visit': 'زيارة',
      'Revenue Overview': 'نظرة عامة على الإيرادات',
      'Recent Transactions': 'أحدث المعاملات',
      'View All Transactions': 'عرض جميع المعاملات',
      'No transactions yet': 'لا توجد معاملات بعد',
      'No data': 'لا توجد بيانات',
      'May': 'مايو',

      // --- Examination View ---
      'Patient Examination': 'معاينة المريض',
      'Measurements': 'القياسات',
      'Diagnosis': 'التشخيص',
      'Prescription': 'الوصفة',
      'Clinical Diagnosis': 'التشخيص السريري',
      'General Doctor Notes': 'ملاحظات الطبيب العامة',
      'Write the clinical diagnosis for the case':
      'اكتب التشخيص السريري للحالة',
      "Write any general notes about the child's condition":
      'اكتب أي ملاحظات عامة حول حالة الطفل',
      'Optional': 'اختياري',
      'Height': 'الطول',
      'Weight': 'الوزن',
      'Medications Prescription': 'وصفة الأدوية',
      'Add Medication': 'إضافة دواء',
      'Add Another Medication': 'إضافة دواء آخر',
      'Medicine Name': 'اسم الدواء',
      'Dosage': 'الجرعة',
      'Quantity': 'الكمية',
      'Instructions': 'التعليمات',
      'Duration': 'المدة',
      'Lab & Imaging Requests': 'طلب تحاليل وصور أشعة',
      'Add Request': 'إضافة طلب',
      'No requests added': 'لا توجد طلبات مضافة',
      'Test': 'تحليل',
      'Imaging': 'صورة أشعة',
      'Request Value': 'قيمة الطلب',
      'Add': 'إضافة',
      'Save & Continue': 'حفظ وتقدم',
      'Save & Finish Examination': 'حفظ وإنهاء المعاينة',
      'Diagnosis saved successfully': 'تم حفظ التشخيص بنجاح',
      'Please enter the diagnosis': 'الرجاء إدخال التشخيص',
      'Please enter both height and weight': 'الرجاء إدخال الطول والوزن معاً',
      'Please save the diagnosis first': 'الرجاء حفظ التشخيص أولاً',
      'Please complete all medication fields': 'الرجاء إكمال جميع حقول الدواء',

      // --- Settings Section (New) ---
      'Working Settings': 'إعدادات العمل',
      'Manage working hours and availability': 'إدارة أوقات العمل والتوافر',
      'Change Password': 'تغيير كلمة المرور',
      'Update your account password': 'تحديث كلمة المرور لحسابك',
      'Language': 'اللغة',
      'Theme': 'المظهر',
      'Customize app language and view': 'تخصيص لغة التطبيق والمظهر',
      'Delete Account': 'حذف الحساب',
      'Permanently delete your account from the app':
      'حذف حسابك بشكل دائم من التطبيق',

      // --- Availability View ---
      'Clinic Settings': 'إعدادات العيادة',
      'Enter Working Day': 'أدخل يوم العمل',
      'Day': 'اليوم',
      'Start Time': 'وقت البداية',
      'End Time': 'وقت النهاية',
      'This day will be saved as your available working hours.':
      'سيتم حفظ هذا اليوم باعتباره وقت دوامك المتاح.',
      'Save Working Hours': 'حفظ وقت الدوام',
      'monday': 'الاثنين',
      'tuesday': 'الثلاثاء',
      'wednesday': 'الأربعاء',
      'thursday': 'الخميس',
      'friday': 'الجمعة',
      'saturday': 'السبت',
      'sunday': 'الأحد',
      'System Language': 'لغة النظام',
      'Arabic': 'العربية',
      'English': 'الإنجليزية',
      'Start Examination': 'بدء الفحص',
      'Current Patients': 'المرضى الحاليون',
      'Yrs': 'سنوات',
      'Change Password?': 'تغيير كلمة المرور؟',
      'Enter your registered mobile number to reset your password.':
      'أدخل رقم الموبايل المسجل لإعادة ضبط كلمة المرور الخاصة بك.',
      'Phone number must be exactly 12 digits and start with 963':
      'رقم الهاتف يجب أن يكون 12 رقماً ويبدأ بـ 963',
      'Send OTP': 'إرسال الرمز',
      'Verify OTP': 'تأكيد الرمز',
      'A 4-digit code has been sent to your registered number.':
      'تم إرسال رمز من 4 أرقام إلى رقمك المسجل.',
      'Please enter a valid 4-digit OTP': 'الرجاء إدخال رمز صحيح من 4 أرقام',
      'Verify': 'تأكيد',
      'Create New Password': 'إنشاء كلمة مرور جديدة',
      'Your new password must be different from previous ones.':
      'يجب أن تكون كلمة المرور الجديدة مختلفة عن السابقة.',
      'New Password': 'كلمة المرور الجديدة',
      'Confirm Password': 'تأكيد كلمة المرور',
      'Password must be at least 6 characters long':
      'كلمة المرور يجب أن لا تقل عن 6 أحرف',
      'Passwords do not match': 'كلمتا المرور غير متطابقتين',
      'Reset Password': 'إعادة ضبط كلمة المرور',
    },
  };
}

```

### File: lib\core\repos\auth\login_repo.dart
```dart
import 'dart:convert';

import '../../../models/auth/login_model.dart';
import '../../apis/auth/login_api.dart';

class LoginRepo {
  final LoginApi api;
  LoginRepo({required this.api});

  Future<LoginModel> login({required String phone, required String password}) async {
    String rawResponse = await api.login(phone: phone, password: password);

    if (rawResponse.contains('{')) {
      rawResponse = rawResponse.substring(rawResponse.indexOf('{'));
    }

    final Map<String, dynamic> decodedJson = jsonDecode(rawResponse);
    return LoginModel.fromJson(decodedJson);
  }
}
```

### File: lib\core\repos\auth\password_reset_repo.dart
```dart
import 'dart:convert';
import '../../apis/auth/password_reset_api.dart';

class PasswordResetRepo {
  final PasswordResetApi api;
  PasswordResetRepo({required this.api});

  String _cleanJson(String response) {
    if (response.contains('{')) return response.substring(response.indexOf('{'));
    return response;
  }

  void _handleErrorResponse(int statusCode, String body) {
    if (statusCode != 200 && statusCode != 201) {
      final decoded = jsonDecode(_cleanJson(body));
      throw Exception(decoded['message'] ?? 'An error occurred');
    }
  }

  Future<String> sendOtp(String phone) async {
    final res = await api.sendOtp(phone);
    _handleErrorResponse(res.statusCode, res.body);
    return jsonDecode(_cleanJson(res.body))['message'] ?? 'OTP sent';
  }

  Future<String> verifyOtp(String phone, String otp) async {
    final res = await api.verifyOtp(phone, otp);
    _handleErrorResponse(res.statusCode, res.body);
    return jsonDecode(_cleanJson(res.body))['message'] ?? 'Verified successfully';
  }

  Future<String> setPassword(String phone, String password, String confirmation) async {
    final res = await api.setPassword(phone, password, confirmation);
    _handleErrorResponse(res.statusCode, res.body);
    return jsonDecode(_cleanJson(res.body))['message'] ?? 'Password updated';
  }
}
```

### File: lib\core\repos\examination\examination_repo.dart
```dart
import 'dart:convert';
import '../../../models/examination/diagnosis_record_model.dart';
import '../../../models/examination/medication_model.dart';
import '../../../models/home/doctor_dashboard_model.dart';
import '../../apis/examination/examination_api.dart';

class ExaminationRepo {
  final ExaminationApi api;
  ExaminationRepo({required this.api});

  String _cleanJson(String response) {
    if (response.contains('{')) return response.substring(response.indexOf('{'));
    if (response.contains('[')) return response.substring(response.indexOf('['));
    return response;
  }

  Future<PatientModel?> getNextPatient() async {
    final res = await api.getNextPatient();
    final decoded = jsonDecode(_cleanJson(res));
    if (decoded['message'] == 'No upcoming patients') return null;
    return PatientModel.fromJson(decoded);
  }

  Future<DiagnosisRecordModel> saveDiagnosis(
    int appointmentId, {
    required String diagnosis,
    String? doctorNotes,
  }) async {
    final res = await api.saveDiagnosis(
      appointmentId,
      diagnosis: diagnosis,
      doctorNotes: doctorNotes,
    );
    final decoded = jsonDecode(_cleanJson(res));
    return DiagnosisRecordModel.fromJson(decoded['record']);
  }

  Future<String> saveGrowth(
    int appointmentId, {
    required num height,
    required num weight,
  }) async {
    final res = await api.saveGrowth(
      appointmentId,
      height: height,
      weight: weight,
    );
    return jsonDecode(_cleanJson(res))['message'] ?? 'Success';
  }

  Future<MedicationModel> addMedication(
    int recordId, {
    required String name,
    required String dosage,
    required String frequency,
    required String timing,
    required String duration,
  }) async {
    final res = await api.addMedication(
      recordId,
      name: name,
      dosage: dosage,
      frequency: frequency,
      timing: timing,
      duration: duration,
    );
    final decoded = jsonDecode(_cleanJson(res));
    return MedicationModel.fromJson(decoded['medication']);
  }

  Future<String> saveMedicalRequests(
    int appointmentId, {
    String? requiredTests,
    String? requiredImaging,
  }) async {
    final res = await api.saveMedicalRequests(
      appointmentId,
      requiredTests: requiredTests,
      requiredImaging: requiredImaging,
    );
    return jsonDecode(_cleanJson(res))['message'] ?? 'Success';
  }

  Future<String> completeAppointment(int appointmentId) async {
    final res = await api.completeAppointment(appointmentId);
    return jsonDecode(_cleanJson(res))['message'] ?? 'Success';
  }
}

```

### File: lib\core\repos\home\home_repo.dart
```dart
import 'dart:convert';
import '../../../models/home/doctor_dashboard_model.dart';
import '../../apis/home/home_api.dart';

class HomeRepo {
  final HomeApi api;
  HomeRepo({required this.api});

  // ─── الحل الجذري لمشكلة قص الـ JSON غير الصالح ───
  String _cleanJson(String response) {

    final brace = response.indexOf('{');
    final bracket = response.indexOf('[');
    // ابدأ من أول قوس يظهر فعليًا (كائن أو مصفوفة) حتى لا نقصّ مصفوفة تبدأ بـ [.
    if (bracket != -1 && (brace == -1 || bracket < brace)) {
      return response.substring(bracket);
    }
    if (brace != -1) return response.substring(brace);

    final startIndex = response.indexOf(RegExp(r'[\{\[]'));
    if (startIndex != -1) {
      return response.substring(startIndex);
    }

    return response;
  }

  Future<DoctorHomeModel> getDoctorHome() async {
    final res = await api.getDoctorHome();
    return DoctorHomeModel.fromJson(jsonDecode(_cleanJson(res)));
  }

  Future<int> getTodayAppointmentsCount() async {
    final res = await api.getTodayAppointmentsCount();
    return jsonDecode(_cleanJson(res))['count'] ?? 0;
  }

  Future<PatientModel?> getNextPatient() async {
    final res = await api.getNextPatient();
    final decoded = jsonDecode(_cleanJson(res));
    if (decoded['message'] == 'No upcoming patients') return null;
    return PatientModel.fromJson(decoded);
  }

  Future<List<PatientModel>> getRemainingPatients() async {
    final res = await api.getRemainingPatients();
    final decoded = jsonDecode(_cleanJson(res));
    if (decoded is List) {
      return decoded.map((e) => PatientModel.fromJson(e)).toList();
    }
    return [];
  }

  // ─── جلب وتحليل المواعيد حسب التاريخ للـ Picker ───
  Future<List<PatientModel>> getAppointmentsByDate(String date) async {
    final res = await api.getAppointmentsByDate(date);
    final decoded = jsonDecode(_cleanJson(res));
    if (decoded['status'] == 'success' && decoded['data'] != null && decoded['data']['appointments'] is List) {
      return (decoded['data']['appointments'] as List).map((e) => PatientModel.fromJson(e)).toList();
    }
    return [];
  }

  Future<int> getCompletedAppointmentsToday() async {
    final res = await api.getCompletedAppointmentsToday();
    return jsonDecode(_cleanJson(res))['completed_appointments'] ?? 0;
  }

  Future<double> getMonthlyRevenue() async {
    final res = await api.getMonthlyRevenue();
    return double.tryParse(jsonDecode(_cleanJson(res))['monthly_revenue']?.toString() ?? '0') ?? 0.0;
  }

  Future<String> completeAppointment(int id) async {
    final res = await api.completeAppointment(id);
    return jsonDecode(_cleanJson(res))['message'] ?? 'Success';
  }
}
```

### File: lib\core\repos\revenue\revenue_repo.dart
```dart
import '../../../models/revenue/transaction_model.dart';
import '../../apis/revenue/revenue_api.dart';

class RevenueRepo {
  final RevenueApi api;
  RevenueRepo({required this.api});

  // ─── Mock data — swap these bodies for real API calls when backend is ready ──

  Future<double> getMonthlyRevenue() async {
    // await api.getMonthlyRevenue();
    return 15600;
  }

  Future<int> getTotalPaidVisits() async {
    // await api.getTotalPaidVisits();
    return 156;
  }

  /// Revenue values for the chart (one per day of the month).
  /// Fluctuates up and down while trending upward, peaking at the 15,600
  /// monthly total shown in the header.
  Future<List<double>> getRevenueChartData() async {
    // await api.getRevenueChartData();
    return [
      1500, 3200, 2400, 4800, 3600, 6200, 4500,
      7400, 5800, 8600, 6900, 9800, 7600, 10900,
      8400, 11800, 9200, 12600, 10100, 13400, 10800,
      14100, 11500, 14800, 12200, 13600, 12900, 14500,
      15600,
    ];
  }

  Future<List<TransactionModel>> getTransactions() async {
    // await api.getTransactions();
    return [
      TransactionModel(id: 1, patientName: 'آدم محمد',    date: '12 مايو 2024', amount: 150, paymentMethod: 'stripe'),
      TransactionModel(id: 2, patientName: 'لينا خالد',   date: '12 مايو 2024', amount: 150, paymentMethod: 'stripe'),
      TransactionModel(id: 3, patientName: 'يوسف عبدالله', date: '11 مايو 2024', amount: 150, paymentMethod: 'stripe'),
      TransactionModel(id: 4, patientName: 'لينا محمد',   date: '11 مايو 2024', amount: 150, paymentMethod: 'stripe'),
      TransactionModel(id: 5, patientName: 'سارة أحمد',   date: '10 مايو 2024', amount: 150, paymentMethod: 'stripe'),
    ];
  }
}

```

### File: lib\core\repos\schedule\appointment_details_repo.dart
```dart
import 'dart:convert';
import '../../../models/schedule/appointment_details_model.dart';
import '../../apis/schedule/appointment_details_api.dart';

class AppointmentDetailsRepo {
  final AppointmentDetailsApi api;
  AppointmentDetailsRepo({required this.api});

  Future<AppointmentDetailsModel> getDetails(int id) async {
    final res = await api.getAppointmentDetails(id);

    String cleanRes = res;
    if (cleanRes.contains('{')) {
      cleanRes = cleanRes.substring(cleanRes.indexOf('{'));
    }

    final decoded = jsonDecode(cleanRes);

    if (decoded['status'] == true && decoded['data'] != null) {
      return AppointmentDetailsModel.fromJson(decoded['data']);
    } else {
      throw Exception(decoded['message'] ?? 'Failed to fetch details');
    }
  }
}
```

### File: lib\core\repos\schedule\patients_repo.dart
```dart
import 'dart:convert';
import '../../../models/schedule/patient_list_model.dart';
import '../../apis/schedule/patients_api.dart';

class PatientsRepo {
  final PatientsApi api;
  PatientsRepo({required this.api});

  String _cleanJson(String response) {
    int curlyIndex = response.indexOf('{');
    int squareIndex = response.indexOf('[');
    if (curlyIndex == -1 && squareIndex == -1) return response;
    if (curlyIndex != -1 && squareIndex != -1) {
      int startIndex = curlyIndex < squareIndex ? curlyIndex : squareIndex;
      return response.substring(startIndex);
    }
    return curlyIndex != -1 ? response.substring(curlyIndex) : response.substring(squareIndex);
  }

  Future<List<PatientListModel>> getPatients({String? query}) async {
    final res = await api.getAllPatients(query: query);
    final decoded = jsonDecode(_cleanJson(res));

    if (decoded['status'] == true && decoded['patients'] != null) {
      final List list = decoded['patients'];
      return list.map((e) => PatientListModel.fromJson(e)).toList();
    }
    return [];
  }
}
```

### File: lib\core\repos\schedule\schedule_repo.dart
```dart
import 'dart:convert';
import '../../../models/schedule/schedule_model.dart';
import '../../apis/schedule/schedule_api.dart';

class ScheduleRepo {
  final ScheduleApi api;
  ScheduleRepo({required this.api});

  Future<ScheduleDataModel> getSchedule(String date) async {
    final res = await api.getAppointmentsByDate(date);

    String cleanRes = res;
    if (cleanRes.contains('{')) {
      cleanRes = cleanRes.substring(cleanRes.indexOf('{'));
    }

    final decoded = jsonDecode(cleanRes);

    // تم التعديل للتحقق من status: success والدخول إلى كائن data
    if (decoded['status'] == 'success' && decoded['data'] != null) {
      return ScheduleDataModel.fromJson(decoded['data']);
    } else {
      throw Exception(decoded['message'] ?? 'Failed to fetch schedule');
    }
  }

  Future<List<DateTime>> getWorkingDays() async {
    final res = await api.getUpcomingWorkingDays();

    String cleanRes = res;
    if (cleanRes.contains('{')) {
      cleanRes = cleanRes.substring(cleanRes.indexOf('{'));
    }

    final decoded = jsonDecode(cleanRes);
    if (decoded['status'] == 'success' && decoded['days'] != null) {
      final List daysList = decoded['days'];
      return daysList.map((e) => DateTime.parse(e['date'].toString())).toList();
    }
    return [];
  }
}
```

### File: lib\core\repos\settings\doctor_availability_repo.dart
```dart
import 'dart:convert';

import '../../../models/settings/doctor_availability_model.dart';
import '../../apis/settings/doctor_availability_api.dart';



class DoctorAvailabilityRepo {
  final DoctorAvailabilityApi api;
  DoctorAvailabilityRepo({required this.api});

  String _cleanJson(String response) {
    if (response.contains('{')) {
      return response.substring(response.indexOf('{'));
    }
    return response;
  }

  Future<DoctorAvailabilityModel> addAvailability({
    required String dayOfWeek,
    required String startTime,
    required String endTime,
  }) async {
    final response = await api.addAvailability(
      dayOfWeek: dayOfWeek,
      startTime: startTime,
      endTime: endTime,
    );

    final cleanedBody = _cleanJson(response.body);
    final Map<String, dynamic> decodedJson = jsonDecode(cleanedBody);

    // ─── التقاط خطأ التضارب 422 الموضح في البوست مان وتمريره للـ BaseController ───
    if (response.statusCode == 422 || response.statusCode == 400) {
      throw Exception(decodedJson['message'] ?? 'Time conflict or invalid data.');
    }

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Server error: ${response.statusCode}');
    }

    return DoctorAvailabilityModel.fromJson(decodedJson);
  }
}
```

### File: lib\core\theme\app_themes.dart
```dart
import 'package:flutter/material.dart';

class AppThemes {
  // ─── الوضع النهاري (مطابق لتصميمك الحالي تماماً) ───
  static final lightTheme = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFF0F4FF), // لون الخلفية العام
    cardColor: Colors.white, // لون البطاقات
    primaryColor: const Color(0xFF3B9EFF), // اللون الأساسي (الأزرق)
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFFF0F4FF),
      elevation: 0,
      iconTheme: IconThemeData(color: Color(0xFF1A2E5A)),
      titleTextStyle: TextStyle(
        color: Color(0xFF1A2E5A),
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
    textTheme: TextTheme(
      bodyLarge: const TextStyle(color: Color(0xFF1A2E5A)), // النصوص الأساسية
      bodyMedium: TextStyle(color: Colors.grey.shade600), // النصوص الثانوية
    ),
    dividerColor: const Color(0xFFE2E8F0),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: Color(0xFF3B9EFF),
      unselectedItemColor: Colors.grey,
    ),
  );

  // ─── الوضع الليلي (Dark Mode) ───
  static final darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF121212), // خلفية داكنة مريحة للعين
    cardColor: const Color(0xFF1E1E1E), // بطاقات بدرجة أفتح قليلاً
    primaryColor: const Color(0xFF3B9EFF),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF121212),
      elevation: 0,
      iconTheme: IconThemeData(color: Colors.white),
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
    textTheme: TextTheme(
      bodyLarge: const TextStyle(color: Colors.white),
      bodyMedium: TextStyle(color: Colors.grey.shade400),
    ),
    dividerColor: const Color(0xFF2C2C2C),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF1E1E1E),
      selectedItemColor: Color(0xFF3B9EFF),
      unselectedItemColor: Colors.grey,
    ),
  );
}
```

### File: lib\export_code.dart
```dart
import 'dart:io';

void main() {
  var dir = Directory('lib');

  var outputFile = File('my_project_code.md');
  var output = StringBuffer();

  if (dir.existsSync()) {
    output.writeln('# KidCare Project Code\n');

    // جلب كل الملفات داخل مجلد lib
    var files = dir.listSync(recursive: true);
    for (var file in files) {
      if (file is File && file.path.endsWith('.dart')) {
        output.writeln('### File: ${file.path}');
        output.writeln('```dart');
        output.writeln(file.readAsStringSync());
        output.writeln('```\n');
      }
    }

    outputFile.writeAsStringSync(output.toString());
    print(
      '  The operation was successful! The my_project_code.md file was created ',
    );
  } else {
    print(' lib folder not found !');
  }
}

```

### File: lib\main.dart
```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kidcare_pro/views/auth/password_reset_view.dart';
import 'package:kidcare_pro/views/settings/doctor_availability_view.dart';


import 'controllers/auth/password_reset_controller.dart';
import 'controllers/settings/doctor_availability_controller.dart';
import 'controllers/settings/settings_controller.dart';
import 'core/apis/auth/password_reset_api.dart';
import 'core/apis/settings/doctor_availability_api.dart';
import 'core/helper/secure_storage_service.dart';
import 'core/localization/app_translations.dart';

import 'core/repos/auth/password_reset_repo.dart';
import 'core/repos/settings/doctor_availability_repo.dart';
import 'core/theme/app_themes.dart';

// Login paths
import 'views/auth/login_view.dart';
import 'controllers/auth/login_controller.dart';
import 'core/apis/auth/login_api.dart';
import 'core/repos/auth/login_repo.dart';

// Home paths
import 'package:kidcare_pro/views/home/home_view.dart';
import 'controllers/home/home_controller.dart';
import 'core/apis/home/home_api.dart';
import 'core/repos/home/home_repo.dart';

// Examination paths
import 'views/examination/examination_view.dart';
import 'controllers/examination/examination_controller.dart';
import 'core/apis/examination/examination_api.dart';
import 'core/repos/examination/examination_repo.dart';

// Revenue paths
import 'views/revenue/revenue_view.dart';
import 'controllers/revenue/revenue_controller.dart';
import 'core/apis/revenue/revenue_api.dart';
import 'core/repos/revenue/revenue_repo.dart';

// Schedule paths
import 'views/schedule/schedule_view.dart';
import 'controllers/schedule/schedule_controller.dart';
import 'core/apis/schedule/schedule_api.dart';
import 'core/repos/schedule/schedule_repo.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'views/schedule/appointment_details_view.dart';
import 'controllers/schedule/appointment_details_controller.dart';
import 'core/apis/schedule/appointment_details_api.dart';
import 'core/repos/schedule/appointment_details_repo.dart';
import 'views/schedule/patients_view.dart';
import 'controllers/schedule/patients_controller.dart';
import 'core/apis/schedule/patients_api.dart';
import 'core/repos/schedule/patients_repo.dart';

void main() async {
  // لتهيئة فلاتر قبل تشغيل أي ميزة Native
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting();
  final String savedToken = await SecureStorage.getToken();
  final String initialRoute = savedToken.isNotEmpty ? '/doctor_home' : '/login';

  String? savedLang = await SecureStorage.getLanguage();
  Locale initialLocale;

  if (savedLang == null || savedLang == 'system') {
    Locale? deviceLocale =
        WidgetsBinding.instance.platformDispatcher.locales.isNotEmpty
        ? WidgetsBinding.instance.platformDispatcher.locales.first
        : null;

    if (deviceLocale != null && deviceLocale.languageCode == 'ar') {
      initialLocale = const Locale('ar', 'SY');
    } else {
      initialLocale = const Locale('en', 'US');
    }
  } else if (savedLang == 'ar') {
    initialLocale = const Locale('ar', 'SY');
  } else {
    initialLocale = const Locale('en', 'US');
  }

  runApp(MyApp(initialLocale: initialLocale, initialRoute: initialRoute));
}

class MyApp extends StatelessWidget {
  final Locale initialLocale;
  final String initialRoute;

  const MyApp({
    super.key,
    required this.initialLocale,
    required this.initialRoute,
  });

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      theme: AppThemes.lightTheme,
      darkTheme: AppThemes.darkTheme,
      themeMode: ThemeMode.system,

      title: 'KidCare Pro',
      debugShowCheckedModeBanner: false,

      translations: AppTranslations(),
      locale: initialLocale,
      fallbackLocale: const Locale('en', 'US'),

      initialRoute: initialRoute,

      getPages: [
        GetPage(
          name: '/login',
          page: () => const LoginView(),
          binding: BindingsBuilder(() {
            Get.lazyPut<LoginApi>(() => LoginApi());
            Get.lazyPut<LoginRepo>(() => LoginRepo(api: Get.find()));
            Get.lazyPut<LoginController>(
              () => LoginController(repo: Get.find()),
            );
          }),
        ),
        GetPage(
          name: '/appointment_details',
          page: () => const AppointmentDetailsView(),
          binding: BindingsBuilder(() {
            Get.lazyPut<AppointmentDetailsApi>(() => AppointmentDetailsApi());
            Get.lazyPut<AppointmentDetailsRepo>(() => AppointmentDetailsRepo(api: Get.find()));
            Get.lazyPut<AppointmentDetailsController>(() => AppointmentDetailsController(repo: Get.find()));
          }),
        ),
        GetPage(
          name: '/doctor_home',
          page: () => const HomeView(),
          binding: BindingsBuilder(() {
            // Home Bindings
            Get.lazyPut<HomeApi>(() => HomeApi());
            Get.lazyPut<HomeRepo>(() => HomeRepo(api: Get.find()));
            Get.lazyPut<HomeController>(() => HomeController(repo: Get.find()));

            // Schedule Bindings (تمت إضافتها هنا)
            Get.lazyPut<ScheduleApi>(() => ScheduleApi());
            Get.lazyPut<ScheduleRepo>(() => ScheduleRepo(api: Get.find()));
            Get.lazyPut<ScheduleController>(() => ScheduleController(repo: Get.find()));
            Get.lazyPut<PatientsApi>(() => PatientsApi());
            Get.lazyPut<PatientsRepo>(() => PatientsRepo(api: Get.find()));
            Get.lazyPut<PatientsController>(() => PatientsController(repo: Get.find()));
          }),
        ),
        GetPage(
          name: '/doctor_home',
          page: () => const HomeView(),
          binding: BindingsBuilder(() {
            Get.lazyPut<HomeApi>(() => HomeApi());
            Get.lazyPut<HomeRepo>(() => HomeRepo(api: Get.find()));
            Get.lazyPut<HomeController>(() => HomeController(repo: Get.find()));
            Get.lazyPut<SettingsController>(() => SettingsController());
          }),
        ),
        GetPage(
          name: '/doctor_availability',
          page: () => const DoctorAvailabilityView(),
          binding: BindingsBuilder(() {
            Get.lazyPut<DoctorAvailabilityApi>(() => DoctorAvailabilityApi());
            Get.lazyPut<DoctorAvailabilityRepo>(() => DoctorAvailabilityRepo(api: Get.find()));
            Get.lazyPut<DoctorAvailabilityController>(() => DoctorAvailabilityController(repo: Get.find()));
          }),
        ),
        GetPage(
          name: '/password_reset',
          page: () => const PasswordResetView(),
          binding: BindingsBuilder(() {
            Get.lazyPut<PasswordResetApi>(() => PasswordResetApi());
            Get.lazyPut<PasswordResetRepo>(() => PasswordResetRepo(api: Get.find()));
            Get.lazyPut<PasswordResetController>(() => PasswordResetController(repo: Get.find()));
          }),
        ),
        GetPage(
          name: '/examination',
          page: () => const ExaminationView(),
          binding: BindingsBuilder(() {
            Get.lazyPut<ExaminationApi>(() => ExaminationApi());
            Get.lazyPut<ExaminationRepo>(
              () => ExaminationRepo(api: Get.find()),
            );
            Get.lazyPut<ExaminationController>(
              () => ExaminationController(repo: Get.find()),
            );
          }),
        ),
        GetPage(
          name: '/revenue',
          page: () => const RevenueView(),
          binding: BindingsBuilder(() {
            Get.lazyPut<RevenueApi>(() => RevenueApi());
            Get.lazyPut<RevenueRepo>(() => RevenueRepo(api: Get.find()));
            Get.lazyPut<RevenueController>(
              () => RevenueController(repo: Get.find()),
            );
          }),
        ),
      ],
    );
  }
}

```

### File: lib\models\auth\login_model.dart
```dart
class LoginModel {
  final String status;
  final String message;
  final String token;

  LoginModel({
    required this.status,
    required this.message,
    required this.token,
  });

  factory LoginModel.fromJson(Map<String, dynamic> json) {
    return LoginModel(
      status: json['status']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      token: json['Token']?.toString() ?? json['token']?.toString() ?? '',
    );
  }
}
```

### File: lib\models\examination\diagnosis_record_model.dart
```dart
class DiagnosisRecordModel {
  final int id;
  final int appointmentId;
  final String diagnosis;
  final String doctorNotes;

  DiagnosisRecordModel({
    required this.id,
    required this.appointmentId,
    required this.diagnosis,
    required this.doctorNotes,
  });

  factory DiagnosisRecordModel.fromJson(Map<String, dynamic> json) {
    return DiagnosisRecordModel(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      appointmentId: json['appointment_id'] is int
          ? json['appointment_id']
          : int.tryParse(json['appointment_id']?.toString() ?? '0') ?? 0,
      diagnosis: json['diagnosis']?.toString() ?? '',
      doctorNotes: json['doctor_notes']?.toString() ?? '',
    );
  }
}

```

### File: lib\models\examination\medication_model.dart
```dart
class MedicationModel {
  final int id;
  final int recordId;
  final String name;
  final String dosage;
  final String frequency;
  final String timing;
  final String duration;

  MedicationModel({
    required this.id,
    required this.recordId,
    required this.name,
    required this.dosage,
    required this.frequency,
    required this.timing,
    required this.duration,
  });

  factory MedicationModel.fromJson(Map<String, dynamic> json) {
    return MedicationModel(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      recordId: json['record_id'] is int
          ? json['record_id']
          : int.tryParse(json['record_id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? '',
      dosage: json['dosage']?.toString() ?? '',
      frequency: json['frequency']?.toString() ?? '',
      timing: json['timing']?.toString() ?? '',
      duration: json['duration']?.toString() ?? '',
    );
  }
}

```

### File: lib\models\home\doctor_dashboard_model.dart
```dart
class DoctorHomeModel {
  final int id;
  final String name;
  final String specialization;
  final String image;

  DoctorHomeModel({required this.id, required this.name, required this.specialization, required this.image});

  factory DoctorHomeModel.fromJson(Map<String, dynamic> json) {
    return DoctorHomeModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? '',
      specialization: json['specialization']?.toString() ?? '',
      image: json['image']?.toString() ?? '',
    );
  }
}

class PatientModel {
  final int id;
  final int appointmentId;
  final String name;
  final int age;
  final String gender;
  final String image;
  final String appointmentTime;

  PatientModel({
    required this.id,
    required this.appointmentId,
    required this.name,
    required this.age,
    required this.gender,
    required this.image,
    required this.appointmentTime,
  });

  factory PatientModel.fromJson(Map<String, dynamic> json) {
    return PatientModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,

      appointmentId: json['appointment_id'] is int
          ? json['appointment_id']
          : int.tryParse(json['appointment_id']?.toString() ?? '0') ?? 0,
      //name: json['name']?.toString() ?? '',

      // ─── توافقية مع مسار appointmentsByDate (patient_name) ومسار remaining (name) ───
      name: json['name']?.toString() ?? json['patient_name']?.toString() ?? '',

      age: json['age'] is int ? json['age'] : int.tryParse(json['age']?.toString() ?? '0') ?? 0,
      gender: json['gender']?.toString() ?? 'male',
      image: json['image']?.toString() ?? '',
      // ─── توافقية مع اختلاف أسماء حقول الوقت ───
      appointmentTime: json['appointment_time']?.toString() ?? json['time']?.toString() ?? '',
    );
  }
}
```

### File: lib\models\home\doctor_info_model.dart
```dart
class DoctorInfoModel {
  final int id;
  final String name;
  final String specialization;
  final String image;

  DoctorInfoModel({required this.id, required this.name, required this.specialization, required this.image});

  factory DoctorInfoModel.fromJson(Map<String, dynamic> json) {
    return DoctorInfoModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? '',
      specialization: json['specialization']?.toString() ?? '',
      image: json['image']?.toString() ?? '',
    );
  }
}
```

### File: lib\models\home\patient_appointment_model.dart
```dart
class PatientAppointmentModel {
  final int appointmentId; // 👈 نعتمد على هذا بعد التعديل
  final int childId;
  final String name;
  final String age;
  final String gender;
  final String image;
  final String appointmentTime;

  PatientAppointmentModel({
    required this.appointmentId,
    required this.childId,
    required this.name,
    required this.age,
    required this.gender,
    required this.image,
    required this.appointmentTime,
  });

  factory PatientAppointmentModel.fromJson(Map<String, dynamic> json) {
    return PatientAppointmentModel(
      // قمت ببرمجتها بمرونة؛ لو أرسل الباك إند appointment_id سيأخذها، وإلا سيعتبر الـ id هو الموعد مؤقتاً
      appointmentId: int.tryParse(json['appointment_id']?.toString() ?? json['id']?.toString() ?? '0') ?? 0,
      childId: int.tryParse(json['child_id']?.toString() ?? json['id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? '',
      age: json['age']?.toString() ?? '',
      gender: json['gender']?.toString() ?? '',
      image: json['image']?.toString() ?? '',
      appointmentTime: json['appointment_time']?.toString() ?? '',
    );
  }
}
```

### File: lib\models\revenue\transaction_model.dart
```dart
class TransactionModel {
  final int id;
  final String patientName;
  final String date;
  final double amount;
  final String paymentMethod;

  TransactionModel({
    required this.id,
    required this.patientName,
    required this.date,
    required this.amount,
    required this.paymentMethod,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] ?? 0,
      patientName: json['patient_name']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
      amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0,
      paymentMethod: json['payment_method']?.toString() ?? 'stripe',
    );
  }
}

```

### File: lib\models\schedule\appointment_details_model.dart
```dart
class AppointmentDetailsModel {
  final int appointmentId;
  final String date;
  final String day;
  final String time;
  final String status;
  final String consultationFee;
  final String currency;
  final String paymentStatus;

  final int childId;
  final String childName;
  final String childImage;
  final String childGender;
  final int childAge;

  // حقول وهمية مؤقتة لتطابق التصميم (يجب إضافتها من الباك إند لاحقاً)
  final String fileNumber;
  final String appointmentType;
  final String parentsNotes;

  AppointmentDetailsModel({
    required this.appointmentId,
    required this.date,
    required this.day,
    required this.time,
    required this.status,
    required this.consultationFee,
    required this.currency,
    required this.paymentStatus,
    required this.childId,
    required this.childName,
    required this.childImage,
    required this.childGender,
    required this.childAge,
    required this.fileNumber,
    required this.appointmentType,
    required this.parentsNotes,
  });

  factory AppointmentDetailsModel.fromJson(Map<String, dynamic> json) {
    final child = json['child'] ?? {};

    // معالجة الوقت
    String rawTime = json['time']?.toString() ?? '00:00:00';
    String parsedTime = rawTime;
    try {
      final parts = rawTime.split(':');
      if (parts.length >= 2) {
        int hour = int.parse(parts[0]);
        String period = hour >= 12 ? 'PM' : 'AM';
        hour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
        parsedTime = '${hour.toString().padLeft(2, '0')}:${parts[1]} $period';
      }
    } catch (_) {}

    // ─── استخراج المسار النسبي للصورة لتفادي تعارض الـ Localhost ───
    String rawImage = child['image']?.toString() ?? '';
    if (rawImage.contains('http')) {
      final parts = rawImage.split('8000/');
      rawImage = parts.length > 1 ? parts.last : rawImage;
    }

    return AppointmentDetailsModel(
      appointmentId: int.tryParse(json['appointment_id']?.toString() ?? '0') ?? 0,
      date: json['date']?.toString() ?? '',
      day: json['day']?.toString() ?? '',
      time: parsedTime,
      status: json['status']?.toString() ?? 'pending',
      consultationFee: json['consultation_fee']?.toString() ?? '0.00',
      currency: json['currency']?.toString() ?? '\$',
      paymentStatus: json['payment_status']?.toString() ?? 'unpaid',

      childId: int.tryParse(child['id']?.toString() ?? '0') ?? 0,
      childName: child['name']?.toString() ?? '',

      // تمرير قيمة الصورة المنظفة
      childImage: rawImage,

      childGender: child['gender']?.toString() ?? 'male',
      childAge: int.tryParse(child['age']?.toString() ?? '0') ?? 0,

      // تعيين قيم افتراضية للحقول الناقصة
      fileNumber: 'PT-2024-${json['appointment_id']}',
      appointmentType: 'Periodic checkup',
      parentsNotes: 'يعاني الطفل من سعال خفيف وارتفاع بدرجة الحرارة يرجى فحص الصدر والحلق.',
    );
  }
}
```

### File: lib\models\schedule\patient_list_model.dart
```dart
class PatientListModel {
  final int id;
  final String name;
  final int age;
  final String gender;
  final String image;
  final String parentPhone;
  final String fileNumber;

  PatientListModel({
    required this.id,
    required this.name,
    required this.age,
    required this.gender,
    required this.image,
    required this.parentPhone,
    required this.fileNumber,
  });

  factory PatientListModel.fromJson(Map<String, dynamic> json) {
    // استخراج وتنظيف مسار الصورة
    String rawImage = json['image']?.toString() ?? '';
    if (rawImage.contains('http')) {
      final parts = rawImage.split('8000/');
      rawImage = parts.length > 1 ? parts.last : rawImage;
    }

    return PatientListModel(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? '',
      age: int.tryParse(json['age']?.toString() ?? '0') ?? 0,
      gender: json['gender']?.toString() ?? 'male',
      image: rawImage,
      parentPhone: json['parent_phone']?.toString() ?? '',
      // قيمة مؤقتة لرقم الملف
      fileNumber: 'PT-2024-${json['id']}',
    );
  }
}
```

### File: lib\models\schedule\schedule_model.dart
```dart
class ScheduleDataModel {
  final int totalAppointments;
  final List<ScheduleAppointmentModel> appointments;

  ScheduleDataModel({required this.totalAppointments, required this.appointments});

  factory ScheduleDataModel.fromJson(Map<String, dynamic> json) {
    // قراءة المصفوفة من داخل كائن data
    var list = json['appointments'] as List? ?? [];
    return ScheduleDataModel(
      totalAppointments: int.tryParse(json['total_appointments']?.toString() ?? '0') ?? 0,
      appointments: list.map((e) => ScheduleAppointmentModel.fromJson(e)).toList(),
    );
  }
}

class ScheduleAppointmentModel {
  final int id;
  final String patientName;
  final int age;
  final String gender;
  final String image;
  final String time;
  final String timePeriod; // يتم حسابها برمجياً
  final String duration;
  final String note;
  final String status;

  ScheduleAppointmentModel({
    required this.id,
    required this.patientName,
    required this.age,
    required this.gender,
    required this.image,
    required this.time,
    required this.timePeriod,
    required this.duration,
    required this.note,
    required this.status,
  });

  factory ScheduleAppointmentModel.fromJson(Map<String, dynamic> json) {
    String rawTime = json['time']?.toString() ?? '00:00';
    String parsedTime = rawTime;
    String period = 'AM';

    // عملية حساب فترة الوقت وتنسيق الساعة
    try {
      final parts = rawTime.split(':');
      if (parts.length >= 2) {
        int hour = int.parse(parts[0]);
        period = hour >= 12 ? 'PM' : 'AM';
        hour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
        String hourStr = hour.toString().padLeft(2, '0');
        parsedTime = '$hourStr:${parts[1]}';
      }
    } catch (e) {
      parsedTime = rawTime;
    }

    // ─── استخراج المسار النسبي للصورة لتفادي تعارض الـ Localhost ───
    String rawImage = json['image']?.toString() ?? '';
    if (rawImage.contains('http')) {
      final parts = rawImage.split('8000/');
      rawImage = parts.length > 1 ? parts.last : rawImage;
    }

    return ScheduleAppointmentModel(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      patientName: json['patient_name']?.toString() ?? '',
      age: int.tryParse(json['age']?.toString() ?? '0') ?? 0,
      gender: json['gender']?.toString() ?? 'male',

      // تمرير قيمة الصورة المنظفة
      image: rawImage,

      time: parsedTime,
      timePeriod: period,
      status: json['status']?.toString() ?? 'pending',

      // قيم افتراضية لعدم إرسالها من الباك إند
      duration: json['duration']?.toString() ?? '30',
      note: json['note']?.toString() ?? '',
    );
  }
}
```

### File: lib\models\settings\doctor_availability_model.dart
```dart
class DoctorAvailabilityModel {
  final String status;
  final String message;
  final int availabilityId;

  DoctorAvailabilityModel({
    required this.status,
    required this.message,
    required this.availabilityId,
  });

  factory DoctorAvailabilityModel.fromJson(Map<String, dynamic> json) {
    return DoctorAvailabilityModel(
      status: json['status']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      availabilityId: json['availability'] != null
          ? (json['availability']['id'] is int ? json['availability']['id'] : int.tryParse(json['availability']['id'].toString()) ?? 0)
          : 0,
    );
  }
}
```

### File: lib\views\auth\login_view.dart
```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth/login_controller.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class LoginView extends GetView<LoginController> {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Form(
            key: controller.loginFormKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 50),

                Image.asset(
                  'assets/images/logo.png',
                  height: 250,
                  fit: BoxFit.cover,
                ),

                const SizedBox(height: 15),

                Text(
                  'Doctor Login'.tr,
                  style: context.theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: context.theme.primaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Welcome back to Clinic Management System'.tr,
                  style: context.theme.textTheme.bodyMedium?.copyWith(
                    color: context.theme.hintColor,
                  ),
                ),

                const SizedBox(height: 40),

                CustomTextField(
                  controller: controller.phoneController,
                  hintText: 'Mobile Number'.tr,
                  prefixIcon: Icons.phone_android,
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter mobile number'.tr;
                    }
                    if (value.trim().length < 10) {
                      return 'Invalid mobile number'.tr;
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // حقل كلمة المرور
                Obx(
                  () => CustomTextField(
                    controller: controller.passwordController,
                    hintText: 'Password'.tr,
                    prefixIcon: Icons.lock_outline,
                    isPassword: true,
                    obscureText: controller.isPasswordHidden.value,
                    onSuffixPressed: () => controller.isPasswordHidden.toggle(),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter password'.tr;
                      }
                      return null;
                    },
                  ),
                ),

                const SizedBox(height: 32),

                Obx(
                  () => CustomButton(
                    text: 'Login'.tr,
                    isLoading: controller.isLoading,
                    onPressed: () => controller.loginProcess(),
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

```

### File: lib\views\auth\password_reset_view.dart
```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth/password_reset_controller.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class PasswordResetView extends GetView<PasswordResetController> {
  const PasswordResetView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: context.theme.appBarTheme.iconTheme?.color),
          onPressed: () => controller.previousPage(),
        ),
      ),
      body: SafeArea(
        child: PageView(
          controller: controller.pageController,
          physics: const NeverScrollableScrollPhysics(), // منع السحب اليدوي
          children: [
            _buildPhoneStep(context),
            _buildOtpStep(context),
            _buildNewPasswordStep(context),
          ],
        ),
      ),
    );
  }

  Widget _buildPhoneStep(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Change Password?'.tr, style: context.theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: context.theme.primaryColor)),
          const SizedBox(height: 12),
          Text('Enter your registered mobile number to reset your password.'.tr, style: context.theme.textTheme.bodyMedium?.copyWith(color: context.theme.hintColor, height: 1.5)),
          const SizedBox(height: 40),
          CustomTextField(
            controller: controller.phoneController,
            hintText: 'e.g. 963912345678',
            prefixIcon: Icons.phone_android,
            keyboardType: TextInputType.phone,
          ),
          const Spacer(),
          Obx(() => CustomButton(
            text: 'Send OTP'.tr,
            isLoading: controller.isLoading,
            onPressed: () => controller.sendOtp(),
          )),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildOtpStep(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Verify OTP'.tr, style: context.theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: context.theme.primaryColor)),
          const SizedBox(height: 12),
          Text('A 4-digit code has been sent to your registered number.'.tr, style: context.theme.textTheme.bodyMedium?.copyWith(color: context.theme.hintColor, height: 1.5)),
          const SizedBox(height: 40),
          // تصميم OTP بسيط وآمن بدون مكاتب خارجية
          Center(
            child: SizedBox(
              width: 200,
              child: TextFormField(
                controller: controller.otpController,
                keyboardType: TextInputType.number,
                maxLength: 4,
                textAlign: TextAlign.center,
                style: context.theme.textTheme.headlineMedium?.copyWith(letterSpacing: 20, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  counterText: '',
                  filled: true,
                  fillColor: context.theme.cardColor,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: context.theme.primaryColor, width: 2)),
                ),
              ),
            ),
          ),
          const Spacer(),
          Obx(() => CustomButton(
            text: 'Verify'.tr,
            isLoading: controller.isLoading,
            onPressed: () => controller.verifyOtp(),
          )),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildNewPasswordStep(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Create New Password'.tr, style: context.theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: context.theme.primaryColor)),
          const SizedBox(height: 12),
          Text('Your new password must be different from previous ones.'.tr, style: context.theme.textTheme.bodyMedium?.copyWith(color: context.theme.hintColor, height: 1.5)),
          const SizedBox(height: 40),
          Obx(() => CustomTextField(
            controller: controller.passwordController,
            hintText: 'New Password'.tr,
            prefixIcon: Icons.lock_outline,
            isPassword: true,
            obscureText: controller.isPasswordHidden.value,
            onSuffixPressed: () => controller.isPasswordHidden.toggle(),
          )),
          const SizedBox(height: 20),
          Obx(() => CustomTextField(
            controller: controller.confirmPasswordController,
            hintText: 'Confirm Password'.tr,
            prefixIcon: Icons.lock_reset,
            isPassword: true,
            obscureText: controller.isConfirmHidden.value,
            onSuffixPressed: () => controller.isConfirmHidden.toggle(),
          )),
          const Spacer(),
          Obx(() => CustomButton(
            text: 'Reset Password'.tr,
            isLoading: controller.isLoading,
            onPressed: () => controller.setPassword(),
          )),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
```

### File: lib\views\examination\examination_view.dart
```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/examination/examination_controller.dart';
import '../../core/constants.dart';
import '../../widgets/custom_button.dart';

class ExaminationView extends GetView<ExaminationController> {
  const ExaminationView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: context.theme.cardColor,
        foregroundColor: context.theme.textTheme.bodyLarge?.color,
        elevation: 0,
        surfaceTintColor: context.theme.cardColor,
        title: Text('Patient Examination'.tr),
        actions: [
          IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildPatientHeader(context),
            _buildTabs(context),
            Expanded(
              child: Obx(() {
                switch (controller.selectedTab.value) {
                  case 1:
                    return _buildPrescriptionTab(context);
                  case 0:
                  default:
                    return _buildDiagnosisTab(context);
                }
              }),
            ),
            _buildBottomAction(context),
          ],
        ),
      ),
    );
  }

  // ─── ترويسة المريض (الصورة / الاسم / العمر / المعرف / المؤقت) ───
  Widget _buildPatientHeader(BuildContext context) {
    return Obx(() {
      final patient = controller.patient.value;
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: context.theme.primaryColor.withOpacity(0.12),
              backgroundImage: patient != null && patient.image.isNotEmpty
                  // الباك إند قد يرجع رابطاً كاملاً أو مساراً نسبياً
                  ? NetworkImage(
                      patient.image.startsWith('http')
                          ? patient.image
                          : '$baseUrl/${patient.image}',
                    )
                  : null,
              child: patient == null || patient.image.isEmpty
                  ? Icon(
                      Icons.person,
                      color: context.theme.primaryColor,
                      size: 30,
                    )
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    patient?.name ?? 'Loading...',
                    style: context.theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    patient != null
                        ? '${patient.age} Yrs • ${patient.gender.tr}'
                        : '',
                    style: context.theme.textTheme.bodyMedium?.copyWith(
                      color: context.theme.hintColor,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    controller.formattedPatientId,
                    style: context.theme.textTheme.bodySmall?.copyWith(
                      color: context.theme.hintColor,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                Text(
                  controller.formattedTime,
                  style: context.theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  width: 9,
                  height: 9,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  // ─── شريط التبويبات (التشخيص / الوصفة) ───
  Widget _buildTabs(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: context.theme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.theme.dividerColor),
      ),
      child: Obx(
        () => Row(
          children: [
            _buildTabItem(context, 1, 'Prescription'.tr),
            _buildTabItem(context, 0, 'Diagnosis'.tr),
          ],
        ),
      ),
    );
  }

  Widget _buildTabItem(BuildContext context, int index, String label) {
    final isSelected = controller.selectedTab.value == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => controller.selectedTab.value = index,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? context.theme.primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : context.theme.hintColor,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  // ─── تبويب التشخيص (التشخيص السريري / الملاحظات / بطاقة القياسات) ───
  Widget _buildDiagnosisTab(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTitledCard(
            context,
            icon: Icons.edit_note,
            title: 'Clinical Diagnosis'.tr,
            child: _buildMultilineField(
              context,
              controller: controller.diagnosisController,
              hintText: 'Write the clinical diagnosis for the case'.tr,
              maxLines: 5,
              maxLength: 500,
              fillColor: context.theme.scaffoldBackgroundColor,
            ),
          ),
          const SizedBox(height: 16),
          _buildTitledCard(
            context,
            icon: Icons.description_outlined,
            title: 'General Doctor Notes'.tr,
            child: _buildMultilineField(
              context,
              controller: controller.doctorNotesController,
              hintText:
                  "Write any general notes about the child's condition".tr,
              maxLines: 4,
              maxLength: 300,
              fillColor: context.theme.scaffoldBackgroundColor,
            ),
          ),
          const SizedBox(height: 16),
          _buildMeasurementsCard(context),
        ],
      ),
    );
  }

  // بطاقة القياسات القابلة للطي (اختيارية) — الطول والوزن معاً
  Widget _buildMeasurementsCard(BuildContext context) {
    return Obx(() {
      final expanded = controller.measurementsExpanded.value;
      return Container(
        decoration: BoxDecoration(
          color: context.theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.theme.dividerColor),
        ),
        child: Column(
          children: [
            // رأس البطاقة القابل للنقر لفتح/طي الحقول
            InkWell(
              onTap: () => controller.measurementsExpanded.toggle(),
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Icon(
                      Icons.straighten,
                      size: 20,
                      color: context.theme.primaryColor,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${'Measurements'.tr} (${'Optional'.tr})',
                        style: context.theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    Icon(
                      expanded ? Icons.expand_less : Icons.expand_more,
                      color: context.theme.hintColor,
                    ),
                  ],
                ),
              ),
            ),
            if (expanded)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildLabeledField(
                        context,
                        controller: controller.heightController,
                        label: 'Height'.tr,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildLabeledField(
                        context,
                        controller: controller.weightController,
                        label: 'Weight'.tr,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      );
    });
  }

  // ─── تبويب الوصفة (بطاقة الأدوية + بطاقة التحاليل والأشعة) ───
  Widget _buildPrescriptionTab(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMedicationsCard(context),
          const SizedBox(height: 16),
          _buildLabSection(context),
        ],
      ),
    );
  }

  // بطاقة وصفة الأدوية — العنوان مع رابط "إضافة دواء" وزر "إضافة دواء آخر" بالأسفل داخلها
  Widget _buildMedicationsCard(BuildContext context) {
    return _buildTitledCard(
      context,
      icon: Icons.medication_outlined,
      title: 'Medications Prescription'.tr,
      trailing: _buildAddLink(
        context,
        'Add Medication'.tr,
        () => controller.addMedicationField(),
      ),
      child: Obx(
        () => Column(
          children: [
            for (int i = 0; i < controller.medications.length; i++) ...[
              if (i > 0) ...[
                const SizedBox(height: 8),
                Divider(height: 1, color: context.theme.dividerColor),
                const SizedBox(height: 8),
              ],
              _buildMedicationEntry(context, i),
            ],
            const SizedBox(height: 12),
            _buildAddAnotherButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicationEntry(BuildContext context, int index) {
    final med = controller.medications[index];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // زر الحذف (X) يظهر فقط عند وجود أكثر من دواء
        if (controller.medications.length > 1)
          Align(
            alignment: AlignmentDirectional.topStart,
            child: GestureDetector(
              onTap: () => controller.removeMedicationField(index),
              child: const Icon(Icons.close, color: Colors.red, size: 20),
            ),
          ),
        _buildLabeledField(
          context,
          controller: med.nameController,
          label: 'Medicine Name'.tr,
        ),
        const SizedBox(height: 12),
        // الجرعة والتعليمات كلٌّ في حقل مستقل
        _buildLabeledField(
          context,
          controller: med.dosageController,
          label: 'Dosage'.tr,
        ),
        const SizedBox(height: 12),
        _buildLabeledField(
          context,
          controller: med.timingController,
          label: 'Instructions'.tr,
        ),
        const SizedBox(height: 12),
        // الكمية والمدة جنباً إلى جنب
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildLabeledField(
                context,
                controller: med.frequencyController,
                label: 'Quantity'.tr,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildLabeledField(
                context,
                controller: med.durationController,
                label: 'Duration'.tr,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // زر "إضافة دواء آخر" الممتد أسفل بطاقة الأدوية
  Widget _buildAddAnotherButton(BuildContext context) {
    return GestureDetector(
      onTap: () => controller.addMedicationField(),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: context.theme.primaryColor.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add, size: 18, color: context.theme.primaryColor),
            const SizedBox(width: 6),
            Text(
              'Add Another Medication'.tr,
              style: TextStyle(
                color: context.theme.primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // بطاقة طلب التحاليل وصور الأشعة — يضيف الطبيب طلبات عبر زر ثم تظهر كصفوف
  Widget _buildLabSection(BuildContext context) {
    return _buildTitledCard(
      context,
      icon: Icons.science_outlined,
      title: 'Lab & Imaging Requests'.tr,
      trailing: _buildAddLink(
        context,
        'Add Request'.tr,
        () => _showAddLabRequestSheet(context),
      ),
      child: Obx(() {
        if (controller.labRequests.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'No requests added'.tr,
              style: context.theme.textTheme.bodySmall?.copyWith(
                color: context.theme.hintColor,
              ),
            ),
          );
        }
        return Column(
          children: [
            for (int i = 0; i < controller.labRequests.length; i++)
              _buildLabRequestRow(context, i),
          ],
        );
      }),
    );
  }

  // صف طلب واحد: أيقونة النوع + القيمة + زر الحذف
  Widget _buildLabRequestRow(BuildContext context, int index) {
    final item = controller.labRequests[index];
    final isTest = item.type == LabRequestType.test;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: context.theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.theme.dividerColor),
      ),
      child: Row(
        children: [
          Icon(
            isTest ? Icons.biotech_outlined : Icons.image_outlined,
            size: 20,
            color: context.theme.primaryColor,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              item.value,
              style: context.theme.textTheme.bodyMedium?.copyWith(
                color: context.theme.textTheme.bodyLarge?.color,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => controller.removeLabRequest(index),
            child: const Icon(Icons.close, color: Colors.red, size: 20),
          ),
        ],
      ),
    );
  }

  // اختيار النوع (تحليل/أشعة) ثم إدخال القيمة عبر نافذة حوارية
  void _showAddLabRequestSheet(BuildContext context) {
    Get.dialog(
      _AddLabRequestDialog(
        onAdd: (type, value) => controller.addLabRequest(type, value),
      ),
    );
  }

  // ─── زر الإجراء السفلي يتغير حسب التبويب الحالي ───
  Widget _buildBottomAction(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Obx(() {
        final isPrescription = controller.selectedTab.value == 1;
        if (isPrescription) {
          // زر أخضر مدمج (إنهاء المعاينة) — لتفادي تعديل الزر المشترك CustomButton
          return SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              onPressed: controller.isLoading
                  ? null
                  : () => controller.saveAndFinish(),
              child: controller.isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Save & Finish Examination'.tr,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
            ),
          );
        }
        return CustomButton(
          text: 'Save & Continue'.tr,
          isLoading: controller.isLoading,
          onPressed: () => controller.saveAndContinue(),
        );
      }),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: context.theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
        fontSize: 15,
      ),
    );
  }

  // بطاقة بعنوان وأيقونة (مع إجراء اختياري بجانب العنوان) تحتوي على محتواها
  Widget _buildTitledCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    Widget? trailing,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: context.theme.primaryColor),
              const SizedBox(width: 8),
              Expanded(child: _buildSectionTitle(context, title)),
              ?trailing,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  // رابط إجراء صغير (+ نص) يُوضع بجانب عنوان البطاقة
  Widget _buildAddLink(BuildContext context, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.add, size: 16, color: context.theme.primaryColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: context.theme.primaryColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // حقل بعنوان صغير فوقه — مصمم ليطابق CustomTextField دون تعديله (بلا أيقونة)
  Widget _buildLabeledField(
    BuildContext context, {
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: context.theme.textTheme.bodySmall?.copyWith(
            color: context.theme.hintColor,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          style: TextStyle(color: context.theme.textTheme.bodyLarge?.color),
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: context.theme.cardColor,
            contentPadding: const EdgeInsets.symmetric(
              vertical: 14,
              horizontal: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: context.theme.dividerColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: context.theme.primaryColor,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // حقل نصي متعدد الأسطر مع عدّاد — مصمم ليطابق CustomTextField دون تعديله
  Widget _buildMultilineField(
    BuildContext context, {
    required TextEditingController controller,
    required String hintText,
    required int maxLines,
    required int maxLength,
    Color? fillColor,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      maxLength: maxLength,
      style: TextStyle(color: context.theme.textTheme.bodyLarge?.color),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: context.theme.hintColor.withOpacity(0.6)),
        filled: true,
        fillColor: fillColor ?? context.theme.cardColor,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 20,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: context.theme.dividerColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: context.theme.primaryColor, width: 1.5),
        ),
      ),
    );
  }
}

class _AddLabRequestDialog extends StatefulWidget {
  final void Function(LabRequestType, String) onAdd;

  const _AddLabRequestDialog({required this.onAdd});

  @override
  State<_AddLabRequestDialog> createState() => _AddLabRequestDialogState();
}

class _AddLabRequestDialogState extends State<_AddLabRequestDialog> {
  final _valueController = TextEditingController();
  LabRequestType _selectedType = LabRequestType.test;

  @override
  void dispose() {
    _valueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: context.theme.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text('Add Request'.tr),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildTypeChip(
                    context,
                    label: 'Test'.tr,
                    icon: Icons.biotech_outlined,
                    selected: _selectedType == LabRequestType.test,
                    onTap: () => setState(() => _selectedType = LabRequestType.test),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildTypeChip(
                    context,
                    label: 'Imaging'.tr,
                    icon: Icons.image_outlined,
                    selected: _selectedType == LabRequestType.imaging,
                    onTap: () => setState(() => _selectedType = LabRequestType.imaging),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildValueField(context),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Get.back(), child: Text('Cancel'.tr)),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: context.theme.primaryColor,
            foregroundColor: Colors.white,
          ),
          onPressed: () {
            final value = _valueController.text.trim();
            if (value.isEmpty) return;
            widget.onAdd(_selectedType, value);
            Get.back();
          },
          child: Text('Add'.tr),
        ),
      ],
    );
  }

  Widget _buildTypeChip(
    BuildContext context, {
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final color = selected ? context.theme.primaryColor : context.theme.hintColor;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? context.theme.primaryColor.withValues(alpha: 0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildValueField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Request Value'.tr,
          style: context.theme.textTheme.bodySmall?.copyWith(
            color: context.theme.hintColor,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: _valueController,
          autofocus: true,
          style: TextStyle(color: context.theme.textTheme.bodyLarge?.color),
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: context.theme.cardColor,
            contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: context.theme.dividerColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: context.theme.primaryColor, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

```

### File: lib\views\home\home_view.dart
```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/home/home_controller.dart';
import '../../widgets/home/floating_bottom_bar.dart';
import '../../widgets/home/home_header.dart';
import '../../widgets/home/next_patient_card.dart';
import '../../widgets/home/remaining_patients_list.dart';
import '../../widgets/home/stats_grid.dart';
import '../settings/settings_view.dart';


import '../schedule/schedule_view.dart';
import '../schedule/patients_view.dart';
import '../revenue/revenue_view.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});


  static const List<Widget> _tabs = [
    _DashboardTab(),        // Index 0: الرئيسية
    ScheduleView(),         // Index 1: الجدول
    PatientsView(),         // Index 2: المرضى
    RevenueView(),          // Index 3: الأرباح
    SettingsView(),         // Index 4: الإعدادات
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      extendBody: true,
      bottomNavigationBar: const FloatingBottomBar(),
      body: Obx(() => _tabs[controller.currentIndex.value]),
    );
  }
}

// ─── كلاس لوحة التحكم الافتراضية المعزول ───
class _DashboardTab extends GetView<HomeController> {
  const _DashboardTab();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading && controller.doctorData.value == null) {
        return const Center(child: CircularProgressIndicator());
      }

      return RefreshIndicator(
        onRefresh: () => controller.fetchAllDashboardData(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const HomeHeader(),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                    const NextPatientCard(),
                    const SizedBox(height: 24),
                    const StatsGrid(),
                    const SizedBox(height: 24),

                    // زر اختيار التاريخ
                    InkWell(
                      onTap: () => controller.selectCustomDate(context),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          vertical: 14,
                          horizontal: 16,
                        ),
                        decoration: BoxDecoration(
                          color: context.theme.primaryColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.calendar_month_outlined,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              controller.displaySelectedDate,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    Text(
                      'Current Patients'.tr,
                      style: context.theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const RemainingPatientsList(),

                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}
```

### File: lib\views\revenue\revenue_view.dart
```dart
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/revenue/revenue_controller.dart';
import '../../models/revenue/transaction_model.dart';

class RevenueView extends GetView<RevenueController> {
  const RevenueView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: context.theme.colorScheme.surface,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.chevron_left,
              color: context.theme.colorScheme.onSurface, size: 30),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Wallet'.tr,
          style: TextStyle(
            color: context.theme.colorScheme.onSurface,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Icon(Icons.more_vert,
              color: context.theme.colorScheme.onSurface, size: 24),
          const SizedBox(width: 12),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        return RefreshIndicator(
          onRefresh: () => controller.fetchAllRevenueData(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildIncomeCard(context),
                const SizedBox(height: 16),
                _buildPaidVisitsCard(context),
                const SizedBox(height: 16),
                _buildChartCard(context),
                const SizedBox(height: 16),
                _buildTransactionsCard(context),
              ],
            ),
          ),
        );
      }),
    );
  }

  // ─── Blue monthly-income card with sparkline ──────────────────────────────

  Widget _buildIncomeCard(BuildContext context) {
    final primary = context.theme.primaryColor;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: primary,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.30),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Monthly Income'.tr,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                Obx(() => Text(
                      '${_formatThousands(controller.monthlyRevenue.value)} ${'SAR'.tr}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
                    )),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 90,
            height: 50,
            child: Obx(() => controller.chartData.isEmpty
                ? const SizedBox.shrink()
                : CustomPaint(
                    painter: _LineChartPainter(
                      data: controller.chartData,
                      lineColor: Colors.white,
                      showDots: false,
                      showGrid: false,
                      fillOpacity: 0.18,
                    ),
                  )),
          ),
        ],
      ),
    );
  }

  // ─── White paid-visits card ───────────────────────────────────────────────

  Widget _buildPaidVisitsCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total Paid Visits'.tr,
            style: TextStyle(
              color: context.theme.hintColor,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 6),
          Obx(() => Text(
                '${controller.totalPaidVisits.value} ${'Visit'.tr}',
                style: context.theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              )),
        ],
      ),
    );
  }

  // ─── White chart card (title + tooltip inside) ────────────────────────────

  Widget _buildChartCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 16, 16, 12),
      decoration: _cardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Text(
              'Revenue Overview'.tr,
              style: context.theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: Obx(() => _buildLineChart(context)),
          ),
        ],
      ),
    );
  }

  Widget _buildLineChart(BuildContext context) {
    final data = controller.chartData;
    if (data.isEmpty) {
      return Center(
        child: Text('No data'.tr, style: TextStyle(color: context.theme.hintColor)),
      );
    }

    final dataMax = data.reduce((a, b) => a > b ? a : b);
    // Round the axis ceiling up to a "nice" value so labels read 5K / 10K / 15K / 20K.
    final axisMax = _niceCeil(dataMax);
    final step = axisMax / 4;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Y-axis labels (unit at top, then values top-to-bottom)
        SizedBox(
          width: 40,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'SAR'.tr,
                style: TextStyle(fontSize: 8, color: context.theme.hintColor),
              ),
              ...List.generate(5, (i) {
                final v = axisMax - step * i;
                return Text(
                  v >= 1000
                      ? '${(v / 1000).toStringAsFixed(0)}K'
                      : v.toStringAsFixed(0),
                  style: TextStyle(fontSize: 9, color: context.theme.hintColor),
                );
              }),
            ],
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            children: [
              Expanded(
                child: CustomPaint(
                  size: Size.infinite,
                  painter: _LineChartPainter(
                    data: data,
                    lineColor: context.theme.primaryColor,
                    showDots: true,
                    showGrid: true,
                    fillOpacity: 0.08,
                    tooltip: '${_formatThousands(dataMax)} ${'SAR'.tr}',
                    tooltipBg: context.theme.primaryColor,
                    axisMax: axisMax,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              _buildXAxisLabels(context, data.length),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildXAxisLabels(BuildContext context, int count) {
    // Day markers (1 → 29 مايو), each sitting under its real point on the chart.
    const days = [1, 8, 15, 22, 29];
    final month = 'May'.tr;
    final style = TextStyle(fontSize: 9, color: context.theme.hintColor);

    return SizedBox(
      height: 12,
      child: LayoutBuilder(
        builder: (ctx, box) {
          final width = box.maxWidth;
          return Stack(
            clipBehavior: Clip.none,
            children: days.where((d) => d <= count).map((d) {
              // point d (1-indexed) is drawn at x = (d-1)/(count-1) of the width
              final t = count > 1 ? (d - 1) / (count - 1) : 0.0;
              final label = Text('$d $month', style: style);
              // Anchor first label to the left edge and last to the right edge
              // so nothing clips; center the rest on their point.
              if (d == days.first) {
                return Positioned(left: 0, child: label);
              }
              if (d == days.where((x) => x <= count).last) {
                return Positioned(right: 0, child: label);
              }
              return Positioned(
                left: width * t,
                child: FractionalTranslation(
                  translation: const Offset(-0.5, 0),
                  child: label,
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  // ─── White transactions card ──────────────────────────────────────────────

  Widget _buildTransactionsCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Transactions'.tr,
            style: context.theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          Obx(() {
            if (controller.transactions.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text('No transactions yet'.tr,
                      style: TextStyle(color: context.theme.hintColor)),
                ),
              );
            }
            return Column(
              children: [
                for (int i = 0; i < controller.transactions.length; i++) ...[
                  _buildTransactionRow(context, controller.transactions[i]),
                  if (i < controller.transactions.length - 1)
                    Divider(
                      height: 1,
                      color: context.theme.dividerColor.withValues(alpha: 0.5),
                    ),
                ],
              ],
            );
          }),
          const SizedBox(height: 12),
          Center(
            child: GestureDetector(
              onTap: () {},
              child: Text(
                'View All Transactions'.tr,
                style: TextStyle(
                  color: context.theme.primaryColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionRow(BuildContext context, TransactionModel tx) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Payment method badge (left) — as in the design
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: context.theme.primaryColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              tx.paymentMethod,
              style: TextStyle(
                color: context.theme.primaryColor,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 14),
          // Patient name + date (middle)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.patientName,
                  overflow: TextOverflow.ellipsis,
                  style: context.theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  tx.date,
                  style: TextStyle(color: context.theme.hintColor, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Amount (right)
          Text(
            '${_formatThousands(tx.amount)} ${'SAR'.tr}',
            style: context.theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Number helpers ───────────────────────────────────────────────────────

  /// Rounds a value up to a clean axis ceiling (e.g. 15600 → 20000) so the
  /// Y-axis reads 5K / 10K / 15K / 20K like the design.
  double _niceCeil(double value) {
    if (value <= 0) return 4;
    final magnitude =
        math.pow(10, (math.log(value) / math.ln10).floor()).toDouble();
    for (final m in const [1.0, 2.0, 2.5, 5.0, 10.0]) {
      final candidate = magnitude * m;
      if (candidate >= value) return candidate;
    }
    return magnitude * 10;
  }

  /// 15600 → "15,600"
  String _formatThousands(double value) {
    final s = value.toStringAsFixed(0);
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  // ─── Shared white-card decoration ─────────────────────────────────────────

  BoxDecoration _cardDecoration(BuildContext context) => BoxDecoration(
        color: context.theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: context.theme.primaryColor.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      );
}

// ─── Custom line chart painter ────────────────────────────────────────────────

class _LineChartPainter extends CustomPainter {
  final List<double> data;
  final Color lineColor;
  final bool showDots;
  final bool showGrid;
  final double fillOpacity;
  final String? tooltip;
  final Color? tooltipBg;
  // When set, normalizes Y against this ceiling (must match Y-axis labels).
  // When null, self-computes from data min→max (used for the sparkline).
  final double? axisMax;

  const _LineChartPainter({
    required this.data,
    required this.lineColor,
    required this.showDots,
    required this.showGrid,
    required this.fillOpacity,
    this.tooltip,
    this.tooltipBg,
    this.axisMax,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;

    final dataMax = data.reduce((a, b) => a > b ? a : b);
    final dataMin = data.reduce((a, b) => a < b ? a : b);
    // Use the axis ceiling when provided so the line matches the Y-axis labels.
    // Fall back to min→max normalization for the compact sparkline.
    final yMax = axisMax ?? dataMax;
    final yMin = axisMax != null ? 0.0 : dataMin;
    final range = (yMax - yMin) == 0 ? 1.0 : (yMax - yMin);
    final xStep = size.width / (data.length - 1);

    Offset toPoint(int i) => Offset(
          i * xStep,
          size.height - ((data[i] - yMin) / range) * size.height * 0.9 -
              size.height * 0.05,
        );

    final points = List.generate(data.length, toPoint);

    // Grid
    if (showGrid) {
      final gridPaint = Paint()
        ..color = lineColor.withValues(alpha: 0.08)
        ..strokeWidth = 1;
      for (int i = 0; i <= 4; i++) {
        final y = size.height / 4 * i;
        canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
      }
    }

    // Fill under line
    if (fillOpacity > 0) {
      final fillPath = Path()..moveTo(points.first.dx, size.height);
      for (final p in points) {
        fillPath.lineTo(p.dx, p.dy);
      }
      fillPath
        ..lineTo(points.last.dx, size.height)
        ..close();
      canvas.drawPath(
        fillPath,
        Paint()..color = lineColor.withValues(alpha: fillOpacity),
      );
    }

    // Straight-segment line (matches the stepped look in the design)
    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path()..moveTo(points[0].dx, points[0].dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(path, linePaint);

    // Small hollow dot at every data point
    if (showDots) {
      final dotFill = Paint()..color = Colors.white;
      final dotRing = Paint()
        ..color = lineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6;
      for (final p in points) {
        canvas.drawCircle(p, 2.6, dotFill);
        canvas.drawCircle(p, 2.6, dotRing);
      }

      // Emphasized last point
      final last = points.last;
      canvas.drawCircle(last, 4, Paint()..color = lineColor);
      canvas.drawCircle(last, 2, Paint()..color = Colors.white);

      // Tooltip bubble above the last point
      if (tooltip != null && tooltipBg != null) {
        final tp = TextPainter(
          text: TextSpan(
            text: tooltip,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();

        const padH = 8.0;
        const padV = 4.0;
        final bubbleW = tp.width + padH * 2;
        final bubbleH = tp.height + padV * 2;
        var bubbleLeft = last.dx - bubbleW / 2;
        // keep bubble inside bounds
        if (bubbleLeft + bubbleW > size.width) bubbleLeft = size.width - bubbleW;
        if (bubbleLeft < 0) bubbleLeft = 0;
        final bubbleTop = (last.dy - bubbleH - 8).clamp(0.0, size.height);

        final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(bubbleLeft, bubbleTop, bubbleW, bubbleH),
          const Radius.circular(6),
        );
        canvas.drawRRect(rect, Paint()..color = tooltipBg!);
        tp.paint(canvas, Offset(bubbleLeft + padH, bubbleTop + padV));
      }
    }
  }

  @override
  bool shouldRepaint(_LineChartPainter old) =>
      old.data != data || old.lineColor != lineColor || old.axisMax != axisMax;
}

```

### File: lib\views\schedule\appointment_details_view.dart
```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/schedule/appointment_details_controller.dart';
import '../../core/constants.dart';
// تم استدعاء المودل هنا لتعريف نوع البيانات
import '../../models/schedule/appointment_details_model.dart';

class AppointmentDetailsView extends GetView<AppointmentDetailsController> {
  const AppointmentDetailsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: context.theme.scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: context.theme.textTheme.bodyLarge?.color),
        title: Text(
          'Appointment Details'.tr,
          style: context.theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {},
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading) {
          return Center(child: CircularProgressIndicator(color: context.theme.primaryColor));
        }

        final data = controller.appointmentDetails.value;
        if (data == null) {
          return Center(child: Text('No details found'.tr));
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPatientHeader(context, data),
              const SizedBox(height: 24),
              Text(
                'Appointment Info'.tr,
                style: context.theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _buildAppointmentInfoCard(context, data),
              const SizedBox(height: 24),
              Text(
                'Parents Notes'.tr,
                style: context.theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _buildNotesCard(context, data),
              const SizedBox(height: 32),
              _buildActionButtons(context),
            ],
          ),
        );
      }),
    );
  }

  // تم تغيير dynamic إلى AppointmentDetailsModel هنا
  Widget _buildPatientHeader(BuildContext context, AppointmentDetailsModel data) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.theme.dividerColor.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 35,
            backgroundColor: context.theme.dividerColor.withValues(alpha: 0.1),
            backgroundImage: data.childImage.isNotEmpty ? NetworkImage('$baseUrl/${data.childImage}') : null,
            child: data.childImage.isEmpty ? Icon(Icons.person, size: 35, color: context.theme.hintColor) : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      data.childName,
                      style: context.theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Icon(Icons.calendar_today_outlined, color: context.theme.hintColor, size: 20),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${data.childAge} ${'Yrs'.tr} - ${data.childGender.tr}',
                  style: context.theme.textTheme.bodyMedium?.copyWith(color: context.theme.hintColor),
                ),
                const SizedBox(height: 4),
                Text(
                  '${'File No'.tr}: ${data.fileNumber}',
                  style: context.theme.textTheme.bodyMedium?.copyWith(color: context.theme.hintColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // تم تغيير dynamic إلى AppointmentDetailsModel هنا
  Widget _buildAppointmentInfoCard(BuildContext context, AppointmentDetailsModel data) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.theme.dividerColor.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          _buildInfoRow(context, Icons.calendar_today, 'Date'.tr, '${data.day.tr}, ${data.date}'),
          const SizedBox(height: 16),
          _buildInfoRow(context, Icons.access_time, 'Time'.tr, data.time.tr),
          const SizedBox(height: 16),
          _buildInfoRow(context, Icons.person_outline, 'Appointment Type'.tr, data.appointmentType.tr),
          const SizedBox(height: 16),
          _buildPaymentRow(context, Icons.credit_card, 'Payment Status'.tr, data.paymentStatus),
          const SizedBox(height: 16),
          _buildInfoRow(context, Icons.attach_money, 'Consultation Fee'.tr, '${data.consultationFee} ${data.currency}'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: context.theme.hintColor, size: 20),
        const SizedBox(width: 12),
        Text(
          label,
          style: context.theme.textTheme.bodyMedium?.copyWith(color: context.theme.hintColor),
        ),
        const Spacer(),
        Text(
          value,
          style: context.theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildPaymentRow(BuildContext context, IconData icon, String label, String status) {
    Color badgeColor = status == 'partially_paid' || status == 'paid' ? Colors.green : Colors.orange;

    return Row(
      children: [
        Icon(icon, color: context.theme.hintColor, size: 20),
        const SizedBox(width: 12),
        Text(
          label,
          style: context.theme.textTheme.bodyMedium?.copyWith(color: context.theme.hintColor),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: badgeColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            status.tr,
            style: TextStyle(color: badgeColor, fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ),
      ],
    );
  }

  // تم تغيير dynamic إلى AppointmentDetailsModel هنا
  Widget _buildNotesCard(BuildContext context, AppointmentDetailsModel data) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.theme.primaryColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.theme.dividerColor.withValues(alpha: 0.05)),
      ),
      child: Text(
        data.parentsNotes,
        style: context.theme.textTheme.bodyMedium?.copyWith(height: 1.5),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {},
            child: Text('Cancel Appointment'.tr, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: context.theme.primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {},
            child: Text('Start Consultation'.tr, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ),
      ],
    );
  }
}
```

### File: lib\views\schedule\patients_view.dart
```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/schedule/patients_controller.dart';
import '../../core/constants.dart';
// ─── استدعاء المودل لتعريف نوع البيانات ───
import '../../models/schedule/patient_list_model.dart';

class PatientsView extends GetView<PatientsController> {
  const PatientsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: context.theme.scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Patients'.tr,
          style: context.theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: Icon(Icons.notifications_outlined, color: context.theme.primaryColor, size: 28),
                onPressed: () {},
              ),
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // ─── شريط البحث ───
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: TextField(
              controller: controller.searchController,
              onChanged: controller.onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search for patient name or file number'.tr,
                hintStyle: TextStyle(color: context.theme.hintColor, fontSize: 14),
                prefixIcon: Icon(Icons.search, color: context.theme.hintColor),
                suffixIcon: IconButton(
                  icon: Icon(Icons.filter_list, color: context.theme.hintColor),
                  onPressed: () {},
                ),
                filled: true,
                fillColor: context.theme.cardColor,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: context.theme.dividerColor.withValues(alpha: 0.1)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: context.theme.dividerColor.withValues(alpha: 0.1)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: context.theme.primaryColor),
                ),
              ),
            ),
          ),

          // ─── قائمة المرضى ───
          Expanded(
            child: Obx(() {
              if (controller.isLoading && controller.patientsList.isEmpty) {
                return Center(child: CircularProgressIndicator(color: context.theme.primaryColor));
              }
              if (controller.patientsList.isEmpty) {
                return Center(child: Text('No patients found'.tr));
              }
              return ListView.builder(
                padding: const EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 100),
                itemCount: controller.patientsList.length,
                itemBuilder: (context, index) {
                  final patient = controller.patientsList[index];
                  return _buildPatientCard(context, patient);
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  // ─── تم تغيير dynamic إلى PatientListModel هنا ───
  Widget _buildPatientCard(BuildContext context, PatientListModel patient) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: context.theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.theme.dividerColor.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: context.theme.shadowColor.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: context.theme.dividerColor.withValues(alpha: 0.1),
                  backgroundImage: patient.image.isNotEmpty ? NetworkImage('$baseUrl/${patient.image}') : null,
                  child: patient.image.isEmpty ? Icon(Icons.person, color: context.theme.hintColor) : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        patient.name,
                        style: context.theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${patient.age} ${'Yrs'.tr} - ${patient.gender.tr}',
                        style: context.theme.textTheme.bodyMedium?.copyWith(color: context.theme.hintColor, fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${'File No'.tr}: ${patient.fileNumber}',
                        style: context.theme.textTheme.bodyMedium?.copyWith(color: context.theme.hintColor, fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${'Phone'.tr}: ${patient.parentPhone}',
                        style: context.theme.textTheme.bodyMedium?.copyWith(color: context.theme.hintColor, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: context.theme.primaryColor,
                  size: 18,
                ),
              ],
            ),
          ),
          InkWell(
            onTap: () {},
            borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(16), bottomRight: Radius.circular(16)),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: context.theme.primaryColor.withValues(alpha: 0.05),
                borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(16), bottomRight: Radius.circular(16)),
              ),
              child: Center(
                child: Text(
                  'View Medical File'.tr,
                  style: TextStyle(color: context.theme.primaryColor, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

### File: lib\views\schedule\schedule_view.dart
```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../controllers/schedule/schedule_controller.dart';
import '../../core/constants.dart';

class ScheduleView extends GetView<ScheduleController> {
  const ScheduleView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: context.theme.scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Appointments Schedule'.tr,
          style: context.theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list, color: context.theme.primaryColor),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // شريط "الكل" والعدد
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
            child: Row(
              children: [
                Text(
                  'All'.tr,
                  style: context.theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Obx(() => CircleAvatar(
                  radius: 12,
                  backgroundColor: context.theme.primaryColor,
                  child: Text(
                    controller.scheduleData.value?.totalAppointments.toString() ?? '0',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                )),
                const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
              ],
            ),
          ),

          // الشريط الأفقي للتواريخ (تم دمج التحقق من الأيام هنا)
          SizedBox(
            height: 90,
            child: Obx(() {
              if (controller.isLoading && controller.weekDates.isEmpty) {
                return Center(child: CircularProgressIndicator(color: context.theme.primaryColor));
              }

              if (controller.weekDates.isEmpty) {
                return Center(
                  child: Text(
                    'No working days available'.tr,
                    style: context.theme.textTheme.bodyMedium?.copyWith(color: context.theme.hintColor),
                  ),
                );
              }

              return ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: controller.weekDates.length,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemBuilder: (context, index) {
                  final date = controller.weekDates[index];
                  final isSelected = DateFormat('yyyy-MM-dd').format(date) == DateFormat('yyyy-MM-dd').format(controller.selectedDate.value);

                  return GestureDetector(
                    onTap: () => controller.onDateSelected(date),
                    child: Container(
                      width: 60,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            controller.getDayName(date),
                            style: TextStyle(
                              fontSize: 12,
                              color: isSelected ? context.theme.primaryColor : context.theme.hintColor,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: isSelected ? context.theme.primaryColor : Colors.transparent,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '${date.day}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? Colors.white : context.theme.textTheme.bodyLarge?.color,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${date.day} ${controller.getMonthName(date)}',
                            style: TextStyle(
                              fontSize: 10,
                              color: isSelected ? context.theme.primaryColor : context.theme.hintColor,
                            ),
                            maxLines: 1,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            }),
          ),
          const SizedBox(height: 10),

          // قائمة المواعيد
          Expanded(
            child: Obx(() {
              if (controller.isLoading && controller.weekDates.isNotEmpty) {
                return Center(child: CircularProgressIndicator(color: context.theme.primaryColor));
              }

              final appointments = controller.scheduleData.value?.appointments ?? [];

              if (appointments.isEmpty) {
                return Center(child: Text('No appointments for this date'.tr));
              }

              return ListView.builder(
                padding: const EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 100),
                itemCount: appointments.length,
                itemBuilder: (context, index) {
                  final appointment = appointments[index];
                  // تحديد البطاقة الأولى للتمييز بناءً على التصميم
                  final isFirst = index == 0;

                  // ─── تم التعديل هنا: إضافة Padding و InkWell للانتقال ───
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: InkWell(
                      onTap: () {
                        // الانتقال لشاشة التفاصيل وتمرير معرّف الموعد
                        Get.toNamed('/appointment_details', arguments: appointment.id);
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isFirst ? context.theme.primaryColor.withValues(alpha: 0.08) : context.theme.cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isFirst ? context.theme.primaryColor.withValues(alpha: 0.3) : context.theme.dividerColor.withValues(alpha: 0.1),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: context.theme.shadowColor.withValues(alpha: 0.02),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // بيانات الوقت في اليسار
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  '${appointment.time} ${appointment.timePeriod.tr}',
                                  style: context.theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: context.theme.textTheme.bodyLarge?.color,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${appointment.duration} ${'minutes'.tr}',
                                  style: context.theme.textTheme.bodySmall?.copyWith(
                                    color: context.theme.hintColor,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(width: 16),

                            // بيانات المريض في المنتصف
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    appointment.patientName,
                                    style: context.theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                    textAlign: TextAlign.right,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${appointment.age} ${'Yrs'.tr} - ${appointment.gender.tr}',
                                    style: context.theme.textTheme.bodySmall?.copyWith(
                                      color: context.theme.hintColor,
                                    ),
                                    textAlign: TextAlign.right,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    appointment.note,
                                    style: context.theme.textTheme.bodySmall?.copyWith(
                                      color: context.theme.textTheme.bodyLarge?.color?.withValues(alpha: 0.8),
                                    ),
                                    textAlign: TextAlign.right,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(width: 16),

                            // الصورة والنقطة في اليمين
                            Stack(
                              clipBehavior: Clip.none,
                              children: [
                                CircleAvatar(
                                  radius: 24,
                                  backgroundColor: context.theme.dividerColor.withValues(alpha: 0.1),
                                  backgroundImage: appointment.image.isNotEmpty
                                      ? NetworkImage('$baseUrl/${appointment.image}')
                                      : null,
                                  child: appointment.image.isEmpty
                                      ? Icon(Icons.person, color: context.theme.hintColor)
                                      : null,
                                ),
                                Positioned(
                                  right: -4,
                                  top: 15,
                                  child: Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: context.theme.primaryColor,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: context.theme.cardColor, width: 2),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}
```

### File: lib\views\settings\doctor_availability_view.dart
```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/settings/doctor_availability_controller.dart';




class DoctorAvailabilityView extends GetView<DoctorAvailabilityController> {
  const DoctorAvailabilityView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: context.theme.appBarTheme.iconTheme?.color),
          onPressed: () => Get.back(),
        ),
        title: Text('Clinic Settings'.tr),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // ─── بطاقة إدخال يوم العمل الرئيسية ───
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: context.theme.cardColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.edit_calendar_outlined, color: context.theme.primaryColor, size: 24),
                      const SizedBox(width: 10),
                      Text(
                        'Enter Working Day'.tr,
                        style: context.theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // حقل اختيار اليوم (Dropdown)
                  Text('Day'.tr, style: TextStyle(color: context.theme.hintColor, fontSize: 13)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: context.theme.scaffoldBackgroundColor.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: context.theme.dividerColor.withOpacity(0.1)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: Obx(() => DropdownButton<String>(
                        value: controller.selectedDay.value,
                        isExpanded: true,
                        icon: Icon(Icons.keyboard_arrow_down, color: context.theme.primaryColor),
                        items: controller.apiDays.map((String day) {
                          return DropdownMenuItem<String>(
                            value: day,
                            child: Text(day.tr), // الترجمة ديناميكية لكل يوم
                          );
                        }).toList(),
                        onChanged: (newValue) {
                          if (newValue != null) controller.selectedDay.value = newValue;
                        },
                      )),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // حقول اختيار الوقت (جنباً إلى جنب)
                  Row(
                    children: [
                      Expanded(child: _buildTimePickerField(context, 'Start Time'.tr, true)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildTimePickerField(context, 'End Time'.tr, false)),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ─── مربع التنبيه الاحترافي الأزرق ───
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: context.theme.primaryColor.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: context.theme.primaryColor.withOpacity(0.15)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: context.theme.primaryColor, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'This day will be saved as your available working hours.'.tr,
                      style: TextStyle(color: context.theme.primaryColor, fontSize: 13, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            //   حفظ وقت الدوام
            Obx(() => SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.theme.primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 1,
                ),
                onPressed: controller.isLoading ? null : () => controller.saveWorkingHours(),
                child: controller.isLoading
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                    : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.save_outlined, color: Colors.white),
                    const SizedBox(width: 10),
                    Text('Save Working Hours'.tr, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildTimePickerField(BuildContext context, String label, bool isStartTime) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: context.theme.hintColor, fontSize: 13)),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => controller.pickTime(context, isStartTime),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            decoration: BoxDecoration(
              color: context.theme.scaffoldBackgroundColor.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.theme.dividerColor.withOpacity(0.1)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Obx(() => Text(
                  isStartTime ? controller.formattedStartTime : controller.formattedEndTime,
                  style: context.theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                )),
                Icon(Icons.access_time, color: context.theme.hintColor.withOpacity(0.6), size: 18),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
```

### File: lib\views\settings\settings_view.dart
```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/settings/settings_controller.dart';

class SettingsView extends GetView<SettingsController> {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Settings'.tr), // 👈 كلمة إعدادات فقط
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false, // بدون زر رجوع لأنها تبوّيب أساسي
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        children: [
          // ─── المجموعة الأولى: إعدادات الحساب والعمل ───
          Container(
            decoration: BoxDecoration(
              color: context.theme.cardColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                _buildSettingsTile(
                  context,
                  title: 'Working Settings'.tr,
                  subtitle: 'Manage working hours and availability'.tr,
                  icon: Icons.business_center_outlined,
                  onTap: () => controller.goToAvailabilities(),
                ),
                _buildDivider(context),
                _buildSettingsTile(
                  context,
                  title: 'Change Password'.tr,
                  subtitle: 'Update your account password'.tr,
                  icon: Icons.lock_open_outlined,
                  onTap: () => controller.changePassword(),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20), // 👈 فصل المجموعات كما في تطبيق المريض

          // ─── المجموعة الثانية: التفضيلات (اللغة والمظهر) ───
          Container(
            decoration: BoxDecoration(
              color: context.theme.cardColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                _buildSettingsTile(
                  context,
                  title: 'Language'.tr,
                  subtitle: 'Customize app language and view'.tr,
                  icon: Icons.language_outlined,
                  onTap: () => controller.showLanguageDialog(), // 👈 تم ربطها بالدالة الجديدة هنا
                ),
                _buildDivider(context),
                _buildSettingsTile(
                  context,
                  title: 'Theme'.tr,
                  subtitle: 'Customize app language and view'.tr,
                  icon: Icons.palette_outlined,
                  onTap: () => controller.changeTheme(),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20), // 👈 فصل المجموعات

          // ─── المجموعة الثالثة: الإجراءات الحساسة (حذف الحساب) ───
          Container(
            decoration: BoxDecoration(
              color: context.theme.cardColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: _buildSettingsTile(
              context,
              title: 'Delete Account'.tr,
              subtitle: 'Permanently delete your account from the app'.tr,
              icon: Icons.delete_outline_rounded,
              textColor: Colors.red,
              iconColor: Colors.red,
              onTap: () => controller.deleteAccount(),
            ),
          ),

          // مسافة سفلية عازلة لعدم التداخل مع البار العائم
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildSettingsTile(
      BuildContext context, {
        required String title,
        required String subtitle,
        required IconData icon,
        required VoidCallback onTap,
        Color? textColor,
        Color? iconColor,
      }) {
    final isRtl = Get.locale?.languageCode == 'ar';
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            // الأيقونة اليمينية (أو اليسارية حسب اللغة)
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (iconColor ?? context.theme.primaryColor).withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor ?? context.theme.primaryColor, size: 24),
            ),
            const SizedBox(width: 16),
            // النصوص الأساسية والثانوية
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: context.theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: textColor,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: context.theme.textTheme.bodyMedium?.copyWith(
                      color: context.theme.hintColor.withOpacity(0.6),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // سهم الانتقال المتكيف مع اتجاه اللغة
            Icon(
              isRtl ? Icons.arrow_forward_ios : Icons.arrow_forward_ios,
              size: 14,
              color: context.theme.hintColor.withOpacity(0.3),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 70, right: 16),
      child: Divider(color: context.theme.dividerColor.withOpacity(0.4), height: 1),
    );
  }
}
```

### File: lib\widgets\custom_button.dart
```dart
import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isLoading;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),

        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Text(
                text,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }
}

```

### File: lib\widgets\custom_text_field.dart
```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData prefixIcon;
  final bool isPassword;
  final bool? obscureText;
  final VoidCallback? onSuffixPressed;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.prefixIcon,
    this.isPassword = false,
    this.obscureText,
    this.onSuffixPressed,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText ?? false,
      keyboardType: keyboardType,
      style: TextStyle(color: context.theme.textTheme.bodyLarge?.color),
      validator: validator,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: context.theme.hintColor.withOpacity(0.6)),
        prefixIcon: Icon(prefixIcon, color: context.theme.primaryColor),
        suffixIcon: isPassword
            ? IconButton(
          icon: Icon(
            obscureText! ? Icons.visibility_off : Icons.visibility,
            color: context.theme.hintColor,
          ),
          onPressed: onSuffixPressed,
        )
            : null,
        filled: true,
        fillColor: context.theme.cardColor,
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: context.theme.dividerColor.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: context.theme.primaryColor, width: 1.5),
        ),
      ),
    );
  }
}
```

### File: lib\widgets\home\floating_bottom_bar.dart
```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/home/home_controller.dart';

class FloatingBottomBar extends GetView<HomeController> {
  const FloatingBottomBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return SafeArea(
        child: Container(
          height: 68,
          margin: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: context.theme.cardColor,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(color: context.theme.primaryColor.withOpacity(0.12), blurRadius: 20, offset: const Offset(0, 8))],
            border: Border.all(color: context.theme.dividerColor.withOpacity(0.05), width: 1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(context, 0, Icons.home_filled, 'Home'.tr),
              _buildNavItem(context, 1, Icons.edit_calendar_outlined, 'Schedule'.tr),
              _buildNavItem(context, 2, Icons.people_alt_outlined, 'Patients'.tr),
              _buildNavItem(context, 3, Icons.analytics_outlined, 'Revenue'.tr),
              _buildNavItem(context, 4, Icons.settings_outlined, 'Settings'.tr),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildNavItem(BuildContext context, int index, IconData icon, String label) {
    final isSelected = controller.currentIndex.value == index;
    final activeColor = context.theme.primaryColor;
    final inactiveColor = context.theme.hintColor.withOpacity(0.4);

    return InkWell(
      onTap: () => controller.currentIndex.value = index,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withOpacity(0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedScale(
              scale: isSelected ? 1.15 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: Icon(icon, color: isSelected ? activeColor : inactiveColor, size: isSelected ? 24 : 22),
            ),
            const SizedBox(height: 3),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(fontSize: 10, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? activeColor : inactiveColor),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}
```

### File: lib\widgets\home\home_header.dart
```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/home/home_controller.dart';

class HomeHeader extends GetView<HomeController> {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final doctor = controller.doctorData.value;
      return SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: context.theme.primaryColor.withOpacity(0.1),
                backgroundImage: doctor != null && doctor.image.isNotEmpty ? NetworkImage(controller.resolveImageUrl(doctor.image)) : null,
                child: doctor == null || doctor.image.isEmpty ? Icon(Icons.person, color: context.theme.primaryColor, size: 28) : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        doctor != null ? 'Dr. ${doctor.name}' : 'Loading...',
                        style: context.theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)
                    ),
                    const SizedBox(height: 2),
                    Text(
                        doctor?.specialization ?? '',
                        style: context.theme.textTheme.bodyMedium?.copyWith(color: context.theme.hintColor)
                    ),
                  ],
                ),
              ),
              Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: context.theme.cardColor,
                      border: Border.all(color: context.theme.dividerColor.withOpacity(0.1)),
                    ),
                    child: IconButton(
                        icon: Icon(Icons.notifications_none_rounded, color: context.theme.textTheme.bodyLarge?.color, size: 26),
                        onPressed: () {}
                    ),
                  ),
                  Positioned(
                    right: 12,
                    top: 12,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                          color: Colors.redAccent,
                          shape: BoxShape.circle,
                          border: Border.all(color: context.theme.scaffoldBackgroundColor, width: 2)
                      ),
                    ),
                  )
                ],
              )
            ],
          ),
        ),
      );
    });
  }
}
```

### File: lib\widgets\home\next_patient_card.dart
```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/home/home_controller.dart';

class NextPatientCard extends GetView<HomeController> {
  const NextPatientCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final patient = controller.nextPatient.value;
      if (patient == null) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: context.theme.primaryColor, borderRadius: BorderRadius.circular(16)),
          child: Center(child: Text('No upcoming patients'.tr, style: const TextStyle(color: Colors.white))),
        );
      }
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: context.theme.primaryColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: context.theme.primaryColor.withOpacity(0.35),
                blurRadius: 20,
                offset: const Offset(0, 8),
              )
            ]
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Next Patient'.tr, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
            const SizedBox(height: 16),
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white24,
                  backgroundImage: patient.image.isNotEmpty ? NetworkImage(controller.resolveImageUrl(patient.image)) : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(patient.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                      const SizedBox(height: 6),
                      Text('${patient.age} ${'Yrs'.tr}• ${patient.gender.tr}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 45,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white, width: 1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  foregroundColor: Colors.white,
                ),
                onPressed: () => controller.completePatientAppointment(patient.id),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Start Examination'.tr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_ios, size: 14),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}
```

### File: lib\widgets\home\remaining_patients_list.dart
```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/home/home_controller.dart';

class RemainingPatientsList extends GetView<HomeController> {
  const RemainingPatientsList({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.remainingPatients.isEmpty) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 30),
          child: Center(child: Text('No remaining patients for this date'.tr)),
        );
      }
      return ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: controller.remainingPatients.length,
        separatorBuilder: (context, index) => Container(
          height: 1,
          width: double.infinity,
          color: context.theme.dividerColor.withOpacity(0.15),
          margin: const EdgeInsets.symmetric(vertical: 4),
        ),
        itemBuilder: (context, index) {
          final patient = controller.remainingPatients[index];
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: context.theme.primaryColor.withOpacity(0.1),
                  backgroundImage: patient.image.isNotEmpty ? NetworkImage(controller.resolveImageUrl(patient.image)) : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(patient.name, style: context.theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 4),
                      Text('${patient.age} ${'Yrs'.tr}• ${patient.gender.tr}', style: context.theme.textTheme.bodyMedium?.copyWith(color: context.theme.hintColor, fontSize: 12)),
                    ],
                  ),
                ),
                Text(
                  controller.formatTime(patient.appointmentTime),
                  style: TextStyle(color: context.theme.primaryColor, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ],
            ),
          );
        },
      );
    });
  }
}
```

### File: lib\widgets\home\stats_grid.dart
```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/home/home_controller.dart';

class StatsGrid extends GetView<HomeController> {
  const StatsGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() => Row(
      children: [
        Expanded(child: _buildStatItem(context, 'Completed'.tr, controller.completedAppointments.value.toString(), Icons.fact_check_outlined, Colors.green)),
        const SizedBox(width: 12),
        Expanded(child: _buildStatItem(context, "Today's Total".tr, controller.totalAppointments.value.toString(), Icons.calendar_today_outlined, Colors.blue)),
        const SizedBox(width: 12),
        Expanded(child: _buildStatItem(context, 'Monthly Rev'.tr, '\$${controller.monthlyRevenue.value.toStringAsFixed(0)}', Icons.monetization_on_outlined, Colors.orange)),
      ],
    ));
  }

  Widget _buildStatItem(BuildContext context, String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: context.theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.theme.dividerColor.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 10),
          Text(label, style: context.theme.textTheme.bodySmall?.copyWith(color: context.theme.hintColor, fontSize: 10), textAlign: TextAlign.center),
          const SizedBox(height: 6),
          Text(value, style: context.theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }
}
```

