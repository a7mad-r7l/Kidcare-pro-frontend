import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/examination/examination_controller.dart';
import 'examination_fields.dart';

// بطاقة وصفة الأدوية — العنوان مع رابط "إضافة دواء" وزر "إضافة دواء آخر" بالأسفل داخلها
class MedicationsCard extends GetView<ExaminationController> {
  const MedicationsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return buildTitledCard(
      context,
      icon: Icons.medication_outlined,
      title: 'Medications Prescription'.tr,
      trailing: buildAddLink(
        context,
        'Add Medication'.tr,
        () => controller.addMedicationField(),
      ),
      child: Obx(
        () => Column(
          children: [
            for (int i = 0; i < controller.medications.length; i++) ...[
              if (i > 0) ...[
                const SizedBox(height: 8),
                Divider(height: 1, color: context.theme.dividerColor),
                const SizedBox(height: 8),
              ],
              _buildMedicationEntry(context, i),
            ],
            const SizedBox(height: 12),
            _buildAddAnotherButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicationEntry(BuildContext context, int index) {
    final med = controller.medications[index];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // زر الحذف (X) يظهر فقط عند وجود أكثر من دواء
        if (controller.medications.length > 1)
          Align(
            alignment: AlignmentDirectional.topStart,
            child: GestureDetector(
              onTap: () => controller.removeMedicationField(index),
              child: const Icon(Icons.close, color: Colors.red, size: 20),
            ),
          ),
        buildLabeledField(
          context,
          controller: med.nameController,
          label: 'Medicine Name'.tr,
        ),
        const SizedBox(height: 12),
        // الجرعة والتعليمات كلٌّ في حقل مستقل
        buildLabeledField(
          context,
          controller: med.dosageController,
          label: 'Dosage'.tr,
        ),
        const SizedBox(height: 12),
        buildLabeledField(
          context,
          controller: med.timingController,
          label: 'Instructions'.tr,
        ),
        const SizedBox(height: 12),
        // الكمية والمدة جنباً إلى جنب
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: buildLabeledField(
                context,
                controller: med.frequencyController,
                label: 'Quantity'.tr,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: buildLabeledField(
                context,
                controller: med.durationController,
                label: 'Duration'.tr,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // زر "إضافة دواء آخر" الممتد أسفل بطاقة الأدوية
  Widget _buildAddAnotherButton(BuildContext context) {
    return GestureDetector(
      onTap: () => controller.addMedicationField(),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: context.theme.primaryColor.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add, size: 18, color: context.theme.primaryColor),
            const SizedBox(width: 6),
            Text(
              'Add Another Medication'.tr,
              style: TextStyle(
                color: context.theme.primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
