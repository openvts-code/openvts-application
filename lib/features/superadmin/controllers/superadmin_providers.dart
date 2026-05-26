import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../../../shared/models/vehicle_summary.dart';
import '../../notifications/controllers/notification_center_controller.dart';
import '../../notifications/models/notification_center_state.dart';
import '../controllers/superadmin_admin_details_controller.dart';
import '../controllers/superadmin_administrators_controller.dart';
import '../controllers/superadmin_dashboard_controller.dart';
import '../controllers/superadmin_map_live_controller.dart';
import '../controllers/superadmin_payments_controller.dart';
import '../controllers/superadmin_server_controller.dart';
import '../controllers/superadmin_settings_controller.dart';
import '../controllers/superadmin_support_controller.dart';
import '../controllers/superadmin_vehicle_history_controller.dart';
import '../models/superadmin_admin_details_state.dart';
import '../models/superadmin_administrators_state.dart';
import '../models/superadmin_dashboard_state.dart';
import '../models/superadmin_map_live_state.dart';
import '../models/superadmin_map_overlay_model.dart';
import '../models/superadmin_payments_state.dart';
import '../models/superadmin_server_state.dart';
import '../models/superadmin_settings_state.dart';
import '../models/superadmin_support_state.dart';
import '../models/superadmin_vehicle_history_model.dart';
import '../models/superadmin_vehicle_model.dart';
import '../services/superadmin_admin_details_service.dart';
import '../services/superadmin_administrators_service.dart';
import '../services/superadmin_dashboard_service.dart';
import '../services/superadmin_map_events_service.dart';
import '../services/superadmin_map_overlay_service.dart';
import '../services/superadmin_notification_service.dart';
import '../services/superadmin_payments_service.dart';
import '../services/superadmin_server_service.dart';
import '../services/superadmin_settings_service.dart';
import '../services/superadmin_support_service.dart';
import '../services/superadmin_vehicle_service.dart';

final superadminDashboardServiceProvider =
    Provider<SuperadminDashboardService>((ref) {
  return SuperadminDashboardService(ref.watch(apiClientProvider));
});

final superadminVehicleServiceProvider =
    Provider<SuperadminVehicleService>((ref) {
  return SuperadminVehicleService(ref.watch(apiClientProvider));
});

final superadminMapOverlayServiceProvider =
    Provider<SuperadminMapOverlayService>((ref) {
  return SuperadminMapOverlayService(ref.watch(apiClientProvider));
});

final superadminMapEventsServiceProvider =
    Provider<SuperadminMapEventsService>((ref) {
  return SuperadminMapEventsService(ref.watch(apiClientProvider));
});

final superadminAdministratorsServiceProvider =
    Provider<SuperadminAdministratorsService>((ref) {
  return SuperadminAdministratorsService(ref.watch(apiClientProvider));
});

final superadminNotificationServiceProvider =
    Provider<SuperadminNotificationService>((ref) {
  return SuperadminNotificationService(ref.watch(apiClientProvider));
});

final superadminServerServiceProvider =
    Provider<SuperadminServerService>((ref) {
  return SuperadminServerService(ref.watch(apiClientProvider));
});

final superadminSupportServiceProvider =
    Provider<SuperadminSupportService>((ref) {
  return SuperadminSupportService(ref.watch(apiClientProvider));
});

final superadminPaymentsServiceProvider =
    Provider<SuperadminPaymentsService>((ref) {
  return SuperadminPaymentsService(ref.watch(apiClientProvider));
});

final superadminDashboardControllerProvider = StateNotifierProvider.autoDispose<
    SuperadminDashboardController, SuperadminDashboardState>((ref) {
  return SuperadminDashboardController(
    ref.watch(superadminDashboardServiceProvider),
  );
});

final superadminVehiclePageProvider =
    FutureProvider.autoDispose<SuperadminVehiclePage>((ref) {
  return ref.watch(superadminVehicleServiceProvider).getVehicles();
});

final superadminVehiclesProvider =
    FutureProvider.autoDispose<List<VehicleSummary>>((ref) {
  return ref.watch(superadminVehicleServiceProvider).getMapVehicles();
});

final superadminMapTelemetryProvider =
    FutureProvider.autoDispose<SuperadminMapTelemetry>((ref) {
  return ref.watch(superadminVehicleServiceProvider).getMapTelemetry();
});

final superadminVehicleDetailsProvider =
    FutureProvider.family<SuperadminVehicleDetails, String>((ref, imei) {
  return ref.watch(superadminVehicleServiceProvider).getVehicleDetailsByImei(
        imei,
      );
});

final superadminVehicleHistoryControllerProvider =
    StateNotifierProvider.autoDispose<SuperadminVehicleHistoryController,
        SuperadminVehicleHistoryState>((ref) {
  return SuperadminVehicleHistoryController(
    ref.watch(superadminVehicleServiceProvider),
  );
});

final superadminMapGeofencesProvider =
    FutureProvider<List<SuperadminMapGeofence>>((ref) {
  return ref.watch(superadminMapOverlayServiceProvider).getGeofences();
});

final superadminMapPoisProvider = FutureProvider<List<SuperadminMapPoi>>((ref) {
  return ref.watch(superadminMapOverlayServiceProvider).getPois();
});

final superadminMapRoutesProvider =
    FutureProvider<List<SuperadminMapRoute>>((ref) {
  return ref.watch(superadminMapOverlayServiceProvider).getRoutes();
});

final superadminMapLiveProvider = StateNotifierProvider.autoDispose<
    SuperadminMapLiveController, SuperadminMapLiveState>((ref) {
  final controller = SuperadminMapLiveController(
    ref.watch(superadminVehicleServiceProvider),
    ref.watch(superadminMapEventsServiceProvider),
    ref.watch(socketServiceProvider),
  );
  controller.initialize();
  return controller;
});

final superadminAdministratorsControllerProvider =
    StateNotifierProvider.autoDispose<SuperadminAdministratorsController,
        SuperadminAdministratorsState>((ref) {
  return SuperadminAdministratorsController(
    ref.watch(superadminAdministratorsServiceProvider),
  );
});

final superadminNotificationCenterProvider = StateNotifierProvider.autoDispose<
    NotificationCenterController, NotificationCenterState>((ref) {
  final controller = NotificationCenterController(
    ref.watch(superadminNotificationServiceProvider),
  );
  controller.load();
  return controller;
});

final superadminNotificationUnreadBadgeProvider =
    FutureProvider.autoDispose<int>((ref) async {
  final cacheLink = ref.keepAlive();
  final cacheTimer = Timer(const Duration(seconds: 30), cacheLink.close);
  ref.onDispose(cacheTimer.cancel);

  try {
    final service = ref.watch(superadminNotificationServiceProvider);
    return await service.getUnreadBadgeCountLightweight();
  } catch (_) {
    return 0;
  }
});

final superadminServerControllerProvider = StateNotifierProvider.autoDispose<
    SuperadminServerController, SuperadminServerState>((ref) {
  return SuperadminServerController(
    ref.watch(superadminServerServiceProvider),
  );
});

final superadminSupportControllerProvider = StateNotifierProvider.autoDispose<
    SuperadminSupportController, SuperadminSupportState>((ref) {
  return SuperadminSupportController(
    ref.watch(superadminSupportServiceProvider),
  );
});

final superadminPaymentsControllerProvider = StateNotifierProvider.autoDispose<
    SuperadminPaymentsController, SuperadminPaymentsState>((ref) {
  return SuperadminPaymentsController(
    ref.watch(superadminPaymentsServiceProvider),
  );
});

final superadminSettingsServiceProvider =
    Provider<SuperadminSettingsService>((ref) {
  return SuperadminSettingsService(ref.watch(apiClientProvider));
});

final superadminSettingsControllerProvider = StateNotifierProvider.autoDispose<
    SuperadminSettingsController, SuperadminSettingsState>((ref) {
  return SuperadminSettingsController(
    ref.watch(superadminSettingsServiceProvider),
  );
});

final superadminAdminDetailsServiceProvider =
    Provider<SuperadminAdminDetailsService>((ref) {
  return SuperadminAdminDetailsService(ref.watch(apiClientProvider));
});

final superadminAdminDetailsControllerProvider =
    StateNotifierProvider.autoDispose.family<SuperadminAdminDetailsController,
        SuperadminAdminDetailsState, String>((ref, adminId) {
  return SuperadminAdminDetailsController(
    adminId: adminId,
    detailsService: ref.watch(superadminAdminDetailsServiceProvider),
    paymentsService: ref.watch(superadminPaymentsServiceProvider),
  )..loadInitial();
});
