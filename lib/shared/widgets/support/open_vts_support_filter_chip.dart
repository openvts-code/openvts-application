import 'package:flutter/material.dart';
import 'package:open_vts/core/theme/open_vts_colors.dart';
import 'package:open_vts/core/theme/open_vts_spacing.dart';
import 'package:open_vts/core/theme/open_vts_radius.dart';
import 'package:open_vts/core/theme/open_vts_typography.dart';

class OpenVtsSupportFilterChip extends StatelessWidget {
  const OpenVtsSupportFilterChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text('$label $count'),
      selected: selected,
      onSelected: (_) => onSelected(),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      labelPadding: const EdgeInsets.symmetric(horizontal: OpenVtsSpacing.xs),
      selectedColor: OpenVtsColors.brandInk.withValues(alpha: 0.08),
      backgroundColor: Theme.of(context).colorScheme.surface,
      side: BorderSide(
        color: selected ? OpenVtsColors.brandInk : OpenVtsColors.border,
      ),
      labelStyle: OpenVtsTypography.meta.copyWith(
        color: selected ? OpenVtsColors.brandInk : OpenVtsColors.textSecondary,
        fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(OpenVtsRadius.pill),
      ),
    );
  }
}
