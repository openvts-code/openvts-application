import 'package:flutter/material.dart';

import '../../../../../core/theme/open_vts_colors.dart';
import '../../../../../core/theme/open_vts_radius.dart';
import '../../../../../core/theme/open_vts_spacing.dart';
import '../../../../../core/theme/open_vts_typography.dart';
import '../../../../../core/utils/date_time_formatter.dart';
import '../../../models/admin_users_model.dart';

enum AdminUserCardAction {
  viewDetails,
  editUser,
  changePassword,
  loginAsUser,
  delete;

  String get label {
    switch (this) {
      case AdminUserCardAction.viewDetails:
        return 'View details';
      case AdminUserCardAction.editUser:
        return 'Edit user';
      case AdminUserCardAction.changePassword:
        return 'Change password';
      case AdminUserCardAction.loginAsUser:
        return 'Login as user';
      case AdminUserCardAction.delete:
        return 'Delete';
    }
  }

  IconData get icon {
    switch (this) {
      case AdminUserCardAction.viewDetails:
        return Icons.visibility_outlined;
      case AdminUserCardAction.editUser:
        return Icons.edit_rounded;
      case AdminUserCardAction.changePassword:
        return Icons.key_rounded;
      case AdminUserCardAction.loginAsUser:
        return Icons.login_rounded;
      case AdminUserCardAction.delete:
        return Icons.delete_outline_rounded;
    }
  }
}

const DateTimeFormatter _cardDateFormatter = DateTimeFormatter();

class AdminUserCard extends StatelessWidget {
  const AdminUserCard({
    required this.user,
    required this.isUpdating,
    required this.isDeleting,
    required this.isLoggingIn,
    required this.onTap,
    required this.onStatusChanged,
    required this.onActionSelected,
    super.key,
  });

  final AdminUserListItem user;
  final bool isUpdating;
  final bool isDeleting;
  final bool isLoggingIn;
  final VoidCallback onTap;
  final ValueChanged<bool> onStatusChanged;
  final ValueChanged<AdminUserCardAction> onActionSelected;

  @override
  Widget build(BuildContext context) {
    final isBusy = isUpdating || isDeleting || isLoggingIn;

    return _RoundedSurface(
      onTap: onTap,
      padding: const EdgeInsets.all(OpenVtsSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(
            user: user,
            isBusy: isBusy,
            isUpdating: isUpdating,
            isLoggingIn: isLoggingIn,
            onStatusChanged: onStatusChanged,
            onActionSelected: onActionSelected,
          ),
          const SizedBox(height: OpenVtsSpacing.md),
          _CardInfoGrid(user: user),
          const SizedBox(height: OpenVtsSpacing.md),
          _CardMetricsRow(user: user),
          if (isDeleting) ...[
            const SizedBox(height: OpenVtsSpacing.sm),
            const LinearProgressIndicator(minHeight: 2),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Card header (avatar + name + toggle + menu)
// ---------------------------------------------------------------------------

class _CardHeader extends StatelessWidget {
  const _CardHeader({
    required this.user,
    required this.isBusy,
    required this.isUpdating,
    required this.isLoggingIn,
    required this.onStatusChanged,
    required this.onActionSelected,
  });

  final AdminUserListItem user;
  final bool isBusy;
  final bool isUpdating;
  final bool isLoggingIn;
  final ValueChanged<bool> onStatusChanged;
  final ValueChanged<AdminUserCardAction> onActionSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _AvatarCircle(user: user),
        const SizedBox(width: OpenVtsSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      _displayName(user),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                          ),
                    ),
                  ),
                  const SizedBox(width: OpenVtsSpacing.xs),
                  Icon(
                    user.isEmailVerified
                        ? Icons.verified_rounded
                        : Icons.gpp_maybe_rounded,
                    size: 16,
                    color: user.isEmailVerified
                        ? OpenVtsColors.success
                        : OpenVtsColors.warning,
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                '@${_displayUsername(user)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: OpenVtsTypography.label.copyWith(
                  color: OpenVtsColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: OpenVtsSpacing.xs),
        _StatusToggle(
          isActive: user.isActive,
          isBusy: isBusy,
          isToggling: isUpdating,
          onChanged: onStatusChanged,
        ),
        _CardMenu(
          isBusy: isBusy,
          isLoggingIn: isLoggingIn,
          isActive: user.isActive,
          onStatusChanged: onStatusChanged,
          onActionSelected: onActionSelected,
        ),
      ],
    );
  }
}

class _AvatarCircle extends StatelessWidget {
  const _AvatarCircle({required this.user});

  final AdminUserListItem user;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      width: 44,
      decoration: BoxDecoration(
        color: _softSurfaceColor(context),
        shape: BoxShape.circle,
        border: Border.all(color: _softBorderColor(context)),
      ),
      alignment: Alignment.center,
      child: Text(
        _initials(user),
        style: OpenVtsTypography.label.copyWith(
          fontWeight: FontWeight.w700,
          color: _primaryInkColor(context),
          fontSize: 14,
        ),
      ),
    );
  }
}

class _StatusToggle extends StatelessWidget {
  const _StatusToggle({
    required this.isActive,
    required this.isBusy,
    required this.isToggling,
    required this.onChanged,
  });

  final bool isActive;
  final bool isBusy;
  final bool isToggling;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    if (isToggling) {
      return const SizedBox(
        width: 40,
        height: 32,
        child: Center(
          child: SizedBox.square(
            dimension: 16,
            child: CircularProgressIndicator(strokeWidth: 2.2),
          ),
        ),
      );
    }

    return Tooltip(
      message: isActive ? 'Deactivate user' : 'Activate user',
      child: Transform.scale(
        scale: 0.85,
        child: Switch(
          value: isActive,
          onChanged: isBusy ? null : onChanged,
          activeThumbColor: OpenVtsColors.white,
          activeTrackColor: _primaryInkColor(context),
          inactiveThumbColor: OpenVtsColors.white,
          inactiveTrackColor: _softBorderColor(context),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
    );
  }
}

class _CardMenu extends StatelessWidget {
  const _CardMenu({
    required this.isBusy,
    required this.isLoggingIn,
    required this.isActive,
    required this.onStatusChanged,
    required this.onActionSelected,
  });

  final bool isBusy;
  final bool isLoggingIn;
  final bool isActive;
  final ValueChanged<bool> onStatusChanged;
  final ValueChanged<AdminUserCardAction> onActionSelected;

  @override
  Widget build(BuildContext context) {
    if (isLoggingIn) {
      return const Padding(
        padding: EdgeInsetsDirectional.only(start: OpenVtsSpacing.xs),
        child: SizedBox.square(
          dimension: 18,
          child: CircularProgressIndicator(strokeWidth: 2.2),
        ),
      );
    }

    return PopupMenuButton<AdminUserCardAction>(
      tooltip: 'More options',
      onSelected: onActionSelected,
      itemBuilder: (context) => [
        for (final action in AdminUserCardAction.values)
          if (action == AdminUserCardAction.delete) ...[
            const PopupMenuDivider(),
            _menuItem(context, action),
          ] else
            _menuItem(context, action),
      ],
      enabled: !isBusy,
      icon: const Icon(
        Icons.more_vert_rounded,
        size: 18,
        color: OpenVtsColors.textSecondary,
      ),
      padding: EdgeInsets.zero,
      splashRadius: 18,
      position: PopupMenuPosition.under,
    );
  }

  PopupMenuItem<AdminUserCardAction> _menuItem(
    BuildContext context,
    AdminUserCardAction action,
  ) {
    final isDelete = action == AdminUserCardAction.delete;
    return PopupMenuItem<AdminUserCardAction>(
      value: action,
      child: Row(
        children: [
          Icon(
            action.icon,
            size: 16,
            color: isDelete ? OpenVtsColors.error : null,
          ),
          const SizedBox(width: OpenVtsSpacing.xs),
          Text(
            action.label,
            style: OpenVtsTypography.label.copyWith(
              color: isDelete ? OpenVtsColors.error : null,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Card info grid (email, phone, company, location)
// ---------------------------------------------------------------------------

class _CardInfoGrid extends StatelessWidget {
  const _CardInfoGrid({required this.user});

  final AdminUserListItem user;

  @override
  Widget build(BuildContext context) {
    final emailValue = _displayValue(user.email);
    final phoneValue = _displayValue(user.mobileDisplay);
    final companyValue = _displayValue(user.companyName);
    final countryValue = _displayValue(
      user.countryCode.trim().isNotEmpty
          ? user.countryCode.trim().toUpperCase()
          : _locationText(user),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 420;

        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _InfoRow(icon: Icons.mail_outline_rounded, value: emailValue),
              const SizedBox(height: OpenVtsSpacing.xs),
              _InfoRow(icon: Icons.call_outlined, value: phoneValue),
              const SizedBox(height: OpenVtsSpacing.xs),
              _InfoRow(icon: Icons.business_outlined, value: companyValue),
              const SizedBox(height: OpenVtsSpacing.xs),
              _InfoRow(icon: Icons.outlined_flag_rounded, value: countryValue),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _InfoRow(
                    icon: Icons.mail_outline_rounded,
                    value: emailValue,
                  ),
                ),
                const SizedBox(width: OpenVtsSpacing.sm),
                Expanded(
                  child: _InfoRow(
                    icon: Icons.call_outlined,
                    value: phoneValue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: OpenVtsSpacing.xs),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _InfoRow(
                    icon: Icons.business_outlined,
                    value: companyValue,
                  ),
                ),
                const SizedBox(width: OpenVtsSpacing.sm),
                Expanded(
                  child: _InfoRow(
                    icon: Icons.outlined_flag_rounded,
                    value: countryValue,
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

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.value,
  });

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, size: 16, color: OpenVtsColors.textSecondary),
        const SizedBox(width: OpenVtsSpacing.xs),
        Expanded(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: OpenVtsTypography.label.copyWith(
              color: OpenVtsColors.textPrimary,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Card metrics row (Vehicles / Created / Updated)
// ---------------------------------------------------------------------------

class _CardMetricsRow extends StatelessWidget {
  const _CardMetricsRow({required this.user});

  final AdminUserListItem user;

  @override
  Widget build(BuildContext context) {
    final createdValue = _createdLabel(user.createdAt);
    final updatedValue = _updatedLabel(user.updatedAt);

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 420;

        if (compact) {
          return Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _MetricCell(
                      icon: Icons.directions_car_outlined,
                      label: 'Vehicles',
                      value: user.vehicleCount.toString(),
                    ),
                  ),
                  const SizedBox(width: OpenVtsSpacing.xs),
                  Expanded(
                    child: _MetricCell(
                      icon: Icons.calendar_today_rounded,
                      label: 'Created',
                      value: createdValue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: OpenVtsSpacing.xs),
              _MetricCell(
                icon: Icons.schedule_outlined,
                label: 'Updated',
                value: updatedValue,
              ),
            ],
          );
        }

        return Row(
          children: [
            Expanded(
              child: _MetricCell(
                icon: Icons.directions_car_outlined,
                label: 'Vehicles',
                value: user.vehicleCount.toString(),
              ),
            ),
            const SizedBox(width: OpenVtsSpacing.xs),
            Expanded(
              child: _MetricCell(
                icon: Icons.calendar_today_rounded,
                label: 'Created',
                value: createdValue,
              ),
            ),
            const SizedBox(width: OpenVtsSpacing.xs),
            Expanded(
              flex: 2,
              child: _MetricCell(
                icon: Icons.schedule_outlined,
                label: 'Updated',
                value: updatedValue,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _MetricCell extends StatelessWidget {
  const _MetricCell({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: OpenVtsSpacing.sm,
        vertical: OpenVtsSpacing.xs + 2,
      ),
      decoration: BoxDecoration(
        color: _softSurfaceColor(context),
        borderRadius: BorderRadius.circular(OpenVtsRadius.md),
        border: Border.all(color: _softBorderColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: OpenVtsColors.textSecondary),
              const SizedBox(width: OpenVtsSpacing.xxs + 2),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: OpenVtsTypography.meta.copyWith(
                    color: OpenVtsColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: OpenVtsSpacing.xxs + 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: OpenVtsTypography.label.copyWith(
              color: _primaryInkColor(context),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared surface
// ---------------------------------------------------------------------------

class _RoundedSurface extends StatelessWidget {
  const _RoundedSurface({
    required this.child,
    this.padding = const EdgeInsets.all(OpenVtsSpacing.md),
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(OpenVtsRadius.lg);
    final surface = Container(
      width: double.infinity,
      padding: padding,
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

// ---------------------------------------------------------------------------
// Theme helpers
// ---------------------------------------------------------------------------

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

// ---------------------------------------------------------------------------
// Data helpers
// ---------------------------------------------------------------------------

String _displayName(AdminUserListItem user) {
  final name = user.name.trim();
  if (name.isNotEmpty) {
    return name;
  }
  final username = user.username.trim();
  if (username.isNotEmpty) {
    return username;
  }
  return _displayValue(user.email);
}

String _displayUsername(AdminUserListItem user) {
  final username = user.username.trim();
  if (username.isNotEmpty) {
    return username;
  }
  final email = user.email.trim();
  if (email.isNotEmpty) {
    return email;
  }
  return 'unknown';
}

String _initials(AdminUserListItem user) {
  final source = _displayName(user).trim();
  if (source.isEmpty || source == '\u2014') {
    return 'U';
  }
  final words = source.split(RegExp(r'\s+'));
  if (words.length == 1) {
    return words.first.characters.take(2).toString().toUpperCase();
  }
  return '${words.first.characters.first}${words.last.characters.first}'
      .toUpperCase();
}

String _locationText(AdminUserListItem user) {
  final parts = <String>[];
  final country = user.countryCode.trim().toUpperCase();
  if (country.isNotEmpty) {
    parts.add(country);
  }
  final state = user.stateCode.trim();
  if (state.isNotEmpty) {
    parts.add(state);
  }
  final city = user.city.trim();
  if (city.isNotEmpty) {
    parts.add(city);
  }
  return parts.isEmpty ? '\u2014' : parts.join(', ');
}

String _createdLabel(DateTime? value) {
  if (value == null) {
    return '\u2014';
  }
  final local = value.toLocal();
  return '${_cardDateFormatter.formatDate(local)} \u2022 ${_relativeTime(local)}';
}

String _updatedLabel(DateTime? value) {
  if (value == null) {
    return '\u2014';
  }
  final local = value.toLocal();
  return '${_cardDateFormatter.formatDate(local)} \u2022 ${_cardDateFormatter.formatTime(local)}';
}

String _relativeTime(DateTime value) {
  final difference = DateTime.now().difference(value);
  if (difference.isNegative || difference.inMinutes < 1) {
    return 'just now';
  }
  if (difference.inHours < 1) {
    return '${difference.inMinutes}m ago';
  }
  if (difference.inDays < 1) {
    return '${difference.inHours}h ago';
  }
  if (difference.inDays < 30) {
    return '${difference.inDays}d ago';
  }
  final months = difference.inDays ~/ 30;
  if (months < 12) {
    return '${months}mo ago';
  }
  return '${difference.inDays ~/ 365}y ago';
}

String _displayValue(String value) {
  final normalized = value.trim();
  return normalized.isEmpty || normalized == '-' ? '\u2014' : normalized;
}
