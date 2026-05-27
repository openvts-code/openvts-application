import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../core/theme/open_vts_colors.dart';
import '../../../../../core/theme/open_vts_spacing.dart';
import '../../../../../shared/widgets/open_vts_card.dart';
import '../../../../../shared/widgets/open_vts_empty_state.dart';
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
        _KpiStrip(summary: summary),
        const SizedBox(height: OpenVtsSpacing.sm),
        _RevenueSummaryCard(summary: summary),
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

class _KpiStrip extends StatelessWidget {
  const _KpiStrip({required this.summary});

  final _AnalyticsSummary summary;

  @override
  Widget build(BuildContext context) {
    final compact = NumberFormat.compact(locale: 'en_US');

    return Row(
      children: [
        Expanded(
          child: _CompactKpiCard(
            icon: Icons.check_circle_rounded,
            iconColor: OpenVtsColors.success,
            label: 'Successful',
            value: compact.format(summary.success),
          ),
        ),
        const SizedBox(width: OpenVtsSpacing.sm),
        Expanded(
          child: _CompactKpiCard(
            icon: Icons.pending_rounded,
            iconColor: OpenVtsColors.warning,
            label: 'Pending',
            value: compact.format(summary.pending),
          ),
        ),
        const SizedBox(width: OpenVtsSpacing.sm),
        Expanded(
          child: _CompactKpiCard(
            icon: Icons.cancel_rounded,
            iconColor: OpenVtsColors.error,
            label: 'Failed',
            value: compact.format(summary.failed),
          ),
        ),
      ],
    );
  }
}

class _CompactKpiCard extends StatelessWidget {
  const _CompactKpiCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return OpenVtsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 18,
            color: iconColor,
          ),
          const SizedBox(height: OpenVtsSpacing.xs),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: OpenVtsColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: OpenVtsColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

class _RevenueSummaryCard extends StatelessWidget {
  const _RevenueSummaryCard({required this.summary});

  final _AnalyticsSummary summary;

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat('#,##0.##', 'en_US');

    return OpenVtsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                Icons.payments_rounded,
                size: 18,
                color: OpenVtsColors.success.withValues(alpha: 0.9),
              ),
              const SizedBox(width: OpenVtsSpacing.xs),
              const Text(
                'Total Revenue',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: OpenVtsColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: OpenVtsSpacing.xs),
          Text(
            '${summary.currency} ${currencyFormat.format(summary.revenue)}',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: OpenVtsColors.textPrimary,
            ),
          ),
          if (summary.success > 0) ...[
            const SizedBox(height: 4),
            Text(
              'Avg ${summary.currency} ${currencyFormat.format(summary.avgValue)} per transaction',
              style: const TextStyle(
                fontSize: 11,
                color: OpenVtsColors.textTertiary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AnalyticsLoadingSkeleton extends StatelessWidget {
  const _AnalyticsLoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: _SkeletonMetricCard()),
            SizedBox(width: OpenVtsSpacing.sm),
            Expanded(child: _SkeletonMetricCard()),
            SizedBox(width: OpenVtsSpacing.sm),
            Expanded(child: _SkeletonMetricCard()),
          ],
        ),
        SizedBox(height: OpenVtsSpacing.sm),
        _SkeletonSectionCard(height: 110),
        SizedBox(height: OpenVtsSpacing.sm),
        _SkeletonSectionCard(height: 180),
        SizedBox(height: OpenVtsSpacing.sm),
        _SkeletonSectionCard(height: 150),
        SizedBox(height: OpenVtsSpacing.sm),
        _SkeletonSectionCard(height: 126),
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
