import 'package:flutter/material.dart';

import '../../../../../../core/theme/open_vts_colors.dart';
import '../../../../../../core/theme/open_vts_radius.dart';
import '../../../../../../core/theme/open_vts_spacing.dart';
import '../../../../../../core/theme/open_vts_typography.dart';
import '../../../../models/user_drivers_state.dart';

class UserDriversSummaryStrip extends StatelessWidget {
  const UserDriversSummaryStrip({
    required this.state,
    super.key,
  });

  final UserDriversState state;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _SummaryPill(
            label: 'Active',
            value: state.activeCount,
            color: OpenVtsColors.success,
          ),
          const SizedBox(width: OpenVtsSpacing.xs),
          _SummaryPill(
            label: 'Inactive',
            value: state.inactiveCount,
            color: OpenVtsColors.textSecondary,
          ),
          const SizedBox(width: OpenVtsSpacing.xs),
          _SummaryPill(
            label: 'Assigned',
            value: state.assignedCount,
            color: OpenVtsColors.info,
          ),
          const SizedBox(width: OpenVtsSpacing.xs),
          _SummaryPill(
            label: 'Verified',
            value: state.verifiedCount,
            color: OpenVtsColors.brandInk,
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
        color: color.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(OpenVtsRadius.pill),
        border: Border.all(color: color.withValues(alpha: 0.18)),
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
