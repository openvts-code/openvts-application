import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/open_vts_colors.dart';
import '../../../../../core/theme/open_vts_radius.dart';
import '../../../../../core/theme/open_vts_spacing.dart';
import '../../../../../core/theme/open_vts_typography.dart';
import '../../../../../shared/helpers/toast_helper.dart';
import '../../../../../shared/widgets/open_vts_button.dart';
import '../../../../../shared/widgets/open_vts_card.dart';
import '../../../../../shared/widgets/open_vts_text_field.dart';
import '../../../controllers/user_vehicle_details_controller.dart';
import '../../../models/user_vehicle_model.dart';
import '../../../models/user_vehicle_state.dart';

final RegExp _gmtOffsetPattern = RegExp(r'^[+-]\d{2}:[0-5]\d$');

class UserVehicleEditSheet extends ConsumerStatefulWidget {
  const UserVehicleEditSheet({
    required this.provider,
    required this.vehicle,
    super.key,
  });

  final AutoDisposeStateNotifierProvider<UserVehicleDetailsController,
      UserVehicleDetailsState> provider;
  final UserVehicleDetails vehicle;

  @override
  ConsumerState<UserVehicleEditSheet> createState() =>
      _UserVehicleEditSheetState();
}

class _UserVehicleEditSheetState extends ConsumerState<UserVehicleEditSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _plateController = TextEditingController();
  final _vinController = TextEditingController();
  final List<_MetaRowController> _metaRows = <_MetaRowController>[];

  String? _vehicleTypeId;
  String? _gmtOffset;

  @override
  void initState() {
    super.initState();
    final vehicle = widget.vehicle;
    _nameController.text = vehicle.name;
    _plateController.text = vehicle.plateNumber;
    _vinController.text = vehicle.vin;
    _vehicleTypeId = _blankToNull(vehicle.vehicleType?.id);
    _gmtOffset = _blankToNull(vehicle.gmtOffset);
    if (vehicle.vehicleMeta.isEmpty) {
      _metaRows.add(_MetaRowController());
    } else {
      for (final entry in vehicle.vehicleMeta.entries) {
        _metaRows.add(
          _MetaRowController(
            keyText: entry.key,
            valueText: entry.value?.toString() ?? '',
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _plateController.dispose();
    _vinController.dispose();
    for (final row in _metaRows) {
      row.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(widget.provider);
    final isSubmitting = state.isSavingVehicle;
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            controller: PrimaryScrollController.maybeOf(context),
            padding: const EdgeInsets.all(OpenVtsSpacing.md),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  OpenVtsTextField(
                    label: 'Name',
                    controller: _nameController,
                    hintText: 'Vehicle name',
                    prefixIcon: Icons.directions_car_filled_outlined,
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      if ((value?.trim() ?? '').isEmpty) {
                        return 'Name is required.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: OpenVtsSpacing.sm),
                  OpenVtsTextField(
                    label: 'Plate Number',
                    controller: _plateController,
                    hintText: 'Plate number',
                    prefixIcon: Icons.confirmation_number_outlined,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: OpenVtsSpacing.sm),
                  OpenVtsTextField(
                    label: 'VIN',
                    controller: _vinController,
                    hintText: 'VIN',
                    prefixIcon: Icons.tag_outlined,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: OpenVtsSpacing.sm),
                  _VehicleTypeField(
                    value: _vehicleTypeId,
                    types: state.vehicleTypes,
                    isLoading: state.isLoadingReferenceData,
                    onChanged: (value) =>
                        setState(() => _vehicleTypeId = value),
                  ),
                  const SizedBox(height: OpenVtsSpacing.sm),
                  _TimezoneField(
                    value: _gmtOffset,
                    timezones: state.timezones,
                    isLoading: state.isLoadingReferenceData,
                    onChanged: (value) => setState(() => _gmtOffset = value),
                  ),
                  const SizedBox(height: OpenVtsSpacing.sm),
                  _MetaRowsEditor(
                    rows: _metaRows,
                    onAdd: _addMetaRow,
                    onRemove: _removeMetaRow,
                    validateKey: _validateMetaKey,
                  ),
                ],
              ),
            ),
          ),
        ),
        const Divider(height: 1),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(OpenVtsSpacing.md),
            child: Row(
              children: [
                Expanded(
                  child: OpenVtsButton(
                    label: 'Cancel',
                    height: 40,
                    variant: OpenVtsButtonVariant.secondary,
                    onPressed:
                        isSubmitting ? null : () => Navigator.of(context).pop(),
                  ),
                ),
                const SizedBox(width: OpenVtsSpacing.sm),
                Expanded(
                  child: OpenVtsButton(
                    label: 'Save',
                    height: 40,
                    trailingIcon: Icons.check_rounded,
                    isLoading: isSubmitting,
                    onPressed: isSubmitting ? null : _submit,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _addMetaRow() {
    setState(() => _metaRows.add(_MetaRowController()));
  }

  void _removeMetaRow(_MetaRowController row) {
    if (_metaRows.length == 1) {
      row.keyController.clear();
      row.valueController.clear();
      setState(() {});
      return;
    }
    setState(() => _metaRows.remove(row));
    row.dispose();
  }

  String? _validateMetaKey(_MetaRowController row) {
    final key = row.keyController.text.trim();
    final value = row.valueController.text.trim();
    if (key.isEmpty && value.isNotEmpty) return 'Key is required.';
    if (key.isEmpty) return null;
    final duplicates = _metaRows.where((candidate) {
      return candidate.keyController.text.trim() == key;
    }).length;
    if (duplicates > 1) return 'Keys must be unique.';
    return null;
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final gmtOffset = _blankToNull(_gmtOffset);
    if (gmtOffset != null && !_gmtOffsetPattern.hasMatch(gmtOffset)) {
      ToastHelper.showError('GMT offset must use +05:30 format.',
          context: context);
      return;
    }

    final ok = await ref.read(widget.provider.notifier).updateVehicle(
          UserVehicleUpdateRequest(
            name: _nameController.text.trim(),
            plateNumber: _plateController.text.trim(),
            vin: _vinController.text.trim(),
            vehicleTypeId: _vehicleTypePayloadValue(_vehicleTypeId),
            gmtOffset: gmtOffset,
            vehicleMeta: _buildMetaPayload(),
          ),
        );

    if (!mounted) return;
    if (ok) {
      ToastHelper.showSuccess('Vehicle updated.', context: context);
      Navigator.of(context).pop();
      return;
    }

    ToastHelper.showError(
      ref.read(widget.provider).sectionErrorMessage ??
          'Unable to update vehicle.',
      context: context,
    );
  }

  Map<String, dynamic> _buildMetaPayload() {
    final payload = <String, dynamic>{};
    for (final row in _metaRows) {
      final key = row.keyController.text.trim();
      final value = row.valueController.text.trim();
      if (key.isEmpty && value.isEmpty) continue;
      payload[key] = value;
    }
    return payload;
  }
}

class _VehicleTypeField extends StatelessWidget {
  const _VehicleTypeField({
    required this.value,
    required this.types,
    required this.isLoading,
    required this.onChanged,
  });

  final String? value;
  final List<UserVehicleTypeOption> types;
  final bool isLoading;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final items = _vehicleTypeItems(value, types);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Vehicle Type', style: OpenVtsTypography.label),
        const SizedBox(height: OpenVtsSpacing.xs),
        DropdownButtonFormField<String>(
          initialValue: value,
          isExpanded: true,
          hint: Text(isLoading ? 'Loading types' : 'Select type'),
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.category_outlined),
          ),
          items: items,
          onChanged: isLoading ? null : onChanged,
        ),
      ],
    );
  }
}

class _TimezoneField extends StatelessWidget {
  const _TimezoneField({
    required this.value,
    required this.timezones,
    required this.isLoading,
    required this.onChanged,
  });

  final String? value;
  final List<String> timezones;
  final bool isLoading;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final items = _timezoneItems(value, timezones);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('GMT Offset', style: OpenVtsTypography.label),
        const SizedBox(height: OpenVtsSpacing.xs),
        DropdownButtonFormField<String>(
          initialValue: value,
          isExpanded: true,
          hint: Text(isLoading ? 'Loading timezones' : 'Select timezone'),
          decoration:
              const InputDecoration(prefixIcon: Icon(Icons.schedule_rounded)),
          items: items,
          validator: (value) {
            final normalized = _blankToNull(value);
            if (normalized == null) return null;
            if (!_gmtOffsetPattern.hasMatch(normalized)) {
              return 'Use +05:30 format.';
            }
            return null;
          },
          onChanged: isLoading ? null : onChanged,
        ),
      ],
    );
  }
}

class _MetaRowsEditor extends StatelessWidget {
  const _MetaRowsEditor({
    required this.rows,
    required this.onAdd,
    required this.onRemove,
    required this.validateKey,
  });

  final List<_MetaRowController> rows;
  final VoidCallback onAdd;
  final ValueChanged<_MetaRowController> onRemove;
  final String? Function(_MetaRowController row) validateKey;

  @override
  Widget build(BuildContext context) {
    return OpenVtsCard(
      padding: const EdgeInsets.all(OpenVtsSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.data_object_rounded, size: 16),
              const SizedBox(width: OpenVtsSpacing.xs),
              Expanded(
                child: Text(
                  'Vehicle Meta',
                  style: OpenVtsTypography.label.copyWith(
                    color: OpenVtsColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Add metadata row',
                onPressed: onAdd,
                icon: const Icon(Icons.add_rounded, size: 18),
                style: IconButton.styleFrom(
                  minimumSize: const Size.square(32),
                  padding: EdgeInsets.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
          const SizedBox(height: OpenVtsSpacing.xs),
          for (final row in rows) ...[
            _MetaRowFields(
              row: row,
              onRemove: () => onRemove(row),
              validateKey: () => validateKey(row),
            ),
            if (row != rows.last) const SizedBox(height: OpenVtsSpacing.sm),
          ],
        ],
      ),
    );
  }
}

class _MetaRowFields extends StatelessWidget {
  const _MetaRowFields({
    required this.row,
    required this.onRemove,
    required this.validateKey,
  });

  final _MetaRowController row;
  final VoidCallback onRemove;
  final String? Function() validateKey;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: TextFormField(
            controller: row.keyController,
            decoration: const InputDecoration(
              hintText: 'Key',
              isDense: true,
            ),
            validator: (_) => validateKey(),
          ),
        ),
        const SizedBox(width: OpenVtsSpacing.xs),
        Expanded(
          child: TextFormField(
            controller: row.valueController,
            decoration: const InputDecoration(
              hintText: 'Value',
              isDense: true,
            ),
          ),
        ),
        const SizedBox(width: OpenVtsSpacing.xs),
        IconButton(
          tooltip: 'Remove metadata row',
          onPressed: onRemove,
          icon: const Icon(Icons.close_rounded, size: 17),
          style: IconButton.styleFrom(
            minimumSize: const Size.square(36),
            padding: EdgeInsets.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(OpenVtsRadius.sm),
            ),
          ),
        ),
      ],
    );
  }
}

class _MetaRowController {
  _MetaRowController({String keyText = '', String valueText = ''})
      : keyController = TextEditingController(text: keyText),
        valueController = TextEditingController(text: valueText);

  final TextEditingController keyController;
  final TextEditingController valueController;

  void dispose() {
    keyController.dispose();
    valueController.dispose();
  }
}

List<DropdownMenuItem<String>> _vehicleTypeItems(
  String? currentValue,
  List<UserVehicleTypeOption> types,
) {
  final seen = <String>{};
  final items = <DropdownMenuItem<String>>[];
  for (final type in types) {
    final value = type.id.trim();
    if (value.isEmpty || !seen.add(value)) continue;
    items.add(
      DropdownMenuItem<String>(
        value: value,
        child: Text(
          type.name.trim().isEmpty ? value : type.name.trim(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
  final normalizedCurrent = _blankToNull(currentValue);
  if (normalizedCurrent != null && seen.add(normalizedCurrent)) {
    items.insert(
      0,
      DropdownMenuItem<String>(
        value: normalizedCurrent,
        child: Text(
          normalizedCurrent,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
  return items;
}

List<DropdownMenuItem<String>> _timezoneItems(
  String? currentValue,
  List<String> timezones,
) {
  final seen = <String>{};
  final items = <DropdownMenuItem<String>>[];
  for (final timezone in timezones) {
    final value = timezone.trim();
    if (value.isEmpty || !seen.add(value)) continue;
    items.add(DropdownMenuItem<String>(value: value, child: Text(value)));
  }
  final normalizedCurrent = _blankToNull(currentValue);
  if (normalizedCurrent != null && seen.add(normalizedCurrent)) {
    items.insert(
      0,
      DropdownMenuItem<String>(
          value: normalizedCurrent, child: Text(normalizedCurrent)),
    );
  }
  return items;
}

Object? _vehicleTypePayloadValue(String? value) {
  final normalized = _blankToNull(value);
  if (normalized == null) return null;
  return int.tryParse(normalized) ?? normalized;
}

String? _blankToNull(String? value) {
  final normalized = value?.trim();
  if (normalized == null || normalized.isEmpty) return null;
  return normalized;
}
