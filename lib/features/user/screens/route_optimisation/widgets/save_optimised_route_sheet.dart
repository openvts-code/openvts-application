import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/open_vts_colors.dart';
import '../../../../../core/theme/open_vts_radius.dart';
import '../../../../../core/theme/open_vts_spacing.dart';
import '../../../../../core/theme/open_vts_typography.dart';
import '../../../../../shared/widgets/open_vts_bottom_sheet.dart';
import '../../../../../shared/widgets/open_vts_button.dart';
import '../../../controllers/user_providers.dart';
import '../../landmarks/widgets/user_landmark_color_picker.dart';

/// Bottom sheet for persisting the current optimised route as a saved Route.
///
/// Delegates the actual API call to `userRouteOptimisationControllerProvider`
/// so this widget stays passive: it only collects form values, validates, and
/// invokes the controller. The screen's existing snackbar listener surfaces
/// success/error toasts. Returns `true` from the sheet on successful save.
Future<bool> showSaveOptimisedRouteSheet(BuildContext context) async {
  final res = await OpenVtsBottomSheet.show<bool>(
    context: context,
    title: 'Save as Route',
    initialChildSize: 0.78,
    minChildSize: 0.5,
    maxChildSize: 0.95,
    draggableChildBuilder: (context, scrollController) {
      return _SaveOptimisedRouteBody(scrollController: scrollController);
    },
  );
  return res ?? false;
}

class _SaveOptimisedRouteBody extends ConsumerStatefulWidget {
  const _SaveOptimisedRouteBody({required this.scrollController});

  final ScrollController scrollController;

  @override
  ConsumerState<_SaveOptimisedRouteBody> createState() =>
      _SaveOptimisedRouteBodyState();
}

class _SaveOptimisedRouteBodyState
    extends ConsumerState<_SaveOptimisedRouteBody> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _description;
  late final TextEditingController _tolerance;
  String _color = kUserLandmarkPalette.first;
  bool _active = true;
  bool _submitting = false;
  String? _localError;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController();
    _description = TextEditingController();
    _tolerance = TextEditingController(text: '100');
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _tolerance.dispose();
    super.dispose();
  }

  bool _isValidHex(String value) {
    final v = value.replaceAll('#', '').trim();
    if (v.length != 6) return false;
    return int.tryParse(v, radix: 16) != null;
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    final state = ref.read(userRouteOptimisationControllerProvider);
    if (state.result == null || state.result!.optimizedOrder.length < 2) {
      setState(() => _localError = 'Need at least 2 optimised points.');
      return;
    }
    if (!_isValidHex(_color)) {
      setState(() => _localError = 'Pick a valid color.');
      return;
    }
    final tol = int.tryParse(_tolerance.text.trim()) ?? -1;
    if (tol < 1) {
      setState(() => _localError = 'Tolerance must be at least 1 meter.');
      return;
    }

    setState(() {
      _submitting = true;
      _localError = null;
    });

    final ok = await ref
        .read(userRouteOptimisationControllerProvider.notifier)
        .saveOptimisedRoute(
          name: _name.text.trim(),
          description: _description.text.trim().isEmpty
              ? null
              : _description.text.trim(),
          color: _color,
          isActive: _active,
          toleranceMeters: tol,
        );

    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop(true);
    } else {
      // Controller wrote errorMessage; screen will toast it. Keep form data.
      setState(() => _submitting = false);
    }
  }

  InputDecoration _dense({String? hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: OpenVtsTypography.body.copyWith(
        color: OpenVtsColors.textTertiary,
      ),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: OpenVtsSpacing.sm,
        vertical: 10,
      ),
      filled: true,
      fillColor: OpenVtsColors.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(OpenVtsRadius.sm),
        borderSide: const BorderSide(color: OpenVtsColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(OpenVtsRadius.sm),
        borderSide: const BorderSide(color: OpenVtsColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(OpenVtsRadius.sm),
        borderSide: const BorderSide(color: OpenVtsColors.brandInk),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(OpenVtsRadius.sm),
        borderSide: const BorderSide(color: OpenVtsColors.error),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(userRouteOptimisationControllerProvider);
    final pointCount = state.result?.optimizedOrder.length ?? 0;
    final isSaving = state.isSavingRoute || _submitting;

    return Form(
      key: _formKey,
      child: ListView(
        controller: widget.scrollController,
        padding: const EdgeInsets.fromLTRB(
          OpenVtsSpacing.md,
          OpenVtsSpacing.xs,
          OpenVtsSpacing.md,
          OpenVtsSpacing.md,
        ),
        children: [
          _SummaryStrip(pointCount: pointCount, state: state),
          const SizedBox(height: OpenVtsSpacing.md),
          const _Label('Name'),
          TextFormField(
            controller: _name,
            style: OpenVtsTypography.body,
            decoration: _dense(hint: 'e.g. Warehouse → Hub run'),
            textInputAction: TextInputAction.next,
            validator: (v) {
              final t = v?.trim() ?? '';
              if (t.length < 2) return 'Enter at least 2 characters.';
              return null;
            },
          ),
          const SizedBox(height: OpenVtsSpacing.sm),
          const _Label('Description (optional)'),
          TextFormField(
            controller: _description,
            style: OpenVtsTypography.body,
            maxLines: 2,
            decoration: _dense(hint: 'Notes for your team'),
          ),
          const SizedBox(height: OpenVtsSpacing.md),
          UserLandmarkColorPicker(
            value: _color,
            onChanged: (c) => setState(() => _color = c),
          ),
          const SizedBox(height: OpenVtsSpacing.md),
          const _Label('Tolerance (meters)'),
          TextFormField(
            controller: _tolerance,
            style: OpenVtsTypography.body,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(5),
            ],
            decoration: _dense(hint: '100'),
            validator: (v) {
              final n = int.tryParse((v ?? '').trim());
              if (n == null || n < 1) return 'Enter a value ≥ 1.';
              return null;
            },
          ),
          const SizedBox(height: OpenVtsSpacing.sm),
          _ActiveRow(
            value: _active,
            onChanged: (v) => setState(() => _active = v),
          ),
          if (_localError != null) ...[
            const SizedBox(height: OpenVtsSpacing.sm),
            Text(
              _localError!,
              style: OpenVtsTypography.meta.copyWith(
                color: OpenVtsColors.error,
              ),
            ),
          ],
          const SizedBox(height: OpenVtsSpacing.lg),
          Row(
            children: [
              Expanded(
                child: OpenVtsButton(
                  label: 'Cancel',
                  variant: OpenVtsButtonVariant.secondary,
                  height: 42,
                  onPressed:
                      isSaving ? null : () => Navigator.of(context).pop(false),
                ),
              ),
              const SizedBox(width: OpenVtsSpacing.sm),
              Expanded(
                child: OpenVtsButton(
                  label: 'Save route',
                  height: 42,
                  isLoading: isSaving,
                  onPressed: isSaving ? null : _submit,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryStrip extends StatelessWidget {
  const _SummaryStrip({
    required this.pointCount,
    required this.state,
  });

  final int pointCount;
  final dynamic state;

  @override
  Widget build(BuildContext context) {
    final km = state.result == null
        ? 0.0
        : (state.result.optimizedDistanceKm as double);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: OpenVtsSpacing.sm,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: OpenVtsColors.surfaceElevated,
        borderRadius: BorderRadius.circular(OpenVtsRadius.sm),
        border: Border.all(color: OpenVtsColors.border),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.route_outlined,
            size: 16,
            color: OpenVtsColors.textSecondary,
          ),
          const SizedBox(width: OpenVtsSpacing.xs),
          Text(
            '$pointCount points · ${km.toStringAsFixed(2)} km',
            style: OpenVtsTypography.label.copyWith(
              color: OpenVtsColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: OpenVtsTypography.meta.copyWith(
          color: OpenVtsColors.textSecondary,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _ActiveRow extends StatelessWidget {
  const _ActiveRow({required this.value, required this.onChanged});
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(OpenVtsRadius.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: OpenVtsSpacing.xs,
          vertical: 6,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Active',
                    style: OpenVtsTypography.label.copyWith(
                      color: OpenVtsColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Show this route in maps and reports.',
                    style: OpenVtsTypography.meta.copyWith(
                      color: OpenVtsColors.textTertiary,
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
      ),
    );
  }
}
