import 'package:flutter/material.dart';

import '../../../../../core/theme/open_vts_colors.dart';
import '../../../../../core/theme/open_vts_radius.dart';
import '../../../../../core/theme/open_vts_typography.dart';

/// Compact floating chip that surfaces the current geometry measurement
/// (length, perimeter + area, or radius) above the map.
///
/// Pure presentational widget — measurement strings are produced by the
/// geometry editor controller, not by this widget.
class UserLandmarkMeasurementChip extends StatelessWidget {
  const UserLandmarkMeasurementChip({
    super.key,
    required this.label,
    this.icon = Icons.straighten,
    this.tone = UserLandmarkMeasurementTone.neutral,
  });

  final String label;
  final IconData icon;
  final UserLandmarkMeasurementTone tone;

  @override
  Widget build(BuildContext context) {
    final foreground = switch (tone) {
      UserLandmarkMeasurementTone.neutral => OpenVtsColors.textPrimary,
      UserLandmarkMeasurementTone.warning => OpenVtsColors.warning,
      UserLandmarkMeasurementTone.error => OpenVtsColors.error,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: OpenVtsColors.surfaceElevated,
        borderRadius: BorderRadius.circular(OpenVtsRadius.pill),
        border: Border.all(color: OpenVtsColors.border),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: foreground),
          const SizedBox(width: 6),
          Text(
            label,
            style: OpenVtsTypography.meta.copyWith(
              color: foreground,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

enum UserLandmarkMeasurementTone { neutral, warning, error }
