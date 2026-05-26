import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import '../../../../../../core/theme/open_vts_colors.dart';
import '../../../../../../core/theme/open_vts_radius.dart';
import '../../../../../../core/theme/open_vts_spacing.dart';
import '../../../../../../core/theme/open_vts_typography.dart';
import '../../../../models/user_landmark_model.dart';
import '../../widgets/user_landmark_map_view.dart';

/// Compact preview map for the geofence list screen. Wraps the shared
/// [UserLandmarkMapView] in a bordered, fixed-height surface with no map
/// interactions beyond pan/zoom and optional tap-to-select.
class UserGeofencePreviewMap extends StatelessWidget {
  const UserGeofencePreviewMap({
    super.key,
    required this.geofences,
    this.selectedGeofenceId,
    this.onSelect,
    this.height = 220,
    this.showEmpty = true,
  });

  final List<UserGeofence> geofences;
  final String? selectedGeofenceId;
  final ValueChanged<UserGeofence>? onSelect;
  final double height;
  final bool showEmpty;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(OpenVtsRadius.lg),
      child: Container(
        height: height,
        decoration: BoxDecoration(
          border: Border.all(color: OpenVtsColors.border),
          borderRadius: BorderRadius.circular(OpenVtsRadius.lg),
        ),
        child: geofences.isEmpty && showEmpty
            ? _EmptyMap(height: height)
            : UserLandmarkMapView(
                geofences: geofences,
                selectedGeofenceId: selectedGeofenceId,
                onSelectGeofence: onSelect,
                interactionFlags:
                    InteractiveFlag.drag | InteractiveFlag.pinchZoom,
              ),
      ),
    );
  }
}

class _EmptyMap extends StatelessWidget {
  const _EmptyMap({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: OpenVtsColors.surface,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(OpenVtsSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.map_outlined,
                size: 22,
                color: OpenVtsColors.textTertiary,
              ),
              const SizedBox(height: 6),
              Text(
                'No geofences to preview',
                style: OpenVtsTypography.meta.copyWith(
                  color: OpenVtsColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
