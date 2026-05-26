import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../../../core/theme/open_vts_spacing.dart';
import '../../../../../core/utils/date_time_formatter.dart';
import '../../../../../shared/widgets/open_vts_card.dart';
import '../../../models/admin_payments_model.dart';

class AdminPaymentTransactionDetailsSheet extends StatelessWidget {
  const AdminPaymentTransactionDetailsSheet({required this.item, super.key});

  final AdminPaymentTransaction item;

  @override
  Widget build(BuildContext context) {
    final formatter = const DateTimeFormatter();
    final date = item.createdAt == null
        ? item.createdAtRaw
        : formatter.formatDateTime(item.createdAt!.toLocal());

    return ListView(
      controller: PrimaryScrollController.maybeOf(context),
      padding: const EdgeInsets.all(OpenVtsSpacing.md),
      children: [
        OpenVtsCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Transaction ID: ${item.id.isEmpty ? '-' : item.id}'),
              Text('Amount: ${item.amountDisplay}'),
              Text('Status: ${item.status.label}'),
              Text('Created: ${date.trim().isEmpty ? '-' : date}'),
              Text(
                  'Payment Type: ${item.paymentType.isEmpty ? '-' : item.paymentType}'),
              Text('Payment Mode: ${item.paymentMode.label}'),
              Text(
                  'Reference: ${item.reference.isEmpty ? '-' : item.reference}'),
              Text('Provider: ${item.provider.isEmpty ? '-' : item.provider}'),
              Text(
                  'Provider Ref: ${item.providerRef.isEmpty ? '-' : item.providerRef}'),
              Text('From: ${item.fromUser?.displayName ?? '-'}'),
              Text('To: ${item.toUser?.displayName ?? '-'}'),
              Text('Recorded By: ${item.recordedBy?.displayName ?? '-'}'),
              Text(
                  'Vehicle: ${item.vehicle['name']?.toString() ?? item.vehicle['plateNumber']?.toString() ?? '-'}'),
              Text(
                  'Failure Code: ${item.failureCode.isEmpty ? '-' : item.failureCode}'),
              Text(
                  'Failure Message: ${item.failureMessage.isEmpty ? '-' : item.failureMessage}'),
            ],
          ),
        ),
        if (item.meta.isNotEmpty) ...[
          const SizedBox(height: OpenVtsSpacing.sm),
          OpenVtsCard(
            child: SelectableText(
                const JsonEncoder.withIndent('  ').convert(item.meta)),
          ),
        ],
      ],
    );
  }
}
