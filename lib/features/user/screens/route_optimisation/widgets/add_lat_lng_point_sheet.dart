import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../core/theme/open_vts_colors.dart';
import '../../../../../core/theme/open_vts_radius.dart';
import '../../../../../core/theme/open_vts_spacing.dart';
import '../../../../../core/theme/open_vts_typography.dart';
import '../../../../../shared/widgets/open_vts_bottom_sheet.dart';
import '../../../models/user_route_optimisation_model.dart';

/// Submission payload from the manual lat/lng sheet.
class ManualLatLngResult {
  const ManualLatLngResult({
    required this.name,
    required this.lat,
    required this.lon,
  });
  final String name;
  final double lat;
  final double lon;
}

/// Compact bottom sheet for typing a single point's name + coordinates.
Future<ManualLatLngResult?> showAddLatLngPointSheet(BuildContext context) {
  return OpenVtsBottomSheet.show<ManualLatLngResult>(
    context: context,
    title: 'Enter lat / lng',
    initialChildSize: 0.55,
    minChildSize: 0.4,
    maxChildSize: 0.95,
    child: const _AddLatLngBody(),
  );
}

class _AddLatLngBody extends StatefulWidget {
  const _AddLatLngBody();

  @override
  State<_AddLatLngBody> createState() => _AddLatLngBodyState();
}

class _AddLatLngBodyState extends State<_AddLatLngBody> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _lat = TextEditingController();
  final _lon = TextEditingController();

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
      ManualLatLngResult(
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
          _Field(
            label: 'Name',
            controller: _name,
            hint: 'e.g. Warehouse A',
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
                  hint: '-90 to 90',
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
                  hint: '-180 to 180',
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
              child: const Text('Add point'),
            ),
          ),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.controller,
    this.hint,
    this.keyboardType,
    this.inputFormatters,
    this.validator,
  });

  final String label;
  final TextEditingController controller;
  final String? hint;
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
            hintText: hint,
            hintStyle: OpenVtsTypography.label.copyWith(
              color: OpenVtsColors.textTertiary,
            ),
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
