import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/invoice/invoice_controller.dart';
import '../../core/constants.dart';

// ─── بطاقة المريض أعلى الفاتورة (الصورة / الاسم / المعرف / تاريخ ووقت الموعد) ───
class InvoicePatientCard extends GetView<InvoiceController> {
  const InvoicePatientCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final image = controller.patientImage;
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.theme.dividerColor),
        ),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: context.theme.primaryColor.withValues(
                    alpha: 0.12,
                  ),
                  // الباك إند قد يرجع رابطاً كاملاً أو مساراً نسبياً
                  backgroundImage: image.isNotEmpty
                      ? NetworkImage(
                          image.startsWith('http') ? image : '$baseUrl/$image',
                        )
                      : null,
                  child: image.isEmpty
                      ? Icon(
                          Icons.person,
                          color: context.theme.primaryColor,
                          size: 32,
                        )
                      : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        controller.patientName.isEmpty
                            ? 'Loading...'.tr
                            : controller.patientName,
                        style: context.theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            '${'Patient ID'.tr}: ',
                            style: context.theme.textTheme.bodySmall?.copyWith(
                              color: context.theme.hintColor,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            controller.formattedPatientId,
                            style: context.theme.textTheme.bodySmall?.copyWith(
                              color: context.theme.primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Divider(color: context.theme.dividerColor, height: 28),
            Row(
              children: [
                _buildMeta(
                  context,
                  Icons.calendar_today_outlined,
                  controller.formattedDate,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Icon(
                    Icons.circle,
                    size: 4,
                    color: context.theme.hintColor,
                  ),
                ),
                _buildMeta(
                  context,
                  Icons.access_time,
                  controller.formattedTime,
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  Widget _buildMeta(BuildContext context, IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: context.theme.primaryColor),
        const SizedBox(width: 6),
        Text(
          label,
          style: context.theme.textTheme.bodySmall?.copyWith(
            color: context.theme.hintColor,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
