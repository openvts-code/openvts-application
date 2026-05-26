import 'package:flutter/material.dart';

import '../../core/theme/open_vts_colors.dart';
import '../../core/theme/open_vts_spacing.dart';
import '../../core/theme/open_vts_typography.dart';

class OpenVtsEmptyState extends StatelessWidget {
  const OpenVtsEmptyState({
    required this.title,
    required this.message,
    super.key,
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(OpenVtsSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: OpenVtsTypography.titleSmall, textAlign: TextAlign.center),
            const SizedBox(height: OpenVtsSpacing.xs),
            Text(
              message,
              style: OpenVtsTypography.body.copyWith(color: OpenVtsColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
