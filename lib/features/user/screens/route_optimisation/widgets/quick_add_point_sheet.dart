import 'package:flutter/material.dart';

import '../../../../../core/theme/open_vts_colors.dart';
import '../../../../../core/theme/open_vts_radius.dart';
import '../../../../../core/theme/open_vts_spacing.dart';
import '../../../../../core/theme/open_vts_typography.dart';
import '../../../../../shared/widgets/open_vts_bottom_sheet.dart';
import '../../../models/user_route_optimisation_model.dart';

/// Submission payload from [showQuickAddPointSheet].
class QuickAddPointResult {
  const QuickAddPointResult({required this.name});
  final String name;
}

/// Compact sheet shown right after a map tap. Coordinates are read-only and
/// pre-filled from the tap location; the user can edit just the name before
/// confirming.
Future<QuickAddPointResult?> showQuickAddPointSheet(
  BuildContext context, {
  required double lat,
  required double lon,
  required int suggestedIndex,
}) {
  return OpenVtsBottomSheet.show<QuickAddPointResult>(
    context: context,
    title: 'Add map stop',
    initialChildSize: 0.42,
    minChildSize: 0.32,
    maxChildSize: 0.8,
    child: _QuickAddBody(
      lat: lat,
      lon: lon,
      defaultName: 'Waypoint $suggestedIndex',
    ),
  );
}

class _QuickAddBody extends StatefulWidget {
  const _QuickAddBody({
    required this.lat,
    required this.lon,
    required this.defaultName,
  });

  final double lat;
  final double lon;
  final String defaultName;

  @override
  State<_QuickAddBody> createState() => _QuickAddBodyState();
}

class _QuickAddBodyState extends State<_QuickAddBody> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.defaultName);

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(QuickAddPointResult(name: _name.text.trim()));
  }

  @override
  Widget build(BuildContext context) {
    final coordsValid = RouteOptimisationValidation.isLatValid(widget.lat) &&
        RouteOptimisationValidation.isLonValid(widget.lon);
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
          _CoordsRow(lat: widget.lat, lon: widget.lon, valid: coordsValid),
          const SizedBox(height: OpenVtsSpacing.sm),
          Text(
            'Name',
            style: OpenVtsTypography.meta.copyWith(
              color: OpenVtsColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          TextFormField(
            controller: _name,
            autofocus: true,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _submit(),
            style: OpenVtsTypography.label,
            validator: (v) {
              final t = (v ?? '').trim();
              if (t.length < 2) return 'Min 2 characters';
              return null;
            },
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
          const SizedBox(height: OpenVtsSpacing.md),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: OpenVtsColors.textPrimary,
                    side: const BorderSide(color: OpenVtsColors.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(OpenVtsRadius.button),
                    ),
                    minimumSize: const Size.fromHeight(40),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: OpenVtsSpacing.xs),
              Expanded(
                child: ElevatedButton(
                  onPressed: coordsValid ? _submit : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: OpenVtsColors.brandInk,
                    foregroundColor: OpenVtsColors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(OpenVtsRadius.button),
                    ),
                    minimumSize: const Size.fromHeight(40),
                  ),
                  child: const Text('Add'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CoordsRow extends StatelessWidget {
  const _CoordsRow({
    required this.lat,
    required this.lon,
    required this.valid,
  });

  final double lat;
  final double lon;
  final bool valid;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: OpenVtsSpacing.sm,
        vertical: OpenVtsSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: OpenVtsColors.surface,
        borderRadius: BorderRadius.circular(OpenVtsRadius.sm),
        border: Border.all(
          color: valid ? OpenVtsColors.border : OpenVtsColors.error,
        ),
      ),
      child: Row(
        children: [
          Icon(
            valid ? Icons.location_on_outlined : Icons.error_outline,
            size: 14,
            color: valid ? OpenVtsColors.textSecondary : OpenVtsColors.error,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              valid
                  ? '${lat.toStringAsFixed(6)}, ${lon.toStringAsFixed(6)}'
                  : 'Invalid coordinates from map tap.',
              style: OpenVtsTypography.label.copyWith(
                color: valid ? OpenVtsColors.textPrimary : OpenVtsColors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
