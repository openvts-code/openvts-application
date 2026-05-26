import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/api/api_options.dart';
import '../models/admin_inventory_model.dart';

class AdminInventoryService {
  AdminInventoryService(this._apiClient);

  final ApiClient _apiClient;

  static final Options _readOptions = normalReadOptions();

  static final Options _mutationOptions = normalWriteOptions();

  Future<List<AdminInventoryDevice>> getDevices({String? refreshKey}) async {
    final response = await _apiClient.get<dynamic>(
      ApiEndpoints.admin.devices,
      queryParameters: _queryParameters(refreshKey),
      options: _readOptions,
      parser: (json) => json,
    );

    _throwIfActionFalse(response.data);
    return AdminInventoryDevice.listFromJson(response.data);
  }

  Future<List<AdminInventorySimCard>> getSimCards({String? refreshKey}) async {
    final response = await _apiClient.get<dynamic>(
      ApiEndpoints.admin.simcards,
      queryParameters: _queryParameters(refreshKey),
      options: _readOptions,
      parser: (json) => json,
    );

    _throwIfActionFalse(response.data);
    return AdminInventorySimCard.listFromJson(response.data);
  }

  Future<AdminInventoryDevice> createDevice(
      AdminCreateDeviceRequest request) async {
    final response = await _apiClient.post<dynamic>(
      ApiEndpoints.admin.devices,
      data: request.toJson(),
      options: _mutationOptions,
      parser: (json) => json,
    );

    _throwIfActionFalse(response.data);
    final parsed = AdminInventoryDevice.listFromJson(response.data);
    if (parsed.isNotEmpty) {
      return parsed.first;
    }
    return AdminInventoryDevice.fromJson(_asMap(response.data));
  }

  Future<AdminInventorySimCard> createSimCard(
      AdminCreateSimCardRequest request) async {
    final response = await _apiClient.post<dynamic>(
      ApiEndpoints.admin.simcards,
      data: request.toJson(),
      options: _mutationOptions,
      parser: (json) => json,
    );

    _throwIfActionFalse(response.data);
    final parsed = AdminInventorySimCard.listFromJson(response.data);
    if (parsed.isNotEmpty) {
      return parsed.first;
    }
    return AdminInventorySimCard.fromJson(_asMap(response.data));
  }

  Future<void> createDeviceAndSim(
      AdminCreateDeviceAndSimRequest request) async {
    final response = await _apiClient.post<dynamic>(
      ApiEndpoints.admin.deviceAndSim,
      data: request.toJson(),
      options: _mutationOptions,
      parser: (json) => json,
    );
    _throwIfActionFalse(response.data);
  }

  Future<AdminInventoryDevice> updateDevice({
    required String id,
    required AdminUpdateDeviceRequest request,
  }) async {
    final response = await _apiClient.patch<dynamic>(
      ApiEndpoints.admin.deviceById(id),
      data: request.toJson(),
      options: _mutationOptions,
      parser: (json) => json,
    );

    _throwIfActionFalse(response.data);

    final refreshed = await _apiClient.get<dynamic>(
      ApiEndpoints.admin.deviceById(id),
      options: _readOptions,
      parser: (json) => json,
    );
    _throwIfActionFalse(refreshed.data);

    final parsed = AdminInventoryDevice.listFromJson(refreshed.data);
    if (parsed.isNotEmpty) {
      return parsed.first;
    }
    return AdminInventoryDevice.fromJson(_asMap(refreshed.data));
  }

  Future<AdminInventorySimCard> updateSimCard({
    required String id,
    required AdminUpdateSimCardRequest request,
  }) async {
    final response = await _apiClient.patch<dynamic>(
      ApiEndpoints.admin.simcardById(id),
      data: request.toJson(),
      options: _mutationOptions,
      parser: (json) => json,
    );

    _throwIfActionFalse(response.data);

    final refreshed = await _apiClient.get<dynamic>(
      ApiEndpoints.admin.simcardById(id),
      options: _readOptions,
      parser: (json) => json,
    );
    _throwIfActionFalse(refreshed.data);

    final parsed = AdminInventorySimCard.listFromJson(refreshed.data);
    if (parsed.isNotEmpty) {
      return parsed.first;
    }
    return AdminInventorySimCard.fromJson(_asMap(refreshed.data));
  }

  Future<List<AdminDeviceTypeOption>> getDeviceTypes() async {
    final response = await _apiClient.get<dynamic>(
      ApiEndpoints.public.deviceTypes,
      options: _readOptions,
      parser: (json) => json,
    );

    _throwIfActionFalse(response.data);
    return AdminDeviceTypeOption.listFromJson(response.data);
  }

  Future<List<AdminSimProviderOption>> getSimProviders() async {
    final response = await _apiClient.get<dynamic>(
      ApiEndpoints.public.simProviders,
      options: _readOptions,
      parser: (json) => json,
    );

    _throwIfActionFalse(response.data);
    return AdminSimProviderOption.listFromJson(response.data);
  }

  Future<List<AdminQuickSimCardOption>> getQuickSimcards() async {
    final response = await _apiClient.get<dynamic>(
      ApiEndpoints.admin.quickSimcards,
      options: _readOptions,
      parser: (json) => json,
    );

    _throwIfActionFalse(response.data);
    return AdminQuickSimCardOption.listFromJson(response.data);
  }

  Map<String, dynamic>? _queryParameters(String? refreshKey) {
    final rk = refreshKey?.trim();
    if (rk == null || rk.isEmpty) {
      return null;
    }
    return <String, dynamic>{'rk': rk};
  }

  void _throwIfActionFalse(dynamic data) {
    final map = _asMap(data);
    if (map.isEmpty || !map.containsKey('action')) {
      return;
    }

    final action = map['action'];
    final isSuccess = action == true ||
        action?.toString().trim().toLowerCase() == 'true' ||
        action?.toString().trim() == '1';

    if (isSuccess) {
      return;
    }

    final message = map['message']?.toString().trim();
    throw Exception(
        (message == null || message.isEmpty) ? 'Request failed.' : message);
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return value.map((key, item) => MapEntry(key.toString(), item));
    }
    return const <String, dynamic>{};
  }
}
