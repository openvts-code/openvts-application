import 'package:flutter/material.dart';

import '../../../../../core/theme/open_vts_spacing.dart';
import '../../../../../shared/widgets/open_vts_button.dart';
import '../../../../../shared/widgets/open_vts_card.dart';
import '../../../../../shared/widgets/open_vts_empty_state.dart';
import '../../../models/admin_vehicle_model.dart';

class AdminVehicleConfigTab extends StatefulWidget {
  const AdminVehicleConfigTab({
    super.key,
    required this.vehicle,
    required this.isSaving,
    required this.onSave,
  });

  final AdminVehicleDetails vehicle;
  final bool isSaving;
  final Future<void> Function(AdminVehicleConfigUpdateRequest request) onSave;

  @override
  State<AdminVehicleConfigTab> createState() => _AdminVehicleConfigTabState();
}

class _AdminVehicleConfigTabState extends State<AdminVehicleConfigTab> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _speedController;
  late final TextEditingController _distanceController;
  late final TextEditingController _odometerController;
  late final TextEditingController _engineHoursController;
  late String _ignitionSource;

  @override
  void initState() {
    super.initState();
    _speedController = TextEditingController(
      text: (widget.vehicle.device?.speedVariation ?? 0).toString(),
    );
    _distanceController = TextEditingController(
      text: (widget.vehicle.device?.distanceVariation ?? 0).toString(),
    );
    _odometerController = TextEditingController(
      text: (widget.vehicle.device?.odometer ?? 0).toString(),
    );
    _engineHoursController = TextEditingController(
      text: (widget.vehicle.device?.engineHours ?? 0).toString(),
    );
    final source =
        widget.vehicle.device?.ignitionSource.trim().toUpperCase() ?? 'ACC';
    _ignitionSource = source == 'MOTION' ? 'MOTION' : 'ACC';
  }

  @override
  void dispose() {
    _speedController.dispose();
    _distanceController.dispose();
    _odometerController.dispose();
    _engineHoursController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.vehicle.device == null) {
      return const OpenVtsEmptyState(
        title: 'No device',
        message: 'No device assigned to this vehicle.',
      );
    }

    return OpenVtsCard(
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            TextFormField(
              controller: _speedController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Speed Variation'),
              validator: (v) => _validateNonNegative(v, 'Speed variation'),
            ),
            const SizedBox(height: OpenVtsSpacing.sm),
            TextFormField(
              controller: _distanceController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration:
                  const InputDecoration(labelText: 'Distance Variation'),
              validator: (v) => _validateNonNegative(v, 'Distance variation'),
            ),
            const SizedBox(height: OpenVtsSpacing.sm),
            TextFormField(
              controller: _odometerController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Odometer'),
              validator: (v) => _validateNonNegative(v, 'Odometer'),
            ),
            const SizedBox(height: OpenVtsSpacing.sm),
            TextFormField(
              controller: _engineHoursController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Engine Hours'),
              validator: (v) => _validateNonNegative(v, 'Engine hours'),
            ),
            const SizedBox(height: OpenVtsSpacing.sm),
            DropdownButtonFormField<String>(
              initialValue: _ignitionSource,
              decoration: const InputDecoration(labelText: 'Ignition Source'),
              items: const [
                DropdownMenuItem(value: 'ACC', child: Text('ACC')),
                DropdownMenuItem(value: 'MOTION', child: Text('MOTION')),
              ],
              onChanged: (value) {
                if (value == null) return;
                setState(() => _ignitionSource = value);
              },
            ),
            const SizedBox(height: OpenVtsSpacing.md),
            Row(
              children: [
                Expanded(
                  child: OpenVtsButton(
                    label: 'Reset',
                    variant: OpenVtsButtonVariant.secondary,
                    onPressed: widget.isSaving ? null : _reset,
                  ),
                ),
                const SizedBox(width: OpenVtsSpacing.xs),
                Expanded(
                  child: OpenVtsButton(
                    label: 'Save Config',
                    isLoading: widget.isSaving,
                    onPressed: widget.isSaving ? null : _save,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String? _validateNonNegative(String? value, String label) {
    final parsed = double.tryParse((value ?? '').trim());
    if (parsed == null) return '$label is required';
    if (parsed < 0) return '$label must be >= 0';
    return null;
  }

  void _reset() {
    _speedController.text =
        (widget.vehicle.device?.speedVariation ?? 0).toString();
    _distanceController.text =
        (widget.vehicle.device?.distanceVariation ?? 0).toString();
    _odometerController.text =
        (widget.vehicle.device?.odometer ?? 0).toString();
    _engineHoursController.text =
        (widget.vehicle.device?.engineHours ?? 0).toString();
    _ignitionSource =
        (widget.vehicle.device?.ignitionSource.trim().toUpperCase() == 'MOTION')
            ? 'MOTION'
            : 'ACC';
    setState(() {});
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    await widget.onSave(
      AdminVehicleConfigUpdateRequest(
        speedVariation: double.parse(_speedController.text.trim()),
        distanceVariation: double.parse(_distanceController.text.trim()),
        odometer: double.parse(_odometerController.text.trim()),
        engineHours: double.parse(_engineHoursController.text.trim()),
        ignitionSource: _ignitionSource,
      ),
    );
  }
}
