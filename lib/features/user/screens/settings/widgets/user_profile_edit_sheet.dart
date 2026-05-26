import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/open_vts_colors.dart';
import '../../../../../core/theme/open_vts_radius.dart';
import '../../../../../core/theme/open_vts_spacing.dart';
import '../../../../../core/theme/open_vts_typography.dart';
import '../../../../../shared/widgets/open_vts_button.dart';
import '../../../controllers/user_providers.dart';
import '../../../controllers/user_settings_controller.dart';
import '../../../models/user_settings_model.dart';

class UserProfileEditSheet extends ConsumerStatefulWidget {
  const UserProfileEditSheet({
    required this.profile,
    required this.controller,
    super.key,
  });

  final UserSettingsProfile profile;
  final UserSettingsController controller;

  @override
  ConsumerState<UserProfileEditSheet> createState() =>
      _UserProfileEditSheetState();
}

class _UserProfileEditSheetState extends ConsumerState<UserProfileEditSheet> {
  static final RegExp _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _mobilePrefixController;
  late final TextEditingController _mobileNumberController;
  late final TextEditingController _addressController;
  late final TextEditingController _countryController;
  late final TextEditingController _stateController;
  late final TextEditingController _cityController;
  late final TextEditingController _pincodeController;

  late String _selectedCountry;
  late String _selectedState;
  late String _selectedCity;
  late String _selectedMobilePrefix;

  bool _isSaving = false;
  String? _submitError;

  @override
  void initState() {
    super.initState();
    final address = widget.profile.address;

    _nameController = TextEditingController(text: widget.profile.name ?? '');
    _emailController = TextEditingController(text: widget.profile.email ?? '');
    _mobilePrefixController =
        TextEditingController(text: widget.profile.mobilePrefix ?? '');
    _mobileNumberController =
        TextEditingController(text: widget.profile.mobileNumber ?? '');
    _addressController =
        TextEditingController(text: address?.addressLine ?? '');
    _countryController =
        TextEditingController(text: address?.countryCode ?? '');
    _stateController = TextEditingController(text: address?.stateCode ?? '');
    _cityController = TextEditingController(text: address?.cityName ?? '');
    _pincodeController = TextEditingController(text: address?.pincode ?? '');

    _selectedCountry = (address?.countryCode ?? '').trim().toUpperCase();
    _selectedState = (address?.stateCode ?? '').trim().toUpperCase();
    _selectedCity = (address?.cityName ?? '').trim();
    _selectedMobilePrefix = (widget.profile.mobilePrefix ?? '').trim();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDependentOptions();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _mobilePrefixController.dispose();
    _mobileNumberController.dispose();
    _addressController.dispose();
    _countryController.dispose();
    _stateController.dispose();
    _cityController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  Future<void> _loadDependentOptions() async {
    if (_selectedCountry.isNotEmpty) {
      await widget.controller.loadStates(_selectedCountry);
    }
    if (_selectedCountry.isNotEmpty && _selectedState.isNotEmpty) {
      await widget.controller.loadCities(_selectedCountry, _selectedState);
    }
  }

  Future<void> _onCountryChanged(String countryCode) async {
    final normalized = countryCode.trim().toUpperCase();
    setState(() {
      _selectedCountry = normalized;
      _selectedState = '';
      _selectedCity = '';
      _countryController.text = normalized;
      _stateController.clear();
      _cityController.clear();
      _submitError = null;
    });
    await widget.controller.loadStates(normalized);
  }

  Future<void> _onStateChanged(String stateCode) async {
    final normalized = stateCode.trim().toUpperCase();
    setState(() {
      _selectedState = normalized;
      _selectedCity = '';
      _stateController.text = normalized;
      _cityController.clear();
      _submitError = null;
    });
    await widget.controller.loadCities(_selectedCountry, normalized);
  }

  Future<void> _handleSave() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }

    final normalizedName = _nameController.text.trim();
    final normalizedEmail = _emailController.text.trim();
    final normalizedPrefix = _effectivePrefix();
    final normalizedMobile = _mobileNumberController.text.trim();
    final normalizedAddress = _addressController.text.trim();
    final normalizedCountry = _effectiveCountry();
    final normalizedState = _effectiveState();
    final normalizedCity = _effectiveCity();
    final normalizedPincode = _pincodeController.text.trim();

    widget.controller.patchDraftProfile(
      name: normalizedName,
      email: normalizedEmail.isEmpty ? '' : normalizedEmail,
      mobilePrefix: normalizedPrefix,
      mobileNumber: normalizedMobile,
      addressLine: normalizedAddress,
      countryCode: normalizedCountry,
      stateCode: normalizedState,
      cityName: normalizedCity,
      pincode: normalizedPincode,
    );

    setState(() {
      _isSaving = true;
      _submitError = null;
    });

    final ok = await widget.controller.saveProfile();
    if (!mounted) {
      return;
    }

    setState(() {
      _isSaving = false;
      if (!ok) {
        _submitError =
            ref.read(userSettingsControllerProvider).profileErrorMessage ??
                'Unable to save profile details.';
      }
    });

    if (ok) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(userSettingsControllerProvider);
    final insets = MediaQuery.viewInsetsOf(context).bottom;

    final mobilePrefixOptions = state.mobilePrefixes;
    final countryOptions = state.countries;
    final stateOptions = state.states;
    final cityOptions = state.cities;

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: OpenVtsColors.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(OpenVtsRadius.lg),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            OpenVtsSpacing.md,
            OpenVtsSpacing.md,
            OpenVtsSpacing.md,
            OpenVtsSpacing.md + insets,
          ),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Edit Profile',
                  style: OpenVtsTypography.label.copyWith(
                    color: OpenVtsColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: OpenVtsSpacing.xxs),
                Text(
                  'Update personal and address details. Changes are saved only when you confirm.',
                  style: OpenVtsTypography.meta.copyWith(
                    color: OpenVtsColors.textSecondary,
                  ),
                ),
                const SizedBox(height: OpenVtsSpacing.sm),
                _textField(
                  controller: _nameController,
                  label: 'Name',
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    final name = (value ?? '').trim();
                    if (name.length < 2) {
                      return 'Name must be at least 2 characters.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: OpenVtsSpacing.xs),
                _textField(
                  controller: _emailController,
                  label: 'Email (optional)',
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    final email = (value ?? '').trim();
                    if (email.isEmpty) {
                      return null;
                    }
                    if (!_emailPattern.hasMatch(email)) {
                      return 'Enter a valid email.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: OpenVtsSpacing.xs),
                if (mobilePrefixOptions.isEmpty)
                  _textField(
                    controller: _mobilePrefixController,
                    label: 'Mobile Prefix',
                    hint: '+1',
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      if ((value ?? '').trim().isEmpty) {
                        return 'Mobile prefix is required.';
                      }
                      return null;
                    },
                  )
                else
                  _dropdownField<String>(
                    label: 'Mobile Prefix',
                    value: _safeDropdownValue(
                      _selectedMobilePrefix,
                      mobilePrefixOptions.map((option) => option.value),
                    ),
                    items: mobilePrefixOptions
                        .map(
                          (option) => DropdownMenuItem<String>(
                            value: option.value,
                            child: Text(
                              option.label,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(growable: false),
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }
                      setState(() {
                        _selectedMobilePrefix = value;
                        _mobilePrefixController.text = value;
                      });
                    },
                  ),
                const SizedBox(height: OpenVtsSpacing.xs),
                _textField(
                  controller: _mobileNumberController,
                  label: 'Mobile Number',
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(15),
                  ],
                  validator: (value) {
                    final mobile = (value ?? '').trim();
                    if (mobile.length < 7 || mobile.length > 15) {
                      return 'Mobile must be 7 to 15 digits.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: OpenVtsSpacing.xs),
                _textField(
                  controller: _addressController,
                  label: 'Address Line',
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if ((value ?? '').trim().isEmpty) {
                      return 'Address is required.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: OpenVtsSpacing.xs),
                if (countryOptions.isEmpty)
                  _textField(
                    controller: _countryController,
                    label: 'Country Code',
                    hint: 'US',
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      if ((value ?? '').trim().isEmpty) {
                        return 'Country is required.';
                      }
                      return null;
                    },
                  )
                else
                  _dropdownField<String>(
                    label: 'Country',
                    value: _safeDropdownValue(
                      _selectedCountry,
                      countryOptions.map((option) => option.value),
                    ),
                    items: countryOptions
                        .map(
                          (option) => DropdownMenuItem<String>(
                            value: option.value,
                            child: Text(
                              option.label,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(growable: false),
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }
                      _onCountryChanged(value);
                    },
                  ),
                const SizedBox(height: OpenVtsSpacing.xs),
                if (stateOptions.isEmpty)
                  _textField(
                    controller: _stateController,
                    label: 'State Code',
                    hint: 'CA',
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      if ((value ?? '').trim().isEmpty) {
                        return 'State is required.';
                      }
                      return null;
                    },
                  )
                else
                  _dropdownField<String>(
                    label: 'State',
                    value: _safeDropdownValue(
                      _selectedState,
                      stateOptions.map((option) => option.value),
                    ),
                    items: stateOptions
                        .map(
                          (option) => DropdownMenuItem<String>(
                            value: option.value,
                            child: Text(
                              option.label,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(growable: false),
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }
                      _onStateChanged(value);
                    },
                  ),
                const SizedBox(height: OpenVtsSpacing.xs),
                if (cityOptions.isEmpty)
                  _textField(
                    controller: _cityController,
                    label: 'City',
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      if ((value ?? '').trim().isEmpty) {
                        return 'City is required.';
                      }
                      return null;
                    },
                  )
                else
                  _dropdownField<String>(
                    label: 'City',
                    value: _safeDropdownValue(
                      _selectedCity,
                      cityOptions.map((option) => option.value),
                    ),
                    items: cityOptions
                        .map(
                          (option) => DropdownMenuItem<String>(
                            value: option.value,
                            child: Text(
                              option.label,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(growable: false),
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }
                      setState(() {
                        _selectedCity = value;
                        _cityController.text = value;
                      });
                    },
                  ),
                const SizedBox(height: OpenVtsSpacing.xs),
                _textField(
                  controller: _pincodeController,
                  label: 'Pincode',
                  hint: 'Optional',
                  textInputAction: TextInputAction.done,
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(12),
                  ],
                  validator: (value) {
                    final pin = (value ?? '').trim();
                    if (pin.length > 12) {
                      return 'Pincode max length is 12.';
                    }
                    return null;
                  },
                ),
                if (_submitError != null) ...[
                  const SizedBox(height: OpenVtsSpacing.xs),
                  Text(
                    _submitError!,
                    style: OpenVtsTypography.meta.copyWith(
                      color: OpenVtsColors.warning,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: OpenVtsSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: OpenVtsButton(
                        label: 'Cancel',
                        variant: OpenVtsButtonVariant.secondary,
                        height: 44,
                        onPressed: _isSaving
                            ? null
                            : () => Navigator.of(context).pop(false),
                      ),
                    ),
                    const SizedBox(width: OpenVtsSpacing.xs),
                    Expanded(
                      child: OpenVtsButton(
                        label: 'Save Profile',
                        height: 44,
                        isLoading: _isSaving,
                        onPressed: _isSaving ? null : _handleSave,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String label,
    String? hint,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      inputFormatters: inputFormatters,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
      ),
    );
  }

  Widget _dropdownField<T>({
    required String label,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      items: items,
      onChanged: onChanged,
      validator: (value) {
        if (value == null || (value is String && value.trim().isEmpty)) {
          return '$label is required.';
        }
        return null;
      },
    );
  }

  T? _safeDropdownValue<T>(T value, Iterable<T> values) {
    for (final item in values) {
      if (item == value) {
        return item;
      }
    }
    return null;
  }

  String _effectivePrefix() {
    final selected = _selectedMobilePrefix.trim();
    if (selected.isNotEmpty) {
      return selected;
    }
    return _mobilePrefixController.text.trim();
  }

  String _effectiveCountry() {
    final selected = _selectedCountry.trim().toUpperCase();
    if (selected.isNotEmpty) {
      return selected;
    }
    return _countryController.text.trim().toUpperCase();
  }

  String _effectiveState() {
    final selected = _selectedState.trim().toUpperCase();
    if (selected.isNotEmpty) {
      return selected;
    }
    return _stateController.text.trim().toUpperCase();
  }

  String _effectiveCity() {
    final selected = _selectedCity.trim();
    if (selected.isNotEmpty) {
      return selected;
    }
    return _cityController.text.trim();
  }
}
