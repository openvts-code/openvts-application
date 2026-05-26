import 'package:flutter/material.dart';

import '../../../../../core/theme/open_vts_colors.dart';
import '../../../../../core/theme/open_vts_radius.dart';
import '../../../../../core/theme/open_vts_spacing.dart';
import '../../../../../core/theme/open_vts_typography.dart';
import '../../../../../shared/widgets/open_vts_card.dart';
import '../../../models/user_settings_model.dart';

class UserCompanySettingsCard extends StatelessWidget {
  const UserCompanySettingsCard({
    required this.company,
    required this.onEdit,
    super.key,
  });

  final UserSettingsCompany? company;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final current = company;
    return OpenVtsCard(
      padding: const EdgeInsets.all(OpenVtsSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Company Settings',
                  style: OpenVtsTypography.label.copyWith(
                    color: OpenVtsColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              OutlinedButton.icon(
                onPressed: current == null ? null : onEdit,
                icon: const Icon(Icons.edit_outlined, size: 14),
                label: const Text('Edit'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 44),
                ),
              ),
            ],
          ),
          const SizedBox(height: OpenVtsSpacing.xs),
          if (current == null)
            Text(
              'No company details are available for this account.',
              style: OpenVtsTypography.meta.copyWith(
                color: OpenVtsColors.textSecondary,
              ),
            )
          else ...[
            _KV(label: 'Name', value: _orDash(current.name)),
            _KV(label: 'Website', value: _orDash(current.websiteUrl)),
            _KV(label: 'Custom Domain', value: _orDash(current.customDomain)),
            _KV(label: 'Primary Color', value: _orDash(current.primaryColor)),
            _KV(label: 'Logo Light URL', value: _orDash(current.logoLightUrl)),
            _KV(label: 'Logo Dark URL', value: _orDash(current.logoDarkUrl)),
            _KV(label: 'Favicon URL', value: _orDash(current.faviconUrl)),
            const SizedBox(height: OpenVtsSpacing.xxs),
            Text(
              'Social Links',
              style: OpenVtsTypography.meta.copyWith(
                color: OpenVtsColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: OpenVtsSpacing.xxs),
            _KV(
                label: 'Facebook',
                value: _orDash(current.socialLinks?.facebook)),
            _KV(
                label: 'Twitter/X',
                value: _orDash(current.socialLinks?.twitter)),
            _KV(
                label: 'LinkedIn',
                value: _orDash(current.socialLinks?.linkedin)),
            _KV(
                label: 'Instagram',
                value: _orDash(current.socialLinks?.instagram)),
            _KV(label: 'YouTube', value: _orDash(current.socialLinks?.youtube)),
            _KV(label: 'GitHub', value: _orDash(current.socialLinks?.github)),
          ],
        ],
      ),
    );
  }

  String _orDash(String? value) {
    final normalized = value?.trim() ?? '';
    return normalized.isEmpty ? '-' : normalized;
  }
}

class _KV extends StatelessWidget {
  const _KV({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: OpenVtsSpacing.xxs),
      padding: const EdgeInsets.symmetric(
        horizontal: OpenVtsSpacing.xs,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: OpenVtsColors.surface,
        border: Border.all(color: OpenVtsColors.border),
        borderRadius: BorderRadius.circular(OpenVtsRadius.sm),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 104,
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
