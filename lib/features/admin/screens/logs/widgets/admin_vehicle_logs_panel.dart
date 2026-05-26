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
import '../../../models/admin_logs_model.dart';
import '../widgets/admin_logs_filter_widgets.dart';
import '../widgets/admin_vehicle_event_detail_sheet.dart';
import '../widgets/admin_vehicle_event_log_card.dart';

class AdminVehicleLogsPanel extends ConsumerStatefulWidget {
  const AdminVehicleLogsPanel({super.key});

  @override
  ConsumerState<AdminVehicleLogsPanel> createState() =>
      _AdminVehicleLogsPanelState();
}

class _AdminVehicleLogsPanelState extends ConsumerState<AdminVehicleLogsPanel> {
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

    if (state.isLoadingVehicle && state.vehicleLogs.isEmpty) {
      return const OpenVtsLoader();
    }
    if (state.sectionErrorMessage != null && state.vehicleLogs.isEmpty) {
      return OpenVtsErrorView(
        message: state.sectionErrorMessage!,
        onRetry: controller.loadVehicleLogs,
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        OpenVtsSearchField(
          hintText: 'Search vehicle event logs...',
          onChanged: (v) {
            controller.setVehicleFilters(search: v);
            _debounce?.cancel();
            _debounce = Timer(const Duration(milliseconds: 350), () {
              unawaited(controller.loadVehicleLogs());
            });
          },
        ),
        const SizedBox(height: OpenVtsSpacing.sm),
        DropdownButtonFormField<String?>(
          initialValue: state.vehicleVehicleId,
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
            controller.setVehicleFilters(vehicleId: v);
            unawaited(controller.loadVehicleLogs());
          },
        ),
        const SizedBox(height: OpenVtsSpacing.sm),
        DropdownButtonFormField<String?>(
          initialValue: state.vehicleUserId,
          decoration: const InputDecoration(labelText: 'Recipient/User'),
          items: [
            const DropdownMenuItem<String?>(
                value: null, child: Text('All users')),
            ...state.options.users.map((u) => DropdownMenuItem<String?>(
                  value: u.uid,
                  child: Text(u.displayName, overflow: TextOverflow.ellipsis),
                )),
          ],
          onChanged: (v) {
            controller.setVehicleFilters(userId: v);
            unawaited(controller.loadVehicleLogs());
          },
        ),
        const SizedBox(height: OpenVtsSpacing.sm),
        DropdownButtonFormField<String>(
          initialValue:
              state.vehicleSource.isEmpty ? null : state.vehicleSource,
          decoration: const InputDecoration(labelText: 'Source'),
          items: [
            const DropdownMenuItem<String>(
                value: '', child: Text('All sources')),
            ...state.options.sources
                .map((s) => DropdownMenuItem<String>(value: s, child: Text(s))),
          ],
          onChanged: (v) {
            controller.setVehicleFilters(source: v ?? '');
            unawaited(controller.loadVehicleLogs());
          },
        ),
        const SizedBox(height: OpenVtsSpacing.sm),
        Wrap(
          spacing: OpenVtsSpacing.xs,
          runSpacing: OpenVtsSpacing.xs,
          children: [
            _chip('All', state.vehicleSeverity.isEmpty, () {
              controller.setVehicleFilters(severity: '');
              controller.loadVehicleLogs();
            }),
            _chip('INFO', state.vehicleSeverity == 'INFO', () {
              controller.setVehicleFilters(severity: 'INFO');
              controller.loadVehicleLogs();
            }),
            _chip('WARNING', state.vehicleSeverity == 'WARNING', () {
              controller.setVehicleFilters(severity: 'WARNING');
              controller.loadVehicleLogs();
            }),
            _chip('CRITICAL', state.vehicleSeverity == 'CRITICAL', () {
              controller.setVehicleFilters(severity: 'CRITICAL');
              controller.loadVehicleLogs();
            }),
          ],
        ),
        const SizedBox(height: OpenVtsSpacing.xs),
        Wrap(
          spacing: OpenVtsSpacing.xs,
          runSpacing: OpenVtsSpacing.xs,
          children: [
            _chip('All Read States',
                state.vehicleReadFilter == AdminReadFilter.all, () {
              controller.setVehicleFilters(readFilter: AdminReadFilter.all);
              controller.loadVehicleLogs();
            }),
            _chip('Read', state.vehicleReadFilter == AdminReadFilter.read, () {
              controller.setVehicleFilters(readFilter: AdminReadFilter.read);
              controller.loadVehicleLogs();
            }),
            _chip('Unread', state.vehicleReadFilter == AdminReadFilter.unread,
                () {
              controller.setVehicleFilters(readFilter: AdminReadFilter.unread);
              controller.loadVehicleLogs();
            }),
          ],
        ),
        const SizedBox(height: OpenVtsSpacing.sm),
        SwitchListTile.adaptive(
          dense: true,
          value: state.vehicleDedupe,
          contentPadding: EdgeInsets.zero,
          title: const Text('Dedupe duplicate events'),
          onChanged: (v) {
            controller.setVehicleFilters(dedupe: v);
            unawaited(controller.loadVehicleLogs());
          },
        ),
        OpenVtsDateTimeRangeField(
          label: 'Date range',
          title: 'Vehicle event date range',
          dateTimeEnabled: true,
          value: OpenVtsDateTimeRange(
              start: state.vehicleFrom, end: state.vehicleTo),
          onChanged: (range) {
            controller.setVehicleFilters(
              from: range.start,
              to: range.end,
              clearFrom: range.start == null,
              clearTo: range.end == null,
            );
            unawaited(controller.loadVehicleLogs());
          },
        ),
        const SizedBox(height: OpenVtsSpacing.sm),
        if (state.vehicleLogs.isEmpty)
          const OpenVtsEmptyState(
            title: 'No vehicle logs found',
            message: 'Try changing filters or search query.',
          )
        else ...[
          for (final item in state.vehicleLogs) ...[
            AdminVehicleEventLogCard(
              item: item,
              onTap: () => OpenVtsBottomSheet.show<void>(
                context: context,
                title: 'Vehicle Event Detail',
                initialChildSize: 0.85,
                minChildSize: 0.45,
                maxChildSize: 0.96,
                child:
                    AdminVehicleEventDetailSheet(id: item.id, fallback: item),
              ),
            ),
            if (item != state.vehicleLogs.last)
              const SizedBox(height: OpenVtsSpacing.sm),
          ],
          if ((state.vehicleNextCursorId ?? '').isNotEmpty) ...[
            const SizedBox(height: OpenVtsSpacing.sm),
            OpenVtsButton(
              label: 'Load More',
              height: 38,
              variant: OpenVtsButtonVariant.secondary,
              isLoading: state.isLoadingMoreVehicle,
              onPressed: state.isLoadingMoreVehicle
                  ? null
                  : controller.loadMoreVehicleLogs,
            ),
          ],
        ],
      ],
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    return AdminFilterChip(label: label, selected: selected, onTap: onTap);
  }
}
