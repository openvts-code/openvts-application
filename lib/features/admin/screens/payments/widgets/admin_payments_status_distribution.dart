import 'package:flutter/material.dart';

import '../../../../../core/theme/open_vts_colors.dart';
import '../../../../../core/theme/open_vts_spacing.dart';
import '../../../../../core/theme/open_vts_typography.dart';
import '../../../../../shared/widgets/open_vts_card.dart';

class AdminPaymentsStatusDistribution extends StatelessWidget {
  const AdminPaymentsStatusDistribution({
    required this.success,
    required this.pending,
    required this.failed,
    super.key,
  });

  final int success;
  final int pending;
  final int failed;

  @override
  Widget build(BuildContext context) {
    return OpenVtsCard(
      child: Row(
        children: [
          _item('Success', success, OpenVtsColors.success),
          const SizedBox(width: OpenVtsSpacing.sm),
          _item('Pending', pending, OpenVtsColors.warning),
          const SizedBox(width: OpenVtsSpacing.sm),
          _item('Failed', failed, OpenVtsColors.error),
        ],
      ),
    );
  }

  Widget _item(String label, int value, Color color) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: OpenVtsTypography.meta
                  .copyWith(color: OpenVtsColors.textSecondary)),
          const SizedBox(height: OpenVtsSpacing.xxs),
          Text(value.toString(),
              style: OpenVtsTypography.titleSmall.copyWith(color: color)),
        ],
      ),
    );
  }
}
