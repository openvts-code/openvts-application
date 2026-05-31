import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/socket/socket_service.dart';
import '../../../core/utils/date_time_formatter.dart';
import '../../../core/utils/unit_formatter.dart';
import '../../../shared/helpers/toast_helper.dart';
import '../../../shared/models/vehicle_summary.dart';
import '../../../shared/widgets/open_vts_bottom_sheet.dart';
import '../../../shared/widgets/open_vts_button.dart';
import '../../../shared/widgets/open_vts_date_time_range_selector.dart';
import '../../../shared/widgets/open_vts_text_field.dart';
import '../../notifications/models/app_notification.dart';
import '../../superadmin/models/superadmin_map_overlay_model.dart';
import '../../superadmin/models/superadmin_vehicle_history_model.dart';
import '../../superadmin/models/superadmin_vehicle_model.dart';
import '../../superadmin/services/superadmin_vehicle_service.dart';
import '../controllers/live_map_providers.dart';
import '../models/live_map_role_config.dart';

part 'markers/map_markers.dart';
part 'panels/map_drawers.dart';
part 'replay/replay_widgets.dart';
part 'widgets/map_controls.dart';

const DateTimeFormatter _mapFmt = DateTimeFormatter();
const Color _mapActionInkColor = Color(0xFF111827);
const double _mapDrawerMinChildSize = 0.28;
const double _mapDrawerInitialChildSize = 0.42;
const double _mapDrawerMaxChildSize = 0.78;
const Duration _inactiveVehicleThreshold = Duration(hours: 48);
const double _vehicleMarkerMinMoveMeters = 2;
const double _vehicleMarkerStationaryDriftSpeedKph = 5;
const double _vehicleMarkerStationaryDriftMeters = 25;
const double _vehicleMarkerMaxImpliedSpeedKph = 320;
const Duration _vehicleMarkerMinMotionDuration = Duration(milliseconds: 700);
const Duration _vehicleMarkerMaxMotionDuration = Duration(milliseconds: 3000);
const double _vehicleMarkerTimestampDurationScale = 0.90;
const double _vehicleMarkerSnapDistanceMeters = 5000;

class LiveMapScreen extends ConsumerWidget {
  const LiveMapScreen({super.key, required this.config});

  final LiveMapRoleConfig config;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ProviderScope(
      overrides: [
        currentLiveMapConfigProvider.overrideWithValue(config),
      ],
      child: Consumer(
        builder: (context, ref, _) {
          final liveState = ref.watch(liveMapControllerProvider);
          final telemetry = liveState.telemetry;
          final vehicles = telemetry.vehicles;

          return _MapPageFrame(
            onClose: () => _handleClose(context),
            child: _LiveMap(
              vehicles: vehicles,
              allCount: telemetry.allCount,
              runningCount: telemetry.runningCount,
              stopCount: telemetry.stopCount,
              inactiveCount: telemetry.inactiveCount,
              alerts: liveState.alerts,
              isAlertsLoading: liveState.isAlertsLoading,
            ),
          );
        },
      ),
    );
  }

  void _handleClose(BuildContext context) {
    if (context.canPop()) {
      context.pop();
      return;
    }

    context.go(config.homeRoute);
  }
}

class _MapPageFrame extends StatelessWidget {
  const _MapPageFrame({required this.child, required this.onClose});

  final Widget child;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(child: child),
          Positioned.fill(
            child: SafeArea(
              child: Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.only(top: 16, right: 16),
                  child: _CloseMapButton(onPressed: onClose),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CloseMapButton extends StatelessWidget {
  const _CloseMapButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Close map',
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: Ink(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _mapActionInkColor,
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.10),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.22),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.close_rounded,
              size: 20,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

class _MapDrawerCloseButton extends StatelessWidget {
  const _MapDrawerCloseButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Close drawer',
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: Ink(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _mapActionInkColor,
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.10),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: const Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 20,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

class _LiveMap extends ConsumerStatefulWidget {
  const _LiveMap({
    required this.vehicles,
    required this.allCount,
    required this.runningCount,
    required this.stopCount,
    required this.inactiveCount,
    required this.alerts,
    required this.isAlertsLoading,
  });

  final List<VehicleSummary> vehicles;
  final int allCount;
  final int runningCount;
  final int stopCount;
  final int inactiveCount;
  final List<AppNotification> alerts;
  final bool isAlertsLoading;

  @override
  ConsumerState<_LiveMap> createState() => _LiveMapState();
}

class _LiveMapState extends ConsumerState<_LiveMap>
    with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  late final Ticker _vehicleAnimationTicker;
  late final AnimationController _historyCameraAnimationController;
  Animation<LatLng>? _historyCameraCenterAnimation;
  Animation<double>? _historyCameraZoomAnimation;
  SuperadminVehicleHistory? _lastAutoFocusedHistory;
  String? _selectedHistorySegmentId;
  bool _didFitBounds = false;
  bool _isDrawerOpen = false;
  String? _selectedLiveVehicleKey;
  bool _replayOpen = false;
  bool _replayLoading = false;
  String? _replayError;
  String? _replayVehicleName;
  List<SuperadminReplayPoint> _replayPoints = const <SuperadminReplayPoint>[];
  int _replayIndex = 0;
  bool _replayPlaying = false;
  double _replaySpeed = 1;
  Timer? _replayTimer;
  List<double> _replayCumulativeDistanceKm = const <double>[];
  List<SuperadminReplayStopMarker> _replayStopMarkers =
      const <SuperadminReplayStopMarker>[];
  SuperadminReplayStopMarker? _selectedReplayStopMarker;
  bool _isVehicleAnimationTickerActive = false;
  double _currentZoom = 11;
  double _currentMapRotation = 0;
  _MapFilter _selectedFilter = _MapFilter.all;
  _MapLayerOption _selectedMapLayer = _primaryMapLayerOptions.first;
  Map<String, _AnimatedVehicleMotion> _animatedVehicleMotions =
      <String, _AnimatedVehicleMotion>{};
  late final ValueNotifier<DateTime> _vehicleMotionFrameNotifier =
      ValueNotifier<DateTime>(DateTime.now());
  _MapVisualSettings _visualSettings = _MapVisualSettings.defaults;

  @override
  void initState() {
    super.initState();
    _vehicleAnimationTicker = createTicker(_handleVehicleAnimationTick);
    _historyCameraAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
    )..addListener(_handleHistoryCameraAnimationTick);
    _loadPersistedMapSettings();
    _syncAnimatedVehicles(widget.vehicles, animateChanges: false);
  }

  void _loadPersistedMapSettings() {
    final cache = ref.read(localCacheProvider);
    final config = ref.read(currentLiveMapConfigProvider);
    var loaded = _MapVisualSettings.fromJsonString(
      cache.getString(config.visualSettingsStorageKey),
    );
    // Roles without overlay support (e.g. Admin) must never end up with
    // overlay flags persisted as `true` — that would trigger guarded
    // provider calls and throw at build time. Clamp to `false` here so the
    // settings drawer never offers, and the build never requests, an
    // unsupported overlay.
    if (!config.supportsGeofence ||
        !config.supportsPoi ||
        !config.supportsRoute) {
      loaded = loaded.copyWith(
        geofence: config.supportsGeofence && loaded.geofence,
        poi: config.supportsPoi && loaded.poi,
        route: config.supportsRoute && loaded.route,
      );
    }
    _visualSettings = loaded;
    _selectedMapLayer = _mapLayerOptionById(
          cache.getString(config.mapLayerStorageKey),
        ) ??
        _primaryMapLayerOptions.first;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scheduleFitVehicles();
  }

  @override
  void didUpdateWidget(covariant _LiveMap oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.vehicles == oldWidget.vehicles) {
      return;
    }

    _syncAnimatedVehicles(widget.vehicles, animateChanges: true);

    final previousVisibleVehicles = _visibleMapVehiclesFor(oldWidget.vehicles);
    final currentVisibleVehicles = _visibleMapVehicles();
    if (previousVisibleVehicles.isNotEmpty || currentVisibleVehicles.isEmpty) {
      return;
    }

    _didFitBounds = false;
    _scheduleFitVehicles();
  }

  @override
  void dispose() {
    _replayTimer?.cancel();
    _historyCameraAnimationController
      ..removeListener(_handleHistoryCameraAnimationTick)
      ..dispose();
    _vehicleAnimationTicker.dispose();
    _vehicleMotionFrameNotifier.dispose();
    super.dispose();
  }

  List<VehicleSummary> _visibleVehicles() {
    return _visibleVehiclesFor(widget.vehicles);
  }

  List<VehicleSummary> _visibleVehiclesFor(List<VehicleSummary> vehicles) {
    return switch (_selectedFilter) {
      _MapFilter.all => vehicles,
      _MapFilter.running => vehicles
          .where((vehicle) => !_isInactiveVehicle(vehicle))
          .where(_isRunningVehicle)
          .toList(growable: false),
      _MapFilter.stop => vehicles
          .where(
            (vehicle) =>
                !_isRunningVehicle(vehicle) && !_isInactiveVehicle(vehicle),
          )
          .toList(growable: false),
      _MapFilter.inactive =>
        vehicles.where(_isInactiveVehicle).toList(growable: false),
    };
  }

  List<VehicleSummary> _visibleMapVehicles() {
    return _visibleMapVehiclesFor(widget.vehicles);
  }

  List<VehicleSummary> _visibleMapVehiclesFor(List<VehicleSummary> vehicles) {
    return _visibleVehiclesFor(
      vehicles,
    ).where((vehicle) => vehicle.hasValidLocation).toList(growable: false);
  }

  void _syncAnimatedVehicles(
    List<VehicleSummary> vehicles, {
    required bool animateChanges,
  }) {
    final now = DateTime.now();
    final nextMotions = <String, _AnimatedVehicleMotion>{};
    final seenKeys = <String>{};

    for (final vehicle in vehicles) {
      final key = _animatedVehicleKey(vehicle);
      if (!seenKeys.add(key)) {
        continue;
      }

      final currentMotion = _animatedVehicleMotions[key];
      if (currentMotion == null ||
          !vehicle.hasValidLocation ||
          !currentMotion.vehicle.hasValidLocation) {
        nextMotions[key] = _AnimatedVehicleMotion.immediate(
          vehicle,
          bearingRadians: _seedVehicleBearingRadians(vehicle),
        );
        continue;
      }

      if (_isInactiveVehicle(vehicle)) {
        nextMotions[key] = _AnimatedVehicleMotion.immediate(
          vehicle,
          bearingRadians: _seedVehicleBearingRadians(vehicle) ??
              currentMotion.bearingRadians,
        );
        continue;
      }

      final settledMotion = currentMotion.settledAt(now);
      final distanceMeters = _coordinateDistanceMeters(
        fromLatitude: settledMotion.targetLatitude,
        fromLongitude: settledMotion.targetLongitude,
        toLatitude: vehicle.latitude,
        toLongitude: vehicle.longitude,
      );
      if (_shouldIgnoreVehicleLocationTransition(
        fromVehicle: settledMotion.vehicle,
        toVehicle: vehicle,
        distanceMeters: distanceMeters,
      )) {
        nextMotions[key] = settledMotion.withVehicle(vehicle);
        continue;
      }

      if (!animateChanges) {
        nextMotions[key] = _AnimatedVehicleMotion.immediate(
          vehicle,
          bearingRadians: _seedVehicleBearingRadians(vehicle) ??
              settledMotion.bearingRadians,
        );
        continue;
      }

      final currentPosition = settledMotion.positionAt(now);
      final duration = _vehicleMotionDuration(
        fromVehicle: settledMotion.vehicle,
        toVehicle: vehicle,
        fromPosition: currentPosition,
      );
      nextMotions[key] = duration == Duration.zero
          ? _AnimatedVehicleMotion.immediate(
              vehicle,
              bearingRadians: settledMotion.bearingRadians,
            )
          : _AnimatedVehicleMotion.animated(
              vehicle: vehicle,
              startLatitude: currentPosition.latitude,
              startLongitude: currentPosition.longitude,
              startedAt: now,
              duration: duration,
              previousBearingRadians: settledMotion.bearingRadians,
            );
    }

    _animatedVehicleMotions = nextMotions;
    if (_animatedVehicleMotions.values
        .any((motion) => motion.isAnimatingAt(now))) {
      _startVehicleAnimationTicker();
    } else {
      _stopVehicleAnimationTicker();
    }
  }

  void _handleVehicleAnimationTick(Duration _) {
    if (!mounted) {
      _stopVehicleAnimationTicker();
      return;
    }

    final now = DateTime.now();
    // Drive only the vehicle marker layer rebuild via the notifier so static
    // map layers (tiles, geofences, POIs, routes, history, replay) do not
    // rebuild on every animation frame.
    _vehicleMotionFrameNotifier.value = now;

    final hasActiveAnimations = _animatedVehicleMotions.values
        .any((motion) => motion.isAnimatingAt(now));
    if (!hasActiveAnimations) {
      _stopVehicleAnimationTicker();
    }
  }

  void _startVehicleAnimationTicker() {
    if (_isVehicleAnimationTickerActive) {
      return;
    }

    _vehicleAnimationTicker.start();
    _isVehicleAnimationTickerActive = true;
  }

  void _stopVehicleAnimationTicker() {
    if (!_isVehicleAnimationTickerActive) {
      return;
    }

    _vehicleAnimationTicker.stop();
    _isVehicleAnimationTickerActive = false;
  }

  bool get _isMapOrientationDefault =>
      _normalizedMapRotation(_currentMapRotation).abs() < 0.5;

  double _normalizedMapRotation(double rotation) {
    if (!rotation.isFinite) {
      return 0;
    }

    final normalized = ((rotation + 180) % 360) - 180;
    return normalized == -180 ? 180 : normalized;
  }

  void _resetMapOrientation() {
    try {
      final didReset = _mapController.rotate(0, id: 'north-reset');
      if (!mounted || (!didReset && _isMapOrientationDefault)) {
        return;
      }

      setState(() {
        _currentMapRotation = 0;
      });
    } catch (_) {
      // Future-proof fallback: if rotation is disabled or unsupported by the
      // active flutter_map configuration, leave the current camera unchanged.
    }
  }

  void _selectFilter(_MapFilter filter) {
    if (_selectedFilter == filter) {
      return;
    }

    setState(() {
      _selectedFilter = filter;
      _didFitBounds = false;
    });

    _scheduleFitVehicles();
  }

  void _openDrawer() {
    if (_isDrawerOpen) {
      return;
    }

    setState(() {
      _isDrawerOpen = true;
    });
  }

  void _closeDrawer() {
    if (!_isDrawerOpen) {
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _isDrawerOpen = false;
    });
  }

  Future<void> _openVehicleDrawer(VehicleSummary vehicle) {
    final selectedImei = vehicle.imei.trim();
    final scopedConfig = ref.read(currentLiveMapConfigProvider);
    return OpenVtsBottomSheet.show<void>(
      context: context,
      initialChildSize: 0.52,
      minChildSize: 0.34,
      maxChildSize: 0.92,
      snap: true,
      draggableChildBuilder: (context, scrollController) {
        return ProviderScope(
          overrides: [
            currentLiveMapConfigProvider.overrideWithValue(scopedConfig),
          ],
          child: _VehicleBottomDrawer(
            selectedImei: selectedImei,
            initialVehicle: vehicle,
            onReplayRequested: _handleReplayRequested,
            replayLoading: _replayLoading,
            replayError: _replayError,
            scrollController: scrollController,
          ),
        );
      },
    );
  }

  Future<_ReplayRequestResult> _handleReplayRequested(
    _ReplayRequest request,
  ) async {
    final imei = request.vehicle.imei.trim();
    if (imei.isEmpty) {
      const message = 'Vehicle IMEI is required to get replay.';
      if (mounted) {
        setState(() {
          _replayLoading = false;
          _replayError = message;
        });
      }
      return const _ReplayRequestResult(errorMessage: message);
    }

    setState(() {
      _replayLoading = true;
      _replayError = null;
      _selectedReplayStopMarker = null;
    });

    try {
      final replay =
          await ref.read(liveMapVehicleControllerProvider).getVehicleReplayByImei(
                imei: imei,
                from: request.from,
                to: request.to,
                maxPoints: 5000,
              );

      if (!mounted) {
        return const _ReplayRequestResult(errorMessage: null);
      }

      final points = replay.points;
      if (points.isEmpty) {
        const message = 'No replay data found for this range.';
        setState(() {
          _replayLoading = false;
          _replayError = message;
          _selectedReplayStopMarker = null;
        });
        return const _ReplayRequestResult(errorMessage: message);
      }

      _replayTimer?.cancel();
      final cumulativeDistanceKm = _buildReplayCumulativeDistanceKm(points);
      final stopMarkers = _deriveReplayStopMarkers(points);
      setState(() {
        _isDrawerOpen = false;
        _replayOpen = true;
        _replayLoading = false;
        _replayError = null;
        _replayVehicleName = _vehicleDisplayName(request.vehicle);
        _replayPoints = points;
        _replayIndex = 0;
        _replayPlaying = false;
        _replaySpeed = 1;
        _replayCumulativeDistanceKm = cumulativeDistanceKm;
        _replayStopMarkers = stopMarkers;
        _selectedReplayStopMarker = null;
      });

      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_replayOpen || !identical(_replayPoints, points)) {
          return;
        }

        _focusReplayPoints(points);
      });

      return const _ReplayRequestResult(started: true);
    } catch (error) {
      final message = _replayLoadErrorMessage(error);
      if (mounted) {
        setState(() {
          _replayLoading = false;
          _replayError = message;
        });
      }
      return _ReplayRequestResult(errorMessage: message);
    }
  }

  void _focusReplayPoints(List<SuperadminReplayPoint> points) {
    _focusHistoryPoints(
      _replayPathLatLngs(points),
      singleZoom: 17,
      maxZoom: 17,
      padding: const EdgeInsets.all(56),
    );
  }

  void _focusReplayPointAtIndex(int index, {bool immediate = false}) {
    if (!mounted || !_replayOpen || _replayPoints.isEmpty) {
      return;
    }

    final clampedIndex = index.clamp(0, _replayPoints.length - 1);
    final targetCenter = _replayPointLatLng(_replayPoints[clampedIndex]);
    final targetZoom = _currentZoom;

    if (immediate) {
      try {
        _historyCameraAnimationController.stop();
        _mapController.move(
          targetCenter,
          targetZoom,
          offset: Offset.zero,
          id: 'replay-camera-follow',
        );
      } catch (_) {}
      return;
    }

    _animateMapCameraTo(targetCenter, targetZoom, offset: Offset.zero);
  }

  void _toggleReplayPlayback() {
    if (_replayPlaying) {
      _pauseReplayPlayback();
      return;
    }

    if (_replayPoints.length < 2) {
      return;
    }

    setState(() {
      if (_replayIndex >= _replayPoints.length - 1) {
        _replayIndex = 0;
      }
      _replayPlaying = true;
    });
    _focusReplayPointAtIndex(_replayIndex);
    _scheduleReplayTick();
  }

  void _pauseReplayPlayback() {
    _replayTimer?.cancel();
    if (!_replayPlaying) {
      return;
    }

    setState(() {
      _replayPlaying = false;
    });
  }

  void _scheduleReplayTick() {
    _replayTimer?.cancel();
    if (!_replayPlaying || _replayPoints.length < 2) {
      return;
    }

    if (_replayIndex >= _replayPoints.length - 1) {
      setState(() {
        _replayPlaying = false;
      });
      return;
    }

    final currentPoint = _replayPoints[_replayIndex];
    final nextPoint = _replayPoints[_replayIndex + 1];
    final currentMs = _effectiveReplayTimeMs(currentPoint);
    final nextMs = _effectiveReplayTimeMs(nextPoint);
    final deltaMs = currentMs == null || nextMs == null
        ? 2000.0
        : (nextMs - currentMs).abs().toDouble();
    final baseDelay = math.min(500.0, deltaMs / 4);
    final delayMs = math.max(30.0, baseDelay / _replaySpeed).round();

    _replayTimer = Timer(Duration(milliseconds: delayMs), () {
      if (!mounted || !_replayPlaying) {
        return;
      }

      if (_replayIndex >= _replayPoints.length - 1) {
        setState(() {
          _replayPlaying = false;
        });
        return;
      }

      setState(() {
        _replayIndex += 1;
        if (_replayIndex >= _replayPoints.length - 1) {
          _replayPlaying = false;
        }
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_replayOpen || _replayPoints.isEmpty) {
          return;
        }

        _focusReplayPointAtIndex(_replayIndex);
      });

      if (_replayPlaying) {
        _scheduleReplayTick();
      }
    });
  }

  void _seekReplayIndex(int index) {
    if (_replayPoints.isEmpty) {
      return;
    }

    _replayTimer?.cancel();
    setState(() {
      _replayPlaying = false;
      _replayIndex = index.clamp(0, _replayPoints.length - 1);
    });
    _focusReplayPointAtIndex(_replayIndex);
  }

  void _setReplaySpeed(double speed) {
    setState(() {
      _replaySpeed = speed;
    });
    if (_replayPlaying) {
      _scheduleReplayTick();
    }
  }

  void _clearReplay() {
    _replayTimer?.cancel();
    setState(() {
      _replayOpen = false;
      _replayLoading = false;
      _replayError = null;
      _replayVehicleName = null;
      _replayPoints = const <SuperadminReplayPoint>[];
      _replayIndex = 0;
      _replayPlaying = false;
      _replaySpeed = 1;
      _replayCumulativeDistanceKm = const <double>[];
      _replayStopMarkers = const <SuperadminReplayStopMarker>[];
      _selectedReplayStopMarker = null;
      _didFitBounds = false;
    });
    _scheduleFitVehicles();
  }

  Future<void> _handleVehicleMarkerTap(VehicleSummary vehicle) async {
    _focusVehicle(vehicle);
    setState(() {
      _selectedLiveVehicleKey = _animatedVehicleKey(vehicle);
    });
    try {
      await _openVehicleDrawer(vehicle);
    } finally {
      if (mounted) {
        setState(() {
          _selectedLiveVehicleKey = null;
        });
      }
    }
  }

  void _focusVehicle(VehicleSummary vehicle) {
    if (!vehicle.hasValidLocation) {
      return;
    }

    final targetZoom = math.max(_currentZoom, 16.6);
    final targetCenter = LatLng(vehicle.latitude, vehicle.longitude);
    _animateMapCameraTo(
      targetCenter,
      targetZoom,
      offset: _vehicleFocusOffset(),
    );
  }

  Offset _vehicleFocusOffset() {
    final size = MediaQuery.sizeOf(context);
    final heightFactor = size.height < 760 ? 0.11 : 0.14;
    final maxShift = size.width < 390 ? 96.0 : 124.0;
    final shift = (size.height * heightFactor).clamp(56.0, maxShift);

    // Negative Y offset keeps the marker in the visible area above drawers.
    return Offset(0, -shift);
  }

  Future<void> _openLayerDrawer() {
    return _showMapActionSheet(
      backgroundColor: Colors.white,
      handleColor: Colors.black.withValues(alpha: 0.08),
      maxHeightFactor: 0.74,
      child: _MapLayerDrawer(
        initialLayerId: _selectedMapLayer.id,
        onLayerSelected: (layer) {
          if (!mounted) {
            return;
          }

          setState(() {
            _selectedMapLayer = layer;
          });
          unawaited(
            ref.read(localCacheProvider).setString(
                  ref.read(currentLiveMapConfigProvider).mapLayerStorageKey,
                  layer.id,
                ),
          );
        },
      ),
    );
  }

  Future<void> _openSettingsDrawer() {
    return _showMapActionSheet(
      backgroundColor: Colors.white,
      handleColor: Colors.black.withValues(alpha: 0.08),
      maxHeightFactor: 0.7,
      child: _MapSettingsDrawer(
        initialSettings: _visualSettings,
        config: ref.read(currentLiveMapConfigProvider),
        onChanged: (settings) {
          if (!mounted) {
            return;
          }

          setState(() {
            _visualSettings = settings;
          });
          unawaited(
            ref.read(localCacheProvider).setString(
                  ref
                      .read(currentLiveMapConfigProvider)
                      .visualSettingsStorageKey,
                  settings.toJsonString(),
                ),
          );
        },
      ),
    );
  }

  Future<void> _showMapActionSheet({
    required Widget child,
    required Color backgroundColor,
    required Color handleColor,
    required double maxHeightFactor,
  }) {
    final scopedConfig = ref.read(currentLiveMapConfigProvider);
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return ProviderScope(
          overrides: [
            currentLiveMapConfigProvider.overrideWithValue(scopedConfig),
          ],
          child: _MapActionDrawer(
            backgroundColor: backgroundColor,
            handleColor: handleColor,
            maxHeightFactor: maxHeightFactor,
            child: child,
          ),
        );
      },
    );
  }

  void _scheduleFitVehicles() {
    final visibleVehicles = _visibleMapVehicles();
    if (_replayOpen || _didFitBounds || visibleVehicles.isEmpty) {
      return;
    }

    _didFitBounds = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentVehicles = _visibleMapVehicles();
      if (!mounted || currentVehicles.isEmpty) {
        return;
      }

      final points = currentVehicles
          .map((vehicle) => LatLng(vehicle.latitude, vehicle.longitude))
          .toList(growable: false);

      if (points.length == 1) {
        _mapController.move(points.first, 13.4);
        return;
      }

      final isWide = MediaQuery.sizeOf(context).width >= 1100;
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: LatLngBounds.fromPoints(points),
          padding: isWide ? const EdgeInsets.all(72) : const EdgeInsets.all(40),
          maxZoom: 14.5,
        ),
      );
    });
  }

  List<_VehicleMarkerGroup> _buildVehicleMarkerGroups(
    List<VehicleSummary> vehicles,
  ) {
    final selectedKey = _selectedLiveVehicleKey;

    if (!_visualSettings.cluster ||
        vehicles.length < 2 ||
        _currentZoom >= 16.5) {
      return vehicles.map(_VehicleMarkerGroup.single).toList(growable: false);
    }

    const clusterCellSizePx = 72.0;
    final buckets = <String, List<VehicleSummary>>{};
    final standalone = <_VehicleMarkerGroup>[];
    for (final vehicle in vehicles) {
      if (selectedKey != null && _animatedVehicleKey(vehicle) == selectedKey) {
        // Pull selected vehicle out of clustering so it stays visible and
        // smoothly animated while the drawer is open (matches Web behavior).
        standalone.add(_VehicleMarkerGroup.single(vehicle));
        continue;
      }
      final worldPoint = _projectToWorldPixel(
        vehicle.latitude,
        vehicle.longitude,
        _currentZoom,
      );
      final cellX = (worldPoint.dx / clusterCellSizePx).floor();
      final cellY = (worldPoint.dy / clusterCellSizePx).floor();
      final bucketKey = '$cellX:$cellY';
      buckets.putIfAbsent(bucketKey, () => <VehicleSummary>[]).add(vehicle);
    }

    final clustered = buckets.values
        .map(_VehicleMarkerGroup.fromVehicles)
        .toList(growable: false);
    if (standalone.isEmpty) {
      return clustered;
    }
    return <_VehicleMarkerGroup>[...clustered, ...standalone];
  }

  void _focusCluster(_VehicleMarkerGroup cluster) {
    if (!cluster.isCluster) {
      return;
    }

    final points = cluster.vehicles
        .map((vehicle) => LatLng(vehicle.latitude, vehicle.longitude))
        .toList(growable: false);
    if (points.isEmpty) {
      return;
    }

    if (points.length == 1) {
      _mapController.move(points.first, (_currentZoom + 1.6).clamp(13.0, 17.2));
      return;
    }

    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: LatLngBounds.fromPoints(points),
        padding: const EdgeInsets.all(82),
        maxZoom: (_currentZoom + 2).clamp(13.5, 17.4),
      ),
    );
  }

  void _handleHistoryStateChanged(
    SuperadminVehicleHistoryState? previous,
    SuperadminVehicleHistoryState next,
  ) {
    final history = next.history;
    if (_replayOpen) {
      _lastAutoFocusedHistory = history;
      return;
    }

    if (history == null) {
      _lastAutoFocusedHistory = null;
      if (_selectedHistorySegmentId != null && mounted) {
        setState(() {
          _selectedHistorySegmentId = null;
        });
      }
      return;
    }

    if (identical(_lastAutoFocusedHistory, history)) {
      return;
    }

    _lastAutoFocusedHistory = history;
    if (_selectedHistorySegmentId != null && mounted) {
      setState(() {
        _selectedHistorySegmentId = null;
      });
    }

    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted ||
          !identical(
            ref.read(liveMapVehicleHistoryControllerProvider).history,
            history,
          )) {
        return;
      }

      _focusHistoryPoints(
        _historyPathLatLngs(history),
        singleZoom: 17,
        maxZoom: 17,
        padding: const EdgeInsets.all(76),
      );
    });
  }

  void _handleHistoryCameraAnimationTick() {
    final center = _historyCameraCenterAnimation?.value;
    final zoom = _historyCameraZoomAnimation?.value;
    if (center == null || zoom == null) {
      return;
    }

    try {
      _mapController.move(center, zoom, id: 'history-camera-animation');
    } catch (_) {
      _historyCameraAnimationController.stop();
    }
  }

  LatLng _applyCameraOffset({
    required MapCamera camera,
    required LatLng center,
    required double zoom,
    required Offset offset,
  }) {
    if (offset == Offset.zero) {
      return center;
    }

    final projectedCenter = camera.project(center, zoom);
    final offsetPoint = math.Point<double>(offset.dx, offset.dy);
    final offsetProjectedCenter = camera.rotatePoint(
      projectedCenter,
      projectedCenter - offsetPoint,
    );

    return camera.unproject(offsetProjectedCenter, zoom);
  }

  void _animateMapCameraTo(
    LatLng center,
    double zoom, {
    Offset offset = Offset.zero,
  }) {
    try {
      final camera = _mapController.camera;
      final targetCenter = _applyCameraOffset(
        camera: camera,
        center: center,
        zoom: zoom,
        offset: offset,
      );
      final curve = CurvedAnimation(
        parent: _historyCameraAnimationController,
        curve: Curves.easeOutCubic,
      );
      _historyCameraCenterAnimation = LatLngTween(
        begin: camera.center,
        end: targetCenter,
      ).animate(curve);
      _historyCameraZoomAnimation = Tween<double>(
        begin: camera.zoom,
        end: zoom,
      ).animate(curve);
      _historyCameraAnimationController.forward(from: 0);
    } catch (_) {
      try {
        _mapController.move(
          center,
          zoom,
          offset: offset,
          id: 'map-camera-fallback',
        );
      } catch (_) {}
    }
  }

  void _focusHistoryPoints(
    List<LatLng> points, {
    double singleZoom = 17,
    double maxZoom = 17,
    EdgeInsets padding = const EdgeInsets.all(82),
  }) {
    if (points.isEmpty) {
      return;
    }

    if (points.length == 1) {
      _animateMapCameraTo(points.first, singleZoom);
      return;
    }

    final cameraFit = CameraFit.bounds(
      bounds: LatLngBounds.fromPoints(points),
      padding: padding,
      maxZoom: maxZoom,
    );
    try {
      final fittedCamera = cameraFit.fit(_mapController.camera);
      _animateMapCameraTo(fittedCamera.center, fittedCamera.zoom);
    } catch (_) {
      try {
        _mapController.fitCamera(cameraFit);
      } catch (_) {}
    }
  }

  void _selectHistoryTarget(String id, List<LatLng> focusPoints) {
    if (_selectedHistorySegmentId != id) {
      setState(() {
        _selectedHistorySegmentId = id;
      });
    }

    _focusHistoryPoints(focusPoints);
  }

  void _handleHistoryEntrySelected(_HistoryTimelineEntry entry) {
    if (entry.focusPoints.isEmpty) {
      return;
    }

    _selectHistoryTarget(_historyTimelineEntryId(entry), entry.focusPoints);
  }

  Offset _projectToWorldPixel(double latitude, double longitude, double zoom) {
    final scale = 256.0 * math.pow(2.0, zoom).toDouble();
    final x = (longitude + 180.0) / 360.0 * scale;
    final sine = math.sin(latitude * math.pi / 180.0).clamp(-0.9999, 0.9999);
    final y = (0.5 - math.log((1 + sine) / (1 - sine)) / (4 * math.pi)) * scale;
    return Offset(x, y);
  }

  List<_MapOverlayStatusItem> _overlayStatusItems({
    required AsyncValue<List<SuperadminMapGeofence>> geofencesAsync,
    required AsyncValue<List<SuperadminMapPoi>> poisAsync,
    required AsyncValue<List<SuperadminMapRoute>> routesAsync,
  }) {
    final items = <_MapOverlayStatusItem>[];

    void addStatus<T>(String noun, AsyncValue<List<T>> value) {
      if (value.isLoading && !value.hasValue) {
        items.add(
          _MapOverlayStatusItem(
            message: 'Loading $noun',
            kind: _MapOverlayStatusKind.loading,
          ),
        );
        return;
      }

      if (value.hasError) {
        items.add(
          _MapOverlayStatusItem(
            message: '$noun unavailable',
            kind: _MapOverlayStatusKind.error,
          ),
        );
        return;
      }

      final data = value.valueOrNull;
      if (data != null && data.isEmpty) {
        items.add(
          _MapOverlayStatusItem(
            message: 'No $noun found',
            kind: _MapOverlayStatusKind.empty,
          ),
        );
      }
    }

    if (_visualSettings.geofence) {
      addStatus('geofences', geofencesAsync);
    }
    if (_visualSettings.poi) {
      addStatus('POIs', poisAsync);
    }
    if (_visualSettings.route) {
      addStatus('routes', routesAsync);
    }

    return items;
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<SuperadminVehicleHistoryState>(
      liveMapVehicleHistoryControllerProvider,
      _handleHistoryStateChanged,
    );

    final history = ref.watch(liveMapVehicleHistoryControllerProvider).history;
    final geofencesAsync = _visualSettings.geofence
        ? ref.watch(liveMapGeofencesProvider)
        : const AsyncData<List<SuperadminMapGeofence>>(
            <SuperadminMapGeofence>[],
          );
    final poisAsync = _visualSettings.poi
        ? ref.watch(liveMapPoisProvider)
        : const AsyncData<List<SuperadminMapPoi>>(<SuperadminMapPoi>[]);
    final routesAsync = _visualSettings.route
        ? ref.watch(liveMapRoutesProvider)
        : const AsyncData<List<SuperadminMapRoute>>(<SuperadminMapRoute>[]);

    final geofences =
        geofencesAsync.valueOrNull ?? const <SuperadminMapGeofence>[];
    final pois = poisAsync.valueOrNull ?? const <SuperadminMapPoi>[];
    final routes = routesAsync.valueOrNull ?? const <SuperadminMapRoute>[];
    // Cluster + visibility are derived from target (non-animated) positions so
    // they don't recompute per animation frame; the per-frame marker layer
    // below uses `_vehicleMotionFrameNotifier` to update only marker points.
    final visibleMapVehicles = _visibleMapVehicles();
    final vehicleMarkerGroups = _buildVehicleMarkerGroups(visibleMapVehicles);
    final replayActive = _replayOpen && _replayPoints.isNotEmpty;
    final replayPathPoints =
        replayActive ? _replayPathLatLngs(_replayPoints) : const <LatLng>[];
    final replayVisitedPoints = replayActive
        ? _replayVisitedPathLatLngs(_replayPoints, _replayIndex)
        : const <LatLng>[];
    final replayRoadPolylines = _historyRoadPolylines(replayPathPoints);
    final replayVisitedRoadPolylines = _historyRoadPolylines(
      replayVisitedPoints,
      selected: true,
    );
    final replayStartPoint = replayActive ? _replayPoints.first : null;
    final replayEndPoint = replayActive ? _replayPoints.last : null;
    final replayCurrentPoint = replayActive
        ? _replayPoints[_replayIndex.clamp(0, _replayPoints.length - 1)]
        : null;
    final replayCumulativeTripDistanceKm =
        replayActive && _replayCumulativeDistanceKm.isNotEmpty
            ? _replayCumulativeDistanceKm[_replayIndex.clamp(
                0,
                _replayCumulativeDistanceKm.length - 1,
              )]
            : null;
    final replayTripDistanceKm = replayCurrentPoint == null
        ? null
        : _replayTripDistanceKm(
            point: replayCurrentPoint,
            cumulativeDistanceKm: replayCumulativeTripDistanceKm,
          );
    final selectedReplayStopMarker =
        replayActive && _replayStopMarkers.contains(_selectedReplayStopMarker)
            ? _selectedReplayStopMarker
            : null;
    final routePolylines = routes
        .where((route) => route.hasPath)
        .map(
          (route) => Polyline(
            points: route.path,
            strokeWidth: 4.5,
            color: const Color(0xFF155EEF).withValues(alpha: 0.88),
          ),
        )
        .toList(growable: false);
    final geofencePolygons = geofences
        .where((geofence) => !geofence.isCircle && geofence.points.length >= 3)
        .map(
          (geofence) => Polygon(
            points: geofence.points,
            color: const Color(0xFF16A34A).withValues(alpha: 0.12),
            borderColor: const Color(0xFF15803D).withValues(alpha: 0.88),
            borderStrokeWidth: 2.2,
          ),
        )
        .toList(growable: false);
    final geofenceCircles = geofences
        .where(
          (geofence) =>
              geofence.isCircle &&
              geofence.center != null &&
              (geofence.radiusMeters ?? 0) > 0,
        )
        .map(
          (geofence) => CircleMarker(
            point: geofence.center!,
            radius: geofence.radiusMeters!,
            useRadiusInMeter: true,
            color: const Color(0xFF16A34A).withValues(alpha: 0.1),
            borderColor: const Color(0xFF15803D).withValues(alpha: 0.8),
            borderStrokeWidth: 2,
          ),
        )
        .toList(growable: false);
    final poiMarkers = pois
        .map(
          (poi) => Marker(
            point: poi.position,
            width: 36,
            height: 36,
            child: _PoiMarker(poi: poi),
          ),
        )
        .toList(growable: false);
    final historyPathPoints =
        replayActive ? const <LatLng>[] : _historyPathLatLngs(history);
    final historyRoadPolylines = _historyRoadPolylines(historyPathPoints);
    final selectedHistoryRoadPolylines = replayActive
        ? const <Polyline>[]
        : _selectedHistoryRoadPolylines(
            history,
            _selectedHistorySegmentId,
          );
    final historyStartPoint = replayActive ? null : history?.startPoint;
    final historyEndPoint = replayActive ? null : history?.endPoint;
    final historyStopMarkers = replayActive
        ? const <_HistoryDerivedStopMarker>[]
        : _historyDerivedStopMarkers(history);
    final overlayStatusItems = _overlayStatusItems(
      geofencesAsync: geofencesAsync,
      poisAsync: poisAsync,
      routesAsync: routesAsync,
    );
    final center = visibleMapVehicles.isEmpty
        ? const LatLng(28.6139, 77.2090)
        : LatLng(
            visibleMapVehicles.first.latitude,
            visibleMapVehicles.first.longitude,
          );

    return Stack(
      children: [
        Positioned.fill(
          child: ColoredBox(
            color: const Color(0xFFE8EEF5),
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: center,
                initialZoom: _currentZoom,
                onPositionChanged: (position, _) {
                  final nextZoom = position.zoom;
                  final nextRotation = position.rotation;
                  final shouldUpdateZoom =
                      (nextZoom - _currentZoom).abs() >= 0.01;
                  final shouldUpdateRotation = _normalizedMapRotation(
                        nextRotation - _currentMapRotation,
                      ).abs() >=
                      0.1;

                  if (!shouldUpdateZoom && !shouldUpdateRotation) {
                    return;
                  }

                  setState(() {
                    if (shouldUpdateZoom) {
                      _currentZoom = nextZoom;
                    }
                    if (shouldUpdateRotation) {
                      _currentMapRotation = nextRotation;
                    }
                  });
                },
              ),
              children: [
                TileLayer(
                  key: ValueKey<String>(_selectedMapLayer.id),
                  urlTemplate: _selectedMapLayer.url,
                  subdomains: _selectedMapLayer.subdomains,
                  userAgentPackageName: 'com.openvts.mobile',
                ),
                if (routePolylines.isNotEmpty)
                  PolylineLayer(polylines: routePolylines),
                if (geofencePolygons.isNotEmpty)
                  PolygonLayer(polygons: geofencePolygons),
                if (geofenceCircles.isNotEmpty)
                  CircleLayer(circles: geofenceCircles),
                if (poiMarkers.isNotEmpty) MarkerLayer(markers: poiMarkers),
                if (vehicleMarkerGroups.isNotEmpty)
                  ValueListenableBuilder<DateTime>(
                    valueListenable: _vehicleMotionFrameNotifier,
                    builder: (context, frameNow, _) {
                      return MarkerLayer(
                        markers: vehicleMarkerGroups
                            .map(
                              (group) => Marker(
                                point: group.isCluster
                                    ? group.center
                                    : (_animatedVehicleMotions[
                                                _animatedVehicleKey(
                                                    group.vehicle)] ??
                                            _AnimatedVehicleMotion.immediate(
                                              group.vehicle,
                                              bearingRadians:
                                                  _seedVehicleBearingRadians(
                                                group.vehicle,
                                              ),
                                            ))
                                        .positionAt(frameNow),
                                width: group.isCluster
                                    ? 62
                                    : _visualSettings.vehicleLabel
                                        ? 124
                                        : 100,
                                height: group.isCluster
                                    ? 62
                                    : _visualSettings.vehicleLabel
                                        ? 110
                                        : 100,
                                child: group.isCluster
                                    ? _VehicleClusterMarker(
                                        count: group.vehicles.length,
                                        onTap: () => _focusCluster(group),
                                      )
                                    : (() {
                                        final motion = _animatedVehicleMotions[
                                                _animatedVehicleKey(
                                                    group.vehicle)] ??
                                            _AnimatedVehicleMotion.immediate(
                                              group.vehicle,
                                              bearingRadians:
                                                  _seedVehicleBearingRadians(
                                                group.vehicle,
                                              ),
                                            );
                                        final status =
                                            _vehicleMarkerStatus(group.vehicle);
                                        return RepaintBoundary(
                                          child: _VehicleMarker(
                                            key: ValueKey<String>(
                                              _animatedVehicleKey(
                                                  group.vehicle),
                                            ),
                                            vehicle: group.vehicle,
                                            showLabel:
                                                _visualSettings.vehicleLabel,
                                            showRipple: _visualSettings.ripple,
                                            status: status,
                                            headingRadians:
                                                motion.bearingRadians,
                                            motionProgress:
                                                motion.progressAt(frameNow),
                                            isInMotion:
                                                motion.isAnimatingAt(frameNow),
                                            onTap: replayActive
                                                ? () {}
                                                : () => _handleVehicleMarkerTap(
                                                      group.vehicle,
                                                    ),
                                          ),
                                        );
                                      })(),
                              ),
                            )
                            .toList(growable: false),
                      );
                    },
                  ),
                if (replayRoadPolylines.isNotEmpty)
                  PolylineLayer(polylines: replayRoadPolylines),
                if (replayVisitedRoadPolylines.isNotEmpty)
                  PolylineLayer(polylines: replayVisitedRoadPolylines),
                if (replayStartPoint != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _replayPointLatLng(replayStartPoint),
                        width: 42,
                        height: 42,
                        child: const _ReplayEndpointMarker(isStart: true),
                      ),
                    ],
                  ),
                if (_replayStopMarkers.isNotEmpty)
                  MarkerLayer(
                    markers: _replayStopMarkers
                        .map(
                          (stop) => Marker(
                            point: LatLng(stop.latitude, stop.longitude),
                            width: 38,
                            height: 38,
                            child: _ReplayStopMarkerWidget(
                              isSelected: _selectedReplayStopMarker == stop,
                              onTap: () {
                                setState(() {
                                  _selectedReplayStopMarker = stop;
                                });
                              },
                            ),
                          ),
                        )
                        .toList(growable: false),
                  ),
                if (selectedReplayStopMarker != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: LatLng(
                          selectedReplayStopMarker.latitude,
                          selectedReplayStopMarker.longitude,
                        ),
                        width: 220,
                        height: 118,
                        alignment: Alignment.topCenter,
                        child: _ReplayStopPopup(
                          stop: selectedReplayStopMarker,
                          onClose: () {
                            setState(() {
                              _selectedReplayStopMarker = null;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                if (replayEndPoint != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _replayPointLatLng(replayEndPoint),
                        width: 42,
                        height: 42,
                        child: const _ReplayEndpointMarker(isStart: false),
                      ),
                    ],
                  ),
                if (replayCurrentPoint != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _replayPointLatLng(replayCurrentPoint),
                        width: 48,
                        height: 48,
                        child: _ReplayMovingMarker(
                          courseDegrees: replayCurrentPoint.course,
                        ),
                      ),
                    ],
                  ),
                if (historyRoadPolylines.isNotEmpty)
                  PolylineLayer(polylines: historyRoadPolylines),
                if (selectedHistoryRoadPolylines.isNotEmpty)
                  PolylineLayer(polylines: selectedHistoryRoadPolylines),
                if (historyStartPoint != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _historyPointLatLng(historyStartPoint),
                        width: 50,
                        height: 50,
                        child: _HistoryMapMarker(
                          kind: _HistoryMapMarkerKind.start,
                          isSelected: _selectedHistorySegmentId == 'start',
                          onTap: () => _selectHistoryTarget(
                            'start',
                            [_historyPointLatLng(historyStartPoint)],
                          ),
                        ),
                      ),
                    ],
                  ),
                if (historyStopMarkers.isNotEmpty)
                  MarkerLayer(
                    markers: historyStopMarkers
                        .map(
                          (stop) => Marker(
                            point: stop.point,
                            width: 50,
                            height: 50,
                            child: _HistoryMapMarker(
                              kind: _HistoryMapMarkerKind.stop,
                              isSelected: _selectedHistorySegmentId ==
                                  _historyStopSegmentId(stop.segment),
                              onTap: () {
                                final id = _historyStopSegmentId(stop.segment);
                                final focusPoints = _historyStopFocusLatLngs(
                                  history!,
                                  stop.segment,
                                );
                                _selectHistoryTarget(
                                  id,
                                  focusPoints.isEmpty
                                      ? [stop.point]
                                      : focusPoints,
                                );
                              },
                            ),
                          ),
                        )
                        .toList(growable: false),
                  ),
                if (historyEndPoint != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _historyPointLatLng(historyEndPoint),
                        width: 50,
                        height: 50,
                        child: _HistoryMapMarker(
                          kind: _HistoryMapMarkerKind.end,
                          isSelected: _selectedHistorySegmentId == 'end',
                          onTap: () => _selectHistoryTarget(
                            'end',
                            [_historyPointLatLng(historyEndPoint)],
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
        if (!replayActive)
          Positioned.fill(
            child: SafeArea(
              child: Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: const EdgeInsets.only(top: 12, left: 12),
                  child: _MapTelemetryFilters(
                    selectedFilter: _selectedFilter,
                    allCount: widget.allCount,
                    runningCount: widget.runningCount,
                    stopCount: widget.stopCount,
                    inactiveCount: widget.inactiveCount,
                    onSelected: _selectFilter,
                  ),
                ),
              ),
            ),
          ),
        if (overlayStatusItems.isNotEmpty && !replayActive)
          Positioned.fill(
            child: IgnorePointer(
              child: SafeArea(
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 64, left: 12),
                    child: _MapOverlayStatusPanel(items: overlayStatusItems),
                  ),
                ),
              ),
            ),
          ),
        if (replayActive && replayCurrentPoint != null)
          Positioned.fill(
            child: IgnorePointer(
              child: SafeArea(
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 12, top: 12),
                    child: _ReplayInfoHud(
                      vehicleName: _replayVehicleTitle(_replayVehicleName),
                      point: replayCurrentPoint,
                      tripDistanceKm: replayTripDistanceKm,
                      engineHours: _replayEngineHours(replayCurrentPoint),
                    ),
                  ),
                ),
              ),
            ),
          ),
        Positioned.fill(
          child: SafeArea(
            child: Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 14),
                child: _MapSideActionButtons(
                  showNorthReset: !_isMapOrientationDefault,
                  onNorthResetTap: _resetMapOrientation,
                  onLayerTap: _openLayerDrawer,
                  onSettingsTap: _openSettingsDrawer,
                ),
              ),
            ),
          ),
        ),
        if (!replayActive)
          Positioned.fill(
            child: _PersistentMapBottomDrawer(
              isOpen: _isDrawerOpen,
              vehicles: _visibleVehicles(),
              alerts: widget.alerts,
              isAlertsLoading: widget.isAlertsLoading,
              onClose: _closeDrawer,
              onVehicleSelected: _focusVehicle,
              selectedHistorySegmentId: _selectedHistorySegmentId,
              onHistoryEntrySelected: _handleHistoryEntrySelected,
            ),
          ),
        if (!_isDrawerOpen && !replayActive)
          Positioned.fill(
            child: SafeArea(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _BottomDrawerButton(onTap: _openDrawer),
                ),
              ),
            ),
          ),
        if (replayActive)
          Positioned.fill(
            child: _ReplayControlDrawer(
              points: _replayPoints,
              index: _replayIndex,
              isPlaying: _replayPlaying,
              speed: _replaySpeed,
              onSeek: _seekReplayIndex,
              onSkipStart: () => _seekReplayIndex(0),
              onTogglePlayback: _toggleReplayPlayback,
              onSkipEnd: () => _seekReplayIndex(_replayPoints.length - 1),
              onSpeedChanged: _setReplaySpeed,
              onClear: _clearReplay,
            ),
          ),
      ],
    );
  }
}

typedef _ReplayRequestHandler = Future<_ReplayRequestResult> Function(
  _ReplayRequest request,
);

class _ReplayRequest {
  const _ReplayRequest({
    required this.vehicle,
    required this.from,
    required this.to,
  });

  final VehicleSummary vehicle;
  final DateTime from;
  final DateTime to;
}

class _ReplayRequestResult {
  const _ReplayRequestResult({
    this.started = false,
    this.errorMessage,
  });

  final bool started;
  final String? errorMessage;
}

class _VehicleBottomDrawer extends ConsumerStatefulWidget {
  const _VehicleBottomDrawer({
    required this.selectedImei,
    required this.initialVehicle,
    required this.onReplayRequested,
    required this.replayLoading,
    required this.replayError,
    this.scrollController,
  });

  final String selectedImei;
  final VehicleSummary initialVehicle;
  final _ReplayRequestHandler onReplayRequested;
  final bool replayLoading;
  final String? replayError;
  final ScrollController? scrollController;

  @override
  ConsumerState<_VehicleBottomDrawer> createState() =>
      _VehicleBottomDrawerState();
}

class _VehicleBottomDrawerState extends ConsumerState<_VehicleBottomDrawer>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  var _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _tabController.addListener(_handleTabChanged);
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabChanged() {
    final nextIndex = _tabController.index;
    if (_selectedTabIndex == nextIndex) {
      return;
    }

    setState(() {
      _selectedTabIndex = nextIndex;
    });
  }

  @override
  Widget build(BuildContext context) {
    final liveVehicles = ref.watch(
      liveMapControllerProvider.select(
        (state) => state.telemetry.vehicles,
      ),
    );
    final liveVehicle = _resolveLiveVehicleSummary(
      selectedImei: widget.selectedImei,
      selectedVehicle: widget.initialVehicle,
      liveVehicles: liveVehicles,
    );

    return Column(
      children: [
        OpenVtsBottomSheet.dragRegion(
          context: context,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: _vehicleRunningIndicatorColor(
                      _isRunningVehicle(liveVehicle),
                    ),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _vehicleDisplayName(liveVehicle),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF141118),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _buildVehicleDrawerSubtitle(liveVehicle),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.black.withValues(alpha: 0.48),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        OpenVtsBottomSheet.dragRegion(
          context: context,
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: const Color(0xFF141118),
            unselectedLabelColor: Colors.black.withValues(alpha: 0.5),
            indicatorColor: const Color(0xFF141118),
            indicatorSize: TabBarIndicatorSize.label,
            dividerColor: Colors.black.withValues(alpha: 0.06),
            labelPadding: const EdgeInsets.symmetric(horizontal: 12),
            labelStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            tabs: const [
              Tab(text: 'Details'),
              Tab(text: 'Logs'),
              Tab(text: 'replay'),
              Tab(text: 'events'),
              Tab(text: 'Sensors'),
              Tab(text: 'Commands'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _VehicleDetailsTab(
                vehicle: liveVehicle,
                scrollController:
                    _selectedTabIndex == 0 ? widget.scrollController : null,
              ),
              _VehicleLogsTab(
                vehicle: liveVehicle,
                isActive: _selectedTabIndex == 1,
              ),
              _VehicleReplaySetupTab(
                vehicle: liveVehicle,
                initialLoading: widget.replayLoading,
                initialError: widget.replayError,
                onReplayRequested: widget.onReplayRequested,
                scrollController:
                    _selectedTabIndex == 2 ? widget.scrollController : null,
              ),
              _VehicleEventsTab(
                vehicle: liveVehicle,
                isActive: _selectedTabIndex == 3,
              ),
              _VehicleSensorsTab(
                vehicle: liveVehicle,
                isActive: _selectedTabIndex == 4,
              ),
              _VehicleCommandsTab(
                vehicle: liveVehicle,
                fallbackImei: widget.selectedImei,
                isActive: _selectedTabIndex == 5,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

VehicleSummary _resolveLiveVehicleSummary({
  required String selectedImei,
  required VehicleSummary selectedVehicle,
  required List<VehicleSummary> liveVehicles,
}) {
  final selectedImeiText = selectedImei.trim().isNotEmpty
      ? selectedImei.trim()
      : selectedVehicle.imei.trim();
  if (selectedImeiText.isNotEmpty) {
    for (final vehicle in liveVehicles) {
      if (vehicle.imei.trim() == selectedImeiText) {
        return vehicle;
      }
    }
  }

  final selectedId = selectedVehicle.id.trim();
  if (selectedId.isNotEmpty) {
    for (final vehicle in liveVehicles) {
      if (vehicle.id.trim() == selectedId) {
        return vehicle;
      }
    }
  }

  return selectedVehicle;
}

class _VehicleLogsTab extends ConsumerStatefulWidget {
  const _VehicleLogsTab({
    required this.vehicle,
    required this.isActive,
  });

  final VehicleSummary vehicle;
  final bool isActive;

  @override
  ConsumerState<_VehicleLogsTab> createState() => _VehicleLogsTabState();
}

class _VehicleLogsTabState extends ConsumerState<_VehicleLogsTab> {
  static const int _pageSize = 100;
  static const int _maxRows = 500;

  final _scrollController = ScrollController();
  var _apiLogs = const <SuperadminVehicleLog>[];
  var _liveLogs = const <SuperadminVehicleLog>[];
  String? _nextCursor;
  bool _loadingInitial = false;
  bool _loadingOlder = false;
  bool _socketConnected = false;
  String? _errorMessage;
  String? _socketErrorMessage;
  SocketConnection? _socketConnection;
  String? _socketImei;
  int _requestGeneration = 0;
  int _socketGeneration = 0;

  String get _imei => widget.vehicle.imei.trim();

  List<SuperadminVehicleLog> get _visibleLogs {
    return mergeSuperadminVehicleLogs(
      current: _apiLogs,
      incoming: _liveLogs,
      imei: _imei,
      cap: _maxRows,
      incomingFirst: true,
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.isActive) {
        _activate();
      }
    });
  }

  @override
  void didUpdateWidget(covariant _VehicleLogsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldImei = oldWidget.vehicle.imei.trim();
    final currentImei = _imei;

    if (oldImei != currentImei) {
      _resetForVehicle();
    }

    if (widget.isActive && (!oldWidget.isActive || oldImei != currentImei)) {
      _activate();
    } else if (!widget.isActive && oldWidget.isActive) {
      _disconnectSocket();
    }
  }

  @override
  void dispose() {
    _requestGeneration += 1;
    _disconnectSocket(updateState: false);
    _scrollController.dispose();
    super.dispose();
  }

  void _resetForVehicle() {
    _requestGeneration += 1;
    _disconnectSocket(updateState: false);
    setState(() {
      _apiLogs = const <SuperadminVehicleLog>[];
      _liveLogs = const <SuperadminVehicleLog>[];
      _nextCursor = null;
      _loadingInitial = false;
      _loadingOlder = false;
      _errorMessage = null;
      _socketErrorMessage = null;
      _socketConnected = false;
    });
  }

  void _activate() {
    final imei = _imei;
    if (imei.isEmpty) {
      return;
    }

    if (_apiLogs.isEmpty && !_loadingInitial) {
      unawaited(_loadInitialLogs());
    }
    unawaited(_ensureSocketConnection());
  }

  Future<void> _loadInitialLogs() async {
    final imei = _imei;
    if (imei.isEmpty || _loadingInitial) {
      return;
    }

    final generation = ++_requestGeneration;
    setState(() {
      _loadingInitial = true;
      _errorMessage = null;
    });

    try {
      final page =
          await ref.read(liveMapVehicleControllerProvider).getVehicleLogsByImei(
                imei,
                limit: _pageSize,
              );
      if (!mounted || generation != _requestGeneration || _imei != imei) {
        return;
      }

      setState(() {
        _apiLogs = mergeSuperadminVehicleLogs(
          current: const <SuperadminVehicleLog>[],
          incoming: page.items,
          imei: imei,
          cap: _maxRows,
        );
        _nextCursor = page.nextCursor;
        _loadingInitial = false;
      });
    } catch (error) {
      if (!mounted || generation != _requestGeneration) {
        return;
      }

      setState(() {
        _loadingInitial = false;
        _errorMessage = _formatVehicleLogError(error);
      });
    }
  }

  Future<void> _loadOlderLogs() async {
    final imei = _imei;
    final cursor = _nextCursor?.trim() ?? '';
    if (imei.isEmpty || cursor.isEmpty || _loadingOlder) {
      return;
    }

    final generation = _requestGeneration;
    setState(() {
      _loadingOlder = true;
      _errorMessage = null;
    });

    try {
      final page =
          await ref.read(liveMapVehicleControllerProvider).getVehicleLogsByImei(
                imei,
                limit: _pageSize,
                beforeId: cursor,
              );
      if (!mounted || generation != _requestGeneration || _imei != imei) {
        return;
      }

      setState(() {
        _apiLogs = mergeSuperadminVehicleLogs(
          current: _apiLogs,
          incoming: page.items,
          imei: imei,
          cap: _maxRows,
          incomingFirst: false,
        );
        _nextCursor = page.nextCursor;
        _loadingOlder = false;
      });
    } catch (error) {
      if (!mounted || generation != _requestGeneration) {
        return;
      }

      setState(() {
        _loadingOlder = false;
        _errorMessage = _formatVehicleLogError(error);
      });
    }
  }

  Future<void> _ensureSocketConnection() async {
    final imei = _imei;
    if (imei.isEmpty || !widget.isActive) {
      return;
    }
    if (_socketConnection != null && _socketImei == imei) {
      return;
    }

    _disconnectSocket(updateState: false);
    final generation = ++_socketGeneration;

    try {
      final connection =
          await ref
              .read(liveMapSocketControllerProvider)
              .connectTelemetry();
      if (!mounted ||
          generation != _socketGeneration ||
          !widget.isActive ||
          _imei != imei) {
        connection.disconnect();
        return;
      }

      _socketConnection = connection;
      _socketImei = imei;
      connection.onConnect(() => _handleSocketConnected(imei));
      connection.onDisconnect((_) => _handleSocketDisconnected(imei));
      connection.onError((error) => _handleSocketError(imei, error));
      connection.on('telemetry:update', _handleTelemetryUpdate);
      connection.on('telemetry:snapshot', _handleTelemetrySnapshot);
      connection.on(
          'telemetry:error', (error) => _handleSocketError(imei, error));

      if (connection.isConnected) {
        _handleSocketConnected(imei);
      }
    } catch (error) {
      if (!mounted || generation != _socketGeneration) {
        return;
      }

      setState(() {
        _socketConnected = false;
        _socketErrorMessage = _formatVehicleLogError(error);
      });
    }
  }

  void _disconnectSocket({bool updateState = true}) {
    _socketGeneration += 1;
    final connection = _socketConnection;
    _socketConnection = null;
    _socketImei = null;
    connection?.disconnect();

    if (updateState && mounted) {
      setState(() {
        _socketConnected = false;
      });
    } else {
      _socketConnected = false;
    }
  }

  void _handleSocketConnected(String imei) {
    if (!mounted || _socketImei != imei || _imei != imei) {
      return;
    }

    _socketConnection?.emit('telemetry:subscribe', <String, dynamic>{
      'imeis': <String>[imei],
    });
    setState(() {
      _socketConnected = true;
      _socketErrorMessage = null;
    });
  }

  void _handleSocketDisconnected(String imei) {
    if (!mounted || _socketImei != imei) {
      return;
    }

    setState(() {
      _socketConnected = false;
    });
  }

  void _handleSocketError(String imei, dynamic error) {
    if (!mounted || _socketImei != imei) {
      return;
    }

    setState(() {
      _socketErrorMessage = _formatVehicleLogError(error);
    });
  }

  void _handleTelemetryUpdate(dynamic data) {
    final log =
        ref.read(liveMapVehicleControllerProvider).parseTelemetryLogPayload(data);
    if (log == null) {
      return;
    }

    _appendLiveLogs(<SuperadminVehicleLog>[log]);
  }

  void _handleTelemetrySnapshot(dynamic data) {
    final logs = ref
        .read(liveMapVehicleControllerProvider)
        .parseTelemetryLogListPayload(data);
    _appendLiveLogs(logs);
  }

  void _appendLiveLogs(Iterable<SuperadminVehicleLog> logs) {
    final imei = _imei;
    if (imei.isEmpty) {
      return;
    }

    final accepted =
        logs.where((log) => log.imei.trim() == imei).toList(growable: false);
    if (accepted.isEmpty || !mounted) {
      return;
    }

    setState(() {
      _liveLogs = mergeSuperadminVehicleLogs(
        current: _liveLogs,
        incoming: accepted,
        imei: imei,
        cap: _maxRows,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final imei = _imei;
    if (imei.isEmpty) {
      return const _VehicleDrawerPlaceholderTab(
        icon: Icons.receipt_long_rounded,
        title: 'Logs unavailable',
        message: 'Vehicle IMEI is required to load telemetry logs.',
      );
    }

    final logs = _visibleLogs;
    final statusLabel = _socketConnected ? 'Live' : 'Connecting';
    final statusColor = _socketConnected
        ? const Color(0xFF20B15A)
        : Colors.black.withValues(alpha: 0.42);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
          child: Row(
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                statusLabel,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: statusColor,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${logs.length} rows',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.black.withValues(alpha: 0.42),
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: _nextCursor == null || _loadingOlder
                    ? null
                    : () => unawaited(_loadOlderLogs()),
                icon: _loadingOlder
                    ? const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.keyboard_double_arrow_down_rounded),
                label: Text(_loadingOlder ? 'Loading' : 'Older'),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  foregroundColor: const Color(0xFF141118),
                  textStyle: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_errorMessage != null || _socketErrorMessage != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 6),
            child: _VehicleDetailsNotice(
              message: _errorMessage ?? _socketErrorMessage!,
              icon: Icons.error_outline_rounded,
              onRetry: _errorMessage == null
                  ? null
                  : () => unawaited(_loadInitialLogs()),
            ),
          ),
        Expanded(
          child: _loadingInitial && logs.isEmpty
              ? const Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.4),
                  ),
                )
              : logs.isEmpty
                  ? const _VehicleDrawerPlaceholderTab(
                      icon: Icons.receipt_long_rounded,
                      title: 'No logs yet',
                      message:
                          'Database and live telemetry logs will appear here.',
                    )
                  : ListView.separated(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(10, 0, 10, 14),
                      itemCount: logs.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 6),
                      itemBuilder: (context, index) {
                        return _VehicleLogListRow(
                          log: logs[index],
                          onTap: () => _showVehicleLogDetails(
                            context,
                            logs[index],
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}

class _VehicleLogListRow extends ConsumerWidget {
  const _VehicleLogListRow({
    required this.log,
    required this.onTap,
  });

  final SuperadminVehicleLog log;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unitFormatter = ref.watch(unitFormatterProvider);
    final ignition = log.ignition ?? log.acc;
    return Material(
      color: const Color(0xFFF7F7F8),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          _formatVehicleLogTime(log.displayTime),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF141118),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            log.packetType.isEmpty ? 'packet' : log.packetType,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Colors.black.withValues(alpha: 0.50),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _formatVehicleLogLatLng(log),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.black.withValues(alpha: 0.45),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _VehicleLogPill(
                label: _formatVehicleLogSpeed(log.speedKph, unitFormatter: unitFormatter),
              ),
              const SizedBox(width: 6),
              _VehicleLogPill(
                label: _formatVehicleLogBool(ignition,
                    trueLabel: 'IGN On', falseLabel: 'IGN Off'),
                isPositive: ignition,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VehicleLogPill extends StatelessWidget {
  const _VehicleLogPill({
    required this.label,
    this.isPositive,
  });

  final String label;
  final bool? isPositive;

  @override
  Widget build(BuildContext context) {
    final color = isPositive == true
        ? const Color(0xFF20B15A)
        : isPositive == false
            ? const Color(0xFFB42318)
            : const Color(0xFF141118);
    return Container(
      constraints: const BoxConstraints(minWidth: 48),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w900,
          color: color,
        ),
      ),
    );
  }
}

void _showVehicleLogDetails(BuildContext context, SuperadminVehicleLog log) {
  showDialog<void>(
    context: context,
    builder: (context) => _VehicleLogDetailsDialog(log: log),
  );
}

class _VehicleLogDetailsDialog extends StatelessWidget {
  const _VehicleLogDetailsDialog({required this.log});

  final SuperadminVehicleLog log;

  @override
  Widget build(BuildContext context) {
    final attributesText =
        log.attributes == null ? null : _formatVehicleLogJson(log.attributes);
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 620),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 8, 8),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Telemetry log',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF141118),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    visualDensity: VisualDensity.compact,
                    splashRadius: 18,
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                children: [
                  _VehicleLogDetailGrid(log: log),
                  if (log.rawPacket.trim().isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _VehicleLogCodeBlock(
                      title: 'Raw packet',
                      value: log.rawPacket,
                    ),
                  ],
                  if (attributesText != null) ...[
                    const SizedBox(height: 12),
                    _VehicleLogCodeBlock(
                      title: 'Attributes',
                      value: attributesText,
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: OpenVtsButton(
                label: 'Close',
                onPressed: () => Navigator.of(context).pop(),
                height: 40,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VehicleLogDetailGrid extends ConsumerWidget {
  const _VehicleLogDetailGrid({required this.log});

  final SuperadminVehicleLog log;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unitFormatter = ref.watch(unitFormatterProvider);
    final rows = <({String label, String value})>[
      (
        label: 'Source',
        value: log.source == SuperadminVehicleLogSource.live
            ? 'Socket'
            : 'Database'
      ),
      (label: 'IMEI', value: log.imei.isEmpty ? '--' : log.imei),
      (label: 'Server time', value: _formatVehicleLogDateTime(log.serverTime)),
      (label: 'Device time', value: _formatVehicleLogDateTime(log.deviceTime)),
      (
        label: 'Packet type',
        value: log.packetType.isEmpty ? '--' : log.packetType
      ),
      (label: 'Protocol', value: log.protocol.isEmpty ? '--' : log.protocol),
      (label: 'Speed', value: _formatVehicleLogSpeed(log.speedKph, unitFormatter: unitFormatter)),
      (label: 'Ignition', value: _formatVehicleLogBool(log.ignition)),
      (label: 'ACC', value: _formatVehicleLogBool(log.acc)),
      (label: 'Latitude', value: _formatVehicleLogCoordinate(log.latitude)),
      (label: 'Longitude', value: _formatVehicleLogCoordinate(log.longitude)),
      (
        label: 'Altitude',
        value: log.altitude == null
            ? '--'
            : '${_formatVehicleMetricNumber(log.altitude!, 0)} m'
      ),
      (label: 'Satellites', value: log.satellites?.toString() ?? '--'),
      (
        label: 'Valid',
        value:
            _formatVehicleLogBool(log.valid, trueLabel: 'Yes', falseLabel: 'No')
      ),
      (
        label: 'Course',
        value: log.course == null
            ? '--'
            : '${_formatVehicleMetricNumber(log.course!, 0)} deg'
      ),
      (
        label: 'Distance',
        value: _formatVehicleMetricDistance(null,
            fallback: log.distance, fractionDigits: 3, unitFormatter: unitFormatter)
      ),
      (
        label: 'Odometer',
        value: _formatVehicleMetricDistance(null,
            fallback: log.odometer, fractionDigits: 1, unitFormatter: unitFormatter)
      ),
      (
        label: 'Engine hours',
        value: _formatVehicleEngineHoursValue(log.engineHours)
      ),
      (
        label: 'Total engine hours',
        value: _formatVehicleEngineHoursValue(log.totalEngineHours)
      ),
      (label: 'Created', value: _formatVehicleLogDateTime(log.createdAt)),
    ];

    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
      ),
      child: Column(
        children: [
          for (var index = 0; index < rows.length; index++)
            _VehicleLogDetailRow(
              label: rows[index].label,
              value: rows[index].value,
              showDivider: index != rows.length - 1,
            ),
        ],
      ),
    );
  }
}

class _VehicleLogDetailRow extends StatelessWidget {
  const _VehicleLogDetailRow({
    required this.label,
    required this.value,
    required this.showDivider,
  });

  final String label;
  final String value;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: showDivider
            ? Border(
                bottom: BorderSide(color: Colors.black.withValues(alpha: 0.05)),
              )
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 120,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Colors.black.withValues(alpha: 0.50),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: SelectableText(
                value,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF141118),
                  height: 1.25,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VehicleLogCodeBlock extends StatelessWidget {
  const _VehicleLogCodeBlock({
    required this.title,
    required this.value,
  });

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: Color(0xFF141118),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxHeight: 180),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF111827),
            borderRadius: BorderRadius.circular(12),
          ),
          child: SingleChildScrollView(
            child: SelectableText(
              value,
              style: const TextStyle(
                fontSize: 10,
                height: 1.35,
                color: Colors.white,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _VehicleEventsTab extends ConsumerStatefulWidget {
  const _VehicleEventsTab({
    required this.vehicle,
    required this.isActive,
  });

  final VehicleSummary vehicle;
  final bool isActive;

  @override
  ConsumerState<_VehicleEventsTab> createState() => _VehicleEventsTabState();
}

class _VehicleEventsTabState extends ConsumerState<_VehicleEventsTab> {
  static const int _pageSize = 50;
  static const int _maxRows = 300;

  final _scrollController = ScrollController();
  var _apiEvents = const <AppNotification>[];
  var _liveEvents = const <AppNotification>[];
  String? _nextCursor;
  bool _loadingInitial = false;
  bool _loadingOlder = false;
  bool _socketConnected = false;
  String? _errorMessage;
  String? _socketErrorMessage;
  SocketConnection? _socketConnection;
  String? _socketImei;
  int _requestGeneration = 0;
  int _socketGeneration = 0;

  String get _imei => widget.vehicle.imei.trim();

  List<AppNotification> get _visibleEvents {
    return mergeSuperadminVehicleEvents(
      current: _apiEvents,
      incoming: _liveEvents,
      imei: _imei,
      cap: _maxRows,
      incomingFirst: true,
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.isActive) {
        _activate();
      }
    });
  }

  @override
  void didUpdateWidget(covariant _VehicleEventsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldImei = oldWidget.vehicle.imei.trim();
    final currentImei = _imei;

    if (oldImei != currentImei) {
      _resetForVehicle();
    }

    if (widget.isActive && (!oldWidget.isActive || oldImei != currentImei)) {
      _activate();
    } else if (!widget.isActive && oldWidget.isActive) {
      _disconnectSocket();
    }
  }

  @override
  void dispose() {
    _requestGeneration += 1;
    _disconnectSocket(updateState: false);
    _scrollController.dispose();
    super.dispose();
  }

  void _resetForVehicle() {
    _requestGeneration += 1;
    _disconnectSocket(updateState: false);
    setState(() {
      _apiEvents = const <AppNotification>[];
      _liveEvents = const <AppNotification>[];
      _nextCursor = null;
      _loadingInitial = false;
      _loadingOlder = false;
      _errorMessage = null;
      _socketErrorMessage = null;
      _socketConnected = false;
    });
  }

  void _activate() {
    final imei = _imei;
    if (imei.isEmpty) {
      return;
    }

    if (_apiEvents.isEmpty && !_loadingInitial) {
      unawaited(_loadInitialEvents());
    }
    unawaited(_ensureSocketConnection());
  }

  Future<void> _loadInitialEvents() async {
    final imei = _imei;
    if (imei.isEmpty || _loadingInitial) {
      return;
    }

    final generation = ++_requestGeneration;
    setState(() {
      _loadingInitial = true;
      _errorMessage = null;
    });

    try {
      final page =
          await ref.read(liveMapVehicleControllerProvider).getVehicleEventsByImei(
                imei,
                limit: _pageSize,
              );
      if (!mounted || generation != _requestGeneration || _imei != imei) {
        return;
      }

      setState(() {
        _apiEvents = mergeSuperadminVehicleEvents(
          current: const <AppNotification>[],
          incoming: page.items,
          imei: imei,
          cap: _maxRows,
        );
        _nextCursor = page.nextCursor;
        _loadingInitial = false;
      });
    } catch (error) {
      if (!mounted || generation != _requestGeneration) {
        return;
      }

      setState(() {
        _loadingInitial = false;
        _errorMessage = _formatVehicleLogError(error);
      });
    }
  }

  Future<void> _loadOlderEvents() async {
    final imei = _imei;
    final cursor = _nextCursor?.trim() ?? '';
    if (imei.isEmpty || cursor.isEmpty || _loadingOlder) {
      return;
    }

    final generation = _requestGeneration;
    setState(() {
      _loadingOlder = true;
      _errorMessage = null;
    });

    try {
      final page =
          await ref.read(liveMapVehicleControllerProvider).getVehicleEventsByImei(
                imei,
                limit: _pageSize,
                beforeId: cursor,
              );
      if (!mounted || generation != _requestGeneration || _imei != imei) {
        return;
      }

      setState(() {
        _apiEvents = mergeSuperadminVehicleEvents(
          current: _apiEvents,
          incoming: page.items,
          imei: imei,
          cap: _maxRows,
          incomingFirst: false,
        );
        _nextCursor = page.nextCursor;
        _loadingOlder = false;
      });
    } catch (error) {
      if (!mounted || generation != _requestGeneration) {
        return;
      }

      setState(() {
        _loadingOlder = false;
        _errorMessage = _formatVehicleLogError(error);
      });
    }
  }

  Future<void> _ensureSocketConnection() async {
    final imei = _imei;
    if (imei.isEmpty || !widget.isActive) {
      return;
    }
    if (_socketConnection != null && _socketImei == imei) {
      return;
    }

    _disconnectSocket(updateState: false);
    final generation = ++_socketGeneration;

    try {
      final connection =
          await ref
              .read(liveMapSocketControllerProvider)
              .connectNotifications();
      if (!mounted ||
          generation != _socketGeneration ||
          !widget.isActive ||
          _imei != imei) {
        connection.disconnect();
        return;
      }

      _socketConnection = connection;
      _socketImei = imei;
      connection.onConnect(() => _handleSocketConnected(imei));
      connection.onDisconnect((_) => _handleSocketDisconnected(imei));
      connection.onError((error) => _handleSocketError(imei, error));
      connection.on('notif:new', _handleNotificationNew);

      if (connection.isConnected) {
        _handleSocketConnected(imei);
      }
    } catch (error) {
      if (!mounted || generation != _socketGeneration) {
        return;
      }

      setState(() {
        _socketConnected = false;
        _socketErrorMessage = _formatVehicleLogError(error);
      });
    }
  }

  void _disconnectSocket({bool updateState = true}) {
    _socketGeneration += 1;
    final connection = _socketConnection;
    _socketConnection = null;
    _socketImei = null;
    connection?.disconnect();

    if (updateState && mounted) {
      setState(() {
        _socketConnected = false;
      });
    } else {
      _socketConnected = false;
    }
  }

  void _handleSocketConnected(String imei) {
    if (!mounted || _socketImei != imei || _imei != imei) {
      return;
    }

    _socketConnection?.emit('notif:subscribe', <String, dynamic>{
      'imeis': <String>[imei],
    });
    setState(() {
      _socketConnected = true;
      _socketErrorMessage = null;
    });
  }

  void _handleSocketDisconnected(String imei) {
    if (!mounted || _socketImei != imei) {
      return;
    }

    setState(() {
      _socketConnected = false;
    });
  }

  void _handleSocketError(String imei, dynamic error) {
    if (!mounted || _socketImei != imei) {
      return;
    }

    setState(() {
      _socketErrorMessage = _formatVehicleLogError(error);
    });
  }

  void _handleNotificationNew(dynamic data) {
    final imei = _imei;
    if (imei.isEmpty) {
      return;
    }

    final event = ref
        .read(liveMapVehicleControllerProvider)
        .parseVehicleEventPayload(data, imei: imei);
    if (event == null || (event.vehicleImei?.trim() ?? '') != imei) {
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _liveEvents = mergeSuperadminVehicleEvents(
        current: _liveEvents,
        incoming: <AppNotification>[event],
        imei: imei,
        cap: _maxRows,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final imei = _imei;
    if (imei.isEmpty) {
      return const _VehicleDrawerPlaceholderTab(
        icon: Icons.event_note_rounded,
        title: 'Events unavailable',
        message: 'Vehicle IMEI is required to load events.',
      );
    }

    final events = _visibleEvents;
    final statusLabel = _socketConnected ? 'Live' : 'Connecting';
    final statusColor = _socketConnected
        ? const Color(0xFF20B15A)
        : Colors.black.withValues(alpha: 0.42);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
          child: Row(
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                statusLabel,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: statusColor,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${events.length} events',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.black.withValues(alpha: 0.42),
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: _nextCursor == null || _loadingOlder
                    ? null
                    : () => unawaited(_loadOlderEvents()),
                icon: _loadingOlder
                    ? const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.keyboard_double_arrow_down_rounded),
                label: Text(_loadingOlder ? 'Loading' : 'Older'),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  foregroundColor: const Color(0xFF141118),
                  textStyle: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_errorMessage != null || _socketErrorMessage != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 6),
            child: _VehicleDetailsNotice(
              message: _errorMessage ?? _socketErrorMessage!,
              icon: Icons.error_outline_rounded,
              onRetry: _errorMessage == null
                  ? null
                  : () => unawaited(_loadInitialEvents()),
            ),
          ),
        Expanded(
          child: _loadingInitial && events.isEmpty
              ? const Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.4),
                  ),
                )
              : events.isEmpty
                  ? const _VehicleDrawerPlaceholderTab(
                      icon: Icons.event_note_rounded,
                      title: 'No events yet',
                      message: 'Vehicle events will appear here.',
                    )
                  : ListView.separated(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(10, 0, 10, 14),
                      itemCount: events.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 6),
                      itemBuilder: (context, index) {
                        return _VehicleEventListRow(
                          event: events[index],
                          onTap: () => _showVehicleEventDetails(
                            context,
                            events[index],
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}

class _VehicleEventListRow extends StatelessWidget {
  const _VehicleEventListRow({
    required this.event,
    required this.onTap,
  });

  final AppNotification event;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final visuals = _resolveAlertVisuals(event);
    final title = _vehicleEventTitle(event);
    final severity = _vehicleEventSeverity(event);

    return Material(
      color: const Color(0xFFF7F7F8),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: visuals.backgroundColor,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(visuals.icon, size: 16, color: visuals.iconColor),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF141118),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatVehicleEventTime(event.createdAt),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Colors.black.withValues(alpha: 0.45),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        _VehicleEventSeverityPill(
                          label: severity,
                          color: visuals.dotColor,
                        ),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            event.message.trim().isEmpty
                                ? 'OpenVTS event'
                                : event.message.trim(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.black.withValues(alpha: 0.52),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VehicleEventSeverityPill extends StatelessWidget {
  const _VehicleEventSeverityPill({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 52),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w900,
          color: color,
        ),
      ),
    );
  }
}

void _showVehicleEventDetails(
  BuildContext context,
  AppNotification event,
) {
  showDialog<void>(
    context: context,
    builder: (context) => _VehicleEventDetailsDialog(event: event),
  );
}

class _VehicleEventDetailsDialog extends StatelessWidget {
  const _VehicleEventDetailsDialog({required this.event});

  final AppNotification event;

  @override
  Widget build(BuildContext context) {
    final metadataText =
        event.metadata.isEmpty ? null : _formatVehicleLogJson(event.metadata);
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 620),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 8, 8),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Vehicle event',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF141118),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    visualDensity: VisualDensity.compact,
                    splashRadius: 18,
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                children: [
                  _VehicleEventDetailGrid(event: event),
                  if (metadataText != null) ...[
                    const SizedBox(height: 12),
                    _VehicleLogCodeBlock(
                      title: 'Metadata',
                      value: metadataText,
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: OpenVtsButton(
                label: 'Close',
                onPressed: () => Navigator.of(context).pop(),
                height: 40,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VehicleEventDetailGrid extends StatelessWidget {
  const _VehicleEventDetailGrid({required this.event});

  final AppNotification event;

  @override
  Widget build(BuildContext context) {
    final rows = <({String label, String value})>[
      (label: 'Title', value: event.title.trim()),
      (label: 'Category', value: event.category?.trim() ?? '--'),
      (label: 'Severity', value: event.severity?.trim() ?? '--'),
      (label: 'Message', value: event.message.trim()),
      (label: 'IMEI', value: event.vehicleImei?.trim() ?? '--'),
      (label: 'Context', value: event.contextLabel?.trim() ?? '--'),
      (label: 'Created', value: _formatVehicleEventDateTime(event.createdAt)),
      (label: 'Read', value: event.isRead ? 'Yes' : 'No'),
      (label: 'ID', value: event.id > 0 ? event.id.toString() : '--'),
      (
        label: 'Event ID',
        value: event.eventId == null ? '--' : event.eventId.toString()
      ),
      (
        label: 'Log ID',
        value: event.logId == null ? '--' : event.logId.toString()
      ),
      (
        label: 'Dedupe',
        value: event.dedupeKey?.trim().isEmpty ?? true
            ? event.dedupeIdentity
            : event.dedupeKey!.trim()
      ),
    ];

    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
      ),
      child: Column(
        children: [
          for (var index = 0; index < rows.length; index++)
            _VehicleLogDetailRow(
              label: rows[index].label,
              value: rows[index].value.isEmpty ? '--' : rows[index].value,
              showDivider: index != rows.length - 1,
            ),
        ],
      ),
    );
  }
}

class _VehicleSensorsTab extends ConsumerStatefulWidget {
  const _VehicleSensorsTab({
    required this.vehicle,
    required this.isActive,
  });

  final VehicleSummary vehicle;
  final bool isActive;

  @override
  ConsumerState<_VehicleSensorsTab> createState() => _VehicleSensorsTabState();
}

class _VehicleSensorsTabState extends ConsumerState<_VehicleSensorsTab> {
  final _scrollController = ScrollController();
  var _sensors = const <SuperadminVehicleSensor>[];
  SuperadminVehicleSensorTelemetryMeta? _telemetryMeta;
  int _totalCount = 0;
  bool _truncated = false;
  bool _loading = false;
  bool _hasLoaded = false;
  String? _errorMessage;
  int _requestGeneration = 0;

  String get _imei => widget.vehicle.imei.trim();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.isActive) {
        _activate();
      }
    });
  }

  @override
  void didUpdateWidget(covariant _VehicleSensorsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldImei = oldWidget.vehicle.imei.trim();
    final currentImei = _imei;

    if (oldImei != currentImei) {
      _resetForVehicle();
    }

    if (widget.isActive && (!oldWidget.isActive || oldImei != currentImei)) {
      _activate();
    } else if (widget.isActive && _sensors.isNotEmpty) {
      _applyLiveTelemetryValues();
    }
  }

  @override
  void dispose() {
    _requestGeneration += 1;
    _scrollController.dispose();
    super.dispose();
  }

  void _resetForVehicle() {
    _requestGeneration += 1;
    setState(() {
      _sensors = const <SuperadminVehicleSensor>[];
      _telemetryMeta = null;
      _totalCount = 0;
      _truncated = false;
      _loading = false;
      _hasLoaded = false;
      _errorMessage = null;
    });
  }

  void _activate() {
    if (_imei.isEmpty || _loading) {
      return;
    }

    if (!_hasLoaded) {
      unawaited(_loadSensors());
      return;
    }

    _applyLiveTelemetryValues();
  }

  Future<void> _loadSensors() async {
    final imei = _imei;
    if (imei.isEmpty || _loading) {
      return;
    }

    final generation = ++_requestGeneration;
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final page = await ref
          .read(liveMapVehicleControllerProvider)
          .getVehicleSensorsByImei(imei);
      if (!mounted || generation != _requestGeneration || _imei != imei) {
        return;
      }

      final sensors = updateSuperadminVehicleSensorsWithTelemetry(
        sensors: page.items,
        telemetry: _vehicleSensorTelemetryValues(widget.vehicle),
        updatedAt: _vehicleSensorTelemetryUpdatedAt(widget.vehicle),
      );

      setState(() {
        _sensors = sensors;
        _telemetryMeta = page.telemetryMeta;
        _totalCount = page.totalCount;
        _truncated = page.truncated;
        _loading = false;
        _hasLoaded = true;
      });
    } catch (error) {
      if (!mounted || generation != _requestGeneration) {
        return;
      }

      setState(() {
        _loading = false;
        _hasLoaded = true;
        _errorMessage = _formatVehicleLogError(error);
      });
    }
  }

  void _applyLiveTelemetryValues() {
    if (_sensors.isEmpty) {
      return;
    }

    final updatedSensors = updateSuperadminVehicleSensorsWithTelemetry(
      sensors: _sensors,
      telemetry: _vehicleSensorTelemetryValues(widget.vehicle),
      updatedAt: _vehicleSensorTelemetryUpdatedAt(widget.vehicle),
    );
    if (identical(updatedSensors, _sensors) || !mounted) {
      return;
    }

    setState(() {
      _sensors = updatedSensors;
    });
  }

  @override
  Widget build(BuildContext context) {
    final imei = _imei;
    if (imei.isEmpty) {
      return const _VehicleDrawerPlaceholderTab(
        icon: Icons.sensors_rounded,
        title: 'Sensors unavailable',
        message: 'Vehicle IMEI is required to load sensors.',
      );
    }

    if (_loading && _sensors.isEmpty) {
      return const Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2.4),
        ),
      );
    }

    if (_errorMessage != null && _sensors.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: _VehicleDetailsNotice(
          message: _errorMessage!,
          icon: Icons.error_outline_rounded,
          onRetry: () {
            setState(() {
              _hasLoaded = false;
            });
            unawaited(_loadSensors());
          },
        ),
      );
    }

    if (_hasLoaded && _sensors.isEmpty) {
      return const _VehicleDrawerPlaceholderTab(
        icon: Icons.sensors_rounded,
        title: 'No sensors configured for this vehicle.',
        message: '',
      );
    }

    final countLabel = _truncated && _totalCount > _sensors.length
        ? '${_sensors.length}/$_totalCount sensors'
        : '${_sensors.length} sensors';
    final telemetryTime = _telemetryMeta?.serverTime ??
        _vehicleSensorTelemetryUpdatedAt(widget.vehicle);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
          child: Row(
            children: [
              const Text(
                'Sensors',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF141118),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                countLabel,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.black.withValues(alpha: 0.42),
                ),
              ),
              const Spacer(),
              if (_loading)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else if (telemetryTime != null)
                Flexible(
                  child: Text(
                    _formatVehicleSensorUpdatedAt(telemetryTime),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.black.withValues(alpha: 0.42),
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (_errorMessage != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 6),
            child: _VehicleDetailsNotice(
              message: _errorMessage!,
              icon: Icons.error_outline_rounded,
            ),
          ),
        Expanded(
          child: ListView.separated(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 14),
            itemCount: _sensors.length,
            separatorBuilder: (_, __) => const SizedBox(height: 6),
            itemBuilder: (context, index) {
              return _VehicleSensorCard(sensor: _sensors[index]);
            },
          ),
        ),
      ],
    );
  }
}

class _VehicleSensorCard extends StatelessWidget {
  const _VehicleSensorCard({required this.sensor});

  final SuperadminVehicleSensor sensor;

  @override
  Widget build(BuildContext context) {
    final source = sensor.sourceExpression;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sensor.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF141118),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        sensor.displayType,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Colors.black.withValues(alpha: 0.46),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _VehicleSensorStatusPill(label: sensor.displayStatus),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Flexible(
                  child: Text(
                    sensor.displayValue,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF141118),
                    ),
                  ),
                ),
                if (sensor.unit?.trim().isNotEmpty ?? false) ...[
                  const SizedBox(width: 4),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(
                      sensor.unit!.trim(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Colors.black.withValues(alpha: 0.46),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            if (source != null || sensor.lastUpdated != null) ...[
              const SizedBox(height: 8),
              if (source != null)
                Text(
                  source,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.black.withValues(alpha: 0.46),
                  ),
                ),
              if (sensor.lastUpdated != null) ...[
                if (source != null) const SizedBox(height: 3),
                Text(
                  _formatVehicleSensorUpdatedAt(sensor.lastUpdated!),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.black.withValues(alpha: 0.38),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _VehicleSensorStatusPill extends StatelessWidget {
  const _VehicleSensorStatusPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 46, maxWidth: 90),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w900,
          color: Color(0xFF141118),
        ),
      ),
    );
  }
}

class _VehicleCommandsTab extends ConsumerStatefulWidget {
  const _VehicleCommandsTab({
    required this.vehicle,
    required this.fallbackImei,
    required this.isActive,
  });

  final VehicleSummary vehicle;
  final String fallbackImei;
  final bool isActive;

  @override
  ConsumerState<_VehicleCommandsTab> createState() =>
      _VehicleCommandsTabState();
}

class _VehicleCommandsTabState extends ConsumerState<_VehicleCommandsTab> {
  static const int _historyLimit = 50;
  static const int _maxHistoryRows = 120;
  static const int _maxPayloadLength = 500;
  static const Duration _pollFastInterval = Duration(seconds: 2);
  static const Duration _pollPreSentInterval = Duration(seconds: 5);
  static const Duration _pollPostSentInterval = Duration(seconds: 8);
  static const Duration _pollFastCutoff = Duration(seconds: 6);
  static const Duration _activeCommandHistoryRefreshInterval =
      Duration(seconds: 6);
  static const Duration _pollTimeout = Duration(seconds: 90);

  final _commandController = TextEditingController();
  final _historyScrollController = ScrollController();

  var _customCommands = const <SuperadminCustomCommand>[];
  var _systemVariables = const <SuperadminSystemVariable>[];
  var _apiHistory = const <SuperadminVehicleCommandEntry>[];
  var _localHistory = const <SuperadminVehicleCommandEntry>[];
  String? _selectedCommandId;
  String? _nextCursorId;
  bool _catalogLoaded = false;
  bool _historyLoaded = false;
  bool _loadingCatalog = false;
  bool _loadingHistory = false;
  bool _loadingOlder = false;
  bool _sending = false;
  bool _commandsUnavailable = false;
  String? _catalogError;
  String? _historyError;
  String? _sendMessage;
  String? _sendError;
  String? _pollingCmdId;
  String? _pollingStatus;
  bool _pollFrontendTimedOut = false;
  bool _pollSentObserved = false;
  bool _pendingCommandHistoryRefresh = false;
  DateTime? _pollStartedAt;
  DateTime? _lastActiveCommandHistoryRefreshAt;
  Timer? _pollTimer;
  Timer? _activeCommandHistoryRefreshTimer;
  int _catalogRequestGeneration = 0;
  int _historyRequestGeneration = 0;
  int _pollGeneration = 0;

  String get _imei => _commandImeiFor(widget.vehicle, widget.fallbackImei);

  LiveMapRoleConfig get _roleConfig => ref.read(currentLiveMapConfigProvider);

  bool get _isBulkVehicleIdMode =>
      _roleConfig.commandSendMode == LiveMapCommandSendMode.bulkByVehicleId;

  /// User-role bulk-send flow requires a numeric backend vehicleId. When the
  /// selected vehicle's id is missing or non-numeric we disable the send
  /// button and surface the spec-mandated message.
  String? get _vehicleIdRequirementMessage {
    if (!_isBulkVehicleIdMode) return null;
    final id = widget.vehicle.id.trim();
    if (id.isEmpty || int.tryParse(id) == null) {
      return 'Vehicle ID is required to send commands.';
    }
    return null;
  }

  String get _localRequestedByRole => _roleConfig.role.name.toUpperCase();

  String get _localCommandSource => 'flutter.${_roleConfig.role.name}.map';

  bool get _canSend {
    final text = _commandController.text.trim();
    if (text.isEmpty || text.length > _maxPayloadLength || _sending) {
      return false;
    }
    if (_isBulkVehicleIdMode) {
      return _vehicleIdRequirementMessage == null;
    }
    return _imei.isNotEmpty;
  }

  List<SuperadminVehicleCommandEntry> get _visibleHistory {
    final rows = <SuperadminVehicleCommandEntry>[];
    final seen = <String>{};

    void addRow(SuperadminVehicleCommandEntry row) {
      final key = row.identity;
      if (seen.add(key)) {
        rows.add(row);
      }
    }

    for (final row in _localHistory) {
      addRow(row);
    }
    for (final row in _apiHistory) {
      addRow(row);
    }

    rows.sort((left, right) {
      final leftMs = left.displayTime?.toUtc().millisecondsSinceEpoch ?? 0;
      final rightMs = right.displayTime?.toUtc().millisecondsSinceEpoch ?? 0;
      final timeComparison = rightMs.compareTo(leftMs);
      if (timeComparison != 0) {
        return timeComparison;
      }

      return right.identity.compareTo(left.identity);
    });

    if (rows.length <= _maxHistoryRows) {
      return rows;
    }

    return rows.take(_maxHistoryRows).toList(growable: false);
  }

  @override
  void initState() {
    super.initState();
    _commandController.addListener(_handleCommandTextChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.isActive) {
        _activate();
      }
    });
  }

  @override
  void didUpdateWidget(covariant _VehicleCommandsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldImei = _commandImeiFor(oldWidget.vehicle, oldWidget.fallbackImei);
    final currentImei = _imei;
    final oldDeviceTypeId = oldWidget.vehicle.deviceTypeId;
    final currentDeviceTypeId = widget.vehicle.deviceTypeId;
    final commandTargetChanged =
        oldImei != currentImei || oldDeviceTypeId != currentDeviceTypeId;

    if (commandTargetChanged) {
      _resetForVehicle();
    }

    if (widget.isActive && (!oldWidget.isActive || commandTargetChanged)) {
      _activate();
    } else if (!widget.isActive && oldWidget.isActive) {
      _stopPolling(updateState: true);
      _pendingCommandHistoryRefresh = false;
    }
  }

  @override
  void dispose() {
    _catalogRequestGeneration += 1;
    _historyRequestGeneration += 1;
    _stopPolling(updateState: false);
    _commandController.removeListener(_handleCommandTextChanged);
    _commandController.dispose();
    _historyScrollController.dispose();
    super.dispose();
  }

  void _handleCommandTextChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _resetForVehicle() {
    _catalogRequestGeneration += 1;
    _historyRequestGeneration += 1;
    _stopPolling(updateState: false);
    _commandController.clear();
    setState(() {
      _customCommands = const <SuperadminCustomCommand>[];
      _systemVariables = const <SuperadminSystemVariable>[];
      _apiHistory = const <SuperadminVehicleCommandEntry>[];
      _localHistory = const <SuperadminVehicleCommandEntry>[];
      _selectedCommandId = null;
      _nextCursorId = null;
      _catalogLoaded = false;
      _historyLoaded = false;
      _loadingCatalog = false;
      _loadingHistory = false;
      _loadingOlder = false;
      _sending = false;
      _catalogError = null;
      _historyError = null;
      _sendMessage = null;
      _sendError = null;
      _pollingCmdId = null;
      _pollingStatus = null;
      _pollFrontendTimedOut = false;
      _pendingCommandHistoryRefresh = false;
    });
  }

  void _activate() {
    final imei = _imei;
    if (imei.isNotEmpty && !_historyLoaded && !_loadingHistory) {
      unawaited(_loadHistory(refresh: true));
    }
    if (!_catalogLoaded && !_loadingCatalog) {
      unawaited(_loadCatalog());
    }
  }

  Future<void> _loadCatalog() async {
    if (_loadingCatalog) {
      return;
    }

    final generation = ++_catalogRequestGeneration;
    setState(() {
      _loadingCatalog = true;
      _catalogError = null;
    });

    try {
      final service = ref.read(liveMapVehicleControllerProvider);
      final commands = await service.getCustomCommands(
        deviceTypeId: widget.vehicle.deviceTypeId,
        activeOnly: true,
      );
      var variables = const <SuperadminSystemVariable>[];
      try {
        variables = await service.getSystemVariables();
      } catch (_) {
        variables = const <SuperadminSystemVariable>[];
      }
      if (!mounted || generation != _catalogRequestGeneration) {
        return;
      }

      final activeCommands =
          commands.where((command) => command.isActive).toList(growable: false);

      setState(() {
        _customCommands = activeCommands;
        _systemVariables = variables;
        _loadingCatalog = false;
        _catalogLoaded = true;
      });

      if (_selectedCommandId == null && activeCommands.isNotEmpty) {
        _selectCommand(activeCommands.first);
      }
    } catch (error) {
      if (!mounted || generation != _catalogRequestGeneration) {
        return;
      }

      // Graceful disable when the role's command endpoints aren't deployed
      // (or the user lacks permission). The drawer keeps working; the
      // commands tab simply shows a friendly disabled notice with no retry.
      final isUnavailable = _isCommandsUnavailableError(error);
      setState(() {
        _loadingCatalog = false;
        _catalogLoaded = true;
        _commandsUnavailable = isUnavailable;
        _catalogError = isUnavailable
            ? 'Commands are not available for this account.'
            : _formatVehicleLogError(error);
      });
    }
  }

  static bool _isCommandsUnavailableError(Object error) {
    if (error is ApiException) {
      final code = error.statusCode;
      return code == 404 || code == 403;
    }
    if (error is StateError) {
      return true;
    }
    return false;
  }

  Future<void> _loadHistory({bool refresh = false}) async {
    final imei = _imei;
    final bulkMode = _isBulkVehicleIdMode;
    final vehicleId = widget.vehicle.id.trim();
    if (_loadingHistory) {
      return;
    }
    if (bulkMode) {
      if (vehicleId.isEmpty || int.tryParse(vehicleId) == null) {
        return;
      }
    } else if (imei.isEmpty) {
      return;
    }

    final generation = ++_historyRequestGeneration;
    setState(() {
      _loadingHistory = true;
      _historyError = null;
      if (refresh) {
        _nextCursorId = null;
      }
    });

    try {
      final service = ref.read(liveMapVehicleControllerProvider);
      final page = bulkMode
          ? await service.getCommandHistoryByVehicleId(
              vehicleId: vehicleId,
              limit: _historyLimit,
            )
          : await service.getCommandHistoryByImei(
              imei: imei,
              limit: _historyLimit,
            );
      if (!mounted ||
          generation != _historyRequestGeneration ||
          (!bulkMode && _imei != imei)) {
        return;
      }

      setState(() {
        _apiHistory = page.items;
        _nextCursorId = page.nextCursorId;
        _loadingHistory = false;
        _historyLoaded = true;
      });
      _drainPendingCommandHistoryRefresh();
    } catch (error) {
      if (!mounted || generation != _historyRequestGeneration) {
        return;
      }

      setState(() {
        _loadingHistory = false;
        _historyLoaded = true;
        _historyError = _formatVehicleLogError(error);
      });
      _drainPendingCommandHistoryRefresh();
    }
  }

  void _requestCommandHistoryRefresh({bool force = false}) {
    if (!mounted || !widget.isActive || _pollingCmdId == null) {
      return;
    }

    final now = DateTime.now();
    final lastRefresh = _lastActiveCommandHistoryRefreshAt;
    if (!force &&
        lastRefresh != null &&
        now.difference(lastRefresh) < _pollFastCutoff) {
      return;
    }

    _lastActiveCommandHistoryRefreshAt = now;
    if (_loadingHistory) {
      _pendingCommandHistoryRefresh = true;
      return;
    }

    unawaited(_loadHistory(refresh: true));
  }

  void _drainPendingCommandHistoryRefresh() {
    if (!_pendingCommandHistoryRefresh || !mounted || !widget.isActive) {
      return;
    }

    _pendingCommandHistoryRefresh = false;
    unawaited(_loadHistory(refresh: true));
  }

  Future<void> _loadOlderHistory() async {
    final imei = _imei;
    final bulkMode = _isBulkVehicleIdMode;
    final vehicleId = widget.vehicle.id.trim();
    final cursor = _nextCursorId?.trim() ?? '';
    if (cursor.isEmpty || _loadingOlder) {
      return;
    }
    if (bulkMode) {
      if (vehicleId.isEmpty || int.tryParse(vehicleId) == null) {
        return;
      }
    } else if (imei.isEmpty) {
      return;
    }

    final generation = _historyRequestGeneration;
    setState(() {
      _loadingOlder = true;
      _historyError = null;
    });

    try {
      final service = ref.read(liveMapVehicleControllerProvider);
      final page = bulkMode
          ? await service.getCommandHistoryByVehicleId(
              vehicleId: vehicleId,
              limit: _historyLimit,
              cursorId: cursor,
            )
          : await service.getCommandHistoryByImei(
              imei: imei,
              limit: _historyLimit,
              cursorId: cursor,
            );
      if (!mounted ||
          generation != _historyRequestGeneration ||
          (!bulkMode && _imei != imei)) {
        return;
      }

      setState(() {
        _apiHistory = _mergeVehicleCommandLists(
          current: _apiHistory,
          incoming: page.items,
        );
        _nextCursorId = page.nextCursorId;
        _loadingOlder = false;
      });
    } catch (error) {
      if (!mounted || generation != _historyRequestGeneration) {
        return;
      }

      setState(() {
        _loadingOlder = false;
        _historyError = _formatVehicleLogError(error);
      });
    }
  }

  void _selectCommand(SuperadminCustomCommand command) {
    final resolved = _resolveCommandTemplate(
      command.command,
      _commandDefaultValues(widget.vehicle, _systemVariables),
    );
    setState(() {
      _selectedCommandId = command.id;
      _commandController.text = resolved;
      _commandController.selection = TextSelection.collapsed(
        offset: _commandController.text.length,
      );
      _sendError = null;
    });
  }

  Future<void> _sendCommand() async {
    final imei = _imei;
    final command = _commandController.text.trim();
    final bulkMode = _isBulkVehicleIdMode;
    if (command.isEmpty || _sending) {
      return;
    }
    if (bulkMode) {
      final reason = _vehicleIdRequirementMessage;
      if (reason != null) {
        setState(() {
          _sendError = reason;
        });
        return;
      }
    } else if (imei.isEmpty) {
      return;
    }
    if (command.length > _maxPayloadLength) {
      setState(() {
        _sendError = 'Command must be $_maxPayloadLength characters or less.';
      });
      return;
    }

    final vehicleId = widget.vehicle.id.trim();
    final requestedAt = DateTime.now().toUtc();
    setState(() {
      _sending = true;
      _sendError = null;
      _sendMessage = null;
      _pollFrontendTimedOut = false;
    });

    try {
      final service = ref.read(liveMapVehicleControllerProvider);
      final response = bulkMode
          ? await service.sendBulkCommandForUserVehicles(
              vehicleIds: <String>[vehicleId],
              command: command,
            )
          : await service.sendCommandByImei(
              imei: imei,
              command: command,
            );
      if (!mounted || (!bulkMode && _imei != imei)) {
        return;
      }

      final localRow = SuperadminVehicleCommandEntry(
        id: 'local-${requestedAt.microsecondsSinceEpoch}',
        cmdId: response.cmdId ?? '',
        imei: imei,
        command: command,
        status: response.localStatus,
        requestedByRole: _localRequestedByRole,
        source: _localCommandSource,
        queueId: response.queueId,
        connectedAtSend: response.connected,
        requestedAt: requestedAt,
        queuedAt: response.wasQueued ? requestedAt : null,
        sentAt: response.connected == true ? requestedAt : null,
      );

      setState(() {
        _sending = false;
        final queueId = response.queueId?.trim() ?? '';
        _sendMessage = response.wasQueued
            ? queueId.isEmpty
                ? 'Queued until device reconnects'
                : 'Queued until device reconnects ($queueId)'
            : 'Sent to device, waiting for response';
        _localHistory = _upsertVehicleCommandEntry(
          _localHistory,
          localRow,
        );
      });

      final cmdId = response.cmdId?.trim() ?? '';
      if (cmdId.isNotEmpty) {
        _startPolling(cmdId);
        _requestCommandHistoryRefresh(force: true);
      } else {
        unawaited(_loadHistory(refresh: true));
      }
    } catch (error) {
      if (!mounted) {
        return;
      }

      final localRow = SuperadminVehicleCommandEntry(
        id: 'local-error-${requestedAt.microsecondsSinceEpoch}',
        cmdId: '',
        imei: imei,
        command: command,
        status: 'ERROR',
        requestedByRole: _localRequestedByRole,
        source: _localCommandSource,
        requestedAt: requestedAt,
        errorMessage: _formatVehicleLogError(error),
      );

      setState(() {
        _sending = false;
        _sendError = _formatVehicleLogError(error);
        _localHistory = _upsertVehicleCommandEntry(
          _localHistory,
          localRow,
        );
      });
    }
  }

  void _startPolling(String cmdId) {
    _stopPolling(updateState: false);
    _pollGeneration += 1;
    _pollStartedAt = DateTime.now();
    _lastActiveCommandHistoryRefreshAt = _pollStartedAt;
    _pollSentObserved = false;
    _pendingCommandHistoryRefresh = false;
    setState(() {
      _pollingCmdId = cmdId;
      _pollingStatus = null;
      _pollFrontendTimedOut = false;
    });
    _schedulePoll(cmdId, _pollGeneration, _pollFastInterval);
    _startActiveCommandHistoryRefreshTimer();
  }

  void _schedulePoll(String cmdId, int generation, Duration delay) {
    _pollTimer?.cancel();
    _pollTimer = Timer(delay, () {
      unawaited(_pollCommandStatus(cmdId, generation));
    });
  }

  void _startActiveCommandHistoryRefreshTimer() {
    _activeCommandHistoryRefreshTimer?.cancel();
    _activeCommandHistoryRefreshTimer = Timer.periodic(
      _activeCommandHistoryRefreshInterval,
      (_) {
        if (!mounted || !widget.isActive || _pollingCmdId == null) {
          _activeCommandHistoryRefreshTimer?.cancel();
          _activeCommandHistoryRefreshTimer = null;
          return;
        }

        _requestCommandHistoryRefresh(force: true);
      },
    );
  }

  Future<void> _pollCommandStatus(String cmdId, int generation) async {
    if (!mounted || generation != _pollGeneration) {
      return;
    }

    final startedAt = _pollStartedAt;
    if (startedAt == null ||
        DateTime.now().difference(startedAt) > _pollTimeout) {
      _stopPolling(updateState: true, timedOut: true);
      return;
    }

    try {
      final status =
          await ref.read(liveMapVehicleControllerProvider).getCommandStatus(cmdId);
      if (!mounted || generation != _pollGeneration) {
        return;
      }

      if (status != null) {
        final upperStatus = status.status.trim().toUpperCase();
        final sentObservedNow = upperStatus == 'SENT' && !_pollSentObserved;
        final deliveredObservedNow =
            upperStatus == 'DELIVERED' && !_pollSentObserved;

        _applyPolledStatus(cmdId, status);

        if (sentObservedNow || deliveredObservedNow) {
          _pollSentObserved = true;
        }
        if (sentObservedNow) {
          _requestCommandHistoryRefresh(force: true);
        }

        if (_isTerminalVehicleCommandStatus(upperStatus)) {
          _requestCommandHistoryRefresh(force: true);
          _stopPolling(updateState: true);
          return;
        }
      }
    } catch (_) {
      if (!mounted || generation != _pollGeneration) {
        return;
      }
    }

    final elapsed = DateTime.now().difference(startedAt);
    final nextDelay = _pollSentObserved
        ? _pollPostSentInterval
        : elapsed < _pollFastCutoff
            ? _pollFastInterval
            : _pollPreSentInterval;
    _schedulePoll(cmdId, generation, nextDelay);
  }

  void _applyPolledStatus(
    String cmdId,
    SuperadminVehicleCommandEntry status,
  ) {
    final normalizedCmdId = cmdId.trim();

    List<SuperadminVehicleCommandEntry> updateRows(
      List<SuperadminVehicleCommandEntry> rows,
    ) {
      var changed = false;
      final updated = rows.map((row) {
        if (row.cmdId.trim() != normalizedCmdId) {
          return row;
        }

        changed = true;
        return _mergeVehicleCommandEntry(row, status);
      }).toList(growable: false);

      if (changed) {
        return updated;
      }

      return rows;
    }

    final latestMessage = _vehicleCommandLatestStatusMessage(status);
    final isFailure = _isFailedVehicleCommandStatus(status.status);

    setState(() {
      _pollingStatus = status.status;
      _pollFrontendTimedOut = false;
      _sendError = isFailure ? latestMessage : null;
      _sendMessage = isFailure ? null : latestMessage;
      _localHistory = updateRows(_localHistory);
      _apiHistory = updateRows(_apiHistory);
    });
  }

  void _stopPolling({bool updateState = true, bool timedOut = false}) {
    _pollGeneration += 1;
    _pollTimer?.cancel();
    _pollTimer = null;
    _activeCommandHistoryRefreshTimer?.cancel();
    _activeCommandHistoryRefreshTimer = null;
    _pollStartedAt = null;
    _pollSentObserved = false;

    if (updateState && mounted) {
      setState(() {
        _pollingCmdId = null;
        _pollFrontendTimedOut = timedOut;
        if (timedOut) {
          _sendError = null;
          _sendMessage =
              'Still waiting for device response. History will update when backend receives it.';
        }
      });
    } else {
      _pollingCmdId = null;
      _pollFrontendTimedOut = timedOut;
    }
  }

  void _showDetails(SuperadminVehicleCommandEntry entry) {
    final cmdId = entry.cmdId.trim();
    final detailFuture = cmdId.isEmpty
        ? null
        : ref.read(liveMapVehicleControllerProvider).getCommandDetail(cmdId);
    showDialog<void>(
      context: context,
      builder: (context) => _VehicleCommandDetailsDialog(
        entry: entry,
        detailFuture: detailFuture,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final imei = _imei;
    final history = _visibleHistory;
    final selectedCommand = _selectedCommandId == null
        ? null
        : _customCommands.cast<SuperadminCustomCommand?>().firstWhere(
              (command) => command?.id == _selectedCommandId,
              orElse: () => null,
            );
    final payloadLength = _commandController.text.trim().length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
          child: _VehicleCommandTargetCard(
            vehicle: widget.vehicle,
            imei: imei,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 0, 10, 6),
          child: _VehicleCommandComposerCard(
            commands: _customCommands,
            selectedCommandId: _selectedCommandId,
            selectedCommand: selectedCommand,
            loading: _loadingCatalog,
            sending: _sending,
            canSend: _canSend,
            payloadLength: payloadLength,
            maxPayloadLength: _maxPayloadLength,
            controller: _commandController,
            onCommandChanged: (commandId) {
              final command = _customCommands.firstWhere(
                (item) => item.id == commandId,
                orElse: () => _customCommands.first,
              );
              _selectCommand(command);
            },
            onSend: _sendCommand,
          ),
        ),
        if (_catalogError != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 6),
            child: _VehicleDetailsNotice(
              message: _catalogError!,
              icon: _commandsUnavailable
                  ? Icons.lock_outline_rounded
                  : Icons.error_outline_rounded,
              onRetry:
                  _commandsUnavailable ? null : () => unawaited(_loadCatalog()),
            ),
          ),
        if (_vehicleIdRequirementMessage != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 6),
            child: _VehicleCommandLatestStatusCard(
              message: _vehicleIdRequirementMessage!,
              isError: true,
            ),
          ),
        if (_sendError != null || _sendMessage != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 6),
            child: _VehicleCommandLatestStatusCard(
              message: _sendError ?? _sendMessage!,
              isError: _sendError != null,
            ),
          ),
        if (_pollingCmdId != null ||
            _pollingStatus != null ||
            _pollFrontendTimedOut)
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 6),
            child: _VehicleCommandPollStrip(
              status: _pollingStatus,
              isPolling: _pollingCmdId != null,
              timedOut: _pollFrontendTimedOut,
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 0, 10, 6),
          child: Row(
            children: [
              const Text(
                'History',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF141118),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${history.length} rows',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.black.withValues(alpha: 0.42),
                ),
              ),
              const Spacer(),
              IconButton(
                tooltip: 'Refresh history',
                onPressed: _loadingHistory
                    ? null
                    : () => unawaited(_loadHistory(refresh: true)),
                visualDensity: VisualDensity.compact,
                iconSize: 18,
                color: const Color(0xFF141118),
                icon: _loadingHistory
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh_rounded),
              ),
              TextButton.icon(
                onPressed: _nextCursorId == null || _loadingOlder
                    ? null
                    : () => unawaited(_loadOlderHistory()),
                icon: _loadingOlder
                    ? const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.keyboard_double_arrow_down_rounded),
                label: Text(_loadingOlder ? 'Loading' : 'Older'),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  foregroundColor: const Color(0xFF141118),
                  textStyle: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_historyError != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 6),
            child: _VehicleDetailsNotice(
              message: _historyError!,
              icon: Icons.error_outline_rounded,
              onRetry: () => unawaited(_loadHistory(refresh: true)),
            ),
          ),
        Expanded(
          child: _loadingHistory && history.isEmpty
              ? const Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.4),
                  ),
                )
              : history.isEmpty
                  ? const _VehicleDrawerPlaceholderTab(
                      icon: Icons.terminal_rounded,
                      title: 'No commands yet',
                      message:
                          'Sent commands and device responses appear here.',
                    )
                  : ListView.separated(
                      controller: _historyScrollController,
                      padding: const EdgeInsets.fromLTRB(10, 0, 10, 14),
                      itemCount: history.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 6),
                      itemBuilder: (context, index) {
                        final row = history[index];
                        return _VehicleCommandHistoryRow(
                          entry: row,
                          onTap: () => _showDetails(row),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}

class _VehicleCommandTargetCard extends StatelessWidget {
  const _VehicleCommandTargetCard({
    required this.vehicle,
    required this.imei,
  });

  final VehicleSummary vehicle;
  final String imei;

  @override
  Widget build(BuildContext context) {
    final hint = _vehicleCommandConnectionHint(vehicle);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
              ),
              child: Icon(
                Icons.terminal_rounded,
                size: 16,
                color: Colors.black.withValues(alpha: 0.62),
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _vehicleDisplayName(vehicle),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF141118),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    imei.isEmpty ? 'IMEI unavailable' : 'IMEI $imei',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.black.withValues(alpha: 0.46),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _VehicleCommandConnectionChip(label: hint),
          ],
        ),
      ),
    );
  }
}

class _VehicleCommandConnectionChip extends StatelessWidget {
  const _VehicleCommandConnectionChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 112),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w900,
          color: Colors.black.withValues(alpha: 0.58),
        ),
      ),
    );
  }
}

class _VehicleCommandComposerCard extends StatelessWidget {
  const _VehicleCommandComposerCard({
    required this.commands,
    required this.selectedCommandId,
    required this.selectedCommand,
    required this.loading,
    required this.sending,
    required this.canSend,
    required this.payloadLength,
    required this.maxPayloadLength,
    required this.controller,
    required this.onCommandChanged,
    required this.onSend,
  });

  final List<SuperadminCustomCommand> commands;
  final String? selectedCommandId;
  final SuperadminCustomCommand? selectedCommand;
  final bool loading;
  final bool sending;
  final bool canSend;
  final int payloadLength;
  final int maxPayloadLength;
  final TextEditingController controller;
  final ValueChanged<String> onCommandChanged;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Text(
                  'Command',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF141118),
                  ),
                ),
                const Spacer(),
                if (loading)
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: selectedCommandId,
              isExpanded: true,
              selectedItemBuilder: (context) {
                return commands.map((command) {
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      command.displayTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF141118),
                      ),
                    ),
                  );
                }).toList(growable: false);
              },
              decoration: InputDecoration(
                isDense: true,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 9,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: Colors.black.withValues(alpha: 0.08),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: Colors.black.withValues(alpha: 0.08),
                  ),
                ),
              ),
              hint: Text(
                commands.isEmpty ? 'No custom commands' : 'Select command',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.black.withValues(alpha: 0.45),
                ),
              ),
              items: commands.map((command) {
                return DropdownMenuItem<String>(
                  value: command.id,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        command.displayTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF141118),
                        ),
                      ),
                      if (command.command.trim() != command.displayTitle) ...[
                        const SizedBox(height: 1),
                        Text(
                          command.command.trim(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'monospace',
                            color: Colors.black.withValues(alpha: 0.42),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }).toList(growable: false),
              onChanged: commands.isEmpty
                  ? null
                  : (value) {
                      if (value != null) {
                        onCommandChanged(value);
                      }
                    },
            ),
            if (selectedCommand?.displaySubtitle.trim().isNotEmpty ??
                false) ...[
              const SizedBox(height: 5),
              Text(
                selectedCommand!.displaySubtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.black.withValues(alpha: 0.42),
                ),
              ),
            ],
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              minLines: 2,
              maxLines: 3,
              maxLength: maxPayloadLength,
              style: const TextStyle(
                fontSize: 12,
                height: 1.25,
                fontFamily: 'monospace',
                fontWeight: FontWeight.w700,
                color: Color(0xFF141118),
              ),
              decoration: InputDecoration(
                counterText: '',
                hintText: 'Enter command text',
                hintStyle: TextStyle(
                  fontSize: 12,
                  color: Colors.black.withValues(alpha: 0.32),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.all(10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: Colors.black.withValues(alpha: 0.08),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: Colors.black.withValues(alpha: 0.08),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  '$payloadLength/$maxPayloadLength',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: payloadLength > maxPayloadLength
                        ? const Color(0xFFB42318)
                        : Colors.black.withValues(alpha: 0.42),
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: 112,
                  child: OpenVtsButton(
                    label: 'Send',
                    onPressed: canSend ? onSend : null,
                    isLoading: sending,
                    trailingIcon: Icons.send_rounded,
                    height: 38,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _VehicleCommandLatestStatusCard extends StatelessWidget {
  const _VehicleCommandLatestStatusCard({
    required this.message,
    required this.isError,
  });

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          children: [
            Icon(
              isError ? Icons.error_outline_rounded : Icons.schedule_rounded,
              size: 15,
              color: Colors.black.withValues(alpha: 0.52),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                isError ? 'Failed' : message,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Colors.black.withValues(alpha: 0.62),
                ),
              ),
            ),
            if (isError && message.trim().isNotEmpty) ...[
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  message.trim(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.black.withValues(alpha: 0.42),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _VehicleCommandPollStrip extends StatelessWidget {
  const _VehicleCommandPollStrip({
    required this.status,
    required this.isPolling,
    required this.timedOut,
  });

  final String? status;
  final bool isPolling;
  final bool timedOut;

  @override
  Widget build(BuildContext context) {
    final label = timedOut
        ? 'Still waiting for device response. History will update when backend receives it.'
        : status == null
            ? 'Checking command status...'
            : _vehicleCommandStatusLabel(status!);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          children: [
            if (isPolling && !timedOut)
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Icon(
                timedOut ? Icons.schedule_rounded : Icons.check_rounded,
                size: 15,
                color: Colors.black.withValues(alpha: 0.48),
              ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Colors.black.withValues(alpha: 0.58),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VehicleCommandHistoryRow extends StatelessWidget {
  const _VehicleCommandHistoryRow({
    required this.entry,
    required this.onTap,
  });

  final SuperadminVehicleCommandEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF7F7F8),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _VehicleCommandStatusPill(status: entry.status),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            _formatVehicleLogTime(entry.displayTime),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Colors.black.withValues(alpha: 0.42),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      entry.command.trim().isEmpty ? '--' : entry.command,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'monospace',
                        color: Color(0xFF141118),
                      ),
                    ),
                    if (entry.hasDeviceResponse ||
                        (entry.errorMessage?.trim().isNotEmpty ?? false)) ...[
                      const SizedBox(height: 5),
                      Text(
                        entry.errorMessage?.trim().isNotEmpty ?? false
                            ? entry.errorMessage!.trim()
                            : (entry.responseRaw ?? entry.responseHex ?? ''),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.black.withValues(alpha: 0.46),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: Colors.black.withValues(alpha: 0.35),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VehicleCommandStatusPill extends StatelessWidget {
  const _VehicleCommandStatusPill({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 170),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
      ),
      child: Text(
        _vehicleCommandStatusLabel(status),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w900,
          color: Color(0xFF141118),
        ),
      ),
    );
  }
}

class _VehicleCommandDetailsDialog extends StatelessWidget {
  const _VehicleCommandDetailsDialog({
    required this.entry,
    required this.detailFuture,
  });

  final SuperadminVehicleCommandEntry entry;
  final Future<SuperadminVehicleCommandEntry?>? detailFuture;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 640),
        child: FutureBuilder<SuperadminVehicleCommandEntry?>(
          future: detailFuture,
          builder: (context, snapshot) {
            final detail = snapshot.data == null
                ? entry
                : _mergeVehicleCommandEntry(entry, snapshot.data!);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 8, 8),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Command details',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF141118),
                          ),
                        ),
                      ),
                      if (snapshot.connectionState == ConnectionState.waiting)
                        const Padding(
                          padding: EdgeInsets.only(right: 6),
                          child: SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        visualDensity: VisualDensity.compact,
                        splashRadius: 18,
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                    children: [
                      _VehicleCommandDetailGrid(entry: detail),
                      const SizedBox(height: 12),
                      _VehicleLogCodeBlock(
                        title: 'Command',
                        value: detail.command.trim().isEmpty
                            ? '--'
                            : detail.command.trim(),
                      ),
                      if (detail.responseRaw?.trim().isNotEmpty ?? false) ...[
                        const SizedBox(height: 12),
                        _VehicleLogCodeBlock(
                          title: 'Device response',
                          value: detail.responseRaw!.trim(),
                        ),
                      ],
                      if (detail.responseHex?.trim().isNotEmpty ?? false) ...[
                        const SizedBox(height: 12),
                        _VehicleLogCodeBlock(
                          title: 'Response hex',
                          value: detail.responseHex!.trim(),
                        ),
                      ],
                      if (detail.errorMessage?.trim().isNotEmpty ?? false) ...[
                        const SizedBox(height: 12),
                        _VehicleLogCodeBlock(
                          title: 'Error',
                          value: detail.errorMessage!.trim(),
                        ),
                      ],
                      if (detail.metadata.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _VehicleLogCodeBlock(
                          title: 'Metadata',
                          value: _formatVehicleLogJson(detail.metadata),
                        ),
                      ],
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                  child: OpenVtsButton(
                    label: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                    height: 40,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _VehicleCommandDetailGrid extends StatelessWidget {
  const _VehicleCommandDetailGrid({required this.entry});

  final SuperadminVehicleCommandEntry entry;

  @override
  Widget build(BuildContext context) {
    final rows = <({String label, String value})>[
      (label: 'Status', value: _vehicleCommandStatusLabel(entry.status)),
      (label: 'IMEI', value: entry.imei.trim().isEmpty ? '--' : entry.imei),
      (label: 'cmdId', value: entry.cmdId.trim().isEmpty ? '--' : entry.cmdId),
      (
        label: 'queueId',
        value:
            entry.queueId?.trim().isEmpty ?? true ? '--' : entry.queueId!.trim()
      ),
      (
        label: 'Role',
        value: entry.requestedByRole?.trim().isEmpty ?? true
            ? '--'
            : entry.requestedByRole!.trim()
      ),
      (
        label: 'Transport',
        value: entry.transport?.trim().isEmpty ?? true
            ? '--'
            : entry.transport!.trim()
      ),
      (
        label: 'Source',
        value:
            entry.source?.trim().isEmpty ?? true ? '--' : entry.source!.trim()
      ),
      (
        label: 'Connected',
        value: _formatVehicleLogBool(entry.connectedAtSend,
            trueLabel: 'Yes', falseLabel: 'No')
      ),
      (label: 'Requested', value: _formatVehicleLogDateTime(entry.requestedAt)),
      (label: 'Queued', value: _formatVehicleLogDateTime(entry.queuedAt)),
      (label: 'Sent', value: _formatVehicleLogDateTime(entry.sentAt)),
      (label: 'Responded', value: _formatVehicleLogDateTime(entry.respondedAt)),
      (label: 'Failed', value: _formatVehicleLogDateTime(entry.failedAt)),
      (label: 'Timed out', value: _formatVehicleLogDateTime(entry.timeoutAt)),
      (label: 'Created', value: _formatVehicleLogDateTime(entry.createdAt)),
    ];

    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
      ),
      child: Column(
        children: [
          for (var index = 0; index < rows.length; index++)
            _VehicleLogDetailRow(
              label: rows[index].label,
              value: rows[index].value,
              showDivider: index != rows.length - 1,
            ),
        ],
      ),
    );
  }
}

class _VehicleReplaySetupTab extends StatefulWidget {
  const _VehicleReplaySetupTab({
    required this.vehicle,
    required this.initialLoading,
    required this.initialError,
    required this.onReplayRequested,
    this.scrollController,
  });

  final VehicleSummary vehicle;
  final bool initialLoading;
  final String? initialError;
  final _ReplayRequestHandler onReplayRequested;
  final ScrollController? scrollController;

  @override
  State<_VehicleReplaySetupTab> createState() => _VehicleReplaySetupTabState();
}

class _VehicleReplaySetupTabState extends State<_VehicleReplaySetupTab> {
  late OpenVtsDateTimeRange _dateTimeRange;
  late bool _isLoading;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _dateTimeRange = OpenVtsDateTimeRange(
      start: now.subtract(const Duration(hours: 1)),
      end: now,
    );
    _isLoading = widget.initialLoading;
    _errorMessage = widget.initialError;
  }

  @override
  Widget build(BuildContext context) {
    final imei = widget.vehicle.imei.trim();
    final now = DateTime.now();

    return ListView(
      controller: widget.scrollController,
      primary: widget.scrollController == null,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
      children: [
        _VehicleDetailsCardShell(
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFF141118),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.route_rounded,
                  size: 18,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _vehicleDisplayName(widget.vehicle),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF141118),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      imei.isEmpty ? 'IMEI unavailable' : 'IMEI $imei',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.black.withValues(alpha: 0.48),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _VehicleDetailsCardShell(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              OpenVtsDateTimeRangeField(
                label: 'Date Time Range',
                title: 'Choose Replay Range',
                hintText: 'Select date time range',
                dateTimeEnabled: true,
                enabled: !_isLoading,
                value: _dateTimeRange,
                firstDate: DateTime(2020),
                lastDate: now.add(const Duration(days: 1)),
                now: now,
                onChanged: (range) {
                  setState(() {
                    _dateTimeRange = range;
                    _errorMessage = null;
                  });
                },
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 10),
                _ReplaySetupMessage(message: _errorMessage!),
              ],
              const SizedBox(height: 14),
              OpenVtsButton(
                label: 'Get Replay',
                onPressed: _isLoading ? null : _submit,
                isLoading: _isLoading,
                trailingIcon: Icons.play_circle_outline_rounded,
                height: 42,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    final validationError = _validateReplayRange();
    if (validationError != null) {
      setState(() {
        _errorMessage = validationError;
      });
      return;
    }

    final from = _dateTimeRange.start!;
    final to = _dateTimeRange.end!;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await widget.onReplayRequested(
      _ReplayRequest(
        vehicle: widget.vehicle,
        from: from,
        to: to,
      ),
    );

    if (!mounted) {
      return;
    }

    if (result.started) {
      Navigator.of(context).pop();
      return;
    }

    setState(() {
      _isLoading = false;
      _errorMessage =
          result.errorMessage ?? 'No replay data found for this range.';
    });
  }

  String? _validateReplayRange() {
    if (widget.vehicle.imei.trim().isEmpty) {
      return 'Vehicle IMEI is required.';
    }

    final from = _dateTimeRange.start;
    if (from == null) {
      return 'From time is required.';
    }

    final to = _dateTimeRange.end;
    if (to == null) {
      return 'To time is required.';
    }

    if (!from.isBefore(to)) {
      return 'From time must be before to time.';
    }

    if (to.difference(from) > const Duration(days: 7)) {
      return 'Replay range cannot exceed 7 days.';
    }

    return null;
  }
}

class _ReplaySetupMessage extends StatelessWidget {
  const _ReplaySetupMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        child: Row(
          children: [
            Icon(
              Icons.info_outline_rounded,
              size: 14,
              color: Colors.black.withValues(alpha: 0.54),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.black.withValues(alpha: 0.58),
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VehicleDetailsTab extends ConsumerWidget {
  const _VehicleDetailsTab({
    required this.vehicle,
    this.scrollController,
  });

  final VehicleSummary vehicle;
  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final imei = vehicle.imei.trim();
    if (imei.isEmpty) {
      return _VehicleDetailsContent(
        vehicle: vehicle,
        scrollController: scrollController,
        notice: const _VehicleDetailsNotice(
          message:
              'IMEI is unavailable for this vehicle. Showing the live map summary only.',
          icon: Icons.info_outline_rounded,
        ),
      );
    }

    final detailsAsync = ref.watch(liveMapVehicleDetailsProvider(imei));

    return _VehicleDetailsContent(
      vehicle: vehicle,
      scrollController: scrollController,
      details: detailsAsync.asData?.value,
      notice: detailsAsync.hasError
          ? _VehicleDetailsNotice(
              message: 'Failed to load full vehicle details.',
              icon: Icons.error_outline_rounded,
              onRetry: () {
                ref.invalidate(liveMapVehicleDetailsProvider(imei));
              },
            )
          : null,
    );
  }
}

class _VehicleDetailsContent extends ConsumerWidget {
  const _VehicleDetailsContent({
    required this.vehicle,
    this.scrollController,
    this.details,
    this.notice,
  });

  final VehicleSummary vehicle;
  final ScrollController? scrollController;
  final SuperadminVehicleDetails? details;
  final Widget? notice;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unitFormatter = ref.watch(unitFormatterProvider);
    final liveStatusText = _resolveVehicleDetailsText(
      vehicle.status,
      '',
      fallbackLabel: 'Unknown',
    );
    final liveSpeed = vehicle.speed;
    final isRunning = _isRunningStatus(
      liveStatusText,
      speed: liveSpeed,
    );
    final vehicleType = _firstVehicleDetailValue([
      _findVehicleDetailValue(details, const [
        'vehicletypename',
        'vehicletype',
        'type',
        'category',
      ]),
    ], fallback: '--');
    final vinNumber = _firstVehicleDetailValue([
      _findVehicleDetailValue(details, const [
        'vinnumber',
        'vin',
        'chassisnumber',
        'chassisno',
      ]),
    ], fallback: '--');
    final todayDistance = _formatVehicleMetricDistance(
      null,
      fallback: vehicle.distanceKm,
      fractionDigits: 2,
      unitFormatter: unitFormatter,
    );
    final odometer = _formatVehicleMetricDistance(
      null,
      fallback: vehicle.odometerKm,
      fractionDigits: 1,
      unitFormatter: unitFormatter,
    );
    final todayEngineHours = _formatVehicleEngineHoursValue(
      vehicle.engineHoursToday ?? vehicle.engineHours,
    );
    final totalEngineHours = _formatVehicleEngineHoursValue(
      vehicle.totalEngineHours,
    );
    final imei = _firstVehicleDetailValue([
      details?.imei,
      vehicle.imei,
    ], fallback: '--');
    final gpsModel = _firstVehicleDetailValue([
      _findVehicleDetailValue(details, const [
        'gpsmodel',
        'devicemodel',
        'trackermodel',
        'modelname',
        'model',
      ]),
    ], fallback: '--');
    final primaryUser = _firstVehicleDetailValue([
      _findVehicleDetailValue(details, const [
        'primaryusername',
        'primaryuser',
        'username',
        'ownername',
        'owner',
      ]),
    ], fallback: '--');
    final ignitionValue = vehicle.ignition ?? vehicle.acc;
    final satellites = vehicle.satellites?.toString() ?? '--';
    final resolvedLatitude = vehicle.hasValidLocation ? vehicle.latitude : null;
    final resolvedLongitude =
        vehicle.hasValidLocation ? vehicle.longitude : null;
    final hasCoordinates =
        resolvedLatitude != null && resolvedLongitude != null;
    final address = _firstVehicleDetailValue([
      _findVehicleDetailValue(details, const [
        'address',
        'formattedaddress',
        'displayaddress',
        'locationaddress',
        'currentaddress',
        'fulladdress',
      ]),
    ], fallback: '--');
    final latLongText = hasCoordinates
        ? '${resolvedLatitude.toStringAsFixed(6)} / ${resolvedLongitude.toStringAsFixed(6)}'
        : '--';
    final speedText = _formatVehicleSpeedMetric(
      null,
      fallback: liveSpeed,
      unitFormatter: unitFormatter,
    );
    final statusLabel = _formatVehicleStatusLabel(
      liveStatusText,
      speed: liveSpeed,
    );

    return ListView(
      controller: scrollController,
      primary: scrollController == null,
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 14),
      children: [
        if (notice != null) ...[notice!, const SizedBox(height: 10)],
        _VehicleDetailsHeroCard(
          statusLabel: statusLabel,
          isRunning: isRunning,
          vehicleType: vehicleType,
          vinNumber: vinNumber,
        ),
        const SizedBox(height: 10),
        _VehicleMetricsGrid(
          items: [
            _VehicleMetricCardData(
              icon: Icons.alt_route_rounded,
              label: 'Today Distance',
              value: todayDistance,
            ),
            _VehicleMetricCardData(
              icon: Icons.speed_rounded,
              label: 'Odometer',
              value: odometer,
            ),
            _VehicleMetricCardData(
              icon: Icons.access_time_rounded,
              label: 'Today Eng. Hours',
              value: todayEngineHours,
            ),
            _VehicleMetricCardData(
              icon: Icons.access_time_filled_rounded,
              label: 'Total Eng. Hours',
              value: totalEngineHours,
            ),
          ],
        ),
        const SizedBox(height: 10),
        _VehicleInformationCard(
          rows: [
            _VehicleInfoRowData(
              icon: Icons.tag_rounded,
              label: 'IMEI',
              value: imei,
            ),
            _VehicleInfoRowData(
              icon: Icons.confirmation_number_outlined,
              label: 'VIN Number',
              value: vinNumber,
            ),
            _VehicleInfoRowData(
              icon: Icons.directions_car_filled_outlined,
              label: 'Vehicle Type',
              value: vehicleType,
            ),
            _VehicleInfoRowData(
              icon: Icons.gps_fixed_rounded,
              label: 'GPS Model',
              value: gpsModel,
            ),
            _VehicleInfoRowData(
              icon: Icons.person_outline_rounded,
              label: 'Primary User',
              value: primaryUser,
            ),
            _VehicleInfoRowData.status(
              label: 'Status',
              value: statusLabel,
              isRunning: isRunning,
            ),
            _VehicleInfoRowData(
              icon: Icons.key_rounded,
              label: 'Ignition',
              value: _formatVehicleIgnitionLabel(ignitionValue),
            ),
            _VehicleInfoRowData(
              icon: Icons.speed_rounded,
              label: 'Speed',
              value: speedText,
            ),
            _VehicleInfoRowData(
              icon: Icons.sensors_rounded,
              label: 'Satellites',
              value: satellites,
            ),
          ],
        ),
        const SizedBox(height: 10),
        _VehicleLocationCard(
          address: address,
          latLongText: latLongText,
          hasCoordinates: hasCoordinates,
          onOpenNavigation: hasCoordinates
              ? () => _openVehicleNavigation(
                    context,
                    resolvedLatitude,
                    resolvedLongitude,
                  )
              : null,
        ),
      ],
    );
  }
}

class _VehicleDetailsHeroCard extends StatelessWidget {
  const _VehicleDetailsHeroCard({
    required this.statusLabel,
    required this.isRunning,
    required this.vehicleType,
    required this.vinNumber,
  });

  final String statusLabel;
  final bool isRunning;
  final String vehicleType;
  final String vinNumber;

  @override
  Widget build(BuildContext context) {
    return _VehicleDetailsCardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.directions_car_filled_rounded,
                  size: 16,
                  color: Color(0xFF141118),
                ),
              ),
              const SizedBox(width: 8),
              _VehicleStatusChip(label: statusLabel, isRunning: isRunning),
            ],
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final itemWidth = constraints.maxWidth >= 520
                  ? (constraints.maxWidth - 8) / 2
                  : constraints.maxWidth;
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  SizedBox(
                    width: itemWidth,
                    child: _VehicleMetaItem(
                      icon: Icons.directions_car_filled_outlined,
                      label: 'Vehicle Type',
                      value: vehicleType,
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: _VehicleMetaItem(
                      icon: Icons.confirmation_number_outlined,
                      label: 'VIN Number',
                      value: vinNumber,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _VehicleMetricsGrid extends StatelessWidget {
  const _VehicleMetricsGrid({required this.items});

  final List<_VehicleMetricCardData> items;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final useTwoColumns = constraints.maxWidth >= 320;
        final itemWidth = useTwoColumns
            ? (constraints.maxWidth - 10) / 2
            : constraints.maxWidth;

        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: items
              .map(
                (item) => SizedBox(
                  width: itemWidth,
                  child: _VehicleDetailStatCard(
                    icon: item.icon,
                    label: item.label,
                    value: item.value,
                  ),
                ),
              )
              .toList(growable: false),
        );
      },
    );
  }
}

class _VehicleInformationCard extends StatelessWidget {
  const _VehicleInformationCard({required this.rows});

  final List<_VehicleInfoRowData> rows;

  @override
  Widget build(BuildContext context) {
    return _VehicleDetailsCardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Vehicle Information',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Color(0xFF141118),
            ),
          ),
          const SizedBox(height: 6),
          ...rows.asMap().entries.map(
                (entry) => Column(
                  children: [
                    _VehicleInfoRow(data: entry.value),
                    if (entry.key < rows.length - 1)
                      Divider(
                        height: 1,
                        color: Colors.black.withValues(alpha: 0.06),
                      ),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}

class _VehicleLocationCard extends StatelessWidget {
  const _VehicleLocationCard({
    required this.address,
    required this.latLongText,
    required this.hasCoordinates,
    required this.onOpenNavigation,
  });

  final String address;
  final String latLongText;
  final bool hasCoordinates;
  final VoidCallback? onOpenNavigation;

  @override
  Widget build(BuildContext context) {
    return _VehicleDetailsCardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.location_on_outlined,
                  size: 13,
                  color: Color(0xFF141118),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Location',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF141118),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _VehicleLocationLine(label: 'Address', value: address),
          const SizedBox(height: 10),
          Divider(height: 1, color: Colors.black.withValues(alpha: 0.06)),
          const SizedBox(height: 10),
          _VehicleLocationLine(label: 'Lat / Long', value: latLongText),
          const SizedBox(height: 10),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onOpenNavigation,
              borderRadius: BorderRadius.circular(14),
              child: Ink(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.black.withValues(alpha: 0.06),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.navigation_rounded,
                          size: 13,
                          color: onOpenNavigation == null
                              ? Colors.black.withValues(alpha: 0.28)
                              : const Color(0xFF141118),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Open in Navigation',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: onOpenNavigation == null
                                ? Colors.black.withValues(alpha: 0.28)
                                : const Color(0xFF141118),
                          ),
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 16,
                        color: onOpenNavigation == null
                            ? Colors.black.withValues(alpha: 0.22)
                            : const Color(0xFF141118),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (!hasCoordinates) ...[
            const SizedBox(height: 8),
            Text(
              'Live coordinates are unavailable for this vehicle.',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: Colors.black.withValues(alpha: 0.44),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _VehicleStatusChip extends StatelessWidget {
  const _VehicleStatusChip({required this.label, required this.isRunning});

  final String label;
  final bool isRunning;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: _vehicleDetailsStatusColor(isRunning),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Color(0xFF141118),
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _VehicleMetaItem extends StatelessWidget {
  const _VehicleMetaItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Icon(icon, size: 13, color: const Color(0xFF141118)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: Colors.black.withValues(alpha: 0.44),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF141118),
                  height: 1.15,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _VehicleDetailsNotice extends StatelessWidget {
  const _VehicleDetailsNotice({
    required this.message,
    this.icon = Icons.info_outline_rounded,
    this.onRetry,
  });

  final String message;
  final IconData icon;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
        child: Row(
          children: [
            Icon(icon, size: 13, color: Colors.black.withValues(alpha: 0.58)),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: Colors.black.withValues(alpha: 0.56),
                  height: 1.35,
                ),
              ),
            ),
            if (onRetry != null)
              TextButton(
                onPressed: onRetry,
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF141118),
                  minimumSize: Size.zero,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Retry',
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _VehicleDrawerPlaceholderTab extends StatelessWidget {
  const _VehicleDrawerPlaceholderTab({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return _DrawerEmptyState(icon: icon, title: title, message: message);
  }
}

class _VehicleDetailStatCard extends StatelessWidget {
  const _VehicleDetailStatCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return _VehicleDetailsCardShell(
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 15, color: const Color(0xFF141118)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: Colors.black.withValues(alpha: 0.44),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF141118),
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VehicleDetailsCardShell extends StatelessWidget {
  const _VehicleDetailsCardShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(padding: const EdgeInsets.all(12), child: child),
    );
  }
}

class _VehicleMetricCardData {
  const _VehicleMetricCardData({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;
}

class _VehicleInfoRowData {
  const _VehicleInfoRowData({
    required this.icon,
    required this.label,
    required this.value,
  })  : isStatus = false,
        isRunning = false;

  const _VehicleInfoRowData.status({
    required this.label,
    required this.value,
    required this.isRunning,
  })  : icon = Icons.radio_button_checked_rounded,
        isStatus = true;

  final IconData icon;
  final String label;
  final String value;
  final bool isStatus;
  final bool isRunning;
}

class _VehicleInfoRow extends StatelessWidget {
  const _VehicleInfoRow({required this.data});

  final _VehicleInfoRowData data;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.04),
              shape: BoxShape.circle,
            ),
            child: Icon(data.icon, size: 12, color: const Color(0xFF141118)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              data.label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF141118),
              ),
            ),
          ),
          if (data.isStatus)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: _vehicleDetailsStatusColor(data.isRunning),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  data.value,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF141118),
                  ),
                ),
              ],
            )
          else
            Flexible(
              child: Text(
                data.value,
                textAlign: TextAlign.right,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF141118),
                  height: 1.25,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _VehicleLocationLine extends StatelessWidget {
  const _VehicleLocationLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: Colors.black.withValues(alpha: 0.44),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Color(0xFF141118),
            height: 1.3,
          ),
        ),
      ],
    );
  }
}

class _VehiclesTab extends StatelessWidget {
  const _VehiclesTab({
    required this.vehicles,
    required this.onVehicleSelected,
    required this.searchController,
    required this.scrollController,
  });

  final List<VehicleSummary> vehicles;
  final ValueChanged<VehicleSummary> onVehicleSelected;
  final TextEditingController searchController;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    if (vehicles.isEmpty) {
      return _DrawerScrollFill(
        scrollController: scrollController,
        child: const _DrawerEmptyState(
          icon: Icons.directions_car_outlined,
          title: 'No vehicles',
          message: 'No vehicles are visible on the map right now.',
        ),
      );
    }

    final query = searchController.text.trim().toLowerCase();
    final filteredVehicles = vehicles
        .where((vehicle) => _matchesSearch(vehicle, query))
        .toList(growable: false)
      ..sort(_compareVehicleListOrder);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
          child: TextField(
            controller: searchController,
            textInputAction: TextInputAction.search,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF141118),
            ),
            decoration: InputDecoration(
              hintText: 'Search vehicle',
              hintStyle: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.black.withValues(alpha: 0.36),
              ),
              prefixIcon: Icon(
                Icons.search_rounded,
                size: 20,
                color: Colors.black.withValues(alpha: 0.42),
              ),
              filled: true,
              fillColor: const Color(0xFFF4F5F7),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        Expanded(
          child: filteredVehicles.isEmpty
              ? _DrawerScrollFill(
                  scrollController: scrollController,
                  child: const _DrawerEmptyState(
                    icon: Icons.search_off_rounded,
                    title: 'No vehicles found',
                    message: 'Try another name or plate number.',
                  ),
                )
              : ListView.separated(
                  controller: scrollController,
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: ClampingScrollPhysics(),
                  ),
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  itemCount: filteredVehicles.length,
                  separatorBuilder: (_, __) => Divider(
                    height: 1,
                    color: Colors.black.withValues(alpha: 0.08),
                  ),
                  itemBuilder: (context, index) {
                    final vehicle = filteredVehicles[index];
                    return _VehicleListTile(
                      vehicle: vehicle,
                      onTap: vehicle.hasValidLocation
                          ? () => onVehicleSelected(vehicle)
                          : null,
                    );
                  },
                ),
        ),
      ],
    );
  }

  bool _matchesSearch(VehicleSummary vehicle, String query) {
    if (query.isEmpty) {
      return true;
    }

    return _vehicleDisplayName(vehicle).toLowerCase().contains(query) ||
        vehicle.plateNumber.toLowerCase().contains(query);
  }
}

class _VehicleListTile extends StatelessWidget {
  const _VehicleListTile({required this.vehicle, this.onTap});

  final VehicleSummary vehicle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isRunning = _isRunningVehicle(vehicle);
    final statusColor = _vehicleRunningIndicatorColor(isRunning);
    final isInteractive = onTap != null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _vehicleDisplayName(vehicle),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF141118),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatVehicleListSubtitle(vehicle),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: Colors.black.withValues(alpha: 0.42),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 66,
                child: RichText(
                  textAlign: TextAlign.right,
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: _formatVehicleSpeed(vehicle.speed),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF141118),
                        ),
                      ),
                      TextSpan(
                        text: ' km/h',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: Colors.black.withValues(alpha: 0.38),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 52,
                child: Text(
                  _formatVehicleDistance(vehicle.distanceKm),
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF141118),
                  ),
                ),
              ),
              if (isInteractive) ...[
                const SizedBox(width: 10),
                Icon(
                  Icons.my_location_rounded,
                  size: 16,
                  color: Colors.black.withValues(alpha: 0.34),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _HistoryTab extends ConsumerWidget {
  const _HistoryTab({
    required this.vehicles,
    required this.selectedHistorySegmentId,
    required this.onEntrySelected,
    required this.scrollController,
  });

  final List<VehicleSummary> vehicles;
  final String? selectedHistorySegmentId;
  final ValueChanged<_HistoryTimelineEntry> onEntrySelected;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(liveMapVehicleHistoryControllerProvider);
    final selectableVehicles = _historySelectableVehicles(vehicles);

    return Column(
      children: [
        _HistoryQueryHeader(
          state: state,
          hasSelectableVehicles: selectableVehicles.isNotEmpty,
          onGetHistory: state.isLoading || selectableVehicles.isEmpty
              ? null
              : () => _openHistoryQuery(
                    context,
                    ref,
                    selectableVehicles,
                    state.request,
                  ),
          onClearHistory: state.isLoading || state.history == null
              ? null
              : () => ref
                  .read(liveMapVehicleHistoryControllerProvider.notifier)
                  .clearHistory(),
        ),
        Expanded(
          child: _buildHistoryBody(context, ref, state, selectableVehicles),
        ),
      ],
    );
  }

  Widget _buildHistoryBody(
    BuildContext context,
    WidgetRef ref,
    SuperadminVehicleHistoryState state,
    List<VehicleSummary> selectableVehicles,
  ) {
    if (selectableVehicles.isEmpty) {
      return _DrawerScrollFill(
        scrollController: scrollController,
        child: const _DrawerEmptyState(
          icon: Icons.no_crash_rounded,
          title: 'No selectable vehicles',
          message: 'History needs a vehicle with an IMEI from live telemetry.',
        ),
      );
    }

    if (state.isLoading) {
      return _DrawerScrollFill(
        scrollController: scrollController,
        child: const _HistoryLoadingState(),
      );
    }

    final errorMessage = state.errorMessage;
    if (errorMessage != null && errorMessage.isNotEmpty) {
      return _DrawerScrollFill(
        scrollController: scrollController,
        child: _HistoryErrorState(
          message: errorMessage,
          onRetry: () => ref
              .read(liveMapVehicleHistoryControllerProvider.notifier)
              .retry(),
        ),
      );
    }

    final history = state.history;
    if (history == null) {
      return _DrawerScrollFill(
        scrollController: scrollController,
        child: const _DrawerEmptyState(
          icon: Icons.route_rounded,
          title: 'Run a history search',
          message: 'Select a vehicle, stop threshold, and date time range.',
        ),
      );
    }

    if (history.validPathPoints.isEmpty &&
        history.segments.isEmpty &&
        history.stopMarkers.isEmpty) {
      return _DrawerScrollFill(
        scrollController: scrollController,
        child: const _DrawerEmptyState(
          icon: Icons.timeline_rounded,
          title: 'No history points',
          message: 'No valid GPS path or stop markers were returned.',
        ),
      );
    }

    return _HistoryTimelineList(
      history: history,
      selectedHistorySegmentId: selectedHistorySegmentId,
      onEntrySelected: onEntrySelected,
      scrollController: scrollController,
    );
  }

  Future<void> _openHistoryQuery(
    BuildContext context,
    WidgetRef ref,
    List<VehicleSummary> selectableVehicles,
    SuperadminVehicleHistoryRequest? initialRequest,
  ) async {
    final scopedConfig = ref.read(currentLiveMapConfigProvider);
    final request = await showDialog<SuperadminVehicleHistoryRequest>(
      context: context,
      builder: (context) {
        return ProviderScope(
          overrides: [
            currentLiveMapConfigProvider.overrideWithValue(scopedConfig),
          ],
          child: _HistoryQueryDialog(
            vehicles: selectableVehicles,
            initialRequest: initialRequest,
          ),
        );
      },
    );

    if (request == null || !context.mounted) {
      return;
    }

    await ref
        .read(liveMapVehicleHistoryControllerProvider.notifier)
        .loadHistory(request);
  }
}

class _HistoryQueryHeader extends StatelessWidget {
  const _HistoryQueryHeader({
    required this.state,
    required this.hasSelectableVehicles,
    required this.onGetHistory,
    required this.onClearHistory,
  });

  final SuperadminVehicleHistoryState state;
  final bool hasSelectableVehicles;
  final VoidCallback? onGetHistory;
  final VoidCallback? onClearHistory;

  @override
  Widget build(BuildContext context) {
    final history = state.history;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFFF7F7F9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final actionButton = SizedBox(
                width: constraints.maxWidth < 360 ? double.infinity : 132,
                child: OpenVtsButton(
                  label: history == null ? 'Get History' : 'Clear History',
                  onPressed: history == null ? onGetHistory : onClearHistory,
                  variant: history == null
                      ? OpenVtsButtonVariant.primary
                      : OpenVtsButtonVariant.secondary,
                  isLoading: state.isLoading,
                  trailingIcon: history == null
                      ? Icons.manage_search_rounded
                      : Icons.clear_rounded,
                  height: 40,
                ),
              );
              final content = _HistoryQueryHeaderText(
                state: state,
                hasSelectableVehicles: hasSelectableVehicles,
              );

              if (constraints.maxWidth < 360) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    content,
                    const SizedBox(height: 10),
                    actionButton,
                    if (history != null) ...[
                      const SizedBox(height: 10),
                      _HistorySummaryStrip(history: history),
                    ],
                  ],
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: content),
                      const SizedBox(width: 12),
                      actionButton,
                    ],
                  ),
                  if (history != null) ...[
                    const SizedBox(height: 10),
                    _HistorySummaryStrip(history: history),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _HistoryQueryHeaderText extends StatelessWidget {
  const _HistoryQueryHeaderText({
    required this.state,
    required this.hasSelectableVehicles,
  });

  final SuperadminVehicleHistoryState state;
  final bool hasSelectableVehicles;

  @override
  Widget build(BuildContext context) {
    final request = state.request;
    final title = request?.vehicleLabel ?? 'Vehicle History';
    final subtitle = !hasSelectableVehicles
        ? 'Waiting for live telemetry vehicles with IMEI.'
        : request == null
            ? 'Choose a vehicle, stop threshold, and date time range.'
            : _formatHistoryRequestSummary(request);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: Color(0xFF141118),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Colors.black.withValues(alpha: 0.5),
            height: 1.25,
          ),
        ),
      ],
    );
  }
}

class _HistorySummaryStrip extends StatelessWidget {
  const _HistorySummaryStrip({required this.history});

  final SuperadminVehicleHistory history;

  @override
  Widget build(BuildContext context) {
    final analytics = history.analytics;
    final stopCount = analytics.stopCount ?? history.stopCount;
    final overspeedCount = analytics.overspeedCount ?? history.overspeedCount;

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        _HistorySummaryPill(
          icon: Icons.timeline_rounded,
          label: '${history.pointCount} points',
        ),
        _HistorySummaryPill(
          icon: Icons.pause_circle_outline_rounded,
          label: '$stopCount stops',
        ),
        if (overspeedCount > 0)
          _HistorySummaryPill(
            icon: Icons.speed_rounded,
            label: '$overspeedCount overspeed',
          ),
        if (history.maxSpeedKph != null)
          _HistorySummaryPill(
            icon: Icons.speed_rounded,
            label: '${_formatHistoryNumber(history.maxSpeedKph!, 1)} km/h max',
          ),
        if (analytics.averageSpeedKph != null)
          _HistorySummaryPill(
            icon: Icons.query_stats_rounded,
            label:
                '${_formatHistoryNumber(analytics.averageSpeedKph!, 1)} km/h avg',
          ),
        if (history.totalDistanceKm != null)
          _HistorySummaryPill(
            icon: Icons.route_rounded,
            label: '${_formatHistoryNumber(history.totalDistanceKm!, 1)} km',
          ),
        if (analytics.runningDuration != null)
          _HistorySummaryPill(
            icon: Icons.directions_car_rounded,
            label:
                '${_formatHistoryDuration(analytics.runningDuration)} running',
          ),
        if (analytics.stoppedDuration != null)
          _HistorySummaryPill(
            icon: Icons.pause_circle_outline_rounded,
            label:
                '${_formatHistoryDuration(analytics.stoppedDuration)} stopped',
          ),
      ],
    );
  }
}

class _HistorySummaryPill extends StatelessWidget {
  const _HistorySummaryPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: const Color(0xFF141118)),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Color(0xFF141118),
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryLoadingState extends StatelessWidget {
  const _HistoryLoadingState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(height: 10),
          Text(
            'Loading history...',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.black.withValues(alpha: 0.56),
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryErrorState extends StatelessWidget {
  const _HistoryErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 18,
              color: const Color(0xFFB42318).withValues(alpha: 0.9),
            ),
            const SizedBox(height: 8),
            const Text(
              'Unable to load history',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: Color(0xFF141118),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: Colors.black.withValues(alpha: 0.52),
                height: 1.3,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: 120,
              child: OpenVtsButton(
                label: 'Retry',
                onPressed: onRetry,
                variant: OpenVtsButtonVariant.secondary,
                height: 38,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryTimelineList extends StatelessWidget {
  const _HistoryTimelineList({
    required this.history,
    required this.selectedHistorySegmentId,
    required this.onEntrySelected,
    required this.scrollController,
  });

  final SuperadminVehicleHistory history;
  final String? selectedHistorySegmentId;
  final ValueChanged<_HistoryTimelineEntry> onEntrySelected;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    final entries = _historyTimelineEntries(history);

    return ListView.builder(
      controller: scrollController,
      physics: const AlwaysScrollableScrollPhysics(
        parent: ClampingScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 16),
      itemCount: entries.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return _HistoryTimelineHeader(count: entries.length);
        }

        final entryIndex = index - 1;
        final entry = entries[entryIndex];
        return _HistoryTimelineTile(
          number: entryIndex + 1,
          entry: entry,
          onTap:
              entry.focusPoints.isEmpty ? null : () => onEntrySelected(entry),
          isSelected:
              selectedHistorySegmentId == _historyTimelineEntryId(entry),
          isFirst: entryIndex == 0,
          isLast: entryIndex == entries.length - 1,
        );
      },
    );
  }
}

class _HistoryTimelineHeader extends StatelessWidget {
  const _HistoryTimelineHeader({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 9),
      child: Text(
        'TIMELINE ($count)',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
          color: Colors.black.withValues(alpha: 0.48),
        ),
      ),
    );
  }
}

class _HistoryTimelineTile extends StatelessWidget {
  const _HistoryTimelineTile({
    required this.number,
    required this.entry,
    required this.onTap,
    required this.isSelected,
    required this.isFirst,
    required this.isLast,
  });

  final int number;
  final _HistoryTimelineEntry entry;
  final VoidCallback? onTap;
  final bool isSelected;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final visuals = _historyTimelineVisuals(entry.kind);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Stack(
        children: [
          Positioned(
            left: 12,
            top: isFirst ? 24 : 0,
            bottom: isLast ? 24 : 0,
            child: const CustomPaint(
              painter: _HistoryTimelineRailPainter(),
              child: SizedBox(width: 1),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 28,
                child: Padding(
                  padding: const EdgeInsets.only(top: 15, left: 3),
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: _HistoryTimelineRailIcon(visuals: visuals),
                  ),
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: _HistoryTimelineCard(
                  number: number,
                  entry: entry,
                  onTap: onTap,
                  isSelected: isSelected,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HistoryTimelineRailIcon extends StatelessWidget {
  const _HistoryTimelineRailIcon({required this.visuals});

  final _HistoryTimelineVisuals visuals;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Center(
        child: visuals.textIcon == null
            ? Icon(visuals.icon, size: 11, color: visuals.color)
            : Text(
                visuals.textIcon!,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: visuals.color,
                ),
              ),
      ),
    );
  }
}

class _HistoryTimelineRailPainter extends CustomPainter {
  const _HistoryTimelineRailPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE5E7EB)
      ..strokeWidth = 1;
    const startY = 0.0;
    final endY = size.height;
    const dashHeight = 4.0;
    const dashGap = 4.0;
    var y = startY;

    while (y < endY) {
      canvas.drawLine(
        Offset(12, y),
        Offset(12, math.min(y + dashHeight, endY)),
        paint,
      );
      y += dashHeight + dashGap;
    }
  }

  @override
  bool shouldRepaint(covariant _HistoryTimelineRailPainter oldDelegate) =>
      false;
}

class _HistoryTimelineCard extends StatelessWidget {
  const _HistoryTimelineCard({
    required this.number,
    required this.entry,
    required this.onTap,
    required this.isSelected,
  });

  final int number;
  final _HistoryTimelineEntry entry;
  final VoidCallback? onTap;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final reasonLabel = _historyStopReasonLabel(entry.primarySegment);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Ink(
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFF7F7F8) : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF3F3F46).withValues(alpha: 0.36)
                  : Colors.black.withValues(alpha: 0.1),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 7,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(11, 10, 11, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        '$number. ${_historyTimelineTitle(entry)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF141118),
                        ),
                      ),
                    ),
                    if (entry.kind == _HistoryTimelineEntryKind.stop &&
                        reasonLabel.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Flexible(
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: _HistoryStopReasonPill(label: reasonLabel),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 7),
                switch (entry.kind) {
                  _HistoryTimelineEntryKind.start ||
                  _HistoryTimelineEntryKind.end =>
                    _HistoryPointTimelineDetails(entry: entry),
                  _HistoryTimelineEntryKind.stop => _HistoryStopTimelineDetails(
                      segment: entry.primarySegment,
                    ),
                  _HistoryTimelineEntryKind.running =>
                    _HistoryRunningTimelineDetails(entry: entry),
                },
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HistoryPointTimelineDetails extends StatelessWidget {
  const _HistoryPointTimelineDetails({required this.entry});

  final _HistoryTimelineEntry entry;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _HistoryTimeLine(text: _formatHistoryPointTimestamp(entry.timestamp)),
        const SizedBox(height: 5),
        _HistoryMutedLine(text: _formatHistoryAddress(entry.point?.address)),
      ],
    );
  }
}

class _HistoryStopTimelineDetails extends StatelessWidget {
  const _HistoryStopTimelineDetails({required this.segment});

  final SuperadminVehicleHistorySegment? segment;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _HistoryTimeLine(
          text: _formatHistoryTimeRange(
            segment?.startTime,
            segment?.endTime,
          ),
        ),
        const SizedBox(height: 5),
        _HistoryMutedLine(
          text: 'Duration: ${_formatHistoryDuration(segment?.duration)}',
        ),
        const SizedBox(height: 4),
        _HistoryMutedLine(text: _formatHistoryAddress(segment?.address)),
      ],
    );
  }
}

class _HistoryRunningTimelineDetails extends StatelessWidget {
  const _HistoryRunningTimelineDetails({required this.entry});

  final _HistoryTimelineEntry entry;

  @override
  Widget build(BuildContext context) {
    final duration = _historyEntryDuration(entry);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _HistoryTimeLine(
          text: _formatHistoryTimeRange(
            _historyEntryStartTime(entry),
            _historyEntryEndTime(entry),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _HistoryMetricBox(
                label: 'Distance',
                value: _formatHistoryDistanceValue(
                  _historyEntryDistanceKm(entry),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _HistoryMetricBox(
                label: 'Avg Speed',
                value: _formatHistorySpeedValue(
                  _historyEntryAvgSpeedKph(entry),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _HistoryMetricBox(
                label: 'Max Speed',
                value: _formatHistorySpeedValue(
                  _historyEntryMaxSpeedKph(entry),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        _HistoryMutedLine(
          text: '${_formatHistoryDuration(duration)} driving',
        ),
      ],
    );
  }
}

class _HistoryMetricBox extends StatelessWidget {
  const _HistoryMetricBox({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.black.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: Colors.black.withValues(alpha: 0.52),
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: Color(0xFF141118),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryTimeLine extends StatelessWidget {
  const _HistoryTimeLine({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.timer_outlined,
          size: 12,
          color: Colors.black.withValues(alpha: 0.45),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.black.withValues(alpha: 0.56),
            ),
          ),
        ),
      ],
    );
  }
}

class _HistoryMutedLine extends StatelessWidget {
  const _HistoryMutedLine({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        color: Colors.black.withValues(alpha: 0.52),
        height: 1.2,
      ),
    );
  }
}

class _HistoryStopReasonPill extends StatelessWidget {
  const _HistoryStopReasonPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 96),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.black.withValues(alpha: 0.12)),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: Colors.black.withValues(alpha: 0.46),
          ),
        ),
      ),
    );
  }
}

class _HistoryQueryDialog extends StatefulWidget {
  const _HistoryQueryDialog({
    required this.vehicles,
    required this.initialRequest,
  });

  final List<VehicleSummary> vehicles;
  final SuperadminVehicleHistoryRequest? initialRequest;

  @override
  State<_HistoryQueryDialog> createState() => _HistoryQueryDialogState();
}

class _HistoryQueryDialogState extends State<_HistoryQueryDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _stopMinutesController;
  late VehicleSummary? _selectedVehicle;
  late OpenVtsDateTimeRange _dateTimeRange;
  String? _rangeError;

  @override
  void initState() {
    super.initState();
    final initialRequest = widget.initialRequest;
    _selectedVehicle = _resolveInitialVehicle(initialRequest);
    _stopMinutesController = TextEditingController(
      text: (initialRequest?.stopMinutes ?? 5).toString(),
    );
    final now = DateTime.now();
    _dateTimeRange = OpenVtsDateTimeRange(
      start: initialRequest?.from ?? now.subtract(const Duration(hours: 24)),
      end: initialRequest?.to ?? now,
    );
  }

  @override
  void dispose() {
    _stopMinutesController.dispose();
    super.dispose();
  }

  VehicleSummary? _resolveInitialVehicle(
    SuperadminVehicleHistoryRequest? initialRequest,
  ) {
    if (widget.vehicles.isEmpty) {
      return null;
    }

    final requestedImei = initialRequest?.imei;
    if (requestedImei == null || requestedImei.isEmpty) {
      return widget.vehicles.first;
    }

    for (final vehicle in widget.vehicles) {
      if (vehicle.imei.trim() == requestedImei) {
        return vehicle;
      }
    }

    return widget.vehicles.first;
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            left: 18,
            right: 18,
            top: 18,
            bottom: 18 + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Get History',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF141118),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Use the live map vehicle list, then choose the stop threshold and date time range.',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.black.withValues(alpha: 0.56),
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Vehicle',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF141118),
                  ),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<VehicleSummary>(
                  initialValue: _selectedVehicle,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    hintText: 'Select vehicle',
                  ),
                  items: widget.vehicles
                      .map(
                        (vehicle) => DropdownMenuItem<VehicleSummary>(
                          value: vehicle,
                          child: Text(
                            _historyVehicleOptionLabel(vehicle),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(growable: false),
                  validator: (value) => value == null
                      ? 'Select a vehicle from live telemetry.'
                      : null,
                  onChanged: (vehicle) {
                    setState(() {
                      _selectedVehicle = vehicle;
                    });
                  },
                ),
                const SizedBox(height: 14),
                OpenVtsTextField(
                  label: 'Stop Minutes',
                  controller: _stopMinutesController,
                  hintText: '5',
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  validator: _validateStopMinutes,
                ),
                const SizedBox(height: 14),
                OpenVtsDateTimeRangeField(
                  label: 'Date Time Range',
                  title: 'Choose Date Time Range',
                  hintText: 'Select date time range',
                  dateTimeEnabled: true,
                  value: _dateTimeRange,
                  firstDate: DateTime(2020),
                  lastDate: now.add(const Duration(days: 1)),
                  now: now,
                  onChanged: (range) {
                    setState(() {
                      _dateTimeRange = range;
                      _rangeError = null;
                    });
                  },
                ),
                if (_rangeError != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    _rangeError!,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFB42318),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OpenVtsButton(
                        label: 'Cancel',
                        onPressed: () => Navigator.of(context).pop(),
                        variant: OpenVtsButtonVariant.secondary,
                        height: 42,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OpenVtsButton(
                        label: 'Show History',
                        onPressed: _submit,
                        trailingIcon: Icons.timeline_rounded,
                        height: 42,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String? _validateStopMinutes(String? value) {
    final text = value?.trim() ?? '';
    final minutes = int.tryParse(text);
    if (minutes == null) {
      return 'Enter stop minutes.';
    }

    if (minutes < 1) {
      return 'Stop minutes must be at least 1.';
    }

    if (minutes > 1440) {
      return 'Use 1440 minutes or less.';
    }

    return null;
  }

  void _submit() {
    final isFormValid = _formKey.currentState?.validate() ?? false;
    final normalizedRange = _dateTimeRange.normalized(dateTimeEnabled: true);
    final start = normalizedRange.start;
    final end = normalizedRange.end;
    var rangeError = _validateDateTimeRange(start, end);

    setState(() {
      _rangeError = rangeError;
    });

    if (!isFormValid || rangeError != null) {
      return;
    }

    final selectedVehicle = _selectedVehicle;
    final stopMinutes = int.parse(_stopMinutesController.text.trim());
    if (selectedVehicle == null || start == null || end == null) {
      return;
    }

    Navigator.of(context).pop(
      SuperadminVehicleHistoryRequest(
        vehicle: selectedVehicle,
        from: start,
        to: end,
        stopMinutes: stopMinutes,
      ),
    );
  }

  String? _validateDateTimeRange(DateTime? start, DateTime? end) {
    if (start == null || end == null) {
      return 'Select a complete date time range.';
    }

    if (!end.isAfter(start)) {
      return 'End time must be after start time.';
    }

    return null;
  }
}

List<VehicleSummary> _historySelectableVehicles(List<VehicleSummary> vehicles) {
  return vehicles
      .where((vehicle) => vehicle.imei.trim().isNotEmpty)
      .toList(growable: false)
    ..sort(_compareVehicleListOrder);
}

String _formatHistoryRequestSummary(SuperadminVehicleHistoryRequest request) {
  final start = _mapFmt.formatDateTime(request.from.toLocal());
  final end = _mapFmt.formatDateTime(request.to.toLocal());
  return '$start - $end • Stops >= ${request.stopMinutes} min';
}

String _historyVehicleOptionLabel(VehicleSummary vehicle) {
  final name = _vehicleDisplayName(vehicle);
  final plate = vehicle.plateNumber.trim();
  final imei = vehicle.imei.trim();
  final meta = [plate, imei]
      .where((value) => value.isNotEmpty && value != name)
      .join(' • ');
  return meta.isEmpty ? name : '$name • $meta';
}

enum _HistoryTimelineEntryKind { start, running, stop, end }

class _HistoryTimelineEntry {
  const _HistoryTimelineEntry({
    required this.kind,
    required this.focusPoints,
    this.timestamp,
    this.point,
    this.segments = const <SuperadminVehicleHistorySegment>[],
  });

  final _HistoryTimelineEntryKind kind;
  final List<LatLng> focusPoints;
  final DateTime? timestamp;
  final SuperadminVehicleHistoryPoint? point;
  final List<SuperadminVehicleHistorySegment> segments;

  SuperadminVehicleHistorySegment? get primarySegment =>
      segments.isEmpty ? null : segments.first;
}

class _HistoryTimelineVisuals {
  const _HistoryTimelineVisuals({
    required this.icon,
    required this.color,
    this.textIcon,
  });

  final IconData icon;
  final Color color;
  final String? textIcon;
}

List<_HistoryTimelineEntry> _historyTimelineEntries(
  SuperadminVehicleHistory history,
) {
  final entries = <_HistoryTimelineEntry>[];
  final cleanSegments = _historyCleanTimelineSegments(history);
  final startPoint = history.startPoint;
  final endPoint = history.endPoint;
  final firstCleanSegment = cleanSegments.isEmpty ? null : cleanSegments.first;
  final lastCleanSegment = cleanSegments.isEmpty ? null : cleanSegments.last;

  if (startPoint != null) {
    entries.add(
      _HistoryTimelineEntry(
        kind: _HistoryTimelineEntryKind.start,
        timestamp: firstCleanSegment?.startTime ?? startPoint.timestamp,
        point: startPoint,
        focusPoints: [_historyPointLatLng(startPoint)],
      ),
    );
  }

  final runningSegments = <SuperadminVehicleHistorySegment>[];
  void flushRunningSegments() {
    if (runningSegments.isEmpty) {
      return;
    }

    final groupedSegments = List<SuperadminVehicleHistorySegment>.unmodifiable(
      runningSegments,
    );
    entries.add(
      _HistoryTimelineEntry(
        kind: _HistoryTimelineEntryKind.running,
        segments: groupedSegments,
        focusPoints: _historySegmentsLatLngs(history, groupedSegments),
      ),
    );
    runningSegments.clear();
  }

  for (final segment in cleanSegments) {
    switch (segment.type) {
      case SuperadminVehicleHistorySegmentType.drive:
        runningSegments.add(segment);
      case SuperadminVehicleHistorySegmentType.stop ||
            SuperadminVehicleHistorySegmentType.idle:
        flushRunningSegments();
        entries.add(
          _HistoryTimelineEntry(
            kind: _HistoryTimelineEntryKind.stop,
            segments: [segment],
            focusPoints: _historyStopFocusLatLngs(history, segment),
          ),
        );
      case SuperadminVehicleHistorySegmentType.overspeed ||
            SuperadminVehicleHistorySegmentType.other:
        flushRunningSegments();
    }
  }
  flushRunningSegments();

  if (endPoint != null) {
    entries.add(
      _HistoryTimelineEntry(
        kind: _HistoryTimelineEntryKind.end,
        timestamp: lastCleanSegment?.endTime ?? endPoint.timestamp,
        point: endPoint,
        focusPoints: [_historyPointLatLng(endPoint)],
      ),
    );
  }

  return entries;
}

List<SuperadminVehicleHistorySegment> _historyCleanTimelineSegments(
  SuperadminVehicleHistory history,
) {
  return history.segments.where((segment) {
    return switch (segment.type) {
      SuperadminVehicleHistorySegmentType.drive => true,
      SuperadminVehicleHistorySegmentType.stop ||
      SuperadminVehicleHistorySegmentType.idle =>
        _historySegmentDurationSec(segment) >= 180,
      SuperadminVehicleHistorySegmentType.overspeed ||
      SuperadminVehicleHistorySegmentType.other =>
        false,
    };
  }).toList(growable: false);
}

_HistoryTimelineVisuals _historyTimelineVisuals(
  _HistoryTimelineEntryKind kind,
) {
  return switch (kind) {
    _HistoryTimelineEntryKind.start => const _HistoryTimelineVisuals(
        icon: Icons.location_on_outlined,
        color: Color(0xFF6B7280),
      ),
    _HistoryTimelineEntryKind.running => const _HistoryTimelineVisuals(
        icon: Icons.speed_rounded,
        color: Color(0xFF6B7280),
      ),
    _HistoryTimelineEntryKind.stop => const _HistoryTimelineVisuals(
        icon: Icons.local_parking_rounded,
        color: Color(0xFF6B7280),
        textIcon: 'P',
      ),
    _HistoryTimelineEntryKind.end => const _HistoryTimelineVisuals(
        icon: Icons.flag_outlined,
        color: Color(0xFF6B7280),
      ),
  };
}

String _historyTimelineTitle(_HistoryTimelineEntry entry) {
  return switch (entry.kind) {
    _HistoryTimelineEntryKind.start => 'Start',
    _HistoryTimelineEntryKind.running => 'Running',
    _HistoryTimelineEntryKind.stop => 'Stop',
    _HistoryTimelineEntryKind.end => 'End',
  };
}

String _historyTimelineEntryId(_HistoryTimelineEntry entry) {
  return switch (entry.kind) {
    _HistoryTimelineEntryKind.start => 'start',
    _HistoryTimelineEntryKind.end => 'end',
    _HistoryTimelineEntryKind.running =>
      'running-${_historyEntryStartIndex(entry) ?? 0}-${_historyEntryEndIndex(entry) ?? 0}',
    _HistoryTimelineEntryKind.stop => _historyStopSegmentId(
        entry.primarySegment,
      ),
  };
}

String _historyStopSegmentId(SuperadminVehicleHistorySegment? segment) {
  if (segment == null) {
    return 'segment-unknown';
  }

  final segmentId = segment.id.trim();
  if (segmentId.isNotEmpty) {
    return 'segment-$segmentId';
  }

  return 'segment-${segment.startIndex ?? 0}-${segment.endIndex ?? 0}';
}

int? _historyEntryStartIndex(_HistoryTimelineEntry entry) {
  return entry.segments.isEmpty ? null : entry.segments.first.startIndex;
}

int? _historyEntryEndIndex(_HistoryTimelineEntry entry) {
  return entry.segments.isEmpty ? null : entry.segments.last.endIndex;
}

DateTime? _historyEntryStartTime(_HistoryTimelineEntry entry) {
  return entry.segments.isEmpty ? null : entry.segments.first.startTime;
}

DateTime? _historyEntryEndTime(_HistoryTimelineEntry entry) {
  return entry.segments.isEmpty ? null : entry.segments.last.endTime;
}

Duration? _historyEntryDuration(_HistoryTimelineEntry entry) {
  var totalSeconds = 0;
  var hasDuration = false;
  for (final segment in entry.segments) {
    final durationSec = segment.durationSec;
    if (durationSec == null) {
      continue;
    }

    totalSeconds += durationSec < 0 ? 0 : durationSec;
    hasDuration = true;
  }

  return hasDuration ? Duration(seconds: totalSeconds) : null;
}

double? _historyEntryDistanceKm(_HistoryTimelineEntry entry) {
  var totalDistanceKm = 0.0;
  var hasDistance = false;
  for (final segment in entry.segments) {
    final distanceKm = segment.distanceKm;
    if (distanceKm == null) {
      continue;
    }

    totalDistanceKm += distanceKm;
    hasDistance = true;
  }

  return hasDistance ? totalDistanceKm : null;
}

double? _historyEntryAvgSpeedKph(_HistoryTimelineEntry entry) {
  if (entry.segments.length == 1) {
    return entry.segments.first.avgSpeedKph;
  }

  var weightedSpeed = 0.0;
  var totalDurationSec = 0;
  for (final segment in entry.segments) {
    final avgSpeedKph = segment.avgSpeedKph;
    final durationSec = segment.durationSec;
    if (avgSpeedKph == null || durationSec == null || durationSec <= 0) {
      continue;
    }

    weightedSpeed += avgSpeedKph * durationSec;
    totalDurationSec += durationSec;
  }

  return totalDurationSec > 0 ? weightedSpeed / totalDurationSec : null;
}

double? _historyEntryMaxSpeedKph(_HistoryTimelineEntry entry) {
  double? maxSpeedKph;
  for (final segment in entry.segments) {
    final speed = segment.maxSpeedKph;
    if (speed == null) {
      continue;
    }

    maxSpeedKph = maxSpeedKph == null ? speed : math.max(maxSpeedKph, speed);
  }

  return maxSpeedKph;
}

List<LatLng> _historySegmentsLatLngs(
  SuperadminVehicleHistory history,
  List<SuperadminVehicleHistorySegment> segments,
) {
  if (segments.isEmpty) {
    return const <LatLng>[];
  }

  return _historyIndexedLatLngs(
    history,
    segments.first.startIndex,
    segments.last.endIndex,
  );
}

List<LatLng> _historySegmentLatLngs(
  SuperadminVehicleHistory history,
  SuperadminVehicleHistorySegment segment,
) {
  return _historyIndexedLatLngs(
    history,
    segment.startIndex,
    segment.endIndex,
  );
}

List<LatLng> _historyStopFocusLatLngs(
  SuperadminVehicleHistory history,
  SuperadminVehicleHistorySegment segment,
) {
  final segmentPoints = _historySegmentLatLngs(history, segment);
  if (segmentPoints.isNotEmpty) {
    return segmentPoints;
  }

  final markerPoint = _historyStopMarkerPoint(history, segment);
  return markerPoint == null ? const <LatLng>[] : <LatLng>[markerPoint];
}

List<LatLng> _historyIndexedLatLngs(
  SuperadminVehicleHistory history,
  int? startIndex,
  int? endIndex,
) {
  final points = _historyIndexedPoints(history, startIndex, endIndex);
  if (points.isEmpty) {
    return const <LatLng>[];
  }

  return points
      .where((point) => point.hasCoordinates)
      .map(_historyPointLatLng)
      .toList(growable: false);
}

List<SuperadminVehicleHistoryPoint> _historyIndexedPoints(
  SuperadminVehicleHistory history,
  int? startIndex,
  int? endIndex,
) {
  if (startIndex == null || endIndex == null || history.points.isEmpty) {
    return const <SuperadminVehicleHistoryPoint>[];
  }

  if (startIndex < 0 ||
      endIndex < startIndex ||
      startIndex >= history.points.length) {
    return const <SuperadminVehicleHistoryPoint>[];
  }

  final clampedEndIndex = math.min(endIndex, history.points.length - 1);
  return history.points.sublist(startIndex, clampedEndIndex + 1);
}

int _historySegmentDurationSec(SuperadminVehicleHistorySegment segment) {
  final durationSec = segment.durationSec;
  if (durationSec == null || durationSec < 0) {
    return 0;
  }

  return durationSec;
}

class _HistoryDerivedStopMarker {
  const _HistoryDerivedStopMarker({
    required this.point,
    required this.segment,
  });

  final LatLng point;
  final SuperadminVehicleHistorySegment segment;
}

List<_HistoryDerivedStopMarker> _historyDerivedStopMarkers(
  SuperadminVehicleHistory? history,
) {
  if (history == null || history.points.isEmpty) {
    return const <_HistoryDerivedStopMarker>[];
  }

  final markers = <_HistoryDerivedStopMarker>[];
  for (final segment in history.segments) {
    final isStopLike =
        segment.type == SuperadminVehicleHistorySegmentType.stop ||
            segment.type == SuperadminVehicleHistorySegmentType.idle;
    if (!isStopLike || _historySegmentDurationSec(segment) < 180) {
      continue;
    }

    final point = _historyStopMarkerPoint(history, segment);
    if (point == null) {
      continue;
    }

    markers.add(
      _HistoryDerivedStopMarker(
        point: point,
        segment: segment,
      ),
    );
  }

  return markers;
}

LatLng? _historyStopMarkerPoint(
  SuperadminVehicleHistory history,
  SuperadminVehicleHistorySegment segment,
) {
  final startIndex = segment.startIndex;
  final endIndex = segment.endIndex;
  if (startIndex == null ||
      endIndex == null ||
      startIndex < 0 ||
      endIndex < startIndex) {
    return null;
  }

  final midpointIndex = startIndex + ((endIndex - startIndex) ~/ 2);
  if (midpointIndex >= history.points.length) {
    return null;
  }

  final point = history.points[midpointIndex];
  return point.hasCoordinates ? _historyPointLatLng(point) : null;
}

List<LatLng> _historyPathLatLngs(SuperadminVehicleHistory? history) {
  if (history == null) {
    return const <LatLng>[];
  }

  return _historyLatLngsFromPoints(history.validPathPoints);
}

List<Polyline> _historyRoadPolylines(
  List<LatLng> points, {
  bool selected = false,
}) {
  if (points.length < 2) {
    return const <Polyline>[];
  }

  if (selected) {
    return <Polyline>[
      Polyline(
        points: points,
        strokeWidth: 12.5,
        color: const Color(0xFFC0CBD3).withValues(alpha: 0.70),
      ),
      Polyline(
        points: points,
        strokeWidth: 7.5,
        color: const Color(0xFF111827).withValues(alpha: 0.90),
      ),
      Polyline(
        points: points,
        strokeWidth: 1.2,
        color: const Color(0xFFFFFFFF).withValues(alpha: 0.88),
        pattern: StrokePattern.dashed(segments: const <double>[8, 8]),
      ),
    ];
  }

  return <Polyline>[
    Polyline(
      points: points,
      strokeWidth: 12,
      color: const Color(0xFFD6DEE5).withValues(alpha: 0.50),
    ),
    Polyline(
      points: points,
      strokeWidth: 7,
      color: const Color(0xFF8B969F).withValues(alpha: 0.58),
    ),
    Polyline(
      points: points,
      strokeWidth: 1.1,
      color: const Color(0xFFF8FAFC).withValues(alpha: 0.72),
      pattern: StrokePattern.dashed(segments: const <double>[8, 9]),
    ),
  ];
}

List<Polyline> _selectedHistoryRoadPolylines(
  SuperadminVehicleHistory? history,
  String? selectedHistorySegmentId,
) {
  if (history == null || selectedHistorySegmentId == null) {
    return const <Polyline>[];
  }

  final selectedPoints = _selectedHistoryPathLatLngs(
    history,
    selectedHistorySegmentId,
  );
  return _historyRoadPolylines(selectedPoints, selected: true);
}

List<LatLng> _selectedHistoryPathLatLngs(
  SuperadminVehicleHistory history,
  String selectedHistorySegmentId,
) {
  if (!selectedHistorySegmentId.startsWith('running-')) {
    return const <LatLng>[];
  }

  final parts = selectedHistorySegmentId.split('-');
  if (parts.length != 3) {
    return const <LatLng>[];
  }

  final startIndex = int.tryParse(parts[1]);
  final endIndex = int.tryParse(parts[2]);
  return _historyIndexedLatLngs(history, startIndex, endIndex);
}

List<LatLng> _historyLatLngsFromPoints(
  List<SuperadminVehicleHistoryPoint> points,
) {
  return points.map(_historyPointLatLng).toList(growable: false);
}

LatLng _historyPointLatLng(SuperadminVehicleHistoryPoint point) {
  return LatLng(point.latitude!, point.longitude!);
}

List<LatLng> _replayPathLatLngs(List<SuperadminReplayPoint> points) {
  return points.map(_replayPointLatLng).toList(growable: false);
}

List<LatLng> _replayVisitedPathLatLngs(
  List<SuperadminReplayPoint> points,
  int replayIndex,
) {
  if (points.isEmpty) {
    return const <LatLng>[];
  }

  final endIndex = replayIndex < 0
      ? 0
      : replayIndex >= points.length
          ? points.length - 1
          : replayIndex;
  return points
      .take(endIndex + 1)
      .map(_replayPointLatLng)
      .toList(growable: false);
}

LatLng _replayPointLatLng(SuperadminReplayPoint point) {
  return LatLng(point.latitude, point.longitude);
}

List<double> _buildReplayCumulativeDistanceKm(
  List<SuperadminReplayPoint> points,
) {
  if (points.isEmpty) {
    return const <double>[];
  }

  final distances = <double>[0];
  var totalKm = 0.0;
  for (var index = 1; index < points.length; index++) {
    final previous = points[index - 1];
    final current = points[index];
    final stepMeters = _coordinateDistanceMeters(
      fromLatitude: previous.latitude,
      fromLongitude: previous.longitude,
      toLatitude: current.latitude,
      toLongitude: current.longitude,
    );

    if (stepMeters < 1.5) {
      distances.add(totalKm);
      continue;
    }

    final previousSpeed = previous.speedKph ?? 0;
    final currentSpeed = current.speedKph ?? 0;
    if (previousSpeed < 5 && currentSpeed < 5 && stepMeters < 25) {
      distances.add(totalKm);
      continue;
    }

    final previousTime = previous.effectiveTime;
    final currentTime = current.effectiveTime;
    if (previousTime != null && currentTime != null) {
      final seconds =
          currentTime.difference(previousTime).inMilliseconds.abs() / 1000;
      if (seconds > 0) {
        final impliedKph = (stepMeters / seconds) * 3.6;
        if (impliedKph > 220) {
          distances.add(totalKm);
          continue;
        }
      }
    }

    totalKm += stepMeters / 1000;
    distances.add(totalKm);
  }

  return distances;
}

List<SuperadminReplayStopMarker> _deriveReplayStopMarkers(
  List<SuperadminReplayPoint> points,
) {
  if (points.length < 2) {
    return const <SuperadminReplayStopMarker>[];
  }

  final markers = <SuperadminReplayStopMarker>[];
  int? segmentStartIndex;

  void flushSegment(int segmentEndIndex) {
    final startIndex = segmentStartIndex;
    if (startIndex == null || segmentEndIndex < startIndex) {
      return;
    }

    final duration =
        _replayStoppedDuration(points, startIndex, segmentEndIndex);
    if (duration.inSeconds < 180) {
      return;
    }

    final midpointIndex = startIndex + ((segmentEndIndex - startIndex) ~/ 2);
    final midpoint = points[midpointIndex];
    markers.add(
      SuperadminReplayStopMarker(
        startIndex: startIndex,
        endIndex: segmentEndIndex,
        latitude: midpoint.latitude,
        longitude: midpoint.longitude,
        startTime: points[startIndex].effectiveTime,
        endTime: points[segmentEndIndex].effectiveTime,
        duration: duration,
      ),
    );
  }

  for (var index = 0; index < points.length; index++) {
    if (_isReplayStoppedPoint(points, index)) {
      segmentStartIndex ??= index;
      continue;
    }

    flushSegment(index - 1);
    segmentStartIndex = null;
  }
  flushSegment(points.length - 1);

  return markers;
}

bool _isReplayStoppedPoint(List<SuperadminReplayPoint> points, int index) {
  final speedKph = points[index].speedKph;
  if (speedKph != null) {
    return speedKph < 5;
  }

  final movementMeters = <double>[];
  final point = points[index];
  if (index > 0) {
    final previous = points[index - 1];
    movementMeters.add(
      _coordinateDistanceMeters(
        fromLatitude: previous.latitude,
        fromLongitude: previous.longitude,
        toLatitude: point.latitude,
        toLongitude: point.longitude,
      ),
    );
  }
  if (index < points.length - 1) {
    final next = points[index + 1];
    movementMeters.add(
      _coordinateDistanceMeters(
        fromLatitude: point.latitude,
        fromLongitude: point.longitude,
        toLatitude: next.latitude,
        toLongitude: next.longitude,
      ),
    );
  }

  return movementMeters.isNotEmpty &&
      movementMeters.every((distanceMeters) => distanceMeters <= 35);
}

Duration _replayStoppedDuration(
  List<SuperadminReplayPoint> points,
  int startIndex,
  int endIndex,
) {
  final startTime = points[startIndex].effectiveTime;
  final endTime = points[endIndex].effectiveTime;
  if (startTime == null || endTime == null) {
    return Duration.zero;
  }

  final milliseconds =
      (endTime.millisecondsSinceEpoch - startTime.millisecondsSinceEpoch).abs();
  return Duration(milliseconds: milliseconds);
}

int? _effectiveReplayTimeMs(SuperadminReplayPoint point) {
  return point.effectiveTime?.millisecondsSinceEpoch;
}

double? _replayEngineHours(SuperadminReplayPoint point) {
  return point.totalengineHours ?? point.engineHours;
}

double? _replayTripDistanceKm({
  required SuperadminReplayPoint point,
  required double? cumulativeDistanceKm,
}) {
  if (cumulativeDistanceKm != null) {
    return cumulativeDistanceKm;
  }

  return _normalizeReplayBackendDistance(point.distance);
}

double? _normalizeReplayBackendDistance(double? value) {
  if (value == null) {
    return null;
  }

  if (value.abs() > 500) {
    return value / 1000;
  }

  return value;
}

String _replayLoadErrorMessage(Object error) {
  final text = error.toString().replaceFirst('Exception: ', '').trim();
  if (text.startsWith('ArgumentError')) {
    return text.replaceFirst('ArgumentError: ', '');
  }

  return 'Unable to load replay. Try another range.';
}

String? _replayVehicleTitle(String? name) {
  final normalizedName = name?.trim() ?? '';
  return normalizedName.isEmpty ? null : normalizedName;
}

String _formatReplayControlTime(DateTime? value) {
  if (value == null) {
    return '--';
  }

  return _mapFmt.formatTime(value.toLocal());
}

String _formatReplayDistanceKm(double? value) {
  if (value == null) {
    return '--';
  }

  return '${_formatReplayNumber(value, value.abs() >= 100 ? 1 : 2)} km';
}

String _formatReplayStopDuration(Duration duration) {
  final totalSeconds = duration.inSeconds.abs();
  final hours = totalSeconds ~/ 3600;
  final minutes = (totalSeconds % 3600) ~/ 60;
  final seconds = totalSeconds % 60;

  if (hours > 0) {
    return '${hours}h ${minutes}m';
  }

  if (minutes > 0) {
    return '${minutes}m ${seconds}s';
  }

  return '${seconds}s';
}

String _formatReplayOdometer(double? value) {
  if (value == null) {
    return '--';
  }

  return '${_formatReplayNumber(value, 1)} km';
}

String _formatReplayHours(double? value) {
  if (value == null) {
    return '--';
  }

  final absValue = value.abs();
  if (absValue < 1) {
    final minutes = (absValue * 60).round();
    return '${value.isNegative ? '-' : ''}${minutes}m';
  }

  if (absValue < 100) {
    final totalMinutes = (absValue * 60).round();
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    final prefix = value.isNegative ? '-' : '';
    return minutes == 0 ? '$prefix${hours}h' : '$prefix${hours}h ${minutes}m';
  }

  return '${_formatReplayNumber(value, 1)} h';
}

String _formatReplayNumber(double value, int fractionDigits) {
  if (!value.isFinite) {
    return '--';
  }

  return value.toStringAsFixed(fractionDigits);
}

TextStyle _replayControlMetaStyle({
  FontWeight weight = FontWeight.w700,
  Color? color,
}) {
  return TextStyle(
    fontSize: 10,
    fontWeight: weight,
    color: color ?? Colors.black.withValues(alpha: 0.54),
  );
}

class _ReplaySpeedOption {
  const _ReplaySpeedOption({required this.label, required this.value});

  final String label;
  final double value;
}

const _replaySpeedOptions = <_ReplaySpeedOption>[
  _ReplaySpeedOption(label: 'Slower', value: 1),
  _ReplaySpeedOption(label: 'Slow', value: 2),
  _ReplaySpeedOption(label: 'Normal', value: 4),
  _ReplaySpeedOption(label: 'Fast', value: 8),
  _ReplaySpeedOption(label: 'Faster', value: 16),
];

String _replaySpeedLabel(double speed) {
  for (final option in _replaySpeedOptions) {
    if (option.value == speed) {
      return '${option.label} ${option.value.toInt()}x';
    }
  }

  return '${speed.toInt()}x';
}

String _formatHistoryPointTimestamp(DateTime? timestamp) {
  if (timestamp == null) {
    return '--';
  }

  final local = timestamp.toLocal();
  return '${_mapFmt.formatTime(local)} · ${_mapFmt.formatDate(local)}';
}

String _formatHistoryTimeRange(DateTime? start, DateTime? end) {
  final startText = start == null
      ? '--'
      : _mapFmt.formatTime(start.toLocal());
  final endText = end == null
      ? '--'
      : _mapFmt.formatTime(end.toLocal());
  return '$startText → $endText';
}

String _formatHistoryAddress(String? address) {
  final normalized = address?.trim() ?? '';
  return 'Address: ${normalized.isEmpty ? 'Address unavailable' : normalized}';
}

String _formatHistoryDuration(Duration? duration) {
  if (duration == null) {
    return '--';
  }

  final totalSeconds = duration.inSeconds < 0 ? 0 : duration.inSeconds;
  final hours = totalSeconds ~/ 3600;
  final minutes = (totalSeconds % 3600) ~/ 60;
  final seconds = totalSeconds % 60;

  if (hours > 0) {
    return minutes == 0 ? '${hours}h' : '${hours}h ${minutes}m';
  }

  if (minutes > 0) {
    return seconds == 0 ? '${minutes}m' : '${minutes}m ${seconds}s';
  }

  return '${seconds}s';
}

String _formatHistoryDistanceValue(double? value) {
  if (value == null) {
    return '--';
  }

  return '${value.toStringAsFixed(2)} km';
}

String _formatHistorySpeedValue(double? value) {
  if (value == null) {
    return '--';
  }

  return '${value.toStringAsFixed(1)} km/h';
}

String _historyStopReasonLabel(SuperadminVehicleHistorySegment? segment) {
  if (segment == null) {
    return '';
  }

  return _normalizeHistoryReasonLabel(segment.reason);
}

String _normalizeHistoryReasonLabel(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    return '';
  }

  final spaced = trimmed.replaceAll(RegExp(r'[_-]+'), ' ');
  final normalized = spaced.toLowerCase();
  if (normalized == 'stop' ||
      normalized == 'stoppage' ||
      normalized == 'halt' ||
      normalized == 'parking') {
    return '';
  }

  if (normalized.contains('engine') &&
      (normalized.contains('off') || normalized.contains('false'))) {
    return 'Engine off';
  }

  if (normalized.contains('short') || normalized.contains('halt')) {
    return 'Short halt';
  }

  return spaced
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .map(
        (part) => '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}',
      )
      .join(' ');
}

String _formatHistoryNumber(double value, int fractionDigits) {
  if (value == value.roundToDouble()) {
    return value.toStringAsFixed(0);
  }

  return value.toStringAsFixed(fractionDigits);
}

class _AlertsTab extends StatelessWidget {
  const _AlertsTab({
    required this.alerts,
    required this.isLoading,
    required this.scrollController,
  });

  final List<AppNotification> alerts;
  final bool isLoading;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    if (isLoading && alerts.isEmpty) {
      return _DrawerScrollFill(
        scrollController: scrollController,
        child: const Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (alerts.isEmpty) {
      return _DrawerScrollFill(
        scrollController: scrollController,
        child: const _DrawerEmptyState(
          icon: Icons.notifications_none_rounded,
          title: 'No alerts',
          message: 'There are no alerts available right now.',
        ),
      );
    }

    final visibleAlerts = alerts;

    return ListView.separated(
      controller: scrollController,
      physics: const AlwaysScrollableScrollPhysics(
        parent: ClampingScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      itemCount: visibleAlerts.length,
      separatorBuilder: (_, __) =>
          Divider(height: 1, color: Colors.black.withValues(alpha: 0.06)),
      itemBuilder: (context, index) {
        final alert = visibleAlerts[index];
        final visuals = _resolveAlertVisuals(alert);
        final metaText = _buildAlertMeta(alert);

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: visuals.backgroundColor,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(visuals.icon, size: 18, color: visuals.iconColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: visuals.dotColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            alert.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF141118),
                              height: 1.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      metaText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Colors.black.withValues(alpha: 0.48),
                        height: 1.25,
                      ),
                    ),
                    if (alert.message.trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        alert.message.trim(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Colors.black.withValues(alpha: 0.58),
                          height: 1.3,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

String _buildAlertMeta(AppNotification alert) {
  final parts = <String>[
    if (alert.contextLabel != null && alert.contextLabel!.trim().isNotEmpty)
      alert.contextLabel!.trim(),
    if (alert.createdAt != null)
      _mapFmt.formatDateTime(alert.createdAt!.toLocal()),
  ];

  if (parts.isNotEmpty) {
    return parts.join(' • ');
  }

  final fallbackMessage = alert.message.trim();
  if (fallbackMessage.isNotEmpty) {
    return fallbackMessage;
  }

  return 'OpenVTS alert';
}

_AlertVisuals _resolveAlertVisuals(AppNotification alert) {
  final key = [
    alert.severity,
    alert.category,
    alert.title,
  ].whereType<String>().join(' ').toLowerCase();

  if (key.contains('critical') ||
      key.contains('warning') ||
      key.contains('overspeed') ||
      key.contains('alarm')) {
    return const _AlertVisuals(
      icon: Icons.warning_amber_rounded,
      iconColor: Color(0xFFDA8A00),
      dotColor: Color(0xFFF2A11B),
      backgroundColor: Color(0xFFFFF4E3),
    );
  }

  return const _AlertVisuals(
    icon: Icons.info_outline_rounded,
    iconColor: Color(0xFF4B84FF),
    dotColor: Color(0xFF4B84FF),
    backgroundColor: Color(0xFFEAF1FF),
  );
}

class _AlertVisuals {
  const _AlertVisuals({
    required this.icon,
    required this.iconColor,
    required this.dotColor,
    required this.backgroundColor,
  });

  final IconData icon;
  final Color iconColor;
  final Color dotColor;
  final Color backgroundColor;
}

class _DrawerScrollFill extends StatelessWidget {
  const _DrawerScrollFill({
    required this.scrollController,
    required this.child,
  });

  final ScrollController scrollController;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      controller: scrollController,
      physics: const AlwaysScrollableScrollPhysics(
        parent: ClampingScrollPhysics(),
      ),
      slivers: [SliverFillRemaining(hasScrollBody: false, child: child)],
    );
  }
}

class _DrawerEmptyState extends StatelessWidget {
  const _DrawerEmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: Colors.black.withValues(alpha: 0.42)),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF141118),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: Colors.black.withValues(alpha: 0.52),
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapOverlayStatusPanel extends StatelessWidget {
  const _MapOverlayStatusPanel({required this.items});

  final List<_MapOverlayStatusItem> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: switch (item.kind) {
                    _MapOverlayStatusKind.loading => Colors.white.withValues(
                        alpha: 0.94,
                      ),
                    _MapOverlayStatusKind.empty => const Color(
                        0xFF141118,
                      ).withValues(alpha: 0.78),
                    _MapOverlayStatusKind.error => const Color(
                        0xFFB42318,
                      ).withValues(alpha: 0.92),
                  },
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.14),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (item.kind == _MapOverlayStatusKind.loading)
                        const SizedBox(
                          width: 13,
                          height: 13,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      else
                        Icon(
                          item.kind == _MapOverlayStatusKind.error
                              ? Icons.error_outline_rounded
                              : Icons.info_outline_rounded,
                          size: 14,
                          color: Colors.white.withValues(alpha: 0.96),
                        ),
                      const SizedBox(width: 8),
                      Text(
                        item.message,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: item.kind == _MapOverlayStatusKind.loading
                              ? const Color(0xFF141118)
                              : Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          )
          .toList(growable: false),
    );
  }
}

enum _MapOverlayStatusKind { loading, empty, error }

class _MapOverlayStatusItem {
  const _MapOverlayStatusItem({required this.message, required this.kind});

  final String message;
  final _MapOverlayStatusKind kind;
}

class _PoiMarker extends StatelessWidget {
  const _PoiMarker({required this.poi});

  final SuperadminMapPoi poi;

  @override
  Widget build(BuildContext context) {
    final tooltip = poi.category == null || poi.category!.trim().isEmpty
        ? poi.name
        : '${poi.name} • ${poi.category}';

    return Tooltip(
      message: tooltip,
      child: Center(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFFF97316),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const SizedBox(
            width: 24,
            height: 24,
            child: Center(
              child: Icon(Icons.place_rounded, size: 14, color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}

class _VehicleClusterMarker extends StatelessWidget {
  const _VehicleClusterMarker({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: '$count vehicles',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF141118).withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                  ),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xFF141118),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.18),
                        blurRadius: 12,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: SizedBox(
                    width: 34,
                    height: 34,
                    child: Center(
                      child: Text(
                        '$count',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _VehicleMarkerGroup {
  _VehicleMarkerGroup._({
    required List<VehicleSummary> vehicles,
    required this.center,
  }) : vehicles = List<VehicleSummary>.unmodifiable(vehicles);

  factory _VehicleMarkerGroup.single(VehicleSummary vehicle) {
    return _VehicleMarkerGroup._(
      vehicles: <VehicleSummary>[vehicle],
      center: LatLng(vehicle.latitude, vehicle.longitude),
    );
  }

  factory _VehicleMarkerGroup.fromVehicles(List<VehicleSummary> vehicles) {
    if (vehicles.length <= 1) {
      return _VehicleMarkerGroup.single(vehicles.first);
    }

    var latitudeTotal = 0.0;
    var longitudeTotal = 0.0;
    for (final vehicle in vehicles) {
      latitudeTotal += vehicle.latitude;
      longitudeTotal += vehicle.longitude;
    }

    return _VehicleMarkerGroup._(
      vehicles: vehicles,
      center: LatLng(
        latitudeTotal / vehicles.length,
        longitudeTotal / vehicles.length,
      ),
    );
  }

  final List<VehicleSummary> vehicles;
  final LatLng center;

  bool get isCluster => vehicles.length > 1;

  VehicleSummary get vehicle => vehicles.first;
}

enum _VehicleMarkerStatus {
  running,
  idle,
  stopped,
  inactive,
  unknown,
}

class _VehicleMarker extends StatelessWidget {
  const _VehicleMarker({
    super.key,
    required this.vehicle,
    required this.showLabel,
    required this.showRipple,
    required this.status,
    required this.headingRadians,
    required this.motionProgress,
    required this.isInMotion,
    required this.onTap,
  });

  final VehicleSummary vehicle;
  final bool showLabel;
  final bool showRipple;
  final _VehicleMarkerStatus status;
  final double? headingRadians;
  final double motionProgress;
  final bool isInMotion;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final markerColor = _vehicleMarkerColor(status);
    final rippleColor = _vehicleRippleColor(status);
    final showStatusRipple = showRipple && _vehicleMarkerShowsRipple(status);
    final showMotionTrail =
        isInMotion && status == _VehicleMarkerStatus.running;
    final motionPulse =
        showMotionTrail ? math.sin(motionProgress * math.pi) : 0.0;
    final assetPath = _vehicleMarkerAssetPath(status);
    final trailColor = _vehicleMarkerColor(_VehicleMarkerStatus.running);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            if (showStatusRipple)
              IgnorePointer(
                child: SizedBox(
                  width: 96,
                  height: 96,
                  child: _VehicleRipple(color: rippleColor),
                ),
              ),
            if (showMotionTrail)
              IgnorePointer(
                child: _VehicleMotionTrail(
                  headingRadians: headingRadians ?? 0,
                  color: trailColor,
                  intensity: 0.4 + (motionPulse * 0.6),
                ),
              ),
            IgnorePointer(
              child: Transform.rotate(
                angle: headingRadians ?? 0,
                child: Transform.scale(
                  scale: 1 + (motionPulse * 0.035),
                  child: Image.asset(
                    assetPath,
                    width: 36,
                    height: 55,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                    gaplessPlayback: true,
                    errorBuilder: (context, error, stackTrace) {
                      return DecoratedBox(
                        decoration: BoxDecoration(
                          color: markerColor,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 2.4,
                          ),
                        ),
                        child: const SizedBox(
                          width: 34,
                          height: 34,
                          child: Center(
                            child: Icon(
                              Icons.directions_car_filled_rounded,
                              size: 18,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            if (showLabel)
              Positioned(
                top: 54,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 112),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.94),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.black.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Text(
                    _vehicleDisplayName(vehicle),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF141118),
                      height: 1,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _VehicleMotionTrail extends StatelessWidget {
  const _VehicleMotionTrail({
    required this.headingRadians,
    required this.color,
    required this.intensity,
  });

  final double headingRadians;
  final Color color;
  final double intensity;

  @override
  Widget build(BuildContext context) {
    final clampedIntensity = intensity.clamp(0.0, 1.0);

    return Transform.rotate(
      angle: headingRadians,
      child: Transform.translate(
        offset: Offset(0, 18 + (4 * (1 - clampedIntensity))),
        child: Opacity(
          opacity: 0.12 + (clampedIntensity * 0.16),
          child: Container(
            width: 12,
            height: 32,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  color.withValues(alpha: 0.34),
                  color.withValues(alpha: 0.14),
                  color.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _VehicleRipple extends StatefulWidget {
  const _VehicleRipple({required this.color});

  final Color color;

  @override
  State<_VehicleRipple> createState() => _VehicleRippleState();
}

class _VehicleRippleState extends State<_VehicleRipple>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2000),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final progress = _controller.value;

          return Stack(
            alignment: Alignment.center,
            children: [
              _RippleRing(color: widget.color, progress: (progress + 0.00) % 1),
              _RippleRing(color: widget.color, progress: (progress + 0.33) % 1),
              _RippleRing(color: widget.color, progress: (progress + 0.66) % 1),
              child!,
            ],
          );
        },
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: widget.color.withValues(alpha: 0.10),
            shape: BoxShape.circle,
          ),
          child: const SizedBox(width: 26, height: 26),
        ),
      ),
    );
  }
}

class _RippleRing extends StatelessWidget {
  const _RippleRing({required this.color, required this.progress});

  final Color color;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final normalizedProgress = progress.clamp(0.0, 1.0);
    final scale = 0.55 + (normalizedProgress * 1.25);
    final opacity = 1 - normalizedProgress;

    return Transform.scale(
      scale: scale,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10 * opacity),
          shape: BoxShape.circle,
          border: Border.all(
            color: color.withValues(alpha: 0.45 * opacity),
            width: 2,
          ),
        ),
        child: const SizedBox(width: 32, height: 32),
      ),
    );
  }
}

class _MapVisualSettings {
  const _MapVisualSettings({
    required this.vehicleLabel,
    required this.cluster,
    required this.ripple,
    required this.geofence,
    required this.poi,
    required this.route,
  });

  static const defaults = _MapVisualSettings(
    vehicleLabel: false,
    cluster: true,
    ripple: true,
    geofence: true,
    poi: false,
    route: false,
  );

  factory _MapVisualSettings.fromJson(Map<String, dynamic> json) {
    return _MapVisualSettings(
      vehicleLabel: _readBool(
        json,
        const ['vehicleLabel', 'showVehicleLabel'],
        defaults.vehicleLabel,
      ),
      cluster: _readBool(
        json,
        const ['cluster', 'enableCluster'],
        defaults.cluster,
      ),
      ripple: _readBool(
        json,
        const ['ripple', 'enableRipple'],
        defaults.ripple,
      ),
      geofence: _readBool(
        json,
        const ['geofence', 'showGeofence'],
        defaults.geofence,
      ),
      poi: _readBool(json, const ['poi', 'showPoi'], defaults.poi),
      route: _readBool(json, const ['route', 'showRoute'], defaults.route),
    );
  }

  static _MapVisualSettings fromJsonString(String? raw) {
    final text = raw?.trim() ?? '';
    if (text.isEmpty) {
      return defaults;
    }

    try {
      final parsed = jsonDecode(text);
      if (parsed is Map<String, dynamic>) {
        return _MapVisualSettings.fromJson(parsed);
      }
      if (parsed is Map) {
        return _MapVisualSettings.fromJson(
          parsed.map((key, value) => MapEntry(key.toString(), value)),
        );
      }
    } catch (_) {}

    return defaults;
  }

  final bool vehicleLabel;
  final bool cluster;
  final bool ripple;
  final bool geofence;
  final bool poi;
  final bool route;

  _MapVisualSettings copyWith({
    bool? vehicleLabel,
    bool? cluster,
    bool? ripple,
    bool? geofence,
    bool? poi,
    bool? route,
  }) {
    return _MapVisualSettings(
      vehicleLabel: vehicleLabel ?? this.vehicleLabel,
      cluster: cluster ?? this.cluster,
      ripple: ripple ?? this.ripple,
      geofence: geofence ?? this.geofence,
      poi: poi ?? this.poi,
      route: route ?? this.route,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'vehicleLabel': vehicleLabel,
      'cluster': cluster,
      'ripple': ripple,
      'geofence': geofence,
      'poi': poi,
      'route': route,
    };
  }

  String toJsonString() => jsonEncode(toJson());

  static bool _readBool(
    Map<String, dynamic> json,
    List<String> keys,
    bool fallback,
  ) {
    for (final key in keys) {
      final value = json[key];
      if (value is bool) {
        return value;
      }
      if (value is num) {
        return value != 0;
      }
      if (value is String) {
        final normalized = value.trim().toLowerCase();
        if (const <String>{'true', '1', 'yes', 'on'}.contains(normalized)) {
          return true;
        }
        if (const <String>{'false', '0', 'no', 'off'}.contains(normalized)) {
          return false;
        }
      }
    }

    return fallback;
  }
}

class _MapLayerOption {
  const _MapLayerOption({
    required this.id,
    required this.name,
    required this.shortLabel,
    required this.url,
    required this.subdomains,
    required this.previewStyle,
  });

  final String id;
  final String name;
  final String shortLabel;
  final String url;
  final List<String> subdomains;
  final _LayerPreviewStyle previewStyle;
}

enum _LayerPreviewStyle {
  road,
  satellite,
  terrain,
  hybrid,
  osm,
  dark,
  light,
  voyager,
  esriSatellite,
  toner,
  watercolor,
}

const List<String> _googleTileSubdomains = ['mt0', 'mt1', 'mt2', 'mt3'];
const List<String> _osmTileSubdomains = ['a', 'b', 'c'];
const List<String> _cartoTileSubdomains = ['a', 'b', 'c', 'd'];
const List<String> _stamenTileSubdomains = ['a', 'b', 'c', 'd'];

const List<_MapLayerOption> _primaryMapLayerOptions = [
  _MapLayerOption(
    id: 'google-road',
    name: 'Google Road',
    shortLabel: 'Road',
    url: 'https://{s}.google.com/vt/lyrs=m&x={x}&y={y}&z={z}',
    subdomains: _googleTileSubdomains,
    previewStyle: _LayerPreviewStyle.road,
  ),
  _MapLayerOption(
    id: 'google-satellite',
    name: 'Google Satellite',
    shortLabel: 'Satellite',
    url: 'https://{s}.google.com/vt/lyrs=s&x={x}&y={y}&z={z}',
    subdomains: _googleTileSubdomains,
    previewStyle: _LayerPreviewStyle.satellite,
  ),
  _MapLayerOption(
    id: 'esri-topo',
    name: 'Esri Topographic',
    shortLabel: 'Terrain',
    url:
        'https://server.arcgisonline.com/ArcGIS/rest/services/World_Topo_Map/MapServer/tile/{z}/{y}/{x}',
    subdomains: <String>[],
    previewStyle: _LayerPreviewStyle.terrain,
  ),
];

const List<_MapLayerOption> _detailMapLayerOptions = [
  _MapLayerOption(
    id: 'google-hybrid',
    name: 'Google Hybrid',
    shortLabel: 'Hybrid',
    url: 'https://{s}.google.com/vt/lyrs=s,h&x={x}&y={y}&z={z}',
    subdomains: _googleTileSubdomains,
    previewStyle: _LayerPreviewStyle.hybrid,
  ),
  _MapLayerOption(
    id: 'osm',
    name: 'OpenStreetMap',
    shortLabel: 'OSM',
    url: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
    subdomains: _osmTileSubdomains,
    previewStyle: _LayerPreviewStyle.osm,
  ),
  _MapLayerOption(
    id: 'carto-dark',
    name: 'CartoDB Dark',
    shortLabel: 'Dark',
    url: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png',
    subdomains: _cartoTileSubdomains,
    previewStyle: _LayerPreviewStyle.dark,
  ),
  _MapLayerOption(
    id: 'carto-light',
    name: 'CartoDB Light',
    shortLabel: 'Light',
    url: 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png',
    subdomains: _cartoTileSubdomains,
    previewStyle: _LayerPreviewStyle.light,
  ),
  _MapLayerOption(
    id: 'carto-voyager',
    name: 'CartoDB Voyager',
    shortLabel: 'Voyager',
    url:
        'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png',
    subdomains: _cartoTileSubdomains,
    previewStyle: _LayerPreviewStyle.voyager,
  ),
  _MapLayerOption(
    id: 'esri-satellite',
    name: 'Esri Satellite',
    shortLabel: 'Esri Sat',
    url:
        'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
    subdomains: <String>[],
    previewStyle: _LayerPreviewStyle.esriSatellite,
  ),
  _MapLayerOption(
    id: 'stamen-toner',
    name: 'Stamen Toner',
    shortLabel: 'Toner',
    url: 'https://stamen-tiles-{s}.a.ssl.fastly.net/toner/{z}/{x}/{y}.png',
    subdomains: _stamenTileSubdomains,
    previewStyle: _LayerPreviewStyle.toner,
  ),
  _MapLayerOption(
    id: 'stamen-watercolor',
    name: 'Stamen Watercolor',
    shortLabel: 'Watercolor',
    url: 'https://stamen-tiles-{s}.a.ssl.fastly.net/watercolor/{z}/{x}/{y}.png',
    subdomains: _stamenTileSubdomains,
    previewStyle: _LayerPreviewStyle.watercolor,
  ),
];

enum _MapFilter { all, running, stop, inactive }

_MapLayerOption? _mapLayerOptionById(String? id) {
  final normalizedId = id?.trim();
  if (normalizedId == null || normalizedId.isEmpty) {
    return null;
  }

  for (final layer in [
    ..._primaryMapLayerOptions,
    ..._detailMapLayerOptions,
  ]) {
    if (layer.id == normalizedId) {
      return layer;
    }
  }

  return null;
}

int _compareVehicleListOrder(VehicleSummary left, VehicleSummary right) {
  final leftUpdatedAt =
      left.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
  final rightUpdatedAt =
      right.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
  final updatedAtCompare = rightUpdatedAt.compareTo(leftUpdatedAt);
  if (updatedAtCompare != 0) {
    return updatedAtCompare;
  }

  return _vehicleDisplayName(
    left,
  ).toLowerCase().compareTo(_vehicleDisplayName(right).toLowerCase());
}

String _animatedVehicleKey(VehicleSummary vehicle) {
  final imei = vehicle.imei.trim().toLowerCase();
  if (imei.isNotEmpty) {
    return 'imei:$imei';
  }

  final id = vehicle.id.trim().toLowerCase();
  if (id.isNotEmpty) {
    return 'id:$id';
  }

  final plateNumber = vehicle.plateNumber.trim().toLowerCase();
  if (plateNumber.isNotEmpty) {
    return 'plate:$plateNumber';
  }

  final name = vehicle.name.trim().toLowerCase();
  if (name.isNotEmpty) {
    return 'name:$name';
  }

  return 'vehicle:${vehicle.latitude.toStringAsFixed(6)}:${vehicle.longitude.toStringAsFixed(6)}';
}

double? _seedVehicleBearingRadians(VehicleSummary vehicle) {
  final headingDegrees = vehicle.headingDegrees;
  if (headingDegrees == null) {
    return null;
  }

  return _degreesToRadians(headingDegrees);
}

bool _hasMeaningfulLocationChange(
  double fromLatitude,
  double fromLongitude,
  double toLatitude,
  double toLongitude,
) {
  return _coordinateDistanceMeters(
        fromLatitude: fromLatitude,
        fromLongitude: fromLongitude,
        toLatitude: toLatitude,
        toLongitude: toLongitude,
      ) >=
      _vehicleMarkerMinMoveMeters;
}

bool _shouldIgnoreVehicleLocationTransition({
  required VehicleSummary fromVehicle,
  required VehicleSummary toVehicle,
  required double distanceMeters,
}) {
  if (distanceMeters < _vehicleMarkerMinMoveMeters) {
    return true;
  }

  if (toVehicle.speed < _vehicleMarkerStationaryDriftSpeedKph &&
      distanceMeters < _vehicleMarkerStationaryDriftMeters) {
    return true;
  }

  final fromTime = fromVehicle.updatedAt ?? fromVehicle.lastSeenAt;
  final toTime = toVehicle.updatedAt ?? toVehicle.lastSeenAt;
  if (fromTime != null && toTime != null) {
    if (toTime.isBefore(fromTime)) {
      return true;
    }

    final elapsedSeconds = toTime.difference(fromTime).inSeconds;
    if (elapsedSeconds >= 2) {
      final impliedSpeedKph = (distanceMeters / elapsedSeconds) * 3.6;
      if (impliedSpeedKph > _vehicleMarkerMaxImpliedSpeedKph) {
        return true;
      }
    }
  }

  return false;
}

Duration _vehicleMotionDuration({
  required VehicleSummary fromVehicle,
  required VehicleSummary toVehicle,
  required LatLng fromPosition,
}) {
  final distanceMeters = _coordinateDistanceMeters(
    fromLatitude: fromPosition.latitude,
    fromLongitude: fromPosition.longitude,
    toLatitude: toVehicle.latitude,
    toLongitude: toVehicle.longitude,
  );

  if (distanceMeters < _vehicleMarkerMinMoveMeters) {
    return Duration.zero;
  }

  // Huge GPS jump: snap immediately, no animation (matches Web shouldSnap).
  if (distanceMeters > _vehicleMarkerSnapDistanceMeters) {
    return Duration.zero;
  }

  final fromTime = fromVehicle.updatedAt;
  final toTime = toVehicle.updatedAt;
  if (fromTime != null && toTime != null) {
    final deltaMs = toTime.difference(fromTime).inMilliseconds;
    if (deltaMs > 0) {
      final scaledMs =
          (deltaMs * _vehicleMarkerTimestampDurationScale).round().clamp(
                _vehicleMarkerMinMotionDuration.inMilliseconds,
                _vehicleMarkerMaxMotionDuration.inMilliseconds,
              );
      return Duration(milliseconds: scaledMs);
    }
  }

  // Fallback to distance-based duration when timestamps are absent or stale.
  final fallbackMs = (600 + (distanceMeters * 14)).round().clamp(900, 2600);
  return Duration(milliseconds: fallbackMs);
}

double? _resolveVehicleBearingRadians({
  required VehicleSummary vehicle,
  required LatLng from,
  required LatLng to,
  required double distanceMeters,
  required double? previousBearingRadians,
}) {
  if (vehicle.speed >= 5 && vehicle.headingDegrees != null) {
    return _degreesToRadians(vehicle.headingDegrees!);
  }

  if (distanceMeters >= 3) {
    final bearing = _vehicleBearingRadians(
      fromLatitude: from.latitude,
      fromLongitude: from.longitude,
      toLatitude: to.latitude,
      toLongitude: to.longitude,
    );
    if (bearing != null) {
      return bearing;
    }
  }

  return previousBearingRadians;
}

double _coordinateDistanceMeters({
  required double fromLatitude,
  required double fromLongitude,
  required double toLatitude,
  required double toLongitude,
}) {
  const earthRadiusMeters = 6371000.0;
  final deltaLatitude = _degreesToRadians(toLatitude - fromLatitude);
  final deltaLongitude = _degreesToRadians(toLongitude - fromLongitude);
  final startLatitudeRadians = _degreesToRadians(fromLatitude);
  final endLatitudeRadians = _degreesToRadians(toLatitude);

  final haversine = math.pow(math.sin(deltaLatitude / 2), 2) +
      math.cos(startLatitudeRadians) *
          math.cos(endLatitudeRadians) *
          math.pow(math.sin(deltaLongitude / 2), 2);
  final arc = 2 *
      math.atan2(
          math.sqrt(haversine.toDouble()), math.sqrt(1 - haversine.toDouble()));
  return earthRadiusMeters * arc;
}

double _degreesToRadians(double degrees) {
  return degrees * (math.pi / 180);
}

double? _vehicleBearingRadians({
  required double fromLatitude,
  required double fromLongitude,
  required double toLatitude,
  required double toLongitude,
}) {
  if (!_hasMeaningfulLocationChange(
    fromLatitude,
    fromLongitude,
    toLatitude,
    toLongitude,
  )) {
    return null;
  }

  final startLatitudeRadians = _degreesToRadians(fromLatitude);
  final endLatitudeRadians = _degreesToRadians(toLatitude);
  final deltaLongitudeRadians = _degreesToRadians(toLongitude - fromLongitude);
  final y = math.sin(deltaLongitudeRadians) * math.cos(endLatitudeRadians);
  final x = math.cos(startLatitudeRadians) * math.sin(endLatitudeRadians) -
      math.sin(startLatitudeRadians) *
          math.cos(endLatitudeRadians) *
          math.cos(deltaLongitudeRadians);
  if (x == 0 && y == 0) {
    return null;
  }

  return math.atan2(y, x);
}

double _lerpCoordinate(double start, double end, double progress) {
  return start + ((end - start) * progress);
}

VehicleSummary _vehicleWithAnimatedPosition(
  VehicleSummary vehicle,
  LatLng position,
) {
  return vehicle.copyWith(
    latitude: position.latitude,
    longitude: position.longitude,
  );
}

class _AnimatedVehicleMotion {
  const _AnimatedVehicleMotion._({
    required this.vehicle,
    required this.startLatitude,
    required this.startLongitude,
    required this.targetLatitude,
    required this.targetLongitude,
    required this.bearingRadians,
    required this.startedAt,
    required this.duration,
  });

  factory _AnimatedVehicleMotion.immediate(
    VehicleSummary vehicle, {
    double? bearingRadians,
  }) {
    return _AnimatedVehicleMotion._(
      vehicle: vehicle,
      startLatitude: vehicle.latitude,
      startLongitude: vehicle.longitude,
      targetLatitude: vehicle.latitude,
      targetLongitude: vehicle.longitude,
      bearingRadians: bearingRadians,
      startedAt: null,
      duration: Duration.zero,
    );
  }

  factory _AnimatedVehicleMotion.animated({
    required VehicleSummary vehicle,
    required double startLatitude,
    required double startLongitude,
    required DateTime startedAt,
    required Duration duration,
    required double? previousBearingRadians,
  }) {
    final distanceMeters = _coordinateDistanceMeters(
      fromLatitude: startLatitude,
      fromLongitude: startLongitude,
      toLatitude: vehicle.latitude,
      toLongitude: vehicle.longitude,
    );
    return _AnimatedVehicleMotion._(
      vehicle: vehicle,
      startLatitude: startLatitude,
      startLongitude: startLongitude,
      targetLatitude: vehicle.latitude,
      targetLongitude: vehicle.longitude,
      bearingRadians: _resolveVehicleBearingRadians(
        vehicle: vehicle,
        from: LatLng(startLatitude, startLongitude),
        to: LatLng(vehicle.latitude, vehicle.longitude),
        distanceMeters: distanceMeters,
        previousBearingRadians: previousBearingRadians,
      ),
      startedAt: startedAt,
      duration: duration,
    );
  }

  final VehicleSummary vehicle;
  final double startLatitude;
  final double startLongitude;
  final double targetLatitude;
  final double targetLongitude;
  final double? bearingRadians;
  final DateTime? startedAt;
  final Duration duration;

  bool get hasDirectionalMotion => _hasMeaningfulLocationChange(
        startLatitude,
        startLongitude,
        targetLatitude,
        targetLongitude,
      );

  bool isAnimatingAt(DateTime now) {
    if (startedAt == null || duration == Duration.zero) {
      return false;
    }

    return now.isBefore(startedAt!.add(duration));
  }

  double progressAt(DateTime now) {
    if (startedAt == null || duration == Duration.zero) {
      return 1;
    }

    final totalMilliseconds = duration.inMilliseconds;
    if (totalMilliseconds <= 0) {
      return 1;
    }

    final elapsedMilliseconds = now.difference(startedAt!).inMilliseconds;
    final rawProgress =
        (elapsedMilliseconds / totalMilliseconds).clamp(0.0, 1.0);
    // Linear motion (matches Web Leaflet2D live marker movement) so that the
    // marker moves at a constant speed instead of step-like easing.
    return rawProgress;
  }

  LatLng positionAt(DateTime now) {
    if (startedAt == null || duration == Duration.zero) {
      return LatLng(targetLatitude, targetLongitude);
    }

    final easedProgress = progressAt(now);
    if (easedProgress >= 1) {
      return LatLng(targetLatitude, targetLongitude);
    }

    return LatLng(
      _lerpCoordinate(startLatitude, targetLatitude, easedProgress),
      _lerpCoordinate(startLongitude, targetLongitude, easedProgress),
    );
  }

  _AnimatedVehicleMotion settledAt(DateTime now) {
    if (isAnimatingAt(now)) {
      return this;
    }

    return _AnimatedVehicleMotion.immediate(
      vehicle,
      bearingRadians: bearingRadians,
    );
  }

  _AnimatedVehicleMotion withVehicle(VehicleSummary nextVehicle) {
    return _AnimatedVehicleMotion._(
      vehicle: nextVehicle,
      startLatitude: startLatitude,
      startLongitude: startLongitude,
      targetLatitude: targetLatitude,
      targetLongitude: targetLongitude,
      bearingRadians: bearingRadians,
      startedAt: startedAt,
      duration: duration,
    );
  }

  VehicleSummary vehicleAt(DateTime now) {
    if (!vehicle.hasValidLocation) {
      return vehicle;
    }

    return _vehicleWithAnimatedPosition(vehicle, positionAt(now));
  }
}

String _vehicleDisplayName(VehicleSummary vehicle) {
  final name = vehicle.name.trim();
  if (name.isNotEmpty) {
    return name;
  }

  final plateNumber = vehicle.plateNumber.trim();
  if (plateNumber.isNotEmpty) {
    return plateNumber;
  }

  return 'Vehicle';
}

String _commandImeiFor(VehicleSummary vehicle, String fallbackImei) {
  final primary = vehicle.imei.trim();
  if (primary.isNotEmpty) {
    return primary;
  }

  return fallbackImei.trim();
}

String _vehicleCommandConnectionHint(VehicleSummary vehicle) {
  final deviceStatus = vehicle.deviceConnectionStatus?.trim().toLowerCase();
  if (deviceStatus != null && deviceStatus.isNotEmpty) {
    if (const <String>{'connected', 'online', 'active'}
        .contains(deviceStatus)) {
      return 'Online';
    }
    if (const <String>{'disconnected', 'offline', 'inactive'}.contains(
      deviceStatus,
    )) {
      return 'Offline';
    }
  }

  if (_isInactiveVehicle(vehicle)) {
    return 'Offline';
  }
  if (_isRunningVehicle(vehicle)) {
    return 'Online';
  }

  final status = vehicle.status.trim();
  return status.isEmpty ? 'Status unknown' : status;
}

String _formatVehicleListSubtitle(VehicleSummary vehicle) {
  if (vehicle.updatedAt != null) {
    return _mapFmt.formatDateTime(vehicle.updatedAt!.toLocal());
  }

  if (vehicle.plateNumber.isNotEmpty) {
    return vehicle.plateNumber;
  }

  return 'No update time';
}

String _buildVehicleDrawerSubtitle(VehicleSummary vehicle) {
  final plateNumber = vehicle.plateNumber.trim();
  final updatedAt = vehicle.updatedAt;

  if (plateNumber.isNotEmpty && updatedAt != null) {
    return '$plateNumber • ${_mapFmt.formatDateTime(updatedAt.toLocal())}';
  }

  if (plateNumber.isNotEmpty) {
    return plateNumber;
  }

  if (updatedAt != null) {
    return _mapFmt.formatDateTime(updatedAt.toLocal());
  }

  return 'Vehicle overview';
}

String _resolveVehicleDetailsText(
  String? preferred,
  String fallback, {
  String fallbackLabel = '--',
}) {
  final preferredText = preferred?.trim() ?? '';
  if (preferredText.isNotEmpty) {
    return preferredText;
  }

  final fallbackText = fallback.trim();
  if (fallbackText.isNotEmpty) {
    return fallbackText;
  }

  return fallbackLabel;
}

String _firstVehicleDetailValue(
  List<String?> candidates, {
  String fallback = '--',
}) {
  for (final candidate in candidates) {
    final text = candidate?.trim() ?? '';
    if (text.isNotEmpty) {
      return text;
    }
  }

  return fallback;
}

String _formatVehicleIgnitionLabel(bool? ignitionValue) {
  if (ignitionValue == null) {
    return '--';
  }

  return ignitionValue ? 'On' : 'Off';
}

String? _findVehicleDetailValue(
  SuperadminVehicleDetails? details,
  List<String> aliases,
) {
  if (details == null || details.sections.isEmpty) {
    return null;
  }

  final fields = details.sections
      .expand((section) => section.rows)
      .toList(growable: false);
  final normalizedAliases = aliases
      .map(_normalizeVehicleDetailLookupKey)
      .where((alias) => alias.isNotEmpty)
      .toList(growable: false);

  for (final alias in normalizedAliases) {
    for (final field in fields) {
      final label = _normalizeVehicleDetailLookupKey(field.label);
      if (label == alias) {
        return field.value;
      }
    }
  }

  for (final alias in normalizedAliases) {
    for (final field in fields) {
      final label = _normalizeVehicleDetailLookupKey(field.label);
      if (label.contains(alias) || alias.contains(label)) {
        return field.value;
      }
    }
  }

  return null;
}

String _normalizeVehicleDetailLookupKey(String value) {
  return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
}

bool _isRunningStatus(String status, {double? speed}) {
  final normalized = _normalizeVehicleStatus(status);
  if ((speed ?? 0) > 0) {
    return true;
  }

  return normalized.contains('running') ||
      normalized.contains('moving') ||
      normalized.contains('drive');
}

Color _vehicleDetailsStatusColor(bool isRunning) {
  return isRunning ? const Color(0xFF20B15A) : const Color(0xFF141118);
}

String _formatVehicleStatusLabel(String status, {double? speed}) {
  final normalized = status.trim().toLowerCase();
  if (normalized.isEmpty || normalized == 'unknown') {
    return '--';
  }

  final normalizedStatus = _normalizeVehicleStatus(status);
  if (_isInactiveStatus(normalizedStatus)) {
    return switch (normalizedStatus) {
      'no_data' => 'No Data',
      'offline' => 'Offline',
      'disconnected' => 'Disconnected',
      'license_blocked' => 'License Blocked',
      _ => 'Inactive',
    };
  }

  if (_isRunningStatus(status, speed: speed)) {
    return 'Running';
  }

  if (normalized.contains('stop') ||
      normalized.contains('idle') ||
      normalized.contains('park') ||
      normalized.contains('halt')) {
    return 'Stopped';
  }

  if (normalized.contains('offline')) {
    return 'Offline';
  }

  if (normalized.contains('online') || normalized.contains('active')) {
    return 'Stopped';
  }

  return normalized
      .split(RegExp(r'[_\s-]+'))
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}

String _formatVehicleMetricDistance(
  String? raw, {
  double? fallback,
  int fractionDigits = 1,
  required UnitFormatter unitFormatter,
}) {
  final rawText = raw?.trim() ?? '';
  if (rawText.isNotEmpty) {
    final numeric = _parseVehicleDouble(rawText);
    if (numeric != null) {
      return '${_formatVehicleMetricNumber(numeric, fractionDigits)} ${unitFormatter.distanceLabel}';
    }

    return rawText;
  }

  if (fallback != null) {
    return '${_formatVehicleMetricNumber(fallback, fractionDigits)} ${unitFormatter.distanceLabel}';
  }

  return '--';
}

String _formatVehicleSpeedMetric(String? raw, {double? fallback, required UnitFormatter unitFormatter}) {
  final rawText = raw?.trim() ?? '';
  if (rawText.isNotEmpty) {
    final numeric = _parseVehicleDouble(rawText);
    if (numeric != null) {
      return '${_formatVehicleMetricNumber(numeric, 2)} ${unitFormatter.speedLabel}';
    }

    return rawText;
  }

  if (fallback != null) {
    return '${_formatVehicleMetricNumber(fallback, 2)} ${unitFormatter.speedLabel}';
  }

  return '--';
}

String _formatVehicleEngineHoursValue(double? value) {
  if (value == null || !value.isFinite) {
    return '--';
  }

  var hours = value.floor();
  var minutes = ((value - hours) * 60).round();
  if (minutes >= 60) {
    hours += minutes ~/ 60;
    minutes %= 60;
  }

  return '${hours}h ${minutes}m';
}

String _vehicleEventTitle(AppNotification event) {
  final category = event.category?.trim() ?? '';
  final title = event.title.trim();
  if (title.isEmpty || title.toLowerCase() == 'notification') {
    return category.isEmpty ? 'Vehicle event' : category;
  }

  return category.isEmpty ? title : '$title / $category';
}

String _vehicleEventSeverity(AppNotification event) {
  final severity = event.severity?.trim() ?? '';
  if (severity.isEmpty) {
    return 'INFO';
  }

  return severity.toUpperCase();
}

String _formatVehicleEventTime(DateTime? value) {
  if (value == null) {
    return '--:--';
  }

  return _mapFmt.formatTime(value.toLocal());
}

String _formatVehicleEventDateTime(DateTime? value) {
  if (value == null) {
    return '--';
  }

  return _mapFmt.formatDateTime(value.toLocal());
}

Map<String, Object?> _vehicleSensorTelemetryValues(VehicleSummary vehicle) {
  return <String, Object?>{
    'status': vehicle.status,
    'vehicleStatus': vehicle.status,
    'speed': vehicle.speed,
    'speedKph': vehicle.speed,
    'vehicleSpeed': vehicle.speed,
    'latitude': vehicle.latitude,
    'lat': vehicle.latitude,
    'longitude': vehicle.longitude,
    'lng': vehicle.longitude,
    'lon': vehicle.longitude,
    'distance': vehicle.distanceKm,
    'distanceKm': vehicle.distanceKm,
    'todayDistance': vehicle.distanceKm,
    'distanceToday': vehicle.distanceKm,
    'odometer': vehicle.odometerKm,
    'odometerKm': vehicle.odometerKm,
    'mileage': vehicle.odometerKm,
    'engineHours': vehicle.engineHours,
    'engineHoursToday': vehicle.engineHoursToday,
    'todayEngineHours': vehicle.engineHoursToday,
    'totalEngineHours': vehicle.totalEngineHours,
    'totalengineHours': vehicle.totalEngineHours,
    'hours': vehicle.totalEngineHours,
    'satellites': vehicle.satellites,
    'satelliteCount': vehicle.satellites,
    'heading': vehicle.headingDegrees,
    'course': vehicle.headingDegrees,
    'bearing': vehicle.headingDegrees,
    'headingDegrees': vehicle.headingDegrees,
    'ignition': vehicle.ignition,
    'ignitionStatus': vehicle.ignition,
    'engineOn': vehicle.ignition,
    'acc': vehicle.acc,
    'accessory': vehicle.acc,
    'accessoryOn': vehicle.acc,
    'connectionStatus': vehicle.deviceConnectionStatus,
    'deviceConnectionStatus': vehicle.deviceConnectionStatus,
    'lastSeenAt': vehicle.lastSeenAt,
    'updatedAt': vehicle.updatedAt,
    'serverTime': vehicle.updatedAt,
    'timestamp': vehicle.updatedAt,
  };
}

Map<String, String> _commandDefaultValues(
  VehicleSummary vehicle,
  List<SuperadminSystemVariable> systemVariables,
) {
  final values = <String, String>{};

  void addValue(String key, Object? value) {
    final trimmedKey = key.trim();
    if (trimmedKey.isEmpty || value == null) {
      return;
    }

    final stringValue = value is DateTime
        ? value.toUtc().toIso8601String()
        : value.toString().trim();
    if (stringValue.isEmpty) {
      return;
    }

    values[trimmedKey] = stringValue;
    values[trimmedKey.toUpperCase()] = stringValue;
  }

  for (final variable in systemVariables) {
    addValue(variable.key, variable.value);
    addValue(variable.name, variable.initialValue);
  }

  addValue('IMEI', vehicle.imei);
  if (vehicle.hasValidLocation) {
    addValue('LAT', vehicle.latitude.toStringAsFixed(6));
    addValue('LON', vehicle.longitude.toStringAsFixed(6));
  }
  addValue('SPEED', _formatVehicleMetricNumber(vehicle.speed, 0));
  addValue('TIMESTAMP', DateTime.now().toUtc().toIso8601String());

  return values;
}

Set<String> _extractCommandVariables(String template) {
  final variables = <String>{};
  for (final pattern in <RegExp>[
    RegExp(r'\{\{([A-Za-z_][A-Za-z0-9_]*)\}\}'),
    RegExp(r'\$\{([A-Za-z_][A-Za-z0-9_]*)\}'),
    RegExp(r'\{([A-Za-z_][A-Za-z0-9_]*)\}'),
  ]) {
    for (final match in pattern.allMatches(template)) {
      final name = match.group(1)?.trim() ?? '';
      if (name.isNotEmpty) {
        variables.add(name);
      }
    }
  }

  return variables;
}

String _resolveCommandTemplate(
  String template,
  Map<String, String> defaultValues,
) {
  var resolved = template;
  for (final variable in _extractCommandVariables(template)) {
    final value =
        defaultValues[variable] ?? defaultValues[variable.toUpperCase()];
    if (value == null) {
      continue;
    }

    resolved = resolved
        .replaceAll('{{$variable}}', value)
        .replaceAll('\${$variable}', value)
        .replaceAll('{$variable}', value);
  }

  return resolved;
}

List<SuperadminVehicleCommandEntry> _mergeVehicleCommandLists({
  required List<SuperadminVehicleCommandEntry> current,
  required List<SuperadminVehicleCommandEntry> incoming,
}) {
  var rows = current;
  for (final entry in incoming) {
    rows = _upsertVehicleCommandEntry(rows, entry);
  }

  final sorted = rows.toList(growable: false)
    ..sort((left, right) {
      final leftMs = left.displayTime?.toUtc().millisecondsSinceEpoch ?? 0;
      final rightMs = right.displayTime?.toUtc().millisecondsSinceEpoch ?? 0;
      return rightMs.compareTo(leftMs);
    });
  return sorted;
}

List<SuperadminVehicleCommandEntry> _upsertVehicleCommandEntry(
  List<SuperadminVehicleCommandEntry> rows,
  SuperadminVehicleCommandEntry entry,
) {
  final updated = <SuperadminVehicleCommandEntry>[];
  var inserted = false;
  for (final row in rows) {
    final sameCmdId =
        row.cmdId.trim().isNotEmpty && row.cmdId.trim() == entry.cmdId.trim();
    final sameIdentity = row.identity == entry.identity;
    if (sameCmdId || sameIdentity) {
      updated.add(_mergeVehicleCommandEntry(row, entry));
      inserted = true;
    } else {
      updated.add(row);
    }
  }

  if (!inserted) {
    updated.insert(0, entry);
  }

  return updated;
}

SuperadminVehicleCommandEntry _mergeVehicleCommandEntry(
  SuperadminVehicleCommandEntry base,
  SuperadminVehicleCommandEntry update,
) {
  String chooseString(String current, String next) {
    return next.trim().isEmpty ? current : next;
  }

  String? chooseNullableString(String? current, String? next) {
    final trimmed = next?.trim() ?? '';
    return trimmed.isEmpty ? current : trimmed;
  }

  return SuperadminVehicleCommandEntry(
    id: chooseString(base.id, update.id),
    cmdId: chooseString(base.cmdId, update.cmdId),
    imei: chooseString(base.imei, update.imei),
    command: chooseString(base.command, update.command),
    status: chooseString(base.status, update.status),
    vehicleId: update.vehicleId ?? base.vehicleId,
    requestedByRole: chooseNullableString(
      base.requestedByRole,
      update.requestedByRole,
    ),
    transport: chooseNullableString(base.transport, update.transport),
    source: chooseNullableString(base.source, update.source),
    queueId: chooseNullableString(base.queueId, update.queueId),
    connectedAtSend: update.connectedAtSend ?? base.connectedAtSend,
    requestedAt: update.requestedAt ?? base.requestedAt,
    queuedAt: update.queuedAt ?? base.queuedAt,
    sentAt: update.sentAt ?? base.sentAt,
    respondedAt: update.respondedAt ?? base.respondedAt,
    failedAt: update.failedAt ?? base.failedAt,
    timeoutAt: update.timeoutAt ?? base.timeoutAt,
    createdAt: update.createdAt ?? base.createdAt,
    responseRaw: chooseNullableString(base.responseRaw, update.responseRaw),
    responseHex: chooseNullableString(base.responseHex, update.responseHex),
    errorMessage: chooseNullableString(base.errorMessage, update.errorMessage),
    metadata: update.metadata.isNotEmpty ? update.metadata : base.metadata,
  );
}

bool _isTerminalVehicleCommandStatus(String status) {
  final upper = status.trim().toUpperCase();
  return upper == 'RESPONDED' ||
      upper == 'ENCODE_FAILED' ||
      upper == 'FAILED' ||
      upper == 'TIMEOUT' ||
      upper == 'ERROR';
}

bool _isFailedVehicleCommandStatus(String status) {
  final upper = status.trim().toUpperCase();
  return upper == 'ENCODE_FAILED' || upper == 'FAILED' || upper == 'ERROR';
}

String _vehicleCommandLatestStatusMessage(
  SuperadminVehicleCommandEntry entry,
) {
  final label = _vehicleCommandStatusLabel(entry.status);
  final rawResponse = entry.responseRaw?.trim() ?? '';
  final hexResponse = entry.responseHex?.trim() ?? '';
  final errorMessage = entry.errorMessage?.trim() ?? '';
  final response = rawResponse.isNotEmpty
      ? rawResponse
      : hexResponse.isNotEmpty
          ? hexResponse
          : null;
  final error = errorMessage.isEmpty ? null : errorMessage;

  if (error != null) {
    return '$label: $error';
  }
  if (response != null) {
    return '$label: $response';
  }

  return label;
}

String _vehicleCommandStatusLabel(String status) {
  switch (status.trim().toUpperCase()) {
    case 'REQUESTED':
      return 'Requested';
    case 'QUEUED':
      return 'Queued';
    case 'QUEUED_OFFLINE':
      return 'Queued until device reconnects';
    case 'SENT':
      return 'Sent to device, waiting for response';
    case 'DELIVERED':
      return 'Delivered';
    case 'RESPONDED':
      return 'Response received';
    case 'ENCODE_FAILED':
      return 'Encoder failed';
    case 'FAILED':
      return 'Failed';
    case 'TIMEOUT':
      return 'No response';
    case 'ERROR':
      return 'Error';
    default:
      final trimmed = status.trim();
      return trimmed.isEmpty ? 'Requested' : trimmed;
  }
}

DateTime? _vehicleSensorTelemetryUpdatedAt(VehicleSummary vehicle) {
  return vehicle.updatedAt ?? vehicle.lastSeenAt;
}

String _formatVehicleSensorUpdatedAt(DateTime value) {
  return _mapFmt.formatDateTime(value.toLocal());
}

String _formatVehicleLogTime(DateTime? value) {
  if (value == null) {
    return '--:--:--';
  }

  return _mapFmt.formatTime(value.toLocal());
}

String _formatVehicleLogDateTime(DateTime? value) {
  if (value == null) {
    return '--';
  }

  return _mapFmt.formatDateTime(value.toLocal());
}

String _formatVehicleLogSpeed(double? value, {required UnitFormatter unitFormatter}) {
  if (value == null || !value.isFinite) {
    return '--';
  }

  return '${_formatVehicleMetricNumber(value, 0)} ${unitFormatter.speedLabel}';
}

String _formatVehicleLogCoordinate(double? value) {
  if (value == null || !value.isFinite) {
    return '--';
  }

  return value.toStringAsFixed(6);
}

String _formatVehicleLogLatLng(SuperadminVehicleLog log) {
  if (!log.hasCoordinates) {
    return '--';
  }

  return '${log.latitude!.toStringAsFixed(5)} / ${log.longitude!.toStringAsFixed(5)}';
}

String _formatVehicleLogBool(
  bool? value, {
  String trueLabel = 'On',
  String falseLabel = 'Off',
}) {
  if (value == null) {
    return '--';
  }

  return value ? trueLabel : falseLabel;
}

String _formatVehicleLogJson(Object? value) {
  if (value == null) {
    return 'null';
  }

  try {
    return const JsonEncoder.withIndent('  ').convert(value);
  } catch (_) {
    return value.toString();
  }
}

String _formatVehicleLogError(Object error) {
  final text = error.toString().trim();
  if (text.isEmpty) {
    return 'Failed to load vehicle logs.';
  }

  return text;
}

double? _parseVehicleDouble(String? raw) {
  final text = raw?.trim() ?? '';
  if (text.isEmpty) {
    return null;
  }

  final direct = double.tryParse(text);
  if (direct != null) {
    return direct;
  }

  final match = RegExp(r'-?\d+(?:\.\d+)?').firstMatch(text.replaceAll(',', ''));
  if (match == null) {
    return null;
  }

  return double.tryParse(match.group(0)!);
}

String _formatVehicleMetricNumber(double value, int fractionDigits) {
  final pattern = switch (fractionDigits) {
    0 => '#,##0',
    1 => '#,##0.0',
    2 => '#,##0.00',
    _ => '#,##0.${'0' * fractionDigits}',
  };

  return NumberFormat(pattern).format(value);
}

Future<void> _openVehicleNavigation(
  BuildContext context,
  double latitude,
  double longitude,
) async {
  final uri = Uri.https('www.google.com', '/maps/search/', <String, String>{
    'api': '1',
    'query': '${latitude.toStringAsFixed(6)},${longitude.toStringAsFixed(6)}',
  });

  final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!launched) {
    if (!context.mounted) return;
    ToastHelper.showError(
      'Unable to open navigation for this vehicle.',
      context: context,
    );
  }
}

String _formatVehicleSpeed(double value) {
  return value.toStringAsFixed(value == value.roundToDouble() ? 0 : 1);
}

String _formatVehicleDistance(double? distanceKm) {
  if (distanceKm == null) {
    return '--';
  }

  return '${distanceKm.toStringAsFixed(1)} km';
}

Color _vehicleRunningIndicatorColor(bool isRunning) {
  return isRunning ? const Color(0xFF20B15A) : const Color(0xFFC9CDD3);
}

_VehicleMarkerStatus _vehicleMarkerStatus(VehicleSummary vehicle) {
  final status = _normalizeVehicleStatus(vehicle.status);
  if (_isInactiveVehicle(vehicle)) {
    return _VehicleMarkerStatus.inactive;
  }
  if (_isRunningVehicle(vehicle)) {
    return _VehicleMarkerStatus.running;
  }
  if (status.contains('idle') ||
      ((vehicle.ignition == true || vehicle.acc == true) &&
          vehicle.speed <= 0)) {
    return _VehicleMarkerStatus.idle;
  }
  if (status.contains('stop') ||
      status.contains('parking') ||
      status.contains('parked') ||
      vehicle.speed <= 0) {
    return _VehicleMarkerStatus.stopped;
  }

  return _VehicleMarkerStatus.unknown;
}

Color _vehicleMarkerColor(_VehicleMarkerStatus status) {
  return switch (status) {
    _VehicleMarkerStatus.running => const Color(0xFF20B15A),
    _VehicleMarkerStatus.idle => const Color(0xFFF59E0B),
    _VehicleMarkerStatus.stopped => const Color(0xFFEF4444),
    _VehicleMarkerStatus.inactive => const Color(0xFF64748B),
    _VehicleMarkerStatus.unknown => const Color(0xFF141118),
  };
}

String _vehicleMarkerAssetPath(_VehicleMarkerStatus status) {
  return status == _VehicleMarkerStatus.running
      ? 'assets/images/vehicleicons/carGreen.png'
      : 'assets/images/vehicleicons/carRed.png';
}

Color _vehicleRippleColor(_VehicleMarkerStatus status) {
  return switch (status) {
    _VehicleMarkerStatus.running => const Color(0xFF20B15A),
    _VehicleMarkerStatus.idle => const Color(0xFFF59E0B),
    _VehicleMarkerStatus.stopped => const Color(0xFFEF4444),
    _VehicleMarkerStatus.inactive => const Color(0xFF64748B),
    _VehicleMarkerStatus.unknown => const Color(0xFF141118),
  };
}

bool _vehicleMarkerShowsRipple(_VehicleMarkerStatus status) {
  return switch (status) {
    _VehicleMarkerStatus.running ||
    _VehicleMarkerStatus.idle ||
    _VehicleMarkerStatus.stopped =>
      true,
    _VehicleMarkerStatus.inactive || _VehicleMarkerStatus.unknown => false,
  };
}

bool _isRunningVehicle(VehicleSummary vehicle) {
  final status = _normalizeVehicleStatus(vehicle.status);
  return vehicle.speed > 0 ||
      status.contains('running') ||
      status.contains('moving') ||
      status.contains('drive');
}

bool _isInactiveVehicle(VehicleSummary vehicle) {
  final status = _normalizeVehicleStatus(vehicle.status);
  if (_isInactiveStatus(status)) {
    return true;
  }

  final deviceStatus = vehicle.deviceConnectionStatus?.trim().toUpperCase();
  if (deviceStatus == 'DISCONNECTED') {
    final lastSeenAt = vehicle.lastSeenAt ?? vehicle.updatedAt;
    if (lastSeenAt == null) {
      return true;
    }

    final age = DateTime.now().difference(lastSeenAt);
    return !age.isNegative && age >= _inactiveVehicleThreshold;
  }

  return false;
}

String _normalizeVehicleStatus(String status) {
  return status.trim().toLowerCase().replaceAll(RegExp(r'[\s-]+'), '_');
}

bool _isInactiveStatus(String normalizedStatus) {
  return const <String>{
    'inactive',
    'no_data',
    'offline',
    'disconnected',
    'license_blocked',
  }.contains(normalizedStatus);
}



