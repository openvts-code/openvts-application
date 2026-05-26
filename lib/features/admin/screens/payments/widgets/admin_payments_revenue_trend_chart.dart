import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../../core/theme/open_vts_colors.dart';
import '../../../../../core/theme/open_vts_spacing.dart';
import '../../../../../core/theme/open_vts_typography.dart';
import '../../../../../shared/widgets/open_vts_card.dart';
import '../../../../../shared/widgets/open_vts_empty_state.dart';
import '../../../models/admin_payments_model.dart';

class AdminPaymentsRevenueTrendChart extends StatelessWidget {
  const AdminPaymentsRevenueTrendChart({required this.analytics, super.key});

  final AdminPaymentsAnalytics analytics;

  @override
  Widget build(BuildContext context) {
    final points = analytics.dailySeriesByCurrency.isEmpty
        ? const <AdminDailyPoint>[]
        : [...analytics.dailySeriesByCurrency.first.points]
      ..sort((a, b) => (a.dateTime ?? DateTime(1970))
          .compareTo(b.dateTime ?? DateTime(1970)));

    return OpenVtsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Revenue Trend', style: OpenVtsTypography.titleSmall),
          const SizedBox(height: OpenVtsSpacing.xxs),
          Text('Daily totals for selected range',
              style: OpenVtsTypography.meta
                  .copyWith(color: OpenVtsColors.textSecondary)),
          const SizedBox(height: OpenVtsSpacing.sm),
          if (points.isEmpty)
            const OpenVtsEmptyState(
              title: 'No trend data',
              message: 'Daily revenue points are not available for this range.',
            )
          else
            SizedBox(
              height: 150,
              child: CustomPaint(
                painter: _TrendPainter(points),
                child: const SizedBox.expand(),
              ),
            ),
        ],
      ),
    );
  }
}

class _TrendPainter extends CustomPainter {
  _TrendPainter(this.points);

  final List<AdminDailyPoint> points;

  @override
  void paint(Canvas canvas, Size size) {
    final values =
        points.map((e) => e.totalAmountValue).toList(growable: false);
    final maxValue = values.fold<double>(0, (p, c) => math.max(p, c));
    final safeMax = maxValue <= 0 ? 1 : maxValue;

    final grid = Paint()
      ..color = OpenVtsColors.border.withValues(alpha: 0.7)
      ..strokeWidth = 1;
    for (var i = 0; i <= 4; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    final line = Paint()
      ..color = OpenVtsColors.textPrimary
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final x = values.length == 1 ? 0.0 : size.width * i / (values.length - 1);
      final y = size.height - (values[i] / safeMax) * size.height;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, line);
  }

  @override
  bool shouldRepaint(covariant _TrendPainter oldDelegate) =>
      oldDelegate.points != points;
}
