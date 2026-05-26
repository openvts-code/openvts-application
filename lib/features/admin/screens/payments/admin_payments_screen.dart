import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/open_vts_colors.dart';
import '../../../../core/theme/open_vts_spacing.dart';
import '../../../../core/theme/open_vts_typography.dart';
import '../../../../shared/widgets/open_vts_bottom_sheet.dart';
import '../../../../shared/widgets/open_vts_card.dart';
import '../../../../shared/widgets/open_vts_empty_state.dart';
import '../../../../shared/widgets/open_vts_error_view.dart';
import '../../../../shared/widgets/open_vts_loader.dart';
import '../../../../shared/widgets/open_vts_page_scaffold.dart';
import '../../../../shared/widgets/open_vts_search_field.dart';
import '../../controllers/admin_providers.dart';
import '../../models/admin_payments_model.dart';
import 'widgets/admin_payment_transaction_card.dart';
import 'widgets/admin_payment_transaction_details_sheet.dart';
import 'widgets/admin_payments_analytics_section.dart';
import 'widgets/admin_payments_filters_card.dart';
import 'widgets/admin_renew_vehicle_sheet.dart';

class AdminPaymentsScreen extends ConsumerStatefulWidget {
  const AdminPaymentsScreen({super.key});

  @override
  ConsumerState<AdminPaymentsScreen> createState() =>
      _AdminPaymentsScreenState();
}

class _AdminPaymentsScreenState extends ConsumerState<AdminPaymentsScreen> {
  Timer? _searchDebounce;

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminPaymentsControllerProvider);
    final controller = ref.read(adminPaymentsControllerProvider.notifier);

    return OpenVtsPageScaffold(
      title: 'Payments',
      headerMode: OpenVtsPageHeaderMode.closeable,
      padding: EdgeInsets.zero,
      body: RefreshIndicator(
        onRefresh: controller.refresh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                OpenVtsSpacing.sm,
                OpenVtsSpacing.sm,
                OpenVtsSpacing.sm,
                0,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _header(state.transactions.length, state.total,
                      () => _showRenewSheet(context), controller.refresh),
                  const SizedBox(height: OpenVtsSpacing.sm),
                  OpenVtsSearchField(
                    hintText: 'Search reference, provider, counterparty...',
                    onChanged: (value) {
                      _searchDebounce?.cancel();
                      _searchDebounce =
                          Timer(const Duration(milliseconds: 300), () {
                        unawaited(controller.setSearchQuery(value));
                      });
                    },
                  ),
                  const SizedBox(height: OpenVtsSpacing.sm),
                  AdminPaymentsFiltersCard(
                    state: state,
                    onUserChanged: (v) => unawaited(controller.setUser(v)),
                    onStatusChanged: (v) => unawaited(controller.setStatus(v)),
                    onModeChanged: controller.setMode,
                    onRangePresetChanged: (v) =>
                        unawaited(controller.setRangePreset(v)),
                    onCustomRangeChanged: (f, t) =>
                        unawaited(controller.setCustomRange(f, t)),
                    onClear: () => unawaited(controller.clearFilters()),
                    onApply: () => unawaited(controller.load()),
                  ),
                  const SizedBox(height: OpenVtsSpacing.sm),
                  AdminPaymentsAnalyticsSection(
                    analytics: state.analytics,
                    isLoading: state.isLoadingAnalytics,
                    errorMessage: state.analyticsErrorMessage,
                  ),
                  const SizedBox(height: OpenVtsSpacing.sm),
                ]),
              ),
            ),
            _content(state),
            const SliverToBoxAdapter(
                child: SizedBox(height: OpenVtsSpacing.lg)),
          ],
        ),
      ),
    );
  }

  Widget _content(state) {
    final controller = ref.read(adminPaymentsControllerProvider.notifier);
    if (state.isLoading && !state.hasTransactions) {
      return const SliverFillRemaining(
          hasScrollBody: false, child: OpenVtsLoader());
    }

    if (state.errorMessage != null && !state.hasTransactions) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: OpenVtsErrorView(
            message: state.errorMessage!, onRetry: controller.load),
      );
    }

    if (!state.hasTransactions) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: OpenVtsEmptyState(
            title: 'No transactions found',
            message: 'Try changing search or filters.'),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: OpenVtsSpacing.sm),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final totalRows = state.transactions.length + (state.hasMore ? 1 : 0);
          if (index == totalRows - 1 && state.hasMore) {
            return Padding(
              padding: const EdgeInsets.only(top: OpenVtsSpacing.xs),
              child: OutlinedButton(
                onPressed: state.isLoadingMore
                    ? null
                    : () => unawaited(controller.loadMore()),
                child: state.isLoadingMore
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Load More'),
              ),
            );
          }

          final item = state.transactions[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: OpenVtsSpacing.sm),
            child: AdminPaymentTransactionCard(
              item: item,
              onTap: () => _showDetails(context, item),
            ),
          );
        }, childCount: state.transactions.length + (state.hasMore ? 1 : 0)),
      ),
    );
  }

  Widget _header(
      int loaded, int total, VoidCallback onRenew, VoidCallback onRefresh) {
    return OpenVtsCard(
      padding: const EdgeInsets.all(OpenVtsSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Payments', style: OpenVtsTypography.titleSmall),
                const SizedBox(height: OpenVtsSpacing.xxs),
                Text(
                  'Manage transactions and renew vehicle subscriptions',
                  style: OpenVtsTypography.meta
                      .copyWith(color: OpenVtsColors.textSecondary),
                ),
                const SizedBox(height: OpenVtsSpacing.xxs),
                Text(
                  '$loaded of $total transactions',
                  style: OpenVtsTypography.meta.copyWith(
                    color: OpenVtsColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh_rounded, size: 18)),
          FilledButton.icon(
            onPressed: onRenew,
            icon: const Icon(Icons.autorenew_rounded, size: 16),
            label: const Text('Renew Vehicle'),
          ),
        ],
      ),
    );
  }

  Future<void> _showRenewSheet(BuildContext context) {
    return OpenVtsBottomSheet.show<void>(
      context: context,
      title: 'Renew Vehicle',
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.96,
      child: const AdminRenewVehicleSheet(),
    );
  }

  Future<void> _showDetails(
      BuildContext context, AdminPaymentTransaction item) {
    return OpenVtsBottomSheet.show<void>(
      context: context,
      title: 'Transaction Details',
      initialChildSize: 0.8,
      minChildSize: 0.45,
      maxChildSize: 0.96,
      child: AdminPaymentTransactionDetailsSheet(item: item),
    );
  }
}
