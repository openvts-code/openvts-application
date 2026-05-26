import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../core/theme/open_vts_colors.dart';
import '../../../../../core/theme/open_vts_spacing.dart';
import '../../../../../core/theme/open_vts_typography.dart';
import '../../../../../shared/widgets/open_vts_card.dart';
import '../../../../../shared/widgets/open_vts_empty_state.dart';
import '../../../models/superadmin_payments_model.dart';

class PaymentsRevenueTrendChart extends StatelessWidget {
  const PaymentsRevenueTrendChart({
    required this.analytics,
    super.key,
  });

  final SuperadminTransactionsAnalytics analytics;

  @override
  Widget build(BuildContext context) {
    final points = _resolveTrendPoints(analytics);

    return OpenVtsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Revenue Trend',
            style: OpenVtsTypography.titleSmall.copyWith(
              color: OpenVtsColors.textPrimary,
            ),
          ),
          const SizedBox(height: OpenVtsSpacing.xxs),
          Text(
            'Daily totals for selected range',
            style: OpenVtsTypography.meta.copyWith(
              color: OpenVtsColors.textSecondary,
            ),
          ),
          const SizedBox(height: OpenVtsSpacing.sm),
          if (points.isEmpty)
            const OpenVtsEmptyState(
              title: 'No trend data',
              message: 'Daily revenue points are not available for this range.',
            )
          else
            _TrendChartBody(points: points),
        ],
      ),
    );
  }

  List<_TrendPoint> _resolveTrendPoints(SuperadminTransactionsAnalytics model) {
    if (model.dailySeriesByCurrency.isEmpty) {
      return const <_TrendPoint>[];
    }

    final series = model.dailySeriesByCurrency.first;
    if (series.points.isEmpty) {
      return const <_TrendPoint>[];
    }

    final points = series.points
        .map(
          (point) => _TrendPoint(
            date: point.dateTime ?? DateTime.tryParse(point.date),
            dateRaw: point.date,
            value: point.totalAmountAsDouble ?? 0,
          ),
        )
        .toList(growable: false)
      ..sort((left, right) {
        final leftDate = left.date;
        final rightDate = right.date;
        if (leftDate != null && rightDate != null) {
          return leftDate.compareTo(rightDate);
        }

        return left.dateRaw.compareTo(right.dateRaw);
      });

    return points;
  }
}

class _TrendChartBody extends StatelessWidget {
  const _TrendChartBody({required this.points});

  final List<_TrendPoint> points;

  @override
  Widget build(BuildContext context) {
    final yAxisValues = _computeYAxisValues(points);

    return Column(
      children: [
        SizedBox(
          height: 166,
          child: Row(
            children: [
              SizedBox(
                width: 38,
                child: _YAxisLabels(values: yAxisValues),
              ),
              const SizedBox(width: OpenVtsSpacing.xs),
              Expanded(
                child: CustomPaint(
                  painter: _RevenueTrendPainter(
                    points: points,
                    maxValue: yAxisValues.last,
                  ),
                  child: const SizedBox.expand(),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: OpenVtsSpacing.xs),
        _XAxisLabels(points: points),
      ],
    );
  }

  List<double> _computeYAxisValues(List<_TrendPoint> points) {
    var highest = 0.0;
    for (final point in points) {
      highest = math.max(highest, point.value);
    }

    final maxValue = _niceCeiling(highest);
    const divisions = 4;

    return List<double>.generate(
      divisions + 1,
      (index) => (maxValue / divisions) * index,
      growable: false,
    );
  }

  double _niceCeiling(double value) {
    if (value <= 0) {
      return 1;
    }

    final exponent = math.pow(10, (math.log(value) / math.ln10).floor());
    final magnitude = exponent.toDouble();
    final normalized = value / magnitude;

    final snapped = normalized <= 1
        ? 1
        : normalized <= 2
            ? 2
            : normalized <= 2.5
                ? 2.5
                : normalized <= 5
                    ? 5
                    : 10;

    return snapped * magnitude;
  }
}

class _RevenueTrendPainter extends CustomPainter {
  const _RevenueTrendPainter({
    required this.points,
    required this.maxValue,
  });

  final List<_TrendPoint> points;
  final double maxValue;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) {
      return;
    }

    final plotRect = Rect.fromLTWH(0, 0, size.width, size.height);
    _drawGrid(canvas, plotRect);

    if (points.length < 2) {
      _drawSinglePoint(canvas, plotRect);
      return;
    }

    final offsets = _mapToOffsets(plotRect);
    final linePath = _buildSmoothPath(offsets, plotRect);

    final areaPath = Path.from(linePath)
      ..lineTo(offsets.last.dx, plotRect.bottom)
      ..lineTo(offsets.first.dx, plotRect.bottom)
      ..close();

    canvas.drawPath(
      areaPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            OpenVtsColors.textSecondary.withValues(alpha: 0.16),
            OpenVtsColors.textSecondary.withValues(alpha: 0.02),
          ],
        ).createShader(plotRect),
    );

    canvas.drawPath(
      linePath,
      Paint()
        ..color = OpenVtsColors.textPrimary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    final lastPoint = offsets.last;
    canvas.drawCircle(
      lastPoint,
      5,
      Paint()..color = OpenVtsColors.white,
    );
    canvas.drawCircle(
      lastPoint,
      3,
      Paint()..color = OpenVtsColors.textPrimary,
    );
  }

  @override
  bool shouldRepaint(covariant _RevenueTrendPainter oldDelegate) {
    return oldDelegate.points != points || oldDelegate.maxValue != maxValue;
  }

  void _drawGrid(Canvas canvas, Rect rect) {
    final paint = Paint()
      ..color = OpenVtsColors.border.withValues(alpha: 0.85)
      ..strokeWidth = 1;

    const horizontalLines = 4;
    for (var index = 0; index <= horizontalLines; index++) {
      final y = rect.top + (rect.height * index / horizontalLines);
      _drawDashedLine(
          canvas, Offset(rect.left, y), Offset(rect.right, y), paint);
    }
  }

  void _drawSinglePoint(Canvas canvas, Rect rect) {
    final offset = _mapValueToOffset(
      rect,
      index: 0,
      total: 1,
      value: points.first.value,
    );

    canvas.drawCircle(
      offset,
      3,
      Paint()..color = OpenVtsColors.textPrimary,
    );
  }

  List<Offset> _mapToOffsets(Rect rect) {
    return List<Offset>.generate(
      points.length,
      (index) => _mapValueToOffset(
        rect,
        index: index,
        total: points.length,
        value: points[index].value,
      ),
      growable: false,
    );
  }

  Offset _mapValueToOffset(
    Rect rect, {
    required int index,
    required int total,
    required double value,
  }) {
    final safeMax = maxValue <= 0 ? 1 : maxValue;
    final x =
        total <= 1 ? rect.left : rect.left + (rect.width * index / (total - 1));
    final y = rect.bottom - ((value / safeMax) * rect.height);

    return Offset(x, y.clamp(rect.top, rect.bottom));
  }

  Path _buildSmoothPath(List<Offset> points, Rect bounds) {
    final path = Path()..moveTo(points.first.dx, points.first.dy);

    for (var index = 0; index < points.length - 1; index++) {
      final previous = index == 0 ? points[index] : points[index - 1];
      final current = points[index];
      final next = points[index + 1];
      final afterNext = index + 2 < points.length ? points[index + 2] : next;

      final control1 = Offset(
        current.dx + (next.dx - previous.dx) / 6,
        (current.dy + (next.dy - previous.dy) / 6)
            .clamp(bounds.top, bounds.bottom),
      );
      final control2 = Offset(
        next.dx - (afterNext.dx - current.dx) / 6,
        (next.dy - (afterNext.dy - current.dy) / 6)
            .clamp(bounds.top, bounds.bottom),
      );

      path.cubicTo(
        control1.dx,
        control1.dy,
        control2.dx,
        control2.dy,
        next.dx,
        next.dy,
      );
    }

    return path;
  }

  void _drawDashedLine(
    Canvas canvas,
    Offset start,
    Offset end,
    Paint paint,
  ) {
    const dashWidth = 5.0;
    const dashSpace = 4.0;

    final distance = (end - start).distance;
    if (distance <= 0) {
      return;
    }

    final direction = (end - start) / distance;
    var traveled = 0.0;

    while (traveled < distance) {
      final dashStart = start + direction * traveled;
      final dashEnd =
          start + direction * math.min(traveled + dashWidth, distance);
      canvas.drawLine(dashStart, dashEnd, paint);
      traveled += dashWidth + dashSpace;
    }
  }
}

class _YAxisLabels extends StatelessWidget {
  const _YAxisLabels({required this.values});

  final List<double> values;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: values.reversed
          .map(
            (value) => Text(
              _formatCompactNumber(value),
              textAlign: TextAlign.end,
              style: OpenVtsTypography.meta.copyWith(
                color: OpenVtsColors.textTertiary,
                fontSize: 10,
              ),
            ),
          )
          .toList(growable: false),
    );
  }

  String _formatCompactNumber(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(value >= 10000000 ? 0 : 1)}M';
    }

    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(value >= 10000 ? 0 : 1)}K';
    }

    if (value == value.roundToDouble()) {
      return value.round().toString();
    }

    return value.toStringAsFixed(1);
  }
}

class _XAxisLabels extends StatelessWidget {
  const _XAxisLabels({required this.points});

  final List<_TrendPoint> points;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return const SizedBox.shrink();
    }

    final labels = _sampleLabels(points, maxLabels: 4);

    return Row(
      children: labels
          .map(
            (item) => Expanded(
              child: Text(
                item,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: labels.first == item
                    ? TextAlign.left
                    : labels.last == item
                        ? TextAlign.right
                        : TextAlign.center,
                style: OpenVtsTypography.meta.copyWith(
                  color: OpenVtsColors.textSecondary,
                  fontSize: 11,
                ),
              ),
            ),
          )
          .toList(growable: false),
    );
  }

  List<String> _sampleLabels(List<_TrendPoint> source,
      {required int maxLabels}) {
    if (source.length <= maxLabels) {
      return source.map(_shortLabel).toList(growable: false);
    }

    final output = <String>[];
    final step = (source.length - 1) / (maxLabels - 1);

    for (var i = 0; i < maxLabels; i++) {
      final index = (i * step).round().clamp(0, source.length - 1);
      output.add(_shortLabel(source[index]));
    }

    return output;
  }

  String _shortLabel(_TrendPoint point) {
    final date = point.date;
    if (date != null) {
      return DateFormat('dd MMM').format(date.toLocal());
    }

    final parsed = DateTime.tryParse(point.dateRaw);
    if (parsed != null) {
      return DateFormat('dd MMM').format(parsed.toLocal());
    }

    return point.dateRaw.trim().isEmpty ? '-' : point.dateRaw.trim();
  }
}

class _TrendPoint {
  const _TrendPoint({
    required this.date,
    required this.dateRaw,
    required this.value,
  });

  final DateTime? date;
  final String dateRaw;
  final double value;
}
