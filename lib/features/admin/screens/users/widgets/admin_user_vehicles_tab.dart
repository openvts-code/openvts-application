import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/open_vts_colors.dart';
import '../../../../../core/theme/open_vts_radius.dart';
import '../../../../../core/theme/open_vts_spacing.dart';
import '../../../../../core/theme/open_vts_typography.dart';
import '../../../../../core/utils/date_time_formatter.dart';
import '../../../../../shared/helpers/toast_helper.dart';
import '../../../../../shared/widgets/open_vts_bottom_sheet.dart';
import '../../../../../shared/widgets/open_vts_button.dart';
import '../../../../../shared/widgets/open_vts_card.dart';
import '../../../../../shared/widgets/open_vts_error_view.dart';
import '../../../controllers/admin_providers.dart';
import '../../../controllers/admin_user_details_controller.dart';
import '../../../models/admin_user_details_model.dart';

class AdminUserVehiclesTab extends ConsumerStatefulWidget {
  const AdminUserVehiclesTab({
    super.key,
    required this.userId,
  });

  final String userId;

  @override
  ConsumerState<AdminUserVehiclesTab> createState() =>
      _AdminUserVehiclesTabState();
}

enum _VehicleFilter { all, blocked, expiring }

class _AdminUserVehiclesTabState extends ConsumerState<AdminUserVehiclesTab> {
  final _searchController = TextEditingController();
  var _query = '';
  var _filter = _VehicleFilter.all;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = adminUserDetailsControllerProvider(widget.userId);
    final state = ref.watch(provider);
    final controller = ref.read(provider.notifier);
    final isInitialLoading = state.isLoadingVehicles &&
        state.linkedVehicles.isEmpty &&
        state.availableVehicles.isEmpty;

    if (isInitialLoading) {
      return const _SectionLoader(title: 'Vehicles');
    }

    if (state.sectionErrorMessage != null &&
        state.linkedVehicles.isEmpty &&
        state.availableVehicles.isEmpty) {
      return _SectionErrorCard(
        message: state.sectionErrorMessage!,
        onRetry: controller.loadVehicles,
      );
    }

    final assigned = state.linkedVehicles.where(_matchesFilters).toList();
    final blockedCount =
        state.linkedVehicles.where((v) => v.isLicenseBlocked).length;
    final expiringCount = state.linkedVehicles
        .where((v) => _isExpiringSoon(v.secondaryExpiry))
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StatsGrid(
          total: state.linkedVehicles.length,
          available: state.availableVehicles.length,
          blocked: blockedCount,
          expiring: expiringCount,
        ),
        const SizedBox(height: OpenVtsSpacing.sm),
        _SummaryCard(
          assignedCount: state.linkedVehicles.length,
          availableCount: state.availableVehicles.length,
          isLoading: state.isLoadingVehicles,
          isAssigning: state.isLinkingVehicle,
          onAssign: state.availableVehicles.isEmpty || state.isLinkingVehicle
              ? null
              : () => _showAssignSheet(state.availableVehicles, controller),
        ),
        const SizedBox(height: OpenVtsSpacing.sm),
        if (state.sectionErrorMessage != null) ...[
          _InlineError(message: state.sectionErrorMessage!),
          const SizedBox(height: OpenVtsSpacing.sm),
        ],
        _SearchField(
          controller: _searchController,
          onChanged: (value) => setState(() => _query = value),
        ),
        const SizedBox(height: OpenVtsSpacing.xs),
        _FilterChips(
          value: _filter,
          onChanged: (next) => setState(() => _filter = next),
        ),
        const SizedBox(height: OpenVtsSpacing.sm),
        if (assigned.isEmpty)
          _EmptyCard(
            label: _query.trim().isEmpty
                ? 'No assigned vehicles'
                : 'No vehicles match your search',
          )
        else
          for (final vehicle in assigned) ...[
            _VehicleCard(
              vehicle: vehicle,
              isUnassigning: state.isUnlinkingVehicle,
              onUnassign: state.isUnlinkingVehicle
                  ? null
                  : () => _unassignVehicle(controller, vehicle),
            ),
            if (vehicle != assigned.last)
              const SizedBox(height: OpenVtsSpacing.sm),
          ],
      ],
    );
  }

  bool _matchesFilters(AdminUserVehicle vehicle) {
    if (!_matchesQuery(vehicle)) {
      return false;
    }
    switch (_filter) {
      case _VehicleFilter.all:
        return true;
      case _VehicleFilter.blocked:
        return vehicle.isLicenseBlocked;
      case _VehicleFilter.expiring:
        return _isExpiringSoon(vehicle.secondaryExpiry);
    }
  }

  bool _matchesQuery(AdminUserVehicle vehicle) {
    final normalized = _query.trim().toLowerCase();
    if (normalized.isEmpty) {
      return true;
    }
    return [
      vehicle.name,
      vehicle.plateNumber,
      vehicle.imei,
      vehicle.simNumber,
      vehicle.vin,
      _planName(vehicle),
      _dateText(vehicle.secondaryExpiry),
    ].any((value) => value.toLowerCase().contains(normalized));
  }

  bool _isExpiringSoon(DateTime? expiry) {
    if (expiry == null) {
      return false;
    }
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(expiry.year, expiry.month, expiry.day);
    return due.difference(today).inDays <= 30;
  }

  Future<void> _showAssignSheet(
    List<AdminUserVehicle> availableVehicles,
    AdminUserDetailsController controller,
  ) {
    final provider = adminUserDetailsControllerProvider(widget.userId);
    return OpenVtsBottomSheet.show<void>(
      context: context,
      title: 'Assign Vehicle',
      initialChildSize: 0.72,
      minChildSize: 0.42,
      maxChildSize: 0.92,
      child: _AssignVehicleSheet(
        vehicles: availableVehicles,
        onAssign: (vehicle) async {
          final ok = await controller.linkVehicle(vehicle.id);
          if (!mounted) {
            return false;
          }
          if (ok) {
            ToastHelper.showSuccess('Vehicle assigned.', context: context);
          } else {
            ToastHelper.showError(
              ref.read(provider).sectionErrorMessage ??
                  'Unable to assign vehicle.',
              context: context,
            );
          }
          return ok;
        },
      ),
    );
  }

  Future<void> _unassignVehicle(
    AdminUserDetailsController controller,
    AdminUserVehicle vehicle,
  ) async {
    final provider = adminUserDetailsControllerProvider(widget.userId);
    final ok = await controller.unlinkVehicle(vehicle.id);
    if (!mounted) {
      return;
    }
    if (ok) {
      ToastHelper.showSuccess('Vehicle unassigned.', context: context);
    } else {
      ToastHelper.showError(
        ref.read(provider).sectionErrorMessage ?? 'Unable to unassign vehicle.',
        context: context,
      );
    }
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({
    required this.total,
    required this.available,
    required this.blocked,
    required this.expiring,
  });

  final int total;
  final int available;
  final int blocked;
  final int expiring;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SummaryTile(
            label: 'Vehicles',
            value: total.toString(),
            icon: Icons.directions_car_outlined,
          ),
        ),
        const SizedBox(width: OpenVtsSpacing.xs),
        Expanded(
          child: _SummaryTile(
            label: 'Available',
            value: available.toString(),
            icon: Icons.add_road_outlined,
          ),
        ),
        const SizedBox(width: OpenVtsSpacing.xs),
        Expanded(
          child: _SummaryTile(
            label: 'Blocked',
            value: blocked.toString(),
            icon: Icons.lock_outline,
          ),
        ),
        const SizedBox(width: OpenVtsSpacing.xs),
        Expanded(
          child: _SummaryTile(
            label: 'Expiring',
            value: expiring.toString(),
            icon: Icons.schedule_outlined,
          ),
        ),
      ],
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return OpenVtsCard(
      padding: const EdgeInsets.symmetric(
        horizontal: OpenVtsSpacing.sm,
        vertical: OpenVtsSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: OpenVtsColors.textSecondary),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: OpenVtsColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: OpenVtsColors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.assignedCount,
    required this.availableCount,
    required this.isLoading,
    required this.isAssigning,
    required this.onAssign,
  });

  final int assignedCount;
  final int availableCount;
  final bool isLoading;
  final bool isAssigning;
  final VoidCallback? onAssign;

  @override
  Widget build(BuildContext context) {
    return OpenVtsCard(
      padding: const EdgeInsets.all(OpenVtsSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.directions_car_filled_outlined,
                      size: 17,
                      color: OpenVtsColors.textSecondary,
                    ),
                    const SizedBox(width: OpenVtsSpacing.xs),
                    Text(
                      'Vehicles',
                      style: OpenVtsTypography.label.copyWith(
                        color: OpenVtsColors.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (isLoading) ...[
                      const SizedBox(width: OpenVtsSpacing.xs),
                      const SizedBox(
                        width: 13,
                        height: 13,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: OpenVtsSpacing.xs),
                Text(
                  '$assignedCount assigned - $availableCount available',
                  style: OpenVtsTypography.meta.copyWith(
                    color: OpenVtsColors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 34,
            child: OpenVtsButton(
              label: 'Assign Vehicle',
              height: 34,
              isLoading: isAssigning,
              onPressed: onAssign,
              trailingIcon: Icons.add_rounded,
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.onChanged,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: OpenVtsColors.surface,
        borderRadius: BorderRadius.circular(OpenVtsRadius.sm),
        border: Border.all(color: OpenVtsColors.border),
      ),
      padding: const EdgeInsets.symmetric(horizontal: OpenVtsSpacing.sm),
      child: Row(
        children: [
          const Icon(Icons.search,
              size: 16, color: OpenVtsColors.textSecondary),
          const SizedBox(width: OpenVtsSpacing.xs),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: const TextStyle(
                  fontSize: 13, color: OpenVtsColors.textPrimary),
              decoration: const InputDecoration(
                isDense: true,
                hintText: 'Search assigned vehicles',
                hintStyle:
                    TextStyle(fontSize: 12, color: OpenVtsColors.textTertiary),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          if (controller.text.isNotEmpty)
            GestureDetector(
              onTap: () {
                controller.clear();
                onChanged('');
              },
              child: const Icon(Icons.close,
                  size: 16, color: OpenVtsColors.textSecondary),
            ),
        ],
      ),
    );
  }
}

class _FilterChips extends StatelessWidget {
  const _FilterChips({required this.value, required this.onChanged});

  final _VehicleFilter value;
  final ValueChanged<_VehicleFilter> onChanged;

  static const _options = <(_VehicleFilter, String)>[
    (_VehicleFilter.all, 'All'),
    (_VehicleFilter.blocked, 'Blocked'),
    (_VehicleFilter.expiring, 'Expiring'),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < _options.length; i++) ...[
            _FilterChip(
              label: _options[i].$2,
              selected: value == _options[i].$1,
              onTap: () => onChanged(_options[i].$1),
            ),
            if (i < _options.length - 1) const SizedBox(width: 6),
          ],
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(OpenVtsRadius.pill),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? OpenVtsColors.brandInk : OpenVtsColors.surface,
          borderRadius: BorderRadius.circular(OpenVtsRadius.pill),
          border: Border.all(
            color: selected ? OpenVtsColors.brandInk : OpenVtsColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: selected ? OpenVtsColors.white : OpenVtsColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _VehicleCard extends StatelessWidget {
  const _VehicleCard({
    required this.vehicle,
    required this.isUnassigning,
    required this.onUnassign,
  });

  final AdminUserVehicle vehicle;
  final bool isUnassigning;
  final VoidCallback? onUnassign;

  @override
  Widget build(BuildContext context) {
    return OpenVtsCard(
      padding: const EdgeInsets.all(OpenVtsSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: OpenVtsColors.background,
                  borderRadius: BorderRadius.circular(OpenVtsRadius.md),
                  border: Border.all(color: OpenVtsColors.border),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.directions_car_filled_outlined,
                  size: 20,
                  color: OpenVtsColors.textSecondary,
                ),
              ),
              const SizedBox(width: OpenVtsSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _vehicleTitle(vehicle),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: OpenVtsColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _vehicleSubtitle(vehicle),
                      style: const TextStyle(
                        fontSize: 11,
                        color: OpenVtsColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              _TinyTextButton(
                label: 'Unassign',
                icon: Icons.link_off_rounded,
                isLoading: isUnassigning,
                onPressed: onUnassign,
              ),
            ],
          ),
          const SizedBox(height: OpenVtsSpacing.sm),
          Wrap(
            spacing: OpenVtsSpacing.xs,
            runSpacing: OpenVtsSpacing.xs,
            children: [
              _MetaPill(
                  icon: Icons.memory_rounded,
                  label: 'IMEI ${_displayValue(vehicle.imei)}'),
              if (vehicle.simNumber.trim().isNotEmpty)
                _MetaPill(
                    icon: Icons.sim_card_outlined,
                    label: 'SIM ${vehicle.simNumber.trim()}'),
              if (vehicle.vin.trim().isNotEmpty)
                _MetaPill(
                    icon: Icons.tag_rounded,
                    label: 'VIN ${vehicle.vin.trim()}'),
              if (_planName(vehicle).isNotEmpty)
                _MetaPill(
                  icon: Icons.workspace_premium_outlined,
                  label: _planName(vehicle),
                ),
              _MetaPill(
                icon: Icons.event_available_outlined,
                label: 'Expiry ${_dateText(vehicle.secondaryExpiry)}',
              ),
              if (vehicle.isLicenseBlocked)
                const _MetaPill(
                  icon: Icons.block_rounded,
                  label: 'License blocked',
                  color: OpenVtsColors.error,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AssignVehicleSheet extends StatefulWidget {
  const _AssignVehicleSheet({
    required this.vehicles,
    required this.onAssign,
  });

  final List<AdminUserVehicle> vehicles;
  final Future<bool> Function(AdminUserVehicle vehicle) onAssign;

  @override
  State<_AssignVehicleSheet> createState() => _AssignVehicleSheetState();
}

class _AssignVehicleSheetState extends State<_AssignVehicleSheet> {
  final _searchController = TextEditingController();
  String? _selectedId;
  var _query = '';
  var _isSubmitting = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final matches = widget.vehicles.where(_matchesQuery).toList();
    final selectedVehicle = _selectedVehicle;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(OpenVtsSpacing.md),
          child: TextField(
            controller: _searchController,
            onChanged: (value) => setState(() => _query = value),
            decoration: const InputDecoration(
              hintText: 'Search available vehicles',
              prefixIcon: Icon(Icons.search_rounded, size: 18),
            ),
          ),
        ),
        Expanded(
          child: matches.isEmpty
              ? Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: OpenVtsSpacing.md),
                  child: _EmptyCard(
                    label: _query.trim().isEmpty
                        ? 'No available vehicles'
                        : 'No vehicles match your search',
                  ),
                )
              : ListView.separated(
                  controller: PrimaryScrollController.maybeOf(context),
                  padding: const EdgeInsets.fromLTRB(
                    OpenVtsSpacing.md,
                    0,
                    OpenVtsSpacing.md,
                    OpenVtsSpacing.md,
                  ),
                  itemCount: matches.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: OpenVtsSpacing.xs),
                  itemBuilder: (context, index) {
                    final vehicle = matches[index];
                    final isSelected = vehicle.id == _selectedId;
                    return _SelectableVehicleTile(
                      vehicle: vehicle,
                      isSelected: isSelected,
                      onTap: () => setState(() => _selectedId = vehicle.id),
                    );
                  },
                ),
        ),
        const Divider(height: 1),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(OpenVtsSpacing.md),
            child: Row(
              children: [
                Expanded(
                  child: OpenVtsButton(
                    label: 'Cancel',
                    height: 40,
                    variant: OpenVtsButtonVariant.secondary,
                    onPressed: _isSubmitting
                        ? null
                        : () => Navigator.of(context).pop(),
                  ),
                ),
                const SizedBox(width: OpenVtsSpacing.sm),
                Expanded(
                  child: OpenVtsButton(
                    label: 'Assign',
                    height: 40,
                    isLoading: _isSubmitting,
                    trailingIcon: Icons.check_rounded,
                    onPressed: selectedVehicle == null || _isSubmitting
                        ? null
                        : () => _assign(selectedVehicle),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  AdminUserVehicle? get _selectedVehicle {
    final selectedId = _selectedId;
    if (selectedId == null) {
      return null;
    }
    for (final vehicle in widget.vehicles) {
      if (vehicle.id == selectedId) {
        return vehicle;
      }
    }
    return null;
  }

  bool _matchesQuery(AdminUserVehicle vehicle) {
    final normalized = _query.trim().toLowerCase();
    if (normalized.isEmpty) {
      return true;
    }
    return [vehicle.name, vehicle.plateNumber, vehicle.imei, vehicle.vin]
        .any((value) => value.toLowerCase().contains(normalized));
  }

  Future<void> _assign(AdminUserVehicle vehicle) async {
    setState(() => _isSubmitting = true);
    final ok = await widget.onAssign(vehicle);
    if (!mounted) {
      return;
    }
    setState(() => _isSubmitting = false);
    if (ok) {
      Navigator.of(context).pop();
    }
  }
}

class _SelectableVehicleTile extends StatelessWidget {
  const _SelectableVehicleTile({
    required this.vehicle,
    required this.isSelected,
    required this.onTap,
  });

  final AdminUserVehicle vehicle;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: OpenVtsColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(OpenVtsRadius.sm),
        side: BorderSide(
          color: isSelected ? OpenVtsColors.brandInk : OpenVtsColors.border,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(OpenVtsRadius.sm),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(OpenVtsSpacing.sm),
          child: Row(
            children: [
              Icon(
                isSelected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_unchecked_rounded,
                size: 18,
                color: isSelected
                    ? OpenVtsColors.brandInk
                    : OpenVtsColors.textTertiary,
              ),
              const SizedBox(width: OpenVtsSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _vehicleTitle(vehicle),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: OpenVtsTypography.label.copyWith(
                        color: OpenVtsColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _vehicleSubtitle(vehicle),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: OpenVtsTypography.meta.copyWith(
                        color: OpenVtsColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TinyTextButton extends StatelessWidget {
  const _TinyTextButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.isLoading = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: isLoading ? null : onPressed,
      style: TextButton.styleFrom(
        minimumSize: const Size(0, 30),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        foregroundColor: OpenVtsColors.textPrimary,
      ),
      icon: isLoading
          ? const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(icon, size: 14),
      label: Text(
        label,
        style: OpenVtsTypography.meta.copyWith(
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({
    required this.icon,
    required this.label,
    this.color = OpenVtsColors.textSecondary,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(OpenVtsRadius.pill),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: OpenVtsTypography.meta.copyWith(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 16,
            color: OpenVtsColors.error,
          ),
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

class _SectionLoader extends StatelessWidget {
  const _SectionLoader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return OpenVtsCard(
      padding: const EdgeInsets.all(OpenVtsSpacing.md),
      child: Row(
        children: [
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: OpenVtsSpacing.sm),
          Text(
            'Loading $title',
            style: OpenVtsTypography.label.copyWith(
              color: OpenVtsColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionErrorCard extends StatelessWidget {
  const _SectionErrorCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return OpenVtsCard(
      padding: const EdgeInsets.all(OpenVtsSpacing.md),
      child: OpenVtsErrorView(
        message: message,
        onRetry: onRetry,
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return OpenVtsCard(
      padding: const EdgeInsets.symmetric(vertical: OpenVtsSpacing.lg),
      child: Center(
        child: Text(
          label,
          style: OpenVtsTypography.meta.copyWith(
            color: OpenVtsColors.textSecondary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

String _vehicleTitle(AdminUserVehicle vehicle) {
  final name = vehicle.name.trim();
  if (name.isNotEmpty) {
    return name;
  }
  return 'Vehicle';
}

String _vehicleSubtitle(AdminUserVehicle vehicle) {
  final parts = <String>[];
  if (vehicle.plateNumber.trim().isNotEmpty) {
    parts.add(vehicle.plateNumber.trim());
  }
  if (vehicle.imei.trim().isNotEmpty) {
    parts.add('IMEI ${vehicle.imei.trim()}');
  }
  if (vehicle.simNumber.trim().isNotEmpty) {
    parts.add('SIM ${vehicle.simNumber.trim()}');
  }
  if (parts.isEmpty) {
    return '—';
  }
  return parts.join(' · ');
}

String _planName(AdminUserVehicle vehicle) {
  final source = vehicle.plan;
  final candidates = <Object?>[
    source['name'],
    source['planName'],
    source['title'],
    source['label'],
    source['slug'],
    source['code'],
  ];
  for (final value in candidates) {
    final normalized = value?.toString().trim() ?? '';
    if (normalized.isNotEmpty) {
      return normalized;
    }
  }
  return '';
}

String _dateText(DateTime? value) {
  if (value == null) {
    return '—';
  }
  return const DateTimeFormatter().formatDate(value.toLocal());
}

String _displayValue(String value) {
  final normalized = value.trim();
  if (normalized.isEmpty || normalized == '-') {
    return '—';
  }
  return normalized;
}
