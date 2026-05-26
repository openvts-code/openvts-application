import 'package:flutter/material.dart';

import '../../../../../core/theme/open_vts_spacing.dart';
import '../../../../../shared/widgets/open_vts_empty_state.dart';
import '../../../models/user_notification_settings_model.dart';
import 'user_notification_channel_card.dart';
import 'user_notification_compact_toggle.dart';
import 'user_notification_vehicle_card.dart';

class UserBasicNotificationTab extends StatelessWidget {
  const UserBasicNotificationTab({
    required this.preferences,
    required this.channelFlags,
    required this.onChannelChanged,
    required this.onVehicleToggle,
    super.key,
  });

  final UserNotificationPreferences preferences;
  final UserNotificationChannelFlags channelFlags;
  final void Function(UserNotificationChannel channel, bool value)
      onChannelChanged;
  final void Function(
    int vehicleId, {
    bool? ignitionEnabled,
    bool? alarmEnabled,
  }) onVehicleToggle;

  @override
  Widget build(BuildContext context) {
    if (preferences.vehicles.isEmpty) {
      return Column(
        children: [
          UserNotificationChannelCard(
            selectedGroup: UserNotificationGroup.basic,
            flags: channelFlags,
            onChanged: onChannelChanged,
          ),
          const SizedBox(height: OpenVtsSpacing.sm),
          const OpenVtsEmptyState(
            title: 'No vehicles assigned yet.',
            message: 'Assign vehicles to configure basic notifications.',
          ),
        ],
      );
    }

    final rowsByVehicle = <int, UserBasicNotificationRow>{
      for (final row in preferences.basic) row.vehicleId: row,
    };

    return Column(
      children: [
        UserNotificationChannelCard(
          selectedGroup: UserNotificationGroup.basic,
          flags: channelFlags,
          onChanged: onChannelChanged,
        ),
        const SizedBox(height: OpenVtsSpacing.sm),
        ...preferences.vehicles.map((vehicle) {
          final row = rowsByVehicle[vehicle.id] ??
              UserBasicNotificationRow(vehicleId: vehicle.id);
          final vehicleLabel =
              userNotificationVehicleName(vehicle.name, vehicle.id);

          return Padding(
            padding: const EdgeInsets.only(bottom: OpenVtsSpacing.sm),
            child: UserNotificationVehicleCard(
              vehicleName: vehicleLabel,
              plateNumber: userNotificationVehiclePlate(vehicle.plateNumber),
              child: Column(
                children: [
                  UserNotificationCompactToggle(
                    label: 'Ignition',
                    icon: Icons.power_settings_new_rounded,
                    semanticsLabel: 'Ignition alerts for $vehicleLabel',
                    value: row.ignitionEnabled,
                    onChanged: (value) {
                      onVehicleToggle(vehicle.id, ignitionEnabled: value);
                    },
                  ),
                  const SizedBox(height: OpenVtsSpacing.xs),
                  UserNotificationCompactToggle(
                    label: 'Alarm',
                    icon: Icons.notifications_active_outlined,
                    semanticsLabel: 'Alarm alerts for $vehicleLabel',
                    value: row.alarmEnabled,
                    onChanged: (value) {
                      onVehicleToggle(vehicle.id, alarmEnabled: value);
                    },
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}
