import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../../core/router/route_paths.dart';
import '../../../../../../core/theme/open_vts_colors.dart';
import '../../../../../../core/theme/open_vts_radius.dart';
import '../../../../../../core/theme/open_vts_spacing.dart';
import '../../../../../../core/theme/open_vts_typography.dart';
import '../../../../../../shared/helpers/toast_helper.dart';
import '../../../../../../shared/widgets/open_vts_bottom_sheet.dart';
import '../../../../../../shared/widgets/open_vts_button.dart';
import '../../../../../../shared/widgets/open_vts_card.dart';
import '../../../../../../shared/widgets/open_vts_empty_state.dart';
import '../../../../controllers/user_subuser_details_controller.dart';
import '../../../../models/user_subuser_model.dart';
import '../../../../models/user_subusers_state.dart';
import 'user_subuser_assign_vehicles_sheet.dart';

typedef UserSubUserDetailsProvider = AutoDisposeStateNotifierProvider<
    UserSubUserDetailsController, UserSubUserDetailsState>;

class UserSubUserVehiclesTab extends ConsumerWidget {
  const UserSubUserVehiclesTab({
    required this.provider,
    super.key,
  });

  final UserSubUserDetailsProvider provider;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(provider);
    final controller = ref.read(provider.notifier);
    final assigned = state.assignedVehicles;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ActionRow(
          isLoadingVehicles: state.isLoadingVehicles,
          isAssigningVehicles: state.isAssigningVehicles,
          availableCount: state.availableVehicles.length,
          onAssignVehicles: () => _showAssignSheet(context),
          onRefresh: state.isLoadingVehicles ? null : controller.loadVehicles,
        ),
        if (state.errorMessage != null) ...[
          const SizedBox(height: OpenVtsSpacing.sm),
          _InlineError(message: state.errorMessage!),
        ],
        const SizedBox(height: OpenVtsSpacing.sm),
        if (state.isLoadingVehicles && assigned.isEmpty)
          const _LoadingCard(label: 'Loading assigned vehicles')
        else if (assigned.isEmpty)
          OpenVtsCard(
            child: Column(
              children: [
                const OpenVtsEmptyState(
                  title: 'No assigned vehicles',
                  message: 'Assign one or more vehicles to this sub user.',
                ),
                const SizedBox(height: OpenVtsSpacing.sm),
                OpenVtsButton(
                  label: 'Assign Vehicles',
                  height: 36,
                  trailingIcon: Icons.add_link_rounded,
                  onPressed: state.isAssigningVehicles
                      ? null
                      : () => _showAssignSheet(context),
                ),
              ],
            ),
          )
        else
          for (var index = 0; index < assigned.length; index++) ...[
            _AssignedVehicleCard(
              vehicle: assigned[index],
              isUnassigning: state.isUnassigningVehicles,
              onViewVehicle: assigned[index].id.trim().isEmpty
                  ? null
                  : () => _openVehicleDetails(context, assigned[index]),
              onUnassign: state.isUnassigningVehicles
                  ? null
                  : () => _confirmUnassign(context, ref, assigned[index]),
            ),
            if (index < assigned.length - 1)
              const SizedBox(height: OpenVtsSpacing.sm),
          ],
      ],
    );
  }

  Future<void> _showAssignSheet(BuildContext context) {
    return OpenVtsBottomSheet.show<bool>(
      context: context,
      title: 'Assign Vehicles',
      initialChildSize: 0.86,
      minChildSize: 0.5,
      maxChildSize: 0.97,
      child: UserSubUserAssignVehiclesSheet(provider: provider),
    );
  }

  Future<void> _confirmUnassign(
    BuildContext context,
    WidgetRef ref,
    UserSubUserVehicle vehicle,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Unassign vehicle'),
          content: Text(
            'Remove ${_vehicleTitle(vehicle)} from this sub user?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Unassign'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    if (!context.mounted) {
      return;
    }

    final id = vehicle.id.trim();
    if (id.isEmpty) {
      ToastHelper.showError('Vehicle id is missing.', context: context);
      return;
    }

    final ok = await ref.read(provider.notifier).unassignVehicles([id]);
    if (!context.mounted) {
      return;
    }

    if (ok) {
      ToastHelper.showSuccess('Vehicle unassigned.', context: context);
      return;
    }

    ToastHelper.showError(
      ref.read(provider).errorMessage ?? 'Unable to unassign vehicle.',
      context: context,
    );
  }

  void _openVehicleDetails(BuildContext context, UserSubUserVehicle vehicle) {
    final id = vehicle.id.trim();
    if (id.isEmpty) {
      return;
    }

    context.push(RoutePaths.userVehicleDetailsPath(id));
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.isLoadingVehicles,
    required this.isAssigningVehicles,
    required this.availableCount,
    required this.onAssignVehicles,
    required this.onRefresh,
  });

  final bool isLoadingVehicles;
  final bool isAssigningVehicles;
  final int availableCount;
  final VoidCallback onAssignVehicles;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: OpenVtsSpacing.xs,
      runSpacing: OpenVtsSpacing.xs,
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(
            color: OpenVtsColors.surface,
            borderRadius: BorderRadius.circular(OpenVtsRadius.pill),
            border: Border.all(color: OpenVtsColors.border),
          ),
          child: Text(
            '$availableCount available to assign',
            style: OpenVtsTypography.meta.copyWith(
              color: OpenVtsColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _CompactActionButton(
              label: 'Refresh',
              icon: Icons.refresh_rounded,
              isLoading: isLoadingVehicles,
              onPressed: onRefresh,
            ),
            const SizedBox(width: OpenVtsSpacing.xs),
            _CompactActionButton(
              label: 'Assign Vehicles',
              icon: Icons.add_link_rounded,
              isLoading: isAssigningVehicles,
              onPressed: isAssigningVehicles ? null : onAssignVehicles,
            ),
          ],
        ),
      ],
    );
  }
}

class _CompactActionButton extends StatelessWidget {
  const _CompactActionButton({
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
    return SizedBox(
      height: 34,
      child: OutlinedButton.icon(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: OpenVtsColors.white,
          foregroundColor: OpenVtsColors.textPrimary,
          side: const BorderSide(color: OpenVtsColors.border),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(OpenVtsRadius.pill),
          ),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        icon: isLoading
            ? const SizedBox(
                width: 13,
                height: 13,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(icon, size: 15),
        label: Text(
          label,
          style: OpenVtsTypography.meta.copyWith(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: OpenVtsColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

class _AssignedVehicleCard extends StatelessWidget {
  const _AssignedVehicleCard({
    required this.vehicle,
    required this.isUnassigning,
    required this.onViewVehicle,
    required this.onUnassign,
  });

  final UserSubUserVehicle vehicle;
  final bool isUnassigning;
  final VoidCallback? onViewVehicle;
  final VoidCallback? onUnassign;

  @override
  Widget build(BuildContext context) {
    return OpenVtsCard(
      padding: const EdgeInsets.all(OpenVtsSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                  Icons.directions_car_outlined,
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
                      _vehicleTitle(vehicle),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: OpenVtsTypography.label.copyWith(
                        color: OpenVtsColors.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      vehicle.plateNumber.trim().isEmpty
                          ? 'Plate unavailable'
                          : vehicle.plateNumber.trim(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: OpenVtsTypography.meta.copyWith(
                        color: OpenVtsColors.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: OpenVtsSpacing.xs),
          _MetaRow(label: 'VIN', value: _display(vehicle.vin)),
          _MetaRow(label: 'IMEI', value: _display(vehicle.imei)),
          _MetaRow(label: 'SIM', value: _display(vehicle.simNumber)),
          if (vehicle.licenseStatus != null &&
              vehicle.licenseStatus!.trim().isNotEmpty)
            _MetaRow(label: 'License', value: vehicle.licenseStatus!.trim()),
          if (vehicle.isBlocked != null)
            _MetaRow(
              label: 'Blocked',
              value: vehicle.isBlocked! ? 'Yes' : 'No',
            ),
          const SizedBox(height: OpenVtsSpacing.xs),
          Row(
            children: [
              if (onViewVehicle != null)
                TextButton.icon(
                  onPressed: onViewVehicle,
                  icon: const Icon(Icons.open_in_new_rounded, size: 15),
                  label: Text(
                    'View Vehicle',
                    style: OpenVtsTypography.meta.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: isUnassigning ? null : onUnassign,
                style: OutlinedButton.styleFrom(
                  foregroundColor: OpenVtsColors.textPrimary,
                  side: const BorderSide(color: OpenVtsColors.border),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                icon: isUnassigning
                    ? const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.link_off_rounded, size: 15),
                label: Text(
                  'Unassign',
                  style: OpenVtsTypography.meta.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          SizedBox(
            width: 64,
            child: Text(
              label,
              style: OpenVtsTypography.meta.copyWith(
                color: OpenVtsColors.textTertiary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: OpenVtsSpacing.xs),
          Expanded(
            child: Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: OpenVtsTypography.meta.copyWith(
                color: OpenVtsColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
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

String _display(String value) {
  final normalized = value.trim();
  return normalized.isEmpty ? '-' : normalized;
}

String _vehicleTitle(UserSubUserVehicle vehicle) {
  final name = vehicle.name.trim();
  if (name.isNotEmpty) {
    return name;
  }
  final plate = vehicle.plateNumber.trim();
  if (plate.isNotEmpty) {
    return plate;
  }
  return 'Vehicle';
}
