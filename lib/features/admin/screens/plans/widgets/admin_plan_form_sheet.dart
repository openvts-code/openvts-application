import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/open_vts_spacing.dart';
import '../../../../../shared/helpers/toast_helper.dart';
import '../../../../../shared/widgets/open_vts_button.dart';
import '../../../../../shared/widgets/open_vts_text_field.dart';
import '../../../controllers/admin_providers.dart';
import '../../../models/admin_plans_model.dart';

enum AdminPlanFormMode { create, edit }

class AdminPlanFormSheet extends ConsumerStatefulWidget {
  const AdminPlanFormSheet.create({super.key})
      : mode = AdminPlanFormMode.create,
        initialPlan = null;

  const AdminPlanFormSheet.edit({required this.initialPlan, super.key})
      : mode = AdminPlanFormMode.edit;

  final AdminPlanFormMode mode;
  final AdminPlan? initialPlan;

  @override
  ConsumerState<AdminPlanFormSheet> createState() => _AdminPlanFormSheetState();
}

class _AdminPlanFormSheetState extends ConsumerState<AdminPlanFormSheet> {
  static const _durationOptions = <int>[
    7,
    30,
    90,
    180,
    270,
    365,
    548,
    730,
    1095,
    1825,
  ];

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();

  int? _durationDays;
  String? _currencyCode;

  bool get _isEditMode => widget.mode == AdminPlanFormMode.edit;

  @override
  void initState() {
    super.initState();
    final initialPlan = widget.initialPlan;
    if (initialPlan != null) {
      _nameController.text = initialPlan.name;
      if (initialPlan.price != null) {
        _priceController.text = initialPlan.price.toString();
      }
      _durationDays = initialPlan.durationDays;
      _currencyCode = initialPlan.currency.trim().isEmpty
          ? null
          : initialPlan.currency.trim();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(adminPlansControllerProvider.notifier).loadCurrencies();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminPlansControllerProvider);
    final isSubmitting = state.isCreating || state.isUpdating;
    final currencies = state.currencies;

    if (_currencyCode == null && currencies.isNotEmpty) {
      _currencyCode = currencies.first.code;
    }

    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Flexible(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  OpenVtsSpacing.md,
                  OpenVtsSpacing.md,
                  OpenVtsSpacing.md,
                  OpenVtsSpacing.lg,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (state.isLoadingCurrencies) ...[
                      const LinearProgressIndicator(minHeight: 2),
                      const SizedBox(height: OpenVtsSpacing.md),
                    ],
                    OpenVtsTextField(
                      label: 'Name',
                      controller: _nameController,
                      textInputAction: TextInputAction.next,
                      prefixIcon: Icons.badge_outlined,
                      validator: _validateName,
                    ),
                    const SizedBox(height: OpenVtsSpacing.sm),
                    DropdownButtonFormField<int>(
                      initialValue: _durationDays,
                      items: _durationOptions
                          .map(
                            (days) => DropdownMenuItem<int>(
                              value: days,
                              child: Text(_durationLabel(days)),
                            ),
                          )
                          .toList(growable: false),
                      decoration: const InputDecoration(
                        labelText: 'Duration',
                        prefixIcon: Icon(Icons.schedule_rounded, size: 20),
                      ),
                      onChanged: isSubmitting
                          ? null
                          : (value) => setState(() => _durationDays = value),
                      validator: (value) =>
                          value == null ? 'Duration is required' : null,
                    ),
                    const SizedBox(height: OpenVtsSpacing.sm),
                    OpenVtsTextField(
                      label: 'Price',
                      controller: _priceController,
                      textInputAction: TextInputAction.next,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      prefixIcon: Icons.payments_outlined,
                      validator: _validatePrice,
                    ),
                    const SizedBox(height: OpenVtsSpacing.sm),
                    DropdownButtonFormField<String>(
                      initialValue: _currencyCode,
                      items: currencies
                          .map(
                            (item) => DropdownMenuItem<String>(
                              value: item.code,
                              child: Text(
                                item.label,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(growable: false),
                      decoration: const InputDecoration(
                        labelText: 'Currency',
                        prefixIcon: Icon(Icons.language_rounded, size: 20),
                      ),
                      onChanged: isSubmitting
                          ? null
                          : (value) => setState(() => _currencyCode = value),
                      validator: (value) =>
                          (value == null || value.trim().isEmpty)
                              ? 'Currency is required'
                              : null,
                    ),
                    if (!state.isLoadingCurrencies &&
                        currencies.isEmpty &&
                        state.submitErrorMessage != null) ...[
                      const SizedBox(height: OpenVtsSpacing.sm),
                      TextButton.icon(
                        onPressed: () => ref
                            .read(adminPlansControllerProvider.notifier)
                            .loadCurrencies(force: true),
                        icon: const Icon(Icons.refresh_rounded, size: 16),
                        label: const Text('Retry loading currencies'),
                      ),
                    ],
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
                      variant: OpenVtsButtonVariant.secondary,
                      onPressed: isSubmitting
                          ? null
                          : () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(width: OpenVtsSpacing.sm),
                  Expanded(
                    child: OpenVtsButton(
                      label: _isEditMode ? 'Save Changes' : 'Save Plan',
                      onPressed: isSubmitting ? null : _submit,
                      isLoading: isSubmitting,
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final price = num.tryParse(_priceController.text.trim());
    if (price == null || !price.isFinite || price <= 0 || price > 1000000) {
      return;
    }

    final request = AdminPlanMutationRequest(
      name: _nameController.text.trim(),
      durationDays: _durationDays!,
      price: price,
      currency: _currencyCode!.trim(),
    );

    final controller = ref.read(adminPlansControllerProvider.notifier);
    final result = _isEditMode
        ? await controller.updatePlan(
            id: widget.initialPlan!.id,
            request: request,
          )
        : await controller.createPlan(request);

    if (!mounted) {
      return;
    }

    final success = _isEditMode ? (result as bool?) ?? false : result != null;

    if (success) {
      Navigator.of(context).pop(result);
      ToastHelper.showSuccess(
        _isEditMode ? 'Plan updated.' : 'Plan created.',
        context: context,
      );
      return;
    }

    final message = ref.read(adminPlansControllerProvider).submitErrorMessage;
    ToastHelper.showError(
      message ?? 'Unable to save plan.',
      context: context,
    );
  }

  String _durationLabel(int days) {
    if (days == 30) {
      return '30 days (1 Month)';
    }
    if (days == 365) {
      return '365 days (1 Year)';
    }
    return '$days days';
  }

  String? _validateName(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return 'Name is required';
    }
    if (text.length < 2) {
      return 'Name must be at least 2 characters';
    }
    if (text.length > 50) {
      return 'Name must be at most 50 characters';
    }
    if (!RegExp(r'[A-Za-z0-9]').hasMatch(text)) {
      return 'Name must include letters or numbers';
    }
    return null;
  }

  String? _validatePrice(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return 'Price is required';
    }
    final number = num.tryParse(text);
    if (number == null || !number.isFinite) {
      return 'Price must be a valid number';
    }
    if (number <= 0) {
      return 'Price must be greater than 0';
    }
    if (number > 1000000) {
      return 'Price must be at most 1000000';
    }
    return null;
  }
}
