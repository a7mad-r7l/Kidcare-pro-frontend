# KidCare Project Code

### File: lib\controllers\auth\login_controller.dart
```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/helper/secure_storage_service.dart';
import '../../core/repos/auth/login_repo.dart';
import '../../service/notification_service.dart';
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
        await NotificationService.sendFCMTokenToServer();

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

  // إدارة شاشات الـ PageView (الآن شاشتان فقط: 0 و 1)
  final pageController = PageController();
  final currentPage = 0.obs;

  // Controllers للحقول
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  final isPasswordHidden = true.obs;
  final isConfirmHidden = true.obs;

  // ─── 1. فحص رقم الهاتف والانتقال الفوري ───
  void validatePhoneAndContinue() {
    final phone = phoneController.text.trim();

    // القيد البرمجي (Client-Side Validation) لرقم الهاتف
    if (phone.length != 12 || !phone.startsWith('963')) {
      handleError('Phone number must be exactly 12 digits and start with 963'.tr);
      return;
    }

    // رقم الهاتف سليم؟ انقله فوراً لواجهة كلمة المرور الجديدة دون OTP
    _nextPage();
  }

  // ─── 2. تعيين كلمة المرور الجديدة وإرسالها للسيرفر ───
  Future<void> setPassword() async {
    final pass = passwordController.text;
    final confirm = confirmPasswordController.text;
    final phone = phoneController.text.trim();

    // القيود البرمجية لكلمة المرور
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
      // 💡 بما أننا ألغينا واجهة الـ OTP، نرسل كلمة المرور مباشرة.
      // ملحوظة هندسية: نمرر قيمة وهمية أو فارغة للـ OTP إذا كان الباك إند يتوقعه في السيرفر،
      // ولكن هنا نمرر الـ phone والـ password بناءً على بنية الـ SetPasswordDoctor.
      final msg = await repo.setPassword(phone, pass, confirm);
      showSuccess(msg);

      // طرد المستخدم لواجهة تسجيل الدخول بعد ثانية من النجاح
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
import '../home/home_controller.dart';

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

  // فتح شاشة الفاتورة — تحتاج معرف الموعد فلا تُفتح قبل تحميل بيانات المريض
  void openInvoice() {
    final current = patient.value;
    if (current == null || current.appointmentId == 0) {
      showInfo('Patient data is not loaded yet'.tr);
      return;
    }
    Get.toNamed('/new_invoice', arguments: current);
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

      final msg = await repo.completeAppointment(
        patient.value?.appointmentId ?? 0,
      );

      if (Get.isRegistered<HomeController>()) {
        Get.find<HomeController>().fetchAllDashboardData();
      }

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
import '../../service/notification_service.dart';
import '../base_controller.dart';

class HomeController extends BaseController {
  final HomeRepo repo;

  HomeController({required this.repo});
  final RxBool hasUnreadNotifications = false.obs;

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
    NotificationService.sendFCMTokenToServer();
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

### File: lib\controllers\invoice\invoice_controller.dart
```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../core/repos/invoice/invoice_repo.dart';
import '../../models/home/doctor_dashboard_model.dart';
import '../../models/invoice/invoice_model.dart';
import '../base_controller.dart';

class InvoiceController extends BaseController {
  final InvoiceRepo repo;

  InvoiceController({required this.repo});

  // تفاصيل الموعد (أجرة الكشف والعملة) — تُجلب عند فتح الشاشة
  final appointment = Rxn<AppointmentInvoiceModel>();

  // الفاتورة الحالية كما يرجعها الخادم بعد كل إضافة أو حذف
  final invoice = Rxn<InvoiceModel>();

  final serviceNameController = TextEditingController();
  final costController = TextEditingController();

  // مؤشرات تحميل منفصلة حتى لا يُقفل زر الحفظ أثناء إضافة خدمة
  final isSubmittingItem = false.obs;
  final deletingAdditionId = RxnInt();

  late final int appointmentId;

  // بيانات المريض الممرَّرة من شاشة المعاينة — تُرسم الترويسة فوراً قبل وصول الرد
  PatientModel? patient;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is PatientModel) {
      patient = args;
      appointmentId = args.appointmentId;
    } else {
      appointmentId = args is int ? args : 0;
    }
    if (appointmentId != 0) fetchAppointment();
  }

  Future<void> fetchAppointment() async {
    showLoading();
    try {
      appointment.value = await repo.getAppointment(appointmentId);
    } catch (e) {
      handleError(e);
    } finally {
      hideLoading();
    }
  }

  // ─── القيم المعروضة ───
  // تُفضَّل قيم الخادم متى توفرت (بعد أول إضافة)، وإلا فقيم تفاصيل الموعد.

  List<AdditionModel> get additions => invoice.value?.additions ?? const [];

  num get consultationFee =>
      invoice.value?.appointmentPrice ?? appointment.value?.consultationFee ?? 0;

  num get extrasTotal => invoice.value?.totalAdditions ?? 0;

  num get totalAmount => invoice.value?.finalPrice ?? consultationFee;

  String get currencySymbol {
    final code = appointment.value?.currency.toUpperCase() ?? '';
    return switch (code) {
      'USD' => '\$',
      'EUR' => '€',
      'INR' => '₹',
      'SYP' => 'ل.س',
      _ => code,
    };
  }

  String formatMoney(num value) =>
      '$currencySymbol ${value.toStringAsFixed(2)}'.trim();

  String get patientName =>
      appointment.value?.child?.name ?? patient?.name ?? '';

  String get patientImage =>
      appointment.value?.child?.image ?? patient?.image ?? '';

  // نفس صيغة معرف المريض المستخدمة في شاشة المعاينة ليتطابق العرض في الشاشتين
  String get formattedPatientId {
    final id = appointment.value?.child?.id ?? patient?.id ?? 0;
    return 'PT-${DateTime.now().year}-${id.toString().padLeft(4, '0')}';
  }

  String get formattedDate {
    final raw = appointment.value?.date ?? '';
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;
    return DateFormat('d MMM yyyy', Get.locale?.toString()).format(parsed);
  }

  String get formattedTime {
    final raw = appointment.value?.time ?? patient?.appointmentTime ?? '';
    final parsed = DateTime.tryParse('2000-01-01 $raw');
    if (parsed == null) return raw;
    return DateFormat('hh:mm a', Get.locale?.toString()).format(parsed);
  }

  // ─── الخدمات الإضافية ───

  void clearServiceName() => serviceNameController.clear();

  // كل خدمة تُحفظ لحظة إضافتها، والرد يحمل الفاتورة كاملة فتُرسم منه مباشرة
  Future<void> addItem() async {
    final name = serviceNameController.text.trim();
    if (name.isEmpty) {
      showInfo('Please enter the service name'.tr);
      return;
    }

    final price = num.tryParse(costController.text.trim());
    if (price == null || price <= 0) {
      showInfo('Please enter a valid cost'.tr);
      return;
    }

    isSubmittingItem.value = true;
    try {
      invoice.value = await repo.addAddition(
        appointmentId,
        itemName: name,
        price: price,
      );
      serviceNameController.clear();
      costController.clear();
    } catch (e) {
      handleError(e);
    } finally {
      isSubmittingItem.value = false;
    }
  }

  // لا يوجد مسار تعديل — تغيير خدمة يتم بحذفها ثم إضافتها من جديد
  Future<void> deleteItem(AdditionModel addition) async {
    if (deletingAdditionId.value != null) return;
    deletingAdditionId.value = addition.id;
    try {
      invoice.value = await repo.deleteAddition(addition.id);
    } catch (e) {
      handleError(e);
    } finally {
      deletingAdditionId.value = null;
    }
  }

  // الخدمات تُحفظ لحظة إضافتها، فهذا الزر إغلاق للشاشة لا حفظ —
  // ويمنع الخروج بخدمة مكتوبة لم تُضَف حتى لا تضيع دون أن يشعر الطبيب.
  void closeInvoice() {
    final hasPendingItem =
        serviceNameController.text.trim().isNotEmpty ||
        costController.text.trim().isNotEmpty;
    if (hasPendingItem) {
      showInfo('Please add the service or clear the fields'.tr);
      return;
    }
    Get.back();
  }

  @override
  void onClose() {
    serviceNameController.dispose();
    costController.dispose();
    super.onClose();
  }
}

```

### File: lib\controllers\notification\doctor_notification_controller.dart
```dart
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

```

### File: lib\controllers\patients\medical_file_controller.dart
```dart
import 'package:get/get.dart';
import '../../core/repos/patients/medical_file_repo.dart';
import '../../models/patients/medical_file_model.dart';
import '../base_controller.dart';

class MedicalFileController extends BaseController {
  final MedicalFileRepo repo;
  MedicalFileController({required this.repo});

  final medicalFile = Rxn<MedicalFileModel>();
  late final int patientId;
  final selectedTab = 0.obs;

  final List<String> tabs = [
    'Summary',
    'Visits & Prescriptions',
    'Growth Chart',
    'Vaccines'
  ];

  @override
  void onInit() {
    super.onInit();
    patientId = Get.arguments as int? ?? 0;
    if (patientId != 0) {
      fetchMedicalFile();
    }
  }

  Future<void> fetchMedicalFile() async {
    showLoading();
    try {
      final data = await repo.getFile(patientId);
      medicalFile.value = data;
    } catch (e) {
      handleError(e);
    } finally {
      hideLoading();
    }
  }

  void changeTab(int index) {
    selectedTab.value = index;
  }
}
```

### File: lib\controllers\profile\doctor_profile_controller.dart
```dart

import 'package:get/get.dart';
import '../../core/repos/profile/doctor_profile_repo.dart';
import '../../models/profile/doctor_profile_model.dart';
import '../base_controller.dart';
import '../home/home_controller.dart';

class DoctorProfileController extends BaseController {
  final DoctorProfileRepo repo;

  DoctorProfileController({required this.repo});

  final Rx<DoctorProfileModel?> profile = Rx<DoctorProfileModel?>(null);

  @override
  void onInit() {
    super.onInit();
    fetchProfile();
  }

  Future<void> fetchProfile() async {
    showLoading();
    try {
      final result = await repo.getProfile();
      profile.value = result;
    } catch (e) {
      handleError(e);
    } finally {
      hideLoading();
    }
  }

  Future<void> updateProfileField(String key, dynamic newValue) async {
    if (newValue.toString().trim().isEmpty) return;

    showLoading();
    try {
      await repo.updateProfile({key: newValue});
      await fetchProfile();


      if ((key == 'first_name' || key == 'last_name') &&
          Get.isRegistered<HomeController>()) {
        Get.find<HomeController>().fetchAllDashboardData();
      }

      Get.back();
      showSuccess('Profile updated successfully'.tr);
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
import '../base_controller.dart';

class RevenueController extends BaseController {
  final RevenueRepo repo;
  RevenueController({required this.repo});

  final monthlyRevenue = 0.0.obs;
  final totalPaidVisits = 0.obs;

  /// One value per month of the current year, January → December.
  final yearlyIncome = <double>[].obs;

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
      _run(() async => yearlyIncome.assignAll(await repo.getYearlyIncome())),
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
          TextButton(
            onPressed: () => Get.back(),
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

          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              Get.back();
              _executeCancellation();
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

        selectedDate.value = weekDates.first;

        await fetchScheduleForDate(selectedDate.value, showLoad: false);
      }
    } catch (e) {
      handleError(e);
    } finally {
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

```

### File: lib\controllers\settings\settings_controller.dart
```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../core/helper/secure_storage_service.dart';
import '../../core/repos/home/home_repo.dart';
import '../../core/repos/settings/doctor_availability_repo.dart';
import '../base_controller.dart';

class SettingsController extends BaseController {
  final DoctorAvailabilityRepo repo;

  SettingsController({required this.repo});

  void goToAvailabilities() {
    Get.toNamed('/doctor_availability');
  }

  void changePassword() {
    Get.toNamed('/password_reset');
  }

  void changeTheme() {
    if (Get.isDarkMode) {
      Get.changeThemeMode(ThemeMode.light);
    } else {
      Get.changeThemeMode(ThemeMode.dark);
    }
  }

  Future<void> logout() async {
    showLoading();
    await SecureStorage.removeAll();
    hideLoading();
    Get.offAllNamed('/login');
  }

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
              style: Get.theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Icon(
                Icons.brightness_auto_outlined,
                color: Get.theme.primaryColor,
              ),
              title: Text('System Language'.tr),
              onTap: () => _updateLanguage('system'),
            ),
            Divider(color: Get.theme.dividerColor.withOpacity(0.2), height: 1),
            ListTile(
              leading: Icon(Icons.language, color: Get.theme.primaryColor),
              title: Text('Arabic'.tr),
              onTap: () => _updateLanguage('ar'),
            ),
            Divider(color: Get.theme.dividerColor.withOpacity(0.2), height: 1),
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
    await SecureStorage.storeLanguage(langCode);
    Get.back();
    Locale targetLocale;
    if (langCode == 'system') {
      Locale? deviceLocale = Get.deviceLocale;
      targetLocale = (deviceLocale != null && deviceLocale.languageCode == 'ar')
          ? const Locale('ar', 'SY')
          : const Locale('en', 'US');
    } else if (langCode == 'ar') {
      targetLocale = const Locale('ar', 'SY');
    } else {
      targetLocale = const Locale('en', 'US');
    }
    Get.updateLocale(targetLocale);
  }

  void deleteAccount() {
    Get.dialog(
      AlertDialog(
        backgroundColor: Get.theme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete Account'.tr,
          style: const TextStyle(
            color: Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to permanently delete your account? This action cannot be undone.'
              .tr,
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'Cancel'.tr,
              style: TextStyle(color: Get.theme.hintColor),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade800,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () async {
              Get.back();
              await _confirmDeleteAccount();
            },
            child: Text(
              'Delete'.tr,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteAccount() async {
    showLoading();
    try {
      final homeRepo = Get.find<HomeRepo>();
      final msg = await homeRepo.deleteDoctorAccount();

      showSuccess(msg);

      await SecureStorage.removeAll();
      Get.offAllNamed('/login');
    } catch (e) {
      handleError(e);
    } finally {
      hideLoading();
    }
  }

  Future<void> pickDateToCancelAppointments(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),

      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Get.theme.primaryColor,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      String formattedDate = DateFormat('yyyy-MM-dd').format(pickedDate);

      _confirmCancellationDialog(formattedDate);
    }
  }

  void _confirmCancellationDialog(String date) {
    Get.defaultDialog(
      title: 'Confirm Cancellation'.tr,
      titleStyle: const TextStyle(
        color: Colors.red,
        fontWeight: FontWeight.bold,
      ),
      middleText:
          '${'Are you sure you want to cancel all appointments for today '.tr}$date?',
      textConfirm: 'Confirm Cancellation'.tr,
      textCancel: 'Back'.tr,
      confirmTextColor: Colors.white,
      buttonColor: Colors.red,
      cancelTextColor: Get.theme.primaryColor,
      onConfirm: () {
        Get.back();
        _executeCancellation(date);
      },
    );
  }

  Future<void> _executeCancellation(String date) async {
    showLoading();
    try {
      final message = await repo.deleteAppointmentsByDate(date);
      showSuccess(message);
    } catch (e) {
      handleError(e);
    } finally {
      hideLoading();
    }
  }
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
  // DELETE ACCOUNT
  Future<String> deleteDoctorAccount() async {
    final response = await http.delete(
      Uri.parse('$baseUrl/api/doctor/account/terminate'),
      headers: await _getHeaders(),
    ).timeout(const Duration(seconds: 15));

    return response.body;
  }
}
```

### File: lib\core\apis\invoice\invoice_api.dart
```dart
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:get/get.dart';
import '../../constants.dart';
import '../../helper/secure_storage_service.dart';

class InvoiceApi {
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

  // تفاصيل الموعد — منها تُقرأ أجرة الكشف والعملة (لا يوجد مسار مستقل للأجرة)
  Future<http.Response> getAppointment(int appointmentId) async {
    return await http
        .get(
          Uri.parse('$baseUrl/api/doctor/appointments/$appointmentId'),
          headers: await _getHeaders(),
        )
        .timeout(const Duration(seconds: 15));
  }

  // إضافة خدمة واحدة — لا يوجد إرسال جماعي، فكل خدمة نداء مستقل
  Future<http.Response> addAddition(
    int appointmentId, {
    required String itemName,
    required num price,
  }) async {
    return await http
        .post(
          Uri.parse('$baseUrl/api/doctor/$appointmentId/additions'),
          headers: await _getHeaders(),
          body: jsonEncode({'item_name': itemName, 'price': price}),
        )
        .timeout(const Duration(seconds: 15));
  }

  // حذف خدمة — تنبيه: المعرف في المسار هو معرف الإضافة (additions[].id)
  // وليس معرف الموعد، خلافاً لبقية مسارات هذا التدفق.
  Future<http.Response> deleteAddition(int additionId) async {
    return await http
        .delete(
          Uri.parse('$baseUrl/api/doctor/$additionId/additions'),
          headers: await _getHeaders(),
        )
        .timeout(const Duration(seconds: 15));
  }
}

```

### File: lib\core\apis\notification\doctor_notification_api.dart
```dart
import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import '../../constants.dart';
import '../../helper/secure_storage_service.dart';

class DoctorNotificationApi {
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

  Future<String> getNotifications() async {
    final url = Uri.parse('$baseUrl/api/doctor/notification');
    final response = await http
        .get(url, headers: await _getHeaders())
        .timeout(const Duration(seconds: 15));
    return response.body;
  }
}

```

### File: lib\core\apis\patients\medical_file_api.dart
```dart
import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import '../../constants.dart';
import '../../helper/secure_storage_service.dart';

class MedicalFileApi {
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

  Future<String> getMedicalFile(int patientId) async {
    final url = Uri.parse('$baseUrl/api/doctor/patients/$patientId/medical-file');
    final response = await http.get(url, headers: await _getHeaders());
    return response.body;
  }
}
```

### File: lib\core\apis\profile\doctor_profile_api.dart
```dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import '../../constants.dart';
import '../../helper/secure_storage_service.dart';

class DoctorProfileApi {
  final http.Client client = http.Client();

  Future<String> getProfile() async {
    final token = await SecureStorage.getToken();

    final response = await client
        .get(
          Uri.parse('$baseUrl/api/doctor/profile'),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
            'Accept-Language': Get.locale?.languageCode ?? 'en',
          },
        )
        .timeout(const Duration(seconds: 15));

    return response.body;
  }

  Future<String> updateProfile(Map<String, dynamic> updatedData) async {
    final token = await SecureStorage.getToken();

    final response = await client
        .put(
          Uri.parse('$baseUrl/api/doctor/updateProfile'),
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
            'Accept-Language': Get.locale?.languageCode ?? 'en',
          },
          body: json.encode(updatedData),
        )
        .timeout(const Duration(seconds: 15));

    return response.body;
  }
}

```

### File: lib\core\apis\revenue\revenue_api.dart
```dart
import 'package:http/http.dart' as http;

import 'package:get/get.dart';
import '../../constants.dart';
import '../../helper/secure_storage_service.dart';

class RevenueApi {
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

  /// GET /api/doctor/income → returns the current month's total earnings for the
  /// logged-in doctor as `{ "monthly_income": <sum of doctor_earnings> }`.
  Future<String> getMonthlyIncome() async {
    return (await http.get(Uri.parse('$baseUrl/api/doctor/income'), headers: await _getHeaders())).body;
  }

  /// GET /api/doctor/yearlyIncome → the current year's earnings grouped by month
  /// as a top-level array of 12 items, January → December:
  /// `[{ "month": "January", "total_income": 0.0 }, …]`.
  Future<String> getYearlyIncome() async {
    return (await http.get(Uri.parse('$baseUrl/api/doctor/yearlyIncome'), headers: await _getHeaders())).body;
  }

  // TODO: implement when the backend exposes this endpoint.
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
  // ───  إلغاء الموعد ───
  Future<String> cancelAppointment(int appointmentId) async {
    final url = Uri.parse('$baseUrl/api/doctor/appointments/$appointmentId/cancel');
    final response = await http.put(url, headers: await _getHeaders());
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

  Future<http.Response> addAvailability({
    required String dayOfWeek,
    required String startTime,
    required String endTime,
  }) async {
    final url = Uri.parse('$baseUrl/api/doctor-availabilities');

    final response = await http
        .post(
          url,
          headers: await _getHeaders(),
          body: jsonEncode({
            'day_of_week': dayOfWeek,
            'start_time': startTime,
            'end_time': endTime,
          }),
        )
        .timeout(const Duration(seconds: 20));

    return response;
  }

  // GET
  Future<http.Response> getAvailabilities(int doctorId) async {
    return await http
        .get(
          Uri.parse('$baseUrl/api/doctors/$doctorId/availabilities'),
          headers: await _getHeaders(),
        )
        .timeout(const Duration(seconds: 20));
  }

  // GET
  Future<http.Response> getAvailableWorkingPeriods() async {
    return await http
        .get(
          Uri.parse('$baseUrl/api/doctors/availableWorkingPeriods'),

          headers: await _getHeaders(),
        )
        .timeout(const Duration(seconds: 20));
  }

  // DELETE
  Future<http.Response> deleteAvailability(int id) async {
    return await http
        .delete(
          Uri.parse('$baseUrl/api/doctor/availability/$id'),
          headers: await _getHeaders(),
        )
        .timeout(const Duration(seconds: 20));
  }

  Future<http.Response> deleteAppointmentsByDate(String date) async {
    final url = Uri.parse(
      '$baseUrl/api/doctor/appointments/cancelAppointments',
    );
    final response = await http
        .put(
          url,
          headers: await _getHeaders(),
          body: jsonEncode({'date': date}),
        )
        .timeout(const Duration(seconds: 20));

    return response;
  }
}

```

### File: lib\core\constants.dart
```dart
const String baseUrl = 'https://kidcare.sy';

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

      //patients
      'Medical File': 'Medical File',
      'Summary': 'Summary',
      'Visits & Prescriptions': 'Visits & Prescriptions',
      'Growth Chart': 'Growth Chart',
      'Vaccines': 'Vaccines',
      'Weight': 'Weight',
      'Height': 'Height',
      'Blood Type': 'Blood Type',
      'Allergies': 'Allergies',
      'kg': 'kg',
      'cm': 'cm',
      'normal': 'Normal',
      'None': 'None',
      'Last Visit': 'Last Visit',
      'Diagnosis': 'Diagnosis',
      'Previous Visits': 'Previous Visits',
      'View All Visits': 'View All Visits',
      'Under Construction': 'Under Construction',
      'Common Cold': 'Common Cold',
      'High Fever': 'High Fever',
      'Chest Allergy': 'Chest Allergy',

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
      'USD': 'USD',
      'Total Paid Visits': 'Total Paid Visits',
      'Visit': 'Visit',
      'Yearly Income': 'Yearly Income',
      'Recent Transactions': 'Recent Transactions',
      'View All Transactions': 'View All Transactions',
      'No transactions yet': 'No transactions yet',
      'No data': 'No data',
      'Jan': 'Jan',
      'Feb': 'Feb',
      'Mar': 'Mar',
      'Apr': 'Apr',
      'May': 'May',
      'Jun': 'Jun',
      'Jul': 'Jul',
      'Aug': 'Aug',
      'Sep': 'Sep',
      'Oct': 'Oct',
      'Nov': 'Nov',
      'Dec': 'Dec',

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

      // --- Invoice View ---
      'Invoice': 'Invoice',
      'New Invoice': 'New Invoice',
      'Patient ID': 'Patient ID',
      // مفتاح 'Consultation Fee' معرَّف أصلاً في قسم لوحة التحكم أعلاه
      'General Consultation': 'General Consultation',
      'Extra Services': 'Extra Services',
      'Add Item': 'Add Item',
      'Service Name': 'Service Name',
      'e.g. Nebulizer session': 'e.g. Nebulizer session',
      'Cost': 'Cost',
      'Clear': 'Clear',
      'No extra services added': 'No extra services added',
      'Total Amount': 'Total Amount',
      'Please enter the service name': 'Please enter the service name',
      'Please enter a valid cost': 'Please enter a valid cost',
      'Please add the service or clear the fields':
          'Please add the service or clear the fields',
      'Patient data is not loaded yet': 'Patient data is not loaded yet',
      'Loading...': 'Loading...',

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
      'Are you sure you want to permanently delete your account? This action cannot be undone.':
          'Are you sure you want to permanently delete your account? This action cannot be undone.',
      'Delete': 'Delete',
      'Continue': 'Continue',
      'Are you sure you want to delete this working day?':
          'Are you sure you want to delete this working day?',
      'Deleted successfully': 'Deleted successfully',
      'Cannot delete this availability': 'Cannot delete this availability',
      'Server error': 'Server error',
      'There are no available days': 'There are no available days',
      'Please wait for home data to load first':
          'Please wait for home data to load first',
      'End time must be after start time': 'End time must be after start time',
      // --- Doctor Profile View ---
      'Personal Profile': 'Personal Profile',
      'Failed to load profile': 'Failed to load profile',
      'First Name': 'First Name',
      'Last Name': 'Last Name',
      'Phone Number': 'Phone Number',
      'Email': 'Email',
      'Address': 'Address',
      'Experience Years': 'Experience Years',
      'Not set': 'Not set',
      'Edit': 'Edit',
      'Save': 'Save',
      'Profile updated successfully': 'Profile updated successfully',
      'Are you sure you want to cancel this appointment?':
          'Are you sure you want to cancel this appointment?',
      'Confirm': 'Confirm',
      'Back': 'Back',
      'Notifications': 'Notifications',
      'No notifications yet': 'No notifications yet',
      'Cancel specific day appointments': 'Cancel specific day appointments',
      'Select a date from the calendar to cancel all its':
          'Select a date from the calendar to cancel all its',
      'Confirm Cancellation': 'Confirm Cancellation',
      'Are you sure you want to cancel all appointments for today ':
          'Are you sure you want to cancel all appointments for today ',
      'My Availabilities': 'My Availabilities',
      'Free Slots': 'Free Slots',
      'No free slots available': 'No free slots available',
      'No times available for this date.': 'No times available for this date.',
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

      //patients
      'Medical File': 'الملف الطبي',
      'Summary': 'الملخص',
      'Visits & Prescriptions': 'الزيارات والوصفات',
      'Growth Chart': 'منحنى النمو',
      'Vaccines': 'اللقاحات',
      'Weight': 'الوزن',
      'Height': 'الطول',
      'Blood Type': 'فصيلة الدم',
      'Allergies': 'الحساسية',
      'kg': 'كجم',
      'cm': 'سم',
      'normal': 'طبيعي',
      'None': 'لا يوجد',
      'Last Visit': 'آخر زيارة',
      'Diagnosis': 'تشخيص',
      'Previous Visits': 'الزيارات السابقة',
      'View All Visits': 'عرض جميع الزيارات',
      'Under Construction': 'قيد التطوير',
      'Common Cold': 'نزلة برد',
      'High Fever': 'ارتفاع في الحرارة',
      'Chest Allergy': 'حساسية صدرية',

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
      'USD': 'دولار',
      'Total Paid Visits': 'إجمالي الزيارات المدفوعة',
      'Visit': 'زيارة',
      'Yearly Income': 'الدخل السنوي',
      'Recent Transactions': 'أحدث المعاملات',
      'View All Transactions': 'عرض جميع المعاملات',
      'No transactions yet': 'لا توجد معاملات بعد',
      'No data': 'لا توجد بيانات',
      'Jan': 'يناير',
      'Feb': 'فبراير',
      'Mar': 'مارس',
      'Apr': 'أبريل',
      'May': 'مايو',
      'Jun': 'يونيو',
      'Jul': 'يوليو',
      'Aug': 'أغسطس',
      'Sep': 'سبتمبر',
      'Oct': 'أكتوبر',
      'Nov': 'نوفمبر',
      'Dec': 'ديسمبر',

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

      // --- Invoice View ---
      'Invoice': 'الفاتورة',
      'New Invoice': 'فاتورة جديدة',
      'Patient ID': 'معرف المريض',
      // مفتاح 'Consultation Fee' معرَّف أصلاً في قسم لوحة التحكم أعلاه
      'General Consultation': 'كشف عام',
      'Extra Services': 'خدمات إضافية',
      'Add Item': 'إضافة خدمة',
      'Service Name': 'اسم الخدمة',
      'e.g. Nebulizer session': 'مثال: جلسة بخّار',
      'Cost': 'التكلفة',
      'Clear': 'مسح',
      'No extra services added': 'لا توجد خدمات إضافية',
      'Total Amount': 'المبلغ الإجمالي',
      'Please enter the service name': 'الرجاء إدخال اسم الخدمة',
      'Please enter a valid cost': 'الرجاء إدخال تكلفة صحيحة',
      'Please add the service or clear the fields':
          'الرجاء إضافة الخدمة أو إفراغ الحقول',
      'Patient data is not loaded yet': 'لم يتم تحميل بيانات المريض بعد',
      'Loading...': 'جارٍ التحميل...',

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
      'Are you sure you want to permanently delete your account? This action cannot be undone.':
          'هل أنت متأكد أنك تريد حذف حسابك نهائياً؟ هذا الإجراء لا يمكن التراجع عنه.',
      'Delete': 'حذف',
      'Continue': 'متابعة',
      'Are you sure you want to delete this working day?':
          'هل أنت متأكد من حذف وقت الدوام هذا؟',
      'Deleted successfully': 'تم الحذف بنجاح',
      'Cannot delete this availability': 'لا يمكن حذف وقت الدوام هذا',
      'Server error': 'خطأ في الخادم',
      'There are no available days': 'لا توجد ايام متاحة',
      'Please wait for home data to load first':
          'الرجاء انتظار تحميل بيانات الرئيسية أولاً',
      'End time must be after start time':
          'وقت النهاية يجب أن يكون بعد وقت البداية',
      // --- Doctor Profile View ---
      'Personal Profile': 'الملف الشخصي',
      'Failed to load profile': 'فشل في تحميل الملف الشخصي',
      'First Name': 'الاسم الأول',
      'Last Name': 'الكنية',
      'Phone Number': 'رقم الهاتف',
      'Email': 'البريد الإلكتروني',
      'Address': 'العنوان',
      'Experience Years': 'سنوات الخبرة',
      'Not set': 'غير محدد',
      'Edit': 'تعديل',
      'Save': 'حفظ',
      'Profile updated successfully': 'تم تحديث الملف الشخصي بنجاح',
      'Are you sure you want to cancel this appointment?':
          'هل أنت متأكد أنك تريد إلغاء هذا الموعد؟',
      'Confirm': 'تأكيد',
      'Back': 'تراجع',
      'Notifications': 'الإشعارات',
      'No notifications yet': 'لا توجد إشعارات بعد',
      'Cancel specific day appointments': 'إلغاء مواعيد يوم محدد',
      'Select a date from the calendar to cancel all its':
          'اختر تاريخاً من التقويم لإلغاء جميع مواعيده',
      'Confirm Cancellation': 'تأكيد الإلغاء',
      'Are you sure you want to cancel all appointments for today ':
          'هل أنت متأكد أنك تريد إلغاء جميع المواعيد ليوم ',
      'My Availabilities': 'أوقات دوامي',
      'Free Slots': 'الأوقات الشاغرة',
      'No free slots available': 'لا توجد أوقات شاغرة متاحة',
      'No times available for this date.': 'لا توجد أوقات متاحة في هذا التاريخ.',
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

  Future<String> deleteDoctorAccount() async {
    final res = await api.deleteDoctorAccount();
    return jsonDecode(_cleanJson(res))['message'] ?? 'Account deleted successfully.';
  }
}
```

### File: lib\core\repos\invoice\invoice_repo.dart
```dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../models/invoice/invoice_model.dart';
import '../../apis/invoice/invoice_api.dart';

class InvoiceRepo {
  final InvoiceApi api;
  InvoiceRepo({required this.api});

  String _cleanJson(String response) {
    if (response.contains('{')) return response.substring(response.indexOf('{'));
    if (response.contains('[')) return response.substring(response.indexOf('['));
    return response;
  }

  // الإضافة ترجع 201 لا 200، لذا يُقبل نطاق 2xx كاملاً.
  // عند الفشل يُرمى نص الجسم كما هو ليستخرج handleError رسالة الخادم منه.
  Map<String, dynamic> _decode(http.Response response) {
    final cleaned = _cleanJson(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(cleaned);
    }
    return jsonDecode(cleaned) as Map<String, dynamic>;
  }

  Future<AppointmentInvoiceModel> getAppointment(int appointmentId) async {
    final decoded = _decode(await api.getAppointment(appointmentId));
    return AppointmentInvoiceModel.fromJson(decoded['data'] ?? {});
  }

  Future<InvoiceModel> addAddition(
    int appointmentId, {
    required String itemName,
    required num price,
  }) async {
    final decoded = _decode(
      await api.addAddition(appointmentId, itemName: itemName, price: price),
    );
    return InvoiceModel.fromJson(decoded['appointment'] ?? {});
  }

  Future<InvoiceModel> deleteAddition(int additionId) async {
    final decoded = _decode(await api.deleteAddition(additionId));
    return InvoiceModel.fromJson(decoded['appointment'] ?? {});
  }
}

```

### File: lib\core\repos\notification\doctor_notification_repo.dart
```dart
import 'dart:convert';
import '../../../models/notification/doctor_notification_model.dart';
import '../../apis/notification/doctor_notification_api.dart';

class DoctorNotificationRepo {
  final DoctorNotificationApi api;

  DoctorNotificationRepo({required this.api});

  String _cleanJson(String response) {
    final startIndex = response.indexOf(RegExp(r'[\{\[]'));
    if (startIndex != -1) return response.substring(startIndex);
    return response;
  }

  Future<List<DoctorNotificationModel>> getNotifications() async {
    final res = await api.getNotifications();
    final decoded = jsonDecode(_cleanJson(res));

    if (decoded['status'] == 'success' && decoded['notifications'] is List) {
      return (decoded['notifications'] as List)
          .map((item) => DoctorNotificationModel.fromJson(item))
          .toList();
    }
    return [];
  }
}

```

### File: lib\core\repos\patients\medical_file_repo.dart
```dart
import 'dart:convert';
import '../../../models/patients/medical_file_model.dart';
import '../../apis/patients/medical_file_api.dart';

class MedicalFileRepo {
  final MedicalFileApi api;
  MedicalFileRepo({required this.api});

  Future<MedicalFileModel> getFile(int id) async {
    final res = await api.getMedicalFile(id);

    String cleanRes = res;
    if (cleanRes.contains('{')) {
      cleanRes = cleanRes.substring(cleanRes.indexOf('{'));
    }

    final decoded = jsonDecode(cleanRes);
    if (decoded['status'] == true && decoded['data'] != null) {
      return MedicalFileModel.fromJson(decoded['data']);
    } else {
      throw Exception(decoded['message'] ?? 'Failed to fetch medical file');
    }
  }
}
```

### File: lib\core\repos\profile\doctor_profile_repo.dart
```dart
import 'dart:convert';
import '../../../models/profile/doctor_profile_model.dart';
import '../../apis/profile/doctor_profile_api.dart';

class DoctorProfileRepo {
  final DoctorProfileApi _api = DoctorProfileApi();

  String _cleanJson(String response) {
    final startIndex = response.indexOf(RegExp(r'[\{\[]'));
    if (startIndex != -1) return response.substring(startIndex);
    return response;
  }

  Future<DoctorProfileModel> getProfile() async {
    final response = await _api.getProfile();
    final body = jsonDecode(_cleanJson(response));

    if (body['status'] == 'success') {
      return DoctorProfileModel.fromJson(body);
    }
    throw Exception(body['message'] ?? 'Failed to load profile');
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    final response = await _api.updateProfile(data);
    final body = jsonDecode(_cleanJson(response));

    if (body['status'] == 'success') {
      return;
    }
    throw Exception(body['message'] ?? 'Failed to update profile');
  }
}

```

### File: lib\core\repos\revenue\revenue_repo.dart
```dart
import 'dart:convert';
import '../../apis/revenue/revenue_api.dart';

class RevenueRepo {
  final RevenueApi api;
  RevenueRepo({required this.api});

  String _cleanJson(String response) {
    final brace = response.indexOf('{');
    final bracket = response.indexOf('[');
    if (bracket != -1 && (brace == -1 || bracket < brace)) {
      return response.substring(bracket);
    }
    if (brace != -1) return response.substring(brace);

    final startIndex = response.indexOf(RegExp(r'[\{\[]'));
    if (startIndex != -1) return response.substring(startIndex);

    return response;
  }

  /// Month names exactly as the backend spells them. They come back in English
  /// even under `Accept-Language: ar`, so they are only used to sanity-check the
  /// ordering here — the label shown to the user is derived from the index.
  static const _monthOrder = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  /// Current month's total earnings for the logged-in doctor.
  ///
  /// Independent from [getYearlyIncome]: this counts appointments whose
  /// `payment_status` is paid, while the yearly breakdown counts appointments
  /// whose `status` is completed. The two will often disagree for the current
  /// month, so never derive one from the other.
  Future<double> getMonthlyRevenue() async {
    final res = await api.getMonthlyIncome();
    return double.tryParse(
            jsonDecode(_cleanJson(res))['monthly_income']?.toString() ?? '0') ??
        0.0;
  }

  /// The current year's earnings per month — always 12 values in calendar
  /// order, January → December, with months that have no income (including
  /// future ones) as 0.
  Future<List<double>> getYearlyIncome() async {
    final decoded = jsonDecode(_cleanJson(await api.getYearlyIncome()));
    final values = List<double>.filled(12, 0.0);
    if (decoded is! List) return values;

    for (int i = 0; i < decoded.length && i < 12; i++) {
      final item = decoded[i];
      if (item is! Map) continue;
      // Trust the month name when we recognise it, fall back to the position.
      final month = _monthOrder.indexOf(item['month']?.toString() ?? '');
      values[month == -1 ? i : month] =
          double.tryParse(item['total_income']?.toString() ?? '') ?? 0.0;
    }
    return values;
  }

  // ─── Mock data — swap this body for a real API call when backend is ready ───

  Future<int> getTotalPaidVisits() async {
    // await api.getTotalPaidVisits();
    return 156;
  }
}

```

### File: lib\core\repos\schedule\appointment_details_repo.dart
```dart
import 'dart:convert';
import '../../../models/schedule/appointment_details_model.dart';
import '../../apis/schedule/appointment_details_api.dart';
import 'package:get/get.dart';

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

  // ───  إلغاء الموعد ───
  Future<String> cancelAppointment(int id) async {
    final res = await api.cancelAppointment(id);

    String cleanRes = res;
    if (cleanRes.contains('{')) {
      cleanRes = cleanRes.substring(cleanRes.indexOf('{'));
    }

    final decoded = jsonDecode(cleanRes);

    if (decoded['status'] == 'success') {
      return decoded['message'] ?? 'Appointment cancelled successfully'.tr;
    } else {
      throw Exception(decoded['message'] ?? 'Failed to cancel appointment');
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

import 'package:get/get.dart';

import '../../../models/settings/availability_item_model.dart';
import '../../../models/settings/available_period_model.dart';
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

    if (response.statusCode == 422 || response.statusCode == 400) {
      throw Exception(
        decodedJson['message'] ?? 'Time conflict or invalid data.',
      );
    }

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Server error: ${response.statusCode}');
    }

    return DoctorAvailabilityModel.fromJson(decodedJson);
  }

  Future<List<AvailabilityItemModel>> getAvailabilities(int doctorId) async {
    final response = await api.getAvailabilities(doctorId);
    final decodedJson = jsonDecode(_cleanJson(response.body));

    if (response.statusCode == 200) {
      final List data = decodedJson['availabilities'] ?? decodedJson['data'] ?? [];
      return data.map((e) => AvailabilityItemModel.fromJson(e)).toList();
    } else {
      throw Exception(
        decodedJson['message'] ?? 'Failed to load availabilities',
      );
    }
  }
  Future<List<AvailablePeriodModel>> fetchAvailableWorkingPeriods() async {
    final response = await api.getAvailableWorkingPeriods();
    final decodedJson = jsonDecode(_cleanJson(response.body));

    if (response.statusCode == 200 && decodedJson['status'] == 'success') {
      final List data = decodedJson['available_periods'] ?? [];
      return data.map((e) => AvailablePeriodModel.fromJson(e)).toList();
    } else {
      throw Exception(
        decodedJson['message'] ?? 'Failed to load free periods',
      );
    }
  }

  Future<String> deleteAvailability(int id) async {
    final response = await api.deleteAvailability(id);

    if (response.statusCode == 200 || response.statusCode == 204) {
      if (response.body.isEmpty) return 'Deleted successfully'.tr;

      try {
        final decoded = jsonDecode(_cleanJson(response.body));
        if (decoded is Map) {
          return decoded['message']?.toString() ?? 'Deleted successfully'.tr;
        }
      } catch (_) {}
      return 'Deleted successfully'.tr;
    } else {
      String errorMessage = '${'Server error'.tr}: ${response.statusCode}';

      try {
        final decoded = jsonDecode(_cleanJson(response.body));

        if (decoded is Map && decoded['message'] != null) {
          errorMessage = decoded['message'].toString();
        } else if (decoded is Map && decoded['errors'] != null) {
          errorMessage = decoded['errors'].values.first[0].toString();
        }
      } catch (_) {
        if (response.statusCode == 422) {
          errorMessage = 'Cannot delete this availability'.tr;
        }
      }

      throw errorMessage;
    }
  }

  Future<String> deleteAppointmentsByDate(String date) async {
    final res = await api.deleteAppointmentsByDate(date);

    if (res.statusCode == 200 || res.statusCode == 201) {
      final decoded = jsonDecode(_cleanJson(res.body));
      return decoded['message'] ?? 'Deleted successfully'.tr;
    } else {
      final decoded = jsonDecode(_cleanJson(res.body));
      throw Exception(decoded['message'] ?? 'Failed to delete appointments'.tr);
    }
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

  var outputFile = File('doctor_project_code.md');
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
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:kidcare_pro/service/notification_service.dart';
import 'package:kidcare_pro/views/notification/doctor_notification_view.dart';
import 'package:kidcare_pro/views/profile/doctor_profile_view.dart';

import 'controllers/notification/doctor_notification_controller.dart';
import 'controllers/profile/doctor_profile_controller.dart';
import 'core/apis/notification/doctor_notification_api.dart';
import 'core/apis/profile/doctor_profile_api.dart';
import 'core/helper/secure_storage_service.dart';
import 'core/localization/app_translations.dart';
import 'core/repos/notification/doctor_notification_repo.dart';
import 'core/repos/profile/doctor_profile_repo.dart';
import 'core/theme/app_themes.dart';

// Login
import 'views/auth/login_view.dart';
import 'controllers/auth/login_controller.dart';
import 'core/apis/auth/login_api.dart';
import 'core/repos/auth/login_repo.dart';

// Home
import 'views/home/home_view.dart';
import 'controllers/home/home_controller.dart';
import 'core/apis/home/home_api.dart';
import 'core/repos/home/home_repo.dart';

// Examination
import 'views/examination/examination_view.dart';
import 'controllers/examination/examination_controller.dart';
import 'core/apis/examination/examination_api.dart';
import 'core/repos/examination/examination_repo.dart';

// Invoice
import 'views/invoice/new_invoice_view.dart';
import 'controllers/invoice/invoice_controller.dart';
import 'core/apis/invoice/invoice_api.dart';
import 'core/repos/invoice/invoice_repo.dart';

// Revenue

import 'controllers/revenue/revenue_controller.dart';
import 'core/apis/revenue/revenue_api.dart';
import 'core/repos/revenue/revenue_repo.dart';

// Schedule & Patients
import 'controllers/schedule/schedule_controller.dart';
import 'core/apis/schedule/schedule_api.dart';
import 'core/repos/schedule/schedule_repo.dart';
import 'views/schedule/appointment_details_view.dart';
import 'controllers/schedule/appointment_details_controller.dart';
import 'core/apis/schedule/appointment_details_api.dart';
import 'core/repos/schedule/appointment_details_repo.dart';
import 'controllers/schedule/patients_controller.dart';
import 'core/apis/schedule/patients_api.dart';
import 'core/repos/schedule/patients_repo.dart';

// Settings & Auth
import 'views/auth/password_reset_view.dart';
import 'views/settings/doctor_availability_view.dart';
import 'controllers/auth/password_reset_controller.dart';
import 'controllers/settings/doctor_availability_controller.dart';
import 'controllers/settings/settings_controller.dart';
import 'core/apis/auth/password_reset_api.dart';
import 'core/apis/settings/doctor_availability_api.dart';
import 'core/repos/auth/password_reset_repo.dart';
import 'core/repos/settings/doctor_availability_repo.dart';

//patients
import 'views/patients/medical_file_view.dart';
import 'controllers/patients/medical_file_controller.dart';
import 'core/apis/patients/medical_file_api.dart';
import 'core/repos/patients/medical_file_repo.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting();

  await Firebase.initializeApp();

  await NotificationService.initialize();

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
          name: '/medical_file',
          page: () => const MedicalFileView(),
          binding: BindingsBuilder(() {
            Get.lazyPut<MedicalFileApi>(() => MedicalFileApi());
            Get.lazyPut<MedicalFileRepo>(
              () => MedicalFileRepo(api: Get.find()),
            );
            Get.lazyPut<MedicalFileController>(
              () => MedicalFileController(repo: Get.find()),
            );
          }),
        ),
        GetPage(
          name: '/appointment_details',
          page: () => const AppointmentDetailsView(),
          binding: BindingsBuilder(() {
            Get.lazyPut<AppointmentDetailsApi>(() => AppointmentDetailsApi());
            Get.lazyPut<AppointmentDetailsRepo>(
              () => AppointmentDetailsRepo(api: Get.find()),
            );
            Get.lazyPut<AppointmentDetailsController>(
              () => AppointmentDetailsController(repo: Get.find()),
            );
          }),
        ),

        GetPage(
          name: '/doctor_home',
          page: () => const HomeView(),
          binding: BindingsBuilder(() {
            // Home
            Get.lazyPut<HomeApi>(() => HomeApi());
            Get.lazyPut<HomeRepo>(() => HomeRepo(api: Get.find()));
            Get.lazyPut<HomeController>(() => HomeController(repo: Get.find()));

            // Schedule & Patients
            Get.lazyPut<ScheduleApi>(() => ScheduleApi());
            Get.lazyPut<ScheduleRepo>(() => ScheduleRepo(api: Get.find()));
            Get.lazyPut<ScheduleController>(
              () => ScheduleController(repo: Get.find()),
            );
            Get.lazyPut<PatientsApi>(() => PatientsApi());
            Get.lazyPut<PatientsRepo>(() => PatientsRepo(api: Get.find()));
            Get.lazyPut<PatientsController>(
              () => PatientsController(repo: Get.find()),
            );

            // Revenue
            Get.lazyPut<RevenueApi>(() => RevenueApi());
            Get.lazyPut<RevenueRepo>(() => RevenueRepo(api: Get.find()));
            Get.lazyPut<RevenueController>(
              () => RevenueController(repo: Get.find()),
            );

            // Settings
            Get.lazyPut<DoctorAvailabilityApi>(() => DoctorAvailabilityApi());
            Get.lazyPut<DoctorAvailabilityRepo>(
              () => DoctorAvailabilityRepo(api: Get.find()),
            );
            Get.lazyPut<SettingsController>(
              () => SettingsController(repo: Get.find()),
            );
          }),
        ),
        GetPage(
          name: '/doctor_availability',
          page: () => const DoctorAvailabilityView(),
          binding: BindingsBuilder(() {
            Get.lazyPut<DoctorAvailabilityApi>(() => DoctorAvailabilityApi());
            Get.lazyPut<DoctorAvailabilityRepo>(
              () => DoctorAvailabilityRepo(api: Get.find()),
            );
            Get.lazyPut<DoctorAvailabilityController>(
              () => DoctorAvailabilityController(repo: Get.find()),
            );
          }),
        ),
        GetPage(
          name: '/password_reset',
          page: () => const PasswordResetView(),
          binding: BindingsBuilder(() {
            Get.lazyPut<PasswordResetApi>(() => PasswordResetApi());
            Get.lazyPut<PasswordResetRepo>(
              () => PasswordResetRepo(api: Get.find()),
            );
            Get.lazyPut<PasswordResetController>(
              () => PasswordResetController(repo: Get.find()),
            );
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
          name: '/new_invoice',
          page: () => const NewInvoiceView(),
          binding: BindingsBuilder(() {
            Get.lazyPut<InvoiceApi>(() => InvoiceApi());
            Get.lazyPut<InvoiceRepo>(() => InvoiceRepo(api: Get.find()));
            Get.lazyPut<InvoiceController>(
              () => InvoiceController(repo: Get.find()),
            );
          }),
        ),
        GetPage(
          name: '/doctor_profile',
          page: () => const DoctorProfileView(),
          binding: BindingsBuilder(() {
            Get.lazyPut<DoctorProfileApi>(() => DoctorProfileApi());
            Get.lazyPut<DoctorProfileRepo>(() => DoctorProfileRepo());
            Get.lazyPut<DoctorProfileController>(
              () => DoctorProfileController(repo: Get.find()),
            );
          }),
        ),
        GetPage(
          name: '/doctor_notifications',
          page: () => const DoctorNotificationView(),
          binding: BindingsBuilder(() {
            Get.lazyPut<DoctorNotificationApi>(() => DoctorNotificationApi());
            Get.lazyPut<DoctorNotificationRepo>(
              () => DoctorNotificationRepo(api: Get.find()),
            );
            Get.lazyPut<DoctorNotificationController>(
              () => DoctorNotificationController(repo: Get.find()),
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
  final String ageType;
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
    required this.appointmentTime, required this.ageType,
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
      ageType: json['age_type']?.toString() ?? 'year',
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

### File: lib\models\invoice\invoice_model.dart
```dart
// ─── نماذج الفاتورة ───
// الفاتورة = أجرة الكشف (تُضبط عند الحجز) + خدمات إضافية اختيارية يضيفها الطبيب.
// الباك إند يرجع الأسعار أحياناً كنص ("50.00") وأحياناً كرقم (95) لذلك تُمرَّر كلها عبر _toNum.

num _toNum(dynamic value) {
  if (value is num) return value;
  return num.tryParse(value?.toString() ?? '') ?? 0;
}

int _toInt(dynamic value) {
  if (value is int) return value;
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

// تفاصيل الموعد — المصدر الوحيد لأجرة الكشف والعملة (لا يوجد مسار مستقل لها)
class AppointmentInvoiceModel {
  final int appointmentId;
  final String date;
  final String day;
  final String time;
  final String status;
  final num consultationFee;
  final String currency;
  final String paymentStatus;
  final InvoiceChildModel? child;

  AppointmentInvoiceModel({
    required this.appointmentId,
    required this.date,
    required this.day,
    required this.time,
    required this.status,
    required this.consultationFee,
    required this.currency,
    required this.paymentStatus,
    this.child,
  });

  factory AppointmentInvoiceModel.fromJson(Map<String, dynamic> json) {
    return AppointmentInvoiceModel(
      appointmentId: _toInt(json['appointment_id']),
      date: json['date']?.toString() ?? '',
      day: json['day']?.toString() ?? '',
      time: json['time']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      consultationFee: _toNum(json['consultation_fee']),
      currency: json['currency']?.toString() ?? '',
      paymentStatus: json['payment_status']?.toString() ?? '',
      child: json['child'] is Map<String, dynamic>
          ? InvoiceChildModel.fromJson(json['child'])
          : null,
    );
  }
}

class InvoiceChildModel {
  final int id;
  final String name;
  final String image;
  final String gender;
  final int age;

  InvoiceChildModel({
    required this.id,
    required this.name,
    required this.image,
    required this.gender,
    required this.age,
  });

  factory InvoiceChildModel.fromJson(Map<String, dynamic> json) {
    return InvoiceChildModel(
      id: _toInt(json['id']),
      name: json['name']?.toString() ?? '',
      image: json['image']?.toString() ?? '',
      gender: json['gender']?.toString() ?? 'male',
      age: _toInt(json['age']),
    );
  }
}

// خدمة إضافية واحدة — يُحفظ id لأنه المعرف المطلوب للحذف
class AdditionModel {
  final int id;
  final int appointmentId;
  final String itemName;
  final num price;

  AdditionModel({
    required this.id,
    required this.appointmentId,
    required this.itemName,
    required this.price,
  });

  factory AdditionModel.fromJson(Map<String, dynamic> json) {
    return AdditionModel(
      id: _toInt(json['id']),
      appointmentId: _toInt(json['appointment_id']),
      itemName: json['item_name']?.toString() ?? '',
      price: _toNum(json['price']),
    );
  }
}

// الفاتورة الكاملة كما يرجعها الخادم بعد كل إضافة أو حذف —
// ترسم الشاشة منها مباشرة دون إعادة جلب.
class InvoiceModel {
  final int appointmentId;
  final num appointmentPrice;
  final List<AdditionModel> additions;
  final num totalAdditions;
  final num finalPrice;

  InvoiceModel({
    required this.appointmentId,
    required this.appointmentPrice,
    required this.additions,
    required this.totalAdditions,
    required this.finalPrice,
  });

  factory InvoiceModel.fromJson(Map<String, dynamic> json) {
    final rawAdditions = json['additions'] as List? ?? [];
    return InvoiceModel(
      appointmentId: _toInt(json['appointment_id']),
      appointmentPrice: _toNum(json['appointment_price']),
      additions: rawAdditions
          .whereType<Map<String, dynamic>>()
          .map(AdditionModel.fromJson)
          .toList(),
      totalAdditions: _toNum(json['total_additions']),
      finalPrice: _toNum(json['final_price']),
    );
  }
}

```

### File: lib\models\notification\doctor_notification_model.dart
```dart
class DoctorNotificationModel {
  final int id;
  final String title;
  final String message;
  final String createdAt;

  DoctorNotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.createdAt,
  });

  factory DoctorNotificationModel.fromJson(Map<String, dynamic> json) {
    return DoctorNotificationModel(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      title: json['title']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      createdAt: json['created_at']?.toString() ?? '',
    );
  }
}
```

### File: lib\models\patients\medical_file_model.dart
```dart
class MedicalFileModel {
  final PatientInfo patientInfo;
  final MedicalSummary summary;

  MedicalFileModel({required this.patientInfo, required this.summary});

  factory MedicalFileModel.fromJson(Map<String, dynamic> json) {
    return MedicalFileModel(
      patientInfo: PatientInfo.fromJson(json['patient_info'] ?? {}),
      summary: MedicalSummary.fromJson(json['summary'] ?? {}),
    );
  }
}

class PatientInfo {
  final int id;
  final String name;
  final int age;
  final String gender;
  final String fileNumber;
  final String image;

  PatientInfo({
    required this.id,
    required this.name,
    required this.age,
    required this.gender,
    required this.fileNumber,
    required this.image,
  });

  factory PatientInfo.fromJson(Map<String, dynamic> json) {
    String rawImage = json['image']?.toString() ?? '';
    if (rawImage.contains('http')) {
      final parts = rawImage.split('8000/');
      rawImage = parts.length > 1 ? parts.last : rawImage;
    }

    return PatientInfo(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? '',
      age: int.tryParse(json['age']?.toString() ?? '0') ?? 0,
      gender: json['gender']?.toString() ?? 'male',
      fileNumber: json['file_number']?.toString() ?? '',
      image: rawImage,
    );
  }
}

class MedicalSummary {
  final String weight;
  final String weightStatus;
  final String height;
  final String heightStatus;
  final String bloodType;
  final String allergies;
  final VisitModel? lastVisit;
  final List<VisitModel> previousVisits;

  MedicalSummary({
    required this.weight,
    required this.weightStatus,
    required this.height,
    required this.heightStatus,
    required this.bloodType,
    required this.allergies,
    this.lastVisit,
    required this.previousVisits,
  });

  factory MedicalSummary.fromJson(Map<String, dynamic> json) {
    var previousList = json['previous_visits'] as List? ?? [];
    return MedicalSummary(
      weight: json['weight']?.toString() ?? '',
      weightStatus: json['weight_status']?.toString() ?? '',
      height: json['height']?.toString() ?? '',
      heightStatus: json['height_status']?.toString() ?? '',
      bloodType: json['blood_type']?.toString() ?? '',
      allergies: json['allergies']?.toString() ?? '',
      lastVisit: json['last_visit'] != null ? VisitModel.fromJson(json['last_visit']) : null,
      previousVisits: previousList.map((e) => VisitModel.fromJson(e)).toList(),
    );
  }
}

class VisitModel {
  final String date;
  final String doctorName;
  final String diagnosis;

  VisitModel({required this.date, required this.doctorName, required this.diagnosis});

  factory VisitModel.fromJson(Map<String, dynamic> json) {
    return VisitModel(
      date: json['date']?.toString() ?? '',
      doctorName: json['doctor_name']?.toString() ?? '',
      diagnosis: json['diagnosis']?.toString() ?? '',
    );
  }
}
```

### File: lib\models\profile\doctor_profile_model.dart
```dart
class DoctorProfileModel {
  final String firstName;
  final String lastName;
  final String email;
  final String phoneNumber;
  final String address;
  final int experienceYears;
  final String education;
  final String? profilePicture;
  final String? cv;

  DoctorProfileModel({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phoneNumber,
    required this.address,
    required this.experienceYears,
    required this.education,
    this.profilePicture,
    this.cv,
  });

  String get fullName => '$firstName $lastName';

  factory DoctorProfileModel.fromJson(Map<String, dynamic> json) {
    final user = json['user'] ?? json;
    return DoctorProfileModel(
      firstName: user['first_name']?.toString() ?? '',
      lastName: user['last_name']?.toString() ?? '',
      email: user['email']?.toString() ?? '',
      phoneNumber: user['phone_number']?.toString() ?? '',
      address: user['address']?.toString() ?? '',
      // 👈 استخدام int.tryParse المتوافق مع باقي نماذج تطبيق الطبيب
      experienceYears: int.tryParse(user['experience_years']?.toString() ?? '0') ?? 0,
      education: user['education']?.toString() ?? '',
      profilePicture: user['profile_picture']?.toString(),
      cv: user['cv']?.toString(),
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
  final String childAgeType;

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
    required this.parentsNotes, required this.childAgeType,
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
      childAgeType: child['age_type']?.toString() ?? 'year',

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
  final String ageType;
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
    required this.fileNumber, required this.ageType,
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
      ageType: json['age_type']?.toString() ?? 'year',
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
  final String ageType;
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
    required this.status, required this.ageType,
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
      ageType: json['age_type']?.toString() ?? 'year',
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

### File: lib\models\settings\availability_item_model.dart
```dart
class AvailabilityItemModel {
  final int id;
  final int doctorId;
  final String dayOfWeek;
  final String startTime;
  final String endTime;

  AvailabilityItemModel({
    required this.id,
    required this.doctorId,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
  });

  factory AvailabilityItemModel.fromJson(Map<String, dynamic> json) {
    // دالة مساعدة لقص الثواني من الوقت القادم من لارافيل
    String formatTime(String time) {
      if (time.length >= 5) return time.substring(0, 5);
      return time;
    }

    return AvailabilityItemModel(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      doctorId: int.tryParse(json['doctor_id']?.toString() ?? '0') ?? 0,
      dayOfWeek: json['day_of_week']?.toString() ?? '',
      startTime: formatTime(json['start_time']?.toString() ?? ''),
      endTime: formatTime(json['end_time']?.toString() ?? ''),
    );
  }
}

```

### File: lib\models\settings\available_period_model.dart
```dart
class AvailablePeriodModel {
  final String day;
  final String dayName;
  final List<FreePeriodModel> freePeriods;

  AvailablePeriodModel({
    required this.day,
    required this.dayName,
    required this.freePeriods,
  });

  factory AvailablePeriodModel.fromJson(Map<String, dynamic> json) {
    final list = json['free_periods'] as List? ?? [];
    return AvailablePeriodModel(
      day: json['day']?.toString() ?? '',
      dayName: json['day_name']?.toString() ?? '',
      freePeriods: list.map((e) => FreePeriodModel.fromJson(e)).toList(),
    );
  }
}

class FreePeriodModel {
  final String startTime;
  final String endTime;

  FreePeriodModel({
    required this.startTime,
    required this.endTime,
  });

  factory FreePeriodModel.fromJson(Map<String, dynamic> json) {
    return FreePeriodModel(
      // قص الثواني إن وجدت للترتيب البصري
      startTime: (json['start_time']?.toString() ?? '').split(':').take(2).join(':'),
      endTime: (json['end_time']?.toString() ?? '').split(':').take(2).join(':'),
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

### File: lib\service\notification_service.dart
```dart
import 'dart:developer';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../core/constants.dart';
import '../core/helper/secure_storage_service.dart';
import '../controllers/home/home_controller.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  log(
    "📩 إشعار جديد في الخلفية للطبيب (Background/Terminated): ${message.messageId}",
  );
}

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _appointmentsChannel =
      AndroidNotificationChannel(
        'doctor_appointments_channel', // channelId
        'Appointments Notifications', // channelName
        description: 'This channel is used for new or cancelled appointments.',
        importance: Importance.max,
        playSound: true,
      );

  static Future<void> initialize() async {
    // 1. طلب الصلاحيات
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      log("🔔 تم منح صلاحيات الإشعارات بنجاح من قبل الطبيب.");
    }

    // 2. إنشاء الإشعارات  بالأندرويد
    await _localNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_appointmentsChannel);

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    // 3. تهيئة Local Notifications
    await _localNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.payload != null) {
          _handleNotificationClick(response.payload!);
        }
      },
    );

    // 4. معالجة الإشعارات في الخلفية
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 5. استلام الإشعارات أثناء فتح التطبيق (Foreground)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      log(
        "📥 استلام إشعار حي وتطبيق الطبيب مفتوح: ${message.notification?.title}",
      );
      _showLocalNotification(message);

      if (Get.isRegistered<HomeController>()) {
        Get.find<HomeController>().hasUnreadNotifications.value = true;
      }
    });

    // 6. النقر على الإشعار والتطبيق في الخلفية
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      log("🖱️ تم النقر على الإشعار وتطبيق الطبيب بالخلفية: ${message.data}");
      if (message.data.containsKey('type')) {
        _handleNotificationClick(message.data['type'].toString());
      }
    });

    // 7. النقر على الإشعار والتطبيق مغلق تماماً (Terminated)
    RemoteMessage? initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null && initialMessage.data.containsKey('type')) {
      log("🚀 إقلاع تطبيق الطبيب من الصفر بنقرة إشعار: ${initialMessage.data}");
      _handleNotificationClick(initialMessage.data['type'].toString());
    }
  }

  // 8. جلب التوكن وإرساله للسيرفر
  static Future<void> sendFCMTokenToServer() async {
    try {
      String? fcmToken = await _messaging.getToken();
      if (fcmToken != null && fcmToken.isNotEmpty) {
        log("🔑 🔑 🔑 DOCTOR DEVICE FCM TOKEN = $fcmToken");

        String doctorToken = await SecureStorage.getToken();
        if (doctorToken.isEmpty || doctorToken == 'null') {
          log("⚠️ لم يتم إرسال FCM Token لأن الطبيب لم يسجل دخوله بعد.");
          return;
        }

        final response = await http.post(
          Uri.parse('$baseUrl/api/parent/save-fcm-token'),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $doctorToken',
          },
          body: {'fcm_token': fcmToken},
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          log("✅ تم حفظ الـ FCM Token للطبيب في الباك إند بنجاح!");
        } else {
          log("⚠️ الباك إند رفض التوكن (تأكد من الـ Route): ${response.body}");
        }
      }
    } catch (e) {
      log("❌ فشل توليد الـ FCM Token للطبيب: $e");
    }
  }

  static void _showLocalNotification(RemoteMessage message) {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null && android != null) {
      String notificationType = message.data['type']?.toString() ?? 'general';

      _localNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _appointmentsChannel.id,
            _appointmentsChannel.name,
            channelDescription: _appointmentsChannel.description,
            importance: Importance.max,
            priority: Priority.high,
            icon: android.smallIcon,
            //icon: '@mipmap/ic_launcher',
            //color: const Color(0xFF00B4D8),
            playSound: true,
          ),
        ),
        payload: notificationType,
      );
    }
  }

  static void _handleNotificationClick(String type) {
    log("🔀 جاري توجيه الطبيب بناءً على نوع الإشعار: $type");

    final typeLower = type.toLowerCase();


    Get.offAllNamed('/doctor_home');

    Future.delayed(const Duration(milliseconds: 500), () {
      if (Get.isRegistered<HomeController>()) {
        final homeCtrl = Get.find<HomeController>();
        homeCtrl.fetchAllDashboardData();

        // التوجيه للتابات
        if (typeLower.contains('cancel') || typeLower.contains('appointment')) {
          homeCtrl.currentIndex.value = 1; //  (Schedule)
        } else if (typeLower.contains('arrived')) {
          homeCtrl.currentIndex.value = 0; //  (Dashboard)
        }
      }
    });
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
                  'assets/images/kidcare_pro_logo.png',
                  height: 300,
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
          physics: const NeverScrollableScrollPhysics(), // منع السحب اليدوي تماماً لإجبارية المسار
          children: [
            _buildPhoneStep(context),        // الواجهة الأولى: رقم الهاتف
            _buildNewPasswordStep(context),  // الواجهة الثانية: كلمة المرور الجديدة مباشرة
          ],
        ),
      ),
    );
  }

  // ─── الواجهة الأولى: إدخال الموبايل ───
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
            text: 'Continue'.tr, // تم تغيير النص إلى "متابعة" بما أنه لا يوجد إرسال OTP هنا
            isLoading: controller.isLoading,
            onPressed: () => controller.validatePhoneAndContinue(), // استدعاء دالة التحقق والانتقال الفوري
          )),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ─── الواجهة الثانية: إدخال كلمة المرور وتأكيدها ───
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
import '../../widgets/examination/diagnosis_tab.dart';
import '../../widgets/examination/examination_bottom_action.dart';
import '../../widgets/examination/examination_tabs.dart';
import '../../widgets/examination/patient_header.dart';
import '../../widgets/examination/prescription_tab.dart';

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
      ),
      body: SafeArea(
        child: Column(
          children: [
            const PatientHeader(),
            const ExaminationTabs(),
            Expanded(
              child: Obx(() {
                switch (controller.selectedTab.value) {
                  case 1:
                    return const PrescriptionTab();
                  case 0:
                  default:
                    return const DiagnosisTab();
                }
              }),
            ),
            const ExaminationBottomAction(),
          ],
        ),
      ),
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

### File: lib\views\invoice\new_invoice_view.dart
```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/invoice/invoice_controller.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/examination/examination_fields.dart';
import '../../widgets/invoice/consultation_fee_card.dart';
import '../../widgets/invoice/extra_services_card.dart';
import '../../widgets/invoice/invoice_patient_card.dart';
import '../../widgets/invoice/invoice_summary_card.dart';

// ─── شاشة الفاتورة — أجرة الكشف + خدمات إضافية اختيارية ───
class NewInvoiceView extends GetView<InvoiceController> {
  const NewInvoiceView({super.key});

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
        title: Text('New Invoice'.tr),
      ),
      body: SafeArea(
        child: Obx(() {
          // تفاصيل الموعد تحمل الأجرة، فلا معنى لرسم الفاتورة قبل وصولها
          if (controller.isLoading && controller.appointment.value == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const InvoicePatientCard(),
                      const SizedBox(height: 20),
                      buildSectionTitle(context, 'Consultation Fee'.tr),
                      const SizedBox(height: 10),
                      const ConsultationFeeCard(),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: buildSectionTitle(
                              context,
                              'Extra Services'.tr,
                            ),
                          ),
                          Obx(
                            () => controller.isSubmittingItem.value
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : buildAddLink(
                                    context,
                                    'Add Item'.tr,
                                    controller.addItem,
                                  ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const ExtraServicesCard(),
                      const SizedBox(height: 20),
                      const InvoiceSummaryCard(),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: CustomButton(
                  text: 'Done'.tr,
                  onPressed: controller.closeInvoice,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

```

### File: lib\views\notification\doctor_notification_view.dart
```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/notification/doctor_notification_controller.dart';

class DoctorNotificationView extends GetView<DoctorNotificationController> {
  const DoctorNotificationView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Notifications'.tr,
          style: TextStyle(
            color: context.textTheme.bodyLarge?.color,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: context.theme.iconTheme.color,
            size: 20,
          ),
          onPressed: () => Get.back(),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading && controller.notifications.isEmpty) {
          return Center(
            child: CircularProgressIndicator(color: context.theme.primaryColor),
          );
        }

        if (controller.notifications.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.notifications_off_outlined,
                  size: 64,
                  color: context.theme.hintColor.withValues(alpha: 0.4),
                ),
                const SizedBox(height: 12),
                Text(
                  'No notifications yet'.tr,
                  style: TextStyle(
                    fontSize: 16,
                    color: context.theme.hintColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          color: context.theme.primaryColor,
          onRefresh: controller.fetchNotifications,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            itemCount: controller.notifications.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = controller.notifications[index];
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => controller.handleNotificationTap(item), // 👈 استدعاء دالة التوجيه
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: context.theme.cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: context.theme.dividerColor.withValues(alpha: 0.2),
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
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: context.theme.primaryColor.withValues(
                              alpha: 0.1,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.notifications_active_outlined,
                            color: context.theme.primaryColor,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.title,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: context.textTheme.bodyLarge?.color,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                item.message,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: context.textTheme.bodyMedium?.color,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                controller.formatDateTime(item.createdAt),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: context.theme.hintColor.withValues(
                                    alpha: 0.6,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      }),
    );
  }
}
```

### File: lib\views\patients\medical_file_view.dart
```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/patients/medical_file_controller.dart';
import '../../core/constants.dart';
import '../../models/patients/medical_file_model.dart';

class MedicalFileView extends GetView<MedicalFileController> {
  const MedicalFileView({super.key});

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
          'Medical File'.tr,
          style: context.theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        // تم إلغاء زر الثلاث نقاط من هنا
      ),
      body: Obx(() {
        if (controller.isLoading) {
          return Center(child: CircularProgressIndicator(color: context.theme.primaryColor));
        }

        final data = controller.medicalFile.value;
        if (data == null) {
          return Center(child: Text('No details found'.tr));
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: _buildPatientHeader(context, data.patientInfo),
            ),
            const SizedBox(height: 16),
            _buildCustomTabBar(context),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
                child: _buildTabContent(context, data.summary),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildPatientHeader(BuildContext context, PatientInfo info) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.theme.primaryColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: context.theme.primaryColor.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 35,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            backgroundImage: info.image.isNotEmpty ? NetworkImage('$baseUrl/${info.image}') : null,
            child: info.image.isEmpty ? const Icon(Icons.person, size: 35, color: Colors.white) : null,
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
                      info.name,
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const Icon(Icons.calendar_today_outlined, color: Colors.white, size: 20),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '${info.age} ${'Yrs'.tr} - ${info.gender.tr}',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14),
                ),
                const SizedBox(height: 6),
                Text(
                  'ID: ${info.fileNumber}',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomTabBar(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: List.generate(
          controller.tabs.length,
              (index) => Obx(() {
            final isSelected = controller.selectedTab.value == index;
            return GestureDetector(
              onTap: () => controller.changeTab(index),
              child: Container(
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? context.theme.primaryColor.withValues(alpha: 0.1) : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  controller.tabs[index].tr,
                  style: TextStyle(
                    color: isSelected ? context.theme.primaryColor : context.theme.hintColor,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildTabContent(BuildContext context, MedicalSummary summary) {
    return Obx(() {
      switch (controller.selectedTab.value) {
        case 0: // Summary
          return _buildSummaryTab(context, summary);
        default:
          return Center(child: Text('Under Construction'.tr, style: TextStyle(color: context.theme.hintColor)));
      }
    });
  }

  Widget _buildSummaryTab(BuildContext context, MedicalSummary summary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: _buildVitalCard(context, 'Weight'.tr, '${summary.weight} ${'kg'.tr}', summary.weightStatus)),
            const SizedBox(width: 12),
            Expanded(child: _buildVitalCard(context, 'Height'.tr, '${summary.height} ${'cm'.tr}', summary.heightStatus)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildVitalCard(context, 'Blood Type'.tr, summary.bloodType, null)),
            const SizedBox(width: 12),
            Expanded(child: _buildVitalCard(context, 'Allergies'.tr, summary.allergies.tr, null)),
          ],
        ),
        const SizedBox(height: 24),

        // Last Visit
        if (summary.lastVisit != null) ...[
          Text('Last Visit'.tr, style: context.theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.theme.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: context.theme.dividerColor.withValues(alpha: 0.1)),
            ),
            child: Row(
              children: [
                Icon(Icons.monitor_heart_outlined, color: context.theme.primaryColor, size: 28),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(summary.lastVisit!.date, style: context.theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('${'Diagnosis'.tr}: ${summary.lastVisit!.diagnosis.tr}', style: context.theme.textTheme.bodySmall?.copyWith(color: context.theme.hintColor)),
                    ],
                  ),
                ),
                Text(summary.lastVisit!.doctorName, style: context.theme.textTheme.bodySmall?.copyWith(color: context.theme.hintColor)),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],

        // Previous Visits
        Text('Previous Visits'.tr, style: context.theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.theme.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.theme.dividerColor.withValues(alpha: 0.1)),
          ),
          child: Column(
            children: [
              ...summary.previousVisits.map((visit) => Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(visit.date, style: context.theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(visit.diagnosis.tr, style: context.theme.textTheme.bodySmall?.copyWith(color: context.theme.hintColor)),
                      ],
                    ),
                    Text(visit.doctorName, style: context.theme.textTheme.bodySmall?.copyWith(color: context.theme.hintColor)),
                  ],
                ),
              )),
              const Divider(),
              TextButton(
                onPressed: () {},
                child: Text('View All Visits'.tr, style: TextStyle(color: context.theme.primaryColor, fontWeight: FontWeight.bold)),
              )
            ],
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildVitalCard(BuildContext context, String title, String value, String? status) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.theme.dividerColor.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(title, style: context.theme.textTheme.bodySmall?.copyWith(color: context.theme.hintColor)),
          const SizedBox(height: 8),
          Text(value, style: context.theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          if (status != null && status.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                status.tr,
                style: const TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
          ]
        ],
      ),
    );
  }
}
```

### File: lib\views\profile\doctor_profile_view.dart
```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/profile/doctor_profile_controller.dart';
import '../../core/constants.dart';

class DoctorProfileView extends GetView<DoctorProfileController> {
  const DoctorProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Personal Profile'.tr,
          style: TextStyle(
            color: context.textTheme.bodyLarge?.color,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: context.theme.iconTheme.color,
            size: 20,
          ),
          onPressed: () => Get.back(),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading && controller.profile.value == null) {
          return Center(
            child: CircularProgressIndicator(color: context.theme.primaryColor),
          );
        }

        final user = controller.profile.value;
        if (user == null) {
          return Center(
            child: Text(
              'Failed to load profile'.tr,
              style: TextStyle(color: context.theme.hintColor),
            ),
          );
        }

        return RefreshIndicator(
          color: context.theme.primaryColor,
          onRefresh: controller.fetchProfile,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              children: [
                // ─── Avatar & Name ───
                Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: context.theme.primaryColor.withOpacity(
                          0.1,
                        ),
                        backgroundImage:
                            (user.profilePicture != null &&
                                user.profilePicture!.isNotEmpty)
                            ? NetworkImage(
                                '$baseUrl/storage/${user.profilePicture}',
                              )
                            : null,
                        child:
                            (user.profilePicture == null ||
                                user.profilePicture!.isEmpty)
                            ? Icon(
                                Icons.person,
                                size: 50,
                                color: context.theme.primaryColor,
                              )
                            : null,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        user.fullName,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: context.textTheme.bodyLarge?.color,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.education,
                        style: TextStyle(
                          fontSize: 14,
                          color: context.theme.hintColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                // ─── Info Fields ───
                Container(
                  decoration: BoxDecoration(
                    color: context.theme.cardColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: context.theme.dividerColor.withOpacity(0.5),
                    ),
                  ),
                  child: Column(
                    children: [
                      _buildInfoTile(
                        context,
                        Icons.person_outline,
                        'First Name'.tr,
                        user.firstName,
                        'first_name',
                      ),
                      _buildDivider(context),
                      _buildInfoTile(
                        context,
                        Icons.person_outline,
                        'Last Name'.tr,
                        user.lastName,
                        'last_name',
                      ),
                      _buildDivider(context),
                      _buildInfoTile(
                        context,
                        Icons.phone_outlined,
                        'Phone Number'.tr,
                        user.phoneNumber,
                        'phone_number',
                        isPhone: true,
                      ),
                      _buildDivider(context),
                      _buildInfoTile(
                        context,
                        Icons.email_outlined,
                        'Email'.tr,
                        user.email,
                        'email',
                      ),
                      _buildDivider(context),
                      _buildInfoTile(
                        context,
                        Icons.location_on_outlined,
                        'Address'.tr,
                        user.address,
                        'address',
                      ),
                      _buildDivider(context),
                      _buildInfoTile(
                        context,
                        Icons.work_outline,
                        'Experience Years'.tr,
                        '${user.experienceYears}',
                        'experience_years',
                        isNumber: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildInfoTile(
    BuildContext context,
    IconData icon,
    String label,
    String value,
    String apiFieldKey, {
    bool isPhone = false,
    bool isNumber = false,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: context.theme.primaryColor.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: context.theme.primaryColor, size: 22),
      ),
      title: Text(
        label,
        style: TextStyle(fontSize: 12, color: context.theme.hintColor),
      ),
      subtitle: Text(
        value.isEmpty ? 'Not set'.tr : value,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: context.textTheme.bodyLarge?.color,
        ),
      ),
      trailing: Icon(
        Icons.edit_outlined,
        size: 18,
        color: context.theme.hintColor,
      ),
      onTap: () => _showEditDialog(
        context,
        label,
        value,
        apiFieldKey,
        isPhone,
        isNumber,
      ),
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Divider(
      color: context.theme.dividerColor.withOpacity(0.3),
      height: 1,
      indent: 70,
      endIndent: 20,
    );
  }

  void _showEditDialog(
    BuildContext context,
    String label,
    String currentValue,
    String apiFieldKey,
    bool isPhone,
    bool isNumber,
  ) {
    final TextEditingController textController = TextEditingController(
      text: currentValue,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: context.theme.scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Edit'.tr + ' ' + label,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: context.textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: textController,
                  keyboardType: isPhone
                      ? TextInputType.phone
                      : (isNumber ? TextInputType.number : TextInputType.text),
                  style: TextStyle(color: context.textTheme.bodyLarge?.color),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: context.theme.cardColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: context.theme.primaryColor),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          onPressed: () => Get.back(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                context.theme.scaffoldBackgroundColor,
                            foregroundColor: context.textTheme.bodyLarge?.color,
                            elevation: 0,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: context.theme.dividerColor,
                                width: 1.5,
                              ),
                            ),
                          ),
                          child: Text(
                            'Cancel'.tr,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // 👈 زر الحفظ
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          onPressed: () {
                            Get.back();
                            controller.updateProfileField(
                              apiFieldKey,
                              textController.text,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: context.theme.primaryColor,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Save'.tr,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }
}

```

### File: lib\views\revenue\revenue_view.dart
```dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/revenue/revenue_controller.dart';

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
        automaticallyImplyLeading: false,
        title: Text(
          'Wallet'.tr,
          style: TextStyle(
            color: context.theme.colorScheme.onSurface,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
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
                _buildChartCard(context),
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
                      '${_formatThousands(controller.monthlyRevenue.value)} ${'USD'.tr}',
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
            child: Obx(() => controller.yearlyIncome.isEmpty
                ? const SizedBox.shrink()
                : CustomPaint(
                    painter: _LineChartPainter(
                      data: controller.yearlyIncome.toList(),
                      plotCount: _elapsedMonths(controller.yearlyIncome.length),
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
              'Yearly Income'.tr,
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
    final data = controller.yearlyIncome.toList();
    if (data.isEmpty) {
      return Center(
        child: Text('No data'.tr, style: TextStyle(color: context.theme.hintColor)),
      );
    }

    // The API always returns all 12 months, with the ones still ahead of us as
    // 0. Plotting those would draw the year falling off a cliff, so the line
    // stops at the current month while the axis keeps its full 12 slots.
    final plotCount = _elapsedMonths(data.length);
    final plotted = data.take(plotCount);
    final dataMax = plotted.reduce((a, b) => a > b ? a : b);
    final peakMonth = data.indexOf(dataMax);
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
                'USD'.tr,
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
                    plotCount: plotCount,
                    lineColor: context.theme.primaryColor,
                    showDots: true,
                    showGrid: true,
                    fillOpacity: 0.08,
                    tooltip: '${_formatThousands(dataMax)} ${'USD'.tr}',
                    tooltipBg: context.theme.primaryColor,
                    tooltipIndex: peakMonth,
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
    // Only a few of the 12 months are labelled, otherwise they overlap. Each
    // sits under its real point on the chart.
    const marks = [0, 3, 6, 9, 11];
    final shown = marks.where((m) => m < count).toList();
    final style = TextStyle(fontSize: 9, color: context.theme.hintColor);

    return SizedBox(
      height: 12,
      child: LayoutBuilder(
        builder: (ctx, box) {
          final width = box.maxWidth;
          return Stack(
            clipBehavior: Clip.none,
            children: shown.map((m) {
              // point m (0-indexed) is drawn at x = m/(count-1) of the width
              final t = count > 1 ? m / (count - 1) : 0.0;
              final label = Text(_monthKeys[m].tr, style: style);
              // Anchor first label to the left edge and last to the right edge
              // so nothing clips; center the rest on their point.
              if (m == shown.first) {
                return Positioned(left: 0, child: label);
              }
              if (m == shown.last) {
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

  // ─── Month helpers ────────────────────────────────────────────────────────

  /// Translation keys for the month labels. The backend sends `month` in
  /// English no matter the `Accept-Language` header, so the label is always
  /// derived from the value's position in the year and localized here instead.
  static const _monthKeys = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  /// How many months of the year have data worth plotting — everything up to
  /// and including the current one.
  int _elapsedMonths(int count) => DateTime.now().month.clamp(1, count);

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
  // How many of [data]'s points to actually draw. The X axis still spans the
  // full list, so a partly-elapsed year keeps all 12 month slots.
  final int? plotCount;
  final Color lineColor;
  final bool showDots;
  final bool showGrid;
  final double fillOpacity;
  final String? tooltip;
  final Color? tooltipBg;
  // Which point the tooltip bubble and the emphasized dot sit on. Defaults to
  // the last drawn point.
  final int? tooltipIndex;
  // When set, normalizes Y against this ceiling (must match Y-axis labels).
  // When null, self-computes from data min→max (used for the sparkline).
  final double? axisMax;

  const _LineChartPainter({
    required this.data,
    required this.lineColor,
    required this.showDots,
    required this.showGrid,
    required this.fillOpacity,
    this.plotCount,
    this.tooltip,
    this.tooltipBg,
    this.tooltipIndex,
    this.axisMax,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;
    final count = (plotCount ?? data.length).clamp(1, data.length);
    final drawn = data.take(count);

    final dataMax = drawn.reduce((a, b) => a > b ? a : b);
    final dataMin = drawn.reduce((a, b) => a < b ? a : b);
    // Use the axis ceiling when provided so the line matches the Y-axis labels.
    // Fall back to min→max normalization for the compact sparkline.
    final yMax = axisMax ?? dataMax;
    final yMin = axisMax != null ? 0.0 : dataMin;
    final range = (yMax - yMin) == 0 ? 1.0 : (yMax - yMin);
    final xStep = data.length > 1 ? size.width / (data.length - 1) : 0.0;

    Offset toPoint(int i) => Offset(
          i * xStep,
          size.height - ((data[i] - yMin) / range) * size.height * 0.9 -
              size.height * 0.05,
        );

    final points = List.generate(count, toPoint);

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
    if (fillOpacity > 0 && points.length > 1) {
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

    if (points.length > 1) {
      final path = Path()..moveTo(points[0].dx, points[0].dy);
      for (int i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
      }
      canvas.drawPath(path, linePaint);
    }

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

      // Emphasized point — the one the tooltip is about
      final last = points[(tooltipIndex ?? points.length - 1)
          .clamp(0, points.length - 1)];
      canvas.drawCircle(last, 4, Paint()..color = lineColor);
      canvas.drawCircle(last, 2, Paint()..color = Colors.white);

      // Tooltip bubble above that point
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
      old.data != data ||
      old.plotCount != plotCount ||
      old.lineColor != lineColor ||
      old.tooltip != tooltip ||
      old.tooltipIndex != tooltipIndex ||
      old.axisMax != axisMax;
}

```

### File: lib\views\schedule\appointment_details_view.dart
```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/schedule/appointment_details_controller.dart';
import '../../core/constants.dart';

// تم استدعاء المودل هنا لتعريف نوع البيانات
import '../../models/home/doctor_dashboard_model.dart';
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
        iconTheme: IconThemeData(
          color: context.theme.textTheme.bodyLarge?.color,
        ),
        title: Text(
          'Appointment Details'.tr,
          style: context.theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading) {
          return Center(
            child: CircularProgressIndicator(color: context.theme.primaryColor),
          );
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
                style: context.theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _buildAppointmentInfoCard(context, data),
              const SizedBox(height: 24),
              Text(
                'Parents Notes'.tr,
                style: context.theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _buildNotesCard(context, data),
              const SizedBox(height: 32),
              if (data.status != 'cancelled_by_clinic' &&
                  data.status != 'cancelled_by_patient' &&
                  data.status != 'completed')
                _buildActionButtons(context, data),
            ],
          ),
        );
      }),
    );
  }

  // تم تغيير dynamic إلى AppointmentDetailsModel هنا
  Widget _buildPatientHeader(
    BuildContext context,
    AppointmentDetailsModel data,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.theme.dividerColor.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 35,
            backgroundColor: context.theme.dividerColor.withValues(alpha: 0.1),
            backgroundImage: data.childImage.isNotEmpty
                ? NetworkImage('$baseUrl/${data.childImage}')
                : null,
            child: data.childImage.isEmpty
                ? Icon(Icons.person, size: 35, color: context.theme.hintColor)
                : null,
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
                      style: context.theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Icon(
                      Icons.calendar_today_outlined,
                      color: context.theme.hintColor,
                      size: 20,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${data.childAge} ${data.childAgeType.tr} - ${data.childGender.tr}',
                  style: context.theme.textTheme.bodyMedium?.copyWith(
                    color: context.theme.hintColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${'File No'.tr}: ${data.fileNumber}',
                  style: context.theme.textTheme.bodyMedium?.copyWith(
                    color: context.theme.hintColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // تم تغيير dynamic إلى AppointmentDetailsModel هنا
  Widget _buildAppointmentInfoCard(
    BuildContext context,
    AppointmentDetailsModel data,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.theme.dividerColor.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        children: [
          _buildInfoRow(
            context,
            Icons.calendar_today,
            'Date'.tr,
            '${data.day.tr}, ${data.date}',
          ),
          const SizedBox(height: 16),
          _buildInfoRow(context, Icons.access_time, 'Time'.tr, data.time.tr),
          const SizedBox(height: 16),
          _buildInfoRow(
            context,
            Icons.person_outline,
            'Appointment Type'.tr,
            data.appointmentType.tr,
          ),
          const SizedBox(height: 16),
          _buildPaymentRow(
            context,
            Icons.credit_card,
            'Payment Status'.tr,
            data.paymentStatus,
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            context,
            Icons.attach_money,
            'Consultation Fee'.tr,
            '${data.consultationFee} ${data.currency}',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Row(
      children: [
        Icon(icon, color: context.theme.hintColor, size: 20),
        const SizedBox(width: 12),
        Text(
          label,
          style: context.theme.textTheme.bodyMedium?.copyWith(
            color: context.theme.hintColor,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: context.theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentRow(
    BuildContext context,
    IconData icon,
    String label,
    String status,
  ) {
    Color badgeColor = status == 'partially_paid' || status == 'paid'
        ? Colors.green
        : Colors.orange;

    return Row(
      children: [
        Icon(icon, color: context.theme.hintColor, size: 20),
        const SizedBox(width: 12),
        Text(
          label,
          style: context.theme.textTheme.bodyMedium?.copyWith(
            color: context.theme.hintColor,
          ),
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
            style: TextStyle(
              color: badgeColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
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
        border: Border.all(
          color: context.theme.dividerColor.withValues(alpha: 0.05),
        ),
      ),
      child: Text(
        data.parentsNotes,
        style: context.theme.textTheme.bodyMedium?.copyWith(height: 1.5),
      ),
    );
  }

  // 👈 تم إضافة استقبال متغير data
  Widget _buildActionButtons(
    BuildContext context,
    AppointmentDetailsModel data,
  ) {
    return Row(
      children: [
        // زر الإلغاء (فارغ حالياً ريثما نربطه لاحقاً بـ API الإلغاء)
        Expanded(
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => controller.confirmCancellation(),
            child: Text(
              'Cancel Appointment'.tr,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(width: 16),
        // زر بدء المعاينة (التعديل الجذري تم هنا)
        Expanded(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: context.theme.primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              // 1. استخراج بيانات المريض والموعد من الواجهة الحالية وتجهيزها
              final patientToExamine = PatientModel(
                id: data.childId,
                appointmentId: data.appointmentId,
                name: data.childName,
                age: data.childAge,
                ageType: data.childAgeType,
                gender: data.childGender,
                image: data.childImage,
                appointmentTime: data.time,
              );

              // 2. الانتقال إلى شاشة المعاينة وتمرير البيانات معها
              Get.toNamed('/examination', arguments: patientToExamine);
            },
            child: Text(
              'Start Consultation'.tr,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
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
                        '${patient.age} ${patient.ageType.tr} - ${patient.gender.tr}',
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
            onTap: () {
              Get.toNamed('/medical_file', arguments: patient.id);
            },
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
                                    '${appointment.age} ${appointment.ageType.tr} - ${appointment.gender.tr}',
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
import '../../models/settings/available_period_model.dart';

class DoctorAvailabilityView extends GetView<DoctorAvailabilityController> {
  const DoctorAvailabilityView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: context.theme.appBarTheme.iconTheme?.color,
          ),
          onPressed: () => Get.back(),
        ),
        title: Text('Clinic Settings'.tr),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      floatingActionButton: Obx(
        () => controller.selectedTab.value == 0
            ? FloatingActionButton.extended(
                onPressed: () => _showAddBottomSheet(context),
                backgroundColor: context.theme.primaryColor,
                icon: const Icon(Icons.add, color: Colors.white),
                label: Text(
                  'Enter Working Day'.tr,
                  style: const TextStyle(color: Colors.white),
                ),
              )
            : const SizedBox.shrink(),
      ),
      body: Column(
        children: [
          // ─── Tabs Switcher ───
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: context.theme.cardColor,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Obx(
                () => Row(
                  children: [
                    _buildTab(
                      context,
                      0,
                      'My Availabilities'.tr,
                      Icons.calendar_month,
                    ),
                    _buildTab(
                      context,
                      1,
                      'Free Slots'.tr,
                      Icons.check_circle_outline,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // ─── Content ───
          Expanded(
            child: Obx(() {
              if (controller.isFetching.value &&
                  controller.availabilitiesList.isEmpty) {
                return Center(
                  child: CircularProgressIndicator(
                    color: context.theme.primaryColor,
                  ),
                );
              }

              return RefreshIndicator(
                color: context.theme.primaryColor,
                onRefresh: controller.fetchAllData,
                child: controller.selectedTab.value == 0
                    ? _buildMyAvailabilitiesList(context)
                    : _buildFreePeriodsList(context),
              );
            }),
          ),
        ],
      ),
    );
  }

  // ─── Tab Widget ───
  Widget _buildTab(
    BuildContext context,
    int index,
    String label,
    IconData icon,
  ) {
    final isSelected = controller.selectedTab.value == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => controller.switchTab(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? context.theme.primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? Colors.white : context.theme.hintColor,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: isSelected
                      ? Colors.white
                      : context.textTheme.bodyMedium?.color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Tab 0: My Availabilities ───
  Widget _buildMyAvailabilitiesList(BuildContext context) {
    if (controller.availabilitiesList.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.3),
          Center(
            child: Text(
              'There are no available days'.tr,
              style: context.theme.textTheme.bodyLarge?.copyWith(
                color: context.theme.hintColor,
              ),
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(left: 20, right: 20, bottom: 100),
      itemCount: controller.availabilitiesList.length,
      itemBuilder: (context, index) {
        final item = controller.availabilitiesList[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: context.theme.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: context.theme.dividerColor.withOpacity(0.1),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            title: Text(
              item.dayOfWeek.tr,
              style: context.theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: context.theme.hintColor,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${item.startTime} - ${item.endTime}',
                    style: TextStyle(color: context.theme.hintColor),
                  ),
                ],
              ),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: () => _confirmDelete(context, item.id),
            ),
          ),
        );
      },
    );
  }

  // ─── Tab 1: Free Slots ───
  Widget _buildFreePeriodsList(BuildContext context) {
    if (controller.availablePeriodsList.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.3),
          Center(
            child: Text(
              'No free slots available'.tr,
              style: context.theme.textTheme.bodyLarge?.copyWith(
                color: context.theme.hintColor,
              ),
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(left: 20, right: 20, bottom: 100),
      itemCount: controller.availablePeriodsList.length,
      itemBuilder: (context, index) {
        final dayData = controller.availablePeriodsList[index];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(
                dayData.dayName.tr,
                style: context.theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (dayData.freePeriods.isEmpty)
              Text(
                'No times available for this date.'.tr,
                style: TextStyle(color: context.theme.hintColor, fontSize: 13),
              ),

            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: dayData.freePeriods
                  .map(
                    (period) =>
                        _buildFreeSlotChip(context, dayData.day, period),
                  )
                  .toList(),
            ),
            const SizedBox(height: 16),
            Divider(color: context.theme.dividerColor.withOpacity(0.5)),
          ],
        );
      },
    );
  }

  Widget _buildFreeSlotChip(
    BuildContext context,
    String day,
    FreePeriodModel period,
  ) {
    return GestureDetector(
      onTap: () {
        controller.preFillData(day, period.startTime, period.endTime);

        _showAddBottomSheet(context);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: context.theme.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: context.theme.primaryColor.withOpacity(0.5),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.add_circle_outline,
              size: 16,
              color: context.theme.primaryColor,
            ),
            const SizedBox(width: 6),
            Text(
              '${period.startTime} - ${period.endTime}',
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

  // ─── Helpers ───
  void _confirmDelete(BuildContext context, int id) {

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete'.tr,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text('Are you sure you want to delete this working day?'.tr),
        actionsPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'Cancel'.tr,
              style: TextStyle(
                color: context.theme.primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              elevation: 0,
            ),
            onPressed: () {
              Get.back();
              controller.deleteDay(id);
            },
            child: Text(
              'Delete'.tr,
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

  void _showAddBottomSheet(BuildContext context) {


    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: context.theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enter Working Day'.tr,
                style: context.theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Day'.tr,
                style: TextStyle(color: context.theme.hintColor, fontSize: 13),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: context.theme.cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: context.theme.dividerColor.withOpacity(0.1),
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: Obx(
                    () => DropdownButton<String>(
                      value: controller.selectedDay.value,
                      isExpanded: true,
                      items: controller.apiDays.map((String day) {
                        return DropdownMenuItem<String>(
                          value: day,
                          child: Text(day.tr),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        if (newValue != null) {
                          controller.selectedDay.value = newValue;
                        }
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _buildTimePickerField(
                      context,
                      'Start Time'.tr,
                      true,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTimePickerField(context, 'End Time'.tr, false),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Obx(
                () => SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.theme.primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: controller.isLoading
                        ? null
                        : () => controller.saveWorkingHours(),
                    child: controller.isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            'Save Working Hours'.tr,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  Widget _buildTimePickerField(
    BuildContext context,
    String label,
    bool isStartTime,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: context.theme.hintColor, fontSize: 13),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => controller.pickTime(context, isStartTime),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            decoration: BoxDecoration(
              color: context.theme.cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: context.theme.dividerColor.withOpacity(0.1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Obx(
                  () => Text(
                    isStartTime
                        ? controller.formattedStartTime
                        : controller.formattedEndTime,
                    style: context.theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Icon(
                  Icons.access_time,
                  color: context.theme.hintColor.withOpacity(0.6),
                  size: 18,
                ),
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
        title: Text('Settings'.tr),
        // 👈 كلمة إعدادات فقط
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
                _buildDivider(context),
                _buildSettingsTile(
                  context,
                  title: 'Cancel specific day appointments'.tr,
                  subtitle:
                      'Select a date from the calendar to cancel all its'.tr,
                  icon: Icons.event_busy,
                  iconColor: Colors.red,
                  onTap: () =>controller.pickDateToCancelAppointments(context),
                ),
              ],
            ),
          ),


          const SizedBox(height: 20),

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
                  onTap: () => controller
                      .showLanguageDialog(), // 👈 تم ربطها بالدالة الجديدة هنا
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
                color: (iconColor ?? context.theme.primaryColor).withOpacity(
                  0.08,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: iconColor ?? context.theme.primaryColor,
                size: 24,
              ),
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
      child: Divider(
        color: context.theme.dividerColor.withOpacity(0.4),
        height: 1,
      ),
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

### File: lib\widgets\examination\add_lab_request_dialog.dart
```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/examination/examination_controller.dart';

// اختيار النوع (تحليل/أشعة) ثم إدخال القيمة عبر نافذة حوارية
class AddLabRequestDialog extends StatefulWidget {
  final void Function(LabRequestType, String) onAdd;

  const AddLabRequestDialog({super.key, required this.onAdd});

  @override
  State<AddLabRequestDialog> createState() => _AddLabRequestDialogState();
}

class _AddLabRequestDialogState extends State<AddLabRequestDialog> {
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

### File: lib\widgets\examination\diagnosis_tab.dart
```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/examination/examination_controller.dart';
import 'examination_fields.dart';

// ─── تبويب التشخيص (التشخيص السريري / الملاحظات / بطاقة القياسات) ───
class DiagnosisTab extends GetView<ExaminationController> {
  const DiagnosisTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildTitledCard(
            context,
            icon: Icons.edit_note,
            title: 'Clinical Diagnosis'.tr,
            child: buildMultilineField(
              context,
              controller: controller.diagnosisController,
              hintText: 'Write the clinical diagnosis for the case'.tr,
              maxLines: 5,
              maxLength: 500,
              fillColor: context.theme.scaffoldBackgroundColor,
            ),
          ),
          const SizedBox(height: 16),
          buildTitledCard(
            context,
            icon: Icons.description_outlined,
            title: 'General Doctor Notes'.tr,
            child: buildMultilineField(
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
                      child: buildLabeledField(
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
                      child: buildLabeledField(
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
}

```

### File: lib\widgets\examination\examination_bottom_action.dart
```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/examination/examination_controller.dart';
import '../custom_button.dart';

// ─── شريط الإجراءات السفلي: زر الفاتورة بجانب زر الحفظ (يتغير حسب التبويب) ───
class ExaminationBottomAction extends GetView<ExaminationController> {
  const ExaminationBottomAction({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Obx(() {
        final isPrescription = controller.selectedTab.value == 1;
        return Row(
          children: [
            _buildInvoiceButton(context),
            const SizedBox(width: 12),
            Expanded(
              child: isPrescription
                  ? _buildFinishButton(context)
                  : CustomButton(
                      text: 'Save & Continue'.tr,
                      isLoading: controller.isLoading,
                      onPressed: () => controller.saveAndContinue(),
                    ),
            ),
          ],
        );
      }),
    );
  }

  // زر الفاتورة — متاح في التبويبين، ولا يعتمد على حفظ التشخيص
  Widget _buildInvoiceButton(BuildContext context) {
    return SizedBox(
      height: 52,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: context.theme.primaryColor,
          side: BorderSide(color: context.theme.primaryColor),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: controller.isLoading ? null : () => controller.openInvoice(),
        icon: const Icon(Icons.receipt_long_outlined, size: 20),
        label: Text(
          'Invoice'.tr,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  // زر أخضر مدمج (إنهاء المعاينة) — لتفادي تعديل الزر المشترك CustomButton
  Widget _buildFinishButton(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green.shade600,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        onPressed: controller.isLoading ? null : () => controller.saveAndFinish(),
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
                  Flexible(
                    child: Text(
                      'Save & Finish Examination'.tr,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

```

### File: lib\widgets\examination\examination_fields.dart
```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';

// ─── عناصر واجهة مشتركة داخل شاشة المعاينة (بطاقات وحقول) ───
// مُجمَّعة هنا لتفادي تكرارها عبر بطاقات المعاينة المستخرَجة.

// عنوان قسم صغير
Widget buildSectionTitle(BuildContext context, String title) {
  return Text(
    title,
    style: context.theme.textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.bold,
      fontSize: 15,
    ),
  );
}

// بطاقة بعنوان وأيقونة (مع إجراء اختياري بجانب العنوان) تحتوي على محتواها
Widget buildTitledCard(
  BuildContext context, {
  required IconData icon,
  required String title,
  Widget? trailing,
  required Widget child,
}) {
  return Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Theme.of(context).dividerColor),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: Theme.of(context).primaryColor),
            const SizedBox(width: 8),
            Expanded(child: buildSectionTitle(context, title)),
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
Widget buildAddLink(BuildContext context, String label, VoidCallback onTap) {
  return GestureDetector(
    onTap: onTap,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.add, size: 16, color: Theme.of(context).primaryColor),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: Theme.of(context).primaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ],
    ),
  );
}

// حقل بعنوان صغير فوقه — مصمم ليطابق CustomTextField دون تعديله (بلا أيقونة)
Widget buildLabeledField(
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
          fillColor: Theme.of(context).cardColor,
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
            borderSide: BorderSide(color: Theme.of(context).dividerColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Theme.of(context).primaryColor,
              width: 1.5,
            ),
          ),
        ),
      ),
    ],
  );
}

// حقل نصي متعدد الأسطر مع عدّاد — مصمم ليطابق CustomTextField دون تعديله
Widget buildMultilineField(
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
      hintStyle: TextStyle(
        color: context.theme.hintColor.withValues(alpha: 0.6),
      ),
      filled: true,
      fillColor: fillColor ?? Theme.of(context).cardColor,
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
        borderSide: BorderSide(color: Theme.of(context).dividerColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: Theme.of(context).primaryColor,
          width: 1.5,
        ),
      ),
    ),
  );
}

```

### File: lib\widgets\examination\examination_tabs.dart
```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/examination/examination_controller.dart';

// ─── شريط التبويبات (التشخيص / الوصفة) ───
class ExaminationTabs extends GetView<ExaminationController> {
  const ExaminationTabs({super.key});

  @override
  Widget build(BuildContext context) {
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
}

```

### File: lib\widgets\examination\lab_requests_card.dart
```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/examination/examination_controller.dart';
import 'add_lab_request_dialog.dart';
import 'examination_fields.dart';

// بطاقة طلب التحاليل وصور الأشعة — يضيف الطبيب طلبات عبر زر ثم تظهر كصفوف
class LabRequestsCard extends GetView<ExaminationController> {
  const LabRequestsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return buildTitledCard(
      context,
      icon: Icons.science_outlined,
      title: 'Lab & Imaging Requests'.tr,
      trailing: buildAddLink(
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

  void _showAddLabRequestSheet(BuildContext context) {
    Get.dialog(
      AddLabRequestDialog(
        onAdd: (type, value) => controller.addLabRequest(type, value),
      ),
    );
  }
}

```

### File: lib\widgets\examination\medications_card.dart
```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/examination/examination_controller.dart';
import 'examination_fields.dart';

// بطاقة وصفة الأدوية — العنوان مع رابط "إضافة دواء" وزر "إضافة دواء آخر" بالأسفل داخلها
class MedicationsCard extends GetView<ExaminationController> {
  const MedicationsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return buildTitledCard(
      context,
      icon: Icons.medication_outlined,
      title: 'Medications Prescription'.tr,
      trailing: buildAddLink(
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
        buildLabeledField(
          context,
          controller: med.nameController,
          label: 'Medicine Name'.tr,
        ),
        const SizedBox(height: 12),
        // الجرعة والتعليمات كلٌّ في حقل مستقل
        buildLabeledField(
          context,
          controller: med.dosageController,
          label: 'Dosage'.tr,
        ),
        const SizedBox(height: 12),
        buildLabeledField(
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
              child: buildLabeledField(
                context,
                controller: med.frequencyController,
                label: 'Quantity'.tr,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: buildLabeledField(
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
}

```

### File: lib\widgets\examination\patient_header.dart
```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/examination/examination_controller.dart';
import '../../core/constants.dart';

// ─── ترويسة المريض (الصورة / الاسم / العمر / المعرف) ───
class PatientHeader extends GetView<ExaminationController> {
  const PatientHeader({super.key});

  @override
  Widget build(BuildContext context) {
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
                        ? '${patient.age} ${patient.ageType.tr} • ${patient.gender.tr}'
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
          ],
        ),
      );
    });
  }
}

```

### File: lib\widgets\examination\prescription_tab.dart
```dart
import 'package:flutter/material.dart';
import 'lab_requests_card.dart';
import 'medications_card.dart';

// ─── تبويب الوصفة (بطاقة الأدوية + بطاقة التحاليل والأشعة) ───
class PrescriptionTab extends StatelessWidget {
  const PrescriptionTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MedicationsCard(),
          SizedBox(height: 16),
          LabRequestsCard(),
        ],
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
              GestureDetector(
                onTap: () => Get.toNamed('/doctor_profile'),
                child: CircleAvatar(
                  radius: 26,
                  backgroundColor: context.theme.primaryColor.withOpacity(0.1),
                  backgroundImage: doctor != null && doctor.image.isNotEmpty
                      ? NetworkImage(controller.resolveImageUrl(doctor.image))
                      : null,
                  child: doctor == null || doctor.image.isEmpty
                      ? Icon(
                          Icons.person,
                          color: context.theme.primaryColor,
                          size: 28,
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doctor != null ? 'Dr. ${doctor.name}' : 'Loading...',
                      style: context.theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      doctor?.specialization ?? '',
                      style: context.theme.textTheme.bodyMedium?.copyWith(
                        color: context.theme.hintColor,
                      ),
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
                      border: Border.all(
                        color: context.theme.dividerColor.withOpacity(0.1),
                      ),
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.notifications_none_rounded,
                        color: context.theme.textTheme.bodyLarge?.color,
                        size: 26,
                      ),
                      onPressed: () {
                        //  إخفاء النقطة عند فتح الإشعارات
                        controller.hasUnreadNotifications.value = false;
                        Get.toNamed('/doctor_notifications');
                      },
                    ),
                  ),
                  //  النقطة التفاعلية
                  Obx(
                        () => controller.hasUnreadNotifications.value
                        ? Positioned(
                      right: 12,
                      top: 12,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: context.theme.scaffoldBackgroundColor,
                            width: 2,
                          ),
                        ),
                      ),
                    )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
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
                      Text('${patient.age} ${patient.ageType.tr}• ${patient.gender.tr}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
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
                // ─── الإصلاح هنا: توجيه الطبيب لشاشة المعاينة بدلاً من إنهاء الموعد ───
                onPressed: () => Get.toNamed('/examination', arguments: patient),
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
                      Text('${patient.age} ${patient.ageType.tr}• ${patient.gender.tr}', style: context.theme.textTheme.bodyMedium?.copyWith(color: context.theme.hintColor, fontSize: 12)),
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

### File: lib\widgets\invoice\consultation_fee_card.dart
```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/invoice/invoice_controller.dart';

// ─── بطاقة أجرة الكشف — قيمة ثابتة تُضبط عند الحجز ولا يعدّلها الطبيب ───
class ConsultationFeeCard extends GetView<InvoiceController> {
  const ConsultationFeeCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.theme.dividerColor),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: context.theme.primaryColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.medical_services_outlined,
              color: context.theme.primaryColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Consultation Fee'.tr,
                  style: context.theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'General Consultation'.tr,
                  style: context.theme.textTheme.bodySmall?.copyWith(
                    color: context.theme.hintColor,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Obx(
            () => Text(
              controller.formatMoney(controller.consultationFee),
              style: context.theme.textTheme.titleMedium?.copyWith(
                color: context.theme.primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

```

### File: lib\widgets\invoice\extra_services_card.dart
```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../controllers/invoice/invoice_controller.dart';
import '../../models/invoice/invoice_model.dart';

// ─── بطاقة الخدمات الإضافية — حقلا الاسم والتكلفة ثم قائمة الخدمات المضافة ───
// كل خدمة تُحفظ في الخادم لحظة إضافتها، والقائمة تُرسم من رد الخادم مباشرة.
class ExtraServicesCard extends GetView<InvoiceController> {
  const ExtraServicesCard({super.key});

  @override
  Widget build(BuildContext context) {
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
          _buildFieldLabel(context, 'Service Name'.tr),
          const SizedBox(height: 6),
          _buildServiceNameField(context),
          const SizedBox(height: 14),
          Obx(
            () => _buildFieldLabel(
              context,
              '${'Cost'.tr} (${controller.currencySymbol})',
            ),
          ),
          const SizedBox(height: 6),
          _buildCostField(context),
          Obx(() {
            final items = controller.additions;
            if (items.isEmpty) {
              return Padding(
                padding: const EdgeInsets.only(top: 14),
                child: Text(
                  'No extra services added'.tr,
                  style: context.theme.textTheme.bodySmall?.copyWith(
                    color: context.theme.hintColor,
                  ),
                ),
              );
            }
            return Column(
              children: [
                const SizedBox(height: 6),
                for (final item in items) _buildServiceRow(context, item),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildFieldLabel(BuildContext context, String label) {
    return Text(
      label,
      style: context.theme.textTheme.bodySmall?.copyWith(
        color: context.theme.hintColor,
        fontSize: 12,
      ),
    );
  }

  // حقل الاسم — أيقونة داخل الحافة اليمنى/اليسرى وزر مسح سريع
  Widget _buildServiceNameField(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.theme.dividerColor),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: context.theme.primaryColor.withValues(alpha: 0.10),
              // اتجاهية حتى تلتصق الأيقونة بحافة الحقل في العربية والإنجليزية
              borderRadius: const BorderRadiusDirectional.horizontal(
                start: Radius.circular(11),
              ),
            ),
            child: Icon(
              Icons.vaccines_outlined,
              size: 20,
              color: context.theme.primaryColor,
            ),
          ),
          Expanded(
            child: TextField(
              controller: controller.serviceNameController,
              textInputAction: TextInputAction.next,
              maxLength: 100,
              style: TextStyle(
                color: context.theme.textTheme.bodyLarge?.color,
              ),
              decoration: InputDecoration(
                counterText: '',
                isDense: true,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                hintText: 'e.g. Nebulizer session'.tr,
                hintStyle: TextStyle(
                  color: context.theme.hintColor.withValues(alpha: 0.6),
                  fontSize: 14,
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: controller.clearServiceName,
            icon: Icon(Icons.close, size: 18, color: context.theme.hintColor),
            tooltip: 'Clear'.tr,
          ),
        ],
      ),
    );
  }

  Widget _buildCostField(BuildContext context) {
    return TextField(
      controller: controller.costController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      // منع الإشارات والحروف — الخادم يتوقع رقماً موجباً
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
      ],
      style: TextStyle(color: context.theme.textTheme.bodyLarge?.color),
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        fillColor: context.theme.scaffoldBackgroundColor,
        hintText: '0.00',
        hintStyle: TextStyle(
          color: context.theme.hintColor.withValues(alpha: 0.6),
        ),
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
    );
  }

  // صف خدمة محفوظة — الحذف ينادي الخادم ويعيد رسم الفاتورة من الرد
  Widget _buildServiceRow(BuildContext context, AdditionModel item) {
    final isDeleting = controller.deletingAdditionId.value == item.id;
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        children: [
          Icon(Icons.circle, size: 7, color: context.theme.primaryColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              item.itemName,
              style: context.theme.textTheme.bodyMedium?.copyWith(
                color: context.theme.textTheme.bodyLarge?.color,
                fontSize: 13,
              ),
            ),
          ),
          Text(
            controller.formatMoney(item.price),
            style: context.theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 36,
            height: 36,
            child: isDeleting
                ? const Padding(
                    padding: EdgeInsets.all(9),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Material(
                    color: Colors.red.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => controller.deleteItem(item),
                      child: const Icon(
                        Icons.delete_outline,
                        size: 18,
                        color: Colors.red,
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

### File: lib\widgets\invoice\invoice_patient_card.dart
```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/invoice/invoice_controller.dart';
import '../../core/constants.dart';

// ─── بطاقة المريض أعلى الفاتورة (الصورة / الاسم / المعرف / تاريخ ووقت الموعد) ───
class InvoicePatientCard extends GetView<InvoiceController> {
  const InvoicePatientCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final image = controller.patientImage;
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.theme.dividerColor),
        ),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: context.theme.primaryColor.withValues(
                    alpha: 0.12,
                  ),
                  // الباك إند قد يرجع رابطاً كاملاً أو مساراً نسبياً
                  backgroundImage: image.isNotEmpty
                      ? NetworkImage(
                          image.startsWith('http') ? image : '$baseUrl/$image',
                        )
                      : null,
                  child: image.isEmpty
                      ? Icon(
                          Icons.person,
                          color: context.theme.primaryColor,
                          size: 32,
                        )
                      : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        controller.patientName.isEmpty
                            ? 'Loading...'.tr
                            : controller.patientName,
                        style: context.theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            '${'Patient ID'.tr}: ',
                            style: context.theme.textTheme.bodySmall?.copyWith(
                              color: context.theme.hintColor,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            controller.formattedPatientId,
                            style: context.theme.textTheme.bodySmall?.copyWith(
                              color: context.theme.primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Divider(color: context.theme.dividerColor, height: 28),
            Row(
              children: [
                _buildMeta(
                  context,
                  Icons.calendar_today_outlined,
                  controller.formattedDate,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Icon(
                    Icons.circle,
                    size: 4,
                    color: context.theme.hintColor,
                  ),
                ),
                _buildMeta(
                  context,
                  Icons.access_time,
                  controller.formattedTime,
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  Widget _buildMeta(BuildContext context, IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: context.theme.primaryColor),
        const SizedBox(width: 6),
        Text(
          label,
          style: context.theme.textTheme.bodySmall?.copyWith(
            color: context.theme.hintColor,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

```

### File: lib\widgets\invoice\invoice_summary_card.dart
```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/invoice/invoice_controller.dart';

// ─── بطاقة الإجمالي — الأجرة + مجموع الخدمات الإضافية ───
class InvoiceSummaryCard extends GetView<InvoiceController> {
  const InvoiceSummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.theme.dividerColor),
      ),
      child: Obx(
        () => Column(
          children: [
            _buildRow(
              context,
              'Consultation Fee'.tr,
              controller.formatMoney(controller.consultationFee),
            ),
            const SizedBox(height: 10),
            _buildRow(
              context,
              '${'Extra Services'.tr} (${controller.additions.length})',
              controller.formatMoney(controller.extrasTotal),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: _DashedDivider(),
            ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Total Amount'.tr,
                    style: context.theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                Text(
                  controller.formatMoney(controller.totalAmount),
                  style: context.theme.textTheme.titleLarge?.copyWith(
                    color: context.theme.primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(BuildContext context, String label, String value) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: context.theme.textTheme.bodyMedium?.copyWith(
              color: context.theme.hintColor,
              fontSize: 13,
            ),
          ),
        ),
        Text(
          value,
          style: context.theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

// فاصل متقطع يفصل بنود الفاتورة عن الإجمالي
class _DashedDivider extends StatelessWidget {
  const _DashedDivider();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const dashWidth = 5.0;
        const dashSpace = 4.0;
        final count = (constraints.maxWidth / (dashWidth + dashSpace)).floor();
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(
            count,
            (_) => SizedBox(
              width: dashWidth,
              height: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(color: context.theme.dividerColor),
              ),
            ),
          ),
        );
      },
    );
  }
}

```

