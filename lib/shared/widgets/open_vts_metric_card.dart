import 'package:flutter/material.dart';

import '../../core/theme/open_vts_colors.dart';
import '../../core/theme/open_vts_spacing.dart';
import '../../core/theme/open_vts_typography.dart';
import 'open_vts_card.dart';

class OpenVtsMetricCard extends StatelessWidget {
  const OpenVtsMetricCard({
    required this.label,
    required this.value,
    this.caption,
    super.key,
  });

  final String label;
  final String value;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    return OpenVtsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: OpenVtsTypography.meta.copyWith(color: OpenVtsColors.textSecondary)),
          const SizedBox(height: OpenVtsSpacing.xs),
          Text(value, style: OpenVtsTypography.titleMedium),
          if (caption != null) ...[
            const SizedBox(height: OpenVtsSpacing.xxs),
            Text(caption!, style: OpenVtsTypography.meta.copyWith(color: OpenVtsColors.textTertiary)),
          ],
        ],
      ),
    );
  }
}
