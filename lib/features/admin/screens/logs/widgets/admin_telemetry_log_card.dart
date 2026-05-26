import 'package:flutter/material.dart';

import '../../../../../core/theme/open_vts_spacing.dart';
import '../../../../../core/theme/open_vts_typography.dart';
import '../../../../../core/utils/date_time_formatter.dart';
import '../../../../../shared/widgets/open_vts_card.dart';
import '../../../models/admin_logs_model.dart';

const _fmt = DateTimeFormatter();

class AdminTelemetryLogCard extends StatelessWidget {
  const AdminTelemetryLogCard({
    super.key,
    required this.item,
    required this.vehicleLabel,
    required this.onTap,
  });

  final AdminTelemetryLogItem item;
  final String vehicleLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final lat = item.latitude?.toStringAsFixed(5) ?? '-';
    final lng = item.longitude?.toStringAsFixed(5) ?? '-';
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: OpenVtsCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
              '${item.packetType} • ${vehicleLabel.isEmpty ? item.imei : vehicleLabel}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: OpenVtsTypography.label
                  .copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: OpenVtsSpacing.xxs),
          Text(
              'Server: ${item.serverTime == null ? '-' : _fmt.formatDateTime(item.serverTime!.toLocal())}',
              style: OpenVtsTypography.meta),
          Text(
              'Device: ${item.deviceTime == null ? '-' : _fmt.formatDateTime(item.deviceTime!.toLocal())}',
              style: OpenVtsTypography.meta),
          const SizedBox(height: OpenVtsSpacing.xxs),
          Text(
              'Speed: ${item.speedKph?.toStringAsFixed(1) ?? '-'} kph • Ignition: ${item.ignition == null ? '-' : (item.ignition! ? 'On' : 'Off')}',
              style: OpenVtsTypography.meta),
          Text('Lat/Lng: $lat, $lng', style: OpenVtsTypography.meta),
          if (item.distance != null || item.engineHours != null)
            Text(
                'Distance: ${item.distance?.toStringAsFixed(2) ?? '-'} • Engine Hrs: ${item.engineHours?.toStringAsFixed(2) ?? '-'}',
                style: OpenVtsTypography.meta),
          if (item.attributes.isNotEmpty)
            Text(
              prettyJson(item.attributes).replaceAll('\n', ' '),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: OpenVtsTypography.meta,
            ),
          if (item.raw.trim().isNotEmpty)
            Text(
              item.raw,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: OpenVtsTypography.meta,
            ),
        ]),
      ),
    );
  }
}
