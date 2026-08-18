import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/examination/examination_controller.dart';
import '../../core/constants.dart';

// ─── ترويسة المريض (الصورة / الاسم / العمر / المعرف) ───
class PatientHeader extends GetView<ExaminationController> {
  const PatientHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final patient = controller.patient.value;
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: context.theme.primaryColor.withOpacity(0.12),
              backgroundImage: patient != null && patient.image.isNotEmpty
                  // الباك إند قد يرجع رابطاً كاملاً أو مساراً نسبياً
                  ? NetworkImage(
                      patient.image.startsWith('http')
                          ? patient.image
                          : '$baseUrl/${patient.image}',
                    )
                  : null,
              child: patient == null || patient.image.isEmpty
                  ? Icon(
                      Icons.person,
                      color: context.theme.primaryColor,
                      size: 30,
                    )
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    patient?.name ?? 'Loading...',
                    style: context.theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    patient != null
                        ? '${patient.age} ${patient.ageType.tr} • ${patient.gender.tr}'
                        : '',
                    style: context.theme.textTheme.bodyMedium?.copyWith(
                      color: context.theme.hintColor,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    controller.formattedPatientId,
                    style: context.theme.textTheme.bodySmall?.copyWith(
                      color: context.theme.hintColor,
                      fontSize: 11,
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
