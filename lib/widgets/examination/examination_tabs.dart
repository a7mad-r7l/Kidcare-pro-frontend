import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/examination/examination_controller.dart';

// ─── شريط التبويبات (التشخيص / الوصفة) ───
class ExaminationTabs extends GetView<ExaminationController> {
  const ExaminationTabs({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: context.theme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.theme.dividerColor),
      ),
      child: Obx(
        () => Row(
          children: [
            _buildTabItem(context, 1, 'Prescription'.tr),
            _buildTabItem(context, 0, 'Diagnosis'.tr),
          ],
        ),
      ),
    );
  }

  Widget _buildTabItem(BuildContext context, int index, String label) {
    final isSelected = controller.selectedTab.value == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => controller.selectedTab.value = index,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? context.theme.primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : context.theme.hintColor,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}
