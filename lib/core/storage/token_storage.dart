import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../features/auth/models/current_user.dart';
import '../../shared/models/user_role.dart';
import 'storage_keys.dart';

class RoleSession {
  const RoleSession({
    required this.role,
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  final UserRole role;
  final String accessToken;
  final String refreshToken;
  final CurrentUser user;
}

class TokenStorage {
  TokenStorage(this._storage);

  static const List<UserRole> _rolePriority = <UserRole>[
    UserRole.user,
    UserRole.admin,
    UserRole.superadmin,
  ];

  final FlutterSecureStorage _storage;
  bool _didCheckLegacyMigration = false;

  Future<void> saveSessionForRole({
    required UserRole role,
    required String accessToken,
    required String refreshToken,
    required String currentUserJson,
  }) async {
    await _storage.write(
      key: StorageKeys.accessTokenForRole(role.apiValue),
      value: accessToken.trim(),
    );
    await _storage.write(
      key: StorageKeys.refreshTokenForRole(role.apiValue),
      value: refreshToken.trim(),
    );
    await _storage.write(
      key: StorageKeys.currentUserForRole(role.apiValue),
      value: _normalizedCurrentUserJson(currentUserJson, role),
    );
    await _storage.write(key: StorageKeys.activeRole, value: role.apiValue);
  }

  Future<String?> getAccessTokenForRole(UserRole role) async {
    await _migrateLegacySessionIfNeeded();
    return _readNonEmpty(StorageKeys.accessTokenForRole(role.apiValue));
  }

  Future<String?> getRefreshTokenForRole(UserRole role) async {
    await _migrateLegacySessionIfNeeded();
    return _readNonEmpty(StorageKeys.refreshTokenForRole(role.apiValue));
  }

  Future<String?> getCurrentUserJsonForRole(UserRole role) async {
    await _migrateLegacySessionIfNeeded();
    return _readNonEmpty(StorageKeys.currentUserForRole(role.apiValue));
  }

  Future<void> clearSessionForRole(UserRole role) async {
    await _storage.delete(key: StorageKeys.accessTokenForRole(role.apiValue));
    await _storage.delete(key: StorageKeys.refreshTokenForRole(role.apiValue));
    await _storage.delete(key: StorageKeys.currentUserForRole(role.apiValue));
    await _syncActiveRoleKey();
  }

  Future<void> clearAllSessions() async {
    for (final role in UserRole.values) {
      await _storage.delete(key: StorageKeys.accessTokenForRole(role.apiValue));
      await _storage.delete(
          key: StorageKeys.refreshTokenForRole(role.apiValue));
      await _storage.delete(key: StorageKeys.currentUserForRole(role.apiValue));
    }
    await _storage.delete(key: StorageKeys.activeRole);
    await _deleteLegacyKeys();
  }

  Future<UserRole?> getActiveRoleByPriority() async {
    await _migrateLegacySessionIfNeeded();

    for (final role in _rolePriority) {
      if (await _hasSessionForRoleRaw(role)) {
        await _storage.write(key: StorageKeys.activeRole, value: role.apiValue);
        return role;
      }
    }

    await _storage.delete(key: StorageKeys.activeRole);
    return null;
  }

  Future<RoleSession?> getActiveSession() async {
    final role = await getActiveRoleByPriority();
    if (role == null) {
      return null;
    }

    return _readRoleSession(role);
  }

  Future<bool> hasSessionForRole(UserRole role) async {
    await _migrateLegacySessionIfNeeded();
    return _hasSessionForRoleRaw(role);
  }

  Future<String?> getActiveAccessToken() async {
    final activeRole = await getActiveRoleByPriority();
    if (activeRole == null) {
      return null;
    }

    return _readNonEmpty(StorageKeys.accessTokenForRole(activeRole.apiValue));
  }

  Future<void> migrateLegacySessionIfNeeded() {
    return _migrateLegacySessionIfNeeded();
  }

  @Deprecated('Use saveSessionForRole instead.')
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    final activeRole = await getActiveRoleByPriority() ?? UserRole.user;
    final currentUserJson = await getCurrentUserJsonForRole(activeRole) ??
        _fallbackUserJson(activeRole);
    await saveSessionForRole(
      role: activeRole,
      accessToken: accessToken,
      refreshToken: refreshToken,
      currentUserJson: currentUserJson,
    );
  }

  @Deprecated('Use getAccessTokenForRole or getActiveAccessToken instead.')
  Future<String?> getAccessToken() {
    return getActiveAccessToken();
  }

  @Deprecated('Use getRefreshTokenForRole instead.')
  Future<String?> getRefreshToken() {
    return _getRefreshTokenForRoleRawByPriority();
  }

  @Deprecated('Use role-scoped session methods instead.')
  Future<void> saveRole(String role) {
    return _storage.write(key: StorageKeys.activeRole, value: role);
  }

  @Deprecated('Use getActiveRoleByPriority instead.')
  Future<String?> getRole() {
    return _storage.read(key: StorageKeys.activeRole);
  }

  @Deprecated('Use saveSessionForRole instead.')
  Future<void> saveCurrentUserJson(String value) {
    return _saveCurrentUserForActiveRole(value);
  }

  @Deprecated('Use getCurrentUserJsonForRole instead.')
  Future<String?> getCurrentUserJson() {
    return _getCurrentUserForActiveRoleByPriority();
  }

  @Deprecated('Use clearSessionForRole or clearAllSessions instead.')
  Future<void> clear() async {
    await clearAllSessions();
  }

  Future<void> _migrateLegacySessionIfNeeded() async {
    if (_didCheckLegacyMigration) {
      return;
    }

    _didCheckLegacyMigration = true;

    if (await _hasAnyRoleSessionRaw()) {
      await _syncActiveRoleKey();
      return;
    }

    final legacyAccessToken = await _readNonEmpty(StorageKeys.accessToken);
    final legacyRoleValue = await _readNonEmpty(StorageKeys.userRole);

    if (legacyAccessToken == null || legacyRoleValue == null) {
      return;
    }

    final role = UserRole.fromString(legacyRoleValue);
    final legacyRefreshToken =
        (await _storage.read(key: StorageKeys.refreshToken))?.trim() ?? '';
    final legacyCurrentUserJson =
        await _storage.read(key: StorageKeys.currentUser);

    await saveSessionForRole(
      role: role,
      accessToken: legacyAccessToken,
      refreshToken: legacyRefreshToken,
      currentUserJson:
          _normalizedCurrentUserJson(legacyCurrentUserJson ?? '', role),
    );

    await _deleteLegacyKeys();
    await _syncActiveRoleKey();
  }

  Future<RoleSession?> _readRoleSession(UserRole role) async {
    final accessToken =
        await _readNonEmpty(StorageKeys.accessTokenForRole(role.apiValue));
    if (accessToken == null) {
      return null;
    }

    final refreshToken = (await _storage.read(
                key: StorageKeys.refreshTokenForRole(role.apiValue)))
            ?.trim() ??
        '';
    final currentUserJson =
        await _storage.read(key: StorageKeys.currentUserForRole(role.apiValue));

    return RoleSession(
      role: role,
      accessToken: accessToken,
      refreshToken: refreshToken,
      user: _parseStoredUser(currentUserJson, role),
    );
  }

  CurrentUser _parseStoredUser(String? currentUserJson, UserRole role) {
    final normalizedJson = currentUserJson?.trim();
    if (normalizedJson != null && normalizedJson.isNotEmpty) {
      try {
        final decoded = jsonDecode(normalizedJson);
        if (decoded is Map<String, dynamic>) {
          return CurrentUser.fromJson(decoded).copyWith(role: role);
        }
      } catch (_) {
        // Ignore malformed json and fallback to a generated user.
      }
    }

    return _fallbackUser(role);
  }

  Future<bool> _hasAnyRoleSessionRaw() async {
    for (final role in UserRole.values) {
      if (await _hasSessionForRoleRaw(role)) {
        return true;
      }
    }

    return false;
  }

  Future<bool> _hasSessionForRoleRaw(UserRole role) async {
    final token =
        await _readNonEmpty(StorageKeys.accessTokenForRole(role.apiValue));
    return token != null;
  }

  Future<void> _syncActiveRoleKey() async {
    for (final role in _rolePriority) {
      if (await _hasSessionForRoleRaw(role)) {
        await _storage.write(key: StorageKeys.activeRole, value: role.apiValue);
        return;
      }
    }

    await _storage.delete(key: StorageKeys.activeRole);
  }

  Future<String?> _readNonEmpty(String key) async {
    final raw = await _storage.read(key: key);
    final normalized = raw?.trim();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }

    return normalized;
  }

  String _normalizedCurrentUserJson(String rawJson, UserRole role) {
    final normalized = rawJson.trim();
    if (normalized.isEmpty) {
      return _fallbackUserJson(role);
    }

    try {
      final decoded = jsonDecode(normalized);
      if (decoded is Map<String, dynamic>) {
        final normalizedUser =
            CurrentUser.fromJson(decoded).copyWith(role: role);
        return jsonEncode(normalizedUser.toJson());
      }
    } catch (_) {
      return _fallbackUserJson(role);
    }

    return _fallbackUserJson(role);
  }

  String _fallbackUserJson(UserRole role) {
    return jsonEncode(_fallbackUser(role).toJson());
  }

  CurrentUser _fallbackUser(UserRole role) {
    return CurrentUser(
      id: 'restored',
      name: role == UserRole.superadmin
          ? 'Super Admin'
          : role == UserRole.admin
              ? 'Admin'
              : 'User',
      email: '',
      role: role,
      username: role.apiValue,
      mobilePrefix: '+1',
      mobileNumber: '5559876543',
      phoneNumber: '+1 5559876543',
      accountStatus: 'active',
      isVerified: true,
      addressLine: '221 Fleet Street',
      countryCode: 'US',
      stateCode: 'CA',
      cityName: 'San Francisco',
      pincode: '94107',
    );
  }

  Future<void> _deleteLegacyKeys() async {
    await _storage.delete(key: StorageKeys.accessToken);
    await _storage.delete(key: StorageKeys.refreshToken);
    await _storage.delete(key: StorageKeys.userRole);
    await _storage.delete(key: StorageKeys.currentUser);
  }

  Future<void> _saveCurrentUserForActiveRole(String value) async {
    final activeRole = await getActiveRoleByPriority();
    if (activeRole == null) {
      return;
    }

    final accessToken = await _readNonEmpty(
      StorageKeys.accessTokenForRole(activeRole.apiValue),
    );
    if (accessToken == null) {
      return;
    }

    final refreshToken = (await _storage.read(
                key: StorageKeys.refreshTokenForRole(activeRole.apiValue)))
            ?.trim() ??
        '';
    await saveSessionForRole(
      role: activeRole,
      accessToken: accessToken,
      refreshToken: refreshToken,
      currentUserJson: value,
    );
  }

  Future<String?> _getCurrentUserForActiveRoleByPriority() async {
    final role = await getActiveRoleByPriority();
    if (role == null) {
      return null;
    }

    return _storage.read(key: StorageKeys.currentUserForRole(role.apiValue));
  }

  Future<String?> _getRefreshTokenForRoleRawByPriority() async {
    final role = await getActiveRoleByPriority();
    if (role == null) {
      return null;
    }

    return _storage.read(key: StorageKeys.refreshTokenForRole(role.apiValue));
  }
}
