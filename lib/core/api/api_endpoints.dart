class ApiEndpoints {
  const ApiEndpoints._();

  static const auth = _AuthEndpoints();
  static const public = _PublicEndpoints();
  static const superadmin = _SuperadminEndpoints();
  static const admin = _AdminEndpoints();
  static const user = _UserEndpoints();
}

class _AuthEndpoints {
  const _AuthEndpoints();

  String get login => '/auth/login';
  String get refreshToken => '/auth/refresh-token';
  String get forgotPassword => '/auth/forgot-password';
  String get resetPassword => '/auth/reset-password';
  String get logout => '/auth/logout';
  String get me => '/auth/me';
  String get fcmMobileConfig => '/auth/fcm-mobile-config';
  String get pushToken => '/auth/push-token';
  String get pushTokensMe => '/auth/push-tokens/me';
  String get pushTest => '/auth/push-test';
}

class _PublicEndpoints {
  const _PublicEndpoints();

  String get countries => '/countries';
  String get mobilePrefix => '/mobileprefix';
  String states(String countryCode) => '/states/$countryCode';
  String cities(String countryCode, String stateCode) =>
      '/cities/$countryCode/$stateCode';
  String get languages => '/languages';
  String get dateFormats => '/dateformats';
  String get vehicleTypes => '/vehicletypes';
  String get deviceTypes => '/devicestypes';
  String get simProviders => '/simproviders';
  String get currencies => '/currencies';
  String get timezones => '/timezones';
}

class _SuperadminEndpoints {
  const _SuperadminEndpoints();

  String get dashboard => '/superadmin/dashboard';
  String get dashboardOverview => '/superadmin/dashboard/overview';
  String get dashboardActivityLogs => '/superadmin/dashboard/activitylogs';
  String get serverOverview => '/superadmin/server/overview';
  String get serverActions => '/superadmin/server/actions';
  String serverJob(String id) => '/superadmin/server/jobs/$id';
  String serverJobStream(String id) => '/superadmin/server/jobs/$id/stream';
  String get adminList => '/superadmin/adminlist';
  String get transactions => '/superadmin/transactions';
  String get transactionsAnalytics => '/superadmin/transactions/analytics';
  String get recordManualTransaction => '/superadmin/transactions/manual';
  String get createAdmin => '/superadmin/createadmin';
  String activateAdmin(String id) => '/superadmin/activateadmin/$id';
  String deleteAdmin(String id) => '/superadmin/deleteadmin/$id';
  String adminLogin(String id) => '/superadmin/adminlogin/$id';
  String get mapVehicles => '/superadmin/map/vehicles';
  String get mapEvents => '/superadmin/map-events';
  String get mapTelemetry => '/superadmin/map-telemetry';
  String get geofences => '/superadmin/geofences';
  String get pois => '/superadmin/pois';
  String get routes => '/superadmin/routes';
  String get notifications => '/superadmin/notifications';
  String notificationRead(String id) => '/superadmin/notifications/$id/read';
  String get notificationsReadAll => '/superadmin/notifications/read-all';
  String get customCommands => '/superadmin/customcommands';
  String get systemVariables => '/superadmin/systemvariables';
  String sendDeviceCommandByImei(String imei) =>
      '/superadmin/devices/${Uri.encodeComponent(imei)}/send-command';
  String sendVehicleCommandByImei(String imei) =>
      '/superadmin/vehicles/by-imei/${Uri.encodeComponent(imei)}/send-command';
  String commandHistoryByImei(String imei) =>
      '/superadmin/vehicles/by-imei/${Uri.encodeComponent(imei)}/commands';
  String commandStatus(String cmdId) =>
      '/superadmin/commands/status/${Uri.encodeComponent(cmdId)}';
  String commandLog(String cmdId) =>
      '/superadmin/commands/${Uri.encodeComponent(cmdId)}';
  String get vehicles => '/superadmin/vehicles';
  String vehicleDetail(String id) => '/superadmin/vehicles/$id';
  String vehicleDetailsByImei(String imei) =>
      '/superadmin/vehicles/by-imei/$imei/details';
  String vehicleReplayByImei(String imei) =>
      '/superadmin/vehicles/by-imei/$imei/replay';
  String vehicleLogsByImei(String imei) =>
      '/superadmin/vehicles/by-imei/${Uri.encodeComponent(imei)}/logs';
  String vehicleEventsByImei(String imei) =>
      '/superadmin/vehicles/by-imei/${Uri.encodeComponent(imei)}/events';
  String vehicleSensorsByImei(String imei) =>
      '/superadmin/vehicles/by-imei/${Uri.encodeComponent(imei)}/sensors';
  String vehicleCommandsByImei(String imei) => commandHistoryByImei(imei);
  String sendDeviceCommand(String imei) => sendDeviceCommandByImei(imei);
  String commandStatusByCmdId(String cmdId) => commandStatus(cmdId);
  String commandByCmdId(String cmdId) => commandLog(cmdId);
  String vehicleHistoryByImei(String imei) =>
      '/superadmin/vehicles/by-imei/${Uri.encodeComponent(imei)}/history';
  String get administrators => '/superadmin/admins';
  String get devices => '/superadmin/devices';
  String get calendarEvents => '/superadmin/calendar/events';
  String get calendarDay => '/superadmin/calendar/day';
  String calendarUser(String uid) => '/superadmin/calendar/user/$uid';
  String get supportTickets => '/superadmin/support/tickets';
  String supportTicketById(String id) =>
      '/superadmin/support/tickets/${Uri.encodeComponent(id)}';
  String supportTicketMessages(String id) =>
      '/superadmin/support/tickets/${Uri.encodeComponent(id)}/messages';
  String supportTicketStatus(String id) =>
      '/superadmin/support/tickets/${Uri.encodeComponent(id)}/status';
  String get profile => '/superadmin/profile';
  String uploadProfile(String id) => '/superadmin/upload/$id';
  String get companyDetails => '/superadmin/companydetails';
  String get updatePassword => '/superadmin/updatepassword';
  String get profileVerifyEmailRequest =>
      '/superadmin/profile/verify/email/request';
  String get profileVerifyEmailConfirm =>
      '/superadmin/profile/verify/email/confirm';
  String get profileVerifyWhatsAppRequest =>
      '/superadmin/profile/verify/whatsapp/request';
  String get profileVerifyWhatsAppConfirm =>
      '/superadmin/profile/verify/whatsapp/confirm';
  String get profileEmailSubscription =>
      '/superadmin/profile/email-subscription';
  String get profileEmailSubscribe =>
      '/superadmin/profile/email-subscription/subscribe';
  String get whiteLabel => '/superadmin/whitelabel';
  String get smtpSettings => '/superadmin/smtpsettings';
  String get testSmtp => '/superadmin/testsmtp';
  String get localization => '/superadmin/localization';
  String get softwareConfig => '/superadmin/softwareconfig';
  String get dataRetentionPreview =>
      '/superadmin/settings/data-retention/preview';
  String get dataRetentionRun => '/superadmin/settings/data-retention/run';
  String get reports => '/superadmin/reports';
  String get settings => '/superadmin/settings';

  String adminDetail(String id) =>
      '/superadmin/admin/${Uri.encodeComponent(id)}';
  String updateAdmin(String id) =>
      '/superadmin/updateadmin/${Uri.encodeComponent(id)}';
  String assignCredits(String id) =>
      '/superadmin/assigncredits/${Uri.encodeComponent(id)}';
  String creditLogs(String id) =>
      '/superadmin/creditlogs/${Uri.encodeComponent(id)}';
  String get adminPasswordUpdate => '/superadmin/adminpasswordupdate';
  String companyConfig(String id) =>
      '/superadmin/companyconfig/${Uri.encodeComponent(id)}';
  String adminVehicles(String adminId) =>
      '/superadmin/adminvehicles/${Uri.encodeComponent(adminId)}';
  String documentsByAdmin(String adminId) =>
      '/superadmin/documents/${Uri.encodeComponent(adminId)}';
  String get documentTypes => '/superadmin/documenttypes';
  String get uploadDoc => '/superadmin/uploaddoc';
  String uploadDocById(String id) =>
      '/superadmin/uploaddoc/${Uri.encodeComponent(id)}';
  String adminActivityLogs(String adminId) =>
      '/superadmin/admin/${Uri.encodeComponent(adminId)}/activitylogs';
}

class _AdminEndpoints {
  const _AdminEndpoints();

  String get dashboard => '/admin/dashboard';
  String get dashboardSummary => '/admin/dashboard/summary';
  String get mapVehicles => '/admin/map/vehicles';
  String get notifications => '/admin/notifications';
  String notificationRead(String id) => '/admin/notifications/$id/read';
  String get notificationsReadAll => '/admin/notifications/read-all';
  String get calendarEvents => '/admin/calendar/events';
  String get calendarDay => '/admin/calendar/day';
  String calendarUser(String uid) => '/admin/calendar/user/$uid';
  String get vehicles => '/admin/vehicles';
  String vehicleById(String id) => '/admin/vehicles/${Uri.encodeComponent(id)}';
  String vehicleConfigUpdate(String id) =>
      '/admin/vehicles/${Uri.encodeComponent(id)}/config';
  String get quickDevice => '/admin/quickdevice';
  String linkUsersByVehicleId(String vehicleId) =>
      '/admin/linkusers/${Uri.encodeComponent(vehicleId)}';
  String unlinkUsersByVehicleId(String vehicleId) =>
      '/admin/unlinkusers/${Uri.encodeComponent(vehicleId)}';
  String vehicleLogsByImei(String imei) =>
      '/admin/vehicles/by-imei/${Uri.encodeComponent(imei)}/logs';
  String vehicleEventsByImei(String imei) =>
      '/admin/vehicles/by-imei/${Uri.encodeComponent(imei)}/events';
  String get customCommands => '/admin/customcommands';
  String get systemVariables => '/admin/systemvariables';
  String sendCommandByImei(String imei) =>
      '/admin/vehicles/by-imei/${Uri.encodeComponent(imei)}/send-command';
  String commandHistoryByImei(String imei) =>
      '/admin/vehicles/by-imei/${Uri.encodeComponent(imei)}/commands';
  String commandStatus(String cmdId) =>
      '/admin/commands/status/${Uri.encodeComponent(cmdId)}';
  String commandLog(String cmdId) =>
      '/admin/commands/${Uri.encodeComponent(cmdId)}';
  String vehicleSensors(String vehicleId) =>
      '/admin/vehicles/${Uri.encodeComponent(vehicleId)}/sensors';
  String vehicleSensorById({
    required String vehicleId,
    required String sensorId,
  }) =>
      '/admin/vehicles/${Uri.encodeComponent(vehicleId)}/sensors/${Uri.encodeComponent(sensorId)}';
  String vehicleSensorsRun(String id) =>
      '/admin/vehicles/${Uri.encodeComponent(id)}/sensors/run';
  String vehicleSensorsTelemetry(String id) =>
      '/admin/vehicles/${Uri.encodeComponent(id)}/sensors/telemetry';
  String documentsByVehicle(String vehicleId) =>
      '/admin/documents/vehicle/${Uri.encodeComponent(vehicleId)}';
  String get vehicleDocumentTypes => '/documenttypes/VEHICLE';
  String vehicleDetail(String id) => '/admin/vehicles/$id';
  String get users => '/admin/users';
  String userById(String id) => '/admin/users/${Uri.encodeComponent(id)}';
  String userLogin(String id) => '/admin/userlogin/${Uri.encodeComponent(id)}';
  String updateUserPassword(String id) =>
      '/admin/updateuserpassword/${Uri.encodeComponent(id)}';
  String companyDetailsByUserId(String id) =>
      '/admin/companydetails/${Uri.encodeComponent(id)}';
  String linkedVehiclesByUserId(String userId) =>
      '/admin/linkvehicles/${Uri.encodeComponent(userId)}';
  String unlinkedVehiclesByUserId(String userId) =>
      '/admin/unlinkvehicles/${Uri.encodeComponent(userId)}';
  String linkedDriversByUserId(String userId) =>
      '/admin/users/linkeddrivers/${Uri.encodeComponent(userId)}';
  String unlinkedDriversByUserId(String userId) =>
      '/admin/users/unlinkeddrivers/${Uri.encodeComponent(userId)}';
  String documentsByUser(String userId) =>
      '/admin/documents/${Uri.encodeComponent(userId)}';
  String get userDocumentTypes => '/documenttypes/USER';
  String get uploadDoc => '/admin/uploaddoc';
  String uploadDocById(String id) =>
      '/admin/uploaddoc/${Uri.encodeComponent(id)}';
  String get tickets => '/admin/tickets';
  String ticketById(String id) => '/admin/tickets/${Uri.encodeComponent(id)}';
  String ticketMessages(String id) =>
      '/admin/tickets/${Uri.encodeComponent(id)}/messages';
  String ticketStatus(String id) =>
      '/admin/tickets/${Uri.encodeComponent(id)}/status';
  String get myTickets => '/admin/mytickets';
  String myTicketById(String id) =>
      '/admin/mytickets/${Uri.encodeComponent(id)}';
  String myTicketMessages(String id) =>
      '/admin/mytickets/${Uri.encodeComponent(id)}/messages';
  String myTicketStatus(String id) =>
      '/admin/mytickets/${Uri.encodeComponent(id)}/status';
  String get adminPayments => '/admin/payments';
  String get transactionsAnalytics => '/admin/transactions/analytics';
  String get renewVehiclesPayment => '/admin/payments/renew';
  String userActivityLogs(String id) =>
      '/admin/users/${Uri.encodeComponent(id)}/activitylogs';
  String get drivers => '/admin/drivers';
  String driverById(String id) => '/admin/drivers/${Uri.encodeComponent(id)}';
  String documentsByDriver(String driverId) =>
      '/admin/documents/driver/${Uri.encodeComponent(driverId)}';
  String get driverDocumentTypes => '/documenttypes/DRIVER';
  String driverLinkedUsers(String driverId) =>
      '/admin/drivers/linkedusers/${Uri.encodeComponent(driverId)}';
  String driverUnlinkedUsers(String driverId) =>
      '/admin/drivers/unlinkedusers/${Uri.encodeComponent(driverId)}';
  String get teams => '/admin/teams';
  String get pricingPlans => '/admin/pricingplans';
  String pricingPlanById(String id) =>
      '/admin/pricingplans/${Uri.encodeComponent(id)}';
  String get transactions => '/admin/transactions';
  String get devices => '/admin/devices';
  String deviceById(String id) => '/admin/devices/${Uri.encodeComponent(id)}';
  String get simcards => '/admin/simcards';
  String simcardById(String id) => '/admin/simcards/${Uri.encodeComponent(id)}';
  String get deviceAndSim => '/admin/deviceandsim';
  String get quickSimcards => '/admin/quicksimcards';
  String get profile => '/admin/profile';
  String get uploadProfile => '/admin/upload';
  String get companyDetails => '/admin/companydetails';
  String get updatePassword => '/admin/updatepassword';
  String get smtpConfig => '/admin/smtpconfig';
  String get testSmtp => '/admin/testsmtp';
  String get localization => '/admin/localization';
  String get profileVerifyEmailRequest => '/admin/profile/verify/email/request';
  String get profileVerifyEmailConfirm => '/admin/profile/verify/email/confirm';
  String get profileVerifyWhatsAppRequest =>
      '/admin/profile/verify/whatsapp/request';
  String get profileVerifyWhatsAppConfirm =>
      '/admin/profile/verify/whatsapp/confirm';
  String get profileEmailSubscription => '/admin/profile/email-subscription';
  String get profileEmailSubscribe =>
      '/admin/profile/email-subscription/subscribe';
  String get reports => '/admin/reports';
  String get settings => '/admin/settings';
  String get logsOptions => '/admin/logs/options';
  String get logsActivity => '/admin/logs/activity';
  String get logsEvents => '/admin/logs/events';
  String logsEventById(String id) =>
      '/admin/logs/events/${Uri.encodeComponent(id)}';
  String get logsTelemetry => '/admin/logs/telemetry';
  String logsTelemetryById(String id) =>
      '/admin/logs/telemetry/${Uri.encodeComponent(id)}';
}

class _UserEndpoints {
  const _UserEndpoints();

  String get dashboards => '/user/dashboards';
  String dashboardById(String id) =>
      '/user/dashboards/${Uri.encodeComponent(id)}';
  String get dashboardFleetStatus => '/user/dashboard/fleet-status';
  String get dashboardUsageLast7Days => '/user/dashboard/usage-last-7-days';
  String get dashboardWeeklyComparison => '/user/dashboard/weekly-comparison';
  String get dashboardRecentAlerts => '/user/dashboard/recent-alerts';
  String dashboardRecentAlertById(String id) =>
      '/user/dashboard/recent-alerts/${Uri.encodeComponent(id)}';
  String dashboardRecentAlertRead(String id) =>
      '/user/dashboard/recent-alerts/${Uri.encodeComponent(id)}/read';
  String get dashboardTopPerformingAssets =>
      '/user/dashboard/top-performing-assets';
  String get dashboardDayNightComparison =>
      '/user/dashboard/day-night-comparison';
  String get mapVehicles => '/user/map/vehicles';
  String get vehicles => '/user/vehicles';
  String get transactions => '/user/transactions';
  String get tickets => '/user/tickets';
  String ticketById(String id) => '/user/tickets/${Uri.encodeComponent(id)}';
  String get shareTrackLinks => '/user/sharetracklinks';
  String shareTrackLinkById(String id) =>
      '/user/sharetracklinks/${Uri.encodeComponent(id)}';
  String vehicleById(String id) => '/user/vehicles/${Uri.encodeComponent(id)}';
  String vehicleUpdate(String id) =>
      '/user/vehicles/${Uri.encodeComponent(id)}';
  String vehicleConfigUpdate(String id) =>
      '/user/vehicles/${Uri.encodeComponent(id)}/config';
  String vehicleDocuments(String id) =>
      '/user/vehicles/${Uri.encodeComponent(id)}/documents';
  String vehicleDocumentById({
    required String vehicleId,
    required String docId,
  }) =>
      '/user/vehicles/${Uri.encodeComponent(vehicleId)}/documents/${Uri.encodeComponent(docId)}';
  String vehicleSensors(String vehicleId) =>
      '/user/vehicles/${Uri.encodeComponent(vehicleId)}/sensors';
  String vehicleSensorById({
    required String vehicleId,
    required String sensorId,
  }) =>
      '/user/vehicles/${Uri.encodeComponent(vehicleId)}/sensors/${Uri.encodeComponent(sensorId)}';
  String vehicleSensorsRun(String id) =>
      '/user/vehicles/${Uri.encodeComponent(id)}/sensors/run';
  String vehicleSensorsTelemetry(String id) =>
      '/user/vehicles/${Uri.encodeComponent(id)}/sensors/telemetry';
  String vehicleSensorHistory({
    required String vehicleId,
    required String sensorId,
  }) =>
      '/user/vehicles/${Uri.encodeComponent(vehicleId)}/sensors/${Uri.encodeComponent(sensorId)}/history';
  String vehicleTelemetry(String id) =>
      '/user/vehicles/${Uri.encodeComponent(id)}/telemetry';
  String get vehicleDocumentTypes => '/documenttypes/VEHICLE';
  String get driverDocumentTypes => '/documenttypes/DRIVER';
  String get drivers => '/user/drivers';
  String driverById(String id) => '/user/drivers/${Uri.encodeComponent(id)}';
  String driverAssignVehicle(String id) =>
      '/user/drivers/${Uri.encodeComponent(id)}/assign-vehicle';
  String driverUnassignVehicle(String id) =>
      '/user/drivers/${Uri.encodeComponent(id)}/unassign-vehicle';
  String driverLogs(String id) =>
      '/user/drivers/${Uri.encodeComponent(id)}/logs';
  String driverDocuments(String id) =>
      '/user/drivers/${Uri.encodeComponent(id)}/documents';
  String driverDocumentById(
          {required String driverId, required String docId}) =>
      '/user/drivers/${Uri.encodeComponent(driverId)}/documents/${Uri.encodeComponent(docId)}';
  String get subusers => '/user/subusers';
  String subuserById(String id) => '/user/subusers/${Uri.encodeComponent(id)}';
  String subuserVehicles(String id) =>
      '/user/subusers/${Uri.encodeComponent(id)}/vehicles';
  String assignSubuserVehicles(String id) =>
      '/user/subusers/${Uri.encodeComponent(id)}/vehicles/assign';
  String unassignSubuserVehicles(String id) =>
      '/user/subusers/${Uri.encodeComponent(id)}/vehicles/unassign';
  String vehicleDetail(String id) => '/user/vehicles/$id';
  String get history => '/user/history';
  String get notificationPreferences => '/user/notifications/preferences';
  String get testFcmMe => '/user/notifications/test-fcm-me';
  String get notifications => '/user/notifications';
  String notificationRead(String id) => '/user/notifications/$id/read';
  String get notificationsReadAll => '/user/notifications/read-all';
  String get customCommands => '/user/customcommands';
  String get systemVariables => '/user/systemvariables';
  String get sendCommandBulk => '/user/commands/send-bulk';
  String get profile => '/user/profile';
  String get uploadProfile => '/user/upload';
  String get companyDetails => '/user/companydetails';
  String get updatePassword => '/user/updatepassword';
  String get profileVerifyEmailRequest => '/user/profile/verify/email/request';
  String get profileVerifyEmailConfirm => '/user/profile/verify/email/confirm';
  String get profileVerifyWhatsAppRequest =>
      '/user/profile/verify/whatsapp/request';
  String get profileVerifyWhatsAppConfirm =>
      '/user/profile/verify/whatsapp/confirm';
  String get profileEmailSubscription => '/user/profile/email-subscription';
  String get profileEmailSubscribe =>
      '/user/profile/email-subscription/subscribe';
  String get localization => '/user/localization';
  String get settings => '/user/settings';

  String get geofences => '/user/geofences';
  String geofenceById(String id) =>
      '/user/geofences/${Uri.encodeComponent(id)}';

  String get pois => '/user/pois';
  String poiById(String id) => '/user/pois/${Uri.encodeComponent(id)}';

  String get routes => '/user/routes';
  String routeById(String id) => '/user/routes/${Uri.encodeComponent(id)}';

  String get landmarkBulkJobs => '/user/landmarkbulkjobs';
  String landmarkBulkJobById(String id) =>
      '/user/landmarkbulkjobs/${Uri.encodeComponent(id)}';
  String landmarkBulkJobStream(String id) =>
      '/user/landmarkbulkjobs/${Uri.encodeComponent(id)}/stream';
  String landmarkBulkJobFailedCsv(String id) =>
      '/user/landmarkbulkjobs/${Uri.encodeComponent(id)}/failed.csv';
}
