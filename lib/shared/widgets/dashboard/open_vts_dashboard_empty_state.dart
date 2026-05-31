import 'package:flutter/material.dart';

import '../../../core/theme/open_vts_colors.dart';
import '../../../core/theme/open_vts_radius.dart';
import '../../../core/theme/open_vts_spacing.dart';
import '../../../core/theme/open_vts_typography.dart';

/// Compact empty state for dashboard sections.
///
/// Displays icon, title, and message in a centered layout.
class OpenVtsDashboardEmptyState extends StatelessWidget {
  const OpenVtsDashboardEmptyState({
    required this.icon,
    required this.title,
    required this.message,
    super.key,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(OpenVtsSpacing.md),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: OpenVtsColors.surface,
                borderRadius: BorderRadius.circular(OpenVtsRadius.md),
                border: Border.all(color: OpenVtsColors.border),
              ),
              child: Icon(
                icon,
                size: 18,
                color: OpenVtsColors.textTertiary,
              ),
            ),
            const SizedBox(height: OpenVtsSpacing.xs),
            Text(
              title,
              textAlign: TextAlign.center,
              style: OpenVtsTypography.label.copyWith(
                color: OpenVtsColors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              message,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: OpenVtsTypography.meta.copyWith(
                color: OpenVtsColors.textSecondary,
                fontSize: 10.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
