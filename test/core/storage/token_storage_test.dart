import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:open_vts/core/storage/storage_keys.dart';
import 'package:open_vts/core/storage/token_storage.dart';
import 'package:open_vts/features/auth/models/current_user.dart';
import 'package:open_vts/shared/models/user_role.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FlutterSecureStorage secureStorage;
  late TokenStorage tokenStorage;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
    secureStorage = const FlutterSecureStorage();
    tokenStorage = TokenStorage(secureStorage);
  });

  Future<void> saveSession(UserRole role) {
    final user = _userForRole(role);
    return tokenStorage.saveSessionForRole(
      role: role,
      accessToken: 'access-${role.apiValue}',
      refreshToken: 'refresh-${role.apiValue}',
      currentUserJson: jsonEncode(user.toJson()),
    );
  }

  test('resolves active role by priority user > admin > superadmin', () async {
    await saveSession(UserRole.superadmin);
    await saveSession(UserRole.admin);

    expect(await tokenStorage.getActiveRoleByPriority(), UserRole.admin);

    await saveSession(UserRole.user);

    expect(await tokenStorage.getActiveRoleByPriority(), UserRole.user);

    final activeSession = await tokenStorage.getActiveSession();
    expect(activeSession, isNotNull);
    expect(activeSession?.role, UserRole.user);
    expect(activeSession?.accessToken, 'access-user');
  });

  test('clears only the selected role session and falls back by priority',
      () async {
    await saveSession(UserRole.superadmin);
    await saveSession(UserRole.admin);

    expect(await tokenStorage.getActiveRoleByPriority(), UserRole.admin);

    await tokenStorage.clearSessionForRole(UserRole.admin);

    final fallbackSession = await tokenStorage.getActiveSession();
    expect(fallbackSession, isNotNull);
    expect(fallbackSession?.role, UserRole.superadmin);

    await tokenStorage.clearSessionForRole(UserRole.superadmin);
    expect(await tokenStorage.getActiveSession(), isNull);
  });

  test('migrates legacy global session when scoped sessions do not exist',
      () async {
    final legacyUser = _userForRole(UserRole.superadmin);

    FlutterSecureStorage.setMockInitialValues(<String, String>{
      StorageKeys.accessToken: 'legacy-access',
      StorageKeys.refreshToken: 'legacy-refresh',
      StorageKeys.userRole: 'superadmin',
      StorageKeys.currentUser: jsonEncode(legacyUser.toJson()),
    });

    secureStorage = const FlutterSecureStorage();
    tokenStorage = TokenStorage(secureStorage);

    final migrated = await tokenStorage.getActiveSession();
    expect(migrated, isNotNull);
    expect(migrated?.role, UserRole.superadmin);
    expect(migrated?.accessToken, 'legacy-access');
    expect(migrated?.refreshToken, 'legacy-refresh');

    expect(
      await secureStorage.read(
        key: StorageKeys.accessTokenForRole(UserRole.superadmin.apiValue),
      ),
      'legacy-access',
    );
    expect(await secureStorage.read(key: StorageKeys.accessToken), isNull);
    expect(await secureStorage.read(key: StorageKeys.refreshToken), isNull);
    expect(await secureStorage.read(key: StorageKeys.userRole), isNull);
    expect(await secureStorage.read(key: StorageKeys.currentUser), isNull);
  });

  test('does not migrate legacy session when scoped session already exists',
      () async {
    final adminUser = _userForRole(UserRole.admin);

    FlutterSecureStorage.setMockInitialValues(<String, String>{
      StorageKeys.accessTokenForRole(UserRole.admin.apiValue): 'admin-access',
      StorageKeys.refreshTokenForRole(UserRole.admin.apiValue): 'admin-refresh',
      StorageKeys.currentUserForRole(UserRole.admin.apiValue):
          jsonEncode(adminUser.toJson()),
      StorageKeys.accessToken: 'legacy-access',
      StorageKeys.userRole: 'superadmin',
    });

    secureStorage = const FlutterSecureStorage();
    tokenStorage = TokenStorage(secureStorage);

    final activeSession = await tokenStorage.getActiveSession();
    expect(activeSession, isNotNull);
    expect(activeSession?.role, UserRole.admin);
    expect(activeSession?.accessToken, 'admin-access');

    expect(
      await secureStorage.read(
        key: StorageKeys.accessTokenForRole(UserRole.superadmin.apiValue),
      ),
      isNull,
    );
  });

  test('clearAllSessions removes scoped and legacy keys', () async {
    await saveSession(UserRole.user);

    await secureStorage.write(key: StorageKeys.accessToken, value: 'legacy');
    await secureStorage.write(key: StorageKeys.refreshToken, value: 'legacy-r');
    await secureStorage.write(key: StorageKeys.userRole, value: 'admin');
    await secureStorage.write(key: StorageKeys.currentUser, value: '{}');

    await tokenStorage.clearAllSessions();

    expect(
      await secureStorage.read(
        key: StorageKeys.accessTokenForRole(UserRole.user.apiValue),
      ),
      isNull,
    );
    expect(
      await secureStorage.read(
        key: StorageKeys.refreshTokenForRole(UserRole.user.apiValue),
      ),
      isNull,
    );
    expect(
      await secureStorage.read(
        key: StorageKeys.currentUserForRole(UserRole.user.apiValue),
      ),
      isNull,
    );
    expect(await secureStorage.read(key: StorageKeys.activeRole), isNull);
    expect(await secureStorage.read(key: StorageKeys.accessToken), isNull);
    expect(await secureStorage.read(key: StorageKeys.refreshToken), isNull);
    expect(await secureStorage.read(key: StorageKeys.userRole), isNull);
    expect(await secureStorage.read(key: StorageKeys.currentUser), isNull);
  });
}

CurrentUser _userForRole(UserRole role) {
  return CurrentUser(
    id: '${role.apiValue}-id',
    name: '${role.apiValue}-name',
    email: '${role.apiValue}@openvts.local',
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
