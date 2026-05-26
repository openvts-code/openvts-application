import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../../core/theme/open_vts_colors.dart';
import '../../../../../../core/theme/open_vts_spacing.dart';
import '../../../../../../core/theme/open_vts_typography.dart';
import '../../../../../../shared/helpers/toast_helper.dart';
import '../../../../../../shared/widgets/open_vts_button.dart';
import '../../../../../../shared/widgets/open_vts_text_field.dart';
import '../../../../controllers/user_providers.dart';
import '../../../../models/user_subuser_model.dart';

class UserSubUserCreateSheet extends ConsumerStatefulWidget {
  const UserSubUserCreateSheet({
    required this.onSubmit,
    super.key,
  });

  final Future<UserSubUser?> Function(CreateUserSubUserRequest request)
      onSubmit;

  @override
  ConsumerState<UserSubUserCreateSheet> createState() =>
      _UserSubUserCreateSheetState();
}

class _UserSubUserCreateSheetState
    extends ConsumerState<UserSubUserCreateSheet> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobilePrefixController = TextEditingController();
  final _mobileNumberController = TextEditingController();
  final _passwordController = TextEditingController();

  var _isActive = true;
  var _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _mobilePrefixController.dispose();
    _mobileNumberController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSubmitting = ref.watch(
      userSubUsersControllerProvider.select((state) => state.isCreating),
    );
    final viewInsets = MediaQuery.of(context).viewInsets;
    final maxHeight = MediaQuery.of(context).size.height * 0.9;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Material(
          color: Theme.of(context).colorScheme.surface,
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    controller: PrimaryScrollController.maybeOf(context),
                    padding: const EdgeInsets.fromLTRB(
                      OpenVtsSpacing.md,
                      OpenVtsSpacing.md,
                      OpenVtsSpacing.md,
                      OpenVtsSpacing.lg,
                    ),
                    children: [
                      Text(
                        'Create Sub User',
                        style: OpenVtsTypography.label.copyWith(
                          color: OpenVtsColors.textPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Create a compact login profile with controlled access.',
                        style: OpenVtsTypography.meta.copyWith(
                          color: OpenVtsColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: OpenVtsSpacing.md),
                      OpenVtsTextField(
                        label: 'Name',
                        controller: _nameController,
                        textInputAction: TextInputAction.next,
                        prefixIcon: Icons.person_outline_rounded,
                        validator: _nameValidator,
                      ),
                      const SizedBox(height: OpenVtsSpacing.sm),
                      OpenVtsTextField(
                        label: 'Username (optional)',
                        controller: _usernameController,
                        textInputAction: TextInputAction.next,
                        prefixIcon: Icons.alternate_email_rounded,
                        validator: _optionalUsernameValidator,
                      ),
                      const SizedBox(height: OpenVtsSpacing.sm),
                      OpenVtsTextField(
                        label: 'Email (optional)',
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        prefixIcon: Icons.mail_outline_rounded,
                        validator: _optionalEmailValidator,
                      ),
                      const SizedBox(height: OpenVtsSpacing.sm),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 124,
                            child: OpenVtsTextField(
                              label: 'Prefix',
                              controller: _mobilePrefixController,
                              textInputAction: TextInputAction.next,
                              prefixIcon: Icons.phone_android_rounded,
                            ),
                          ),
                          const SizedBox(width: OpenVtsSpacing.sm),
                          Expanded(
                            child: OpenVtsTextField(
                              label: 'Mobile (optional)',
                              controller: _mobileNumberController,
                              keyboardType: TextInputType.phone,
                              textInputAction: TextInputAction.next,
                              prefixIcon: Icons.phone_rounded,
                              validator: _optionalMobileValidator,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: OpenVtsSpacing.sm),
                      OpenVtsTextField(
                        label: 'Password (optional)',
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.done,
                        prefixIcon: Icons.lock_outline_rounded,
                        suffixIcon: IconButton(
                          tooltip: _obscurePassword
                              ? 'Show password'
                              : 'Hide password',
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            size: 18,
                          ),
                        ),
                        validator: _optionalPasswordValidator,
                      ),
                      const SizedBox(height: OpenVtsSpacing.sm),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: OpenVtsSpacing.sm,
                          vertical: OpenVtsSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: OpenVtsColors.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: OpenVtsColors.border),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Active account',
                                style: OpenVtsTypography.meta.copyWith(
                                  color: OpenVtsColors.textSecondary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Transform.scale(
                              scale: 0.9,
                              child: Switch.adaptive(
                                value: _isActive,
                                activeThumbColor: OpenVtsColors.brandInk,
                                activeTrackColor: OpenVtsColors.brandInk
                                    .withValues(alpha: 0.35),
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                                onChanged: isSubmitting
                                    ? null
                                    : (value) {
                                        setState(() => _isActive = value);
                                      },
                              ),
                            ),
                          ],
                        ),
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
                            height: 40,
                            variant: OpenVtsButtonVariant.secondary,
                            onPressed: isSubmitting
                                ? null
                                : () => Navigator.of(context).pop(),
                          ),
                        ),
                        const SizedBox(width: OpenVtsSpacing.sm),
                        Expanded(
                          child: OpenVtsButton(
                            label: 'Create Sub User',
                            height: 40,
                            trailingIcon: Icons.person_add_alt_1_rounded,
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
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final request = CreateUserSubUserRequest(
      name: _nameController.text.trim(),
      username: _optionalValue(_usernameController.text),
      email: _optionalValue(_emailController.text),
      mobilePrefix: _optionalValue(_mobilePrefixController.text),
      mobileNumber: _optionalValue(_mobileNumberController.text),
      password: _optionalValue(_passwordController.text),
      isActive: _isActive,
    );

    final created = await widget.onSubmit(request);
    if (!mounted) {
      return;
    }

    if (created == null) {
      final message = ref.read(userSubUsersControllerProvider).errorMessage ??
          'Unable to create sub user.';
      ToastHelper.showError(message, context: context);
      return;
    }

    Navigator.of(context).pop(created);
  }

  String? _nameValidator(String? value) {
    final normalized = value?.trim() ?? '';
    if (normalized.isEmpty) {
      return 'Name is required';
    }
    if (normalized.length < 2) {
      return 'Name must be at least 2 characters';
    }
    return null;
  }

  String? _optionalUsernameValidator(String? value) {
    final normalized = value?.trim() ?? '';
    if (normalized.isEmpty) {
      return null;
    }
    if (normalized.length < 3) {
      return 'Username must be at least 3 characters';
    }
    return null;
  }

  String? _optionalEmailValidator(String? value) {
    final normalized = value?.trim() ?? '';
    if (normalized.isEmpty) {
      return null;
    }

    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(normalized)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  String? _optionalMobileValidator(String? value) {
    final normalized = value?.trim() ?? '';
    if (normalized.isEmpty) {
      return null;
    }

    final digitsOnly = RegExp(r'^\d{7,15}$');
    if (!digitsOnly.hasMatch(normalized)) {
      return 'Enter 7 to 15 digits';
    }

    return null;
  }

  String? _optionalPasswordValidator(String? value) {
    final normalized = value ?? '';
    if (normalized.trim().isEmpty) {
      return null;
    }
    if (normalized.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  String? _optionalValue(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }
    return normalized;
  }
}
