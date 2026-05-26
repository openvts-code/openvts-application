import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
import '../../../controllers/superadmin_providers.dart';
import '../../../controllers/superadmin_settings_controller.dart';
import '../../../models/superadmin_settings_model.dart';
import '../../../models/superadmin_settings_state.dart';

// =====================================================================
// Theme color presets (mirror of Web THEME_COLORS)
// =====================================================================

class _ThemeColorOption {
  const _ThemeColorOption({
    required this.name,
    required this.lightValue,
    required this.darkValue,
  });

  final String name;
  final String lightValue;
  final String darkValue;

  String get id => name.toLowerCase();
}

const List<_ThemeColorOption> _kThemeColors = [
  _ThemeColorOption(
    name: 'Black',
    lightValue: '#0F172A',
    darkValue: '#F8FAFC',
  ),
  _ThemeColorOption(
    name: 'Blue',
    lightValue: '#2563EB',
    darkValue: '#60A5FA',
  ),
  _ThemeColorOption(
    name: 'Green',
    lightValue: '#16A34A',
    darkValue: '#4ADE80',
  ),
  _ThemeColorOption(
    name: 'Purple',
    lightValue: '#9333EA',
    darkValue: '#C084FC',
  ),
  _ThemeColorOption(
    name: 'Pink',
    lightValue: '#DB2777',
    darkValue: '#F472B6',
  ),
  _ThemeColorOption(
    name: 'Orange',
    lightValue: '#EA580C',
    darkValue: '#FB923C',
  ),
];

const _faviconExts = ['ico', 'png', 'svg'];
const _logoExts = ['png', 'jpg', 'jpeg', 'svg', 'webp'];
const int _faviconMaxBytes = 2 * 1024 * 1024;
const int _logoMaxBytes = 5 * 1024 * 1024;

// =====================================================================
// Public section widget
// =====================================================================

class WhiteLabelSettingsSection extends ConsumerStatefulWidget {
  const WhiteLabelSettingsSection({super.key, required this.state});

  final SuperadminSettingsState state;

  @override
  ConsumerState<WhiteLabelSettingsSection> createState() =>
      _WhiteLabelSettingsSectionState();
}

class _WhiteLabelSettingsSectionState
    extends ConsumerState<WhiteLabelSettingsSection> {
  final _domainController = TextEditingController();
  final _domainFormKey = GlobalKey<FormState>();

  String? _selectedColorId;
  String? _syncedDomain;
  String? _syncedColor;

  // Per-asset picked file + clear flag.
  _PickedAsset? _faviconPicked;
  bool _faviconCleared = false;
  _PickedAsset? _logoLightPicked;
  bool _logoLightCleared = false;
  _PickedAsset? _logoDarkPicked;
  bool _logoDarkCleared = false;

  bool _savingDomain = false;
  bool _savingFavicon = false;
  bool _savingLogoLight = false;
  bool _savingLogoDark = false;

  @override
  void initState() {
    super.initState();
    _syncFromState(widget.state.whiteLabel);
  }

  @override
  void didUpdateWidget(covariant WhiteLabelSettingsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = widget.state.whiteLabel;
    if (next?.customDomain != _syncedDomain ||
        next?.primaryColor != _syncedColor) {
      _syncFromState(next);
    }
  }

  void _syncFromState(SuperadminWhiteLabelSettings? wl) {
    _syncedDomain = wl?.customDomain;
    _syncedColor = wl?.primaryColor;
    _domainController.text = wl?.customDomain ?? '';
    _selectedColorId = _resolveColorId(wl?.primaryColor);
  }

  String _resolveColorId(String? raw) {
    final v = (raw ?? '').trim().toLowerCase();
    if (v.isEmpty) return _kThemeColors.first.id;
    for (final c in _kThemeColors) {
      if (c.id == v) return c.id;
    }
    return _kThemeColors.first.id;
  }

  _ThemeColorOption get _selectedColor =>
      _kThemeColors.firstWhere((c) => c.id == _selectedColorId,
          orElse: () => _kThemeColors.first);

  @override
  void dispose() {
    _domainController.dispose();
    super.dispose();
  }

  SuperadminSettingsController get _controller =>
      ref.read(superadminSettingsControllerProvider.notifier);

  // -----------------------------------------------------------------
  // Domain & color save
  // -----------------------------------------------------------------

  bool get _domainOrColorChanged {
    final domain = _normalizeDomain(_domainController.text);
    return domain != (_syncedDomain ?? '') ||
        _selectedColor.name.toLowerCase() !=
            (_syncedColor ?? '').trim().toLowerCase();
  }

  Future<void> _saveDomainAndColor() async {
    if (_savingDomain) return;
    final form = _domainFormKey.currentState;
    if (form == null || !form.validate()) return;

    final domain = _normalizeDomain(_domainController.text);

    setState(() => _savingDomain = true);
    final ok = await _controller.updateWhiteLabel(
      customDomain: domain,
      primaryColor: _selectedColor.name,
    );
    if (!mounted) return;
    setState(() => _savingDomain = false);
    if (ok) {
      await _controller.loadWhiteLabel();
      if (!mounted) return;
      ToastHelper.showSuccess('Domain and brand color saved');
    } else {
      final latest = ref.read(superadminSettingsControllerProvider);
      ToastHelper.showError(
        latest.sectionErrorMessage ?? 'Could not save changes',
      );
    }
  }

  // -----------------------------------------------------------------
  // Asset pick / clear / save
  // -----------------------------------------------------------------

  Future<_PickedAsset?> _pickFile({
    required List<String> allowedExtensions,
    required int maxBytes,
  }) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: allowedExtensions,
        withData: true,
      );
      if (result == null || result.files.isEmpty) return null;
      final file = result.files.single;
      final bytes = file.bytes;
      if (bytes == null) {
        ToastHelper.showError('Could not read selected file');
        return null;
      }
      if (bytes.length > maxBytes) {
        final mb = (maxBytes / (1024 * 1024)).toStringAsFixed(0);
        ToastHelper.showError('File exceeds $mb MB limit');
        return null;
      }
      final ext = _extensionOf(file.name);
      if (!allowedExtensions.contains(ext)) {
        ToastHelper.showError(
          'Unsupported format. Allowed: ${allowedExtensions.join(", ")}',
        );
        return null;
      }
      return _PickedAsset(bytes: bytes, fileName: file.name);
    } catch (_) {
      if (mounted) {
        ToastHelper.showError('Could not pick file');
      }
      return null;
    }
  }

  Future<void> _saveFavicon() async {
    if (_savingFavicon) return;
    final picked = _faviconPicked;
    final cleared = _faviconCleared;
    final existing = widget.state.whiteLabel?.faviconUrl;
    if (picked == null && !(cleared && (existing ?? '').isNotEmpty)) return;

    setState(() => _savingFavicon = true);
    final ok = await _controller.updateWhiteLabel(
      favicon: picked == null
          ? null
          : FileAttachment(bytes: picked.bytes, fileName: picked.fileName),
      faviconUrl: picked == null && cleared ? '' : null,
    );
    if (!mounted) return;
    setState(() {
      _savingFavicon = false;
      if (ok) {
        _faviconPicked = null;
        _faviconCleared = false;
      }
    });
    if (ok) {
      ToastHelper.showSuccess('Favicon updated');
    } else {
      ToastHelper.showError(
        ref.read(superadminSettingsControllerProvider).sectionErrorMessage ?? 'Could not save favicon',
      );
    }
  }

  Future<void> _saveLogoLight() async {
    if (_savingLogoLight) return;
    final picked = _logoLightPicked;
    final cleared = _logoLightCleared;
    final existing = widget.state.whiteLabel?.logoLightUrl;
    if (picked == null && !(cleared && (existing ?? '').isNotEmpty)) return;

    setState(() => _savingLogoLight = true);
    final ok = await _controller.updateWhiteLabel(
      logoLight: picked == null
          ? null
          : FileAttachment(bytes: picked.bytes, fileName: picked.fileName),
      logoLightUrl: picked == null && cleared ? '' : null,
    );
    if (!mounted) return;
    setState(() {
      _savingLogoLight = false;
      if (ok) {
        _logoLightPicked = null;
        _logoLightCleared = false;
      }
    });
    if (ok) {
      ToastHelper.showSuccess('Light logo updated');
    } else {
      ToastHelper.showError(
        ref.read(superadminSettingsControllerProvider).sectionErrorMessage ?? 'Could not save light logo',
      );
    }
  }

  Future<void> _saveLogoDark() async {
    if (_savingLogoDark) return;
    final picked = _logoDarkPicked;
    final cleared = _logoDarkCleared;
    final existing = widget.state.whiteLabel?.logoDarkUrl;
    if (picked == null && !(cleared && (existing ?? '').isNotEmpty)) return;

    setState(() => _savingLogoDark = true);
    final ok = await _controller.updateWhiteLabel(
      logoDark: picked == null
          ? null
          : FileAttachment(bytes: picked.bytes, fileName: picked.fileName),
      logoDarkUrl: picked == null && cleared ? '' : null,
    );
    if (!mounted) return;
    setState(() {
      _savingLogoDark = false;
      if (ok) {
        _logoDarkPicked = null;
        _logoDarkCleared = false;
      }
    });
    if (ok) {
      ToastHelper.showSuccess('Dark logo updated');
    } else {
      ToastHelper.showError(
        ref.read(superadminSettingsControllerProvider).sectionErrorMessage ?? 'Could not save dark logo',
      );
    }
  }

  // -----------------------------------------------------------------
  // Build
  // -----------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final controller = _controller;

    if (state.isLoadingWhiteLabel && state.whiteLabel == null) {
      return const OpenVtsCard(
        padding: EdgeInsets.symmetric(vertical: OpenVtsSpacing.lg),
        child: Center(child: OpenVtsLoader()),
      );
    }

    if (state.whiteLabel == null) {
      return OpenVtsCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              state.sectionErrorMessage ??
                  'Could not load white-label settings.',
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
              onPressed: controller.loadWhiteLabel,
            ),
          ],
        ),
      );
    }

    final baseUrl = ref.watch(apiBaseUrlProvider);
    final wl = state.whiteLabel!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionHeader(
          title: 'White Label',
          subtitle: 'Domain, logos, favicon, and brand color.',
          icon: Icons.palette_outlined,
          trailing: IconButton(
            tooltip: 'Refresh',
            onPressed:
                state.isLoadingWhiteLabel ? null : controller.loadWhiteLabel,
            iconSize: 18,
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ),
        const SizedBox(height: OpenVtsSpacing.sm),
        _DomainAndColorCard(
          formKey: _domainFormKey,
          domainController: _domainController,
          selectedColor: _selectedColor,
          onColorChanged: (c) {
            setState(() => _selectedColorId = c.id);
          },
          onSave: _saveDomainAndColor,
          isSaving: _savingDomain,
          canSave: _domainOrColorChanged,
        ),
        const SizedBox(height: OpenVtsSpacing.sm),
        _AssetCard(
          title: 'Favicon',
          subtitle: 'Browser tab icon. ICO, PNG or SVG. Max 2 MB.',
          icon: Icons.tab_outlined,
          currentUrl: wl.faviconUrl,
          baseUrl: baseUrl,
          picked: _faviconPicked,
          cleared: _faviconCleared,
          isSaving: _savingFavicon,
          onPick: () async {
            final picked = await _pickFile(
              allowedExtensions: _faviconExts,
              maxBytes: _faviconMaxBytes,
            );
            if (picked != null && mounted) {
              setState(() {
                _faviconPicked = picked;
                _faviconCleared = false;
              });
            }
          },
          onClear: () {
            setState(() {
              _faviconPicked = null;
              _faviconCleared = (wl.faviconUrl ?? '').isNotEmpty;
            });
          },
          onSave: _saveFavicon,
        ),
        const SizedBox(height: OpenVtsSpacing.sm),
        _AssetCard(
          title: 'Light Logo',
          subtitle: 'Shown on light backgrounds. PNG, JPG, SVG, WEBP. Max 5 MB.',
          icon: Icons.wb_sunny_outlined,
          currentUrl: wl.logoLightUrl,
          baseUrl: baseUrl,
          picked: _logoLightPicked,
          cleared: _logoLightCleared,
          isSaving: _savingLogoLight,
          previewBackground: OpenVtsColors.white,
          onPick: () async {
            final picked = await _pickFile(
              allowedExtensions: _logoExts,
              maxBytes: _logoMaxBytes,
            );
            if (picked != null && mounted) {
              setState(() {
                _logoLightPicked = picked;
                _logoLightCleared = false;
              });
            }
          },
          onClear: () {
            setState(() {
              _logoLightPicked = null;
              _logoLightCleared = (wl.logoLightUrl ?? '').isNotEmpty;
            });
          },
          onSave: _saveLogoLight,
        ),
        const SizedBox(height: OpenVtsSpacing.sm),
        _AssetCard(
          title: 'Dark Logo',
          subtitle: 'Shown on dark backgrounds. PNG, JPG, SVG, WEBP. Max 5 MB.',
          icon: Icons.nightlight_outlined,
          currentUrl: wl.logoDarkUrl,
          baseUrl: baseUrl,
          picked: _logoDarkPicked,
          cleared: _logoDarkCleared,
          isSaving: _savingLogoDark,
          previewBackground: OpenVtsColors.brandInk,
          onPick: () async {
            final picked = await _pickFile(
              allowedExtensions: _logoExts,
              maxBytes: _logoMaxBytes,
            );
            if (picked != null && mounted) {
              setState(() {
                _logoDarkPicked = picked;
                _logoDarkCleared = false;
              });
            }
          },
          onClear: () {
            setState(() {
              _logoDarkPicked = null;
              _logoDarkCleared = (wl.logoDarkUrl ?? '').isNotEmpty;
            });
          },
          onSave: _saveLogoDark,
        ),
      ],
    );
  }
}

// =====================================================================
// Picked asset value object
// =====================================================================

class _PickedAsset {
  const _PickedAsset({required this.bytes, required this.fileName});
  final Uint8List bytes;
  final String fileName;
}

// =====================================================================
// Section header (matches _SectionCard look)
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
// Domain & Color card
// =====================================================================

class _DomainAndColorCard extends StatelessWidget {
  const _DomainAndColorCard({
    required this.formKey,
    required this.domainController,
    required this.selectedColor,
    required this.onColorChanged,
    required this.onSave,
    required this.isSaving,
    required this.canSave,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController domainController;
  final _ThemeColorOption selectedColor;
  final ValueChanged<_ThemeColorOption> onColorChanged;
  final Future<void> Function() onSave;
  final bool isSaving;
  final bool canSave;

  @override
  Widget build(BuildContext context) {
    return OpenVtsCard(
      padding: const EdgeInsets.all(OpenVtsSpacing.md),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _CardTitle(
              icon: Icons.domain_outlined,
              title: 'Domain & Color',
              subtitle: 'Custom domain and brand color.',
            ),
            const SizedBox(height: OpenVtsSpacing.sm),
            OpenVtsTextField(
              label: 'Custom Domain',
              controller: domainController,
              keyboardType: TextInputType.url,
              hintText: 'track.example.com',
              validator: (value) {
                final normalized = _normalizeDomain(value ?? '');
                if (normalized.isEmpty) return null;
                if (normalized.length > 100) {
                  return 'Maximum 100 characters';
                }
                if (!_isValidDomain(normalized)) {
                  return 'Enter a valid hostname or IP';
                }
                return null;
              },
            ),
            const SizedBox(height: OpenVtsSpacing.sm),
            const Text('Primary Color', style: OpenVtsTypography.label),
            const SizedBox(height: OpenVtsSpacing.xs),
            InkWell(
              borderRadius: BorderRadius.circular(OpenVtsRadius.sm),
              onTap: isSaving
                  ? null
                  : () async {
                      final result = await showModalBottomSheet<_ThemeColorOption>(
                        context: context,
                        backgroundColor: OpenVtsColors.surfaceElevated,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(OpenVtsRadius.lg),
                          ),
                        ),
                        builder: (ctx) => _ColorPickerSheet(
                          selectedId: selectedColor.id,
                        ),
                      );
                      if (result != null) onColorChanged(result);
                    },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: OpenVtsSpacing.sm,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: OpenVtsColors.surface,
                  borderRadius: BorderRadius.circular(OpenVtsRadius.sm),
                  border: Border.all(color: OpenVtsColors.border),
                ),
                child: Row(
                  children: [
                    _ColorChip(hex: selectedColor.lightValue),
                    const SizedBox(width: OpenVtsSpacing.xs),
                    Expanded(
                      child: Text(
                        selectedColor.name,
                        style: const TextStyle(
                          fontFamily: OpenVtsTypography.primaryFontFamily,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: OpenVtsColors.textPrimary,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.expand_more_rounded,
                      size: 18,
                      color: OpenVtsColors.textTertiary,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: OpenVtsSpacing.md),
            OpenVtsButton(
              label: 'Save changes',
              isLoading: isSaving,
              height: 42,
              onPressed: canSave && !isSaving ? () => onSave() : null,
            ),
          ],
        ),
      ),
    );
  }
}

// =====================================================================
// Color picker sheet
// =====================================================================

class _ColorPickerSheet extends StatelessWidget {
  const _ColorPickerSheet({required this.selectedId});

  final String selectedId;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
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
            const Text(
              'Brand color',
              style: TextStyle(
                fontFamily: OpenVtsTypography.primaryFontFamily,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: OpenVtsColors.textPrimary,
              ),
            ),
            const SizedBox(height: OpenVtsSpacing.xs),
            for (final option in _kThemeColors)
              InkWell(
                borderRadius: BorderRadius.circular(OpenVtsRadius.sm),
                onTap: () => Navigator.of(context).pop(option),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: OpenVtsSpacing.xs,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      _ColorChip(hex: option.lightValue),
                      const SizedBox(width: OpenVtsSpacing.sm),
                      Expanded(
                        child: Text(
                          option.name,
                          style: const TextStyle(
                            fontFamily: OpenVtsTypography.primaryFontFamily,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w500,
                            color: OpenVtsColors.textPrimary,
                          ),
                        ),
                      ),
                      if (option.id == selectedId)
                        const Icon(
                          Icons.check_rounded,
                          size: 18,
                          color: OpenVtsColors.success,
                        ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ColorChip extends StatelessWidget {
  const _ColorChip({required this.hex});
  final String hex;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: _parseHex(hex),
        borderRadius: BorderRadius.circular(OpenVtsRadius.sm),
        border: Border.all(color: OpenVtsColors.border),
      ),
    );
  }
}

// =====================================================================
// Asset card (favicon / light / dark)
// =====================================================================

class _AssetCard extends StatelessWidget {
  const _AssetCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.currentUrl,
    required this.baseUrl,
    required this.picked,
    required this.cleared,
    required this.isSaving,
    required this.onPick,
    required this.onClear,
    required this.onSave,
    this.previewBackground,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String? currentUrl;
  final String baseUrl;
  final _PickedAsset? picked;
  final bool cleared;
  final bool isSaving;
  final Future<void> Function() onPick;
  final VoidCallback onClear;
  final Future<void> Function() onSave;
  final Color? previewBackground;

  bool get _hasExistingUrl =>
      currentUrl != null && currentUrl!.trim().isNotEmpty;

  bool get _canSave => picked != null || (cleared && _hasExistingUrl);

  bool get _canClear => picked != null || (_hasExistingUrl && !cleared);

  @override
  Widget build(BuildContext context) {
    final resolvedUrl =
        _hasExistingUrl ? resolveProfileImageUrl(baseUrl, currentUrl) : null;

    return OpenVtsCard(
      padding: const EdgeInsets.all(OpenVtsSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CardTitle(
            icon: icon,
            title: title,
            subtitle: subtitle,
          ),
          const SizedBox(height: OpenVtsSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _AssetPreview(
                pickedBytes: picked?.bytes,
                pickedFileName: picked?.fileName,
                existingUrl: cleared ? null : resolvedUrl,
                background: previewBackground,
              ),
              const SizedBox(width: OpenVtsSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _statusLabel(),
                      style: const TextStyle(
                        fontFamily: OpenVtsTypography.primaryFontFamily,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: OpenVtsColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      _detailLabel(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
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
          Row(
            children: [
              Expanded(
                child: OpenVtsButton(
                  label: picked != null
                      ? 'Replace'
                      : (_hasExistingUrl ? 'Replace' : 'Select file'),
                  variant: OpenVtsButtonVariant.secondary,
                  height: 38,
                  onPressed: isSaving ? null : () => onPick(),
                ),
              ),
              const SizedBox(width: OpenVtsSpacing.xs),
              SizedBox(
                width: 40,
                height: 38,
                child: IconButton(
                  tooltip: 'Remove',
                  onPressed: isSaving || !_canClear ? null : onClear,
                  iconSize: 18,
                  icon: const Icon(Icons.delete_outline_rounded),
                  style: IconButton.styleFrom(
                    backgroundColor: OpenVtsColors.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(OpenVtsRadius.sm),
                      side: const BorderSide(color: OpenVtsColors.border),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: OpenVtsSpacing.xs),
          OpenVtsButton(
            label: 'Save',
            height: 38,
            isLoading: isSaving,
            onPressed: _canSave && !isSaving ? () => onSave() : null,
          ),
        ],
      ),
    );
  }

  String _statusLabel() {
    if (picked != null) return 'New file ready';
    if (cleared && _hasExistingUrl) return 'Will remove current asset';
    if (_hasExistingUrl) return 'Current asset';
    return 'No asset uploaded';
  }

  String _detailLabel() {
    if (picked != null) {
      final kb = picked!.bytes.length / 1024;
      final size = kb >= 1024
          ? '${(kb / 1024).toStringAsFixed(2)} MB'
          : '${kb.toStringAsFixed(0)} KB';
      return '${picked!.fileName}  ·  $size';
    }
    if (cleared && _hasExistingUrl) {
      return 'Press Save to apply.';
    }
    if (_hasExistingUrl) {
      return currentUrl!;
    }
    return 'Pick a file to upload.';
  }
}

class _AssetPreview extends StatelessWidget {
  const _AssetPreview({
    required this.pickedBytes,
    required this.pickedFileName,
    required this.existingUrl,
    this.background,
  });

  final Uint8List? pickedBytes;
  final String? pickedFileName;
  final String? existingUrl;
  final Color? background;

  bool get _pickedIsRaster {
    final ext = _extensionOf(pickedFileName ?? '');
    return ['png', 'jpg', 'jpeg', 'webp', 'ico', 'gif'].contains(ext);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: background ?? OpenVtsColors.surface,
        borderRadius: BorderRadius.circular(OpenVtsRadius.sm),
        border: Border.all(color: OpenVtsColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (pickedBytes != null) {
      if (_pickedIsRaster) {
        return Image.memory(
          pickedBytes!,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => _placeholder(),
        );
      }
      return _filePlaceholder(pickedFileName ?? '');
    }
    if (existingUrl != null) {
      final lower = existingUrl!.toLowerCase();
      if (lower.endsWith('.svg')) {
        return _filePlaceholder('SVG');
      }
      return Image.network(
        existingUrl!,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => _placeholder(),
      );
    }
    return _placeholder();
  }

  Widget _placeholder() {
    return const Icon(
      Icons.image_not_supported_outlined,
      size: 18,
      color: OpenVtsColors.textTertiary,
    );
  }

  Widget _filePlaceholder(String label) {
    final ext = _extensionOf(label).toUpperCase();
    return Text(
      ext.isEmpty ? 'FILE' : ext,
      style: const TextStyle(
        fontFamily: OpenVtsTypography.primaryFontFamily,
        fontSize: 10.5,
        fontWeight: FontWeight.w700,
        color: OpenVtsColors.textPrimary,
        letterSpacing: 0.5,
      ),
    );
  }
}

// =====================================================================
// Compact in-card title row
// =====================================================================

class _CardTitle extends StatelessWidget {
  const _CardTitle({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
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
    );
  }
}

// =====================================================================
// Helpers
// =====================================================================

String _normalizeDomain(String raw) {
  var s = raw.trim();
  if (s.isEmpty) return '';
  // strip protocol like https:// or anything://
  final proto = RegExp(r'^[a-zA-Z][a-zA-Z0-9+\-.]*://');
  final m = proto.firstMatch(s);
  if (m != null) s = s.substring(m.end);
  // remove path / query / fragment
  final cut = s.indexOf(RegExp(r'[/?#]'));
  if (cut >= 0) s = s.substring(0, cut);
  // strip user:pass@ if pasted
  final at = s.indexOf('@');
  if (at >= 0) s = s.substring(at + 1);
  return s.toLowerCase();
}

bool _isValidDomain(String s) {
  if (s.isEmpty) return true;
  if (s.length > 100) return false;
  if (s == 'localhost') return true;
  final ipv4 = RegExp(
    r'^((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)\.){3}(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)$',
  );
  if (ipv4.hasMatch(s)) return true;
  final hostname = RegExp(
    r'^(?=.{1,253}$)(?!-)[a-z0-9-]{1,63}(?<!-)(\.(?!-)[a-z0-9-]{1,63}(?<!-))+$',
  );
  return hostname.hasMatch(s);
}

String _extensionOf(String fileName) {
  final dot = fileName.lastIndexOf('.');
  if (dot < 0 || dot == fileName.length - 1) return '';
  return fileName.substring(dot + 1).toLowerCase();
}

Color _parseHex(String hex) {
  var s = hex.trim();
  if (s.startsWith('#')) s = s.substring(1);
  if (s.length == 6) s = 'FF$s';
  final v = int.tryParse(s, radix: 16);
  if (v == null) return OpenVtsColors.brandInk;
  return Color(v);
}
