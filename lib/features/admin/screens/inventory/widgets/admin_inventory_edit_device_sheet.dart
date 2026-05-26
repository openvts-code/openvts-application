import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/open_vts_spacing.dart';
import '../../../../../shared/helpers/toast_helper.dart';
import '../../../../../shared/widgets/open_vts_button.dart';
import '../../../controllers/admin_providers.dart';
import '../../../models/admin_inventory_model.dart';

class AdminInventoryEditDeviceSheet extends ConsumerStatefulWidget {
  const AdminInventoryEditDeviceSheet({required this.device, super.key});

  final AdminInventoryDevice device;

  @override
  ConsumerState<AdminInventoryEditDeviceSheet> createState() =>
      _AdminInventoryEditDeviceSheetState();
}

class _AdminInventoryEditDeviceSheetState
    extends ConsumerState<AdminInventoryEditDeviceSheet> {
  List<AdminDeviceTypeOption> _deviceTypes = const <AdminDeviceTypeOption>[];
  List<AdminQuickSimCardOption> _simCards = const <AdminQuickSimCardOption>[];
  bool _isLoading = true;

  String? _deviceTypeId;
  String? _simId;
  String _status = 'IN_STOCK';
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    _status = widget.device.status.toApiValue();
    _isActive = widget.device.isActive;
    _deviceTypeId = widget.device.deviceTypeId;
    _simId = widget.device.assignedSimId ?? '0';
    _loadRefs();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminInventoryControllerProvider);
    final isSubmitting = state.editingDeviceIds.contains(widget.device.id);

    return Column(
      children: [
        Expanded(
          child: ListView(
            controller: PrimaryScrollController.maybeOf(context),
            padding: const EdgeInsets.all(OpenVtsSpacing.md),
            children: [
              if (_isLoading) ...[
                const LinearProgressIndicator(minHeight: 2),
                const SizedBox(height: OpenVtsSpacing.sm),
              ],
              DropdownButtonFormField<String>(
                initialValue: _deviceTypeId,
                items: _deviceTypes
                    .map((item) => DropdownMenuItem<String>(
                        value: item.id, child: Text(item.name)))
                    .toList(growable: false),
                decoration: const InputDecoration(labelText: 'Device Type'),
                onChanged: isSubmitting
                    ? null
                    : (v) => setState(() => _deviceTypeId = v),
              ),
              const SizedBox(height: OpenVtsSpacing.sm),
              DropdownButtonFormField<String>(
                initialValue: _simId,
                items: _simCards
                    .map((item) => DropdownMenuItem<String>(
                        value: item.id, child: Text(item.simNumber)))
                    .toList(growable: false),
                decoration: const InputDecoration(labelText: 'SIM Number'),
                onChanged:
                    isSubmitting ? null : (v) => setState(() => _simId = v),
              ),
              const SizedBox(height: OpenVtsSpacing.sm),
              DropdownButtonFormField<String>(
                initialValue: _status,
                items: const [
                  DropdownMenuItem(value: 'IN_STOCK', child: Text('IN_STOCK')),
                  DropdownMenuItem(value: 'IN_USE', child: Text('IN_USE')),
                  DropdownMenuItem(value: 'IN_SCRAP', child: Text('IN_SCRAP')),
                ],
                decoration: const InputDecoration(labelText: 'Status'),
                onChanged: isSubmitting
                    ? null
                    : (v) => setState(() => _status = v ?? 'IN_STOCK'),
              ),
              const SizedBox(height: OpenVtsSpacing.sm),
              SwitchListTile.adaptive(
                value: _isActive,
                contentPadding: EdgeInsets.zero,
                title: const Text('Active'),
                onChanged:
                    isSubmitting ? null : (v) => setState(() => _isActive = v),
              ),
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
                    onPressed:
                        isSubmitting ? null : () => Navigator.of(context).pop(),
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
    );
  }

  Future<void> _loadRefs() async {
    setState(() => _isLoading = true);
    final controller = ref.read(adminInventoryControllerProvider.notifier);
    try {
      final results = await Future.wait([
        controller.loadDeviceTypes(),
        controller.loadQuickSimcards(),
      ]);
      if (!mounted) return;
      final types = results[0] as List<AdminDeviceTypeOption>;
      final sims = [...(results[1] as List<AdminQuickSimCardOption>)];
      if (!sims.any((e) => e.id == '0')) {
        sims.insert(
            0, const AdminQuickSimCardOption(id: '0', simNumber: 'Unassigned'));
      }
      final currentSimId = widget.device.assignedSimId;
      final currentSimNum = widget.device.assignedSimNumber;
      if (currentSimId != null &&
          currentSimId.isNotEmpty &&
          !sims.any((e) => e.id == currentSimId) &&
          currentSimNum.trim().isNotEmpty) {
        sims.insert(
            1,
            AdminQuickSimCardOption(
                id: currentSimId, simNumber: currentSimNum));
      }

      setState(() {
        _deviceTypes = types;
        _simCards = sims;
        _deviceTypeId ??= types.isNotEmpty ? types.first.id : null;
        _simId ??= '0';
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _submit() async {
    final req = AdminUpdateDeviceRequest(
      deviceTypeId: _deviceTypeId == null ? null : int.tryParse(_deviceTypeId!),
      simId: _simId == null ? null : int.tryParse(_simId!),
      status: _status,
      isActive: _isActive,
    );

    final success =
        await ref.read(adminInventoryControllerProvider.notifier).updateDevice(
              id: widget.device.id,
              request: req,
            );

    if (!mounted) return;
    if (success) {
      Navigator.of(context).pop();
      ToastHelper.showSuccess('Device updated.', context: context);
      return;
    }
    final message = ref.read(adminInventoryControllerProvider).editErrorMessage;
    ToastHelper.showError(message ?? 'Unable to update device.',
        context: context);
  }
}
