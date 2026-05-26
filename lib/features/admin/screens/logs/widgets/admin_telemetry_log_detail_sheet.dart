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

class AdminTelemetryLogDetailSheet extends ConsumerWidget {
  const AdminTelemetryLogDetailSheet({
    super.key,
    required this.id,
  });

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(adminLogsControllerProvider.notifier);
    return FutureBuilder<AdminTelemetryDetail>(
      future: controller.getTelemetryDetail(id),
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
        final d = snapshot.data?.item;
        if (d == null) {
          return const OpenVtsErrorView(message: 'No telemetry detail found');
        }
        return ListView(
          controller: PrimaryScrollController.maybeOf(context),
          padding: const EdgeInsets.all(OpenVtsSpacing.md),
          children: [
            _row('Packet Type', d.packetType),
            _row('Protocol', d.protocol),
            _row('Valid', d.valid == null ? '-' : (d.valid! ? 'Yes' : 'No')),
            _row('ID', d.id),
            _row('IMEI', d.imei),
            _row(
                'Server Time',
                d.serverTime == null
                    ? '-'
                    : _fmt.formatDateTime(d.serverTime!.toLocal())),
            _row(
                'Device Time',
                d.deviceTime == null
                    ? '-'
                    : _fmt.formatDateTime(d.deviceTime!.toLocal())),
            _row('Latitude', d.latitude?.toString() ?? '-'),
            _row('Longitude', d.longitude?.toString() ?? '-'),
            _row('Altitude', d.altitude?.toString() ?? '-'),
            _row('Speed Kph', d.speedKph?.toString() ?? '-'),
            _row('Course', d.course?.toString() ?? '-'),
            _row('Satellites', d.satellites?.toString() ?? '-'),
            _row('Ignition',
                d.ignition == null ? '-' : (d.ignition! ? 'On' : 'Off')),
            _row('ACC', d.acc == null ? '-' : (d.acc! ? 'On' : 'Off')),
            _row('Distance', d.distance?.toString() ?? '-'),
            _row('Engine Hours', d.engineHours?.toString() ?? '-'),
            _row('Odometer', d.odometer?.toString() ?? '-'),
            _row('Total Engine Hours', d.totalEngineHours?.toString() ?? '-'),
            _row(
                'Created At',
                d.createdAt == null
                    ? '-'
                    : _fmt.formatDateTime(d.createdAt!.toLocal())),
            const SizedBox(height: OpenVtsSpacing.sm),
            const Text('Attributes', style: OpenVtsTypography.label),
            const SizedBox(height: OpenVtsSpacing.xs),
            SelectableText(prettyJson(d.attributes),
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
            const SizedBox(height: OpenVtsSpacing.sm),
            const Text('Raw', style: OpenVtsTypography.label),
            const SizedBox(height: OpenVtsSpacing.xs),
            SelectableText(d.raw,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
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
            TextSpan(text: value.isEmpty ? '-' : value),
          ],
        ),
      ),
    );
  }
}
