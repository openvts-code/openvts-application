import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../../core/theme/open_vts_colors.dart';
import '../../../../../core/theme/open_vts_radius.dart';
import '../../../../../core/theme/open_vts_typography.dart';
import '../../../models/user_landmark_model.dart';

/// Tile configuration matching the OpenVTS live map default (Google Road).
/// Kept inline so this widget does not depend on internals of `live_map`.
const String _kLandmarkTileUrl =
    'https://{s}.google.com/vt/lyrs=m&x={x}&y={y}&z={z}';
const List<String> _kLandmarkTileSubdomains = <String>[
  'mt0',
  'mt1',
  'mt2',
  'mt3',
];

const LatLng _kLandmarkFallbackCenter = LatLng(20.5937, 78.9629); // IN center

/// Shared, read-only map view for the Landmark Studio.
///
/// Renders geofences (circle, polygon, line), POIs (with optional tolerance
/// rings), and routes. Tapping any item selects it; selected items are
/// emphasised while inactive items are muted. The camera auto-fits all items
/// when the content first becomes non-empty, and tightens to the selected
/// item whenever the selection changes.
class UserLandmarkMapView extends StatefulWidget {
  const UserLandmarkMapView({
    super.key,
    this.geofences = const <UserGeofence>[],
    this.pois = const <UserPoi>[],
    this.routes = const <UserRouteLandmark>[],
    this.selectedGeofenceId,
    this.selectedPoiId,
    this.selectedRouteId,
    this.onSelectGeofence,
    this.onSelectPoi,
    this.onSelectRoute,
    this.onMapTap,
    this.showPoiToleranceRings = true,
    this.initialCenter,
    this.initialZoom = 5,
    this.minZoom = 3,
    this.maxZoom = 19,
    this.interactionFlags,
    this.mapController,
    this.overlay,
  });

  final List<UserGeofence> geofences;
  final List<UserPoi> pois;
  final List<UserRouteLandmark> routes;

  final String? selectedGeofenceId;
  final String? selectedPoiId;
  final String? selectedRouteId;

  final ValueChanged<UserGeofence>? onSelectGeofence;
  final ValueChanged<UserPoi>? onSelectPoi;
  final ValueChanged<UserRouteLandmark>? onSelectRoute;

  /// Optional callback for raw map taps. When provided, taps that don't hit
  /// a marker invoke this. Used by editor screens to add vertices.
  final void Function(LatLng point)? onMapTap;

  final bool showPoiToleranceRings;
  final LatLng? initialCenter;
  final double initialZoom;
  final double minZoom;
  final double maxZoom;

  final int? interactionFlags;
  final MapController? mapController;

  /// Optional widget stacked over the map (e.g. floating controls).
  final Widget? overlay;

  @override
  State<UserLandmarkMapView> createState() => _UserLandmarkMapViewState();
}

class _UserLandmarkMapViewState extends State<UserLandmarkMapView> {
  late final MapController _controller =
      widget.mapController ?? MapController();

  bool _didInitialFit = false;
  String? _lastSelectionKey;

  @override
  void didUpdateWidget(covariant UserLandmarkMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final hasContent = widget.geofences.isNotEmpty ||
        widget.pois.isNotEmpty ||
        widget.routes.isNotEmpty;

    if (!_didInitialFit && hasContent) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _fitAll());
    }

    final selectionKey = _selectionKey();
    if (selectionKey != _lastSelectionKey) {
      _lastSelectionKey = selectionKey;
      if (selectionKey != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _fitSelection());
      }
    }
  }

  String? _selectionKey() {
    if (widget.selectedGeofenceId != null) {
      return 'g:${widget.selectedGeofenceId}';
    }
    if (widget.selectedPoiId != null) return 'p:${widget.selectedPoiId}';
    if (widget.selectedRouteId != null) return 'r:${widget.selectedRouteId}';
    return null;
  }

  void _fitAll() {
    final points = <LatLng>[
      for (final g in widget.geofences) ..._pointsForGeofence(g),
      for (final p in widget.pois)
        if (p.coordinates != null) p.coordinates!.toLatLng(),
      for (final r in widget.routes)
        if (r.geodata != null)
          ...r.geodata!.coordinates.map((p) => p.toLatLng()),
    ];
    _fitToPoints(points);
    _didInitialFit = true;
  }

  void _fitSelection() {
    final points = <LatLng>[];
    if (widget.selectedGeofenceId != null) {
      final g = _findById(widget.geofences, widget.selectedGeofenceId!);
      if (g != null) points.addAll(_pointsForGeofence(g));
    }
    if (widget.selectedPoiId != null) {
      final p = _findById(widget.pois, widget.selectedPoiId!);
      if (p?.coordinates != null) points.add(p!.coordinates!.toLatLng());
    }
    if (widget.selectedRouteId != null) {
      final r = _findById(widget.routes, widget.selectedRouteId!);
      if (r?.geodata != null) {
        points.addAll(r!.geodata!.coordinates.map((p) => p.toLatLng()));
      }
    }
    _fitToPoints(points);
  }

  void _fitToPoints(List<LatLng> points) {
    if (points.isEmpty) return;
    if (points.length == 1) {
      _controller.move(points.first, math.max(widget.initialZoom, 14));
      return;
    }
    _controller.fitCamera(
      CameraFit.bounds(
        bounds: LatLngBounds.fromPoints(points),
        padding: const EdgeInsets.all(40),
        maxZoom: 17,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final initialCenter =
        widget.initialCenter ?? _firstPoint() ?? _kLandmarkFallbackCenter;

    final layers = <Widget>[
      TileLayer(
        urlTemplate: _kLandmarkTileUrl,
        subdomains: _kLandmarkTileSubdomains,
        userAgentPackageName: 'com.openvts.mobile',
      ),
      // Routes drawn first so geofences/POIs sit on top.
      if (widget.routes.isNotEmpty)
        PolylineLayer(
          polylines: [
            for (final r in widget.routes) ..._polylinesForRoute(r),
          ],
        ),
      if (_polygonsForAll().isNotEmpty)
        PolygonLayer(polygons: _polygonsForAll()),
      if (_circlesForAll().isNotEmpty) CircleLayer(circles: _circlesForAll()),
      if (widget.pois.isNotEmpty)
        MarkerLayer(markers: [for (final p in widget.pois) _poiMarker(p)]),
    ];

    return Stack(
      children: [
        Positioned.fill(
          child: ColoredBox(
            color: const Color(0xFFE8EEF5),
            child: FlutterMap(
              mapController: _controller,
              options: MapOptions(
                initialCenter: initialCenter,
                initialZoom: widget.initialZoom,
                minZoom: widget.minZoom,
                maxZoom: widget.maxZoom,
                interactionOptions: InteractionOptions(
                  flags: widget.interactionFlags ?? InteractiveFlag.all,
                ),
                onTap: widget.onMapTap == null
                    ? null
                    : (tapPos, point) => widget.onMapTap!(point),
              ),
              children: layers,
            ),
          ),
        ),
        if (widget.overlay != null) Positioned.fill(child: widget.overlay!),
      ],
    );
  }

  LatLng? _firstPoint() {
    for (final g in widget.geofences) {
      final pts = _pointsForGeofence(g);
      if (pts.isNotEmpty) return pts.first;
    }
    for (final p in widget.pois) {
      if (p.coordinates != null) return p.coordinates!.toLatLng();
    }
    for (final r in widget.routes) {
      if (r.geodata != null && r.geodata!.coordinates.isNotEmpty) {
        return r.geodata!.coordinates.first.toLatLng();
      }
    }
    return null;
  }

  List<LatLng> _pointsForGeofence(UserGeofence g) {
    final geo = g.geodata;
    if (geo is UserCircleGeoData) {
      return _circleEnvelope(geo.center.toLatLng(), geo.radiusM);
    }
    if (geo is UserPolygonGeoData) {
      return geo.coordinates.map((p) => p.toLatLng()).toList(growable: false);
    }
    if (geo is UserLineGeoData) {
      return geo.coordinates.map((p) => p.toLatLng()).toList(growable: false);
    }
    return const <LatLng>[];
  }

  List<LatLng> _circleEnvelope(LatLng center, double radiusM) {
    // Cheap 8-point bounding ring for fit-camera math.
    const segments = 8;
    final result = <LatLng>[];
    const earth = 6371008.8;
    final latRad = center.latitude * math.pi / 180;
    final dLat = (radiusM / earth) * (180 / math.pi);
    final dLon = dLat / math.cos(latRad).clamp(1e-6, 1).toDouble();
    for (var i = 0; i < segments; i++) {
      final a = (i / segments) * 2 * math.pi;
      result.add(
        LatLng(
          center.latitude + dLat * math.sin(a),
          center.longitude + dLon * math.cos(a),
        ),
      );
    }
    return result;
  }

  List<CircleMarker> _circlesForAll() {
    final result = <CircleMarker>[];
    for (final g in widget.geofences) {
      final geo = g.geodata;
      if (geo is! UserCircleGeoData) continue;
      final selected = g.id == widget.selectedGeofenceId;
      final color = _parseHex(g.color);
      result.add(
        CircleMarker(
          point: geo.center.toLatLng(),
          radius: geo.radiusM,
          useRadiusInMeter: true,
          color: color.withValues(alpha: g.isActive ? 0.18 : 0.08),
          borderColor: color.withValues(
            alpha: !g.isActive
                ? 0.35
                : selected
                    ? 1.0
                    : 0.7,
          ),
          borderStrokeWidth: selected ? 2.5 : 1.4,
        ),
      );
    }

    if (widget.showPoiToleranceRings) {
      for (final p in widget.pois) {
        final coords = p.coordinates;
        final tol = p.toleranceMeters;
        if (coords == null || tol == null || tol <= 0) continue;
        final selected = p.id == widget.selectedPoiId;
        final color = _parseHex(p.color);
        result.add(
          CircleMarker(
            point: coords.toLatLng(),
            radius: tol,
            useRadiusInMeter: true,
            color: color.withValues(alpha: p.isActive ? 0.12 : 0.05),
            borderColor: color.withValues(
              alpha: !p.isActive
                  ? 0.3
                  : selected
                      ? 0.95
                      : 0.55,
            ),
            borderStrokeWidth: selected ? 2 : 1.1,
          ),
        );
      }
    }
    return result;
  }

  List<Polygon> _polygonsForAll() {
    final result = <Polygon>[];
    for (final g in widget.geofences) {
      final geo = g.geodata;
      if (geo is! UserPolygonGeoData) continue;
      if (geo.coordinates.length < 3) continue;
      final selected = g.id == widget.selectedGeofenceId;
      final color = _parseHex(g.color);
      result.add(
        Polygon(
          points: geo.coordinates.map((p) => p.toLatLng()).toList(),
          color: color.withValues(alpha: g.isActive ? 0.18 : 0.08),
          borderColor: color.withValues(
            alpha: !g.isActive
                ? 0.4
                : selected
                    ? 1.0
                    : 0.75,
          ),
          borderStrokeWidth: selected ? 2.5 : 1.4,
          pattern: g.isActive
              ? const StrokePattern.solid()
              : StrokePattern.dashed(segments: const <double>[6, 4]),
        ),
      );
    }
    return result;
  }

  List<Polyline> _polylinesForRoute(UserRouteLandmark r) {
    final geo = r.geodata;
    if (geo == null || geo.coordinates.length < 2) return const <Polyline>[];
    final selected = r.id == widget.selectedRouteId;
    final color = _parseHex(r.color);
    return <Polyline>[
      Polyline(
        points: geo.coordinates.map((p) => p.toLatLng()).toList(),
        color: color.withValues(
          alpha: !r.isActive
              ? 0.45
              : selected
                  ? 1.0
                  : 0.85,
        ),
        strokeWidth: selected ? 5 : 3.5,
        pattern: r.isActive
            ? const StrokePattern.solid()
            : StrokePattern.dashed(segments: const <double>[10, 6]),
      ),
    ];
  }

  Marker _poiMarker(UserPoi p) {
    final coords = p.coordinates!;
    final selected = p.id == widget.selectedPoiId;
    final color = _parseHex(p.color);
    return Marker(
      point: coords.toLatLng(),
      width: 38,
      height: 38,
      alignment: Alignment.topCenter,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => widget.onSelectPoi?.call(p),
        child: _PoiPin(
          color: color,
          selected: selected,
          muted: !p.isActive,
        ),
      ),
    );
  }

  static T? _findById<T>(List<T> list, String id) {
    for (final entry in list) {
      // ignore: avoid_dynamic_calls
      if ((entry as dynamic).id == id) return entry;
    }
    return null;
  }

  static Color _parseHex(String value) {
    var hex = value.trim().replaceAll('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    final parsed = int.tryParse(hex, radix: 16);
    if (parsed == null) return OpenVtsColors.brandInk;
    return Color(parsed);
  }
}

class _PoiPin extends StatelessWidget {
  const _PoiPin({
    required this.color,
    required this.selected,
    required this.muted,
  });

  final Color color;
  final bool selected;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final effective = muted ? color.withValues(alpha: 0.6) : color;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: selected ? 22 : 18,
          height: selected ? 22 : 18,
          decoration: BoxDecoration(
            color: OpenVtsColors.white,
            shape: BoxShape.circle,
            border: Border.all(
              color: effective,
              width: selected ? 3 : 2,
            ),
            boxShadow: selected
                ? <BoxShadow>[
                    BoxShadow(
                      color: effective.withValues(alpha: 0.35),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Container(
              width: selected ? 8 : 6,
              height: selected ? 8 : 6,
              decoration: BoxDecoration(
                color: effective,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
        Container(
          width: 2,
          height: selected ? 12 : 8,
          color: effective,
        ),
      ],
    );
  }
}

/// A subtle gradient overlay used by editors to indicate the safe touch area
/// near the bottom toolbar. Exposed so editor widgets can reuse it.
class UserLandmarkMapEdgeFade extends StatelessWidget {
  const UserLandmarkMapEdgeFade({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: <Color>[
              OpenVtsColors.brandInk.withValues(alpha: 0.08),
              const Color(0x00000000),
            ],
            stops: const <double>[0.0, 0.25],
          ),
          borderRadius: BorderRadius.circular(OpenVtsRadius.md),
        ),
      ),
    );
  }
}

/// Small attribution badge satisfying tile provider requirements.
class UserLandmarkMapAttribution extends StatelessWidget {
  const UserLandmarkMapAttribution({super.key, this.text = '© Google'});

  final String text;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(OpenVtsRadius.sm),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          color: OpenVtsColors.white.withValues(alpha: 0.7),
          child: Text(
            text,
            style: OpenVtsTypography.meta.copyWith(
              color: OpenVtsColors.textSecondary,
              fontSize: 10,
            ),
          ),
        ),
      ),
    );
  }
}
