import 'package:flutter/material.dart';

import '../../../../../core/theme/open_vts_spacing.dart';
import '../../../../../shared/helpers/toast_helper.dart';
import '../../../../../shared/widgets/open_vts_button.dart';
import '../../../../../shared/widgets/open_vts_text_field.dart';
import '../../../models/admin_users_model.dart';

class AdminUserPasswordSheet extends StatefulWidget {
  const AdminUserPasswordSheet({
    required this.user,
    required this.isSubmitting,
    required this.errorMessage,
    required this.onSubmit,
    super.key,
  });

  final AdminUserListItem user;
  final bool isSubmitting;
  final String? errorMessage;
  final Future<void> Function(String newPassword) onSubmit;

  @override
  State<AdminUserPasswordSheet> createState() => _AdminUserPasswordSheetState();
}

class _AdminUserPasswordSheetState extends State<AdminUserPasswordSheet> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  var _obscurePassword = true;
  var _obscureConfirm = true;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(OpenVtsSpacing.md),
        children: [
          OpenVtsTextField(
            label: 'New password',
            controller: _passwordController,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.next,
            prefixIcon: Icons.lock_outline_rounded,
            suffixIcon: IconButton(
              tooltip: _obscurePassword ? 'Show password' : 'Hide password',
              onPressed: () {
                setState(() => _obscurePassword = !_obscurePassword);
              },
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                size: 18,
              ),
            ),
            validator: _passwordValidator,
          ),
          const SizedBox(height: OpenVtsSpacing.sm),
          OpenVtsTextField(
            label: 'Confirm password',
            controller: _confirmController,
            obscureText: _obscureConfirm,
            textInputAction: TextInputAction.done,
            prefixIcon: Icons.lock_reset_rounded,
            suffixIcon: IconButton(
              tooltip: _obscureConfirm ? 'Show password' : 'Hide password',
              onPressed: () {
                setState(() => _obscureConfirm = !_obscureConfirm);
              },
              icon: Icon(
                _obscureConfirm
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                size: 18,
              ),
            ),
            validator: _confirmValidator,
          ),
          const SizedBox(height: OpenVtsSpacing.lg),
          OpenVtsButton(
            label: 'Update Password',
            onPressed: widget.isSubmitting ? null : _submit,
            isLoading: widget.isSubmitting,
            trailingIcon: Icons.check_rounded,
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      await widget.onSubmit(_passwordController.text.trim());
      if (!mounted) {
        return;
      }
      _passwordController.clear();
      _confirmController.clear();
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) {
        return;
      }
      ToastHelper.showError(
        widget.errorMessage ?? 'Unable to update password.',
        context: context,
      );
    }
  }

  String? _passwordValidator(String? value) {
    final normalized = value?.trim() ?? '';
    if (normalized.isEmpty) {
      return 'Required';
    }
    if (normalized.length < 8) {
      return 'Use at least 8 characters';
    }
    return null;
  }

  String? _confirmValidator(String? value) {
    final normalized = value?.trim() ?? '';
    if (normalized.isEmpty) {
      return 'Required';
    }
    if (normalized != _passwordController.text.trim()) {
      return 'Passwords do not match';
    }
    return null;
  }
}
