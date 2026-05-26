import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/open_vts_colors.dart';
import '../../../../../core/theme/open_vts_radius.dart';
import '../../../../../core/theme/open_vts_spacing.dart';
import '../../../../../core/theme/open_vts_typography.dart';
import '../../../../../core/utils/date_time_formatter.dart';
import '../../../../../core/utils/validators.dart';
import '../../../../../shared/helpers/toast_helper.dart';
import '../../../../../shared/widgets/open_vts_bottom_sheet.dart';
import '../../../../../shared/widgets/open_vts_button.dart';
import '../../../../../shared/widgets/open_vts_card.dart';
import '../../../../../shared/widgets/open_vts_text_field.dart';
import '../../../controllers/admin_providers.dart';
import '../../../controllers/admin_user_details_controller.dart';
import '../../../models/admin_user_details_model.dart';
import '../../../models/admin_users_model.dart' as admin_users;
import 'admin_user_form_fields.dart';

class AdminUserProfileTab extends ConsumerWidget {
  const AdminUserProfileTab({
    super.key,
    required this.userId,
    this.initialUser,
  });

  final String userId;
  final admin_users.AdminUserListItem? initialUser;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = adminUserDetailsControllerProvider(userId);
    final state = ref.watch(provider);
    final controller = ref.read(provider.notifier);
    final profile = _ProfileSnapshot.resolve(
      details: state.user,
      fallback: initialUser,
      userId: userId,
    );

    if (state.isLoadingProfile && !profile.hasKnownData) {
      return const _ProfileSkeletonCard();
    }

    if (state.errorMessage != null && !profile.hasKnownData) {
      return _SectionErrorCard(
        message: state.errorMessage!,
        onRetry: controller.loadProfile,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (state.sectionErrorMessage != null) ...[
          _InlineError(message: state.sectionErrorMessage!),
          const SizedBox(height: OpenVtsSpacing.sm),
        ],
        _IdentityCard(
          profile: profile,
          isUpdatingStatus: state.isUpdatingStatus,
          onStatusChanged: (isActive) => _updateStatus(
            context,
            controller,
            isActive,
          ),
        ),
        const SizedBox(height: OpenVtsSpacing.sm),
        _CompanyCard(
          profile: profile,
        ),
        const SizedBox(height: OpenVtsSpacing.sm),
        _LocationCard(profile: profile),
        const SizedBox(height: OpenVtsSpacing.sm),
        _StatsCard(
          profile: profile,
          linkedVehiclesCount: state.linkedVehicles.length,
        ),
        const SizedBox(height: OpenVtsSpacing.sm),
        if (_hasRenderableSocialLinks(profile.socialLinks)) ...[
          _SocialLinksCard(socialLinks: profile.socialLinks),
        ],
      ],
    );
  }

  bool _hasRenderableSocialLinks(Map<String, String> links) {
    for (final entry in links.entries) {
      if (entry.value.trim().isNotEmpty) {
        return true;
      }
    }
    return false;
  }

  Future<void> _updateStatus(
    BuildContext context,
    AdminUserDetailsController controller,
    bool isActive,
  ) async {
    final ok = await controller.updateStatus(isActive);
    if (!context.mounted) {
      return;
    }
    if (ok) {
      ToastHelper.showSuccess(
        isActive ? 'User activated.' : 'User deactivated.',
        context: context,
      );
    } else {
      ToastHelper.showError(
        'Unable to update status.',
        context: context,
      );
    }
  }
}

Future<void> showAdminUserEditProfileSheet({
  required BuildContext context,
  required WidgetRef ref,
  required String userId,
  required AdminUserDetails? details,
  required admin_users.AdminUserListItem? fallback,
  required AdminUserDetailsController controller,
}) {
  final profile = _ProfileSnapshot.resolve(
    details: details,
    fallback: fallback,
    userId: userId,
  );
  return _showAdminUserEditProfileSheetWithProfile(
    context: context,
    ref: ref,
    userId: userId,
    profile: profile,
    controller: controller,
  );
}

Future<void> _showAdminUserEditProfileSheetWithProfile({
  required BuildContext context,
  required WidgetRef ref,
  required String userId,
  required _ProfileSnapshot profile,
  required AdminUserDetailsController controller,
}) {
  return OpenVtsBottomSheet.show<void>(
    context: context,
    title: 'Edit Profile',
    initialChildSize: 0.82,
    minChildSize: 0.52,
    maxChildSize: 0.94,
    child: _EditProfileSheet(
      profile: profile,
      onSubmit: (request) async {
        final ok = await controller.updateProfile(request);
        if (!context.mounted) {
          return false;
        }
        if (ok) {
          ToastHelper.showSuccess('Profile updated.', context: context);
        } else {
          ToastHelper.showError(
            ref
                    .read(adminUserDetailsControllerProvider(userId))
                    .sectionErrorMessage ??
                'Unable to update profile.',
            context: context,
          );
        }
        return ok;
      },
    ),
  );
}

Future<void> showAdminUserEditCompanySheet({
  required BuildContext context,
  required WidgetRef ref,
  required String userId,
  required AdminUserDetails? details,
  required admin_users.AdminUserListItem? fallback,
  required AdminUserDetailsController controller,
}) {
  final profile = _ProfileSnapshot.resolve(
    details: details,
    fallback: fallback,
    userId: userId,
  );
  return _showAdminUserEditCompanySheetWithProfile(
    context: context,
    ref: ref,
    userId: userId,
    profile: profile,
    controller: controller,
  );
}

Future<void> _showAdminUserEditCompanySheetWithProfile({
  required BuildContext context,
  required WidgetRef ref,
  required String userId,
  required _ProfileSnapshot profile,
  required AdminUserDetailsController controller,
}) {
  return OpenVtsBottomSheet.show<void>(
    context: context,
    title: 'Edit Company',
    initialChildSize: 0.78,
    minChildSize: 0.48,
    maxChildSize: 0.94,
    child: _CompanySheet(
      initialCompany: profile.company,
      fallbackName: profile.companyName,
      loadCompany: () {
        return ref.read(adminUserDetailsServiceProvider).getCompanyDetails(userId);
      },
      onSubmit: (request) async {
        final ok = await controller.updateCompany(request);
        if (!context.mounted) {
          return false;
        }
        if (ok) {
          ToastHelper.showSuccess('Company updated.', context: context);
        } else {
          ToastHelper.showError(
            ref
                    .read(adminUserDetailsControllerProvider(userId))
                    .sectionErrorMessage ??
                'Unable to update company.',
            context: context,
          );
        }
        return ok;
      },
    ),
  );
}

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

class _IdentityCard extends StatelessWidget {
  const _IdentityCard({
    required this.profile,
    required this.isUpdatingStatus,
    required this.onStatusChanged,
  });

  final _ProfileSnapshot profile;
  final bool isUpdatingStatus;
  final ValueChanged<bool> onStatusChanged;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'IDENTITY',
      trailing: _StatusBadge(isActive: profile.isActive),
      children: [
        _InfoRow(label: 'Name', value: profile.displayName, icon: Icons.person_outline_rounded),
        _InfoRow(label: 'Username', value: profile.usernameLabel, icon: Icons.alternate_email_rounded),
        _InfoRow(label: 'Email', value: profile.email, icon: Icons.mail_outline_rounded),
        _InfoRow(label: 'Phone', value: profile.phone, icon: Icons.call_outlined),
        _InfoRow(
          label: 'Email verified',
          valueWidget: _StatusPill(
            label: profile.isEmailVerified ? 'Verified' : 'Unverified',
            icon: profile.isEmailVerified
                ? Icons.verified_outlined
                : Icons.gpp_maybe_rounded,
            color: profile.isEmailVerified
                ? OpenVtsColors.success
                : OpenVtsColors.warning,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: OpenVtsSpacing.xs),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Account status',
                  style: OpenVtsTypography.meta.copyWith(
                    color: OpenVtsColors.textTertiary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (isUpdatingStatus)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Switch.adaptive(
                  value: profile.isActive,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  onChanged: onStatusChanged,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CompanyCard extends StatelessWidget {
  const _CompanyCard({required this.profile});

  final _ProfileSnapshot profile;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'COMPANY',
      children: [
        _InfoRow(label: 'Company', value: profile.companyName, icon: Icons.business_outlined),
        _InfoRow(label: 'Domain', value: profile.customDomain, icon: Icons.dns_outlined),
        _InfoRow(label: 'Website', value: profile.websiteUrl, icon: Icons.language_outlined),
        _InfoRow(
          label: 'Brand color',
          value: profile.primaryColor,
          icon: Icons.palette_outlined,
          trailing: profile.primaryColor.trim().isNotEmpty
              ? Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: _colorFromName(profile.primaryColor),
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
  const _LocationCard({required this.profile});

  final _ProfileSnapshot profile;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'LOCATION',
      children: [
        _InfoRow(label: 'Address', value: profile.address, icon: Icons.home_outlined),
        _InfoRow(label: 'City', value: profile.city, icon: Icons.location_city_outlined),
        _InfoRow(label: 'State', value: profile.stateCode, icon: Icons.map_outlined),
        _InfoRow(label: 'Country', value: profile.countryCode, icon: Icons.public_outlined),
        _InfoRow(label: 'Pincode', value: profile.pincode, icon: Icons.local_post_office_outlined),
        _InfoRow(label: 'Full address', value: profile.address, icon: Icons.place_outlined),
      ],
    );
  }
}

class _StatsCard extends StatelessWidget {
  const _StatsCard({required this.profile, required this.linkedVehiclesCount});

  final _ProfileSnapshot profile;
  final int linkedVehiclesCount;

  @override
  Widget build(BuildContext context) {
    final vehicles = profile.vehicleCount ?? linkedVehiclesCount;
    return _SectionCard(
      title: 'STATS / TIMELINE',
      children: [
        _InfoRow(label: 'Vehicles', value: vehicles.toString(), icon: Icons.directions_car_outlined),
        _InfoRow(label: 'Created', value: _dateText(profile.createdAt), icon: Icons.event_outlined),
        _InfoRow(label: 'Updated', value: _dateText(profile.updatedAt), icon: Icons.update_rounded),
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
    for (final entry in socialLinks.entries) {
      final value = entry.value.trim();
      if (value.isEmpty) {
        continue;
      }
      rows.add(
        _InfoRow(
          label: _titleCase(entry.key),
          value: value,
          icon: Icons.link_rounded,
        ),
      );
    }
    return _SectionCard(title: 'SOCIAL', children: rows);
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.isActive});

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? OpenVtsColors.success : OpenVtsColors.textTertiary;
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

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(OpenVtsRadius.pill),
          border: Border.all(color: color.withValues(alpha: 0.22)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 11, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: OpenVtsTypography.meta.copyWith(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
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

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(OpenVtsSpacing.sm),
      decoration: BoxDecoration(
        color: OpenVtsColors.error.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(OpenVtsRadius.sm),
        border: Border.all(color: OpenVtsColors.error.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 16,
            color: OpenVtsColors.error,
          ),
          const SizedBox(width: OpenVtsSpacing.xs),
          Expanded(
            child: Text(
              message,
              style: OpenVtsTypography.meta.copyWith(
                color: OpenVtsColors.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionErrorCard extends StatelessWidget {
  const _SectionErrorCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return OpenVtsCard(
      padding: const EdgeInsets.all(OpenVtsSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 17,
                color: OpenVtsColors.error,
              ),
              const SizedBox(width: OpenVtsSpacing.xs),
              Text(
                'Unable to load profile',
                style: OpenVtsTypography.label.copyWith(
                  color: OpenVtsColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: OpenVtsSpacing.xs),
          Text(
            message,
            style: OpenVtsTypography.meta.copyWith(
              color: OpenVtsColors.textSecondary,
            ),
          ),
          const SizedBox(height: OpenVtsSpacing.sm),
          OpenVtsButton(
            label: 'Retry',
            height: 34,
            variant: OpenVtsButtonVariant.secondary,
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}

class _ProfileSkeletonCard extends StatelessWidget {
  const _ProfileSkeletonCard();

  @override
  Widget build(BuildContext context) {
    return const OpenVtsCard(
      padding: EdgeInsets.all(OpenVtsSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SkeletonBox(width: 116, height: 14),
          SizedBox(height: OpenVtsSpacing.md),
          _SkeletonBox(width: double.infinity, height: 11),
          SizedBox(height: OpenVtsSpacing.xs),
          _SkeletonBox(width: double.infinity, height: 11),
          SizedBox(height: OpenVtsSpacing.xs),
          _SkeletonBox(width: 180, height: 11),
        ],
      ),
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  const _SkeletonBox({
    required this.width,
    required this.height,
  });

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: OpenVtsColors.surface,
        borderRadius: BorderRadius.circular(OpenVtsRadius.sm),
      ),
    );
  }
}

class _EditProfileSheet extends ConsumerStatefulWidget {
  const _EditProfileSheet({
    required this.profile,
    required this.onSubmit,
  });

  final _ProfileSnapshot profile;
  final Future<bool> Function(AdminUpdateUserDetailsRequest request) onSubmit;

  @override
  ConsumerState<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends ConsumerState<_EditProfileSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _mobileNumberController;
  late final TextEditingController _usernameController;
  late final TextEditingController _companyNameController;
  late final TextEditingController _addressController;
  late final TextEditingController _pincodeController;

  var _mobilePrefixes = const <admin_users.AdminUserMobilePrefixOption>[];
  var _countries = const <admin_users.AdminUserCountryOption>[];
  var _states = const <admin_users.AdminUserStateOption>[];
  var _cities = const <admin_users.AdminUserCityOption>[];
  String? _mobilePrefix;
  String? _countryCode;
  String? _stateCode;
  String? _city;
  var _isLoadingReferences = true;
  var _isLoadingStates = false;
  var _isLoadingCities = false;
  var _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final profile = widget.profile;
    _nameController = TextEditingController(text: profile.name);
    _emailController = TextEditingController(text: profile.email);
    _mobileNumberController = TextEditingController(text: profile.mobileNumber);
    _usernameController = TextEditingController(text: profile.username);
    _companyNameController = TextEditingController(text: profile.companyName);
    _addressController = TextEditingController(text: profile.address);
    _pincodeController = TextEditingController(text: profile.pincode);
    _mobilePrefix = _blankToNull(profile.mobilePrefix);
    _countryCode = _blankToNull(profile.countryCode)?.toUpperCase();
    _stateCode = _blankToNull(profile.stateCode)?.toUpperCase();
    _city = _blankToNull(profile.city);
    _loadInitialReferences();
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
                if (_isLoadingReferences) ...[
                  const LinearProgressIndicator(minHeight: 2),
                  const SizedBox(height: OpenVtsSpacing.md),
                ],
                AdminUserFormSection(
                  title: 'Identity',
                  children: [
                    OpenVtsTextField(
                      label: 'Name',
                      controller: _nameController,
                      textInputAction: TextInputAction.next,
                      prefixIcon: Icons.person_outline_rounded,
                      validator: (value) => Validators.required(
                        value,
                        fieldName: 'Name',
                      ),
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
                    const SizedBox(height: OpenVtsSpacing.sm),
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
                  ],
                ),
                const SizedBox(height: OpenVtsSpacing.lg),
                AdminUserFormSection(
                  title: 'Location',
                  children: [
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
                    const SizedBox(height: OpenVtsSpacing.sm),
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
          _SheetActions(
            isSubmitting: _isSubmitting,
            onSubmit: _submit,
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

  Future<void> _loadInitialReferences() async {
    try {
      final controller = ref.read(adminUsersControllerProvider.notifier);
      final countriesFuture = controller.getCountries();
      final prefixesFuture = controller.getMobilePrefixes();
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

      await _loadStates(_countryCode, clearSelection: false);
      await _loadCities(_countryCode, _stateCode, clearSelection: false);
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _isLoadingReferences = false);
      ToastHelper.showError('Unable to load form options.', context: context);
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
      _states = const <admin_users.AdminUserStateOption>[];
      _cities = const <admin_users.AdminUserCityOption>[];
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
      _cities = const <admin_users.AdminUserCityOption>[];
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
      final cities = await ref
          .read(adminUsersControllerProvider.notifier)
          .getCities(requestedCountry, requestedState);
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
    setState(() => _isSubmitting = true);
    final ok = await widget.onSubmit(
      AdminUpdateUserDetailsRequest(
        name: _nameController.text,
        email: _emailController.text,
        mobilePrefix: _mobilePrefix,
        mobileNumber: _mobileNumberController.text,
        username: _usernameController.text,
        companyName: _companyNameController.text,
        address: _addressController.text,
        countryCode: _countryCode,
        stateCode: _stateCode,
        city: _city,
        pincode: _pincodeController.text,
      ),
    );
    if (!mounted) {
      return;
    }
    setState(() => _isSubmitting = false);
    if (ok) {
      Navigator.of(context).pop();
    }
  }

  String? _pincodeValidator(String? value) {
    final normalized = value?.trim() ?? '';
    if (normalized.length > 10) {
      return 'Use 10 characters or fewer';
    }
    return null;
  }
}

class _PasswordSheet extends StatefulWidget {
  const _PasswordSheet({required this.onSubmit});

  final Future<bool> Function(String password) onSubmit;

  @override
  State<_PasswordSheet> createState() => _PasswordSheetState();
}

class _PasswordSheetState extends State<_PasswordSheet> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  var _obscurePassword = true;
  var _obscureConfirm = true;
  var _isSubmitting = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        controller: PrimaryScrollController.maybeOf(context),
        padding: const EdgeInsets.all(OpenVtsSpacing.md),
        children: [
          OpenVtsTextField(
            label: 'New password',
            controller: _passwordController,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.next,
            prefixIcon: Icons.lock_outline_rounded,
            suffixIcon: IconButton(
              tooltip: _obscurePassword ? 'Show password' : 'Hide password',
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
          const SizedBox(height: OpenVtsSpacing.sm),
          OpenVtsTextField(
            label: 'Confirm password',
            controller: _confirmController,
            obscureText: _obscureConfirm,
            textInputAction: TextInputAction.done,
            prefixIcon: Icons.lock_reset_rounded,
            suffixIcon: IconButton(
              tooltip: _obscureConfirm ? 'Show password' : 'Hide password',
              onPressed: () {
                setState(() => _obscureConfirm = !_obscureConfirm);
              },
              icon: Icon(
                _obscureConfirm
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                size: 18,
              ),
            ),
            validator: _confirmValidator,
          ),
          const SizedBox(height: OpenVtsSpacing.lg),
          OpenVtsButton(
            label: 'Update Password',
            height: 40,
            isLoading: _isSubmitting,
            onPressed: _isSubmitting ? null : _submit,
            trailingIcon: Icons.check_rounded,
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _isSubmitting = true);
    final ok = await widget.onSubmit(_passwordController.text.trim());
    if (!mounted) {
      return;
    }
    setState(() => _isSubmitting = false);
    if (ok) {
      Navigator.of(context).pop();
    }
  }

  String? _passwordValidator(String? value) {
    final normalized = value?.trim() ?? '';
    if (normalized.isEmpty) {
      return 'Required';
    }
    if (normalized.length < 8) {
      return 'Use at least 8 characters';
    }
    return null;
  }

  String? _confirmValidator(String? value) {
    final normalized = value?.trim() ?? '';
    if (normalized.isEmpty) {
      return 'Required';
    }
    if (normalized != _passwordController.text.trim()) {
      return 'Passwords do not match';
    }
    return null;
  }
}

class _CompanySheet extends StatefulWidget {
  const _CompanySheet({
    required this.initialCompany,
    required this.fallbackName,
    required this.loadCompany,
    required this.onSubmit,
  });

  final AdminUserCompany? initialCompany;
  final String fallbackName;
  final Future<AdminUserCompany?> Function() loadCompany;
  final Future<bool> Function(AdminUpdateUserCompanyRequest request) onSubmit;

  @override
  State<_CompanySheet> createState() => _CompanySheetState();
}

class _CompanySheetState extends State<_CompanySheet> {
  static const _socialKeys = <String>[
    'facebook',
    'twitter',
    'linkedin',
    'instagram',
    'youtube',
    'github',
  ];

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _websiteController;
  late final TextEditingController _customDomainController;
  late final Map<String, TextEditingController> _socialControllers;
  String? _primaryColor;
  var _isLoadingCompany = false;
  var _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final company = widget.initialCompany;
    _nameController = TextEditingController(
      text: _initialText(company?.name ?? widget.fallbackName),
    );
    _websiteController = TextEditingController(
      text: _initialText(company?.websiteUrl),
    );
    _customDomainController = TextEditingController(
      text: _initialText(company?.customDomain),
    );
    _primaryColor = _normalizePrimaryColorOption(company?.primaryColor);
    _socialControllers = <String, TextEditingController>{
      for (final socialKey in _socialKeys)
        socialKey: TextEditingController(
          text: _initialText(company?.socialLinks[socialKey]),
        ),
    };
    if (_shouldLoadCompany(company)) {
      _loadCompany();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _websiteController.dispose();
    _customDomainController.dispose();
    for (final controller in _socialControllers.values) {
      controller.dispose();
    }
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
                if (_isLoadingCompany) ...[
                  const LinearProgressIndicator(minHeight: 2),
                  const SizedBox(height: OpenVtsSpacing.md),
                ],
                AdminUserFormSection(
                  title: 'Company',
                  children: [
                    OpenVtsTextField(
                      label: 'Name',
                      controller: _nameController,
                      textInputAction: TextInputAction.next,
                      prefixIcon: Icons.apartment_rounded,
                      validator: (value) => Validators.required(
                        value,
                        fieldName: 'Company name',
                      ),
                    ),
                    const SizedBox(height: OpenVtsSpacing.sm),
                    OpenVtsTextField(
                      label: 'Website',
                      controller: _websiteController,
                      textInputAction: TextInputAction.next,
                      keyboardType: TextInputType.url,
                      prefixIcon: Icons.language_rounded,
                    ),
                    const SizedBox(height: OpenVtsSpacing.sm),
                    OpenVtsTextField(
                      label: 'Custom Domain',
                      controller: _customDomainController,
                      textInputAction: TextInputAction.next,
                      keyboardType: TextInputType.url,
                      prefixIcon: Icons.dns_outlined,
                    ),
                    const SizedBox(height: OpenVtsSpacing.sm),
                    AdminUserDropdownField(
                      label: 'Primary Color',
                      value: _primaryColor,
                      options: _primaryColorOptions,
                      hintText: 'Select color',
                      prefixIcon: Icons.palette_outlined,
                      validator: requiredDropdown,
                      onChanged: (value) {
                        setState(() => _primaryColor = value);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: OpenVtsSpacing.lg),
                AdminUserFormSection(
                  title: 'Social Links',
                  children: [
                    for (final socialKey in _socialKeys) ...[
                      OpenVtsTextField(
                        label: _titleCase(socialKey),
                        controller: _socialControllers[socialKey],
                        textInputAction: socialKey == _socialKeys.last
                            ? TextInputAction.done
                            : TextInputAction.next,
                        keyboardType: TextInputType.url,
                        prefixIcon: Icons.link_rounded,
                      ),
                      if (socialKey != _socialKeys.last)
                        const SizedBox(height: OpenVtsSpacing.sm),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          _SheetActions(
            isSubmitting: _isSubmitting,
            onSubmit: _submit,
          ),
        ],
      ),
    );
  }

  List<AdminUserDropdownOption> get _primaryColorOptions {
    return AdminUpdateUserCompanyRequest.allowedPrimaryColors
        .map(
          (color) => AdminUserDropdownOption(value: color, label: color),
        )
        .toList(growable: false);
  }

  Future<void> _loadCompany() async {
    setState(() => _isLoadingCompany = true);
    try {
      final company = await widget.loadCompany();
      if (!mounted) {
        return;
      }
      if (company != null) {
        _applyCompany(company);
      }
      setState(() => _isLoadingCompany = false);
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _isLoadingCompany = false);
      ToastHelper.showError('Unable to load company details.',
          context: context);
    }
  }

  void _applyCompany(AdminUserCompany company) {
    _nameController.text = _initialText(company.name);
    _websiteController.text = _initialText(company.websiteUrl);
    _customDomainController.text = _initialText(company.customDomain);
    _primaryColor = _normalizePrimaryColorOption(company.primaryColor);
    for (final socialKey in _socialKeys) {
      _socialControllers[socialKey]?.text =
          _initialText(company.socialLinks[socialKey]);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _isSubmitting = true);
    final socialLinks = <String, String>{};
    for (final entry in _socialControllers.entries) {
      final normalized = _normalizeUrl(entry.value.text);
      if (normalized.isNotEmpty) {
        socialLinks[entry.key] = normalized;
      }
    }

    final ok = await widget.onSubmit(
      AdminUpdateUserCompanyRequest(
        name: _nameController.text,
        websiteUrl: _normalizeUrl(_websiteController.text),
        customDomain: _hostnameOnly(_customDomainController.text),
        primaryColor: _primaryColor ?? 'Black',
        socialLinks: socialLinks,
      ),
    );
    if (!mounted) {
      return;
    }
    setState(() => _isSubmitting = false);
    if (ok) {
      Navigator.of(context).pop();
    }
  }
}

class _SheetActions extends StatelessWidget {
  const _SheetActions({
    required this.isSubmitting,
    required this.onSubmit,
  });

  final bool isSubmitting;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
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
                isLoading: isSubmitting,
                onPressed: isSubmitting ? null : onSubmit,
                trailingIcon: Icons.check_rounded,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileSnapshot {
  const _ProfileSnapshot({
    required this.id,
    required this.name,
    required this.username,
    required this.email,
    required this.mobilePrefix,
    required this.mobileNumber,
    required this.phone,
    required this.isEmailVerified,
    required this.isActive,
    required this.companyName,
    required this.company,
    required this.websiteUrl,
    required this.customDomain,
    required this.primaryColor,
    required this.socialLinks,
    required this.address,
    required this.countryCode,
    required this.stateCode,
    required this.city,
    required this.pincode,
    required this.createdAt,
    required this.updatedAt,
    required this.vehicleCount,
  });

  final String id;
  final String name;
  final String username;
  final String email;
  final String mobilePrefix;
  final String mobileNumber;
  final String phone;
  final bool isEmailVerified;
  final bool isActive;
  final String companyName;
  final AdminUserCompany? company;
  final String websiteUrl;
  final String customDomain;
  final String primaryColor;
  final Map<String, String> socialLinks;
  final String address;
  final String countryCode;
  final String stateCode;
  final String city;
  final String pincode;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int? vehicleCount;

  bool get hasKnownData =>
      name.isNotEmpty || username.isNotEmpty || email.isNotEmpty;

  String get displayName {
    if (name.trim().isNotEmpty) {
      return name.trim();
    }
    if (username.trim().isNotEmpty) {
      return username.trim();
    }
    if (email.trim().isNotEmpty) {
      return email.trim();
    }
    return 'User';
  }

  String get usernameLabel {
    if (username.trim().isNotEmpty) {
      return '@${username.trim()}';
    }
    return '-';
  }

  static _ProfileSnapshot resolve({
    required AdminUserDetails? details,
    required admin_users.AdminUserListItem? fallback,
    required String userId,
  }) {
    if (details != null) {
      final address = details.address;
      final company = details.companies.isNotEmpty
          ? details.companies.first
          : _companyFromName(details.organization);
      return _ProfileSnapshot(
        id: details.id.isNotEmpty ? details.id : userId,
        name: details.name,
        username: details.username,
        email: details.email,
        mobilePrefix: details.mobilePrefix,
        mobileNumber: details.mobileNumber,
        phone: details.mobileDisplay,
        isEmailVerified: details.isEmailVerified,
        isActive: details.isActive,
        companyName: company?.name ?? details.organization,
        company: company,
        websiteUrl: company?.websiteUrl ?? '',
        customDomain: company?.customDomain ?? '',
        primaryColor: company?.primaryColor ?? '',
        socialLinks: company?.socialLinks ?? const <String, String>{},
        address: _firstNonEmpty([
          address?.addressLine,
          address?.fullAddress,
          details.location,
        ]),
        countryCode:
            _firstNonEmpty([details.countryCode, address?.countryCode]),
        stateCode: address?.stateCode ?? '',
        city: address?.cityName ?? '',
        pincode: address?.pincode ?? '',
        createdAt: details.createdAt,
        updatedAt: details.updatedAt,
        vehicleCount: details.vehicleCount,
      );
    }

    if (fallback != null) {
      final company = _companyFromName(fallback.companyName);
      return _ProfileSnapshot(
        id: fallback.id.isNotEmpty ? fallback.id : userId,
        name: fallback.name,
        username: fallback.username,
        email: fallback.email,
        mobilePrefix: fallback.mobilePrefix,
        mobileNumber: fallback.mobileNumber,
        phone: fallback.mobileDisplay,
        isEmailVerified: fallback.isEmailVerified,
        isActive: fallback.isActive,
        companyName: fallback.companyName,
        company: company,
        websiteUrl: '',
        customDomain: '',
        primaryColor: '',
        socialLinks: const <String, String>{},
        address: fallback.location,
        countryCode: fallback.countryCode,
        stateCode: fallback.stateCode,
        city: fallback.city,
        pincode: fallback.pincode,
        createdAt: fallback.createdAt,
        updatedAt: fallback.updatedAt,
        vehicleCount: fallback.vehicleCount,
      );
    }

    return _ProfileSnapshot(
      id: userId,
      name: '',
      username: '',
      email: '',
      mobilePrefix: '',
      mobileNumber: '',
      phone: '',
      isEmailVerified: false,
      isActive: false,
      companyName: '',
      company: null,
      websiteUrl: '',
      customDomain: '',
      primaryColor: '',
      socialLinks: const <String, String>{},
      address: '',
      countryCode: '',
      stateCode: '',
      city: '',
      pincode: '',
      createdAt: null,
      updatedAt: null,
      vehicleCount: null,
    );
  }
}

AdminUserCompany? _companyFromName(String name) {
  final normalized = name.trim();
  if (normalized.isEmpty || normalized == '-') {
    return null;
  }
  return AdminUserCompany(
    id: '',
    name: normalized,
    websiteUrl: '',
    customDomain: '',
    socialLinks: const <String, String>{},
    logoLightUrl: '',
    logoDarkUrl: '',
    faviconUrl: '',
    primaryColor: '',
  );
}

bool _shouldLoadCompany(AdminUserCompany? company) {
  if (company == null) {
    return true;
  }
  return company.websiteUrl.isEmpty &&
      company.customDomain.isEmpty &&
      company.primaryColor.isEmpty &&
      company.socialLinks.isEmpty;
}

String _displayValue(String value) {
  final normalized = value.trim();
  if (normalized.isEmpty || normalized == '-') {
    return '-';
  }
  return normalized;
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

String _firstNonEmpty(List<String?> values) {
  for (final value in values) {
    final normalized = value?.trim() ?? '';
    if (normalized.isNotEmpty && normalized != '-') {
      return normalized;
    }
  }
  return '';
}

String _dateText(DateTime? value) {
  if (value == null) {
    return '-';
  }
  return const DateTimeFormatter().formatDate(value.toLocal());
}

String _titleCase(String value) {
  final normalized = value.trim();
  if (normalized.isEmpty) {
    return normalized;
  }
  return '${normalized[0].toUpperCase()}${normalized.substring(1)}';
}

Color _colorFromName(String name) {
  switch (name.trim().toLowerCase()) {
    case 'black':
      return const Color(0xFF111827);
    case 'blue':
      return const Color(0xFF2563EB);
    case 'green':
      return const Color(0xFF16A34A);
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

String _normalizeUrl(String value) {
  final normalized = value.trim();
  if (normalized.isEmpty) {
    return '';
  }
  final lower = normalized.toLowerCase();
  if (lower.startsWith('http://') || lower.startsWith('https://')) {
    return normalized;
  }
  return 'https://$normalized';
}

String _hostnameOnly(String value) {
  final normalized = value.trim();
  if (normalized.isEmpty) {
    return '';
  }
  final candidate =
      normalized.contains('://') ? normalized : 'https://$normalized';
  final uri = Uri.tryParse(candidate);
  if (uri != null && uri.host.isNotEmpty) {
    return uri.host.toLowerCase();
  }
  return normalized.split('/').first.split(':').first.toLowerCase();
}

String? _normalizePrimaryColorOption(String? value) {
  final normalized = value?.trim() ?? '';
  for (final color in AdminUpdateUserCompanyRequest.allowedPrimaryColors) {
    if (color.toLowerCase() == normalized.toLowerCase()) {
      return color;
    }
  }
  return 'Black';
}
