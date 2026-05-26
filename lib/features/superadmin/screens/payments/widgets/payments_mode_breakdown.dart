import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../core/theme/open_vts_colors.dart';
import '../../../../../core/theme/open_vts_radius.dart';
import '../../../../../core/theme/open_vts_spacing.dart';
import '../../../../../core/theme/open_vts_typography.dart';
import '../../../../../shared/widgets/open_vts_card.dart';
import '../../../../../shared/widgets/open_vts_empty_state.dart';
import '../../../models/superadmin_payments_model.dart';

class PaymentsModeBreakdown extends StatelessWidget {
  const PaymentsModeBreakdown({
    required this.items,
    super.key,
  });

  final List<SuperadminModeBreakdown> items;

  @override
  Widget build(BuildContext context) {
    final ranked = [...items]
      ..sort((left, right) => right.count.compareTo(left.count));
    final maxCount =
        ranked.fold<int>(0, (value, item) => math.max(value, item.count));

    return OpenVtsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payment Mode Breakdown',
            style: OpenVtsTypography.titleSmall.copyWith(
              color: OpenVtsColors.textPrimary,
            ),
          ),
          const SizedBox(height: OpenVtsSpacing.xxs),
          Text(
            'Ranked by transaction count',
            style: OpenVtsTypography.meta.copyWith(
              color: OpenVtsColors.textSecondary,
            ),
          ),
          const SizedBox(height: OpenVtsSpacing.sm),
          if (ranked.isEmpty)
            const OpenVtsEmptyState(
              title: 'No mode data',
              message:
                  'Payment mode breakdown is not available for this range.',
            )
          else
            Column(
              children: ranked
                  .map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: OpenVtsSpacing.xs),
                      child: _ModeRow(
                        label: item.mode.label,
                        count: item.count,
                        maxCount: maxCount,
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
        ],
      ),
    );
  }
}

class _ModeRow extends StatelessWidget {
  const _ModeRow({
    required this.label,
    required this.count,
    required this.maxCount,
  });

  final String label;
  final int count;
  final int maxCount;

  @override
  Widget build(BuildContext context) {
    final ratio = maxCount <= 0 ? 0.0 : count / maxCount;

    return Row(
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: OpenVtsTypography.body.copyWith(
              color: OpenVtsColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(width: OpenVtsSpacing.xs),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(OpenVtsRadius.pill),
            child: SizedBox(
              height: 10,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  const DecoratedBox(
                    decoration: BoxDecoration(color: OpenVtsColors.surface),
                  ),
                  FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: ratio.clamp(0, 1).toDouble(),
                    child: const DecoratedBox(
                      decoration:
                          BoxDecoration(color: OpenVtsColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: OpenVtsSpacing.xs),
        SizedBox(
          width: 38,
          child: Text(
            NumberFormat.compact().format(count),
            textAlign: TextAlign.right,
            style: OpenVtsTypography.meta.copyWith(
              color: OpenVtsColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
