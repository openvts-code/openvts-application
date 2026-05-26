import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/open_vts_colors.dart';
import '../../../../core/theme/open_vts_radius.dart';
import '../../../../core/theme/open_vts_spacing.dart';
import '../../../../core/theme/open_vts_typography.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/helpers/toast_helper.dart';
import '../../../../shared/widgets/open_vts_button.dart';
import '../../../../shared/widgets/open_vts_error_view.dart';
import '../../../../shared/widgets/open_vts_loader.dart';
import '../../../../shared/widgets/open_vts_page_scaffold.dart';
import '../../../../shared/widgets/open_vts_searchable_dropdown.dart';
import '../../../../shared/widgets/open_vts_text_field.dart';
import '../../controllers/admin_providers.dart';
import '../../models/admin_users_model.dart';

class AdminCreateUserScreen extends ConsumerStatefulWidget {
  const AdminCreateUserScreen({super.key});

  @override
  ConsumerState<AdminCreateUserScreen> createState() =>
      _AdminCreateUserScreenState();
}

class _AdminCreateUserScreenState extends ConsumerState<AdminCreateUserScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileNumberController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _companyController = TextEditingController();
  final _addressController = TextEditingController();
  final _pincodeController = TextEditingController();

  var _countries = const <AdminUserCountryOption>[];
  var _mobilePrefixes = const <AdminUserMobilePrefixOption>[];
  var _states = const <AdminUserStateOption>[];
  var _cities = const <AdminUserCityOption>[];

  String? _selectedMobilePrefix;
  String? _selectedCountryCode;
  String? _selectedStateCode;
  String? _selectedCityName;

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  bool _isCatalogLoading = true;
  bool _isLoadingStates = false;
  bool _isLoadingCities = false;
  String? _catalogError;

  bool _catalogPrepared = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _prepareCatalog());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _mobileNumberController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _companyController.dispose();
    _addressController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  Future<void> _prepareCatalog() async {
    if (_catalogPrepared) {
      return;
    }
    _catalogPrepared = true;

    setState(() {
      _isCatalogLoading = true;
      _catalogError = null;
    });

    try {
      final controller = ref.read(adminUsersControllerProvider.notifier);
      final results = await Future.wait([
        controller.getCountries(),
        controller.getMobilePrefixes(),
      ]);

      if (!mounted) {
        return;
      }

      setState(() {
        _countries = results[0] as List<AdminUserCountryOption>;
        _mobilePrefixes = results[1] as List<AdminUserMobilePrefixOption>;
        _isCatalogLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isCatalogLoading = false;
        _catalogError = error.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final usersState = ref.watch(adminUsersControllerProvider);

    return OpenVtsPageScaffold(
      title: 'Create User',
      headerMode: OpenVtsPageHeaderMode.closeable,
      onClose: () => _handleClose(context),
      padding: EdgeInsets.zero,
      body: SafeArea(
        top: false,
        child: _isCatalogLoading && _countries.isEmpty
            ? const Center(child: OpenVtsLoader())
            : _catalogError != null && _countries.isEmpty
                ? OpenVtsErrorView(
                    message: _catalogError!,
                    onRetry: () {
                      _catalogPrepared = false;
                      _prepareCatalog();
                    },
                  )
                : _buildForm(context, usersState.isCreating),
      ),
    );
  }

  Widget _buildForm(BuildContext context, bool isSubmitting) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              OpenVtsSpacing.sm,
              OpenVtsSpacing.sm,
              OpenVtsSpacing.sm,
              OpenVtsSpacing.md,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _IntroBanner(),
                  const SizedBox(height: OpenVtsSpacing.sm),
                  _personalSection(),
                  const SizedBox(height: OpenVtsSpacing.sm),
                  _accountSection(),
                  const SizedBox(height: OpenVtsSpacing.sm),
                  _companySection(),
                  const SizedBox(height: OpenVtsSpacing.sm),
                  _locationSection(),
                ],
              ),
            ),
          ),
        ),
        _StickyActionBar(
          isSubmitting: isSubmitting,
          onCancel: () {
            if (isSubmitting) {
              return;
            }
            _handleClose(context);
          },
          onSubmit: isSubmitting ? null : _submit,
        ),
      ],
    );
  }

  Widget _personalSection() {
    final mobileOptions = _mobilePrefixes
        .map(
          (option) => OpenVtsDropdownOption<String>(
            value: option.value,
            label: option.value,
            subtitle: option.countryCode,
            searchText:
                '${option.value} ${option.countryCode} ${option.label}',
          ),
        )
        .toList(growable: false);

    return _FormSection(
      icon: Icons.person_outline_rounded,
      title: 'Personal information',
      description: 'How the user will be identified on the platform.',
      children: [
        OpenVtsTextField(
          label: 'Full name',
          hintText: 'Jane Smith',
          controller: _nameController,
          textInputAction: TextInputAction.next,
          validator: (value) =>
              Validators.required(value, fieldName: 'Full name'),
        ),
        OpenVtsTextField(
          label: 'Email',
          hintText: 'jane@company.com',
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          validator: Validators.email,
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 520) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  OpenVtsSearchableDropdown<String>(
                    label: 'Mobile prefix',
                    hintText: '+91',
                    sheetTitle: 'Select mobile prefix',
                    searchHintText: 'Search dial code or country',
                    leadingIcon: Icons.public_rounded,
                    options: mobileOptions,
                    value: _selectedMobilePrefix,
                    onChanged: (value) =>
                        setState(() => _selectedMobilePrefix = value),
                  ),
                  const SizedBox(height: OpenVtsSpacing.md),
                  OpenVtsTextField(
                    label: 'Mobile number',
                    hintText: '7856565655',
                    controller: _mobileNumberController,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    validator: (value) => Validators.required(
                      value,
                      fieldName: 'Mobile number',
                    ),
                  ),
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: OpenVtsSearchableDropdown<String>(
                    label: 'Mobile prefix',
                    hintText: '+91',
                    sheetTitle: 'Select mobile prefix',
                    searchHintText: 'Search dial code or country',
                    leadingIcon: Icons.public_rounded,
                    options: mobileOptions,
                    value: _selectedMobilePrefix,
                    onChanged: (value) =>
                        setState(() => _selectedMobilePrefix = value),
                  ),
                ),
                const SizedBox(width: OpenVtsSpacing.md),
                Expanded(
                  flex: 2,
                  child: OpenVtsTextField(
                    label: 'Mobile number',
                    hintText: '7856565655',
                    controller: _mobileNumberController,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    validator: (value) => Validators.required(
                      value,
                      fieldName: 'Mobile number',
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _accountSection() {
    return _FormSection(
      icon: Icons.lock_outline_rounded,
      title: 'Account access',
      description: 'Credentials the user will use to sign into OpenVTS.',
      children: [
        OpenVtsTextField(
          label: 'Username',
          hintText: 'janesmith',
          controller: _usernameController,
          textInputAction: TextInputAction.next,
          validator: (value) =>
              Validators.required(value, fieldName: 'Username'),
        ),
        OpenVtsTextField(
          label: 'Password',
          hintText: 'Minimum 8 characters',
          controller: _passwordController,
          obscureText: _obscurePassword,
          textInputAction: TextInputAction.next,
          suffixIcon: IconButton(
            tooltip: _obscurePassword ? 'Show password' : 'Hide password',
            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            icon: Icon(
              _obscurePassword
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              size: 18,
              color: OpenVtsColors.textSecondary,
            ),
          ),
          validator: (value) {
            final requiredMessage =
                Validators.required(value, fieldName: 'Password');
            if (requiredMessage != null) {
              return requiredMessage;
            }
            if ((value?.trim().length ?? 0) < 8) {
              return 'Password must be at least 8 characters';
            }
            return null;
          },
        ),
        OpenVtsTextField(
          label: 'Confirm password',
          hintText: 'Re-enter the password',
          controller: _confirmPasswordController,
          obscureText: _obscureConfirmPassword,
          textInputAction: TextInputAction.next,
          suffixIcon: IconButton(
            tooltip: _obscureConfirmPassword
                ? 'Show password'
                : 'Hide password',
            onPressed: () => setState(
              () => _obscureConfirmPassword = !_obscureConfirmPassword,
            ),
            icon: Icon(
              _obscureConfirmPassword
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              size: 18,
              color: OpenVtsColors.textSecondary,
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please confirm the password';
            }
            if (value != _passwordController.text) {
              return 'Passwords do not match';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _companySection() {
    return _FormSection(
      icon: Icons.business_outlined,
      title: 'Company',
      description: 'The organisation this user belongs to within OpenVTS.',
      children: [
        OpenVtsTextField(
          label: 'Company name',
          hintText: 'Acme Logistics Pvt. Ltd.',
          controller: _companyController,
          textInputAction: TextInputAction.next,
          validator: (value) =>
              Validators.required(value, fieldName: 'Company name'),
        ),
        OpenVtsTextField(
          label: 'Address',
          hintText: 'Street, building, area\u2026',
          controller: _addressController,
          maxLines: 3,
          textInputAction: TextInputAction.newline,
          validator: (value) =>
              Validators.required(value, fieldName: 'Address'),
        ),
      ],
    );
  }

  Widget _locationSection() {
    final countryOptions = _countries
        .map(
          (country) => OpenVtsDropdownOption<String>(
            value: country.value,
            label: country.label,
            subtitle: country.value,
            searchText: country.value,
          ),
        )
        .toList(growable: false);

    final stateOptions = _states
        .map(
          (option) => OpenVtsDropdownOption<String>(
            value: option.value,
            label: option.label,
            subtitle: option.value,
            searchText: option.value,
          ),
        )
        .toList(growable: false);

    final cityOptions = _cities
        .map(
          (option) => OpenVtsDropdownOption<String>(
            value: option.value,
            label: option.label,
          ),
        )
        .toList(growable: false);

    return _FormSection(
      icon: Icons.location_on_outlined,
      title: 'Location',
      description:
          'Used for regional defaults like currency, timezone, and routing.',
      children: [
        OpenVtsSearchableDropdown<String>(
          label: 'Country',
          required: true,
          hintText: 'Select a country',
          searchHintText: 'Search country or ISO code',
          sheetTitle: 'Select country',
          leadingIcon: Icons.public_rounded,
          options: countryOptions,
          value: _selectedCountryCode,
          isLoading: _isCatalogLoading && countryOptions.isEmpty,
          validator: (value) => value == null || value.trim().isEmpty
              ? 'Country is required'
              : null,
          onChanged: (value) async {
            setState(() {
              _selectedCountryCode = value;
              _selectedStateCode = null;
              _selectedCityName = null;
              _states = const <AdminUserStateOption>[];
              _cities = const <AdminUserCityOption>[];
              _selectedMobilePrefix = _mobilePrefixes
                  .where((item) => item.countryCode == value)
                  .map((item) => item.value)
                  .cast<String?>()
                  .firstOrNull;
            });

            if (value != null && value.trim().isNotEmpty) {
              await _loadStates(value);
            }
          },
        ),
        OpenVtsSearchableDropdown<String>(
          label: 'State',
          required: true,
          enabled: _selectedCountryCode != null,
          hintText: _selectedCountryCode == null
              ? 'Select a country first'
              : 'Select a state',
          searchHintText: 'Search state',
          sheetTitle: 'Select state',
          leadingIcon: Icons.map_outlined,
          options: stateOptions,
          value: _selectedStateCode,
          isLoading: _isLoadingStates && stateOptions.isEmpty,
          validator: (value) => value == null || value.trim().isEmpty
              ? 'State is required'
              : null,
          onChanged: (value) async {
            setState(() {
              _selectedStateCode = value;
              _selectedCityName = null;
              _cities = const <AdminUserCityOption>[];
            });

            if (_selectedCountryCode != null && value != null) {
              await _loadCities(_selectedCountryCode!, value);
            }
          },
        ),
        OpenVtsSearchableDropdown<String>(
          label: 'City',
          required: true,
          enabled: _selectedStateCode != null,
          hintText: _selectedStateCode == null
              ? 'Select a state first'
              : 'Select a city',
          searchHintText: 'Search city',
          sheetTitle: 'Select city',
          leadingIcon: Icons.location_city_outlined,
          options: cityOptions,
          value: _selectedCityName,
          isLoading: _isLoadingCities && cityOptions.isEmpty,
          validator: (value) => value == null || value.trim().isEmpty
              ? 'City is required'
              : null,
          onChanged: (value) => setState(() => _selectedCityName = value),
        ),
        OpenVtsTextField(
          label: 'Pincode',
          hintText: 'Postal / ZIP code',
          controller: _pincodeController,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          validator: (value) {
            final normalized = value?.trim() ?? '';
            if (normalized.length > 10) {
              return 'Use 10 characters or fewer';
            }
            return null;
          },
        ),
      ],
    );
  }

  Future<void> _loadStates(String countryCode) async {
    final requestedCountry = countryCode.trim().toUpperCase();
    if (requestedCountry.isEmpty) {
      return;
    }

    setState(() => _isLoadingStates = true);
    try {
      final states = await ref
          .read(adminUsersControllerProvider.notifier)
          .getStates(requestedCountry);
      if (!mounted || _selectedCountryCode != requestedCountry) {
        return;
      }
      setState(() {
        _states = states;
        _isLoadingStates = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _isLoadingStates = false);
      ToastHelper.showError(error.toString(), context: context);
    }
  }

  Future<void> _loadCities(String countryCode, String stateCode) async {
    final requestedCountry = countryCode.trim().toUpperCase();
    final requestedState = stateCode.trim().toUpperCase();
    if (requestedCountry.isEmpty || requestedState.isEmpty) {
      return;
    }

    setState(() => _isLoadingCities = true);
    try {
      final cities = await ref
          .read(adminUsersControllerProvider.notifier)
          .getCities(requestedCountry, requestedState);
      if (!mounted ||
          _selectedCountryCode != requestedCountry ||
          _selectedStateCode != requestedState) {
        return;
      }
      setState(() {
        _cities = cities;
        _isLoadingCities = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _isLoadingCities = false);
      ToastHelper.showError(error.toString(), context: context);
    }
  }

  Future<void> _submit() async {
    final formState = _formKey.currentState;
    if (formState == null || !formState.validate()) {
      ToastHelper.showError(
        'Please fix the highlighted fields before continuing.',
        context: context,
      );
      return;
    }

    if (_selectedCountryCode == null ||
        _selectedStateCode == null ||
        _selectedCityName == null) {
      ToastHelper.showError(
        'Country, state, and city are required.',
        context: context,
      );
      return;
    }

    try {
      await ref.read(adminUsersControllerProvider.notifier).createUser(
            AdminCreateUserRequest(
              name: _nameController.text,
              email: _emailController.text,
              mobilePrefix: _selectedMobilePrefix ?? '',
              mobileNumber: _mobileNumberController.text,
              username: _usernameController.text,
              password: _passwordController.text,
              companyName: _companyController.text,
              address: _addressController.text,
              countryCode: _selectedCountryCode!,
              stateCode: _selectedStateCode!,
              city: _selectedCityName!,
              pincode: _pincodeController.text,
            ),
          );

      if (!mounted) {
        return;
      }

      ToastHelper.showSuccess(
        'User "${_nameController.text.trim()}" created.',
        context: context,
      );
      if (context.canPop()) {
        context.pop();
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      ToastHelper.showError(
        ref.read(adminUsersControllerProvider).errorMessage ??
            error.toString(),
        context: context,
      );
    }
  }

  void _handleClose(BuildContext context) {
    final hasUnsavedInput = _nameController.text.trim().isNotEmpty ||
        _emailController.text.trim().isNotEmpty ||
        _usernameController.text.trim().isNotEmpty ||
        _passwordController.text.trim().isNotEmpty ||
        _companyController.text.trim().isNotEmpty ||
        _addressController.text.trim().isNotEmpty ||
        _mobileNumberController.text.trim().isNotEmpty ||
        _pincodeController.text.trim().isNotEmpty ||
        _selectedCountryCode != null;

    if (!hasUnsavedInput) {
      if (context.canPop()) {
        context.pop();
      }
      return;
    }

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Discard new user?'),
        content: const Text(
          'Your changes will be lost. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => dialogContext.pop(),
            child: const Text('Keep editing'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: OpenVtsColors.error),
            onPressed: () {
              dialogContext.pop();
              if (context.canPop()) {
                context.pop();
              }
            },
            child: const Text('Discard'),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Layout building blocks
// ---------------------------------------------------------------------------

class _IntroBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(OpenVtsSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? OpenVtsColors.darkSurface : OpenVtsColors.surface,
        borderRadius: BorderRadius.circular(OpenVtsRadius.lg),
        border: Border.all(
          color: isDark ? OpenVtsColors.darkBorder : OpenVtsColors.border,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 36,
            width: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isDark
                  ? OpenVtsColors.darkBackground
                  : OpenVtsColors.surfaceElevated,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.person_add_alt_1_rounded,
              size: 18,
              color: isDark
                  ? OpenVtsColors.darkTextPrimary
                  : OpenVtsColors.brandInk,
            ),
          ),
          const SizedBox(width: OpenVtsSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Add a new user',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Complete the sections below. Required fields are marked with an asterisk (*).',
                  style: OpenVtsTypography.label.copyWith(
                    color: OpenVtsColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FormSection extends StatelessWidget {
  const _FormSection({
    required this.icon,
    required this.title,
    required this.description,
    required this.children,
  });

  final IconData icon;
  final String title;
  final String description;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(OpenVtsSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(OpenVtsRadius.lg),
        border: Border.all(
          color: isDark ? OpenVtsColors.darkBorder : OpenVtsColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SectionHeader(
            icon: icon,
            title: title,
            description: description,
          ),
          const SizedBox(height: OpenVtsSpacing.md),
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(height: OpenVtsSpacing.md),
            children[i],
          ],
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 36,
          width: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isDark ? OpenVtsColors.darkBackground : OpenVtsColors.surface,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 18,
            color: isDark
                ? OpenVtsColors.darkTextPrimary
                : OpenVtsColors.brandInk,
          ),
        ),
        const SizedBox(width: OpenVtsSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: OpenVtsTypography.label.copyWith(
                  color: OpenVtsColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StickyActionBar extends StatelessWidget {
  const _StickyActionBar({
    required this.isSubmitting,
    required this.onCancel,
    required this.onSubmit,
  });

  final bool isSubmitting;
  final VoidCallback onCancel;
  final VoidCallback? onSubmit;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.fromLTRB(
        OpenVtsSpacing.md,
        OpenVtsSpacing.sm,
        OpenVtsSpacing.md,
        OpenVtsSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: isDark ? OpenVtsColors.darkBorder : OpenVtsColors.border,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: OpenVtsButton(
                label: 'Cancel',
                variant: OpenVtsButtonVariant.secondary,
                onPressed: isSubmitting ? null : onCancel,
              ),
            ),
            const SizedBox(width: OpenVtsSpacing.sm),
            Expanded(
              flex: 2,
              child: OpenVtsButton(
                label: 'Create user',
                isLoading: isSubmitting,
                onPressed: onSubmit,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
