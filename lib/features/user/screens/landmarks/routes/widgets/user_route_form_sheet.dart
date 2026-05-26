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
import 'user_route_editor_screen.dart';

/// Bottom-sheet entry point for creating or editing a route. Metadata is
/// captured here; geometry is drawn in a dedicated full-screen editor. The
/// sheet never performs API calls directly — it dispatches through
/// `userRoutesControllerProvider`.
class UserRouteFormSheet {
  static Future<UserRouteLandmark?> show({
    required BuildContext context,
    UserRouteLandmark? route,
  }) {
    return OpenVtsBottomSheet.show<UserRouteLandmark>(
      context: context,
      title: route == null ? 'New route' : 'Edit route',
      initialChildSize: 0.78,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      draggableChildBuilder: (context, scrollController) {
        return _UserRouteFormBody(
          existing: route,
          scrollController: scrollController,
        );
      },
    );
  }
}

class _UserRouteFormBody extends ConsumerStatefulWidget {
  const _UserRouteFormBody({
    required this.existing,
    required this.scrollController,
  });

  final UserRouteLandmark? existing;
  final ScrollController scrollController;

  @override
  ConsumerState<_UserRouteFormBody> createState() => _UserRouteFormBodyState();
}

class _UserRouteFormBodyState extends ConsumerState<_UserRouteFormBody> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _description;
  late String _color;
  late bool _active;
  List<UserGeoPoint> _points = const <UserGeoPoint>[];
  double _toleranceM = 50;

  bool _submitting = false;
  String? _submitError;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _name = TextEditingController(text: existing?.name ?? '');
    _description = TextEditingController(text: existing?.description ?? '');
    _color = existing?.color.isNotEmpty == true
        ? existing!.color
        : kUserLandmarkPalette.first;
    _active = existing?.isActive ?? true;
    _points = existing?.geodata?.coordinates ?? const <UserGeoPoint>[];
    final t = existing?.toleranceMeters ?? existing?.geodata?.toleranceM;
    if (t != null && t > 0) _toleranceM = t;
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  Color get _routeColor {
    final cleaned = _color.replaceAll('#', '').trim();
    final parsed = int.tryParse('FF$cleaned', radix: 16);
    return parsed == null ? OpenVtsColors.brandInk : Color(parsed);
  }

  Future<void> _openEditor() async {
    final result = await Navigator.of(context).push<UserRouteEditorResult>(
      MaterialPageRoute<UserRouteEditorResult>(
        fullscreenDialog: true,
        builder: (_) => UserRouteEditorScreen(
          initialPoints: _points,
          initialToleranceM: _toleranceM,
          routeColor: _routeColor,
          title: widget.existing == null ? 'Draw route' : 'Edit route',
        ),
      ),
    );
    if (result == null || !mounted) return;
    setState(() {
      _points = result.points;
      _toleranceM = result.toleranceM;
      _submitError = null;
    });
  }

  Future<void> _submit() async {
    if (_submitting) return;
    if (!_formKey.currentState!.validate()) return;
    if (_points.length < 2) {
      setState(() => _submitError = 'Draw at least 2 route points.');
      return;
    }
    if (!_isValidHex(_color)) {
      setState(() => _submitError = 'Pick a valid color.');
      return;
    }
    if (_toleranceM < 1) {
      setState(
        () => _submitError = 'Tolerance must be at least 1 meter.',
      );
      return;
    }

    setState(() {
      _submitting = true;
      _submitError = null;
    });

    final controller = ref.read(userRoutesControllerProvider.notifier);
    try {
      final UserRouteLandmark saved;
      final geodata = UserLineGeoData(
        coordinates: _points,
        toleranceM: _toleranceM,
      );
      if (widget.existing == null) {
        saved = await controller.createRoute(
          CreateUserRouteRequest(
            name: _name.text.trim(),
            description: _description.text.trim().isEmpty
                ? null
                : _description.text.trim(),
            color: _color,
            isActive: _active,
            toleranceMeters: _toleranceM,
            geodata: geodata,
          ),
        );
      } else {
        saved = await controller.updateRoute(
          widget.existing!.id,
          UpdateUserRouteRequest(
            name: _name.text.trim(),
            description: _description.text.trim(),
            color: _color,
            isActive: _active,
            toleranceMeters: _toleranceM,
            geodata: geodata,
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

  bool _isValidHex(String value) {
    final v = value.replaceAll('#', '').trim();
    if (v.length != 6) return false;
    return int.tryParse(v, radix: 16) != null;
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        controller: widget.scrollController,
        padding: const EdgeInsets.fromLTRB(
          OpenVtsSpacing.md,
          OpenVtsSpacing.sm,
          OpenVtsSpacing.md,
          OpenVtsSpacing.lg,
        ),
        children: [
          const _SectionLabel('Details'),
          const SizedBox(height: OpenVtsSpacing.xs),
          const _FieldLabel('Name'),
          TextFormField(
            controller: _name,
            style: OpenVtsTypography.body,
            decoration: _denseDecoration(hint: 'e.g. Mumbai → Pune corridor'),
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
          const _SectionLabel('Geometry'),
          const SizedBox(height: OpenVtsSpacing.xs),
          _GeometryCard(
            points: _points,
            toleranceM: _toleranceM,
            onOpenEditor: _openEditor,
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
            label: widget.existing == null ? 'Create route' : 'Save changes',
            onPressed: _submit,
            isLoading: _submitting,
          ),
          const SizedBox(height: OpenVtsSpacing.xs),
          Center(
            child: TextButton(
              onPressed: _submitting ? null : () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: OpenVtsTypography.label.copyWith(
                  color: OpenVtsColors.textSecondary,
                ),
              ),
            ),
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
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: OpenVtsTypography.meta.copyWith(
        color: OpenVtsColors.textTertiary,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        label,
        style: OpenVtsTypography.meta.copyWith(
          color: OpenVtsColors.textSecondary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _GeometryCard extends StatelessWidget {
  const _GeometryCard({
    required this.points,
    required this.toleranceM,
    required this.onOpenEditor,
  });

  final List<UserGeoPoint> points;
  final double toleranceM;
  final VoidCallback onOpenEditor;

  @override
  Widget build(BuildContext context) {
    final hasGeometry = points.length >= 2;
    return Container(
      decoration: BoxDecoration(
        color: OpenVtsColors.surface,
        borderRadius: BorderRadius.circular(OpenVtsRadius.lg),
        border: Border.all(color: OpenVtsColors.border),
      ),
      padding: const EdgeInsets.all(OpenVtsSpacing.sm),
      child: Row(
        children: [
          const Icon(
            Icons.timeline,
            size: 18,
            color: OpenVtsColors.textSecondary,
          ),
          const SizedBox(width: OpenVtsSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasGeometry ? '${points.length} points' : 'No geometry yet',
                  style: OpenVtsTypography.label.copyWith(
                    color: OpenVtsColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  hasGeometry
                      ? 'Tolerance ±${toleranceM.toStringAsFixed(0)} m'
                      : 'Draw at least 2 points on the map.',
                  style: OpenVtsTypography.meta.copyWith(
                    color: OpenVtsColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onOpenEditor,
            child: Text(
              hasGeometry ? 'Edit on map' : 'Draw on map',
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
      decoration: BoxDecoration(
        color: OpenVtsColors.surface,
        borderRadius: BorderRadius.circular(OpenVtsRadius.lg),
        border: Border.all(color: OpenVtsColors.border),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: OpenVtsSpacing.sm,
        vertical: 4,
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
                  'Inactive routes stay archived but visible.',
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
