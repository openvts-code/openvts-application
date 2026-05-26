import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/open_vts_colors.dart';
import '../../../../../core/theme/open_vts_radius.dart';
import '../../../../../core/theme/open_vts_spacing.dart';
import '../../../../../core/theme/open_vts_typography.dart';
import '../../../../../shared/widgets/open_vts_bottom_sheet.dart';
import '../../../../../shared/widgets/open_vts_empty_state.dart';
import '../../../controllers/user_providers.dart';
import '../../../models/user_route_optimisation_model.dart';
import '../../../models/user_route_optimisation_state.dart';

/// Multi-select landmark picker (POIs / Geofences) backed by
/// `UserRouteOptimisationController.loadLandmarks()`.
///
/// Returns the number of points the user added. Already-added landmarks are
/// shown as disabled rows so users can see what's already in the workspace.
Future<int?> showSelectLandmarksSheet(BuildContext context) {
  return OpenVtsBottomSheet.show<int>(
    context: context,
    title: 'Select landmarks',
    initialChildSize: 0.78,
    minChildSize: 0.5,
    maxChildSize: 0.95,
    draggableChildBuilder: (context, scrollController) {
      return _SelectLandmarksBody(scrollController: scrollController);
    },
  );
}

class _SelectLandmarksBody extends ConsumerStatefulWidget {
  const _SelectLandmarksBody({required this.scrollController});

  final ScrollController scrollController;

  @override
  ConsumerState<_SelectLandmarksBody> createState() =>
      _SelectLandmarksBodyState();
}

class _SelectLandmarksBodyState extends ConsumerState<_SelectLandmarksBody> {
  final _search = TextEditingController();
  final _selected = <String, RouteOptimisationPoint>{};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref
          .read(userRouteOptimisationControllerProvider.notifier)
          .loadLandmarks();
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _toggle(RouteOptimisationPoint p, bool checked) {
    setState(() {
      if (checked) {
        _selected[p.id] = p;
      } else {
        _selected.remove(p.id);
      }
    });
  }

  Future<void> _confirm() async {
    if (_selected.isEmpty) {
      Navigator.of(context).pop(0);
      return;
    }
    final toAdd = _selected.values.toList(growable: false);
    ref.read(userRouteOptimisationControllerProvider.notifier).addPoints(toAdd);
    if (!mounted) return;
    Navigator.of(context).pop(toAdd.length);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(userRouteOptimisationControllerProvider);
    final controller =
        ref.read(userRouteOptimisationControllerProvider.notifier);
    final tab = state.selectedLandmarkTypeTab;
    final source = tab == LandmarkTypeTab.poi
        ? state.landmarkPois
        : state.landmarkGeofences;
    final query = state.landmarkSearchQuery.trim().toLowerCase();
    final filtered = query.isEmpty
        ? source
        : source
            .where((p) => p.name.toLowerCase().contains(query))
            .toList(growable: false);
    final existing = state.existingPointIds;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            OpenVtsSpacing.md,
            OpenVtsSpacing.xs,
            OpenVtsSpacing.md,
            OpenVtsSpacing.xs,
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _Tab(
                      label: 'POIs',
                      count: state.landmarkPois.length,
                      selected: tab == LandmarkTypeTab.poi,
                      onTap: () => controller
                          .setSelectedLandmarkTypeTab(LandmarkTypeTab.poi),
                    ),
                  ),
                  const SizedBox(width: OpenVtsSpacing.xs),
                  Expanded(
                    child: _Tab(
                      label: 'Geofences',
                      count: state.landmarkGeofences.length,
                      selected: tab == LandmarkTypeTab.geofence,
                      onTap: () => controller
                          .setSelectedLandmarkTypeTab(LandmarkTypeTab.geofence),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: OpenVtsSpacing.xs),
              TextField(
                controller: _search,
                onChanged: controller.setLandmarkSearchQuery,
                style: OpenVtsTypography.label,
                decoration: InputDecoration(
                  hintText: 'Search by name',
                  hintStyle: OpenVtsTypography.label.copyWith(
                    color: OpenVtsColors.textTertiary,
                  ),
                  prefixIcon: const Icon(Icons.search, size: 16),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: OpenVtsSpacing.sm,
                    vertical: OpenVtsSpacing.xs,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(OpenVtsRadius.sm),
                    borderSide: const BorderSide(color: OpenVtsColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(OpenVtsRadius.sm),
                    borderSide: const BorderSide(color: OpenVtsColors.border),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _PickerBody(
            isLoading: state.isLoadingLandmarks,
            errorMessage: state.errorMessage,
            items: filtered,
            existingIds: existing,
            selected: _selected,
            onToggle: _toggle,
            onRetry: controller.loadLandmarks,
            scrollController: widget.scrollController,
          ),
        ),
        const Divider(height: 1, color: OpenVtsColors.border),
        Padding(
          padding: const EdgeInsets.all(OpenVtsSpacing.sm),
          child: Row(
            children: [
              Text(
                _selected.isEmpty
                    ? 'No selection'
                    : '${_selected.length} selected',
                style: OpenVtsTypography.meta.copyWith(
                  color: OpenVtsColors.textSecondary,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => Navigator.of(context).pop(0),
                child: Text(
                  'Cancel',
                  style: OpenVtsTypography.label.copyWith(
                    color: OpenVtsColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              ElevatedButton(
                onPressed: _selected.isEmpty ? null : _confirm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: OpenVtsColors.brandInk,
                  foregroundColor: OpenVtsColors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(OpenVtsRadius.button),
                  ),
                  minimumSize: const Size(0, 38),
                ),
                child: Text(
                  _selected.isEmpty ? 'Add' : 'Add ${_selected.length}',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PickerBody extends StatelessWidget {
  const _PickerBody({
    required this.isLoading,
    required this.errorMessage,
    required this.items,
    required this.existingIds,
    required this.selected,
    required this.onToggle,
    required this.onRetry,
    required this.scrollController,
  });

  final bool isLoading;
  final String? errorMessage;
  final List<RouteOptimisationPoint> items;
  final Set<String> existingIds;
  final Map<String, RouteOptimisationPoint> selected;
  final void Function(RouteOptimisationPoint, bool) onToggle;
  final VoidCallback onRetry;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    if (isLoading && items.isEmpty) {
      return const Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    if (errorMessage != null && items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(OpenVtsSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 20,
              color: OpenVtsColors.error,
            ),
            const SizedBox(height: OpenVtsSpacing.xs),
            const Text(
              'Could not load landmarks',
              style: OpenVtsTypography.label,
            ),
            const SizedBox(height: 4),
            Text(
              errorMessage!,
              textAlign: TextAlign.center,
              style: OpenVtsTypography.meta.copyWith(
                color: OpenVtsColors.textSecondary,
              ),
            ),
            const SizedBox(height: OpenVtsSpacing.sm),
            OutlinedButton(
              onPressed: onRetry,
              style: OutlinedButton.styleFrom(
                foregroundColor: OpenVtsColors.textPrimary,
                side: const BorderSide(color: OpenVtsColors.border),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(OpenVtsRadius.button),
                ),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    if (items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(
          horizontal: OpenVtsSpacing.md,
          vertical: OpenVtsSpacing.lg,
        ),
        child: OpenVtsEmptyState(
          title: 'Nothing to show',
          message: 'Try clearing the search or switching tabs.',
        ),
      );
    }
    return ListView.separated(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(
        OpenVtsSpacing.md,
        0,
        OpenVtsSpacing.md,
        OpenVtsSpacing.sm,
      ),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 6),
      itemBuilder: (context, i) {
        final p = items[i];
        final added = existingIds.contains(p.id);
        final checked = selected.containsKey(p.id);
        return _LandmarkRow(
          point: p,
          disabled: added,
          checked: checked,
          onChanged: added ? null : (v) => onToggle(p, v),
        );
      },
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bg =
        selected ? OpenVtsColors.brandInk : OpenVtsColors.surfaceElevated;
    final fg = selected ? OpenVtsColors.white : OpenVtsColors.textPrimary;
    return Material(
      color: bg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(OpenVtsRadius.sm),
        side: BorderSide(
          color: selected ? OpenVtsColors.brandInk : OpenVtsColors.border,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(OpenVtsRadius.sm),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(label, style: OpenVtsTypography.label.copyWith(color: fg)),
              const SizedBox(width: 6),
              Text(
                '$count',
                style: OpenVtsTypography.meta.copyWith(
                  color: fg.withValues(alpha: 0.75),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LandmarkRow extends StatelessWidget {
  const _LandmarkRow({
    required this.point,
    required this.disabled,
    required this.checked,
    required this.onChanged,
  });

  final RouteOptimisationPoint point;
  final bool disabled;
  final bool checked;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final isGeofence = point.source == RouteOptimisationPointSource.geofence;
    return Material(
      color: disabled ? OpenVtsColors.surface : OpenVtsColors.surfaceElevated,
      borderRadius: BorderRadius.circular(OpenVtsRadius.sm),
      child: InkWell(
        borderRadius: BorderRadius.circular(OpenVtsRadius.sm),
        onTap: onChanged == null ? null : () => onChanged!(!checked),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: OpenVtsSpacing.xs,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(OpenVtsRadius.sm),
            border: Border.all(color: OpenVtsColors.border),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 22,
                height: 22,
                child: Checkbox(
                  value: checked,
                  onChanged:
                      onChanged == null ? null : (v) => onChanged!(v ?? false),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              const SizedBox(width: OpenVtsSpacing.xs),
              Icon(
                isGeofence ? Icons.fence_outlined : Icons.place_outlined,
                size: 14,
                color: disabled
                    ? OpenVtsColors.textTertiary
                    : OpenVtsColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      point.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: OpenVtsTypography.label.copyWith(
                        color: disabled
                            ? OpenVtsColors.textTertiary
                            : OpenVtsColors.textPrimary,
                      ),
                    ),
                    Text(
                      '${point.lat.toStringAsFixed(4)}, '
                      '${point.lon.toStringAsFixed(4)}',
                      style: OpenVtsTypography.meta.copyWith(
                        color: OpenVtsColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (disabled)
                Text(
                  'Added',
                  style: OpenVtsTypography.meta.copyWith(
                    color: OpenVtsColors.textTertiary,
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
