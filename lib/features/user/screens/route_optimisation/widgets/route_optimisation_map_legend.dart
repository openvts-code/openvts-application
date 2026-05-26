import 'package:flutter/material.dart';

import '../../../../../core/theme/open_vts_colors.dart';
import '../../../../../core/theme/open_vts_radius.dart';
import '../../../../../core/theme/open_vts_spacing.dart';
import '../../../../../core/theme/open_vts_typography.dart';

/// Compact, surface-elevated legend for the route map.
///
/// Always shows the three marker roles. When [hasResult] is `true`, also
/// shows the line legend (Original / Optimised) so users can decode the
/// dashed-vs-solid polylines.
class RouteOptimisationMapLegend extends StatelessWidget {
  const RouteOptimisationMapLegend({
    required this.hasResult,
    required this.roundTrip,
    super.key,
  });

  final bool hasResult;
  final bool roundTrip;

  @override
  Widget build(BuildContext context) {
    final items = <Widget>[
      const _DotItem(color: OpenVtsColors.brandInk, label: 'Start'),
      if (!roundTrip) const _DotItem(color: OpenVtsColors.info, label: 'End'),
      const _DotItem(
        color: OpenVtsColors.surfaceElevated,
        outline: OpenVtsColors.border,
        label: 'Stop',
      ),
      if (hasResult) ...[
        const _LineItem(
          color: OpenVtsColors.textTertiary,
          label: 'Original',
          dashed: true,
        ),
        const _LineItem(
          color: OpenVtsColors.brandInk,
          label: 'Optimised',
        ),
      ],
    ];

    return DecoratedBox(
      decoration: BoxDecoration(
        color: OpenVtsColors.surfaceElevated.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(OpenVtsRadius.md),
        border: Border.all(color: OpenVtsColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 6,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: OpenVtsSpacing.xs,
          vertical: 6,
        ),
        child: Wrap(
          spacing: OpenVtsSpacing.sm,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: items,
        ),
      ),
    );
  }
}

class _DotItem extends StatelessWidget {
  const _DotItem({required this.color, required this.label, this.outline});

  final Color color;
  final Color? outline;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border:
                outline == null ? null : Border.all(color: outline!, width: 1),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: OpenVtsTypography.meta.copyWith(
            color: OpenVtsColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _LineItem extends StatelessWidget {
  const _LineItem({
    required this.color,
    required this.label,
    this.dashed = false,
  });

  final Color color;
  final String label;
  final bool dashed;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 18,
          height: 6,
          child: CustomPaint(
            painter: _LinePainter(color: color, dashed: dashed),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: OpenVtsTypography.meta.copyWith(
            color: OpenVtsColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _LinePainter extends CustomPainter {
  _LinePainter({required this.color, required this.dashed});
  final Color color;
  final bool dashed;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    final y = size.height / 2;
    if (!dashed) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
      return;
    }
    const dash = 3.0;
    const gap = 2.5;
    double x = 0;
    while (x < size.width) {
      final end = (x + dash).clamp(0.0, size.width);
      canvas.drawLine(Offset(x, y), Offset(end, y), paint);
      x += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _LinePainter old) =>
      old.color != color || old.dashed != dashed;
}
