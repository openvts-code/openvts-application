import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../core/theme/open_vts_colors.dart';
import '../../../../../core/theme/open_vts_spacing.dart';
import '../../../../../shared/widgets/open_vts_card.dart';
import '../../../../../shared/widgets/open_vts_empty_state.dart';
import '../../../../../shared/widgets/open_vts_metric_card.dart';
import '../../../models/superadmin_payments_model.dart';
import 'payments_mode_breakdown.dart';
import 'payments_revenue_trend_chart.dart';
import 'payments_status_distribution.dart';

class PaymentsAnalyticsSection extends StatelessWidget {
  const PaymentsAnalyticsSection({
    required this.analytics,
    required this.isLoading,
    required this.errorMessage,
    super.key,
  });

  final SuperadminTransactionsAnalytics? analytics;
  final bool isLoading;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    if (isLoading && analytics == null) {
      return const _AnalyticsLoadingSkeleton();
    }

    if (errorMessage != null && analytics == null) {
      return OpenVtsCard(
        child: Text(
          errorMessage!,
          style: const TextStyle(color: OpenVtsColors.error),
        ),
      );
    }

    final model = analytics;
    if (model == null) {
      return const OpenVtsCard(
        child: OpenVtsEmptyState(
          title: 'No analytics data',
          message: 'Analytics will appear once transactions are available.',
        ),
      );
    }

    final summary = _buildSummary(model);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SummaryMetricsGrid(summary: summary),
        const SizedBox(height: OpenVtsSpacing.sm),
        PaymentsRevenueTrendChart(analytics: model),
        const SizedBox(height: OpenVtsSpacing.sm),
        PaymentsModeBreakdown(items: model.modeBreakdown),
        const SizedBox(height: OpenVtsSpacing.sm),
        PaymentsStatusDistribution(
          success: summary.success,
          pending: summary.pending,
          failed: summary.failed,
        ),
      ],
    );
  }

  _AnalyticsSummary _buildSummary(SuperadminTransactionsAnalytics model) {
    final primary = model.totalsByCurrency.isNotEmpty
        ? model.totalsByCurrency.first
        : const SuperadminCurrencyTotal(
            currency: 'USD',
            totalAmount: '0',
            countSuccess: 0,
          );

    final currency =
        primary.currency.trim().isEmpty ? 'USD' : primary.currency.trim();
    final revenue = primary.totalAmountAsDouble ?? 0;

    final success =
        model.statusBreakdown[SuperadminTransactionStatus.success] ?? 0;
    final pending =
        model.statusBreakdown[SuperadminTransactionStatus.pending] ?? 0;
    final failed =
        model.statusBreakdown[SuperadminTransactionStatus.failed] ?? 0;

    final totalTransactions =
        model.totalTransactions < 0 ? 0 : model.totalTransactions;
    final successRate =
        totalTransactions <= 0 ? 0.0 : (success / totalTransactions) * 100;
    final avgValue = success <= 0 ? 0.0 : revenue / success;

    return _AnalyticsSummary(
      currency: currency,
      revenue: revenue,
      success: success,
      pending: pending,
      failed: failed,
      totalTransactions: totalTransactions,
      successRate: successRate,
      avgValue: avgValue,
    );
  }
}

class _SummaryMetricsGrid extends StatelessWidget {
  const _SummaryMetricsGrid({required this.summary});

  final _AnalyticsSummary summary;

  @override
  Widget build(BuildContext context) {
    final compact = NumberFormat.compact(locale: 'en_US');
    final currencyFormat = NumberFormat('#,##0.##', 'en_US');

    final metrics = <_MetricData>[
      _MetricData(
        label: 'Revenue',
        value: '${summary.currency} ${currencyFormat.format(summary.revenue)}',
        caption: summary.success > 0
            ? 'Avg ${summary.currency} ${currencyFormat.format(summary.avgValue)}'
            : 'Avg ${summary.currency} 0',
      ),
      _MetricData(
        label: 'Successful',
        value: compact.format(summary.success),
      ),
      _MetricData(
        label: 'Pending',
        value: compact.format(summary.pending),
      ),
      _MetricData(
        label: 'Failed',
        value: compact.format(summary.failed),
      ),
      _MetricData(
        label: 'Success Rate',
        value: '${summary.successRate.toStringAsFixed(1)}%',
      ),
      _MetricData(
        label: 'Total Transactions',
        value: compact.format(summary.totalTransactions),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth >= 760 ? 3 : 2;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: metrics.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: OpenVtsSpacing.sm,
            mainAxisSpacing: OpenVtsSpacing.sm,
            childAspectRatio: 1.42,
          ),
          itemBuilder: (context, index) {
            final metric = metrics[index];
            return OpenVtsMetricCard(
              label: metric.label,
              value: metric.value,
              caption: metric.caption,
            );
          },
        );
      },
    );
  }
}

class _AnalyticsLoadingSkeleton extends StatelessWidget {
  const _AnalyticsLoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final crossAxisCount = constraints.maxWidth >= 760 ? 3 : 2;

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 6,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: OpenVtsSpacing.sm,
                mainAxisSpacing: OpenVtsSpacing.sm,
                childAspectRatio: 1.42,
              ),
              itemBuilder: (context, index) {
                return const _SkeletonMetricCard();
              },
            );
          },
        ),
        const SizedBox(height: OpenVtsSpacing.sm),
        const _SkeletonSectionCard(height: 180),
        const SizedBox(height: OpenVtsSpacing.sm),
        const _SkeletonSectionCard(height: 150),
        const SizedBox(height: OpenVtsSpacing.sm),
        const _SkeletonSectionCard(height: 126),
      ],
    );
  }
}

class _SkeletonMetricCard extends StatelessWidget {
  const _SkeletonMetricCard();

  @override
  Widget build(BuildContext context) {
    return const OpenVtsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SkeletonLine(width: 72, height: 10),
          SizedBox(height: OpenVtsSpacing.xs),
          _SkeletonLine(width: 94, height: 20),
          SizedBox(height: OpenVtsSpacing.xs),
          _SkeletonLine(width: 68, height: 10),
        ],
      ),
    );
  }
}

class _SkeletonSectionCard extends StatelessWidget {
  const _SkeletonSectionCard({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return OpenVtsCard(
      child: SizedBox(
        height: height,
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SkeletonLine(width: 132, height: 12),
            SizedBox(height: OpenVtsSpacing.xs),
            _SkeletonLine(width: 172, height: 10),
            SizedBox(height: OpenVtsSpacing.sm),
            Expanded(
              child: _SkeletonBlock(),
            ),
          ],
        ),
      ),
    );
  }
}

class _SkeletonLine extends StatelessWidget {
  const _SkeletonLine({
    required this.width,
    required this.height,
  });

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: OpenVtsColors.surface,
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }
}

class _SkeletonBlock extends StatelessWidget {
  const _SkeletonBlock();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: OpenVtsColors.surface,
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }
}

class _MetricData {
  const _MetricData({
    required this.label,
    required this.value,
    this.caption,
  });

  final String label;
  final String value;
  final String? caption;
}

class _AnalyticsSummary {
  const _AnalyticsSummary({
    required this.currency,
    required this.revenue,
    required this.success,
    required this.pending,
    required this.failed,
    required this.totalTransactions,
    required this.successRate,
    required this.avgValue,
  });

  final String currency;
  final double revenue;
  final int success;
  final int pending;
  final int failed;
  final int totalTransactions;
  final double successRate;
  final double avgValue;
}
