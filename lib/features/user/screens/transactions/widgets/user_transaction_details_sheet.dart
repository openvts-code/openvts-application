import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../../../core/theme/open_vts_colors.dart';
import '../../../../../core/theme/open_vts_radius.dart';
import '../../../../../core/theme/open_vts_spacing.dart';
import '../../../../../core/theme/open_vts_typography.dart';
import '../../../../../core/utils/date_time_formatter.dart';
import '../../../../../shared/helpers/toast_helper.dart';
import '../../../../../shared/widgets/open_vts_card.dart';
import '../../../../../shared/widgets/open_vts_status_chip.dart';
import '../../../models/user_transactions_model.dart';
import 'user_transaction_detail_row.dart';

const DateTimeFormatter _sheetDateFormatter = DateTimeFormatter();

Future<void> showUserTransactionDetailsSheet({
  required BuildContext context,
  required UserTransaction transaction,
  String? currentUserId,
}) {
  return showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => UserTransactionDetailsSheet(
      transaction: transaction,
      currentUserId: currentUserId,
    ),
  );
}

class UserTransactionDetailsSheet extends StatelessWidget {
  const UserTransactionDetailsSheet({
    required this.transaction,
    this.currentUserId,
    super.key,
  });

  final UserTransaction transaction;
  final String? currentUserId;

  @override
  Widget build(BuildContext context) {
    final hasFailure = transaction.status == UserTransactionStatus.failed ||
        _hasReadable(transaction.failureCode) ||
        _hasReadable(transaction.failureMessage);
    final hasVehiclePlan = _hasVehicleOrPlanDetails(transaction);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.86,
      minChildSize: 0.52,
      maxChildSize: 0.96,
      builder: (context, scrollController) {
        return DecoratedBox(
          decoration: const BoxDecoration(
            color: OpenVtsColors.surfaceElevated,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(OpenVtsRadius.lg),
            ),
          ),
          child: Column(
            children: [
              const SizedBox(height: OpenVtsSpacing.sm),
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: OpenVtsColors.border,
                    borderRadius: BorderRadius.circular(OpenVtsRadius.sm),
                  ),
                ),
              ),
              const SizedBox(height: OpenVtsSpacing.xs),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: OpenVtsSpacing.md),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Transaction Details',
                        style: OpenVtsTypography.label.copyWith(
                          color: OpenVtsColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close',
                      constraints: const BoxConstraints(
                        minWidth: 44,
                        minHeight: 44,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded, size: 18),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: OpenVtsColors.divider),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(OpenVtsSpacing.md),
                  children: [
                    _AmountSummaryCard(transaction: transaction),
                    const SizedBox(height: OpenVtsSpacing.sm),
                    _SectionCard(
                      title: 'Details',
                      rows: [
                        _SheetRow(
                          label: 'Transaction ID',
                          value: _safeValue(transaction.id),
                          onCopy: _copyAction(
                            context,
                            label: 'Transaction ID',
                            value: transaction.id,
                          ),
                        ),
                        _SheetRow(
                          label: 'Date/Time',
                          value: _dateTimeLabel(transaction),
                        ),
                        _SheetRow(
                          label: 'Payment Type',
                          value: _paymentTypeLabel(transaction.paymentType),
                        ),
                        _SheetRow(
                          label: 'Payment Mode',
                          value: transaction.paymentMode.label,
                        ),
                        _SheetRow(
                          label: 'Reference',
                          value: _safeValue(transaction.reference),
                          onCopy: _copyAction(
                            context,
                            label: 'Reference',
                            value: transaction.reference,
                          ),
                        ),
                        _SheetRow(
                          label: 'Provider',
                          value: _safeValue(transaction.provider),
                        ),
                        _SheetRow(
                          label: 'Provider Ref',
                          value: _safeValue(transaction.providerRef),
                          onCopy: _copyAction(
                            context,
                            label: 'Provider Ref',
                            value: transaction.providerRef,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: OpenVtsSpacing.sm),
                    _SectionCard(
                      title: 'Parties',
                      rows: [
                        _SheetRow(
                          label: 'From',
                          value: _partyLabel(
                            transaction.fromUser,
                            fallbackPrimaryId: transaction.fromUserId,
                          ),
                        ),
                        _SheetRow(
                          label: 'To',
                          value: _partyLabel(
                            transaction.toUser,
                            fallbackPrimaryId: transaction.toUserId,
                          ),
                        ),
                        _SheetRow(
                          label: 'Recorded By',
                          value: _partyLabel(
                            transaction.recordedBy,
                            fallbackPrimaryId: transaction.recordedById,
                          ),
                        ),
                      ],
                    ),
                    if (hasVehiclePlan) ...[
                      const SizedBox(height: OpenVtsSpacing.sm),
                      _SectionCard(
                        title: 'Vehicle and Plan',
                        rows: _vehiclePlanRows(transaction),
                      ),
                    ],
                    if (hasFailure) ...[
                      const SizedBox(height: OpenVtsSpacing.sm),
                      _SectionCard(
                        title: 'Failure',
                        rows: [
                          _SheetRow(
                            label: 'Failure Code',
                            value: _safeValue(transaction.failureCode),
                          ),
                          _SheetRow(
                            label: 'Failure Message',
                            value: _safeValue(transaction.failureMessage),
                            multiline: true,
                          ),
                        ],
                      ),
                    ],
                    if (transaction.meta.isNotEmpty) ...[
                      const SizedBox(height: OpenVtsSpacing.sm),
                      _MetadataCard(meta: transaction.meta),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<_SheetRow> _vehiclePlanRows(UserTransaction source) {
    final plan = source.plan ?? source.vehicle?.plan;
    final currency = source.currency.trim();
    final planPrice = _safeValue(plan?.price ?? '');
    final planDuration = plan?.durationDays;
    final durationLabel =
        planDuration == null || planDuration <= 0 ? '-' : '$planDuration days';

    return <_SheetRow>[
      _SheetRow(
        label: 'Vehicle Name',
        value: _safeValue(source.vehicle?.name ?? ''),
      ),
      _SheetRow(
        label: 'Plate Number',
        value: _safeValue(source.vehicle?.plateNumber ?? ''),
      ),
      _SheetRow(
        label: 'Plan Name',
        value: _safeValue(plan?.name ?? ''),
      ),
      _SheetRow(
        label: 'Duration',
        value: durationLabel,
      ),
      _SheetRow(
        label: 'Plan Price',
        value: planPrice == '-' || currency.isEmpty
            ? planPrice
            : '$currency $planPrice',
      ),
    ];
  }

  bool _hasVehicleOrPlanDetails(UserTransaction source) {
    final plan = source.plan ?? source.vehicle?.plan;

    return _hasReadable(source.vehicle?.name ?? '') ||
        _hasReadable(source.vehicle?.plateNumber ?? '') ||
        _hasReadable(plan?.name ?? '') ||
        _hasReadable(plan?.price ?? '') ||
        (plan?.durationDays != null && plan!.durationDays! > 0);
  }

  VoidCallback? _copyAction(
    BuildContext context, {
    required String label,
    required String value,
  }) {
    final normalized = value.trim();
    if (normalized.isEmpty || normalized == '-') {
      return null;
    }

    return () {
      Clipboard.setData(ClipboardData(text: normalized));
      ToastHelper.showSuccess('$label copied', context: context);
    };
  }

  String _partyLabel(
    UserTransactionParty? user, {
    required int? fallbackPrimaryId,
  }) {
    final fallbackId = fallbackPrimaryId ?? user?.uid ?? user?.id;
    final isCurrent = _isCurrentUser(fallbackId);
    final display = user?.displayName.trim() ?? '';
    final username = user?.username.trim() ?? '';

    if (display.isNotEmpty && display != '-') {
      var resolved = display;
      if (username.isNotEmpty && username != display) {
        resolved = '$display (@$username)';
      }

      return isCurrent ? '$resolved (You)' : resolved;
    }

    if (username.isNotEmpty) {
      final resolved = '@$username';
      return isCurrent ? '$resolved (You)' : resolved;
    }

    if (isCurrent) {
      return 'You';
    }

    if (fallbackId != null && fallbackId > 0) {
      return 'User #$fallbackId';
    }

    return '-';
  }

  bool _isCurrentUser(int? candidateId) {
    final normalizedCurrent = currentUserId?.trim() ?? '';
    if (normalizedCurrent.isEmpty || candidateId == null || candidateId <= 0) {
      return false;
    }

    return normalizedCurrent == candidateId.toString();
  }

  String _dateTimeLabel(UserTransaction source) {
    if (source.createdAt != null) {
      return _sheetDateFormatter.formatDateTime(source.createdAt!.toLocal());
    }

    return _safeValue(source.createdAtRaw);
  }

  String _paymentTypeLabel(String rawType) {
    final normalized = rawType.trim().toUpperCase();
    if (normalized == 'CREDIT') {
      return 'Credit';
    }
    if (normalized == 'DEBIT') {
      return 'Debit';
    }
    if (normalized.isEmpty) {
      return '-';
    }
    return rawType.trim();
  }

  bool _hasReadable(String value) {
    return _safeValue(value) != '-';
  }

  String _safeValue(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty || normalized == '-' || normalized == '--') {
      return '-';
    }

    return normalized;
  }
}

class _AmountSummaryCard extends StatelessWidget {
  const _AmountSummaryCard({required this.transaction});

  final UserTransaction transaction;

  @override
  Widget build(BuildContext context) {
    return OpenVtsCard(
      padding: const EdgeInsets.all(OpenVtsSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Amount',
                  style: OpenVtsTypography.meta.copyWith(
                    color: OpenVtsColors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _amountText(transaction),
                  style: OpenVtsTypography.numeric.copyWith(
                    fontSize: 22,
                    color: OpenVtsColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: OpenVtsSpacing.sm),
          OpenVtsStatusChip(
            label: transaction.status.label,
            type: _statusType(transaction.status),
          ),
        ],
      ),
    );
  }

  OpenVtsStatusType _statusType(UserTransactionStatus status) {
    switch (status) {
      case UserTransactionStatus.success:
        return OpenVtsStatusType.success;
      case UserTransactionStatus.pending:
        return OpenVtsStatusType.warning;
      case UserTransactionStatus.failed:
        return OpenVtsStatusType.error;
    }
  }

  String _amountText(UserTransaction source) {
    final amount = _formatAmount(source.amount);
    final currency = source.currency.trim();
    if (currency.isEmpty) {
      return amount;
    }

    return '$currency $amount';
  }

  String _formatAmount(String rawValue) {
    final normalized = rawValue.replaceAll(',', '').trim();
    final parsed = num.tryParse(normalized);
    if (parsed == null) {
      return normalized.isEmpty ? '0' : normalized;
    }

    return NumberFormat('#,##0.##', 'en_US').format(parsed);
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.rows,
  });

  final String title;
  final List<_SheetRow> rows;

  @override
  Widget build(BuildContext context) {
    return OpenVtsCard(
      padding: const EdgeInsets.all(OpenVtsSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: OpenVtsTypography.meta.copyWith(
              color: OpenVtsColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: OpenVtsSpacing.xs),
          ...List.generate(rows.length, (index) {
            final row = rows[index];
            return Column(
              children: [
                if (index > 0)
                  const Divider(
                    height: 1,
                    thickness: 0.5,
                    color: OpenVtsColors.divider,
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  child: UserTransactionDetailRow(
                    label: row.label,
                    value: row.value,
                    multiline: row.multiline,
                    onCopy: row.onCopy,
                    copyTooltip: 'Copy ${row.label}',
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _MetadataCard extends StatelessWidget {
  const _MetadataCard({required this.meta});

  final Map<String, dynamic> meta;

  @override
  Widget build(BuildContext context) {
    return OpenVtsCard(
      padding: const EdgeInsets.all(OpenVtsSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Metadata',
            style: OpenVtsTypography.meta.copyWith(
              color: OpenVtsColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: OpenVtsSpacing.xs),
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxHeight: 220),
            padding: const EdgeInsets.all(OpenVtsSpacing.sm),
            decoration: BoxDecoration(
              color: OpenVtsColors.surface,
              borderRadius: BorderRadius.circular(OpenVtsRadius.sm),
              border: Border.all(color: OpenVtsColors.border),
            ),
            child: Scrollbar(
              thumbVisibility: false,
              child: SingleChildScrollView(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SelectableText(
                    _prettyJson(meta),
                    style: OpenVtsTypography.meta.copyWith(
                      color: OpenVtsColors.textPrimary,
                      fontFamily: 'Courier New',
                      height: 1.35,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _prettyJson(Map<String, dynamic> value) {
    try {
      return const JsonEncoder.withIndent('  ').convert(value);
    } catch (_) {
      return value.toString();
    }
  }
}

class _SheetRow {
  const _SheetRow({
    required this.label,
    required this.value,
    this.multiline = false,
    this.onCopy,
  });

  final String label;
  final String value;
  final bool multiline;
  final VoidCallback? onCopy;
}
