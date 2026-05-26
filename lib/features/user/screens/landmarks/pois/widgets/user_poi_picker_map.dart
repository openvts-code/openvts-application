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

const String _kPoiTileUrl =
    'https://{s}.google.com/vt/lyrs=m&x={x}&y={y}&z={z}';
const List<String> _kPoiTileSubdomains = <String>['mt0', 'mt1', 'mt2', 'mt3'];
const LatLng _kPoiFallbackCenter = LatLng(20.5937, 78.9629);

/// Result returned from [UserPoiPickerMap].
class UserPoiPickerResult {
  const UserPoiPickerResult({required this.coordinates, this.toleranceMeters});

  final UserGeoPoint coordinates;
  final double? toleranceMeters;
}

/// Full-screen page used to pick or refine a POI coordinate. Supports tap to
/// place, numeric coordinate edits, nudge controls, and an optional tolerance
/// radius slider. Marker dragging is not used because `flutter_map` v7 does
/// not provide reliable drag support; tap-to-reposition is the primary UX.
class UserPoiPickerMap extends StatefulWidget {
  const UserPoiPickerMap({
    super.key,
    this.initialPoint,
    this.initialToleranceM,
    this.title = 'Pick location',
  });

  final LatLng? initialPoint;
  final double? initialToleranceM;
  final String title;

  @override
  State<UserPoiPickerMap> createState() => _UserPoiPickerMapState();
}

class _UserPoiPickerMapState extends State<UserPoiPickerMap> {
  late final MapController _map;
  late LatLng? _point;
  late double _tolerance;
  late final TextEditingController _latCtrl;
  late final TextEditingController _lonCtrl;
  late final TextEditingController _tolCtrl;

  static const double _nudgeMeters = 10;

  @override
  void initState() {
    super.initState();
    _map = MapController();
    _point = widget.initialPoint;
    _tolerance = (widget.initialToleranceM ?? 0).clamp(0, 5000).toDouble();
    _latCtrl = TextEditingController(
      text: _point == null ? '' : _point!.latitude.toStringAsFixed(6),
    );
    _lonCtrl = TextEditingController(
      text: _point == null ? '' : _point!.longitude.toStringAsFixed(6),
    );
    _tolCtrl = TextEditingController(
      text: _tolerance > 0 ? _tolerance.toStringAsFixed(0) : '',
    );
  }

  @override
  void dispose() {
    _latCtrl.dispose();
    _lonCtrl.dispose();
    _tolCtrl.dispose();
    super.dispose();
  }

  void _setPoint(LatLng point, {bool recenter = false}) {
    setState(() {
      _point = point;
      _latCtrl.text = point.latitude.toStringAsFixed(6);
      _lonCtrl.text = point.longitude.toStringAsFixed(6);
    });
    if (recenter) {
      try {
        _map.move(point, _map.camera.zoom);
      } catch (_) {
        // Map not ready yet — initialCenter handles it.
      }
    }
  }

  void _applyCoordsFromFields() {
    final lat = double.tryParse(_latCtrl.text.trim());
    final lon = double.tryParse(_lonCtrl.text.trim());
    if (lat == null || lon == null) return;
    if (lat < -90 || lat > 90 || lon < -180 || lon > 180) return;
    _setPoint(LatLng(lat, lon), recenter: true);
  }

  void _applyToleranceFromField() {
    final raw = _tolCtrl.text.trim();
    final value = raw.isEmpty ? 0.0 : double.tryParse(raw);
    if (value == null || value < 0) return;
    setState(() => _tolerance = value.clamp(0, 5000).toDouble());
  }

  void _nudge({required double dLat, required double dLon}) {
    if (_point == null) return;
    final p = _point!;
    const metersPerDegLat = 111111.0;
    final metersPerDegLon =
        metersPerDegLat * math.cos(p.latitude * math.pi / 180).abs();
    final latOffset = (dLat * _nudgeMeters) / metersPerDegLat;
    final lonOffset =
        metersPerDegLon < 1 ? 0.0 : (dLon * _nudgeMeters) / metersPerDegLon;
    _setPoint(LatLng(p.latitude + latOffset, p.longitude + lonOffset));
  }

  void _save() {
    if (_point == null) {
      ToastHelper.showError(
        'Tap the map or enter coordinates to place the POI.',
        context: context,
      );
      return;
    }
    Navigator.of(context).pop(
      UserPoiPickerResult(
        coordinates: UserGeoPoint(
          lat: _point!.latitude,
          lon: _point!.longitude,
        ),
        toleranceMeters: _tolerance > 0 ? _tolerance : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final center = _point ?? widget.initialPoint ?? _kPoiFallbackCenter;
    return Scaffold(
      backgroundColor: OpenVtsColors.surface,
      appBar: AppBar(
        backgroundColor: OpenVtsColors.surfaceElevated,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: OpenVtsColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.title,
          style: OpenVtsTypography.titleSmall.copyWith(
            color: OpenVtsColors.textPrimary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _save,
            style: TextButton.styleFrom(
              foregroundColor: OpenVtsColors.brandInk,
            ),
            child: Text(
              'Save',
              style: OpenVtsTypography.label.copyWith(
                color: OpenVtsColors.brandInk,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: OpenVtsSpacing.xs),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: OpenVtsColors.divider),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ColoredBox(
              color: const Color(0xFFE8EEF5),
              child: FlutterMap(
                mapController: _map,
                options: MapOptions(
                  initialCenter: center,
                  initialZoom: widget.initialPoint == null ? 4.5 : 15,
                  minZoom: 2,
                  maxZoom: 19,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.all,
                  ),
                  onTap: (_, latlng) => _setPoint(latlng),
                ),
                children: [
                  TileLayer(
                    urlTemplate: _kPoiTileUrl,
                    subdomains: _kPoiTileSubdomains,
                    userAgentPackageName: 'com.openvts.mobile',
                  ),
                  if (_point != null && _tolerance > 0)
                    CircleLayer(
                      circles: [
                        CircleMarker(
                          point: _point!,
                          useRadiusInMeter: true,
                          radius: _tolerance,
                          color: OpenVtsColors.brandInk.withValues(alpha: 0.10),
                          borderStrokeWidth: 1.2,
                          borderColor: OpenVtsColors.brandInk.withValues(
                            alpha: 0.6,
                          ),
                        ),
                      ],
                    ),
                  if (_point != null)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _point!,
                          width: 22,
                          height: 22,
                          alignment: Alignment.center,
                          child: const _PickerPin(),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          _Panel(
            latCtrl: _latCtrl,
            lonCtrl: _lonCtrl,
            tolCtrl: _tolCtrl,
            tolerance: _tolerance,
            hasPoint: _point != null,
            onApplyCoords: _applyCoordsFromFields,
            onApplyTolerance: _applyToleranceFromField,
            onToleranceChanged: (value) {
              setState(() {
                _tolerance = value;
                _tolCtrl.text = value > 0 ? value.toStringAsFixed(0) : '';
              });
            },
            onNudgeNorth: () => _nudge(dLat: 1, dLon: 0),
            onNudgeSouth: () => _nudge(dLat: -1, dLon: 0),
            onNudgeEast: () => _nudge(dLat: 0, dLon: 1),
            onNudgeWest: () => _nudge(dLat: 0, dLon: -1),
            onRecenter: () {
              if (_point != null) {
                try {
                  _map.move(_point!, 16);
                } catch (_) {}
              }
            },
            onSave: _save,
          ),
        ],
      ),
    );
  }
}

class _PickerPin extends StatelessWidget {
  const _PickerPin();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: OpenVtsColors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
              blurRadius: 4, color: Color(0x33000000), offset: Offset(0, 2)),
        ],
      ),
      padding: const EdgeInsets.all(3),
      child: Container(
        decoration: const BoxDecoration(
          color: OpenVtsColors.brandInk,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({
    required this.latCtrl,
    required this.lonCtrl,
    required this.tolCtrl,
    required this.tolerance,
    required this.hasPoint,
    required this.onApplyCoords,
    required this.onApplyTolerance,
    required this.onToleranceChanged,
    required this.onNudgeNorth,
    required this.onNudgeSouth,
    required this.onNudgeEast,
    required this.onNudgeWest,
    required this.onRecenter,
    required this.onSave,
  });

  final TextEditingController latCtrl;
  final TextEditingController lonCtrl;
  final TextEditingController tolCtrl;
  final double tolerance;
  final bool hasPoint;
  final VoidCallback onApplyCoords;
  final VoidCallback onApplyTolerance;
  final ValueChanged<double> onToleranceChanged;
  final VoidCallback onNudgeNorth;
  final VoidCallback onNudgeSouth;
  final VoidCallback onNudgeEast;
  final VoidCallback onNudgeWest;
  final VoidCallback onRecenter;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: OpenVtsColors.surfaceElevated,
        border: Border(
          top: BorderSide(color: OpenVtsColors.divider),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(
        OpenVtsSpacing.md,
        OpenVtsSpacing.sm,
        OpenVtsSpacing.md,
        OpenVtsSpacing.sm,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: _CoordField(
                    label: 'Latitude',
                    controller: latCtrl,
                    onSubmitted: onApplyCoords,
                  ),
                ),
                const SizedBox(width: OpenVtsSpacing.xs),
                Expanded(
                  child: _CoordField(
                    label: 'Longitude',
                    controller: lonCtrl,
                    onSubmitted: onApplyCoords,
                  ),
                ),
                const SizedBox(width: OpenVtsSpacing.xs),
                _IconBtn(
                  icon: Icons.my_location,
                  tooltip: 'Recenter',
                  onTap: hasPoint ? onRecenter : null,
                ),
              ],
            ),
            const SizedBox(height: OpenVtsSpacing.xs),
            Row(
              children: [
                Text(
                  'Nudge 10 m',
                  style: OpenVtsTypography.meta.copyWith(
                    color: OpenVtsColors.textSecondary,
                  ),
                ),
                const Spacer(),
                _IconBtn(
                  icon: Icons.arrow_upward,
                  tooltip: 'North',
                  onTap: hasPoint ? onNudgeNorth : null,
                ),
                _IconBtn(
                  icon: Icons.arrow_downward,
                  tooltip: 'South',
                  onTap: hasPoint ? onNudgeSouth : null,
                ),
                _IconBtn(
                  icon: Icons.arrow_back,
                  tooltip: 'West',
                  onTap: hasPoint ? onNudgeWest : null,
                ),
                _IconBtn(
                  icon: Icons.arrow_forward,
                  tooltip: 'East',
                  onTap: hasPoint ? onNudgeEast : null,
                ),
              ],
            ),
            const SizedBox(height: OpenVtsSpacing.xs),
            Row(
              children: [
                Text(
                  'Tolerance',
                  style: OpenVtsTypography.label.copyWith(
                    color: OpenVtsColors.textPrimary,
                  ),
                ),
                const SizedBox(width: OpenVtsSpacing.xs),
                Expanded(
                  child: Slider(
                    value: tolerance.clamp(0, 1000).toDouble(),
                    min: 0,
                    max: 1000,
                    divisions: 100,
                    activeColor: OpenVtsColors.brandInk,
                    inactiveColor: OpenVtsColors.border,
                    label: tolerance > 0
                        ? '${tolerance.toStringAsFixed(0)} m'
                        : 'off',
                    onChanged: onToleranceChanged,
                  ),
                ),
                SizedBox(
                  width: 70,
                  child: TextField(
                    controller: tolCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    ],
                    style: OpenVtsTypography.numeric,
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(
                      isDense: true,
                      hintText: '0',
                      suffixText: 'm',
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => onApplyTolerance(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: OpenVtsSpacing.xs),
            OpenVtsButton(
              label: hasPoint ? 'Use this location' : 'Tap map to place POI',
              onPressed: hasPoint ? onSave : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _CoordField extends StatelessWidget {
  const _CoordField({
    required this.label,
    required this.controller,
    required this.onSubmitted,
  });

  final String label;
  final TextEditingController controller;
  final VoidCallback onSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(
        signed: true,
        decimal: true,
      ),
      inputFormatters: <TextInputFormatter>[
        FilteringTextInputFormatter.allow(RegExp(r'[0-9.\-]')),
      ],
      style: OpenVtsTypography.numeric,
      onSubmitted: (_) => onSubmitted(),
      onEditingComplete: onSubmitted,
      decoration: InputDecoration(
        isDense: true,
        labelText: label,
        labelStyle: OpenVtsTypography.meta.copyWith(
          color: OpenVtsColors.textSecondary,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: OpenVtsSpacing.sm,
          vertical: 10,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(OpenVtsRadius.button),
          borderSide: const BorderSide(color: OpenVtsColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(OpenVtsRadius.button),
          borderSide: const BorderSide(color: OpenVtsColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(OpenVtsRadius.button),
          borderSide: const BorderSide(
            color: OpenVtsColors.brandInk,
            width: 1.4,
          ),
        ),
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  const _IconBtn({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return Tooltip(
      message: tooltip,
      child: InkResponse(
        onTap: onTap,
        radius: 20,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(
            icon,
            size: 18,
            color: disabled
                ? OpenVtsColors.textTertiary
                : OpenVtsColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
