import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/open_vts_colors.dart';
import '../../../../core/theme/open_vts_radius.dart';
import '../../../../core/theme/open_vts_spacing.dart';
import '../../../../shared/widgets/open_vts_empty_state.dart';
import '../../../../shared/widgets/open_vts_error_view.dart';
import '../../../../shared/widgets/open_vts_list_page_header.dart';
import '../../../../shared/widgets/open_vts_loader.dart';
import '../../../../shared/widgets/open_vts_page_scaffold.dart';
import '../../controllers/admin_drivers_controller.dart';
import '../../controllers/admin_providers.dart';
import '../../models/admin_drivers_model.dart';
import '../../models/admin_drivers_state.dart';
import 'widgets/admin_driver_card.dart';
import 'widgets/admin_driver_create_sheet.dart';

class AdminDriversScreen extends ConsumerWidget {
  const AdminDriversScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(adminDriversControllerProvider);
    final controller = ref.read(adminDriversControllerProvider.notifier);

    return OpenVtsPageScaffold(
      title: 'Drivers',
      headerMode: OpenVtsPageHeaderMode.closeable,
      actions: [
        IconButton(
          tooltip: 'Refresh drivers',
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
      body: state.isLoading && !state.hasDrivers
          ? const OpenVtsLoader()
          : state.errorMessage != null && !state.hasDrivers
              ? OpenVtsErrorView(
                  message: state.errorMessage ?? 'Drivers could not be loaded.',
                  onRetry: controller.refresh,
                )
              : _DriversBody(
                  state: state,
                  controller: controller,
                  onCreate: () => _showCreateDriverSheet(context),
                  onOpenFilters: () => _showFilterSheet(context, ref),
                  onOpenSort: () => _showSortSheet(context, ref),
                  onOpenDetails: (driver) => context.push(
                    RoutePaths.adminDriverDetailsPath(driver.id),
                    extra: driver,
                  ),
                ),
    );
  }

  Future<void> _showCreateDriverSheet(BuildContext context) {
    return showDriverCreateSheet(
      context: context,
      provider: adminDriversControllerProvider,
    );
  }

  Future<void> _showFilterSheet(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final controller = ref.read(adminDriversControllerProvider.notifier);
    final state = ref.read(adminDriversControllerProvider);

    var selectedStatus = state.statusFilter;
    var selectedVerified = state.verifiedFilter;
    var selectedCountry = state.countryFilter;
    final countryCodes = _countryCodes(state.drivers);

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
              title: 'Filter drivers',
              sections: [
                OpenVtsListPageOptionsSection(
                  label: 'Status',
                  child: Wrap(
                    spacing: OpenVtsSpacing.xs,
                    runSpacing: OpenVtsSpacing.xs,
                    children: AdminDriverStatusFilter.values
                        .map(
                          (option) => OpenVtsListPageChoiceChip(
                            label: switch (option) {
                              AdminDriverStatusFilter.all => 'All',
                              AdminDriverStatusFilter.active => 'Active',
                              AdminDriverStatusFilter.inactive => 'Inactive',
                            },
                            selected: selectedStatus == option,
                            onSelected: () =>
                                setSheetState(() => selectedStatus = option),
                          ),
                        )
                        .toList(growable: false),
                  ),
                ),
                OpenVtsListPageOptionsSection(
                  label: 'Verification',
                  child: Wrap(
                    spacing: OpenVtsSpacing.xs,
                    runSpacing: OpenVtsSpacing.xs,
                    children: AdminDriverVerifiedFilter.values
                        .map(
                          (option) => OpenVtsListPageChoiceChip(
                            label: switch (option) {
                              AdminDriverVerifiedFilter.all => 'All',
                              AdminDriverVerifiedFilter.verified => 'Verified',
                              AdminDriverVerifiedFilter.unverified =>
                                'Unverified',
                            },
                            selected: selectedVerified == option,
                            onSelected: () =>
                                setSheetState(() => selectedVerified = option),
                          ),
                        )
                        .toList(growable: false),
                  ),
                ),
                OpenVtsListPageOptionsSection(
                  label: 'Country',
                  child: Wrap(
                    spacing: OpenVtsSpacing.xs,
                    runSpacing: OpenVtsSpacing.xs,
                    children: [
                      OpenVtsListPageChoiceChip(
                        label: 'All Countries',
                        selected: selectedCountry == null,
                        onSelected: () =>
                            setSheetState(() => selectedCountry = null),
                      ),
                      for (final code in countryCodes)
                        OpenVtsListPageChoiceChip(
                          label: code,
                          selected: selectedCountry == code,
                          onSelected: () =>
                              setSheetState(() => selectedCountry = code),
                        ),
                    ],
                  ),
                ),
              ],
              primaryActionLabel: 'Apply filters',
              onPrimaryAction: () {
                controller.setStatusFilter(selectedStatus);
                controller.setVerifiedFilter(selectedVerified);
                controller.setCountryFilter(selectedCountry);
                Navigator.of(sheetContext).pop();
              },
              secondaryActionLabel: 'Reset',
              onSecondaryAction: () {
                setSheetState(() {
                  selectedStatus = AdminDriverStatusFilter.all;
                  selectedVerified = AdminDriverVerifiedFilter.all;
                  selectedCountry = null;
                });
              },
            );
          },
        );
      },
    );
  }

  Future<void> _showSortSheet(BuildContext context, WidgetRef ref) async {
    final controller = ref.read(adminDriversControllerProvider.notifier);
    final state = ref.read(adminDriversControllerProvider);

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
          title: 'Sort drivers',
          sections: [
            OpenVtsListPageOptionsSection(
              label: 'Order by',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: AdminDriversSortOption.values
                    .map(
                      (option) => OpenVtsListPageRadioRow(
                        label: switch (option) {
                          AdminDriversSortOption.newest => 'Newest',
                          AdminDriversSortOption.nameAsc => 'Name A-Z',
                          AdminDriversSortOption.activeFirst => 'Active first',
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

  List<String> _countryCodes(List<AdminDriverListItem> drivers) {
    final codes = <String>{
      for (final driver in drivers)
        if (driver.countryCode.trim().isNotEmpty &&
            driver.countryCode.trim() != '-')
          driver.countryCode.trim().toUpperCase(),
    }.toList()
      ..sort();
    return codes;
  }
}

class _DriversBody extends StatelessWidget {
  const _DriversBody({
    required this.state,
    required this.controller,
    required this.onCreate,
    required this.onOpenFilters,
    required this.onOpenSort,
    required this.onOpenDetails,
  });

  final AdminDriversState state;
  final AdminDriversController controller;
  final VoidCallback onCreate;
  final VoidCallback onOpenFilters;
  final VoidCallback onOpenSort;
  final void Function(AdminDriverListItem) onOpenDetails;

  @override
  Widget build(BuildContext context) {
    final filteredCount = state.filteredCount;
    final visible = state.visibleDrivers;

    return Column(
      children: [
        OpenVtsListPageHeaderCard(
          icon: Icons.badge_outlined,
          countLabel:
              '$filteredCount Driver${filteredCount == 1 ? '' : 's'}',
          createLabel: 'Add Driver',
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
          filterTooltip: 'Filter drivers',
          onOpenSort: onOpenSort,
          sortTooltip: 'Sort drivers',
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
                        title: 'No drivers found',
                        message: state.hasActiveFilters
                            ? 'Try a different search or filter.'
                            : 'Create a driver to get started.',
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

                      final driver = visible[index];
                      return AdminDriverCard(
                        driver: driver,
                        onTap: () => onOpenDetails(driver),
                      );
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
