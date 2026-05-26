import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/open_vts_spacing.dart';
import '../../../../../shared/helpers/toast_helper.dart';
import '../../../../../shared/widgets/open_vts_button.dart';
import '../../../../../shared/widgets/open_vts_text_field.dart';
import '../../../controllers/admin_providers.dart';
import '../../../models/admin_inventory_model.dart';

class AdminInventoryEditSimSheet extends ConsumerStatefulWidget {
  const AdminInventoryEditSimSheet({required this.simCard, super.key});

  final AdminInventorySimCard simCard;

  @override
  ConsumerState<AdminInventoryEditSimSheet> createState() =>
      _AdminInventoryEditSimSheetState();
}

class _AdminInventoryEditSimSheetState
    extends ConsumerState<AdminInventoryEditSimSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _simNumberController;
  late final TextEditingController _imsiController;
  late final TextEditingController _iccidController;

  List<AdminSimProviderOption> _providers = const <AdminSimProviderOption>[];
  bool _isLoading = true;
  String? _providerId;
  String _status = 'IN_STOCK';
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    _simNumberController =
        TextEditingController(text: _dashToEmpty(widget.simCard.simNumber));
    _imsiController =
        TextEditingController(text: _dashToEmpty(widget.simCard.imsi));
    _iccidController =
        TextEditingController(text: _dashToEmpty(widget.simCard.iccid));
    _providerId = widget.simCard.providerId ?? '';
    _status = widget.simCard.status.toApiValue();
    _isActive = widget.simCard.isActive;
    _loadProviders();
  }

  @override
  void dispose() {
    _simNumberController.dispose();
    _imsiController.dispose();
    _iccidController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminInventoryControllerProvider);
    final isSubmitting = state.editingSimIds.contains(widget.simCard.id);

    return Form(
      key: _formKey,
      child: Column(
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
                OpenVtsTextField(
                  label: 'SIM Number',
                  controller: _simNumberController,
                  validator: (v) => (v ?? '').trim().isEmpty
                      ? 'SIM number is required'
                      : null,
                ),
                const SizedBox(height: OpenVtsSpacing.sm),
                OpenVtsTextField(label: 'IMSI', controller: _imsiController),
                const SizedBox(height: OpenVtsSpacing.sm),
                OpenVtsTextField(label: 'ICCID', controller: _iccidController),
                const SizedBox(height: OpenVtsSpacing.sm),
                DropdownButtonFormField<String>(
                  initialValue: _providerId,
                  items: [
                    const DropdownMenuItem(
                        value: '', child: Text('No Provider')),
                    ..._providers.map((item) => DropdownMenuItem<String>(
                        value: item.id, child: Text(item.name))),
                  ],
                  decoration: const InputDecoration(labelText: 'SIM Provider'),
                  onChanged: isSubmitting
                      ? null
                      : (v) => setState(() => _providerId = v),
                ),
                const SizedBox(height: OpenVtsSpacing.sm),
                DropdownButtonFormField<String>(
                  initialValue: _status,
                  items: const [
                    DropdownMenuItem(
                        value: 'IN_STOCK', child: Text('IN_STOCK')),
                    DropdownMenuItem(value: 'IN_USE', child: Text('IN_USE')),
                    DropdownMenuItem(
                        value: 'IN_SCRAP', child: Text('IN_SCRAP')),
                  ],
                  decoration: const InputDecoration(labelText: 'Status'),
                  onChanged: isSubmitting
                      ? null
                      : (v) => setState(() => _status = v ?? 'IN_STOCK'),
                ),
                const SizedBox(height: OpenVtsSpacing.sm),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Active'),
                  value: _isActive,
                  onChanged: isSubmitting
                      ? null
                      : (v) => setState(() => _isActive = v),
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

  Future<void> _loadProviders() async {
    setState(() => _isLoading = true);
    try {
      final providers = await ref
          .read(adminInventoryControllerProvider.notifier)
          .loadSimProviders();
      if (!mounted) return;
      setState(() {
        _providers = providers;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final req = AdminUpdateSimCardRequest(
      simNumber: _simNumberController.text,
      imsi: _imsiController.text,
      iccid: _iccidController.text,
      providerId: (_providerId ?? '').trim().isEmpty
          ? null
          : int.tryParse(_providerId!),
      status: _status,
      isActive: _isActive,
    );

    final success =
        await ref.read(adminInventoryControllerProvider.notifier).updateSimCard(
              id: widget.simCard.id,
              request: req,
            );

    if (!mounted) return;
    if (success) {
      Navigator.of(context).pop();
      ToastHelper.showSuccess('SIM card updated.', context: context);
      return;
    }

    final message = ref.read(adminInventoryControllerProvider).editErrorMessage;
    ToastHelper.showError(message ?? 'Unable to update SIM card.',
        context: context);
  }

  String _dashToEmpty(String value) => value.trim() == '-' ? '' : value;
}
