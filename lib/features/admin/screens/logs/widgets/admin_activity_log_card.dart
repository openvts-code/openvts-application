import 'package:flutter/material.dart';

import '../../../../../core/theme/open_vts_colors.dart';
import '../../../../../core/theme/open_vts_spacing.dart';
import '../../../../../core/theme/open_vts_typography.dart';
import '../../../../../core/utils/date_time_formatter.dart';
import '../../../../../shared/widgets/open_vts_card.dart';
import '../../../models/admin_logs_model.dart';

const _fmt = DateTimeFormatter();

class AdminActivityLogCard extends StatelessWidget {
  const AdminActivityLogCard({
    super.key,
    required this.item,
    required this.onTap,
  });

  final AdminActivityLogItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: OpenVtsCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(item.humanAction,
              style: OpenVtsTypography.label
                  .copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: OpenVtsSpacing.xxs),
          Text(item.action,
              style: OpenVtsTypography.meta
                  .copyWith(color: OpenVtsColors.textSecondary)),
          const SizedBox(height: OpenVtsSpacing.xs),
          Text(
              'Entity: ${item.entity}${item.entityId.isEmpty ? '' : ' • ${item.entityId}'}',
              style: OpenVtsTypography.meta),
          const SizedBox(height: OpenVtsSpacing.xxs),
          Text(
              'By: ${item.actorDisplay}${item.userLoginType.isEmpty ? '' : ' • ${item.userLoginType}'}',
              style: OpenVtsTypography.meta),
          if (item.ip.isNotEmpty ||
              item.browser.isNotEmpty ||
              item.platform.isNotEmpty) ...[
            const SizedBox(height: OpenVtsSpacing.xxs),
            Text(
                'IP: ${item.ip.isEmpty ? '-' : item.ip}  •  ${item.browser.isEmpty ? '-' : item.browser}  •  ${item.platform.isEmpty ? '-' : item.platform}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: OpenVtsTypography.meta
                    .copyWith(color: OpenVtsColors.textSecondary)),
          ],
          const SizedBox(height: OpenVtsSpacing.xxs),
          Text(
              item.createdAt == null
                  ? '-'
                  : _fmt.formatDateTime(item.createdAt!.toLocal()),
              style: OpenVtsTypography.meta
                  .copyWith(color: OpenVtsColors.textSecondary)),
        ]),
      ),
    );
  }
}
