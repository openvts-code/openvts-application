import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/open_vts_colors.dart';
import '../../../../../core/theme/open_vts_radius.dart';
import '../../../../../core/theme/open_vts_spacing.dart';
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

class AdminDetailsProfileTab extends ConsumerWidget {
  const AdminDetailsProfileTab({required this.adminId, super.key});

  final String adminId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = superadminAdminDetailsControllerProvider(adminId);
    final state = ref.watch(provider);
    final controller = ref.read(provider.notifier);
    final admin = state.admin;

    if (admin == null) {
      return const OpenVtsCard(
        padding: EdgeInsets.symmetric(vertical: OpenVtsSpacing.lg),
        child: Center(child: OpenVtsLoader()),
      );
    }

    final company =
        admin.companies.isNotEmpty ? admin.companies.first : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _IdentityCard(
          admin: admin,
          isUpdatingStatus: state.isUpdatingStatus,
          onToggleStatus: (next) => _handleStatusToggle(
            context: context,
            controller: controller,
            next: next,
          ),
        ),
        const SizedBox(height: OpenVtsSpacing.sm),
        _BusinessCard(admin: admin, company: company),
        const SizedBox(height: OpenVtsSpacing.sm),
        _LocationCard(admin: admin),
        const SizedBox(height: OpenVtsSpacing.sm),
        _StatsCard(admin: admin),
        if (company != null && _hasAnySocial(company.socialLinks)) ...[
          const SizedBox(height: OpenVtsSpacing.sm),
          _SocialLinksCard(socialLinks: company.socialLinks),
        ],
        const SizedBox(height: OpenVtsSpacing.sm),
        _ActionsCard(
          isSavingProfile: state.isSavingProfile,
          isChangingPassword: state.isChangingPassword,
          isSavingCompany: state.isSavingCompany,
          onEditProfile: () => _openEditProfile(context, ref, admin),
          onChangePassword: () => _openChangePassword(context, ref),
          onEditCompany: () => _openEditCompany(context, ref, company),
        ),
        const SizedBox(height: OpenVtsSpacing.lg),
      ],
    );
  }

  bool _hasAnySocial(Map<String, String> links) {
    for (final key in _kSocialKeys) {
      final v = links[key];
      if (v != null && v.trim().isNotEmpty) return true;
    }
    return false;
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
      ToastHelper.showError(
        'Failed to update status.',
        context: context,
      );
    }
  }

  Future<void> _openEditProfile(
    BuildContext context,
    WidgetRef ref,
    SuperadminAdminDetails admin,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: OpenVtsColors.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return _EditProfileSheet(adminId: adminId, admin: admin);
      },
    );
  }

  Future<void> _openChangePassword(
    BuildContext context,
    WidgetRef ref,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: OpenVtsColors.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return _ChangePasswordSheet(adminId: adminId);
      },
    );
  }

  Future<void> _openEditCompany(
    BuildContext context,
    WidgetRef ref,
    SuperadminAdminCompany? company,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: OpenVtsColors.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return _EditCompanySheet(adminId: adminId, company: company);
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Display cards
// ---------------------------------------------------------------------------

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.children, this.trailing});

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

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.icon,
    this.valueColor,
    this.trailing,
  });

  final String label;
  final String value;
  final IconData? icon;
  final Color? valueColor;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: OpenVtsColors.textTertiary),
            const SizedBox(width: 8),
          ],
          SizedBox(
            width: 96,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: OpenVtsColors.textTertiary,
                height: 1.3,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '—' : value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: valueColor ?? OpenVtsColors.textPrimary,
                height: 1.3,
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.isActive});
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final color =
        isActive ? OpenVtsColors.success : OpenVtsColors.textTertiary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(OpenVtsRadius.pill),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        isActive ? 'Active' : 'Inactive',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _IdentityCard extends StatelessWidget {
  const _IdentityCard({
    required this.admin,
    required this.isUpdatingStatus,
    required this.onToggleStatus,
  });

  final SuperadminAdminDetails admin;
  final bool isUpdatingStatus;
  final ValueChanged<bool> onToggleStatus;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'IDENTITY',
      trailing: _StatusBadge(isActive: admin.isActive),
      children: [
        _InfoRow(label: 'Name', value: admin.name, icon: Icons.person_outline_rounded),
        _InfoRow(label: 'Username', value: admin.username, icon: Icons.alternate_email_rounded),
        _InfoRow(label: 'Email', value: admin.email, icon: Icons.mail_outline_rounded),
        _InfoRow(label: 'Phone', value: admin.mobileDisplay, icon: Icons.phone_outlined),
        _InfoRow(
          label: 'Email verified',
          value: admin.isEmailVerified ? 'Yes' : 'No',
          icon: Icons.verified_outlined,
          valueColor: admin.isEmailVerified
              ? OpenVtsColors.success
              : OpenVtsColors.textSecondary,
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Icon(
              admin.isActive
                  ? Icons.toggle_on_outlined
                  : Icons.toggle_off_outlined,
              size: 16,
              color: OpenVtsColors.textSecondary,
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Account status',
                style: TextStyle(
                  fontSize: 12,
                  color: OpenVtsColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (isUpdatingStatus)
              const SizedBox(
                height: 16,
                width: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Transform.scale(
                scale: 0.8,
                child: Switch(
                  value: admin.isActive,
                  onChanged: isUpdatingStatus ? null : onToggleStatus,
                  activeThumbColor: OpenVtsColors.brandInk,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _BusinessCard extends StatelessWidget {
  const _BusinessCard({required this.admin, required this.company});

  final SuperadminAdminDetails admin;
  final SuperadminAdminCompany? company;

  @override
  Widget build(BuildContext context) {
    final companyName = company?.name.trim().isNotEmpty == true
        ? company!.name
        : admin.organization;
    return _SectionCard(
      title: 'BUSINESS',
      children: [
        _InfoRow(
          label: 'Company',
          value: companyName,
          icon: Icons.business_outlined,
        ),
        _InfoRow(
          label: 'Domain',
          value: company?.customDomain ?? '',
          icon: Icons.dns_outlined,
        ),
        _InfoRow(
          label: 'Website',
          value: company?.websiteUrl ?? '',
          icon: Icons.language_outlined,
        ),
        _InfoRow(
          label: 'Brand color',
          value: company?.primaryColor ?? '',
          icon: Icons.palette_outlined,
          trailing: company?.primaryColor.isNotEmpty == true
              ? Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: _colorFromName(company!.primaryColor),
                      shape: BoxShape.circle,
                      border: Border.all(color: OpenVtsColors.border),
                    ),
                  ),
                )
              : null,
        ),
      ],
    );
  }
}

class _LocationCard extends StatelessWidget {
  const _LocationCard({required this.admin});
  final SuperadminAdminDetails admin;

  @override
  Widget build(BuildContext context) {
    final address = admin.address;
    final addressLine = address?.addressLine ?? '';
    final city = address?.cityName ?? admin.cityName;
    final stateCode = address?.stateCode ?? admin.stateCode;
    final countryCode = address?.countryCode ?? admin.countryCode;
    final pincode = address?.pincode ?? admin.pincode;
    final fullAddress = address?.fullAddress.trim().isNotEmpty == true
        ? address!.fullAddress
        : admin.location;

    return _SectionCard(
      title: 'LOCATION',
      children: [
        _InfoRow(
          label: 'Address',
          value: addressLine,
          icon: Icons.home_outlined,
        ),
        _InfoRow(label: 'City', value: city, icon: Icons.location_city_outlined),
        _InfoRow(label: 'State', value: stateCode, icon: Icons.map_outlined),
        _InfoRow(
          label: 'Country',
          value: countryCode,
          icon: Icons.public_outlined,
        ),
        _InfoRow(
          label: 'Pincode',
          value: pincode,
          icon: Icons.local_post_office_outlined,
        ),
        if (fullAddress.trim().isNotEmpty)
          _InfoRow(
            label: 'Full',
            value: fullAddress,
            icon: Icons.place_outlined,
          ),
      ],
    );
  }
}

class _StatsCard extends StatelessWidget {
  const _StatsCard({required this.admin});
  final SuperadminAdminDetails admin;

  @override
  Widget build(BuildContext context) {
    const fmt = DateTimeFormatter();
    final lastLogin = admin.recentLogin != null
        ? fmt.formatDateTime(admin.recentLogin!)
        : '';
    final created =
        admin.createdAt != null ? fmt.formatDateTime(admin.createdAt!) : '';
    return _SectionCard(
      title: 'STATS',
      children: [
        _InfoRow(
          label: 'Vehicles',
          value: admin.totalVehicles.toString(),
          icon: Icons.local_shipping_outlined,
        ),
        _InfoRow(
          label: 'Credits',
          value: admin.credits.toString(),
          icon: Icons.credit_card_outlined,
        ),
        _InfoRow(
          label: 'Last login',
          value: lastLogin,
          icon: Icons.login_rounded,
        ),
        _InfoRow(
          label: 'Created',
          value: created,
          icon: Icons.event_outlined,
        ),
      ],
    );
  }
}

class _SocialLinksCard extends StatelessWidget {
  const _SocialLinksCard({required this.socialLinks});
  final Map<String, String> socialLinks;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (final key in _kSocialKeys) {
      final value = socialLinks[key];
      if (value == null || value.trim().isEmpty) continue;
      rows.add(
        _InfoRow(
          label: _labelForSocial(key),
          value: value,
          icon: _iconForSocial(key),
        ),
      );
    }
    return _SectionCard(title: 'SOCIAL', children: rows);
  }

  String _labelForSocial(String key) {
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

  IconData _iconForSocial(String key) {
    switch (key) {
      case 'facebook':
        return Icons.facebook_rounded;
      case 'twitter':
        return Icons.alternate_email_rounded;
      case 'linkedin':
        return Icons.business_center_outlined;
      case 'instagram':
        return Icons.photo_camera_outlined;
      case 'youtube':
        return Icons.play_circle_outline_rounded;
      case 'github':
        return Icons.code_rounded;
      default:
        return Icons.link_rounded;
    }
  }
}

class _ActionsCard extends StatelessWidget {
  const _ActionsCard({
    required this.isSavingProfile,
    required this.isChangingPassword,
    required this.isSavingCompany,
    required this.onEditProfile,
    required this.onChangePassword,
    required this.onEditCompany,
  });

  final bool isSavingProfile;
  final bool isChangingPassword;
  final bool isSavingCompany;
  final VoidCallback onEditProfile;
  final VoidCallback onChangePassword;
  final VoidCallback onEditCompany;

  @override
  Widget build(BuildContext context) {
    final busy = isSavingProfile || isChangingPassword || isSavingCompany;
    return _SectionCard(
      title: 'ACTIONS',
      children: [
        Row(
          children: [
            Expanded(
              child: OpenVtsButton(
                label: 'Edit profile',
                onPressed: busy ? null : onEditProfile,
              ),
            ),
            const SizedBox(width: OpenVtsSpacing.sm),
            Expanded(
              child: OpenVtsButton(
                label: 'Edit company',
                variant: OpenVtsButtonVariant.secondary,
                onPressed: busy ? null : onEditCompany,
              ),
            ),
          ],
        ),
        const SizedBox(height: OpenVtsSpacing.sm),
        OpenVtsButton(
          label: 'Change password',
          variant: OpenVtsButtonVariant.secondary,
          onPressed: busy ? null : onChangePassword,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Edit profile sheet
// ---------------------------------------------------------------------------

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
    _stateCode = (addr?.stateCode.isNotEmpty == true
        ? addr!.stateCode
        : a.stateCode);
    _cityName = (addr?.cityName.isNotEmpty == true
        ? addr!.cityName
        : a.cityName);
    if (_countryCode!.isEmpty) _countryCode = null;
    if (_stateCode!.isEmpty) _stateCode = null;
    if (_cityName!.isEmpty) _cityName = null;

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
    } catch (_) {
      // Toast handled below; we still let user input plain text fallback.
    }
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

    // Inject fallback items if backend value missing from options list.
    final countryItems = _withFallback<String>(
      values: countries.map((c) => c.code).toList(),
      labels: {for (final c in countries) c.code: c.name},
      current: _countryCode,
    );
    final stateItems = _withFallback<String>(
      values: states.map((s) => s.code).toList(),
      labels: {for (final s in states) s.code: s.name},
      current: _stateCode,
    );
    final cityItems = _withFallback<String>(
      values: cities.map((c) => c.name).toList(),
      labels: {for (final c in cities) c.name: c.name},
      current: _cityName,
    );
    final prefixItems = _withFallback<String>(
      values: prefixes.map((p) => p.dialCode).toList(),
      labels: {
        for (final p in prefixes) p.dialCode: '${p.dialCode} (${p.countryCode})',
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
              const _SheetHeader(title: 'Edit profile'),
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
                        OpenVtsTextField(
                          label: 'Name',
                          controller: _name,
                          textInputAction: TextInputAction.next,
                          validator: (v) =>
                              Validators.required(v, fieldName: 'Name'),
                        ),
                        const SizedBox(height: OpenVtsSpacing.sm),
                        OpenVtsTextField(
                          label: 'Email',
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          validator: (v) {
                            final s = v?.trim() ?? '';
                            if (s.isEmpty) return null;
                            return Validators.email(s);
                          },
                        ),
                        const SizedBox(height: OpenVtsSpacing.sm),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 4,
                              child: _CompactSelect<String>(
                                label: 'Prefix',
                                value: _mobilePrefix,
                                items: prefixItems,
                                onChanged: (v) =>
                                    setState(() => _mobilePrefix = v),
                                validator: (v) =>
                                    (v == null || v.trim().isEmpty)
                                        ? 'Required'
                                        : null,
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
                                validator: (v) => Validators.required(
                                  v,
                                  fieldName: 'Mobile number',
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: OpenVtsSpacing.sm),
                        OpenVtsTextField(
                          label: 'Address',
                          controller: _addressLine,
                          maxLines: 2,
                          textInputAction: TextInputAction.next,
                          validator: (v) => Validators.required(
                            v,
                            fieldName: 'Address',
                          ),
                        ),
                        const SizedBox(height: OpenVtsSpacing.sm),
                        _CompactSelect<String>(
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
                        _CompactSelect<String>(
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
                        _CompactSelect<String>(
                          label: 'City',
                          value: _cityName,
                          items: cityItems,
                          onChanged: (v) => setState(() => _cityName = v),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'City is required'
                              : null,
                        ),
                        const SizedBox(height: OpenVtsSpacing.sm),
                        OpenVtsTextField(
                          label: 'Pincode',
                          controller: _pincode,
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.done,
                          validator: (v) {
                            final s = v?.trim() ?? '';
                            if (s.isEmpty) return null;
                            if (int.tryParse(s) == null) {
                              return 'Pincode must be numeric';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              _SheetFooter(
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
    final controller =
        ref.read(superadminAdminDetailsControllerProvider(widget.adminId).notifier);
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
      await controller.refreshAdmin();
      if (!mounted) return;
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

// ---------------------------------------------------------------------------
// Change password sheet
// ---------------------------------------------------------------------------

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
            const _SheetHeader(title: 'Change password'),
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
                        ),
                        onPressed: () =>
                            setState(() => _obscure1 = !_obscure1),
                      ),
                      validator: (v) {
                        final s = v ?? '';
                        if (s.length < 8) {
                          return 'Minimum 8 characters';
                        }
                        return null;
                      },
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
                        ),
                        onPressed: () =>
                            setState(() => _obscure2 = !_obscure2),
                      ),
                      validator: (v) {
                        if ((v ?? '') != _password.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            _SheetFooter(
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
    final controller =
        ref.read(superadminAdminDetailsControllerProvider(widget.adminId).notifier);
    final ok = await controller.changePassword(
      newPassword: _password.text,
      confirmPassword: _confirm.text,
    );
    if (!mounted) return;
    if (ok) {
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

// ---------------------------------------------------------------------------
// Edit company sheet
// ---------------------------------------------------------------------------

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
    final existing = c?.primaryColor.trim() ?? '';
    _primaryColor = _kPrimaryColorOptions.contains(existing) ? existing : null;
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

  @override
  Widget build(BuildContext context) {
    final state =
        ref.watch(superadminAdminDetailsControllerProvider(widget.adminId));
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final colorItems = _kPrimaryColorOptions
        .map(
          (c) => DropdownMenuItem<String>(
            value: c,
            child: Row(
              children: [
                Container(
                  width: 14,
                  height: 14,
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
        )
        .toList(growable: false);

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
              const _SheetHeader(title: 'Edit company'),
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
                          validator: (v) => Validators.required(
                            v,
                            fieldName: 'Company name',
                          ),
                        ),
                        const SizedBox(height: OpenVtsSpacing.sm),
                        OpenVtsTextField(
                          label: 'Website URL',
                          controller: _website,
                          keyboardType: TextInputType.url,
                          textInputAction: TextInputAction.next,
                          hintText: 'https://example.com',
                        ),
                        const SizedBox(height: OpenVtsSpacing.sm),
                        OpenVtsTextField(
                          label: 'Custom domain',
                          controller: _domain,
                          keyboardType: TextInputType.url,
                          textInputAction: TextInputAction.next,
                          hintText: 'example.com',
                        ),
                        const SizedBox(height: OpenVtsSpacing.sm),
                        _CompactSelect<String>(
                          label: 'Primary color',
                          value: _primaryColor,
                          items: colorItems,
                          onChanged: (v) => setState(() => _primaryColor = v),
                        ),
                        const SizedBox(height: OpenVtsSpacing.md),
                        const _SubSectionLabel(label: 'SOCIAL LINKS'),
                        const SizedBox(height: OpenVtsSpacing.xs),
                        for (final k in _kSocialKeys) ...[
                          OpenVtsTextField(
                            label: _socialLabel(k),
                            controller: _social[k],
                            keyboardType: TextInputType.url,
                            textInputAction: TextInputAction.next,
                          ),
                          const SizedBox(height: OpenVtsSpacing.sm),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              _SheetFooter(
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

    final controller =
        ref.read(superadminAdminDetailsControllerProvider(widget.adminId).notifier);
    final ok = await controller.updateCompany(
      SuperadminAdminCompanyUpdateRequest(
        name: _name.text,
        websiteUrl: _normalizeUrlOptional(_website.text),
        customDomain: _normalizeDomain(_domain.text),
        socialLinks: social,
        primaryColor: _primaryColor ?? '',
      ),
    );
    if (!mounted) return;
    if (ok) {
      await controller.refreshAdmin();
      if (!mounted) return;
      Navigator.of(context).maybePop();
      ToastHelper.showSuccess('Company updated.', context: context);
    } else {
      final msg = ref
              .read(superadminAdminDetailsControllerProvider(widget.adminId))
              .sectionErrorMessage ??
          'Failed to update company.';
      ToastHelper.showError(msg, context: context);
    }
  }
}

// ---------------------------------------------------------------------------
// Shared sheet bits
// ---------------------------------------------------------------------------

class _SheetHeader extends StatelessWidget {
  const _SheetHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        OpenVtsSpacing.md,
        OpenVtsSpacing.sm,
        OpenVtsSpacing.xs,
        0,
      ),
      child: Column(
        children: [
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(top: 6, bottom: OpenVtsSpacing.sm),
            decoration: BoxDecoration(
              color: OpenVtsColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: OpenVtsColors.textPrimary,
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

class _SheetFooter extends StatelessWidget {
  const _SheetFooter({
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
        color: OpenVtsColors.surfaceElevated,
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

class _SubSectionLabel extends StatelessWidget {
  const _SubSectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: OpenVtsColors.textTertiary,
        letterSpacing: 0.4,
      ),
    );
  }
}

class _CompactSelect<T> extends StatelessWidget {
  const _CompactSelect({
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
          style: const TextStyle(
            fontSize: 12,
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

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

List<DropdownMenuItem<String>> _withFallback<T>({
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
