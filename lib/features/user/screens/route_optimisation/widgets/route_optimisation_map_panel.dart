import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../../../core/theme/open_vts_colors.dart';
import '../../../../../core/theme/open_vts_radius.dart';
import '../../../../../core/theme/open_vts_spacing.dart';
import '../../../../../core/theme/open_vts_typography.dart';
import '../../../controllers/user_providers.dart';
import '../../../controllers/user_route_optimisation_controller.dart';
import '../../../models/user_route_optimisation_model.dart';
import '../../../models/user_route_optimisation_state.dart';
import 'quick_add_point_sheet.dart';
import 'route_optimisation_map_controls.dart';
import 'route_optimisation_map_legend.dart';
import 'route_optimisation_marker.dart';

/// Tile config mirrors Landmark Studio (Google Road) for visual continuity.
const String _kRouteTileUrl =
    'https://{s}.google.com/vt/lyrs=m&x={x}&y={y}&z={z}';
const List<String> _kRouteTileSubdomains = <String>[
  'mt0',
  'mt1',
  'mt2',
  'mt3',
];

/// Fallback when there are zero points to anchor the camera.
const LatLng _kRouteFallbackCenter = LatLng(20.5937, 78.9629); // IN centroid

/// Self-contained map pane for the Route Optimisation screen.
///
/// Responsibilities:
/// * Render numbered markers (start / end / waypoint visual roles).
/// * Render current-order polyline (and optimised polyline when a result
///   exists, using OSRM road geometry if available, else straight legs).
/// * Auto-fit on point set changes; auto-fit optimised route on new result.
/// * Honor [UserRouteOptimisationState.clickToAddMode] with a banner +
///   QuickAdd sheet flow.
///
/// The widget only invokes controller callbacks. No direct API calls.
class RouteOptimisationMapPanel extends ConsumerStatefulWidget {
  const RouteOptimisationMapPanel({
    required this.onEditPoint,
    super.key,
  });

  /// Invoked when the user long-presses a marker. The hosting screen is
  /// responsible for opening the edit sheet (it already wires the sheet
  /// across panels).
  final void Function(int index, RouteOptimisationPoint point) onEditPoint;

  @override
  ConsumerState<RouteOptimisationMapPanel> createState() =>
      _RouteOptimisationMapPanelState();
}

class _RouteOptimisationMapPanelState
    extends ConsumerState<RouteOptimisationMapPanel> {
  final MapController _map = MapController();

  String _pointsSig = '';
  String _resultSig = '';
  bool _mapReady = false;

  void _onMapReady() {
    _mapReady = true;
    // Initial fit using current state (read once, no listen).
    final state = ref.read(userRouteOptimisationControllerProvider);
    if (state.points.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _fitAll(state));
    }
  }

  String _signaturePoints(UserRouteOptimisationState s) =>
      s.points.map((p) => '${p.id}|${p.lat}|${p.lon}').join(';');

  String _signatureResult(UserRouteOptimisationState s) {
    final r = s.result;
    if (r == null) return '';
    return '${r.optimizedOrder.join(',')}|'
        '${s.roadGeometry?.fullPolyline.length ?? 0}';
  }

  void _maybeAutoFit(UserRouteOptimisationState s) {
    if (!_mapReady) return;
    final ps = _signaturePoints(s);
    final rs = _signatureResult(s);
    if (ps != _pointsSig) {
      _pointsSig = ps;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _fitAll(s);
      });
    }
    if (rs != _resultSig && rs.isNotEmpty) {
      _resultSig = rs;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _fitOptimised(s);
      });
    } else if (rs.isEmpty) {
      _resultSig = '';
    }
  }

  void _fitAll(UserRouteOptimisationState s) {
    final pts = [for (final p in s.points) p.toLatLng()];
    _fitToPoints(pts);
  }

  void _fitOptimised(UserRouteOptimisationState s) {
    final road = s.roadGeometry;
    final pts = <LatLng>[];
    if (road != null && road.isNotEmpty) {
      pts.addAll(road.fullPolyline);
    } else {
      pts.addAll(s.optimizedOrderedPoints.map((p) => p.toLatLng()));
    }
    _fitToPoints(pts);
  }

  void _fitToPoints(List<LatLng> pts) {
    if (pts.isEmpty) return;
    if (pts.length == 1) {
      _map.move(pts.first, math.max(_map.camera.zoom, 14));
      return;
    }
    _map.fitCamera(
      CameraFit.bounds(
        bounds: LatLngBounds.fromPoints(pts),
        padding: const EdgeInsets.all(48),
        maxZoom: 17,
      ),
    );
  }

  Future<void> _handleMapTap(
    TapPosition _,
    LatLng point,
    UserRouteOptimisationController controller,
    UserRouteOptimisationState state,
  ) async {
    if (!state.clickToAddMode) return;
    final suggested = state.points.length + 1;
    final r = await showQuickAddPointSheet(
      context,
      lat: point.latitude,
      lon: point.longitude,
      suggestedIndex: suggested,
    );
    // Always exit the mode after a tap so the user doesn't keep dropping pins
    // accidentally; they can re-enter via the panel/screen action.
    controller.setClickToAddMode(false);
    if (r != null) {
      controller.addMapPoint(
        lat: point.latitude,
        lon: point.longitude,
        name: r.name,
      );
    }
  }

  // --- Polyline assembly -------------------------------------------------

  List<Polyline> _buildPolylines(UserRouteOptimisationState s) {
    final out = <Polyline>[];
    final hasResult = s.hasResult;

    // 1) Current order — primary line if no result; muted otherwise.
    final currentPts = [for (final p in s.points) p.toLatLng()];
    if (s.roundTrip && currentPts.length >= 2) {
      currentPts.add(currentPts.first);
    }
    if (currentPts.length >= 2) {
      out.add(
        Polyline(
          points: currentPts,
          strokeWidth: hasResult ? 2.0 : 3.0,
          color: hasResult
              ? OpenVtsColors.textTertiary.withValues(alpha: 0.55)
              : OpenVtsColors.brandInk,
        ),
      );
    }

    // 2) Optimised order — only when result exists.
    if (hasResult) {
      final road = s.roadGeometry;
      final optimisedPts = <LatLng>[];
      if (road != null && road.isNotEmpty) {
        optimisedPts.addAll(road.fullPolyline);
      } else {
        optimisedPts.addAll(s.optimizedOrderedPoints.map((p) => p.toLatLng()));
        if (s.roundTrip && optimisedPts.length >= 2) {
          optimisedPts.add(optimisedPts.first);
        }
      }
      if (optimisedPts.length >= 2) {
        out.add(
          Polyline(
            points: optimisedPts,
            strokeWidth: 3.5,
            color: OpenVtsColors.brandInk,
          ),
        );
      }
    }

    return out;
  }

  // --- Marker assembly ---------------------------------------------------

  List<Marker> _buildMarkers(
    UserRouteOptimisationState s,
    UserRouteOptimisationController controller,
  ) {
    final markers = <Marker>[];
    final effectiveEnd = s.effectiveEndIndex;
    final selected = s.selectedPointIndex;

    for (var i = 0; i < s.points.length; i++) {
      final p = s.points[i];
      final isStart = i == s.startIndex;
      final isEnd = !s.roundTrip && i == effectiveEnd && i != s.startIndex;
      final role = isStart
          ? RouteMarkerRole.start
          : isEnd
              ? RouteMarkerRole.end
              : RouteMarkerRole.waypoint;
      final isSel = selected == i;

      markers.add(
        Marker(
          point: p.toLatLng(),
          width: 44,
          height: 44,
          alignment: Alignment.center,
          child: Center(
            child: RouteOptimisationMarker(
              label: i + 1,
              role: role,
              isSelected: isSel,
              onTap: () => controller.setSelectedPointIndex(
                isSel ? null : i,
              ),
              onLongPress: () => widget.onEditPoint(i, p),
            ),
          ),
        ),
      );
    }
    return markers;
  }

  // --- Build -------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(userRouteOptimisationControllerProvider);
    final controller =
        ref.read(userRouteOptimisationControllerProvider.notifier);

    _maybeAutoFit(state);

    final initialCenter = state.points.isNotEmpty
        ? state.points.first.toLatLng()
        : _kRouteFallbackCenter;

    return ClipRRect(
      borderRadius: BorderRadius.circular(OpenVtsRadius.md),
      child: Stack(
        children: [
          Positioned.fill(
            child: ColoredBox(
              color: const Color(0xFFE8EEF5),
              child: FlutterMap(
                mapController: _map,
                options: MapOptions(
                  initialCenter: initialCenter,
                  initialZoom: state.points.isEmpty ? 4 : 12,
                  minZoom: 3,
                  maxZoom: 19,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.all,
                  ),
                  onMapReady: _onMapReady,
                  onTap: (tap, point) =>
                      _handleMapTap(tap, point, controller, state),
                ),
                children: [
                  TileLayer(
                    urlTemplate: _kRouteTileUrl,
                    subdomains: _kRouteTileSubdomains,
                    userAgentPackageName: 'com.openvts.mobile',
                  ),
                  PolylineLayer(polylines: _buildPolylines(state)),
                  MarkerLayer(markers: _buildMarkers(state, controller)),
                ],
              ),
            ),
          ),
          if (state.clickToAddMode)
            Positioned(
              top: OpenVtsSpacing.xs,
              left: OpenVtsSpacing.xs,
              right: OpenVtsSpacing.xs,
              child: _ClickToAddBanner(
                onCancel: () => controller.setClickToAddMode(false),
              ),
            ),
          Positioned(
            top: state.clickToAddMode
                ? 52 + OpenVtsSpacing.xs
                : OpenVtsSpacing.xs,
            right: OpenVtsSpacing.xs,
            child: RouteOptimisationMapLegend(
              hasResult: state.hasResult,
              roundTrip: state.roundTrip,
            ),
          ),
          Positioned(
            bottom: OpenVtsSpacing.sm,
            right: OpenVtsSpacing.xs,
            child: RouteOptimisationMapControls(
              canFit: state.points.isNotEmpty,
              onFitAll: () => _fitAll(state),
              onZoomIn: () => _map.move(
                _map.camera.center,
                (_map.camera.zoom + 1).clamp(3, 19),
              ),
              onZoomOut: () => _map.move(
                _map.camera.center,
                (_map.camera.zoom - 1).clamp(3, 19),
              ),
            ),
          ),
          if (state.points.isEmpty && !state.clickToAddMode)
            const Positioned(
              bottom: OpenVtsSpacing.sm,
              left: OpenVtsSpacing.xs,
              child: _HintBubble(text: 'No stops yet — add some to plan.'),
            ),
        ],
      ),
    );
  }
}

class _ClickToAddBanner extends StatelessWidget {
  const _ClickToAddBanner({required this.onCancel});

  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(
        horizontal: OpenVtsSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: OpenVtsColors.brandInk,
        borderRadius: BorderRadius.circular(OpenVtsRadius.md),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(
            Icons.touch_app_outlined,
            color: OpenVtsColors.white,
            size: 16,
          ),
          const SizedBox(width: OpenVtsSpacing.xs),
          Expanded(
            child: Text(
              'Tap map to add waypoint',
              style: OpenVtsTypography.label.copyWith(
                color: OpenVtsColors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: onCancel,
            style: TextButton.styleFrom(
              foregroundColor: OpenVtsColors.white,
              minimumSize: const Size(0, 32),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(OpenVtsRadius.sm),
                side: BorderSide(
                  color: OpenVtsColors.white.withValues(alpha: 0.4),
                ),
              ),
            ),
            child: Text(
              'Cancel',
              style: OpenVtsTypography.label.copyWith(
                color: OpenVtsColors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HintBubble extends StatelessWidget {
  const _HintBubble({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: OpenVtsColors.surfaceElevated.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(OpenVtsRadius.pill),
        border: Border.all(color: OpenVtsColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: OpenVtsSpacing.sm,
          vertical: 6,
        ),
        child: Text(
          text,
          style: OpenVtsTypography.meta.copyWith(
            color: OpenVtsColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
