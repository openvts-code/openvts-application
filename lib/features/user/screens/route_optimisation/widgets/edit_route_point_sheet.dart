import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../core/theme/open_vts_colors.dart';
import '../../../../../core/theme/open_vts_radius.dart';
import '../../../../../core/theme/open_vts_spacing.dart';
import '../../../../../core/theme/open_vts_typography.dart';
import '../../../../../shared/widgets/open_vts_bottom_sheet.dart';
import '../../../models/user_route_optimisation_model.dart';

/// Submission payload from [showEditRoutePointSheet].
class EditPointResult {
  const EditPointResult({
    required this.name,
    required this.lat,
    required this.lon,
  });
  final String name;
  final double lat;
  final double lon;
}

/// Sheet for editing an existing stop's name + coordinates.
///
/// The source ([RouteOptimisationPoint.source]) is shown as a read-only chip
/// because changing it would invalidate de-duplication keys upstream.
Future<EditPointResult?> showEditRoutePointSheet(
  BuildContext context, {
  required RouteOptimisationPoint point,
}) {
  return OpenVtsBottomSheet.show<EditPointResult>(
    context: context,
    title: 'Edit point',
    initialChildSize: 0.6,
    minChildSize: 0.45,
    maxChildSize: 0.95,
    child: _EditPointBody(point: point),
  );
}

class _EditPointBody extends StatefulWidget {
  const _EditPointBody({required this.point});
  final RouteOptimisationPoint point;

  @override
  State<_EditPointBody> createState() => _EditPointBodyState();
}

class _EditPointBodyState extends State<_EditPointBody> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.point.name);
  late final _lat =
      TextEditingController(text: widget.point.lat.toStringAsFixed(6));
  late final _lon =
      TextEditingController(text: widget.point.lon.toStringAsFixed(6));

  @override
  void dispose() {
    _name.dispose();
    _lat.dispose();
    _lon.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(
      EditPointResult(
        name: _name.text.trim(),
        lat: double.parse(_lat.text.trim()),
        lon: double.parse(_lon.text.trim()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          OpenVtsSpacing.md,
          OpenVtsSpacing.xs,
          OpenVtsSpacing.md,
          OpenVtsSpacing.md,
        ),
        children: [
          _SourceRow(source: widget.point.source),
          const SizedBox(height: OpenVtsSpacing.sm),
          _Field(
            label: 'Name',
            controller: _name,
            validator: (v) {
              final t = (v ?? '').trim();
              if (t.length < 2) return 'Min 2 characters';
              return null;
            },
          ),
          const SizedBox(height: OpenVtsSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _Field(
                  label: 'Latitude',
                  controller: _lat,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9\.\-]')),
                  ],
                  validator: (v) {
                    final p = double.tryParse((v ?? '').trim());
                    if (p == null || p.isNaN || p.isInfinite) {
                      return 'Required';
                    }
                    if (!RouteOptimisationValidation.isLatValid(p)) {
                      return 'Out of range';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: OpenVtsSpacing.sm),
              Expanded(
                child: _Field(
                  label: 'Longitude',
                  controller: _lon,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9\.\-]')),
                  ],
                  validator: (v) {
                    final p = double.tryParse((v ?? '').trim());
                    if (p == null || p.isNaN || p.isInfinite) {
                      return 'Required';
                    }
                    if (!RouteOptimisationValidation.isLonValid(p)) {
                      return 'Out of range';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: OpenVtsSpacing.md),
          SizedBox(
            height: 42,
            child: ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: OpenVtsColors.brandInk,
                foregroundColor: OpenVtsColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(OpenVtsRadius.button),
                ),
              ),
              child: const Text('Save changes'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SourceRow extends StatelessWidget {
  const _SourceRow({required this.source});

  final RouteOptimisationPointSource source;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          'Source',
          style: OpenVtsTypography.meta.copyWith(
            color: OpenVtsColors.textSecondary,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: OpenVtsSpacing.xs,
            vertical: 4,
          ),
          decoration: BoxDecoration(
            color: OpenVtsColors.surface,
            borderRadius: BorderRadius.circular(OpenVtsRadius.sm),
            border: Border.all(color: OpenVtsColors.border),
          ),
          child: Text(
            source.label,
            style: OpenVtsTypography.meta.copyWith(
              color: OpenVtsColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.controller,
    this.keyboardType,
    this.inputFormatters,
    this.validator,
  });

  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: OpenVtsTypography.meta.copyWith(
            color: OpenVtsColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          validator: validator,
          style: OpenVtsTypography.label,
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: OpenVtsSpacing.sm,
              vertical: OpenVtsSpacing.xs,
            ),
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
          ),
        ),
      ],
    );
  }
}
