import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../core/theme/open_vts_colors.dart';
import '../../../../../core/theme/open_vts_radius.dart';
import '../../../../../core/theme/open_vts_spacing.dart';
import '../../../../../core/theme/open_vts_typography.dart';
import '../../../../../shared/widgets/open_vts_card.dart';
import '../../../models/admin_dashboard_model.dart';

enum AdminGrowthChartRange {
  threeMonths('3M', 3),
  sixMonths('6M', 6),
  twelveMonths('12M', 12),
  all('All', null);

  const AdminGrowthChartRange(this.label, this.limit);

  final String label;
  final int? limit;
}

class AdminGrowthChartCard extends StatefulWidget {
  const AdminGrowthChartCard({required this.points, super.key});

  final List<AdminMonthGraphPoint> points;

  @override
  State<AdminGrowthChartCard> createState() => _AdminGrowthChartCardState();
}

class _AdminGrowthChartCardState extends State<AdminGrowthChartCard> {
  AdminGrowthChartRange _range = AdminGrowthChartRange.twelveMonths;

  @override
  Widget build(BuildContext context) {
    final points = _filteredPoints(widget.points, _range);
    final isEmpty = _isFlatOrZero(points);

    return OpenVtsCard(
      padding: const EdgeInsets.all(OpenVtsSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: _SectionHeading(
                  title: 'Growth Chart',
                  icon: Icons.show_chart_rounded,
                ),
              ),
              _RangeSelector(
                selectedRange: _range,
                onChanged: (range) {
                  setState(() {
                    _range = range;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: OpenVtsSpacing.xs),
          const Wrap(
            spacing: OpenVtsSpacing.sm,
            runSpacing: OpenVtsSpacing.xs,
            children: [
              _SeriesLegend(label: 'Users', solid: true),
              _SeriesLegend(label: 'Vehicles', solid: false),
            ],
          ),
          const SizedBox(height: OpenVtsSpacing.sm),
          SizedBox(
            height: 286,
            child: isEmpty
                ? const _GrowthEmptyState()
                : _GrowthLineChart(points: points),
          ),
        ],
      ),
    );
  }

  List<AdminMonthGraphPoint> _filteredPoints(
    List<AdminMonthGraphPoint> points,
    AdminGrowthChartRange range,
  ) {
    if (points.isEmpty ||
        range.limit == null ||
        points.length <= range.limit!) {
      return points;
    }

    return points.sublist(points.length - range.limit!);
  }

  bool _isFlatOrZero(List<AdminMonthGraphPoint> points) {
    if (points.isEmpty) {
      return true;
    }

    final allZero = points.every(
      (point) => point.userCount == 0 && point.vehicleCount == 0,
    );
    if (allZero) {
      return true;
    }

    final firstUser = points.first.userCount;
    final firstVehicle = points.first.vehicleCount;
    return points.every(
      (point) =>
          point.userCount == firstUser && point.vehicleCount == firstVehicle,
    );
  }
}

class _RangeSelector extends StatelessWidget {
  const _RangeSelector({
    required this.selectedRange,
    required this.onChanged,
  });

  final AdminGrowthChartRange selectedRange;
  final ValueChanged<AdminGrowthChartRange> onChanged;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: OpenVtsColors.surface,
        borderRadius: BorderRadius.circular(OpenVtsRadius.md),
        border: Border.all(color: OpenVtsColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final range in AdminGrowthChartRange.values)
              _RangeSegment(
                range: range,
                isSelected: range == selectedRange,
                onTap: () => onChanged(range),
              ),
          ],
        ),
      ),
    );
  }
}

class _RangeSegment extends StatelessWidget {
  const _RangeSegment({
    required this.range,
    required this.isSelected,
    required this.onTap,
  });

  final AdminGrowthChartRange range;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(OpenVtsRadius.sm),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(
            horizontal: OpenVtsSpacing.xs,
            vertical: 5,
          ),
          decoration: BoxDecoration(
            color: isSelected ? OpenVtsColors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(OpenVtsRadius.sm),
            border: isSelected ? Border.all(color: OpenVtsColors.border) : null,
          ),
          child: Text(
            range.label,
            style: OpenVtsTypography.meta.copyWith(
              color: isSelected
                  ? OpenVtsColors.textPrimary
                  : OpenVtsColors.textSecondary,
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _SeriesLegend extends StatelessWidget {
  const _SeriesLegend({required this.label, required this.solid});

  final String label;
  final bool solid;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomPaint(
          size: const Size(18, 8),
          painter: _LegendLinePainter(solid: solid),
        ),
        const SizedBox(width: OpenVtsSpacing.xxs),
        Text(
          label,
          style: OpenVtsTypography.meta.copyWith(
            color: OpenVtsColors.textSecondary,
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _LegendLinePainter extends CustomPainter {
  const _LegendLinePainter({required this.solid});

  final bool solid;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = solid ? OpenVtsColors.brandInk : OpenVtsColors.textTertiary
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    if (solid) {
      canvas.drawLine(Offset(0, size.height / 2),
          Offset(size.width, size.height / 2), paint);
      return;
    }

    var x = 0.0;
    while (x < size.width) {
      canvas.drawLine(
        Offset(x, size.height / 2),
        Offset(math.min(x + 4, size.width), size.height / 2),
        paint,
      );
      x += 7;
    }
  }

  @override
  bool shouldRepaint(covariant _LegendLinePainter oldDelegate) {
    return oldDelegate.solid != solid;
  }
}

class _GrowthEmptyState extends StatelessWidget {
  const _GrowthEmptyState();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: OpenVtsColors.surface,
        borderRadius: BorderRadius.circular(OpenVtsRadius.md),
        border: Border.all(color: OpenVtsColors.border),
      ),
      child: Center(
        child: Text(
          'No growth data yet.',
          style: OpenVtsTypography.meta.copyWith(
            color: OpenVtsColors.textSecondary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _GrowthLineChart extends StatelessWidget {
  const _GrowthLineChart({required this.points});

  final List<AdminMonthGraphPoint> points;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _GrowthLineChartPainter(points: points),
      child: const SizedBox.expand(),
    );
  }
}

class _GrowthLineChartPainter extends CustomPainter {
  const _GrowthLineChartPainter({required this.points});

  final List<AdminMonthGraphPoint> points;

  @override
  void paint(Canvas canvas, Size size) {
    final chartRect = Rect.fromLTWH(36, 14, size.width - 46, size.height - 58);
    final maxValue = _maxValue();
    _paintGrid(canvas, chartRect, maxValue);

    final userOffsets = _offsetsFor(
      points.map((point) => point.userCount).toList(growable: false),
      chartRect,
      maxValue,
    );
    final vehicleOffsets = _offsetsFor(
      points.map((point) => point.vehicleCount).toList(growable: false),
      chartRect,
      maxValue,
    );

    _paintArea(canvas, chartRect, userOffsets);
    _paintSeries(
      canvas,
      userOffsets,
      OpenVtsColors.brandInk,
      dashed: false,
    );
    _paintSeries(
      canvas,
      vehicleOffsets,
      OpenVtsColors.textTertiary,
      dashed: true,
    );
    _paintDots(canvas, userOffsets, OpenVtsColors.brandInk);
    _paintDots(canvas, vehicleOffsets, OpenVtsColors.textTertiary);
    _paintAxisLabels(canvas, chartRect, maxValue);
  }

  int _maxValue() {
    final rawMax = points.fold<int>(
      0,
      (max, point) =>
          math.max(max, math.max(point.userCount, point.vehicleCount)),
    );
    return rawMax <= 0 ? 1 : rawMax;
  }

  void _paintGrid(Canvas canvas, Rect chartRect, int maxValue) {
    final gridPaint = Paint()
      ..color = OpenVtsColors.border.withValues(alpha: 0.9)
      ..strokeWidth = 1;

    for (var index = 0; index <= 4; index++) {
      final y = chartRect.top + chartRect.height * (index / 4);
      canvas.drawLine(
        Offset(chartRect.left, y),
        Offset(chartRect.right, y),
        gridPaint,
      );
    }

    final axisPaint = Paint()
      ..color = OpenVtsColors.border
      ..strokeWidth = 1.1;
    canvas.drawLine(chartRect.bottomLeft, chartRect.bottomRight, axisPaint);
  }

  List<Offset> _offsetsFor(List<int> values, Rect chartRect, int maxValue) {
    return List<Offset>.generate(values.length, (index) {
      final x = values.length == 1
          ? chartRect.left
          : chartRect.left + chartRect.width * (index / (values.length - 1));
      final y =
          chartRect.bottom - chartRect.height * (values[index] / maxValue);
      return Offset(x, y);
    });
  }

  void _paintArea(Canvas canvas, Rect chartRect, List<Offset> offsets) {
    if (offsets.length < 2) {
      return;
    }

    final path = _smoothPath(offsets)
      ..lineTo(offsets.last.dx, chartRect.bottom)
      ..lineTo(offsets.first.dx, chartRect.bottom)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          OpenVtsColors.brandInk.withValues(alpha: 0.08),
          OpenVtsColors.brandInk.withValues(alpha: 0.01),
        ],
      ).createShader(chartRect);
    canvas.drawPath(path, fillPaint);
  }

  void _paintSeries(
    Canvas canvas,
    List<Offset> offsets,
    Color color, {
    required bool dashed,
  }) {
    if (offsets.isEmpty) {
      return;
    }

    final paint = Paint()
      ..color = color
      ..strokeWidth = dashed ? 2 : 2.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final path = _smoothPath(offsets);

    if (dashed) {
      _drawDashedPath(canvas, path, paint);
      return;
    }

    canvas.drawPath(path, paint);
  }

  Path _smoothPath(List<Offset> offsets) {
    final path = Path()..moveTo(offsets.first.dx, offsets.first.dy);
    if (offsets.length == 1) {
      return path;
    }

    for (var index = 0; index < offsets.length - 1; index++) {
      final current = offsets[index];
      final next = offsets[index + 1];
      final controlX = current.dx + (next.dx - current.dx) / 2;
      path.cubicTo(controlX, current.dy, controlX, next.dy, next.dx, next.dy);
    }
    return path;
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint) {
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = math.min(distance + 7, metric.length);
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance += 12;
      }
    }
  }

  void _paintDots(Canvas canvas, List<Offset> offsets, Color color) {
    final paint = Paint()..color = color;
    for (final offset in offsets) {
      canvas.drawCircle(offset, 2.4, paint);
    }
  }

  void _paintAxisLabels(Canvas canvas, Rect chartRect, int maxValue) {
    final labelStyle = OpenVtsTypography.meta.copyWith(
      color: OpenVtsColors.textTertiary,
      fontSize: 10,
    );
    for (var index = 0; index <= 2; index++) {
      final value = (maxValue * (1 - index / 2)).round();
      _paintText(
        canvas,
        _formatCompactNumber(value),
        Offset(0, chartRect.top + chartRect.height * (index / 2) - 8),
        labelStyle,
        maxWidth: 34,
      );
    }

    final shouldRotate = points.length > 8;
    final labelIndexes = shouldRotate
        ? List<int>.generate(points.length, (index) => index)
        : <int>{0, points.length ~/ 2, points.length - 1}.toList();
    for (final index in labelIndexes) {
      final point = points[index];
      final x = points.length == 1
          ? chartRect.left
          : chartRect.left + chartRect.width * (index / (points.length - 1));
      _paintText(
        canvas,
        point.label,
        Offset(x - 16, chartRect.bottom + 10),
        labelStyle,
        maxWidth: 44,
        rotate: shouldRotate,
      );
    }
  }

  void _paintText(
    Canvas canvas,
    String text,
    Offset offset,
    TextStyle style, {
    required double maxWidth,
    bool rotate = false,
  }) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: 1,
      textDirection: ui.TextDirection.ltr,
    )..layout(maxWidth: maxWidth);

    if (!rotate) {
      painter.paint(canvas, offset);
      return;
    }

    canvas.save();
    canvas.translate(offset.dx + 8, offset.dy + 2);
    canvas.rotate(-math.pi / 4);
    painter.paint(canvas, Offset.zero);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _GrowthLineChartPainter oldDelegate) {
    return oldDelegate.points != points;
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: OpenVtsColors.surface,
            borderRadius: BorderRadius.circular(OpenVtsRadius.sm),
            border: Border.all(color: OpenVtsColors.border),
          ),
          child: Icon(icon, size: 16, color: OpenVtsColors.textSecondary),
        ),
        const SizedBox(width: OpenVtsSpacing.xs),
        Flexible(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: OpenVtsTypography.label.copyWith(
              color: OpenVtsColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

String _formatCompactNumber(num value) {
  return NumberFormat.compact(locale: 'en_IN').format(value);
}
