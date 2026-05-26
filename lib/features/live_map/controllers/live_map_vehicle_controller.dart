import '../../notifications/models/app_notification.dart';
import '../../superadmin/models/superadmin_vehicle_model.dart';
import '../services/live_map_vehicle_service.dart';

class LiveMapVehicleController {
  const LiveMapVehicleController(this._service);

  final LiveMapVehicleService _service;

  Future<SuperadminVehicleReplay> getVehicleReplayByImei({
    required String imei,
    required DateTime from,
    required DateTime to,
    int maxPoints = 5000,
  }) {
    return _service.getVehicleReplayByImei(
      imei: imei,
      from: from,
      to: to,
      maxPoints: maxPoints,
    );
  }

  Future<SuperadminVehicleLogPage> getVehicleLogsByImei(
    String imei, {
    int limit = 100,
    String? beforeId,
  }) {
    return _service.getVehicleLogsByImei(
      imei,
      limit: limit,
      beforeId: beforeId,
    );
  }

  Future<SuperadminVehicleEventPage> getVehicleEventsByImei(
    String imei, {
    int limit = 50,
    String? beforeId,
  }) {
    return _service.getVehicleEventsByImei(
      imei,
      limit: limit,
      beforeId: beforeId,
    );
  }

  Future<SuperadminVehicleSensorPage> getVehicleSensorsByImei(String imei) {
    return _service.getVehicleSensorsByImei(imei);
  }

  Future<List<SuperadminCustomCommand>> getCustomCommands({
    int? deviceTypeId,
    bool activeOnly = true,
  }) {
    return _service.getCustomCommands(
      deviceTypeId: deviceTypeId,
      activeOnly: activeOnly,
    );
  }

  Future<List<SuperadminSystemVariable>> getSystemVariables() {
    return _service.getSystemVariables();
  }

  Future<SuperadminCommandHistoryPage> getCommandHistoryByImei({
    required String imei,
    int limit = 50,
    String? cursorId,
  }) {
    return _service.getCommandHistoryByImei(
      imei: imei,
      limit: limit,
      cursorId: cursorId,
    );
  }

  Future<SuperadminCommandHistoryPage> getCommandHistoryByVehicleId({
    required String vehicleId,
    int limit = 50,
    String? cursorId,
  }) {
    return _service.getCommandHistoryByVehicleId(
      vehicleId: vehicleId,
      limit: limit,
      cursorId: cursorId,
    );
  }

  Future<SuperadminSendCommandResult> sendCommandByImei({
    required String imei,
    required String command,
    String? note,
  }) {
    return _service.sendCommandByImei(
      imei: imei,
      command: command,
      note: note,
    );
  }

  Future<SuperadminSendCommandResult> sendBulkCommandForUserVehicles({
    required List<String> vehicleIds,
    required String command,
  }) {
    return _service.sendBulkCommandForUserVehicles(
      vehicleIds: vehicleIds,
      command: command,
    );
  }

  Future<SuperadminCommandStatus?> getCommandStatus(String cmdId) {
    return _service.getCommandStatus(cmdId);
  }

  Future<SuperadminCommandHistoryItem?> getCommandDetail(String cmdId) {
    return _service.getCommandDetail(cmdId);
  }

  SuperadminVehicleLog? parseTelemetryLogPayload(dynamic raw) {
    return _service.parseTelemetryLogPayload(raw);
  }

  List<SuperadminVehicleLog> parseTelemetryLogListPayload(dynamic raw) {
    return _service.parseTelemetryLogListPayload(raw);
  }

  AppNotification? parseVehicleEventPayload(dynamic raw, {String? imei}) {
    return _service.parseVehicleEventPayload(raw, imei: imei);
  }
}
