import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/open_vts_spacing.dart';
import '../../../../../shared/helpers/toast_helper.dart';
import '../../../../../shared/widgets/open_vts_button.dart';
import '../../../../../shared/widgets/open_vts_text_field.dart';
import '../../../controllers/admin_providers.dart';
import '../../../models/admin_inventory_model.dart';

enum AdminInventoryAddMode { device, sim, both }

class AdminInventoryAddSheet extends ConsumerStatefulWidget {
  const AdminInventoryAddSheet({super.key});

  @override
  ConsumerState<AdminInventoryAddSheet> createState() =>
      _AdminInventoryAddSheetState();
}

class _AdminInventoryAddSheetState
    extends ConsumerState<AdminInventoryAddSheet> {
  final _formKey = GlobalKey<FormState>();
  final _imeiController = TextEditingController();
  final _simNumberController = TextEditingController();
  final _imsiController = TextEditingController();
  final _iccidController = TextEditingController();

  AdminInventoryAddMode _mode = AdminInventoryAddMode.device;
  List<AdminDeviceTypeOption> _deviceTypes = const <AdminDeviceTypeOption>[];
  List<AdminSimProviderOption> _providers = const <AdminSimProviderOption>[];
  String? _deviceTypeId;
  String? _providerId;
  bool _loadingRefs = true;

  @override
  void initState() {
    super.initState();
    _loadReferences();
  }

  @override
  void dispose() {
    _imeiController.dispose();
    _simNumberController.dispose();
    _imsiController.dispose();
    _iccidController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminInventoryControllerProvider);
    final isSubmitting = state.isCreating;

    return Form(
      key: _formKey,
      child: Column(
        children: [
          Expanded(
            child: ListView(
              controller: PrimaryScrollController.maybeOf(context),
              padding: const EdgeInsets.all(OpenVtsSpacing.md),
              children: [
                _modeChips(),
                if (_loadingRefs) ...[
                  const SizedBox(height: OpenVtsSpacing.sm),
                  const LinearProgressIndicator(minHeight: 2),
                ],
                const SizedBox(height: OpenVtsSpacing.sm),
                if (_mode != AdminInventoryAddMode.sim) ...[
                  OpenVtsTextField(
                    label: 'IMEI',
                    controller: _imeiController,
                    keyboardType: TextInputType.number,
                    validator: _validateImei,
                  ),
                  const SizedBox(height: OpenVtsSpacing.sm),
                  DropdownButtonFormField<String>(
                    initialValue: _deviceTypeId,
                    items: _deviceTypes
                        .map((item) => DropdownMenuItem<String>(
                              value: item.id,
                              child: Text(item.name,
                                  overflow: TextOverflow.ellipsis),
                            ))
                        .toList(growable: false),
                    decoration: const InputDecoration(labelText: 'Device Type'),
                    onChanged: isSubmitting
                        ? null
                        : (v) => setState(() => _deviceTypeId = v),
                    validator: _mode == AdminInventoryAddMode.sim
                        ? null
                        : (value) => (value == null || value.isEmpty)
                            ? 'Device type is required'
                            : null,
                  ),
                  const SizedBox(height: OpenVtsSpacing.sm),
                ],
                if (_mode != AdminInventoryAddMode.device) ...[
                  OpenVtsTextField(
                    label: 'SIM Number',
                    controller: _simNumberController,
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (_mode == AdminInventoryAddMode.device) return null;
                      final value = (v ?? '').trim();
                      return value.isEmpty ? 'SIM number is required' : null;
                    },
                  ),
                  const SizedBox(height: OpenVtsSpacing.sm),
                  OpenVtsTextField(
                    label: 'IMSI (optional)',
                    controller: _imsiController,
                    keyboardType: TextInputType.number,
                    validator: _validateImsi,
                  ),
                  const SizedBox(height: OpenVtsSpacing.sm),
                  OpenVtsTextField(
                    label: 'ICCID (optional)',
                    controller: _iccidController,
                    keyboardType: TextInputType.number,
                    validator: _validateIccid,
                  ),
                  const SizedBox(height: OpenVtsSpacing.sm),
                  DropdownButtonFormField<String>(
                    initialValue: _providerId,
                    items: [
                      const DropdownMenuItem<String>(
                          value: '', child: Text('No Provider')),
                      ..._providers.map((item) => DropdownMenuItem<String>(
                            value: item.id,
                            child: Text(item.name,
                                overflow: TextOverflow.ellipsis),
                          )),
                    ],
                    decoration: const InputDecoration(
                        labelText: 'SIM Provider (optional)'),
                    onChanged: isSubmitting
                        ? null
                        : (v) => setState(() => _providerId = v),
                  ),
                ],
              ],
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
                      variant: OpenVtsButtonVariant.secondary,
                      onPressed: isSubmitting
                          ? null
                          : () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(width: OpenVtsSpacing.sm),
                  Expanded(
                    child: OpenVtsButton(
                      label: 'Save',
                      isLoading: isSubmitting,
                      onPressed: isSubmitting ? null : _submit,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _modeChips() {
    return Wrap(
      spacing: OpenVtsSpacing.xs,
      runSpacing: OpenVtsSpacing.xs,
      children: [
        ChoiceChip(
          label: const Text('Device Only'),
          selected: _mode == AdminInventoryAddMode.device,
          onSelected: (_) =>
              setState(() => _mode = AdminInventoryAddMode.device),
        ),
        ChoiceChip(
          label: const Text('SIM Only'),
          selected: _mode == AdminInventoryAddMode.sim,
          onSelected: (_) => setState(() => _mode = AdminInventoryAddMode.sim),
        ),
        ChoiceChip(
          label: const Text('Device + SIM'),
          selected: _mode == AdminInventoryAddMode.both,
          onSelected: (_) => setState(() => _mode = AdminInventoryAddMode.both),
        ),
      ],
    );
  }

  Future<void> _loadReferences() async {
    setState(() => _loadingRefs = true);
    final controller = ref.read(adminInventoryControllerProvider.notifier);
    try {
      final results = await Future.wait([
        controller.loadDeviceTypes(),
        controller.loadSimProviders(),
      ]);
      if (!mounted) return;
      final deviceTypes = results[0] as List<AdminDeviceTypeOption>;
      final providers = results[1] as List<AdminSimProviderOption>;
      setState(() {
        _deviceTypes = deviceTypes;
        _providers = providers;
        _deviceTypeId = deviceTypes.isNotEmpty ? deviceTypes.first.id : null;
        _providerId = '';
        _loadingRefs = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingRefs = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final controller = ref.read(adminInventoryControllerProvider.notifier);
    bool success = false;

    if (_mode == AdminInventoryAddMode.device) {
      success = await controller.createDevice(
        AdminCreateDeviceRequest(
          imei: _imeiController.text,
          deviceTypeId: int.parse(_deviceTypeId ?? '0'),
        ),
      );
    } else if (_mode == AdminInventoryAddMode.sim) {
      success = await controller.createSimCard(
        AdminCreateSimCardRequest(
          simNumber: _simNumberController.text,
          imsi: _imsiController.text,
          iccid: _iccidController.text,
          providerId: (_providerId ?? '').trim().isEmpty ? null : _providerId,
        ),
      );
    } else {
      success = await controller.createDeviceAndSim(
        AdminCreateDeviceAndSimRequest(
          imei: _imeiController.text,
          deviceTypeId: int.parse(_deviceTypeId ?? '0'),
          simNumber: _simNumberController.text,
          imsi: _imsiController.text,
          iccid: _iccidController.text,
          providerId: (_providerId ?? '').trim().isEmpty ? null : _providerId,
        ),
      );
    }

    if (!mounted) {
      return;
    }
    if (success) {
      Navigator.of(context).pop();
      ToastHelper.showSuccess('Inventory item created.', context: context);
      return;
    }

    final message =
        ref.read(adminInventoryControllerProvider).createErrorMessage;
    ToastHelper.showError(message ?? 'Unable to create inventory item.',
        context: context);
  }

  String? _validateImei(String? value) {
    if (_mode == AdminInventoryAddMode.sim) {
      return null;
    }
    final input = (value ?? '').trim();
    if (input.isEmpty) {
      return 'IMEI is required';
    }
    if (!RegExp(r'^\d+$').hasMatch(input)) {
      return 'IMEI must be digits only';
    }
    if (input.length < 5 || input.length > 20) {
      return 'IMEI length must be 5-20 digits';
    }
    return null;
  }

  String? _validateImsi(String? value) {
    final input = (value ?? '').trim();
    if (input.isEmpty) {
      return null;
    }
    if (!RegExp(r'^\d+$').hasMatch(input)) {
      return 'IMSI must be digits only';
    }
    if (input.length < 5 || input.length > 20) {
      return 'IMSI length must be 5-20 digits';
    }
    return null;
  }

  String? _validateIccid(String? value) {
    final input = (value ?? '').trim();
    if (input.isEmpty) {
      return null;
    }
    if (!RegExp(r'^\d+$').hasMatch(input)) {
      return 'ICCID must be digits only';
    }
    if (input.length < 10 || input.length > 25) {
      return 'ICCID length must be 10-25 digits';
    }
    return null;
  }
}
