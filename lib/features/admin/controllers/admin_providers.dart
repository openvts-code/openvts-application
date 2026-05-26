import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../notifications/controllers/notification_center_controller.dart';
import '../../notifications/models/notification_center_state.dart';
import '../models/admin_dashboard_state.dart';
import '../models/admin_driver_details_state.dart';
import '../models/admin_drivers_state.dart';
import '../models/admin_inventory_state.dart';
import '../models/admin_logs_state.dart';
import '../models/admin_payments_state.dart';
import '../models/admin_plans_state.dart';
import '../models/admin_settings_state.dart';
import '../models/admin_support_state.dart';
import '../models/admin_team_state.dart';
import '../models/admin_transactions_state.dart';
import '../models/admin_user_details_state.dart';
import '../models/admin_users_state.dart';
import '../models/admin_vehicle_state.dart';
import '../services/admin_calendar_service.dart';
import '../services/admin_dashboard_service.dart';
import '../services/admin_drivers_service.dart';
import '../services/admin_inventory_service.dart';
import '../services/admin_logs_service.dart';
import '../services/admin_notification_service.dart';
import '../services/admin_payments_service.dart';
import '../services/admin_plans_service.dart';
import '../services/admin_settings_service.dart';
import '../services/admin_support_service.dart';
import '../services/admin_team_service.dart';
import '../services/admin_transactions_service.dart';
import '../services/admin_user_details_service.dart';
import '../services/admin_users_service.dart';
import '../services/admin_vehicle_service.dart';
import 'admin_dashboard_controller.dart';
import 'admin_driver_details_controller.dart';
import 'admin_drivers_controller.dart';
import 'admin_inventory_controller.dart';
import 'admin_logs_controller.dart';
import 'admin_payments_controller.dart';
import 'admin_plans_controller.dart';
import 'admin_settings_controller.dart';
import 'admin_support_controller.dart';
import 'admin_team_controller.dart';
import 'admin_transactions_controller.dart';
import 'admin_user_details_controller.dart';
import 'admin_users_controller.dart';
import 'admin_vehicle_details_controller.dart';
import 'admin_vehicles_controller.dart';

final adminDashboardServiceProvider = Provider<AdminDashboardService>((ref) {
  return AdminDashboardService(ref.watch(apiClientProvider));
});

final adminCalendarServiceProvider = Provider<AdminCalendarService>((ref) {
  return AdminCalendarService(ref.watch(apiClientProvider));
});

final adminVehicleServiceProvider = Provider<AdminVehicleService>((ref) {
  return AdminVehicleService(ref.watch(apiClientProvider));
});

final adminUsersServiceProvider = Provider<AdminUsersService>((ref) {
  return AdminUsersService(ref.watch(apiClientProvider));
});

final adminDriversServiceProvider = Provider<AdminDriversService>((ref) {
  return AdminDriversService(ref.watch(apiClientProvider));
});

final adminTeamServiceProvider = Provider<AdminTeamService>((ref) {
  return AdminTeamService(ref.watch(apiClientProvider));
});

final adminInventoryServiceProvider = Provider<AdminInventoryService>((ref) {
  return AdminInventoryService(ref.watch(apiClientProvider));
});

final adminLogsServiceProvider = Provider<AdminLogsService>((ref) {
  return AdminLogsService(ref.watch(apiClientProvider));
});

final adminPaymentsServiceProvider = Provider<AdminPaymentsService>((ref) {
  return AdminPaymentsService(ref.watch(apiClientProvider));
});

final adminPlansServiceProvider = Provider<AdminPlansService>((ref) {
  return AdminPlansService(ref.watch(apiClientProvider));
});

final adminSettingsServiceProvider = Provider<AdminSettingsService>((ref) {
  return AdminSettingsService(ref.watch(apiClientProvider));
});

final adminSupportServiceProvider = Provider<AdminSupportService>((ref) {
  return AdminSupportService(ref.watch(apiClientProvider));
});

final adminTransactionsServiceProvider =
    Provider<AdminTransactionsService>((ref) {
  return AdminTransactionsService(ref.watch(apiClientProvider));
});

final adminUserDetailsServiceProvider = Provider<AdminUserDetailsService>((
  ref,
) {
  return AdminUserDetailsService(ref.watch(apiClientProvider));
});

final adminNotificationServiceProvider = Provider<AdminNotificationService>((
  ref,
) {
  return AdminNotificationService(ref.watch(apiClientProvider));
});

final adminDashboardControllerProvider = StateNotifierProvider.autoDispose<
    AdminDashboardController, AdminDashboardState>((ref) {
  final controller = AdminDashboardController(
    service: ref.watch(adminDashboardServiceProvider),
    localCache: ref.watch(localCacheProvider),
  );
  controller.load();
  return controller;
});

final adminVehiclesControllerProvider = StateNotifierProvider.autoDispose<
    AdminVehiclesController, AdminVehiclesState>((ref) {
  final controller = AdminVehiclesController(
    service: ref.watch(adminVehicleServiceProvider),
  );
  controller.load();
  return controller;
});

final adminUsersControllerProvider =
    StateNotifierProvider.autoDispose<AdminUsersController, AdminUsersState>((
  ref,
) {
  final controller = AdminUsersController(
    service: ref.watch(adminUsersServiceProvider),
    authController: ref.read(authControllerProvider.notifier),
  );
  controller.load();
  return controller;
});

final adminDriversControllerProvider = StateNotifierProvider.autoDispose<
    AdminDriversController, AdminDriversState>((ref) {
  final controller = AdminDriversController(
    service: ref.watch(adminDriversServiceProvider),
  );
  controller.load();
  return controller;
});

final adminTeamControllerProvider =
    StateNotifierProvider.autoDispose<AdminTeamController, AdminTeamState>((
  ref,
) {
  final controller = AdminTeamController(
    service: ref.watch(adminTeamServiceProvider),
  );
  controller.load();
  return controller;
});

final adminInventoryControllerProvider = StateNotifierProvider.autoDispose<
    AdminInventoryController, AdminInventoryState>((ref) {
  final controller = AdminInventoryController(
    service: ref.watch(adminInventoryServiceProvider),
  );
  controller.loadInitial();
  return controller;
});

final adminLogsControllerProvider =
    StateNotifierProvider.autoDispose<AdminLogsController, AdminLogsState>(
        (ref) {
  return AdminLogsController(service: ref.watch(adminLogsServiceProvider));
});

final adminPaymentsControllerProvider = StateNotifierProvider.autoDispose<
    AdminPaymentsController, AdminPaymentsState>((ref) {
  final controller = AdminPaymentsController(
    service: ref.watch(adminPaymentsServiceProvider),
  );
  controller.load();
  return controller;
});

final adminPlansControllerProvider =
    StateNotifierProvider.autoDispose<AdminPlansController, AdminPlansState>(
        (ref) {
  final controller = AdminPlansController(
    service: ref.watch(adminPlansServiceProvider),
  );
  controller.load();
  return controller;
});

final adminSettingsControllerProvider = StateNotifierProvider.autoDispose<
    AdminSettingsController, AdminSettingsState>((ref) {
  return AdminSettingsController(ref.watch(adminSettingsServiceProvider));
});

final adminSupportControllerProvider = StateNotifierProvider.autoDispose<
    AdminSupportController, AdminSupportState>((ref) {
  return AdminSupportController(ref.watch(adminSupportServiceProvider));
});

final adminTransactionsControllerProvider = StateNotifierProvider.autoDispose<
    AdminTransactionsController, AdminTransactionsState>((ref) {
  final controller = AdminTransactionsController(
    service: ref.watch(adminTransactionsServiceProvider),
  );
  controller.load();
  return controller;
});

final adminDriverDetailsControllerProvider = StateNotifierProvider.autoDispose
    .family<AdminDriverDetailsController, AdminDriverDetailsState, String>((
  ref,
  driverId,
) {
  return AdminDriverDetailsController(
    driverId: driverId,
    service: ref.watch(adminDriversServiceProvider),
  )..loadInitial();
});

final adminUserDetailsControllerProvider = StateNotifierProvider.autoDispose
    .family<AdminUserDetailsController, AdminUserDetailsState, String>((
  ref,
  userId,
) {
  return AdminUserDetailsController(
    userId: userId,
    service: ref.watch(adminUserDetailsServiceProvider),
  )..loadInitial();
});

final adminVehicleDetailsControllerProvider = StateNotifierProvider.autoDispose
    .family<AdminVehicleDetailsController, AdminVehicleDetailsState, String>((
  ref,
  vehicleId,
) {
  return AdminVehicleDetailsController(
    vehicleId: vehicleId,
    service: ref.watch(adminVehicleServiceProvider),
  )..loadInitial();
});

final adminNotificationCenterProvider = StateNotifierProvider.autoDispose<
    NotificationCenterController, NotificationCenterState>((ref) {
  final controller = NotificationCenterController(
    ref.watch(adminNotificationServiceProvider),
  );
  controller.load();
  return controller;
});

final adminNotificationUnreadBadgeProvider =
    FutureProvider.autoDispose<int>((ref) async {
  final cacheLink = ref.keepAlive();
  final cacheTimer = Timer(const Duration(seconds: 30), cacheLink.close);
  ref.onDispose(cacheTimer.cancel);

  try {
    final service = ref.watch(adminNotificationServiceProvider);
    return await service.getUnreadBadgeCountLightweight();
  } catch (_) {
    return 0;
  }
});
