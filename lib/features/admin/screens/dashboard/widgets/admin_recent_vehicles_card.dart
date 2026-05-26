import 'package:flutter/material.dart';

import '../../../../../core/router/route_paths.dart';
import '../../../../../core/theme/open_vts_colors.dart';
import '../../../../../core/theme/open_vts_spacing.dart';
import '../../../../../core/theme/open_vts_typography.dart';
import '../../../models/admin_dashboard_model.dart';
import 'admin_dashboard_list_card.dart';

class AdminRecentVehiclesCard extends StatelessWidget {
  const AdminRecentVehiclesCard({required this.vehicles, super.key});

  final List<AdminRecentVehicle> vehicles;

  @override
  Widget build(BuildContext context) {
    return AdminDashboardListCard(
      title: 'Recent Vehicles',
      icon: Icons.directions_car_outlined,
      viewAllRoute: RoutePaths.adminVehicles,
      emptyTitle: 'No recent vehicles',
      emptyMessage: 'New vehicles will appear here.',
      itemCount: vehicles.length,
      itemBuilder: (context, index) {
        return _RecentVehicleRow(vehicle: vehicles[index]);
      },
    );
  }
}

class _RecentVehicleRow extends StatelessWidget {
  const _RecentVehicleRow({required this.vehicle});

  final AdminRecentVehicle vehicle;

  @override
  Widget build(BuildContext context) {
    final status = _vehicleStatus(vehicle);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: OpenVtsSpacing.md,
        vertical: OpenVtsSpacing.sm,
      ),
      child: Row(
        children: [
          const AdminDashboardLeadingIcon(icon: Icons.directions_car_outlined),
          const SizedBox(width: OpenVtsSpacing.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  vehicle.plateNumber ?? vehicle.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: OpenVtsTypography.label.copyWith(
                    color: OpenVtsColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  vehicle.hasDevice ? (vehicle.imei ?? 'No IMEI') : 'No Device',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: OpenVtsTypography.meta.copyWith(
                    color: OpenVtsColors.textSecondary,
                    fontSize: 10.5,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: OpenVtsSpacing.xs),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 126),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                AdminDashboardStatusChip(
                  label: status.label,
                  icon: status.icon,
                  color: status.color,
                ),
                const SizedBox(height: 4),
                Text(
                  adminDashboardRelativeDate(vehicle.createdAt),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: OpenVtsTypography.meta.copyWith(
                    color: OpenVtsColors.textSecondary,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

_VehicleStatus _vehicleStatus(AdminRecentVehicle vehicle) {
  if (vehicle.licenseBlocked) {
    return const _VehicleStatus(
      label: 'License Blocked',
      icon: Icons.lock_outline_rounded,
      color: OpenVtsColors.error,
    );
  }

  if (!vehicle.hasDevice) {
    return const _VehicleStatus(
      label: 'No Device',
      icon: Icons.wifi_off_outlined,
      color: OpenVtsColors.textTertiary,
    );
  }

  switch (vehicle.liveStatus.trim().toUpperCase()) {
    case 'RUNNING':
      return const _VehicleStatus(
        label: 'Running',
        icon: Icons.speed_outlined,
        color: OpenVtsColors.success,
      );
    case 'STOP':
      return const _VehicleStatus(
        label: 'Stop',
        icon: Icons.pause_circle_outline_rounded,
        color: OpenVtsColors.info,
      );
    case 'INACTIVE':
      return const _VehicleStatus(
        label: 'Inactive',
        icon: Icons.warning_amber_rounded,
        color: OpenVtsColors.warning,
      );
    case 'NO_DATA':
    default:
      return const _VehicleStatus(
        label: 'No Data',
        icon: Icons.storage_outlined,
        color: OpenVtsColors.textTertiary,
      );
  }
}

class _VehicleStatus {
  const _VehicleStatus({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;
}
