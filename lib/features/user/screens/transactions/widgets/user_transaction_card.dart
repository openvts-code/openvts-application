import 'package:flutter/material.dart';

import '../../../../../core/theme/open_vts_colors.dart';
import '../../../../../core/theme/open_vts_spacing.dart';
import '../../../../../core/theme/open_vts_typography.dart';
import '../../../../../core/utils/date_time_formatter.dart';
import '../../../../../shared/widgets/open_vts_card.dart';
import '../../../../../shared/widgets/open_vts_status_chip.dart';
import '../../../models/user_transactions_model.dart';

const DateTimeFormatter _dateTimeFormatter = DateTimeFormatter();

class UserTransactionCard extends StatelessWidget {
  const UserTransactionCard({
    required this.transaction,
    required this.counterpartyName,
    required this.onTap,
    super.key,
  });

  final UserTransaction transaction;
  final String counterpartyName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final referenceProviderLine = _referenceProviderLine(transaction);
    final vehiclePlanLine = _vehiclePlanLine(transaction);

    return OpenVtsCard(
      onTap: onTap,
      padding: const EdgeInsets.all(OpenVtsSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      counterpartyName.trim().isEmpty ? '-' : counterpartyName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: OpenVtsTypography.label.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_paymentTypeLabel(transaction.paymentType)} | '
                      '${transaction.paymentMode.label}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: OpenVtsTypography.meta.copyWith(
                        color: OpenVtsColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: OpenVtsSpacing.xs),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  OpenVtsStatusChip(
                    label: transaction.status.label,
                    type: _statusType(transaction.status),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _amountLabel(transaction),
                    style: OpenVtsTypography.numeric.copyWith(
                      fontSize: 18,
                      color: OpenVtsColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (referenceProviderLine != null) ...[
            const SizedBox(height: 6),
            Text(
              referenceProviderLine,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: OpenVtsTypography.meta.copyWith(
                color: OpenVtsColors.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(
                Icons.schedule_outlined,
                size: 14,
                color: OpenVtsColors.textTertiary,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  _metaLine(transaction, vehiclePlanLine),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: OpenVtsTypography.meta.copyWith(
                    color: OpenVtsColors.textTertiary,
                  ),
                ),
              ),
              const SizedBox(width: OpenVtsSpacing.xs),
              const Icon(
                Icons.chevron_right_rounded,
                size: 16,
                color: OpenVtsColors.textTertiary,
              ),
            ],
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

  String _amountLabel(UserTransaction item) {
    final amount = item.amount.trim().isEmpty ? '0' : item.amount.trim();
    final currency = item.currency.trim();
    if (currency.isEmpty) {
      return amount;
    }

    return '$currency $amount';
  }

  String _paymentTypeLabel(String rawValue) {
    final normalized = rawValue.trim().toUpperCase();
    if (normalized == 'CREDIT') {
      return 'Credit';
    }
    if (normalized == 'DEBIT') {
      return 'Debit';
    }
    if (normalized.isEmpty) {
      return 'Type N/A';
    }

    return _titleCaseWords(rawValue);
  }

  String _metaLine(UserTransaction item, String? vehiclePlanLine) {
    final parts = <String>[_dateLabel(item)];
    if (vehiclePlanLine != null) {
      parts.add(vehiclePlanLine);
    }

    final recordedBy = _recordedByLabel(item);
    if (recordedBy != null) {
      parts.add('By $recordedBy');
    }

    return parts.join(' | ');
  }

  String? _recordedByLabel(UserTransaction item) {
    final displayName = item.recordedBy?.displayName.trim() ?? '';
    if (displayName.isNotEmpty && displayName != '-') {
      return displayName;
    }

    final username = item.recordedBy?.username.trim() ?? '';
    if (username.isNotEmpty) {
      return '@$username';
    }

    final id = item.recordedById;
    if (id != null && id > 0) {
      return 'User #$id';
    }

    return null;
  }

  String _dateLabel(UserTransaction item) {
    if (item.createdAt != null) {
      return _dateTimeFormatter.formatDateTime(item.createdAt!.toLocal());
    }

    final fallback = item.createdAtRaw.trim();
    return fallback.isEmpty ? '-' : fallback;
  }

  String? _referenceProviderLine(UserTransaction item) {
    final parts = <String>[];

    final reference = item.reference.trim();
    if (reference.isNotEmpty) {
      parts.add('Ref: $reference');
    }

    final provider = item.provider.trim();
    final providerRef = item.providerRef.trim();
    if (provider.isNotEmpty || providerRef.isNotEmpty) {
      final providerValue =
          [provider, providerRef].where((value) => value.isNotEmpty).join(' ');
      parts.add('Provider: $providerValue');
    }

    if (parts.isEmpty) {
      return null;
    }

    return parts.join(' | ');
  }

  String? _vehiclePlanLine(UserTransaction item) {
    final vehicleParts = <String>[];
    final vehicleName = item.vehicle?.name.trim() ?? '';
    final plate = item.vehicle?.plateNumber.trim() ?? '';
    final planName = (item.plan?.name.trim().isNotEmpty ?? false)
        ? item.plan!.name.trim()
        : (item.vehicle?.plan?.name.trim() ?? '');

    if (vehicleName.isNotEmpty) {
      vehicleParts.add(vehicleName);
    }
    if (plate.isNotEmpty) {
      vehicleParts.add(plate);
    }
    if (planName.isNotEmpty) {
      vehicleParts.add(planName);
    }

    if (vehicleParts.isEmpty) {
      return null;
    }

    return vehicleParts.join(' | ');
  }

  String _titleCaseWords(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty) {
      return normalized;
    }

    return normalized
        .split(RegExp(r'[\s_-]+'))
        .where((part) => part.isNotEmpty)
        .map((part) {
      final lower = part.toLowerCase();
      if (lower.length == 1) {
        return lower.toUpperCase();
      }
      return '${lower[0].toUpperCase()}${lower.substring(1)}';
    }).join(' ');
  }
}
