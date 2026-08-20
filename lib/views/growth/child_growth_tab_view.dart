// File: lib/views/growth/child_growth_tab_view.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/growth/child_growth_controller.dart';
import '../../../core/repos/growth/child_growth_repo.dart';
import '../../widgets/growth/growth_chart_widget.dart';
import '../../widgets/growth/growth_history_list.dart';

class ChildGrowthTabView extends StatelessWidget {
  final int childId;

  const ChildGrowthTabView({super.key, required this.childId});

  @override
  Widget build(BuildContext context) {
    // حقن الـ Controller الخاص بالنمو
    final controller = Get.put(ChildGrowthController(repo: ChildGrowthRepo()));
    controller.childId = childId;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.getGrowthDashboard();
    });

    return Obx(() {
      if (controller.isLoading && controller.growthData.value == null) {
        return Center(
          child: CircularProgressIndicator(color: context.theme.primaryColor),
        );
      }

      final data = controller.growthData.value;
      if (data == null) {
        return Center(
          child: Text(
            'Failed to load growth data'.tr,
            style: TextStyle(color: context.textTheme.bodyMedium?.color),
          ),
        );
      }

      return RefreshIndicator(
        onRefresh: () => controller.getGrowthDashboard(),
        color: context.theme.primaryColor,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildQuickStatsSection(context, data.growthHistory, data.currentAgeMonths),
              const SizedBox(height: 16),
              GrowthChartWidget(data: data),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Growth History'.tr,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: context.textTheme.bodyLarge?.color,
                    ),
                  ),
                  Icon(Icons.sort_rounded, color: context.textTheme.bodyMedium?.color, size: 20),
                ],
              ),
              const SizedBox(height: 12),
              GrowthHistoryList(data: data),
              const SizedBox(height: 60),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildQuickStatsSection(BuildContext context, List<dynamic> history, double rawAge) {
    final latestRecord = history.isNotEmpty ? history.first : null;
    final displayWeight = latestRecord != null ? '${latestRecord.weight} ${'kg'.tr}' : '--';
    final displayHeight = latestRecord != null ? '${latestRecord.height} ${'cm'.tr}' : '--';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.theme.dividerColor),
      ),
      child: Row(
        children: [
          Expanded(child: _QuickStatCard(icon: Icons.scale_outlined, label: 'Current Weight'.tr, value: displayWeight)),
          Container(width: 1, height: 40, color: context.theme.dividerColor),
          Expanded(child: _QuickStatCard(icon: Icons.straighten_outlined, label: 'Current Height'.tr, value: displayHeight)),
          Container(width: 1, height: 40, color: context.theme.dividerColor),
          Expanded(child: _QuickStatCard(icon: Icons.calendar_month_outlined, label: 'Age'.tr, value: '${rawAge.toInt()} ${'Months'.tr}')),
        ],
      ),
    );
  }
}

class _QuickStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _QuickStatCard({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: context.theme.primaryColor, size: 22),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: context.textTheme.bodyMedium?.color, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: context.textTheme.bodyLarge?.color),
        ),
      ],
    );
  }
}