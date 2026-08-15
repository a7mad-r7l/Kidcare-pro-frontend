import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/examination/examination_controller.dart';
import '../custom_button.dart';

// ─── شريط الإجراءات السفلي: زر الفاتورة بجانب زر الحفظ (يتغير حسب التبويب) ───
class ExaminationBottomAction extends GetView<ExaminationController> {
  const ExaminationBottomAction({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Obx(() {
        final isPrescription = controller.selectedTab.value == 1;
        return Row(
          children: [
            _buildInvoiceButton(context),
            const SizedBox(width: 12),
            Expanded(
              child: isPrescription
                  ? _buildFinishButton(context)
                  : CustomButton(
                      text: 'Save & Continue'.tr,
                      isLoading: controller.isLoading,
                      onPressed: () => controller.saveAndContinue(),
                    ),
            ),
          ],
        );
      }),
    );
  }

  // زر الفاتورة — متاح في التبويبين، ولا يعتمد على حفظ التشخيص
  Widget _buildInvoiceButton(BuildContext context) {
    return SizedBox(
      height: 52,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: context.theme.primaryColor,
          side: BorderSide(color: context.theme.primaryColor),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: controller.isLoading ? null : () => controller.openInvoice(),
        icon: const Icon(Icons.receipt_long_outlined, size: 20),
        label: Text(
          'Invoice'.tr,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  // زر أخضر مدمج (إنهاء المعاينة) — لتفادي تعديل الزر المشترك CustomButton
  Widget _buildFinishButton(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green.shade600,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        onPressed: controller.isLoading ? null : () => controller.saveAndFinish(),
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
                  Flexible(
                    child: Text(
                      'Save & Finish Examination'.tr,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
