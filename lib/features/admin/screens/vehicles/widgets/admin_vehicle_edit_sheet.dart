import 'package:flutter/material.dart';

import '../../../../../core/theme/open_vts_spacing.dart';
import '../../../../../shared/widgets/open_vts_button.dart';
import '../../../models/admin_vehicle_model.dart';

class AdminVehicleEditSheet extends StatefulWidget {
  const AdminVehicleEditSheet({
    super.key,
    required this.vehicle,
    required this.vehicleTypes,
    required this.timezones,
    required this.isSubmitting,
    required this.onSubmit,
  });

  final AdminVehicleDetails vehicle;
  final List<AdminVehicleTypeOption> vehicleTypes;
  final List<String> timezones;
  final bool isSubmitting;
  final Future<void> Function(AdminUpdateVehicleRequest request) onSubmit;

  @override
  State<AdminVehicleEditSheet> createState() => _AdminVehicleEditSheetState();
}

class _AdminVehicleEditSheetState extends State<AdminVehicleEditSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _plateController;
  late final TextEditingController _vinController;

  late String _vehicleTypeId;
  String _gmtOffset = '';
  late final List<_MetaRow> _metaRows;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.vehicle.name);
    _plateController = TextEditingController(text: widget.vehicle.plateNumber);
    _vinController = TextEditingController(text: widget.vehicle.vin);
    _vehicleTypeId = widget.vehicle.vehicleTypeId;
    _gmtOffset = widget.vehicle.gmtOffset;
    _metaRows = widget.vehicle.vehicleMeta.entries
        .map((entry) =>
            _MetaRow(keyText: entry.key, valueText: '${entry.value ?? ''}'))
        .toList(growable: true);
    if (_metaRows.isEmpty) {
      _metaRows.add(const _MetaRow(keyText: '', valueText: ''));
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _plateController.dispose();
    _vinController.dispose();
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
                validator: (value) =>
                    (value ?? '').trim().isEmpty ? 'Name is required' : null,
              ),
              const SizedBox(height: OpenVtsSpacing.sm),
              TextFormField(
                controller: _plateController,
                decoration: const InputDecoration(labelText: 'Plate Number'),
              ),
              const SizedBox(height: OpenVtsSpacing.sm),
              TextFormField(
                controller: _vinController,
                decoration: const InputDecoration(labelText: 'VIN'),
              ),
              const SizedBox(height: OpenVtsSpacing.sm),
              DropdownButtonFormField<String>(
                initialValue: _vehicleTypeId.isEmpty ? null : _vehicleTypeId,
                decoration: const InputDecoration(labelText: 'Vehicle Type'),
                items: widget.vehicleTypes
                    .map((item) => DropdownMenuItem<String>(
                          value: item.id,
                          child: Text(item.name),
                        ))
                    .toList(growable: false),
                onChanged: (value) =>
                    setState(() => _vehicleTypeId = value ?? ''),
              ),
              const SizedBox(height: OpenVtsSpacing.sm),
              DropdownButtonFormField<String>(
                initialValue: _gmtOffset.isEmpty ? null : _gmtOffset,
                decoration: const InputDecoration(labelText: 'GMT Offset'),
                items: widget.timezones
                    .map((item) => DropdownMenuItem<String>(
                        value: item, child: Text(item)))
                    .toList(growable: false),
                onChanged: (value) => setState(() => _gmtOffset = value ?? ''),
              ),
              const SizedBox(height: OpenVtsSpacing.md),
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Vehicle Meta',
                    style: Theme.of(context).textTheme.titleSmall),
              ),
              const SizedBox(height: OpenVtsSpacing.xs),
              ..._metaRows.asMap().entries.map((entry) {
                final idx = entry.key;
                final row = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: OpenVtsSpacing.xs),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          initialValue: row.keyText,
                          decoration: const InputDecoration(labelText: 'Key'),
                          onChanged: (value) => _metaRows[idx] =
                              _metaRows[idx].copyWith(keyText: value),
                        ),
                      ),
                      const SizedBox(width: OpenVtsSpacing.xs),
                      Expanded(
                        child: TextFormField(
                          initialValue: row.valueText,
                          decoration: const InputDecoration(labelText: 'Value'),
                          onChanged: (value) => _metaRows[idx] =
                              _metaRows[idx].copyWith(valueText: value),
                        ),
                      ),
                      IconButton(
                        onPressed: _metaRows.length <= 1
                            ? null
                            : () => setState(() => _metaRows.removeAt(idx)),
                        icon: const Icon(Icons.remove_circle_outline_rounded),
                      )
                    ],
                  ),
                );
              }),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => setState(() => _metaRows
                      .add(const _MetaRow(keyText: '', valueText: ''))),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Add Meta Row'),
                ),
              ),
              const SizedBox(height: OpenVtsSpacing.sm),
              OpenVtsButton(
                label: 'Save Changes',
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
    if (_gmtOffset.trim().isNotEmpty &&
        !RegExp(r'^[+-](0\d|1\d|2[0-3]):[0-5]\d$')
            .hasMatch(_gmtOffset.trim())) {
      _show('Invalid GMT offset format. Use +05:30');
      return;
    }

    final meta = <String, dynamic>{};
    final keys = <String>{};
    for (final row in _metaRows) {
      final key = row.keyText.trim();
      final value = row.valueText.trim();
      if (key.isEmpty) continue;
      if (!keys.add(key.toLowerCase())) {
        _show('Meta keys must be unique.');
        return;
      }
      meta[key] = value;
    }

    final parsedTypeId = int.tryParse(_vehicleTypeId.trim());
    if (parsedTypeId == null || parsedTypeId <= 0) {
      _show('Vehicle type is required.');
      return;
    }

    await widget.onSubmit(
      AdminUpdateVehicleRequest(
        name: _nameController.text.trim(),
        vin: _vinController.text.trim(),
        plateNumber: _plateController.text.trim(),
        vehicleTypeId: parsedTypeId,
        gmtOffset: _gmtOffset.trim(),
        isActive: widget.vehicle.isActive,
        vehicleMeta: meta,
      ),
    );
  }

  void _show(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}

class _MetaRow {
  const _MetaRow({required this.keyText, required this.valueText});

  final String keyText;
  final String valueText;

  _MetaRow copyWith({String? keyText, String? valueText}) {
    return _MetaRow(
      keyText: keyText ?? this.keyText,
      valueText: valueText ?? this.valueText,
    );
  }
}
