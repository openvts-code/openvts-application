import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../../../../core/theme/open_vts_colors.dart';
import '../../../../../../core/theme/open_vts_radius.dart';
import '../../../../../../core/theme/open_vts_spacing.dart';
import '../../../../../../core/theme/open_vts_typography.dart';
import '../../../../../../shared/widgets/open_vts_bottom_sheet.dart';
import '../../../../../../shared/widgets/open_vts_button.dart';
import '../../../../controllers/user_providers.dart';
import '../../../../models/user_landmark_model.dart';
import '../../widgets/user_landmark_color_picker.dart';
import '../user_poi_constants.dart';
import 'user_poi_category_picker.dart';
import 'user_poi_icon_picker.dart';
import 'user_poi_picker_map.dart';

/// Bottom-sheet entry point for creating or editing a POI. Widgets are dumb;
/// all API work is dispatched through `userPoisControllerProvider`.
class UserPoiFormSheet {
  static Future<UserPoi?> show({
    required BuildContext context,
    UserPoi? poi,
  }) {
    return OpenVtsBottomSheet.show<UserPoi>(
      context: context,
      title: poi == null ? 'New POI' : 'Edit POI',
      initialChildSize: 0.82,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      draggableChildBuilder: (context, scrollController) {
        return _UserPoiFormBody(
          existing: poi,
          scrollController: scrollController,
        );
      },
    );
  }
}

class _UserPoiFormBody extends ConsumerStatefulWidget {
  const _UserPoiFormBody({
    required this.existing,
    required this.scrollController,
  });

  final UserPoi? existing;
  final ScrollController scrollController;

  @override
  ConsumerState<_UserPoiFormBody> createState() => _UserPoiFormBodyState();
}

class _UserPoiFormBodyState extends ConsumerState<_UserPoiFormBody> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _description;
  late final TextEditingController _tolerance;

  late String _category;
  late String _iconSlug;
  late String _color;
  late bool _isActive;
  UserGeoPoint? _coordinates;
  double? _toleranceMeters;

  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _name = TextEditingController(text: existing?.name ?? '');
    _description = TextEditingController(text: existing?.description ?? '');
    _category = existing?.category ?? '';
    _iconSlug = (existing?.iconSlug.isNotEmpty ?? false)
        ? existing!.iconSlug
        : kDefaultUserPoiIconSlug;
    _color = (existing?.color.isNotEmpty ?? false)
        ? existing!.color
        : kUserLandmarkPalette.first;
    _isActive = existing?.isActive ?? true;
    _coordinates = existing?.coordinates;
    _toleranceMeters = existing?.toleranceMeters;
    _tolerance = TextEditingController(
      text: _toleranceMeters == null || _toleranceMeters == 0
          ? ''
          : _toleranceMeters!.toStringAsFixed(0),
    );
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _tolerance.dispose();
    super.dispose();
  }

  Future<void> _pickLocation() async {
    final initial = _coordinates == null
        ? null
        : LatLng(_coordinates!.lat, _coordinates!.lon);
    final result = await Navigator.of(context).push<UserPoiPickerResult>(
      MaterialPageRoute<UserPoiPickerResult>(
        fullscreenDialog: true,
        builder: (_) => UserPoiPickerMap(
          initialPoint: initial,
          initialToleranceM: _toleranceMeters,
          title: widget.existing == null ? 'Place POI' : 'Move POI',
        ),
      ),
    );
    if (!mounted || result == null) return;
    setState(() {
      _coordinates = result.coordinates;
      if (result.toleranceMeters != null) {
        _toleranceMeters = result.toleranceMeters;
        _tolerance.text = result.toleranceMeters!.toStringAsFixed(0);
      }
    });
  }

  String? _validateName(String? value) {
    final v = (value ?? '').trim();
    if (v.length < 2) return 'Name must be at least 2 characters';
    return null;
  }

  bool _isValidHex(String value) {
    final cleaned = value.replaceAll('#', '').trim();
    if (cleaned.length != 6) return false;
    return int.tryParse(cleaned, radix: 16) != null;
  }

  Future<void> _submit() async {
    setState(() => _error = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_category.trim().isEmpty) {
      setState(() => _error = 'Category is required.');
      return;
    }
    if (!_isValidHex(_color)) {
      setState(() => _error = 'Pick a valid color.');
      return;
    }
    if (_coordinates == null) {
      setState(() => _error = 'Tap "Pick on map" to set coordinates.');
      return;
    }
    final coords = _coordinates!;
    if (coords.lat < -90 || coords.lat > 90) {
      setState(() => _error = 'Latitude must be between -90 and 90.');
      return;
    }
    if (coords.lon < -180 || coords.lon > 180) {
      setState(() => _error = 'Longitude must be between -180 and 180.');
      return;
    }
    final tolText = _tolerance.text.trim();
    double? tol;
    if (tolText.isNotEmpty) {
      final parsed = double.tryParse(tolText);
      if (parsed == null || parsed < 0) {
        setState(() => _error = 'Tolerance must be 0 or greater.');
        return;
      }
      tol = parsed == 0 ? null : parsed;
    }

    setState(() => _submitting = true);
    final controller = ref.read(userPoisControllerProvider.notifier);
    try {
      UserPoi saved;
      final descTrim = _description.text.trim();
      if (widget.existing == null) {
        saved = await controller.createPoi(
          CreateUserPoiRequest(
            name: _name.text.trim(),
            description: descTrim.isEmpty ? null : descTrim,
            category: _category.trim(),
            color: _color,
            iconSlug: _iconSlug,
            toleranceMeters: tol,
            isActive: _isActive,
            coordinates: coords,
          ),
        );
      } else {
        saved = await controller.updatePoi(
          widget.existing!.id,
          UpdateUserPoiRequest(
            name: _name.text.trim(),
            description: descTrim,
            category: _category.trim(),
            color: _color,
            iconSlug: _iconSlug,
            toleranceMeters: tol,
            isActive: _isActive,
            coordinates: coords,
          ),
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop(saved);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = error.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    return Form(
      key: _formKey,
      child: ListView(
        controller: widget.scrollController,
        padding: EdgeInsets.fromLTRB(
          OpenVtsSpacing.md,
          OpenVtsSpacing.md,
          OpenVtsSpacing.md,
          OpenVtsSpacing.md + viewInsets,
        ),
        children: [
          _Field(
            label: 'Name',
            required: true,
            child: TextFormField(
              controller: _name,
              style: OpenVtsTypography.body,
              textInputAction: TextInputAction.next,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              validator: _validateName,
              decoration: _inputDecoration(hint: 'e.g. Pune warehouse'),
            ),
          ),
          const SizedBox(height: OpenVtsSpacing.md),
          _Field(
            label: 'Description',
            child: TextFormField(
              controller: _description,
              style: OpenVtsTypography.body,
              minLines: 2,
              maxLines: 4,
              decoration: _inputDecoration(
                hint: 'Optional notes for ops staff',
              ),
            ),
          ),
          const SizedBox(height: OpenVtsSpacing.md),
          UserPoiCategoryPicker(
            value: _category,
            onChanged: (value) => setState(() => _category = value),
          ),
          const SizedBox(height: OpenVtsSpacing.md),
          UserPoiIconPicker(
            value: _iconSlug,
            onChanged: (slug) => setState(() => _iconSlug = slug),
          ),
          const SizedBox(height: OpenVtsSpacing.md),
          UserLandmarkColorPicker(
            value: _color,
            onChanged: (value) => setState(() => _color = value),
          ),
          const SizedBox(height: OpenVtsSpacing.md),
          _Field(
            label: 'Tolerance (meters)',
            child: TextFormField(
              controller: _tolerance,
              style: OpenVtsTypography.numeric,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              decoration: _inputDecoration(
                hint: 'Optional radius for proximity alerts',
                suffix: 'm',
              ),
            ),
          ),
          const SizedBox(height: OpenVtsSpacing.md),
          _LocationCard(
            coordinates: _coordinates,
            tolerance: _toleranceMeters,
            onPick: _pickLocation,
          ),
          const SizedBox(height: OpenVtsSpacing.md),
          _ActiveToggle(
            value: _isActive,
            onChanged: (v) => setState(() => _isActive = v),
          ),
          if (_error != null) ...[
            const SizedBox(height: OpenVtsSpacing.sm),
            Text(
              _error!,
              style: OpenVtsTypography.meta.copyWith(
                color: OpenVtsColors.error,
              ),
            ),
          ],
          const SizedBox(height: OpenVtsSpacing.md),
          OpenVtsButton(
            label: widget.existing == null ? 'Create POI' : 'Save changes',
            onPressed: _submitting ? null : _submit,
            isLoading: _submitting,
          ),
          const SizedBox(height: OpenVtsSpacing.sm),
          TextButton(
            onPressed: _submitting ? null : () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor: OpenVtsColors.textSecondary,
            ),
            child: Text(
              'Cancel',
              style: OpenVtsTypography.label.copyWith(
                color: OpenVtsColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({String? hint, String? suffix}) {
    return InputDecoration(
      isDense: true,
      hintText: hint,
      suffixText: suffix,
      hintStyle: OpenVtsTypography.body.copyWith(
        color: OpenVtsColors.textTertiary,
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: OpenVtsSpacing.sm,
        vertical: 12,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(OpenVtsRadius.button),
        borderSide: const BorderSide(color: OpenVtsColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(OpenVtsRadius.button),
        borderSide: const BorderSide(color: OpenVtsColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(OpenVtsRadius.button),
        borderSide: const BorderSide(
          color: OpenVtsColors.brandInk,
          width: 1.4,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(OpenVtsRadius.button),
        borderSide: const BorderSide(color: OpenVtsColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(OpenVtsRadius.button),
        borderSide: const BorderSide(
          color: OpenVtsColors.error,
          width: 1.4,
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.child,
    this.required = false,
  });

  final String label;
  final Widget child;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: OpenVtsTypography.label.copyWith(
                color: OpenVtsColors.textPrimary,
              ),
            ),
            if (required) ...[
              const SizedBox(width: 4),
              Text(
                '*',
                style: OpenVtsTypography.label.copyWith(
                  color: OpenVtsColors.error,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

class _LocationCard extends StatelessWidget {
  const _LocationCard({
    required this.coordinates,
    required this.tolerance,
    required this.onPick,
  });

  final UserGeoPoint? coordinates;
  final double? tolerance;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(OpenVtsSpacing.sm),
      decoration: BoxDecoration(
        color: OpenVtsColors.surface,
        borderRadius: BorderRadius.circular(OpenVtsRadius.md),
        border: Border.all(color: OpenVtsColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: OpenVtsColors.brandInk.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(OpenVtsRadius.sm),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.place_outlined,
              size: 18,
              color: OpenVtsColors.brandInk,
            ),
          ),
          const SizedBox(width: OpenVtsSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Location',
                  style: OpenVtsTypography.label.copyWith(
                    color: OpenVtsColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  coordinates == null
                      ? 'Not set'
                      : '${coordinates!.lat.toStringAsFixed(6)}, '
                          '${coordinates!.lon.toStringAsFixed(6)}'
                          '${tolerance != null && tolerance! > 0 ? ' • ±${tolerance!.toStringAsFixed(0)} m' : ''}',
                  style: OpenVtsTypography.meta.copyWith(
                    color: coordinates == null
                        ? OpenVtsColors.textTertiary
                        : OpenVtsColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onPick,
            style: TextButton.styleFrom(
              foregroundColor: OpenVtsColors.brandInk,
              padding: const EdgeInsets.symmetric(
                horizontal: OpenVtsSpacing.sm,
              ),
            ),
            child: Text(
              coordinates == null ? 'Pick on map' : 'Edit on map',
              style: OpenVtsTypography.label.copyWith(
                color: OpenVtsColors.brandInk,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActiveToggle extends StatelessWidget {
  const _ActiveToggle({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: OpenVtsSpacing.sm,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: OpenVtsColors.surface,
        borderRadius: BorderRadius.circular(OpenVtsRadius.md),
        border: Border.all(color: OpenVtsColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Active',
                  style: OpenVtsTypography.label.copyWith(
                    color: OpenVtsColors.textPrimary,
                  ),
                ),
                Text(
                  value
                      ? 'Visible on live map and proximity alerts.'
                      : 'Hidden from alerts; stays in the list.',
                  style: OpenVtsTypography.meta.copyWith(
                    color: OpenVtsColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeThumbColor: OpenVtsColors.brandInk,
          ),
        ],
      ),
    );
  }
}
