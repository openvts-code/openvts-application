import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/open_vts_spacing.dart';
import '../../../../../core/utils/validators.dart';
import '../../../../../shared/helpers/toast_helper.dart';
import '../../../../../shared/widgets/open_vts_bottom_sheet.dart';
import '../../../../../shared/widgets/open_vts_button.dart';
import '../../../../../shared/widgets/open_vts_text_field.dart';
import '../../../controllers/admin_drivers_controller.dart';
import '../../../models/admin_drivers_model.dart';
import '../../../models/admin_drivers_state.dart';

Future<void> showDriverCreateSheet({
  required BuildContext context,
  required AutoDisposeStateNotifierProvider<AdminDriversController,
          AdminDriversState>
      provider,
}) {
  return OpenVtsBottomSheet.show<void>(
    context: context,
    title: 'Add Driver',
    initialChildSize: 0.9,
    minChildSize: 0.5,
    maxChildSize: 0.96,
    child: _DriverCreateSheet(provider: provider),
  );
}

class _DriverCreateSheet extends ConsumerStatefulWidget {
  const _DriverCreateSheet({required this.provider});

  final AutoDisposeStateNotifierProvider<AdminDriversController,
      AdminDriversState> provider;

  @override
  ConsumerState<_DriverCreateSheet> createState() => _DriverCreateSheetState();
}

class _DriverCreateSheetState extends ConsumerState<_DriverCreateSheet> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _mobilePrefix = TextEditingController(text: '+91');
  final _mobile = TextEditingController();
  final _email = TextEditingController();
  final _username = TextEditingController();
  final _password = TextEditingController();
  final _countryCode = TextEditingController();
  final _stateCode = TextEditingController();
  final _city = TextEditingController();
  final _address = TextEditingController();
  final _pincode = TextEditingController();
  var _obscurePassword = true;
  var _loadingUsers = true;
  var _primaryUsers = const <AdminDriverListItem>[];
  String? _primaryUserId;

  @override
  void initState() {
    super.initState();
    _loadPrimaryUsers();
  }

  @override
  void dispose() {
    _name.dispose();
    _mobilePrefix.dispose();
    _mobile.dispose();
    _email.dispose();
    _username.dispose();
    _password.dispose();
    _countryCode.dispose();
    _stateCode.dispose();
    _city.dispose();
    _address.dispose();
    _pincode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(widget.provider);
    final controller = ref.read(widget.provider.notifier);

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
                if (_loadingUsers) ...[
                  const LinearProgressIndicator(minHeight: 2),
                  const SizedBox(height: OpenVtsSpacing.md),
                ],
                DropdownButtonFormField<String>(
                  initialValue: _primaryUserId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Primary User',
                    prefixIcon: Icon(Icons.person_search_outlined),
                  ),
                  items: _primaryUsers
                      .map(
                        (user) => DropdownMenuItem<String>(
                          value: user.id,
                          child: Text(
                            _primaryLabel(user),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (value) => setState(() => _primaryUserId = value),
                  validator: (value) => Validators.required(
                    value,
                    fieldName: 'Primary user',
                  ),
                ),
                const SizedBox(height: OpenVtsSpacing.sm),
                OpenVtsTextField(
                  label: 'Name',
                  controller: _name,
                  prefixIcon: Icons.person_outline_rounded,
                  validator: (value) =>
                      Validators.required(value, fieldName: 'Name'),
                ),
                const SizedBox(height: OpenVtsSpacing.sm),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 124,
                      child: OpenVtsTextField(
                        label: 'Mobile Prefix',
                        controller: _mobilePrefix,
                        prefixIcon: Icons.phone_android_rounded,
                        validator: (value) => Validators.required(
                          value,
                          fieldName: 'Mobile prefix',
                        ),
                      ),
                    ),
                    const SizedBox(width: OpenVtsSpacing.sm),
                    Expanded(
                      child: OpenVtsTextField(
                        label: 'Mobile',
                        controller: _mobile,
                        keyboardType: TextInputType.phone,
                        prefixIcon: Icons.phone_rounded,
                        validator: (value) =>
                            Validators.required(value, fieldName: 'Mobile'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: OpenVtsSpacing.sm),
                OpenVtsTextField(
                  label: 'Email',
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icons.mail_outline_rounded,
                  validator: (value) {
                    final text = value?.trim() ?? '';
                    if (text.isEmpty) return null;
                    return Validators.email(text);
                  },
                ),
                const SizedBox(height: OpenVtsSpacing.sm),
                OpenVtsTextField(
                  label: 'Username',
                  controller: _username,
                  prefixIcon: Icons.alternate_email_rounded,
                  validator: (value) =>
                      Validators.required(value, fieldName: 'Username'),
                ),
                const SizedBox(height: OpenVtsSpacing.sm),
                OpenVtsTextField(
                  label: 'Password',
                  controller: _password,
                  obscureText: _obscurePassword,
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
                  validator: (value) {
                    final text = value?.trim() ?? '';
                    if (text.isEmpty) return 'Password is required';
                    if (text.length < 6) return 'Minimum 6 characters';
                    return null;
                  },
                ),
                const SizedBox(height: OpenVtsSpacing.sm),
                OpenVtsTextField(
                  label: 'Country Code',
                  controller: _countryCode,
                  prefixIcon: Icons.public_rounded,
                  validator: (value) =>
                      Validators.required(value, fieldName: 'Country code'),
                ),
                const SizedBox(height: OpenVtsSpacing.sm),
                OpenVtsTextField(
                  label: 'State Code',
                  controller: _stateCode,
                  prefixIcon: Icons.map_outlined,
                ),
                const SizedBox(height: OpenVtsSpacing.sm),
                OpenVtsTextField(
                  label: 'City',
                  controller: _city,
                  prefixIcon: Icons.location_city_rounded,
                ),
                const SizedBox(height: OpenVtsSpacing.sm),
                OpenVtsTextField(
                  label: 'Address',
                  controller: _address,
                  prefixIcon: Icons.place_outlined,
                  maxLines: 2,
                ),
                const SizedBox(height: OpenVtsSpacing.sm),
                OpenVtsTextField(
                  label: 'Pincode',
                  controller: _pincode,
                  keyboardType: TextInputType.number,
                  prefixIcon: Icons.pin_drop_outlined,
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
                      onPressed: state.isCreating
                          ? null
                          : () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(width: OpenVtsSpacing.sm),
                  Expanded(
                    child: OpenVtsButton(
                      label: 'Create driver',
                      isLoading: state.isCreating,
                      trailingIcon: Icons.person_add_alt_1_rounded,
                      onPressed: state.isCreating
                          ? null
                          : () => _submit(context, controller),
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

  Future<void> _loadPrimaryUsers() async {
    try {
      final users = await ref
          .read(widget.provider.notifier)
          .fetchUsersForPrimarySelection();
      if (!mounted) return;
      setState(() {
        _primaryUsers = users;
        _primaryUserId = users.isNotEmpty ? users.first.id : null;
      });
    } catch (_) {
      if (mounted) {
        ToastHelper.showError('Unable to load users.', context: context);
      }
    } finally {
      if (mounted) setState(() => _loadingUsers = false);
    }
  }

  Future<void> _submit(
    BuildContext context,
    AdminDriversController controller,
  ) async {
    if (!_formKey.currentState!.validate()) return;

    final request = AdminDriverCreateRequest(
      primaryUserid: _primaryUserId ?? '',
      name: _name.text,
      mobilePrefix: _mobilePrefix.text,
      mobile: _mobile.text,
      email: _email.text,
      username: _username.text,
      password: _password.text,
      countryCode: _countryCode.text,
      stateCode: _stateCode.text,
      city: _city.text,
      address: _address.text,
      pincode: _pincode.text,
    );

    try {
      await controller.createDriver(request);
      if (!context.mounted) return;
      ToastHelper.showSuccess('Driver created.', context: context);
      Navigator.of(context).pop();
    } catch (_) {
      if (!context.mounted) return;
      ToastHelper.showError(
        ref.read(widget.provider).errorMessage ?? 'Unable to create driver.',
        context: context,
      );
    }
  }

  String _primaryLabel(AdminDriverListItem user) {
    final name =
        user.firstName.trim().isNotEmpty ? user.firstName.trim() : 'User';
    final email = user.email.trim();
    if (email.isNotEmpty && email != '-') {
      return '$name • $email';
    }
    final phone = user.phone.trim();
    if (phone.isNotEmpty && phone != '-') {
      return '$name • $phone';
    }
    return name;
  }
}
