import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../../core/theme/open_vts_colors.dart';
import '../../../../../core/theme/open_vts_radius.dart';
import '../../../../../core/theme/open_vts_spacing.dart';
import '../../../../../shared/helpers/toast_helper.dart';
import '../../../../../shared/widgets/open_vts_button.dart';
import '../../../../../shared/widgets/open_vts_card.dart';
import '../../../../../shared/widgets/open_vts_error_view.dart';
import '../../../../../shared/widgets/open_vts_loader.dart';
import '../../../../../shared/widgets/open_vts_text_field.dart';
import '../../../controllers/superadmin_providers.dart';
import '../../../models/superadmin_payments_model.dart';
import '../../payments/widgets/superadmin_transaction_card.dart';
import '../../payments/widgets/transaction_details_sheet.dart';

class AdminDetailsPaymentsTab extends ConsumerStatefulWidget {
  const AdminDetailsPaymentsTab({required this.adminId, super.key});

  final String adminId;

  @override
  ConsumerState<AdminDetailsPaymentsTab> createState() =>
      _AdminDetailsPaymentsTabState();
}

class _AdminDetailsPaymentsTabState
    extends ConsumerState<AdminDetailsPaymentsTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = superadminAdminDetailsControllerProvider(widget.adminId);
      final state = ref.read(provider);
      if (state.transactions.isEmpty &&
          state.transactionAnalytics == null &&
          !state.isLoadingPayments) {
        unawaited(ref.read(provider.notifier).loadPayments());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = superadminAdminDetailsControllerProvider(widget.adminId);
    final state = ref.watch(provider);
    final controller = ref.read(provider.notifier);

    if (state.isLoadingPayments &&
        state.transactions.isEmpty &&
        state.transactionAnalytics == null) {
      return const SizedBox(
        height: 200,
        child: Center(child: OpenVtsLoader()),
      );
    }

    if (state.sectionErrorMessage != null &&
        state.transactions.isEmpty &&
        state.transactionAnalytics == null) {
      return OpenVtsCard(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: OpenVtsSpacing.md),
          child: OpenVtsErrorView(
            message: state.sectionErrorMessage!,
            onRetry: () => controller.loadPayments(),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _PaymentsHeader(
          adminId: widget.adminId,
          isRecording: state.isRecordingPayment,
          onRecordPressed: () => _openRecordSheet(context),
        ),
        const SizedBox(height: OpenVtsSpacing.sm),
        if (state.transactionAnalytics != null) ...[
          _KpiStrip(analytics: state.transactionAnalytics!),
          const SizedBox(height: OpenVtsSpacing.sm),
          _RevenueCard(analytics: state.transactionAnalytics!),
          const SizedBox(height: OpenVtsSpacing.sm),
        ],
        if (state.isLoadingPayments && state.transactions.isNotEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: OpenVtsSpacing.xs),
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
        if (state.transactions.isEmpty)
          const _EmptyState(message: 'No transactions yet.')
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: state.transactions.length,
            separatorBuilder: (_, __) =>
                const SizedBox(height: OpenVtsSpacing.sm),
            itemBuilder: (context, index) {
              final tx = state.transactions[index];
              return SuperadminTransactionCard(
                transaction: tx,
                onTap: () => _openTransactionDetails(context, tx),
              );
            },
          ),
        if (state.paymentsHasMore) ...[
          const SizedBox(height: OpenVtsSpacing.sm),
          OpenVtsButton(
            label: 'Load More',
            variant: OpenVtsButtonVariant.secondary,
            isLoading: state.isLoadingMorePayments,
            onPressed: state.isLoadingMorePayments
                ? null
                : () => controller.loadMorePayments(),
          ),
        ],
      ],
    );
  }

  void _openTransactionDetails(
    BuildContext context,
    SuperadminTransaction transaction,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TransactionDetailsSheet(transaction: transaction),
    );
  }

  Future<void> _openRecordSheet(BuildContext context) async {
    final numericAdminId = int.tryParse(widget.adminId);
    if (numericAdminId == null || numericAdminId <= 0) {
      ToastHelper.showError(
        'Invalid administrator id.',
        context: context,
      );
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return _RecordPaymentSheet(
          adminId: widget.adminId,
          numericAdminId: numericAdminId,
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Header
// ---------------------------------------------------------------------------

class _PaymentsHeader extends StatelessWidget {
  const _PaymentsHeader({
    required this.adminId,
    required this.isRecording,
    required this.onRecordPressed,
  });

  final String adminId;
  final bool isRecording;
  final VoidCallback onRecordPressed;

  @override
  Widget build(BuildContext context) {
    return OpenVtsCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Payments',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: OpenVtsColors.textPrimary,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Transaction history',
                  style: TextStyle(
                    fontSize: 11,
                    color: OpenVtsColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: OpenVtsSpacing.xs),
          OpenVtsButton(
            label: 'Record Payment',
            trailingIcon: Icons.add_rounded,
            onPressed: isRecording ? null : onRecordPressed,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// KPI Strip
// ---------------------------------------------------------------------------

class _KpiStrip extends StatelessWidget {
  const _KpiStrip({required this.analytics});

  final SuperadminTransactionsAnalytics analytics;

  @override
  Widget build(BuildContext context) {
    final breakdown = analytics.statusBreakdown;
    final success = breakdown[SuperadminTransactionStatus.success] ?? 0;
    final pending = breakdown[SuperadminTransactionStatus.pending] ?? 0;
    final failed = breakdown[SuperadminTransactionStatus.failed] ?? 0;
    final compact = NumberFormat.compact(locale: 'en_US');

    return Row(
      children: [
        Expanded(
          child: _CompactKpiCard(
            icon: Icons.check_circle_rounded,
            iconColor: OpenVtsColors.brandInk,
            label: 'Successful',
            value: compact.format(success),
          ),
        ),
        const SizedBox(width: OpenVtsSpacing.sm),
        Expanded(
          child: _CompactKpiCard(
            icon: Icons.pending_rounded,
            iconColor: OpenVtsColors.brandInk,
            label: 'Pending',
            value: compact.format(pending),
          ),
        ),
        const SizedBox(width: OpenVtsSpacing.sm),
        Expanded(
          child: _CompactKpiCard(
            icon: Icons.cancel_rounded,
            iconColor: OpenVtsColors.brandInk,
            label: 'Failed',
            value: compact.format(failed),
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

class _RevenueCard extends StatelessWidget {
  const _RevenueCard({required this.analytics});

  final SuperadminTransactionsAnalytics analytics;

  @override
  Widget build(BuildContext context) {
    final totals = analytics.totalsByCurrency;
    final currencyFormat = NumberFormat('#,##0.##', 'en_US');

    if (totals.isEmpty) {
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
            const Text(
              '—',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: OpenVtsColors.textPrimary,
              ),
            ),
          ],
        ),
      );
    }

    final primary = totals.first;
    final revenue = primary.totalAmountAsDouble ?? 0;
    final currency =
        primary.currency.trim().isEmpty ? 'USD' : primary.currency.trim();
    final success = primary.countSuccess;

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
            '$currency ${currencyFormat.format(revenue)}',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: OpenVtsColors.textPrimary,
            ),
          ),
          if (success > 0) ...[
            const SizedBox(height: 4),
            Text(
              'Avg $currency ${currencyFormat.format(revenue / success)} per transaction',
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

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return OpenVtsCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: OpenVtsSpacing.lg),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.receipt_long_outlined,
                size: 36,
                color: OpenVtsColors.textSecondary.withValues(alpha: 0.5),
              ),
              const SizedBox(height: OpenVtsSpacing.xs),
              Text(
                message,
                style: const TextStyle(
                  fontSize: 13,
                  color: OpenVtsColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Record payment sheet (admin-scoped; no admin selector)
// ---------------------------------------------------------------------------

class _RecordPaymentSheet extends ConsumerStatefulWidget {
  const _RecordPaymentSheet({
    required this.adminId,
    required this.numericAdminId,
  });

  final String adminId;
  final int numericAdminId;

  @override
  ConsumerState<_RecordPaymentSheet> createState() =>
      _RecordPaymentSheetState();
}

class _RecordPaymentSheetState extends ConsumerState<_RecordPaymentSheet> {
  static const List<SuperadminPaymentMode> _paymentModeOrder =
      <SuperadminPaymentMode>[
    SuperadminPaymentMode.bankTransfer,
    SuperadminPaymentMode.cash,
    SuperadminPaymentMode.upi,
    SuperadminPaymentMode.card,
    SuperadminPaymentMode.wallet,
    SuperadminPaymentMode.razorpay,
    SuperadminPaymentMode.stripe,
    SuperadminPaymentMode.other,
  ];
  static final RegExp _amountPattern = RegExp(r'^\d+(\.\d{1,2})?$');

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _amount = TextEditingController();
  final TextEditingController _reference = TextEditingController();
  SuperadminPaymentMode _mode = SuperadminPaymentMode.bankTransfer;

  @override
  void dispose() {
    _amount.dispose();
    _reference.dispose();
    super.dispose();
  }

  String? _validateAmount(String? value) {
    final raw = value?.trim() ?? '';
    if (raw.isEmpty) return 'Amount is required.';
    if (raw.length > 12) return 'Amount must be 12 characters or less.';
    if (!_amountPattern.hasMatch(raw)) {
      return 'Enter a valid amount (up to 2 decimals).';
    }
    final parsed = double.tryParse(raw);
    if (parsed == null || parsed <= 0) return 'Amount must be greater than 0.';
    return null;
  }

  String? _validateReference(String? value) {
    final raw = value?.trim() ?? '';
    if (raw.length > 100) return 'Reference must be 100 characters or less.';
    return null;
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final provider = superadminAdminDetailsControllerProvider(widget.adminId);
    final controller = ref.read(provider.notifier);
    final ref0 = _reference.text.trim();
    final ok = await controller.recordManualPayment(
      SuperadminRecordPaymentRequest(
        adminId: widget.numericAdminId,
        amount: _amount.text.trim(),
        paymentMode: _mode,
        reference: ref0.isEmpty ? null : ref0,
      ),
    );
    if (!mounted) return;
    if (ok) {
      ToastHelper.showSuccess('Payment recorded', context: context);
      Navigator.of(context).pop();
    } else {
      final message = ref.read(provider).sectionErrorMessage ??
          'Unable to record payment right now.';
      ToastHelper.showError(message, context: context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = superadminAdminDetailsControllerProvider(widget.adminId);
    final isLoading = ref.watch(provider.select((s) => s.isRecordingPayment));

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.72,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return DecoratedBox(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(OpenVtsRadius.xl),
            ),
          ),
          child: Column(
            children: [
              const SizedBox(height: OpenVtsSpacing.sm),
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: OpenVtsColors.border,
                    borderRadius: BorderRadius.circular(OpenVtsRadius.sm),
                  ),
                ),
              ),
              const SizedBox(height: OpenVtsSpacing.xs),
              const _SheetHeader(title: 'Record Payment'),
              const Divider(height: 1, color: OpenVtsColors.divider),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(OpenVtsSpacing.md),
                  children: [
                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          OpenVtsTextField(
                            label: 'Amount',
                            controller: _amount,
                            hintText: '0.00',
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            textInputAction: TextInputAction.next,
                            validator: _validateAmount,
                            prefixIcon: Icons.payments_outlined,
                          ),
                          const SizedBox(height: OpenVtsSpacing.sm),
                          _ModeDropdown(
                            value: _mode,
                            options: _paymentModeOrder,
                            onChanged: (next) {
                              if (next != null) setState(() => _mode = next);
                            },
                          ),
                          const SizedBox(height: OpenVtsSpacing.sm),
                          OpenVtsTextField(
                            label: 'Reference (optional)',
                            controller: _reference,
                            hintText: 'Bank ref / UTR / transaction ID',
                            textInputAction: TextInputAction.done,
                            validator: _validateReference,
                            prefixIcon: Icons.tag,
                          ),
                          const SizedBox(height: OpenVtsSpacing.xs),
                          const Text(
                            'Payment will appear immediately in transaction list.',
                            style: TextStyle(
                              fontSize: 11,
                              color: OpenVtsColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              _SheetFooter(
                isLoading: isLoading,
                submitLabel: 'Record Payment',
                onCancel: () => Navigator.of(context).pop(),
                onSubmit: _submit,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ModeDropdown extends StatelessWidget {
  const _ModeDropdown({
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final SuperadminPaymentMode value;
  final List<SuperadminPaymentMode> options;
  final ValueChanged<SuperadminPaymentMode?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Payment mode',
          style: TextStyle(
            fontSize: 11,
            color: OpenVtsColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        DropdownButtonFormField<SuperadminPaymentMode>(
          initialValue: value,
          isDense: true,
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: OpenVtsSpacing.sm,
              vertical: OpenVtsSpacing.sm,
            ),
            filled: true,
            fillColor: OpenVtsColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(OpenVtsRadius.sm),
              borderSide: const BorderSide(color: OpenVtsColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(OpenVtsRadius.sm),
              borderSide: const BorderSide(color: OpenVtsColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(OpenVtsRadius.sm),
              borderSide: const BorderSide(color: OpenVtsColors.brandInk),
            ),
          ),
          items: options
              .map(
                (m) => DropdownMenuItem<SuperadminPaymentMode>(
                  value: m,
                  child: Text(
                    m.label,
                    style: const TextStyle(
                      fontSize: 13,
                      color: OpenVtsColors.textPrimary,
                    ),
                  ),
                ),
              )
              .toList(growable: false),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Sheet chrome
// ---------------------------------------------------------------------------

class _SheetHeader extends StatelessWidget {
  const _SheetHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: OpenVtsSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: OpenVtsColors.textPrimary,
              ),
            ),
          ),
          IconButton(
            constraints: const BoxConstraints(
              minWidth: 44,
              minHeight: 44,
            ),
            icon: const Icon(Icons.close_rounded, size: 20),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'Close',
          ),
        ],
      ),
    );
  }
}

class _SheetFooter extends StatelessWidget {
  const _SheetFooter({
    required this.isLoading,
    required this.onCancel,
    required this.onSubmit,
    required this.submitLabel,
  });

  final bool isLoading;
  final VoidCallback onCancel;
  final VoidCallback onSubmit;
  final String submitLabel;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          OpenVtsSpacing.md,
          OpenVtsSpacing.xs,
          OpenVtsSpacing.md,
          OpenVtsSpacing.md,
        ),
        child: Row(
          children: [
            Expanded(
              child: OpenVtsButton(
                label: 'Cancel',
                variant: OpenVtsButtonVariant.secondary,
                onPressed: isLoading ? null : onCancel,
              ),
            ),
            const SizedBox(width: OpenVtsSpacing.sm),
            Expanded(
              child: OpenVtsButton(
                label: submitLabel,
                isLoading: isLoading,
                onPressed: isLoading ? null : onSubmit,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
