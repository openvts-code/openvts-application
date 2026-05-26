import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/open_vts_colors.dart';
import '../../../../../core/theme/open_vts_radius.dart';
import '../../../../../core/theme/open_vts_spacing.dart';
import '../../../../../core/theme/open_vts_typography.dart';
import '../../../../../shared/helpers/toast_helper.dart';
import '../../../../../shared/widgets/open_vts_button.dart';
import '../../../../../shared/widgets/open_vts_text_field.dart';
import '../../../controllers/user_vehicle_details_controller.dart';
import '../../../models/user_vehicle_model.dart';
import '../../../models/user_vehicle_state.dart';

class UserVehicleSensorSheet extends ConsumerStatefulWidget {
  const UserVehicleSensorSheet({
    required this.provider,
    this.sensor,
    super.key,
  });

  final AutoDisposeStateNotifierProvider<UserVehicleDetailsController,
      UserVehicleDetailsState> provider;
  final UserVehicleSensor? sensor;

  @override
  ConsumerState<UserVehicleSensorSheet> createState() =>
      _UserVehicleSensorSheetState();
}

class _UserVehicleSensorSheetState
    extends ConsumerState<UserVehicleSensorSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _unitController;
  late final TextEditingController _iconController;
  late final TextEditingController _codeController;

  UserVehicleSensorRunResult? _runResult;
  String? _runError;
  String? _runNote;

  @override
  void initState() {
    super.initState();
    final sensor = widget.sensor;
    _nameController = TextEditingController(text: sensor?.name ?? '');
    _unitController = TextEditingController(text: sensor?.unit ?? '');
    _iconController = TextEditingController(text: sensor?.icon ?? '');
    _codeController = TextEditingController(text: sensor?.code ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _unitController.dispose();
    _iconController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(widget.provider);
    final isEditing = widget.sensor != null;
    final isSaving = state.isCreatingSensor || state.isUpdatingSensor;
    final isRunning = state.isRunningSensor || state.isLoadingSensorTelemetry;

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          OpenVtsSpacing.md,
          OpenVtsSpacing.sm,
          OpenVtsSpacing.md,
          OpenVtsSpacing.xl,
        ),
        children: [
          _SectionLabel(
            title: isEditing ? 'Sensor Settings' : 'New Sensor',
            subtitle: 'Name and code are required.',
          ),
          const SizedBox(height: OpenVtsSpacing.sm),
          OpenVtsTextField(
            controller: _nameController,
            label: 'Name',
            textInputAction: TextInputAction.next,
            validator: (value) {
              final normalized = value?.trim() ?? '';
              if (normalized.length < 2) {
                return 'Name must be at least 2 characters.';
              }
              return null;
            },
          ),
          const SizedBox(height: OpenVtsSpacing.sm),
          Row(
            children: [
              Expanded(
                child: OpenVtsTextField(
                  controller: _unitController,
                  label: 'Unit',
                  hintText: 'km/h, C, V',
                  textInputAction: TextInputAction.next,
                ),
              ),
              const SizedBox(width: OpenVtsSpacing.sm),
              Expanded(
                child: OpenVtsTextField(
                  controller: _iconController,
                  label: 'Icon',
                  hintText: 'speed, fuel',
                  textInputAction: TextInputAction.next,
                ),
              ),
            ],
          ),
          const SizedBox(height: OpenVtsSpacing.sm),
          OpenVtsTextField(
            controller: _codeController,
            label: 'Code',
            maxLines: 7,
            keyboardType: TextInputType.multiline,
            textInputAction: TextInputAction.newline,
            validator: (value) {
              final normalized = value?.trim() ?? '';
              if (normalized.length < 5) {
                return 'Code must be at least 5 characters.';
              }
              return null;
            },
          ),
          const SizedBox(height: OpenVtsSpacing.md),
          Row(
            children: [
              Expanded(
                child: OpenVtsButton(
                  label: isSaving
                      ? 'Saving...'
                      : isEditing
                          ? 'Save Changes'
                          : 'Create Sensor',
                  height: 40,
                  onPressed: isSaving ? null : _submit,
                ),
              ),
              const SizedBox(width: OpenVtsSpacing.sm),
              Expanded(
                child: OpenVtsButton(
                  label: isRunning ? 'Running...' : 'Run',
                  height: 40,
                  variant: OpenVtsButtonVariant.secondary,
                  trailingIcon: Icons.play_arrow_rounded,
                  onPressed: isRunning ? null : _runSensor,
                ),
              ),
            ],
          ),
          if (state.sectionErrorMessage != null) ...[
            const SizedBox(height: OpenVtsSpacing.sm),
            _InlineMessage(
              message: state.sectionErrorMessage!,
              color: OpenVtsColors.error,
              icon: Icons.error_outline_rounded,
            ),
          ],
          if (_runNote != null) ...[
            const SizedBox(height: OpenVtsSpacing.sm),
            _InlineMessage(
              message: _runNote!,
              color: OpenVtsColors.warning,
              icon: Icons.info_outline_rounded,
            ),
          ],
          if (_runError != null) ...[
            const SizedBox(height: OpenVtsSpacing.sm),
            _InlineMessage(
              message: _runError!,
              color: OpenVtsColors.error,
              icon: Icons.error_outline_rounded,
            ),
          ],
          if (_runResult != null) ...[
            const SizedBox(height: OpenVtsSpacing.md),
            _RunResultCard(result: _runResult!),
          ],
        ],
      ),
    );
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final controller = ref.read(widget.provider.notifier);
    final ok = widget.sensor == null
        ? await controller.createSensor(
            name: _nameController.text.trim(),
            unit: _optionalText(_unitController.text),
            icon: _optionalText(_iconController.text),
            code: _codeController.text.trim(),
          )
        : await controller.updateSensor(
            sensorId: widget.sensor!.id,
            name: _nameController.text.trim(),
            unit: _optionalText(_unitController.text),
            icon: _optionalText(_iconController.text),
            code: _codeController.text.trim(),
          );
    if (!mounted) return;

    if (ok) {
      ToastHelper.showSuccess(
        widget.sensor == null ? 'Sensor created.' : 'Sensor updated.',
        context: context,
      );
      Navigator.of(context).pop();
      return;
    }

    ToastHelper.showError(
      ref.read(widget.provider).sectionErrorMessage ?? 'Unable to save sensor.',
      context: context,
    );
  }

  Future<void> _runSensor() async {
    FocusScope.of(context).unfocus();
    final code = _codeController.text.trim();
    if (code.length < 5) {
      setState(() {
        _runError = 'Code must be at least 5 characters.';
        _runNote = null;
        _runResult = null;
      });
      return;
    }

    setState(() {
      _runError = null;
      _runNote = null;
      _runResult = null;
    });

    final controller = ref.read(widget.provider.notifier);
    var telemetry = ref.read(widget.provider).telemetryPayload;
    telemetry ??= await controller.loadSensorTelemetry();
    final payload = telemetry?.payload ?? const <String, dynamic>{};

    if (payload.isEmpty && mounted) {
      setState(() {
        _runNote = 'Telemetry unavailable. Running with an empty payload.';
      });
    }

    final result = await controller.runSensor(code: code, payload: payload);
    if (!mounted) return;

    if (result == null) {
      setState(() {
        _runError = ref.read(widget.provider).sectionErrorMessage ??
            'Unable to run this sensor.';
      });
      return;
    }

    setState(() {
      _runResult = result;
      _runError = result.error;
    });
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: OpenVtsTypography.label.copyWith(
            color: OpenVtsColors.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: OpenVtsTypography.meta.copyWith(
            color: OpenVtsColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _RunResultCard extends StatelessWidget {
  const _RunResultCard({required this.result});

  final UserVehicleSensorRunResult result;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(OpenVtsSpacing.sm),
      decoration: BoxDecoration(
        color: OpenVtsColors.surface,
        borderRadius: BorderRadius.circular(OpenVtsRadius.sm),
        border: Border.all(color: OpenVtsColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Run Result',
            style: OpenVtsTypography.meta.copyWith(
              color: OpenVtsColors.textSecondary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: OpenVtsSpacing.xs),
          _ResultRow(label: 'Value', value: _formatValue(result.value)),
          if ((result.output ?? '').trim().isNotEmpty)
            _ResultRow(label: 'Output', value: result.output!.trim()),
          if ((result.error ?? '').trim().isNotEmpty)
            _ResultRow(
                label: 'Error', value: result.error!.trim(), isError: true),
        ],
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({
    required this.label,
    required this.value,
    this.isError = false,
  });

  final String label;
  final String value;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 56,
            child: Text(
              label,
              style: OpenVtsTypography.meta.copyWith(
                color: OpenVtsColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: OpenVtsTypography.meta.copyWith(
                color:
                    isError ? OpenVtsColors.error : OpenVtsColors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineMessage extends StatelessWidget {
  const _InlineMessage({
    required this.message,
    required this.color,
    required this.icon,
  });

  final String message;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(OpenVtsSpacing.sm),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(OpenVtsRadius.sm),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: OpenVtsSpacing.xs),
          Expanded(
            child: Text(
              message,
              style: OpenVtsTypography.meta.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String? _optionalText(String value) {
  final normalized = value.trim();
  return normalized.isEmpty ? null : normalized;
}

String _formatValue(Object? value) {
  if (value == null) return '-';
  return value.toString();
}
