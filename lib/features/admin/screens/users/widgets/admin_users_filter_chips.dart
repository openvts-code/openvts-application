import 'package:flutter/material.dart';

import '../../../../../core/theme/open_vts_colors.dart';
import '../../../../../core/theme/open_vts_radius.dart';
import '../../../../../core/theme/open_vts_spacing.dart';
import '../../../../../core/theme/open_vts_typography.dart';
import '../../../models/admin_users_state.dart';

class AdminUsersFilterChips extends StatelessWidget {
  const AdminUsersFilterChips({
    required this.statusFilter,
    required this.verifiedFilter,
    required this.countryFilter,
    required this.countryCodes,
    required this.onStatusChanged,
    required this.onVerifiedChanged,
    required this.onCountryChanged,
    super.key,
  });

  final AdminUserStatusFilter statusFilter;
  final AdminUserVerifiedFilter verifiedFilter;
  final String? countryFilter;
  final List<String> countryCodes;
  final ValueChanged<AdminUserStatusFilter> onStatusChanged;
  final ValueChanged<AdminUserVerifiedFilter> onVerifiedChanged;
  final ValueChanged<String?> onCountryChanged;

  @override
  Widget build(BuildContext context) {
    final showCountryFilters = countryCodes.length > 1;

    return SizedBox(
      height: 34,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        children: [
          _AdminFilterChip(
            label: 'All',
            selected: statusFilter == AdminUserStatusFilter.all,
            onTap: () => onStatusChanged(AdminUserStatusFilter.all),
          ),
          const SizedBox(width: OpenVtsSpacing.xs),
          _AdminFilterChip(
            label: 'Active',
            selected: statusFilter == AdminUserStatusFilter.active,
            onTap: () => onStatusChanged(AdminUserStatusFilter.active),
          ),
          const SizedBox(width: OpenVtsSpacing.xs),
          _AdminFilterChip(
            label: 'Inactive',
            selected: statusFilter == AdminUserStatusFilter.inactive,
            onTap: () => onStatusChanged(AdminUserStatusFilter.inactive),
          ),
          const SizedBox(width: OpenVtsSpacing.xs),
          _AdminFilterChip(
            label: 'All',
            selected: verifiedFilter == AdminUserVerifiedFilter.all,
            onTap: () => onVerifiedChanged(AdminUserVerifiedFilter.all),
          ),
          const SizedBox(width: OpenVtsSpacing.xs),
          _AdminFilterChip(
            label: 'Verified',
            selected: verifiedFilter == AdminUserVerifiedFilter.verified,
            onTap: () => onVerifiedChanged(AdminUserVerifiedFilter.verified),
          ),
          const SizedBox(width: OpenVtsSpacing.xs),
          _AdminFilterChip(
            label: 'Unverified',
            selected: verifiedFilter == AdminUserVerifiedFilter.unverified,
            onTap: () => onVerifiedChanged(AdminUserVerifiedFilter.unverified),
          ),
          if (showCountryFilters) ...[
            const SizedBox(width: OpenVtsSpacing.xs),
            _CountryFilterChip(
              countryFilter: countryFilter,
              countryCodes: countryCodes,
              onCountryChanged: onCountryChanged,
            ),
          ],
        ],
      ),
    );
  }
}

class _CountryFilterChip extends StatelessWidget {
  const _CountryFilterChip({
    required this.countryFilter,
    required this.countryCodes,
    required this.onCountryChanged,
  });

  final String? countryFilter;
  final List<String> countryCodes;
  final ValueChanged<String?> onCountryChanged;

  @override
  Widget build(BuildContext context) {
    final selected = countryFilter != null;
    final label = selected ? countryFilter! : 'All Countries';

    return PopupMenuButton<String>(
      tooltip: 'Country filter',
      onSelected: (value) => onCountryChanged(value.isEmpty ? null : value),
      itemBuilder: (context) {
        return [
          _menuItem('', 'All Countries', countryFilter == null),
          for (final countryCode in countryCodes)
            _menuItem(countryCode, countryCode, countryFilter == countryCode),
        ];
      },
      child: Material(
        color: selected ? OpenVtsColors.brandInk : OpenVtsColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(OpenVtsRadius.pill),
          side: BorderSide(
            color: selected ? OpenVtsColors.brandInk : OpenVtsColors.border,
          ),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 32),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: OpenVtsSpacing.sm,
              vertical: OpenVtsSpacing.xs,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.public_rounded,
                  size: 14,
                  color: selected
                      ? OpenVtsColors.white
                      : OpenVtsColors.textPrimary,
                ),
                const SizedBox(width: OpenVtsSpacing.xxs),
                Text(
                  label,
                  style: OpenVtsTypography.meta.copyWith(
                    color: selected
                        ? OpenVtsColors.white
                        : OpenVtsColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: OpenVtsSpacing.xxs),
                Icon(
                  Icons.expand_more_rounded,
                  size: 16,
                  color: selected
                      ? OpenVtsColors.white
                      : OpenVtsColors.textPrimary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  PopupMenuItem<String> _menuItem(
    String value,
    String label,
    bool selected,
  ) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(
            selected ? Icons.check_rounded : Icons.public_rounded,
            size: 18,
            color: OpenVtsColors.textSecondary,
          ),
          const SizedBox(width: OpenVtsSpacing.xs),
          Text(label, style: OpenVtsTypography.label),
        ],
      ),
    );
  }
}

class _AdminFilterChip extends StatelessWidget {
  const _AdminFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? OpenVtsColors.brandInk : OpenVtsColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(OpenVtsRadius.pill),
        side: BorderSide(
          color: selected ? OpenVtsColors.brandInk : OpenVtsColors.border,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(OpenVtsRadius.pill),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 32),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: OpenVtsSpacing.sm,
              vertical: OpenVtsSpacing.xs,
            ),
            child: Text(
              label,
              style: OpenVtsTypography.meta.copyWith(
                color:
                    selected ? OpenVtsColors.white : OpenVtsColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
