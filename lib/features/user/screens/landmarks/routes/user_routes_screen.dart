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
import '../../../models/user_landmark_state.dart';
import '../widgets/user_landmark_export_sheet.dart';
import '../widgets/user_landmark_import_sheet.dart';
import 'widgets/user_route_card.dart';
import 'widgets/user_route_filter_bar.dart';
import 'widgets/user_route_form_sheet.dart';
import 'widgets/user_route_preview_map.dart';

/// Landing screen for the Routes module inside Landmark Studio.
///
/// Composes header, filter bar, scrollable card list, and an adaptive route
/// preview map (bottom on mobile, side panel on tablet/wide). All business
/// logic lives in `userRoutesControllerProvider`; widgets only render state
/// and dispatch intents.
class UserRoutesScreen extends ConsumerWidget {
  const UserRoutesScreen({super.key});

  static const double _tabletBreakpoint = 860;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(userRoutesControllerProvider);
    final controller = ref.read(userRoutesControllerProvider.notifier);

    return OpenVtsPageScaffold(
      title: 'Route',
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
                  entityType: UserLandmarkEntityType.route,
                ),
                onImport: () => UserLandmarkImportSheet.show(
                  context: context,
                  entityType: UserLandmarkEntityType.route,
                ),
              ),
              const SizedBox(height: OpenVtsSpacing.xs),
              UserRouteFilterBar(
                searchQuery: state.searchQuery,
                statusFilter: state.statusFilter,
                onSearchChanged: controller.setSearchQuery,
                onStatusChanged: controller.setStatusFilter,
              ),
              const SizedBox(height: OpenVtsSpacing.sm),
              Expanded(
                child: wide
                    ? _WideLayout(
                        state: state,
                        controller: controller,
                        onEdit: (r) => _openEdit(context, r),
                        onDelete: (r) => _confirmAndDelete(context, ref, r),
                      )
                    : _MobileLayout(
                        state: state,
                        controller: controller,
                        onEdit: (r) => _openEdit(context, r),
                        onDelete: (r) => _confirmAndDelete(context, ref, r),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _openCreate(BuildContext context) async {
    await UserRouteFormSheet.show(context: context);
  }

  Future<void> _openEdit(BuildContext context, UserRouteLandmark route) async {
    await UserRouteFormSheet.show(context: context, route: route);
  }

  Future<void> _confirmAndDelete(
    BuildContext context,
    WidgetRef ref,
    UserRouteLandmark route,
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
                  'Delete route?',
                  style: OpenVtsTypography.titleSmall.copyWith(
                    color: OpenVtsColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '"${route.name}" will be permanently removed.',
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
      await ref
          .read(userRoutesControllerProvider.notifier)
          .deleteRoute(route.id);
    } catch (e) {
      if (!context.mounted) return;
      ToastHelper.showError(e.toString(), context: context);
    }
  }
}

// ---------------------------------------------------------------------------
// Header
// ---------------------------------------------------------------------------

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
                'Create and manage operational route corridors.',
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
          tooltip: 'New route',
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

// ---------------------------------------------------------------------------
// Layouts
// ---------------------------------------------------------------------------

class _MobileLayout extends StatelessWidget {
  const _MobileLayout({
    required this.state,
    required this.controller,
    required this.onEdit,
    required this.onDelete,
  });

  final UserRoutesState state;
  final dynamic controller;
  final ValueChanged<UserRouteLandmark> onEdit;
  final ValueChanged<UserRouteLandmark> onDelete;

  @override
  Widget build(BuildContext context) {
    final routes = state.filteredRoutes;
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
        if (routes.isNotEmpty) ...[
          const SizedBox(height: OpenVtsSpacing.sm),
          UserRoutePreviewMap(
            routes: routes,
            selectedRouteId: state.selectedRoute?.id,
            onSelectRoute: (r) => controller.selectRoute(r),
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

  final UserRoutesState state;
  final dynamic controller;
  final ValueChanged<UserRouteLandmark> onEdit;
  final ValueChanged<UserRouteLandmark> onDelete;

  @override
  Widget build(BuildContext context) {
    final routes = state.filteredRoutes;
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
          child: UserRoutePreviewMap(
            routes: routes,
            selectedRouteId: state.selectedRoute?.id,
            onSelectRoute: (r) => controller.selectRoute(r),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// List body
// ---------------------------------------------------------------------------

class _ListBody extends StatelessWidget {
  const _ListBody({
    required this.state,
    required this.controller,
    required this.onEdit,
    required this.onDelete,
  });

  final UserRoutesState state;
  final dynamic controller;
  final ValueChanged<UserRouteLandmark> onEdit;
  final ValueChanged<UserRouteLandmark> onDelete;

  @override
  Widget build(BuildContext context) {
    final filtered = state.filteredRoutes;
    final selected = state.selectedRoute;

    if (state.isLoading && !state.hasRoutes) {
      return const OpenVtsLoader();
    }
    if (state.errorMessage != null && !state.hasRoutes) {
      return OpenVtsErrorView(
        message: state.errorMessage!,
        onRetry: () => controller.load(),
      );
    }
    if (!state.hasRoutes) {
      return _EmptyState(
        title: 'No routes yet',
        message: 'Draw your first route corridor to start tracking.',
        actionLabel: 'Create route',
        onAction: () => UserRouteFormSheet.show(context: context),
      );
    }
    if (filtered.isEmpty) {
      return _EmptyState(
        title: 'No matching routes',
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
          final r = filtered[index];
          return UserRouteCard(
            route: r,
            isSelected: selected?.id == r.id,
            isDeleting: state.isDeletingId(r.id),
            onSelect: () => controller.selectRoute(r),
            onEdit: () => onEdit(r),
            onDelete: () => onDelete(r),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty state
// ---------------------------------------------------------------------------

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
