import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../../../core/theme/open_vts_colors.dart';
import '../../../../../../core/theme/open_vts_radius.dart';
import '../../../../../../core/theme/open_vts_spacing.dart';
import '../../../../../../core/theme/open_vts_typography.dart';
import '../../../../../../shared/helpers/toast_helper.dart';
import '../../../../../../shared/widgets/open_vts_button.dart';
import '../../../../models/user_landmark_model.dart';
import 'user_route_search_panel.dart';

/// Result returned from the full-screen route editor on save.
class UserRouteEditorResult {
  const UserRouteEditorResult({
    required this.points,
    required this.toleranceM,
  });

  final List<UserGeoPoint> points;
  final double toleranceM;
}

/// Full-screen mobile-first route geometry editor.
///
/// Owns local editing state only (point list + tolerance + camera). Never
/// performs API calls; the parent form sheet dispatches through the route
/// controller. Supports two creation modes:
///   - manual: tap map to add vertices, undo/clear, vertex tap-to-edit
///   - search: optional Nominatim+OSRM panel that yields a polyline preview
class UserRouteEditorScreen extends StatefulWidget {
  const UserRouteEditorScreen({
    super.key,
    this.initialPoints = const <UserGeoPoint>[],
    this.initialToleranceM,
    this.routeColor = const Color(0xFF0F172A),
    this.title = 'Draw route',
  });

  final List<UserGeoPoint> initialPoints;
  final double? initialToleranceM;
  final Color routeColor;
  final String title;

  @override
  State<UserRouteEditorScreen> createState() => _UserRouteEditorScreenState();
}

enum _EditorMode { manual, search }

class _UserRouteEditorScreenState extends State<UserRouteEditorScreen> {
  final MapController _map = MapController();
  final List<LatLng> _points = <LatLng>[];
  double _tolerance = 50;
  _EditorMode _mode = _EditorMode.manual;
  bool _showSearchPanel = false;

  @override
  void initState() {
    super.initState();
    _points.addAll(
      widget.initialPoints.map((p) => LatLng(p.lat, p.lon)),
    );
    final t = widget.initialToleranceM;
    if (t != null && t > 0) _tolerance = t;
  }

  // -------------------------------------------------------------------------
  // Point mutations
  // -------------------------------------------------------------------------

  void _addPoint(LatLng p) {
    setState(() => _points.add(p));
  }

  void _undo() {
    if (_points.isEmpty) return;
    setState(_points.removeLast);
  }

  void _clear() {
    if (_points.isEmpty) return;
    setState(_points.clear);
  }

  void _replaceAll(List<LatLng> next) {
    setState(() {
      _points
        ..clear()
        ..addAll(next);
    });
    _fitToPoints();
  }

  void _updatePointAt(int index, LatLng next) {
    if (index < 0 || index >= _points.length) return;
    setState(() => _points[index] = next);
  }

  void _removePointAt(int index) {
    if (index < 0 || index >= _points.length) return;
    setState(() => _points.removeAt(index));
  }

  // -------------------------------------------------------------------------
  // Camera helpers
  // -------------------------------------------------------------------------

  void _fitToPoints() {
    if (_points.length < 2) {
      if (_points.length == 1) {
        try {
          _map.move(_points.first, 14);
        } catch (_) {/* map not yet ready */}
      }
      return;
    }
    double minLat = _points.first.latitude;
    double maxLat = _points.first.latitude;
    double minLon = _points.first.longitude;
    double maxLon = _points.first.longitude;
    for (final p in _points) {
      minLat = math.min(minLat, p.latitude);
      maxLat = math.max(maxLat, p.latitude);
      minLon = math.min(minLon, p.longitude);
      maxLon = math.max(maxLon, p.longitude);
    }
    try {
      _map.fitCamera(
        CameraFit.bounds(
          bounds: LatLngBounds(
            LatLng(minLat, minLon),
            LatLng(maxLat, maxLon),
          ),
          padding: const EdgeInsets.all(48),
          maxZoom: 16,
        ),
      );
    } catch (_) {/* map not yet ready */}
  }

  // -------------------------------------------------------------------------
  // Vertex editor sheet
  // -------------------------------------------------------------------------

  Future<void> _openVertexEditor(int index) async {
    if (index < 0 || index >= _points.length) return;
    final initial = _points[index];
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: OpenVtsColors.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetCtx) {
        return _VertexEditorSheet(
          index: index,
          initial: initial,
          onChanged: (next) => _updatePointAt(index, next),
          onRemove: () {
            _removePointAt(index);
            Navigator.of(sheetCtx).pop();
          },
        );
      },
    );
  }

  // -------------------------------------------------------------------------
  // Save
  // -------------------------------------------------------------------------

  String? _validate() {
    if (_points.length < 2) {
      return 'Add at least 2 points to form a route.';
    }
    for (final p in _points) {
      if (p.latitude.isNaN ||
          p.longitude.isNaN ||
          p.latitude.abs() > 90 ||
          p.longitude.abs() > 180) {
        return 'One or more vertices have invalid coordinates.';
      }
    }
    if (_tolerance < 1) {
      return 'Tolerance must be at least 1 meter.';
    }
    return null;
  }

  void _save() {
    final error = _validate();
    if (error != null) {
      ToastHelper.showError(error, context: context);
      return;
    }
    Navigator.of(context).pop(
      UserRouteEditorResult(
        points: _points
            .map((p) => UserGeoPoint(lat: p.latitude, lon: p.longitude))
            .toList(growable: false),
        toleranceM: _tolerance,
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Build
  // -------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final initialCenter =
        _points.isNotEmpty ? _points.first : const LatLng(20.5937, 78.9629);
    final initialZoom = _points.isNotEmpty ? 12.0 : 5.0;

    return Scaffold(
      backgroundColor: OpenVtsColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(
              title: widget.title,
              onCancel: () => Navigator.of(context).maybePop(),
              onSave: _save,
            ),
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: FlutterMap(
                      mapController: _map,
                      options: MapOptions(
                        initialCenter: initialCenter,
                        initialZoom: initialZoom,
                        minZoom: 3,
                        maxZoom: 19,
                        interactionOptions: const InteractionOptions(
                          flags: InteractiveFlag.drag |
                              InteractiveFlag.pinchZoom |
                              InteractiveFlag.doubleTapZoom |
                              InteractiveFlag.scrollWheelZoom,
                        ),
                        onTap: _mode == _EditorMode.manual
                            ? (_, point) => _addPoint(point)
                            : null,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://{s}.google.com/vt/lyrs=m&x={x}&y={y}&z={z}',
                          subdomains: const ['mt0', 'mt1', 'mt2', 'mt3'],
                          userAgentPackageName: 'com.openvts.mobile',
                        ),
                        if (_points.length >= 2)
                          PolylineLayer(
                            polylines: [
                              Polyline(
                                points: _points,
                                color: widget.routeColor,
                                strokeWidth: 4,
                                borderColor: OpenVtsColors.white,
                                borderStrokeWidth: 1.5,
                              ),
                            ],
                          ),
                        if (_points.isNotEmpty)
                          MarkerLayer(
                            markers: [
                              for (var i = 0; i < _points.length; i++)
                                Marker(
                                  point: _points[i],
                                  width: 26,
                                  height: 26,
                                  child: _VertexPin(
                                    index: i,
                                    isEndpoint:
                                        i == 0 || i == _points.length - 1,
                                    color: widget.routeColor,
                                    onTap: () => _openVertexEditor(i),
                                  ),
                                ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: OpenVtsSpacing.sm,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: _ModeToggle(
                        mode: _mode,
                        onChanged: (m) => setState(() {
                          _mode = m;
                          if (m == _EditorMode.search) {
                            _showSearchPanel = true;
                          }
                        }),
                      ),
                    ),
                  ),
                  Positioned(
                    right: OpenVtsSpacing.sm,
                    top: OpenVtsSpacing.lg * 2 + OpenVtsSpacing.sm,
                    child: _MapControls(
                      onZoomIn: () => _map.move(
                        _map.camera.center,
                        (_map.camera.zoom + 1).clamp(3.0, 19.0),
                      ),
                      onZoomOut: () => _map.move(
                        _map.camera.center,
                        (_map.camera.zoom - 1).clamp(3.0, 19.0),
                      ),
                      onFit: _points.length >= 2 ? _fitToPoints : null,
                      onUndo: _points.isNotEmpty ? _undo : null,
                      onClear: _points.isNotEmpty ? _clear : null,
                    ),
                  ),
                  if (_mode == _EditorMode.search && _showSearchPanel)
                    Positioned(
                      left: OpenVtsSpacing.sm,
                      right: OpenVtsSpacing.sm,
                      top: OpenVtsSpacing.lg * 2 + OpenVtsSpacing.sm,
                      child: UserRouteSearchPanel(
                        onRouteGenerated: (points) {
                          _replaceAll(points);
                          setState(() => _showSearchPanel = false);
                        },
                        onClose: () => setState(() => _showSearchPanel = false),
                      ),
                    ),
                ],
              ),
            ),
            _BottomPanel(
              pointCount: _points.length,
              distanceMeters: _polylineLength(_points),
              tolerance: _tolerance,
              onToleranceChanged: (v) =>
                  setState(() => _tolerance = v.clamp(1.0, 5000.0)),
            ),
          ],
        ),
      ),
    );
  }

  static double _polylineLength(List<LatLng> pts) {
    if (pts.length < 2) return 0;
    const earth = 6371000.0;
    double total = 0;
    for (var i = 1; i < pts.length; i++) {
      final a = pts[i - 1];
      final b = pts[i];
      final lat1 = a.latitude * math.pi / 180;
      final lat2 = b.latitude * math.pi / 180;
      final dLat = (b.latitude - a.latitude) * math.pi / 180;
      final dLon = (b.longitude - a.longitude) * math.pi / 180;
      final h = math.sin(dLat / 2) * math.sin(dLat / 2) +
          math.cos(lat1) *
              math.cos(lat2) *
              math.sin(dLon / 2) *
              math.sin(dLon / 2);
      total += 2 * earth * math.asin(math.min(1.0, math.sqrt(h)));
    }
    return total;
  }
}

// ---------------------------------------------------------------------------
// Top bar
// ---------------------------------------------------------------------------

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.title,
    required this.onCancel,
    required this.onSave,
  });

  final String title;
  final VoidCallback onCancel;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: OpenVtsColors.surfaceElevated,
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close, color: OpenVtsColors.textPrimary),
            onPressed: onCancel,
          ),
          Expanded(
            child: Text(
              title,
              style: OpenVtsTypography.titleSmall.copyWith(
                color: OpenVtsColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: onSave,
            child: Text(
              'Save',
              style: OpenVtsTypography.label.copyWith(
                color: OpenVtsColors.brandInk,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Mode toggle pill
// ---------------------------------------------------------------------------

class _ModeToggle extends StatelessWidget {
  const _ModeToggle({required this.mode, required this.onChanged});

  final _EditorMode mode;
  final ValueChanged<_EditorMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: OpenVtsColors.surfaceElevated,
        borderRadius: BorderRadius.circular(OpenVtsRadius.pill),
        border: Border.all(color: OpenVtsColors.border),
      ),
      padding: const EdgeInsets.all(2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ModeChip(
            label: 'Draw',
            icon: Icons.edit_road_outlined,
            selected: mode == _EditorMode.manual,
            onTap: () => onChanged(_EditorMode.manual),
          ),
          _ModeChip(
            label: 'Search',
            icon: Icons.search,
            selected: mode == _EditorMode.search,
            onTap: () => onChanged(_EditorMode.search),
          ),
        ],
      ),
    );
  }
}

class _ModeChip extends StatelessWidget {
  const _ModeChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(OpenVtsRadius.pill),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(
          horizontal: OpenVtsSpacing.sm,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: selected ? OpenVtsColors.brandInk : Colors.transparent,
          borderRadius: BorderRadius.circular(OpenVtsRadius.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color:
                  selected ? OpenVtsColors.white : OpenVtsColors.textSecondary,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: OpenVtsTypography.meta.copyWith(
                color:
                    selected ? OpenVtsColors.white : OpenVtsColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Map controls
// ---------------------------------------------------------------------------

class _MapControls extends StatelessWidget {
  const _MapControls({
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onFit,
    required this.onUndo,
    required this.onClear,
  });

  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback? onFit;
  final VoidCallback? onUndo;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: OpenVtsColors.surfaceElevated,
        borderRadius: BorderRadius.circular(OpenVtsRadius.md),
        border: Border.all(color: OpenVtsColors.border),
      ),
      padding: const EdgeInsets.all(2),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ControlButton(icon: Icons.add, onTap: onZoomIn),
          _ControlButton(icon: Icons.remove, onTap: onZoomOut),
          _ControlDivider(),
          _ControlButton(icon: Icons.center_focus_strong, onTap: onFit),
          _ControlButton(icon: Icons.undo, onTap: onUndo),
          _ControlButton(
            icon: Icons.delete_outline,
            onTap: onClear,
            destructive: true,
          ),
        ],
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  const _ControlButton({
    required this.icon,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    final color = destructive ? OpenVtsColors.error : OpenVtsColors.textPrimary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(OpenVtsRadius.sm),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Icon(
          icon,
          size: 18,
          color: disabled ? OpenVtsColors.textTertiary : color,
        ),
      ),
    );
  }
}

class _ControlDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 6),
      color: OpenVtsColors.divider,
    );
  }
}

// ---------------------------------------------------------------------------
// Vertex pin
// ---------------------------------------------------------------------------

class _VertexPin extends StatelessWidget {
  const _VertexPin({
    required this.index,
    required this.isEndpoint,
    required this.color,
    required this.onTap,
  });

  final int index;
  final bool isEndpoint;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 22,
        height: 22,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isEndpoint ? color : OpenVtsColors.white,
          shape: BoxShape.circle,
          border: Border.all(
            color: isEndpoint ? OpenVtsColors.white : color,
            width: 2,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 4,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Text(
          '${index + 1}',
          style: OpenVtsTypography.meta.copyWith(
            color: isEndpoint ? OpenVtsColors.white : color,
            fontSize: 9,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bottom panel: count, distance, tolerance
// ---------------------------------------------------------------------------

class _BottomPanel extends StatelessWidget {
  const _BottomPanel({
    required this.pointCount,
    required this.distanceMeters,
    required this.tolerance,
    required this.onToleranceChanged,
  });

  final int pointCount;
  final double distanceMeters;
  final double tolerance;
  final ValueChanged<double> onToleranceChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: OpenVtsColors.surfaceElevated,
        border: Border(top: BorderSide(color: OpenVtsColors.border)),
      ),
      padding: const EdgeInsets.fromLTRB(
        OpenVtsSpacing.md,
        OpenVtsSpacing.sm,
        OpenVtsSpacing.md,
        OpenVtsSpacing.md,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _MetaChip(
                icon: Icons.scatter_plot_outlined,
                label: '$pointCount points',
              ),
              const SizedBox(width: OpenVtsSpacing.xs),
              _MetaChip(
                icon: Icons.straighten,
                label: _formatMeters(distanceMeters),
              ),
              const Spacer(),
              _MetaChip(
                icon: Icons.tune,
                label: '±${_formatMeters(tolerance)}',
              ),
            ],
          ),
          const SizedBox(height: OpenVtsSpacing.xs),
          Row(
            children: [
              Text(
                'Tolerance',
                style: OpenVtsTypography.meta.copyWith(
                  color: OpenVtsColors.textSecondary,
                ),
              ),
              const SizedBox(width: OpenVtsSpacing.sm),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 2,
                    overlayShape: SliderComponentShape.noOverlay,
                  ),
                  child: Slider(
                    value: tolerance.clamp(1.0, 1000.0),
                    min: 1,
                    max: 1000,
                    onChanged: onToleranceChanged,
                    activeColor: OpenVtsColors.brandInk,
                    inactiveColor: OpenVtsColors.divider,
                  ),
                ),
              ),
              SizedBox(
                width: 80,
                child: TextField(
                  controller: TextEditingController(
                    text: tolerance.toStringAsFixed(0),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                  textAlign: TextAlign.center,
                  style: OpenVtsTypography.numeric,
                  decoration: const InputDecoration(
                    isDense: true,
                    suffixText: 'm',
                    contentPadding:
                        EdgeInsets.symmetric(vertical: 6, horizontal: 6),
                  ),
                  onSubmitted: (v) {
                    final parsed = double.tryParse(v);
                    if (parsed != null) onToleranceChanged(parsed);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _formatMeters(double m) {
    if (m >= 1000) {
      return '${(m / 1000).toStringAsFixed(m >= 10000 ? 1 : 2)} km';
    }
    return '${m.toStringAsFixed(m >= 100 ? 0 : 1)} m';
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: OpenVtsColors.surface,
        borderRadius: BorderRadius.circular(OpenVtsRadius.pill),
        border: Border.all(color: OpenVtsColors.border),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: OpenVtsSpacing.sm,
        vertical: 4,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: OpenVtsColors.textSecondary),
          const SizedBox(width: 4),
          Text(
            label,
            style: OpenVtsTypography.meta.copyWith(
              color: OpenVtsColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Vertex editor bottom sheet
// ---------------------------------------------------------------------------

class _VertexEditorSheet extends StatefulWidget {
  const _VertexEditorSheet({
    required this.index,
    required this.initial,
    required this.onChanged,
    required this.onRemove,
  });

  final int index;
  final LatLng initial;
  final ValueChanged<LatLng> onChanged;
  final VoidCallback onRemove;

  @override
  State<_VertexEditorSheet> createState() => _VertexEditorSheetState();
}

class _VertexEditorSheetState extends State<_VertexEditorSheet> {
  late final TextEditingController _lat;
  late final TextEditingController _lon;

  @override
  void initState() {
    super.initState();
    _lat = TextEditingController(
      text: widget.initial.latitude.toStringAsFixed(6),
    );
    _lon = TextEditingController(
      text: widget.initial.longitude.toStringAsFixed(6),
    );
  }

  @override
  void dispose() {
    _lat.dispose();
    _lon.dispose();
    super.dispose();
  }

  void _apply() {
    final lat = double.tryParse(_lat.text);
    final lon = double.tryParse(_lon.text);
    if (lat == null || lon == null) return;
    if (lat.abs() > 90 || lon.abs() > 180) return;
    widget.onChanged(LatLng(lat, lon));
    Navigator.of(context).maybePop();
  }

  void _nudge({double dLat = 0, double dLon = 0}) {
    final current = LatLng(
      double.tryParse(_lat.text) ?? widget.initial.latitude,
      double.tryParse(_lon.text) ?? widget.initial.longitude,
    );
    const stepMeters = 10.0;
    final metersPerDegLat = 111111.0;
    final metersPerDegLon =
        111111.0 * math.cos(current.latitude * math.pi / 180).abs();
    final nextLat = (current.latitude + dLat * stepMeters / metersPerDegLat)
        .clamp(-90.0, 90.0);
    final nextLon = (current.longitude +
            dLon * stepMeters / (metersPerDegLon == 0 ? 1 : metersPerDegLon))
        .clamp(-180.0, 180.0);
    setState(() {
      _lat.text = nextLat.toStringAsFixed(6);
      _lon.text = nextLon.toStringAsFixed(6);
    });
    widget.onChanged(LatLng(nextLat, nextLon));
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          OpenVtsSpacing.md,
          OpenVtsSpacing.sm,
          OpenVtsSpacing.md,
          OpenVtsSpacing.md + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(
                  'Vertex ${widget.index + 1}',
                  style: OpenVtsTypography.titleSmall.copyWith(
                    color: OpenVtsColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    color: OpenVtsColors.error,
                  ),
                  onPressed: widget.onRemove,
                ),
              ],
            ),
            const SizedBox(height: OpenVtsSpacing.xs),
            Row(
              children: [
                Expanded(
                  child: _CoordField(label: 'Latitude', controller: _lat),
                ),
                const SizedBox(width: OpenVtsSpacing.xs),
                Expanded(
                  child: _CoordField(label: 'Longitude', controller: _lon),
                ),
              ],
            ),
            const SizedBox(height: OpenVtsSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _NudgeBtn(
                  icon: Icons.arrow_upward,
                  onTap: () => _nudge(dLat: 1),
                ),
                const SizedBox(width: OpenVtsSpacing.xs),
                _NudgeBtn(
                  icon: Icons.arrow_downward,
                  onTap: () => _nudge(dLat: -1),
                ),
                const SizedBox(width: OpenVtsSpacing.md),
                _NudgeBtn(
                  icon: Icons.arrow_back,
                  onTap: () => _nudge(dLon: -1),
                ),
                const SizedBox(width: OpenVtsSpacing.xs),
                _NudgeBtn(
                  icon: Icons.arrow_forward,
                  onTap: () => _nudge(dLon: 1),
                ),
              ],
            ),
            const SizedBox(height: OpenVtsSpacing.md),
            OpenVtsButton(label: 'Apply', onPressed: _apply),
          ],
        ),
      ),
    );
  }
}

class _CoordField extends StatelessWidget {
  const _CoordField({required this.label, required this.controller});

  final String label;
  final TextEditingController controller;

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
        TextField(
          controller: controller,
          style: OpenVtsTypography.numeric,
          keyboardType: const TextInputType.numberWithOptions(
              decimal: true, signed: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.\-]')),
          ],
          decoration: InputDecoration(
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(OpenVtsRadius.button),
              borderSide: const BorderSide(color: OpenVtsColors.border),
            ),
          ),
        ),
      ],
    );
  }
}

class _NudgeBtn extends StatelessWidget {
  const _NudgeBtn({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(OpenVtsRadius.button),
      child: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: OpenVtsColors.surface,
          borderRadius: BorderRadius.circular(OpenVtsRadius.button),
          border: Border.all(color: OpenVtsColors.border),
        ),
        child: Icon(icon, size: 16, color: OpenVtsColors.textPrimary),
      ),
    );
  }
}
