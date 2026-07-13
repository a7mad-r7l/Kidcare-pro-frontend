import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/examination/examination_controller.dart';
import '../custom_button.dart';

// ─── زر الإجراء السفلي يتغير حسب التبويب الحالي ───
class ExaminationBottomAction extends GetView<ExaminationController> {
  const ExaminationBottomAction({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Obx(() {
        final isPrescription = controller.selectedTab.value == 1;
        if (isPrescription) {
          // زر أخضر مدمج (إنهاء المعاينة) — لتفادي تعديل الزر المشترك CustomButton
          return SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              onPressed: controller.isLoading
                  ? null
                  : () => controller.saveAndFinish(),
              child: controller.isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Save & Finish Examination'.tr,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
            ),
          );
        }
        return CustomButton(
          text: 'Save & Continue'.tr,
          isLoading: controller.isLoading,
          onPressed: () => controller.saveAndContinue(),
        );
      }),
    );
  }
}
