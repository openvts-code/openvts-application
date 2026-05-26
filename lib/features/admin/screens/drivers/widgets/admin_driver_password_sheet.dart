import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/open_vts_spacing.dart';
import '../../../../../shared/helpers/toast_helper.dart';
import '../../../../../shared/widgets/open_vts_bottom_sheet.dart';
import '../../../../../shared/widgets/open_vts_button.dart';
import '../../../../../shared/widgets/open_vts_text_field.dart';
import '../../../controllers/admin_driver_details_controller.dart';
import '../../../models/admin_driver_details_state.dart';

Future<void> showDriverPasswordSheet({
  required BuildContext context,
  required AutoDisposeStateNotifierProvider<AdminDriverDetailsController,
          AdminDriverDetailsState>
      provider,
}) {
  return OpenVtsBottomSheet.show<void>(
    context: context,
    title: 'Update Password',
    initialChildSize: 0.46,
    minChildSize: 0.34,
    maxChildSize: 0.72,
    child: _DriverPasswordSheet(provider: provider),
  );
}

class _DriverPasswordSheet extends ConsumerStatefulWidget {
  const _DriverPasswordSheet({required this.provider});

  final AutoDisposeStateNotifierProvider<AdminDriverDetailsController,
      AdminDriverDetailsState> provider;

  @override
  ConsumerState<_DriverPasswordSheet> createState() =>
      _DriverPasswordSheetState();
}

class _DriverPasswordSheetState extends ConsumerState<_DriverPasswordSheet> {
  final _formKey = GlobalKey<FormState>();
  final _newPassword = TextEditingController();
  final _confirmPassword = TextEditingController();

  @override
  void dispose() {
    _newPassword.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(widget.provider);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(OpenVtsSpacing.md),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            OpenVtsTextField(
              label: 'New Password',
              controller: _newPassword,
              obscureText: true,
              validator: (v) => (v == null || v.length < 8)
                  ? 'Password must be at least 8 characters'
                  : null,
            ),
            const SizedBox(height: OpenVtsSpacing.sm),
            OpenVtsTextField(
              label: 'Confirm Password',
              controller: _confirmPassword,
              obscureText: true,
              validator: (v) =>
                  v != _newPassword.text ? 'Passwords do not match' : null,
            ),
            const SizedBox(height: OpenVtsSpacing.sm),
            OpenVtsButton(
              label: 'Update Password',
              isLoading: state.isUpdatingPassword,
              onPressed: state.isUpdatingPassword ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await ref
        .read(widget.provider.notifier)
        .updatePassword(_newPassword.text);
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop();
      ToastHelper.showSuccess('Password updated.', context: context);
    } else {
      ToastHelper.showError(
        ref.read(widget.provider).sectionErrorMessage ??
            'Unable to update password.',
        context: context,
      );
    }
  }
}
