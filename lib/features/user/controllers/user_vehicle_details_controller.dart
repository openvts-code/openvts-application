import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user_vehicle_model.dart';
import '../models/user_vehicle_state.dart';
import '../services/user_vehicle_service.dart';

class UserVehicleDetailsController
    extends StateNotifier<UserVehicleDetailsState> {
  UserVehicleDetailsController({
    required String vehicleId,
    required UserVehicleService service,
    UserVehicleListItem? initialVehicle,
  })  : _vehicleId = vehicleId,
        _service = service,
        super(
          UserVehicleDetailsState.initial(
            vehicleId: vehicleId,
            initialVehicle: initialVehicle,
          ),
        );

  final String _vehicleId;
  final UserVehicleService _service;
  final Set<UserVehicleDetailsTab> _loadedTabs = <UserVehicleDetailsTab>{};
  var _sensorSearchQuery = '';

  Future<void> loadInitial() async {
    await loadVehicle();
    if (mounted) unawaited(loadReferenceData());
  }

  void selectTab(UserVehicleDetailsTab tab) {
    if (state.selectedTab == tab) return;
    state = state.copyWith(selectedTab: tab, sectionErrorMessage: null);
    _lazyLoadForTab(tab);
  }

  Future<void> refreshCurrentTab() async {
    switch (state.selectedTab) {
      case UserVehicleDetailsTab.details:
        await loadVehicle(refreshing: state.vehicle != null);
        break;
      case UserVehicleDetailsTab.sensors:
        await loadSensors();
        break;
      case UserVehicleDetailsTab.documents:
        await loadDocuments();
        break;
      case UserVehicleDetailsTab.config:
        await loadVehicle(refreshing: state.vehicle != null);
        break;
    }
  }

  void _lazyLoadForTab(UserVehicleDetailsTab tab) {
    if (_loadedTabs.contains(tab)) {
      if (tab == UserVehicleDetailsTab.details &&
          !state.hasReferenceData &&
          !state.isLoadingReferenceData) {
        unawaited(loadReferenceData());
      }
      return;
    }

    switch (tab) {
      case UserVehicleDetailsTab.details:
        if (!state.hasReferenceData && !state.isLoadingReferenceData) {
          unawaited(loadReferenceData());
        }
        if (!state.isLoadingVehicle && state.vehicle == null) {
          unawaited(loadVehicle());
        }
        break;
      case UserVehicleDetailsTab.sensors:
        if (!state.isLoadingSensors) unawaited(loadSensors());
        break;
      case UserVehicleDetailsTab.documents:
        if (!state.isLoadingDocuments) unawaited(loadDocuments());
        break;
      case UserVehicleDetailsTab.config:
        if (!state.isLoadingVehicle && state.vehicle == null) {
          unawaited(loadVehicle());
        }
        break;
    }
  }

  Future<void> loadVehicle({bool refreshing = false}) async {
    state = state.copyWith(
      isLoadingVehicle: !refreshing,
      isRefreshing: refreshing,
      errorMessage: null,
      sectionErrorMessage: null,
    );
    try {
      final vehicle = await _service.getVehicleById(_vehicleId);
      if (!mounted) return;
      _loadedTabs.add(UserVehicleDetailsTab.details);
      _loadedTabs.add(UserVehicleDetailsTab.config);
      state = state.copyWith(
        vehicle: vehicle,
        isLoadingVehicle: false,
        isRefreshing: false,
      );
    } catch (error) {
      if (!mounted) return;
      final message = _errorMessage(error);
      state = state.copyWith(
        isLoadingVehicle: false,
        isRefreshing: false,
        errorMessage: state.hasVehicle ? null : message,
        sectionErrorMessage: state.hasVehicle ? message : null,
      );
    }
  }

  Future<void> loadReferenceData() async {
    if (state.hasReferenceData || state.isLoadingReferenceData) return;

    state = state.copyWith(
      isLoadingReferenceData: true,
      sectionErrorMessage: null,
    );
    try {
      final results = await Future.wait<dynamic>([
        _service.getVehicleTypes(),
        _service.getTimezones(),
      ]);
      if (!mounted) return;
      state = state.copyWith(
        vehicleTypes: results[0] as List<UserVehicleTypeOption>,
        timezones: results[1] as List<String>,
        isLoadingReferenceData: false,
      );
    } catch (error) {
      if (!mounted) return;
      state = state.copyWith(
        isLoadingReferenceData: false,
        sectionErrorMessage: _errorMessage(error),
      );
    }
  }

  Future<bool> updateVehicle(UserVehicleUpdateRequest request) async {
    state = state.copyWith(isSavingVehicle: true, sectionErrorMessage: null);
    try {
      final vehicle = await _service.updateVehicle(
        id: _vehicleId,
        request: request,
      );
      if (!mounted) return true;
      state = state.copyWith(vehicle: vehicle, isSavingVehicle: false);
      return true;
    } catch (error) {
      if (!mounted) return false;
      state = state.copyWith(
        isSavingVehicle: false,
        sectionErrorMessage: _errorMessage(error),
      );
      return false;
    }
  }

  Future<bool> updateConfig(UserVehicleConfigUpdateRequest request) async {
    state = state.copyWith(isSavingConfig: true, sectionErrorMessage: null);
    try {
      final vehicle = await _service.updateVehicleConfig(
        id: _vehicleId,
        request: request,
      );
      if (!mounted) return true;
      state = state.copyWith(vehicle: vehicle, isSavingConfig: false);
      return true;
    } catch (error) {
      if (!mounted) return false;
      state = state.copyWith(
        isSavingConfig: false,
        sectionErrorMessage: _errorMessage(error),
      );
      return false;
    }
  }

  Future<void> loadSensors({String? search}) async {
    if (search != null) {
      _sensorSearchQuery = search.trim();
    }
    state = state.copyWith(
      isLoadingSensors: true,
      sectionErrorMessage: null,
    );
    try {
      final page = await _service.getVehicleSensors(
        vehicleId: _vehicleId,
        search: _sensorSearchQuery.isEmpty ? null : _sensorSearchQuery,
      );
      if (!mounted) return;
      _loadedTabs.add(UserVehicleDetailsTab.sensors);
      state = state.copyWith(
        sensors: page.items,
        isLoadingSensors: false,
      );
    } catch (error) {
      if (!mounted) return;
      state = state.copyWith(
        isLoadingSensors: false,
        sectionErrorMessage: _errorMessage(error),
      );
    }
  }

  Future<bool> createSensor({
    required String name,
    String? unit,
    String? icon,
    required String code,
    bool isActive = true,
  }) async {
    state = state.copyWith(isCreatingSensor: true, sectionErrorMessage: null);
    try {
      await _service.createVehicleSensor(
        vehicleId: _vehicleId,
        name: name,
        unit: unit,
        icon: icon,
        code: code,
        isActive: isActive,
      );
      if (!mounted) return true;
      state = state.copyWith(isCreatingSensor: false);
      await loadSensors();
      return true;
    } catch (error) {
      if (!mounted) return false;
      state = state.copyWith(
        isCreatingSensor: false,
        sectionErrorMessage: _errorMessage(error),
      );
      return false;
    }
  }

  Future<bool> updateSensor({
    required String sensorId,
    required String name,
    String? unit,
    String? icon,
    required String code,
    bool isActive = true,
  }) async {
    state = state.copyWith(isUpdatingSensor: true, sectionErrorMessage: null);
    try {
      await _service.updateVehicleSensor(
        vehicleId: _vehicleId,
        sensorId: sensorId,
        name: name,
        unit: unit,
        icon: icon,
        code: code,
        isActive: isActive,
      );
      if (!mounted) return true;
      state = state.copyWith(isUpdatingSensor: false);
      await loadSensors();
      return true;
    } catch (error) {
      if (!mounted) return false;
      state = state.copyWith(
        isUpdatingSensor: false,
        sectionErrorMessage: _errorMessage(error),
      );
      return false;
    }
  }

  Future<bool> deleteSensor(String sensorId) async {
    state = state.copyWith(isDeletingSensor: true, sectionErrorMessage: null);
    try {
      await _service.deleteVehicleSensor(
        vehicleId: _vehicleId,
        sensorId: sensorId,
      );
      if (!mounted) return true;
      state = state.copyWith(isDeletingSensor: false);
      await loadSensors();
      return true;
    } catch (error) {
      if (!mounted) return false;
      state = state.copyWith(
        isDeletingSensor: false,
        sectionErrorMessage: _errorMessage(error),
      );
      return false;
    }
  }

  Future<UserVehicleSensorRunResult?> runSensor({
    required String code,
    required Map<String, dynamic> payload,
  }) async {
    state = state.copyWith(isRunningSensor: true, sectionErrorMessage: null);
    try {
      final result = await _service.runVehicleSensor(
        vehicleId: _vehicleId,
        code: code,
        payload: payload,
      );
      if (mounted) state = state.copyWith(isRunningSensor: false);
      return result;
    } catch (error) {
      if (!mounted) return null;
      state = state.copyWith(
        isRunningSensor: false,
        sectionErrorMessage: _errorMessage(error),
      );
      return null;
    }
  }

  Future<UserVehicleSensorTelemetry?> loadSensorTelemetry() async {
    state = state.copyWith(
      isLoadingSensorTelemetry: true,
      sectionErrorMessage: null,
    );
    try {
      final telemetry = await _service.getVehicleSensorTelemetry(_vehicleId);
      if (mounted) {
        state = state.copyWith(
          telemetryPayload: telemetry,
          isLoadingSensorTelemetry: false,
        );
      }
      return telemetry;
    } catch (error) {
      if (!mounted) return null;
      state = state.copyWith(
        isLoadingSensorTelemetry: false,
        sectionErrorMessage: _errorMessage(error),
      );
      return null;
    }
  }

  Future<UserVehicleSensorHistory?> loadSensorHistory({
    required String sensorId,
    required DateTime from,
    required DateTime to,
    int maxPoints = 500,
  }) async {
    state = state.copyWith(
      isLoadingSensorHistory: true,
      sectionErrorMessage: null,
    );
    try {
      final history = await _service.getVehicleSensorHistory(
        vehicleId: _vehicleId,
        sensorId: sensorId,
        from: from,
        to: to,
        maxPoints: maxPoints,
      );
      if (mounted) state = state.copyWith(isLoadingSensorHistory: false);
      return history;
    } catch (error) {
      if (!mounted) return null;
      state = state.copyWith(
        isLoadingSensorHistory: false,
        sectionErrorMessage: _errorMessage(error),
      );
      return null;
    }
  }

  Future<void> loadDocuments() async {
    final shouldLoadTypes = state.documentTypes.isEmpty;
    state = state.copyWith(
      isLoadingDocuments: true,
      isLoadingDocumentTypes: shouldLoadTypes,
      sectionErrorMessage: null,
    );
    try {
      final results = await Future.wait<dynamic>([
        _service.getVehicleDocuments(_vehicleId),
        if (shouldLoadTypes)
          _service.getVehicleDocumentTypes()
        else
          Future<List<UserVehicleDocumentType>>.value(state.documentTypes),
      ]);
      if (!mounted) return;
      _loadedTabs.add(UserVehicleDetailsTab.documents);
      state = state.copyWith(
        documents: results[0] as List<UserVehicleDocument>,
        documentTypes: results[1] as List<UserVehicleDocumentType>,
        isLoadingDocuments: false,
        isLoadingDocumentTypes: false,
      );
    } catch (error) {
      if (!mounted) return;
      state = state.copyWith(
        isLoadingDocuments: false,
        isLoadingDocumentTypes: false,
        sectionErrorMessage: _errorMessage(error),
      );
    }
  }

  Future<bool> uploadDocument(UserVehicleDocumentRequest request) async {
    state = state.copyWith(
      isUploadingDocument: true,
      sectionErrorMessage: null,
    );
    try {
      await _service.uploadVehicleDocument(
        vehicleId: _vehicleId,
        request: request,
      );
      if (!mounted) return true;
      state = state.copyWith(isUploadingDocument: false);
      await loadDocuments();
      return true;
    } catch (error) {
      if (!mounted) return false;
      state = state.copyWith(
        isUploadingDocument: false,
        sectionErrorMessage: _errorMessage(error),
      );
      return false;
    }
  }

  Future<bool> updateDocument({
    required String docId,
    required UserVehicleDocumentRequest request,
  }) async {
    state = state.copyWith(
      isUpdatingDocument: true,
      sectionErrorMessage: null,
    );
    try {
      await _service.updateVehicleDocument(
        vehicleId: _vehicleId,
        docId: docId,
        request: request,
      );
      if (!mounted) return true;
      state = state.copyWith(isUpdatingDocument: false);
      await loadDocuments();
      return true;
    } catch (error) {
      if (!mounted) return false;
      state = state.copyWith(
        isUpdatingDocument: false,
        sectionErrorMessage: _errorMessage(error),
      );
      return false;
    }
  }

  Future<bool> deleteDocument(String docId) async {
    state = state.copyWith(
      isDeletingDocument: true,
      sectionErrorMessage: null,
    );
    try {
      await _service.deleteVehicleDocument(vehicleId: _vehicleId, docId: docId);
      if (!mounted) return true;
      state = state.copyWith(isDeletingDocument: false);
      await loadDocuments();
      return true;
    } catch (error) {
      if (!mounted) return false;
      state = state.copyWith(
        isDeletingDocument: false,
        sectionErrorMessage: _errorMessage(error),
      );
      return false;
    }
  }

  String _errorMessage(Object error) {
    if (error is DioException) {
      final responseMessage = _extractResponseMessage(error.response?.data);
      if (responseMessage != null) return responseMessage;
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout) {
        return 'The request timed out. Please try again.';
      }
      if (error.type == DioExceptionType.connectionError) {
        return 'Unable to reach the server right now.';
      }
      final message = error.message?.trim();
      if (message != null && message.isNotEmpty) return message;
    }

    final raw = error.toString().trim();
    if (raw.startsWith('Exception: ')) {
      return raw.substring('Exception: '.length).trim();
    }
    return raw.isEmpty ? 'Vehicle details could not be loaded.' : raw;
  }

  String? _extractResponseMessage(dynamic data) {
    if (data is Map<String, dynamic>) {
      for (final key in const ['message', 'error']) {
        final value = data[key];
        if (value is String && value.trim().isNotEmpty) return value.trim();
        if (value is List) {
          final parts = value
              .whereType<String>()
              .map((item) => item.trim())
              .where((item) => item.isNotEmpty)
              .toList(growable: false);
          if (parts.isNotEmpty) return parts.join(', ');
        }
      }
      final nestedData = data['data'];
      if (!identical(nestedData, data)) {
        return _extractResponseMessage(nestedData);
      }
    }
    if (data is String && data.trim().isNotEmpty) return data.trim();
    return null;
  }
}
