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

### File: lib\controllers\home\home_controller.dart
```dart
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

### File: lib\core\apis\home\home_api.dart
```dart
import 'package:http/http.dart' as http;
import 'dart:convert';
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

  // 1. بيانات الطبيب العامة
  Future<String> getDoctorHome() async {
    return (await http.get(Uri.parse('$baseUrl/api/doctor/home'), headers: await _getHeaders())).body;
  }

  // 2. عدد مواعيد اليوم الكلي
  Future<String> getTodayAppointmentsCount() async {
    return (await http.get(Uri.parse('$baseUrl/api/doctor/today-appointments-count'), headers: await _getHeaders())).body;
  }

  // 3. المريض القادم (Next Patient)
  Future<String> getNextPatient() async {
    return (await http.get(Uri.parse('$baseUrl/api/doctor/next-patient'), headers: await _getHeaders())).body;
  }

  // 4. المرضى المتبقين (Remaining Patients)
  Future<String> getRemainingPatients() async {
    return (await http.get(Uri.parse('$baseUrl/api/doctor/remaining-patients'), headers: await _getHeaders())).body;
  }

  // 5. عدد المواعيد المكتملة اليوم
  Future<String> getCompletedAppointmentsToday() async {
    return (await http.get(Uri.parse('$baseUrl/api/doctor/completed-appointments-today'), headers: await _getHeaders())).body;
  }

  // 6. الأرباح الشهرية للطبيب
  Future<String> getMonthlyRevenue() async {
    return (await http.get(Uri.parse('$baseUrl/api/doctor/monthlyRevenue'), headers: await _getHeaders())).body;
  }

  // دالة إتمام الموعد
  Future<String> completeAppointment(int appointmentId) async {
    return (await http.get(Uri.parse('$baseUrl/api/doctors/$appointmentId/completeAppointment'), headers: await _getHeaders())).body;
  }
}
```

### File: lib\core\constants.dart
```dart
const String baseUrl = 'http://192.168.1.6:8000';

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
    //القاموس الإنجليزي
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

      // --- Home View ---
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

      // --- Home View ---
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

### File: lib\core\repos\home\home_repo.dart
```dart
import 'dart:convert';
import '../../../models/home/doctor_dashboard_model.dart';
import '../../apis/home/home_api.dart';

class HomeRepo {
  final HomeApi api;
  HomeRepo({required this.api});

  String _cleanJson(String response) {
    if (response.contains('{')) return response.substring(response.indexOf('{'));
    if (response.contains('[')) return response.substring(response.indexOf('['));
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

import 'core/helper/secure_storage_service.dart';
import 'core/localization/app_translations.dart';

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

void main() async {
  // لتهيئة فلاتر قبل تشغيل أي ميزة Native
  WidgetsFlutterBinding.ensureInitialized();
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

  const MyApp({super.key, required this.initialLocale, required this.initialRoute});

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
          name: '/doctor_home',
          page: () => const HomeView(),
          binding: BindingsBuilder(() {
            Get.lazyPut<HomeApi>(() => HomeApi());
            Get.lazyPut<HomeRepo>(() => HomeRepo(api: Get.find()));
            Get.lazyPut<HomeController>(() => HomeController(repo: Get.find()));
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
  final String name;
  final int age;
  final String gender;
  final String image;
  final String appointmentTime;

  PatientModel({
    required this.id,
    required this.name,
    required this.age,
    required this.gender,
    required this.image,
    required this.appointmentTime,
  });

  factory PatientModel.fromJson(Map<String, dynamic> json) {
    return PatientModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? '',
      age: json['age'] is int ? json['age'] : int.tryParse(json['age']?.toString() ?? '0') ?? 0,
      gender: json['gender']?.toString() ?? 'male',
      image: json['image']?.toString() ?? '',
      appointmentTime: json['appointment_time']?.toString() ?? '',
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

### File: lib\views\home\home_view.dart
```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/home/home_controller.dart';
import '../../core/constants.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      // ─── تمديد جسم الشاشة خلف شريط التنقل لمنع الفراغات البيضاء ───
      extendBody: true,

      // ─── استدعاء الـ Custom Floating Bottom Navigation Bar ───
      bottomNavigationBar: _buildFloatingBottomBar(context),

      body: Obx(() {
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
                // الـ Curved Header الاحترافي الباقي كما هو وثابت
                _buildCurvedHeader(context),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),

                      // ─── 1. الـ Next Patient أصبح في الأعلى أولاً ───
                      Text(
                        'Next Patient'.tr,
                        style: context.theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _buildNextPatientCard(context),

                      const SizedBox(height: 24),

                      // ─── 2. الإحصائيات أصبحت أسفل الـ Next Patient وبعناوين واضحة ───
                      _buildStatsGrid(context),

                      const SizedBox(height: 24),

                      // ─── 3. شريط اختيار التاريخ فوق قائمة المرضى المتبقين ───
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Remaining Patients'.tr,
                            style: context.theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          // زر محدد التاريخ الديناميكي المظهر للتاريخ الحالي
                          InkWell(
                            onTap: () => controller.selectCustomDate(context),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 6,
                                horizontal: 10,
                              ),
                              decoration: BoxDecoration(
                                color: context.theme.primaryColor.withOpacity(
                                  0.08,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.calendar_month,
                                    size: 16,
                                    color: context.theme.primaryColor,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    controller.formattedSelectedDate,
                                    style: TextStyle(
                                      color: context.theme.primaryColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // قائمة المرضى المتبقين النظيفة والمحدثة
                      _buildRemainingPatientsList(context),

                      // ─── مسافة عازلة إضافية لمنع البار العائم من تغطية آخر مريض ───
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  // ─── دالة بناء شريط التنقل السفلي العائم (Floating Bottom Bar) ───
  Widget _buildFloatingBottomBar(BuildContext context) {
    return Obx(() {
      return SafeArea(
        child: Container(
          height: 68,
          margin: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: context.theme.cardColor, // يتكيف تلقائياً مع الـ Dark/Light Mode
            borderRadius: BorderRadius.circular(24), // حواف دائرية انسيابية وفخمة
            boxShadow: [
              BoxShadow(
                color: context.theme.primaryColor.withOpacity(0.12), // ظلال بلون هوية التطبيق تعطي عمقاً جذاباً
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
            border: Border.all(
              color: context.theme.dividerColor.withOpacity(0.05), // حد خفيف للبروز المعماري
              width: 1,
            ),
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

  // ─── دالة بناء العنصر الفردي داخل الشريط مع اللمسة الحركية المخصصة ───
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
          // ظهور خلفية دائرية خفيفة جداً بلون الهوية عند اختيار العنصر
          color: isSelected ? activeColor.withOpacity(0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // تأثير حركي لتكبير الأيقونة المحددة بسلاسة (Scale Animation)
            AnimatedScale(
              scale: isSelected ? 1.15 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: Icon(
                icon,
                color: isSelected ? activeColor : inactiveColor,
                size: isSelected ? 24 : 22,
              ),
            ),
            const SizedBox(height: 3),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? activeColor : inactiveColor,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurvedHeader(BuildContext context) {
    final doctor = controller.doctorData.value;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 60, left: 24, right: 24, bottom: 35),
      decoration: BoxDecoration(
        color: context.theme.primaryColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white24,
            backgroundImage: doctor != null && doctor.image.isNotEmpty
                ? NetworkImage('$baseUrl/${doctor.image}')
                : null,
            child: doctor == null || doctor.image.isEmpty
                ? const Icon(Icons.person, color: Colors.white, size: 30)
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  doctor != null ? 'Dr. ${doctor.name}' : 'Loading...',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  doctor?.specialization ?? '',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.notifications_outlined,
              color: Colors.white,
              size: 26,
            ),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.15,
      children: [
        _buildStatItem(
          context,
          "Today's Total".tr,
          controller.totalAppointments.value.toString(),
          Icons.calendar_today,
          Colors.blue,
        ),
        _buildStatItem(
          context,
          'Completed'.tr,
          controller.completedAppointments.value.toString(),
          Icons.check_circle_outline,
          Colors.green,
        ),
        _buildStatItem(
          context,
          'Monthly Rev'.tr,
          '\$${controller.monthlyRevenue.value.toStringAsFixed(0)}',
          Icons.monetization_on_outlined,
          Colors.orange,
        ),
      ],
    );
  }

  Widget _buildStatItem(
      BuildContext context,
      String label,
      String value,
      IconData icon,
      Color color,
      ) {
    return Container(
      decoration: BoxDecoration(
        color: context.theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.theme.dividerColor.withOpacity(0.04)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(
            value,
            style: context.theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: context.theme.textTheme.bodySmall?.copyWith(
              color: context.theme.hintColor,
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNextPatientCard(BuildContext context) {
    final patient = controller.nextPatient.value;
    if (patient == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: context.theme.cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(child: Text('No upcoming patients'.tr)),
      );
    }
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            context.theme.primaryColor.withOpacity(0.85),
            context.theme.primaryColor,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundImage: patient.image.isNotEmpty
                ? NetworkImage('$baseUrl/${patient.image}')
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  patient.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${patient.age} Yrs • ${patient.gender.tr} • ${patient.appointmentTime}',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: context.theme.primaryColor,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            ),
            onPressed: () => controller.completePatientAppointment(patient.id),
            child: Text(
              'Done'.tr,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRemainingPatientsList(BuildContext context) {
    if (controller.remainingPatients.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 30),
        child: Center(child: Text('No remaining patients for this date'.tr)),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: controller.remainingPatients.length,
      itemBuilder: (context, index) {
        final patient = controller.remainingPatients[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: context.theme.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: context.theme.dividerColor.withOpacity(0.04),
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundImage: patient.image.isNotEmpty
                    ? NetworkImage('$baseUrl/${patient.image}')
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      patient.name,
                      style: context.theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${patient.age} Yrs • ${patient.gender.tr} • ${patient.appointmentTime}',
                      style: context.theme.textTheme.bodyMedium?.copyWith(
                        color: context.theme.hintColor,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 26,
                ),
                onPressed: () =>
                    controller.completePatientAppointment(patient.id),
              ),
            ],
          ),
        );
      },
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

### File: lib\widgets\patient_appointment_card.dart
```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../models/home/patient_appointment_model.dart';
import '../core/constants.dart';


class PatientAppointmentCard extends StatelessWidget {
  final PatientAppointmentModel patient;
  final VoidCallback onDone;
  final VoidCallback onCancel;

  const PatientAppointmentCard({
    super.key,
    required this.patient,
    required this.onDone,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: context.theme.shadowColor.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundImage: patient.image.isNotEmpty
                    ? NetworkImage('$baseUrl/${patient.image}')
                    : null,
                child: patient.image.isEmpty
                    ? const Icon(Icons.person, size: 30)
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      patient.name,
                      style: context.theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${patient.age} • ${patient.gender.tr} • ${patient.appointmentTime}',
                      style: context.theme.textTheme.bodyMedium?.copyWith(color: context.theme.hintColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onCancel,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text('Cancel'.tr),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: onDone,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.theme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text('Done'.tr),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
```

### File: lib\widgets\schedule_summary_card.dart
```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ScheduleSummaryCard extends StatelessWidget {
  final int count;
  const ScheduleSummaryCard({super.key, required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.theme.primaryColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Today'.tr,
                style: const TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                '$count ${'Appointments'.tr}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.calendar_today, color: Colors.white, size: 28),
          ),
        ],
      ),
    );
  }
}
```

