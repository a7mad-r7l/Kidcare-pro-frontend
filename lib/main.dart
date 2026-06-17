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