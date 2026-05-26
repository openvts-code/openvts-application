import 'package:flutter/material.dart';

import '../../../../../core/theme/open_vts_colors.dart';
import '../../../../../core/theme/open_vts_radius.dart';
import '../../../../../core/theme/open_vts_spacing.dart';
import '../../../../../core/theme/open_vts_typography.dart';
import '../../../../../shared/widgets/open_vts_card.dart';
import '../../../../../shared/widgets/open_vts_empty_state.dart';
import '../../../models/user_notification_settings_model.dart';
import 'user_notification_channel_card.dart';
import 'user_notification_vehicle_card.dart';

const double _matrixBreakpoint = 760;
const int _maxMatrixGeofences = 5;

class UserGeofenceNotificationTab extends StatelessWidget {
  const UserGeofenceNotificationTab({
    required this.preferences,
    required this.channelFlags,
    required this.onChannelChanged,
    required this.onGeofenceToggle,
    super.key,
  });

  final UserNotificationPreferences preferences;
  final UserNotificationChannelFlags channelFlags;
  final void Function(UserNotificationChannel channel, bool value)
      onChannelChanged;
  final void Function(int vehicleId, int geofenceId, bool value)
      onGeofenceToggle;

  @override
  Widget build(BuildContext context) {
    if (preferences.geofences.isEmpty) {
      return Column(
        children: [
          UserNotificationChannelCard(
            selectedGroup: UserNotificationGroup.geofence,
            flags: channelFlags,
            onChanged: onChannelChanged,
          ),
          const SizedBox(height: OpenVtsSpacing.sm),
          const OpenVtsEmptyState(
            title: 'No geofences available.',
            message: 'Create geofences to configure geofence notifications.',
          ),
        ],
      );
    }

    if (preferences.vehicles.isEmpty) {
      return Column(
        children: [
          UserNotificationChannelCard(
            selectedGroup: UserNotificationGroup.geofence,
            flags: channelFlags,
            onChanged: onChannelChanged,
          ),
          const SizedBox(height: OpenVtsSpacing.sm),
          const OpenVtsEmptyState(
            title: 'No vehicles assigned yet.',
            message: 'Assign vehicles to configure geofence notifications.',
          ),
        ],
      );
    }

    final enabledLookup = <String, bool>{
      for (final item in preferences.geofenceMatrix)
        '${item.vehicleId}:${item.geofenceId}': item.enabled,
    };

    final enabledCountByVehicle = <int, int>{};
    for (final item in preferences.geofenceMatrix) {
      if (!item.enabled) {
        continue;
      }

      enabledCountByVehicle[item.vehicleId] =
          (enabledCountByVehicle[item.vehicleId] ?? 0) + 1;
    }

    return Column(
      children: [
        UserNotificationChannelCard(
          selectedGroup: UserNotificationGroup.geofence,
          flags: channelFlags,
          onChanged: onChannelChanged,
        ),
        const SizedBox(height: OpenVtsSpacing.sm),
        LayoutBuilder(
          builder: (context, constraints) {
            final useMatrix = constraints.maxWidth >= _matrixBreakpoint &&
                preferences.geofences.length <= _maxMatrixGeofences;

            if (useMatrix) {
              return _WideGeofenceMatrix(
                vehicles: preferences.vehicles,
                geofences: preferences.geofences,
                enabledLookup: enabledLookup,
                onToggle: onGeofenceToggle,
              );
            }

            return Column(
              children: preferences.vehicles.map((vehicle) {
                final enabledCount = enabledCountByVehicle[vehicle.id] ?? 0;

                return Padding(
                  padding: const EdgeInsets.only(bottom: OpenVtsSpacing.sm),
                  child: _VehicleGeofenceCard(
                    vehicle: vehicle,
                    geofences: preferences.geofences,
                    enabledCount: enabledCount,
                    enabledLookup: enabledLookup,
                    onToggle: onGeofenceToggle,
                  ),
                );
              }).toList(growable: false),
            );
          },
        ),
      ],
    );
  }
}

class _VehicleGeofenceCard extends StatelessWidget {
  const _VehicleGeofenceCard({
    required this.vehicle,
    required this.geofences,
    required this.enabledCount,
    required this.enabledLookup,
    required this.onToggle,
  });

  final UserNotificationVehicle vehicle;
  final List<UserNotificationGeofence> geofences;
  final int enabledCount;
  final Map<String, bool> enabledLookup;
  final void Function(int vehicleId, int geofenceId, bool value) onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return OpenVtsCard(
      padding: const EdgeInsets.symmetric(
        horizontal: OpenVtsSpacing.xs,
        vertical: 2,
      ),
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: EdgeInsets.zero,
          childrenPadding: const EdgeInsets.only(bottom: OpenVtsSpacing.xs),
          iconColor: OpenVtsColors.textSecondary,
          collapsedIconColor: OpenVtsColors.textSecondary,
          title: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: OpenVtsColors.surface,
                  borderRadius: BorderRadius.circular(OpenVtsRadius.sm),
                  border: Border.all(color: OpenVtsColors.border),
                ),
                child: const Icon(
                  Icons.directions_car_outlined,
                  size: 14,
                  color: OpenVtsColors.textSecondary,
                ),
              ),
              const SizedBox(width: OpenVtsSpacing.xs),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userNotificationVehicleName(vehicle.name, vehicle.id),
                      style: OpenVtsTypography.body.copyWith(
                        color: OpenVtsColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      userNotificationVehiclePlate(vehicle.plateNumber),
                      style: OpenVtsTypography.meta.copyWith(
                        color: OpenVtsColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              _EnabledCountChip(enabledCount: enabledCount),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: OpenVtsSpacing.xxs),
            child: Text(
              'Tap to edit geofence notifications',
              style: OpenVtsTypography.meta.copyWith(
                color: OpenVtsColors.textTertiary,
              ),
            ),
          ),
          children: [
            ...geofences.asMap().entries.map((entry) {
              final index = entry.key;
              final geofence = entry.value;
              final key = '${vehicle.id}:${geofence.id}';
              final enabled = enabledLookup[key] ?? false;

              return Padding(
                padding: EdgeInsets.only(
                  top: index == 0 ? OpenVtsSpacing.xs : OpenVtsSpacing.xxs,
                ),
                child: Column(
                  children: [
                    _GeofenceToggleRow(
                      vehicleLabel:
                          userNotificationVehicleName(vehicle.name, vehicle.id),
                      geofence: geofence,
                      enabled: enabled,
                      onChanged: (value) {
                        onToggle(vehicle.id, geofence.id, value);
                      },
                    ),
                    if (index != geofences.length - 1)
                      const Divider(
                        height: OpenVtsSpacing.sm,
                        color: OpenVtsColors.border,
                      ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _GeofenceToggleRow extends StatelessWidget {
  const _GeofenceToggleRow({
    required this.vehicleLabel,
    required this.geofence,
    required this.enabled,
    required this.onChanged,
  });

  final String vehicleLabel;
  final UserNotificationGeofence geofence;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final normalizedName = geofence.name.trim();
    final name =
        normalizedName.isEmpty ? 'Geofence #${geofence.id}' : normalizedName;
    final type = geofence.type.trim().isEmpty ? '-' : geofence.type.trim();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 2),
          child: Icon(
            Icons.location_on_outlined,
            size: 14,
            color: OpenVtsColors.textSecondary,
          ),
        ),
        const SizedBox(width: OpenVtsSpacing.xs),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: OpenVtsTypography.meta.copyWith(
                  color: OpenVtsColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: OpenVtsSpacing.xxs),
              Wrap(
                spacing: OpenVtsSpacing.xs,
                runSpacing: OpenVtsSpacing.xxs,
                children: [
                  _MetaChip(
                    label: type,
                    isActive: false,
                    isStatus: false,
                  ),
                  _MetaChip(
                    label: geofence.isActive ? 'Active' : 'Inactive',
                    isActive: geofence.isActive,
                    isStatus: true,
                  ),
                ],
              ),
            ],
          ),
        ),
        Semantics(
          label: 'Geofence $name for $vehicleLabel',
          toggled: enabled,
          child: Switch.adaptive(
            value: enabled,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.label,
    required this.isActive,
    required this.isStatus,
  });

  final String label;
  final bool isActive;
  final bool isStatus;

  @override
  Widget build(BuildContext context) {
    final textColor = isStatus
        ? (isActive ? OpenVtsColors.success : OpenVtsColors.textSecondary)
        : OpenVtsColors.textSecondary;
    final borderColor = isStatus
        ? (isActive
            ? OpenVtsColors.success.withValues(alpha: 0.28)
            : OpenVtsColors.border)
        : OpenVtsColors.border;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: OpenVtsSpacing.xs,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: OpenVtsColors.surfaceElevated,
        borderRadius: BorderRadius.circular(OpenVtsRadius.sm),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        label,
        style: OpenVtsTypography.meta.copyWith(
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _EnabledCountChip extends StatelessWidget {
  const _EnabledCountChip({required this.enabledCount});

  final int enabledCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: OpenVtsSpacing.xs,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: OpenVtsColors.surfaceElevated,
        borderRadius: BorderRadius.circular(OpenVtsRadius.sm),
        border: Border.all(color: OpenVtsColors.border),
      ),
      child: Text(
        '$enabledCount enabled',
        style: OpenVtsTypography.meta.copyWith(
          color: OpenVtsColors.textSecondary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _WideGeofenceMatrix extends StatelessWidget {
  const _WideGeofenceMatrix({
    required this.vehicles,
    required this.geofences,
    required this.enabledLookup,
    required this.onToggle,
  });

  final List<UserNotificationVehicle> vehicles;
  final List<UserNotificationGeofence> geofences;
  final Map<String, bool> enabledLookup;
  final void Function(int vehicleId, int geofenceId, bool value) onToggle;

  @override
  Widget build(BuildContext context) {
    final columnWidths = <int, TableColumnWidth>{
      0: const FlexColumnWidth(2.8),
      for (var i = 0; i < geofences.length; i += 1)
        i + 1: const FlexColumnWidth(1.2),
    };

    return OpenVtsCard(
      padding: const EdgeInsets.all(OpenVtsSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Vehicle-Geofence Matrix',
            style: OpenVtsTypography.meta.copyWith(
              color: OpenVtsColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: OpenVtsSpacing.xs),
          Table(
            columnWidths: columnWidths,
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            children: [
              TableRow(
                children: [
                  const _MatrixHeaderCell(label: 'Vehicle'),
                  ...geofences.map(
                    (geofence) => _MatrixHeaderCell(
                      label: _shortName(geofence.name, geofence.id),
                      tooltip: geofence.name.trim().isEmpty
                          ? 'Geofence #${geofence.id}'
                          : geofence.name.trim(),
                    ),
                  ),
                ],
              ),
              ...vehicles.map((vehicle) {
                return TableRow(
                  children: [
                    _MatrixVehicleCell(vehicle: vehicle),
                    ...geofences.map((geofence) {
                      final key = '${vehicle.id}:${geofence.id}';
                      final enabled = enabledLookup[key] ?? false;

                      return Center(
                        child: Semantics(
                          label:
                              'Geofence ${_shortName(geofence.name, geofence.id)} for ${userNotificationVehicleName(vehicle.name, vehicle.id)}',
                          toggled: enabled,
                          child: Switch.adaptive(
                            value: enabled,
                            onChanged: (value) {
                              onToggle(vehicle.id, geofence.id, value);
                            },
                          ),
                        ),
                      );
                    }),
                  ],
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  String _shortName(String name, int geofenceId) {
    final normalized = name.trim();
    if (normalized.isEmpty) {
      return '#$geofenceId';
    }

    if (normalized.length <= 10) {
      return normalized;
    }

    return '${normalized.substring(0, 10)}...';
  }
}

class _MatrixHeaderCell extends StatelessWidget {
  const _MatrixHeaderCell({
    required this.label,
    this.tooltip,
  });

  final String label;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final text = Text(
      label,
      style: OpenVtsTypography.meta.copyWith(
        color: OpenVtsColors.textSecondary,
        fontWeight: FontWeight.w700,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.center,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: OpenVtsSpacing.xxs,
        vertical: OpenVtsSpacing.xs,
      ),
      child: tooltip == null ? text : Tooltip(message: tooltip!, child: text),
    );
  }
}

class _MatrixVehicleCell extends StatelessWidget {
  const _MatrixVehicleCell({required this.vehicle});

  final UserNotificationVehicle vehicle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: OpenVtsSpacing.xxs,
        vertical: OpenVtsSpacing.xxs,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            userNotificationVehicleName(vehicle.name, vehicle.id),
            style: OpenVtsTypography.meta.copyWith(
              color: OpenVtsColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            userNotificationVehiclePlate(vehicle.plateNumber),
            style: OpenVtsTypography.meta.copyWith(
              color: OpenVtsColors.textTertiary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
