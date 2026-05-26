import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../../core/theme/open_vts_colors.dart';
import '../../../../../core/theme/open_vts_radius.dart';
import '../../../../../core/theme/open_vts_spacing.dart';
import '../../../../../core/theme/open_vts_typography.dart';
import '../../../../../shared/widgets/open_vts_card.dart';
import '../../../controllers/user_settings_controller.dart';
import '../../../models/user_settings_model.dart';
import '../../../models/user_settings_state.dart';
import 'user_localization_preview_card.dart';
import 'user_localization_select_card.dart';
import 'user_location_preset_chips.dart';
import 'user_map_defaults_card.dart';

class UserLocalizationSettingsTab extends StatefulWidget {
  const UserLocalizationSettingsTab({
    required this.state,
    required this.controller,
    super.key,
  });

  final UserSettingsState state;
  final UserSettingsController controller;

  @override
  State<UserLocalizationSettingsTab> createState() =>
      _UserLocalizationSettingsTabState();
}

class _UserLocalizationSettingsTabState
    extends State<UserLocalizationSettingsTab> {
  final TextEditingController _latitudeController = TextEditingController();
  final TextEditingController _longitudeController = TextEditingController();
  final TextEditingController _mapZoomController = TextEditingController();

  bool _isHydrating = false;
  String? _latitudeError;
  String? _longitudeError;
  String? _mapZoomError;

  UserLocalizationSettings get _draft =>
      widget.state.draftLocalization ??
      widget.state.localization ??
      UserLocalizationSettings.defaults;

  @override
  void initState() {
    super.initState();
    _hydrateMapControllers(_draft, clearErrors: true);
  }

  @override
  void didUpdateWidget(covariant UserLocalizationSettingsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    _hydrateMapControllers(_draft, clearErrors: true);
  }

  @override
  void dispose() {
    _latitudeController.dispose();
    _longitudeController.dispose();
    _mapZoomController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final draft = _draft;

    final languageOptions = _buildLanguageOptions(draft);
    final dateFormatOptions = _buildDateFormatOptions(draft);
    final timezoneOptions = _buildTimezoneOptions(draft);

    final languageLabel = _labelForValue(
      options: languageOptions,
      value: draft.language,
      fallback: draft.language.toUpperCase(),
    );

    final showReferenceFallbackWarning = !widget.state.isLoadingReferences &&
        (widget.state.languages.isEmpty ||
            widget.state.dateFormats.isEmpty ||
            widget.state.timezones.isEmpty);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        UserLocalizationPreviewCard(
          settings: draft,
          languageLabel: languageLabel,
        ),
        if (showReferenceFallbackWarning) ...[
          const SizedBox(height: OpenVtsSpacing.sm),
          _ReferenceFallbackWarning(
            message: widget.state.errorMessage,
            onRetry: () {
              unawaited(widget.controller.loadReferenceData(force: true));
            },
          ),
        ],
        const SizedBox(height: OpenVtsSpacing.sm),
        UserLocalizationSelectCard(
          title: 'Language',
          subtitle: 'Language and layout direction.',
          icon: Icons.translate_rounded,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              UserLocalizationPickerTile(
                label: 'Language',
                valueLabel: languageLabel,
                onTap: () => _pickLanguage(languageOptions),
                hintText: 'Select language',
              ),
              const SizedBox(height: OpenVtsSpacing.sm),
              _SegmentedField<UserLayoutDirection>(
                label: 'Layout Direction',
                child: UserLocalizationSegmentedControl<UserLayoutDirection>(
                  value: draft.layoutDirection,
                  semanticsLabel: 'Layout direction selector',
                  segments: const [
                    UserLocalizationSegmentOption<UserLayoutDirection>(
                      value: UserLayoutDirection.ltr,
                      label: 'LTR',
                    ),
                    UserLocalizationSegmentOption<UserLayoutDirection>(
                      value: UserLayoutDirection.rtl,
                      label: 'RTL',
                    ),
                  ],
                  onChanged: (value) {
                    widget.controller.patchDraftLocalization(
                      layoutDirection: value,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: OpenVtsSpacing.sm),
        UserLocalizationSelectCard(
          title: 'Date and Time',
          subtitle: 'Date format, time style, and timezone.',
          icon: Icons.event_note_rounded,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              UserLocalizationPickerTile(
                label: 'Date Format',
                valueLabel: _labelForValue(
                  options: dateFormatOptions,
                  value: draft.dateFormat,
                  fallback: draft.dateFormat,
                ),
                onTap: () => _pickDateFormat(dateFormatOptions),
                hintText: 'Select date format',
              ),
              const SizedBox(height: OpenVtsSpacing.sm),
              _SegmentedField<bool>(
                label: 'Time Format',
                child: UserLocalizationSegmentedControl<bool>(
                  value: draft.use24Hour,
                  semanticsLabel: 'Time format selector',
                  segments: const [
                    UserLocalizationSegmentOption<bool>(
                      value: true,
                      label: '24H',
                    ),
                    UserLocalizationSegmentOption<bool>(
                      value: false,
                      label: '12H',
                    ),
                  ],
                  onChanged: (value) {
                    widget.controller.patchDraftLocalization(use24Hour: value);
                  },
                ),
              ),
              const SizedBox(height: OpenVtsSpacing.sm),
              UserLocalizationPickerTile(
                label: 'Timezone',
                valueLabel: _labelForValue(
                  options: timezoneOptions,
                  value: draft.timezoneOffset,
                  fallback: draft.timezoneOffset,
                ),
                onTap: () => _pickTimezone(timezoneOptions),
                hintText: 'Select timezone',
              ),
            ],
          ),
        ),
        const SizedBox(height: OpenVtsSpacing.sm),
        UserLocalizationSelectCard(
          title: 'Units and Theme',
          subtitle: 'Distance units and app appearance preference.',
          icon: Icons.tune_rounded,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SegmentedField<UserDistanceUnit>(
                label: 'Distance Unit',
                child: UserLocalizationSegmentedControl<UserDistanceUnit>(
                  value: draft.units,
                  semanticsLabel: 'Distance unit selector',
                  segments: const [
                    UserLocalizationSegmentOption<UserDistanceUnit>(
                      value: UserDistanceUnit.km,
                      label: 'KM',
                    ),
                    UserLocalizationSegmentOption<UserDistanceUnit>(
                      value: UserDistanceUnit.miles,
                      label: 'MILES',
                    ),
                  ],
                  onChanged: (value) {
                    widget.controller.patchDraftLocalization(units: value);
                  },
                ),
              ),
              const SizedBox(height: OpenVtsSpacing.sm),
              _SegmentedField<UserThemeMode>(
                label: 'Theme',
                child: UserLocalizationSegmentedControl<UserThemeMode>(
                  value: draft.theme,
                  semanticsLabel: 'Theme selector',
                  segments: const [
                    UserLocalizationSegmentOption<UserThemeMode>(
                      value: UserThemeMode.system,
                      label: 'System',
                    ),
                    UserLocalizationSegmentOption<UserThemeMode>(
                      value: UserThemeMode.light,
                      label: 'Light',
                    ),
                    UserLocalizationSegmentOption<UserThemeMode>(
                      value: UserThemeMode.dark,
                      label: 'Dark',
                    ),
                  ],
                  onChanged: (value) {
                    widget.controller.patchDraftLocalization(theme: value);
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: OpenVtsSpacing.sm),
        UserMapDefaultsCard(
          latitudeController: _latitudeController,
          longitudeController: _longitudeController,
          mapZoomController: _mapZoomController,
          latitudeError: _latitudeError,
          longitudeError: _longitudeError,
          mapZoomError: _mapZoomError,
          activePresetLabel: _activePresetLabel(draft),
          onLatitudeChanged: _handleLatitudeChanged,
          onLongitudeChanged: _handleLongitudeChanged,
          onMapZoomChanged: _handleMapZoomChanged,
          onPresetSelected: _applyPreset,
        ),
      ],
    );
  }

  Future<void> _pickLanguage(
    List<UserLocalizationOption<String>> options,
  ) async {
    final selected = await showLocalizationOptionPicker<String>(
      context: context,
      title: 'Select Language',
      options: options,
      selectedValue: _draft.language,
      searchHintText: 'Search language',
    );

    if (selected == null || !mounted) {
      return;
    }

    widget.controller.patchDraftLocalization(language: selected);
  }

  Future<void> _pickDateFormat(
    List<UserLocalizationOption<String>> options,
  ) async {
    final selected = await showLocalizationOptionPicker<String>(
      context: context,
      title: 'Select Date Format',
      options: options,
      selectedValue: _draft.dateFormat,
      searchHintText: 'Search date format',
    );

    if (selected == null || !mounted) {
      return;
    }

    widget.controller.patchDraftLocalization(dateFormat: selected);
  }

  Future<void> _pickTimezone(
    List<UserLocalizationOption<String>> options,
  ) async {
    final selected = await showLocalizationOptionPicker<String>(
      context: context,
      title: 'Select Timezone',
      options: options,
      selectedValue: _draft.timezoneOffset,
      searchHintText: 'Search timezone',
    );

    if (selected == null || !mounted) {
      return;
    }

    widget.controller.patchDraftLocalization(timezoneOffset: selected);
  }

  void _handleLatitudeChanged(String raw) {
    if (_isHydrating) {
      return;
    }

    final value = raw.trim();
    if (value.isEmpty) {
      _setLatitudeError('Latitude is required.');
      return;
    }

    final parsed = double.tryParse(value);
    if (parsed == null) {
      _setLatitudeError('Enter a valid latitude.');
      return;
    }

    if (parsed < -90 || parsed > 90) {
      _setLatitudeError('Latitude must be between -90 and 90.');
      return;
    }

    _setLatitudeError(null);
    widget.controller.patchDraftLocalization(defaultLat: parsed);
  }

  void _handleLongitudeChanged(String raw) {
    if (_isHydrating) {
      return;
    }

    final value = raw.trim();
    if (value.isEmpty) {
      _setLongitudeError('Longitude is required.');
      return;
    }

    final parsed = double.tryParse(value);
    if (parsed == null) {
      _setLongitudeError('Enter a valid longitude.');
      return;
    }

    if (parsed < -180 || parsed > 180) {
      _setLongitudeError('Longitude must be between -180 and 180.');
      return;
    }

    _setLongitudeError(null);
    widget.controller.patchDraftLocalization(defaultLon: parsed);
  }

  void _handleMapZoomChanged(String raw) {
    if (_isHydrating) {
      return;
    }

    final value = raw.trim();
    if (value.isEmpty) {
      _setMapZoomError('Map zoom is required.');
      return;
    }

    final parsed = int.tryParse(value);
    if (parsed == null) {
      _setMapZoomError('Enter a valid zoom level.');
      return;
    }

    if (parsed < 1 || parsed > 22) {
      _setMapZoomError('Map zoom must be between 1 and 22.');
      return;
    }

    _setMapZoomError(null);
    widget.controller.patchDraftLocalization(mapZoom: parsed);
  }

  void _applyPreset(UserLocationPreset preset) {
    _isHydrating = true;
    _setText(_latitudeController, _formatDouble(preset.latitude));
    _setText(_longitudeController, _formatDouble(preset.longitude));
    _setText(_mapZoomController, preset.zoom.toString());
    _isHydrating = false;

    _clearMapErrors();
    widget.controller.patchDraftLocalization(
      defaultLat: preset.latitude,
      defaultLon: preset.longitude,
      mapZoom: preset.zoom,
    );
  }

  void _hydrateMapControllers(
    UserLocalizationSettings settings, {
    required bool clearErrors,
  }) {
    _isHydrating = true;
    _setText(_latitudeController, _formatDouble(settings.defaultLat));
    _setText(_longitudeController, _formatDouble(settings.defaultLon));
    _setText(_mapZoomController, settings.mapZoom.toString());
    _isHydrating = false;

    if (clearErrors) {
      _clearMapErrors();
    }
  }

  void _setText(TextEditingController controller, String value) {
    if (controller.text == value) {
      return;
    }

    controller.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
  }

  void _setLatitudeError(String? error) {
    if (_latitudeError == error) {
      return;
    }
    setState(() {
      _latitudeError = error;
    });
  }

  void _setLongitudeError(String? error) {
    if (_longitudeError == error) {
      return;
    }
    setState(() {
      _longitudeError = error;
    });
  }

  void _setMapZoomError(String? error) {
    if (_mapZoomError == error) {
      return;
    }
    setState(() {
      _mapZoomError = error;
    });
  }

  void _clearMapErrors() {
    if (_latitudeError == null &&
        _longitudeError == null &&
        _mapZoomError == null) {
      return;
    }

    setState(() {
      _latitudeError = null;
      _longitudeError = null;
      _mapZoomError = null;
    });
  }

  List<UserLocalizationOption<String>> _buildLanguageOptions(
    UserLocalizationSettings draft,
  ) {
    final options = widget.state.languages
        .map(
          (item) => UserLocalizationOption<String>(
            value: item.code,
            label: item.label,
            searchTokens: [item.code, item.label],
          ),
        )
        .toList(growable: true);

    if (options.isEmpty) {
      options.addAll(const [
        UserLocalizationOption<String>(value: 'en', label: 'English'),
        UserLocalizationOption<String>(value: 'ar', label: 'Arabic'),
        UserLocalizationOption<String>(value: 'hi', label: 'Hindi'),
      ]);
    }

    final current = draft.language.trim();
    if (current.isNotEmpty) {
      _prependIfMissing(
        options: options,
        value: current,
        label: current.toUpperCase(),
        matcher: (item) => item.value.toLowerCase(),
      );
    }

    return _distinctBy(options, (item) => item.value.toLowerCase());
  }

  List<UserLocalizationOption<String>> _buildDateFormatOptions(
    UserLocalizationSettings draft,
  ) {
    final options = widget.state.dateFormats
        .map(
          (item) => UserLocalizationOption<String>(
            value: item.value,
            label: item.label,
            searchTokens: [item.value, item.label],
          ),
        )
        .toList(growable: true);

    if (options.isEmpty) {
      options.addAll(const [
        UserLocalizationOption<String>(
          value: 'YYYY-MM-DD',
          label: 'YYYY-MM-DD',
        ),
        UserLocalizationOption<String>(
          value: 'DD/MM/YYYY',
          label: 'DD/MM/YYYY',
        ),
        UserLocalizationOption<String>(
          value: 'MM/DD/YYYY',
          label: 'MM/DD/YYYY',
        ),
      ]);
    }

    final current = draft.dateFormat.trim();
    if (current.isNotEmpty) {
      _prependIfMissing(
        options: options,
        value: current,
        label: current,
        matcher: (item) => item.value,
      );
    }

    return _distinctBy(options, (item) => item.value);
  }

  List<UserLocalizationOption<String>> _buildTimezoneOptions(
    UserLocalizationSettings draft,
  ) {
    final options = widget.state.timezones
        .map(
          (item) => UserLocalizationOption<String>(
            value: item,
            label: item,
            searchTokens: [item],
          ),
        )
        .toList(growable: true);

    if (options.isEmpty) {
      options.addAll(const [
        UserLocalizationOption<String>(value: '+00:00', label: '+00:00 UTC'),
        UserLocalizationOption<String>(value: '+05:30', label: '+05:30 IST'),
        UserLocalizationOption<String>(value: '-08:00', label: '-08:00 PST'),
      ]);
    }

    final current = draft.timezoneOffset.trim();
    if (current.isNotEmpty) {
      _prependIfMissing(
        options: options,
        value: current,
        label: current,
        matcher: (item) => item.value,
      );
    }

    return _distinctBy(options, (item) => item.value);
  }

  String _labelForValue({
    required List<UserLocalizationOption<String>> options,
    required String value,
    required String fallback,
  }) {
    for (final option in options) {
      if (option.value == value) {
        return option.label;
      }
    }

    final normalized = value.trim();
    if (normalized.isNotEmpty) {
      return normalized;
    }

    return fallback;
  }

  void _prependIfMissing({
    required List<UserLocalizationOption<String>> options,
    required String value,
    required String label,
    required String Function(UserLocalizationOption<String>) matcher,
  }) {
    final normalized = value.trim();
    if (normalized.isEmpty) {
      return;
    }

    final exists = options.any((item) => matcher(item) == normalized);
    if (exists) {
      return;
    }

    options.insert(
      0,
      UserLocalizationOption<String>(
        value: normalized,
        label: label,
        searchTokens: [normalized, label],
      ),
    );
  }

  List<UserLocalizationOption<String>> _distinctBy(
    List<UserLocalizationOption<String>> options,
    String Function(UserLocalizationOption<String>) keyOf,
  ) {
    final seen = <String>{};
    final distinct = <UserLocalizationOption<String>>[];

    for (final item in options) {
      final key = keyOf(item);
      if (seen.contains(key)) {
        continue;
      }
      seen.add(key);
      distinct.add(item);
    }

    return distinct;
  }

  String _formatDouble(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }

    var formatted = value.toStringAsFixed(6);
    formatted = formatted.replaceFirst(RegExp(r'0+$'), '');
    formatted = formatted.replaceFirst(RegExp(r'\.$'), '');
    return formatted;
  }

  String? _activePresetLabel(UserLocalizationSettings settings) {
    for (final preset in kUserLocationPresets) {
      final latMatches =
          (settings.defaultLat - preset.latitude).abs() <= 0.0001;
      final lonMatches =
          (settings.defaultLon - preset.longitude).abs() <= 0.0001;
      final zoomMatches = settings.mapZoom == preset.zoom;

      if (latMatches && lonMatches && zoomMatches) {
        return preset.label;
      }
    }

    return null;
  }
}

class _SegmentedField<T> extends StatelessWidget {
  const _SegmentedField({
    required this.label,
    required this.child,
  });

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: OpenVtsTypography.meta.copyWith(
            color: OpenVtsColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: OpenVtsSpacing.xxs),
        child,
      ],
    );
  }
}

class _ReferenceFallbackWarning extends StatelessWidget {
  const _ReferenceFallbackWarning({
    required this.message,
    required this.onRetry,
  });

  final String? message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final normalizedMessage = message?.trim();

    return OpenVtsCard(
      padding: const EdgeInsets.all(OpenVtsSpacing.sm),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: OpenVtsColors.warning.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(OpenVtsRadius.md),
          border: Border.all(
            color: OpenVtsColors.warning.withValues(alpha: 0.3),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            OpenVtsSpacing.sm,
            OpenVtsSpacing.xs,
            OpenVtsSpacing.xs,
            OpenVtsSpacing.xs,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 1),
                child: Icon(
                  Icons.warning_amber_rounded,
                  size: 16,
                  color: OpenVtsColors.warning,
                ),
              ),
              const SizedBox(width: OpenVtsSpacing.xs),
              Expanded(
                child: Text(
                  normalizedMessage == null || normalizedMessage.isEmpty
                      ? 'Reference options are unavailable right now. Fallback options are shown.'
                      : 'Reference options unavailable. $normalizedMessage',
                  style: OpenVtsTypography.meta.copyWith(
                    color: OpenVtsColors.warning,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              TextButton(
                onPressed: onRetry,
                style: TextButton.styleFrom(
                  minimumSize: const Size(0, 44),
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
