import 'package:flutter/material.dart';

import '../../../../../core/theme/open_vts_spacing.dart';
import '../../../../../core/theme/open_vts_typography.dart';
import '../../../../../core/utils/date_time_formatter.dart';
import '../../../../../shared/widgets/open_vts_card.dart';
import '../../../../../shared/widgets/open_vts_status_chip.dart';
import '../../../models/admin_logs_model.dart';

const _fmt = DateTimeFormatter();

class AdminVehicleEventLogCard extends StatelessWidget {
  const AdminVehicleEventLogCard({
    super.key,
    required this.item,
    required this.onTap,
  });

  final AdminVehicleEventLogItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: OpenVtsCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: Text(item.title.isEmpty ? 'Vehicle Event' : item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: OpenVtsTypography.label
                      .copyWith(fontWeight: FontWeight.w700)),
            ),
            OpenVtsStatusChip(
              label: item.severity,
              type: item.severity == 'CRITICAL'
                  ? OpenVtsStatusType.error
                  : item.severity == 'WARNING'
                      ? OpenVtsStatusType.warning
                      : OpenVtsStatusType.info,
            ),
          ]),
          const SizedBox(height: OpenVtsSpacing.xxs),
          Text(item.message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: OpenVtsTypography.body.copyWith(fontSize: 13)),
          const SizedBox(height: OpenVtsSpacing.xs),
          Text(
              'Vehicle: ${item.vehicleName.isEmpty ? '-' : item.vehicleName} ${item.plateNumber.isEmpty ? '' : '(${item.plateNumber})'}',
              style: OpenVtsTypography.meta),
          Text(
              'Source: ${item.source.isEmpty ? '-' : item.source} • User: ${item.userName.isEmpty ? '-' : item.userName}',
              style: OpenVtsTypography.meta),
          Text('State: ${item.isRead ? 'Read' : 'Unread'}',
              style: OpenVtsTypography.meta),
          const SizedBox(height: OpenVtsSpacing.xxs),
          Text(
              item.createdAt == null
                  ? '-'
                  : _fmt.formatDateTime(item.createdAt!.toLocal()),
              style: OpenVtsTypography.meta),
        ]),
      ),
    );
  }
}
