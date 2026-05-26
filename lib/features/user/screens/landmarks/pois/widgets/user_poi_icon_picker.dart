import 'package:flutter/material.dart';

import '../../../../../../core/theme/open_vts_colors.dart';
import '../../../../../../core/theme/open_vts_radius.dart';
import '../../../../../../core/theme/open_vts_typography.dart';
import '../user_poi_constants.dart';

/// Compact slug-based icon picker. Emits the icon slug (string) so the
/// caller can persist it as-is on the backend.
class UserPoiIconPicker extends StatelessWidget {
  const UserPoiIconPicker({
    super.key,
    required this.value,
    required this.onChanged,
    this.label = 'Icon',
  });

  final String value;
  final ValueChanged<String> onChanged;
  final String label;

  @override
  Widget build(BuildContext context) {
    final normalised = value.trim().toLowerCase();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: OpenVtsTypography.label.copyWith(
            color: OpenVtsColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final option in kUserPoiIcons)
              _IconChip(
                icon: option.icon,
                selected: option.slug == normalised,
                onTap: () => onChanged(option.slug),
                tooltip: option.slug,
              ),
          ],
        ),
      ],
    );
  }
}

class _IconChip extends StatelessWidget {
  const _IconChip({
    required this.icon,
    required this.selected,
    required this.onTap,
    required this.tooltip,
  });

  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(OpenVtsRadius.sm),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: selected ? OpenVtsColors.brandInk : OpenVtsColors.surface,
            borderRadius: BorderRadius.circular(OpenVtsRadius.sm),
            border: Border.all(
              color: selected ? OpenVtsColors.brandInk : OpenVtsColors.border,
            ),
          ),
          alignment: Alignment.center,
          child: Icon(
            icon,
            size: 16,
            color: selected ? OpenVtsColors.white : OpenVtsColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

/// Slim trailing-icon row used by the picker preview.
class UserPoiIconBadge extends StatelessWidget {
  const UserPoiIconBadge({
    super.key,
    required this.slug,
    required this.color,
    this.size = 14,
    this.padding = 6,
  });

  final String slug;
  final Color color;
  final double size;
  final double padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(OpenVtsRadius.sm),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Icon(iconForUserPoiSlug(slug), size: size, color: color),
    );
  }
}
