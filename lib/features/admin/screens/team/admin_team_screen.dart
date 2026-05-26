import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/open_vts_colors.dart';
import '../../../../core/theme/open_vts_radius.dart';
import '../../../../core/theme/open_vts_spacing.dart';
import '../../../../shared/widgets/open_vts_bottom_sheet.dart';
import '../../../../shared/widgets/open_vts_empty_state.dart';
import '../../../../shared/widgets/open_vts_error_view.dart';
import '../../../../shared/widgets/open_vts_list_page_header.dart';
import '../../../../shared/widgets/open_vts_loader.dart';
import '../../../../shared/widgets/open_vts_page_scaffold.dart';
import '../../controllers/admin_providers.dart';
import '../../controllers/admin_team_controller.dart';
import '../../models/admin_team_state.dart';
import 'widgets/admin_create_team_sheet.dart';
import 'widgets/admin_team_card.dart';

class AdminTeamScreen extends ConsumerWidget {
  const AdminTeamScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(adminTeamControllerProvider);
    final controller = ref.read(adminTeamControllerProvider.notifier);

    return OpenVtsPageScaffold(
      title: 'Team',
      headerMode: OpenVtsPageHeaderMode.closeable,
      actions: [
        IconButton(
          tooltip: 'Refresh team',
          onPressed: controller.refresh,
          icon: state.isRefreshing
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2.2),
                )
              : const Icon(Icons.refresh_rounded, size: 20),
        ),
      ],
      padding: const EdgeInsetsDirectional.fromSTEB(
        OpenVtsSpacing.sm,
        OpenVtsSpacing.sm,
        OpenVtsSpacing.sm,
        OpenVtsSpacing.sm,
      ),
      body: state.isLoading && !state.hasTeams
          ? const OpenVtsLoader()
          : state.errorMessage != null && !state.hasTeams
              ? OpenVtsErrorView(
                  message: state.errorMessage ?? 'Team could not be loaded.',
                  onRetry: controller.refresh,
                )
              : _TeamBody(
                  state: state,
                  controller: controller,
                  onCreate: () => _showCreateTeamSheet(context, ref),
                  onOpenFilters: () => _showFilterSheet(context, ref),
                  onOpenSort: () => _showSortSheet(context, ref),
                ),
    );
  }

  Future<void> _showCreateTeamSheet(BuildContext context, WidgetRef ref) {
    return OpenVtsBottomSheet.show<void>(
      context: context,
      title: 'Add New Team',
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.96,
      child: Consumer(
        builder: (context, ref, child) {
          final teamState = ref.watch(adminTeamControllerProvider);
          return AdminCreateTeamSheet(isSubmitting: teamState.isCreating);
        },
      ),
    );
  }

  Future<void> _showFilterSheet(BuildContext context, WidgetRef ref) async {
    final controller = ref.read(adminTeamControllerProvider.notifier);
    final state = ref.read(adminTeamControllerProvider);

    var selectedStatus = state.statusFilter;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(OpenVtsRadius.xl),
        ),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return OpenVtsListPageOptionsSheet(
              title: 'Filter team',
              sections: [
                OpenVtsListPageOptionsSection(
                  label: 'Status',
                  child: Wrap(
                    spacing: OpenVtsSpacing.xs,
                    runSpacing: OpenVtsSpacing.xs,
                    children: AdminTeamStatusFilter.values
                        .map(
                          (option) => OpenVtsListPageChoiceChip(
                            label: switch (option) {
                              AdminTeamStatusFilter.all => 'All',
                              AdminTeamStatusFilter.active => 'Active',
                              AdminTeamStatusFilter.inactive => 'Inactive',
                            },
                            selected: selectedStatus == option,
                            onSelected: () =>
                                setSheetState(() => selectedStatus = option),
                          ),
                        )
                        .toList(growable: false),
                  ),
                ),
              ],
              primaryActionLabel: 'Apply filters',
              onPrimaryAction: () {
                controller.setStatusFilter(selectedStatus);
                Navigator.of(sheetContext).pop();
              },
              secondaryActionLabel: 'Reset',
              onSecondaryAction: () {
                setSheetState(() {
                  selectedStatus = AdminTeamStatusFilter.all;
                });
              },
            );
          },
        );
      },
    );
  }

  Future<void> _showSortSheet(BuildContext context, WidgetRef ref) async {
    final controller = ref.read(adminTeamControllerProvider.notifier);
    final state = ref.read(adminTeamControllerProvider);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(OpenVtsRadius.xl),
        ),
      ),
      builder: (sheetContext) {
        return OpenVtsListPageOptionsSheet(
          title: 'Sort team',
          sections: [
            OpenVtsListPageOptionsSection(
              label: 'Order by',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: AdminTeamSortOption.values
                    .map(
                      (option) => OpenVtsListPageRadioRow(
                        label: switch (option) {
                          AdminTeamSortOption.newest => 'Newest',
                          AdminTeamSortOption.nameAsc => 'Name A-Z',
                          AdminTeamSortOption.activeFirst => 'Active first',
                        },
                        selected: state.sortOption == option,
                        onTap: () {
                          controller.setSortOption(option);
                          Navigator.of(sheetContext).pop();
                        },
                      ),
                    )
                    .toList(growable: false),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _TeamBody extends StatelessWidget {
  const _TeamBody({
    required this.state,
    required this.controller,
    required this.onCreate,
    required this.onOpenFilters,
    required this.onOpenSort,
  });

  final AdminTeamState state;
  final AdminTeamController controller;
  final VoidCallback onCreate;
  final VoidCallback onOpenFilters;
  final VoidCallback onOpenSort;

  @override
  Widget build(BuildContext context) {
    final filteredCount = state.filteredCount;
    final visible = state.visibleTeams;

    return Column(
      children: [
        OpenVtsListPageHeaderCard(
          icon: Icons.groups_outlined,
          countLabel: filteredCount == 1
              ? '1 Team Member'
              : '$filteredCount Team Members',
          createLabel: 'Add Team',
          onCreate: onCreate,
          isCreateLoading: state.isCreating,
        ),
        const SizedBox(height: OpenVtsSpacing.sm),
        OpenVtsListPageToolbar(
          searchQuery: state.searchQuery,
          hintText: 'Search by name, email\u2026',
          hasActiveFilters: state.hasActiveFilters,
          onSearchChanged: controller.setSearchQuery,
          onOpenFilters: onOpenFilters,
          filterTooltip: 'Filter team',
          onOpenSort: onOpenSort,
          sortTooltip: 'Sort team',
          recordsPerPage: state.recordsPerPage,
          onRecordsChanged: controller.setRecordsPerPage,
        ),
        if (state.errorMessage != null) ...[
          const SizedBox(height: OpenVtsSpacing.sm),
          _InlineErrorBanner(message: state.errorMessage!),
        ],
        Expanded(
          child: RefreshIndicator(
            onRefresh: controller.refresh,
            child: filteredCount == 0
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      const SizedBox(height: OpenVtsSpacing.section),
                      OpenVtsEmptyState(
                        title: 'No team members found',
                        message: state.hasActiveFilters
                            ? 'Try a different search or filter.'
                            : 'Create a team member to get started.',
                      ),
                    ],
                  )
                : ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: visible.length + 1,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: OpenVtsSpacing.sm),
                    itemBuilder: (context, index) {
                      if (index == visible.length) {
                        return OpenVtsListPagePaginationFooter(
                          currentPage: state.safeCurrentPage,
                          pageCount: state.pageCount,
                          showingCount: visible.length,
                          totalCount: filteredCount,
                          onPrev: () =>
                              controller.goToPage(state.safeCurrentPage - 1),
                          onNext: () =>
                              controller.goToPage(state.safeCurrentPage + 1),
                        );
                      }

                      return AdminTeamCard(team: visible[index]);
                    },
                  ),
          ),
        ),
      ],
    );
  }
}

class _InlineErrorBanner extends StatelessWidget {
  const _InlineErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: OpenVtsSpacing.md,
        vertical: OpenVtsSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: OpenVtsColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(OpenVtsRadius.md),
        border: Border.all(color: OpenVtsColors.error.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: OpenVtsColors.error),
          const SizedBox(width: OpenVtsSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: OpenVtsColors.error,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
