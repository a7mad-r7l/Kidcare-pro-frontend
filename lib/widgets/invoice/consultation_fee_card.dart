import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/invoice/invoice_controller.dart';

// ─── بطاقة أجرة الكشف — قيمة ثابتة تُضبط عند الحجز ولا يعدّلها الطبيب ───
class ConsultationFeeCard extends GetView<InvoiceController> {
  const ConsultationFeeCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.theme.dividerColor),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: context.theme.primaryColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.medical_services_outlined,
              color: context.theme.primaryColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Consultation Fee'.tr,
                  style: context.theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'General Consultation'.tr,
                  style: context.theme.textTheme.bodySmall?.copyWith(
                    color: context.theme.hintColor,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Obx(
            () => Text(
              controller.formatMoney(controller.consultationFee),
              style: context.theme.textTheme.titleMedium?.copyWith(
                color: context.theme.primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
