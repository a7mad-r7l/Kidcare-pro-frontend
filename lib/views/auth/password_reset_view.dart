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
          physics: const NeverScrollableScrollPhysics(), // منع السحب اليدوي
          children: [
            _buildPhoneStep(context),
            _buildOtpStep(context),
            _buildNewPasswordStep(context),
          ],
        ),
      ),
    );
  }

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
            text: 'Send OTP'.tr,
            isLoading: controller.isLoading,
            onPressed: () => controller.sendOtp(),
          )),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildOtpStep(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Verify OTP'.tr, style: context.theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: context.theme.primaryColor)),
          const SizedBox(height: 12),
          Text('A 4-digit code has been sent to your registered number.'.tr, style: context.theme.textTheme.bodyMedium?.copyWith(color: context.theme.hintColor, height: 1.5)),
          const SizedBox(height: 40),
          // تصميم OTP بسيط وآمن بدون مكاتب خارجية
          Center(
            child: SizedBox(
              width: 200,
              child: TextFormField(
                controller: controller.otpController,
                keyboardType: TextInputType.number,
                maxLength: 4,
                textAlign: TextAlign.center,
                style: context.theme.textTheme.headlineMedium?.copyWith(letterSpacing: 20, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  counterText: '',
                  filled: true,
                  fillColor: context.theme.cardColor,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: context.theme.primaryColor, width: 2)),
                ),
              ),
            ),
          ),
          const Spacer(),
          Obx(() => CustomButton(
            text: 'Verify'.tr,
            isLoading: controller.isLoading,
            onPressed: () => controller.verifyOtp(),
          )),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

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