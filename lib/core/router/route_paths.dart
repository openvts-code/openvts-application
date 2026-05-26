class RoutePaths {
  const RoutePaths._();

  static const splash = '/splash';
  static const login = '/login';
  static const forgotPassword = '/forgot-password';
  static const apiBaseUrlSettings = '/login/api-base-url';

  static const superadminHome = '/superadmin';
  static const superadminDashboard = '/superadmin/dashboard';
  static const superadminMap = '/superadmin/map';
  static const superadminVehicles = '/superadmin/vehicles';
  static const superadminAdministrators = '/superadmin/administrators';
  static const superadminAdministratorCreate = '/superadmin/create-admin';
  static const superadminAdministratorDetails =
      '/superadmin/administrators/:adminId';

  static String superadminAdministratorDetailsPath(String adminId) =>
      '/superadmin/administrators/$adminId';
  static const superadminCalendar = '/superadmin/calendar';
  static const superadminServer = '/superadmin/server';
  static const superadminSupport = '/superadmin/support';
  static const superadminSupportCreate = '/superadmin/support/create';
  static const superadminPayments = '/superadmin/payments';
  static const superadminDevices = '/superadmin/devices';
  static const superadminNotifications = '/superadmin/notifications';
  static const superadminReports = '/superadmin/reports';
  static const superadminProfile = '/superadmin/profile';
  static const superadminSettings = '/superadmin/settings';

  static const adminHome = '/admin';
  static const adminDashboard = '/admin/dashboard';
  static const adminMap = '/admin/map';
  static const adminUsers = '/admin/users';
  static const adminUserCreate = '/admin/create-user';
  static const adminUserDetails = '/admin/users/:userId';

  static String adminUserDetailsPath(String userId) => '/admin/users/$userId';
  static const adminVehicleCreate = '/admin/create-vehicle';
  static const adminVehicleDetails = '/admin/vehicles/:vehicleId';

  static String adminVehicleDetailsPath(String vehicleId) =>
      '/admin/vehicles/$vehicleId';
  static const adminVehicles = '/admin/vehicles';
  static const adminDrivers = '/admin/drivers';
  static const adminDriverDetails = '/admin/drivers/:driverId';

  static String adminDriverDetailsPath(String driverId) =>
      '/admin/drivers/$driverId';
  static const adminTeam = '/admin/team';
  static const adminInventory = '/admin/inventory';
  static const adminTransactions = '/admin/transactions';
  static const adminPayments = '/admin/payments';
  static const adminSupport = '/admin/support';
  static const adminSupportCreate = '/admin/support/create';
  static const adminNotifications = '/admin/notifications';
  static const adminCalendar = '/admin/calendar';
  static const adminLogs = '/admin/logs';
  static const adminPlans = '/admin/plans';
  static const adminReports = '/admin/reports';
  static const adminProfile = '/admin/profile';
  static const adminSettings = '/admin/settings';

  static const userHome = '/user';
  static const userDashboard = '/user/dashboard';
  static const userMap = '/user/map';
  static const userVehicles = '/user/vehicles';
  static const userVehicleDetails = '/user/vehicles/:vehicleId';

  static String userVehicleDetailsPath(String vehicleId) =>
      '/user/vehicles/$vehicleId';

  static const userHistory = '/user/history';
  static const userLandmarksStudio = '/user/landmarks-studio';
  static const userLandmarkGeofences = '/user/landmarks-studio/geofences';
  static const userLandmarkPois = '/user/landmarks-studio/pois';
  static const userLandmarkRoutes = '/user/landmarks-studio/routes';

  static String userLandmarksStudioPath() => userLandmarksStudio;
  static String userLandmarkGeofencesPath() => userLandmarkGeofences;
  static String userLandmarkPoisPath() => userLandmarkPois;
  static String userLandmarkRoutesPath() => userLandmarkRoutes;

  static const userGeofenceEditor = '/user/landmarks-studio/geofences/editor';
  static const userPoiEditor = '/user/landmarks-studio/pois/editor';
  static const userRouteEditor = '/user/landmarks-studio/routes/editor';
  static const userTrackLinks = '/user/track-links';
  static const userRouteOptimisation = '/user/route-optimisation';
  static const userSupport = '/user/support';
  static const userSupportCreate = '/user/support/create';
  static const userTransactions = '/user/transactions';
  static const userAccounts = '/user/accounts';
  static const userDrivers = '/user/accounts/drivers';
  static const userDriverDetails = '/user/accounts/drivers/:driverId';

  static String userDriverDetailsPath(String driverId) =>
      '/user/accounts/drivers/$driverId';

  static const userSubUsers = '/user/accounts/sub-users';
  static const userSubUserDetails = '/user/accounts/sub-users/:subUserId';

  static String userSubUserDetailsPath(String subUserId) =>
      '/user/accounts/sub-users/$subUserId';
  static const userNotifications = '/user/notifications';
  static const userNotificationCenter = '/user/notifications/center';
  static const userProfile = '/user/profile';
  static const userSettings = '/user/settings';
}
