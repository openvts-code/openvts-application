import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../../core/router/route_paths.dart';
import '../../../../../../core/theme/open_vts_colors.dart';
import '../../../../../../core/theme/open_vts_radius.dart';
import '../../../../../../core/theme/open_vts_spacing.dart';
import '../../../../../../core/theme/open_vts_typography.dart';
import '../../../../../../core/utils/date_time_formatter.dart';
import '../../../../../../shared/helpers/toast_helper.dart';
import '../../../../../../shared/widgets/open_vts_bottom_sheet.dart';
import '../../../../../../shared/widgets/open_vts_button.dart';
import '../../../../../../shared/widgets/open_vts_card.dart';
import '../../../../controllers/user_driver_details_controller.dart';
import '../../../../controllers/user_providers.dart';
import '../../../../models/user_driver_model.dart';
import '../../../../models/user_drivers_state.dart';
import 'user_driver_assign_vehicle_sheet.dart';
import 'user_driver_delete_sheet.dart';
import 'user_driver_edit_sheet.dart';

const DateTimeFormatter _dateFormatter = DateTimeFormatter();

class UserDriverProfileTab extends ConsumerWidget {
  const UserDriverProfileTab({required this.provider, super.key});

  final AutoDisposeStateNotifierProvider<UserDriverDetailsController,
      UserDriverDetailsState> provider;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(provider);
    final controller = ref.read(provider.notifier);
    final driver = state.driver;

    if (driver == null) {
      return _SectionStateCard(
        isLoading: state.isLoading,
        message: state.errorMessage,
        onRetry: controller.loadInitial,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ActionButtons(
          isSaving: state.isSaving,
          isAssigning: state.isAssigning,
          isUnassigning: state.isUnassigning,
          isDeleting: state.isDeleting,
          hasAssignedVehicle: driver.hasAssignedVehicle,
          onEdit: () => _showEditSheet(context, driver),
          onAssign: () => _showAssignSheet(context, driver),
          onUnassign: driver.hasAssignedVehicle
              ? () => _confirmUnassign(context, ref)
              : null,
          onDelete: () => _showDeleteSheet(context, ref, driver),
        ),
        if (state.errorMessage != null) ...[
          const SizedBox(height: OpenVtsSpacing.sm),
          _InlineError(message: state.errorMessage!),
        ],
        const SizedBox(height: OpenVtsSpacing.sm),
        _InfoCard(
          title: 'Driver Profile',
          icon: Icons.badge_outlined,
          rows: [
            _InfoRow(label: 'Name', value: _display(driver.name)),
            _InfoRow(label: 'Username', value: _username(driver.username)),
            _InfoRow(
                label: 'Status',
                value: driver.isActive ? 'Active' : 'Inactive'),
            _InfoRow(
              label: 'Verification',
              value: driver.isVerified ? 'Verified' : 'Unverified',
            ),
            _InfoRow(
              label: 'Created',
              value: _dateText(driver.createdAt),
            ),
          ],
        ),
        const SizedBox(height: OpenVtsSpacing.sm),
        _InfoCard(
          title: 'Contact',
          icon: Icons.phone_outlined,
          rows: [
            _InfoRow(label: 'Mobile', value: _phoneLabel(driver)),
            _InfoRow(label: 'Email', value: _display(driver.email)),
          ],
        ),
        const SizedBox(height: OpenVtsSpacing.sm),
        _InfoCard(
          title: 'Address',
          icon: Icons.location_on_outlined,
          rows: [
            _InfoRow(label: 'Address', value: _addressText(driver)),
            _InfoRow(label: 'Country', value: _display(driver.countryCode)),
            _InfoRow(label: 'State', value: _display(driver.stateCode)),
            _InfoRow(label: 'City', value: _display(driver.city)),
            _InfoRow(label: 'Pincode', value: _display(driver.pincode)),
          ],
        ),
        const SizedBox(height: OpenVtsSpacing.sm),
        _AssignmentCard(driver: driver),
      ],
    );
  }

  Future<void> _showEditSheet(
    BuildContext context,
    UserDriver driver,
  ) {
    return OpenVtsBottomSheet.show<bool>(
      context: context,
      title: 'Edit Driver',
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.97,
      child: UserDriverEditSheet(
        provider: provider,
        driver: driver,
      ),
    );
  }

  Future<void> _showAssignSheet(
    BuildContext context,
    UserDriver driver,
  ) {
    return OpenVtsBottomSheet.show<bool>(
      context: context,
      title: driver.hasAssignedVehicle ? 'Change Vehicle' : 'Assign Vehicle',
      initialChildSize: 0.84,
      minChildSize: 0.48,
      maxChildSize: 0.96,
      child: UserDriverAssignVehicleSheet(
        provider: provider,
        driver: driver,
      ),
    );
  }

  Future<void> _confirmUnassign(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Unassign vehicle'),
          content: const Text('Remove vehicle assignment from this driver?'),
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

    if (confirmed != true || !context.mounted) {
      return;
    }

    final ok = await ref.read(provider.notifier).unassignVehicle();
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

  Future<void> _showDeleteSheet(
    BuildContext context,
    WidgetRef ref,
    UserDriver driver,
  ) async {
    final deleted = await OpenVtsBottomSheet.show<bool>(
      context: context,
      title: 'Delete Driver',
      initialChildSize: 0.44,
      minChildSize: 0.36,
      maxChildSize: 0.64,
      child: UserDriverDeleteSheet(
        provider: provider,
        driver: driver,
      ),
    );

    if (deleted != true || !context.mounted) {
      return;
    }

    await ref.read(userDriversControllerProvider.notifier).refresh();
    if (!context.mounted) {
      return;
    }

    ToastHelper.showSuccess('Driver deleted.', context: context);
    context.go(RoutePaths.userDrivers);
  }
}

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({
    required this.isSaving,
    required this.isAssigning,
    required this.isUnassigning,
    required this.isDeleting,
    required this.hasAssignedVehicle,
    required this.onEdit,
    required this.onAssign,
    required this.onUnassign,
    required this.onDelete,
  });

  final bool isSaving;
  final bool isAssigning;
  final bool isUnassigning;
  final bool isDeleting;
  final bool hasAssignedVehicle;
  final VoidCallback onEdit;
  final VoidCallback onAssign;
  final VoidCallback? onUnassign;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: OpenVtsSpacing.xs,
      runSpacing: OpenVtsSpacing.xs,
      children: [
        _CompactActionButton(
          label: 'Edit',
          icon: Icons.edit_outlined,
          isLoading: isSaving,
          onPressed: isSaving ? null : onEdit,
        ),
        _CompactActionButton(
          label: hasAssignedVehicle ? 'Change Vehicle' : 'Assign Vehicle',
          icon: Icons.directions_car_outlined,
          isLoading: isAssigning,
          onPressed: isAssigning ? null : onAssign,
        ),
        _CompactActionButton(
          label: 'Unassign',
          icon: Icons.link_off_rounded,
          isLoading: isUnassigning,
          onPressed: isUnassigning ? null : onUnassign,
        ),
        _CompactActionButton(
          label: 'Delete',
          icon: Icons.delete_outline_rounded,
          isDestructive: true,
          isLoading: isDeleting,
          onPressed: isDeleting ? null : onDelete,
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
    this.isDestructive = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final foreground =
        isDestructive ? OpenVtsColors.error : OpenVtsColors.textPrimary;

    return SizedBox(
      height: 34,
      child: OutlinedButton.icon(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: OpenVtsColors.white,
          foregroundColor: foreground,
          side: BorderSide(
            color: isDestructive
                ? OpenVtsColors.error.withValues(alpha: 0.35)
                : OpenVtsColors.border,
          ),
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
            color: foreground,
          ),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.title,
    required this.icon,
    required this.rows,
  });

  final String title;
  final IconData icon;
  final List<_InfoRow> rows;

  @override
  Widget build(BuildContext context) {
    return OpenVtsCard(
      padding: const EdgeInsets.all(OpenVtsSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: OpenVtsColors.textSecondary),
              const SizedBox(width: OpenVtsSpacing.xs),
              Text(
                title,
                style: OpenVtsTypography.label.copyWith(
                  color: OpenVtsColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: OpenVtsSpacing.xs),
          for (final row in rows) row,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: OpenVtsTypography.meta.copyWith(
                color: OpenVtsColors.textTertiary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: OpenVtsSpacing.sm),
          Flexible(
            flex: 2,
            child: Text(
              value,
              textAlign: TextAlign.end,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: OpenVtsTypography.meta.copyWith(
                color: OpenVtsColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AssignmentCard extends StatelessWidget {
  const _AssignmentCard({required this.driver});

  final UserDriver driver;

  @override
  Widget build(BuildContext context) {
    final assigned = driver.assignedVehicle;

    return OpenVtsCard(
      padding: const EdgeInsets.all(OpenVtsSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.directions_car_outlined,
                size: 16,
                color: OpenVtsColors.textSecondary,
              ),
              const SizedBox(width: OpenVtsSpacing.xs),
              Text(
                'Assigned Vehicle',
                style: OpenVtsTypography.label.copyWith(
                  color: OpenVtsColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: OpenVtsSpacing.xs),
          if (assigned == null)
            Text(
              'No vehicle assigned.',
              style: OpenVtsTypography.meta.copyWith(
                color: OpenVtsColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            )
          else ...[
            _InfoRow(label: 'Name', value: _display(assigned.name)),
            _InfoRow(label: 'Plate', value: _display(assigned.plateNumber)),
            _InfoRow(label: 'IMEI', value: _display(assigned.imei)),
            _InfoRow(label: 'VIN', value: _display(assigned.vin)),
          ],
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

class _SectionStateCard extends StatelessWidget {
  const _SectionStateCard({
    required this.isLoading,
    required this.message,
    required this.onRetry,
  });

  final bool isLoading;
  final String? message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return OpenVtsCard(
      padding: const EdgeInsets.all(OpenVtsSpacing.sm),
      child: isLoading
          ? Row(
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: OpenVtsSpacing.sm),
                Text(
                  'Loading profile',
                  style: OpenVtsTypography.meta.copyWith(
                    color: OpenVtsColors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  message ?? 'Driver profile could not be loaded.',
                  style: OpenVtsTypography.meta.copyWith(
                    color: OpenVtsColors.error,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: OpenVtsSpacing.sm),
                OpenVtsButton(
                  label: 'Retry',
                  height: 36,
                  variant: OpenVtsButtonVariant.secondary,
                  onPressed: onRetry,
                ),
              ],
            ),
    );
  }
}

String _display(String? value) {
  final normalized = value?.trim();
  return normalized == null || normalized.isEmpty ? '-' : normalized;
}

String _username(String value) {
  final normalized = value.trim();
  if (normalized.isEmpty || normalized == '-') {
    return '-';
  }
  return '@$normalized';
}

String _phoneLabel(UserDriver driver) {
  final prefix = driver.mobilePrefix.trim();
  final mobile = driver.mobile.trim();
  final merged = [prefix, mobile]
      .where((part) => part.isNotEmpty && part != '-')
      .join(' ')
      .trim();
  return merged.isEmpty ? '-' : merged;
}

String _dateText(DateTime? value) {
  if (value == null) {
    return '-';
  }
  return _dateFormatter.formatDateTime(value.toLocal());
}

String _addressText(UserDriver driver) {
  final details = driver.addressDetails;
  final fullAddress = details?.fullAddress.trim() ?? '';
  if (fullAddress.isNotEmpty && fullAddress != '-') {
    return fullAddress;
  }

  final joined = [
    driver.address,
    driver.city,
    driver.stateCode,
    driver.countryCode,
    driver.pincode,
  ]
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty && item != '-')
      .toList(growable: false)
      .join(', ')
      .trim();

  if (joined.isEmpty) {
    return '-';
  }

  return joined;
}
