import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../../core/providers/core_providers.dart';
import '../../../../../core/theme/open_vts_colors.dart';
import '../../../../../core/theme/open_vts_spacing.dart';
import '../../../../../shared/helpers/toast_helper.dart';
import '../../../../../shared/widgets/open_vts_card.dart';
import '../../../../../shared/widgets/open_vts_empty_state.dart';
import '../../../../../shared/widgets/open_vts_role_home.dart';
import '../../../controllers/user_providers.dart';
import '../../../controllers/user_settings_controller.dart';
import '../../../models/user_settings_model.dart';
import '../../../models/user_settings_state.dart';
import 'user_company_edit_sheet.dart';
import 'user_company_settings_card.dart';
import 'user_email_subscription_card.dart';
import 'user_otp_verification_sheet.dart';
import 'user_password_change_sheet.dart';
import 'user_profile_edit_sheet.dart';
import 'user_profile_header_card.dart';
import 'user_profile_info_card.dart';
import 'user_verification_card.dart';

const _allowedImageExts = ['png', 'jpg', 'jpeg', 'webp'];
const int _maxImageBytes = 5 * 1024 * 1024;

enum _OtpChannel { email, whatsapp }

class UserProfileSettingsTab extends ConsumerStatefulWidget {
  const UserProfileSettingsTab({
    required this.state,
    required this.controller,
    super.key,
  });

  final UserSettingsState state;
  final UserSettingsController controller;

  @override
  ConsumerState<UserProfileSettingsTab> createState() =>
      _UserProfileSettingsTabState();
}

class _UserProfileSettingsTabState
    extends ConsumerState<UserProfileSettingsTab> {
  final _imagePicker = ImagePicker();
  Uint8List? _localAvatarBytes;
  String? _photoCacheBust;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      final needsProfileReferences =
          widget.state.countries.isEmpty || widget.state.mobilePrefixes.isEmpty;
      if (needsProfileReferences && !widget.state.isLoadingReferences) {
        unawaited(widget.controller.loadReferenceData());
      }

      final needsSubscription = widget.state.emailSubscription == null;
      if (needsSubscription && !widget.state.isLoadingEmailSubscription) {
        unawaited(widget.controller.loadEmailSubscription());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final draft = widget.state.draftProfile ?? widget.state.profile;
    if (draft == null) {
      return const OpenVtsCard(
        child: OpenVtsEmptyState(
          title: 'Profile settings unavailable',
          message: 'Pull to refresh and try loading your profile again.',
        ),
      );
    }

    final baseUrl = ref.watch(apiBaseUrlProvider);
    var imageUrl = resolveProfileImageUrl(baseUrl, draft.profileUrl);
    if (imageUrl != null && _photoCacheBust != null) {
      final sep = imageUrl.contains('?') ? '&' : '?';
      imageUrl = '$imageUrl${sep}ts=$_photoCacheBust';
    }

    final hasReferenceError =
        widget.state.errorMessage?.trim().isNotEmpty == true;
    final showReferenceWarning = !widget.state.isLoadingReferences &&
        hasReferenceError &&
        (widget.state.countries.isEmpty || widget.state.mobilePrefixes.isEmpty);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showReferenceWarning) ...[
          _ProfileReferenceWarningCard(
            message: widget.state.errorMessage,
            onRetry: () {
              unawaited(widget.controller.loadReferenceData(force: true));
            },
          ),
          const SizedBox(height: OpenVtsSpacing.sm),
        ],
        UserProfileHeaderCard(
          profile: draft,
          profileImageUrl: imageUrl,
          localAvatarBytes: _localAvatarBytes,
          isUploadingAvatar: widget.state.isUploadingProfilePhoto,
          onChangeAvatar: _pickPhoto,
          onEditProfile: () => _openProfileEditSheet(draft),
        ),
        const SizedBox(height: OpenVtsSpacing.sm),
        UserProfileInfoCard(profile: draft),
        const SizedBox(height: OpenVtsSpacing.sm),
        UserVerificationCard(
          isEmailVerified: draft.isEmailVerified,
          isMobileVerified: draft.isMobileVerified,
          isRequestingEmailOtp: widget.state.isRequestingEmailOtp,
          isConfirmingEmailOtp: widget.state.isConfirmingEmailOtp,
          isRequestingWhatsAppOtp: widget.state.isRequestingWhatsAppOtp,
          isConfirmingWhatsAppOtp: widget.state.isConfirmingWhatsAppOtp,
          onVerifyEmail: draft.isEmailVerified
              ? null
              : () => _startOtpFlow(_OtpChannel.email),
          onVerifyWhatsApp: draft.isMobileVerified
              ? null
              : () => _startOtpFlow(_OtpChannel.whatsapp),
        ),
        const SizedBox(height: OpenVtsSpacing.sm),
        UserCompanySettingsCard(
          company: draft.company,
          onEdit: draft.company == null
              ? null
              : () => _openCompanyEditSheet(draft.company!),
        ),
        const SizedBox(height: OpenVtsSpacing.sm),
        _PasswordActionCard(onPressed: _openPasswordSheet),
        const SizedBox(height: OpenVtsSpacing.sm),
        UserEmailSubscriptionCard(
          subscription: widget.state.emailSubscription,
          isLoading: widget.state.isLoadingEmailSubscription,
          isSubscribing: widget.state.isSubscribingEmail,
          errorMessage: widget.state.profileErrorMessage,
          onRefresh: () {
            unawaited(widget.controller.loadEmailSubscription());
          },
          onSubscribe: _subscribeEmail,
        ),
      ],
    );
  }

  Future<void> _pickPhoto() async {
    if (widget.state.isUploadingProfilePhoto) {
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

    if (picked == null) {
      return;
    }

    final ext = picked.name.split('.').last.toLowerCase();
    if (!_allowedImageExts.contains(ext)) {
      ToastHelper.showError('Unsupported format. Use PNG, JPG, JPEG or WEBP.');
      return;
    }

    final bytes = await picked.readAsBytes();
    if (bytes.isEmpty) {
      ToastHelper.showError('Selected file is empty.');
      return;
    }
    if (bytes.length > _maxImageBytes) {
      ToastHelper.showError('Image too large. Max 5 MB.');
      return;
    }

    if (mounted) {
      setState(() {
        _localAvatarBytes = bytes;
      });
    }

    final ok = await widget.controller.uploadProfilePhoto(
      bytes: bytes,
      fileName: picked.name,
    );

    if (!mounted) {
      return;
    }

    if (ok) {
      setState(() {
        _photoCacheBust = DateTime.now().millisecondsSinceEpoch.toString();
        _localAvatarBytes = null;
      });
      ToastHelper.showSuccess('Profile photo updated');
    } else {
      final message =
          ref.read(userSettingsControllerProvider).profileErrorMessage ??
              'Unable to upload profile photo.';
      ToastHelper.showError(message);
    }
  }

  Future<void> _openProfileEditSheet(UserSettingsProfile profile) async {
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => UserProfileEditSheet(
        profile: profile,
        controller: widget.controller,
      ),
    );

    if (ok == true) {
      ToastHelper.showSuccess('Profile updated');
    }
  }

  Future<void> _openCompanyEditSheet(UserSettingsCompany company) async {
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => UserCompanyEditSheet(
        company: company,
        onSave: (request) => widget.controller.updateCompany(request),
      ),
    );

    if (ok == true) {
      ToastHelper.showSuccess('Company updated');
    }
  }

  Future<void> _openPasswordSheet() async {
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => UserPasswordChangeSheet(
        onSave: (request) => widget.controller.changePassword(request),
      ),
    );

    if (ok == true) {
      ToastHelper.showSuccess('Password changed');
    }
  }

  Future<void> _startOtpFlow(_OtpChannel channel) async {
    final requested = channel == _OtpChannel.email
        ? await widget.controller.requestEmailOtp()
        : await widget.controller.requestWhatsAppOtp();

    if (!mounted) {
      return;
    }

    if (!requested) {
      final message =
          ref.read(userSettingsControllerProvider).profileErrorMessage ??
              'Unable to request OTP right now.';
      ToastHelper.showError(message);
      return;
    }

    final sheetTitle =
        channel == _OtpChannel.email ? 'Verify Email' : 'Verify WhatsApp';

    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => UserOtpVerificationSheet(
        title: sheetTitle,
        subtitle: 'Enter the OTP sent to your registered contact.',
        onConfirm: (otp) {
          if (channel == _OtpChannel.email) {
            return widget.controller.confirmEmailOtp(otp);
          }
          return widget.controller.confirmWhatsAppOtp(otp);
        },
        onResend: () {
          if (channel == _OtpChannel.email) {
            return widget.controller.requestEmailOtp();
          }
          return widget.controller.requestWhatsAppOtp();
        },
      ),
    );

    if (ok == true && mounted) {
      ToastHelper.showSuccess(
        channel == _OtpChannel.email ? 'Email verified' : 'WhatsApp verified',
      );
    }
  }

  Future<void> _subscribeEmail() async {
    final ok = await widget.controller.subscribeEmail();
    if (!mounted) {
      return;
    }

    if (ok) {
      ToastHelper.showSuccess('Subscribed to email updates');
      unawaited(widget.controller.loadEmailSubscription());
    } else {
      final message =
          ref.read(userSettingsControllerProvider).profileErrorMessage ??
              'Unable to subscribe right now.';
      ToastHelper.showError(message);
    }
  }
}

class _PasswordActionCard extends StatelessWidget {
  const _PasswordActionCard({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OpenVtsCard(
      padding: const EdgeInsets.all(OpenVtsSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Security',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: OpenVtsColors.textPrimary,
                ),
          ),
          const SizedBox(height: OpenVtsSpacing.xxs),
          Text(
            'Change your password to secure account access.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: OpenVtsColors.textSecondary,
                ),
          ),
          const SizedBox(height: OpenVtsSpacing.xs),
          OutlinedButton.icon(
            onPressed: onPressed,
            icon: const Icon(Icons.lock_outline_rounded, size: 14),
            label: const Text('Change Password'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 44),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileReferenceWarningCard extends StatelessWidget {
  const _ProfileReferenceWarningCard({
    required this.message,
    required this.onRetry,
  });

  final String? message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return OpenVtsCard(
      padding: const EdgeInsets.all(OpenVtsSpacing.sm),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            size: 18,
            color: OpenVtsColors.warning,
          ),
          const SizedBox(width: OpenVtsSpacing.xs),
          Expanded(
            child: Text(
              message?.trim().isNotEmpty == true
                  ? message!.trim()
                  : 'Country and mobile prefix references are unavailable. You can still edit manually.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: OpenVtsColors.textSecondary,
                  ),
            ),
          ),
          const SizedBox(width: OpenVtsSpacing.xs),
          OutlinedButton(
            onPressed: onRetry,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 44),
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
