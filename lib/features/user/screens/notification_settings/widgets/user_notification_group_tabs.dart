import 'package:flutter/material.dart';

import '../../../../../core/theme/open_vts_colors.dart';
import '../../../../../core/theme/open_vts_radius.dart';
import '../../../../../core/theme/open_vts_spacing.dart';
import '../../../../../core/theme/open_vts_typography.dart';
import '../../../../../shared/widgets/open_vts_card.dart';
import '../../../models/user_notification_settings_model.dart';

class UserNotificationGroupTabs extends StatelessWidget {
  const UserNotificationGroupTabs({
    required this.selectedGroup,
    required this.onChanged,
    super.key,
  });

  final UserNotificationGroup selectedGroup;
  final ValueChanged<UserNotificationGroup> onChanged;

  @override
  Widget build(BuildContext context) {
    final tabs = <_GroupTabItem>[
      const _GroupTabItem(
        group: UserNotificationGroup.basic,
        label: 'Basic',
        icon: Icons.bolt_rounded,
      ),
      const _GroupTabItem(
        group: UserNotificationGroup.overspeed,
        label: 'Overspeed',
        icon: Icons.speed_rounded,
      ),
      const _GroupTabItem(
        group: UserNotificationGroup.geofence,
        label: 'Geofence',
        icon: Icons.location_on_outlined,
      ),
    ];

    return OpenVtsCard(
      padding: const EdgeInsets.all(OpenVtsSpacing.xs),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final chips = tabs
              .map(
                (item) => _GroupChoiceChip(
                  item: item,
                  selected: selectedGroup == item.group,
                  onTap: () => onChanged(item.group),
                ),
              )
              .toList(growable: false);

          if (constraints.maxWidth < 360) {
            return Wrap(
              spacing: OpenVtsSpacing.xs,
              runSpacing: OpenVtsSpacing.xs,
              children: chips,
            );
          }

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: chips
                  .map(
                    (chip) => Padding(
                      padding: const EdgeInsets.only(right: OpenVtsSpacing.xs),
                      child: chip,
                    ),
                  )
                  .toList(growable: false),
            ),
          );
        },
      ),
    );
  }
}

class _GroupChoiceChip extends StatelessWidget {
  const _GroupChoiceChip({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final _GroupTabItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 44),
      child: ChoiceChip(
        selected: selected,
        showCheckmark: false,
        avatar: Icon(
          item.icon,
          size: 15,
          color:
              selected ? OpenVtsColors.brandInk : OpenVtsColors.textSecondary,
        ),
        label: Text(item.label),
        onSelected: (_) => onTap(),
        materialTapTargetSize: MaterialTapTargetSize.padded,
        selectedColor: OpenVtsColors.brandInk.withValues(alpha: 0.10),
        backgroundColor: OpenVtsColors.surfaceElevated,
        side: BorderSide(
          color: selected ? OpenVtsColors.brandInk : OpenVtsColors.border,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(OpenVtsRadius.pill),
        ),
        labelStyle: OpenVtsTypography.meta.copyWith(
          color:
              selected ? OpenVtsColors.brandInk : OpenVtsColors.textSecondary,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
        ),
      ),
    );
  }
}

class _GroupTabItem {
  const _GroupTabItem({
    required this.group,
    required this.label,
    required this.icon,
  });

  final UserNotificationGroup group;
  final String label;
  final IconData icon;
}
