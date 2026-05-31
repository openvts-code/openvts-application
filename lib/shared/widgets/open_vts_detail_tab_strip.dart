import 'package:flutter/material.dart';

import '../../core/theme/open_vts_colors.dart';
import '../../core/theme/open_vts_radius.dart';
import '../../core/theme/open_vts_spacing.dart';
import '../../core/theme/open_vts_typography.dart';

class OpenVtsDetailTabOption<T> {
  const OpenVtsDetailTabOption({
    required this.value,
    required this.label,
    this.icon,
  });

  final T value;
  final String label;
  final IconData? icon;
}

class OpenVtsDetailTabStrip<T> extends StatelessWidget {
  const OpenVtsDetailTabStrip({
    required this.tabs,
    required this.selected,
    required this.onChanged,
    super.key,
  });

  final List<OpenVtsDetailTabOption<T>> tabs;
  final T selected;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 32,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: tabs.length,
        separatorBuilder: (context, index) =>
            const SizedBox(width: OpenVtsSpacing.xs),
        itemBuilder: (context, index) {
          final tab = tabs[index];
          return _TabChip(
            label: tab.label,
            icon: tab.icon,
            isSelected: tab.value == selected,
            onTap: () => onChanged(tab.value),
          );
        },
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  const _TabChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final IconData? icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final background =
        isSelected ? OpenVtsColors.brandInk : OpenVtsColors.white;
    final foreground =
        isSelected ? OpenVtsColors.white : OpenVtsColors.textPrimary;
    final borderColor =
        isSelected ? OpenVtsColors.brandInk : OpenVtsColors.border;

    return Material(
      color: background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(OpenVtsRadius.pill),
        side: BorderSide(color: borderColor),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(OpenVtsRadius.pill),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 14, color: foreground),
                const SizedBox(width: 5),
              ],
              Text(
                label,
                style: OpenVtsTypography.meta.copyWith(
                  color: foreground,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
