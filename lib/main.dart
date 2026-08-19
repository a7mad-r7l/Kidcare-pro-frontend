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
  String? savedTheme = await SecureStorage.getThemeMode();
  ThemeMode initialThemeMode = ThemeMode.system;
  if (savedTheme == 'dark') {
    initialThemeMode = ThemeMode.dark;
  } else if (savedTheme == 'light') {
    initialThemeMode = ThemeMode.light;
  }

  runApp(
    MyApp(
      initialLocale: initialLocale,
      initialRoute: initialRoute,
      initialThemeMode: initialThemeMode,
    ),
  );
}

class MyApp extends StatelessWidget {
  final Locale initialLocale;
  final String initialRoute;
  final ThemeMode initialThemeMode;

  const MyApp({
    super.key,
    required this.initialLocale,
    required this.initialRoute,
    required this.initialThemeMode,
  });

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      theme: AppThemes.lightTheme,
      darkTheme: AppThemes.darkTheme,
      themeMode: initialThemeMode,
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
