import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/open_vts_colors.dart';
import '../../../../core/theme/open_vts_radius.dart';
import '../../../../core/theme/open_vts_spacing.dart';
import '../../../../core/theme/open_vts_typography.dart';
import '../../../../shared/widgets/open_vts_empty_state.dart';
import '../../../../shared/widgets/open_vts_error_view.dart';
import '../../../../shared/widgets/open_vts_loader.dart';
import '../../../../shared/widgets/open_vts_page_scaffold.dart';
import '../../controllers/admin_providers.dart';
import '../../models/admin_vehicle_state.dart';
import 'widgets/admin_vehicle_card.dart';

class AdminVehiclesScreen extends ConsumerWidget {
  const AdminVehiclesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(adminVehiclesControllerProvider);
    final controller = ref.read(adminVehiclesControllerProvider.notifier);

    final typeOptions = <String>{
      for (final vehicle in state.vehicles)
        if (vehicle.vehicleTypeName.trim().isNotEmpty)
          vehicle.vehicleTypeName.trim(),
    }.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    final hasActiveFilters = state.searchQuery.trim().isNotEmpty ||
        state.statusFilter != AdminVehicleStatusFilter.all ||
        state.typeFilter.trim().isNotEmpty;

    return OpenVtsPageScaffold(
      title: 'Vehicles',
      headerMode: OpenVtsPageHeaderMode.closeable,
      actions: [
        IconButton(
          tooltip: 'Refresh vehicles',
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
      body: state.isLoading && state.vehicles.isEmpty
          ? const OpenVtsLoader()
          : state.errorMessage != null && state.filteredVehicles.isEmpty
              ? OpenVtsErrorView(
                  message: state.errorMessage!,
                  onRetry: controller.load,
                )
              : Column(
                  children: [
                    _VehiclesHeaderCard(
                      count: state.filteredVehicles.length,
                      totalCount: state.vehicles.length,
                      onCreateVehicle: () =>
                          context.push(RoutePaths.adminVehicleCreate),
                    ),
                    const SizedBox(height: OpenVtsSpacing.sm),
                    _VehiclesToolbar(
                      searchQuery: state.searchQuery,
                      hasActiveFilters: hasActiveFilters,
                      onSearchChanged: controller.setSearchQuery,
                      onOpenFilters: () => _openFiltersSheet(
                        context,
                        ref,
                        typeOptions: typeOptions,
                      ),
                    ),
                    const SizedBox(height: OpenVtsSpacing.sm),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: controller.refresh,
                        child: state.filteredVehicles.isEmpty
                            ? ListView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                children: const [
                                  SizedBox(height: OpenVtsSpacing.section),
                                  OpenVtsEmptyState(
                                    title: 'No vehicles',
                                    message:
                                        'No matching vehicles found. Try a different search or filter.',
                                  ),
                                ],
                              )
                            : ListView.separated(
                                physics: const AlwaysScrollableScrollPhysics(),
                                itemCount: state.filteredVehicles.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: OpenVtsSpacing.sm),
                                itemBuilder: (context, index) {
                                  final vehicle = state.filteredVehicles[index];
                                  return AdminVehicleCard(
                                    vehicle: vehicle,
                                    onTap: () => context.push(
                                      RoutePaths.adminVehicleDetailsPath(
                                        vehicle.id,
                                      ),
                                      extra: vehicle,
                                    ),
                                  );
                                },
                              ),
                      ),
                    ),
                  ],
                ),
    );
  }

  Future<void> _openFiltersSheet(
    BuildContext context,
    WidgetRef ref, {
    required List<String> typeOptions,
  }) async {
    final controller = ref.read(adminVehiclesControllerProvider.notifier);
    final state = ref.read(adminVehiclesControllerProvider);

    var selectedStatus = state.statusFilter;
    var selectedType = state.typeFilter;

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
            return _OptionsSheet(
              title: 'Filter vehicles',
              sections: [
                _OptionsSheetSection(
                  label: 'Status',
                  child: Wrap(
                    spacing: OpenVtsSpacing.xs,
                    runSpacing: OpenVtsSpacing.xs,
                    children: AdminVehicleStatusFilter.values
                        .map(
                          (option) => _ChoiceChip(
                            label: _statusFilterLabel(option),
                            selected: selectedStatus == option,
                            onSelected: () =>
                                setSheetState(() => selectedStatus = option),
                          ),
                        )
                        .toList(growable: false),
                  ),
                ),
                _OptionsSheetSection(
                  label: 'Vehicle type',
                  child: Wrap(
                    spacing: OpenVtsSpacing.xs,
                    runSpacing: OpenVtsSpacing.xs,
                    children: [
                      _ChoiceChip(
                        label: 'All Types',
                        selected: selectedType.trim().isEmpty,
                        onSelected: () =>
                            setSheetState(() => selectedType = ''),
                      ),
                      ...typeOptions.map(
                        (type) => _ChoiceChip(
                          label: type,
                          selected: selectedType == type,
                          onSelected: () =>
                              setSheetState(() => selectedType = type),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              primaryActionLabel: 'Apply filters',
              onPrimaryAction: () {
                controller.setStatusFilter(selectedStatus);
                controller.setTypeFilter(selectedType);
                Navigator.of(sheetContext).pop();
              },
              secondaryActionLabel: 'Reset',
              onSecondaryAction: () {
                setSheetState(() {
                  selectedStatus = AdminVehicleStatusFilter.all;
                  selectedType = '';
                });
              },
            );
          },
        );
      },
    );
  }
}

String _statusFilterLabel(AdminVehicleStatusFilter filter) {
  return switch (filter) {
    AdminVehicleStatusFilter.all => 'All',
    AdminVehicleStatusFilter.active => 'Active',
    AdminVehicleStatusFilter.inactive => 'Inactive',
    AdminVehicleStatusFilter.licenseBlocked => 'License Blocked',
  };
}

class _VehiclesHeaderCard extends StatelessWidget {
  const _VehiclesHeaderCard({
    required this.count,
    required this.totalCount,
    required this.onCreateVehicle,
  });

  final int count;
  final int totalCount;
  final VoidCallback onCreateVehicle;

  @override
  Widget build(BuildContext context) {
    final suffix = count == 1 ? 'Vehicle' : 'Vehicles';
    final summary = count == totalCount
        ? '$count $suffix'
        : '$count of $totalCount $suffix';

    return _RoundedSurface(
      padding: const EdgeInsets.fromLTRB(
        OpenVtsSpacing.md,
        OpenVtsSpacing.sm,
        OpenVtsSpacing.sm,
        OpenVtsSpacing.sm,
      ),
      child: Row(
        children: [
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: _softSurfaceColor(context),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.local_shipping_outlined,
              size: 22,
              color: _primaryInkColor(context),
            ),
          ),
          const SizedBox(width: OpenVtsSpacing.sm),
          Expanded(
            child: Text(
              summary,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
            ),
          ),
          const SizedBox(width: OpenVtsSpacing.sm),
          _PrimaryCreateButton(onPressed: onCreateVehicle),
        ],
      ),
    );
  }
}

class _PrimaryCreateButton extends StatelessWidget {
  const _PrimaryCreateButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background =
        isDark ? OpenVtsColors.surfaceElevated : OpenVtsColors.brandInk;
    final foreground =
        isDark ? OpenVtsColors.brandInk : OpenVtsColors.white;

    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.add_rounded, size: 18),
      label: const Text('New Vehicle'),
      style: ElevatedButton.styleFrom(
        backgroundColor: background,
        foregroundColor: foreground,
        elevation: 0,
        padding: const EdgeInsets.symmetric(
          horizontal: OpenVtsSpacing.md,
          vertical: OpenVtsSpacing.sm,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(OpenVtsRadius.md),
        ),
        textStyle: OpenVtsTypography.label.copyWith(
          fontWeight: FontWeight.w600,
        ),
        visualDensity: VisualDensity.compact,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}

class _VehiclesToolbar extends StatefulWidget {
  const _VehiclesToolbar({
    required this.searchQuery,
    required this.hasActiveFilters,
    required this.onSearchChanged,
    required this.onOpenFilters,
  });

  final String searchQuery;
  final bool hasActiveFilters;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onOpenFilters;

  @override
  State<_VehiclesToolbar> createState() => _VehiclesToolbarState();
}

class _VehiclesToolbarState extends State<_VehiclesToolbar> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.searchQuery);
  }

  @override
  void didUpdateWidget(covariant _VehiclesToolbar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.searchQuery != _searchController.text) {
      _searchController.value = TextEditingValue(
        text: widget.searchQuery,
        selection: TextSelection.collapsed(offset: widget.searchQuery.length),
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _RoundedSurface(
      padding: const EdgeInsets.all(OpenVtsSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: _SearchInput(
              controller: _searchController,
              onChanged: widget.onSearchChanged,
            ),
          ),
          const SizedBox(width: OpenVtsSpacing.xs),
          _SquareIconButton(
            icon: Icons.filter_alt_outlined,
            tooltip: 'Filter vehicles',
            onPressed: widget.onOpenFilters,
            showDot: widget.hasActiveFilters,
          ),
        ],
      ),
    );
  }
}

class _SearchInput extends StatelessWidget {
  const _SearchInput({
    required this.controller,
    required this.onChanged,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  static const double _height = 40;

  static const TextStyle _baseStyle = TextStyle(
    fontFamily: OpenVtsTypography.primaryFontFamily,
    fontFamilyFallback: OpenVtsTypography.fontFallback,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.2,
    leadingDistribution: TextLeadingDistribution.even,
  );

  @override
  Widget build(BuildContext context) {
    final fillColor = _softSurfaceColor(context);
    final borderColor = _softBorderColor(context);

    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(OpenVtsRadius.md),
      borderSide: BorderSide(color: borderColor),
    );
    final focusedBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(OpenVtsRadius.md),
      borderSide: BorderSide(color: _primaryInkColor(context), width: 1.2),
    );

    return SizedBox(
      height: _height,
      child: ValueListenableBuilder<TextEditingValue>(
        valueListenable: controller,
        builder: (context, value, _) {
          final hasText = value.text.isNotEmpty;
          return TextField(
            controller: controller,
            onChanged: onChanged,
            textAlignVertical: TextAlignVertical.center,
            cursorColor: _primaryInkColor(context),
            cursorWidth: 1.4,
            style: _baseStyle.copyWith(color: OpenVtsColors.textPrimary),
            strutStyle: const StrutStyle(
              fontFamily: OpenVtsTypography.primaryFontFamily,
              fontFamilyFallback: OpenVtsTypography.fontFallback,
              fontSize: 14,
              height: 1.2,
              leading: 0,
              forceStrutHeight: true,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: fillColor,
              isDense: true,
              isCollapsed: false,
              hintText: 'Search vehicle, plate, VIN, IMEI, SIM, user\u2026',
              hintStyle: _baseStyle.copyWith(
                color: OpenVtsColors.textTertiary,
                fontWeight: FontWeight.w400,
              ),
              prefixIcon: const Padding(
                padding: EdgeInsetsDirectional.only(
                  start: OpenVtsSpacing.sm,
                  end: OpenVtsSpacing.xs,
                ),
                child: Icon(
                  Icons.search_rounded,
                  size: 18,
                  color: OpenVtsColors.textSecondary,
                ),
              ),
              prefixIconConstraints: const BoxConstraints(
                minWidth: 0,
                minHeight: _height,
              ),
              suffixIcon: !hasText
                  ? null
                  : Padding(
                      padding: const EdgeInsetsDirectional.only(
                        end: OpenVtsSpacing.xxs,
                      ),
                      child: IconButton(
                        tooltip: 'Clear search',
                        onPressed: () {
                          controller.clear();
                          onChanged('');
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 28,
                          minHeight: 28,
                        ),
                        splashRadius: 16,
                        icon: const Icon(
                          Icons.close_rounded,
                          size: 16,
                          color: OpenVtsColors.textSecondary,
                        ),
                      ),
                    ),
              suffixIconConstraints: const BoxConstraints(
                minWidth: 0,
                minHeight: _height,
              ),
              contentPadding: const EdgeInsetsDirectional.only(
                end: OpenVtsSpacing.sm,
              ),
              border: border,
              enabledBorder: border,
              focusedBorder: focusedBorder,
            ),
          );
        },
      ),
    );
  }
}

class _SquareIconButton extends StatelessWidget {
  const _SquareIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.showDot = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final bool showDot;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: _softSurfaceColor(context),
        borderRadius: BorderRadius.circular(OpenVtsRadius.md),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(OpenVtsRadius.md),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(OpenVtsRadius.md),
                  border: Border.all(color: _softBorderColor(context)),
                ),
                alignment: Alignment.center,
                child: Icon(
                  icon,
                  size: 18,
                  color: _primaryInkColor(context),
                ),
              ),
              if (showDot)
                PositionedDirectional(
                  top: -2,
                  end: -2,
                  child: Container(
                    height: 10,
                    width: 10,
                    decoration: BoxDecoration(
                      color: OpenVtsColors.brandInk,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Theme.of(context).colorScheme.surface,
                        width: 2,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OptionsSheet extends StatelessWidget {
  const _OptionsSheet({
    required this.title,
    required this.sections,
    this.primaryActionLabel,
    this.onPrimaryAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
  });

  final String title;
  final List<_OptionsSheetSection> sections;
  final String? primaryActionLabel;
  final VoidCallback? onPrimaryAction;
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          OpenVtsSpacing.md,
          OpenVtsSpacing.sm,
          OpenVtsSpacing.md,
          OpenVtsSpacing.lg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                height: 4,
                width: 40,
                margin: const EdgeInsets.only(bottom: OpenVtsSpacing.sm),
                decoration: BoxDecoration(
                  color: OpenVtsColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.close_rounded, size: 20),
                  tooltip: 'Close',
                ),
              ],
            ),
            const SizedBox(height: OpenVtsSpacing.sm),
            for (final section in sections) ...[
              Text(
                section.label,
                style: OpenVtsTypography.label.copyWith(
                  color: OpenVtsColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: OpenVtsSpacing.xs),
              section.child,
              const SizedBox(height: OpenVtsSpacing.md),
            ],
            if (primaryActionLabel != null && onPrimaryAction != null) ...[
              ElevatedButton(
                onPressed: onPrimaryAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryInkColor(context),
                  foregroundColor: OpenVtsColors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    vertical: OpenVtsSpacing.sm,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(OpenVtsRadius.md),
                  ),
                ),
                child: Text(primaryActionLabel!),
              ),
            ],
            if (secondaryActionLabel != null && onSecondaryAction != null) ...[
              const SizedBox(height: OpenVtsSpacing.xs),
              TextButton(
                onPressed: onSecondaryAction,
                child: Text(secondaryActionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _OptionsSheetSection {
  const _OptionsSheetSection({
    required this.label,
    required this.child,
  });

  final String label;
  final Widget child;
}

class _ChoiceChip extends StatelessWidget {
  const _ChoiceChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      checkmarkColor: OpenVtsColors.white,
      selectedColor: _primaryInkColor(context),
      backgroundColor: _softSurfaceColor(context),
      side: BorderSide(color: _softBorderColor(context)),
      labelStyle: OpenVtsTypography.label.copyWith(
        color: selected ? OpenVtsColors.white : OpenVtsColors.textSecondary,
        fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
      ),
      onSelected: (_) => onSelected(),
    );
  }
}

class _RoundedSurface extends StatelessWidget {
  const _RoundedSurface({
    required this.child,
    this.padding = const EdgeInsets.all(OpenVtsSpacing.md),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(OpenVtsRadius.lg),
        border: Border.all(color: _softBorderColor(context)),
      ),
      child: child,
    );
  }
}

Color _softSurfaceColor(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark
      ? OpenVtsColors.darkSurface
      : OpenVtsColors.background;
}

Color _softBorderColor(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark
      ? OpenVtsColors.darkBorder
      : OpenVtsColors.border;
}

Color _primaryInkColor(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark
      ? OpenVtsColors.darkTextPrimary
      : OpenVtsColors.brandInk;
}
