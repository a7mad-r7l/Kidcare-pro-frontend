import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/home/home_controller.dart';

class NextPatientCard extends GetView<HomeController> {
  const NextPatientCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final patient = controller.nextPatient.value;
      if (patient == null) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: context.theme.primaryColor, borderRadius: BorderRadius.circular(16)),
          child: Center(child: Text('No upcoming patients'.tr, style: const TextStyle(color: Colors.white))),
        );
      }
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: context.theme.primaryColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: context.theme.primaryColor.withOpacity(0.35),
                blurRadius: 20,
                offset: const Offset(0, 8),
              )
            ]
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Next Patient'.tr, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
            const SizedBox(height: 16),
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white24,
                  backgroundImage: patient.image.isNotEmpty ? NetworkImage(controller.resolveImageUrl(patient.image)) : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(patient.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                      const SizedBox(height: 6),
                      Text('${patient.age} ${'Yrs'.tr}• ${patient.gender.tr}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 45,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white, width: 1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  foregroundColor: Colors.white,
                ),
                // ─── الإصلاح هنا: توجيه الطبيب لشاشة المعاينة بدلاً من إنهاء الموعد ───
                onPressed: () => Get.toNamed('/examination', arguments: patient),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Start Examination'.tr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_ios, size: 14),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}