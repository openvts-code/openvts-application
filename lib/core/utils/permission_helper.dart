import '../../shared/models/user_role.dart';

class PermissionHelper {
  const PermissionHelper._();

  static bool canAccessPath(UserRole role, String path) {
    return path.startsWith(role.routePrefix);
  }
}
