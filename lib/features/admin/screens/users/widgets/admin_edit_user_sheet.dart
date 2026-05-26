import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/open_vts_spacing.dart';
import '../../../../../core/utils/validators.dart';
import '../../../../../shared/helpers/toast_helper.dart';
import '../../../../../shared/widgets/open_vts_button.dart';
import '../../../../../shared/widgets/open_vts_text_field.dart';
import '../../../controllers/admin_providers.dart';
import '../../../models/admin_users_model.dart';
import 'admin_user_form_fields.dart';

class AdminEditUserSheet extends ConsumerStatefulWidget {
  const AdminEditUserSheet({
    required this.user,
    required this.isSubmitting,
    required this.onSubmit,
    super.key,
  });

  final AdminUserListItem user;
  final bool isSubmitting;
  final Future<void> Function(AdminUpdateUserRequest request) onSubmit;

  @override
  ConsumerState<AdminEditUserSheet> createState() => _AdminEditUserSheetState();
}

class _AdminEditUserSheetState extends ConsumerState<AdminEditUserSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _mobileNumberController;
  late final TextEditingController _usernameController;
  late final TextEditingController _companyNameController;
  late final TextEditingController _addressController;
  late final TextEditingController _pincodeController;

  var _mobilePrefixes = const <AdminUserMobilePrefixOption>[];
  var _countries = const <AdminUserCountryOption>[];
  var _states = const <AdminUserStateOption>[];
  var _cities = const <AdminUserCityOption>[];
  String? _mobilePrefix;
  String? _countryCode;
  String? _stateCode;
  String? _city;
  var _isLoadingReferences = true;
  var _isLoadingDetails = false;
  var _isLoadingStates = false;
  var _isLoadingCities = false;

  @override
  void initState() {
    super.initState();
    final user = widget.user;
    _nameController = TextEditingController(text: user.name);
    _emailController = TextEditingController(text: user.email);
    _mobileNumberController = TextEditingController(text: user.mobileNumber);
    _usernameController = TextEditingController(text: user.username);
    _companyNameController = TextEditingController(
      text: _initialText(user.companyName),
    );
    _addressController =
        TextEditingController(text: _initialText(user.location));
    _pincodeController = TextEditingController(text: user.pincode);
    _mobilePrefix = _blankToNull(user.mobilePrefix);
    _countryCode = _blankToNull(user.countryCode)?.toUpperCase();
    _stateCode = _blankToNull(user.stateCode)?.toUpperCase();
    _city = _blankToNull(user.city);
    _loadInitialData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _mobileNumberController.dispose();
    _usernameController.dispose();
    _companyNameController.dispose();
    _addressController.dispose();
    _pincodeController.dispose();
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
                if (_isLoadingReferences || _isLoadingDetails) ...[
                  const LinearProgressIndicator(minHeight: 2),
                  const SizedBox(height: OpenVtsSpacing.md),
                ],
                AdminUserFormSection(
                  title: 'Identity',
                  children: [
                    OpenVtsTextField(
                      label: 'Full Name',
                      controller: _nameController,
                      textInputAction: TextInputAction.next,
                      prefixIcon: Icons.person_outline_rounded,
                      validator: (value) => Validators.required(
                        value,
                        fieldName: 'Full name',
                      ),
                    ),
                    const SizedBox(height: OpenVtsSpacing.sm),
                    OpenVtsTextField(
                      label: 'Email',
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.email],
                      prefixIcon: Icons.mail_outline_rounded,
                      validator: Validators.email,
                    ),
                    const SizedBox(height: OpenVtsSpacing.sm),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 124,
                          child: AdminUserDropdownField(
                            label: 'Mobile Prefix',
                            value: _mobilePrefix,
                            options: _mobilePrefixOptions,
                            hintText: '+91',
                            prefixIcon: Icons.phone_android_rounded,
                            isLoading: _isLoadingReferences,
                            validator: requiredDropdown,
                            onChanged: (value) {
                              setState(() => _mobilePrefix = value);
                            },
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
                  ],
                ),
                const SizedBox(height: OpenVtsSpacing.lg),
                AdminUserFormSection(
                  title: 'Login',
                  children: [
                    OpenVtsTextField(
                      label: 'Username',
                      controller: _usernameController,
                      textInputAction: TextInputAction.next,
                      prefixIcon: Icons.alternate_email_rounded,
                      validator: (value) => Validators.required(
                        value,
                        fieldName: 'Username',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: OpenVtsSpacing.lg),
                AdminUserFormSection(
                  title: 'Company',
                  children: [
                    OpenVtsTextField(
                      label: 'Company Name',
                      controller: _companyNameController,
                      textInputAction: TextInputAction.next,
                      prefixIcon: Icons.apartment_rounded,
                      validator: (value) => Validators.required(
                        value,
                        fieldName: 'Company name',
                      ),
                    ),
                    const SizedBox(height: OpenVtsSpacing.sm),
                    OpenVtsTextField(
                      label: 'Address',
                      controller: _addressController,
                      textInputAction: TextInputAction.next,
                      prefixIcon: Icons.place_outlined,
                      maxLines: 2,
                      validator: (value) => Validators.required(
                        value,
                        fieldName: 'Address',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: OpenVtsSpacing.lg),
                AdminUserFormSection(
                  title: 'Location',
                  children: [
                    AdminUserDropdownField(
                      label: 'Country',
                      value: _countryCode,
                      options: _countryOptions,
                      hintText: 'Select country',
                      prefixIcon: Icons.public_rounded,
                      isLoading: _isLoadingReferences,
                      validator: requiredDropdown,
                      onChanged: _onCountryChanged,
                    ),
                    const SizedBox(height: OpenVtsSpacing.sm),
                    AdminUserDropdownField(
                      label: 'State',
                      value: _stateCode,
                      options: _stateOptions,
                      hintText: 'Select state',
                      prefixIcon: Icons.map_outlined,
                      isLoading: _isLoadingStates,
                      validator: requiredDropdown,
                      onChanged: _countryCode == null ? null : _onStateChanged,
                    ),
                    const SizedBox(height: OpenVtsSpacing.sm),
                    AdminUserDropdownField(
                      label: 'City',
                      value: _city,
                      options: _cityOptions,
                      hintText: 'Select city',
                      prefixIcon: Icons.location_city_rounded,
                      isLoading: _isLoadingCities,
                      validator: requiredDropdown,
                      onChanged: _stateCode == null
                          ? null
                          : (value) => setState(() => _city = value),
                    ),
                    const SizedBox(height: OpenVtsSpacing.sm),
                    OpenVtsTextField(
                      label: 'Pincode',
                      controller: _pincodeController,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
                      prefixIcon: Icons.pin_drop_outlined,
                      validator: _pincodeValidator,
                    ),
                  ],
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
                      trailingIcon: Icons.check_rounded,
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

  List<AdminUserDropdownOption> get _mobilePrefixOptions {
    return _mobilePrefixes
        .map(
          (item) => AdminUserDropdownOption(
            value: item.value,
            label: item.label,
          ),
        )
        .toList(growable: false);
  }

  List<AdminUserDropdownOption> get _countryOptions {
    return _countries
        .map(
          (item) => AdminUserDropdownOption(
            value: item.value,
            label: item.label,
          ),
        )
        .toList(growable: false);
  }

  List<AdminUserDropdownOption> get _stateOptions {
    return _states
        .map(
          (item) => AdminUserDropdownOption(
            value: item.value,
            label: item.label,
          ),
        )
        .toList(growable: false);
  }

  List<AdminUserDropdownOption> get _cityOptions {
    return _cities
        .map(
          (item) => AdminUserDropdownOption(
            value: item.value,
            label: item.label,
          ),
        )
        .toList(growable: false);
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoadingDetails = true);
    try {
      final controller = ref.read(adminUsersControllerProvider.notifier);
      final countriesFuture = controller.getCountries();
      final prefixesFuture = controller.getMobilePrefixes();
      final detailsFuture = controller
          .getUserDetails(widget.user.id)
          .then<AdminUserDetails?>((details) => details)
          .catchError((_) => null);

      final countries = await countriesFuture;
      final prefixes = await prefixesFuture;
      final details = await detailsFuture;

      if (!mounted) {
        return;
      }

      setState(() {
        _countries = countries;
        _mobilePrefixes = prefixes;
        _isLoadingReferences = false;
        _isLoadingDetails = false;
        if (details != null) {
          _applyUser(details);
        }
      });

      await _loadStates(_countryCode, clearSelection: false);
      await _loadCities(_countryCode, _stateCode, clearSelection: false);
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoadingReferences = false;
        _isLoadingDetails = false;
      });
      ToastHelper.showError(
        'Unable to load form options.',
        context: context,
      );
    }
  }

  Future<void> _onCountryChanged(String? value) async {
    if (value == _countryCode) {
      return;
    }

    setState(() {
      _countryCode = value;
      _stateCode = null;
      _city = null;
      _states = const <AdminUserStateOption>[];
      _cities = const <AdminUserCityOption>[];
    });

    await _loadStates(value, clearSelection: true);
  }

  Future<void> _onStateChanged(String? value) async {
    if (value == _stateCode) {
      return;
    }

    setState(() {
      _stateCode = value;
      _city = null;
      _cities = const <AdminUserCityOption>[];
    });

    await _loadCities(_countryCode, value, clearSelection: true);
  }

  Future<void> _loadStates(
    String? countryCode, {
    required bool clearSelection,
  }) async {
    final requestedCountry = countryCode?.trim().toUpperCase();
    if (requestedCountry == null || requestedCountry.isEmpty) {
      return;
    }

    setState(() => _isLoadingStates = true);
    try {
      final states = await ref
          .read(adminUsersControllerProvider.notifier)
          .getStates(requestedCountry);
      if (!mounted || _countryCode?.toUpperCase() != requestedCountry) {
        return;
      }

      setState(() {
        _states = states;
        if (clearSelection) {
          _stateCode = null;
        }
        _isLoadingStates = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _isLoadingStates = false);
      ToastHelper.showError('Unable to load states.', context: context);
    }
  }

  Future<void> _loadCities(
    String? countryCode,
    String? stateCode, {
    required bool clearSelection,
  }) async {
    final requestedCountry = countryCode?.trim().toUpperCase();
    final requestedState = stateCode?.trim().toUpperCase();
    if (requestedCountry == null ||
        requestedCountry.isEmpty ||
        requestedState == null ||
        requestedState.isEmpty) {
      return;
    }

    setState(() => _isLoadingCities = true);
    try {
      final cities =
          await ref.read(adminUsersControllerProvider.notifier).getCities(
                requestedCountry,
                requestedState,
              );
      if (!mounted ||
          _countryCode?.toUpperCase() != requestedCountry ||
          _stateCode?.toUpperCase() != requestedState) {
        return;
      }

      setState(() {
        _cities = cities;
        if (clearSelection) {
          _city = null;
        }
        _isLoadingCities = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _isLoadingCities = false);
      ToastHelper.showError('Unable to load cities.', context: context);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      await widget.onSubmit(
        AdminUpdateUserRequest(
          name: _nameController.text,
          email: _emailController.text,
          mobilePrefix: _mobilePrefix ?? '',
          mobileNumber: _mobileNumberController.text,
          username: _usernameController.text,
          companyName: _companyNameController.text,
          address: _addressController.text,
          countryCode: _countryCode ?? '',
          stateCode: _stateCode ?? '',
          city: _city ?? '',
          pincode: _pincodeController.text,
        ),
      );

      if (!mounted) {
        return;
      }
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) {
        return;
      }
      ToastHelper.showError(
        ref.read(adminUsersControllerProvider).errorMessage ??
            'Unable to update user.',
        context: context,
      );
    }
  }

  void _applyUser(AdminUserListItem user) {
    _nameController.text = user.name;
    _emailController.text = user.email;
    _mobileNumberController.text = user.mobileNumber;
    _usernameController.text = user.username;
    _companyNameController.text = _initialText(user.companyName);
    _addressController.text = _initialText(user.location);
    _pincodeController.text = user.pincode;
    _mobilePrefix = _blankToNull(user.mobilePrefix);
    _countryCode = _blankToNull(user.countryCode)?.toUpperCase();
    _stateCode = _blankToNull(user.stateCode)?.toUpperCase();
    _city = _blankToNull(user.city);
  }

  String? _pincodeValidator(String? value) {
    final normalized = value?.trim() ?? '';
    if (normalized.length > 10) {
      return 'Use 10 characters or fewer';
    }
    return null;
  }
}

String _initialText(String? value) {
  final normalized = value?.trim() ?? '';
  if (normalized.isEmpty || normalized == '-') {
    return '';
  }
  return normalized;
}

String? _blankToNull(String? value) {
  final normalized = value?.trim();
  if (normalized == null || normalized.isEmpty || normalized == '-') {
    return null;
  }
  return normalized;
}
