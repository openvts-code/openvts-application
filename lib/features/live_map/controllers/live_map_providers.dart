import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../../superadmin/models/superadmin_map_overlay_model.dart';
import '../../superadmin/models/superadmin_vehicle_history_model.dart';
import '../models/live_map_role_config.dart';
import '../models/live_map_state.dart';
import '../services/live_map_events_service.dart';
import '../services/live_map_vehicle_service.dart';
import 'live_map_controller.dart';
import 'live_map_vehicle_history_controller.dart';

/// Scope-local "current role config" handle.
///
/// The shared [LiveMapScreen] overrides this provider inside its own
/// `ProviderScope` with the role config it received from its caller. Every
/// downstream provider in this file reads from it, so screen/widget code
/// stays argument-free and identical across superadmin / admin / user
/// roles.
final currentLiveMapConfigProvider = Provider<LiveMapRoleConfig>((ref) {
  throw StateError(
    'currentLiveMapConfigProvider was read outside of a LiveMapScreen scope. '
    'Override it via ProviderScope when mounting LiveMapScreen.',
  );
});

/// Role-aware vehicle service for the currently scoped live map.
final liveMapVehicleServiceProvider = Provider<LiveMapVehicleService>(
  (ref) {
    return LiveMapVehicleService(
      apiClient: ref.watch(apiClientProvider),
      config: ref.watch(currentLiveMapConfigProvider),
    );
  },
  dependencies: <ProviderOrFamily>[currentLiveMapConfigProvider],
);

/// Role-aware map alert/event service for the currently scoped live map.
final liveMapEventsServiceProvider = Provider<LiveMapEventsService>(
  (ref) {
    return LiveMapEventsService(
      apiClient: ref.watch(apiClientProvider),
      config: ref.watch(currentLiveMapConfigProvider),
    );
  },
  dependencies: <ProviderOrFamily>[currentLiveMapConfigProvider],
);

/// Role-aware live map controller (telemetry + alerts) for the scoped role.
final liveMapControllerProvider =
    StateNotifierProvider.autoDispose<LiveMapController, LiveMapState>(
  (ref) {
    final controller = LiveMapController(
      vehicleService: ref.watch(liveMapVehicleServiceProvider),
      mapEventsService: ref.watch(liveMapEventsServiceProvider),
      socketService: ref.watch(socketServiceProvider),
      config: ref.watch(currentLiveMapConfigProvider),
    );
    controller.initialize();
    return controller;
  },
  dependencies: <ProviderOrFamily>[
    currentLiveMapConfigProvider,
    liveMapVehicleServiceProvider,
    liveMapEventsServiceProvider,
  ],
);

/// Role-aware vehicle-details lookup keyed by IMEI.
final liveMapVehicleDetailsProvider =
    FutureProvider.family<LiveMapVehicleDetails, String>(
  (ref, imei) {
    return ref
        .watch(liveMapVehicleServiceProvider)
        .getVehicleDetailsByImei(imei);
  },
  dependencies: <ProviderOrFamily>[
    currentLiveMapConfigProvider,
    liveMapVehicleServiceProvider,
  ],
);

/// Role-aware vehicle history controller (Quick Track tab).
final liveMapVehicleHistoryControllerProvider = StateNotifierProvider
    .autoDispose<LiveMapVehicleHistoryController,
        SuperadminVehicleHistoryState>(
  (ref) {
    return LiveMapVehicleHistoryController(
      ref.watch(liveMapVehicleServiceProvider),
    );
  },
  dependencies: <ProviderOrFamily>[
    currentLiveMapConfigProvider,
    liveMapVehicleServiceProvider,
  ],
);

/// Role-aware geofence overlay.
final liveMapGeofencesProvider = FutureProvider<List<SuperadminMapGeofence>>(
  (ref) {
    return ref.watch(liveMapVehicleServiceProvider).getGeofences();
  },
  dependencies: <ProviderOrFamily>[
    currentLiveMapConfigProvider,
    liveMapVehicleServiceProvider,
  ],
);

/// Role-aware POI overlay.
final liveMapPoisProvider = FutureProvider<List<SuperadminMapPoi>>(
  (ref) {
    return ref.watch(liveMapVehicleServiceProvider).getPois();
  },
  dependencies: <ProviderOrFamily>[
    currentLiveMapConfigProvider,
    liveMapVehicleServiceProvider,
  ],
);

/// Role-aware route overlay.
final liveMapRoutesProvider = FutureProvider<List<SuperadminMapRoute>>(
  (ref) {
    return ref.watch(liveMapVehicleServiceProvider).getRoutes();
  },
  dependencies: <ProviderOrFamily>[
    currentLiveMapConfigProvider,
    liveMapVehicleServiceProvider,
  ],
);
