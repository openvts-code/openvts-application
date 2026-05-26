import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/open_vts_colors.dart';
import '../../../../../core/theme/open_vts_radius.dart';
import '../../../../../core/theme/open_vts_spacing.dart';
import '../../../../../core/theme/open_vts_typography.dart';
import '../../../controllers/user_providers.dart';
import '../../../models/user_dashboard_model.dart';
import 'user_dashboard_widget_card.dart';

class UserSendCommandDashboardWidget extends ConsumerStatefulWidget {
  const UserSendCommandDashboardWidget({
    required this.config,
    required this.refreshTick,
    super.key,
  });

  final UserDashboardWidgetConfig config;
  final int refreshTick;

  @override
  ConsumerState<UserSendCommandDashboardWidget> createState() =>
      _UserSendCommandDashboardWidgetState();
}

class _UserSendCommandDashboardWidgetState
    extends ConsumerState<UserSendCommandDashboardWidget> {
  static const int _maxCommandLength = 500;

  late Future<_SendCommandData> _future;
  final TextEditingController _commandController = TextEditingController();
  String? _selectedVehicleId;
  String? _selectedCommandId;
  bool _isSending = false;
  Object? _sendError;
  UserDashboardSendCommandResult? _result;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void didUpdateWidget(covariant UserSendCommandDashboardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshTick != widget.refreshTick ||
        oldWidget.config.id != widget.config.id) {
      _reload();
    }
  }

  @override
  void dispose() {
    _commandController.dispose();
    super.dispose();
  }

  Future<_SendCommandData> _load() async {
    final service = ref.read(userDashboardServiceProvider);
    final results = await Future.wait<dynamic>([
      service.getVehicles(),
      service.getCustomCommands(),
      service.getSystemVariables(),
    ]);
    final allVehicles = results[0] as List<UserDashboardVehicleOption>;
    final operationalVehicles = allVehicles
        .where((vehicle) => !vehicle.isLicenseBlocked)
        .toList(growable: false);
    final commands = (results[1] as List<UserDashboardCustomCommand>)
        .where((command) => command.isActive)
        .toList(growable: false);
    final variables = (results[2] as List<UserDashboardSystemVariable>)
        .where((variable) => variable.isActive)
        .toList(growable: false);

    if (mounted) {
      _ensureSelection(
        operationalVehicles: operationalVehicles,
        commands: commands,
      );
    }

    return _SendCommandData(
      allVehicles: allVehicles,
      vehicles: operationalVehicles,
      commands: commands,
      variables: variables,
    );
  }

  void _ensureSelection({
    required List<UserDashboardVehicleOption> operationalVehicles,
    required List<UserDashboardCustomCommand> commands,
  }) {
    if (operationalVehicles.isEmpty) {
      _selectedVehicleId = null;
    } else if (_selectedVehicleId == null ||
        !operationalVehicles
            .any((vehicle) => vehicle.id == _selectedVehicleId)) {
      _selectedVehicleId = operationalVehicles.first.id;
    }

    if (commands.isEmpty) {
      _selectedCommandId = null;
      return;
    }

    final selectedCommandIsValid =
        commands.any((command) => command.id == _selectedCommandId);
    if (_selectedCommandId == null || !selectedCommandIsValid) {
      _selectedCommandId = commands.first.id;
      if (_commandController.text.trim().isEmpty) {
        _commandController.text = commands.first.command;
      }
    }
  }

  void _reload() {
    setState(() {
      _future = _load();
      _sendError = null;
    });
  }

  void _selectVehicle(String? value) {
    if (value == null || value == _selectedVehicleId) return;
    setState(() {
      _selectedVehicleId = value;
      _sendError = null;
      _result = null;
    });
  }

  void _selectCommand(String? value, _SendCommandData data) {
    if (value == null || value == _selectedCommandId) return;
    final selected = data.commands.where((command) => command.id == value);
    if (selected.isEmpty) return;

    setState(() {
      _selectedCommandId = value;
      _commandController.text = selected.first.command;
      _sendError = null;
      _result = null;
    });
  }

  Future<void> _send(_SendCommandData data) async {
    final vehicle = _selectedVehicle(data);
    final rawCommand = _commandController.text;
    final validationError = _validate(vehicle: vehicle, command: rawCommand);
    if (validationError != null) {
      setState(() => _sendError = validationError);
      return;
    }

    final defaults = _systemVariableDefaults(data.variables);
    final resolvedCommand = _resolveCommand(
      rawCommand.trim(),
      vehicle: vehicle!,
      defaults: defaults,
      now: DateTime.now(),
    );
    if (resolvedCommand.trim().isEmpty) {
      setState(() => _sendError = 'Command text is required.');
      return;
    }
    if (resolvedCommand.length > _maxCommandLength) {
      setState(
        () => _sendError =
            'Resolved command must be $_maxCommandLength characters or less.',
      );
      return;
    }
    final usesImei = _templateVariables(rawCommand).contains('IMEI');

    setState(() {
      _isSending = true;
      _sendError = null;
      _result = null;
    });

    try {
      final result =
          await ref.read(userDashboardServiceProvider).sendBulkCommand(
                mode: UserDashboardSendCommandMode.selected,
                command: usesImei ? null : resolvedCommand,
                vehicleIds: usesImei ? const <String>[] : <String>[vehicle.id],
                items: usesImei
                    ? <UserDashboardSendCommandItem>[
                        UserDashboardSendCommandItem(
                          vehicleId: vehicle.id,
                          command: resolvedCommand,
                        ),
                      ]
                    : const <UserDashboardSendCommandItem>[],
              );
      if (!mounted) return;
      setState(() => _result = result);
    } catch (error) {
      if (!mounted) return;
      setState(() => _sendError = error);
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  String? _validate({
    required UserDashboardVehicleOption? vehicle,
    required String command,
  }) {
    if (vehicle == null) {
      return 'Choose an operational vehicle before sending.';
    }
    if (vehicle.isLicenseBlocked) {
      return 'Software license required for the selected vehicle.';
    }
    final trimmedCommand = command.trim();
    if (trimmedCommand.isEmpty) {
      return 'Command text is required.';
    }
    if (trimmedCommand.length > _maxCommandLength) {
      return 'Command must be $_maxCommandLength characters or less.';
    }
    return null;
  }

  UserDashboardVehicleOption? _selectedVehicle(_SendCommandData data) {
    if (data.vehicles.isEmpty) return null;
    final selectedId = _selectedVehicleId;
    if (selectedId != null) {
      for (final vehicle in data.vehicles) {
        if (vehicle.id == selectedId) return vehicle;
      }
    }
    return data.vehicles.first;
  }

  UserDashboardCustomCommand? _selectedCommand(_SendCommandData data) {
    final selectedId = _selectedCommandId;
    if (selectedId != null) {
      for (final command in data.commands) {
        if (command.id == selectedId) return command;
      }
    }
    return data.commands.isEmpty ? null : data.commands.first;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_SendCommandData>(
      future: _future,
      builder: (context, snapshot) {
        final isLoading = snapshot.connectionState != ConnectionState.done;
        return UserDashboardWidgetCard(
          title: widget.config.title,
          icon: Icons.terminal_rounded,
          isLoading: isLoading || _isSending,
          onRefresh: _reload,
          child: _buildBody(snapshot),
        );
      },
    );
  }

  Widget _buildBody(AsyncSnapshot<_SendCommandData> snapshot) {
    if (snapshot.hasError) {
      return UserDashboardWidgetError(
        message: userDashboardErrorText(snapshot.error!),
        onRetry: _reload,
      );
    }

    final data = snapshot.data;
    if (data == null) {
      return const _SendCommandSkeleton();
    }

    final vehicle = _selectedVehicle(data);
    final selectedVehicleId = vehicle?.id;
    final selectedCommand = _selectedCommand(data);
    final selectedCommandId = selectedCommand?.id;
    final defaults = _systemVariableDefaults(data.variables);
    final commandText = _commandController.text;
    final detectedVariables =
        _templateVariables(commandText).toList(growable: false);
    final resolvedPreview = vehicle == null
        ? commandText.trim()
        : _resolveCommand(
            commandText.trim(),
            vehicle: vehicle,
            defaults: defaults,
            now: DateTime.now(),
          );
    final blockedCount = data.allVehicles.length - data.vehicles.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (data.vehicles.isEmpty)
          UserDashboardWidgetEmpty(
            message: blockedCount > 0
                ? 'No operational vehicles available.'
                : 'No vehicles available.',
            icon: Icons.no_transfer_rounded,
          )
        else ...[
          _VehicleSelector(
            vehicles: data.vehicles,
            value: selectedVehicleId,
            onChanged: _isSending ? null : _selectVehicle,
          ),
          if (blockedCount > 0) ...[
            const SizedBox(height: OpenVtsSpacing.xs),
            _CompactNotice(
              icon: Icons.lock_outline_rounded,
              text:
                  '$blockedCount blocked vehicle${blockedCount == 1 ? '' : 's'} excluded.',
            ),
          ],
          const SizedBox(height: OpenVtsSpacing.sm),
          _CommandSelector(
            commands: data.commands,
            value: selectedCommandId,
            onChanged:
                _isSending ? null : (value) => _selectCommand(value, data),
          ),
          const SizedBox(height: OpenVtsSpacing.sm),
          TextField(
            controller: _commandController,
            enabled: !_isSending,
            maxLength: _maxCommandLength,
            minLines: 2,
            maxLines: 3,
            style: OpenVtsTypography.body.copyWith(
              color: OpenVtsColors.textPrimary,
              fontFamily: 'monospace',
              fontWeight: FontWeight.w700,
            ),
            decoration: InputDecoration(
              labelText: 'Command Text',
              hintText: 'Type command payload',
              isDense: true,
              counterStyle: OpenVtsTypography.meta.copyWith(
                color: OpenVtsColors.textTertiary,
                fontSize: 10,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(OpenVtsRadius.md),
              ),
            ),
            onChanged: (_) {
              setState(() {
                _sendError = null;
                _result = null;
              });
            },
          ),
          const SizedBox(height: OpenVtsSpacing.xs),
          _VariablePreview(
            variables: detectedVariables,
            resolvedCommand: resolvedPreview,
            vehicle: vehicle,
            defaults: defaults,
          ),
          if (_sendError != null) ...[
            const SizedBox(height: OpenVtsSpacing.sm),
            UserDashboardWidgetError(
                message: userDashboardErrorText(_sendError!)),
          ],
          if (_result != null) ...[
            const SizedBox(height: OpenVtsSpacing.sm),
            _SendResultSummary(result: _result!),
          ],
          const SizedBox(height: OpenVtsSpacing.md),
          FilledButton.icon(
            onPressed: _isSending ? null : () => _send(data),
            icon: _isSending
                ? const SizedBox.square(
                    dimension: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send_rounded, size: 17),
            label: Text(_isSending ? 'Sending' : 'Send command'),
          ),
        ],
      ],
    );
  }
}

class _VehicleSelector extends StatelessWidget {
  const _VehicleSelector({
    required this.vehicles,
    required this.value,
    required this.onChanged,
  });

  final List<UserDashboardVehicleOption> vehicles;
  final String? value;
  final ValueChanged<String?>? onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      key: ValueKey(value),
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'Vehicle',
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: OpenVtsSpacing.sm,
          vertical: OpenVtsSpacing.xs,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(OpenVtsRadius.md),
          borderSide: const BorderSide(color: OpenVtsColors.border),
        ),
      ),
      items: [
        for (final vehicle in vehicles)
          DropdownMenuItem<String>(
            value: vehicle.id,
            child: Text(
              _vehicleLabel(vehicle),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
      onChanged: onChanged,
    );
  }
}

class _CommandSelector extends StatelessWidget {
  const _CommandSelector({
    required this.commands,
    required this.value,
    required this.onChanged,
  });

  final List<UserDashboardCustomCommand> commands;
  final String? value;
  final ValueChanged<String?>? onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      key: ValueKey(commands.isEmpty ? 'manual' : value),
      initialValue: commands.isEmpty ? null : value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'Custom Command',
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: OpenVtsSpacing.sm,
          vertical: OpenVtsSpacing.xs,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(OpenVtsRadius.md),
          borderSide: const BorderSide(color: OpenVtsColors.border),
        ),
      ),
      hint: const Text('Type manually'),
      items: [
        for (final command in commands)
          DropdownMenuItem<String>(
            value: command.id,
            child: Text(
              command.displayTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
      onChanged: commands.isEmpty ? null : onChanged,
    );
  }
}

class _VariablePreview extends StatelessWidget {
  const _VariablePreview({
    required this.variables,
    required this.resolvedCommand,
    required this.vehicle,
    required this.defaults,
  });

  final List<String> variables;
  final String resolvedCommand;
  final UserDashboardVehicleOption? vehicle;
  final Map<String, String> defaults;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(OpenVtsSpacing.sm),
      decoration: BoxDecoration(
        color: OpenVtsColors.surface,
        borderRadius: BorderRadius.circular(OpenVtsRadius.md),
        border: Border.all(color: OpenVtsColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.data_object_rounded,
                size: 15,
                color: OpenVtsColors.textSecondary,
              ),
              const SizedBox(width: OpenVtsSpacing.xs),
              Text(
                'Variable Preview',
                style: OpenVtsTypography.meta.copyWith(
                  color: OpenVtsColors.textSecondary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          if (variables.isNotEmpty) ...[
            const SizedBox(height: OpenVtsSpacing.xs),
            Wrap(
              spacing: OpenVtsSpacing.xs,
              runSpacing: OpenVtsSpacing.xs,
              children: [
                for (final variable in variables)
                  _VariableChip(
                    label: variable,
                    value: _variableValue(
                      variable,
                      vehicle: vehicle,
                      defaults: defaults,
                      now: DateTime.now(),
                    ),
                  ),
              ],
            ),
          ],
          if (resolvedCommand.trim().isNotEmpty) ...[
            const SizedBox(height: OpenVtsSpacing.xs),
            Text(
              resolvedCommand,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: OpenVtsTypography.meta.copyWith(
                color: OpenVtsColors.textPrimary,
                fontFamily: 'monospace',
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _VariableChip extends StatelessWidget {
  const _VariableChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: OpenVtsSpacing.xs,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: OpenVtsColors.surfaceElevated,
        borderRadius: BorderRadius.circular(OpenVtsRadius.pill),
        border: Border.all(color: OpenVtsColors.border),
      ),
      child: Text(
        '$label: ${value.isEmpty ? '-' : value}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: OpenVtsTypography.meta.copyWith(
          color: OpenVtsColors.textSecondary,
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _CompactNotice extends StatelessWidget {
  const _CompactNotice({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: OpenVtsColors.textTertiary),
        const SizedBox(width: OpenVtsSpacing.xs),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: OpenVtsTypography.meta.copyWith(
              color: OpenVtsColors.textTertiary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _SendResultSummary extends StatelessWidget {
  const _SendResultSummary({required this.result});

  final UserDashboardSendCommandResult result;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(OpenVtsSpacing.sm),
      decoration: BoxDecoration(
        color: OpenVtsColors.surface,
        borderRadius: BorderRadius.circular(OpenVtsRadius.md),
        border: Border.all(color: OpenVtsColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: UserDashboardMetricTile(
                  label: 'Sent',
                  value: userDashboardFormatNumber(result.sentNow),
                ),
              ),
              const SizedBox(width: OpenVtsSpacing.xs),
              Expanded(
                child: UserDashboardMetricTile(
                  label: 'Queued',
                  value: userDashboardFormatNumber(result.queued),
                ),
              ),
              const SizedBox(width: OpenVtsSpacing.xs),
              Expanded(
                child: UserDashboardMetricTile(
                  label: 'Failed',
                  value: userDashboardFormatNumber(result.invalid),
                ),
              ),
            ],
          ),
          if (result.results.isNotEmpty) ...[
            const SizedBox(height: OpenVtsSpacing.sm),
            for (var index = 0; index < result.results.length; index++) ...[
              _CommandResultRow(result: result.results[index]),
              if (index != result.results.length - 1)
                const Divider(height: OpenVtsSpacing.md),
            ],
          ],
        ],
      ),
    );
  }
}

class _CommandResultRow extends StatelessWidget {
  const _CommandResultRow({required this.result});

  final UserDashboardSendCommandItemResult result;

  @override
  Widget build(BuildContext context) {
    final failed = (result.error ?? '').trim().isNotEmpty;
    final queued = result.queued == true && !failed;
    final sent = result.connected == true && !failed;
    final statusLabel = failed
        ? 'Failed'
        : queued
            ? 'Queued'
            : sent
                ? 'Sent'
                : 'Requested';
    final statusColor = failed
        ? OpenVtsColors.error
        : queued
            ? OpenVtsColors.warning
            : sent
                ? OpenVtsColors.success
                : OpenVtsColors.textSecondary;
    final vehicleLabel = (result.vehicleName ?? '').trim().isNotEmpty
        ? result.vehicleName!
        : (result.plateNumber ?? '').trim().isNotEmpty
            ? result.plateNumber!
            : result.vehicleId ?? 'Vehicle';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                vehicleLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: OpenVtsTypography.label.copyWith(
                  color: OpenVtsColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                [
                  if ((result.imei ?? '').trim().isNotEmpty) result.imei,
                  if ((result.cmdId ?? '').trim().isNotEmpty) result.cmdId,
                  if (failed) result.error,
                ].whereType<String>().join(' - '),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: OpenVtsTypography.meta.copyWith(
                  color: failed
                      ? OpenVtsColors.error
                      : OpenVtsColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: OpenVtsSpacing.sm),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: OpenVtsSpacing.xs,
            vertical: 3,
          ),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(OpenVtsRadius.pill),
            border: Border.all(color: statusColor.withValues(alpha: 0.18)),
          ),
          child: Text(
            statusLabel,
            style: OpenVtsTypography.meta.copyWith(
              color: statusColor,
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _SendCommandSkeleton extends StatelessWidget {
  const _SendCommandSkeleton();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(height: 220);
  }
}

class _SendCommandData {
  const _SendCommandData({
    required this.allVehicles,
    required this.vehicles,
    required this.commands,
    required this.variables,
  });

  final List<UserDashboardVehicleOption> allVehicles;
  final List<UserDashboardVehicleOption> vehicles;
  final List<UserDashboardCustomCommand> commands;
  final List<UserDashboardSystemVariable> variables;
}

String _vehicleLabel(UserDashboardVehicleOption vehicle) {
  final plate = vehicle.plateNumber?.trim();
  if (plate != null && plate.isNotEmpty) {
    return '${vehicle.name} - $plate';
  }
  return vehicle.name;
}

Map<String, String> _systemVariableDefaults(
  List<UserDashboardSystemVariable> variables,
) {
  final defaults = <String, String>{};
  for (final variable in variables) {
    final value = variable.initialValue;
    defaults[variable.name.toUpperCase()] = value;
    defaults[variable.key.toUpperCase()] = value;
  }
  return defaults;
}

Set<String> _templateVariables(String template) {
  final detected = <String>{};
  final pattern = RegExp(
    r'\{\{\s*([A-Za-z_][A-Za-z0-9_]*)\s*\}\}|\{\s*([A-Za-z_][A-Za-z0-9_]*)\s*\}',
  );
  for (final match in pattern.allMatches(template)) {
    final variable = (match.group(1) ?? match.group(2) ?? '').toUpperCase();
    if (_supportedVariables.contains(variable)) {
      detected.add(variable);
    }
  }
  return detected;
}

String _resolveCommand(
  String template, {
  required UserDashboardVehicleOption vehicle,
  required Map<String, String> defaults,
  required DateTime now,
}) {
  var resolved = template;
  for (final variable in _supportedVariables) {
    final value = _variableValue(
      variable,
      vehicle: vehicle,
      defaults: defaults,
      now: now,
    );
    final escapedVariable = RegExp.escape(variable);
    final pattern = RegExp(
      '\\{\\{\\s*$escapedVariable\\s*\\}\\}|\\{\\s*$escapedVariable\\s*\\}',
      caseSensitive: false,
    );
    resolved = resolved.replaceAllMapped(pattern, (_) => value);
  }
  return resolved;
}

String _variableValue(
  String variable, {
  required UserDashboardVehicleOption? vehicle,
  required Map<String, String> defaults,
  required DateTime now,
}) {
  final normalized = variable.toUpperCase();
  return switch (normalized) {
    'IMEI' => (vehicle?.imei ?? defaults[normalized] ?? '').trim(),
    'TIMESTAMP' => now.toUtc().toIso8601String(),
    'LAT' || 'LON' || 'SPEED' => defaults[normalized] ?? '{$normalized}',
    _ => defaults[normalized] ?? '{$normalized}',
  };
}

const Set<String> _supportedVariables = <String>{
  'IMEI',
  'LAT',
  'LON',
  'SPEED',
  'TIMESTAMP',
};
