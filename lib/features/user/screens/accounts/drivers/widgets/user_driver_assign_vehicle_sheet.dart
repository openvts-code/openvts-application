import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../../core/theme/open_vts_colors.dart';
import '../../../../../../core/theme/open_vts_radius.dart';
import '../../../../../../core/theme/open_vts_spacing.dart';
import '../../../../../../core/theme/open_vts_typography.dart';
import '../../../../../../shared/helpers/toast_helper.dart';
import '../../../../../../shared/widgets/open_vts_button.dart';
import '../../../../../../shared/widgets/open_vts_card.dart';
import '../../../../../../shared/widgets/open_vts_empty_state.dart';
import '../../../../../../shared/widgets/open_vts_search_field.dart';
import '../../../../controllers/user_driver_details_controller.dart';
import '../../../../models/user_driver_model.dart';
import '../../../../models/user_drivers_state.dart';

class UserDriverAssignVehicleSheet extends ConsumerStatefulWidget {
  const UserDriverAssignVehicleSheet({
    required this.provider,
    required this.driver,
    super.key,
  });

  final AutoDisposeStateNotifierProvider<UserDriverDetailsController,
      UserDriverDetailsState> provider;
  final UserDriver driver;

  @override
  ConsumerState<UserDriverAssignVehicleSheet> createState() =>
      _UserDriverAssignVehicleSheetState();
}

class _UserDriverAssignVehicleSheetState
    extends ConsumerState<UserDriverAssignVehicleSheet> {
  var _searchQuery = '';
  String? _selectedVehicleId;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(widget.provider);
    final vehicles = state.availableVehicles;
    final filteredVehicles = _filterVehicles(vehicles, _searchQuery);
    final isLoading = state.isLoading && vehicles.isEmpty;
    final isSubmitting = state.isAssigning;

    return Column(
      children: [
        Expanded(
          child: ListView(
            controller: PrimaryScrollController.maybeOf(context),
            padding: const EdgeInsets.all(OpenVtsSpacing.md),
            children: [
              OpenVtsSearchField(
                hintText: 'Search by name, plate, IMEI, or VIN',
                onChanged: (value) {
                  setState(() => _searchQuery = value.trim());
                },
              ),
              const SizedBox(height: OpenVtsSpacing.sm),
              _HeaderRow(
                totalCount: vehicles.length,
                visibleCount: filteredVehicles.length,
                isLoading: state.isLoading,
              ),
              if (state.errorMessage != null) ...[
                const SizedBox(height: OpenVtsSpacing.sm),
                _InlineError(message: state.errorMessage!),
              ],
              const SizedBox(height: OpenVtsSpacing.sm),
              if (isLoading)
                const _LoadingCard(label: 'Loading available vehicles')
              else if (filteredVehicles.isEmpty)
                OpenVtsCard(
                  padding: const EdgeInsets.all(OpenVtsSpacing.md),
                  child: OpenVtsEmptyState(
                    title: vehicles.isEmpty
                        ? 'No unassigned vehicles'
                        : 'No matching vehicles',
                    message: vehicles.isEmpty
                        ? 'All vehicles are already assigned.'
                        : 'Try a different search query.',
                  ),
                )
              else
                for (final vehicle in filteredVehicles) ...[
                  _VehicleOptionCard(
                    vehicle: vehicle,
                    isSelected: _selectedVehicleId == vehicle.id,
                    onTap: () {
                      setState(() => _selectedVehicleId = vehicle.id);
                    },
                  ),
                  if (vehicle != filteredVehicles.last)
                    const SizedBox(height: OpenVtsSpacing.sm),
                ],
            ],
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
                    onPressed:
                        isSubmitting ? null : () => Navigator.of(context).pop(),
                  ),
                ),
                const SizedBox(width: OpenVtsSpacing.sm),
                Expanded(
                  child: OpenVtsButton(
                    label: 'Assign',
                    height: 40,
                    trailingIcon: Icons.check_rounded,
                    isLoading: isSubmitting,
                    onPressed: isSubmitting ? null : _assignVehicle,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _assignVehicle() async {
    final selectedId = _selectedVehicleId?.trim() ?? '';
    if (selectedId.isEmpty) {
      ToastHelper.showError('Select a vehicle first.', context: context);
      return;
    }

    final ok =
        await ref.read(widget.provider.notifier).assignVehicle(selectedId);
    if (!mounted) {
      return;
    }

    if (ok) {
      ToastHelper.showSuccess('Vehicle assigned.', context: context);
      Navigator.of(context).pop(true);
      return;
    }

    ToastHelper.showError(
      ref.read(widget.provider).errorMessage ?? 'Unable to assign vehicle.',
      context: context,
    );
  }

  List<UserDriverVehicleMini> _filterVehicles(
    List<UserDriverVehicleMini> vehicles,
    String query,
  ) {
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) {
      return vehicles;
    }

    return vehicles.where((vehicle) {
      return vehicle.searchContent.contains(normalizedQuery);
    }).toList(growable: false);
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow({
    required this.totalCount,
    required this.visibleCount,
    required this.isLoading,
  });

  final int totalCount;
  final int visibleCount;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(
          Icons.directions_car_outlined,
          size: 17,
          color: OpenVtsColors.textSecondary,
        ),
        const SizedBox(width: OpenVtsSpacing.xs),
        Expanded(
          child: Text(
            '$visibleCount of $totalCount vehicles',
            style: OpenVtsTypography.meta.copyWith(
              color: OpenVtsColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        if (isLoading)
          const SizedBox(
            width: 13,
            height: 13,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
      ],
    );
  }
}

class _VehicleOptionCard extends StatelessWidget {
  const _VehicleOptionCard({
    required this.vehicle,
    required this.isSelected,
    required this.onTap,
  });

  final UserDriverVehicleMini vehicle;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = _joinParts([
      vehicle.name,
      vehicle.plateNumber,
      vehicle.vehicleType,
    ]);

    return OpenVtsCard(
      onTap: onTap,
      padding: const EdgeInsets.all(OpenVtsSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: OpenVtsColors.surface,
              borderRadius: BorderRadius.circular(OpenVtsRadius.sm),
              border: Border.all(color: OpenVtsColors.border),
            ),
            child: const Icon(
              Icons.directions_car_filled_outlined,
              size: 18,
              color: OpenVtsColors.textSecondary,
            ),
          ),
          const SizedBox(width: OpenVtsSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: OpenVtsTypography.label.copyWith(
                    color: OpenVtsColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _joinParts([
                    vehicle.imei.isEmpty ? null : 'IMEI ${vehicle.imei}',
                    vehicle.vin.isEmpty ? null : 'VIN ${vehicle.vin}',
                  ]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: OpenVtsTypography.meta.copyWith(
                    color: OpenVtsColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: OpenVtsSpacing.xs),
          AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected
                  ? OpenVtsColors.brandInk.withValues(alpha: 0.12)
                  : OpenVtsColors.surface,
              border: Border.all(
                color:
                    isSelected ? OpenVtsColors.brandInk : OpenVtsColors.border,
              ),
            ),
            child: Icon(
              isSelected ? Icons.check_rounded : Icons.circle_outlined,
              size: 14,
              color: isSelected
                  ? OpenVtsColors.brandInk
                  : OpenVtsColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return OpenVtsCard(
      padding: const EdgeInsets.all(OpenVtsSpacing.sm),
      child: Row(
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: OpenVtsSpacing.sm),
          Text(
            label,
            style: OpenVtsTypography.meta.copyWith(
              color: OpenVtsColors.textSecondary,
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

String _joinParts(List<String?> parts) {
  final normalized = parts
      .map((item) => item?.trim() ?? '')
      .where((item) => item.isNotEmpty)
      .toList(growable: false);

  if (normalized.isEmpty) {
    return '-';
  }

  return normalized.join(' - ');
}
