import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/home/home_controller.dart';

class FloatingBottomBar extends GetView<HomeController> {
  const FloatingBottomBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return SafeArea(
        child: Container(
          height: 68,
          margin: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: context.theme.cardColor,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(color: context.theme.primaryColor.withOpacity(0.12), blurRadius: 20, offset: const Offset(0, 8))],
            border: Border.all(color: context.theme.dividerColor.withOpacity(0.05), width: 1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(context, 0, Icons.home_filled, 'Home'.tr),
              _buildNavItem(context, 1, Icons.edit_calendar_outlined, 'Schedule'.tr),
              _buildNavItem(context, 2, Icons.people_alt_outlined, 'Patients'.tr),
              _buildNavItem(context, 3, Icons.analytics_outlined, 'Revenue'.tr),
              _buildNavItem(context, 4, Icons.settings_outlined, 'Settings'.tr),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildNavItem(BuildContext context, int index, IconData icon, String label) {
    final isSelected = controller.currentIndex.value == index;
    final activeColor = context.theme.primaryColor;
    final inactiveColor = context.theme.hintColor.withOpacity(0.4);

    return InkWell(
      onTap: () => controller.currentIndex.value = index,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withOpacity(0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedScale(
              scale: isSelected ? 1.15 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: Icon(icon, color: isSelected ? activeColor : inactiveColor, size: isSelected ? 24 : 22),
            ),
            const SizedBox(height: 3),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(fontSize: 10, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? activeColor : inactiveColor),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}