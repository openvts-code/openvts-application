import 'package:flutter/material.dart';

import '../../core/theme/open_vts_colors.dart';
import '../../core/theme/open_vts_radius.dart';
import '../../core/theme/open_vts_spacing.dart';
import '../../core/theme/open_vts_typography.dart';

class OpenVtsListTile extends StatelessWidget {
  const OpenVtsListTile({
    required this.title,
    super.key,
    this.subtitle,
    this.leadingIcon,
    this.trailing,
    this.onTap,
  });

  final String title;
  final String? subtitle;
  final IconData? leadingIcon;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(OpenVtsRadius.md),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: OpenVtsSpacing.md,
          vertical: OpenVtsSpacing.sm,
        ),
        child: Row(
          children: [
            if (leadingIcon != null) ...[
              Container(
                padding: const EdgeInsets.all(OpenVtsSpacing.sm),
                decoration: BoxDecoration(
                  color: OpenVtsColors.background,
                  borderRadius: BorderRadius.circular(OpenVtsRadius.sm),
                ),
                child: Icon(
                  leadingIcon,
                  size: 20,
                  color: OpenVtsColors.textSecondary,
                ),
              ),
              const SizedBox(width: OpenVtsSpacing.md),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: OpenVtsTypography.body.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: OpenVtsTypography.meta.copyWith(
                        color: OpenVtsColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: OpenVtsSpacing.md),
              trailing!,
            ] else if (onTap != null) ...[
              const SizedBox(width: OpenVtsSpacing.md),
              const Icon(
                Icons.chevron_right,
                size: 20,
                color: OpenVtsColors.textTertiary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
