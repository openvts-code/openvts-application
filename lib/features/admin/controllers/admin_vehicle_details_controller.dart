import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/admin_vehicle_model.dart';
import '../models/admin_vehicle_state.dart';
import '../services/admin_vehicle_service.dart';

class AdminVehicleDetailsController
    extends StateNotifier<AdminVehicleDetailsState> {
  AdminVehicleDetailsController({
    required String vehicleId,
    required AdminVehicleService service,
    AdminVehicleDetails? initialVehicle,
  })  : _service = service,
        super(AdminVehicleDetailsState.initial(
          vehicleId: vehicleId,
          initialVehicle: initialVehicle,
        ));

  final AdminVehicleService _service;
  final Set<AdminVehicleDetailsTab> _loadedTabs = <AdminVehicleDetailsTab>{};

  Future<void> loadInitial() async {
    await loadVehicle();
  }

  void selectTab(AdminVehicleDetailsTab tab) {
    if (state.selectedTab == tab) return;
    state = state.copyWith(selectedTab: tab, sectionErrorMessage: null);
    _lazyLoad(tab);
  }

  Future<void> refreshCurrentTab() async {
    switch (state.selectedTab) {
      case AdminVehicleDetailsTab.details:
      case AdminVehicleDetailsTab.config:
        await loadVehicle();
        break;
      case AdminVehicleDetailsTab.users:
        await loadUsers();
        break;
      case AdminVehicleDetailsTab.logs:
        await loadLogs();
        break;
      case AdminVehicleDetailsTab.commands:
        await loadCommands();
        break;
      case AdminVehicleDetailsTab.sensors:
        await loadSensors();
        break;
      case AdminVehicleDetailsTab.documents:
        await loadDocuments();
        break;
      case AdminVehicleDetailsTab.events:
        await loadEvents();
        break;
    }
  }

  Future<void> loadVehicle() async {
    state = state.copyWith(
        isLoadingVehicle: true, errorMessage: null, sectionErrorMessage: null);
    try {
      final vehicle = await _service.getVehicleById(state.vehicleId);
      _loadedTabs.add(AdminVehicleDetailsTab.details);
      state = state.copyWith(vehicle: vehicle, isLoadingVehicle: false);
      unawaited(_loadReferenceDataOnce());
    } catch (error) {
      state = state.copyWith(
        isLoadingVehicle: false,
        errorMessage: state.vehicle == null ? _errorMessage(error) : null,
        sectionErrorMessage:
            state.vehicle == null ? null : _errorMessage(error),
      );
    }
  }

  Future<void> updateVehicle(AdminUpdateVehicleRequest request) async {
    state = state.copyWith(isUpdatingVehicle: true, sectionErrorMessage: null);
    try {
      final updated =
          await _service.updateVehicle(id: state.vehicleId, request: request);
      state = state.copyWith(vehicle: updated, isUpdatingVehicle: false);
    } catch (error) {
      state = state.copyWith(
          isUpdatingVehicle: false, sectionErrorMessage: _errorMessage(error));
    }
  }

  Future<void> updateVehicleStatus(bool isActive) async {
    state = state.copyWith(isUpdatingStatus: true, sectionErrorMessage: null);
    try {
      await _service.updateVehicleStatus(
          id: state.vehicleId, isActive: isActive);
      state = state.copyWith(isUpdatingStatus: false);
      await loadVehicle();
    } catch (error) {
      state = state.copyWith(
          isUpdatingStatus: false, sectionErrorMessage: _errorMessage(error));
    }
  }

  Future<void> deleteVehicle() async {
    state = state.copyWith(isDeletingVehicle: true, sectionErrorMessage: null);
    try {
      await _service.deleteVehicle(state.vehicleId);
      state = state.copyWith(isDeletingVehicle: false);
    } catch (error) {
      state = state.copyWith(
          isDeletingVehicle: false, sectionErrorMessage: _errorMessage(error));
    }
  }

  Future<void> updateConfig(AdminVehicleConfigUpdateRequest request) async {
    state = state.copyWith(isUpdatingConfig: true, sectionErrorMessage: null);
    try {
      final updated = await _service.updateVehicleConfig(
          id: state.vehicleId, request: request);
      state = state.copyWith(vehicle: updated, isUpdatingConfig: false);
    } catch (error) {
      state = state.copyWith(
          isUpdatingConfig: false, sectionErrorMessage: _errorMessage(error));
    }
  }

  Future<void> loadUsers() async {
    state = state.copyWith(isLoadingUsers: true, sectionErrorMessage: null);
    try {
      final results = await Future.wait<List<AdminVehicleUserMini>>([
        _service.getLinkedUsers(state.vehicleId),
        _service.getUnlinkedUsers(state.vehicleId),
      ]);
      _loadedTabs.add(AdminVehicleDetailsTab.users);
      state = state.copyWith(
        linkedUsers: results[0],
        availableUsers: results[1],
        isLoadingUsers: false,
      );
    } catch (error) {
      state = state.copyWith(
          isLoadingUsers: false, sectionErrorMessage: _errorMessage(error));
    }
  }

  Future<void> linkUser(String userId) async {
    state = state.copyWith(isLinkingUser: true, sectionErrorMessage: null);
    try {
      await _service.linkUser(vehicleId: state.vehicleId, userId: userId);
      state = state.copyWith(isLinkingUser: false);
      await loadUsers();
    } catch (error) {
      state = state.copyWith(
          isLinkingUser: false, sectionErrorMessage: _errorMessage(error));
    }
  }

  Future<void> unlinkUser(String userId) async {
    state = state.copyWith(isUnlinkingUser: true, sectionErrorMessage: null);
    try {
      await _service.unlinkUser(vehicleId: state.vehicleId, userId: userId);
      state = state.copyWith(isUnlinkingUser: false);
      await loadUsers();
    } catch (error) {
      state = state.copyWith(
          isUnlinkingUser: false, sectionErrorMessage: _errorMessage(error));
    }
  }

  Future<void> loadLogs({DateTime? from, DateTime? to}) async {
    final imei = state.vehicle?.imei.trim() ?? '';
    if (imei.isEmpty) return;
    state = state.copyWith(isLoadingLogs: true, sectionErrorMessage: null);
    try {
      final page =
          await _service.getVehicleLogsByImei(imei: imei, from: from, to: to);
      _loadedTabs.add(AdminVehicleDetailsTab.logs);
      state = state.copyWith(
        logs: page.items,
        logNextCursor: page.nextCursor,
        isLoadingLogs: false,
      );
    } catch (error) {
      state = state.copyWith(
          isLoadingLogs: false, sectionErrorMessage: _errorMessage(error));
    }
  }

  Future<void> loadMoreLogs() async {
    final imei = state.vehicle?.imei.trim() ?? '';
    final cursor = state.logNextCursor?.trim() ?? '';
    if (imei.isEmpty || cursor.isEmpty || state.isLoadingMoreLogs) return;
    state = state.copyWith(isLoadingMoreLogs: true, sectionErrorMessage: null);
    try {
      final page =
          await _service.getVehicleLogsByImei(imei: imei, beforeId: cursor);
      state = state.copyWith(
        logs: <AdminVehicleLogItem>[...state.logs, ...page.items],
        logNextCursor: page.nextCursor,
        isLoadingMoreLogs: false,
      );
    } catch (error) {
      state = state.copyWith(
          isLoadingMoreLogs: false, sectionErrorMessage: _errorMessage(error));
    }
  }

  Future<void> setLogRange({DateTime? from, DateTime? to}) async {
    await loadLogs(from: from, to: to);
  }

  Future<void> loadEvents(
      {DateTime? from, DateTime? to, String? source, String? severity}) async {
    final imei = state.vehicle?.imei.trim() ?? '';
    if (imei.isEmpty) return;
    state = state.copyWith(isLoadingEvents: true, sectionErrorMessage: null);
    try {
      final page = await _service.getVehicleEventsByImei(
        imei: imei,
        from: from,
        to: to,
        source: source,
        severity: severity,
      );
      _loadedTabs.add(AdminVehicleDetailsTab.events);
      state = state.copyWith(
        events: page.items,
        eventNextCursor: page.nextCursor,
        isLoadingEvents: false,
      );
    } catch (error) {
      state = state.copyWith(
          isLoadingEvents: false, sectionErrorMessage: _errorMessage(error));
    }
  }

  Future<void> loadMoreEvents() async {
    final imei = state.vehicle?.imei.trim() ?? '';
    final cursor = state.eventNextCursor?.trim() ?? '';
    if (imei.isEmpty || cursor.isEmpty || state.isLoadingMoreEvents) return;
    state =
        state.copyWith(isLoadingMoreEvents: true, sectionErrorMessage: null);
    try {
      final page =
          await _service.getVehicleEventsByImei(imei: imei, beforeId: cursor);
      state = state.copyWith(
        events: <AdminVehicleEventItem>[...state.events, ...page.items],
        eventNextCursor: page.nextCursor,
        isLoadingMoreEvents: false,
      );
    } catch (error) {
      state = state.copyWith(
          isLoadingMoreEvents: false,
          sectionErrorMessage: _errorMessage(error));
    }
  }

  Future<void> setEventFilters(
      {DateTime? from, DateTime? to, String? source, String? severity}) async {
    await loadEvents(from: from, to: to, source: source, severity: severity);
  }

  Future<void> loadCommands() async {
    final imei = state.vehicle?.imei.trim() ?? '';
    if (imei.isEmpty) return;
    state = state.copyWith(isLoadingCommands: true, sectionErrorMessage: null);
    try {
      final results = await Future.wait<dynamic>([
        _service.getCommandHistoryByImei(imei: imei),
        _service.getCustomCommands(activeOnly: true),
        _service.getSystemVariables(),
      ]);
      final page = results[0] as AdminVehicleCommandHistoryPage;
      _loadedTabs.add(AdminVehicleDetailsTab.commands);
      state = state.copyWith(
        commandHistory: page.items,
        customCommands: results[1] as List<AdminCustomCommand>,
        systemVariables: results[2] as List<AdminSystemVariable>,
        isLoadingCommands: false,
      );
    } catch (error) {
      state = state.copyWith(
          isLoadingCommands: false, sectionErrorMessage: _errorMessage(error));
    }
  }

  Future<void> sendCommand({required String command, String? note}) async {
    final imei = state.vehicle?.imei.trim() ?? '';
    if (imei.isEmpty) return;
    state = state.copyWith(isSendingCommand: true, sectionErrorMessage: null);
    try {
      final result = await _service.sendCommandByImei(
          imei: imei, command: command, note: note);
      state = state.copyWith(isSendingCommand: false);
      await loadCommands();
      final cmdId = (result.cmdId ?? '').trim();
      if (cmdId.isNotEmpty) {
        unawaited(pollCommandStatus(cmdId));
      }
    } catch (error) {
      state = state.copyWith(
          isSendingCommand: false, sectionErrorMessage: _errorMessage(error));
    }
  }

  Future<void> pollCommandStatus(String cmdId) async {
    try {
      await _service.getCommandStatus(cmdId);
    } catch (_) {}
  }

  Future<AdminCommandStatus?> getCommandStatus(String cmdId) {
    return _service.getCommandStatus(cmdId);
  }

  Future<AdminVehicleCommandItem?> getCommandLog(String cmdId) {
    return _service.getCommandLog(cmdId);
  }

  Future<void> loadSensors({
    String? search,
    int page = 1,
    int limit = 100,
    bool includeLive = true,
  }) async {
    state = state.copyWith(isLoadingSensors: true, sectionErrorMessage: null);
    try {
      final sensorPage = await _service.getVehicleSensors(
        vehicleId: state.vehicleId,
        search: search,
        page: page,
        limit: limit,
        includeLive: includeLive,
      );
      _loadedTabs.add(AdminVehicleDetailsTab.sensors);
      state =
          state.copyWith(sensors: sensorPage.items, isLoadingSensors: false);
    } catch (error) {
      state = state.copyWith(
          isLoadingSensors: false, sectionErrorMessage: _errorMessage(error));
    }
  }

  Future<void> createSensor(AdminVehicleSensorUpsertRequest request) async {
    state = state.copyWith(isCreatingSensor: true, sectionErrorMessage: null);
    try {
      await _service.createVehicleSensor(
          vehicleId: state.vehicleId, request: request);
      state = state.copyWith(isCreatingSensor: false);
      await loadSensors();
    } catch (error) {
      state = state.copyWith(
          isCreatingSensor: false, sectionErrorMessage: _errorMessage(error));
    }
  }

  Future<void> updateSensor(
      {required String sensorId,
      required AdminVehicleSensorUpsertRequest request}) async {
    state = state.copyWith(isUpdatingSensor: true, sectionErrorMessage: null);
    try {
      await _service.updateVehicleSensor(
          vehicleId: state.vehicleId, sensorId: sensorId, request: request);
      state = state.copyWith(isUpdatingSensor: false);
      await loadSensors();
    } catch (error) {
      state = state.copyWith(
          isUpdatingSensor: false, sectionErrorMessage: _errorMessage(error));
    }
  }

  Future<void> deleteSensor(String sensorId) async {
    state = state.copyWith(isDeletingSensor: true, sectionErrorMessage: null);
    try {
      await _service.deleteVehicleSensor(
          vehicleId: state.vehicleId, sensorId: sensorId);
      state = state.copyWith(isDeletingSensor: false);
      await loadSensors();
    } catch (error) {
      state = state.copyWith(
          isDeletingSensor: false, sectionErrorMessage: _errorMessage(error));
    }
  }

  Future<void> runSensor({
    String? sensorId,
    AdminVehicleSensorRunRequest? request,
  }) async {
    state = state.copyWith(isRunningSensor: true, sectionErrorMessage: null);
    try {
      await _service.runVehicleSensor(
        vehicleId: state.vehicleId,
        sensorId: sensorId,
        request: request,
      );
      state = state.copyWith(isRunningSensor: false);
    } catch (error) {
      state = state.copyWith(
          isRunningSensor: false, sectionErrorMessage: _errorMessage(error));
    }
  }

  Future<void> loadDocuments() async {
    state = state.copyWith(isLoadingDocuments: true, sectionErrorMessage: null);
    try {
      final results = await Future.wait<dynamic>([
        _service.getVehicleDocuments(state.vehicleId),
        if (state.documentTypes.isEmpty)
          _service.getVehicleDocumentTypes()
        else
          Future<List<AdminVehicleDocumentType>>.value(state.documentTypes),
      ]);
      _loadedTabs.add(AdminVehicleDetailsTab.documents);
      state = state.copyWith(
        documents: results[0] as List<AdminVehicleDocument>,
        documentTypes: results[1] as List<AdminVehicleDocumentType>,
        isLoadingDocuments: false,
      );
    } catch (error) {
      state = state.copyWith(
          isLoadingDocuments: false, sectionErrorMessage: _errorMessage(error));
    }
  }

  Future<void> uploadDocument(AdminVehicleDocumentRequest request) async {
    state =
        state.copyWith(isUploadingDocument: true, sectionErrorMessage: null);
    try {
      await _service.uploadVehicleDocument(request);
      state = state.copyWith(isUploadingDocument: false);
      await loadDocuments();
    } catch (error) {
      state = state.copyWith(
          isUploadingDocument: false,
          sectionErrorMessage: _errorMessage(error));
    }
  }

  Future<void> updateDocument(
      {required String docId,
      required AdminVehicleDocumentRequest request}) async {
    state = state.copyWith(isUpdatingDocument: true, sectionErrorMessage: null);
    try {
      await _service.updateVehicleDocument(docId: docId, request: request);
      state = state.copyWith(isUpdatingDocument: false);
      await loadDocuments();
    } catch (error) {
      state = state.copyWith(
          isUpdatingDocument: false, sectionErrorMessage: _errorMessage(error));
    }
  }

  Future<void> deleteDocument(String docId) async {
    state = state.copyWith(isDeletingDocument: true, sectionErrorMessage: null);
    try {
      await _service.deleteVehicleDocument(docId);
      state = state.copyWith(isDeletingDocument: false);
      await loadDocuments();
    } catch (error) {
      state = state.copyWith(
          isDeletingDocument: false, sectionErrorMessage: _errorMessage(error));
    }
  }

  void _lazyLoad(AdminVehicleDetailsTab tab) {
    if (_loadedTabs.contains(tab)) {
      return;
    }
    switch (tab) {
      case AdminVehicleDetailsTab.details:
      case AdminVehicleDetailsTab.config:
        if (!state.isLoadingVehicle) unawaited(loadVehicle());
        break;
      case AdminVehicleDetailsTab.users:
        if (!state.isLoadingUsers) unawaited(loadUsers());
        break;
      case AdminVehicleDetailsTab.logs:
        if (!state.isLoadingLogs) unawaited(loadLogs());
        break;
      case AdminVehicleDetailsTab.commands:
        if (!state.isLoadingCommands) unawaited(loadCommands());
        break;
      case AdminVehicleDetailsTab.sensors:
        if (!state.isLoadingSensors) unawaited(loadSensors());
        break;
      case AdminVehicleDetailsTab.documents:
        if (!state.isLoadingDocuments) unawaited(loadDocuments());
        break;
      case AdminVehicleDetailsTab.events:
        if (!state.isLoadingEvents) unawaited(loadEvents());
        break;
    }
  }

  Future<void> _loadReferenceDataOnce() async {
    if (state.isLoadingReferences ||
        (state.vehicleTypes.isNotEmpty && state.timezones.isNotEmpty)) {
      return;
    }
    state = state.copyWith(isLoadingReferences: true);
    try {
      final results = await Future.wait<dynamic>([
        _service.getVehicleTypes(),
        _service.getTimezones(),
        _service.getQuickDevices(),
        _service.getPricingPlans(),
      ]);
      state = state.copyWith(
        vehicleTypes: results[0] as List<AdminVehicleTypeOption>,
        timezones: results[1] as List<String>,
        quickDevices: results[2] as List<AdminQuickDeviceOption>,
        pricingPlans: results[3] as List<AdminPricingPlanOption>,
        isLoadingReferences: false,
      );
    } catch (_) {
      state = state.copyWith(isLoadingReferences: false);
    }
  }

  String _errorMessage(Object error) {
    final message = error.toString().trim();
    if (message.startsWith('Exception:')) {
      return message.replaceFirst('Exception:', '').trim();
    }
    return message.isEmpty ? 'Unable to complete request.' : message;
  }
}
