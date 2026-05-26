import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../../../core/theme/open_vts_colors.dart';
import '../../../../../core/theme/open_vts_radius.dart';
import '../../../../../core/theme/open_vts_spacing.dart';
import '../../../../../core/theme/open_vts_typography.dart';
import '../../../../../core/utils/date_time_formatter.dart';
import '../../../../../shared/widgets/open_vts_card.dart';
import '../../../../../shared/widgets/open_vts_status_chip.dart';
import '../../../models/user_settings_model.dart';

const DateTimeFormatter _profileHeaderDateFormatter = DateTimeFormatter();

class UserProfileHeaderCard extends StatelessWidget {
  const UserProfileHeaderCard({
    required this.profile,
    required this.profileImageUrl,
    required this.localAvatarBytes,
    required this.isUploadingAvatar,
    required this.onChangeAvatar,
    required this.onEditProfile,
    super.key,
  });

  final UserSettingsProfile profile;
  final String? profileImageUrl;
  final Uint8List? localAvatarBytes;
  final bool isUploadingAvatar;
  final VoidCallback? onChangeAvatar;
  final VoidCallback? onEditProfile;

  @override
  Widget build(BuildContext context) {
    final name = _orDash(profile.name);
    final username = _normalize(profile.username);
    final email = _normalize(profile.email);
    final mobile = _buildMobile(profile.mobilePrefix, profile.mobileNumber);

    return OpenVtsCard(
      padding: const EdgeInsets.all(OpenVtsSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _AvatarView(
                name: name,
                profileImageUrl: profileImageUrl,
                localAvatarBytes: localAvatarBytes,
                isUploading: isUploadingAvatar,
              ),
              const SizedBox(width: OpenVtsSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: OpenVtsTypography.label.copyWith(
                        color: OpenVtsColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (username.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        '@$username',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: OpenVtsTypography.meta.copyWith(
                          color: OpenVtsColors.textSecondary,
                        ),
                      ),
                    ],
                    if (email.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: OpenVtsTypography.meta.copyWith(
                          color: OpenVtsColors.textSecondary,
                        ),
                      ),
                    ],
                    if (mobile.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        mobile,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: OpenVtsTypography.meta.copyWith(
                          color: OpenVtsColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: OpenVtsSpacing.xs),
          Wrap(
            spacing: OpenVtsSpacing.xs,
            runSpacing: OpenVtsSpacing.xs,
            children: [
              OpenVtsStatusChip(
                label: profile.isEmailVerified
                    ? 'Email verified'
                    : 'Email pending',
                type: profile.isEmailVerified
                    ? OpenVtsStatusType.success
                    : OpenVtsStatusType.warning,
              ),
              OpenVtsStatusChip(
                label: profile.isMobileVerified
                    ? 'WhatsApp verified'
                    : 'WhatsApp pending',
                type: profile.isMobileVerified
                    ? OpenVtsStatusType.success
                    : OpenVtsStatusType.warning,
              ),
              if (profile.credits != null)
                OpenVtsStatusChip(
                  label: '${profile.credits!.toStringAsFixed(0)} credits',
                  type: OpenVtsStatusType.info,
                ),
            ],
          ),
          const SizedBox(height: OpenVtsSpacing.xs),
          Wrap(
            spacing: OpenVtsSpacing.sm,
            runSpacing: OpenVtsSpacing.xxs,
            children: [
              if (profile.createdAt != null)
                Text(
                  'Joined ${_profileHeaderDateFormatter.formatDate(profile.createdAt!.toLocal())}',
                  style: OpenVtsTypography.meta.copyWith(
                    color: OpenVtsColors.textTertiary,
                  ),
                ),
              if (profile.updatedAt != null)
                Text(
                  'Updated ${_profileHeaderDateFormatter.formatDateTime(profile.updatedAt!.toLocal())}',
                  style: OpenVtsTypography.meta.copyWith(
                    color: OpenVtsColors.textTertiary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: OpenVtsSpacing.xs),
          Row(
            children: [
              _CompactSecondaryButton(
                icon: Icons.photo_camera_outlined,
                label: isUploadingAvatar ? 'Uploading...' : 'Change Avatar',
                onPressed: isUploadingAvatar ? null : onChangeAvatar,
              ),
              const SizedBox(width: OpenVtsSpacing.xs),
              _CompactSecondaryButton(
                icon: Icons.edit_outlined,
                label: 'Edit Profile',
                onPressed: onEditProfile,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _normalize(String? value) => value?.trim() ?? '';

  String _orDash(String? value) {
    final normalized = _normalize(value);
    return normalized.isEmpty ? 'User' : normalized;
  }

  String _buildMobile(String? prefix, String? number) {
    final parts = <String>[];
    final normalizedPrefix = _normalize(prefix);
    final normalizedNumber = _normalize(number);
    if (normalizedPrefix.isNotEmpty) {
      parts.add(normalizedPrefix);
    }
    if (normalizedNumber.isNotEmpty) {
      parts.add(normalizedNumber);
    }
    return parts.join(' ');
  }
}

class _AvatarView extends StatelessWidget {
  const _AvatarView({
    required this.name,
    required this.profileImageUrl,
    required this.localAvatarBytes,
    required this.isUploading,
  });

  final String name;
  final String? profileImageUrl;
  final Uint8List? localAvatarBytes;
  final bool isUploading;

  @override
  Widget build(BuildContext context) {
    final hasRemote = (profileImageUrl ?? '').trim().isNotEmpty;

    Widget content;
    if (localAvatarBytes != null && localAvatarBytes!.isNotEmpty) {
      content = Image.memory(localAvatarBytes!, fit: BoxFit.cover);
    } else if (hasRemote) {
      content = Image.network(
        profileImageUrl!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _AvatarInitial(name: name),
      );
    } else {
      content = _AvatarInitial(name: name);
    }

    return SizedBox(
      width: 56,
      height: 56,
      child: Stack(
        alignment: Alignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(OpenVtsRadius.md),
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(color: OpenVtsColors.border),
              ),
              child: SizedBox(width: 56, height: 56, child: content),
            ),
          ),
          if (isUploading)
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: OpenVtsColors.brandInk.withValues(alpha: 0.48),
                borderRadius: BorderRadius.circular(OpenVtsRadius.md),
              ),
              child: const Center(
                child: SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: OpenVtsColors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AvatarInitial extends StatelessWidget {
  const _AvatarInitial({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : 'U';

    return Container(
      color: OpenVtsColors.brandInk,
      alignment: Alignment.center,
      child: Text(
        initial,
        style: OpenVtsTypography.label.copyWith(
          color: OpenVtsColors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _CompactSecondaryButton extends StatelessWidget {
  const _CompactSecondaryButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 14),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 44),
        textStyle: OpenVtsTypography.meta.copyWith(fontWeight: FontWeight.w600),
        padding: const EdgeInsets.symmetric(
          horizontal: OpenVtsSpacing.xs,
          vertical: 8,
        ),
      ),
    );
  }
}
