import 'package:flutter/material.dart';

import '../../../../../../core/theme/open_vts_colors.dart';
import '../../../../../../core/theme/open_vts_radius.dart';
import '../../../../models/user_landmark_model.dart';
import '../../widgets/user_landmark_map_view.dart';

/// Bordered, rounded map panel that previews route polylines.
///
/// This is a pure presentation wrapper around [UserLandmarkMapView] scoped to
/// routes-only. The map view itself owns rendering, selection emphasis and
/// inactive muting; this widget only frames it and forwards selection.
class UserRoutePreviewMap extends StatelessWidget {
  const UserRoutePreviewMap({
    super.key,
    required this.routes,
    required this.selectedRouteId,
    required this.onSelectRoute,
    this.height,
  });

  final List<UserRouteLandmark> routes;
  final String? selectedRouteId;
  final ValueChanged<UserRouteLandmark>? onSelectRoute;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final map = ClipRRect(
      borderRadius: BorderRadius.circular(OpenVtsRadius.lg),
      child: UserLandmarkMapView(
        routes: routes,
        selectedRouteId: selectedRouteId,
        onSelectRoute: onSelectRoute,
      ),
    );

    final framed = DecoratedBox(
      decoration: BoxDecoration(
        color: OpenVtsColors.surfaceElevated,
        borderRadius: BorderRadius.circular(OpenVtsRadius.lg),
        border: Border.all(color: OpenVtsColors.border),
      ),
      child: map,
    );

    if (height != null) {
      return SizedBox(height: height, child: framed);
    }
    return framed;
  }
}
