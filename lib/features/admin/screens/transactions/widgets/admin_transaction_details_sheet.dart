import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../core/theme/open_vts_colors.dart';
import '../../../../../core/theme/open_vts_radius.dart';
import '../../../../../core/theme/open_vts_spacing.dart';
import '../../../../../core/theme/open_vts_typography.dart';
import '../../../../../core/utils/date_time_formatter.dart';
import '../../../../../shared/helpers/toast_helper.dart';
import '../../../../../shared/widgets/open_vts_card.dart';
import '../../../../../shared/widgets/open_vts_status_chip.dart';
import '../../../models/admin_transactions_model.dart';

class AdminTransactionDetailsSheet extends StatelessWidget {
  const AdminTransactionDetailsSheet({required this.transaction, super.key});

  final AdminTransaction transaction;

  @override
  Widget build(BuildContext context) {
    final formatter = const DateTimeFormatter();

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.88,
      minChildSize: 0.56,
      maxChildSize: 0.96,
      builder: (context, scrollController) {
        return DecoratedBox(
          decoration: const BoxDecoration(
            color: OpenVtsColors.white,
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
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(OpenVtsSpacing.md),
                  children: [
                    OpenVtsCard(
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              transaction.amountDisplay,
                              style: OpenVtsTypography.numeric.copyWith(
                                fontSize: 24,
                                color: OpenVtsColors.textPrimary,
                              ),
                            ),
                          ),
                          OpenVtsStatusChip(
                            label: transaction.status.label,
                            type: _statusType(transaction.status),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: OpenVtsSpacing.sm),
                    _Section(
                      title: 'Details',
                      rows: [
                        _RowData(
                            label: 'Transaction ID',
                            value: _dash(transaction.id),
                            copy: true),
                        _RowData(
                          label: 'Date/Time',
                          value: transaction.createdAt == null
                              ? _dash(transaction.createdAtRaw)
                              : formatter.formatDateTime(
                                  transaction.createdAt!.toLocal()),
                        ),
                        _RowData(
                            label: 'Payment Type',
                            value: transaction.paymentType.label),
                        _RowData(
                            label: 'Payment Mode',
                            value: transaction.paymentMode.label),
                        _RowData(
                            label: 'Reference',
                            value: transaction.referenceDisplay,
                            copy: true),
                        _RowData(
                            label: 'Provider',
                            value: transaction.providerDisplay),
                        _RowData(
                            label: 'Provider Ref',
                            value: _dash(transaction.providerRef),
                            copy: true),
                      ],
                    ),
                    const SizedBox(height: OpenVtsSpacing.sm),
                    _Section(
                      title: 'Parties',
                      rows: [
                        _RowData(
                            label: 'From Admin',
                            value: _party(transaction.fromUser,
                                transaction.fromUserId, 'Admin')),
                        _RowData(
                            label: 'To Superadmin / Platform',
                            value: _party(transaction.toUser,
                                transaction.toUserId, 'Platform')),
                        _RowData(
                            label: 'Recorded By',
                            value: _party(transaction.recordedBy,
                                transaction.recordedById, 'User')),
                      ],
                    ),
                    if (_dash(transaction.failureCode) != '-' ||
                        _dash(transaction.failureMessage) != '-') ...[
                      const SizedBox(height: OpenVtsSpacing.sm),
                      _Section(
                        title: 'Failure',
                        rows: [
                          _RowData(
                              label: 'Failure Code',
                              value: _dash(transaction.failureCode)),
                          _RowData(
                              label: 'Failure Message',
                              value: _dash(transaction.failureMessage),
                              multiline: true),
                        ],
                      ),
                    ],
                    if (transaction.meta.isNotEmpty) ...[
                      const SizedBox(height: OpenVtsSpacing.sm),
                      OpenVtsCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Metadata',
                              style: OpenVtsTypography.label.copyWith(
                                color: OpenVtsColors.textPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: OpenVtsSpacing.xs),
                            SelectableText(
                              const JsonEncoder.withIndent('  ')
                                  .convert(transaction.meta),
                              style: OpenVtsTypography.meta.copyWith(
                                color: OpenVtsColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
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

  String _party(AdminTransactionUser? user, String? fallbackId, String prefix) {
    final name = user?.displayName.trim() ?? '';
    if (name.isNotEmpty && name != '—') {
      final username = user?.username.trim() ?? '';
      if (username.isNotEmpty) return '$name (@$username)';
      return name;
    }
    if ((fallbackId ?? '').trim().isNotEmpty) {
      return '$prefix #${fallbackId!.trim()}';
    }
    return '-';
  }

  OpenVtsStatusType _statusType(AdminTransactionStatus status) {
    return switch (status) {
      AdminTransactionStatus.success => OpenVtsStatusType.success,
      AdminTransactionStatus.pending => OpenVtsStatusType.warning,
      AdminTransactionStatus.failed => OpenVtsStatusType.error,
    };
  }

  String _dash(String value) {
    final text = value.trim();
    return text.isEmpty ? '-' : text;
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.rows});

  final String title;
  final List<_RowData> rows;

  @override
  Widget build(BuildContext context) {
    return OpenVtsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: OpenVtsTypography.label.copyWith(
              color: OpenVtsColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: OpenVtsSpacing.xs),
          ...rows.map((row) => _Row(row: row)),
        ],
      ),
    );
  }
}

class _RowData {
  const _RowData({
    required this.label,
    required this.value,
    this.copy = false,
    this.multiline = false,
  });

  final String label;
  final String value;
  final bool copy;
  final bool multiline;
}

class _Row extends StatelessWidget {
  const _Row({required this.row});

  final _RowData row;

  @override
  Widget build(BuildContext context) {
    final value = row.value.trim().isEmpty ? '-' : row.value.trim();

    return Padding(
      padding: const EdgeInsets.only(top: OpenVtsSpacing.xxs),
      child: Row(
        crossAxisAlignment: row.multiline
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              '${row.label}: $value',
              maxLines: row.multiline ? null : 1,
              overflow:
                  row.multiline ? TextOverflow.visible : TextOverflow.ellipsis,
              style: OpenVtsTypography.meta
                  .copyWith(color: OpenVtsColors.textSecondary),
            ),
          ),
          if (row.copy && value != '-')
            InkWell(
              onTap: () {
                Clipboard.setData(ClipboardData(text: value));
                ToastHelper.showSuccess('${row.label} copied',
                    context: context);
              },
              child: const Padding(
                padding: EdgeInsets.all(2),
                child: Icon(Icons.copy_rounded,
                    size: 14, color: OpenVtsColors.textSecondary),
              ),
            ),
        ],
      ),
    );
  }
}
