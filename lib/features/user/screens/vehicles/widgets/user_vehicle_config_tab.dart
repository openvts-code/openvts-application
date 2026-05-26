import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/open_vts_colors.dart';
import '../../../../../core/theme/open_vts_radius.dart';
import '../../../../../core/theme/open_vts_spacing.dart';
import '../../../../../core/theme/open_vts_typography.dart';
import '../../../../../shared/helpers/toast_helper.dart';
import '../../../../../shared/widgets/open_vts_button.dart';
import '../../../../../shared/widgets/open_vts_card.dart';
import '../../../controllers/user_vehicle_details_controller.dart';
import '../../../models/user_vehicle_model.dart';
import '../../../models/user_vehicle_state.dart';

class UserVehicleConfigTabView extends ConsumerStatefulWidget {
  const UserVehicleConfigTabView({required this.provider, super.key});

  final AutoDisposeStateNotifierProvider<UserVehicleDetailsController,
      UserVehicleDetailsState> provider;

  @override
  ConsumerState<UserVehicleConfigTabView> createState() =>
      _UserVehicleConfigTabViewState();
}

class _UserVehicleConfigTabViewState
    extends ConsumerState<UserVehicleConfigTabView> {
  final _formKey = GlobalKey<FormState>();
  final _speedController = TextEditingController();
  final _distanceController = TextEditingController();
  final _odometerController = TextEditingController();
  final _engineHoursController = TextEditingController();

  _ConfigValues? _initialValues;
  String? _vehicleId;
  String _ignitionSource = 'ACC';
  var _isApplyingValues = false;

  @override
  void initState() {
    super.initState();
    for (final controller in _controllers) {
      controller.addListener(_handleFieldChanged);
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.removeListener(_handleFieldChanged);
    }
    _speedController.dispose();
    _distanceController.dispose();
    _odometerController.dispose();
    _engineHoursController.dispose();
    super.dispose();
  }

  List<TextEditingController> get _controllers => [
        _speedController,
        _distanceController,
        _odometerController,
        _engineHoursController,
      ];

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(widget.provider);
    final controller = ref.read(widget.provider.notifier);
    final vehicle = state.vehicle;

    if (vehicle == null) {
      return _StatusCard(
        isLoading: state.isLoadingVehicle,
        message: state.isLoadingVehicle
            ? 'Loading config'
            : state.sectionErrorMessage ?? 'Config could not be loaded.',
        onRetry: controller.loadVehicle,
      );
    }

    final device = vehicle.device;
    if (device == null) {
      return const _NoDeviceCard();
    }

    _syncFromDevice(vehicle.id, device);
    final isDirty = _isDirty;
    final isSaving = state.isSavingConfig;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _DeviceSummaryCard(device: device),
          const SizedBox(height: OpenVtsSpacing.sm),
          _NumberConfigCard(
            title: 'Speed Multiplier',
            helper: 'Default 1. Applied to speed calibration.',
            icon: Icons.speed_rounded,
            controller: _speedController,
            validator: _nonNegativeValidator('Speed multiplier'),
          ),
          const SizedBox(height: OpenVtsSpacing.sm),
          _NumberConfigCard(
            title: 'Distance Multiplier',
            helper: 'Default 1. Applied to distance calibration.',
            icon: Icons.route_outlined,
            controller: _distanceController,
            validator: _nonNegativeValidator('Distance multiplier'),
          ),
          const SizedBox(height: OpenVtsSpacing.sm),
          _NumberConfigCard(
            title: 'Set Odometer',
            helper: 'Seeded from live odometer when available.',
            icon: Icons.countertops_outlined,
            controller: _odometerController,
            validator: _nonNegativeValidator('Odometer'),
          ),
          const SizedBox(height: OpenVtsSpacing.sm),
          _NumberConfigCard(
            title: 'Set Engine Hours',
            helper: 'Seeded from live engine hours when available.',
            icon: Icons.timer_outlined,
            controller: _engineHoursController,
            validator: _nonNegativeValidator('Engine hours'),
          ),
          const SizedBox(height: OpenVtsSpacing.sm),
          _IgnitionSourceCard(
            value: _ignitionSource,
            onChanged: _changeIgnitionSource,
          ),
          if (state.sectionErrorMessage != null) ...[
            const SizedBox(height: OpenVtsSpacing.sm),
            _InlineError(message: state.sectionErrorMessage!),
          ],
          const SizedBox(height: OpenVtsSpacing.sm),
          _SaveBar(
            isDirty: isDirty,
            isSaving: isSaving,
            onReset: isSaving || !isDirty ? null : _reset,
            onSave: isSaving || !isDirty ? null : _save,
          ),
        ],
      ),
    );
  }

  void _handleFieldChanged() {
    if (_isApplyingValues || !mounted) return;
    setState(() {});
  }

  void _syncFromDevice(String vehicleId, UserVehicleDeviceMini device) {
    final nextValues = _ConfigValues.fromDevice(device);
    final initialValues = _initialValues;
    if (_vehicleId == vehicleId && initialValues != null) {
      if (_isDirty || nextValues.matches(initialValues)) return;
    }
    _vehicleId = vehicleId;
    _applyValues(nextValues, updateInitial: true);
  }

  void _applyValues(_ConfigValues values, {required bool updateInitial}) {
    _isApplyingValues = true;
    _speedController.text = _formatNumber(values.speedVariation);
    _distanceController.text = _formatNumber(values.distanceVariation);
    _odometerController.text = _formatNumber(values.odometer);
    _engineHoursController.text = _formatNumber(values.engineHours);
    _ignitionSource = values.ignitionSource;
    if (updateInitial) _initialValues = values;
    _isApplyingValues = false;
  }

  void _changeIgnitionSource(Set<String> selection) {
    final selected = selection.isEmpty ? null : selection.first;
    if (selected == null || selected == _ignitionSource) return;
    setState(() => _ignitionSource = selected);
  }

  bool get _isDirty {
    final initial = _initialValues;
    final current = _currentValues();
    if (initial == null || current == null) return true;
    return !current.matches(initial);
  }

  _ConfigValues? _currentValues() {
    final speed = _parseNonNegative(_speedController.text);
    final distance = _parseNonNegative(_distanceController.text);
    final odometer = _parseNonNegative(_odometerController.text);
    final engineHours = _parseNonNegative(_engineHoursController.text);
    if (speed == null ||
        distance == null ||
        odometer == null ||
        engineHours == null) {
      return null;
    }
    return _ConfigValues(
      speedVariation: speed,
      distanceVariation: distance,
      odometer: odometer,
      engineHours: engineHours,
      ignitionSource: _normalizedIgnitionSource(_ignitionSource),
    );
  }

  void _reset() {
    final initial = _initialValues;
    if (initial == null) return;
    FocusScope.of(context).unfocus();
    setState(() => _applyValues(initial, updateInitial: false));
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final values = _currentValues();
    if (values == null) return;

    final ok = await ref.read(widget.provider.notifier).updateConfig(
          UserVehicleConfigUpdateRequest(
            speedVariation: values.speedVariation,
            distanceVariation: values.distanceVariation,
            odometer: values.odometer,
            engineHours: values.engineHours,
            ignitionSource: values.ignitionSource,
          ),
        );
    if (!mounted) return;

    if (ok) {
      final refreshedDevice = ref.read(widget.provider).vehicle?.device;
      final refreshedValues = refreshedDevice == null
          ? values
          : _ConfigValues.fromDevice(refreshedDevice);
      setState(() => _applyValues(refreshedValues, updateInitial: true));
      ToastHelper.showSuccess('Config updated.', context: context);
      return;
    }

    ToastHelper.showError(
      ref.read(widget.provider).sectionErrorMessage ??
          'Unable to update config.',
      context: context,
    );
  }
}

class _DeviceSummaryCard extends StatelessWidget {
  const _DeviceSummaryCard({required this.device});

  final UserVehicleDeviceMini device;

  @override
  Widget build(BuildContext context) {
    return OpenVtsCard(
      padding: const EdgeInsets.all(OpenVtsSpacing.sm),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: OpenVtsColors.textPrimary.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(OpenVtsRadius.sm),
              border: Border.all(color: OpenVtsColors.border),
            ),
            child: const Icon(
              Icons.memory_outlined,
              size: 18,
              color: OpenVtsColors.textSecondary,
            ),
          ),
          const SizedBox(width: OpenVtsSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Device Config',
                  style: OpenVtsTypography.label.copyWith(
                    color: OpenVtsColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _joinParts([
                    device.imei.trim().isEmpty ? null : 'IMEI ${device.imei}',
                    device.id.trim().isEmpty ? null : 'ID ${device.id}',
                  ]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: OpenVtsTypography.meta.copyWith(
                    color: OpenVtsColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NumberConfigCard extends StatelessWidget {
  const _NumberConfigCard({
    required this.title,
    required this.helper,
    required this.icon,
    required this.controller,
    required this.validator,
  });

  final String title;
  final String helper;
  final IconData icon;
  final TextEditingController controller;
  final String? Function(String?) validator;

  @override
  Widget build(BuildContext context) {
    return OpenVtsCard(
      padding: const EdgeInsets.all(OpenVtsSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: OpenVtsColors.textSecondary),
          const SizedBox(width: OpenVtsSpacing.sm),
          Expanded(
            child: Column(
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
                  helper,
                  style: OpenVtsTypography.meta.copyWith(
                    color: OpenVtsColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: OpenVtsSpacing.xs),
                TextFormField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textInputAction: TextInputAction.next,
                  validator: validator,
                  decoration: const InputDecoration(isDense: true),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _IgnitionSourceCard extends StatelessWidget {
  const _IgnitionSourceCard({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<Set<String>> onChanged;

  @override
  Widget build(BuildContext context) {
    return OpenVtsCard(
      padding: const EdgeInsets.all(OpenVtsSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.key_rounded,
                size: 18,
                color: OpenVtsColors.textSecondary,
              ),
              const SizedBox(width: OpenVtsSpacing.sm),
              Text(
                'Ignition Source',
                style: OpenVtsTypography.label.copyWith(
                  color: OpenVtsColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            'ACC means wire/ACC. MOTION means motion fallback.',
            style: OpenVtsTypography.meta.copyWith(
              color: OpenVtsColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: OpenVtsSpacing.sm),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment<String>(value: 'ACC', label: Text('ACC')),
                ButtonSegment<String>(value: 'MOTION', label: Text('MOTION')),
              ],
              selected: {value},
              showSelectedIcon: false,
              style: ButtonStyle(
                visualDensity: VisualDensity.compact,
                textStyle: WidgetStatePropertyAll(
                  OpenVtsTypography.meta.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              onSelectionChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class _SaveBar extends StatelessWidget {
  const _SaveBar({
    required this.isDirty,
    required this.isSaving,
    required this.onReset,
    required this.onSave,
  });

  final bool isDirty;
  final bool isSaving;
  final VoidCallback? onReset;
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) {
    return OpenVtsCard(
      padding: const EdgeInsets.all(OpenVtsSpacing.sm),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: OpenVtsButton(
                label: 'Reset',
                height: 40,
                variant: OpenVtsButtonVariant.secondary,
                onPressed: onReset,
              ),
            ),
            const SizedBox(width: OpenVtsSpacing.sm),
            Expanded(
              child: OpenVtsButton(
                label: isDirty ? 'Save' : 'Saved',
                height: 40,
                isLoading: isSaving,
                trailingIcon: Icons.check_rounded,
                onPressed: onSave,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoDeviceCard extends StatelessWidget {
  const _NoDeviceCard();

  @override
  Widget build(BuildContext context) {
    return OpenVtsCard(
      padding: const EdgeInsets.all(OpenVtsSpacing.md),
      child: Row(
        children: [
          const Icon(
            Icons.memory_outlined,
            size: 18,
            color: OpenVtsColors.textSecondary,
          ),
          const SizedBox(width: OpenVtsSpacing.sm),
          Expanded(
            child: Text(
              'No device assigned to this vehicle.',
              style: OpenVtsTypography.meta.copyWith(
                color: OpenVtsColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.isLoading,
    required this.message,
    required this.onRetry,
  });

  final bool isLoading;
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return OpenVtsCard(
      padding: const EdgeInsets.all(OpenVtsSpacing.sm),
      child: isLoading
          ? Row(
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: OpenVtsSpacing.sm),
                Text(
                  message,
                  style: OpenVtsTypography.meta.copyWith(
                    color: OpenVtsColors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  message,
                  style: OpenVtsTypography.meta.copyWith(
                    color: OpenVtsColors.error,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: OpenVtsSpacing.sm),
                OpenVtsButton(
                  label: 'Retry',
                  height: 36,
                  variant: OpenVtsButtonVariant.secondary,
                  onPressed: onRetry,
                ),
              ],
            ),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(OpenVtsSpacing.sm),
      decoration: BoxDecoration(
        color: OpenVtsColors.error.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(OpenVtsRadius.sm),
        border: Border.all(color: OpenVtsColors.error.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 16,
            color: OpenVtsColors.error,
          ),
          const SizedBox(width: OpenVtsSpacing.xs),
          Expanded(
            child: Text(
              message,
              style: OpenVtsTypography.meta.copyWith(
                color: OpenVtsColors.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfigValues {
  const _ConfigValues({
    required this.speedVariation,
    required this.distanceVariation,
    required this.odometer,
    required this.engineHours,
    required this.ignitionSource,
  });

  final num speedVariation;
  final num distanceVariation;
  final num odometer;
  final num engineHours;
  final String ignitionSource;

  factory _ConfigValues.fromDevice(UserVehicleDeviceMini device) {
    return _ConfigValues(
      speedVariation: device.speedVariation ?? 1,
      distanceVariation: device.distanceVariation ?? 1,
      odometer: device.liveOdometer ?? device.odometer ?? 0,
      engineHours: device.liveEngineHours ?? device.engineHours ?? 0,
      ignitionSource: _normalizedIgnitionSource(device.ignitionSource),
    );
  }

  bool matches(_ConfigValues other) {
    return _numberEquals(speedVariation, other.speedVariation) &&
        _numberEquals(distanceVariation, other.distanceVariation) &&
        _numberEquals(odometer, other.odometer) &&
        _numberEquals(engineHours, other.engineHours) &&
        ignitionSource == other.ignitionSource;
  }
}

String? Function(String?) _nonNegativeValidator(String label) {
  return (value) {
    final normalized = value?.trim() ?? '';
    if (normalized.isEmpty) return '$label is required.';
    final parsed = num.tryParse(normalized);
    if (parsed == null) return 'Enter a valid number.';
    if (parsed < 0) return '$label must be 0 or greater.';
    return null;
  };
}

num? _parseNonNegative(String value) {
  final parsed = num.tryParse(value.trim());
  if (parsed == null || parsed < 0) return null;
  return parsed;
}

String _normalizedIgnitionSource(String? value) {
  final normalized = value?.trim().toUpperCase();
  if (normalized == 'MOTION') return 'MOTION';
  return 'ACC';
}

bool _numberEquals(num left, num right) {
  return (left.toDouble() - right.toDouble()).abs() < 0.0000001;
}

String _formatNumber(num value) {
  if (value == value.roundToDouble()) return value.toInt().toString();
  return value.toString();
}

String _joinParts(List<String?> parts) {
  final normalized = parts
      .map((item) => item?.trim() ?? '')
      .where((item) => item.isNotEmpty)
      .toList(growable: false);
  return normalized.isEmpty ? '-' : normalized.join(' - ');
}
