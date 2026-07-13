import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/examination/examination_controller.dart';
import '../../widgets/examination/diagnosis_tab.dart';
import '../../widgets/examination/examination_bottom_action.dart';
import '../../widgets/examination/examination_tabs.dart';
import '../../widgets/examination/patient_header.dart';
import '../../widgets/examination/prescription_tab.dart';

class ExaminationView extends GetView<ExaminationController> {
  const ExaminationView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: context.theme.cardColor,
        foregroundColor: context.theme.textTheme.bodyLarge?.color,
        elevation: 0,
        surfaceTintColor: context.theme.cardColor,
        title: Text('Patient Examination'.tr),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const PatientHeader(),
            const ExaminationTabs(),
            Expanded(
              child: Obx(() {
                switch (controller.selectedTab.value) {
                  case 1:
                    return const PrescriptionTab();
                  case 0:
                  default:
                    return const DiagnosisTab();
                }
              }),
            ),
            const ExaminationBottomAction(),
          ],
        ),
      ),
    );
  }
}
