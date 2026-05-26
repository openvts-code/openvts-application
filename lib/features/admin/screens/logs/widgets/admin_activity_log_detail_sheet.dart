import 'package:flutter/material.dart';

import '../../../../../core/theme/open_vts_spacing.dart';
import '../../../../../core/theme/open_vts_typography.dart';
import '../../../../../core/utils/date_time_formatter.dart';
import '../../../models/admin_logs_model.dart';

const _fmt = DateTimeFormatter();

class AdminActivityLogDetailSheet extends StatelessWidget {
  const AdminActivityLogDetailSheet({super.key, required this.item});

  final AdminActivityLogItem item;

  @override
  Widget build(BuildContext context) {
    return ListView(
      controller: PrimaryScrollController.maybeOf(context),
      padding: const EdgeInsets.all(OpenVtsSpacing.md),
      children: [
        _row('Action', item.humanAction),
        _row('Raw Action', item.action),
        _row(
            'Time',
            item.createdAt == null
                ? '-'
                : _fmt.formatDateTime(item.createdAt!.toLocal())),
        _row('Entity', item.entity),
        _row('Entity ID', item.entityId.isEmpty ? '-' : item.entityId),
        _row('Performed By', item.actorDisplay),
        _row('IP Address', item.ip.isEmpty ? '-' : item.ip),
        _row('Browser', item.browser.isEmpty ? '-' : item.browser),
        _row('Platform', item.platform.isEmpty ? '-' : item.platform),
        const SizedBox(height: OpenVtsSpacing.sm),
        const Text('Metadata', style: OpenVtsTypography.label),
        const SizedBox(height: OpenVtsSpacing.xs),
        SelectableText(
          prettyJson(item.meta),
          style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
        ),
      ],
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: OpenVtsSpacing.xs),
      child: RichText(
        text: TextSpan(
          style: OpenVtsTypography.body.copyWith(fontSize: 13),
          children: [
            TextSpan(text: '$label: ', style: OpenVtsTypography.label),
            TextSpan(text: value.isEmpty ? '-' : value),
          ],
        ),
      ),
    );
  }
}
