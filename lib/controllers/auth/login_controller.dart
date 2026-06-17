import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/helper/secure_storage_service.dart';
import '../../core/repos/auth/login_repo.dart';
import '../base_controller.dart';

class LoginController extends BaseController {
  final LoginRepo repo;

  LoginController({required this.repo});

  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  final loginFormKey = GlobalKey<FormState>();

  final isPasswordHidden = true.obs;

  Future<void> loginProcess() async {
    if (!loginFormKey.currentState!.validate()) return;

    showLoading();
    try {
      final result = await repo.login(
        phone: phoneController.text.trim(),
        password: passwordController.text,
      );

      if (result.token.isNotEmpty) {
        await SecureStorage.storeToken(result.token);

        hideLoading();

        showSuccess(
          result.message.isNotEmpty ? result.message : 'Logged in successfully',
        );

        // الانتقال لصفحة الطبيب الرئيسية
        Get.offAllNamed('/doctor_home');
      } else {
        hideLoading();
        Get.snackbar(
          'Error'.tr,
          result.message.isNotEmpty ? result.message : 'Login Failed',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      hideLoading();
      handleError(e);
    }
  }

  @override
  void onClose() {
    phoneController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}
