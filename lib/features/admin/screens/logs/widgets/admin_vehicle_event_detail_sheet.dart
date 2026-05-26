import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/open_vts_spacing.dart';
import '../../../../../core/theme/open_vts_typography.dart';
import '../../../../../core/utils/date_time_formatter.dart';
import '../../../../../shared/widgets/open_vts_error_view.dart';
import '../../../../../shared/widgets/open_vts_loader.dart';
import '../../../controllers/admin_providers.dart';
import '../../../models/admin_logs_model.dart';

const _fmt = DateTimeFormatter();

class AdminVehicleEventDetailSheet extends ConsumerWidget {
  const AdminVehicleEventDetailSheet({
    super.key,
    required this.id,
    required this.fallback,
  });

  final String id;
  final AdminVehicleEventLogItem fallback;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(adminLogsControllerProvider.notifier);
    return FutureBuilder<AdminVehicleEventDetail>(
      future: controller.getVehicleEventDetail(id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: OpenVtsLoader());
        }
        if (snapshot.hasError) {
          return OpenVtsErrorView(
            message: snapshot.error.toString().replaceFirst('Exception: ', ''),
            onRetry: () => (context as Element).markNeedsBuild(),
          );
        }

        final detail = snapshot.data;
        if (detail == null) {
          return const OpenVtsErrorView(message: 'No event detail found');
        }

        return ListView(
          controller: PrimaryScrollController.maybeOf(context),
          padding: const EdgeInsets.all(OpenVtsSpacing.md),
          children: [
            _row('Title', detail.title.isEmpty ? '-' : detail.title),
            _row(
                'Created',
                detail.createdAt == null
                    ? '-'
                    : _fmt.formatDateTime(detail.createdAt!.toLocal())),
            _row('Severity', fallback.severity),
            _row('Read', detail.isRead ? 'Read' : 'Unread'),
            _row('Source', detail.source.isEmpty ? '-' : detail.source),
            _row('Vehicle',
                detail.vehicleName.isEmpty ? '-' : detail.vehicleName),
            _row(
                'Plate', detail.plateNumber.isEmpty ? '-' : detail.plateNumber),
            _row('IMEI', detail.imei.isEmpty ? '-' : detail.imei),
            _row('User', detail.userName.isEmpty ? '-' : detail.userName),
            _row('Username',
                detail.userUsername.isEmpty ? '-' : detail.userUsername),
            const SizedBox(height: OpenVtsSpacing.sm),
            const Text('Message', style: OpenVtsTypography.label),
            const SizedBox(height: OpenVtsSpacing.xs),
            Text(detail.message.isEmpty ? '-' : detail.message,
                style: OpenVtsTypography.body.copyWith(fontSize: 13)),
            const SizedBox(height: OpenVtsSpacing.sm),
            const Text('Meta', style: OpenVtsTypography.label),
            const SizedBox(height: OpenVtsSpacing.xs),
            SelectableText(prettyJson(detail.meta),
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
            if (detail.deliveries.isNotEmpty) ...[
              const SizedBox(height: OpenVtsSpacing.sm),
              const Text('Deliveries', style: OpenVtsTypography.label),
              const SizedBox(height: OpenVtsSpacing.xs),
              for (final d in detail.deliveries)
                Padding(
                  padding: const EdgeInsets.only(bottom: OpenVtsSpacing.xs),
                  child: Text(
                    '${d.channel} • ${d.status} • sent ${d.sentAt == null ? '-' : _fmt.formatDateTime(d.sentAt!.toLocal())} • delivered ${d.deliveredAt == null ? '-' : _fmt.formatDateTime(d.deliveredAt!.toLocal())} • retry ${d.retryCount}${d.failureReason.isEmpty ? '' : ' • ${d.failureReason}'}',
                    style: OpenVtsTypography.meta,
                  ),
                ),
            ],
          ],
        );
      },
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
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}
