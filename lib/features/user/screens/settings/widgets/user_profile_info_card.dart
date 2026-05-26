import 'package:flutter/material.dart';

import '../../../../../core/theme/open_vts_colors.dart';
import '../../../../../core/theme/open_vts_radius.dart';
import '../../../../../core/theme/open_vts_spacing.dart';
import '../../../../../core/theme/open_vts_typography.dart';
import '../../../../../shared/widgets/open_vts_card.dart';
import '../../../../../shared/widgets/open_vts_status_chip.dart';
import '../../../models/user_settings_model.dart';

class UserProfileInfoCard extends StatelessWidget {
  const UserProfileInfoCard({
    required this.profile,
    super.key,
  });

  final UserSettingsProfile profile;

  @override
  Widget build(BuildContext context) {
    final address = profile.address;

    return OpenVtsCard(
      padding: const EdgeInsets.all(OpenVtsSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Profile Details',
            style: OpenVtsTypography.label.copyWith(
              color: OpenVtsColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
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
            ],
          ),
          const SizedBox(height: OpenVtsSpacing.sm),
          _DetailRow(label: 'Name', value: _orDash(profile.name)),
          _DetailRow(label: 'Username', value: _orDash(profile.username)),
          _DetailRow(label: 'Email', value: _orDash(profile.email)),
          _DetailRow(
            label: 'Mobile',
            value: _orDash(_join(profile.mobilePrefix, profile.mobileNumber)),
          ),
          _DetailRow(
              label: 'Address Line', value: _orDash(address?.addressLine)),
          _DetailRow(label: 'Country', value: _orDash(address?.countryCode)),
          _DetailRow(label: 'State', value: _orDash(address?.stateCode)),
          _DetailRow(label: 'City', value: _orDash(address?.cityName)),
          _DetailRow(label: 'Pincode', value: _orDash(address?.pincode)),
          _DetailRow(
              label: 'Full Address', value: _orDash(address?.fullAddress)),
        ],
      ),
    );
  }

  String _normalize(String? value) => value?.trim() ?? '';

  String _orDash(String? value) {
    final normalized = _normalize(value);
    return normalized.isEmpty ? '-' : normalized;
  }

  String _join(String? first, String? second) {
    final parts = <String>[];
    final a = _normalize(first);
    final b = _normalize(second);
    if (a.isNotEmpty) {
      parts.add(a);
    }
    if (b.isNotEmpty) {
      parts.add(b);
    }
    return parts.join(' ');
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: OpenVtsSpacing.xxs),
      padding: const EdgeInsets.symmetric(
        horizontal: OpenVtsSpacing.xs,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: OpenVtsColors.surface,
        borderRadius: BorderRadius.circular(OpenVtsRadius.sm),
        border: Border.all(color: OpenVtsColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Text(
              label,
              style: OpenVtsTypography.meta.copyWith(
                color: OpenVtsColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: OpenVtsSpacing.xs),
          Expanded(
            child: Text(
              value,
              style: OpenVtsTypography.meta.copyWith(
                color: OpenVtsColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
