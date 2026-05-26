import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/open_vts_colors.dart';
import '../../../../core/theme/open_vts_radius.dart';
import '../../../../core/theme/open_vts_spacing.dart';
import '../../../../core/theme/open_vts_typography.dart';
import '../../../../shared/widgets/open_vts_card.dart';
import '../../../../shared/widgets/open_vts_page_scaffold.dart';
import '../../controllers/superadmin_providers.dart';
import '../../models/superadmin_settings_model.dart';
import '../../models/superadmin_settings_state.dart';
import 'widgets/general_settings_section.dart';
import 'widgets/localization_settings_section.dart';
import 'widgets/profile_settings_section.dart';
import 'widgets/smtp_settings_section.dart';
import 'widgets/white_label_settings_section.dart';

class SuperadminSettingsScreen extends ConsumerStatefulWidget {
  const SuperadminSettingsScreen({super.key});

  @override
  ConsumerState<SuperadminSettingsScreen> createState() =>
      _SuperadminSettingsScreenState();
}

class _SuperadminSettingsScreenState
    extends ConsumerState<SuperadminSettingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(
        ref
            .read(superadminSettingsControllerProvider.notifier)
            .loadInitial(),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(superadminSettingsControllerProvider);

    return OpenVtsPageScaffold(
      title: 'Settings',
      headerMode: OpenVtsPageHeaderMode.closeable,
      padding: const EdgeInsets.fromLTRB(
        OpenVtsSpacing.sm,
        OpenVtsSpacing.sm,
        OpenVtsSpacing.sm,
        OpenVtsSpacing.md,
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          const _SettingsHeader(),
          const SizedBox(height: OpenVtsSpacing.sm),
          _SectionSelector(selected: state.selectedSection),
          const SizedBox(height: OpenVtsSpacing.sm),
          _SectionContent(state: state),
        ],
      ),
    );
  }
}

// =====================================================================
// Top header card
// =====================================================================

class _SettingsHeader extends StatelessWidget {
  const _SettingsHeader();

  @override
  Widget build(BuildContext context) {
    return OpenVtsCard(
      padding: const EdgeInsets.symmetric(
        horizontal: OpenVtsSpacing.md,
        vertical: OpenVtsSpacing.sm,
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: OpenVtsColors.brandInk,
              borderRadius: BorderRadius.circular(OpenVtsRadius.md),
            ),
            child: const Icon(
              Icons.tune_rounded,
              size: 18,
              color: OpenVtsColors.white,
            ),
          ),
          const SizedBox(width: OpenVtsSpacing.sm),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Settings',
                  style: TextStyle(
                    fontFamily: OpenVtsTypography.primaryFontFamily,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: OpenVtsColors.textPrimary,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Profile, branding, mail, localization, and platform preferences.',
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
    );
  }
}

// =====================================================================
// Horizontal section selector
// =====================================================================

class _SectionItem {
  const _SectionItem(this.section, this.label, this.icon);
  final SuperadminSettingsSection section;
  final String label;
  final IconData icon;
}

const List<_SectionItem> _kSections = <_SectionItem>[
  _SectionItem(
    SuperadminSettingsSection.profile,
    'Profile',
    Icons.person_outline_rounded,
  ),
  _SectionItem(
    SuperadminSettingsSection.whiteLabel,
    'White Label',
    Icons.palette_outlined,
  ),
  _SectionItem(
    SuperadminSettingsSection.smtp,
    'SMTP',
    Icons.mail_outline_rounded,
  ),
  _SectionItem(
    SuperadminSettingsSection.localization,
    'Localization',
    Icons.public_rounded,
  ),
  _SectionItem(
    SuperadminSettingsSection.general,
    'Settings',
    Icons.settings_suggest_outlined,
  ),
];

class _SectionSelector extends ConsumerWidget {
  const _SectionSelector({required this.selected});

  final SuperadminSettingsSection selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 2),
        physics: const BouncingScrollPhysics(),
        itemCount: _kSections.length,
        separatorBuilder: (_, __) => const SizedBox(width: OpenVtsSpacing.xs),
        itemBuilder: (context, index) {
          final item = _kSections[index];
          final isSelected = item.section == selected;
          return _SectionChip(
            item: item,
            isSelected: isSelected,
            onTap: () {
              ref
                  .read(superadminSettingsControllerProvider.notifier)
                  .selectSection(item.section);
            },
          );
        },
      ),
    );
  }
}

class _SectionChip extends StatelessWidget {
  const _SectionChip({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  final _SectionItem item;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bg = isSelected ? OpenVtsColors.brandInk : OpenVtsColors.surfaceElevated;
    final fg = isSelected ? OpenVtsColors.white : OpenVtsColors.textPrimary;
    final borderColor =
        isSelected ? OpenVtsColors.brandInk : OpenVtsColors.border;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(OpenVtsRadius.pill),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: OpenVtsSpacing.sm,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(OpenVtsRadius.pill),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(item.icon, size: 14, color: fg),
              const SizedBox(width: 6),
              Text(
                item.label,
                style: TextStyle(
                  fontFamily: OpenVtsTypography.primaryFontFamily,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =====================================================================
// Section dispatch
// =====================================================================

class _SectionContent extends ConsumerWidget {
  const _SectionContent({required this.state});

  final SuperadminSettingsState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    switch (state.selectedSection) {
      case SuperadminSettingsSection.profile:
        return ProfileSettingsSection(state: state);
      case SuperadminSettingsSection.whiteLabel:
        return WhiteLabelSettingsSection(state: state);
      case SuperadminSettingsSection.smtp:
        return SmtpSettingsSection(state: state);
      case SuperadminSettingsSection.localization:
        return LocalizationSettingsSection(state: state);
      case SuperadminSettingsSection.general:
        return GeneralSettingsSection(state: state);
    }
  }
}
