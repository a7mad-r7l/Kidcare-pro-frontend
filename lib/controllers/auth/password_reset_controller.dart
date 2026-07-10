import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/repos/auth/password_reset_repo.dart';
import '../base_controller.dart';

class PasswordResetController extends BaseController {
  final PasswordResetRepo repo;
  PasswordResetController({required this.repo});

  // إدارة شاشات الـ PageView (الآن شاشتان فقط: 0 و 1)
  final pageController = PageController();
  final currentPage = 0.obs;

  // Controllers للحقول
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  final isPasswordHidden = true.obs;
  final isConfirmHidden = true.obs;

  // ─── 1. فحص رقم الهاتف والانتقال الفوري ───
  void validatePhoneAndContinue() {
    final phone = phoneController.text.trim();

    // القيد البرمجي (Client-Side Validation) لرقم الهاتف
    if (phone.length != 12 || !phone.startsWith('963')) {
      handleError('Phone number must be exactly 12 digits and start with 963'.tr);
      return;
    }

    // رقم الهاتف سليم؟ انقله فوراً لواجهة كلمة المرور الجديدة دون OTP
    _nextPage();
  }

  // ─── 2. تعيين كلمة المرور الجديدة وإرسالها للسيرفر ───
  Future<void> setPassword() async {
    final pass = passwordController.text;
    final confirm = confirmPasswordController.text;
    final phone = phoneController.text.trim();

    // القيود البرمجية لكلمة المرور
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
      // 💡 بما أننا ألغينا واجهة الـ OTP، نرسل كلمة المرور مباشرة.
      // ملحوظة هندسية: نمرر قيمة وهمية أو فارغة للـ OTP إذا كان الباك إند يتوقعه في السيرفر،
      // ولكن هنا نمرر الـ phone والـ password بناءً على بنية الـ SetPasswordDoctor.
      final msg = await repo.setPassword(phone, pass, confirm);
      showSuccess(msg);

      // طرد المستخدم لواجهة تسجيل الدخول بعد ثانية من النجاح
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
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }
}