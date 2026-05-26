import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../../../core/theme/open_vts_spacing.dart';
import '../../../../../shared/widgets/open_vts_bottom_sheet.dart';
import '../../../../../shared/widgets/open_vts_button.dart';
import '../../../../../shared/widgets/open_vts_card.dart';
import '../../../../../shared/widgets/open_vts_empty_state.dart';
import '../../../../../shared/widgets/open_vts_loader.dart';
import '../../../models/admin_vehicle_model.dart';
import 'admin_vehicle_sensor_sheet.dart';

class AdminVehicleSensorsTab extends StatefulWidget {
  const AdminVehicleSensorsTab({
    super.key,
    required this.isLoading,
    required this.isCreating,
    required this.isUpdating,
    required this.isDeleting,
    required this.isRunning,
    required this.sensors,
    required this.onLoad,
    required this.onCreate,
    required this.onUpdate,
    required this.onDelete,
    required this.onRun,
  });

  final bool isLoading;
  final bool isCreating;
  final bool isUpdating;
  final bool isDeleting;
  final bool isRunning;
  final List<AdminVehicleSensor> sensors;
  final Future<void> Function({String? search}) onLoad;
  final Future<void> Function(AdminVehicleSensorUpsertRequest request) onCreate;
  final Future<void> Function(
      String sensorId, AdminVehicleSensorUpsertRequest request) onUpdate;
  final Future<void> Function(String sensorId) onDelete;
  final Future<void> Function(AdminVehicleSensorRunRequest request) onRun;

  @override
  State<AdminVehicleSensorsTab> createState() => _AdminVehicleSensorsTabState();
}

class _AdminVehicleSensorsTabState extends State<AdminVehicleSensorsTab> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        OpenVtsCard(
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        hintText: 'Search sensors...',
                        prefixIcon: Icon(Icons.search_rounded),
                      ),
                      onSubmitted: (value) =>
                          widget.onLoad(search: value.trim()),
                    ),
                  ),
                  const SizedBox(width: OpenVtsSpacing.xs),
                  OpenVtsButton(
                    label: 'Add Sensor',
                    variant: OpenVtsButtonVariant.secondary,
                    onPressed: _openCreateSheet,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: OpenVtsSpacing.sm),
        if (widget.isLoading)
          const OpenVtsLoader()
        else if (widget.sensors.isEmpty)
          const OpenVtsEmptyState(
            title: 'No sensors',
            message: 'Create a sensor for this vehicle.',
          )
        else
          ...widget.sensors.map(
            (sensor) => Padding(
              padding: const EdgeInsets.only(bottom: OpenVtsSpacing.sm),
              child: OpenVtsCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            sensor.name,
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                        ),
                        Text(sensor.isOk ? 'Active' : 'Inactive'),
                      ],
                    ),
                    const SizedBox(height: OpenVtsSpacing.xxs),
                    Text(
                        'Live Value: ${_safe(sensor.latestValue)} ${_safe(sensor.unit ?? '')}'),
                    Text('Status: ${_safe(sensor.status)}'),
                    Text(
                        'Code: ${_safe(sensor.sourceKey ?? sensor.expression ?? '')}'),
                    const SizedBox(height: OpenVtsSpacing.sm),
                    Wrap(
                      spacing: OpenVtsSpacing.xs,
                      runSpacing: OpenVtsSpacing.xs,
                      children: [
                        OutlinedButton(
                          onPressed: () => _openEditSheet(sensor),
                          child: const Text('Edit'),
                        ),
                        OutlinedButton(
                          onPressed: widget.isRunning
                              ? null
                              : () => _runSensor(sensor),
                          child: widget.isRunning
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Run'),
                        ),
                        OutlinedButton(
                          onPressed: widget.isDeleting
                              ? null
                              : () => _deleteSensor(sensor),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _openCreateSheet() {
    return OpenVtsBottomSheet.show<void>(
      context: context,
      title: 'Add Sensor',
      initialChildSize: 0.8,
      minChildSize: 0.5,
      maxChildSize: 0.94,
      child: AdminVehicleSensorSheet(
        isSubmitting: widget.isCreating,
        onSubmit: (request) async {
          await widget.onCreate(request);
          if (!mounted) return;
          await widget.onLoad();
          if (!mounted) return;
          Navigator.of(context).pop();
        },
      ),
    );
  }

  Future<void> _openEditSheet(AdminVehicleSensor sensor) {
    return OpenVtsBottomSheet.show<void>(
      context: context,
      title: 'Edit Sensor',
      initialChildSize: 0.8,
      minChildSize: 0.5,
      maxChildSize: 0.94,
      child: AdminVehicleSensorSheet(
        initial: sensor,
        isSubmitting: widget.isUpdating,
        onSubmit: (request) async {
          await widget.onUpdate(sensor.id, request);
          if (!mounted) return;
          await widget.onLoad();
          if (!mounted) return;
          Navigator.of(context).pop();
        },
      ),
    );
  }

  Future<void> _runSensor(AdminVehicleSensor sensor) async {
    final code = sensor.sourceKey?.trim().isNotEmpty == true
        ? sensor.sourceKey!.trim()
        : sensor.expression?.trim() ?? '';
    if (code.isEmpty) {
      _toast('Sensor code is required to run.');
      return;
    }

    await OpenVtsBottomSheet.show<void>(
      context: context,
      title: 'Run Sensor',
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      child: _RunSensorSheet(
        defaultCode: code,
        isRunning: widget.isRunning,
        onRun: (request) async {
          await widget.onRun(request);
          if (!mounted) return;
          Navigator.of(context).pop();
        },
      ),
    );
  }

  Future<void> _deleteSensor(AdminVehicleSensor sensor) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete sensor'),
        content: Text('Delete ${sensor.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await widget.onDelete(sensor.id);
    await widget.onLoad();
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  String _safe(String value) => value.trim().isEmpty ? '-' : value.trim();
}

class _RunSensorSheet extends StatefulWidget {
  const _RunSensorSheet({
    required this.defaultCode,
    required this.isRunning,
    required this.onRun,
  });

  final String defaultCode;
  final bool isRunning;
  final Future<void> Function(AdminVehicleSensorRunRequest request) onRun;

  @override
  State<_RunSensorSheet> createState() => _RunSensorSheetState();
}

class _RunSensorSheetState extends State<_RunSensorSheet> {
  late final TextEditingController _codeController;
  final TextEditingController _payloadController =
      TextEditingController(text: '{}');

  @override
  void initState() {
    super.initState();
    _codeController = TextEditingController(text: widget.defaultCode);
  }

  @override
  void dispose() {
    _codeController.dispose();
    _payloadController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(OpenVtsSpacing.md),
      children: [
        TextField(
          controller: _codeController,
          decoration: const InputDecoration(labelText: 'Code'),
        ),
        const SizedBox(height: OpenVtsSpacing.sm),
        TextField(
          controller: _payloadController,
          maxLines: 6,
          decoration: const InputDecoration(labelText: 'Payload JSON'),
        ),
        const SizedBox(height: OpenVtsSpacing.sm),
        OpenVtsButton(
          label: 'Run Sensor',
          isLoading: widget.isRunning,
          onPressed: widget.isRunning ? null : _submit,
        ),
      ],
    );
  }

  Future<void> _submit() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Code is required.')),
      );
      return;
    }

    Map<String, dynamic> payload = const <String, dynamic>{};
    final raw = _payloadController.text.trim();
    if (raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          payload = decoded;
        }
      } catch (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payload must be valid JSON object.')),
        );
        return;
      }
    }

    await widget
        .onRun(AdminVehicleSensorRunRequest(code: code, payload: payload));
  }
}
