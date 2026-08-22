import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/home/home_controller.dart';

class NextPatientCard extends GetView<HomeController> {
  const NextPatientCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // 1. جلب بيانات المريض القادم (تأكد أن المتغير لديك اسمه هكذا، أو قم بتغييره ليطابق الكنترولر)
      final patient = controller.nextPatient.value;

      // 2. التحقق الذكي: إذا كان لا يوجد مريض، أو اسمه فارغ -> إخفاء البطاقة تماماً
      if (patient == null || patient.name.trim().isEmpty || patient.name == 'null') {
        return const SizedBox.shrink(); // يرجع مساحة فارغة (صفر)
      }

      // 3. التصميم الأنيق في حال وجود مريض قادم فعلياً
      return Padding(
        padding: const EdgeInsets.only(bottom: 24.0), // دمجنا المسافة السفلية هنا
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.blue.shade400,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withValues(alpha: 0.3),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Next Patient'.tr,
                    style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  // عرض وقت الموعد
                  Text(
                    controller.formatTime(patient.appointmentTime),
                    style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    backgroundImage: patient.image.isNotEmpty
                        ? NetworkImage(controller.resolveImageUrl(patient.image))
                        : null,
                    child: patient.image.isEmpty
                        ? const Icon(Icons.person, color: Colors.white, size: 30)
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          patient.name,
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${patient.age} ${patient.ageType.tr} • ${patient.gender.tr}',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // الانتقال إلى الملف الطبي للمريض القادم
                    Get.toNamed('/medical_file', arguments: patient);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: Colors.white, width: 1.5),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Start Examination'.tr, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_ios, size: 14),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}