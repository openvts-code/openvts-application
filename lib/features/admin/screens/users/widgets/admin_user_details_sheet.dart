import 'package:flutter/material.dart';

import '../../../../../core/theme/open_vts_colors.dart';
import '../../../../../core/theme/open_vts_spacing.dart';
import '../../../../../core/theme/open_vts_typography.dart';
import '../../../../../core/utils/date_time_formatter.dart';
import '../../../../../shared/widgets/open_vts_button.dart';
import '../../../models/admin_users_model.dart';

class AdminUserDetailsSheet extends StatelessWidget {
  const AdminUserDetailsSheet({
    required this.user,
    required this.onEdit,
    required this.onChangePassword,
    required this.onLoginAsUser,
    required this.onDelete,
    super.key,
  });

  final AdminUserListItem user;
  final VoidCallback onEdit;
  final VoidCallback onChangePassword;
  final VoidCallback onLoginAsUser;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(OpenVtsSpacing.md),
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _displayValue(user.name),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: OpenVtsTypography.titleSmall.copyWith(
                      color: OpenVtsColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: OpenVtsSpacing.xxs),
                  Text(
                    user.username.trim().isEmpty ? '—' : '@${user.username}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: OpenVtsTypography.meta.copyWith(
                      color: OpenVtsColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            _StatusBadge(
              label: user.isActive ? 'Active' : 'Inactive',
              color:
                  user.isActive ? OpenVtsColors.success : OpenVtsColors.error,
            ),
          ],
        ),
        const SizedBox(height: OpenVtsSpacing.md),
        _DetailsRow(
          icon: Icons.verified_rounded,
          label: 'Email status',
          value: user.isEmailVerified ? 'Verified' : 'Unverified',
        ),
        _DetailsRow(
          icon: Icons.mail_outline_rounded,
          label: 'Email',
          value: user.email,
        ),
        _DetailsRow(
          icon: Icons.phone_rounded,
          label: 'Mobile',
          value: user.mobileDisplay,
        ),
        _DetailsRow(
          icon: Icons.apartment_rounded,
          label: 'Company',
          value: user.companyName,
        ),
        _DetailsRow(
          icon: Icons.place_outlined,
          label: 'Location',
          value: user.location,
        ),
        _DetailsRow(
          icon: Icons.flag_outlined,
          label: 'Country',
          value: user.countryCode,
        ),
        _DetailsRow(
          icon: Icons.directions_car_filled_outlined,
          label: 'Assigned vehicles',
          value: _vehicleCountText(user.vehicleCount),
        ),
        _DetailsRow(
          icon: Icons.calendar_today_rounded,
          label: 'Created',
          value: user.createdAt == null
              ? '—'
              : const DateTimeFormatter().formatDate(user.createdAt!.toLocal()),
        ),
        const SizedBox(height: OpenVtsSpacing.md),
        Row(
          children: [
            Expanded(
              child: OpenVtsButton(
                label: 'Edit',
                height: 40,
                onPressed: onEdit,
                variant: OpenVtsButtonVariant.secondary,
              ),
            ),
            const SizedBox(width: OpenVtsSpacing.xs),
            Expanded(
              child: OpenVtsButton(
                label: 'Password',
                height: 40,
                onPressed: onChangePassword,
                variant: OpenVtsButtonVariant.secondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: OpenVtsSpacing.xs),
        Row(
          children: [
            Expanded(
              child: OpenVtsButton(
                label: 'Login as User',
                height: 40,
                onPressed: onLoginAsUser,
                trailingIcon: Icons.login_rounded,
              ),
            ),
            const SizedBox(width: OpenVtsSpacing.xs),
            Expanded(
              child: OpenVtsButton(
                label: 'Delete',
                height: 40,
                onPressed: onDelete,
                variant: OpenVtsButtonVariant.secondary,
                trailingIcon: Icons.delete_outline_rounded,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: OpenVtsSpacing.xs,
        vertical: OpenVtsSpacing.xxs,
      ),
      decoration: BoxDecoration(
        border: Border.all(color: color.withValues(alpha: 0.35)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: OpenVtsTypography.meta.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _DetailsRow extends StatelessWidget {
  const _DetailsRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: OpenVtsSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: OpenVtsColors.textTertiary),
          const SizedBox(width: OpenVtsSpacing.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: OpenVtsTypography.meta.copyWith(
                    color: OpenVtsColors.textTertiary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _displayValue(value),
                  style: OpenVtsTypography.label.copyWith(
                    color: OpenVtsColors.textPrimary,
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

String _displayValue(String value) {
  final normalized = value.trim();
  if (normalized.isEmpty || normalized == '-') {
    return '—';
  }
  return normalized;
}

String _vehicleCountText(int count) {
  if (count == 1) {
    return '1 vehicle';
  }
  return '$count vehicles';
}
