import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/repos/auth/password_reset_repo.dart';
import '../base_controller.dart';

class PasswordResetController extends BaseController {
  final PasswordResetRepo repo;
  PasswordResetController({required this.repo});

  // إدارة شاشات الـ PageView
  final pageController = PageController();
  final currentPage = 0.obs;

  // Controllers للحقول
  final phoneController = TextEditingController();
  final otpController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  final isPasswordHidden = true.obs;
  final isConfirmHidden = true.obs;

  // ─── 1. إرسال الـ OTP ───
  Future<void> sendOtp() async {
    final phone = phoneController.text.trim();

    // Client-Side Validation لرقم الهاتف
    if (phone.length != 12 || !phone.startsWith('963')) {
      handleError('Phone number must be exactly 12 digits and start with 963'.tr);
      return;
    }

    showLoading();
    try {
      final msg = await repo.sendOtp(phone);
      showSuccess(msg);
      _nextPage();
    } catch (e) {
      handleError(e);
    } finally {
      hideLoading();
    }
  }

  // ─── 2. التحقق من الـ OTP ───
  Future<void> verifyOtp() async {
    final otp = otpController.text.trim();

    if (otp.length < 4) {
      handleError('Please enter a valid 4-digit OTP'.tr);
      return;
    }

    showLoading();
    try {
      final msg = await repo.verifyOtp(phoneController.text.trim(), otp);
      showSuccess(msg);
      _nextPage();
    } catch (e) {
      handleError(e);
    } finally {
      hideLoading();
    }
  }

  // ─── 3. تعيين كلمة المرور الجديدة ───
  Future<void> setPassword() async {
    final pass = passwordController.text;
    final confirm = confirmPasswordController.text;

    // Client-Side Validation لكلمة المرور
    if (pass.length < 6) {
      handleError('Password must be at least 6 characters long'.tr);
      return;
    }
    if (pass != confirm) {
      handleError('Passwords do not match'.tr);
      return;
    }

    showLoading();
    try {
      final msg = await repo.setPassword(phoneController.text.trim(), pass, confirm);
      showSuccess(msg);

      // طرد المستخدم للوجن بعد ثانية للنجاح
      Future.delayed(const Duration(seconds: 1), () {
        Get.offAllNamed('/login');
      });
    } catch (e) {
      handleError(e);
    } finally {
      hideLoading();
    }
  }

  void _nextPage() {
    currentPage.value++;
    pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
  }

  void previousPage() {
    if (currentPage.value > 0) {
      currentPage.value--;
      pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } else {
      Get.back();
    }
  }

  @override
  void onClose() {
    pageController.dispose();
    phoneController.dispose();
    otpController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }
}