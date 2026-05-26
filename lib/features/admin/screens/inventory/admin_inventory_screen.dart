import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/open_vts_colors.dart';
import '../../../../core/theme/open_vts_radius.dart';
import '../../../../core/theme/open_vts_spacing.dart';
import '../../../../core/theme/open_vts_typography.dart';
import '../../../../shared/widgets/open_vts_bottom_sheet.dart';
import '../../../../shared/widgets/open_vts_empty_state.dart';
import '../../../../shared/widgets/open_vts_error_view.dart';
import '../../../../shared/widgets/open_vts_list_page_header.dart';
import '../../../../shared/widgets/open_vts_loader.dart';
import '../../../../shared/widgets/open_vts_page_scaffold.dart';
import '../../controllers/admin_inventory_controller.dart';
import '../../controllers/admin_providers.dart';
import '../../models/admin_inventory_model.dart';
import '../../models/admin_inventory_state.dart';
import 'widgets/admin_inventory_add_sheet.dart';
import 'widgets/admin_inventory_device_card.dart';
import 'widgets/admin_inventory_edit_device_sheet.dart';
import 'widgets/admin_inventory_edit_sim_sheet.dart';
import 'widgets/admin_inventory_sim_card.dart';

class AdminInventoryScreen extends ConsumerWidget {
  const AdminInventoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(adminInventoryControllerProvider);
    final controller = ref.read(adminInventoryControllerProvider.notifier);

    final isDevices = state.selectedTab == AdminInventoryTab.devices;
    final isInitialLoading = isDevices
        ? state.isLoadingDevices && state.devices.isEmpty
        : state.isLoadingSimCards && state.simCards.isEmpty;
    final hasData =
        isDevices ? state.devices.isNotEmpty : state.simCards.isNotEmpty;
    final errorMessage =
        isDevices ? state.devicesErrorMessage : state.simCardsErrorMessage;
    final isRefreshing = isDevices
        ? state.isRefreshingDevices
        : state.isRefreshingSimCards;

    return OpenVtsPageScaffold(
      title: 'Inventory',
      headerMode: OpenVtsPageHeaderMode.closeable,
      actions: [
        IconButton(
          tooltip: 'Refresh inventory',
          onPressed: controller.refreshCurrentTab,
          icon: isRefreshing
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
      body: isInitialLoading
          ? const OpenVtsLoader()
          : errorMessage != null && !hasData
              ? OpenVtsErrorView(
                  message: errorMessage,
                  onRetry: isDevices
                      ? controller.loadDevices
                      : controller.loadSimCards,
                )
              : _InventoryBody(
                  state: state,
                  controller: controller,
                  onAdd: () => _showAddSheet(context),
                  onOpenFilters: () => _showFilterSheet(context, ref),
                  onOpenSort: () => _showSortSheet(context, ref),
                  onEditDevice: (device) => _showEditDeviceSheet(context, device),
                  onEditSim: (sim) => _showEditSimSheet(context, sim),
                ),
    );
  }

  Future<void> _showAddSheet(BuildContext context) {
    return OpenVtsBottomSheet.show<void>(
      context: context,
      title: 'Add Inventory',
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.96,
      child: const AdminInventoryAddSheet(),
    );
  }

  Future<void> _showEditDeviceSheet(
    BuildContext context,
    AdminInventoryDevice device,
  ) {
    return OpenVtsBottomSheet.show<void>(
      context: context,
      title: 'Edit Device',
      initialChildSize: 0.85,
      minChildSize: 0.45,
      maxChildSize: 0.96,
      child: AdminInventoryEditDeviceSheet(device: device),
    );
  }

  Future<void> _showEditSimSheet(
    BuildContext context,
    AdminInventorySimCard simCard,
  ) {
    return OpenVtsBottomSheet.show<void>(
      context: context,
      title: 'Edit SIM',
      initialChildSize: 0.85,
      minChildSize: 0.45,
      maxChildSize: 0.96,
      child: AdminInventoryEditSimSheet(simCard: simCard),
    );
  }

  Future<void> _showFilterSheet(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final controller = ref.read(adminInventoryControllerProvider.notifier);
    final state = ref.read(adminInventoryControllerProvider);

    if (state.selectedTab == AdminInventoryTab.devices) {
      var status = state.deviceStatusFilter;
      var active = state.deviceActiveFilter;

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
                title: 'Filter devices',
                sections: [
                  OpenVtsListPageOptionsSection(
                    label: 'Inventory status',
                    child: Wrap(
                      spacing: OpenVtsSpacing.xs,
                      runSpacing: OpenVtsSpacing.xs,
                      children: AdminInventoryStatusFilter.values
                          .map(
                            (option) => OpenVtsListPageChoiceChip(
                              label: _statusLabel(option),
                              selected: status == option,
                              onSelected: () =>
                                  setSheetState(() => status = option),
                            ),
                          )
                          .toList(growable: false),
                    ),
                  ),
                  OpenVtsListPageOptionsSection(
                    label: 'Active status',
                    child: Wrap(
                      spacing: OpenVtsSpacing.xs,
                      runSpacing: OpenVtsSpacing.xs,
                      children: AdminInventoryActiveFilter.values
                          .map(
                            (option) => OpenVtsListPageChoiceChip(
                              label: _activeLabel(option),
                              selected: active == option,
                              onSelected: () =>
                                  setSheetState(() => active = option),
                            ),
                          )
                          .toList(growable: false),
                    ),
                  ),
                ],
                primaryActionLabel: 'Apply filters',
                onPrimaryAction: () {
                  controller.setDeviceStatusFilter(status);
                  controller.setDeviceActiveFilter(active);
                  Navigator.of(sheetContext).pop();
                },
                secondaryActionLabel: 'Reset',
                onSecondaryAction: () {
                  setSheetState(() {
                    status = AdminInventoryStatusFilter.all;
                    active = AdminInventoryActiveFilter.all;
                  });
                },
              );
            },
          );
        },
      );
      return;
    }

    var status = state.simStatusFilter;
    var active = state.simActiveFilter;
    var provider = state.deviceProviderFilter;
    final providers = <String>{
      for (final item in state.simCards)
        if (item.provider.trim().isNotEmpty && item.provider.trim() != '-')
          item.provider.trim(),
    }.toList()
      ..sort();

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
              title: 'Filter SIM cards',
              sections: [
                OpenVtsListPageOptionsSection(
                  label: 'SIM status',
                  child: Wrap(
                    spacing: OpenVtsSpacing.xs,
                    runSpacing: OpenVtsSpacing.xs,
                    children: AdminInventoryStatusFilter.values
                        .map(
                          (option) => OpenVtsListPageChoiceChip(
                            label: _statusLabel(option),
                            selected: status == option,
                            onSelected: () =>
                                setSheetState(() => status = option),
                          ),
                        )
                        .toList(growable: false),
                  ),
                ),
                OpenVtsListPageOptionsSection(
                  label: 'Active status',
                  child: Wrap(
                    spacing: OpenVtsSpacing.xs,
                    runSpacing: OpenVtsSpacing.xs,
                    children: AdminInventoryActiveFilter.values
                        .map(
                          (option) => OpenVtsListPageChoiceChip(
                            label: _activeLabel(option),
                            selected: active == option,
                            onSelected: () =>
                                setSheetState(() => active = option),
                          ),
                        )
                        .toList(growable: false),
                  ),
                ),
                if (providers.isNotEmpty)
                  OpenVtsListPageOptionsSection(
                    label: 'Provider',
                    child: Wrap(
                      spacing: OpenVtsSpacing.xs,
                      runSpacing: OpenVtsSpacing.xs,
                      children: [
                        OpenVtsListPageChoiceChip(
                          label: 'All Providers',
                          selected: provider == null,
                          onSelected: () =>
                              setSheetState(() => provider = null),
                        ),
                        for (final item in providers)
                          OpenVtsListPageChoiceChip(
                            label: item,
                            selected: provider == item,
                            onSelected: () =>
                                setSheetState(() => provider = item),
                          ),
                      ],
                    ),
                  ),
              ],
              primaryActionLabel: 'Apply filters',
              onPrimaryAction: () {
                controller.setSimStatusFilter(status);
                controller.setSimActiveFilter(active);
                controller.setDeviceProviderFilter(provider);
                Navigator.of(sheetContext).pop();
              },
              secondaryActionLabel: 'Reset',
              onSecondaryAction: () {
                setSheetState(() {
                  status = AdminInventoryStatusFilter.all;
                  active = AdminInventoryActiveFilter.all;
                  provider = null;
                });
              },
            );
          },
        );
      },
    );
  }

  Future<void> _showSortSheet(BuildContext context, WidgetRef ref) async {
    final controller = ref.read(adminInventoryControllerProvider.notifier);
    final state = ref.read(adminInventoryControllerProvider);

    if (state.selectedTab == AdminInventoryTab.devices) {
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
            title: 'Sort devices',
            sections: [
              OpenVtsListPageOptionsSection(
                label: 'Order by',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: AdminInventoryDeviceSortOption.values
                      .map(
                        (option) => OpenVtsListPageRadioRow(
                          label: switch (option) {
                            AdminInventoryDeviceSortOption.newest => 'Newest',
                            AdminInventoryDeviceSortOption.imeiAsc =>
                              'IMEI A-Z',
                            AdminInventoryDeviceSortOption.typeAsc =>
                              'Type A-Z',
                            AdminInventoryDeviceSortOption.activeFirst =>
                              'Active first',
                          },
                          selected: state.deviceSortOption == option,
                          onTap: () {
                            controller.setDeviceSortOption(option);
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
      return;
    }

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
          title: 'Sort SIM cards',
          sections: [
            OpenVtsListPageOptionsSection(
              label: 'Order by',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: AdminInventorySimSortOption.values
                    .map(
                      (option) => OpenVtsListPageRadioRow(
                        label: switch (option) {
                          AdminInventorySimSortOption.newest => 'Newest',
                          AdminInventorySimSortOption.simNumberAsc =>
                            'SIM Number A-Z',
                          AdminInventorySimSortOption.providerAsc =>
                            'Provider A-Z',
                          AdminInventorySimSortOption.activeFirst =>
                            'Active first',
                        },
                        selected: state.simSortOption == option,
                        onTap: () {
                          controller.setSimSortOption(option);
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

class _InventoryBody extends StatelessWidget {
  const _InventoryBody({
    required this.state,
    required this.controller,
    required this.onAdd,
    required this.onOpenFilters,
    required this.onOpenSort,
    required this.onEditDevice,
    required this.onEditSim,
  });

  final AdminInventoryState state;
  final AdminInventoryController controller;
  final VoidCallback onAdd;
  final VoidCallback onOpenFilters;
  final VoidCallback onOpenSort;
  final ValueChanged<AdminInventoryDevice> onEditDevice;
  final ValueChanged<AdminInventorySimCard> onEditSim;

  @override
  Widget build(BuildContext context) {
    final isDevices = state.selectedTab == AdminInventoryTab.devices;
    final filteredCount =
        isDevices ? state.deviceFilteredCount : state.simFilteredCount;
    final visible = isDevices ? state.visibleDevices : state.visibleSimCards;
    final searchQuery =
        isDevices ? state.deviceSearchQuery : state.simSearchQuery;
    final recordsPerPage =
        isDevices ? state.deviceRecordsPerPage : state.simRecordsPerPage;
    final hasActiveFilters = isDevices
        ? _deviceHasActiveFilters(state)
        : _simHasActiveFilters(state);
    final errorMessage =
        isDevices ? state.devicesErrorMessage : state.simCardsErrorMessage;

    return Column(
      children: [
        OpenVtsListPageHeaderCard(
          icon: Icons.inventory_2_outlined,
          countLabel: isDevices
              ? '$filteredCount Device${filteredCount == 1 ? '' : 's'}'
              : '$filteredCount SIM Card${filteredCount == 1 ? '' : 's'}',
          createLabel: 'Add Inventory',
          onCreate: onAdd,
          isCreateLoading: state.isCreating,
          footer: _InventoryTabs(
            selectedTab: state.selectedTab,
            onTap: controller.selectTab,
          ),
        ),
        const SizedBox(height: OpenVtsSpacing.sm),
        OpenVtsListPageToolbar(
          searchQuery: searchQuery,
          hintText: isDevices
              ? 'Search IMEI, device type, SIM number\u2026'
              : 'Search SIM, IMSI, ICCID, provider\u2026',
          hasActiveFilters: hasActiveFilters,
          onSearchChanged: (value) {
            if (isDevices) {
              controller.setDeviceSearchQuery(value);
            } else {
              controller.setSimSearchQuery(value);
            }
          },
          onOpenFilters: onOpenFilters,
          filterTooltip: isDevices ? 'Filter devices' : 'Filter SIM cards',
          onOpenSort: onOpenSort,
          sortTooltip: isDevices ? 'Sort devices' : 'Sort SIM cards',
          recordsPerPage: recordsPerPage,
          onRecordsChanged: (value) {
            if (isDevices) {
              controller.setDeviceRecordsPerPage(value);
            } else {
              controller.setSimRecordsPerPage(value);
            }
          },
        ),
        if (errorMessage != null) ...[
          const SizedBox(height: OpenVtsSpacing.sm),
          _InlineErrorBanner(message: errorMessage),
        ],
        Expanded(
          child: RefreshIndicator(
            onRefresh: controller.refreshCurrentTab,
            child: filteredCount == 0
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      const SizedBox(height: OpenVtsSpacing.section),
                      OpenVtsEmptyState(
                        title: isDevices
                            ? 'No devices found'
                            : 'No SIM cards found',
                        message: hasActiveFilters
                            ? 'Try a different search or filter.'
                            : 'Add inventory to get started.',
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
                          currentPage: isDevices
                              ? state.safeDeviceCurrentPage
                              : state.safeSimCurrentPage,
                          pageCount: isDevices
                              ? state.devicePageCount
                              : state.simPageCount,
                          showingCount: isDevices
                              ? state.deviceShowingCount
                              : state.simShowingCount,
                          totalCount: filteredCount,
                          onPrev: () {
                            if (isDevices) {
                              controller.goToDevicePage(
                                state.safeDeviceCurrentPage - 1,
                              );
                            } else {
                              controller.goToSimPage(
                                state.safeSimCurrentPage - 1,
                              );
                            }
                          },
                          onNext: () {
                            if (isDevices) {
                              controller.goToDevicePage(
                                state.safeDeviceCurrentPage + 1,
                              );
                            } else {
                              controller.goToSimPage(
                                state.safeSimCurrentPage + 1,
                              );
                            }
                          },
                        );
                      }

                      if (isDevices) {
                        final device = state.visibleDevices[index];
                        return AdminInventoryDeviceCard(
                          device: device,
                          isEditing: state.editingDeviceIds.contains(device.id),
                          onEdit: () => onEditDevice(device),
                        );
                      }

                      final simCard = state.visibleSimCards[index];
                      return AdminInventorySimCardWidget(
                        simCard: simCard,
                        isEditing: state.editingSimIds.contains(simCard.id),
                        onEdit: () => onEditSim(simCard),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }
}

class _InventoryTabs extends StatelessWidget {
  const _InventoryTabs({
    required this.selectedTab,
    required this.onTap,
  });

  final String selectedTab;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _tab(context, 'Devices', AdminInventoryTab.devices),
        const SizedBox(width: OpenVtsSpacing.xs),
        _tab(context, 'SIM Cards', AdminInventoryTab.simCards),
      ],
    );
  }

  Widget _tab(BuildContext context, String label, String value) {
    final selected = selectedTab == value;
    final background = selected
        ? OpenVtsListPageTheme.primaryInkColor(context)
        : OpenVtsListPageTheme.softSurfaceColor(context);
    final foreground = selected
        ? Theme.of(context).colorScheme.surface
        : OpenVtsListPageTheme.primaryInkColor(context);

    return Material(
      color: background,
      borderRadius: BorderRadius.circular(OpenVtsRadius.pill),
      child: InkWell(
        borderRadius: BorderRadius.circular(OpenVtsRadius.pill),
        onTap: () => onTap(value),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: OpenVtsSpacing.md,
            vertical: OpenVtsSpacing.xs,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(OpenVtsRadius.pill),
            border: Border.all(
              color: selected
                  ? OpenVtsListPageTheme.primaryInkColor(context)
                  : OpenVtsListPageTheme.softBorderColor(context),
            ),
          ),
          child: Text(
            label,
            style: OpenVtsTypography.label.copyWith(
              color: foreground,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
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

bool _deviceHasActiveFilters(AdminInventoryState state) {
  return state.deviceSearchQuery.trim().isNotEmpty ||
      state.deviceStatusFilter != AdminInventoryStatusFilter.all ||
      state.deviceActiveFilter != AdminInventoryActiveFilter.all;
}

bool _simHasActiveFilters(AdminInventoryState state) {
  return state.simSearchQuery.trim().isNotEmpty ||
      state.simStatusFilter != AdminInventoryStatusFilter.all ||
      state.simActiveFilter != AdminInventoryActiveFilter.all ||
      (state.deviceProviderFilter?.trim().isNotEmpty ?? false);
}

String _statusLabel(AdminInventoryStatusFilter value) {
  return switch (value) {
    AdminInventoryStatusFilter.all => 'All',
    AdminInventoryStatusFilter.inStock => 'In Stock',
    AdminInventoryStatusFilter.inUse => 'In Use',
    AdminInventoryStatusFilter.inScrap => 'In Scrap',
  };
}

String _activeLabel(AdminInventoryActiveFilter value) {
  return switch (value) {
    AdminInventoryActiveFilter.all => 'All',
    AdminInventoryActiveFilter.active => 'Active',
    AdminInventoryActiveFilter.inactive => 'Inactive',
  };
}
