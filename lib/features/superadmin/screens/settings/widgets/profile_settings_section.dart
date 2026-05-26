import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../../core/providers/core_providers.dart';
import '../../../../../core/theme/open_vts_colors.dart';
import '../../../../../core/theme/open_vts_radius.dart';
import '../../../../../core/theme/open_vts_spacing.dart';
import '../../../../../core/theme/open_vts_typography.dart';
import '../../../../../shared/helpers/toast_helper.dart';
import '../../../../../shared/widgets/open_vts_button.dart';
import '../../../../../shared/widgets/open_vts_card.dart';
import '../../../../../shared/widgets/open_vts_loader.dart';
import '../../../../../shared/widgets/open_vts_role_home.dart';
import '../../../../../shared/widgets/open_vts_text_field.dart';
import '../../../../auth/controllers/auth_controller.dart';
import '../../../controllers/superadmin_providers.dart';
import '../../../controllers/superadmin_settings_controller.dart';
import '../../../models/superadmin_administrator_model.dart';
import '../../../models/superadmin_settings_model.dart';
import '../../../models/superadmin_settings_state.dart';

const _allowedImageExts = ['png', 'jpg', 'jpeg', 'webp'];
const int _maxImageBytes = 5 * 1024 * 1024;

class ProfileSettingsSection extends ConsumerStatefulWidget {
  const ProfileSettingsSection({super.key, required this.state});

  final SuperadminSettingsState state;

  @override
  ConsumerState<ProfileSettingsSection> createState() =>
      _ProfileSettingsSectionState();
}

class _ProfileSettingsSectionState
    extends ConsumerState<ProfileSettingsSection> {
  final _imagePicker = ImagePicker();
  bool _subscriptionRequested = false;
  String? _photoCacheBust;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeLoadSubscription());
  }

  @override
  void didUpdateWidget(covariant ProfileSettingsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _maybeLoadSubscription();
    });
  }

  void _maybeLoadSubscription() {
    if (_subscriptionRequested) return;
    final profile = widget.state.profile;
    if (profile == null) return;
    _subscriptionRequested = true;
    unawaited(
      ref
          .read(superadminSettingsControllerProvider.notifier)
          .loadEmailSubscription(),
    );
  }

  SuperadminSettingsController get _controller =>
      ref.read(superadminSettingsControllerProvider.notifier);

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final profile = state.profile;

    if (state.isLoadingProfile && profile == null) {
      return const OpenVtsCard(
        padding: EdgeInsets.symmetric(vertical: OpenVtsSpacing.lg),
        child: Center(child: OpenVtsLoader()),
      );
    }

    if (profile == null) {
      return OpenVtsCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              state.sectionErrorMessage ?? 'No profile available.',
              style: const TextStyle(
                fontFamily: OpenVtsTypography.primaryFontFamily,
                fontSize: 12.5,
                color: OpenVtsColors.textSecondary,
              ),
            ),
            const SizedBox(height: OpenVtsSpacing.sm),
            OpenVtsButton(
              label: 'Retry',
              variant: OpenVtsButtonVariant.secondary,
              height: 38,
              onPressed: _controller.loadProfile,
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ProfileHeaderCard(
          profile: profile,
          isUploading: state.isUploadingProfilePhoto,
          cacheBust: _photoCacheBust,
          onPickPhoto: _pickPhoto,
        ),
        const SizedBox(height: OpenVtsSpacing.sm),
        _VerificationCard(
          profile: profile,
          isRequestingEmailOtp: state.isRequestingEmailOtp,
          isRequestingWhatsAppOtp: state.isRequestingWhatsAppOtp,
          onVerifyEmail: () => _openOtpSheet(_OtpChannel.email),
          onVerifyWhatsApp: () => _openOtpSheet(_OtpChannel.whatsapp),
        ),
        const SizedBox(height: OpenVtsSpacing.sm),
        _ActionCard(
          icon: Icons.edit_outlined,
          title: 'Edit Profile',
          subtitle: 'Update personal details and address.',
          onTap: _openEditProfileSheet,
        ),
        const SizedBox(height: OpenVtsSpacing.xs),
        _ActionCard(
          icon: Icons.lock_outline_rounded,
          title: 'Change Password',
          subtitle: 'Rotate your account password.',
          onTap: _openChangePasswordSheet,
        ),
        if (profile.company != null) ...[
          const SizedBox(height: OpenVtsSpacing.xs),
          _ActionCard(
            icon: Icons.business_outlined,
            title: 'Company Details',
            subtitle: profile.company?.name?.trim().isNotEmpty == true
                ? profile.company!.name!
                : 'Edit company information.',
            onTap: _openEditCompanySheet,
          ),
        ],
        const SizedBox(height: OpenVtsSpacing.sm),
        _EmailSubscriptionCard(
          subscribed: state.emailSubscribed,
          isLoading: state.isLoadingEmailSubscription,
          isSubscribing: state.isSubscribingEmail,
          onSubscribe: _handleSubscribe,
          onRefresh: () =>
              unawaited(_controller.loadEmailSubscription()),
        ),
        const SizedBox(height: OpenVtsSpacing.sm),
        _LogoutCard(onLogout: _handleLogout),
      ],
    );
  }

  // ---------- AuthController sync ----------

  Future<void> _syncCurrentUser() async {
    final profile = ref
        .read(superadminSettingsControllerProvider)
        .profile;
    if (profile == null) return;
    final current = ref.read(authControllerProvider).user;
    if (current == null) return;

    final address = profile.address;
    final updated = current.copyWith(
      name: profile.name ?? current.name,
      email: profile.email ?? current.email,
      username: profile.username ?? current.username,
      profileUrl: profile.profileUrl ?? current.profileUrl,
      mobilePrefix: profile.mobilePrefix ?? current.mobilePrefix,
      mobileNumber: profile.mobileNumber ?? current.mobileNumber,
      addressLine: address?.addressLine ?? current.addressLine,
      countryCode: address?.countryCode ?? current.countryCode,
      stateCode: address?.stateCode ?? current.stateCode,
      cityName: address?.cityName ?? current.cityName,
      pincode: address?.pincode ?? current.pincode,
    );
    await ref
        .read(authControllerProvider.notifier)
        .replaceCurrentUser(updated);
  }

  // ---------- Photo upload ----------

  Future<void> _pickPhoto() async {
    if (widget.state.isUploadingProfilePhoto) return;

    final profile = widget.state.profile;
    final userId = profile?.uid?.toString();
    if (userId == null || userId.isEmpty) {
      ToastHelper.showError('Profile not loaded yet.');
      return;
    }

    XFile? picked;
    try {
      picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        imageQuality: 90,
      );
    } catch (_) {
      ToastHelper.showError('Unable to open image picker.');
      return;
    }
    if (picked == null) return;

    final ext = picked.name.split('.').last.toLowerCase();
    if (!_allowedImageExts.contains(ext)) {
      ToastHelper.showError(
        'Unsupported format. Use PNG, JPG, JPEG or WEBP.',
      );
      return;
    }

    final Uint8List bytes;
    try {
      bytes = await picked.readAsBytes();
    } catch (_) {
      ToastHelper.showError('Unable to read the selected image.');
      return;
    }
    if (bytes.isEmpty) {
      ToastHelper.showError('Selected file is empty.');
      return;
    }
    if (bytes.length > _maxImageBytes) {
      ToastHelper.showError('Image too large. Max 5 MB.');
      return;
    }

    final ok = await _controller.uploadProfilePhoto(
      userId: userId,
      bytes: bytes,
      fileName: picked.name,
    );
    if (!mounted) return;
    if (ok) {
      setState(() {
        _photoCacheBust =
            DateTime.now().millisecondsSinceEpoch.toString();
      });
      await _syncCurrentUser();
      if (!mounted) return;
      ToastHelper.showSuccess('Profile photo updated');
    } else {
      final msg = ref
              .read(superadminSettingsControllerProvider)
              .sectionErrorMessage ??
          'Unable to upload photo.';
      ToastHelper.showError(msg);
    }
  }

  // ---------- Sheets ----------

  Future<void> _openEditProfileSheet() async {
    final profile = widget.state.profile;
    if (profile == null) return;
    final saved = await _showSheet<bool>(
      child: _EditProfileSheet(profile: profile),
    );
    if (saved == true && mounted) {
      await _syncCurrentUser();
      if (!mounted) return;
      ToastHelper.showSuccess('Profile updated');
    }
  }

  Future<void> _openChangePasswordSheet() async {
    final ok = await _showSheet<bool>(child: const _ChangePasswordSheet());
    if (ok == true && mounted) {
      ToastHelper.showSuccess('Password changed');
    }
  }

  Future<void> _openEditCompanySheet() async {
    final profile = widget.state.profile;
    final company = profile?.company;
    if (company == null) return;
    final saved = await _showSheet<bool>(
      child: _EditCompanySheet(company: company),
    );
    if (saved == true && mounted) {
      await _syncCurrentUser();
      if (!mounted) return;
      ToastHelper.showSuccess('Company updated');
    }
  }

  Future<void> _openOtpSheet(_OtpChannel channel) async {
    final ok = await _showSheet<bool>(
      child: _OtpVerificationSheet(channel: channel),
    );
    if (ok == true && mounted) {
      ToastHelper.showSuccess(
        channel == _OtpChannel.email
            ? 'Email verified'
            : 'WhatsApp verified',
      );
    }
  }

  Future<T?> _showSheet<T>({required Widget child}) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BottomSheetShell(child: child),
    );
  }

  Future<void> _handleSubscribe() async {
    final ok = await _controller.subscribeEmail();
    if (!mounted) return;
    if (ok) {
      ToastHelper.showSuccess('Subscribed to email updates');
    } else {
      final msg = ref
              .read(superadminSettingsControllerProvider)
              .sectionErrorMessage ??
          'Unable to subscribe.';
      ToastHelper.showError(msg);
    }
  }

  Future<void> _handleLogout() async {
    final activeRole = ref.read(authControllerProvider).activeRole;
    final loggedOut =
        await ref.read(authControllerProvider.notifier).logout();
    if (!mounted) return;
    final label = (loggedOut ?? activeRole)?.displayLabel;
    if (label != null) {
      ToastHelper.showInfo('Logged out from $label');
    }
  }
}

// =====================================================================
// Header card
// =====================================================================

class _ProfileHeaderCard extends ConsumerWidget {
  const _ProfileHeaderCard({
    required this.profile,
    required this.isUploading,
    required this.cacheBust,
    required this.onPickPhoto,
  });

  final SuperadminProfileSettings profile;
  final bool isUploading;
  final String? cacheBust;
  final VoidCallback onPickPhoto;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final baseUrl = ref.watch(apiBaseUrlProvider);
    var url = resolveProfileImageUrl(baseUrl, profile.profileUrl);
    if (url != null && cacheBust != null) {
      final sep = url.contains('?') ? '&' : '?';
      url = '$url${sep}ts=$cacheBust';
    }
    final name = (profile.name ?? '').trim();
    final username = (profile.username ?? '').trim();
    final email = (profile.email ?? '').trim();
    final mobile = [
      profile.mobilePrefix?.trim() ?? '',
      profile.mobileNumber?.trim() ?? '',
    ].where((s) => s.isNotEmpty).join(' ');

    return OpenVtsCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _AvatarWithEdit(
            url: url,
            name: name.isNotEmpty ? name : 'S',
            isUploading: isUploading,
            onTap: onPickPhoto,
          ),
          const SizedBox(width: OpenVtsSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.isNotEmpty ? name : 'Superadmin',
                  style: const TextStyle(
                    fontFamily: OpenVtsTypography.primaryFontFamily,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: OpenVtsColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (username.isNotEmpty) ...[
                  const SizedBox(height: 1),
                  Text(
                    '@$username',
                    style: const TextStyle(
                      fontFamily: OpenVtsTypography.primaryFontFamily,
                      fontSize: 11.5,
                      color: OpenVtsColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (email.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    email,
                    style: const TextStyle(
                      fontFamily: OpenVtsTypography.primaryFontFamily,
                      fontSize: 11.5,
                      color: OpenVtsColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (mobile.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    mobile,
                    style: const TextStyle(
                      fontFamily: OpenVtsTypography.primaryFontFamily,
                      fontSize: 11.5,
                      color: OpenVtsColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (profile.credits != null) ...[
                  const SizedBox(height: OpenVtsSpacing.xs),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: OpenVtsColors.surface,
                      borderRadius:
                          BorderRadius.circular(OpenVtsRadius.pill),
                      border: Border.all(color: OpenVtsColors.border),
                    ),
                    child: Text(
                      '${profile.credits!.toStringAsFixed(0)} credits',
                      style: const TextStyle(
                        fontFamily: OpenVtsTypography.primaryFontFamily,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: OpenVtsColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AvatarWithEdit extends StatelessWidget {
  const _AvatarWithEdit({
    required this.url,
    required this.name,
    required this.isUploading,
    required this.onTap,
  });

  final String? url;
  final String name;
  final bool isUploading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasUrl = (url ?? '').trim().isNotEmpty;
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'S';

    return SizedBox(
      width: 56,
      height: 56,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: OpenVtsColors.brandInk,
              borderRadius: BorderRadius.circular(OpenVtsRadius.md),
              image: hasUrl
                  ? DecorationImage(
                      image: NetworkImage(url!),
                      fit: BoxFit.cover,
                      onError: (_, __) {},
                    )
                  : null,
            ),
            alignment: Alignment.center,
            child: hasUrl
                ? null
                : Text(
                    initial,
                    style: const TextStyle(
                      fontFamily: OpenVtsTypography.primaryFontFamily,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: OpenVtsColors.white,
                    ),
                  ),
          ),
          if (isUploading)
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.45),
                  borderRadius:
                      BorderRadius.circular(OpenVtsRadius.md),
                ),
                child: const Center(
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(
                        OpenVtsColors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          Positioned(
            right: -2,
            bottom: -2,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: isUploading ? null : onTap,
                borderRadius: BorderRadius.circular(OpenVtsRadius.pill),
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: OpenVtsColors.white,
                    border: Border.all(
                      color: OpenVtsColors.border,
                    ),
                    borderRadius:
                        BorderRadius.circular(OpenVtsRadius.pill),
                  ),
                  child: const Icon(
                    Icons.camera_alt_rounded,
                    size: 12,
                    color: OpenVtsColors.textPrimary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =====================================================================
// Verification chips card
// =====================================================================

class _VerificationCard extends StatelessWidget {
  const _VerificationCard({
    required this.profile,
    required this.isRequestingEmailOtp,
    required this.isRequestingWhatsAppOtp,
    required this.onVerifyEmail,
    required this.onVerifyWhatsApp,
  });

  final SuperadminProfileSettings profile;
  final bool isRequestingEmailOtp;
  final bool isRequestingWhatsAppOtp;
  final VoidCallback onVerifyEmail;
  final VoidCallback onVerifyWhatsApp;

  @override
  Widget build(BuildContext context) {
    return OpenVtsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _VerificationRow(
            icon: Icons.mail_outline_rounded,
            label: 'Email',
            value: profile.email ?? '',
            verified: profile.isEmailVerified,
            busy: isRequestingEmailOtp,
            onVerify: onVerifyEmail,
          ),
          const Divider(
            height: OpenVtsSpacing.md,
            color: OpenVtsColors.border,
          ),
          _VerificationRow(
            icon: Icons.chat_outlined,
            label: 'WhatsApp',
            value: [
              profile.mobilePrefix?.trim() ?? '',
              profile.mobileNumber?.trim() ?? '',
            ].where((s) => s.isNotEmpty).join(' '),
            verified: profile.isMobileVerified,
            busy: isRequestingWhatsAppOtp,
            onVerify: onVerifyWhatsApp,
          ),
        ],
      ),
    );
  }
}

class _VerificationRow extends StatelessWidget {
  const _VerificationRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.verified,
    required this.busy,
    required this.onVerify,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool verified;
  final bool busy;
  final VoidCallback onVerify;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: OpenVtsColors.textSecondary),
        const SizedBox(width: OpenVtsSpacing.xs),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontFamily: OpenVtsTypography.primaryFontFamily,
                  fontSize: 11,
                  color: OpenVtsColors.textTertiary,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                value.isNotEmpty ? value : '—',
                style: const TextStyle(
                  fontFamily: OpenVtsTypography.primaryFontFamily,
                  fontSize: 12.5,
                  color: OpenVtsColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: OpenVtsSpacing.xs),
        if (verified)
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: OpenVtsColors.success.withValues(alpha: 0.10),
              borderRadius:
                  BorderRadius.circular(OpenVtsRadius.pill),
              border: Border.all(
                color: OpenVtsColors.success.withValues(alpha: 0.4),
              ),
            ),
            child: const Text(
              'Verified',
              style: TextStyle(
                fontFamily: OpenVtsTypography.primaryFontFamily,
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: OpenVtsColors.success,
              ),
            ),
          )
        else
          SizedBox(
            height: 30,
            child: TextButton(
              onPressed: busy || value.isEmpty ? null : onVerify,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                minimumSize: const Size(0, 30),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                foregroundColor: OpenVtsColors.brandInk,
                textStyle: const TextStyle(
                  fontFamily: OpenVtsTypography.primaryFontFamily,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: busy
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Verify'),
            ),
          ),
      ],
    );
  }
}

// =====================================================================
// Action card
// =====================================================================

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OpenVtsCard(
      padding: const EdgeInsets.symmetric(
        horizontal: OpenVtsSpacing.md,
        vertical: OpenVtsSpacing.sm,
      ),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: OpenVtsColors.surface,
              border: Border.all(color: OpenVtsColors.border),
              borderRadius: BorderRadius.circular(OpenVtsRadius.sm),
            ),
            child: Icon(icon, size: 16, color: OpenVtsColors.textPrimary),
          ),
          const SizedBox(width: OpenVtsSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: OpenVtsTypography.primaryFontFamily,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: OpenVtsColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontFamily: OpenVtsTypography.primaryFontFamily,
                    fontSize: 11.5,
                    color: OpenVtsColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            size: 18,
            color: OpenVtsColors.textTertiary,
          ),
        ],
      ),
    );
  }
}

// =====================================================================
// Email subscription card
// =====================================================================

class _EmailSubscriptionCard extends StatelessWidget {
  const _EmailSubscriptionCard({
    required this.subscribed,
    required this.isLoading,
    required this.isSubscribing,
    required this.onSubscribe,
    required this.onRefresh,
  });

  final bool? subscribed;
  final bool isLoading;
  final bool isSubscribing;
  final Future<void> Function() onSubscribe;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final isSubscribed = subscribed == true;
    return OpenVtsCard(
      padding: const EdgeInsets.symmetric(
        horizontal: OpenVtsSpacing.md,
        vertical: OpenVtsSpacing.sm,
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: OpenVtsColors.surface,
              border: Border.all(color: OpenVtsColors.border),
              borderRadius: BorderRadius.circular(OpenVtsRadius.sm),
            ),
            child: const Icon(
              Icons.notifications_none_rounded,
              size: 16,
              color: OpenVtsColors.textPrimary,
            ),
          ),
          const SizedBox(width: OpenVtsSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Email Subscription',
                  style: TextStyle(
                    fontFamily: OpenVtsTypography.primaryFontFamily,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: OpenVtsColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  isLoading
                      ? 'Checking status…'
                      : subscribed == null
                          ? 'Status unknown'
                          : isSubscribed
                              ? 'Subscribed'
                              : 'Not subscribed',
                  style: const TextStyle(
                    fontFamily: OpenVtsTypography.primaryFontFamily,
                    fontSize: 11.5,
                    color: OpenVtsColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: OpenVtsSpacing.xs),
          if (isSubscribed)
            IconButton(
              tooltip: 'Refresh',
              onPressed: isLoading ? null : onRefresh,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              visualDensity: VisualDensity.compact,
            )
          else
            SizedBox(
              height: 32,
              child: OpenVtsButton(
                label: 'Subscribe',
                variant: OpenVtsButtonVariant.secondary,
                height: 32,
                isLoading: isSubscribing,
                onPressed: () => onSubscribe(),
              ),
            ),
        ],
      ),
    );
  }
}

// =====================================================================
// Logout card
// =====================================================================

class _LogoutCard extends StatelessWidget {
  const _LogoutCard({required this.onLogout});
  final Future<void> Function() onLogout;

  @override
  Widget build(BuildContext context) {
    return OpenVtsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: OpenVtsColors.surface,
                  border: Border.all(color: OpenVtsColors.border),
                  borderRadius: BorderRadius.circular(OpenVtsRadius.sm),
                ),
                child: const Icon(
                  Icons.logout_rounded,
                  size: 16,
                  color: OpenVtsColors.textPrimary,
                ),
              ),
              const SizedBox(width: OpenVtsSpacing.xs),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sign out',
                      style: TextStyle(
                        fontFamily: OpenVtsTypography.primaryFontFamily,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: OpenVtsColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 1),
                    Text(
                      'End this session on this device.',
                      style: TextStyle(
                        fontFamily: OpenVtsTypography.primaryFontFamily,
                        fontSize: 11,
                        color: OpenVtsColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: OpenVtsSpacing.sm),
          OpenVtsButton(
            label: 'Logout',
            variant: OpenVtsButtonVariant.secondary,
            height: 38,
            onPressed: () => onLogout(),
          ),
        ],
      ),
    );
  }
}

// =====================================================================
// Bottom sheet shell
// =====================================================================

class _BottomSheetShell extends StatelessWidget {
  const _BottomSheetShell({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: inset),
      child: SafeArea(
        top: false,
        child: Container(
          margin: const EdgeInsets.all(OpenVtsSpacing.sm),
          decoration: BoxDecoration(
            color: OpenVtsColors.surfaceElevated,
            borderRadius: BorderRadius.circular(OpenVtsRadius.lg),
            border: Border.all(color: OpenVtsColors.border),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _SheetHeader extends StatelessWidget {
  const _SheetHeader({required this.title, this.subtitle});
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        OpenVtsSpacing.md,
        OpenVtsSpacing.md,
        OpenVtsSpacing.sm,
        OpenVtsSpacing.xs,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: OpenVtsTypography.primaryFontFamily,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: OpenVtsColors.textPrimary,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: const TextStyle(
                      fontFamily: OpenVtsTypography.primaryFontFamily,
                      fontSize: 12,
                      color: OpenVtsColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.close_rounded, size: 18),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

// =====================================================================
// Edit Profile sheet (with cascading country/state/city)
// =====================================================================

class _EditProfileSheet extends ConsumerStatefulWidget {
  const _EditProfileSheet({required this.profile});
  final SuperadminProfileSettings profile;

  @override
  ConsumerState<_EditProfileSheet> createState() =>
      _EditProfileSheetState();
}

class _EditProfileSheetState extends ConsumerState<_EditProfileSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _email;
  late final TextEditingController _mobile;
  late final TextEditingController _addressLine;
  late final TextEditingController _pincode;

  String? _mobilePrefix;
  String? _countryCode;
  String? _stateCode;
  String? _cityName;

  List<SuperadminMobilePrefixOption> _prefixes = [];
  List<SuperadminCountryOption> _countries = [];
  List<SuperadminStateOption> _states = [];
  List<SuperadminCityOption> _cities = [];

  bool _loadingCatalogs = true;
  bool _loadingStates = false;
  bool _loadingCities = false;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final p = widget.profile;
    final a = p.address;
    _name = TextEditingController(text: p.name ?? '');
    _email = TextEditingController(text: p.email ?? '');
    _mobile = TextEditingController(text: p.mobileNumber ?? '');
    _addressLine = TextEditingController(text: a?.addressLine ?? '');
    _pincode = TextEditingController(text: a?.pincode ?? '');
    _mobilePrefix = p.mobilePrefix?.trim().isNotEmpty == true
        ? p.mobilePrefix
        : null;
    _countryCode = a?.countryCode?.trim().isNotEmpty == true
        ? a!.countryCode
        : null;
    _stateCode =
        a?.stateCode?.trim().isNotEmpty == true ? a!.stateCode : null;
    _cityName =
        a?.cityName?.trim().isNotEmpty == true ? a!.cityName : null;
    unawaited(_loadCatalogs());
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _mobile.dispose();
    _addressLine.dispose();
    _pincode.dispose();
    super.dispose();
  }

  Future<void> _loadCatalogs() async {
    final controller = ref.read(superadminAdministratorsControllerProvider.notifier);
    try {
      final results = await Future.wait([
        controller.getCountries(),
        controller.getMobilePrefixes(),
      ]);
      if (!mounted) return;
      setState(() {
        _countries = results[0] as List<SuperadminCountryOption>;
        _prefixes = results[1] as List<SuperadminMobilePrefixOption>;
        _loadingCatalogs = false;
      });
      if (_countryCode != null) {
        await _loadStates(_countryCode!);
        if (_stateCode != null) {
          await _loadCities(_countryCode!, _stateCode!);
        }
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingCatalogs = false);
    }
  }

  Future<void> _loadStates(String countryCode) async {
    setState(() {
      _loadingStates = true;
      _states = [];
    });
    try {
      final states = await ref
          .read(superadminAdministratorsControllerProvider.notifier)
          .getStates(countryCode);
      if (!mounted) return;
      setState(() {
        _states = states;
        _loadingStates = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingStates = false);
    }
  }

  Future<void> _loadCities(String countryCode, String stateCode) async {
    setState(() {
      _loadingCities = true;
      _cities = [];
    });
    try {
      final cities = await ref
          .read(superadminAdministratorsControllerProvider.notifier)
          .getCities(countryCode, stateCode);
      if (!mounted) return;
      setState(() {
        _cities = cities;
        _loadingCities = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingCities = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    final controller =
        ref.read(superadminSettingsControllerProvider.notifier);
    final ok = await controller.updateProfile(
      SuperadminUpdateProfileRequest(
        name: _name.text.trim(),
        email: _email.text.trim(),
        mobilePrefix: _mobilePrefix,
        mobileNumber: _mobile.text.trim().isEmpty ? null : _mobile.text.trim(),
        addressLine: _addressLine.text.trim().isEmpty
            ? null
            : _addressLine.text.trim(),
        countryCode: _countryCode,
        stateCode: _stateCode,
        cityName: _cityName,
        pincode: _pincode.text.trim().isEmpty ? null : _pincode.text.trim(),
      ),
    );
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop(true);
    } else {
      setState(() => _submitting = false);
      final msg = ref
              .read(superadminSettingsControllerProvider)
              .sectionErrorMessage ??
          'Unable to update profile.';
      ToastHelper.showError(msg);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingCatalogs) {
      return const SizedBox(
        height: 220,
        child: Center(child: OpenVtsLoader()),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const _SheetHeader(
          title: 'Edit Profile',
          subtitle: 'Personal details and address',
        ),
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              OpenVtsSpacing.md,
              0,
              OpenVtsSpacing.md,
              OpenVtsSpacing.md,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  OpenVtsTextField(
                    label: 'Name',
                    controller: _name,
                    validator: (v) => (v ?? '').trim().isEmpty
                        ? 'Name is required'
                        : null,
                  ),
                  const SizedBox(height: OpenVtsSpacing.sm),
                  OpenVtsTextField(
                    label: 'Email',
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) {
                      final t = (v ?? '').trim();
                      if (t.isEmpty) return 'Email is required';
                      if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(t)) {
                        return 'Enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: OpenVtsSpacing.sm),
                  Row(
                    children: [
                      Expanded(
                        flex: 4,
                        child: _DropdownField<String>(
                          label: 'Prefix',
                          value: _mobilePrefix,
                          items: _prefixes
                              .map(
                                (p) => DropdownMenuItem(
                                  value: p.dialCode,
                                  child: Text(
                                    '${p.dialCode} (${p.countryCode})',
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _mobilePrefix = v),
                        ),
                      ),
                      const SizedBox(width: OpenVtsSpacing.xs),
                      Expanded(
                        flex: 7,
                        child: OpenVtsTextField(
                          label: 'Mobile',
                          controller: _mobile,
                          keyboardType: TextInputType.phone,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: OpenVtsSpacing.sm),
                  OpenVtsTextField(
                    label: 'Address',
                    controller: _addressLine,
                  ),
                  const SizedBox(height: OpenVtsSpacing.sm),
                  _DropdownField<String>(
                    label: 'Country',
                    value: _countryCode,
                    items: _countries
                        .map(
                          (c) => DropdownMenuItem(
                            value: c.code,
                            child: Text(c.name),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      setState(() {
                        _countryCode = v;
                        _stateCode = null;
                        _cityName = null;
                        _states = [];
                        _cities = [];
                      });
                      if (v != null) unawaited(_loadStates(v));
                    },
                  ),
                  const SizedBox(height: OpenVtsSpacing.sm),
                  _DropdownField<String>(
                    label: 'State',
                    value: _stateCode,
                    enabled: !_loadingStates && _states.isNotEmpty,
                    busy: _loadingStates,
                    items: _states
                        .map(
                          (s) => DropdownMenuItem(
                            value: s.code,
                            child: Text(s.name),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      setState(() {
                        _stateCode = v;
                        _cityName = null;
                        _cities = [];
                      });
                      if (v != null && _countryCode != null) {
                        unawaited(_loadCities(_countryCode!, v));
                      }
                    },
                  ),
                  const SizedBox(height: OpenVtsSpacing.sm),
                  _DropdownField<String>(
                    label: 'City',
                    value: _cityName,
                    enabled: !_loadingCities && _cities.isNotEmpty,
                    busy: _loadingCities,
                    items: _cities
                        .map(
                          (c) => DropdownMenuItem(
                            value: c.name,
                            child: Text(c.name),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _cityName = v),
                  ),
                  const SizedBox(height: OpenVtsSpacing.sm),
                  OpenVtsTextField(
                    label: 'Pincode',
                    controller: _pincode,
                  ),
                  const SizedBox(height: OpenVtsSpacing.md),
                  OpenVtsButton(
                    label: 'Save Changes',
                    isLoading: _submitting,
                    onPressed: _submit,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DropdownField<T> extends StatelessWidget {
  const _DropdownField({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.enabled = true,
    this.busy = false,
  });

  final String label;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  final bool enabled;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: OpenVtsTypography.primaryFontFamily,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: OpenVtsColors.textSecondary,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 4),
        InputDecorator(
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            filled: true,
            fillColor: OpenVtsColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(OpenVtsRadius.sm),
              borderSide: const BorderSide(color: OpenVtsColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(OpenVtsRadius.sm),
              borderSide: const BorderSide(color: OpenVtsColors.border),
            ),
            suffixIcon: busy
                ? const Padding(
                    padding: EdgeInsets.all(10),
                    child: SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : null,
          ),
          child: DropdownButtonHideUnderline(
            child: Builder(
              builder: (context) {
                final hasValueInItems =
                    value != null && items.any((it) => it.value == value);
                final safeItems = hasValueInItems
                    ? items
                    : <DropdownMenuItem<T>>[
                        if (value != null)
                          DropdownMenuItem<T>(
                            value: value,
                            child: Text(
                              value.toString(),
                              style: const TextStyle(
                                fontFamily:
                                    OpenVtsTypography.primaryFontFamily,
                                fontSize: 12.5,
                                color: OpenVtsColors.textTertiary,
                              ),
                            ),
                          ),
                        ...items,
                      ];
                return DropdownButton<T>(
                  value: value,
                  isExpanded: true,
                  isDense: true,
                  onChanged: enabled ? onChanged : null,
                  items: safeItems,
                  hint: const Text(
                    'Select',
                    style: TextStyle(
                      fontFamily: OpenVtsTypography.primaryFontFamily,
                      fontSize: 12.5,
                      color: OpenVtsColors.textTertiary,
                    ),
                  ),
                  style: const TextStyle(
                    fontFamily: OpenVtsTypography.primaryFontFamily,
                    fontSize: 12.5,
                    color: OpenVtsColors.textPrimary,
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

// =====================================================================
// Change Password sheet
// =====================================================================

class _ChangePasswordSheet extends ConsumerStatefulWidget {
  const _ChangePasswordSheet();

  @override
  ConsumerState<_ChangePasswordSheet> createState() =>
      _ChangePasswordSheetState();
}

class _ChangePasswordSheetState
    extends ConsumerState<_ChangePasswordSheet> {
  final _formKey = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  bool _obscureCurrent = true;
  bool _obscureNext = true;
  bool _submitting = false;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    final ok = await ref
        .read(superadminSettingsControllerProvider.notifier)
        .changePassword(
          SuperadminChangePasswordRequest(
            currentPassword: _current.text,
            newPassword: _next.text,
          ),
        );
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop(true);
    } else {
      setState(() => _submitting = false);
      final msg = ref
              .read(superadminSettingsControllerProvider)
              .sectionErrorMessage ??
          'Unable to change password.';
      ToastHelper.showError(msg);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const _SheetHeader(
          title: 'Change Password',
          subtitle: 'Use a strong, unique password',
        ),
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              OpenVtsSpacing.md,
              0,
              OpenVtsSpacing.md,
              OpenVtsSpacing.md,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  OpenVtsTextField(
                    label: 'Current password',
                    controller: _current,
                    obscureText: _obscureCurrent,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureCurrent
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 18,
                      ),
                      onPressed: () => setState(
                        () => _obscureCurrent = !_obscureCurrent,
                      ),
                    ),
                    validator: (v) => (v ?? '').isEmpty
                        ? 'Current password required'
                        : null,
                  ),
                  const SizedBox(height: OpenVtsSpacing.sm),
                  OpenVtsTextField(
                    label: 'New password',
                    controller: _next,
                    obscureText: _obscureNext,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureNext
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 18,
                      ),
                      onPressed: () =>
                          setState(() => _obscureNext = !_obscureNext),
                    ),
                    validator: (v) {
                      final t = v ?? '';
                      if (t.length < 8) {
                        return 'Use at least 8 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: OpenVtsSpacing.sm),
                  OpenVtsTextField(
                    label: 'Confirm new password',
                    controller: _confirm,
                    obscureText: _obscureNext,
                    validator: (v) {
                      if ((v ?? '') != _next.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: OpenVtsSpacing.md),
                  OpenVtsButton(
                    label: 'Update Password',
                    isLoading: _submitting,
                    onPressed: _submit,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// =====================================================================
// Edit Company sheet
// =====================================================================

class _EditCompanySheet extends ConsumerStatefulWidget {
  const _EditCompanySheet({required this.company});
  final SuperadminCompanySettings company;

  @override
  ConsumerState<_EditCompanySheet> createState() =>
      _EditCompanySheetState();
}

class _EditCompanySheetState extends ConsumerState<_EditCompanySheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _website;
  late final TextEditingController _domain;
  late final TextEditingController _primaryColor;
  late final TextEditingController _facebook;
  late final TextEditingController _twitter;
  late final TextEditingController _linkedin;
  late final TextEditingController _instagram;
  late final TextEditingController _youtube;
  late final TextEditingController _github;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final c = widget.company;
    final s = c.socialLinks ?? const SuperadminSocialLinks();
    _name = TextEditingController(text: c.name ?? '');
    _website = TextEditingController(text: c.websiteUrl ?? '');
    _domain = TextEditingController(text: c.customDomain ?? '');
    _primaryColor = TextEditingController(text: c.primaryColor ?? '');
    _facebook = TextEditingController(text: s.facebook ?? '');
    _twitter = TextEditingController(text: s.twitter ?? '');
    _linkedin = TextEditingController(text: s.linkedin ?? '');
    _instagram = TextEditingController(text: s.instagram ?? '');
    _youtube = TextEditingController(text: s.youtube ?? '');
    _github = TextEditingController(text: s.github ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _website.dispose();
    _domain.dispose();
    _primaryColor.dispose();
    _facebook.dispose();
    _twitter.dispose();
    _linkedin.dispose();
    _instagram.dispose();
    _youtube.dispose();
    _github.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    final ok = await ref
        .read(superadminSettingsControllerProvider.notifier)
        .updateCompany(
          SuperadminUpdateCompanyRequest(
            name: _name.text.trim(),
            websiteUrl: _website.text.trim(),
            customDomain: _domain.text.trim(),
            primaryColor: _primaryColor.text.trim(),
            socialLinks: SuperadminSocialLinks(
              facebook: _facebook.text.trim(),
              twitter: _twitter.text.trim(),
              linkedin: _linkedin.text.trim(),
              instagram: _instagram.text.trim(),
              youtube: _youtube.text.trim(),
              github: _github.text.trim(),
            ),
          ),
        );
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop(true);
    } else {
      setState(() => _submitting = false);
      final msg = ref
              .read(superadminSettingsControllerProvider)
              .sectionErrorMessage ??
          'Unable to update company.';
      ToastHelper.showError(msg);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const _SheetHeader(
          title: 'Edit Company',
          subtitle: 'Brand and contact details',
        ),
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              OpenVtsSpacing.md,
              0,
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
                    validator: (v) => (v ?? '').trim().isEmpty
                        ? 'Name is required'
                        : null,
                  ),
                  const SizedBox(height: OpenVtsSpacing.sm),
                  OpenVtsTextField(
                    label: 'Website',
                    controller: _website,
                    keyboardType: TextInputType.url,
                    validator: (v) {
                      final t = (v ?? '').trim();
                      if (t.isEmpty) return null;
                      final candidate =
                          t.startsWith('http://') || t.startsWith('https://')
                              ? t
                              : 'https://$t';
                      final uri = Uri.tryParse(candidate);
                      if (uri == null || (uri.host).isEmpty) {
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
                  ),
                  const SizedBox(height: OpenVtsSpacing.sm),
                  OpenVtsTextField(
                    label: 'Primary color (hex)',
                    controller: _primaryColor,
                    validator: (v) {
                      final t = (v ?? '').trim();
                      if (t.isEmpty) return null;
                      if (!RegExp(r'^#?[0-9a-fA-F]{6}$').hasMatch(t)) {
                        return 'Enter a valid hex color';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: OpenVtsSpacing.md),
                  const _SubSectionLabel('Social Links'),
                  const SizedBox(height: OpenVtsSpacing.xs),
                  OpenVtsTextField(
                    label: 'Facebook',
                    controller: _facebook,
                    keyboardType: TextInputType.url,
                  ),
                  const SizedBox(height: OpenVtsSpacing.xs),
                  OpenVtsTextField(
                    label: 'Twitter / X',
                    controller: _twitter,
                    keyboardType: TextInputType.url,
                  ),
                  const SizedBox(height: OpenVtsSpacing.xs),
                  OpenVtsTextField(
                    label: 'LinkedIn',
                    controller: _linkedin,
                    keyboardType: TextInputType.url,
                  ),
                  const SizedBox(height: OpenVtsSpacing.xs),
                  OpenVtsTextField(
                    label: 'Instagram',
                    controller: _instagram,
                    keyboardType: TextInputType.url,
                  ),
                  const SizedBox(height: OpenVtsSpacing.xs),
                  OpenVtsTextField(
                    label: 'YouTube',
                    controller: _youtube,
                    keyboardType: TextInputType.url,
                  ),
                  const SizedBox(height: OpenVtsSpacing.xs),
                  OpenVtsTextField(
                    label: 'GitHub',
                    controller: _github,
                    keyboardType: TextInputType.url,
                  ),
                  const SizedBox(height: OpenVtsSpacing.md),
                  OpenVtsButton(
                    label: 'Save Changes',
                    isLoading: _submitting,
                    onPressed: _submit,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SubSectionLabel extends StatelessWidget {
  const _SubSectionLabel(this.label);
  final String label;
  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: const TextStyle(
        fontFamily: OpenVtsTypography.primaryFontFamily,
        fontSize: 10,
        letterSpacing: 0.8,
        fontWeight: FontWeight.w600,
        color: OpenVtsColors.textTertiary,
      ),
    );
  }
}

// =====================================================================
// OTP verification sheet
// =====================================================================

enum _OtpChannel { email, whatsapp }

class _OtpVerificationSheet extends ConsumerStatefulWidget {
  const _OtpVerificationSheet({required this.channel});
  final _OtpChannel channel;

  @override
  ConsumerState<_OtpVerificationSheet> createState() =>
      _OtpVerificationSheetState();
}

class _OtpVerificationSheetState
    extends ConsumerState<_OtpVerificationSheet> {
  final _otp = TextEditingController();
  bool _requested = false;
  bool _submitting = false;
  bool _resending = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _requestOtp());
  }

  @override
  void dispose() {
    _otp.dispose();
    super.dispose();
  }

  Future<void> _requestOtp({bool isResend = false}) async {
    setState(() {
      if (isResend) _resending = true;
    });
    final controller =
        ref.read(superadminSettingsControllerProvider.notifier);
    final ok = widget.channel == _OtpChannel.email
        ? await controller.requestEmailOtp()
        : await controller.requestWhatsAppOtp();
    if (!mounted) return;
    setState(() {
      _resending = false;
      _requested = _requested || ok;
    });
    if (ok) {
      ToastHelper.showInfo(
        widget.channel == _OtpChannel.email
            ? 'OTP sent to your email'
            : 'OTP sent via WhatsApp',
      );
    } else {
      final msg = ref
              .read(superadminSettingsControllerProvider)
              .sectionErrorMessage ??
          'Unable to send OTP.';
      ToastHelper.showError(msg);
    }
  }

  Future<void> _confirm() async {
    final code = _otp.text.trim();
    if (code.length != 6) {
      ToastHelper.showError('Enter the 6-digit code');
      return;
    }
    setState(() => _submitting = true);
    final controller =
        ref.read(superadminSettingsControllerProvider.notifier);
    final ok = widget.channel == _OtpChannel.email
        ? await controller.confirmEmailOtp(code)
        : await controller.confirmWhatsAppOtp(code);
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop(true);
    } else {
      setState(() => _submitting = false);
      final msg = ref
              .read(superadminSettingsControllerProvider)
              .sectionErrorMessage ??
          'Invalid or expired code.';
      ToastHelper.showError(msg);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEmail = widget.channel == _OtpChannel.email;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _SheetHeader(
          title: isEmail ? 'Verify Email' : 'Verify WhatsApp',
          subtitle: 'Enter the 6-digit code we sent you',
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            OpenVtsSpacing.md,
            0,
            OpenVtsSpacing.md,
            OpenVtsSpacing.md,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _otp,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                style: const TextStyle(
                  fontFamily: OpenVtsTypography.primaryFontFamily,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 8,
                  color: OpenVtsColors.textPrimary,
                ),
                decoration: InputDecoration(
                  counterText: '',
                  filled: true,
                  fillColor: OpenVtsColors.surface,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(OpenVtsRadius.sm),
                    borderSide:
                        const BorderSide(color: OpenVtsColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(OpenVtsRadius.sm),
                    borderSide:
                        const BorderSide(color: OpenVtsColors.border),
                  ),
                ),
              ),
              const SizedBox(height: OpenVtsSpacing.sm),
              Align(
                alignment: Alignment.center,
                child: TextButton(
                  onPressed:
                      _resending ? null : () => _requestOtp(isResend: true),
                  child: _resending
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(
                          'Resend code',
                          style: TextStyle(
                            fontFamily:
                                OpenVtsTypography.primaryFontFamily,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: OpenVtsSpacing.sm),
              OpenVtsButton(
                label: 'Verify',
                isLoading: _submitting,
                onPressed: _confirm,
              ),
            ],
          ),
        ),
      ],
    );
  }
}


