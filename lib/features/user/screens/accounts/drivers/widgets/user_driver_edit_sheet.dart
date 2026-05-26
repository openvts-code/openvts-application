import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../../core/theme/open_vts_colors.dart';
import '../../../../../../core/theme/open_vts_radius.dart';
import '../../../../../../core/theme/open_vts_spacing.dart';
import '../../../../../../core/theme/open_vts_typography.dart';
import '../../../../../../shared/helpers/toast_helper.dart';
import '../../../../../../shared/widgets/open_vts_button.dart';
import '../../../../../../shared/widgets/open_vts_text_field.dart';
import '../../../../controllers/user_driver_details_controller.dart';
import '../../../../controllers/user_providers.dart';
import '../../../../models/user_driver_model.dart';
import '../../../../models/user_drivers_state.dart';

class UserDriverEditSheet extends ConsumerStatefulWidget {
  const UserDriverEditSheet({
    required this.provider,
    required this.driver,
    super.key,
  });

  final AutoDisposeStateNotifierProvider<UserDriverDetailsController,
      UserDriverDetailsState> provider;
  final UserDriver driver;

  @override
  ConsumerState<UserDriverEditSheet> createState() =>
      _UserDriverEditSheetState();
}

class _UserDriverEditSheetState extends ConsumerState<UserDriverEditSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _addressController = TextEditingController();
  final _pincodeController = TextEditingController();

  var _obscurePassword = true;
  var _isLoadingReferences = true;
  var _isLoadingStates = false;
  var _isLoadingCities = false;

  var _mobilePrefix = '';
  var _countryCode = '';
  String? _stateCode;
  String? _city;
  var _isActive = true;

  List<UserDriverCountryOption> _countries = const <UserDriverCountryOption>[];
  List<UserDriverMobilePrefixOption> _mobilePrefixes =
      const <UserDriverMobilePrefixOption>[];
  List<UserDriverStateOption> _states = const <UserDriverStateOption>[];
  List<UserDriverCityOption> _cities = const <UserDriverCityOption>[];

  @override
  void initState() {
    super.initState();
    final driver = widget.driver;
    _nameController.text = driver.name;
    _mobileController.text = driver.mobile;
    _emailController.text = driver.email;
    _usernameController.text = driver.username;
    _addressController.text = driver.address;
    _pincodeController.text = driver.pincode;
    _mobilePrefix = driver.mobilePrefix.trim();
    _countryCode = driver.countryCode.trim().toUpperCase();
    _stateCode = _optionalValue(driver.stateCode)?.toUpperCase();
    _city = _optionalValue(driver.city);
    _isActive = driver.isActive;

    _loadReferenceData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _addressController.dispose();
    _pincodeController.dispose();
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
                    hintText: 'Driver name',
                    prefixIcon: Icons.badge_outlined,
                    textInputAction: TextInputAction.next,
                    validator: _nameValidator,
                  ),
                  const SizedBox(height: OpenVtsSpacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: _DropdownField(
                          label: 'Mobile Prefix',
                          value: _mobilePrefix,
                          options: _mobilePrefixOptions,
                          hintText: 'Select prefix',
                          prefixIcon: Icons.call_outlined,
                          isLoading: _isLoadingReferences,
                          validator: _requiredDropdown,
                          onChanged: (value) {
                            setState(() => _mobilePrefix = value ?? '');
                          },
                        ),
                      ),
                      const SizedBox(width: OpenVtsSpacing.sm),
                      Expanded(
                        flex: 2,
                        child: OpenVtsTextField(
                          label: 'Mobile',
                          controller: _mobileController,
                          hintText: '7 to 15 digits',
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.next,
                          prefixIcon: Icons.phone_outlined,
                          validator: _mobileValidator,
                        ),
                      ),
                    ],
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
                  OpenVtsTextField(
                    label: 'Username',
                    controller: _usernameController,
                    hintText: 'Username',
                    textInputAction: TextInputAction.next,
                    prefixIcon: Icons.alternate_email_rounded,
                    validator: _usernameValidator,
                  ),
                  const SizedBox(height: OpenVtsSpacing.sm),
                  OpenVtsTextField(
                    label: 'Password (optional)',
                    controller: _passwordController,
                    hintText: 'Leave blank to keep current password',
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.next,
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
                      ),
                    ),
                    validator: _optionalPasswordValidator,
                  ),
                  const SizedBox(height: OpenVtsSpacing.sm),
                  _DropdownField(
                    label: 'Country Code',
                    value: _countryCode,
                    options: _countryOptions,
                    hintText: 'Select country',
                    prefixIcon: Icons.public_rounded,
                    isLoading: _isLoadingReferences,
                    validator: _requiredDropdown,
                    onChanged: _onCountryChanged,
                  ),
                  const SizedBox(height: OpenVtsSpacing.sm),
                  _DropdownField(
                    label: 'State',
                    value: _stateCode,
                    options: _stateOptions,
                    hintText: 'Select state',
                    prefixIcon: Icons.map_outlined,
                    isLoading: _isLoadingStates,
                    onChanged: _onStateChanged,
                  ),
                  const SizedBox(height: OpenVtsSpacing.sm),
                  _DropdownField(
                    label: 'City',
                    value: _city,
                    options: _cityOptions,
                    hintText: 'Select city',
                    prefixIcon: Icons.location_city_outlined,
                    isLoading: _isLoadingCities,
                    onChanged: (value) => setState(() => _city = value),
                  ),
                  const SizedBox(height: OpenVtsSpacing.sm),
                  OpenVtsTextField(
                    label: 'Address',
                    controller: _addressController,
                    hintText: 'Address',
                    textInputAction: TextInputAction.next,
                    prefixIcon: Icons.home_outlined,
                  ),
                  const SizedBox(height: OpenVtsSpacing.sm),
                  OpenVtsTextField(
                    label: 'Pincode',
                    controller: _pincodeController,
                    hintText: 'Postal code',
                    textInputAction: TextInputAction.done,
                    prefixIcon: Icons.pin_drop_outlined,
                    validator: _pincodeValidator,
                  ),
                  const SizedBox(height: OpenVtsSpacing.sm),
                  _StatusToggle(
                    value: _isActive,
                    onChanged: (value) => setState(() => _isActive = value),
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
                    label: 'Save',
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

  List<_DropdownOption> get _mobilePrefixOptions {
    final options = _mobilePrefixes.map((item) {
      return _DropdownOption(
        value: item.value,
        label: item.label,
      );
    }).toList(growable: false);

    return _mergeCurrentOption(options, _mobilePrefix);
  }

  List<_DropdownOption> get _countryOptions {
    final options = _countries.map((item) {
      return _DropdownOption(
        value: item.value,
        label: item.label,
      );
    }).toList(growable: false);

    return _mergeCurrentOption(options, _countryCode);
  }

  List<_DropdownOption> get _stateOptions {
    final options = _states.map((item) {
      return _DropdownOption(
        value: item.value,
        label: item.label,
      );
    }).toList(growable: false);

    return _mergeCurrentOption(options, _stateCode);
  }

  List<_DropdownOption> get _cityOptions {
    final options = _cities.map((item) {
      return _DropdownOption(
        value: item.value,
        label: item.label,
      );
    }).toList(growable: false);

    return _mergeCurrentOption(options, _city);
  }

  Future<void> _loadReferenceData() async {
    try {
      final service = ref.read(userDriversServiceProvider);
      final countriesFuture = service.fetchCountries();
      final prefixesFuture = service.fetchMobilePrefixes();

      final countries = await countriesFuture;
      final prefixes = await prefixesFuture;

      if (!mounted) {
        return;
      }

      setState(() {
        _countries = countries;
        _mobilePrefixes = prefixes;
        _isLoadingReferences = false;
      });

      if (_countryCode.isNotEmpty) {
        await _loadStates(_countryCode);
      }
      if (_countryCode.isNotEmpty && (_stateCode ?? '').isNotEmpty) {
        await _loadCities(_countryCode, _stateCode);
      }
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() => _isLoadingReferences = false);
      ToastHelper.showError('Unable to load form options.', context: context);
    }
  }

  Future<void> _onCountryChanged(String? value) async {
    final nextCountry = value?.trim().toUpperCase() ?? '';
    if (nextCountry == _countryCode) {
      return;
    }

    setState(() {
      _countryCode = nextCountry;
      _stateCode = null;
      _city = null;
      _states = const <UserDriverStateOption>[];
      _cities = const <UserDriverCityOption>[];
    });

    await _loadStates(nextCountry);
  }

  Future<void> _onStateChanged(String? value) async {
    final nextState = value?.trim().toUpperCase();
    if (nextState == _stateCode) {
      return;
    }

    setState(() {
      _stateCode = nextState;
      _city = null;
      _cities = const <UserDriverCityOption>[];
    });

    await _loadCities(_countryCode, nextState);
  }

  Future<void> _loadStates(String? countryCode) async {
    final requestedCountry = countryCode?.trim().toUpperCase() ?? '';
    if (requestedCountry.isEmpty) {
      return;
    }

    setState(() => _isLoadingStates = true);
    try {
      final states = await ref
          .read(userDriversServiceProvider)
          .fetchStates(requestedCountry);

      if (!mounted || _countryCode != requestedCountry) {
        return;
      }

      setState(() {
        _states = states;
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

  Future<void> _loadCities(String? countryCode, String? stateCode) async {
    final requestedCountry = countryCode?.trim().toUpperCase() ?? '';
    final requestedState = stateCode?.trim().toUpperCase() ?? '';
    if (requestedCountry.isEmpty || requestedState.isEmpty) {
      return;
    }

    setState(() => _isLoadingCities = true);
    try {
      final cities = await ref
          .read(userDriversServiceProvider)
          .fetchCities(requestedCountry, requestedState);

      if (!mounted ||
          _countryCode != requestedCountry ||
          (_stateCode ?? '') != requestedState) {
        return;
      }

      setState(() {
        _cities = cities;
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
    FocusScope.of(context).unfocus();

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final request = UpdateUserDriverRequest(
      name: _nameController.text.trim(),
      mobilePrefix: _mobilePrefix.trim(),
      mobile: _mobileController.text.trim(),
      email: _optionalValue(_emailController.text),
      username: _usernameController.text.trim(),
      password: _optionalValue(_passwordController.text),
      countryCode: _countryCode.trim(),
      stateCode: _optionalValue(_stateCode),
      city: _optionalValue(_city),
      address: _optionalValue(_addressController.text),
      pincode: _optionalValue(_pincodeController.text),
      isActive: _isActive,
    );

    final ok = await ref.read(widget.provider.notifier).updateDriver(request);
    if (!mounted) {
      return;
    }

    if (ok) {
      ToastHelper.showSuccess('Driver updated.', context: context);
      Navigator.of(context).pop(true);
      return;
    }

    ToastHelper.showError(
      ref.read(widget.provider).errorMessage ?? 'Unable to update driver.',
      context: context,
    );
  }

  List<_DropdownOption> _mergeCurrentOption(
    List<_DropdownOption> options,
    String? currentValue,
  ) {
    final normalizedCurrent = currentValue?.trim() ?? '';
    if (normalizedCurrent.isEmpty) {
      return options;
    }

    final hasCurrent = options.any((item) => item.value == normalizedCurrent);
    if (hasCurrent) {
      return options;
    }

    return [
      _DropdownOption(
        value: normalizedCurrent,
        label: '$normalizedCurrent (current)',
        isFallback: true,
      ),
      ...options,
    ];
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

  String? _usernameValidator(String? value) {
    final normalized = value?.trim() ?? '';
    if (normalized.isEmpty) {
      return 'Username is required';
    }
    if (normalized.length < 3) {
      return 'Username must be at least 3 characters';
    }
    return null;
  }

  String? _optionalPasswordValidator(String? value) {
    final normalized = value?.trim() ?? '';
    if (normalized.isEmpty) {
      return null;
    }
    if (normalized.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  String? _mobileValidator(String? value) {
    final normalized = value?.trim() ?? '';
    if (normalized.isEmpty) {
      return 'Mobile number is required';
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

  String? _pincodeValidator(String? value) {
    final normalized = value?.trim() ?? '';
    if (normalized.isNotEmpty && normalized.length > 10) {
      return 'Use 10 digits or fewer';
    }
    return null;
  }

  String? _requiredDropdown(String? value) {
    final normalized = value?.trim() ?? '';
    if (normalized.isEmpty) {
      return 'Required';
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

class _StatusToggle extends StatelessWidget {
  const _StatusToggle({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: OpenVtsSpacing.sm,
        vertical: OpenVtsSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: OpenVtsColors.surface,
        borderRadius: BorderRadius.circular(OpenVtsRadius.sm),
        border: Border.all(color: OpenVtsColors.border),
      ),
      child: Row(
        children: [
          Icon(
            value
                ? Icons.check_circle_outline_rounded
                : Icons.pause_circle_outline_rounded,
            size: 18,
            color: OpenVtsColors.textSecondary,
          ),
          const SizedBox(width: OpenVtsSpacing.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Active',
                  style: OpenVtsTypography.label.copyWith(
                    color: OpenVtsColors.textPrimary,
                  ),
                ),
                Text(
                  value
                      ? 'Driver can access assigned vehicles'
                      : 'Driver is disabled',
                  style: OpenVtsTypography.meta.copyWith(
                    color: OpenVtsColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _DropdownOption {
  const _DropdownOption({
    required this.value,
    required this.label,
    this.isFallback = false,
  });

  final String value;
  final String label;
  final bool isFallback;
}

class _DropdownField extends StatelessWidget {
  const _DropdownField({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    this.hintText,
    this.prefixIcon,
    this.validator,
    this.isLoading = false,
  });

  final String label;
  final String? value;
  final List<_DropdownOption> options;
  final ValueChanged<String?>? onChanged;
  final String? hintText;
  final IconData? prefixIcon;
  final String? Function(String?)? validator;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final normalizedValue = _normalize(value);
    final menuItems = _menuItems(normalizedValue);
    final safeValue = menuItems.any((item) => item.value == normalizedValue)
        ? normalizedValue
        : null;
    final optionSignature = menuItems.map((item) => item.value ?? '').join('|');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: OpenVtsTypography.label),
        const SizedBox(height: OpenVtsSpacing.xs),
        DropdownButtonFormField<String>(
          key: ValueKey('$label:${safeValue ?? ''}:$optionSignature'),
          initialValue: safeValue,
          isExpanded: true,
          items: menuItems,
          onChanged: isLoading ? null : onChanged,
          validator: validator,
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: prefixIcon == null
                ? null
                : Icon(
                    prefixIcon,
                    size: 20,
                    color: OpenVtsColors.textSecondary,
                  ),
            suffixIcon: isLoading
                ? const Padding(
                    padding: EdgeInsets.all(14),
                    child: SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : null,
          ),
        ),
      ],
    );
  }

  List<DropdownMenuItem<String>> _menuItems(String? normalizedValue) {
    final distinctOptions = <_DropdownOption>[];
    final seen = <String>{};

    for (final option in options) {
      final optionValue = option.value.trim();
      if (optionValue.isEmpty || seen.contains(optionValue)) {
        continue;
      }
      seen.add(optionValue);
      distinctOptions.add(
        _DropdownOption(
          value: optionValue,
          label: option.label.trim().isEmpty ? optionValue : option.label,
          isFallback: option.isFallback,
        ),
      );
    }

    if (normalizedValue != null && !seen.contains(normalizedValue)) {
      distinctOptions.insert(
        0,
        _DropdownOption(
          value: normalizedValue,
          label: '$normalizedValue (current)',
          isFallback: true,
        ),
      );
    }

    return distinctOptions
        .map(
          (option) => DropdownMenuItem<String>(
            value: option.value,
            enabled: !option.isFallback,
            child: Text(
              option.label,
              overflow: TextOverflow.ellipsis,
              style: OpenVtsTypography.body.copyWith(
                color: option.isFallback
                    ? OpenVtsColors.textTertiary
                    : OpenVtsColors.textPrimary,
              ),
            ),
          ),
        )
        .toList(growable: false);
  }

  String? _normalize(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }
    return normalized;
  }
}
