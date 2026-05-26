import 'package:flutter/material.dart';

import '../../../../../core/theme/open_vts_colors.dart';
import '../../../../../core/theme/open_vts_spacing.dart';
import '../../../../../core/theme/open_vts_typography.dart';
import '../../../../../core/utils/date_time_formatter.dart';
import '../../../../../shared/widgets/open_vts_card.dart';
import '../../../../../shared/widgets/open_vts_status_chip.dart';
import '../../../models/admin_payments_model.dart';

class AdminPaymentTransactionCard extends StatelessWidget {
  const AdminPaymentTransactionCard({
    required this.item,
    required this.onTap,
    super.key,
  });

  final AdminPaymentTransaction item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final formatter = const DateTimeFormatter();
    return OpenVtsCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.amountDisplay,
                  style: OpenVtsTypography.numeric.copyWith(fontSize: 20),
                ),
              ),
              OpenVtsStatusChip(
                label: item.status.label,
                type: item.status == AdminPaymentStatus.success
                    ? OpenVtsStatusType.success
                    : item.status == AdminPaymentStatus.pending
                        ? OpenVtsStatusType.warning
                        : OpenVtsStatusType.error,
              ),
            ],
          ),
          const SizedBox(height: OpenVtsSpacing.xs),
          _row(
              'Date',
              item.createdAt == null
                  ? item.createdAtRaw
                  : formatter.formatDateTime(item.createdAt!.toLocal())),
          _row('Mode', item.paymentMode.label),
          _row('Type', item.paymentType.isEmpty ? '-' : item.paymentType),
          _row('Reference', item.reference.isEmpty ? '-' : item.reference),
          _row('Provider', item.provider.isEmpty ? '-' : item.provider),
          _row('User', item.toUser?.displayName ?? '-'),
          _row(
              'Vehicle',
              item.vehicle['name']?.toString().trim().isNotEmpty == true
                  ? item.vehicle['name'].toString()
                  : (item.vehicle['plateNumber']?.toString() ?? '-')),
          _row('Recorded By', item.recordedBy?.displayName ?? '-'),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    final text = value.trim().isEmpty ? '-' : value.trim();
    return Padding(
      padding: const EdgeInsets.only(top: OpenVtsSpacing.xxs),
      child: Text(
        '$label: $text',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style:
            OpenVtsTypography.meta.copyWith(color: OpenVtsColors.textSecondary),
      ),
    );
  }
}
