import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/route_paths.dart';
import '../../../core/theme/open_vts_colors.dart';
import '../../../core/theme/open_vts_spacing.dart';
import '../../../core/theme/open_vts_typography.dart';
import '../../../core/utils/validators.dart';
import '../../../shared/widgets/open_vts_button.dart';
import '../../../shared/widgets/open_vts_text_field.dart';

class LoginForm extends StatefulWidget {
  const LoginForm({
    required this.isLoading,
    required this.onSubmit,
    super.key,
  });

  final bool isLoading;
  final void Function(String email, String password) onSubmit;

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() != true) {
      return;
    }

    widget.onSubmit(
      _identifierController.text.trim(),
      _passwordController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AutofillGroup(
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            OpenVtsTextField(
              label: 'Username',
              hintText: 'Enter your username',
              controller: _identifierController,
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.username],
              prefixIcon: Icons.person_outline_rounded,
              validator: (value) =>
                  Validators.required(value, fieldName: 'Username'),
            ),
            const SizedBox(height: OpenVtsSpacing.md),
            OpenVtsTextField(
              label: 'Password',
              hintText: 'Enter your password',
              controller: _passwordController,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.password],
              prefixIcon: Icons.lock_outline_rounded,
              suffixIcon: IconButton(
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
                tooltip: _obscurePassword ? 'Show password' : 'Hide password',
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: OpenVtsColors.textSecondary,
                ),
              ),
              validator: (value) =>
                  Validators.required(value, fieldName: 'Password'),
              onFieldSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: OpenVtsSpacing.sm),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton(
                onPressed: widget.isLoading
                    ? null
                    : () => context.push(RoutePaths.forgotPassword),
                style: TextButton.styleFrom(
                  foregroundColor: OpenVtsColors.textTertiary,
                  minimumSize: const Size(44, 44),
                  padding: EdgeInsets.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  textStyle: OpenVtsTypography.meta.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                child: const Text('Forgot Password?'),
              ),
            ),
            const SizedBox(height: OpenVtsSpacing.md),
            SizedBox(
              width: double.infinity,
              child: OpenVtsButton(
                label: 'Login',
                isLoading: widget.isLoading,
                trailingIcon: Icons.arrow_forward_rounded,
                onPressed: _submit,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
