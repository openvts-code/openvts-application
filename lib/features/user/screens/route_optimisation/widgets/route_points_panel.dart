import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/open_vts_colors.dart';
import '../../../../../core/theme/open_vts_radius.dart';
import '../../../../../core/theme/open_vts_spacing.dart';
import '../../../../../core/theme/open_vts_typography.dart';
import '../../../../../shared/widgets/open_vts_empty_state.dart';
import '../../../controllers/user_providers.dart';
import '../../../controllers/user_route_optimisation_controller.dart';
import '../../../models/user_route_optimisation_model.dart';
import '../../../models/user_route_optimisation_state.dart';
import 'add_lat_lng_point_sheet.dart';
import 'add_route_point_sheet.dart';
import 'clear_points_confirm_sheet.dart';
import 'edit_route_point_sheet.dart';
import 'route_point_card.dart';
import 'select_landmarks_sheet.dart';

/// Self-contained Points pane for the Route Optimisation screen.
///
/// Owns: header (count + round-trip toggle), action bar (Add / Optimise /
/// Apply / Clear), and a reorderable list of [RoutePointCard]s. The screen
/// remains responsible for tab navigation, so [onTapOnMapRequested] is
/// invoked when the user picks "Tap on map" from the add-point sheet.
class RoutePointsPanel extends ConsumerWidget {
  const RoutePointsPanel({
    required this.onTapOnMapRequested,
    super.key,
  });

  /// Called when the user selects "Tap on map" from the add-point sheet so
  /// the screen can switch to the Map tab.
  final VoidCallback onTapOnMapRequested;

  Future<void> _openAddFlow(
    BuildContext context,
    UserRouteOptimisationController controller,
  ) async {
    final choice = await showAddRoutePointSheet(context);
    if (choice == null || !context.mounted) return;
    switch (choice) {
      case AddPointChoice.landmarks:
        await showSelectLandmarksSheet(context);
        break;
      case AddPointChoice.latLng:
        final r = await showAddLatLngPointSheet(context);
        if (r != null) {
          controller.addManualPoint(name: r.name, lat: r.lat, lon: r.lon);
        }
        break;
      case AddPointChoice.mapTap:
        controller.setClickToAddMode(true);
        onTapOnMapRequested();
        break;
    }
  }

  Future<void> _editPoint(
    BuildContext context,
    UserRouteOptimisationController controller,
    int index,
    RouteOptimisationPoint point,
  ) async {
    final r = await showEditRoutePointSheet(context, point: point);
    if (r == null) return;
    controller.updatePoint(
      index,
      point.copyWith(name: r.name, lat: r.lat, lon: r.lon),
    );
  }

  Future<void> _clearAll(
    BuildContext context,
    UserRouteOptimisationController controller,
    UserRouteOptimisationState state,
  ) async {
    final ok = await showClearPointsConfirmSheet(
      context,
      pointCount: state.points.length,
      hasResult: state.hasResult,
    );
    if (ok) controller.clearAll();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(userRouteOptimisationControllerProvider);
    final controller =
        ref.read(userRouteOptimisationControllerProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Header(
          count: state.points.length,
          roundTrip: state.constraints.roundTrip,
          onToggleRoundTrip: controller.toggleRoundTrip,
        ),
        const SizedBox(height: OpenVtsSpacing.xs),
        _ActionRow(
          canOptimise: state.canOptimise,
          isOptimising: state.isOptimising,
          hasResult: state.hasResult,
          canClear: state.points.isNotEmpty || state.hasResult,
          onAdd: () => _openAddFlow(context, controller),
          onOptimise: controller.optimise,
          onApplyOptimized: controller.applyOptimisedOrder,
          onClear: () => _clearAll(context, controller, state),
        ),
        const SizedBox(height: OpenVtsSpacing.sm),
        const Divider(height: 1, color: OpenVtsColors.border),
        Expanded(
          child: state.points.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(OpenVtsSpacing.lg),
                  child: OpenVtsEmptyState(
                    title: 'No stops yet',
                    message: 'Add a point to start planning your route.',
                  ),
                )
              : _PointsList(
                  state: state,
                  controller: controller,
                  onEdit: (i, p) => _editPoint(context, controller, i, p),
                ),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.count,
    required this.roundTrip,
    required this.onToggleRoundTrip,
  });

  final int count;
  final bool roundTrip;
  final VoidCallback onToggleRoundTrip;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: OpenVtsSpacing.xs,
      ),
      child: Row(
        children: [
          const Text('Stops', style: OpenVtsTypography.titleSmall),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 6,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: OpenVtsColors.surface,
              borderRadius: BorderRadius.circular(OpenVtsRadius.pill),
              border: Border.all(color: OpenVtsColors.border),
            ),
            child: Text(
              '$count',
              style: OpenVtsTypography.meta.copyWith(
                color: OpenVtsColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const Spacer(),
          _RoundTripPill(
            active: roundTrip,
            onTap: onToggleRoundTrip,
          ),
        ],
      ),
    );
  }
}

class _RoundTripPill extends StatelessWidget {
  const _RoundTripPill({required this.active, required this.onTap});

  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bg = active ? OpenVtsColors.brandInk : OpenVtsColors.surfaceElevated;
    final fg = active ? OpenVtsColors.white : OpenVtsColors.textSecondary;
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(OpenVtsRadius.pill),
      child: InkWell(
        borderRadius: BorderRadius.circular(OpenVtsRadius.pill),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(OpenVtsRadius.pill),
            border: Border.all(
              color: active ? OpenVtsColors.brandInk : OpenVtsColors.border,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.loop, size: 12, color: fg),
              const SizedBox(width: 4),
              Text(
                'Round trip',
                style: OpenVtsTypography.meta.copyWith(
                  color: fg,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.canOptimise,
    required this.isOptimising,
    required this.hasResult,
    required this.canClear,
    required this.onAdd,
    required this.onOptimise,
    required this.onApplyOptimized,
    required this.onClear,
  });

  final bool canOptimise;
  final bool isOptimising;
  final bool hasResult;
  final bool canClear;
  final VoidCallback onAdd;
  final VoidCallback onOptimise;
  final VoidCallback onApplyOptimized;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _PrimaryAction(
            icon: Icons.add,
            label: 'Add point',
            onPressed: onAdd,
          ),
          const SizedBox(width: 6),
          _SecondaryAction(
            icon: Icons.auto_awesome_outlined,
            label: isOptimising ? 'Optimising…' : 'Optimise',
            onPressed: canOptimise && !isOptimising ? onOptimise : null,
          ),
          if (hasResult) ...[
            const SizedBox(width: 6),
            _SecondaryAction(
              icon: Icons.playlist_add_check_outlined,
              label: 'Apply order',
              onPressed: onApplyOptimized,
            ),
          ],
          const SizedBox(width: 6),
          _SubtleAction(
            icon: Icons.delete_sweep_outlined,
            label: 'Clear',
            onPressed: canClear ? onClear : null,
          ),
        ],
      ),
    );
  }
}

class _PrimaryAction extends StatelessWidget {
  const _PrimaryAction({
    required this.icon,
    required this.label,
    required this.onPressed,
  });
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 14),
      label: Text(label, style: OpenVtsTypography.label),
      style: ElevatedButton.styleFrom(
        backgroundColor: OpenVtsColors.brandInk,
        foregroundColor: OpenVtsColors.white,
        minimumSize: const Size(0, 36),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(OpenVtsRadius.button),
        ),
      ),
    );
  }
}

class _SecondaryAction extends StatelessWidget {
  const _SecondaryAction({
    required this.icon,
    required this.label,
    required this.onPressed,
  });
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 14),
      label: Text(label, style: OpenVtsTypography.label),
      style: OutlinedButton.styleFrom(
        foregroundColor: OpenVtsColors.textPrimary,
        side: const BorderSide(color: OpenVtsColors.border),
        minimumSize: const Size(0, 36),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(OpenVtsRadius.button),
        ),
      ),
    );
  }
}

class _SubtleAction extends StatelessWidget {
  const _SubtleAction({
    required this.icon,
    required this.label,
    required this.onPressed,
  });
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 14),
      label: Text(label, style: OpenVtsTypography.label),
      style: TextButton.styleFrom(
        foregroundColor: OpenVtsColors.textSecondary,
        minimumSize: const Size(0, 36),
        padding: const EdgeInsets.symmetric(horizontal: 8),
      ),
    );
  }
}

class _PointsList extends StatelessWidget {
  const _PointsList({
    required this.state,
    required this.controller,
    required this.onEdit,
  });

  final UserRouteOptimisationState state;
  final UserRouteOptimisationController controller;
  final void Function(int index, RouteOptimisationPoint point) onEdit;

  @override
  Widget build(BuildContext context) {
    final points = state.points;
    final effectiveEnd = state.effectiveEndIndex;
    return ReorderableListView.builder(
      buildDefaultDragHandles: false,
      padding: const EdgeInsets.symmetric(
        horizontal: 2,
        vertical: OpenVtsSpacing.xs,
      ),
      itemCount: points.length,
      onReorder: controller.reorderPoint,
      proxyDecorator: (child, _, __) => Material(
        color: Colors.transparent,
        child: child,
      ),
      itemBuilder: (context, i) {
        final p = points[i];
        final isStart = i == state.constraints.startIndex;
        final isEnd = i == effectiveEnd;
        final endSet = state.constraints.endIndex != -1;
        return Padding(
          key: ValueKey(p.id),
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: RoutePointCard(
            index: i,
            point: p,
            isStart: isStart,
            isEnd: isEnd,
            totalCount: points.length,
            isSelected: state.selectedPointIndex == i,
            onTap: () => controller.setSelectedPointIndex(
              state.selectedPointIndex == i ? null : i,
            ),
            onEdit: () => onEdit(i, p),
            onDelete: () => controller.deletePoint(i),
            onSetStart: () => controller.setStartIndex(i),
            onSetEnd: () => controller.setEndIndex(i),
            onClearEnd: endSet ? () => controller.setEndIndex(-1) : null,
            onMoveUp: i > 0 ? () => controller.reorderPoint(i, i - 1) : null,
            onMoveDown: i < points.length - 1
                ? () => controller.reorderPoint(i, i + 2)
                : null,
            dragHandle: ReorderableDragStartListener(
              index: i,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Icon(
                  Icons.drag_indicator,
                  size: 16,
                  color: OpenVtsColors.textTertiary,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
