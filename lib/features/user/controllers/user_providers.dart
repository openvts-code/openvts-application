import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../../notifications/controllers/notification_center_controller.dart';
import '../../notifications/models/notification_center_state.dart';
import '../controllers/user_dashboard_controller.dart';
import '../controllers/user_driver_details_controller.dart';
import '../controllers/user_drivers_controller.dart';
import '../controllers/user_geofences_controller.dart';
import '../controllers/user_landmark_bulk_job_controller.dart';
import '../controllers/user_landmark_geometry_editor_controller.dart';
import '../controllers/user_landmark_studio_controller.dart';
import '../controllers/user_notification_settings_controller.dart';
import '../controllers/user_pois_controller.dart';
import '../controllers/user_route_optimisation_controller.dart';
import '../controllers/user_routes_controller.dart';
import '../controllers/user_settings_controller.dart';
import '../controllers/user_share_track_link_controller.dart';
import '../controllers/user_subuser_details_controller.dart';
import '../controllers/user_subusers_controller.dart';
import '../controllers/user_support_controller.dart';
import '../controllers/user_transactions_controller.dart';
import '../controllers/user_vehicle_details_controller.dart';
import '../controllers/user_vehicles_controller.dart';
import '../models/user_dashboard_model.dart';
import '../models/user_dashboard_state.dart';
import '../models/user_driver_model.dart';
import '../models/user_drivers_state.dart';
import '../models/user_landmark_model.dart';
import '../models/user_landmark_state.dart';
import '../models/user_notification_settings_state.dart';
import '../models/user_route_optimisation_state.dart';
import '../models/user_settings_state.dart';
import '../models/user_share_track_link_state.dart';
import '../models/user_subuser_model.dart';
import '../models/user_subusers_state.dart';
import '../models/user_support_state.dart';
import '../models/user_transactions_state.dart';
import '../models/user_vehicle_model.dart';
import '../models/user_vehicle_state.dart';
import '../services/user_dashboard_service.dart';
import '../services/user_driver_service.dart';
import '../services/user_landmark_service.dart';
import '../services/user_notification_service.dart';
import '../services/user_notification_settings_service.dart';
import '../services/user_route_optimisation_service.dart';
import '../services/user_settings_service.dart';
import '../services/user_share_track_link_service.dart';
import '../services/user_subuser_service.dart';
import '../services/user_support_service.dart';
import '../services/user_transactions_service.dart';
import '../services/user_vehicle_service.dart';

final userDashboardServiceProvider = Provider<UserDashboardService>((ref) {
  return UserDashboardService(ref.watch(apiClientProvider));
});

final userVehicleServiceProvider = Provider<UserVehicleService>((ref) {
  return UserVehicleService(ref.watch(apiClientProvider));
});

final userNotificationServiceProvider =
    Provider<UserNotificationService>((ref) {
  return UserNotificationService(ref.watch(apiClientProvider));
});

final userNotificationSettingsServiceProvider =
    Provider<UserNotificationSettingsService>((ref) {
  return UserNotificationSettingsService(ref.watch(apiClientProvider));
});

final userShareTrackLinkServiceProvider =
    Provider<UserShareTrackLinkService>((ref) {
  return UserShareTrackLinkService(ref.watch(apiClientProvider));
});

final userSupportServiceProvider = Provider<UserSupportService>((ref) {
  return UserSupportService(ref.watch(apiClientProvider));
});

final userSettingsServiceProvider = Provider<UserSettingsService>((ref) {
  return UserSettingsService(ref.watch(apiClientProvider));
});

final userTransactionsServiceProvider =
    Provider<UserTransactionsService>((ref) {
  return UserTransactionsService(ref.watch(apiClientProvider));
});

final userDriversServiceProvider = Provider<UserDriverService>((ref) {
  return UserDriverService(ref.watch(apiClientProvider));
});

final userSubUsersServiceProvider = Provider<UserSubUserService>((ref) {
  return UserSubUserService(ref.watch(apiClientProvider));
});

class UserDriverDetailsProviderArgs {
  const UserDriverDetailsProviderArgs({
    required this.driverId,
    this.initialDriver,
  });

  final String driverId;
  final UserDriver? initialDriver;

  @override
  bool operator ==(Object other) {
    return other is UserDriverDetailsProviderArgs && other.driverId == driverId;
  }

  @override
  int get hashCode => driverId.hashCode;
}

final userDriversControllerProvider =
    StateNotifierProvider.autoDispose<UserDriversController, UserDriversState>(
        (ref) {
  final controller = UserDriversController(
    service: ref.watch(userDriversServiceProvider),
  );
  controller.load();
  return controller;
});

final userDriverDetailsControllerProvider = StateNotifierProvider.autoDispose
    .family<UserDriverDetailsController, UserDriverDetailsState,
        UserDriverDetailsProviderArgs>(
  (ref, args) {
    return UserDriverDetailsController(
      driverId: args.driverId,
      initialDriver: args.initialDriver,
      service: ref.watch(userDriversServiceProvider),
    )..loadInitial();
  },
);

final userSubUsersControllerProvider = StateNotifierProvider.autoDispose<
    UserSubUsersController, UserSubUsersState>((ref) {
  final controller = UserSubUsersController(
    service: ref.watch(userSubUsersServiceProvider),
  );
  controller.loadInitial();
  return controller;
});

class UserSubUserDetailsProviderArgs {
  const UserSubUserDetailsProviderArgs({
    required this.subUserId,
    this.initialSubUser,
  });

  final String subUserId;
  final UserSubUser? initialSubUser;

  @override
  bool operator ==(Object other) {
    return other is UserSubUserDetailsProviderArgs &&
        other.subUserId == subUserId;
  }

  @override
  int get hashCode => subUserId.hashCode;
}

final userSubUserDetailsControllerProvider = StateNotifierProvider.autoDispose
    .family<UserSubUserDetailsController, UserSubUserDetailsState,
        UserSubUserDetailsProviderArgs>(
  (ref, args) {
    return UserSubUserDetailsController(
      subUserId: args.subUserId,
      initialSubUser: args.initialSubUser,
      service: ref.watch(userSubUsersServiceProvider),
    )..loadInitial();
  },
);

final userDashboardControllerProvider = StateNotifierProvider.autoDispose<
    UserDashboardController, UserDashboardState>((ref) {
  final controller = UserDashboardController(
    service: ref.watch(userDashboardServiceProvider),
    localCache: ref.watch(localCacheProvider),
  );
  controller.loadInitial();
  return controller;
});

class UserDashboardRefreshArgs {
  const UserDashboardRefreshArgs({
    required this.widgetId,
    required this.refreshKey,
  });

  final String widgetId;
  final int refreshKey;

  bool get forceRefresh => refreshKey > 0;

  @override
  bool operator ==(Object other) {
    return other is UserDashboardRefreshArgs &&
        other.widgetId == widgetId &&
        other.refreshKey == refreshKey;
  }

  @override
  int get hashCode => Object.hash(widgetId, refreshKey);
}

class UserDashboardVehicleScopedArgs extends UserDashboardRefreshArgs {
  const UserDashboardVehicleScopedArgs({
    required super.widgetId,
    required super.refreshKey,
    required this.vehicleId,
  });

  final String? vehicleId;

  @override
  bool operator ==(Object other) {
    return other is UserDashboardVehicleScopedArgs &&
        other.widgetId == widgetId &&
        other.refreshKey == refreshKey &&
        other.vehicleId == vehicleId;
  }

  @override
  int get hashCode => Object.hash(widgetId, refreshKey, vehicleId);
}

class UserDashboardTopAssetsArgs extends UserDashboardRefreshArgs {
  const UserDashboardTopAssetsArgs({
    required super.widgetId,
    required super.refreshKey,
    required this.from,
    required this.to,
    required this.limit,
  });

  final DateTime from;
  final DateTime to;
  final int limit;

  @override
  bool operator ==(Object other) {
    return other is UserDashboardTopAssetsArgs &&
        other.widgetId == widgetId &&
        other.refreshKey == refreshKey &&
        other.from == from &&
        other.to == to &&
        other.limit == limit;
  }

  @override
  int get hashCode => Object.hash(widgetId, refreshKey, from, to, limit);
}

class UserDashboardRangeArgs extends UserDashboardVehicleScopedArgs {
  const UserDashboardRangeArgs({
    required super.widgetId,
    required super.refreshKey,
    required super.vehicleId,
    required this.from,
    required this.to,
  });

  final DateTime from;
  final DateTime to;

  @override
  bool operator ==(Object other) {
    return other is UserDashboardRangeArgs &&
        other.widgetId == widgetId &&
        other.refreshKey == refreshKey &&
        other.vehicleId == vehicleId &&
        other.from == from &&
        other.to == to;
  }

  @override
  int get hashCode => Object.hash(widgetId, refreshKey, vehicleId, from, to);
}

class UserDashboardSensorHistoryArgs extends UserDashboardRangeArgs {
  const UserDashboardSensorHistoryArgs({
    required super.widgetId,
    required super.refreshKey,
    required super.vehicleId,
    required super.from,
    required super.to,
    required this.sensorId,
  });

  final String? sensorId;

  @override
  bool operator ==(Object other) {
    return other is UserDashboardSensorHistoryArgs &&
        other.widgetId == widgetId &&
        other.refreshKey == refreshKey &&
        other.vehicleId == vehicleId &&
        other.from == from &&
        other.to == to &&
        other.sensorId == sensorId;
  }

  @override
  int get hashCode =>
      Object.hash(widgetId, refreshKey, vehicleId, from, to, sensorId);
}

final userDashboardFleetStatusProvider = FutureProvider.autoDispose
    .family<UserDashboardFleetStatus, UserDashboardRefreshArgs>((ref, args) {
  return ref
      .watch(userDashboardControllerProvider.notifier)
      .getFleetStatus(forceRefresh: args.forceRefresh);
});

final userDashboardTopAssetsProvider = FutureProvider.autoDispose
    .family<UserDashboardTopAssets, UserDashboardTopAssetsArgs>((ref, args) {
  return ref.watch(userDashboardControllerProvider.notifier).getTopPerformingAssets(
        from: args.from,
        to: args.to,
        limit: args.limit,
        forceRefresh: args.forceRefresh,
      );
});

final userDashboardUsageProvider = FutureProvider.autoDispose
    .family<
        ({List<UserDashboardVehicleOption> vehicles, UserDashboardUsageLast7Days usage}),
        UserDashboardVehicleScopedArgs>((ref, args) async {
  final controller = ref.watch(userDashboardControllerProvider.notifier);
  final results = await Future.wait<dynamic>([
    controller.getVehicles(forceRefresh: args.forceRefresh),
    controller.getUsageLast7Days(
      vehicleId: args.vehicleId,
      forceRefresh: args.forceRefresh,
    ),
  ]);
  return (
    vehicles: results[0] as List<UserDashboardVehicleOption>,
    usage: results[1] as UserDashboardUsageLast7Days,
  );
});

final userDashboardWeeklyProvider = FutureProvider.autoDispose
    .family<
        ({
          List<UserDashboardVehicleOption> vehicles,
          UserDashboardWeeklyComparison comparison,
        }),
        UserDashboardVehicleScopedArgs>((ref, args) async {
  final controller = ref.watch(userDashboardControllerProvider.notifier);
  final results = await Future.wait<dynamic>([
    controller.getVehicles(forceRefresh: args.forceRefresh),
    controller.getWeeklyComparison(
      vehicleId: args.vehicleId,
      forceRefresh: args.forceRefresh,
    ),
  ]);
  return (
    vehicles: results[0] as List<UserDashboardVehicleOption>,
    comparison: results[1] as UserDashboardWeeklyComparison,
  );
});

final userDashboardDayNightProvider = FutureProvider.autoDispose
    .family<
        ({
          List<UserDashboardVehicleOption> vehicles,
          UserDashboardDayNightComparison comparison,
        }),
        UserDashboardRangeArgs>((ref, args) async {
  final controller = ref.watch(userDashboardControllerProvider.notifier);
  final vehicles = await controller.getVehicles(forceRefresh: args.forceRefresh);
  final selectedVehicleId = args.vehicleId == 'all' ? null : args.vehicleId;
  final comparison = await controller.getDayNightComparison(
    vehicleId: selectedVehicleId,
    from: args.from,
    to: args.to,
  );
  return (vehicles: vehicles, comparison: comparison);
});

final userDashboardSensorHistoryProvider = FutureProvider.autoDispose
    .family<
        ({
          List<UserDashboardVehicleOption> vehicles,
          List<UserDashboardSensorOption> sensors,
          String? selectedVehicleId,
          String? selectedSensorId,
          UserDashboardSensorHistory? history,
          String? emptyMessage,
        }),
        UserDashboardSensorHistoryArgs>((ref, args) async {
  final controller = ref.watch(userDashboardControllerProvider.notifier);
  final vehicles = await controller.getVehicles(forceRefresh: args.forceRefresh);
  if (vehicles.isEmpty) {
    return (
      vehicles: vehicles,
      sensors: const <UserDashboardSensorOption>[],
      selectedVehicleId: null,
      selectedSensorId: null,
      history: null,
      emptyMessage: 'No vehicles available.',
    );
  }

  final requestedVehicleId = args.vehicleId;
  final vehicleId = requestedVehicleId != null &&
          vehicles.any((vehicle) => vehicle.id == requestedVehicleId)
      ? requestedVehicleId
      : vehicles.first.id;
  final sensors = await controller.getVehicleSensors(vehicleId);
  if (sensors.isEmpty) {
    final vehicleName = vehicles
        .firstWhere((vehicle) => vehicle.id == vehicleId, orElse: () => vehicles.first)
        .name;
    return (
      vehicles: vehicles,
      sensors: sensors,
      selectedVehicleId: vehicleId,
      selectedSensorId: null,
      history: null,
      emptyMessage: 'No sensors available for $vehicleName.',
    );
  }

  final requestedSensorId = args.sensorId;
  final sensorId = requestedSensorId != null &&
          sensors.any((sensor) => sensor.id == requestedSensorId)
      ? requestedSensorId
      : sensors.first.id;
  final history = await controller.getSensorHistory(
    vehicleId: vehicleId,
    sensorId: sensorId,
    from: args.from,
    to: args.to,
    maxPoints: 500,
  );
  return (
    vehicles: vehicles,
    sensors: sensors,
    selectedVehicleId: vehicleId,
    selectedSensorId: sensorId,
    history: history,
    emptyMessage: null,
  );
});

final userDashboardRecentAlertsProvider = FutureProvider.autoDispose
    .family<
        ({
          List<UserDashboardVehicleOption> vehicles,
          UserDashboardRecentAlertsPage page,
        }),
        UserDashboardVehicleScopedArgs>((ref, args) async {
  final controller = ref.watch(userDashboardControllerProvider.notifier);
  final vehicles = await controller.getVehicles(forceRefresh: args.forceRefresh);
  final selectedVehicleId = args.vehicleId == 'all' ? null : args.vehicleId;
  final page = await controller.getRecentAlerts(
    vehicleId: selectedVehicleId,
    limit: 30,
    refreshKey: args.forceRefresh
        ? DateTime.now().millisecondsSinceEpoch.toString()
        : null,
    forceRefresh: args.forceRefresh,
  );
  return (vehicles: vehicles, page: page);
});

final userDashboardRecentAlertDetailProvider =
    FutureProvider.autoDispose.family<UserDashboardAlertDetail, String>(
  (ref, id) {
    return ref
        .watch(userDashboardControllerProvider.notifier)
        .getRecentAlertDetail(id);
  },
);

final userDashboardSendCommandProvider = FutureProvider.autoDispose
    .family<
        ({
          List<UserDashboardVehicleOption> allVehicles,
          List<UserDashboardVehicleOption> vehicles,
          List<UserDashboardCustomCommand> commands,
          List<UserDashboardSystemVariable> variables,
        }),
        UserDashboardRefreshArgs>((ref, args) async {
  final controller = ref.watch(userDashboardControllerProvider.notifier);
  final results = await Future.wait<dynamic>([
    controller.getVehicles(forceRefresh: args.forceRefresh),
    controller.getCustomCommands(),
    controller.getSystemVariables(),
  ]);
  final allVehicles = results[0] as List<UserDashboardVehicleOption>;
  return (
    allVehicles: allVehicles,
    vehicles: allVehicles
        .where((vehicle) => !vehicle.isLicenseBlocked)
        .toList(growable: false),
    commands: (results[1] as List<UserDashboardCustomCommand>)
        .where((command) => command.isActive)
        .toList(growable: false),
    variables: (results[2] as List<UserDashboardSystemVariable>)
        .where((variable) => variable.isActive)
        .toList(growable: false),
  );
});

final userVehiclesControllerProvider = StateNotifierProvider.autoDispose<
    UserVehiclesController, UserVehiclesState>((ref) {
  final controller = UserVehiclesController(
    service: ref.watch(userVehicleServiceProvider),
  );
  controller.load();
  return controller;
});

final userShareTrackLinkControllerProvider = StateNotifierProvider.autoDispose<
    UserShareTrackLinkController, UserShareTrackLinkState>((ref) {
  final controller = UserShareTrackLinkController(
    service: ref.watch(userShareTrackLinkServiceProvider),
  );
  controller.load();
  return controller;
});

final userSupportControllerProvider =
    StateNotifierProvider.autoDispose<UserSupportController, UserSupportState>(
        (ref) {
  final controller = UserSupportController(
    service: ref.watch(userSupportServiceProvider),
  );
  controller.loadTickets();
  return controller;
});

final userSettingsControllerProvider = StateNotifierProvider.autoDispose<
    UserSettingsController, UserSettingsState>((ref) {
  final controller = UserSettingsController(
    service: ref.watch(userSettingsServiceProvider),
  );
  controller.loadInitial();
  return controller;
});

final userTransactionsControllerProvider = StateNotifierProvider.autoDispose<
    UserTransactionsController, UserTransactionsState>((ref) {
  final controller = UserTransactionsController(
    service: ref.watch(userTransactionsServiceProvider),
  );
  controller.loadInitial();
  return controller;
});

class UserVehicleDetailsProviderArgs {
  const UserVehicleDetailsProviderArgs({
    required this.vehicleId,
    this.initialVehicle,
  });

  final String vehicleId;
  final UserVehicleListItem? initialVehicle;

  @override
  bool operator ==(Object other) {
    return other is UserVehicleDetailsProviderArgs &&
        other.vehicleId == vehicleId;
  }

  @override
  int get hashCode => vehicleId.hashCode;
}

final userVehicleDetailsControllerProvider = StateNotifierProvider.autoDispose
    .family<UserVehicleDetailsController, UserVehicleDetailsState,
        UserVehicleDetailsProviderArgs>(
  (ref, args) {
    return UserVehicleDetailsController(
      vehicleId: args.vehicleId,
      initialVehicle: args.initialVehicle,
      service: ref.watch(userVehicleServiceProvider),
    )..loadInitial();
  },
);

final userNotificationCenterProvider = StateNotifierProvider.autoDispose<
    NotificationCenterController, NotificationCenterState>((ref) {
  final controller = NotificationCenterController(
    ref.watch(userNotificationServiceProvider),
  );
  controller.load();
  return controller;
});

final userNotificationUnreadBadgeProvider =
    FutureProvider.autoDispose<int>((ref) async {
  final cacheLink = ref.keepAlive();
  final cacheTimer = Timer(const Duration(seconds: 30), cacheLink.close);
  ref.onDispose(cacheTimer.cancel);

  try {
    final service = ref.watch(userNotificationServiceProvider);
    return await service.getUnreadBadgeCountLightweight();
  } catch (_) {
    return 0;
  }
});

final userNotificationSettingsControllerProvider =
    StateNotifierProvider.autoDispose<UserNotificationSettingsController,
        UserNotificationSettingsState>((ref) {
  final controller = UserNotificationSettingsController(
    service: ref.watch(userNotificationSettingsServiceProvider),
  );
  controller.load();
  return controller;
});

// ---------------------------------------------------------------------------
// Landmark Studio (geofences, POIs, routes)
// ---------------------------------------------------------------------------

final userLandmarkServiceProvider = Provider<UserLandmarkService>((ref) {
  return UserLandmarkService(ref.watch(apiClientProvider));
});

final userLandmarkStudioControllerProvider = StateNotifierProvider.autoDispose<
    UserLandmarkStudioController, UserLandmarkStudioCountsState>((ref) {
  final controller = UserLandmarkStudioController(
    service: ref.watch(userLandmarkServiceProvider),
  );
  controller.load();
  return controller;
});

final userGeofencesControllerProvider = StateNotifierProvider.autoDispose<
    UserGeofencesController, UserGeofencesState>((ref) {
  final controller = UserGeofencesController(
    service: ref.watch(userLandmarkServiceProvider),
  );
  controller.load();
  return controller;
});

final userPoisControllerProvider =
    StateNotifierProvider.autoDispose<UserPoisController, UserPoisState>((ref) {
  final controller = UserPoisController(
    service: ref.watch(userLandmarkServiceProvider),
  );
  controller.load();
  return controller;
});

final userRoutesControllerProvider =
    StateNotifierProvider.autoDispose<UserRoutesController, UserRoutesState>(
        (ref) {
  final controller = UserRoutesController(
    service: ref.watch(userLandmarkServiceProvider),
  );
  controller.load();
  return controller;
});

final userLandmarkBulkJobControllerProvider = StateNotifierProvider.autoDispose<
    UserLandmarkBulkJobController, UserLandmarkBulkJobState>((ref) {
  return UserLandmarkBulkJobController(
    service: ref.watch(userLandmarkServiceProvider),
  );
});

// ---------------------------------------------------------------------------
// Route Optimisation
// ---------------------------------------------------------------------------

final userRouteOptimisationServiceProvider =
    Provider<UserRouteOptimisationService>((ref) {
  return UserRouteOptimisationService(ref.watch(userLandmarkServiceProvider));
});

final userRouteOptimisationControllerProvider =
    StateNotifierProvider.autoDispose<UserRouteOptimisationController,
        UserRouteOptimisationState>((ref) {
  return UserRouteOptimisationController(
    service: ref.watch(userRouteOptimisationServiceProvider),
  );
});

class UserLandmarkGeometryEditorArgs {
  const UserLandmarkGeometryEditorArgs({
    this.initialMode = UserGeofenceEditorMode.polygon,
    this.initialCenterLat,
    this.initialCenterLon,
    this.initialZoom = 14,
  });

  final UserGeofenceEditorMode initialMode;
  final double? initialCenterLat;
  final double? initialCenterLon;
  final double initialZoom;

  @override
  bool operator ==(Object other) {
    return other is UserLandmarkGeometryEditorArgs &&
        other.initialMode == initialMode &&
        other.initialCenterLat == initialCenterLat &&
        other.initialCenterLon == initialCenterLon &&
        other.initialZoom == initialZoom;
  }

  @override
  int get hashCode => Object.hash(
        initialMode,
        initialCenterLat,
        initialCenterLon,
        initialZoom,
      );
}

final userLandmarkGeometryEditorControllerProvider =
    StateNotifierProvider.autoDispose.family<
        UserLandmarkGeometryEditorController,
        UserLandmarkGeometryEditorState,
        UserLandmarkGeometryEditorArgs>((ref, args) {
  return UserLandmarkGeometryEditorController(
    initialMode: args.initialMode,
    initialCenter:
        args.initialCenterLat != null && args.initialCenterLon != null
            ? UserGeoPoint(
                lat: args.initialCenterLat!,
                lon: args.initialCenterLon!,
              )
            : null,
    initialZoom: args.initialZoom,
  );
});
