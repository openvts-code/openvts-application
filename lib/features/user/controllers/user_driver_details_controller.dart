import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user_driver_model.dart';
import '../models/user_drivers_state.dart';
import '../services/user_driver_service.dart';

class UserDriverDetailsController
    extends StateNotifier<UserDriverDetailsState> {
  UserDriverDetailsController({
    required String driverId,
    required UserDriverService service,
    UserDriver? initialDriver,
  })  : _driverId = driverId,
        _service = service,
        super(
          UserDriverDetailsState.initial(
            driverId: driverId,
            initialDriver: initialDriver,
          ),
        );

  final String _driverId;
  final UserDriverService _service;

  Future<void> loadInitial() async {
    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
    );

    try {
      final results = await Future.wait<dynamic>([
        _service.fetchDriverById(_driverId),
        _service.fetchAvailableVehicles(),
        _service.fetchDriverDocumentTypes(),
      ]);

      if (!mounted) {
        return;
      }

      final driver = results[0] as UserDriver;
      final vehicles = results[1] as List<UserDriverVehicleMini>;
      final documentTypes = results[2] as List<UserDriverDocumentType>;

      state = state.copyWith(
        driver: driver,
        availableVehicles: _filterAvailableVehicles(vehicles, driver),
        documentTypes: documentTypes,
        isLoading: false,
      );

      await Future.wait<void>([
        loadLogs(),
        loadDocuments(),
      ]);
    } catch (error) {
      if (!mounted) {
        return;
      }

      state = state.copyWith(
        isLoading: false,
        errorMessage: _errorMessage(error),
      );
    }
  }

  Future<void> refresh() async {
    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
    );

    try {
      final refreshKey = DateTime.now().millisecondsSinceEpoch.toString();
      final results = await Future.wait<dynamic>([
        _service.fetchDriverById(_driverId, refreshKey: refreshKey),
        _service.fetchAvailableVehicles(refreshKey: refreshKey),
      ]);

      if (!mounted) {
        return;
      }

      final driver = results[0] as UserDriver;
      final vehicles = results[1] as List<UserDriverVehicleMini>;

      state = state.copyWith(
        driver: driver,
        availableVehicles: _filterAvailableVehicles(vehicles, driver),
        isLoading: false,
      );

      await Future.wait<void>([
        loadLogs(),
        loadDocuments(),
      ]);
    } catch (error) {
      if (!mounted) {
        return;
      }

      state = state.copyWith(
        isLoading: false,
        errorMessage: _errorMessage(error),
      );
    }
  }

  Future<bool> updateDriver(UpdateUserDriverRequest request) async {
    state = state.copyWith(
      isSaving: true,
      errorMessage: null,
    );

    try {
      final updated = await _service.updateDriver(_driverId, request);
      if (!mounted) {
        return true;
      }

      state = state.copyWith(
        driver: updated,
        isSaving: false,
      );
      return true;
    } catch (error) {
      if (!mounted) {
        return false;
      }

      state = state.copyWith(
        isSaving: false,
        errorMessage: _errorMessage(error),
      );
      return false;
    }
  }

  Future<bool> deleteDriver() async {
    state = state.copyWith(
      isDeleting: true,
      errorMessage: null,
    );

    try {
      await _service.deleteDriver(_driverId);
      if (!mounted) {
        return true;
      }

      state = state.copyWith(
        driver: null,
        logs: const <UserDriverLog>[],
        documents: const <UserDriverDocument>[],
        availableVehicles: const <UserDriverVehicleMini>[],
        isDeleting: false,
      );
      return true;
    } catch (error) {
      if (!mounted) {
        return false;
      }

      state = state.copyWith(
        isDeleting: false,
        errorMessage: _errorMessage(error),
      );
      return false;
    }
  }

  Future<bool> assignVehicle(String vehicleId) async {
    state = state.copyWith(
      isAssigning: true,
      errorMessage: null,
    );

    try {
      await _service.assignVehicle(_driverId, vehicleId);
      await _reloadDriverAndVehicles(refreshLogs: true);
      if (!mounted) {
        return true;
      }

      state = state.copyWith(isAssigning: false);
      return true;
    } catch (error) {
      if (!mounted) {
        return false;
      }

      state = state.copyWith(
        isAssigning: false,
        errorMessage: _errorMessage(error),
      );
      return false;
    }
  }

  Future<bool> unassignVehicle() async {
    state = state.copyWith(
      isUnassigning: true,
      errorMessage: null,
    );

    try {
      await _service.unassignVehicle(_driverId);
      await _reloadDriverAndVehicles(refreshLogs: true);
      if (!mounted) {
        return true;
      }

      state = state.copyWith(isUnassigning: false);
      return true;
    } catch (error) {
      if (!mounted) {
        return false;
      }

      state = state.copyWith(
        isUnassigning: false,
        errorMessage: _errorMessage(error),
      );
      return false;
    }
  }

  Future<void> loadLogs() async {
    state = state.copyWith(
      isLoadingLogs: true,
      errorMessage: null,
    );

    try {
      final logs = await _service.fetchDriverLogs(_driverId);
      if (!mounted) {
        return;
      }

      state = state.copyWith(
        logs: logs,
        isLoadingLogs: false,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      state = state.copyWith(
        isLoadingLogs: false,
        errorMessage: _errorMessage(error),
      );
    }
  }

  Future<void> loadDocuments() async {
    final shouldLoadTypes = state.documentTypes.isEmpty;

    state = state.copyWith(
      isLoadingDocuments: true,
      errorMessage: null,
    );

    try {
      final results = await Future.wait<dynamic>([
        _service.fetchDriverDocuments(_driverId),
        if (shouldLoadTypes)
          _service.fetchDriverDocumentTypes()
        else
          Future<List<UserDriverDocumentType>>.value(state.documentTypes),
      ]);

      if (!mounted) {
        return;
      }

      state = state.copyWith(
        documents: results[0] as List<UserDriverDocument>,
        documentTypes: results[1] as List<UserDriverDocumentType>,
        isLoadingDocuments: false,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      state = state.copyWith(
        isLoadingDocuments: false,
        errorMessage: _errorMessage(error),
      );
    }
  }

  Future<UserDriverDocument?> uploadDocument(
    UserDriverDocumentMutationRequest request,
  ) async {
    state = state.copyWith(
      isUploadingDocument: true,
      errorMessage: null,
    );

    try {
      final uploaded = await _service.uploadDriverDocument(
        driverId: _driverId,
        request: request,
      );

      if (!mounted) {
        return uploaded;
      }

      state = state.copyWith(isUploadingDocument: false);
      await loadDocuments();
      return uploaded;
    } catch (error) {
      if (!mounted) {
        return null;
      }

      state = state.copyWith(
        isUploadingDocument: false,
        errorMessage: _errorMessage(error),
      );
      return null;
    }
  }

  Future<UserDriverDocument?> updateDocument({
    required String docId,
    required UserDriverDocumentMutationRequest request,
  }) async {
    state = state.copyWith(
      isUploadingDocument: true,
      errorMessage: null,
    );

    try {
      final updated = await _service.updateDriverDocument(
        driverId: _driverId,
        docId: docId,
        request: request,
      );

      if (!mounted) {
        return updated;
      }

      state = state.copyWith(isUploadingDocument: false);
      await loadDocuments();
      return updated;
    } catch (error) {
      if (!mounted) {
        return null;
      }

      state = state.copyWith(
        isUploadingDocument: false,
        errorMessage: _errorMessage(error),
      );
      return null;
    }
  }

  Future<bool> deleteDocument(String docId) async {
    state = state.copyWith(
      isUploadingDocument: true,
      errorMessage: null,
    );

    try {
      await _service.deleteDriverDocument(driverId: _driverId, docId: docId);
      if (!mounted) {
        return true;
      }

      state = state.copyWith(isUploadingDocument: false);
      await loadDocuments();
      return true;
    } catch (error) {
      if (!mounted) {
        return false;
      }

      state = state.copyWith(
        isUploadingDocument: false,
        errorMessage: _errorMessage(error),
      );
      return false;
    }
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  Future<void> _reloadDriverAndVehicles({required bool refreshLogs}) async {
    final results = await Future.wait<dynamic>([
      _service.fetchDriverById(_driverId),
      _service.fetchAvailableVehicles(),
    ]);

    if (!mounted) {
      return;
    }

    final driver = results[0] as UserDriver;
    final vehicles = results[1] as List<UserDriverVehicleMini>;

    state = state.copyWith(
      driver: driver,
      availableVehicles: _filterAvailableVehicles(vehicles, driver),
    );

    if (refreshLogs) {
      await loadLogs();
    }
  }

  List<UserDriverVehicleMini> _filterAvailableVehicles(
    List<UserDriverVehicleMini> vehicles,
    UserDriver driver,
  ) {
    final assignedVehicleId = driver.vehicleAssignment?.vehicleId.trim() ?? '';
    if (assignedVehicleId.isEmpty) {
      return vehicles;
    }

    return vehicles
        .where((vehicle) => vehicle.id.trim() != assignedVehicleId)
        .toList(growable: false);
  }

  String _errorMessage(Object error) {
    if (error is ArgumentError) {
      final message = error.message?.toString().trim();
      if (message != null && message.isNotEmpty) {
        return message;
      }
    }

    if (error is DioException) {
      final responseMessage = _extractResponseMessage(error.response?.data);
      if (responseMessage != null) {
        return responseMessage;
      }

      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout) {
        return 'The request timed out. Please try again.';
      }

      if (error.type == DioExceptionType.connectionError) {
        return 'Unable to reach the server right now.';
      }

      final message = error.message?.trim();
      if (message != null && message.isNotEmpty) {
        return message;
      }
    }

    final raw = error.toString().trim();
    if (raw.startsWith('Exception: ')) {
      return raw.substring('Exception: '.length).trim();
    }

    return raw.isEmpty ? 'Driver details could not be loaded.' : raw;
  }

  String? _extractResponseMessage(dynamic data) {
    if (data is Map<String, dynamic>) {
      for (final key in const ['message', 'error']) {
        final value = data[key];
        if (value is String && value.trim().isNotEmpty) {
          return value.trim();
        }

        if (value is List) {
          final parts = value
              .whereType<String>()
              .map((item) => item.trim())
              .where((item) => item.isNotEmpty)
              .toList(growable: false);
          if (parts.isNotEmpty) {
            return parts.join(', ');
          }
        }
      }

      final nestedData = data['data'];
      if (!identical(nestedData, data)) {
        return _extractResponseMessage(nestedData);
      }
    }

    if (data is String && data.trim().isNotEmpty) {
      return data.trim();
    }

    return null;
  }
}
