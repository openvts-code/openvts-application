import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../core/theme/open_vts_colors.dart';
import '../../../../../core/theme/open_vts_radius.dart';
import '../../../../../core/theme/open_vts_spacing.dart';
import '../../../../../core/theme/open_vts_typography.dart';
import '../../../models/admin_team_model.dart';

class AdminTeamCard extends StatelessWidget {
  const AdminTeamCard({required this.team, this.onTap, super.key});

  final AdminTeamListItem team;
  final VoidCallback? onTap;

  static final DateFormat _createdFormat = DateFormat('yyyy-MM-dd HH:mm');

  @override
  Widget build(BuildContext context) {
    final name = _displayName(team);
    final username = _displayUsername(team);
    final createdValue = team.createdAt == null
        ? '-'
        : _createdFormat.format(team.createdAt!.toLocal());

    return _RoundedSurface(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(
            name: name,
            username: username,
            isVerified: team.isVerified,
            statusLabel: team.statusLabel,
            initials: _initials(name),
          ),
          const SizedBox(height: OpenVtsSpacing.md),
          _CardInfoGrid(
            email: _displayValue(team.email),
            phone: _displayValue(team.phone),
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
    required this.username,
    required this.isVerified,
    required this.statusLabel,
    required this.initials,
  });

  final String name;
  final String username;
  final bool isVerified;
  final String statusLabel;
  final String initials;

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
          child: initials.isNotEmpty
              ? Text(
                  initials,
                  style: OpenVtsTypography.label.copyWith(
                    fontWeight: FontWeight.w700,
                    color: _primaryInkColor(context),
                    fontSize: 14,
                  ),
                )
              : Icon(
                  Icons.person_outline_rounded,
                  size: 22,
                  color: _primaryInkColor(context),
                ),
        ),
        const SizedBox(width: OpenVtsSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                          ),
                    ),
                  ),
                  if (isVerified) ...[
                    const SizedBox(width: OpenVtsSpacing.xs),
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: _primaryInkColor(context),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.check_rounded,
                        size: 10,
                        color: OpenVtsColors.white,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 2),
              Text(
                '@$username',
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
        _StatusBadge(label: statusLabel),
      ],
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
    required this.email,
    required this.phone,
  });

  final String email;
  final String phone;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 420;

        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _InfoRow(icon: Icons.mail_outline_rounded, value: email),
              const SizedBox(height: OpenVtsSpacing.xs),
              _InfoRow(icon: Icons.call_outlined, value: phone),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _InfoRow(
                icon: Icons.mail_outline_rounded,
                value: email,
              ),
            ),
            const SizedBox(width: OpenVtsSpacing.sm),
            Expanded(
              child: _InfoRow(
                icon: Icons.call_outlined,
                value: phone,
              ),
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 16,
          color: OpenVtsColors.textSecondary,
        ),
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
          const Icon(
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

String _displayName(AdminTeamListItem team) {
  final name = team.teamName.trim();
  if (name.isNotEmpty && name != '-') {
    return name;
  }
  final username = team.username.trim();
  if (username.isNotEmpty && username != '-') {
    return username;
  }
  return _displayValue(team.email);
}

String _displayUsername(AdminTeamListItem team) {
  final username = team.username.trim();
  if (username.isNotEmpty && username != '-') {
    return username;
  }
  final email = team.email.trim();
  if (email.isNotEmpty && email != '-') {
    return email;
  }
  return 'unknown';
}

String _initials(String input) {
  final parts = input
      .trim()
      .split(RegExp(r'\s+'))
      .where((e) => e.isNotEmpty)
      .toList(growable: false);
  if (parts.isEmpty) return '';
  if (parts.length == 1) {
    return parts.first.characters.first.toUpperCase();
  }
  return '${parts.first.characters.first}${parts.last.characters.first}'
      .toUpperCase();
}

String _displayValue(String value) {
  final normalized = value.trim();
  return normalized.isEmpty || normalized == '-' ? '—' : normalized;
}
