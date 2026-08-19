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

  Future<void> changeTheme() async {
    if (Get.isDarkMode) {
      Get.changeThemeMode(ThemeMode.light);
      await SecureStorage.storeThemeMode('light');
    } else {
      Get.changeThemeMode(ThemeMode.dark);
      await SecureStorage.storeThemeMode('dark');
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
