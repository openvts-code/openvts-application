import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../../../core/theme/open_vts_spacing.dart';
import '../../../../../shared/widgets/open_vts_bottom_sheet.dart';
import '../../../../../shared/widgets/open_vts_button.dart';
import '../../../../../shared/widgets/open_vts_card.dart';
import '../../../../../shared/widgets/open_vts_empty_state.dart';
import '../../../../../shared/widgets/open_vts_loader.dart';
import '../../../models/admin_vehicle_model.dart';

class AdminVehicleEventsTab extends StatefulWidget {
  const AdminVehicleEventsTab({
    super.key,
    required this.imei,
    required this.events,
    required this.nextCursor,
    required this.isLoading,
    required this.isLoadingMore,
    required this.onLoad,
    required this.onLoadMore,
    required this.onApplyFilters,
  });

  final String imei;
  final List<AdminVehicleEventItem> events;
  final String? nextCursor;
  final bool isLoading;
  final bool isLoadingMore;
  final Future<void> Function() onLoad;
  final Future<void> Function() onLoadMore;
  final Future<void> Function({
    DateTime? from,
    DateTime? to,
    String? source,
    String? severity,
  }) onApplyFilters;

  @override
  State<AdminVehicleEventsTab> createState() => _AdminVehicleEventsTabState();
}

class _AdminVehicleEventsTabState extends State<AdminVehicleEventsTab> {
  DateTimeRange? _range;
  String _source = '';
  String _severity = '';

  @override
  Widget build(BuildContext context) {
    if (widget.imei.trim().isEmpty) {
      return const OpenVtsEmptyState(
        title: 'IMEI missing',
        message: 'IMEI is required to load vehicle events.',
      );
    }

    return Column(
      children: [
        OpenVtsCard(
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                initialValue: _source.isEmpty ? null : _source,
                hint: const Text('Source'),
                items: const [
                  DropdownMenuItem(value: '', child: Text('All sources')),
                  DropdownMenuItem(value: 'DEVICE', child: Text('DEVICE')),
                  DropdownMenuItem(value: 'SYSTEM', child: Text('SYSTEM')),
                  DropdownMenuItem(value: 'USER', child: Text('USER')),
                ],
                onChanged: (value) => setState(() => _source = value ?? ''),
              ),
              const SizedBox(height: OpenVtsSpacing.xs),
              DropdownButtonFormField<String>(
                initialValue: _severity.isEmpty ? null : _severity,
                hint: const Text('Severity'),
                items: const [
                  DropdownMenuItem(value: '', child: Text('All severity')),
                  DropdownMenuItem(value: 'LOW', child: Text('LOW')),
                  DropdownMenuItem(value: 'MEDIUM', child: Text('MEDIUM')),
                  DropdownMenuItem(value: 'HIGH', child: Text('HIGH')),
                  DropdownMenuItem(value: 'CRITICAL', child: Text('CRITICAL')),
                ],
                onChanged: (value) => setState(() => _severity = value ?? ''),
              ),
              const SizedBox(height: OpenVtsSpacing.xs),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _range == null
                          ? 'All dates'
                          : '${_fmtDate(_range!.start)} → ${_fmtDate(_range!.end)}',
                    ),
                  ),
                  IconButton(
                    onPressed: _pickRange,
                    icon: const Icon(Icons.date_range_rounded),
                  ),
                ],
              ),
              const SizedBox(height: OpenVtsSpacing.xs),
              Row(
                children: [
                  Expanded(
                    child: OpenVtsButton(
                      label: 'Apply Filters',
                      onPressed: _applyFilters,
                    ),
                  ),
                  const SizedBox(width: OpenVtsSpacing.xs),
                  Expanded(
                    child: OpenVtsButton(
                      label: 'Reset',
                      onPressed: _reset,
                      variant: OpenVtsButtonVariant.secondary,
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
        const SizedBox(height: OpenVtsSpacing.sm),
        if (widget.isLoading)
          const OpenVtsLoader()
        else if (widget.events.isEmpty)
          const OpenVtsEmptyState(
            title: 'No events',
            message: 'No events found for selected filters.',
          )
        else ...[
          ...widget.events.map(
            (event) => Padding(
              padding: const EdgeInsets.only(bottom: OpenVtsSpacing.sm),
              child: OpenVtsCard(
                onTap: () => _openDetails(event),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(event.title,
                        style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: OpenVtsSpacing.xxs),
                    Text('Severity: ${_safe(event.severity ?? '')}'),
                    Text('Source: ${_safe(event.category ?? '')}'),
                    Text('Message: ${_safe(event.message)}'),
                    Text('Created: ${_fmtDateTime(event.createdAt)}'),
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
  }

  Future<void> _applyFilters() {
    return widget.onApplyFilters(
      from: _range?.start,
      to: _range?.end,
      source: _source.trim().isEmpty ? null : _source.trim(),
      severity: _severity.trim().isEmpty ? null : _severity.trim(),
    );
  }

  Future<void> _reset() async {
    setState(() {
      _range = null;
      _source = '';
      _severity = '';
    });
    await widget.onLoad();
  }

  Future<void> _openDetails(AdminVehicleEventItem event) {
    return OpenVtsBottomSheet.show<void>(
      context: context,
      title: 'Event Details',
      initialChildSize: 0.8,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      child: ListView(
        padding: const EdgeInsets.all(OpenVtsSpacing.md),
        children: [
          _line('Title', event.title),
          _line('Category', _safe(event.category ?? '')),
          _line('Severity', _safe(event.severity ?? '')),
          _line('Source', _safe(event.category ?? '')),
          _line('Message', event.message),
          _line('Created At', _fmtDateTime(event.createdAt)),
          _line('Vehicle IMEI', _safe(event.vehicleImei ?? '')),
          _line('Context', _safe(event.contextLabel ?? '')),
          const SizedBox(height: OpenVtsSpacing.sm),
          Text('Metadata', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: OpenVtsSpacing.xs),
          SelectableText(_json(event.metadata)),
        ],
      ),
    );
  }

  Widget _line(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text('$label: ${_safe(value)}'),
      );

  String _json(Map<String, dynamic> value) {
    if (value.isEmpty) return '{}';
    return const JsonEncoder.withIndent('  ').convert(value);
  }

  String _safe(String value) => value.trim().isEmpty ? '-' : value.trim();

  String _fmtDate(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';

  String _fmtDateTime(DateTime? value) {
    if (value == null) return '-';
    final local = value.toLocal();
    return '${_fmtDate(local)} ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }
}
