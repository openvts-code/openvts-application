import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../../core/theme/open_vts_colors.dart';
import '../../../../../../core/theme/open_vts_radius.dart';
import '../../../../../../core/theme/open_vts_spacing.dart';
import '../../../../../../core/theme/open_vts_typography.dart';
import '../../../../../../shared/widgets/open_vts_bottom_sheet.dart';
import '../../../../../../shared/widgets/open_vts_button.dart';
import '../../../../controllers/user_providers.dart';
import '../../../../models/user_landmark_model.dart';
import '../../widgets/user_landmark_color_picker.dart';
import 'user_geofence_editor_screen.dart';

/// Local form-only type that distinguishes Rectangle from Polygon. The
/// payload still maps Rectangle to backend `POLYGON` via the request DTO.
enum UserGeofenceFormType { circle, polygon, rectangle, line }

extension on UserGeofenceFormType {
  String get label {
    switch (this) {
      case UserGeofenceFormType.circle:
        return 'Circle';
      case UserGeofenceFormType.polygon:
        return 'Polygon';
      case UserGeofenceFormType.rectangle:
        return 'Rectangle';
      case UserGeofenceFormType.line:
        return 'Line';
    }
  }

  UserGeofenceEditorMode get editorMode {
    switch (this) {
      case UserGeofenceFormType.circle:
        return UserGeofenceEditorMode.circle;
      case UserGeofenceFormType.polygon:
        return UserGeofenceEditorMode.polygon;
      case UserGeofenceFormType.rectangle:
        return UserGeofenceEditorMode.rectangle;
      case UserGeofenceFormType.line:
        return UserGeofenceEditorMode.line;
    }
  }
}

UserGeofenceFormType _formTypeFromGeodata(UserGeofenceGeoData? geodata) {
  if (geodata is UserCircleGeoData) return UserGeofenceFormType.circle;
  if (geodata is UserLineGeoData) return UserGeofenceFormType.line;
  return UserGeofenceFormType.polygon;
}

/// Bottom-sheet entry point for creating or editing a geofence. Metadata is
/// captured here; geometry is drawn in a dedicated full-screen editor. The
/// sheet never performs API calls directly — it dispatches through
/// `userGeofencesControllerProvider`.
class UserGeofenceFormSheet {
  static Future<UserGeofence?> show({
    required BuildContext context,
    UserGeofence? geofence,
  }) {
    return OpenVtsBottomSheet.show<UserGeofence>(
      context: context,
      title: geofence == null ? 'New geofence' : 'Edit geofence',
      initialChildSize: 0.78,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      draggableChildBuilder: (context, scrollController) {
        return _UserGeofenceFormBody(
          existing: geofence,
          scrollController: scrollController,
        );
      },
    );
  }
}

class _UserGeofenceFormBody extends ConsumerStatefulWidget {
  const _UserGeofenceFormBody({
    required this.existing,
    required this.scrollController,
  });

  final UserGeofence? existing;
  final ScrollController scrollController;

  @override
  ConsumerState<_UserGeofenceFormBody> createState() =>
      _UserGeofenceFormBodyState();
}

class _UserGeofenceFormBodyState extends ConsumerState<_UserGeofenceFormBody> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _description;
  late UserGeofenceFormType _type;
  late String _color;
  late bool _active;
  UserGeofenceGeoData? _geodata;
  double? _toleranceM;
  String? _submitError;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _name = TextEditingController(text: existing?.name ?? '');
    _description = TextEditingController(text: existing?.description ?? '');
    _type = _formTypeFromGeodata(existing?.geodata);
    _color = existing?.color ?? kUserLandmarkPalette.first;
    _active = existing?.isActive ?? true;
    _geodata = existing?.geodata;
    _toleranceM = existing?.toleranceMeters ??
        (existing?.geodata is UserLineGeoData
            ? (existing!.geodata as UserLineGeoData).toleranceM
            : null);
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _openEditor() async {
    final result = await Navigator.of(context).push<UserGeofenceEditorResult>(
      MaterialPageRoute<UserGeofenceEditorResult>(
        fullscreenDialog: true,
        builder: (_) => UserGeofenceEditorScreen(
          initialMode: _type.editorMode,
          initialGeodata: _geodata,
          initialToleranceM: _toleranceM,
        ),
      ),
    );
    if (result == null || !mounted) return;
    setState(() {
      _geodata = result.geodata;
      if (_type == UserGeofenceFormType.line) {
        _toleranceM = result.toleranceM;
      }
      _submitError = null;
    });
  }

  void _onTypeChanged(UserGeofenceFormType next) {
    if (next == _type) return;
    setState(() {
      _type = next;
      // Reset geometry if the shape category changes — circle/polygon/line
      // are not cross-compatible. Rectangle and Polygon both produce a
      // POLYGON payload but the editor screen requires a matching mode, so
      // clear those too to avoid mismatched preview.
      _geodata = null;
      _submitError = null;
    });
  }

  Future<void> _submit() async {
    if (_submitting) return;
    if (!_formKey.currentState!.validate()) return;
    if (_geodata == null) {
      setState(() => _submitError = 'Draw the geometry before saving.');
      return;
    }

    setState(() {
      _submitting = true;
      _submitError = null;
    });

    final controller = ref.read(userGeofencesControllerProvider.notifier);
    try {
      final UserGeofence saved;
      if (widget.existing == null) {
        saved = await controller.createGeofence(
          CreateUserGeofenceRequest(
            name: _name.text.trim(),
            description: _description.text.trim().isEmpty
                ? null
                : _description.text.trim(),
            color: _color,
            isActive: _active,
            toleranceMeters:
                _type == UserGeofenceFormType.line ? _toleranceM : null,
            geodata: _geodata!,
          ),
        );
      } else {
        saved = await controller.updateGeofence(
          widget.existing!.id,
          UpdateUserGeofenceRequest(
            name: _name.text.trim(),
            description: _description.text.trim(),
            color: _color,
            isActive: _active,
            toleranceMeters:
                _type == UserGeofenceFormType.line ? _toleranceM : null,
            geodata: _geodata,
          ),
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop(saved);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitError = e.toString();
        _submitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    return Form(
      key: _formKey,
      child: ListView(
        controller: widget.scrollController,
        padding: EdgeInsets.fromLTRB(
          OpenVtsSpacing.md,
          OpenVtsSpacing.sm,
          OpenVtsSpacing.md,
          OpenVtsSpacing.lg + keyboard,
        ),
        children: [
          const _SectionLabel('Details'),
          const SizedBox(height: OpenVtsSpacing.xs),
          const _FieldLabel('Name'),
          TextFormField(
            controller: _name,
            style: OpenVtsTypography.body,
            decoration: _denseDecoration(hint: 'e.g. Warehouse perimeter'),
            validator: (value) {
              final v = value?.trim() ?? '';
              if (v.length < 2) return 'Enter at least 2 characters.';
              return null;
            },
          ),
          const SizedBox(height: OpenVtsSpacing.sm),
          const _FieldLabel('Description (optional)'),
          TextFormField(
            controller: _description,
            style: OpenVtsTypography.body,
            maxLines: 2,
            decoration: _denseDecoration(hint: 'Notes for your team'),
          ),
          const SizedBox(height: OpenVtsSpacing.md),
          const _SectionLabel('Shape'),
          const SizedBox(height: OpenVtsSpacing.xs),
          _TypeSegmented(value: _type, onChanged: _onTypeChanged),
          const SizedBox(height: OpenVtsSpacing.sm),
          _GeometrySummaryCard(
            type: _type,
            geodata: _geodata,
            toleranceM: _toleranceM,
            onDraw: _openEditor,
          ),
          const SizedBox(height: OpenVtsSpacing.md),
          const _SectionLabel('Appearance'),
          const SizedBox(height: OpenVtsSpacing.xs),
          UserLandmarkColorPicker(
            value: _color,
            onChanged: (hex) => setState(() => _color = hex),
          ),
          const SizedBox(height: OpenVtsSpacing.sm),
          _ActiveToggle(
            value: _active,
            onChanged: (v) => setState(() => _active = v),
          ),
          if (_submitError != null) ...[
            const SizedBox(height: OpenVtsSpacing.sm),
            Text(
              _submitError!,
              style: OpenVtsTypography.meta.copyWith(
                color: OpenVtsColors.error,
              ),
            ),
          ],
          const SizedBox(height: OpenVtsSpacing.md),
          OpenVtsButton(
            label: widget.existing == null ? 'Create geofence' : 'Save changes',
            onPressed: _submit,
            isLoading: _submitting,
          ),
        ],
      ),
    );
  }

  InputDecoration _denseDecoration({String? hint}) {
    return InputDecoration(
      isDense: true,
      hintText: hint,
      hintStyle: OpenVtsTypography.body.copyWith(
        color: OpenVtsColors.textTertiary,
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: OpenVtsSpacing.sm,
        vertical: 10,
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
        borderSide: const BorderSide(color: OpenVtsColors.brandInk, width: 1.4),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: OpenVtsTypography.meta.copyWith(
        color: OpenVtsColors.textSecondary,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: OpenVtsTypography.label.copyWith(
          color: OpenVtsColors.textPrimary,
        ),
      ),
    );
  }
}

class _TypeSegmented extends StatelessWidget {
  const _TypeSegmented({required this.value, required this.onChanged});

  final UserGeofenceFormType value;
  final ValueChanged<UserGeofenceFormType> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final t in UserGeofenceFormType.values)
          _TypePill(
            label: t.label,
            selected: value == t,
            onTap: () => onChanged(t),
          ),
      ],
    );
  }
}

class _TypePill extends StatelessWidget {
  const _TypePill({
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
      onTap: onTap,
      borderRadius: BorderRadius.circular(OpenVtsRadius.pill),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: OpenVtsSpacing.sm,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: selected ? OpenVtsColors.brandInk : OpenVtsColors.surface,
          borderRadius: BorderRadius.circular(OpenVtsRadius.pill),
          border: Border.all(
            color: selected ? OpenVtsColors.brandInk : OpenVtsColors.border,
          ),
        ),
        child: Text(
          label,
          style: OpenVtsTypography.meta.copyWith(
            color: selected ? OpenVtsColors.white : OpenVtsColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _GeometrySummaryCard extends StatelessWidget {
  const _GeometrySummaryCard({
    required this.type,
    required this.geodata,
    required this.toleranceM,
    required this.onDraw,
  });

  final UserGeofenceFormType type;
  final UserGeofenceGeoData? geodata;
  final double? toleranceM;
  final VoidCallback onDraw;

  @override
  Widget build(BuildContext context) {
    final summary = _summary(geodata, type, toleranceM);
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
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: OpenVtsColors.surfaceElevated,
              borderRadius: BorderRadius.circular(OpenVtsRadius.sm),
              border: Border.all(color: OpenVtsColors.border),
            ),
            child: Icon(
              _iconFor(type),
              size: 14,
              color: OpenVtsColors.textPrimary,
            ),
          ),
          const SizedBox(width: OpenVtsSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  geodata == null ? 'No geometry yet' : 'Geometry ready',
                  style: OpenVtsTypography.label.copyWith(
                    color: OpenVtsColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  summary,
                  style: OpenVtsTypography.meta.copyWith(
                    color: OpenVtsColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          TextButton.icon(
            style: TextButton.styleFrom(
              foregroundColor: OpenVtsColors.brandInk,
              minimumSize: const Size(0, 32),
              padding: const EdgeInsets.symmetric(
                horizontal: OpenVtsSpacing.sm,
              ),
            ),
            onPressed: onDraw,
            icon: const Icon(Icons.edit_location_alt_outlined, size: 14),
            label: Text(
              geodata == null ? 'Draw' : 'Edit',
              style: OpenVtsTypography.meta.copyWith(
                fontWeight: FontWeight.w700,
                color: OpenVtsColors.brandInk,
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconFor(UserGeofenceFormType t) {
    switch (t) {
      case UserGeofenceFormType.circle:
        return Icons.radio_button_unchecked;
      case UserGeofenceFormType.polygon:
        return Icons.hexagon_outlined;
      case UserGeofenceFormType.rectangle:
        return Icons.crop_square;
      case UserGeofenceFormType.line:
        return Icons.show_chart;
    }
  }

  String _summary(
    UserGeofenceGeoData? geo,
    UserGeofenceFormType type,
    double? toleranceM,
  ) {
    if (geo == null) {
      switch (type) {
        case UserGeofenceFormType.circle:
          return 'Tap "Draw" to set center & radius.';
        case UserGeofenceFormType.polygon:
          return 'Tap "Draw" to plot polygon vertices.';
        case UserGeofenceFormType.rectangle:
          return 'Tap "Draw" to set two opposite corners.';
        case UserGeofenceFormType.line:
          return 'Tap "Draw" to plot a route corridor.';
      }
    }
    if (geo is UserCircleGeoData) {
      return 'Circle • radius ${geo.radiusM.round()} m';
    }
    if (geo is UserPolygonGeoData) {
      return '${geo.coordinates.length} vertices';
    }
    if (geo is UserLineGeoData) {
      final tol = toleranceM ?? geo.toleranceM;
      final parts = <String>['${geo.coordinates.length} points'];
      if (tol != null && tol > 0) parts.add('tol ${tol.round()} m');
      return parts.join(' • ');
    }
    return 'Geometry set';
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
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  value
                      ? 'Events will trigger for this geofence.'
                      : 'Geofence is paused.',
                  style: OpenVtsTypography.meta.copyWith(
                    color: OpenVtsColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}
