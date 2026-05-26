import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../core/theme/open_vts_colors.dart';
import '../../../../../core/theme/open_vts_radius.dart';
import '../../../../../core/theme/open_vts_spacing.dart';
import '../../../../../core/theme/open_vts_typography.dart';
import '../../../../../shared/widgets/open_vts_card.dart';
import '../../../../../shared/widgets/open_vts_empty_state.dart';
import '../../../models/admin_payments_model.dart';

class AdminPaymentsModeBreakdown extends StatelessWidget {
  const AdminPaymentsModeBreakdown({required this.items, super.key});

  final List<AdminModeBreakdown> items;

  @override
  Widget build(BuildContext context) {
    final ranked = [...items]..sort((a, b) => b.count.compareTo(a.count));
    final total = ranked.fold<int>(0, (p, c) => p + c.count);
    final max = ranked.fold<int>(0, (p, c) => math.max(p, c.count));

    return OpenVtsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Payment Mode Breakdown',
              style: OpenVtsTypography.titleSmall),
          const SizedBox(height: OpenVtsSpacing.xxs),
          Text('Ranked by transaction count',
              style: OpenVtsTypography.meta
                  .copyWith(color: OpenVtsColors.textSecondary)),
          const SizedBox(height: OpenVtsSpacing.sm),
          if (ranked.isEmpty)
            const OpenVtsEmptyState(
              title: 'No mode data',
              message:
                  'Payment mode breakdown is not available for this range.',
            )
          else
            Column(
              children: ranked.map((e) {
                final ratio = max == 0 ? 0.0 : e.count / max;
                final pct = total == 0 ? 0 : ((e.count / total) * 100).round();
                return Padding(
                  padding: const EdgeInsets.only(bottom: OpenVtsSpacing.xs),
                  child: Row(
                    children: [
                      SizedBox(
                          width: 118,
                          child: Text(e.mode.label,
                              style: OpenVtsTypography.body)),
                      Expanded(
                        child: ClipRRect(
                          borderRadius:
                              BorderRadius.circular(OpenVtsRadius.pill),
                          child: SizedBox(
                            height: 10,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                const DecoratedBox(
                                    decoration: BoxDecoration(
                                        color: OpenVtsColors.surface)),
                                FractionallySizedBox(
                                  alignment: Alignment.centerLeft,
                                  widthFactor: ratio,
                                  child: const DecoratedBox(
                                    decoration: BoxDecoration(
                                        color: OpenVtsColors.textSecondary),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: OpenVtsSpacing.xs),
                      SizedBox(
                        width: 52,
                        child: Text(
                          '${NumberFormat.compact().format(e.count)} ($pct%)',
                          textAlign: TextAlign.right,
                          style: OpenVtsTypography.meta
                              .copyWith(color: OpenVtsColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(growable: false),
            ),
        ],
      ),
    );
  }
}
