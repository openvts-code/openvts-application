import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/open_vts_colors.dart';
import '../../../../../core/theme/open_vts_radius.dart';
import '../../../../../core/theme/open_vts_spacing.dart';
import '../../../../../core/theme/open_vts_typography.dart';
import '../../../../../shared/helpers/toast_helper.dart';
import '../../../../../shared/widgets/open_vts_button.dart';
import '../../../../../shared/widgets/open_vts_card.dart';
import '../../../../../shared/widgets/open_vts_loader.dart';
import '../../../../../shared/widgets/open_vts_text_field.dart';
import '../../../controllers/superadmin_providers.dart';
import '../../../controllers/superadmin_settings_controller.dart';
import '../../../models/superadmin_settings_model.dart';
import '../../../models/superadmin_settings_state.dart';

// =====================================================================
// General settings (software config + data retention)
// =====================================================================

class GeneralSettingsSection extends ConsumerStatefulWidget {
  const GeneralSettingsSection({super.key, required this.state});

  final SuperadminSettingsState state;

  @override
  ConsumerState<GeneralSettingsSection> createState() =>
      _GeneralSettingsSectionState();
}

class _GeneralSettingsSectionState
    extends ConsumerState<GeneralSettingsSection> {
  final _formKey = GlobalKey<FormState>();
  final _signupCreditsCtrl = TextEditingController();

  bool _allowDemoLogin = true;
  bool _allowSignup = true;
  SuperadminGeocodingPrecision _precision =
      SuperadminGeocodingPrecision.twoDigit;
  int _backupDays = 365;
  bool _hydrated = false;

  @override
  void initState() {
    super.initState();
    _hydrate(widget.state.softwareConfig);
  }

  @override
  void didUpdateWidget(covariant GeneralSettingsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_hydrated && widget.state.softwareConfig != null) {
      _hydrate(widget.state.softwareConfig);
    }
  }

  void _hydrate(SuperadminSoftwareConfig? cfg) {
    if (cfg == null) return;
    _allowDemoLogin = cfg.allowDemoLogin;
    _allowSignup = cfg.allowSignup;
    _precision = cfg.geocodingPrecision;
    _backupDays = cfg.backupDays > 0 ? cfg.backupDays : 365;
    _signupCreditsCtrl.text = cfg.signupCredits.toString();
    _hydrated = true;
  }

  @override
  void dispose() {
    _signupCreditsCtrl.dispose();
    super.dispose();
  }

  SuperadminSettingsController get _controller =>
      ref.read(superadminSettingsControllerProvider.notifier);

  // -----------------------------------------------------------------
  // Save
  // -----------------------------------------------------------------

  Future<void> _save() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    final credits = int.tryParse(_signupCreditsCtrl.text.trim()) ?? 0;
    final request = SuperadminSoftwareConfig(
      geocodingPrecision: _precision,
      backupDays: _backupDays,
      allowDemoLogin: _allowDemoLogin,
      allowSignup: _allowSignup,
      signupCredits: credits,
    );

    final ok = await _controller.updateSoftwareConfig(request);
    if (!mounted) return;
    if (ok) {
      ToastHelper.showSuccess('Settings saved');
      await _controller.loadSoftwareConfig();
      if (mounted) {
        setState(() => _hydrated = false);
        _hydrate(
          ref.read(superadminSettingsControllerProvider).softwareConfig,
        );
      }
    } else {
      ToastHelper.showError(
        ref.read(superadminSettingsControllerProvider).sectionErrorMessage ?? 'Failed to save settings',
      );
    }
  }

  // -----------------------------------------------------------------
  // Data retention
  // -----------------------------------------------------------------

  Future<void> _previewRetention() async {
    final ok = await _controller.previewDataRetention();
    if (!mounted) return;
    if (ok) {
      ToastHelper.showInfo('Preview updated');
    } else {
      ToastHelper.showError(
        ref.read(superadminSettingsControllerProvider).sectionErrorMessage ?? 'Failed to load preview',
      );
    }
  }

  Future<void> _dryRunRetention() async {
    final ok = await _controller.runDataRetention(dryRun: true);
    if (!mounted) return;
    if (ok) {
      ToastHelper.showInfo('Dry-run completed');
    } else {
      ToastHelper.showError(
        ref.read(superadminSettingsControllerProvider).sectionErrorMessage ?? 'Dry-run failed',
      );
    }
  }

  Future<void> _openCleanupSheet() async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: OpenVtsColors.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(OpenVtsRadius.lg),
        ),
      ),
      builder: (_) => const _CleanupConfirmSheet(),
    );
    if (confirmed != true) return;

    final ok = await _controller.runDataRetention(dryRun: false);
    if (!mounted) return;
    if (ok) {
      ToastHelper.showSuccess('Cleanup completed');
      await _controller.previewDataRetention();
    } else {
      ToastHelper.showError(
        ref.read(superadminSettingsControllerProvider).sectionErrorMessage ?? 'Cleanup failed',
      );
    }
  }

  // -----------------------------------------------------------------
  // Build
  // -----------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final state = widget.state;

    if (state.isLoadingSoftwareConfig && state.softwareConfig == null) {
      return const OpenVtsCard(
        padding: EdgeInsets.symmetric(vertical: OpenVtsSpacing.lg),
        child: Center(child: OpenVtsLoader()),
      );
    }

    if (state.softwareConfig == null) {
      return OpenVtsCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              state.sectionErrorMessage ?? 'Could not load settings.',
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
              height: 40,
              onPressed: _controller.loadSoftwareConfig,
            ),
          ],
        ),
      );
    }

    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SectionHeader(
            title: 'Settings',
            subtitle: 'Platform behavior, signup, geocoding, and retention.',
            icon: Icons.settings_suggest_outlined,
            trailing: IconButton(
              tooltip: 'Refresh',
              onPressed: state.isLoadingSoftwareConfig
                  ? null
                  : _controller.loadSoftwareConfig,
              iconSize: 18,
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ),
          const SizedBox(height: OpenVtsSpacing.sm),
          _CurrentConfigCard(
            allowDemoLogin: _allowDemoLogin,
            allowSignup: _allowSignup,
            precision: _precision,
            backupDays: _backupDays,
            signupCredits: int.tryParse(_signupCreditsCtrl.text.trim()) ?? 0,
          ),
          const SizedBox(height: OpenVtsSpacing.sm),
          _GroupedCard(
            icon: Icons.science_outlined,
            title: 'Demo Login',
            subtitle: 'Allow visitors to log in to a demo workspace.',
            children: [
              _LabeledSwitchRow(
                label: 'Enable demo login',
                value: _allowDemoLogin,
                onChanged: (v) => setState(() => _allowDemoLogin = v),
              ),
            ],
          ),
          const SizedBox(height: OpenVtsSpacing.sm),
          _GroupedCard(
            icon: Icons.place_outlined,
            title: 'Reverse Geocoding Precision',
            subtitle: 'Higher precision uses more lookups.',
            children: [
              _SegmentedControl<SuperadminGeocodingPrecision>(
                value: _precision,
                segments: const [
                  _Seg(
                    value: SuperadminGeocodingPrecision.twoDigit,
                    label: '2 digits',
                  ),
                  _Seg(
                    value: SuperadminGeocodingPrecision.threeDigit,
                    label: '3 digits',
                  ),
                ],
                onChanged: (v) => setState(() => _precision = v),
              ),
            ],
          ),
          const SizedBox(height: OpenVtsSpacing.sm),
          _GroupedCard(
            icon: Icons.person_add_alt_1_outlined,
            title: 'Signup',
            subtitle: 'Public signup and welcome credits.',
            children: [
              _LabeledSwitchRow(
                label: 'Enable public signup',
                value: _allowSignup,
                onChanged: (v) => setState(() => _allowSignup = v),
              ),
              const SizedBox(height: OpenVtsSpacing.sm),
              OpenVtsTextField(
                label: 'Free signup credits',
                controller: _signupCreditsCtrl,
                keyboardType: TextInputType.number,
                hintText: '100',
                validator: (v) {
                  final s = (v ?? '').trim();
                  if (s.isEmpty) return 'Required';
                  final n = int.tryParse(s);
                  if (n == null) return 'Invalid number';
                  if (n < 0) return 'Must be ≥ 0';
                  if (n > 5000) return 'Max 5000';
                  return null;
                },
              ),
            ],
          ),
          const SizedBox(height: OpenVtsSpacing.sm),
          _GroupedCard(
            icon: Icons.backup_outlined,
            title: 'Backup / Data Retention',
            subtitle: 'How long historical data is kept before cleanup.',
            children: [
              _BackupDaysDropdown(
                value: _backupDays,
                onChanged: (v) {
                  if (v == null) return;
                  setState(() => _backupDays = v);
                },
              ),
            ],
          ),
          const SizedBox(height: OpenVtsSpacing.md),
          OpenVtsButton(
            label: 'Save changes',
            isLoading: state.isSavingSoftwareConfig,
            height: 44,
            onPressed: state.isSavingSoftwareConfig ? null : _save,
          ),
          const SizedBox(height: OpenVtsSpacing.md),
          _AdvancedCleanupCard(
            state: state,
            onPreview: state.isPreviewingDataRetention
                ? null
                : _previewRetention,
            onDryRun: state.isRunningDataRetention ? null : _dryRunRetention,
            onRun: state.isRunningDataRetention ? null : _openCleanupSheet,
          ),
        ],
      ),
    );
  }
}

// =====================================================================
// Current configuration summary
// =====================================================================

class _CurrentConfigCard extends StatelessWidget {
  const _CurrentConfigCard({
    required this.allowDemoLogin,
    required this.allowSignup,
    required this.precision,
    required this.backupDays,
    required this.signupCredits,
  });

  final bool allowDemoLogin;
  final bool allowSignup;
  final SuperadminGeocodingPrecision precision;
  final int backupDays;
  final int signupCredits;

  @override
  Widget build(BuildContext context) {
    return OpenVtsCard(
      padding: const EdgeInsets.all(OpenVtsSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.fact_check_outlined,
                size: 14,
                color: OpenVtsColors.textTertiary,
              ),
              SizedBox(width: 6),
              Text(
                'CURRENT CONFIGURATION',
                style: TextStyle(
                  fontFamily: OpenVtsTypography.primaryFontFamily,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.6,
                  color: OpenVtsColors.textTertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: OpenVtsSpacing.xs),
          Row(
            children: [
              Expanded(
                child: _ConfigTile(
                  label: 'Demo login',
                  value: allowDemoLogin ? 'On' : 'Off',
                  positive: allowDemoLogin,
                ),
              ),
              const SizedBox(width: OpenVtsSpacing.xs),
              Expanded(
                child: _ConfigTile(
                  label: 'Signup',
                  value: allowSignup ? 'On' : 'Off',
                  positive: allowSignup,
                ),
              ),
            ],
          ),
          const SizedBox(height: OpenVtsSpacing.xs),
          Row(
            children: [
              Expanded(
                child: _ConfigTile(
                  label: 'Geocoding',
                  value: precision == SuperadminGeocodingPrecision.threeDigit
                      ? '3 digits'
                      : '2 digits',
                ),
              ),
              const SizedBox(width: OpenVtsSpacing.xs),
              Expanded(
                child: _ConfigTile(
                  label: 'Backup',
                  value: _formatBackupDays(backupDays),
                ),
              ),
            ],
          ),
          const SizedBox(height: OpenVtsSpacing.xs),
          _ConfigTile(
            label: 'Free signup credits',
            value: signupCredits.toString(),
          ),
        ],
      ),
    );
  }
}

class _ConfigTile extends StatelessWidget {
  const _ConfigTile({
    required this.label,
    required this.value,
    this.positive,
  });

  final String label;
  final String value;
  final bool? positive;

  @override
  Widget build(BuildContext context) {
    final Color valueColor;
    if (positive == null) {
      valueColor = OpenVtsColors.textPrimary;
    } else if (positive!) {
      valueColor = OpenVtsColors.success;
    } else {
      valueColor = OpenVtsColors.textTertiary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: OpenVtsColors.surface,
        borderRadius: BorderRadius.circular(OpenVtsRadius.sm),
        border: Border.all(color: OpenVtsColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: OpenVtsTypography.primaryFontFamily,
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: OpenVtsColors.textTertiary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: OpenVtsTypography.primaryFontFamily,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

// =====================================================================
// Backup days dropdown
// =====================================================================

class _BackupDaysOption {
  const _BackupDaysOption(this.label, this.days);
  final String label;
  final int days;
}

const List<_BackupDaysOption> _kBackupOptions = [
  _BackupDaysOption('1 Month', 30),
  _BackupDaysOption('3 Months', 90),
  _BackupDaysOption('6 Months', 180),
  _BackupDaysOption('1 Year', 365),
  _BackupDaysOption('2 Years', 730),
  _BackupDaysOption('3 Years', 1095),
  _BackupDaysOption('5 Years', 1825),
  _BackupDaysOption('10 Years', 3650),
];

String _formatBackupDays(int days) {
  for (final o in _kBackupOptions) {
    if (o.days == days) return o.label;
  }
  return '$days days';
}

class _BackupDaysDropdown extends StatelessWidget {
  const _BackupDaysDropdown({required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    final hasValue = _kBackupOptions.any((o) => o.days == value);
    final items = <DropdownMenuItem<int>>[
      if (!hasValue)
        DropdownMenuItem(value: value, child: Text('$value days')),
      for (final o in _kBackupOptions)
        DropdownMenuItem(
          value: o.days,
          child: Text('${o.label}  ·  ${o.days} days'),
        ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Retention period', style: OpenVtsTypography.label),
        const SizedBox(height: OpenVtsSpacing.xs),
        InputDecorator(
          decoration: const InputDecoration(isDense: true),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: value,
              isExpanded: true,
              icon: const Icon(
                Icons.expand_more_rounded,
                size: 18,
                color: OpenVtsColors.textTertiary,
              ),
              style: const TextStyle(
                fontFamily: OpenVtsTypography.primaryFontFamily,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: OpenVtsColors.textPrimary,
              ),
              items: items,
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}

// =====================================================================
// Segmented control
// =====================================================================

class _Seg<T> {
  const _Seg({required this.value, required this.label});
  final T value;
  final String label;
}

class _SegmentedControl<T> extends StatelessWidget {
  const _SegmentedControl({
    required this.value,
    required this.segments,
    required this.onChanged,
  });

  final T value;
  final List<_Seg<T>> segments;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: OpenVtsColors.surface,
        borderRadius: BorderRadius.circular(OpenVtsRadius.sm),
        border: Border.all(color: OpenVtsColors.border),
      ),
      child: Row(
        children: [
          for (final seg in segments)
            Expanded(
              child: _SegBtn(
                label: seg.label,
                selected: seg.value == value,
                onTap: () => onChanged(seg.value),
              ),
            ),
        ],
      ),
    );
  }
}

class _SegBtn extends StatelessWidget {
  const _SegBtn({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(OpenVtsRadius.sm - 2),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? OpenVtsColors.brandInk : Colors.transparent,
          borderRadius: BorderRadius.circular(OpenVtsRadius.sm - 2),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: OpenVtsTypography.primaryFontFamily,
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: selected ? OpenVtsColors.white : OpenVtsColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

// =====================================================================
// Labeled switch row
// =====================================================================

class _LabeledSwitchRow extends StatelessWidget {
  const _LabeledSwitchRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: OpenVtsTypography.primaryFontFamily,
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: OpenVtsColors.textPrimary,
            ),
          ),
        ),
        Switch.adaptive(value: value, onChanged: onChanged),
      ],
    );
  }
}

// =====================================================================
// Advanced cleanup card
// =====================================================================

class _AdvancedCleanupCard extends StatelessWidget {
  const _AdvancedCleanupCard({
    required this.state,
    required this.onPreview,
    required this.onDryRun,
    required this.onRun,
  });

  final SuperadminSettingsState state;
  final VoidCallback? onPreview;
  final VoidCallback? onDryRun;
  final VoidCallback? onRun;

  @override
  Widget build(BuildContext context) {
    final preview = state.dataRetentionPreview;
    return OpenVtsCard(
      padding: const EdgeInsets.all(OpenVtsSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              Icon(
                Icons.delete_sweep_outlined,
                size: 16,
                color: OpenVtsColors.textSecondary,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Advanced Cleanup',
                      style: TextStyle(
                        fontFamily: OpenVtsTypography.primaryFontFamily,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: OpenVtsColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 1),
                    Text(
                      'Permanently remove historical rows older than the retention period.',
                      style: TextStyle(
                        fontFamily: OpenVtsTypography.primaryFontFamily,
                        fontSize: 11,
                        height: 1.3,
                        color: OpenVtsColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: OpenVtsSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7E6),
              borderRadius: BorderRadius.circular(OpenVtsRadius.sm),
              border: Border.all(color: const Color(0xFFFFE0A6)),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  size: 14,
                  color: Color(0xFFB76E00),
                ),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Running cleanup deletes data permanently. Always preview first.',
                    style: TextStyle(
                      fontFamily: OpenVtsTypography.primaryFontFamily,
                      fontSize: 11,
                      height: 1.3,
                      color: Color(0xFF8A5200),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: OpenVtsSpacing.sm),
          Row(
            children: [
              Expanded(
                child: OpenVtsButton(
                  label: 'Preview',
                  variant: OpenVtsButtonVariant.secondary,
                  height: 40,
                  isLoading: state.isPreviewingDataRetention,
                  onPressed: onPreview,
                ),
              ),
              const SizedBox(width: OpenVtsSpacing.xs),
              Expanded(
                child: OpenVtsButton(
                  label: 'Dry-run',
                  variant: OpenVtsButtonVariant.secondary,
                  height: 40,
                  isLoading:
                      state.isRunningDataRetention && (preview?.dryRun ?? false),
                  onPressed: onDryRun,
                ),
              ),
            ],
          ),
          const SizedBox(height: OpenVtsSpacing.xs),
          OpenVtsButton(
            label: 'Run cleanup',
            height: 42,
            isLoading: state.isRunningDataRetention,
            onPressed: onRun,
          ),
          if (preview != null) ...[
            const SizedBox(height: OpenVtsSpacing.sm),
            _RetentionSummaryBlock(summary: preview),
          ],
        ],
      ),
    );
  }
}

// =====================================================================
// Retention summary block + expandable tables
// =====================================================================

class _RetentionSummaryBlock extends StatelessWidget {
  const _RetentionSummaryBlock({required this.summary});
  final SuperadminDataRetentionSummary summary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(OpenVtsSpacing.sm),
      decoration: BoxDecoration(
        color: OpenVtsColors.surface,
        borderRadius: BorderRadius.circular(OpenVtsRadius.md),
        border: Border.all(color: OpenVtsColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                summary.dryRun
                    ? Icons.preview_rounded
                    : Icons.history_toggle_off_rounded,
                size: 14,
                color: OpenVtsColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                summary.dryRun ? 'Dry-run summary' : 'Last cleanup',
                style: const TextStyle(
                  fontFamily: OpenVtsTypography.primaryFontFamily,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: OpenVtsColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          _SummaryRow(
            label: 'Retention',
            value: summary.retentionDays != null
                ? '${summary.retentionDays} days'
                : '—',
          ),
          _SummaryRow(
            label: 'Cutoff',
            value: summary.cutoff != null
                ? summary.cutoff!.toIso8601String().split('T').first
                : '—',
          ),
          _SummaryRow(
            label: 'Older rows',
            value: _formatNumber(summary.totalOlderRows),
          ),
          _SummaryRow(
            label: 'Deleted rows',
            value: _formatNumber(summary.totalDeletedRows),
          ),
          _SummaryRow(
            label: 'Failed tables',
            value: summary.failedTables.toString(),
            warn: summary.failedTables > 0,
          ),
          if (summary.tables.isNotEmpty) ...[
            const SizedBox(height: 6),
            Theme(
              data: Theme.of(context).copyWith(
                dividerColor: Colors.transparent,
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
              ),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: EdgeInsets.zero,
                title: Text(
                  'Tables (${summary.tables.length})',
                  style: const TextStyle(
                    fontFamily: OpenVtsTypography.primaryFontFamily,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: OpenVtsColors.textPrimary,
                  ),
                ),
                children: [
                  for (final t in summary.tables) _TableRow(table: t),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.warn = false,
  });

  final String label;
  final String value;
  final bool warn;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: OpenVtsTypography.primaryFontFamily,
                fontSize: 11.5,
                color: OpenVtsColors.textSecondary,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontFamily: OpenVtsTypography.primaryFontFamily,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: warn ? const Color(0xFFB76E00) : OpenVtsColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _TableRow extends StatelessWidget {
  const _TableRow({required this.table});
  final SuperadminDataRetentionTableResult table;

  @override
  Widget build(BuildContext context) {
    final tableLabel = table.tableName ?? '—';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  tableLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: OpenVtsTypography.primaryFontFamily,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: OpenVtsColors.textPrimary,
                  ),
                ),
              ),
              if (table.failed)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEBE6),
                    borderRadius: BorderRadius.circular(OpenVtsRadius.pill),
                    border: Border.all(color: const Color(0xFFFFC4B0)),
                  ),
                  child: const Text(
                    'FAILED',
                    style: TextStyle(
                      fontFamily: OpenVtsTypography.primaryFontFamily,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: Color(0xFFB42318),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              _MiniMetric(
                label: 'Older',
                value: _formatNumber(table.olderRows),
              ),
              const SizedBox(width: 10),
              _MiniMetric(
                label: 'Deleted',
                value: _formatNumber(table.deletedRows),
              ),
            ],
          ),
          if (table.failed && (table.errorMessage?.isNotEmpty ?? false)) ...[
            const SizedBox(height: 2),
            Text(
              table.errorMessage!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: OpenVtsTypography.primaryFontFamily,
                fontSize: 10.5,
                color: Color(0xFFB42318),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MiniMetric extends StatelessWidget {
  const _MiniMetric({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label:',
          style: const TextStyle(
            fontFamily: OpenVtsTypography.primaryFontFamily,
            fontSize: 10.5,
            color: OpenVtsColors.textTertiary,
          ),
        ),
        const SizedBox(width: 3),
        Text(
          value,
          style: const TextStyle(
            fontFamily: OpenVtsTypography.primaryFontFamily,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: OpenVtsColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

// =====================================================================
// Cleanup confirm sheet
// =====================================================================

const String _kCleanupPhrase = 'DELETE OLD LOGS';

class _CleanupConfirmSheet extends StatefulWidget {
  const _CleanupConfirmSheet();

  @override
  State<_CleanupConfirmSheet> createState() => _CleanupConfirmSheetState();
}

class _CleanupConfirmSheetState extends State<_CleanupConfirmSheet> {
  final _ctrl = TextEditingController();
  bool _matches = false;

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(() {
      final next = _ctrl.text.trim() == _kCleanupPhrase;
      if (next != _matches) setState(() => _matches = next);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            OpenVtsSpacing.md,
            OpenVtsSpacing.sm,
            OpenVtsSpacing.md,
            OpenVtsSpacing.md,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: OpenVtsSpacing.sm),
                  decoration: BoxDecoration(
                    color: OpenVtsColors.border,
                    borderRadius: BorderRadius.circular(OpenVtsRadius.pill),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEBE6),
                      borderRadius: BorderRadius.circular(OpenVtsRadius.sm),
                      border: Border.all(color: const Color(0xFFFFC4B0)),
                    ),
                    child: const Icon(
                      Icons.warning_amber_rounded,
                      size: 16,
                      color: Color(0xFFB42318),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Confirm cleanup',
                      style: TextStyle(
                        fontFamily: OpenVtsTypography.primaryFontFamily,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: OpenVtsColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'This permanently deletes data older than the retention period. '
                'It cannot be undone.',
                style: TextStyle(
                  fontFamily: OpenVtsTypography.primaryFontFamily,
                  fontSize: 11.5,
                  height: 1.4,
                  color: OpenVtsColors.textSecondary,
                ),
              ),
              const SizedBox(height: OpenVtsSpacing.sm),
              const Text.rich(
                TextSpan(
                  style: TextStyle(
                    fontFamily: OpenVtsTypography.primaryFontFamily,
                    fontSize: 11.5,
                    color: OpenVtsColors.textSecondary,
                  ),
                  children: [
                    TextSpan(text: 'Type '),
                    TextSpan(
                      text: _kCleanupPhrase,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: OpenVtsColors.textPrimary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    TextSpan(text: ' to enable the button.'),
                  ],
                ),
              ),
              const SizedBox(height: OpenVtsSpacing.xs),
              OpenVtsTextField(
                label: 'Confirmation phrase',
                controller: _ctrl,
                hintText: _kCleanupPhrase,
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: OpenVtsSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: OpenVtsButton(
                      label: 'Cancel',
                      variant: OpenVtsButtonVariant.secondary,
                      height: 42,
                      onPressed: () => Navigator.of(context).pop(false),
                    ),
                  ),
                  const SizedBox(width: OpenVtsSpacing.sm),
                  Expanded(
                    child: OpenVtsButton(
                      label: 'Delete',
                      height: 42,
                      onPressed: _matches
                          ? () => Navigator.of(context).pop(true)
                          : null,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =====================================================================
// Section header
// =====================================================================

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return OpenVtsCard(
      padding: const EdgeInsets.all(OpenVtsSpacing.md),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: OpenVtsColors.surface,
              borderRadius: BorderRadius.circular(OpenVtsRadius.sm),
              border: Border.all(color: OpenVtsColors.border),
            ),
            child: Icon(icon, size: 16, color: OpenVtsColors.textPrimary),
          ),
          const SizedBox(width: OpenVtsSpacing.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: OpenVtsTypography.primaryFontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: OpenVtsColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontFamily: OpenVtsTypography.primaryFontFamily,
                    fontSize: 11,
                    height: 1.3,
                    color: OpenVtsColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: OpenVtsSpacing.xs),
            trailing!,
          ],
        ],
      ),
    );
  }
}

// =====================================================================
// Grouped card with title row
// =====================================================================

class _GroupedCard extends StatelessWidget {
  const _GroupedCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return OpenVtsCard(
      padding: const EdgeInsets.all(OpenVtsSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: OpenVtsColors.textSecondary),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
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
                        fontSize: 11,
                        height: 1.3,
                        color: OpenVtsColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: OpenVtsSpacing.sm),
          ...children,
        ],
      ),
    );
  }
}

// =====================================================================
// Helpers
// =====================================================================

String _formatNumber(int n) {
  final s = n.toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    final fromEnd = s.length - i;
    buf.write(s[i]);
    if (fromEnd > 1 && (fromEnd - 1) % 3 == 0) buf.write(',');
  }
  return buf.toString();
}
