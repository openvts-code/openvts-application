import 'package:flutter/material.dart';

import '../../../../../core/theme/open_vts_colors.dart';
import '../../../../../core/theme/open_vts_radius.dart';
import '../../../../../core/theme/open_vts_typography.dart';

/// Visual role a marker plays in the planned route.
enum RouteMarkerRole { start, end, waypoint }

/// Compact numbered marker used on the Route Optimisation map.
///
/// Sized at 28×28 so it reads as a "premium pin" without dominating the
/// tilelayer. Colour is driven by [role]; selection nudges the border.
class RouteOptimisationMarker extends StatelessWidget {
  const RouteOptimisationMarker({
    required this.label,
    required this.role,
    required this.isSelected,
    this.onTap,
    this.onLongPress,
    super.key,
  });

  /// 1-based stop number displayed inside the dot.
  final int label;
  final RouteMarkerRole role;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  static const double dimension = 28;

  Color get _fill {
    switch (role) {
      case RouteMarkerRole.start:
        return OpenVtsColors.brandInk;
      case RouteMarkerRole.end:
        return OpenVtsColors.info;
      case RouteMarkerRole.waypoint:
        return OpenVtsColors.surfaceElevated;
    }
  }

  Color get _fg {
    switch (role) {
      case RouteMarkerRole.start:
      case RouteMarkerRole.end:
        return OpenVtsColors.white;
      case RouteMarkerRole.waypoint:
        return OpenVtsColors.textPrimary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = isSelected
        ? OpenVtsColors.brandInk
        : (role == RouteMarkerRole.waypoint ? OpenVtsColors.border : _fill);
    final borderWidth = isSelected ? 2.0 : 1.0;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        width: dimension,
        height: dimension,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: _fill,
          shape: BoxShape.circle,
          border: Border.all(color: borderColor, width: borderWidth),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 4,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Text(
          '$label',
          style: OpenVtsTypography.meta.copyWith(
            color: _fg,
            fontWeight: FontWeight.w700,
            height: 1,
          ),
        ),
      ),
    );
  }
}

/// Tiny pulsing halo placed behind the selected marker for emphasis without
/// resorting to "loud" colors. Used internally by the map panel.
class RouteOptimisationMarkerHalo extends StatelessWidget {
  const RouteOptimisationMarkerHalo({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: RouteOptimisationMarker.dimension + 10,
        height: RouteOptimisationMarker.dimension + 10,
        decoration: BoxDecoration(
          color: OpenVtsColors.brandInk.withValues(alpha: 0.08),
          shape: BoxShape.circle,
          border: Border.all(
            color: OpenVtsColors.brandInk.withValues(alpha: 0.35),
          ),
          borderRadius: BorderRadius.circular(OpenVtsRadius.pill),
        ),
      ),
    );
  }
}
