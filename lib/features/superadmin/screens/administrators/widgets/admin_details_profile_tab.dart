import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/open_vts_colors.dart';
import '../../../../../core/theme/open_vts_radius.dart';
import '../../../../../core/theme/open_vts_spacing.dart';
import '../../../../../core/theme/open_vts_typography.dart';
import '../../../../../core/utils/date_time_formatter.dart';
import '../../../../../core/utils/validators.dart';
import '../../../../../shared/helpers/toast_helper.dart';
import '../../../../../shared/widgets/open_vts_button.dart';
import '../../../../../shared/widgets/open_vts_card.dart';
import '../../../../../shared/widgets/open_vts_loader.dart';
import '../../../../../shared/widgets/open_vts_text_field.dart';
import '../../../controllers/superadmin_admin_details_controller.dart';
import '../../../controllers/superadmin_providers.dart';
import '../../../models/superadmin_admin_details_model.dart';

const List<String> _kPrimaryColorOptions = <String>[
  'Black',
  'Blue',
  'Green',
  'Purple',
  'Pink',
  'Orange',
];

const _kSocialKeys = <String>[
  'facebook',
  'twitter',
  'linkedin',
  'instagram',
  'youtube',
  'github',
];

// =============================================================================
// Profile tab
// =============================================================================

class AdminDetailsProfileTab extends ConsumerStatefulWidget {
  const AdminDetailsProfileTab({required this.adminId, super.key});

  final String adminId;

  @override
  ConsumerState<AdminDetailsProfileTab> createState() =>
      _AdminDetailsProfileTabState();
}

class _AdminDetailsProfileTabState
    extends ConsumerState<AdminDetailsProfileTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(superadminAdminDetailsControllerProvider(widget.adminId).notifier)
          .ensureVehicleCountLoaded();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = superadminAdminDetailsControllerProvider(widget.adminId);
    final admin = ref.watch(provider.select((s) => s.admin));
    final effectiveIsActive = ref.watch(provider.select((s) => s.effectiveIsActive));
    final isUpdatingStatus =
        ref.watch(provider.select((s) => s.isUpdatingStatus));
    final isBusy = ref.watch(
      provider.select(
        (s) => s.isSavingProfile || s.isChangingPassword || s.isSavingCompany,
      ),
    );

    if (admin == null) {
      return const OpenVtsCard(
        padding: EdgeInsets.symmetric(vertical: OpenVtsSpacing.lg),
        child: Center(child: OpenVtsLoader()),
      );
    }

    final company = admin.companies.isNotEmpty ? admin.companies.first : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _AdminPersonalCard(
          adminId: widget.adminId,
          admin: admin,
          effectiveIsActive: effectiveIsActive,
          isUpdatingStatus: isUpdatingStatus,
          isBusy: isBusy,
          onToggleStatus: (next) => _handleStatusToggle(
            context: context,
            controller: ref.read(provider.notifier),
            next: next,
          ),
        ),
        const SizedBox(height: OpenVtsSpacing.sm),
        _CompanyCard(
          admin: admin,
          company: company,
          isBusy: isBusy,
          onEditCompany: () => _openEditCompany(company),
        ),
        const SizedBox(height: OpenVtsSpacing.md),
        _BottomActions(
          isBusy: isBusy,
          onEditProfile: () => _openEditProfile(admin),
          onChangePassword: () => _openChangePassword(),
        ),
        const SizedBox(height: OpenVtsSpacing.lg),
      ],
    );
  }

  Future<void> _handleStatusToggle({
    required BuildContext context,
    required SuperadminAdminDetailsController controller,
    required bool next,
  }) async {
    final ok = await controller.updateStatus(next);
    if (!context.mounted) return;
    if (ok) {
      ToastHelper.showSuccess(
        next ? 'Administrator activated.' : 'Administrator deactivated.',
        context: context,
      );
    } else {
      ToastHelper.showError('Failed to update status.', context: context);
    }
  }

  Future<void> _openEditProfile(SuperadminAdminDetails admin) async {
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _EditProfileSheet(adminId: widget.adminId, admin: admin),
    );
  }

  Future<void> _openChangePassword() async {
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ChangePasswordSheet(adminId: widget.adminId),
    );
  }

  Future<void> _openEditCompany(SuperadminAdminCompany? company) async {
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _EditCompanySheet(adminId: widget.adminId, company: company),
    );
  }
}

// =============================================================================
// 1. Admin personal card — identity + contact + location + stats
// =============================================================================

class _AdminPersonalCard extends ConsumerWidget {
  const _AdminPersonalCard({
    required this.adminId,
    required this.admin,
    required this.effectiveIsActive,
    required this.isUpdatingStatus,
    required this.isBusy,
    required this.onToggleStatus,
  });

  final String adminId;
  final SuperadminAdminDetails admin;
  final bool effectiveIsActive;
  final bool isUpdatingStatus;
  final bool isBusy;
  final ValueChanged<bool> onToggleStatus;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const fmt = DateTimeFormatter();
    final address = admin.address;
    final addressLine = address?.addressLine ?? admin.location;
    final city = address?.cityName ?? admin.cityName;
    final stateCode = address?.stateCode ?? admin.stateCode;
    final countryCode = address?.countryCode ?? admin.countryCode;
    final pincode = address?.pincode ?? admin.pincode;

    // Get resolved last login from controller state
    final controllerState = ref.watch(
      superadminAdminDetailsControllerProvider(adminId).select((s) => s),
    );
    final resolvedLastLogin =
        controllerState.resolvedLastLogin ?? admin.recentLogin;
    final lastLogin = resolvedLastLogin != null
        ? fmt.formatDate(resolvedLastLogin)
        : 'Never';
    final created =
        admin.createdAt != null ? fmt.formatDate(admin.createdAt!) : '—';

    return _SectionCard(
      title: 'ACCOUNT',
      children: [
        // --- Avatar + Name + Username + Status Toggle ---
        Padding(
          padding: const EdgeInsets.only(bottom: OpenVtsSpacing.xs),
          child: Row(
            children: [
              _Avatar(name: admin.name),
              const SizedBox(width: OpenVtsSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      admin.name,
                      style: OpenVtsTypography.label.copyWith(
                        color: OpenVtsColors.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '@${admin.username}',
                      style: OpenVtsTypography.meta.copyWith(
                        color: OpenVtsColors.textSecondary,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: OpenVtsSpacing.xs),
              if (isUpdatingStatus)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                SizedBox(
                  width: 44,
                  height: 44,
                  child: Switch.adaptive(
                    value: effectiveIsActive,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    onChanged: isBusy ? null : onToggleStatus,
                  ),
                ),
            ],
          ),
        ),
        _InfoRow(
            label: 'Address', value: addressLine, icon: Icons.home_outlined),
        _InfoRow(
            label: 'Country', value: countryCode, icon: Icons.public_outlined),
        _InfoRow(label: 'State', value: stateCode, icon: Icons.map_outlined),
        _InfoRow(
            label: 'City', value: city, icon: Icons.location_city_outlined),
        _InfoRow(
            label: 'Pincode',
            value: pincode,
            icon: Icons.local_post_office_outlined),
        // Compact created & last login row
        Padding(
          padding: const EdgeInsets.only(top: OpenVtsSpacing.xs),
          child: Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(
                      Icons.event_outlined,
                      size: 14,
                      color: OpenVtsColors.textTertiary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Created: ',
                      style: OpenVtsTypography.meta.copyWith(
                        color: OpenVtsColors.textTertiary,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Flexible(
                      child: Text(
                        created,
                        style: OpenVtsTypography.label.copyWith(
                          color: OpenVtsColors.textSecondary,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: OpenVtsSpacing.xs),
              Expanded(
                child: Row(
                  children: [
                    const Icon(
                      Icons.login_outlined,
                      size: 14,
                      color: OpenVtsColors.textTertiary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Last login: ',
                      style: OpenVtsTypography.meta.copyWith(
                        color: OpenVtsColors.textTertiary,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Flexible(
                      child: Text(
                        lastLogin,
                        style: OpenVtsTypography.label.copyWith(
                          color: OpenVtsColors.textSecondary,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// 2. Company card — with edit icon top-right
// =============================================================================

class _CompanyCard extends StatelessWidget {
  const _CompanyCard({
    required this.admin,
    required this.company,
    required this.isBusy,
    required this.onEditCompany,
  });

  final SuperadminAdminDetails admin;
  final SuperadminAdminCompany? company;
  final bool isBusy;
  final VoidCallback onEditCompany;

  @override
  Widget build(BuildContext context) {
    final companyName = company?.name.trim().isNotEmpty == true
        ? company!.name
        : admin.organization;
    final website = company?.websiteUrl ?? '';
    final domain = company?.customDomain ?? '';
    final color = company?.primaryColor ?? '';
    final socialLinks = company?.socialLinks ?? const {};

    final hasSocial = _kSocialKeys.any(
      (k) => (socialLinks[k]?.trim().isNotEmpty ?? false),
    );

    return _SectionCard(
      title: 'COMPANY',
      trailing: SizedBox(
        width: 32,
        height: 32,
        child: IconButton(
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          icon: const Icon(
            Icons.edit_outlined,
            size: 16,
            color: OpenVtsColors.textSecondary,
          ),
          tooltip: 'Edit company',
          onPressed: isBusy ? null : onEditCompany,
        ),
      ),
      children: [
        _InfoRow(
            label: 'Company',
            value: companyName,
            icon: Icons.business_outlined),
        _InfoRow(
            label: 'Website', value: website, icon: Icons.language_outlined),
        _InfoRow(label: 'Domain', value: domain, icon: Icons.dns_outlined),
        _InfoRow(
          label: 'Brand color',
          value: color,
          icon: Icons.palette_outlined,
          trailing: color.trim().isNotEmpty
              ? Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: _colorFromName(color),
                      shape: BoxShape.circle,
                      border: Border.all(color: OpenVtsColors.border),
                    ),
                  ),
                )
              : null,
        ),
        if (hasSocial)
          for (final k in _kSocialKeys)
            if (socialLinks[k]?.trim().isNotEmpty ?? false)
              _InfoRow(
                label: _socialLabel(k),
                value: socialLinks[k]!.trim(),
                icon: Icons.link_rounded,
              ),
      ],
    );
  }

  static String _socialLabel(String key) {
    switch (key) {
      case 'facebook':
        return 'Facebook';
      case 'twitter':
        return 'Twitter';
      case 'linkedin':
        return 'LinkedIn';
      case 'instagram':
        return 'Instagram';
      case 'youtube':
        return 'YouTube';
      case 'github':
        return 'GitHub';
      default:
        return key;
    }
  }
}

// =============================================================================
// 3. Bottom action buttons
// =============================================================================

class _BottomActions extends StatelessWidget {
  const _BottomActions({
    required this.isBusy,
    required this.onEditProfile,
    required this.onChangePassword,
  });

  final bool isBusy;
  final VoidCallback onEditProfile;
  final VoidCallback onChangePassword;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OpenVtsButton(
            label: 'Edit Profile',
            variant: OpenVtsButtonVariant.secondary,
            onPressed: isBusy ? null : onEditProfile,
          ),
        ),
        const SizedBox(width: OpenVtsSpacing.sm),
        Expanded(
          child: OpenVtsButton(
            label: 'Change Password',
            variant: OpenVtsButtonVariant.secondary,
            onPressed: isBusy ? null : onChangePassword,
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// Shared display components
// =============================================================================

class _SectionCard extends StatelessWidget {
  const _SectionCard(
      {required this.title, required this.children, this.trailing});

  final String title;
  final List<Widget> children;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return OpenVtsCard(
      padding: const EdgeInsets.fromLTRB(
        OpenVtsSpacing.md,
        OpenVtsSpacing.sm,
        OpenVtsSpacing.md,
        OpenVtsSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: OpenVtsColors.textTertiary,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: OpenVtsSpacing.xs),
          const Divider(height: 1, color: OpenVtsColors.border),
          const SizedBox(height: OpenVtsSpacing.xs),
          ...children,
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: OpenVtsColors.brandInk,
        borderRadius: BorderRadius.circular(OpenVtsRadius.md),
      ),
      alignment: Alignment.center,
      child: Text(
        _initials(name),
        style: OpenVtsTypography.label.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  static String _initials(String value) {
    final parts =
        value.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return 'OV';
    if (parts.length == 1) {
      return parts.first
          .substring(0, parts.first.length.clamp(1, 2))
          .toUpperCase();
    }
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    this.value,
    this.valueWidget,
    this.icon,
    this.trailing,
  }) : assert(value != null || valueWidget != null);

  final String label;
  final String? value;
  final Widget? valueWidget;
  final IconData? icon;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: OpenVtsSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: OpenVtsColors.textTertiary),
            const SizedBox(width: 8),
          ],
          SizedBox(
            width: 108,
            child: Text(
              label,
              style: OpenVtsTypography.meta.copyWith(
                color: OpenVtsColors.textTertiary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: OpenVtsSpacing.xs),
          Expanded(
            child: valueWidget ??
                Text(
                  _displayValue(value ?? ''),
                  style: OpenVtsTypography.label.copyWith(
                    color: OpenVtsColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

String _displayValue(String value) {
  final normalized = value.trim();
  if (normalized.isEmpty || normalized == '-') {
    return '—';
  }
  return normalized;
}

// =============================================================================
// Edit profile sheet
// =============================================================================

class _EditProfileSheet extends ConsumerStatefulWidget {
  const _EditProfileSheet({required this.adminId, required this.admin});

  final String adminId;
  final SuperadminAdminDetails admin;

  @override
  ConsumerState<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends ConsumerState<_EditProfileSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _email;
  late final TextEditingController _mobileNumber;
  late final TextEditingController _addressLine;
  late final TextEditingController _pincode;

  String? _mobilePrefix;
  String? _countryCode;
  String? _stateCode;
  String? _cityName;
  bool _catalogReady = false;

  @override
  void initState() {
    super.initState();
    final a = widget.admin;
    final addr = a.address;
    _name = TextEditingController(text: a.name);
    _email = TextEditingController(text: a.email);
    _mobileNumber = TextEditingController(text: a.mobileNumber);
    _addressLine = TextEditingController(text: addr?.addressLine ?? a.location);
    _pincode = TextEditingController(text: addr?.pincode ?? a.pincode);
    _mobilePrefix = a.mobilePrefix.isEmpty ? null : a.mobilePrefix;
    _countryCode = (addr?.countryCode.isNotEmpty == true
            ? addr!.countryCode
            : a.countryCode)
        .toUpperCase();
    _stateCode =
        (addr?.stateCode.isNotEmpty == true ? addr!.stateCode : a.stateCode);
    _cityName =
        (addr?.cityName.isNotEmpty == true ? addr!.cityName : a.cityName)
            .trim();
    if (_countryCode!.isEmpty) _countryCode = null;
    if (_stateCode!.isEmpty) _stateCode = null;
    if (_cityName != null && _cityName!.isEmpty) _cityName = null;

    WidgetsBinding.instance.addPostFrameCallback((_) => _prepareCatalog());
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _mobileNumber.dispose();
    _addressLine.dispose();
    _pincode.dispose();
    super.dispose();
  }

  Future<void> _prepareCatalog() async {
    final controller =
        ref.read(superadminAdministratorsControllerProvider.notifier);
    try {
      await controller.prepareCreateForm();
      if (_countryCode != null && _countryCode!.isNotEmpty) {
        await controller.loadStateOptions(_countryCode!);
        if (_stateCode != null && _stateCode!.isNotEmpty) {
          await controller.loadCityOptions(_countryCode!, _stateCode!);
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _catalogReady = true);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(superadminAdministratorsControllerProvider);
    final detailsState =
        ref.watch(superadminAdminDetailsControllerProvider(widget.adminId));
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    final countries = state.countries;
    final prefixes = state.mobilePrefixes;
    final states = state.stateOptions;
    final cities = state.cityOptions;

    final countryItems = _withFallback(
      values: countries.map((c) => c.code).toList(),
      labels: {for (final c in countries) c.code: c.name},
      current: _countryCode,
    );
    final stateItems = _withFallback(
      values: states.map((s) => s.code).toList(),
      labels: {for (final s in states) s.code: s.name},
      current: _stateCode,
    );
    final cityItems = _withFallback(
      values: cities.map((c) => c.name).toList(),
      labels: {for (final c in cities) c.name: c.name},
      current: _cityName,
    );
    final prefixItems = _withFallback(
      values: prefixes.map((p) => p.dialCode).toList(),
      labels: {
        for (final p in prefixes)
          p.dialCode: '${p.dialCode} (${p.countryCode})',
      },
      current: _mobilePrefix,
    );

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.92,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _SheetHandle(),
              const _SheetTitle(title: 'Edit profile'),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    OpenVtsSpacing.md,
                    OpenVtsSpacing.sm,
                    OpenVtsSpacing.md,
                    OpenVtsSpacing.md,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (!_catalogReady && countries.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(
                              vertical: OpenVtsSpacing.md,
                            ),
                            child: Center(child: OpenVtsLoader()),
                          ),
                        const _FormSectionLabel(label: 'CONTACT'),
                        const SizedBox(height: OpenVtsSpacing.xs),
                        OpenVtsTextField(
                          label: 'Name',
                          controller: _name,
                          textInputAction: TextInputAction.next,
                          validator: Validators.adminName,
                        ),
                        const SizedBox(height: OpenVtsSpacing.sm),
                        OpenVtsTextField(
                          label: 'Email',
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          validator: Validators.adminEmailOptional,
                        ),
                        const SizedBox(height: OpenVtsSpacing.sm),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 4,
                              child: _DropdownField<String>(
                                label: 'Prefix',
                                value: _mobilePrefix,
                                items: prefixItems,
                                onChanged: (v) =>
                                    setState(() => _mobilePrefix = v),
                                validator: Validators.mobilePrefix,
                              ),
                            ),
                            const SizedBox(width: OpenVtsSpacing.sm),
                            Expanded(
                              flex: 6,
                              child: OpenVtsTextField(
                                label: 'Mobile number',
                                controller: _mobileNumber,
                                keyboardType: TextInputType.phone,
                                textInputAction: TextInputAction.next,
                                validator: Validators.mobileNumber,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: OpenVtsSpacing.md),
                        const _FormSectionLabel(label: 'ADDRESS'),
                        const SizedBox(height: OpenVtsSpacing.xs),
                        OpenVtsTextField(
                          label: 'Address',
                          controller: _addressLine,
                          maxLines: 2,
                          textInputAction: TextInputAction.next,
                          validator: Validators.address,
                        ),
                        const SizedBox(height: OpenVtsSpacing.sm),
                        OpenVtsTextField(
                          label: 'Pincode',
                          controller: _pincode,
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.done,
                          validator: Validators.pincodeOptional,
                        ),
                        const SizedBox(height: OpenVtsSpacing.md),
                        const _FormSectionLabel(label: 'LOCATION'),
                        const SizedBox(height: OpenVtsSpacing.xs),
                        _DropdownField<String>(
                          label: 'Country',
                          value: _countryCode,
                          items: countryItems,
                          onChanged: (v) async {
                            setState(() {
                              _countryCode = v;
                              _stateCode = null;
                              _cityName = null;
                            });
                            if (v != null && v.trim().isNotEmpty) {
                              try {
                                await ref
                                    .read(
                                      superadminAdministratorsControllerProvider
                                          .notifier,
                                    )
                                    .loadStateOptions(v);
                              } catch (_) {}
                            }
                          },
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Country is required'
                              : null,
                        ),
                        const SizedBox(height: OpenVtsSpacing.sm),
                        _DropdownField<String>(
                          label: 'State',
                          value: _stateCode,
                          items: stateItems,
                          onChanged: (v) async {
                            setState(() {
                              _stateCode = v;
                              _cityName = null;
                            });
                            if (_countryCode != null && v != null) {
                              try {
                                await ref
                                    .read(
                                      superadminAdministratorsControllerProvider
                                          .notifier,
                                    )
                                    .loadCityOptions(_countryCode!, v);
                              } catch (_) {}
                            }
                          },
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'State is required'
                              : null,
                        ),
                        const SizedBox(height: OpenVtsSpacing.sm),
                        _DropdownField<String>(
                          label: 'City',
                          value: _cityName,
                          items: cityItems,
                          onChanged: (v) => setState(() => _cityName = v),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'City is required'
                              : null,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              _SheetActions(
                isLoading: detailsState.isSavingProfile,
                onCancel: () => Navigator.of(context).maybePop(),
                onSubmit: _submit,
                submitLabel: 'Save changes',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final controller = ref.read(
        superadminAdminDetailsControllerProvider(widget.adminId).notifier);
    final ok = await controller.updateProfile(
      SuperadminUpdateAdminRequest(
        name: _name.text,
        email: _email.text,
        mobilePrefix: _mobilePrefix ?? '',
        mobileNumber: _mobileNumber.text,
        addressLine: _addressLine.text,
        countryCode: _countryCode ?? '',
        stateCode: _stateCode ?? '',
        cityName: _cityName ?? '',
        pincode: _pincode.text,
      ),
    );
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).maybePop();
      ToastHelper.showSuccess('Profile updated.', context: context);
    } else {
      final msg = ref
              .read(superadminAdminDetailsControllerProvider(widget.adminId))
              .sectionErrorMessage ??
          'Failed to update profile.';
      ToastHelper.showError(msg, context: context);
    }
  }
}

// =============================================================================
// Change password sheet
// =============================================================================

class _ChangePasswordSheet extends ConsumerStatefulWidget {
  const _ChangePasswordSheet({required this.adminId});
  final String adminId;

  @override
  ConsumerState<_ChangePasswordSheet> createState() =>
      _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends ConsumerState<_ChangePasswordSheet> {
  final _formKey = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _obscure1 = true;
  bool _obscure2 = true;

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state =
        ref.watch(superadminAdminDetailsControllerProvider(widget.adminId));
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _SheetHandle(),
            const _SheetTitle(title: 'Change password'),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                OpenVtsSpacing.md,
                OpenVtsSpacing.sm,
                OpenVtsSpacing.md,
                OpenVtsSpacing.md,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    OpenVtsTextField(
                      label: 'New password',
                      controller: _password,
                      obscureText: _obscure1,
                      textInputAction: TextInputAction.next,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscure1
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          size: 18,
                          color: OpenVtsColors.textTertiary,
                        ),
                        onPressed: () => setState(() => _obscure1 = !_obscure1),
                      ),
                      validator: Validators.adminPassword,
                    ),
                    const SizedBox(height: OpenVtsSpacing.sm),
                    OpenVtsTextField(
                      label: 'Confirm password',
                      controller: _confirm,
                      obscureText: _obscure2,
                      textInputAction: TextInputAction.done,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscure2
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          size: 18,
                          color: OpenVtsColors.textTertiary,
                        ),
                        onPressed: () => setState(() => _obscure2 = !_obscure2),
                      ),
                      validator: (v) => Validators.adminConfirmPassword(
                        v,
                        _password.text,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _SheetActions(
              isLoading: state.isChangingPassword,
              onCancel: () => Navigator.of(context).maybePop(),
              onSubmit: _submit,
              submitLabel: 'Update password',
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final controller = ref.read(
        superadminAdminDetailsControllerProvider(widget.adminId).notifier);
    final ok = await controller.changePassword(
      newPassword: _password.text.trim(),
      confirmPassword: _confirm.text.trim(),
    );
    if (!mounted) return;
    if (ok) {
      _password.clear();
      _confirm.clear();
      Navigator.of(context).maybePop();
      ToastHelper.showSuccess('Password updated.', context: context);
    } else {
      final msg = ref
              .read(superadminAdminDetailsControllerProvider(widget.adminId))
              .sectionErrorMessage ??
          'Failed to update password.';
      ToastHelper.showError(msg, context: context);
    }
  }
}

// =============================================================================
// Edit company sheet
// =============================================================================

class _EditCompanySheet extends ConsumerStatefulWidget {
  const _EditCompanySheet({required this.adminId, required this.company});
  final String adminId;
  final SuperadminAdminCompany? company;

  @override
  ConsumerState<_EditCompanySheet> createState() => _EditCompanySheetState();
}

class _EditCompanySheetState extends ConsumerState<_EditCompanySheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _website;
  late final TextEditingController _domain;
  late final Map<String, TextEditingController> _social;
  String? _primaryColor;

  @override
  void initState() {
    super.initState();
    final c = widget.company;
    _name = TextEditingController(text: c?.name ?? '');
    _website = TextEditingController(text: c?.websiteUrl ?? '');
    _domain = TextEditingController(text: c?.customDomain ?? '');
    _social = {
      for (final k in _kSocialKeys)
        k: TextEditingController(text: c?.socialLinks[k] ?? ''),
    };
    _primaryColor = _resolveColor(c?.primaryColor);
  }

  @override
  void dispose() {
    _name.dispose();
    _website.dispose();
    _domain.dispose();
    for (final ctl in _social.values) {
      ctl.dispose();
    }
    super.dispose();
  }

  String _resolveColor(String? raw) {
    final existing = raw?.trim() ?? '';
    if (existing.isEmpty) return 'Black';
    for (final option in _kPrimaryColorOptions) {
      if (option.toLowerCase() == existing.toLowerCase()) return option;
    }
    return existing;
  }

  @override
  Widget build(BuildContext context) {
    final state =
        ref.watch(superadminAdminDetailsControllerProvider(widget.adminId));
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    final colorItems = <DropdownMenuItem<String>>[
      for (final c in _kPrimaryColorOptions)
        DropdownMenuItem<String>(
          value: c,
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: _colorFromName(c),
                  shape: BoxShape.circle,
                  border: Border.all(color: OpenVtsColors.border),
                ),
              ),
              const SizedBox(width: 8),
              Text(c, style: const TextStyle(fontSize: 13)),
            ],
          ),
        ),
    ];

    if (_primaryColor != null &&
        _primaryColor!.trim().isNotEmpty &&
        !_kPrimaryColorOptions.contains(_primaryColor)) {
      colorItems.insert(
        0,
        DropdownMenuItem<String>(
          value: _primaryColor,
          child: Text(
            _primaryColor!,
            style: const TextStyle(color: OpenVtsColors.textSecondary),
          ),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.92,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _SheetHandle(),
              const _SheetTitle(title: 'Edit company'),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    OpenVtsSpacing.md,
                    OpenVtsSpacing.sm,
                    OpenVtsSpacing.md,
                    OpenVtsSpacing.md,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        OpenVtsTextField(
                          label: 'Company name',
                          controller: _name,
                          textInputAction: TextInputAction.next,
                          validator: Validators.companyName,
                        ),
                        const SizedBox(height: OpenVtsSpacing.sm),
                        OpenVtsTextField(
                          label: 'Website URL',
                          controller: _website,
                          keyboardType: TextInputType.url,
                          textInputAction: TextInputAction.next,
                          hintText: 'https://example.com',
                          validator: (v) {
                            final s = v?.trim() ?? '';
                            if (s.isEmpty) return null;
                            final normalized =
                                s.startsWith(RegExp(r'https?://'))
                                    ? s
                                    : 'https://$s';
                            final uri = Uri.tryParse(normalized);
                            if (uri == null ||
                                !(uri.hasScheme &&
                                    (uri.scheme == 'http' ||
                                        uri.scheme == 'https'))) {
                              return 'Enter a valid URL';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: OpenVtsSpacing.sm),
                        OpenVtsTextField(
                          label: 'Custom domain',
                          controller: _domain,
                          keyboardType: TextInputType.url,
                          textInputAction: TextInputAction.next,
                          hintText: 'example.com',
                          validator: (v) {
                            final s = v?.trim() ?? '';
                            if (s.isEmpty) return null;
                            if (s.startsWith('http://') ||
                                s.startsWith('https://')) {
                              return 'Remove protocol from domain';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: OpenVtsSpacing.sm),
                        _DropdownField<String>(
                          label: 'Primary color',
                          value: _primaryColor,
                          items: colorItems,
                          onChanged: (v) => setState(() => _primaryColor = v),
                        ),
                        const SizedBox(height: OpenVtsSpacing.md),
                        const _FormSectionLabel(label: 'SOCIAL LINKS'),
                        const SizedBox(height: OpenVtsSpacing.xs),
                        for (final k in _kSocialKeys) ...[
                          OpenVtsTextField(
                            label: _socialLabel(k),
                            controller: _social[k],
                            keyboardType: TextInputType.url,
                            textInputAction: TextInputAction.next,
                            validator: (v) {
                              final s = v?.trim() ?? '';
                              if (s.isEmpty) return null;
                              final normalized =
                                  s.startsWith(RegExp(r'https?://'))
                                      ? s
                                      : 'https://$s';
                              final uri = Uri.tryParse(normalized);
                              if (uri == null ||
                                  !(uri.hasScheme &&
                                      (uri.scheme == 'http' ||
                                          uri.scheme == 'https'))) {
                                return 'Enter a valid URL';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: OpenVtsSpacing.sm),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              _SheetActions(
                isLoading: state.isSavingCompany,
                onCancel: () => Navigator.of(context).maybePop(),
                onSubmit: _submit,
                submitLabel: 'Save company',
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _socialLabel(String key) {
    switch (key) {
      case 'facebook':
        return 'Facebook';
      case 'twitter':
        return 'Twitter';
      case 'linkedin':
        return 'LinkedIn';
      case 'instagram':
        return 'Instagram';
      case 'youtube':
        return 'YouTube';
      case 'github':
        return 'GitHub';
      default:
        return key;
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final social = <String, String>{};
    for (final entry in _social.entries) {
      final v = entry.value.text.trim();
      if (v.isEmpty) continue;
      social[entry.key] = _normalizeUrl(v);
    }

    final controller = ref.read(
        superadminAdminDetailsControllerProvider(widget.adminId).notifier);
    final ok = await controller.updateCompany(
      SuperadminAdminCompanyUpdateRequest(
        name: _name.text.trim(),
        websiteUrl: _normalizeUrlOptional(_website.text),
        customDomain: _normalizeDomain(_domain.text),
        socialLinks: social,
        primaryColor: _primaryColor ?? 'Black',
      ),
    );
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).maybePop();
      ToastHelper.showSuccess('Company updated.', context: context);
    } else {
      final backendMsg = ref
              .read(superadminAdminDetailsControllerProvider(widget.adminId))
              .sectionErrorMessage
              ?.trim() ??
          '';
      final msg =
          backendMsg.isNotEmpty ? backendMsg : 'Failed to update company.';
      ToastHelper.showError(msg, context: context);
    }
  }
}

// =============================================================================
// Shared sheet components
// =============================================================================

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 36,
        height: 4,
        margin: const EdgeInsets.only(top: 10, bottom: 6),
        decoration: BoxDecoration(
          color: OpenVtsColors.border,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

class _SheetTitle extends StatelessWidget {
  const _SheetTitle({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        OpenVtsSpacing.md,
        0,
        OpenVtsSpacing.xs,
        0,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: OpenVtsTypography.body.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 20),
                onPressed: () => Navigator.of(context).maybePop(),
                tooltip: 'Close',
              ),
            ],
          ),
          const Divider(height: 1, color: OpenVtsColors.border),
        ],
      ),
    );
  }
}

class _SheetActions extends StatelessWidget {
  const _SheetActions({
    required this.isLoading,
    required this.onCancel,
    required this.onSubmit,
    required this.submitLabel,
  });

  final bool isLoading;
  final VoidCallback onCancel;
  final VoidCallback onSubmit;
  final String submitLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: OpenVtsColors.border)),
      ),
      padding: const EdgeInsets.fromLTRB(
        OpenVtsSpacing.md,
        OpenVtsSpacing.sm,
        OpenVtsSpacing.md,
        OpenVtsSpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: OpenVtsButton(
              label: 'Cancel',
              variant: OpenVtsButtonVariant.secondary,
              onPressed: isLoading ? null : onCancel,
            ),
          ),
          const SizedBox(width: OpenVtsSpacing.sm),
          Expanded(
            flex: 2,
            child: OpenVtsButton(
              label: submitLabel,
              isLoading: isLoading,
              onPressed: isLoading ? null : onSubmit,
            ),
          ),
        ],
      ),
    );
  }
}

class _FormSectionLabel extends StatelessWidget {
  const _FormSectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: OpenVtsSpacing.xs),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: OpenVtsColors.textTertiary,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

class _DropdownField<T> extends StatelessWidget {
  const _DropdownField({
    required this.label,
    required this.items,
    required this.onChanged,
    this.value,
    this.validator,
  });

  final String label;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  final String? Function(T?)? validator;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: OpenVtsTypography.meta.copyWith(
            fontWeight: FontWeight.w500,
            color: OpenVtsColors.textSecondary,
          ),
        ),
        const SizedBox(height: OpenVtsSpacing.xxs),
        DropdownButtonFormField<T>(
          initialValue: value,
          items: items,
          validator: validator,
          onChanged: onChanged,
          isExpanded: true,
          menuMaxHeight: 320,
          decoration: const InputDecoration(),
          borderRadius: BorderRadius.circular(OpenVtsRadius.md),
        ),
      ],
    );
  }
}

// =============================================================================
// Helpers
// =============================================================================

List<DropdownMenuItem<String>> _withFallback({
  required List<String> values,
  required Map<String, String> labels,
  required String? current,
}) {
  final items = <DropdownMenuItem<String>>[
    for (final v in values)
      DropdownMenuItem<String>(
        value: v,
        child: Text(
          labels[v] ?? v,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
  ];
  if (current != null &&
      current.trim().isNotEmpty &&
      !values.contains(current)) {
    items.insert(
      0,
      DropdownMenuItem<String>(
        value: current,
        child: Text(
          current,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: OpenVtsColors.textSecondary),
        ),
      ),
    );
  }
  return items;
}

String _normalizeUrl(String input) {
  final s = input.trim();
  if (s.isEmpty) return s;
  if (s.startsWith('http://') || s.startsWith('https://')) return s;
  return 'https://$s';
}

String _normalizeUrlOptional(String input) {
  final s = input.trim();
  if (s.isEmpty) return '';
  return _normalizeUrl(s);
}

String _normalizeDomain(String input) {
  var s = input.trim();
  if (s.isEmpty) return '';
  s = s.replaceFirst(RegExp(r'^https?://', caseSensitive: false), '');
  final slash = s.indexOf('/');
  if (slash >= 0) s = s.substring(0, slash);
  return s;
}

Color _colorFromName(String name) {
  switch (name.trim().toLowerCase()) {
    case 'black':
      return const Color(0xFF141118);
    case 'blue':
      return const Color(0xFF2563EB);
    case 'green':
      return const Color(0xFF2F6B4F);
    case 'purple':
      return const Color(0xFF7C3AED);
    case 'pink':
      return const Color(0xFFDB2777);
    case 'orange':
      return const Color(0xFFEA580C);
    default:
      return OpenVtsColors.textTertiary;
  }
}

// silence unused import lint for HapticFeedback (kept for future haptics tweaks)
// ignore: unused_element
void _noop() => HapticFeedback.selectionClick();
