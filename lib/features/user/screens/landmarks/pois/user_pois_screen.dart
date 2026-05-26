import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/open_vts_colors.dart';
import '../../../../../core/theme/open_vts_radius.dart';
import '../../../../../core/theme/open_vts_spacing.dart';
import '../../../../../core/theme/open_vts_typography.dart';
import '../../../../../shared/helpers/toast_helper.dart';
import '../../../../../shared/widgets/open_vts_button.dart';
import '../../../../../shared/widgets/open_vts_empty_state.dart';
import '../../../../../shared/widgets/open_vts_error_view.dart';
import '../../../../../shared/widgets/open_vts_loader.dart';
import '../../../../../shared/widgets/open_vts_page_scaffold.dart';
import '../../../controllers/user_providers.dart';
import '../../../models/user_landmark_model.dart';
import '../widgets/user_landmark_export_sheet.dart';
import '../widgets/user_landmark_import_sheet.dart';
import '../widgets/user_landmark_map_view.dart';
import 'widgets/user_poi_card.dart';
import 'widgets/user_poi_filter_bar.dart';
import 'widgets/user_poi_form_sheet.dart';

/// Landing screen for the POI module inside Landmark Studio.
///
/// Composes header, filter bar, scrollable card list, and an adaptive map
/// preview (bottom on mobile, side panel on tablet/wide). All business logic
/// lives in [userPoisControllerProvider]; widgets only render state and
/// dispatch intents.
class UserPoisScreen extends ConsumerWidget {
  const UserPoisScreen({super.key});

  static const double _tabletBreakpoint = 860;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(userPoisControllerProvider);
    final controller = ref.read(userPoisControllerProvider.notifier);

    return OpenVtsPageScaffold(
      title: 'POI',
      headerMode: OpenVtsPageHeaderMode.closeable,
      padding: const EdgeInsets.fromLTRB(
        OpenVtsSpacing.sm,
        OpenVtsSpacing.xs,
        OpenVtsSpacing.sm,
        OpenVtsSpacing.sm,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= _tabletBreakpoint;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _HeaderRow(
                isRefreshing: state.isRefreshing,
                onCreate: () => _openCreate(context),
                onRefresh:
                    state.isRefreshing ? null : () => controller.refresh(),
                onExport: () => UserLandmarkExportSheet.show(
                  context: context,
                  entityType: UserLandmarkEntityType.poi,
                ),
                onImport: () => UserLandmarkImportSheet.show(
                  context: context,
                  entityType: UserLandmarkEntityType.poi,
                ),
              ),
              const SizedBox(height: OpenVtsSpacing.xs),
              UserPoiFilterBar(
                searchQuery: state.searchQuery,
                statusFilter: state.statusFilter,
                categoryFilter: state.categoryFilter,
                categories: state.availableCategories,
                onSearchChanged: controller.setSearchQuery,
                onStatusChanged: controller.setStatusFilter,
                onCategoryChanged: controller.setCategoryFilter,
              ),
              const SizedBox(height: OpenVtsSpacing.sm),
              Expanded(
                child: wide
                    ? _WideLayout(
                        state: state,
                        controller: controller,
                        onEdit: (p) => _openEdit(context, p),
                        onDelete: (p) => _confirmAndDelete(context, ref, p),
                      )
                    : _MobileLayout(
                        state: state,
                        controller: controller,
                        onEdit: (p) => _openEdit(context, p),
                        onDelete: (p) => _confirmAndDelete(context, ref, p),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _openCreate(BuildContext context) async {
    await UserPoiFormSheet.show(context: context);
  }

  Future<void> _openEdit(BuildContext context, UserPoi poi) async {
    await UserPoiFormSheet.show(context: context, poi: poi);
  }

  Future<void> _confirmAndDelete(
    BuildContext context,
    WidgetRef ref,
    UserPoi poi,
  ) async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: false,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return SafeArea(
          top: false,
          child: Container(
            margin: const EdgeInsets.all(OpenVtsSpacing.sm),
            padding: const EdgeInsets.all(OpenVtsSpacing.md),
            decoration: BoxDecoration(
              color: OpenVtsColors.surfaceElevated,
              borderRadius: BorderRadius.circular(OpenVtsRadius.lg),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Delete POI?',
                  style: OpenVtsTypography.titleSmall.copyWith(
                    color: OpenVtsColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '"${poi.name}" will be permanently removed.',
                  style: OpenVtsTypography.meta.copyWith(
                    color: OpenVtsColors.textSecondary,
                  ),
                ),
                const SizedBox(height: OpenVtsSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: OpenVtsButton(
                        label: 'Cancel',
                        onPressed: () => Navigator.of(ctx).pop(false),
                        variant: OpenVtsButtonVariant.secondary,
                      ),
                    ),
                    const SizedBox(width: OpenVtsSpacing.sm),
                    Expanded(
                      child: OpenVtsButton(
                        label: 'Delete',
                        onPressed: () => Navigator.of(ctx).pop(true),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
    if (confirmed != true) return;
    try {
      await ref.read(userPoisControllerProvider.notifier).deletePoi(poi.id);
    } catch (e) {
      if (!context.mounted) return;
      ToastHelper.showError(e.toString(), context: context);
    }
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow({
    required this.isRefreshing,
    required this.onCreate,
    required this.onRefresh,
    required this.onExport,
    required this.onImport,
  });

  final bool isRefreshing;
  final VoidCallback onCreate;
  final VoidCallback? onRefresh;
  final VoidCallback onExport;
  final VoidCallback onImport;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Manage important places and operational points.',
                style: TextStyle(
                  fontSize: 12,
                  color: OpenVtsColors.textSecondary,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
        _HeaderIconButton(
          icon: Icons.refresh,
          tooltip: 'Refresh',
          onTap: onRefresh,
          showSpinner: isRefreshing,
        ),
        const SizedBox(width: 6),
        _HeaderIconButton(
          icon: Icons.file_upload_outlined,
          tooltip: 'Import CSV',
          onTap: onImport,
        ),
        const SizedBox(width: 6),
        _HeaderIconButton(
          icon: Icons.file_download_outlined,
          tooltip: 'Export KML',
          onTap: onExport,
        ),
        const SizedBox(width: 6),
        _HeaderIconButton(
          icon: Icons.add,
          tooltip: 'New POI',
          onTap: onCreate,
          primary: true,
        ),
      ],
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.primary = false,
    this.showSpinner = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  final bool primary;
  final bool showSpinner;

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    final bg = primary ? OpenVtsColors.brandInk : OpenVtsColors.surfaceElevated;
    final fg = primary ? OpenVtsColors.white : OpenVtsColors.textPrimary;
    return Tooltip(
      message: tooltip,
      child: InkResponse(
        onTap: onTap,
        radius: 22,
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: disabled ? bg.withValues(alpha: 0.55) : bg,
            borderRadius: BorderRadius.circular(OpenVtsRadius.button),
            border: primary ? null : Border.all(color: OpenVtsColors.border),
          ),
          alignment: Alignment.center,
          child: showSpinner
              ? SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(fg),
                  ),
                )
              : Icon(icon, size: 16, color: fg),
        ),
      ),
    );
  }
}

class _MobileLayout extends StatelessWidget {
  const _MobileLayout({
    required this.state,
    required this.controller,
    required this.onEdit,
    required this.onDelete,
  });

  final dynamic state;
  final dynamic controller;
  final ValueChanged<UserPoi> onEdit;
  final ValueChanged<UserPoi> onDelete;

  @override
  Widget build(BuildContext context) {
    final pois = state.filteredPois as List<UserPoi>;
    return Column(
      children: [
        Expanded(
          child: _ListBody(
            state: state,
            controller: controller,
            onEdit: onEdit,
            onDelete: onDelete,
          ),
        ),
        if (pois.isNotEmpty) ...[
          const SizedBox(height: OpenVtsSpacing.sm),
          _MapPanel(
            pois: pois,
            selectedId: (state.selectedPoi as UserPoi?)?.id,
            onSelect: (p) => controller.selectPoi(p),
            height: 220,
          ),
        ],
      ],
    );
  }
}

class _WideLayout extends StatelessWidget {
  const _WideLayout({
    required this.state,
    required this.controller,
    required this.onEdit,
    required this.onDelete,
  });

  final dynamic state;
  final dynamic controller;
  final ValueChanged<UserPoi> onEdit;
  final ValueChanged<UserPoi> onDelete;

  @override
  Widget build(BuildContext context) {
    final pois = state.filteredPois as List<UserPoi>;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: 3,
          child: _ListBody(
            state: state,
            controller: controller,
            onEdit: onEdit,
            onDelete: onDelete,
          ),
        ),
        const SizedBox(width: OpenVtsSpacing.sm),
        Expanded(
          flex: 2,
          child: _MapPanel(
            pois: pois,
            selectedId: (state.selectedPoi as UserPoi?)?.id,
            onSelect: (p) => controller.selectPoi(p),
          ),
        ),
      ],
    );
  }
}

class _MapPanel extends StatelessWidget {
  const _MapPanel({
    required this.pois,
    required this.selectedId,
    required this.onSelect,
    this.height,
  });

  final List<UserPoi> pois;
  final String? selectedId;
  final ValueChanged<UserPoi> onSelect;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(OpenVtsRadius.md),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(OpenVtsRadius.md),
            border: Border.all(color: OpenVtsColors.border),
          ),
          child: UserLandmarkMapView(
            pois: pois,
            selectedPoiId: selectedId,
            onSelectPoi: onSelect,
            showPoiToleranceRings: true,
          ),
        ),
      ),
    );
  }
}

class _ListBody extends StatelessWidget {
  const _ListBody({
    required this.state,
    required this.controller,
    required this.onEdit,
    required this.onDelete,
  });

  final dynamic state;
  final dynamic controller;
  final ValueChanged<UserPoi> onEdit;
  final ValueChanged<UserPoi> onDelete;

  @override
  Widget build(BuildContext context) {
    final hasPois = state.hasPois as bool;
    final isLoading = state.isLoading as bool;
    final errorMessage = state.errorMessage as String?;
    final filtered = state.filteredPois as List<UserPoi>;
    final selected = state.selectedPoi as UserPoi?;
    final deletingIds = state.deletingIds as Set<String>;

    if (isLoading && !hasPois) {
      return const OpenVtsLoader();
    }
    if (errorMessage != null && !hasPois) {
      return OpenVtsErrorView(
        message: errorMessage,
        onRetry: () => controller.load(),
      );
    }
    if (!hasPois) {
      return _EmptyState(
        title: 'No POIs yet',
        message: 'Create your first place to track operational points.',
        actionLabel: 'Create POI',
        onAction: () => UserPoiFormSheet.show(context: context),
      );
    }
    if (filtered.isEmpty) {
      return _EmptyState(
        title: 'No matching POIs',
        message: 'Try adjusting your filters.',
        actionLabel: 'Clear filters',
        onAction: () => controller.clearFilters(),
        secondary: true,
      );
    }

    return RefreshIndicator(
      onRefresh: () => controller.refresh(),
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        itemCount: filtered.length,
        separatorBuilder: (_, __) => const SizedBox(height: OpenVtsSpacing.xs),
        itemBuilder: (context, index) {
          final p = filtered[index];
          return UserPoiCard(
            poi: p,
            isSelected: selected?.id == p.id,
            isDeleting: deletingIds.contains(p.id),
            onSelect: () => controller.selectPoi(p),
            onEdit: () => onEdit(p),
            onDelete: () => onDelete(p),
          );
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
    this.secondary = false,
  });

  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;
  final bool secondary;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        OpenVtsEmptyState(title: title, message: message),
        const SizedBox(height: OpenVtsSpacing.sm),
        SizedBox(
          width: 220,
          child: OpenVtsButton(
            label: actionLabel,
            onPressed: onAction,
            variant: secondary
                ? OpenVtsButtonVariant.secondary
                : OpenVtsButtonVariant.primary,
          ),
        ),
      ],
    );
  }
}
