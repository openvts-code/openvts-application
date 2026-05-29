import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/open_vts_colors.dart';
import '../../../../core/theme/open_vts_radius.dart';
import '../../../../core/theme/open_vts_spacing.dart';
import '../../../../core/theme/open_vts_typography.dart';
import '../../../../shared/widgets/open_vts_button.dart';
import '../../../../shared/widgets/open_vts_card.dart';
import '../../../../shared/widgets/open_vts_empty_state.dart';
import '../../../../shared/widgets/open_vts_error_view.dart';
import '../../../../shared/widgets/open_vts_loader.dart';
import '../../../../shared/widgets/open_vts_page_scaffold.dart';
import '../../controllers/superadmin_payments_controller.dart';
import '../../controllers/superadmin_providers.dart';
import '../../models/superadmin_payments_model.dart';
import '../../models/superadmin_payments_state.dart';
import 'widgets/payments_analytics_section.dart';
import 'widgets/record_payment_sheet.dart';
import 'widgets/superadmin_payments_filters_card.dart';
import 'widgets/superadmin_transaction_card.dart';
import 'widgets/transaction_details_sheet.dart';

class SuperadminPaymentsScreen extends ConsumerStatefulWidget {
  const SuperadminPaymentsScreen({super.key});

  @override
  ConsumerState<SuperadminPaymentsScreen> createState() =>
      _SuperadminPaymentsScreenState();
}

class _SuperadminPaymentsScreenState
    extends ConsumerState<SuperadminPaymentsScreen> {
  bool _hasLoadedInitial = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _hasLoadedInitial) {
        return;
      }

      _hasLoadedInitial = true;

      // Invalidate any surviving autoDispose provider state from a prior
      // session so we always fetch fresh data when the screen mounts.
      ref.invalidate(superadminPaymentsControllerProvider);

      unawaited(
        ref.read(superadminPaymentsControllerProvider.notifier).loadInitial(),
      );
    });
  }

  Future<void> _openTransactionDetails(
      SuperadminTransaction transaction) async {
    if (!mounted) {
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TransactionDetailsSheet(transaction: transaction),
    );
  }

  Future<void> _openRecordPaymentSheet() async {
    final controller = ref.read(superadminPaymentsControllerProvider.notifier);
    final state = ref.read(superadminPaymentsControllerProvider);

    if (state.admins.isEmpty && !state.isLoadingAdmins) {
      await controller.loadAdmins();
    }

    if (!mounted) {
      return;
    }

    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const RecordPaymentSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(superadminPaymentsControllerProvider);
    final controller = ref.read(superadminPaymentsControllerProvider.notifier);

    return OpenVtsPageScaffold(
      title: 'Payments',
      headerMode: OpenVtsPageHeaderMode.closeable,
      padding: EdgeInsets.zero,
      body: RefreshIndicator(
        color: Theme.of(context).colorScheme.primary,
        onRefresh: controller.refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: const EdgeInsets.fromLTRB(
            OpenVtsSpacing.sm,
            OpenVtsSpacing.sm,
            OpenVtsSpacing.sm,
            OpenVtsSpacing.lg,
          ),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 920),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _PaymentsHeaderCard(
                        onRecordPressed: _openRecordPaymentSheet),
                    const SizedBox(height: OpenVtsSpacing.sm),
                    SuperadminPaymentsFiltersCard(
                      state: state,
                      onAdminChanged: (value) {
                        unawaited(controller.setAdminFilter(value));
                      },
                      onRangePresetChanged: (preset) {
                        unawaited(controller.setRangePreset(preset));
                      },
                      onCustomRangeChanged: (from, to) {
                        unawaited(controller.setCustomRange(from, to));
                      },
                      onSearchChanged: controller.setSearchQuery,
                      onStatusChanged: (status) {
                        unawaited(controller.setStatusFilter(status));
                      },
                      onClearFilters: () {
                        unawaited(controller.clearFilters());
                      },
                    ),
                    if (state.errorMessage != null) ...[
                      const SizedBox(height: OpenVtsSpacing.sm),
                      _InlineErrorBanner(message: state.errorMessage!),
                    ],
                    if (state.analyticsErrorMessage != null) ...[
                      const SizedBox(height: OpenVtsSpacing.sm),
                      _InlineErrorBanner(message: state.analyticsErrorMessage!),
                    ],
                    const SizedBox(height: OpenVtsSpacing.sm),
                    PaymentsAnalyticsSection(
                      analytics: state.analytics,
                      isLoading: state.isLoadingAnalytics,
                      errorMessage: state.analyticsErrorMessage,
                    ),
                    const SizedBox(height: OpenVtsSpacing.sm),
                    _TransactionsHeader(state: state),
                    const SizedBox(height: OpenVtsSpacing.xs),
                    _buildTransactionsSection(state, controller),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionsSection(
    SuperadminPaymentsState state,
    SuperadminPaymentsController controller,
  ) {
    if (state.isLoadingTransactions && !state.hasTransactions) {
      return const SizedBox(
        height: 190,
        child: OpenVtsLoader(),
      );
    }

    if (!state.hasTransactions && state.errorMessage != null) {
      return OpenVtsErrorView(
        message: state.errorMessage ?? 'Unable to load transactions.',
        onRetry: controller.loadTransactions,
      );
    }

    if (!state.hasTransactions) {
      final hasFilters = state.hasActiveFilters;
      return OpenVtsCard(
        child: OpenVtsEmptyState(
          title: hasFilters
              ? 'No transactions match your filters'
              : 'No transactions found',
          message: hasFilters
              ? state.selectedAdminId != null
                  ? 'No payments found for this admin. Try clearing filters.'
                  : 'Try adjusting your filters or date range.'
              : 'Record a manual payment to get started.',
        ),
      );
    }

    return Column(
      children: [
        ...state.transactions.map(
          (transaction) => Padding(
            padding: const EdgeInsets.only(bottom: OpenVtsSpacing.xs),
            child: SuperadminTransactionCard(
              transaction: transaction,
              onTap: () => _openTransactionDetails(transaction),
            ),
          ),
        ),
        if (state.hasMoreTransactions)
          Padding(
            padding: const EdgeInsets.only(top: OpenVtsSpacing.sm),
            child: OpenVtsButton(
              label: 'Load More',
              variant: OpenVtsButtonVariant.secondary,
              isLoading: state.isLoadingTransactions,
              onPressed: state.isLoadingTransactions
                  ? null
                  : () {
                      unawaited(controller.loadMore());
                    },
            ),
          ),
      ],
    );
  }
}

class _PaymentsHeaderCard extends StatelessWidget {
  const _PaymentsHeaderCard({required this.onRecordPressed});

  final Future<void> Function() onRecordPressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Transactions and revenue',
            style: OpenVtsTypography.meta.copyWith(
              color: OpenVtsColors.textTertiary,
            ),
          ),
        ),
        const SizedBox(width: OpenVtsSpacing.xs),
        OpenVtsButton(
          label: 'Record Payment',
          trailingIcon: Icons.add_rounded,
          onPressed: onRecordPressed,
        ),
      ],
    );
  }
}

class _TransactionsHeader extends StatelessWidget {
  const _TransactionsHeader({required this.state});

  final SuperadminPaymentsState state;

  @override
  Widget build(BuildContext context) {
    final loaded = state.transactions.length;
    final total = state.total;

    return Row(
      children: [
        Expanded(
          child: Text(
            'Transactions',
            style: OpenVtsTypography.titleSmall.copyWith(
              color: OpenVtsColors.textPrimary,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: OpenVtsSpacing.sm,
            vertical: OpenVtsSpacing.xxs,
          ),
          decoration: BoxDecoration(
            color: OpenVtsColors.surface,
            borderRadius: BorderRadius.circular(OpenVtsRadius.pill),
            border: Border.all(color: OpenVtsColors.border),
          ),
          child: Text(
            total > 0 ? '$loaded / $total' : '$loaded',
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

class _InlineErrorBanner extends StatelessWidget {
  const _InlineErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(OpenVtsSpacing.sm),
      decoration: BoxDecoration(
        color: OpenVtsColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(OpenVtsRadius.md),
        border: Border.all(
          color: OpenVtsColors.error.withValues(alpha: 0.28),
        ),
      ),
      child: Text(
        message,
        style: OpenVtsTypography.body.copyWith(
          color: OpenVtsColors.error,
        ),
      ),
    );
  }
}
