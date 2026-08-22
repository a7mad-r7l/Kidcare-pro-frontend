import 'dart:convert';

import 'package:get/get.dart';
import 'package:flutter/material.dart';

import '../core/helper/secure_storage_service.dart';

class BaseController extends GetxController {
  final _isLoading = false.obs;

  bool get isLoading => _isLoading.value;

  void showLoading() => _isLoading.value = true;

  void hideLoading() => _isLoading.value = false;

  void handleError(dynamic e) {
    hideLoading();

    final errorString = e.toString();
    String message = "Something went wrong. Please try again.".tr;

    try {
      if (errorString.toLowerCase().contains("unauthenticated") ||
          errorString.contains("401")) {
        SecureStorage.removeAll();

        if (Get.currentRoute != '/login') {
          Get.offAllNamed('/login');

          Get.snackbar(
            "Session Expired".tr,
            "Please login again to continue.".tr,
            backgroundColor: Colors.orange.shade700,
            colorText: Colors.white,
            snackPosition: SnackPosition.BOTTOM,
            margin: const EdgeInsets.all(15),
            icon: const Icon(Icons.lock_clock, color: Colors.white),
            duration: const Duration(seconds: 4),
          );
        }
        return;
      } else if (errorString.contains('{') && errorString.contains('}')) {
        final startIndex = errorString.indexOf('{');
        final endIndex = errorString.lastIndexOf('}') + 1;
        final jsonPart = errorString.substring(startIndex, endIndex);
        final decoded = jsonDecode(jsonPart);
        if (decoded['message'] != null) {
          message = decoded['message'];
        }
      } else if (errorString.contains("Exception:")) {
        message = errorString.split("Exception:").last.trim();
      } else if (errorString.contains("SocketException")) {
        message = "No Internet connection. Please check your network.".tr;
      } else if (errorString.contains("TimeoutException")) {
        message = "Request timed out. Please try again.".tr;
      }
    } catch (_) {}

    Get.snackbar(
      "Error".tr,
      message,
      backgroundColor: Colors.red.shade800,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(15),
      icon: const Icon(Icons.error_outline, color: Colors.white),
      duration: const Duration(seconds: 4),
    );
  }

  void showSuccess(String message) {
    Get.snackbar(
      "Success".tr,
      message,
      backgroundColor: Colors.green.shade700,
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
      margin: const EdgeInsets.all(15),
      icon: const Icon(Icons.check_circle_outline, color: Colors.white),
      duration: const Duration(seconds: 3),
    );
  }

  void showInfo(String message) {
    Get.snackbar(
      "Info".tr,
      message,
      backgroundColor: Colors.grey.shade700,
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
      margin: const EdgeInsets.all(15),
      duration: const Duration(seconds: 3),
    );
  }
}
