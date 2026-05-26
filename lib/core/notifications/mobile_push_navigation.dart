import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/admin/controllers/admin_providers.dart';
import '../../features/auth/controllers/auth_controller.dart';
import '../../features/superadmin/controllers/superadmin_providers.dart';
import '../../features/user/controllers/user_providers.dart';
import '../../shared/models/user_role.dart';
import '../providers/core_providers.dart';
import '../router/app_router.dart';
import '../router/route_paths.dart';
import 'mobile_push_message_mapper.dart';

class MobilePushNavigation {
  MobilePushNavigation(this._ref);

  static const _pendingTapPayloadKey = 'openvts_mobile_push_pending_tap';
  static MobilePushMessage? _pendingTapInMemory;

  final WidgetRef _ref;
  bool _isNavigating = false;

  Future<void> handleForegroundMessage(MobilePushMessage message) async {
    refreshActiveNotificationCenter();
  }

  Future<void> handleNotificationTap(MobilePushMessage message) async {
    final authState = _ref.read(authControllerProvider);
    if (!authState.isAuthenticated || authState.activeRole == null) {
      await storePendingTap(message);
      return;
    }

    await _navigateForMessage(message, authState.activeRole!);
  }

  Future<void> consumePendingNotificationTapIfPossible() async {
    final authState = _ref.read(authControllerProvider);
    if (!authState.isAuthenticated || authState.activeRole == null) {
      return;
    }

    final message = _readPendingTap();
    if (message == null) {
      await _clearPendingTap();
      return;
    }

    await _clearPendingTap();
    await _navigateForMessage(message, authState.activeRole!);
  }

  Future<void> storePendingTap(MobilePushMessage message) async {
    _pendingTapInMemory = message;
    await _ref.read(localCacheProvider).setString(
          _pendingTapPayloadKey,
          message.toLocalNotificationPayload(),
        );
  }

  void refreshActiveNotificationCenter() {
    final activeRole = _ref.read(authControllerProvider).activeRole;
    switch (activeRole) {
      case UserRole.superadmin:
        _ref.invalidate(superadminNotificationCenterProvider);
      case UserRole.admin:
        _ref.invalidate(adminNotificationCenterProvider);
      case UserRole.user:
        _ref.invalidate(userNotificationCenterProvider);
      case null:
        return;
    }
  }

  Future<void> _navigateForMessage(
    MobilePushMessage message,
    UserRole activeRole,
  ) async {
    if (_isNavigating) {
      await storePendingTap(message);
      return;
    }

    _isNavigating = true;
    try {
      final targetRoute = _resolveTargetRoute(message, activeRole);
      if (_isNotificationCenterRoute(targetRoute)) {
        refreshActiveNotificationCenter();
      }

      final isReady = await _waitForRouterReady();
      if (!isReady) {
        await storePendingTap(message);
        return;
      }

      final latestAuthState = _ref.read(authControllerProvider);
      if (!latestAuthState.isAuthenticated ||
          latestAuthState.activeRole != activeRole) {
        await storePendingTap(message);
        return;
      }

      _ref.read(appRouterProvider).go(targetRoute);

      if (_isNotificationCenterRoute(targetRoute)) {
        scheduleMicrotask(refreshActiveNotificationCenter);
      }
    } finally {
      _isNavigating = false;
    }
  }

  Future<bool> _waitForRouterReady() async {
    for (var attempt = 0; attempt < 8; attempt++) {
      await WidgetsBinding.instance.endOfFrame;
      if (appRootNavigatorKey.currentContext != null) {
        return true;
      }
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }

    return appRootNavigatorKey.currentContext != null;
  }

  MobilePushMessage? _readPendingTap() {
    final memoryValue = _pendingTapInMemory;
    if (memoryValue != null) {
      return memoryValue;
    }

    final payload = _ref.read(localCacheProvider).getString(
          _pendingTapPayloadKey,
        );
    return MobilePushMessageMapper.fromLocalNotificationPayload(payload);
  }

  Future<void> _clearPendingTap() async {
    _pendingTapInMemory = null;
    await _ref.read(localCacheProvider).remove(_pendingTapPayloadKey);
  }

  String _resolveTargetRoute(MobilePushMessage message, UserRole activeRole) {
    final explicitRoute = _normalizeRoute(message.route);
    if (explicitRoute != null && _isSafeKnownRoute(explicitRoute, activeRole)) {
      return explicitRoute;
    }

    final vehicleRoute = _vehicleRouteForRole(message.vehicleId, activeRole);
    if (vehicleRoute != null && _isSafeKnownRoute(vehicleRoute, activeRole)) {
      return vehicleRoute;
    }

    return _notificationCenterRouteForRole(activeRole);
  }

  String? _vehicleRouteForRole(String? vehicleId, UserRole activeRole) {
    final normalizedVehicleId = vehicleId?.trim();
    if (normalizedVehicleId == null || normalizedVehicleId.isEmpty) {
      return null;
    }

    switch (activeRole) {
      case UserRole.superadmin:
        return _withVehicleQuery(
          RoutePaths.superadminMap,
          normalizedVehicleId,
        );
      case UserRole.admin:
        return _withVehicleQuery(RoutePaths.adminMap, normalizedVehicleId);
      case UserRole.user:
        return '/user/vehicles/${Uri.encodeComponent(normalizedVehicleId)}';
    }
  }

  String _notificationCenterRouteForRole(UserRole activeRole) {
    switch (activeRole) {
      case UserRole.superadmin:
        return RoutePaths.superadminNotifications;
      case UserRole.admin:
        return RoutePaths.adminNotifications;
      case UserRole.user:
        return RoutePaths.userNotificationCenter;
    }
  }

  bool _isNotificationCenterRoute(String route) {
    final path = Uri.tryParse(route)?.path ?? route;
    return path == RoutePaths.superadminNotifications ||
        path == RoutePaths.adminNotifications ||
        path == RoutePaths.userNotificationCenter;
  }

  bool _isSafeKnownRoute(String route, UserRole activeRole) {
    final uri = Uri.tryParse(route);
    if (uri == null) {
      return false;
    }

    final path = _normalizePath(uri.path);
    if (path != activeRole.homePath &&
        !path.startsWith('${activeRole.routePrefix}/')) {
      return false;
    }

    return _knownStaticRoutesForRole(activeRole).contains(path) ||
        _isKnownDynamicRouteForRole(path, activeRole);
  }

  Set<String> _knownStaticRoutesForRole(UserRole activeRole) {
    switch (activeRole) {
      case UserRole.superadmin:
        return _superadminStaticRoutes;
      case UserRole.admin:
        return _adminStaticRoutes;
      case UserRole.user:
        return _userStaticRoutes;
    }
  }

  bool _isKnownDynamicRouteForRole(String path, UserRole activeRole) {
    switch (activeRole) {
      case UserRole.superadmin:
        return RegExp(r'^/superadmin/administrators/[^/]+$').hasMatch(path);
      case UserRole.admin:
        return RegExp(r'^/admin/users/[^/]+$').hasMatch(path);
      case UserRole.user:
        return RegExp(r'^/user/vehicles/[^/]+$').hasMatch(path) ||
            RegExp(r'^/user/accounts/drivers/[^/]+$').hasMatch(path) ||
            RegExp(r'^/user/accounts/sub-users/[^/]+$').hasMatch(path);
    }
  }
}

const _superadminStaticRoutes = <String>{
  RoutePaths.superadminHome,
  RoutePaths.superadminDashboard,
  RoutePaths.superadminMap,
  RoutePaths.superadminVehicles,
  RoutePaths.superadminAdministrators,
  RoutePaths.superadminCalendar,
  RoutePaths.superadminServer,
  RoutePaths.superadminSupport,
  RoutePaths.superadminPayments,
  RoutePaths.superadminDevices,
  RoutePaths.superadminNotifications,
  RoutePaths.superadminReports,
  RoutePaths.superadminProfile,
  RoutePaths.superadminSettings,
};

const _adminStaticRoutes = <String>{
  RoutePaths.adminHome,
  RoutePaths.adminDashboard,
  RoutePaths.adminMap,
  RoutePaths.adminUsers,
  RoutePaths.adminVehicles,
  RoutePaths.adminDrivers,
  RoutePaths.adminTeam,
  RoutePaths.adminInventory,
  RoutePaths.adminTransactions,
  RoutePaths.adminPayments,
  RoutePaths.adminSupport,
  RoutePaths.adminNotifications,
  RoutePaths.adminCalendar,
  RoutePaths.adminLogs,
  RoutePaths.adminPlans,
  RoutePaths.adminReports,
  RoutePaths.adminProfile,
  RoutePaths.adminSettings,
};

const _userStaticRoutes = <String>{
  RoutePaths.userHome,
  RoutePaths.userDashboard,
  RoutePaths.userMap,
  RoutePaths.userVehicles,
  RoutePaths.userHistory,
  RoutePaths.userLandmarksStudio,
  RoutePaths.userLandmarkGeofences,
  RoutePaths.userLandmarkPois,
  RoutePaths.userLandmarkRoutes,
  RoutePaths.userGeofenceEditor,
  RoutePaths.userPoiEditor,
  RoutePaths.userRouteEditor,
  RoutePaths.userTrackLinks,
  RoutePaths.userRouteOptimisation,
  RoutePaths.userSupport,
  RoutePaths.userTransactions,
  RoutePaths.userAccounts,
  RoutePaths.userDrivers,
  RoutePaths.userSubUsers,
  RoutePaths.userNotifications,
  RoutePaths.userNotificationCenter,
  RoutePaths.userProfile,
  RoutePaths.userSettings,
};

String? _normalizeRoute(String? route) {
  final trimmed = route?.trim();
  if (trimmed == null || trimmed.isEmpty) {
    return null;
  }

  final parsed = Uri.tryParse(trimmed);
  if (parsed == null) {
    return null;
  }

  Uri localUri;
  if (parsed.hasScheme) {
    final scheme = parsed.scheme.toLowerCase();
    final path = scheme == 'http' || scheme == 'https'
        ? parsed.path
        : parsed.host.isEmpty
            ? parsed.path
            : '/${parsed.host}${parsed.path}';
    localUri = Uri(path: path, query: parsed.query);
  } else {
    final normalized = trimmed.startsWith('/') ? trimmed : '/$trimmed';
    localUri = Uri.tryParse(normalized) ?? Uri(path: normalized);
  }

  final path = _normalizePath(localUri.path);
  if (path.isEmpty || path == '/') {
    return null;
  }

  return Uri(
    path: path,
    query: localUri.query.isEmpty ? null : localUri.query,
  ).toString();
}

String _normalizePath(String path) {
  final normalized = path.trim().replaceAll(RegExp(r'/+$'), '');
  if (normalized.isEmpty) {
    return '/';
  }
  return normalized.startsWith('/') ? normalized : '/$normalized';
}

String _withVehicleQuery(String path, String vehicleId) {
  return Uri(
    path: path,
    queryParameters: <String, String>{'vehicleId': vehicleId},
  ).toString();
}
