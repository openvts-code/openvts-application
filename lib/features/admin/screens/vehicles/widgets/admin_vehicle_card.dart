import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../core/theme/open_vts_colors.dart';
import '../../../../../core/theme/open_vts_radius.dart';
import '../../../../../core/theme/open_vts_spacing.dart';
import '../../../../../core/theme/open_vts_typography.dart';
import '../../../models/admin_vehicle_model.dart';

class AdminVehicleCard extends StatelessWidget {
  const AdminVehicleCard({
    super.key,
    required this.vehicle,
    required this.onTap,
  });

  final AdminVehicleListItem vehicle;
  final VoidCallback onTap;

  static final DateFormat _createdFormat = DateFormat('yyyy-MM-dd HH:mm');

  @override
  Widget build(BuildContext context) {
    final name =
        vehicle.name.trim().isEmpty ? 'Untitled Vehicle' : vehicle.name.trim();
    final plate = vehicle.plateNumber.trim();
    final typeName = vehicle.vehicleTypeName.trim();
    final statusLabel = vehicle.isLicenseBlocked
        ? 'License Blocked'
        : vehicle.isActive
            ? 'Active'
            : 'Inactive';
    final createdValue = vehicle.createdAt == null
        ? '-'
        : _createdFormat.format(vehicle.createdAt!.toLocal());

    return _RoundedSurface(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(
            name: name,
            plate: plate,
            typeName: typeName,
            statusLabel: statusLabel,
          ),
          const SizedBox(height: OpenVtsSpacing.md),
          _CardInfoGrid(
            imei: vehicle.imei,
            sim: vehicle.simNumber,
            vin: vehicle.vin,
            primaryUser: vehicle.primaryUserName,
          ),
          const SizedBox(height: OpenVtsSpacing.md),
          _CreatedFooter(createdValue: createdValue),
        ],
      ),
    );
  }
}

class _CardHeader extends StatelessWidget {
  const _CardHeader({
    required this.name,
    required this.plate,
    required this.typeName,
    required this.statusLabel,
  });

  final String name;
  final String plate;
  final String typeName;
  final String statusLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 44,
          width: 44,
          decoration: BoxDecoration(
            color: _softSurfaceColor(context),
            shape: BoxShape.circle,
            border: Border.all(color: _softBorderColor(context)),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: OpenVtsSpacing.xs,
                runSpacing: OpenVtsSpacing.xxs,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                  ),
                  if (plate.isNotEmpty) _PlateBadge(plate: plate),
                ],
              ),
              if (typeName.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  typeName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: OpenVtsTypography.label.copyWith(
                    color: OpenVtsColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: OpenVtsSpacing.xs),
        _StatusBadge(label: statusLabel),
      ],
    );
  }
}

class _PlateBadge extends StatelessWidget {
  const _PlateBadge({required this.plate});

  final String plate;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: OpenVtsSpacing.xs + 2,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: _softSurfaceColor(context),
        borderRadius: BorderRadius.circular(OpenVtsRadius.pill),
        border: Border.all(color: _softBorderColor(context)),
      ),
      child: Text(
        plate,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: OpenVtsTypography.meta.copyWith(
          color: OpenVtsColors.textSecondary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: OpenVtsSpacing.sm,
        vertical: OpenVtsSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: _softSurfaceColor(context),
        borderRadius: BorderRadius.circular(OpenVtsRadius.pill),
        border: Border.all(color: _softBorderColor(context)),
      ),
      child: Text(
        label,
        style: OpenVtsTypography.label.copyWith(
          color: _primaryInkColor(context),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _CardInfoGrid extends StatelessWidget {
  const _CardInfoGrid({
    required this.imei,
    required this.sim,
    required this.vin,
    required this.primaryUser,
  });

  final String imei;
  final String sim;
  final String vin;
  final String primaryUser;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 420;

        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _InfoField(
                icon: Icons.qr_code_2_rounded,
                label: 'IMEI',
                value: imei,
              ),
              const SizedBox(height: OpenVtsSpacing.xs),
              _InfoField(
                icon: Icons.sim_card_outlined,
                label: 'SIM',
                value: sim,
              ),
              const SizedBox(height: OpenVtsSpacing.xs),
              _InfoField(
                icon: Icons.qr_code_scanner_rounded,
                label: 'VIN',
                value: vin,
              ),
              const SizedBox(height: OpenVtsSpacing.xs),
              _InfoField(
                icon: Icons.account_circle_outlined,
                label: 'PRIMARY USER',
                value: primaryUser,
              ),
            ],
          );
        }

        return Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _InfoField(
                    icon: Icons.qr_code_2_rounded,
                    label: 'IMEI',
                    value: imei,
                  ),
                ),
                const SizedBox(width: OpenVtsSpacing.sm),
                Expanded(
                  child: _InfoField(
                    icon: Icons.qr_code_scanner_rounded,
                    label: 'VIN',
                    value: vin,
                  ),
                ),
              ],
            ),
            const SizedBox(height: OpenVtsSpacing.xs),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _InfoField(
                    icon: Icons.sim_card_outlined,
                    label: 'SIM',
                    value: sim,
                  ),
                ),
                const SizedBox(width: OpenVtsSpacing.sm),
                Expanded(
                  child: _InfoField(
                    icon: Icons.account_circle_outlined,
                    label: 'PRIMARY USER',
                    value: primaryUser,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _InfoField extends StatelessWidget {
  const _InfoField({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final resolved = value.trim().isEmpty ? '-' : value.trim();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 16,
          color: OpenVtsColors.textSecondary,
        ),
        const SizedBox(width: OpenVtsSpacing.xs),
        Expanded(
          child: RichText(
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            text: TextSpan(
              style: OpenVtsTypography.label.copyWith(
                color: OpenVtsColors.textPrimary,
                height: 1.4,
              ),
              children: [
                TextSpan(
                  text: '$label : ',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                TextSpan(
                  text: resolved,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CreatedFooter extends StatelessWidget {
  const _CreatedFooter({required this.createdValue});

  final String createdValue;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: OpenVtsSpacing.sm,
        vertical: OpenVtsSpacing.xs + 2,
      ),
      decoration: BoxDecoration(
        color: _softSurfaceColor(context),
        borderRadius: BorderRadius.circular(OpenVtsRadius.md),
        border: Border.all(color: _softBorderColor(context)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.schedule_outlined,
            size: 16,
            color: OpenVtsColors.textSecondary,
          ),
          const SizedBox(width: OpenVtsSpacing.xs),
          Expanded(
            child: RichText(
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              text: TextSpan(
                style: OpenVtsTypography.label.copyWith(
                  color: OpenVtsColors.textPrimary,
                  height: 1.4,
                ),
                children: [
                  const TextSpan(
                    text: 'Created : ',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  TextSpan(
                    text: createdValue,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundedSurface extends StatelessWidget {
  const _RoundedSurface({
    required this.child,
    this.onTap,
  });

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(OpenVtsRadius.lg);
    final surface = Container(
      width: double.infinity,
      padding: const EdgeInsets.all(OpenVtsSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: radius,
        border: Border.all(color: _softBorderColor(context)),
      ),
      child: child,
    );

    if (onTap == null) {
      return surface;
    }

    return Material(
      color: Colors.transparent,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: surface,
      ),
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
