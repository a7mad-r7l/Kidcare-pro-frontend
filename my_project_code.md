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

      // التحقق الصارم من وجود التوكن المرتجع بنجاح
      if (result.token.isNotEmpty) {
        await SecureStorage.storeToken(result.token);

        hideLoading();

        Get.snackbar(
            'Success'.tr,
            result.message.isNotEmpty ? result.message : 'Logged in successfully',
            snackPosition: SnackPosition.BOTTOM
        );

        // الانتقال لصفحة الطبيب الرئيسية
        Get.offAllNamed('/doctor_home');
      } else {
        hideLoading();
        Get.snackbar(
            'Error'.tr,
            result.message.isNotEmpty ? result.message : 'Login Failed',
            snackPosition: SnackPosition.BOTTOM
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
        'phone': phone,
        'password': password,
      }),
    ).timeout(const Duration(seconds: 15));

    return response.body;
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

void main() async {
  // لتهيئة فلاتر قبل تشغيل أي ميزة Native
  WidgetsFlutterBinding.ensureInitialized();

  String? savedLang = await SecureStorage.getLanguage();
  Locale initialLocale;

  if (savedLang == null || savedLang == 'system') {
    Locale? deviceLocale = WidgetsBinding.instance.platformDispatcher.locales.isNotEmpty
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

  runApp(MyApp(initialLocale: initialLocale));
}

class MyApp extends StatelessWidget {
  final Locale initialLocale;

  const MyApp({super.key, required this.initialLocale});

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


      initialRoute: '/login',


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
      token: json['token']?.toString() ?? '',
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

