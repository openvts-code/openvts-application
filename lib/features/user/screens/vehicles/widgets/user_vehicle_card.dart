import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/router/route_paths.dart';
import '../../../../../core/theme/open_vts_colors.dart';
import '../../../../../core/theme/open_vts_radius.dart';
import '../../../../../core/theme/open_vts_spacing.dart';
import '../../../../../core/theme/open_vts_typography.dart';
import '../../../../../core/utils/date_time_formatter.dart';
import '../../../../../shared/helpers/toast_helper.dart';
import '../../../../../shared/widgets/open_vts_card.dart';
import '../../../../../shared/widgets/open_vts_status_chip.dart';
import '../../../models/user_vehicle_model.dart';

const DateTimeFormatter _dateFormatter = DateTimeFormatter();

class UserVehicleCard extends StatelessWidget {
  const UserVehicleCard({required this.vehicle, super.key});

  final UserVehicleListItem vehicle;

  @override
  Widget build(BuildContext context) {
    return OpenVtsCard(
      onTap: () => context.push(
        RoutePaths.userVehicleDetailsPath(vehicle.id),
        extra: vehicle,
      ),
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
                  color: OpenVtsColors.textPrimary.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(OpenVtsRadius.sm),
                  border: Border.all(color: OpenVtsColors.border),
                ),
                child: const Icon(
                  Icons.directions_car_filled_outlined,
                  size: 19,
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
                    const SizedBox(height: 3),
                    Text(
                      _joinParts([
                        vehicle.plateNumber,
                        vehicle.vehicleTypeName,
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
              OpenVtsStatusChip(
                label: vehicle.isActive ? 'Active' : 'Inactive',
                type: vehicle.isActive
                    ? OpenVtsStatusType.success
                    : OpenVtsStatusType.neutral,
              ),
            ],
          ),
          const SizedBox(height: OpenVtsSpacing.sm),
          Wrap(
            spacing: OpenVtsSpacing.xs,
            runSpacing: OpenVtsSpacing.xs,
            children: [
              if (vehicle.vin.trim().isNotEmpty)
                _MetaPill(
                    icon: Icons.tag_outlined,
                    label: 'VIN ${vehicle.vin.trim()}'),
              _MetaPill(
                icon: Icons.memory_outlined,
                label: 'IMEI ${_display(vehicle.imei)}',
                copyValue: vehicle.imei,
              ),
              _MetaPill(
                icon: Icons.sim_card_outlined,
                label: 'SIM ${_display(vehicle.simNumber)}',
                copyValue: vehicle.simNumber,
              ),
              if (vehicle.createdAt != null)
                _MetaPill(
                  icon: Icons.calendar_today_outlined,
                  label:
                      _dateFormatter.formatDate(vehicle.createdAt!.toLocal()),
                ),
              if (vehicle.isLicenseBlocked)
                const _StatusPill(
                  icon: Icons.block_rounded,
                  label: 'License Blocked',
                  color: OpenVtsColors.error,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({
    required this.icon,
    required this.label,
    this.copyValue,
  });

  final IconData icon;
  final String label;
  final String? copyValue;

  @override
  Widget build(BuildContext context) {
    final normalizedCopyValue = copyValue?.trim() ?? '';
    final content = _StatusPill(
      icon: icon,
      label: label,
      color: OpenVtsColors.textSecondary,
    );

    if (normalizedCopyValue.isEmpty) return content;

    return Tooltip(
      message: 'Copy',
      child: InkWell(
        borderRadius: BorderRadius.circular(OpenVtsRadius.pill),
        onTap: () {
          Clipboard.setData(ClipboardData(text: normalizedCopyValue));
          ToastHelper.showSuccess('Copied', context: context);
        },
        child: content,
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 240),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(OpenVtsRadius.pill),
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: OpenVtsTypography.meta.copyWith(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _vehicleTitle(UserVehicleListItem vehicle) {
  if (vehicle.name.trim().isNotEmpty) return vehicle.name.trim();
  if (vehicle.plateNumber.trim().isNotEmpty) return vehicle.plateNumber.trim();
  if (vehicle.imei.trim().isNotEmpty) return vehicle.imei.trim();
  return 'Vehicle';
}

String _display(String value) {
  final normalized = value.trim();
  return normalized.isEmpty ? '-' : normalized;
}

String _joinParts(List<String?> parts) {
  final normalized = parts
      .map((item) => item?.trim() ?? '')
      .where((item) => item.isNotEmpty && item != '-')
      .toList(growable: false);
  return normalized.isEmpty ? '-' : normalized.join(' - ');
}
