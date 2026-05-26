import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/open_vts_spacing.dart';
import '../../../../../core/utils/validators.dart';
import '../../../../../shared/helpers/toast_helper.dart';
import '../../../../../shared/widgets/open_vts_button.dart';
import '../../../../../shared/widgets/open_vts_text_field.dart';
import '../../../controllers/admin_providers.dart';
import '../../../models/admin_team_model.dart';

class AdminCreateTeamSheet extends ConsumerStatefulWidget {
  const AdminCreateTeamSheet({required this.isSubmitting, super.key});

  final bool isSubmitting;

  @override
  ConsumerState<AdminCreateTeamSheet> createState() =>
      _AdminCreateTeamSheetState();
}

class _AdminCreateTeamSheetState extends ConsumerState<AdminCreateTeamSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileNumberController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  var _mobilePrefixes = const <AdminTeamMobilePrefixOption>[];
  String? _mobilePrefix;
  var _isLoadingPrefixes = true;
  var _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _loadMobilePrefixes();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _mobileNumberController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
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
                if (_isLoadingPrefixes) ...[
                  const LinearProgressIndicator(minHeight: 2),
                  const SizedBox(height: OpenVtsSpacing.md),
                ],
                OpenVtsTextField(
                  label: 'Full Name',
                  controller: _nameController,
                  textInputAction: TextInputAction.next,
                  prefixIcon: Icons.person_outline_rounded,
                  validator: (value) =>
                      Validators.required(value, fieldName: 'Full name'),
                ),
                const SizedBox(height: OpenVtsSpacing.sm),
                OpenVtsTextField(
                  label: 'Email',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  prefixIcon: Icons.mail_outline_rounded,
                  validator: Validators.email,
                ),
                const SizedBox(height: OpenVtsSpacing.sm),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 124,
                      child: DropdownButtonFormField<String>(
                        key: ValueKey<String?>(
                          'team-mobile-prefix-${_mobilePrefix ?? ''}',
                        ),
                        initialValue: _mobilePrefix,
                        items: _mobilePrefixes
                            .map(
                              (item) => DropdownMenuItem<String>(
                                value: item.code,
                                child: Text(
                                  item.code,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(growable: false),
                        decoration: const InputDecoration(
                          labelText: 'Mobile Prefix',
                          prefixIcon: Icon(
                            Icons.phone_android_rounded,
                            size: 20,
                          ),
                        ),
                        onChanged: widget.isSubmitting
                            ? null
                            : (value) => setState(() => _mobilePrefix = value),
                        validator: (value) => Validators.required(
                          value,
                          fieldName: 'Mobile prefix',
                        ),
                      ),
                    ),
                    const SizedBox(width: OpenVtsSpacing.sm),
                    Expanded(
                      child: OpenVtsTextField(
                        label: 'Mobile Number',
                        controller: _mobileNumberController,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.next,
                        prefixIcon: Icons.phone_rounded,
                        validator: (value) => Validators.required(
                          value,
                          fieldName: 'Mobile number',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: OpenVtsSpacing.sm),
                OpenVtsTextField(
                  label: 'Username',
                  controller: _usernameController,
                  textInputAction: TextInputAction.next,
                  prefixIcon: Icons.alternate_email_rounded,
                  validator: (value) =>
                      Validators.required(value, fieldName: 'Username'),
                ),
                const SizedBox(height: OpenVtsSpacing.sm),
                OpenVtsTextField(
                  label: 'Password',
                  controller: _passwordController,
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
                  validator: _passwordValidator,
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
                      onPressed: widget.isSubmitting
                          ? null
                          : () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(width: OpenVtsSpacing.sm),
                  Expanded(
                    child: OpenVtsButton(
                      label: 'Save',
                      onPressed: widget.isSubmitting ? null : _submit,
                      isLoading: widget.isSubmitting,
                      trailingIcon: Icons.person_add_alt_1_rounded,
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

  Future<void> _loadMobilePrefixes() async {
    setState(() => _isLoadingPrefixes = true);

    try {
      final prefixes = await ref
          .read(adminTeamControllerProvider.notifier)
          .getMobilePrefixes();
      if (!mounted) {
        return;
      }

      String? selected;
      if (prefixes.isNotEmpty) {
        final preferred = prefixes.where((item) => item.code.trim() == '+91');
        selected =
            preferred.isNotEmpty ? preferred.first.code : prefixes.first.code;
      }

      setState(() {
        _mobilePrefixes = prefixes;
        _mobilePrefix = selected;
        _isLoadingPrefixes = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _mobilePrefixes = const <AdminTeamMobilePrefixOption>[];
        _mobilePrefix = null;
        _isLoadingPrefixes = false;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final request = AdminCreateTeamRequest(
      name: _nameController.text,
      email: _emailController.text,
      mobilePrefix: _mobilePrefix ?? '',
      mobileNumber: _mobileNumberController.text,
      username: _usernameController.text,
      password: _passwordController.text,
    );

    final success = await ref
        .read(adminTeamControllerProvider.notifier)
        .createTeam(request);

    if (!mounted) {
      return;
    }

    if (success) {
      Navigator.of(context).pop();
      ToastHelper.showSuccess('Team member created.', context: context);
      return;
    }

    final error = ref.read(adminTeamControllerProvider).createErrorMessage;
    ToastHelper.showError(
      error ?? 'Unable to create team member.',
      context: context,
    );
  }

  String? _passwordValidator(String? value) {
    final requiredError = Validators.required(value, fieldName: 'Password');
    if (requiredError != null) {
      return requiredError;
    }

    if (value!.trim().length < 8) {
      return 'Password must be at least 8 characters';
    }

    return null;
  }
}
