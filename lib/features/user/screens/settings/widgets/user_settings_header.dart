import 'package:flutter/material.dart';

import '../../../../../core/theme/open_vts_colors.dart';
import '../../../../../core/theme/open_vts_radius.dart';
import '../../../../../core/theme/open_vts_spacing.dart';
import '../../../../../core/theme/open_vts_typography.dart';
import '../../../../../core/utils/date_time_formatter.dart';
import '../../../../../shared/widgets/open_vts_card.dart';
import '../../../../../shared/widgets/open_vts_status_chip.dart';
import '../../../models/user_settings_model.dart';

const DateTimeFormatter _settingsDateFormatter = DateTimeFormatter();

class UserSettingsHeader extends StatelessWidget {
  const UserSettingsHeader({
    required this.selectedTab,
    required this.isCurrentTabDirty,
    required this.isCurrentTabSaving,
    this.lastUpdatedAt,
    super.key,
  });

  final UserSettingsTab selectedTab;
  final bool isCurrentTabDirty;
  final bool isCurrentTabSaving;
  final DateTime? lastUpdatedAt;

  @override
  Widget build(BuildContext context) {
    final tabLabel =
        selectedTab == UserSettingsTab.profile ? 'Profile' : 'Localization';

    final statusChip = isCurrentTabSaving
        ? const OpenVtsStatusChip(
            label: 'Saving',
            type: OpenVtsStatusType.info,
          )
        : OpenVtsStatusChip(
            label: isCurrentTabDirty ? 'Unsaved' : 'Saved',
            type: isCurrentTabDirty
                ? OpenVtsStatusType.warning
                : OpenVtsStatusType.neutral,
          );

    return OpenVtsCard(
      padding: const EdgeInsets.all(OpenVtsSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: OpenVtsColors.surface,
                  borderRadius: BorderRadius.circular(OpenVtsRadius.sm),
                  border: Border.all(color: OpenVtsColors.border),
                ),
                child: const Icon(
                  Icons.settings_outlined,
                  size: 16,
                  color: OpenVtsColors.textSecondary,
                ),
              ),
              const SizedBox(width: OpenVtsSpacing.xs),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Settings',
                      style: TextStyle(
                        fontFamily: OpenVtsTypography.primaryFontFamily,
                        fontSize: 14,
                        height: 1.25,
                        fontWeight: FontWeight.w600,
                        color: OpenVtsColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Manage profile, security, and localization preferences.',
                      style: TextStyle(
                        fontFamily: OpenVtsTypography.primaryFontFamily,
                        fontSize: 11.5,
                        height: 1.35,
                        color: OpenVtsColors.textSecondary,
                      ),
                    ),
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
                label: '$tabLabel tab',
                type: OpenVtsStatusType.neutral,
              ),
              statusChip,
            ],
          ),
          if (lastUpdatedAt != null) ...[
            const SizedBox(height: OpenVtsSpacing.xs),
            Text(
              'Profile updated ${_settingsDateFormatter.formatDateTime(lastUpdatedAt!.toLocal())}',
              style: OpenVtsTypography.meta.copyWith(
                color: OpenVtsColors.textTertiary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
