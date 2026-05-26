import 'package:flutter/material.dart';

import '../../../../../core/theme/open_vts_colors.dart';
import '../../../../../core/theme/open_vts_radius.dart';
import '../../../../../core/theme/open_vts_spacing.dart';
import '../../../../../core/theme/open_vts_typography.dart';
import '../../../../../shared/widgets/open_vts_status_chip.dart';
import '../../../models/user_route_optimisation_state.dart';

/// Compact, non-hero header for the Route Optimisation page.
///
/// Renders a single line of subtitle plus a muted status chip on the right
/// describing the current pipeline phase. No hero, no oversized typography.
class RouteOptimisationHeader extends StatelessWidget {
  const RouteOptimisationHeader({required this.state, super.key});

  final UserRouteOptimisationState state;

  @override
  Widget build(BuildContext context) {
    final stopsCount = state.points.length;
    final stopsSummary = stopsCount == 0
        ? 'No stops yet'
        : '$stopsCount stop${stopsCount == 1 ? '' : 's'}'
            '${state.roundTrip ? ' • round trip' : ''}';

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: OpenVtsSpacing.sm,
        vertical: OpenVtsSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: OpenVtsColors.surfaceElevated,
        borderRadius: BorderRadius.circular(OpenVtsRadius.md),
        border: Border.all(color: OpenVtsColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Plan multi-stop routes',
                  style: OpenVtsTypography.label.copyWith(
                    color: OpenVtsColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  stopsSummary,
                  style: OpenVtsTypography.meta.copyWith(
                    color: OpenVtsColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: OpenVtsSpacing.xs),
          _StatusChip(state: state),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.state});

  final UserRouteOptimisationState state;

  @override
  Widget build(BuildContext context) {
    if (state.isSavingRoute) {
      return const OpenVtsStatusChip(
        label: 'Saving…',
        type: OpenVtsStatusType.info,
      );
    }
    if (state.isOptimising) {
      return const OpenVtsStatusChip(
        label: 'Optimising…',
        type: OpenVtsStatusType.info,
      );
    }
    if (state.isFetchingRoadGeometry) {
      return const OpenVtsStatusChip(
        label: 'Mapping roads…',
        type: OpenVtsStatusType.info,
      );
    }
    if (state.hasResult) {
      return const OpenVtsStatusChip(
        label: 'Optimised',
        type: OpenVtsStatusType.success,
      );
    }
    if (state.canOptimise) {
      return const OpenVtsStatusChip(
        label: 'Ready',
        type: OpenVtsStatusType.neutral,
      );
    }
    return const OpenVtsStatusChip(
      label: 'Add 2+ stops',
      type: OpenVtsStatusType.neutral,
    );
  }
}
