import 'package:flutter/material.dart';

import '../../../../../core/theme/open_vts_colors.dart';
import '../../../../../core/theme/open_vts_radius.dart';
import '../../../../../core/theme/open_vts_spacing.dart';
import '../../../../../core/theme/open_vts_typography.dart';
import '../../../../../shared/widgets/open_vts_card.dart';
import '../../../models/user_settings_model.dart';

class UserSettingsTabSelector extends StatelessWidget {
  const UserSettingsTabSelector({
    required this.selectedTab,
    required this.onChanged,
    super.key,
  });

  final UserSettingsTab selectedTab;
  final ValueChanged<UserSettingsTab> onChanged;

  @override
  Widget build(BuildContext context) {
    return OpenVtsCard(
      padding: const EdgeInsets.all(OpenVtsSpacing.xs),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _SettingsTabChip(
              label: 'Profile',
              icon: Icons.person_outline_rounded,
              selected: selectedTab == UserSettingsTab.profile,
              onTap: () => onChanged(UserSettingsTab.profile),
            ),
            const SizedBox(width: OpenVtsSpacing.xs),
            _SettingsTabChip(
              label: 'Localization',
              icon: Icons.public_rounded,
              selected: selectedTab == UserSettingsTab.localization,
              onTap: () => onChanged(UserSettingsTab.localization),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsTabChip extends StatelessWidget {
  const _SettingsTabChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final backgroundColor =
        selected ? OpenVtsColors.brandInk : OpenVtsColors.surfaceElevated;
    final foregroundColor =
        selected ? OpenVtsColors.white : OpenVtsColors.textPrimary;

    return SizedBox(
      height: 44,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(OpenVtsRadius.pill),
          child: Semantics(
            button: true,
            selected: selected,
            label: 'Switch to $label tab',
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: OpenVtsSpacing.sm,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(OpenVtsRadius.pill),
                border: Border.all(
                  color:
                      selected ? OpenVtsColors.brandInk : OpenVtsColors.border,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 14, color: foregroundColor),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: OpenVtsTypography.meta.copyWith(
                      color: foregroundColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
