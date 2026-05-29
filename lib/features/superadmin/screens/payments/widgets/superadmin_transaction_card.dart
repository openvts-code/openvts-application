import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../core/theme/open_vts_colors.dart';
import '../../../../../core/theme/open_vts_spacing.dart';
import '../../../../../core/theme/open_vts_typography.dart';
import '../../../../../core/utils/date_time_formatter.dart';
import '../../../../../shared/widgets/open_vts_card.dart';
import '../../../../../shared/widgets/open_vts_status_chip.dart';
import '../../../models/superadmin_payments_model.dart';

const DateTimeFormatter _transactionDateFormatter = DateTimeFormatter();

class SuperadminTransactionCard extends StatelessWidget {
  const SuperadminTransactionCard({
    required this.transaction,
    required this.onTap,
    super.key,
  });

  final SuperadminTransaction transaction;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final adminName = _adminDisplayName(transaction);
    final amountText = _formatAmount(transaction.amount);
    final currency = transaction.currency.trim();
    final modeLabel = transaction.paymentMode.label;
    final dateText = _formatDateTime(transaction);
    final referenceLine = _referenceLine(transaction);

    return OpenVtsCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(
        horizontal: OpenVtsSpacing.md,
        vertical: OpenVtsSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  adminName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: OpenVtsTypography.body.copyWith(
                    color: OpenVtsColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: OpenVtsSpacing.xs),
              OpenVtsStatusChip(
                label: transaction.status.label,
                type: _statusType(transaction.status),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: Text(
                  '${currency.isEmpty ? '' : '$currency '}$amountText'.trim(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: OpenVtsTypography.numeric.copyWith(
                    fontSize: 18,
                    color: OpenVtsColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: OpenVtsSpacing.xs),
              _SmallLabel(value: modeLabel),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(
                  dateText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: OpenVtsTypography.meta.copyWith(
                    color: OpenVtsColors.textSecondary,
                  ),
                ),
              ),
              if (referenceLine.isNotEmpty)
                Flexible(
                  child: Text(
                    referenceLine,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                    style: OpenVtsTypography.meta.copyWith(
                      color: OpenVtsColors.textTertiary,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _adminDisplayName(SuperadminTransaction transaction) {
    final toUserName = transaction.toUser?.displayName ?? '';
    if (toUserName.trim().isNotEmpty && toUserName.trim() != '—') {
      return toUserName;
    }

    final fromUserName = transaction.fromUser?.displayName ?? '';
    if (fromUserName.trim().isNotEmpty && fromUserName.trim() != '—') {
      return fromUserName;
    }

    if (transaction.toUserId != null && transaction.toUserId! > 0) {
      return 'Admin #${transaction.toUserId}';
    }

    if (transaction.fromUserId != null && transaction.fromUserId! > 0) {
      return 'Admin #${transaction.fromUserId}';
    }

    return 'Admin';
  }

  String _formatAmount(String rawAmount) {
    final normalized = rawAmount.replaceAll(',', '').trim();
    final parsed = num.tryParse(normalized);
    if (parsed == null) {
      return rawAmount.trim().isEmpty ? '0' : rawAmount.trim();
    }

    return NumberFormat('#,##0.##', 'en_US').format(parsed);
  }

  String _formatDateTime(SuperadminTransaction transaction) {
    final date = transaction.createdAt;
    if (date != null) {
      return _transactionDateFormatter.formatDateTime(date.toLocal());
    }

    final raw = transaction.createdAtRaw.trim();
    if (raw.isNotEmpty) {
      return raw;
    }

    return '—';
  }

  String _referenceLine(SuperadminTransaction transaction) {
    final pieces = <String>[];
    final reference = transaction.reference.trim();
    final provider = transaction.provider.trim();
    final providerRef = transaction.providerRef.trim();

    if (reference.isNotEmpty) {
      pieces.add('Ref: $reference');
    }

    if (provider.isNotEmpty) {
      pieces.add('Provider: $provider');
    }

    if (providerRef.isNotEmpty) {
      pieces.add('Provider Ref: $providerRef');
    }

    return pieces.join('  •  ');
  }

  OpenVtsStatusType _statusType(SuperadminTransactionStatus status) {
    switch (status) {
      case SuperadminTransactionStatus.success:
        return OpenVtsStatusType.success;
      case SuperadminTransactionStatus.pending:
        return OpenVtsStatusType.warning;
      case SuperadminTransactionStatus.failed:
        return OpenVtsStatusType.error;
    }
  }
}

class _SmallLabel extends StatelessWidget {
  const _SmallLabel({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: OpenVtsSpacing.xs,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: OpenVtsColors.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: OpenVtsColors.border),
      ),
      child: Text(
        value,
        style: OpenVtsTypography.meta.copyWith(
          color: OpenVtsColors.textSecondary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
