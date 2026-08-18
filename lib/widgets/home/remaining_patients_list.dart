import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/home/home_controller.dart';

class RemainingPatientsList extends GetView<HomeController> {
  const RemainingPatientsList({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.remainingPatients.isEmpty) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 30),
          child: Center(child: Text('No remaining patients for this date'.tr)),
        );
      }
      return ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: controller.remainingPatients.length,
        separatorBuilder: (context, index) => Container(
          height: 1,
          width: double.infinity,
          color: context.theme.dividerColor.withOpacity(0.15),
          margin: const EdgeInsets.symmetric(vertical: 4),
        ),
        itemBuilder: (context, index) {
          final patient = controller.remainingPatients[index];
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: context.theme.primaryColor.withOpacity(0.1),
                  backgroundImage: patient.image.isNotEmpty ? NetworkImage(controller.resolveImageUrl(patient.image)) : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(patient.name, style: context.theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 4),
                      Text('${patient.age} ${patient.ageType.tr}• ${patient.gender.tr}', style: context.theme.textTheme.bodyMedium?.copyWith(color: context.theme.hintColor, fontSize: 12)),
                    ],
                  ),
                ),
                Text(
                  controller.formatTime(patient.appointmentTime),
                  style: TextStyle(color: context.theme.primaryColor, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ],
            ),
          );
        },
      );
    });
  }
}