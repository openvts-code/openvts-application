import 'admin_logs_model.dart';

class AdminLogsState {
  const AdminLogsState({
    required this.selectedTab,
    required this.options,
    required this.isLoadingOptions,
    required this.errorMessage,
    required this.activityLogs,
    required this.activityNextCursorId,
    required this.activityHasMore,
    required this.isLoadingActivity,
    required this.isLoadingMoreActivity,
    required this.activityUserId,
    required this.activityActionPrefix,
    required this.activityEntity,
    required this.activitySearch,
    required this.activityFrom,
    required this.activityTo,
    required this.vehicleLogs,
    required this.vehicleNextCursorId,
    required this.isLoadingVehicle,
    required this.isLoadingMoreVehicle,
    required this.vehicleVehicleId,
    required this.vehicleUserId,
    required this.vehicleSource,
    required this.vehicleSeverity,
    required this.vehicleReadFilter,
    required this.vehicleSearch,
    required this.vehicleFrom,
    required this.vehicleTo,
    required this.vehicleDedupe,
    required this.telemetryLogs,
    required this.telemetryNextCursor,
    required this.isLoadingTelemetry,
    required this.isLoadingMoreTelemetry,
    required this.telemetryVehicleId,
    required this.telemetryPacketType,
    required this.telemetryImeiSearch,
    required this.telemetryFrom,
    required this.telemetryTo,
    required this.sectionErrorMessage,
  });

  const AdminLogsState.initial()
      : selectedTab = AdminLogsTab.activity,
        options = const AdminLogsOptions(
          users: <AdminLogsUserOption>[],
          vehicles: <AdminLogsVehicleOption>[],
          sources: <String>[],
          packetTypes: <String>[],
        ),
        isLoadingOptions = false,
        errorMessage = null,
        activityLogs = const <AdminActivityLogItem>[],
        activityNextCursorId = null,
        activityHasMore = false,
        isLoadingActivity = true,
        isLoadingMoreActivity = false,
        activityUserId = null,
        activityActionPrefix = '',
        activityEntity = '',
        activitySearch = '',
        activityFrom = null,
        activityTo = null,
        vehicleLogs = const <AdminVehicleEventLogItem>[],
        vehicleNextCursorId = null,
        isLoadingVehicle = false,
        isLoadingMoreVehicle = false,
        vehicleVehicleId = null,
        vehicleUserId = null,
        vehicleSource = '',
        vehicleSeverity = '',
        vehicleReadFilter = AdminReadFilter.all,
        vehicleSearch = '',
        vehicleFrom = null,
        vehicleTo = null,
        vehicleDedupe = true,
        telemetryLogs = const <AdminTelemetryLogItem>[],
        telemetryNextCursor = null,
        isLoadingTelemetry = false,
        isLoadingMoreTelemetry = false,
        telemetryVehicleId = null,
        telemetryPacketType = '',
        telemetryImeiSearch = '',
        telemetryFrom = null,
        telemetryTo = null,
        sectionErrorMessage = null;

  static const Object _unset = Object();

  final AdminLogsTab selectedTab;
  final AdminLogsOptions options;
  final bool isLoadingOptions;
  final String? errorMessage;

  final List<AdminActivityLogItem> activityLogs;
  final String? activityNextCursorId;
  final bool activityHasMore;
  final bool isLoadingActivity;
  final bool isLoadingMoreActivity;
  final String? activityUserId;
  final String activityActionPrefix;
  final String activityEntity;
  final String activitySearch;
  final DateTime? activityFrom;
  final DateTime? activityTo;

  final List<AdminVehicleEventLogItem> vehicleLogs;
  final String? vehicleNextCursorId;
  final bool isLoadingVehicle;
  final bool isLoadingMoreVehicle;
  final String? vehicleVehicleId;
  final String? vehicleUserId;
  final String vehicleSource;
  final String vehicleSeverity;
  final AdminReadFilter vehicleReadFilter;
  final String vehicleSearch;
  final DateTime? vehicleFrom;
  final DateTime? vehicleTo;
  final bool vehicleDedupe;

  final List<AdminTelemetryLogItem> telemetryLogs;
  final String? telemetryNextCursor;
  final bool isLoadingTelemetry;
  final bool isLoadingMoreTelemetry;
  final String? telemetryVehicleId;
  final String telemetryPacketType;
  final String telemetryImeiSearch;
  final DateTime? telemetryFrom;
  final DateTime? telemetryTo;

  final String? sectionErrorMessage;

  AdminLogsState copyWith({
    AdminLogsTab? selectedTab,
    AdminLogsOptions? options,
    bool? isLoadingOptions,
    Object? errorMessage = _unset,
    List<AdminActivityLogItem>? activityLogs,
    Object? activityNextCursorId = _unset,
    bool? activityHasMore,
    bool? isLoadingActivity,
    bool? isLoadingMoreActivity,
    Object? activityUserId = _unset,
    String? activityActionPrefix,
    String? activityEntity,
    String? activitySearch,
    Object? activityFrom = _unset,
    Object? activityTo = _unset,
    List<AdminVehicleEventLogItem>? vehicleLogs,
    Object? vehicleNextCursorId = _unset,
    bool? isLoadingVehicle,
    bool? isLoadingMoreVehicle,
    Object? vehicleVehicleId = _unset,
    Object? vehicleUserId = _unset,
    String? vehicleSource,
    String? vehicleSeverity,
    AdminReadFilter? vehicleReadFilter,
    String? vehicleSearch,
    Object? vehicleFrom = _unset,
    Object? vehicleTo = _unset,
    bool? vehicleDedupe,
    List<AdminTelemetryLogItem>? telemetryLogs,
    Object? telemetryNextCursor = _unset,
    bool? isLoadingTelemetry,
    bool? isLoadingMoreTelemetry,
    Object? telemetryVehicleId = _unset,
    String? telemetryPacketType,
    String? telemetryImeiSearch,
    Object? telemetryFrom = _unset,
    Object? telemetryTo = _unset,
    Object? sectionErrorMessage = _unset,
  }) {
    return AdminLogsState(
      selectedTab: selectedTab ?? this.selectedTab,
      options: options ?? this.options,
      isLoadingOptions: isLoadingOptions ?? this.isLoadingOptions,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
      activityLogs: activityLogs ?? this.activityLogs,
      activityNextCursorId: identical(activityNextCursorId, _unset)
          ? this.activityNextCursorId
          : activityNextCursorId as String?,
      activityHasMore: activityHasMore ?? this.activityHasMore,
      isLoadingActivity: isLoadingActivity ?? this.isLoadingActivity,
      isLoadingMoreActivity:
          isLoadingMoreActivity ?? this.isLoadingMoreActivity,
      activityUserId: identical(activityUserId, _unset)
          ? this.activityUserId
          : activityUserId as String?,
      activityActionPrefix: activityActionPrefix ?? this.activityActionPrefix,
      activityEntity: activityEntity ?? this.activityEntity,
      activitySearch: activitySearch ?? this.activitySearch,
      activityFrom: identical(activityFrom, _unset)
          ? this.activityFrom
          : activityFrom as DateTime?,
      activityTo: identical(activityTo, _unset)
          ? this.activityTo
          : activityTo as DateTime?,
      vehicleLogs: vehicleLogs ?? this.vehicleLogs,
      vehicleNextCursorId: identical(vehicleNextCursorId, _unset)
          ? this.vehicleNextCursorId
          : vehicleNextCursorId as String?,
      isLoadingVehicle: isLoadingVehicle ?? this.isLoadingVehicle,
      isLoadingMoreVehicle: isLoadingMoreVehicle ?? this.isLoadingMoreVehicle,
      vehicleVehicleId: identical(vehicleVehicleId, _unset)
          ? this.vehicleVehicleId
          : vehicleVehicleId as String?,
      vehicleUserId: identical(vehicleUserId, _unset)
          ? this.vehicleUserId
          : vehicleUserId as String?,
      vehicleSource: vehicleSource ?? this.vehicleSource,
      vehicleSeverity: vehicleSeverity ?? this.vehicleSeverity,
      vehicleReadFilter: vehicleReadFilter ?? this.vehicleReadFilter,
      vehicleSearch: vehicleSearch ?? this.vehicleSearch,
      vehicleFrom: identical(vehicleFrom, _unset)
          ? this.vehicleFrom
          : vehicleFrom as DateTime?,
      vehicleTo: identical(vehicleTo, _unset)
          ? this.vehicleTo
          : vehicleTo as DateTime?,
      vehicleDedupe: vehicleDedupe ?? this.vehicleDedupe,
      telemetryLogs: telemetryLogs ?? this.telemetryLogs,
      telemetryNextCursor: identical(telemetryNextCursor, _unset)
          ? this.telemetryNextCursor
          : telemetryNextCursor as String?,
      isLoadingTelemetry: isLoadingTelemetry ?? this.isLoadingTelemetry,
      isLoadingMoreTelemetry:
          isLoadingMoreTelemetry ?? this.isLoadingMoreTelemetry,
      telemetryVehicleId: identical(telemetryVehicleId, _unset)
          ? this.telemetryVehicleId
          : telemetryVehicleId as String?,
      telemetryPacketType: telemetryPacketType ?? this.telemetryPacketType,
      telemetryImeiSearch: telemetryImeiSearch ?? this.telemetryImeiSearch,
      telemetryFrom: identical(telemetryFrom, _unset)
          ? this.telemetryFrom
          : telemetryFrom as DateTime?,
      telemetryTo: identical(telemetryTo, _unset)
          ? this.telemetryTo
          : telemetryTo as DateTime?,
      sectionErrorMessage: identical(sectionErrorMessage, _unset)
          ? this.sectionErrorMessage
          : sectionErrorMessage as String?,
    );
  }
}
