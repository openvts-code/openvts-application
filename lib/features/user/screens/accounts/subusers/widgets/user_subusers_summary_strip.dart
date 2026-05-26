import 'package:flutter/material.dart';

import '../../../../../../core/theme/open_vts_colors.dart';
import '../../../../../../core/theme/open_vts_radius.dart';
import '../../../../../../core/theme/open_vts_spacing.dart';
import '../../../../../../core/theme/open_vts_typography.dart';

class UserSubUsersSummaryStrip extends StatelessWidget {
  const UserSubUsersSummaryStrip({
    required this.totalLoaded,
    required this.totalRemote,
    required this.activeCount,
    required this.inactiveCount,
    super.key,
  });

  final int totalLoaded;
  final int totalRemote;
  final int activeCount;
  final int inactiveCount;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _SummaryPill(
            label: 'Loaded',
            value: totalLoaded,
            color: OpenVtsColors.brandInk,
          ),
          const SizedBox(width: OpenVtsSpacing.xs),
          _SummaryPill(
            label: 'Total',
            value: totalRemote,
            color: OpenVtsColors.info,
          ),
          const SizedBox(width: OpenVtsSpacing.xs),
          _SummaryPill(
            label: 'Active',
            value: activeCount,
            color: OpenVtsColors.textSecondary,
          ),
          const SizedBox(width: OpenVtsSpacing.xs),
          _SummaryPill(
            label: 'Inactive',
            value: inactiveCount,
            color: OpenVtsColors.textTertiary,
          ),
        ],
      ),
    );
  }
}

class _SummaryPill extends StatelessWidget {
  const _SummaryPill({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(OpenVtsRadius.pill),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$value',
            style: OpenVtsTypography.meta.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: OpenVtsTypography.meta.copyWith(
              color: OpenVtsColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
