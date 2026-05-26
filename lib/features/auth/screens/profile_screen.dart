import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/providers/core_providers.dart';
import '../../../core/theme/open_vts_colors.dart';
import '../../../core/theme/open_vts_radius.dart';
import '../../../core/theme/open_vts_spacing.dart';
import '../../../core/theme/open_vts_typography.dart';
import '../../../shared/helpers/toast_helper.dart';
import '../../../shared/widgets/open_vts_button.dart';
import '../../../shared/widgets/open_vts_card.dart';
import '../../../shared/widgets/open_vts_error_view.dart';
import '../../../shared/widgets/open_vts_loader.dart';
import '../../../shared/widgets/open_vts_role_home.dart';
import '../controllers/auth_controller.dart';
import '../controllers/profile_controller.dart';
import '../controllers/profile_state.dart';
import '../models/current_user.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();

    Future.microtask(
      () => ref.read(profileControllerProvider.notifier).load(refresh: true),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<ProfileState>(profileControllerProvider, (previous, next) {
      final previousError = previous?.errorMessage;
      final nextError = next.errorMessage;
      if (nextError != null && nextError != previousError) {
        ToastHelper.showError(nextError);
      }
    });

    final profileState = ref.watch(profileControllerProvider);
    final authUser =
        ref.watch(authControllerProvider.select((state) => state.user));
    final user = profileState.user ?? authUser;
    final baseUrl = ref.watch(apiBaseUrlProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? OpenVtsColors.darkBackground : OpenVtsColors.background,
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? const [
                    OpenVtsColors.darkBackground,
                    OpenVtsColors.brandInk,
                    OpenVtsColors.darkBackground,
                  ]
                : const [
                    Color(0xFFF4F1EC),
                    OpenVtsColors.background,
                    Color(0xFFF7F6F3),
                  ],
          ),
        ),
        child: SafeArea(
          child: user == null
              ? _ProfilePageStateBody(
                  isLoading: profileState.isInitialLoading,
                  message: profileState.errorMessage,
                  onRetry: () => ref
                      .read(profileControllerProvider.notifier)
                      .load(refresh: true),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    OpenVtsSpacing.md,
                    OpenVtsSpacing.md,
                    OpenVtsSpacing.md,
                    OpenVtsSpacing.lg,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _ProfileHeader(
                              onBack: () => _handleBack(context, user)),
                          const SizedBox(height: OpenVtsSpacing.sm),
                          OpenVtsCard(
                            padding: const EdgeInsets.fromLTRB(
                              OpenVtsSpacing.md,
                              OpenVtsSpacing.md,
                              OpenVtsSpacing.md,
                              OpenVtsSpacing.lg,
                            ),
                            child: Column(
                              children: [
                                _ProfileAvatar(
                                  displayName: user.name.trim().isNotEmpty
                                      ? user.name.trim()
                                      : 'OpenVTS User',
                                  localPhotoBytes: profileState.localPhotoBytes,
                                  profileImageUrl: resolveProfileImageUrl(
                                    baseUrl,
                                    user.profileUrl,
                                  ),
                                  isUploading: profileState.isUploadingPhoto,
                                  onEditPhoto: _pickProfilePhoto,
                                ),
                                const SizedBox(height: OpenVtsSpacing.md),
                                Text(
                                  user.name.trim().isNotEmpty
                                      ? user.name.trim()
                                      : 'OpenVTS User',
                                  textAlign: TextAlign.center,
                                  style: OpenVtsTypography.titleLarge.copyWith(
                                    color: theme.colorScheme.onSurface,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 30,
                                  ),
                                ),
                                const SizedBox(height: OpenVtsSpacing.sm),
                                _VerificationPill(
                                  label: _verificationLabel(user),
                                  icon: _verificationIcon(user),
                                  color: _verificationColor(user),
                                ),
                                const SizedBox(height: OpenVtsSpacing.sm),
                                Text(
                                  user.role.displayLabel,
                                  textAlign: TextAlign.center,
                                  style: OpenVtsTypography.bodyLarge.copyWith(
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.72),
                                  ),
                                ),
                                const SizedBox(height: OpenVtsSpacing.xs),
                                Text(
                                  _fallbackText(
                                    user.email,
                                    fallback: 'No email available',
                                  ),
                                  textAlign: TextAlign.center,
                                  style: OpenVtsTypography.body.copyWith(
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.58),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: OpenVtsSpacing.sm),
                          OpenVtsCard(
                            padding: const EdgeInsets.symmetric(
                              horizontal: OpenVtsSpacing.md,
                              vertical: OpenVtsSpacing.md,
                            ),
                            child: Column(
                              children: [
                                _ProfileInfoRow(
                                  icon: Icons.smartphone_rounded,
                                  title: 'Mobile',
                                  value: _fallbackText(
                                    user.resolvedPhoneNumber,
                                    fallback: 'Not available',
                                  ),
                                ),
                                Divider(
                                  height: OpenVtsSpacing.lg,
                                  color: isDark
                                      ? OpenVtsColors.darkBorder
                                      : OpenVtsColors.divider,
                                ),
                                _ProfileInfoRow(
                                  icon: Icons.shield_outlined,
                                  title: 'Account Status',
                                  value: _humanizeText(user.accountStatus) ??
                                      'Active',
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: OpenVtsSpacing.lg),
                          OpenVtsButton(
                            label: 'Logout',
                            height: 54,
                            trailingIcon: Icons.logout_rounded,
                            onPressed: profileState.isUploadingPhoto
                                ? null
                                : () async {
                                    final activeRole = ref
                                        .read(authControllerProvider)
                                        .activeRole;
                                    final loggedOutRole = await ref
                                        .read(authControllerProvider.notifier)
                                        .logout();
                                    final roleLabel =
                                        (loggedOutRole ?? activeRole)
                                            ?.displayLabel;
                                    if (roleLabel != null) {
                                      ToastHelper.showInfo(
                                        'Logged out from $roleLabel',
                                      );
                                    }
                                  },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  void _handleBack(BuildContext context, CurrentUser user) {
    if (context.canPop()) {
      context.pop();
      return;
    }

    context.go(user.role.homePath);
  }

  Future<void> _pickProfilePhoto() async {
    final profileState = ref.read(profileControllerProvider);
    final previousProfileUrl =
        (profileState.user ?? ref.read(authControllerProvider).user)
            ?.profileUrl;
    if (profileState.isUploadingPhoto) {
      return;
    }

    final image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      imageQuality: 90,
    );
    if (image == null) {
      return;
    }

    final bytes = await image.readAsBytes();
    if (bytes.isEmpty) {
      ToastHelper.showError('Unable to read the selected image.');
      return;
    }

    try {
      final updatedUser =
          await ref.read(profileControllerProvider.notifier).uploadPhoto(
                bytes: bytes,
                fileName: image.name.isNotEmpty ? image.name : 'profile.jpg',
              );
      if (!mounted) {
        return;
      }

      if (_didProfilePhotoRefresh(previousProfileUrl, updatedUser.profileUrl)) {
        ToastHelper.showInfo('Profile photo updated');
        return;
      }

      ToastHelper.showError(
        'The upload finished, but the new profile photo was not returned by the server.',
      );
    } catch (_) {
      // Error toast is handled by the controller listener.
    }
  }

  static bool _didProfilePhotoRefresh(String? previous, String? next) {
    final normalizedPrevious = previous?.trim();
    final normalizedNext = next?.trim();

    if (normalizedNext == null || normalizedNext.isEmpty) {
      return false;
    }

    if (normalizedPrevious == null || normalizedPrevious.isEmpty) {
      return true;
    }

    return normalizedPrevious != normalizedNext;
  }

  static String _fallbackText(String? value, {required String fallback}) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) {
      return fallback;
    }

    return normalized;
  }

  static String? _humanizeText(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }

    return normalized
        .split(RegExp(r'[_\s-]+'))
        .where((segment) => segment.isNotEmpty)
        .map((segment) {
      final lower = segment.toLowerCase();
      return '${lower[0].toUpperCase()}${lower.substring(1)}';
    }).join(' ');
  }

  static String _verificationLabel(CurrentUser user) {
    if (user.isVerified == false) {
      return 'Pending';
    }
    if (user.isVerified == true) {
      return 'Verified';
    }
    return 'Signed in';
  }

  static IconData _verificationIcon(CurrentUser user) {
    return user.isVerified == false
        ? Icons.shield_outlined
        : Icons.verified_user_outlined;
  }

  static Color _verificationColor(CurrentUser user) {
    return user.isVerified == false
        ? OpenVtsColors.warning
        : OpenVtsColors.brandInk;
  }
}

class _ProfilePageStateBody extends StatelessWidget {
  const _ProfilePageStateBody({
    required this.isLoading,
    required this.message,
    required this.onRetry,
  });

  final bool isLoading;
  final String? message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: OpenVtsLoader());
    }

    return Center(
      child: OpenVtsErrorView(
        message: message ?? 'Unable to load the profile right now.',
        onRetry: onRetry,
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Row(
      children: [
        IconButton(
          onPressed: onBack,
          style: IconButton.styleFrom(
            backgroundColor:
                isDark ? OpenVtsColors.darkSurface : OpenVtsColors.white,
            foregroundColor: theme.colorScheme.onSurface,
            minimumSize: const Size.square(42),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(OpenVtsRadius.lg),
              side: BorderSide(
                color: isDark ? OpenVtsColors.darkBorder : OpenVtsColors.border,
              ),
            ),
          ),
          icon: const Icon(Icons.arrow_back_rounded, size: 20),
        ),
        const SizedBox(width: OpenVtsSpacing.sm),
        Text(
          'Profile',
          style: OpenVtsTypography.titleSmall.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({
    required this.displayName,
    required this.localPhotoBytes,
    required this.profileImageUrl,
    required this.isUploading,
    required this.onEditPhoto,
  });

  final String displayName;
  final List<int>? localPhotoBytes;
  final String? profileImageUrl;
  final bool isUploading;
  final VoidCallback onEditPhoto;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SizedBox(
      width: 132,
      height: 132,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 124,
            height: 124,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isDark
                    ? OpenVtsColors.darkBorder
                    : OpenVtsColors.border.withValues(alpha: 0.9),
              ),
              color: isDark ? OpenVtsColors.darkSurface : OpenVtsColors.white,
            ),
            child: ClipOval(
              child: localPhotoBytes != null
                  ? Image.memory(
                      Uint8List.fromList(localPhotoBytes!),
                      key: ValueKey(localPhotoBytes.hashCode),
                      fit: BoxFit.cover,
                    )
                  : profileImageUrl == null
                      ? Center(
                          child: Text(
                            _initials(displayName),
                            style: OpenVtsTypography.titleMedium.copyWith(
                              color: theme.colorScheme.onSurface,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        )
                      : Image.network(
                          key: ValueKey(profileImageUrl),
                          profileImageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) {
                            return Icon(
                              Icons.person_outline_rounded,
                              size: 40,
                              color: theme.colorScheme.onSurface,
                            );
                          },
                        ),
            ),
          ),
          PositionedDirectional(
            end: 0,
            bottom: 6,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: isUploading ? null : onEditPhoto,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: OpenVtsColors.brandInk,
                    border: Border.all(color: OpenVtsColors.white, width: 2),
                  ),
                  child: isUploading
                      ? const Padding(
                          padding: EdgeInsets.all(10),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              OpenVtsColors.white,
                            ),
                          ),
                        )
                      : const Icon(
                          Icons.photo_camera_outlined,
                          size: 16,
                          color: OpenVtsColors.white,
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _initials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((segment) => segment.isNotEmpty)
        .take(2)
        .toList();

    if (parts.isEmpty) {
      return 'OV';
    }

    return parts.map((part) => part[0].toUpperCase()).join();
  }
}

class _VerificationPill extends StatelessWidget {
  const _VerificationPill({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(OpenVtsRadius.md),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: OpenVtsSpacing.sm,
          vertical: OpenVtsSpacing.xs,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: OpenVtsSpacing.xxs),
            Text(
              label,
              style: OpenVtsTypography.label.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileInfoRow extends StatelessWidget {
  const _ProfileInfoRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDark ? OpenVtsColors.brandInkSoft : OpenVtsColors.surface,
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: 20, color: theme.colorScheme.onSurface),
        ),
        const SizedBox(width: OpenVtsSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: OpenVtsTypography.label.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: OpenVtsTypography.body.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.68),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
