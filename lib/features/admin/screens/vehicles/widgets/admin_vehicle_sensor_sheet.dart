import 'package:flutter/material.dart';

import '../../../../../core/theme/open_vts_spacing.dart';
import '../../../../../shared/widgets/open_vts_button.dart';
import '../../../models/admin_vehicle_model.dart';

class AdminVehicleSensorSheet extends StatefulWidget {
  const AdminVehicleSensorSheet({
    super.key,
    this.initial,
    required this.isSubmitting,
    required this.onSubmit,
  });

  final AdminVehicleSensor? initial;
  final bool isSubmitting;
  final Future<void> Function(AdminVehicleSensorUpsertRequest request) onSubmit;

  @override
  State<AdminVehicleSensorSheet> createState() =>
      _AdminVehicleSensorSheetState();
}

class _AdminVehicleSensorSheetState extends State<AdminVehicleSensorSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _unitController;
  late final TextEditingController _iconController;
  late final TextEditingController _codeController;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _nameController = TextEditingController(text: initial?.name ?? '');
    _unitController = TextEditingController(text: initial?.unit ?? '');
    _iconController = TextEditingController(text: initial?.icon ?? '');
    _codeController = TextEditingController(
      text: initial?.sourceKey ?? initial?.expression ?? '',
    );
    _isActive = initial?.isOk ?? true;
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
    return ListView(
      padding: const EdgeInsets.all(OpenVtsSpacing.md),
      children: [
        Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (v) =>
                    (v ?? '').trim().isEmpty ? 'Name required' : null,
              ),
              const SizedBox(height: OpenVtsSpacing.sm),
              TextFormField(
                controller: _unitController,
                decoration: const InputDecoration(labelText: 'Unit'),
                validator: (v) =>
                    (v ?? '').trim().isEmpty ? 'Unit required' : null,
              ),
              const SizedBox(height: OpenVtsSpacing.sm),
              TextFormField(
                controller: _iconController,
                decoration: const InputDecoration(labelText: 'Icon'),
              ),
              const SizedBox(height: OpenVtsSpacing.sm),
              TextFormField(
                controller: _codeController,
                decoration: const InputDecoration(labelText: 'Code'),
                validator: (v) =>
                    (v ?? '').trim().isEmpty ? 'Code required' : null,
              ),
              const SizedBox(height: OpenVtsSpacing.sm),
              SwitchListTile(
                value: _isActive,
                onChanged: (value) => setState(() => _isActive = value),
                title: const Text('Active'),
              ),
              const SizedBox(height: OpenVtsSpacing.sm),
              OpenVtsButton(
                label: widget.initial == null ? 'Create Sensor' : 'Save Sensor',
                isLoading: widget.isSubmitting,
                onPressed: widget.isSubmitting ? null : _submit,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await widget.onSubmit(
      AdminVehicleSensorUpsertRequest(
        name: _nameController.text.trim(),
        unit: _unitController.text.trim(),
        icon: _iconController.text.trim(),
        code: _codeController.text.trim(),
        slug: _codeController.text.trim(),
        formula: _codeController.text.trim(),
        isActive: _isActive,
      ),
    );
  }
}
