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