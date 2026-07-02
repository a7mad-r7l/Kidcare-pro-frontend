import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/home/home_controller.dart';

class StatsGrid extends GetView<HomeController> {
  const StatsGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() => Row(
      children: [
        Expanded(child: _buildStatItem(context, 'Completed'.tr, controller.completedAppointments.value.toString(), Icons.fact_check_outlined, Colors.green)),
        const SizedBox(width: 12),
        Expanded(child: _buildStatItem(context, "Today's Total".tr, controller.totalAppointments.value.toString(), Icons.calendar_today_outlined, Colors.blue)),
        const SizedBox(width: 12),
        Expanded(child: _buildStatItem(context, 'Monthly Rev'.tr, '\$${controller.monthlyRevenue.value.toStringAsFixed(0)}', Icons.monetization_on_outlined, Colors.orange)),
      ],
    ));
  }

  Widget _buildStatItem(BuildContext context, String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: context.theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.theme.dividerColor.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 10),
          Text(label, style: context.theme.textTheme.bodySmall?.copyWith(color: context.theme.hintColor, fontSize: 10), textAlign: TextAlign.center),
          const SizedBox(height: 6),
          Text(value, style: context.theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }
}