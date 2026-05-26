import 'mobile_push_platform.dart';

enum MobilePushTestStep {
  idle,
  initializingFirebase,
  checkingPermission,
  generatingToken,
  registeringToken,
  verifyingBackendToken,
  sendingBackendTest,
  completed,
  failed,
}

class MobilePushState {
  const MobilePushState({
    required this.isSupported,
    required this.isInitialized,
    required this.isInitializing,
    required this.isTesting,
    this.testStep = MobilePushTestStep.idle,
    required this.isPermissionGranted,
    required this.platform,
    this.permissionStatus,
    this.fcmTokenLast10,
    this.registeredTokenLast10,
    this.registeredTokenCount,
    this.currentTokenVerifiedByBackend,
    this.tokenDiagnosticsUpdatedAt,
    this.configVersion,
    this.lastError,
    this.pendingReinitializeOnNextLaunch = false,
  });

  final bool isSupported;
  final bool isInitialized;
  final bool isInitializing;
  final bool isTesting;
  final MobilePushTestStep testStep;
  final bool isPermissionGranted;
  final String? permissionStatus;
  final String? fcmTokenLast10;
  final String? registeredTokenLast10;
  final int? registeredTokenCount;
  final bool? currentTokenVerifiedByBackend;
  final DateTime? tokenDiagnosticsUpdatedAt;
  final MobilePushPlatform platform;
  final String? configVersion;
  final String? lastError;
  final bool pendingReinitializeOnNextLaunch;

  static const _unset = Object();

  factory MobilePushState.initial({
    required bool isSupported,
    required MobilePushPlatform platform,
    String? permissionStatus,
    String? fcmTokenLast10,
    String? registeredTokenLast10,
    String? configVersion,
    String? lastError,
  }) {
    return MobilePushState(
      isSupported: isSupported,
      isInitialized: false,
      isInitializing: false,
      isTesting: false,
      testStep: MobilePushTestStep.idle,
      isPermissionGranted: _isGrantedPermissionStatus(permissionStatus),
      permissionStatus: permissionStatus,
      fcmTokenLast10: fcmTokenLast10,
      registeredTokenLast10: registeredTokenLast10,
      platform: platform,
      configVersion: configVersion,
      lastError: lastError,
    );
  }

  MobilePushState copyWith({
    bool? isSupported,
    bool? isInitialized,
    bool? isInitializing,
    bool? isTesting,
    MobilePushTestStep? testStep,
    bool? isPermissionGranted,
    Object? permissionStatus = _unset,
    Object? fcmTokenLast10 = _unset,
    Object? registeredTokenLast10 = _unset,
    Object? registeredTokenCount = _unset,
    Object? currentTokenVerifiedByBackend = _unset,
    Object? tokenDiagnosticsUpdatedAt = _unset,
    MobilePushPlatform? platform,
    Object? configVersion = _unset,
    Object? lastError = _unset,
    bool? pendingReinitializeOnNextLaunch,
  }) {
    return MobilePushState(
      isSupported: isSupported ?? this.isSupported,
      isInitialized: isInitialized ?? this.isInitialized,
      isInitializing: isInitializing ?? this.isInitializing,
      isTesting: isTesting ?? this.isTesting,
      testStep: testStep ?? this.testStep,
      isPermissionGranted: isPermissionGranted ?? this.isPermissionGranted,
      permissionStatus: identical(permissionStatus, _unset)
          ? this.permissionStatus
          : permissionStatus as String?,
      fcmTokenLast10: identical(fcmTokenLast10, _unset)
          ? this.fcmTokenLast10
          : fcmTokenLast10 as String?,
      registeredTokenLast10: identical(registeredTokenLast10, _unset)
          ? this.registeredTokenLast10
          : registeredTokenLast10 as String?,
      registeredTokenCount: identical(registeredTokenCount, _unset)
          ? this.registeredTokenCount
          : registeredTokenCount as int?,
      currentTokenVerifiedByBackend:
          identical(currentTokenVerifiedByBackend, _unset)
            ? this.currentTokenVerifiedByBackend
            : currentTokenVerifiedByBackend as bool?,
      tokenDiagnosticsUpdatedAt: identical(tokenDiagnosticsUpdatedAt, _unset)
          ? this.tokenDiagnosticsUpdatedAt
          : tokenDiagnosticsUpdatedAt as DateTime?,
      platform: platform ?? this.platform,
      configVersion: identical(configVersion, _unset)
          ? this.configVersion
          : configVersion as String?,
        lastError:
          identical(lastError, _unset) ? this.lastError : lastError as String?,
        pendingReinitializeOnNextLaunch: pendingReinitializeOnNextLaunch ??
          this.pendingReinitializeOnNextLaunch,
    );
  }

  static bool _isGrantedPermissionStatus(String? status) {
    switch (status?.trim()) {
      case 'authorized':
      case 'provisional':
        return true;
      default:
        return false;
    }
  }
}
