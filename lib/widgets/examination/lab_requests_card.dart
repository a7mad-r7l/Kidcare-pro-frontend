import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/examination/examination_controller.dart';
import 'add_lab_request_dialog.dart';
import 'examination_fields.dart';

// بطاقة طلب التحاليل وصور الأشعة — يضيف الطبيب طلبات عبر زر ثم تظهر كصفوف
class LabRequestsCard extends GetView<ExaminationController> {
  const LabRequestsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return buildTitledCard(
      context,
      icon: Icons.science_outlined,
      title: 'Lab & Imaging Requests'.tr,
      trailing: buildAddLink(
        context,
        'Add Request'.tr,
        () => _showAddLabRequestSheet(context),
      ),
      child: Obx(() {
        if (controller.labRequests.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'No requests added'.tr,
              style: context.theme.textTheme.bodySmall?.copyWith(
                color: context.theme.hintColor,
              ),
            ),
          );
        }
        return Column(
          children: [
            for (int i = 0; i < controller.labRequests.length; i++)
              _buildLabRequestRow(context, i),
          ],
        );
      }),
    );
  }

  // صف طلب واحد: أيقونة النوع + القيمة + زر الحذف
  Widget _buildLabRequestRow(BuildContext context, int index) {
    final item = controller.labRequests[index];
    final isTest = item.type == LabRequestType.test;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: context.theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.theme.dividerColor),
      ),
      child: Row(
        children: [
          Icon(
            isTest ? Icons.biotech_outlined : Icons.image_outlined,
            size: 20,
            color: context.theme.primaryColor,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              item.value,
              style: context.theme.textTheme.bodyMedium?.copyWith(
                color: context.theme.textTheme.bodyLarge?.color,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => controller.removeLabRequest(index),
            child: const Icon(Icons.close, color: Colors.red, size: 20),
          ),
        ],
      ),
    );
  }

  void _showAddLabRequestSheet(BuildContext context) {
    Get.dialog(
      AddLabRequestDialog(
        onAdd: (type, value) => controller.addLabRequest(type, value),
      ),
    );
  }
}
