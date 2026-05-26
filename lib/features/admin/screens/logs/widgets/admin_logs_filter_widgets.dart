import 'package:flutter/material.dart';

import '../../../../../core/theme/open_vts_colors.dart';
import '../../../../../core/theme/open_vts_radius.dart';
import '../../../../../core/theme/open_vts_typography.dart';

class AdminFilterChip extends StatelessWidget {
  const AdminFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(OpenVtsRadius.md),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? OpenVtsColors.brandInk : OpenVtsColors.white,
          borderRadius: BorderRadius.circular(OpenVtsRadius.md),
          border: Border.all(
              color: selected ? OpenVtsColors.brandInk : OpenVtsColors.border),
        ),
        child: Text(
          label,
          style: OpenVtsTypography.meta.copyWith(
            color: selected ? OpenVtsColors.white : OpenVtsColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
