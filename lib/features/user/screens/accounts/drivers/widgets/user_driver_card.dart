import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../../core/router/route_paths.dart';
import '../../../../../../core/theme/open_vts_colors.dart';
import '../../../../../../core/theme/open_vts_radius.dart';
import '../../../../../../core/theme/open_vts_spacing.dart';
import '../../../../../../core/theme/open_vts_typography.dart';
import '../../../../../../core/utils/date_time_formatter.dart';
import '../../../../../../shared/widgets/open_vts_card.dart';
import '../../../../../../shared/widgets/open_vts_status_chip.dart';
import '../../../../models/user_driver_model.dart';

const DateTimeFormatter _dateFormatter = DateTimeFormatter();

class UserDriverCard extends StatelessWidget {
  const UserDriverCard({
    required this.driver,
    super.key,
  });

  final UserDriver driver;

  @override
  Widget build(BuildContext context) {
    final hasDriverId = driver.id.trim().isNotEmpty;

    return OpenVtsCard(
      onTap: hasDriverId
          ? () {
              context.push(
                RoutePaths.userDriverDetailsPath(driver.id),
                extra: driver,
              );
            }
          : null,
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
                  Icons.badge_outlined,
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
                      _driverTitle(driver),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: OpenVtsTypography.label.copyWith(
                        color: OpenVtsColors.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _usernameLabel(driver),
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
              if (hasDriverId)
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: OpenVtsColors.textTertiary,
                ),
            ],
          ),
          const SizedBox(height: OpenVtsSpacing.xs),
          Wrap(
            spacing: OpenVtsSpacing.xs,
            runSpacing: OpenVtsSpacing.xs,
            children: [
              OpenVtsStatusChip(
                label: driver.isActive ? 'Active' : 'Inactive',
                type: driver.isActive
                    ? OpenVtsStatusType.success
                    : OpenVtsStatusType.neutral,
              ),
              OpenVtsStatusChip(
                label: driver.isVerified ? 'Verified' : 'Unverified',
                type: driver.isVerified
                    ? OpenVtsStatusType.info
                    : OpenVtsStatusType.neutral,
              ),
            ],
          ),
          const SizedBox(height: OpenVtsSpacing.xs),
          Wrap(
            spacing: OpenVtsSpacing.xs,
            runSpacing: OpenVtsSpacing.xs,
            children: [
              _MetaPill(
                icon: Icons.phone_outlined,
                label: _phoneLabel(driver),
              ),
              if (driver.email.trim().isNotEmpty)
                _MetaPill(
                  icon: Icons.mail_outline_rounded,
                  label: driver.email.trim(),
                ),
              _MetaPill(
                icon: Icons.directions_car_outlined,
                label: _assignmentLabel(driver),
              ),
              _MetaPill(
                icon: Icons.calendar_today_outlined,
                label: _createdLabel(driver),
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
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 280),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: OpenVtsColors.textSecondary.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(OpenVtsRadius.pill),
        border: Border.all(
          color: OpenVtsColors.textSecondary.withValues(alpha: 0.14),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: OpenVtsColors.textSecondary),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: OpenVtsTypography.meta.copyWith(
                color: OpenVtsColors.textSecondary,
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

String _driverTitle(UserDriver driver) {
  for (final value in [driver.name, driver.username, driver.email]) {
    final normalized = value.trim();
    if (normalized.isNotEmpty && normalized != '-') {
      return normalized;
    }
  }
  return 'Driver';
}

String _usernameLabel(UserDriver driver) {
  final username = driver.username.trim();
  if (username.isEmpty || username == '-') {
    return 'Username unavailable';
  }
  return '@$username';
}

String _phoneLabel(UserDriver driver) {
  final prefix = driver.mobilePrefix.trim();
  final mobile = driver.mobile.trim();
  final value = [prefix, mobile]
      .where((part) => part.isNotEmpty && part != '-')
      .join(' ')
      .trim();
  return value.isEmpty ? '-' : value;
}

String _assignmentLabel(UserDriver driver) {
  final vehicle = driver.assignedVehicle;
  if (vehicle == null) {
    return 'Unassigned';
  }

  final name = vehicle.name.trim();
  final plate = vehicle.plateNumber.trim();
  final combined = [name, plate]
      .where((part) => part.isNotEmpty && part != '-')
      .join(' - ')
      .trim();
  return combined.isEmpty ? 'Assigned' : combined;
}

String _createdLabel(UserDriver driver) {
  final createdAt = driver.createdAt;
  if (createdAt == null) {
    return 'Created date unavailable';
  }
  return _dateFormatter.formatDate(createdAt.toLocal());
}
