import 'package:flutter/material.dart';

import '../../../../../core/theme/open_vts_colors.dart';
import '../../../../../core/theme/open_vts_radius.dart';
import '../../../../../core/theme/open_vts_spacing.dart';
import '../../../../../core/theme/open_vts_typography.dart';
import '../../../models/user_route_optimisation_model.dart';

/// Compact 2-up grid of summary metrics for an optimisation result.
///
/// Designed to fit on a phone without horizontal scroll: six tiles wrap into
/// three rows of two. Uses muted surfaces and small fonts deliberately —
/// this is a status read-out, not a hero stat.
class RouteOptimisationMetricStrip extends StatelessWidget {
  const RouteOptimisationMetricStrip({
    required this.result,
    super.key,
  });

  final RouteOptimisationResult result;

  String get _savedLabel {
    final saved = result.originalDistanceKm - result.optimizedDistanceKm;
    final clamped = saved < 0 ? 0.0 : saved;
    return '${clamped.toStringAsFixed(2)} km';
  }

  String get _improvementLabel {
    final pct = result.improvementPct;
    if (pct <= 0) return '0%';
    return '−${pct.toStringAsFixed(1)}%';
  }

  String get _timeLabel {
    final ms = result.processingMs;
    if (ms < 1000) return '${ms.toStringAsFixed(0)} ms';
    return '${(ms / 1000).toStringAsFixed(2)} s';
  }

  @override
  Widget build(BuildContext context) {
    final tiles = <Widget>[
      _MetricTile(
        label: 'Original',
        value: '${result.originalDistanceKm.toStringAsFixed(2)} km',
      ),
      _MetricTile(
        label: 'Optimised',
        value: '${result.optimizedDistanceKm.toStringAsFixed(2)} km',
        emphasis: true,
      ),
      _MetricTile(label: 'Saved', value: _savedLabel),
      _MetricTile(label: 'Improvement', value: _improvementLabel),
      _MetricTile(label: 'Algorithm', value: result.algorithmUsed, wide: true),
      _MetricTile(label: 'Time', value: _timeLabel),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final cols = width >= 520 ? 3 : 2;
        final spacing = OpenVtsSpacing.xs;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final t in tiles)
              SizedBox(
                width: (width - spacing * (cols - 1)) / cols,
                child: t,
              ),
          ],
        );
      },
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    this.emphasis = false,
    this.wide = false,
  });

  final String label;
  final String value;
  final bool emphasis;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: OpenVtsSpacing.xs,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color:
            emphasis ? OpenVtsColors.brandInk : OpenVtsColors.surfaceElevated,
        borderRadius: BorderRadius.circular(OpenVtsRadius.sm),
        border: Border.all(
          color: emphasis ? OpenVtsColors.brandInk : OpenVtsColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label.toUpperCase(),
            style: OpenVtsTypography.meta.copyWith(
              color: emphasis
                  ? OpenVtsColors.white.withValues(alpha: 0.8)
                  : OpenVtsColors.textTertiary,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: wide ? 2 : 1,
            overflow: TextOverflow.ellipsis,
            style: OpenVtsTypography.label.copyWith(
              color: emphasis ? OpenVtsColors.white : OpenVtsColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
