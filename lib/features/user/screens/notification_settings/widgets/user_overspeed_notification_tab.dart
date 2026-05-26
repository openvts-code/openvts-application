import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../core/theme/open_vts_colors.dart';
import '../../../../../core/theme/open_vts_radius.dart';
import '../../../../../core/theme/open_vts_spacing.dart';
import '../../../../../core/theme/open_vts_typography.dart';
import '../../../../../shared/widgets/open_vts_empty_state.dart';
import '../../../models/user_notification_settings_model.dart';
import 'user_notification_channel_card.dart';
import 'user_notification_compact_toggle.dart';
import 'user_notification_vehicle_card.dart';

class UserOverspeedNotificationTab extends StatelessWidget {
  const UserOverspeedNotificationTab({
    required this.preferences,
    required this.channelFlags,
    required this.onChannelChanged,
    required this.onOverspeedEnabledChanged,
    required this.onSpeedLimitChanged,
    super.key,
  });

  final UserNotificationPreferences preferences;
  final UserNotificationChannelFlags channelFlags;
  final void Function(UserNotificationChannel channel, bool value)
      onChannelChanged;
  final void Function(int vehicleId, bool value) onOverspeedEnabledChanged;
  final void Function(int vehicleId, int? speedLimitKph) onSpeedLimitChanged;

  @override
  Widget build(BuildContext context) {
    if (preferences.vehicles.isEmpty) {
      return Column(
        children: [
          UserNotificationChannelCard(
            selectedGroup: UserNotificationGroup.overspeed,
            flags: channelFlags,
            onChanged: onChannelChanged,
          ),
          const SizedBox(height: OpenVtsSpacing.sm),
          const OpenVtsEmptyState(
            title: 'No vehicles assigned yet.',
            message: 'Assign vehicles to configure overspeed notifications.',
          ),
        ],
      );
    }

    final rowsByVehicle = <int, UserOverspeedNotificationRow>{
      for (final row in preferences.overspeed) row.vehicleId: row,
    };

    return Column(
      children: [
        UserNotificationChannelCard(
          selectedGroup: UserNotificationGroup.overspeed,
          flags: channelFlags,
          onChanged: onChannelChanged,
        ),
        const SizedBox(height: OpenVtsSpacing.sm),
        ...preferences.vehicles.map((vehicle) {
          final row = rowsByVehicle[vehicle.id] ??
              UserOverspeedNotificationRow(vehicleId: vehicle.id);
          final isInvalid = row.enabled && ((row.speedLimitKph ?? 0) < 1);
          final vehicleLabel =
              userNotificationVehicleName(vehicle.name, vehicle.id);

          return Padding(
            padding: const EdgeInsets.only(bottom: OpenVtsSpacing.sm),
            child: UserNotificationVehicleCard(
              vehicleName: vehicleLabel,
              plateNumber: userNotificationVehiclePlate(vehicle.plateNumber),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  UserNotificationCompactToggle(
                    label: 'Overspeed Enabled',
                    icon: Icons.speed_rounded,
                    semanticsLabel: 'Overspeed alerts for $vehicleLabel',
                    value: row.enabled,
                    onChanged: (value) {
                      onOverspeedEnabledChanged(vehicle.id, value);
                    },
                  ),
                  const SizedBox(height: OpenVtsSpacing.xs),
                  _SpeedLimitField(
                    vehicleId: vehicle.id,
                    vehicleLabel: vehicleLabel,
                    enabled: row.enabled,
                    hasError: isInvalid,
                    value: row.speedLimitKph,
                    onChanged: (value) {
                      onSpeedLimitChanged(vehicle.id, value);
                    },
                  ),
                  if (isInvalid)
                    Padding(
                      padding: const EdgeInsets.only(
                        top: OpenVtsSpacing.xxs,
                        left: OpenVtsSpacing.xxs,
                      ),
                      child: Text(
                        'Speed limit must be at least 1 km/h.',
                        style: OpenVtsTypography.meta.copyWith(
                          color: OpenVtsColors.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
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

class _SpeedLimitField extends StatelessWidget {
  const _SpeedLimitField({
    required this.vehicleId,
    required this.vehicleLabel,
    required this.enabled,
    required this.hasError,
    required this.value,
    required this.onChanged,
  });

  final int vehicleId;
  final String vehicleLabel;
  final bool enabled;
  final bool hasError;
  final int? value;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    final key = ValueKey<String>(
      'speed-limit-$vehicleId-${value ?? 'null'}-$enabled',
    );

    return SizedBox(
      width: 140,
      child: Semantics(
        textField: true,
        label: 'Overspeed limit in kilometers per hour for $vehicleLabel',
        child: TextFormField(
          key: key,
          initialValue: value?.toString() ?? '',
          enabled: enabled,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(3),
          ],
          style: OpenVtsTypography.meta.copyWith(
            color: enabled
                ? OpenVtsColors.textPrimary
                : OpenVtsColors.textTertiary,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            isDense: true,
            hintText: 'Limit',
            hintStyle: OpenVtsTypography.meta.copyWith(
              color: OpenVtsColors.textTertiary,
            ),
            suffixText: 'km/h',
            suffixStyle: OpenVtsTypography.meta.copyWith(
              color: OpenVtsColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: OpenVtsSpacing.xs,
              vertical: 10,
            ),
            filled: true,
            fillColor:
                enabled ? OpenVtsColors.surfaceElevated : OpenVtsColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(OpenVtsRadius.sm),
              borderSide: BorderSide(
                color: hasError ? OpenVtsColors.error : OpenVtsColors.border,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(OpenVtsRadius.sm),
              borderSide: BorderSide(
                color: hasError ? OpenVtsColors.error : OpenVtsColors.border,
              ),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(OpenVtsRadius.sm),
              borderSide: BorderSide(
                color: hasError ? OpenVtsColors.error : OpenVtsColors.border,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(OpenVtsRadius.sm),
              borderSide: BorderSide(
                color: hasError
                    ? OpenVtsColors.error
                    : OpenVtsColors.textSecondary,
              ),
            ),
          ),
          onChanged: (raw) {
            final trimmed = raw.trim();
            if (trimmed.isEmpty) {
              onChanged(null);
              return;
            }

            onChanged(int.tryParse(trimmed));
          },
        ),
      ),
    );
  }
}
