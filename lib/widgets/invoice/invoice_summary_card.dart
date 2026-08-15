import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/invoice/invoice_controller.dart';

// ─── بطاقة الإجمالي — الأجرة + مجموع الخدمات الإضافية ───
class InvoiceSummaryCard extends GetView<InvoiceController> {
  const InvoiceSummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.theme.dividerColor),
      ),
      child: Obx(
        () => Column(
          children: [
            _buildRow(
              context,
              'Consultation Fee'.tr,
              controller.formatMoney(controller.consultationFee),
            ),
            const SizedBox(height: 10),
            _buildRow(
              context,
              '${'Extra Services'.tr} (${controller.additions.length})',
              controller.formatMoney(controller.extrasTotal),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: _DashedDivider(),
            ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Total Amount'.tr,
                    style: context.theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                Text(
                  controller.formatMoney(controller.totalAmount),
                  style: context.theme.textTheme.titleLarge?.copyWith(
                    color: context.theme.primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(BuildContext context, String label, String value) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: context.theme.textTheme.bodyMedium?.copyWith(
              color: context.theme.hintColor,
              fontSize: 13,
            ),
          ),
        ),
        Text(
          value,
          style: context.theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

// فاصل متقطع يفصل بنود الفاتورة عن الإجمالي
class _DashedDivider extends StatelessWidget {
  const _DashedDivider();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const dashWidth = 5.0;
        const dashSpace = 4.0;
        final count = (constraints.maxWidth / (dashWidth + dashSpace)).floor();
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(
            count,
            (_) => SizedBox(
              width: dashWidth,
              height: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(color: context.theme.dividerColor),
              ),
            ),
          ),
        );
      },
    );
  }
}
