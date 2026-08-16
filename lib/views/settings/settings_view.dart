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
