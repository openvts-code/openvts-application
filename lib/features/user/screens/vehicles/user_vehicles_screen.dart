import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/open_vts_colors.dart';
import '../../../../core/theme/open_vts_radius.dart';
import '../../../../core/theme/open_vts_spacing.dart';
import '../../../../core/theme/open_vts_typography.dart';
import '../../../../shared/widgets/open_vts_card.dart';
import '../../../../shared/widgets/open_vts_empty_state.dart';
import '../../../../shared/widgets/open_vts_error_view.dart';
import '../../../../shared/widgets/open_vts_loader.dart';
import '../../../../shared/widgets/open_vts_page_scaffold.dart';
import '../../../../shared/widgets/open_vts_search_field.dart';
import '../../controllers/user_providers.dart';
import '../../controllers/user_vehicles_controller.dart';
import '../../models/user_vehicle_model.dart';
import '../../models/user_vehicle_state.dart';
import 'widgets/user_vehicle_card.dart';

class UserVehiclesScreen extends ConsumerWidget {
  const UserVehiclesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(userVehiclesControllerProvider);
    final controller = ref.read(userVehiclesControllerProvider.notifier);

    return OpenVtsPageScaffold(
      title: 'Vehicles',
      headerMode: OpenVtsPageHeaderMode.closeable,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: OpenVtsSpacing.xxs),
          child: IconButton(
            tooltip: 'Refresh',
            onPressed: state.isRefreshing ? null : controller.refresh,
            icon: state.isRefreshing
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh_rounded, size: 18),
          ),
        ),
      ],
      body: _buildBody(state, controller),
    );
  }

  Widget _buildBody(
    UserVehiclesState state,
    UserVehiclesController controller,
  ) {
    if (state.isLoading && state.vehicles.isEmpty) {
      return const OpenVtsLoader();
    }

    if (state.errorMessage != null && state.vehicles.isEmpty) {
      return OpenVtsErrorView(
        message: state.errorMessage!,
        onRetry: controller.load,
      );
    }

    final typeOptions = _typeOptions(state.vehicles);

    return RefreshIndicator(
      onRefresh: controller.refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          _ToolbarCard(
            state: state,
            typeOptions: typeOptions,
            onSearchChanged: controller.setSearchQuery,
            onStatusChanged: controller.setStatusFilter,
            onTypeChanged: controller.setTypeFilter,
            onClearFilters: controller.clearFilters,
          ),
          if (state.errorMessage != null) ...[
            const SizedBox(height: OpenVtsSpacing.sm),
            _InlineError(message: state.errorMessage!),
          ],
          const SizedBox(height: OpenVtsSpacing.sm),
          if (state.filteredVehicles.isEmpty)
            OpenVtsEmptyState(
              title:
                  state.hasActiveFilters ? 'No vehicles found' : 'No vehicles',
              message: state.hasActiveFilters
                  ? 'Try changing the search or filters.'
                  : 'No vehicles are assigned yet.',
            )
          else
            for (final vehicle in state.filteredVehicles) ...[
              UserVehicleCard(vehicle: vehicle),
              if (vehicle != state.filteredVehicles.last)
                const SizedBox(height: OpenVtsSpacing.sm),
            ],
          const SizedBox(height: OpenVtsSpacing.lg),
        ],
      ),
    );
  }
}

class _ToolbarCard extends StatelessWidget {
  const _ToolbarCard({
    required this.state,
    required this.typeOptions,
    required this.onSearchChanged,
    required this.onStatusChanged,
    required this.onTypeChanged,
    required this.onClearFilters,
  });

  final UserVehiclesState state;
  final List<_TypeFilterOption> typeOptions;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<UserVehicleStatusFilter> onStatusChanged;
  final ValueChanged<String?> onTypeChanged;
  final VoidCallback onClearFilters;

  @override
  Widget build(BuildContext context) {
    return OpenVtsCard(
      padding: const EdgeInsets.all(OpenVtsSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${state.filteredVehicles.length} of ${state.vehicles.length} vehicles',
                  style: OpenVtsTypography.label.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (state.hasActiveFilters)
                TextButton.icon(
                  onPressed: onClearFilters,
                  icon: const Icon(Icons.filter_alt_off_outlined, size: 15),
                  label: Text(
                    'Clear',
                    style: OpenVtsTypography.meta.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: OpenVtsSpacing.xs),
          OpenVtsSearchField(
            hintText: 'Search vehicle, plate, VIN, IMEI, SIM...',
            onChanged: onSearchChanged,
          ),
          const SizedBox(height: OpenVtsSpacing.sm),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final filter in UserVehicleStatusFilter.values) ...[
                  _FilterChip(
                    label: _statusFilterLabel(filter),
                    selected: state.statusFilter == filter,
                    onTap: () => onStatusChanged(filter),
                  ),
                  const SizedBox(width: OpenVtsSpacing.xs),
                ],
                if (typeOptions.length > 1)
                  _TypeFilterButton(
                    value: state.typeFilter,
                    options: typeOptions,
                    onChanged: onTypeChanged,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      selected: selected,
      showCheckmark: false,
      label: Text(label),
      onSelected: (_) => onTap(),
      labelStyle: OpenVtsTypography.meta.copyWith(
        color: selected ? OpenVtsColors.white : OpenVtsColors.textPrimary,
        fontWeight: FontWeight.w800,
      ),
      selectedColor: OpenVtsColors.brandInk,
      backgroundColor: OpenVtsColors.white,
      side: const BorderSide(color: OpenVtsColors.border),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(OpenVtsRadius.pill),
      ),
    );
  }
}

class _TypeFilterButton extends StatelessWidget {
  const _TypeFilterButton({
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String? value;
  final List<_TypeFilterOption> options;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final selected = _selectedOption;
    return PopupMenuButton<String?>(
      tooltip: 'Vehicle type filter',
      enabled: options.isNotEmpty,
      onSelected: onChanged,
      itemBuilder: (context) => [
        const PopupMenuItem<String?>(
          value: null,
          child: Text('All Types'),
        ),
        for (final option in options)
          PopupMenuItem<String?>(
            value: option.value,
            child: Text(option.label),
          ),
      ],
      child: Container(
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: value == null ? OpenVtsColors.white : OpenVtsColors.brandInk,
          borderRadius: BorderRadius.circular(OpenVtsRadius.pill),
          border: Border.all(color: OpenVtsColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.category_outlined,
              size: 15,
              color: value == null
                  ? OpenVtsColors.textPrimary
                  : OpenVtsColors.white,
            ),
            const SizedBox(width: 6),
            Text(
              selected?.label ?? 'All Types',
              style: OpenVtsTypography.meta.copyWith(
                color: value == null
                    ? OpenVtsColors.textPrimary
                    : OpenVtsColors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.expand_more_rounded,
              size: 16,
              color: value == null
                  ? OpenVtsColors.textPrimary
                  : OpenVtsColors.white,
            ),
          ],
        ),
      ),
    );
  }

  _TypeFilterOption? get _selectedOption {
    for (final option in options) {
      if (option.value == value) return option;
    }
    return null;
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(OpenVtsSpacing.sm),
      decoration: BoxDecoration(
        color: OpenVtsColors.error.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(OpenVtsRadius.sm),
        border: Border.all(color: OpenVtsColors.error.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              size: 16, color: OpenVtsColors.error),
          const SizedBox(width: OpenVtsSpacing.xs),
          Expanded(
            child: Text(
              message,
              style: OpenVtsTypography.meta.copyWith(
                color: OpenVtsColors.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TypeFilterOption {
  const _TypeFilterOption({required this.value, required this.label});

  final String value;
  final String label;
}

List<_TypeFilterOption> _typeOptions(List<UserVehicleListItem> vehicles) {
  final byValue = <String, _TypeFilterOption>{};
  for (final vehicle in vehicles) {
    final type = vehicle.vehicleType;
    if (type == null) continue;
    final value = type.id.trim().isNotEmpty
        ? type.id.trim().toLowerCase()
        : type.slug.trim().isNotEmpty
            ? type.slug.trim().toLowerCase()
            : type.name.trim().toLowerCase();
    if (value.isEmpty) continue;
    final label = type.name.trim().isNotEmpty
        ? type.name.trim()
        : type.slug.trim().isNotEmpty
            ? type.slug.trim()
            : type.id.trim();
    byValue[value] = _TypeFilterOption(value: value, label: label);
  }
  final options = byValue.values.toList(growable: false)
    ..sort((left, right) => left.label.compareTo(right.label));
  return options;
}

String _statusFilterLabel(UserVehicleStatusFilter filter) {
  return switch (filter) {
    UserVehicleStatusFilter.all => 'All',
    UserVehicleStatusFilter.active => 'Active',
    UserVehicleStatusFilter.inactive => 'Inactive',
    UserVehicleStatusFilter.licenseBlocked => 'License Blocked',
  };
}
