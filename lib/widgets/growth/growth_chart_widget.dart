import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:get/get.dart';
import '../../../models/growth/child_growth_response_model.dart';
import '../../../models/growth/growth_record_model.dart';
import 'dart:math' as math;

class GrowthChartWidget extends StatelessWidget {
  final ChildGrowthResponseModel data;

  const GrowthChartWidget({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final isRtl = Get.locale?.languageCode == 'ar';

    return Container(
      height: 320,
      padding: const EdgeInsets.fromLTRB(12, 20, 20, 12),
      decoration: BoxDecoration(
        color: context.theme.cardColor,
        borderRadius: BorderRadius.circular(20),

        border: Border.all(color: context.theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLegend(context),
          const SizedBox(height: 16),
          Expanded(child: LineChart(_buildChartData(context, isRtl))),
        ],
      ),
    );
  }

  /// الألوان والخطوط أعلى المخطط (Legend)
  Widget _buildLegend(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          _LegendItem(
            color: Colors.blue,
            label: '${'weight'.tr} ${data.childName}',
            isDot: false,
          ),
          const SizedBox(width: 12),
          _LegendItem(
            color: Colors.green,
            label: 'Ideal Weight (WHO)'.tr,
            isDot: true,
          ),
          const SizedBox(width: 12),
          _LegendItem(
            color: Colors.redAccent,
            label: 'Max Limit (WHO)'.tr,
            isDot: true,
          ),
        ],
      ),
    );
  }

  LineChartData _buildChartData(BuildContext context, bool isRtl) {
    // 1. خط منظمة الصحة العالمية (المثالي)
    final List<FlSpot> idealSpots = data.whoStandards
        .map((e) => FlSpot(e.ageInMonths.toDouble(), e.whoIdeal))
        .toList();

    // 2. خط منظمة الصحة العالمية (الأقصى)
    final List<FlSpot> maxSpots = data.whoStandards
        .map((e) => FlSpot(e.ageInMonths.toDouble(), e.whoMaxWeight))
        .toList();

    // 3. خط منظمة الصحة العالمية (الأدنى)
    final List<FlSpot> minSpots = data.whoStandards
        .map((e) => FlSpot(e.ageInMonths.toDouble(), e.whoMinWeight))
        .toList();

    // 4. خط نمو الطفل الفعلي
    final List<GrowthRecordModel> sortedHistory = List.from(data.growthHistory)
      ..sort((a, b) => a.ageInMonths.compareTo(b.ageInMonths));

    final List<FlSpot> childSpots = sortedHistory
        .map((e) => FlSpot(e.ageInMonths.toDouble(), e.weight))
        .toList();

    final double maxAgeInData = sortedHistory.isNotEmpty
        ? sortedHistory.last.ageInMonths.toDouble()
        : 0;
    final double maxWeightInData = sortedHistory.isNotEmpty
        ? sortedHistory.map((e) => e.weight).reduce(math.max)
        : 0;

    final double calculatedMaxX = math.max(36.0, maxAgeInData + 2);
    final double calculatedMaxY = math.max(20.0, maxWeightInData + 5);

    return LineChartData(
      clipData: const FlClipData.all(),
      gridData: FlGridData(
        show: true,
        drawVerticalLine: true,
        horizontalInterval: 5,

        verticalInterval: (data.currentAgeMonths > 24) ? 12 : 6,

        getDrawingHorizontalLine: (value) =>
            FlLine(color: context.theme.dividerColor, strokeWidth: 1),
        getDrawingVerticalLine: (value) =>
            FlLine(color: context.theme.dividerColor, strokeWidth: 1),
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          axisNameWidget: Text(
            'Age (Months)'.tr,
            style: TextStyle(
              fontSize: 11,

              color: context.textTheme.bodyMedium?.color,
              fontWeight: FontWeight.bold,
            ),
          ),
          axisNameSize: 20,
          sideTitles: SideTitles(
            showTitles: true,

            interval: (data.currentAgeMonths > 24) ? 12 : 6,
            getTitlesWidget: (value, meta) => Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                value.toInt().toString(),

                style: TextStyle(
                  color: context.textTheme.bodyMedium?.color,
                  fontSize: 11,
                ),
              ),
            ),
          ),
        ),
        leftTitles: AxisTitles(
          axisNameWidget: Text(
            'Weight (kg)'.tr,
            style: TextStyle(
              fontSize: 11,

              color: context.textTheme.bodyMedium?.color,
              fontWeight: FontWeight.bold,
            ),
          ),
          axisNameSize: 20,
          sideTitles: SideTitles(
            showTitles: true,
            interval: 5,
            getTitlesWidget: (value, meta) => Text(
              value.toInt().toString(),

              style: TextStyle(
                color: context.textTheme.bodyMedium?.color,
                fontSize: 11,
              ),
            ),
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      minX: 0,

      maxX: data.currentAgeMonths > 24
          ? data.currentAgeMonths.toDouble()
          : 24.0,
      minY: 0,
      maxY: calculatedMaxY,
      lineBarsData: [
        LineChartBarData(
          spots: minSpots,
          isCurved: true,
          color: Colors.redAccent.withOpacity(0.4),
          barWidth: 1.5,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
          dashArray: [4, 4],
        ),
        LineChartBarData(
          spots: maxSpots,
          isCurved: true,
          color: Colors.redAccent.withOpacity(0.6),
          barWidth: 1.5,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
          dashArray: [4, 4],
        ),
        LineChartBarData(
          spots: idealSpots,
          isCurved: true,
          color: Colors.green.withOpacity(0.7),
          barWidth: 2,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
          dashArray: [4, 4],
        ),
        // خط نمو الطفل الفعلي
        LineChartBarData(
          spots: childSpots,
          isCurved: false,
          color: Colors.blue.shade700,
          barWidth: 3.5,
          isStrokeCapRound: true,

          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) =>
                FlDotCirclePainter(
                  radius: 5,
                  color: Colors.blue.shade800,
                  strokeWidth: 2,

                  strokeColor: context.theme.cardColor,
                ),
          ),
        ),
      ],
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (touchedSpot) => context.isDarkMode
              ? const Color(0xFF303030)
              : const Color(0xFF212121),
          getTooltipItems: (List<LineBarSpot> touchedSpots) {
            return touchedSpots.map((barSpot) {
              if (barSpot.barIndex == 3) {
                final index = barSpot.spotIndex;
                if (index < sortedHistory.length) {
                  final record = sortedHistory[index];
                  return LineTooltipItem(
                    '${record.date}\n${'Weight (kg)'.tr}: ${record.weight}\n${'Status: '.tr}${record.statusText.tr}',
                    const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      height: 1.4,
                    ),
                  );
                }
              }
              return null;
            }).toList();
          },
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final bool isDot;

  const _LegendItem({
    required this.color,
    required this.label,
    required this.isDot,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isDot)
          Row(
            children: List.generate(
              3,
              (index) => Container(
                width: 5,
                height: 2,
                margin: const EdgeInsets.symmetric(horizontal: 1),
                color: color,
              ),
            ),
          )
        else
          Container(width: 14, height: 3, color: color),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            // ─── لون نص الدليل متكيف ───
            color: context.textTheme.bodyMedium?.color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
