import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/revenue/revenue_controller.dart';

class RevenueView extends GetView<RevenueController> {
  const RevenueView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: context.theme.colorScheme.surface,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: Text(
          'Wallet'.tr,
          style: TextStyle(
            color: context.theme.colorScheme.onSurface,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        return RefreshIndicator(
          onRefresh: () => controller.fetchAllRevenueData(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildIncomeCard(context),
                const SizedBox(height: 16),
                _buildPaidVisitsCard(context),
                const SizedBox(height: 16),
                _buildChartCard(context),
              ],
            ),
          ),
        );
      }),
    );
  }

  // ─── Blue monthly-income card with sparkline ──────────────────────────────

  Widget _buildIncomeCard(BuildContext context) {
    final primary = context.theme.primaryColor;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: primary,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.30),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Monthly Income'.tr,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                Obx(() => Text(
                      '${_formatThousands(controller.monthlyRevenue.value)} ${'SAR'.tr}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
                    )),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 90,
            height: 50,
            child: Obx(() => controller.chartData.isEmpty
                ? const SizedBox.shrink()
                : CustomPaint(
                    painter: _LineChartPainter(
                      data: controller.chartData,
                      lineColor: Colors.white,
                      showDots: false,
                      showGrid: false,
                      fillOpacity: 0.18,
                    ),
                  )),
          ),
        ],
      ),
    );
  }

  // ─── White paid-visits card ───────────────────────────────────────────────

  Widget _buildPaidVisitsCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total Paid Visits'.tr,
            style: TextStyle(
              color: context.theme.hintColor,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 6),
          Obx(() => Text(
                '${controller.totalPaidVisits.value} ${'Visit'.tr}',
                style: context.theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              )),
        ],
      ),
    );
  }

  // ─── White chart card (title + tooltip inside) ────────────────────────────

  Widget _buildChartCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 16, 16, 12),
      decoration: _cardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Text(
              'Revenue Overview'.tr,
              style: context.theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: Obx(() => _buildLineChart(context)),
          ),
        ],
      ),
    );
  }

  Widget _buildLineChart(BuildContext context) {
    final data = controller.chartData;
    if (data.isEmpty) {
      return Center(
        child: Text('No data'.tr, style: TextStyle(color: context.theme.hintColor)),
      );
    }

    final dataMax = data.reduce((a, b) => a > b ? a : b);
    // Round the axis ceiling up to a "nice" value so labels read 5K / 10K / 15K / 20K.
    final axisMax = _niceCeil(dataMax);
    final step = axisMax / 4;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Y-axis labels (unit at top, then values top-to-bottom)
        SizedBox(
          width: 40,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'SAR'.tr,
                style: TextStyle(fontSize: 8, color: context.theme.hintColor),
              ),
              ...List.generate(5, (i) {
                final v = axisMax - step * i;
                return Text(
                  v >= 1000
                      ? '${(v / 1000).toStringAsFixed(0)}K'
                      : v.toStringAsFixed(0),
                  style: TextStyle(fontSize: 9, color: context.theme.hintColor),
                );
              }),
            ],
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            children: [
              Expanded(
                child: CustomPaint(
                  size: Size.infinite,
                  painter: _LineChartPainter(
                    data: data,
                    lineColor: context.theme.primaryColor,
                    showDots: true,
                    showGrid: true,
                    fillOpacity: 0.08,
                    tooltip: '${_formatThousands(dataMax)} ${'SAR'.tr}',
                    tooltipBg: context.theme.primaryColor,
                    axisMax: axisMax,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              _buildXAxisLabels(context, data.length),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildXAxisLabels(BuildContext context, int count) {
    // Day markers (1 → 29 مايو), each sitting under its real point on the chart.
    const days = [1, 8, 15, 22, 29];
    final month = 'May'.tr;
    final style = TextStyle(fontSize: 9, color: context.theme.hintColor);

    return SizedBox(
      height: 12,
      child: LayoutBuilder(
        builder: (ctx, box) {
          final width = box.maxWidth;
          return Stack(
            clipBehavior: Clip.none,
            children: days.where((d) => d <= count).map((d) {
              // point d (1-indexed) is drawn at x = (d-1)/(count-1) of the width
              final t = count > 1 ? (d - 1) / (count - 1) : 0.0;
              final label = Text('$d $month', style: style);
              // Anchor first label to the left edge and last to the right edge
              // so nothing clips; center the rest on their point.
              if (d == days.first) {
                return Positioned(left: 0, child: label);
              }
              if (d == days.where((x) => x <= count).last) {
                return Positioned(right: 0, child: label);
              }
              return Positioned(
                left: width * t,
                child: FractionalTranslation(
                  translation: const Offset(-0.5, 0),
                  child: label,
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  // ─── Number helpers ───────────────────────────────────────────────────────

  /// Rounds a value up to a clean axis ceiling (e.g. 15600 → 20000) so the
  /// Y-axis reads 5K / 10K / 15K / 20K like the design.
  double _niceCeil(double value) {
    if (value <= 0) return 4;
    final magnitude =
        math.pow(10, (math.log(value) / math.ln10).floor()).toDouble();
    for (final m in const [1.0, 2.0, 2.5, 5.0, 10.0]) {
      final candidate = magnitude * m;
      if (candidate >= value) return candidate;
    }
    return magnitude * 10;
  }

  /// 15600 → "15,600"
  String _formatThousands(double value) {
    final s = value.toStringAsFixed(0);
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  // ─── Shared white-card decoration ─────────────────────────────────────────

  BoxDecoration _cardDecoration(BuildContext context) => BoxDecoration(
        color: context.theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: context.theme.primaryColor.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      );
}

// ─── Custom line chart painter ────────────────────────────────────────────────

class _LineChartPainter extends CustomPainter {
  final List<double> data;
  final Color lineColor;
  final bool showDots;
  final bool showGrid;
  final double fillOpacity;
  final String? tooltip;
  final Color? tooltipBg;
  // When set, normalizes Y against this ceiling (must match Y-axis labels).
  // When null, self-computes from data min→max (used for the sparkline).
  final double? axisMax;

  const _LineChartPainter({
    required this.data,
    required this.lineColor,
    required this.showDots,
    required this.showGrid,
    required this.fillOpacity,
    this.tooltip,
    this.tooltipBg,
    this.axisMax,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;

    final dataMax = data.reduce((a, b) => a > b ? a : b);
    final dataMin = data.reduce((a, b) => a < b ? a : b);
    // Use the axis ceiling when provided so the line matches the Y-axis labels.
    // Fall back to min→max normalization for the compact sparkline.
    final yMax = axisMax ?? dataMax;
    final yMin = axisMax != null ? 0.0 : dataMin;
    final range = (yMax - yMin) == 0 ? 1.0 : (yMax - yMin);
    final xStep = size.width / (data.length - 1);

    Offset toPoint(int i) => Offset(
          i * xStep,
          size.height - ((data[i] - yMin) / range) * size.height * 0.9 -
              size.height * 0.05,
        );

    final points = List.generate(data.length, toPoint);

    // Grid
    if (showGrid) {
      final gridPaint = Paint()
        ..color = lineColor.withValues(alpha: 0.08)
        ..strokeWidth = 1;
      for (int i = 0; i <= 4; i++) {
        final y = size.height / 4 * i;
        canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
      }
    }

    // Fill under line
    if (fillOpacity > 0) {
      final fillPath = Path()..moveTo(points.first.dx, size.height);
      for (final p in points) {
        fillPath.lineTo(p.dx, p.dy);
      }
      fillPath
        ..lineTo(points.last.dx, size.height)
        ..close();
      canvas.drawPath(
        fillPath,
        Paint()..color = lineColor.withValues(alpha: fillOpacity),
      );
    }

    // Straight-segment line (matches the stepped look in the design)
    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path()..moveTo(points[0].dx, points[0].dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(path, linePaint);

    // Small hollow dot at every data point
    if (showDots) {
      final dotFill = Paint()..color = Colors.white;
      final dotRing = Paint()
        ..color = lineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6;
      for (final p in points) {
        canvas.drawCircle(p, 2.6, dotFill);
        canvas.drawCircle(p, 2.6, dotRing);
      }

      // Emphasized last point
      final last = points.last;
      canvas.drawCircle(last, 4, Paint()..color = lineColor);
      canvas.drawCircle(last, 2, Paint()..color = Colors.white);

      // Tooltip bubble above the last point
      if (tooltip != null && tooltipBg != null) {
        final tp = TextPainter(
          text: TextSpan(
            text: tooltip,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();

        const padH = 8.0;
        const padV = 4.0;
        final bubbleW = tp.width + padH * 2;
        final bubbleH = tp.height + padV * 2;
        var bubbleLeft = last.dx - bubbleW / 2;
        // keep bubble inside bounds
        if (bubbleLeft + bubbleW > size.width) bubbleLeft = size.width - bubbleW;
        if (bubbleLeft < 0) bubbleLeft = 0;
        final bubbleTop = (last.dy - bubbleH - 8).clamp(0.0, size.height);

        final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(bubbleLeft, bubbleTop, bubbleW, bubbleH),
          const Radius.circular(6),
        );
        canvas.drawRRect(rect, Paint()..color = tooltipBg!);
        tp.paint(canvas, Offset(bubbleLeft + padH, bubbleTop + padV));
      }
    }
  }

  @override
  bool shouldRepaint(_LineChartPainter old) =>
      old.data != data || old.lineColor != lineColor || old.axisMax != axisMax;
}
