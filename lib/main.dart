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
          name: '/doctor_home',
          page: () => const HomeView(),
          binding: BindingsBuilder(() {
            Get.lazyPut<HomeApi>(() => HomeApi());
            Get.lazyPut<HomeRepo>(() => HomeRepo(api: Get.find()));
            Get.lazyPut<HomeController>(() => HomeController(repo: Get.find()));
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
