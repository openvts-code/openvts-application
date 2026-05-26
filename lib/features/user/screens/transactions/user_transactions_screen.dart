import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/open_vts_colors.dart';
import '../../../../core/theme/open_vts_radius.dart';
import '../../../../core/theme/open_vts_spacing.dart';
import '../../../../core/theme/open_vts_typography.dart';
import '../../../../core/utils/date_time_formatter.dart';
import '../../../../shared/widgets/open_vts_button.dart';
import '../../../../shared/widgets/open_vts_card.dart';
import '../../../../shared/widgets/open_vts_empty_state.dart';
import '../../../../shared/widgets/open_vts_error_view.dart';
import '../../../../shared/widgets/open_vts_loader.dart';
import '../../../../shared/widgets/open_vts_page_scaffold.dart';
import '../../../auth/controllers/auth_controller.dart';
import '../../controllers/user_providers.dart';
import '../../models/user_transactions_model.dart';
import '../../models/user_transactions_state.dart';
import 'widgets/user_transaction_card.dart';
import 'widgets/user_transaction_details_sheet.dart';
import 'widgets/user_transactions_filter_card.dart';
import 'widgets/user_transactions_summary_strip.dart';

const DateTimeFormatter _transactionsFormatter = DateTimeFormatter();

class UserTransactionsScreen extends ConsumerWidget {
  const UserTransactionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(userTransactionsControllerProvider);
    final controller = ref.read(userTransactionsControllerProvider.notifier);
    final currentUserId = ref.watch(
      authControllerProvider.select((authState) => authState.user?.id),
    );
    final filteredTransactions = state.filteredTransactions;

    return OpenVtsPageScaffold(
      title: 'Transactions',
      headerMode: OpenVtsPageHeaderMode.closeable,
      padding: const EdgeInsets.fromLTRB(
        OpenVtsSpacing.sm,
        OpenVtsSpacing.xs,
        OpenVtsSpacing.sm,
        0,
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: OpenVtsSpacing.xxs),
          child: IconButton(
            tooltip: 'Refresh transactions',
            onPressed: state.isRefreshing ? null : controller.refresh,
            icon: state.isRefreshing
                ? const SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh_rounded, size: 18),
          ),
        ),
      ],
      body: RefreshIndicator(
        onRefresh: controller.refresh,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 920),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: OpenVtsSpacing.lg),
                  children: [
                    _TransactionsHeaderCard(
                      loadedCount: filteredTransactions.length,
                      totalCount: state.total,
                      rangeLabel: _rangeLabel(state),
                    ),
                    const SizedBox(height: OpenVtsSpacing.sm),
                    UserTransactionsSummaryStrip(
                      transactions: filteredTransactions,
                    ),
                    const SizedBox(height: OpenVtsSpacing.sm),
                    UserTransactionsFilterCard(
                      searchQuery: state.searchQuery,
                      rangePreset: state.rangePreset,
                      customFrom: state.customFrom,
                      customTo: state.customTo,
                      selectedStatus: state.selectedStatus,
                      selectedPaymentMode: state.selectedPaymentMode,
                      selectedPaymentType: state.selectedPaymentType,
                      hasActiveFilters: state.hasActiveFilters,
                      onSearchChanged: controller.setSearchQuery,
                      onRangePresetChanged: (preset) {
                        unawaited(controller.setRangePreset(preset));
                      },
                      onCustomRangeChanged: (from, to) {
                        unawaited(controller.setCustomRange(from, to));
                      },
                      onStatusChanged: (status) {
                        unawaited(controller.setStatusFilter(status));
                      },
                      onPaymentModeChanged: controller.setPaymentModeFilter,
                      onPaymentTypeChanged: controller.setPaymentTypeFilter,
                      onClearFilters: () {
                        unawaited(controller.clearFilters());
                      },
                    ),
                    const SizedBox(height: OpenVtsSpacing.sm),
                    if (state.isLoading && !state.hasTransactions)
                      const SizedBox(
                        height: 220,
                        child: OpenVtsLoader(),
                      )
                    else if (!state.hasTransactions &&
                        state.errorMessage != null)
                      OpenVtsErrorView(
                        message: state.errorMessage ??
                            'Unable to load transactions right now.',
                        onRetry: controller.loadTransactions,
                      )
                    else if (filteredTransactions.isEmpty)
                      OpenVtsEmptyState(
                        title: 'No transactions found',
                        message: state.hasActiveFilters
                            ? 'Try adjusting the filters or date range.'
                            : 'No transactions available for this period.',
                      )
                    else
                      ...filteredTransactions.map(
                        (transaction) => Padding(
                          padding: const EdgeInsets.only(
                            bottom: OpenVtsSpacing.sm,
                          ),
                          child: UserTransactionCard(
                            transaction: transaction,
                            counterpartyName: _counterpartyLabel(
                              transaction,
                              currentUserId,
                            ),
                            onTap: () async {
                              controller.selectTransaction(transaction);
                              try {
                                await showUserTransactionDetailsSheet(
                                  context: context,
                                  transaction: transaction,
                                  currentUserId: currentUserId,
                                );
                              } finally {
                                controller.clearSelectedTransaction();
                              }
                            },
                          ),
                        ),
                      ),
                    if (state.errorMessage != null && state.hasTransactions)
                      _InlineErrorBanner(message: state.errorMessage!),
                    if (state.hasMore && state.hasTransactions) ...[
                      const SizedBox(height: OpenVtsSpacing.xs),
                      OpenVtsButton(
                        label: 'Load More',
                        variant: OpenVtsButtonVariant.secondary,
                        height: 44,
                        isLoading: state.isLoading,
                        onPressed: state.isLoading ? null : controller.loadMore,
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _TransactionsHeaderCard extends StatelessWidget {
  const _TransactionsHeaderCard({
    required this.loadedCount,
    required this.totalCount,
    required this.rangeLabel,
  });

  final int loadedCount;
  final int totalCount;
  final String? rangeLabel;

  @override
  Widget build(BuildContext context) {
    final resolvedTotal = totalCount <= 0 ? loadedCount : totalCount;

    return OpenVtsCard(
      padding: const EdgeInsets.all(OpenVtsSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Transactions',
            style: OpenVtsTypography.label.copyWith(
              fontWeight: FontWeight.w700,
              color: OpenVtsColors.textPrimary,
            ),
          ),
          const SizedBox(height: OpenVtsSpacing.xxs),
          Text(
            'View payments, credits, debits, and billing records.',
            style: OpenVtsTypography.meta.copyWith(
              color: OpenVtsColors.textSecondary,
            ),
          ),
          const SizedBox(height: OpenVtsSpacing.xs),
          Wrap(
            spacing: OpenVtsSpacing.xs,
            runSpacing: OpenVtsSpacing.xs,
            children: [
              _HeaderValueChip(label: 'Loaded', value: '$loadedCount'),
              _HeaderValueChip(label: 'Total', value: '$resolvedTotal'),
              if (rangeLabel != null)
                _HeaderTagChip(
                  text: rangeLabel!,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderValueChip extends StatelessWidget {
  const _HeaderValueChip({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: OpenVtsSpacing.xs,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: OpenVtsColors.surfaceElevated,
        borderRadius: BorderRadius.circular(OpenVtsRadius.sm),
        border: Border.all(color: OpenVtsColors.border),
      ),
      child: Text(
        '$label: $value',
        style: OpenVtsTypography.meta.copyWith(
          color: OpenVtsColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _HeaderTagChip extends StatelessWidget {
  const _HeaderTagChip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: OpenVtsSpacing.xs,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: OpenVtsColors.surface,
        borderRadius: BorderRadius.circular(OpenVtsRadius.sm),
        border: Border.all(color: OpenVtsColors.border),
      ),
      child: Text(
        text,
        style: OpenVtsTypography.meta.copyWith(
          color: OpenVtsColors.textSecondary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _InlineErrorBanner extends StatelessWidget {
  const _InlineErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: OpenVtsSpacing.sm),
      child: OpenVtsCard(
        padding: const EdgeInsets.all(OpenVtsSpacing.sm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 1),
              child: Icon(
                Icons.error_outline_rounded,
                size: 16,
                color: OpenVtsColors.error,
              ),
            ),
            const SizedBox(width: OpenVtsSpacing.xs),
            Expanded(
              child: Text(
                message,
                style: OpenVtsTypography.meta.copyWith(
                  color: OpenVtsColors.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String? _rangeLabel(UserTransactionsState state) {
  switch (state.rangePreset) {
    case UserTransactionsRangePreset.thisMonth:
      return 'This Month';
    case UserTransactionsRangePreset.last30Days:
      return 'Last 30 Days';
    case UserTransactionsRangePreset.thisYear:
      return 'This Year';
    case UserTransactionsRangePreset.custom:
      final from = state.customFrom;
      final to = state.customTo;
      if (from == null && to == null) {
        return null;
      }
      if (from != null && to != null) {
        final fromLabel = _transactionsFormatter.formatDate(from.toLocal());
        final toLabel = _transactionsFormatter.formatDate(to.toLocal());
        return '$fromLabel - $toLabel';
      }
      if (from != null) {
        return 'From ${_transactionsFormatter.formatDate(from.toLocal())}';
      }
      return 'Until ${_transactionsFormatter.formatDate(to!.toLocal())}';
  }
}

String _counterpartyLabel(UserTransaction transaction, String? currentUserId) {
  final fromName =
      _partyDisplayName(transaction.fromUser, transaction.fromUserId);
  final toName = _partyDisplayName(transaction.toUser, transaction.toUserId);
  final normalizedUserId = currentUserId?.trim() ?? '';

  if (normalizedUserId.isNotEmpty) {
    final isFromCurrentUser = _matchesCurrentUser(
      normalizedUserId,
      transaction.fromUserId,
      transaction.fromUser,
    );
    if (isFromCurrentUser) {
      return toName;
    }

    final isToCurrentUser = _matchesCurrentUser(
      normalizedUserId,
      transaction.toUserId,
      transaction.toUser,
    );
    if (isToCurrentUser) {
      return fromName;
    }
  }

  if (fromName != '-' && toName != '-') {
    if (fromName == toName) {
      return fromName;
    }
    return '$fromName -> $toName';
  }

  if (toName != '-') {
    return toName;
  }

  if (fromName != '-') {
    return fromName;
  }

  return '-';
}

bool _matchesCurrentUser(
  String currentUserId,
  int? transactionPartyId,
  UserTransactionParty? party,
) {
  if (transactionPartyId != null &&
      currentUserId == transactionPartyId.toString()) {
    return true;
  }
  if (party?.uid != null && currentUserId == party!.uid.toString()) {
    return true;
  }
  if (party?.id != null && currentUserId == party!.id.toString()) {
    return true;
  }
  return false;
}

String _partyDisplayName(UserTransactionParty? party, int? fallbackId) {
  final displayName = party?.displayName.trim() ?? '';
  if (displayName.isNotEmpty && displayName != '-') {
    return displayName;
  }
  if (fallbackId != null) {
    return 'User $fallbackId';
  }
  return '-';
}
