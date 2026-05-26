import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../../core/theme/open_vts_colors.dart';
import '../../../../../../core/theme/open_vts_spacing.dart';
import '../../../../../../core/theme/open_vts_typography.dart';
import '../../../../../../shared/helpers/toast_helper.dart';
import '../../../../../../shared/widgets/open_vts_button.dart';
import '../../../../../../shared/widgets/open_vts_text_field.dart';
import '../../../../controllers/user_subuser_details_controller.dart';
import '../../../../models/user_subuser_model.dart';
import '../../../../models/user_subusers_state.dart';

typedef UserSubUserDetailsProvider = AutoDisposeStateNotifierProvider<
    UserSubUserDetailsController, UserSubUserDetailsState>;

class UserSubUserEditSheet extends ConsumerStatefulWidget {
  const UserSubUserEditSheet({
    required this.provider,
    required this.subUser,
    super.key,
  });

  final UserSubUserDetailsProvider provider;
  final UserSubUser subUser;

  @override
  ConsumerState<UserSubUserEditSheet> createState() =>
      _UserSubUserEditSheetState();
}

class _UserSubUserEditSheetState extends ConsumerState<UserSubUserEditSheet> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobilePrefixController = TextEditingController();
  final _mobileNumberController = TextEditingController();
  final _passwordController = TextEditingController();

  var _obscurePassword = true;
  var _isActive = true;

  @override
  void initState() {
    super.initState();
    final subUser = widget.subUser;
    _nameController.text = subUser.name;
    _usernameController.text = subUser.username;
    _emailController.text = subUser.email;
    _mobilePrefixController.text = subUser.mobilePrefix;
    _mobileNumberController.text = subUser.mobileNumber;
    _isActive = subUser.isActive;
  }

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
    final state = ref.watch(widget.provider);
    final isSubmitting = state.isSaving;

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
                    hintText: 'Sub user name',
                    textInputAction: TextInputAction.next,
                    prefixIcon: Icons.person_outline_rounded,
                    validator: _nameValidator,
                  ),
                  const SizedBox(height: OpenVtsSpacing.sm),
                  OpenVtsTextField(
                    label: 'Username',
                    controller: _usernameController,
                    hintText: 'Optional username',
                    textInputAction: TextInputAction.next,
                    prefixIcon: Icons.alternate_email_rounded,
                    validator: _optionalUsernameValidator,
                  ),
                  const SizedBox(height: OpenVtsSpacing.sm),
                  OpenVtsTextField(
                    label: 'Email',
                    controller: _emailController,
                    hintText: 'Optional email',
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    prefixIcon: Icons.mail_outline_rounded,
                    validator: _optionalEmailValidator,
                  ),
                  const SizedBox(height: OpenVtsSpacing.sm),
                  Row(
                    children: [
                      SizedBox(
                        width: 124,
                        child: OpenVtsTextField(
                          label: 'Prefix',
                          controller: _mobilePrefixController,
                          hintText: '+91',
                          textInputAction: TextInputAction.next,
                          prefixIcon: Icons.phone_android_rounded,
                        ),
                      ),
                      const SizedBox(width: OpenVtsSpacing.sm),
                      Expanded(
                        child: OpenVtsTextField(
                          label: 'Mobile',
                          controller: _mobileNumberController,
                          hintText: 'Optional mobile',
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
                    hintText: 'Leave blank to keep current password',
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.done,
                    prefixIcon: Icons.lock_outline_rounded,
                    suffixIcon: IconButton(
                      tooltip:
                          _obscurePassword ? 'Show password' : 'Hide password',
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
                      border: Border.all(color: OpenVtsColors.border),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Active account',
                                style: OpenVtsTypography.label.copyWith(
                                  color: OpenVtsColors.textPrimary,
                                ),
                              ),
                              Text(
                                _isActive
                                    ? 'Sub user can access assigned vehicles'
                                    : 'Sub user is disabled',
                                style: OpenVtsTypography.meta.copyWith(
                                  color: OpenVtsColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch.adaptive(
                          value: _isActive,
                          activeThumbColor: OpenVtsColors.brandInk,
                          activeTrackColor:
                              OpenVtsColors.brandInk.withValues(alpha: 0.35),
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          onChanged: isSubmitting
                              ? null
                              : (value) {
                                  setState(() => _isActive = value);
                                },
                        ),
                      ],
                    ),
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
                    label: 'Save Changes',
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final request = UpdateUserSubUserRequest(
      name: _nameController.text.trim(),
      username: _optionalValue(_usernameController.text),
      email: _optionalValue(_emailController.text),
      mobilePrefix: _optionalValue(_mobilePrefixController.text),
      mobileNumber: _optionalValue(_mobileNumberController.text),
      password: _optionalValue(_passwordController.text),
      isActive: _isActive,
    );

    final ok = await ref.read(widget.provider.notifier).updateSubUser(request);
    if (!mounted) {
      return;
    }

    if (ok) {
      ToastHelper.showSuccess('Sub user updated.', context: context);
      Navigator.of(context).pop(true);
      return;
    }

    ToastHelper.showError(
      ref.read(widget.provider).errorMessage ?? 'Unable to update sub user.',
      context: context,
    );
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

  String? _optionalValue(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }
    return normalized;
  }
}
