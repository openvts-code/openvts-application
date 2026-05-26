import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../core/theme/open_vts_spacing.dart';
import '../../../../../shared/widgets/open_vts_card.dart';
import '../../../../../shared/widgets/open_vts_empty_state.dart';
import '../../../../../shared/widgets/open_vts_metric_card.dart';
import '../../../models/admin_payments_model.dart';
import 'admin_payments_mode_breakdown.dart';
import 'admin_payments_revenue_trend_chart.dart';
import 'admin_payments_status_distribution.dart';

class AdminPaymentsAnalyticsSection extends StatelessWidget {
  const AdminPaymentsAnalyticsSection({
    required this.analytics,
    required this.isLoading,
    required this.errorMessage,
    super.key,
  });

  final AdminPaymentsAnalytics? analytics;
  final bool isLoading;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    if (isLoading && analytics == null) {
      return const OpenVtsCard(
          child: SizedBox(
              height: 120, child: Center(child: CircularProgressIndicator())));
    }

    if (errorMessage != null && analytics == null) {
      return OpenVtsCard(child: Text(errorMessage!));
    }

    final model = analytics;
    if (model == null) {
      return const OpenVtsCard(
        child: OpenVtsEmptyState(
          title: 'No analytics data',
          message: 'Analytics will appear once payments are available.',
        ),
      );
    }

    final primary = model.totalsByCurrency.isNotEmpty
        ? model.totalsByCurrency.first
        : const AdminCurrencyTotal(
            currency: 'USD', totalAmount: '0', countSuccess: 0);
    final revenue = primary.totalAmountValue;
    final success = model.statusBreakdown[AdminPaymentStatus.success] ?? 0;
    final pending = model.statusBreakdown[AdminPaymentStatus.pending] ?? 0;
    final failed = model.statusBreakdown[AdminPaymentStatus.failed] ?? 0;
    final total = model.totalTransactions;
    final successRate = total <= 0 ? 0 : (success / total) * 100;

    final metrics = [
      (
        'Revenue Total',
        '${primary.currency} ${NumberFormat('#,##0.##').format(revenue)}'
      ),
      ('Successful Payments', success.toString()),
      ('Pending Payments', pending.toString()),
      ('Failed Payments', failed.toString()),
      ('Success Rate', '${successRate.toStringAsFixed(1)}%'),
      ('Total Transactions', total.toString()),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final cols = constraints.maxWidth >= 760 ? 3 : 2;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: metrics.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: cols,
                crossAxisSpacing: OpenVtsSpacing.sm,
                mainAxisSpacing: OpenVtsSpacing.sm,
                childAspectRatio: 1.42,
              ),
              itemBuilder: (context, index) {
                final item = metrics[index];
                return OpenVtsMetricCard(label: item.$1, value: item.$2);
              },
            );
          },
        ),
        const SizedBox(height: OpenVtsSpacing.sm),
        AdminPaymentsRevenueTrendChart(analytics: model),
        const SizedBox(height: OpenVtsSpacing.sm),
        AdminPaymentsModeBreakdown(items: model.modeBreakdown),
        const SizedBox(height: OpenVtsSpacing.sm),
        AdminPaymentsStatusDistribution(
            success: success, pending: pending, failed: failed),
      ],
    );
  }
}
