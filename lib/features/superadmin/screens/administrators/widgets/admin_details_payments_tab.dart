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
      final provider =
          superadminAdminDetailsControllerProvider(widget.adminId);
      final state = ref.read(provider);
      if (state.transactions.isEmpty &&
          state.transactionAnalytics == null &&
          !state.isLoadingPayments) {
        ref.read(provider.notifier).loadPayments();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider =
        superadminAdminDetailsControllerProvider(widget.adminId);
    final state = ref.watch(provider);
    final controller = ref.read(provider.notifier);

    if (state.isLoadingPayments && state.transactions.isEmpty) {
      return const OpenVtsCard(
        padding: EdgeInsets.symmetric(vertical: OpenVtsSpacing.lg),
        child: Center(child: OpenVtsLoader()),
      );
    }

    if (state.sectionErrorMessage != null && state.transactions.isEmpty) {
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

    final analytics = state.transactionAnalytics;
    final transactions = state.transactions;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (analytics != null) ...[
          _AnalyticsSummary(analytics: analytics),
          const SizedBox(height: OpenVtsSpacing.sm),
          _RevenueCard(analytics: analytics),
          const SizedBox(height: OpenVtsSpacing.sm),
        ],
        OpenVtsButton(
          label: 'Record payment',
          onPressed: state.isRecordingPayment
              ? null
              : () => _openRecordSheet(context),
        ),
        const SizedBox(height: OpenVtsSpacing.sm),
        if (transactions.isEmpty)
          const _EmptyState(message: 'No transactions yet.')
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: transactions.length,
            separatorBuilder: (_, __) =>
                const SizedBox(height: OpenVtsSpacing.xs),
            itemBuilder: (context, index) {
              final tx = transactions[index];
              return SuperadminTransactionCard(
                transaction: tx,
                onTap: () => _openTransactionDetails(context, tx),
              );
            },
          ),
        if (state.paymentsHasMore) ...[
          const SizedBox(height: OpenVtsSpacing.sm),
          OpenVtsButton(
            label: 'Load more',
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
      backgroundColor: OpenVtsColors.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
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
// Analytics summary
// ---------------------------------------------------------------------------

class _AnalyticsSummary extends StatelessWidget {
  const _AnalyticsSummary({required this.analytics});

  final SuperadminTransactionsAnalytics analytics;

  @override
  Widget build(BuildContext context) {
    final breakdown = analytics.statusBreakdown;
    final success = breakdown[SuperadminTransactionStatus.success] ?? 0;
    final pending = breakdown[SuperadminTransactionStatus.pending] ?? 0;
    final failed = breakdown[SuperadminTransactionStatus.failed] ?? 0;

    return Row(
      children: [
        Expanded(
          child: _SummaryTile(
            label: 'Total',
            value: analytics.totalTransactions.toString(),
            icon: Icons.receipt_long_outlined,
          ),
        ),
        const SizedBox(width: OpenVtsSpacing.xs),
        Expanded(
          child: _SummaryTile(
            label: 'Success',
            value: success.toString(),
            icon: Icons.check_circle_outline,
          ),
        ),
        const SizedBox(width: OpenVtsSpacing.xs),
        Expanded(
          child: _SummaryTile(
            label: 'Pending',
            value: pending.toString(),
            icon: Icons.schedule_outlined,
          ),
        ),
        const SizedBox(width: OpenVtsSpacing.xs),
        Expanded(
          child: _SummaryTile(
            label: 'Failed',
            value: failed.toString(),
            icon: Icons.error_outline,
          ),
        ),
      ],
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return OpenVtsCard(
      padding: const EdgeInsets.symmetric(
        horizontal: OpenVtsSpacing.xs,
        vertical: OpenVtsSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: OpenVtsColors.textSecondary),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: OpenVtsColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: OpenVtsColors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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
    if (totals.isEmpty) {
      return const OpenVtsCard(
        padding: EdgeInsets.symmetric(
          horizontal: OpenVtsSpacing.sm,
          vertical: OpenVtsSpacing.sm,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Revenue',
                style: TextStyle(
                  fontSize: 11,
                  color: OpenVtsColors.textSecondary,
                ),
              ),
            ),
            Text(
              '—',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: OpenVtsColors.textPrimary,
              ),
            ),
          ],
        ),
      );
    }
    return OpenVtsCard(
      padding: const EdgeInsets.symmetric(
        horizontal: OpenVtsSpacing.sm,
        vertical: OpenVtsSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Revenue (this month)',
            style: TextStyle(
              fontSize: 11,
              color: OpenVtsColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          ...totals.map((total) {
            return Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      total.currency.isEmpty ? '—' : total.currency,
                      style: const TextStyle(
                        fontSize: 12,
                        color: OpenVtsColors.textSecondary,
                      ),
                    ),
                  ),
                  Text(
                    _formatTotal(total),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: OpenVtsColors.textPrimary,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  String _formatTotal(SuperadminCurrencyTotal total) {
    final value = total.totalAmountAsDouble;
    if (value == null) {
      return total.totalAmount.isEmpty ? '—' : total.totalAmount;
    }
    return NumberFormat.decimalPattern().format(value);
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return OpenVtsCard(
      padding: const EdgeInsets.symmetric(vertical: OpenVtsSpacing.lg),
      child: Center(
        child: Text(
          message,
          style: const TextStyle(
            fontSize: 12,
            color: OpenVtsColors.textSecondary,
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
    if (!_amountPattern.hasMatch(raw)) {
      return 'Enter a valid amount (up to 2 decimals).';
    }
    final parsed = double.tryParse(raw);
    if (parsed == null || parsed <= 0) return 'Amount must be greater than 0.';
    return null;
  }

  String? _validateReference(String? value) {
    final raw = value?.trim() ?? '';
    if (raw.length > 120) return 'Reference is too long.';
    return null;
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final provider =
        superadminAdminDetailsControllerProvider(widget.adminId);
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
      ToastHelper.showSuccess('Payment recorded.', context: context);
      Navigator.of(context).maybePop();
    } else {
      final message =
          ref.read(provider).sectionErrorMessage ?? 'Failed to record payment.';
      ToastHelper.showError(message, context: context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider =
        superadminAdminDetailsControllerProvider(widget.adminId);
    final isLoading =
        ref.watch(provider.select((s) => s.isRecordingPayment));
    final viewInsets = MediaQuery.of(context).viewInsets;

    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _SheetHeader(title: 'Record payment'),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  OpenVtsSpacing.md,
                  OpenVtsSpacing.sm,
                  OpenVtsSpacing.md,
                  OpenVtsSpacing.sm,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      OpenVtsTextField(
                        label: 'Amount',
                        controller: _amount,
                        hintText: 'e.g. 1000.00',
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
                        hintText: 'Bank ref / UTR / receipt no.',
                        textInputAction: TextInputAction.done,
                        validator: _validateReference,
                        prefixIcon: Icons.tag,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            _SheetFooter(
              isLoading: isLoading,
              submitLabel: 'Record payment',
              onCancel: () => Navigator.of(context).maybePop(),
              onSubmit: _submit,
            ),
          ],
        ),
      ),
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
      padding: const EdgeInsets.fromLTRB(
        OpenVtsSpacing.md,
        OpenVtsSpacing.sm,
        OpenVtsSpacing.xs,
        0,
      ),
      child: Column(
        children: [
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(top: 6, bottom: OpenVtsSpacing.sm),
            decoration: BoxDecoration(
              color: OpenVtsColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Row(
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
                icon: const Icon(Icons.close_rounded, size: 20),
                onPressed: () => Navigator.of(context).maybePop(),
                tooltip: 'Close',
              ),
            ],
          ),
          const Divider(height: 1, color: OpenVtsColors.border),
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
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: OpenVtsColors.border)),
        color: OpenVtsColors.surfaceElevated,
      ),
      padding: const EdgeInsets.fromLTRB(
        OpenVtsSpacing.md,
        OpenVtsSpacing.sm,
        OpenVtsSpacing.md,
        OpenVtsSpacing.sm,
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
    );
  }
}

