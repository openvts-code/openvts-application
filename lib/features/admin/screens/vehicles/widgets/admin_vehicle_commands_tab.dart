import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../../../core/theme/open_vts_spacing.dart';
import '../../../../../shared/widgets/open_vts_bottom_sheet.dart';
import '../../../../../shared/widgets/open_vts_button.dart';
import '../../../../../shared/widgets/open_vts_card.dart';
import '../../../../../shared/widgets/open_vts_empty_state.dart';
import '../../../../../shared/widgets/open_vts_loader.dart';
import '../../../models/admin_vehicle_model.dart';

class AdminVehicleCommandsTab extends StatefulWidget {
  const AdminVehicleCommandsTab({
    super.key,
    required this.vehicle,
    required this.customCommands,
    required this.systemVariables,
    required this.history,
    required this.isLoading,
    required this.isSending,
    required this.onRefresh,
    required this.onSend,
    required this.onPollStatus,
    required this.onFetchCommandLog,
  });

  final AdminVehicleDetails vehicle;
  final List<AdminCustomCommand> customCommands;
  final List<AdminSystemVariable> systemVariables;
  final List<AdminVehicleCommandItem> history;
  final bool isLoading;
  final bool isSending;
  final Future<void> Function() onRefresh;
  final Future<void> Function({required String command, String? note}) onSend;
  final Future<AdminCommandStatus?> Function(String cmdId) onPollStatus;
  final Future<AdminVehicleCommandItem?> Function(String cmdId)
      onFetchCommandLog;

  @override
  State<AdminVehicleCommandsTab> createState() =>
      _AdminVehicleCommandsTabState();
}

class _AdminVehicleCommandsTabState extends State<AdminVehicleCommandsTab> {
  final TextEditingController _commandController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  String? _selectedTemplateId;
  String _latestStatus = '-';
  bool _polling = false;

  static const Set<String> _terminalStatuses = {
    'RESPONDED',
    'ENCODE_FAILED',
    'FAILED',
    'TIMEOUT',
    'ERROR',
  };

  @override
  void dispose() {
    _commandController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final imei = widget.vehicle.imei.trim();
    if (imei.isEmpty) {
      return const OpenVtsEmptyState(
        title: 'Command unavailable',
        message: 'IMEI is required to send commands.',
      );
    }

    return Column(
      children: [
        OpenVtsCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Target Vehicle',
                  style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: OpenVtsSpacing.xs),
              Text('Name: ${_safe(widget.vehicle.name)}'),
              Text('IMEI: ${_safe(widget.vehicle.imei)}'),
              Text('Plate: ${_safe(widget.vehicle.plateNumber)}'),
            ],
          ),
        ),
        const SizedBox(height: OpenVtsSpacing.sm),
        OpenVtsCard(
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                initialValue: _selectedTemplateId,
                hint: const Text('Select command template'),
                items: widget.customCommands
                    .map(
                      (item) => DropdownMenuItem<String>(
                        value: item.id,
                        child: Text(item.displayTitle),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (value) {
                  setState(() => _selectedTemplateId = value);
                  final selected = widget.customCommands
                      .where((item) => item.id == value)
                      .toList(growable: false);
                  if (selected.isNotEmpty) {
                    _commandController.text =
                        _resolveVariables(selected.first.command);
                  }
                },
              ),
              const SizedBox(height: OpenVtsSpacing.sm),
              TextField(
                controller: _commandController,
                maxLines: 3,
                maxLength: 500,
                decoration: const InputDecoration(
                  labelText: 'Command text',
                  hintText: 'Enter command',
                ),
              ),
              const SizedBox(height: OpenVtsSpacing.xs),
              TextField(
                controller: _noteController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Note (optional)',
                ),
              ),
              const SizedBox(height: OpenVtsSpacing.sm),
              OpenVtsButton(
                label: _polling ? 'Polling status...' : 'Send Command',
                isLoading: widget.isSending,
                onPressed: widget.isSending ? null : _send,
              ),
              const SizedBox(height: OpenVtsSpacing.xs),
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Latest status: $_latestStatus'),
              ),
            ],
          ),
        ),
        const SizedBox(height: OpenVtsSpacing.sm),
        if (widget.isLoading)
          const OpenVtsLoader()
        else if (widget.history.isEmpty)
          const OpenVtsEmptyState(
            title: 'No command history',
            message: 'Send a command to see history.',
          )
        else ...[
          ...widget.history.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: OpenVtsSpacing.sm),
              child: OpenVtsCard(
                onTap: () => _openHistoryDetails(item),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.command,
                        style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: OpenVtsSpacing.xxs),
                    Text('Status: ${item.status}'),
                    Text(
                        'Requested: ${_fmtDateTime(item.requestedAt ?? item.displayTime)}'),
                    Text(
                        'Response/Error: ${_safe(item.responseRaw ?? item.errorMessage ?? '-')}'),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _send() async {
    final command = _commandController.text.trim();
    if (command.isEmpty) {
      _toast('Command is required.');
      return;
    }
    if (command.length > 500) {
      _toast('Command must be 500 characters or less.');
      return;
    }

    await widget.onSend(
      command: command,
      note: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
    );
    await widget.onRefresh();

    final latest = widget.history.isEmpty ? null : widget.history.first;
    final cmdId = latest?.cmdId.trim() ?? '';
    if (cmdId.isNotEmpty) {
      _latestStatus = latest?.status ?? 'REQUESTED';
      setState(() {});
      unawaited(_startPolling(cmdId));
    }
  }

  Future<void> _startPolling(String cmdId) async {
    _polling = true;
    final deadline = DateTime.now().add(const Duration(seconds: 90));

    while (DateTime.now().isBefore(deadline)) {
      final status = await widget.onPollStatus(cmdId);
      final current = (status?.status ?? '').trim().toUpperCase();
      if (current.isNotEmpty) {
        _latestStatus = current;
        if (mounted) setState(() {});
      }
      if (_terminalStatuses.contains(current)) {
        break;
      }
      await Future<void>.delayed(const Duration(seconds: 3));
    }

    _polling = false;
    if (mounted) {
      setState(() {});
      await widget.onRefresh();
    }
  }

  Future<void> _openHistoryDetails(AdminVehicleCommandItem item) async {
    final cmdId = item.cmdId.trim();
    final loaded =
        cmdId.isEmpty ? item : (await widget.onFetchCommandLog(cmdId) ?? item);

    if (!mounted) return;
    await OpenVtsBottomSheet.show<void>(
      context: context,
      title: 'Command Details',
      initialChildSize: 0.82,
      minChildSize: 0.52,
      maxChildSize: 0.95,
      child: ListView(
        padding: const EdgeInsets.all(OpenVtsSpacing.md),
        children: [
          _line('CmdId', _safe(loaded.cmdId)),
          _line('Status', _safe(loaded.status)),
          _line('Command', _safe(loaded.command)),
          _line('IMEI', _safe(loaded.imei)),
          _line('Requested At', _fmtDateTime(loaded.requestedAt)),
          _line('Queued At', _fmtDateTime(loaded.queuedAt)),
          _line('Sent At', _fmtDateTime(loaded.sentAt)),
          _line('Responded At', _fmtDateTime(loaded.respondedAt)),
          _line('Failed At', _fmtDateTime(loaded.failedAt)),
          _line('Timeout At', _fmtDateTime(loaded.timeoutAt)),
          _line('Response Raw', _safe(loaded.responseRaw ?? '')),
          _line('Response Hex', _safe(loaded.responseHex ?? '')),
          _line('Error', _safe(loaded.errorMessage ?? '')),
          const SizedBox(height: OpenVtsSpacing.xs),
          Text('Metadata', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: OpenVtsSpacing.xs),
          SelectableText(
              const JsonEncoder.withIndent('  ').convert(loaded.metadata)),
        ],
      ),
    );
  }

  Widget _line(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text('$label: $value'),
      );

  String _resolveVariables(String template) {
    final map = <String, String>{
      'IMEI': widget.vehicle.imei,
      'LAT': _extractVehicleValue(['lat', 'latitude']),
      'LON': _extractVehicleValue(['lon', 'lng', 'longitude']),
      'SPEED': _extractVehicleValue(['speed']),
      'TIMESTAMP': DateTime.now().toUtc().toIso8601String(),
    };

    var text = template;
    for (final entry in map.entries) {
      text = text
          .replaceAll('{${entry.key}}', entry.value)
          .replaceAll('{{${entry.key}}}', entry.value)
          .replaceAll('{${entry.key.toLowerCase()}}', entry.value)
          .replaceAll('{{${entry.key.toLowerCase()}}}', entry.value);
    }
    return text;
  }

  String _extractVehicleValue(List<String> keys) {
    final meta = widget.vehicle.vehicleMeta;
    for (final key in keys) {
      final value =
          meta[key] ?? meta[key.toUpperCase()] ?? meta[key.toLowerCase()];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString().trim();
      }
    }
    return '';
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  String _safe(String value) => value.trim().isEmpty ? '-' : value.trim();

  String _fmtDateTime(DateTime? value) {
    if (value == null) return '-';
    final local = value.toLocal();
    final d =
        '${local.year.toString().padLeft(4, '0')}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
    final t =
        '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}:${local.second.toString().padLeft(2, '0')}';
    return '$d $t';
  }
}
