import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/open_vts_spacing.dart';
import '../../../../../shared/widgets/open_vts_bottom_sheet.dart';
import '../../../../../shared/widgets/open_vts_button.dart';
import '../../../../../shared/widgets/open_vts_date_time_range_selector.dart';
import '../../../../../shared/widgets/open_vts_empty_state.dart';
import '../../../../../shared/widgets/open_vts_error_view.dart';
import '../../../../../shared/widgets/open_vts_loader.dart';
import '../../../../../shared/widgets/open_vts_search_field.dart';
import '../../../controllers/admin_providers.dart';
import '../widgets/admin_logs_filter_widgets.dart';
import '../widgets/admin_telemetry_log_card.dart';
import '../widgets/admin_telemetry_log_detail_sheet.dart';

class AdminTelemetryLogsPanel extends ConsumerStatefulWidget {
  const AdminTelemetryLogsPanel({super.key});

  @override
  ConsumerState<AdminTelemetryLogsPanel> createState() =>
      _AdminTelemetryLogsPanelState();
}

class _AdminTelemetryLogsPanelState
    extends ConsumerState<AdminTelemetryLogsPanel> {
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminLogsControllerProvider);
    final controller = ref.read(adminLogsControllerProvider.notifier);
    final vehicleMap = {
      for (final v in state.options.vehicles) v.imei: v.displayName
    };

    if (state.isLoadingTelemetry && state.telemetryLogs.isEmpty) {
      return const OpenVtsLoader();
    }
    if (state.sectionErrorMessage != null && state.telemetryLogs.isEmpty) {
      return OpenVtsErrorView(
        message: state.sectionErrorMessage!,
        onRetry: controller.loadTelemetryLogs,
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        DropdownButtonFormField<String?>(
          initialValue: state.telemetryVehicleId,
          decoration: const InputDecoration(labelText: 'Vehicle'),
          items: [
            const DropdownMenuItem<String?>(
                value: null, child: Text('All vehicles')),
            ...state.options.vehicles.map((v) => DropdownMenuItem<String?>(
                  value: v.id,
                  child: Text(v.displayName, overflow: TextOverflow.ellipsis),
                )),
          ],
          onChanged: (v) {
            controller.setTelemetryFilters(vehicleId: v, imeiSearch: '');
            unawaited(controller.loadTelemetryLogs());
          },
        ),
        const SizedBox(height: OpenVtsSpacing.sm),
        if ((state.telemetryVehicleId ?? '').isEmpty)
          OpenVtsSearchField(
            hintText: 'Search by IMEI...',
            onChanged: (v) {
              controller.setTelemetryFilters(imeiSearch: v);
              _debounce?.cancel();
              _debounce = Timer(const Duration(milliseconds: 350), () {
                unawaited(controller.loadTelemetryLogs());
              });
            },
          ),
        if ((state.telemetryVehicleId ?? '').isEmpty)
          const SizedBox(height: OpenVtsSpacing.sm),
        Wrap(
          spacing: OpenVtsSpacing.xs,
          runSpacing: OpenVtsSpacing.xs,
          children: [
            _chip('All', state.telemetryPacketType.isEmpty, () {
              controller.setTelemetryFilters(packetType: '');
              controller.loadTelemetryLogs();
            }),
            _chip('LOCATION', state.telemetryPacketType == 'LOCATION', () {
              controller.setTelemetryFilters(packetType: 'LOCATION');
              controller.loadTelemetryLogs();
            }),
            _chip('HISTORY', state.telemetryPacketType == 'HISTORY', () {
              controller.setTelemetryFilters(packetType: 'HISTORY');
              controller.loadTelemetryLogs();
            }),
            _chip('EVENT', state.telemetryPacketType == 'EVENT', () {
              controller.setTelemetryFilters(packetType: 'EVENT');
              controller.loadTelemetryLogs();
            }),
            _chip('UNKNOWN', state.telemetryPacketType == 'UNKNOWN', () {
              controller.setTelemetryFilters(packetType: 'UNKNOWN');
              controller.loadTelemetryLogs();
            }),
          ],
        ),
        const SizedBox(height: OpenVtsSpacing.sm),
        OpenVtsDateTimeRangeField(
          label: 'Date range',
          title: 'Telemetry date range',
          dateTimeEnabled: true,
          value: OpenVtsDateTimeRange(
              start: state.telemetryFrom, end: state.telemetryTo),
          onChanged: (range) {
            controller.setTelemetryFilters(
              from: range.start,
              to: range.end,
              clearFrom: range.start == null,
              clearTo: range.end == null,
            );
            unawaited(controller.loadTelemetryLogs());
          },
        ),
        const SizedBox(height: OpenVtsSpacing.sm),
        if (state.telemetryLogs.isEmpty)
          const OpenVtsEmptyState(
            title: 'No telemetry logs found',
            message: 'Try changing filters.',
          )
        else ...[
          for (final item in state.telemetryLogs) ...[
            AdminTelemetryLogCard(
              item: item,
              vehicleLabel: vehicleMap[item.imei] ?? '',
              onTap: () => OpenVtsBottomSheet.show<void>(
                context: context,
                title: 'Telemetry Detail',
                initialChildSize: 0.88,
                minChildSize: 0.5,
                maxChildSize: 0.96,
                child: AdminTelemetryLogDetailSheet(id: item.id),
              ),
            ),
            if (item != state.telemetryLogs.last)
              const SizedBox(height: OpenVtsSpacing.sm),
          ],
          if ((state.telemetryNextCursor ?? '').isNotEmpty) ...[
            const SizedBox(height: OpenVtsSpacing.sm),
            OpenVtsButton(
              label: 'Load More',
              height: 38,
              variant: OpenVtsButtonVariant.secondary,
              isLoading: state.isLoadingMoreTelemetry,
              onPressed: state.isLoadingMoreTelemetry
                  ? null
                  : controller.loadMoreTelemetryLogs,
            ),
          ],
        ]
      ],
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    return AdminFilterChip(label: label, selected: selected, onTap: onTap);
  }
}
