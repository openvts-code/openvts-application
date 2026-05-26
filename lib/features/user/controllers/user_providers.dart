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
