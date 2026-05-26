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
import '../../../models/superadmin_payments_model.dart';

const DateTimeFormatter _detailsDateFormatter = DateTimeFormatter();

class TransactionDetailsSheet extends StatelessWidget {
  const TransactionDetailsSheet({
    required this.transaction,
    super.key,
  });

  final SuperadminTransaction transaction;

  @override
  Widget build(BuildContext context) {
    final headerAmount = _formatHeaderAmount(transaction);
    final hasFailure = _hasValue(transaction.failureCode) ||
        _hasValue(transaction.failureMessage);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.88,
      minChildSize: 0.56,
      maxChildSize: 0.96,
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
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: OpenVtsSpacing.md),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Transaction Details',
                        style: OpenVtsTypography.titleSmall.copyWith(
                          color: OpenVtsColors.textPrimary,
                        ),
                      ),
                    ),
                    IconButton(
                      constraints: const BoxConstraints(
                        minHeight: 44,
                        minWidth: 44,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
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
                    OpenVtsCard(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              headerAmount,
                              style: OpenVtsTypography.numeric.copyWith(
                                fontSize: 26,
                                color: OpenVtsColors.textPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: OpenVtsSpacing.sm),
                          _StatusChip(status: transaction.status),
                        ],
                      ),
                    ),
                    const SizedBox(height: OpenVtsSpacing.sm),
                    _DetailsSection(
                      title: 'Details',
                      rows: [
                        _DetailRowData(
                          label: 'Transaction ID',
                          value: _valueOrDash(transaction.id),
                          onCopy: _hasValue(transaction.id)
                              ? () => _copyValue(
                                    context,
                                    label: 'Transaction ID',
                                    value: transaction.id,
                                  )
                              : null,
                        ),
                        _DetailRowData(
                          label: 'Date/Time',
                          value: _formattedDateTime(transaction),
                        ),
                        _DetailRowData(
                          label: 'Payment Type',
                          value: _valueOrDash(transaction.paymentType),
                        ),
                        _DetailRowData(
                          label: 'Payment Mode',
                          value: _statusModeLabel(transaction.paymentMode),
                        ),
                        _DetailRowData(
                          label: 'Reference',
                          value: _valueOrDash(transaction.reference),
                          onCopy: _hasValue(transaction.reference)
                              ? () => _copyValue(
                                    context,
                                    label: 'Reference',
                                    value: transaction.reference,
                                  )
                              : null,
                        ),
                        _DetailRowData(
                          label: 'Provider',
                          value: _valueOrDash(transaction.provider),
                        ),
                        _DetailRowData(
                          label: 'Provider Ref',
                          value: _valueOrDash(transaction.providerRef),
                          onCopy: _hasValue(transaction.providerRef)
                              ? () => _copyValue(
                                    context,
                                    label: 'Provider Ref',
                                    value: transaction.providerRef,
                                  )
                              : null,
                        ),
                      ],
                    ),
                    const SizedBox(height: OpenVtsSpacing.sm),
                    _DetailsSection(
                      title: 'Parties',
                      rows: [
                        _DetailRowData(
                          label: 'From Admin',
                          value: _partyLabel(
                            transaction.fromUser,
                            fallbackId: transaction.fromUserId,
                            fallbackPrefix: 'Admin',
                          ),
                        ),
                        _DetailRowData(
                          label: 'To',
                          value: _partyLabel(
                            transaction.toUser,
                            fallbackId: transaction.toUserId,
                            fallbackPrefix: 'User',
                          ),
                        ),
                        _DetailRowData(
                          label: 'Recorded By',
                          value: _partyLabel(
                            transaction.recordedBy,
                            fallbackId: transaction.recordedById,
                            fallbackPrefix: 'User',
                          ),
                        ),
                      ],
                    ),
                    if (hasFailure) ...[
                      const SizedBox(height: OpenVtsSpacing.sm),
                      _DetailsSection(
                        title: 'Failure',
                        rows: [
                          _DetailRowData(
                            label: 'Failure Code',
                            value: _valueOrDash(transaction.failureCode),
                          ),
                          _DetailRowData(
                            label: 'Failure Message',
                            value: _valueOrDash(transaction.failureMessage),
                            multiline: true,
                          ),
                        ],
                      ),
                    ],
                    if (transaction.meta.isNotEmpty) ...[
                      const SizedBox(height: OpenVtsSpacing.sm),
                      _MetaSection(meta: transaction.meta),
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

  void _copyValue(
    BuildContext context, {
    required String label,
    required String value,
  }) {
    final normalized = value.trim();
    if (normalized.isEmpty) {
      return;
    }

    Clipboard.setData(ClipboardData(text: normalized));
    ToastHelper.showSuccess('$label copied', context: context);
  }

  String _formatHeaderAmount(SuperadminTransaction source) {
    final currency = _normalizedValue(source.currency);
    final amount = _formatAmount(source.amount);
    if (currency == '-') {
      return amount;
    }

    return '$currency $amount';
  }

  String _formatAmount(String rawAmount) {
    final normalized = rawAmount.replaceAll(',', '').trim();
    final parsed = num.tryParse(normalized);
    if (parsed == null) {
      final raw = _normalizedValue(rawAmount);
      return raw == '-' ? '0' : raw;
    }

    return NumberFormat('#,##0.##', 'en_US').format(parsed);
  }

  String _formattedDateTime(SuperadminTransaction source) {
    final parsed = source.createdAt;
    if (parsed != null) {
      return _detailsDateFormatter.formatDateTime(parsed.toLocal());
    }

    return _valueOrDash(source.createdAtRaw);
  }

  String _statusModeLabel(SuperadminPaymentMode mode) {
    return mode.label;
  }

  String _partyLabel(
    SuperadminTransactionUser? user, {
    required int? fallbackId,
    required String fallbackPrefix,
  }) {
    final name = _normalizedValue(user?.displayName ?? '');
    if (name != '-') {
      final username = _normalizedValue(user?.username ?? '');
      if (username != '-') {
        return '$name (@$username)';
      }
      return name;
    }

    if (fallbackId != null && fallbackId > 0) {
      return '$fallbackPrefix #$fallbackId';
    }

    return '-';
  }

  String _valueOrDash(String value) {
    return _normalizedValue(value);
  }

  bool _hasValue(String value) {
    final normalized = _normalizedValue(value);
    return normalized != '-';
  }

  String _normalizedValue(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty || trimmed == '—' || trimmed == '--') {
      return '-';
    }

    return trimmed;
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final SuperadminTransactionStatus status;

  @override
  Widget build(BuildContext context) {
    final label = switch (status) {
      SuperadminTransactionStatus.success => 'Success',
      SuperadminTransactionStatus.pending => 'Pending',
      SuperadminTransactionStatus.failed => 'Failed',
    };

    final borderColor = switch (status) {
      SuperadminTransactionStatus.failed =>
        OpenVtsColors.textSecondary.withValues(alpha: 0.38),
      SuperadminTransactionStatus.pending =>
        OpenVtsColors.textSecondary.withValues(alpha: 0.38),
      SuperadminTransactionStatus.success =>
        OpenVtsColors.textSecondary.withValues(alpha: 0.38),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: OpenVtsColors.surface,
        borderRadius: BorderRadius.circular(OpenVtsRadius.sm),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        label,
        style: OpenVtsTypography.meta.copyWith(
          color: OpenVtsColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _DetailsSection extends StatelessWidget {
  const _DetailsSection({
    required this.title,
    required this.rows,
  });

  final String title;
  final List<_DetailRowData> rows;

  @override
  Widget build(BuildContext context) {
    return OpenVtsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: OpenVtsTypography.label.copyWith(
              color: OpenVtsColors.textSecondary,
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
                  child: _DetailRow(row: row),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _MetaSection extends StatelessWidget {
  const _MetaSection({required this.meta});

  final Map<String, dynamic> meta;

  @override
  Widget build(BuildContext context) {
    return OpenVtsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Metadata',
            style: OpenVtsTypography.label.copyWith(
              color: OpenVtsColors.textSecondary,
            ),
          ),
          const SizedBox(height: OpenVtsSpacing.xs),
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxHeight: 220),
            decoration: BoxDecoration(
              color: OpenVtsColors.surface,
              borderRadius: BorderRadius.circular(OpenVtsRadius.sm),
              border: Border.all(color: OpenVtsColors.border),
            ),
            child: Scrollbar(
              thumbVisibility: false,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(OpenVtsSpacing.sm),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SelectableText(
                    _prettyJson(meta),
                    style: OpenVtsTypography.meta.copyWith(
                      color: OpenVtsColors.textPrimary,
                      fontFamily: 'Courier New',
                      height: 1.4,
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

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.row});

  final _DetailRowData row;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment:
          row.multiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 114,
          child: Text(
            row.label,
            style: OpenVtsTypography.meta.copyWith(
              color: OpenVtsColors.textTertiary,
            ),
          ),
        ),
        const SizedBox(width: OpenVtsSpacing.xs),
        Expanded(
          child: Text(
            row.value,
            maxLines: row.multiline ? null : 2,
            overflow:
                row.multiline ? TextOverflow.visible : TextOverflow.ellipsis,
            style: OpenVtsTypography.body.copyWith(
              color: OpenVtsColors.textPrimary,
            ),
          ),
        ),
        if (row.onCopy != null) ...[
          const SizedBox(width: OpenVtsSpacing.xxs),
          IconButton(
            onPressed: row.onCopy,
            icon: const Icon(Icons.content_copy_rounded, size: 18),
            color: OpenVtsColors.textSecondary,
            tooltip: 'Copy',
            constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ],
    );
  }
}

class _DetailRowData {
  const _DetailRowData({
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
