// File: lib/widgets/growth/growth_history_list.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/growth/child_growth_controller.dart';
import '../../../models/growth/child_growth_response_model.dart';
import '../../../models/growth/growth_record_model.dart';

class GrowthHistoryList extends StatelessWidget {
  final ChildGrowthResponseModel data;

  const GrowthHistoryList({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ChildGrowthController>();

    // ترتيب السجلات تنازلياً (الأحدث أولاً)
    final List<GrowthRecordModel> sortedHistory = List.from(data.growthHistory)
      ..sort((a, b) => b.ageInMonths.compareTo(a.ageInMonths));

    if (sortedHistory.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 32),
          child: Text(
            'No measurements found'.tr, // تم تعديل النص ليكون أوضح
            style: TextStyle(color: context.textTheme.bodyMedium?.color, fontSize: 14),
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sortedHistory.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final record = sortedHistory[index];
        return _HistoryCard(record: record, controller: controller);
      },
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final GrowthRecordModel record;
  final ChildGrowthController controller;

  const _HistoryCard({required this.record, required this.controller});

  @override
  Widget build(BuildContext context) {
    Color badgeColor;
    try {
      badgeColor = Color(int.parse(record.statusColor.replaceAll('#', '0xFF')));
    } catch (_) {
      badgeColor = const Color(0xFF4CAF50);
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: context.isDarkMode ? Colors.transparent : Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: context.theme.dividerColor),
      ),
      child: Row(
        children: [
          // 1. أيقونة الميزان الجانبية
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: context.isDarkMode ? Colors.blue.withOpacity(0.15) : const Color(0xFFF0F4FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.assignment_outlined,
              color: context.isDarkMode ? Colors.blue.shade300 : Colors.blue,
              size: 24,
            ),
          ),
          const SizedBox(width: 10),

          // 2. عمود تفاصيل الوزن والطول
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      Text(
                        '${'Weight'.tr}: ${record.weight} ${'kg'.tr}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: context.textTheme.bodyLarge?.color,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '|  ${'Height'.tr}: ${record.height} ${'cm'.tr}',
                        style: TextStyle(
                          fontSize: 12,
                          color: context.textTheme.bodyMedium?.color,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      record.date,
                      style: TextStyle(
                        fontSize: 10,
                        color: context.textTheme.bodyMedium?.color,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      width: 3,
                      height: 3,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: context.theme.dividerColor,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${'Age'.tr} ${record.ageInMonths.toInt()} ${'months_old'.tr}',
                        style: TextStyle(
                          fontSize: 10,
                          color: context.textTheme.bodyMedium?.color,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),

          // 3. قسم الشارة التفاعلية (تم إزالة زر الحذف من هنا)
          Expanded(
            flex: 2,
            child: GestureDetector(
              onTap: () => _showStatusDetailsDialog(context, badgeColor),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                decoration: BoxDecoration(
                  color: badgeColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        record.statusText.contains('ينصح')
                            ? 'Needs Review'.tr
                            : record.statusText.tr,
                        style: TextStyle(
                          color: badgeColor,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Icon(
                      Icons.info_outline_rounded,
                      color: badgeColor,
                      size: 10,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showStatusDetailsDialog(BuildContext context, Color color) {
    Get.dialog(
      AlertDialog(
        backgroundColor: context.theme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.analytics_outlined, color: color, size: 24),
            const SizedBox(width: 8),
            Text(
              'Medical Assessment'.tr,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: context.textTheme.bodyLarge?.color,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: color.withOpacity(0.2)),
              ),
              child: Text(
                record.statusText,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                  color: context.textTheme.bodyLarge?.color,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'Close'.tr,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: context.theme.primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}