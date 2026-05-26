import '../../core/router/route_paths.dart';

enum UserRole {
  superadmin,
  admin,
  user;

  static UserRole fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'superadmin':
      case 'super_admin':
        return UserRole.superadmin;
      case 'admin':
        return UserRole.admin;
      case 'user':
      default:
        return UserRole.user;
    }
  }

  String get apiValue {
    switch (this) {
      case UserRole.superadmin:
        return 'superadmin';
      case UserRole.admin:
        return 'admin';
      case UserRole.user:
        return 'user';
    }
  }

  String get homePath {
    switch (this) {
      case UserRole.superadmin:
        return RoutePaths.superadminHome;
      case UserRole.admin:
        return RoutePaths.adminHome;
      case UserRole.user:
        return RoutePaths.userHome;
    }
  }

  String get profilePath {
    switch (this) {
      case UserRole.superadmin:
        return RoutePaths.superadminProfile;
      case UserRole.admin:
        return RoutePaths.adminProfile;
      case UserRole.user:
        return RoutePaths.userProfile;
    }
  }

  String get settingsPath {
    switch (this) {
      case UserRole.superadmin:
        return RoutePaths.superadminSettings;
      case UserRole.admin:
        return RoutePaths.adminSettings;
      case UserRole.user:
        return RoutePaths.userSettings;
    }
  }

  String get displayLabel {
    switch (this) {
      case UserRole.superadmin:
        return 'Super Admin';
      case UserRole.admin:
        return 'Admin';
      case UserRole.user:
        return 'User';
    }
  }

  String get routePrefix {
    switch (this) {
      case UserRole.superadmin:
        return '/superadmin';
      case UserRole.admin:
        return '/admin';
      case UserRole.user:
        return '/user';
    }
  }
}
