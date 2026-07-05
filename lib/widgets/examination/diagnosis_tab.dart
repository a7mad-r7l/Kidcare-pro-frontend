import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/examination/examination_controller.dart';
import 'examination_fields.dart';

// ─── تبويب التشخيص (التشخيص السريري / الملاحظات / بطاقة القياسات) ───
class DiagnosisTab extends GetView<ExaminationController> {
  const DiagnosisTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildTitledCard(
            context,
            icon: Icons.edit_note,
            title: 'Clinical Diagnosis'.tr,
            child: buildMultilineField(
              context,
              controller: controller.diagnosisController,
              hintText: 'Write the clinical diagnosis for the case'.tr,
              maxLines: 5,
              maxLength: 500,
              fillColor: context.theme.scaffoldBackgroundColor,
            ),
          ),
          const SizedBox(height: 16),
          buildTitledCard(
            context,
            icon: Icons.description_outlined,
            title: 'General Doctor Notes'.tr,
            child: buildMultilineField(
              context,
              controller: controller.doctorNotesController,
              hintText:
                  "Write any general notes about the child's condition".tr,
              maxLines: 4,
              maxLength: 300,
              fillColor: context.theme.scaffoldBackgroundColor,
            ),
          ),
          const SizedBox(height: 16),
          _buildMeasurementsCard(context),
        ],
      ),
    );
  }

  // بطاقة القياسات القابلة للطي (اختيارية) — الطول والوزن معاً
  Widget _buildMeasurementsCard(BuildContext context) {
    return Obx(() {
      final expanded = controller.measurementsExpanded.value;
      return Container(
        decoration: BoxDecoration(
          color: context.theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.theme.dividerColor),
        ),
        child: Column(
          children: [
            // رأس البطاقة القابل للنقر لفتح/طي الحقول
            InkWell(
              onTap: () => controller.measurementsExpanded.toggle(),
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Icon(
                      Icons.straighten,
                      size: 20,
                      color: context.theme.primaryColor,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${'Measurements'.tr} (${'Optional'.tr})',
                        style: context.theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    Icon(
                      expanded ? Icons.expand_less : Icons.expand_more,
                      color: context.theme.hintColor,
                    ),
                  ],
                ),
              ),
            ),
            if (expanded)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                child: Row(
                  children: [
                    Expanded(
                      child: buildLabeledField(
                        context,
                        controller: controller.heightController,
                        label: 'Height'.tr,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: buildLabeledField(
                        context,
                        controller: controller.weightController,
                        label: 'Weight'.tr,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      );
    });
  }
}
