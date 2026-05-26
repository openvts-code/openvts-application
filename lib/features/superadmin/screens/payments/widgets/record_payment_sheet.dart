import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/open_vts_colors.dart';
import '../../../../../core/theme/open_vts_radius.dart';
import '../../../../../core/theme/open_vts_spacing.dart';
import '../../../../../core/theme/open_vts_typography.dart';
import '../../../../../shared/helpers/toast_helper.dart';
import '../../../../../shared/widgets/open_vts_button.dart';
import '../../../../../shared/widgets/open_vts_loader.dart';
import '../../../controllers/superadmin_providers.dart';
import '../../../models/superadmin_payments_model.dart';

class RecordPaymentSheet extends ConsumerStatefulWidget {
  const RecordPaymentSheet({super.key});

  @override
  ConsumerState<RecordPaymentSheet> createState() => _RecordPaymentSheetState();
}

class _RecordPaymentSheetState extends ConsumerState<RecordPaymentSheet> {
  static final RegExp _amountPattern = RegExp(r'^\d+(\.\d{1,2})?$');

  static const List<SuperadminPaymentMode> _paymentModeOrder = [
    SuperadminPaymentMode.bankTransfer,
    SuperadminPaymentMode.cash,
    SuperadminPaymentMode.upi,
    SuperadminPaymentMode.card,
    SuperadminPaymentMode.wallet,
    SuperadminPaymentMode.razorpay,
    SuperadminPaymentMode.stripe,
    SuperadminPaymentMode.other,
  ];

  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _referenceController = TextEditingController();

  int? _adminId;
  SuperadminPaymentMode _paymentMode = SuperadminPaymentMode.bankTransfer;
  bool _didAttemptSubmit = false;

  @override
  void initState() {
    super.initState();

    _amountController.addListener(_onFieldChanged);
    _referenceController.addListener(_onFieldChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      final state = ref.read(superadminPaymentsControllerProvider);
      if (state.admins.isEmpty && !state.isLoadingAdmins) {
        unawaited(
          ref.read(superadminPaymentsControllerProvider.notifier).loadAdmins(),
        );
      }
    });
  }

  @override
  void dispose() {
    _amountController.removeListener(_onFieldChanged);
    _referenceController.removeListener(_onFieldChanged);
    _amountController.dispose();
    _referenceController.dispose();
    super.dispose();
  }

  void _onFieldChanged() {
    if (!mounted) {
      return;
    }

    setState(() {});
  }

  String? _validateAmount(String rawValue) {
    final value = rawValue.trim();

    if (value.isEmpty) {
      return 'Amount is required.';
    }

    if (value.length > 12) {
      return 'Amount must be 12 characters or less.';
    }

    if (!_amountPattern.hasMatch(value)) {
      return 'Use numbers with up to 2 decimal places.';
    }

    final parsed = num.tryParse(value);
    if (parsed == null || parsed <= 0) {
      return 'Amount must be greater than 0.';
    }

    return null;
  }

  bool _isReferenceValid() {
    return _referenceController.text.trim().length <= 100;
  }

  bool _isAdminValid() {
    return _adminId != null && _adminId! > 0;
  }

  bool _canSubmit(bool isRecordingPayment) {
    if (isRecordingPayment) {
      return false;
    }

    if (!_isAdminValid()) {
      return false;
    }

    if (_validateAmount(_amountController.text) != null) {
      return false;
    }

    if (!_isReferenceValid()) {
      return false;
    }

    return true;
  }

  Future<void> _submit() async {
    final state = ref.read(superadminPaymentsControllerProvider);
    if (state.isRecordingPayment) {
      return;
    }

    setState(() {
      _didAttemptSubmit = true;
    });

    if (!_isAdminValid()) {
      ToastHelper.showError('Please select an administrator.',
          context: context);
      return;
    }

    final amountError = _validateAmount(_amountController.text);
    if (amountError != null) {
      ToastHelper.showError(amountError, context: context);
      return;
    }

    final reference = _referenceController.text.trim();
    if (reference.length > 100) {
      ToastHelper.showError(
        'Reference must be 100 characters or less.',
        context: context,
      );
      return;
    }

    final request = SuperadminRecordPaymentRequest(
      adminId: _adminId!,
      amount: _amountController.text.trim(),
      paymentMode: _paymentMode,
      reference: reference.isEmpty ? null : reference,
    );

    try {
      await ref
          .read(superadminPaymentsControllerProvider.notifier)
          .recordManualPayment(request);

      if (!mounted) {
        return;
      }

      _clearForm();
      ToastHelper.showSuccess('Payment recorded', context: context);
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) {
        return;
      }

      final message = ref.read(
            superadminPaymentsControllerProvider.select(
              (value) => value.errorMessage,
            ),
          ) ??
          'Unable to record payment right now.';
      ToastHelper.showError(message, context: context);
    }
  }

  void _clearForm() {
    _amountController.clear();
    _referenceController.clear();
    _adminId = null;
    _paymentMode = SuperadminPaymentMode.bankTransfer;
    _didAttemptSubmit = false;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(superadminPaymentsControllerProvider);
    final admins = state.admins;

    if (_adminId == null && admins.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _adminId != null) {
          return;
        }

        setState(() {
          _adminId = admins.first.uid;
        });
      });
    }

    final selectedAdmin = _selectedAdmin(admins);
    final amountError =
        _didAttemptSubmit ? _validateAmount(_amountController.text) : null;
    final isSubmitEnabled = _canSubmit(state.isRecordingPayment);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.84,
      minChildSize: 0.54,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return DecoratedBox(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(OpenVtsRadius.xl),
            ),
          ),
          child: Column(
            children: [
              const SizedBox(height: OpenVtsSpacing.sm),
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: OpenVtsColors.border,
                    borderRadius: BorderRadius.circular(OpenVtsRadius.sm),
                  ),
                ),
              ),
              const SizedBox(height: OpenVtsSpacing.xs),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: OpenVtsSpacing.md),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Record Payment',
                        style: OpenVtsTypography.titleSmall.copyWith(
                          color: OpenVtsColors.textPrimary,
                        ),
                      ),
                    ),
                    IconButton(
                      constraints: const BoxConstraints(
                        minWidth: 44,
                        minHeight: 44,
                      ),
                      onPressed: state.isRecordingPayment
                          ? null
                          : () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: OpenVtsColors.divider),
              Expanded(
                child: state.isLoadingAdmins && admins.isEmpty
                    ? const OpenVtsLoader()
                    : ListView(
                        controller: scrollController,
                        padding: const EdgeInsets.all(OpenVtsSpacing.md),
                        children: [
                          DropdownButtonFormField<int>(
                            initialValue: selectedAdmin?.uid,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Administrator *',
                            ),
                            items: admins
                                .map(
                                  (admin) => DropdownMenuItem<int>(
                                    value: admin.uid,
                                    child: _AdminMenuLabel(admin: admin),
                                  ),
                                )
                                .toList(growable: false),
                            onChanged: state.isRecordingPayment
                                ? null
                                : (value) {
                                    setState(() {
                                      _adminId = value;
                                    });
                                  },
                          ),
                          if (admins.isEmpty && !state.isLoadingAdmins)
                            Padding(
                              padding:
                                  const EdgeInsets.only(top: OpenVtsSpacing.xs),
                              child: Text(
                                'No administrators available. Pull to refresh and try again.',
                                style: OpenVtsTypography.meta.copyWith(
                                  color: OpenVtsColors.textSecondary,
                                ),
                              ),
                            ),
                          const SizedBox(height: OpenVtsSpacing.sm),
                          TextField(
                            controller: _amountController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            textInputAction: TextInputAction.next,
                            inputFormatters: [
                              LengthLimitingTextInputFormatter(12),
                              FilteringTextInputFormatter.allow(
                                RegExp(r'[0-9.]'),
                              ),
                            ],
                            decoration: InputDecoration(
                              labelText: 'Amount *',
                              hintText: '0.00',
                              errorText: amountError,
                              suffixText: _currencySuffix(selectedAdmin),
                              suffixStyle: OpenVtsTypography.label.copyWith(
                                color: OpenVtsColors.textSecondary,
                              ),
                            ),
                          ),
                          const SizedBox(height: OpenVtsSpacing.sm),
                          DropdownButtonFormField<SuperadminPaymentMode>(
                            initialValue: _paymentMode,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Payment Mode *',
                            ),
                            items: _paymentModeOrder
                                .map(
                                  (mode) =>
                                      DropdownMenuItem<SuperadminPaymentMode>(
                                    value: mode,
                                    child: Text(mode.apiValue),
                                  ),
                                )
                                .toList(growable: false),
                            onChanged: state.isRecordingPayment
                                ? null
                                : (value) {
                                    if (value == null) {
                                      return;
                                    }

                                    setState(() {
                                      _paymentMode = value;
                                    });
                                  },
                          ),
                          const SizedBox(height: OpenVtsSpacing.sm),
                          TextField(
                            controller: _referenceController,
                            textInputAction: TextInputAction.done,
                            inputFormatters: [
                              LengthLimitingTextInputFormatter(100),
                            ],
                            decoration: const InputDecoration(
                              labelText: 'Reference (Optional)',
                              hintText:
                                  'Bank transfer note / UTR / transaction ref',
                            ),
                          ),
                          const SizedBox(height: OpenVtsSpacing.xs),
                          Text(
                            'Manual payments update transactions and analytics after successful submission.',
                            style: OpenVtsTypography.meta.copyWith(
                              color: OpenVtsColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    OpenVtsSpacing.md,
                    OpenVtsSpacing.xs,
                    OpenVtsSpacing.md,
                    OpenVtsSpacing.md,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OpenVtsButton(
                          label: 'Cancel',
                          variant: OpenVtsButtonVariant.secondary,
                          onPressed: state.isRecordingPayment
                              ? null
                              : () => Navigator.of(context).pop(),
                        ),
                      ),
                      const SizedBox(width: OpenVtsSpacing.sm),
                      Expanded(
                        child: OpenVtsButton(
                          label: 'Record Payment',
                          isLoading: state.isRecordingPayment,
                          onPressed: isSubmitEnabled ? _submit : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  SuperadminPaymentAdminOption? _selectedAdmin(
    List<SuperadminPaymentAdminOption> admins,
  ) {
    final selectedId = _adminId;
    if (selectedId == null || selectedId <= 0) {
      return null;
    }

    for (final admin in admins) {
      if (admin.uid == selectedId) {
        return admin;
      }
    }

    return null;
  }

  String? _currencySuffix(SuperadminPaymentAdminOption? admin) {
    final currency = admin?.currency.trim() ?? '';
    if (currency.isEmpty) {
      return null;
    }

    return currency;
  }
}

class _AdminMenuLabel extends StatelessWidget {
  const _AdminMenuLabel({required this.admin});

  final SuperadminPaymentAdminOption admin;

  @override
  Widget build(BuildContext context) {
    final username = admin.username.trim();
    final currency = admin.currency.trim();
    final title = username.isEmpty
        ? admin.displayName
        : '${admin.displayName} (@$username)';
    final text = currency.isEmpty ? title : '$title | $currency';

    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: OpenVtsTypography.body.copyWith(
        color: OpenVtsColors.textPrimary,
      ),
    );
  }
}
