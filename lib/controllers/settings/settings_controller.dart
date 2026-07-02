import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/helper/secure_storage_service.dart';
import '../base_controller.dart';

class SettingsController extends BaseController {
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

  void deleteAccount() {}
}
