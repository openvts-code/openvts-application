import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../../../core/theme/open_vts_spacing.dart';
import '../../../../../shared/widgets/open_vts_bottom_sheet.dart';
import '../../../../../shared/widgets/open_vts_button.dart';
import '../../../../../shared/widgets/open_vts_card.dart';
import '../../../../../shared/widgets/open_vts_empty_state.dart';
import '../../../../../shared/widgets/open_vts_loader.dart';
import '../../../models/admin_vehicle_model.dart';

class AdminVehicleLogsTab extends StatefulWidget {
  const AdminVehicleLogsTab({
    super.key,
    required this.imei,
    required this.logs,
    required this.nextCursor,
    required this.isLoading,
    required this.isLoadingMore,
    required this.onLoad,
    required this.onLoadMore,
    required this.onApplyRange,
  });

  final String imei;
  final List<AdminVehicleLogItem> logs;
  final String? nextCursor;
  final bool isLoading;
  final bool isLoadingMore;
  final Future<void> Function() onLoad;
  final Future<void> Function() onLoadMore;
  final Future<void> Function(DateTime? from, DateTime? to) onApplyRange;

  @override
  State<AdminVehicleLogsTab> createState() => _AdminVehicleLogsTabState();
}

class _AdminVehicleLogsTabState extends State<AdminVehicleLogsTab> {
  DateTimeRange? _range;

  @override
  Widget build(BuildContext context) {
    if (widget.imei.trim().isEmpty) {
      return const OpenVtsEmptyState(
        title: 'IMEI missing',
        message: 'IMEI is required to load telemetry logs.',
      );
    }

    return Column(
      children: [
        OpenVtsCard(
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _range == null
                      ? 'All dates'
                      : '${_fmtDate(_range!.start)} → ${_fmtDate(_range!.end)}',
                ),
              ),
              IconButton(
                tooltip: 'Date range',
                onPressed: _pickRange,
                icon: const Icon(Icons.date_range_rounded),
              ),
              TextButton(
                onPressed: widget.onLoad,
                child: const Text('Reset'),
              ),
            ],
          ),
        ),
        const SizedBox(height: OpenVtsSpacing.sm),
        if (widget.isLoading)
          const OpenVtsLoader()
        else if (widget.logs.isEmpty)
          const OpenVtsEmptyState(
            title: 'No logs',
            message: 'No telemetry logs found.',
          )
        else ...[
          ...widget.logs.map(
            (log) => Padding(
              padding: const EdgeInsets.only(bottom: OpenVtsSpacing.sm),
              child: OpenVtsCard(
                onTap: () => _openDetails(log),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Time: ${_fmtDateTime(log.displayTime)}'),
                    Text('Packet: ${_safe(log.packetType)}'),
                    Text('Speed: ${_num(log.speedKph)}'),
                    Text(
                        'Ignition/ACC: ${_bool(log.ignition)}/${_bool(log.acc)}'),
                    Text(
                        'Lat/Lng: ${_coord(log.latitude)}, ${_coord(log.longitude)}'),
                  ],
                ),
              ),
            ),
          ),
          if ((widget.nextCursor ?? '').trim().isNotEmpty)
            OpenVtsButton(
              label: 'Load older',
              isLoading: widget.isLoadingMore,
              onPressed: widget.isLoadingMore ? null : widget.onLoadMore,
              variant: OpenVtsButtonVariant.secondary,
            ),
        ],
      ],
    );
  }

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final selected = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1),
      initialDateRange: _range,
    );
    if (selected == null) return;
    setState(() => _range = selected);
    await widget.onApplyRange(selected.start, selected.end);
  }

  Future<void> _openDetails(AdminVehicleLogItem log) {
    return OpenVtsBottomSheet.show<void>(
      context: context,
      title: 'Log Details',
      initialChildSize: 0.8,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      child: ListView(
        padding: const EdgeInsets.all(OpenVtsSpacing.md),
        children: [
          _line('ID', _safe(log.id)),
          _line('IMEI', _safe(log.imei)),
          _line('Time', _fmtDateTime(log.displayTime)),
          _line('Packet Type', _safe(log.packetType)),
          _line('Protocol', _safe(log.protocol)),
          _line('Speed', _num(log.speedKph)),
          _line('Course', _num(log.course)),
          _line('Ignition', _bool(log.ignition)),
          _line('ACC', _bool(log.acc)),
          _line('Latitude', _coord(log.latitude)),
          _line('Longitude', _coord(log.longitude)),
          _line('Altitude', _num(log.altitude)),
          _line('Satellites', log.satellites?.toString() ?? '-'),
          _line('Valid', _bool(log.valid)),
          _line('Odometer', _num(log.odometer)),
          _line('Distance', _num(log.distance)),
          _line('Engine Hours', _num(log.engineHours)),
          _line('Total Engine Hours', _num(log.totalEngineHours)),
          _line('Raw Packet', _safe(log.rawPacket)),
          const SizedBox(height: OpenVtsSpacing.sm),
          Text('Attributes', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: OpenVtsSpacing.xs),
          SelectableText(_json(log.attributes)),
        ],
      ),
    );
  }

  Widget _line(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text('$label: $value'),
      );

  String _json(Object? value) {
    if (value == null) return '{}';
    try {
      return const JsonEncoder.withIndent('  ').convert(value);
    } catch (_) {
      return value.toString();
    }
  }

  String _safe(String value) => value.trim().isEmpty ? '-' : value.trim();

  String _num(num? value) => value == null ? '-' : value.toStringAsFixed(2);

  String _coord(double? value) =>
      value == null ? '-' : value.toStringAsFixed(5);

  String _bool(bool? value) => value == null ? '-' : (value ? 'ON' : 'OFF');

  String _fmtDate(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';

  String _fmtDateTime(DateTime? value) {
    if (value == null) return '-';
    final local = value.toLocal();
    return '${_fmtDate(local)} ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }
}
