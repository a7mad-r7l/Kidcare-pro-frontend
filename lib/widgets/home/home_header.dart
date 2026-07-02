import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/home/home_controller.dart';

class HomeHeader extends GetView<HomeController> {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final doctor = controller.doctorData.value;
      return SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: context.theme.primaryColor.withOpacity(0.1),
                backgroundImage: doctor != null && doctor.image.isNotEmpty ? NetworkImage(controller.resolveImageUrl(doctor.image)) : null,
                child: doctor == null || doctor.image.isEmpty ? Icon(Icons.person, color: context.theme.primaryColor, size: 28) : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        doctor != null ? 'Dr. ${doctor.name}' : 'Loading...',
                        style: context.theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)
                    ),
                    const SizedBox(height: 2),
                    Text(
                        doctor?.specialization ?? '',
                        style: context.theme.textTheme.bodyMedium?.copyWith(color: context.theme.hintColor)
                    ),
                  ],
                ),
              ),
              Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: context.theme.cardColor,
                      border: Border.all(color: context.theme.dividerColor.withOpacity(0.1)),
                    ),
                    child: IconButton(
                        icon: Icon(Icons.notifications_none_rounded, color: context.theme.textTheme.bodyLarge?.color, size: 26),
                        onPressed: () {}
                    ),
                  ),
                  Positioned(
                    right: 12,
                    top: 12,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                          color: Colors.redAccent,
                          shape: BoxShape.circle,
                          border: Border.all(color: context.theme.scaffoldBackgroundColor, width: 2)
                      ),
                    ),
                  )
                ],
              )
            ],
          ),
        ),
      );
    });
  }
}