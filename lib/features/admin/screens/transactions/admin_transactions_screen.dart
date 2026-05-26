import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/open_vts_colors.dart';
import '../../../../core/theme/open_vts_spacing.dart';
import '../../../../core/theme/open_vts_typography.dart';
import '../../../../shared/widgets/open_vts_card.dart';
import '../../../../shared/widgets/open_vts_empty_state.dart';
import '../../../../shared/widgets/open_vts_error_view.dart';
import '../../../../shared/widgets/open_vts_loader.dart';
import '../../../../shared/widgets/open_vts_page_scaffold.dart';
import '../../../../shared/widgets/open_vts_search_field.dart';
import '../../controllers/admin_providers.dart';
import '../../controllers/admin_transactions_controller.dart';
import '../../models/admin_transactions_model.dart';
import '../../models/admin_transactions_state.dart';
import 'widgets/admin_transaction_card.dart';
import 'widgets/admin_transaction_details_sheet.dart';
import 'widgets/admin_transactions_filters_card.dart';

class AdminTransactionsScreen extends ConsumerStatefulWidget {
  const AdminTransactionsScreen({super.key});

  @override
  ConsumerState<AdminTransactionsScreen> createState() =>
      _AdminTransactionsScreenState();
}

class _AdminTransactionsScreenState
    extends ConsumerState<AdminTransactionsScreen> {
  Timer? _searchDebounce;

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminTransactionsControllerProvider);
    final controller = ref.read(adminTransactionsControllerProvider.notifier);

    return OpenVtsPageScaffold(
      title: 'Transactions',
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
                  _HeaderCard(
                    loaded: state.transactions.length,
                    total: state.total,
                    onRefresh: controller.refresh,
                  ),
                  const SizedBox(height: OpenVtsSpacing.sm),
                  OpenVtsSearchField(
                    hintText: 'Search reference, provider, counterparty...',
                    onChanged: (value) {
                      _searchDebounce?.cancel();
                      _searchDebounce = Timer(
                        const Duration(milliseconds: 300),
                        () => unawaited(controller.setSearchQuery(value)),
                      );
                    },
                  ),
                  const SizedBox(height: OpenVtsSpacing.sm),
                  AdminTransactionsFiltersCard(
                    state: state,
                    onStatusChanged: (value) =>
                        unawaited(controller.setStatus(value)),
                    onModeChanged: controller.setMode,
                    onTypeChanged: controller.setType,
                    onRangePresetChanged: (value) =>
                        unawaited(controller.setRangePreset(value)),
                    onCustomRangeChanged: (from, to) =>
                        unawaited(controller.setCustomRange(from, to)),
                    onClearFilters: () => unawaited(controller.clearFilters()),
                    onApplyFilters: () => unawaited(controller.load()),
                  ),
                  const SizedBox(height: OpenVtsSpacing.sm),
                ]),
              ),
            ),
            _buildContent(state, controller),
            const SliverToBoxAdapter(
                child: SizedBox(height: OpenVtsSpacing.lg)),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(
    AdminTransactionsState state,
    AdminTransactionsController controller,
  ) {
    if (state.isLoading && !state.hasTransactions) {
      return const SliverFillRemaining(
          hasScrollBody: false, child: OpenVtsLoader());
    }

    if (state.errorMessage != null && !state.hasTransactions) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: OpenVtsErrorView(
          message: state.errorMessage!,
          onRetry: controller.load,
        ),
      );
    }

    if (!state.hasTransactions) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: OpenVtsEmptyState(
          title: 'No transactions found',
          message: 'Try changing search or filters.',
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: OpenVtsSpacing.sm),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final totalRows =
              state.transactions.length + (state.hasMoreTransactions ? 1 : 0);
          if (index == totalRows - 1 && state.hasMoreTransactions) {
            return Padding(
              padding: const EdgeInsets.only(top: OpenVtsSpacing.xs),
              child: OutlinedButton(
                onPressed: state.isLoadingMore
                    ? null
                    : () {
                        unawaited(controller.loadMore());
                      },
                child: state.isLoadingMore
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Load More'),
              ),
            );
          }

          final item = state.transactions[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: OpenVtsSpacing.sm),
            child: AdminTransactionCard(
              transaction: item,
              onTap: () => _openDetails(item),
            ),
          );
        },
            childCount: state.transactions.length +
                (state.hasMoreTransactions ? 1 : 0)),
      ),
    );
  }

  Future<void> _openDetails(AdminTransaction transaction) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AdminTransactionDetailsSheet(transaction: transaction),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.loaded,
    required this.total,
    required this.onRefresh,
  });

  final int loaded;
  final int total;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return OpenVtsCard(
      padding: const EdgeInsets.all(OpenVtsSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Transactions',
                  style: OpenVtsTypography.titleSmall.copyWith(
                    color: OpenVtsColors.textPrimary,
                  ),
                ),
                const SizedBox(height: OpenVtsSpacing.xxs),
                Text(
                  'Admin payments made to platform account.',
                  style: OpenVtsTypography.meta.copyWith(
                    color: OpenVtsColors.textSecondary,
                  ),
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
            icon: const Icon(Icons.refresh_rounded, size: 18),
          ),
        ],
      ),
    );
  }
}
