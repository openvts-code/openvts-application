import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../models/superadmin_administrator_model.dart';

class SuperadminAdministratorsService {
  SuperadminAdministratorsService(this._apiClient);

  static final Options _readOptions = Options(
    receiveTimeout: const Duration(seconds: 60),
  );

  static final Options _mutationOptions = Options(
    sendTimeout: const Duration(seconds: 60),
    receiveTimeout: const Duration(seconds: 60),
  );

  final ApiClient _apiClient;

  Future<SuperadminAdministratorPage> getAdministrators({
    String? refreshKey,
  }) async {
    final response = await _apiClient.get<dynamic>(
      ApiEndpoints.superadmin.adminList,
      queryParameters: <String, dynamic>{
        'rk': refreshKey ?? DateTime.now().millisecondsSinceEpoch.toString(),
      },
      options: _readOptions,
      parser: (json) => json,
    );

    return SuperadminAdministratorPage.fromJson(response.data);
  }

  Future<List<SuperadminCountryOption>> getCountries() async {
    final response = await _apiClient.get<dynamic>(
      ApiEndpoints.public.countries,
      options: _readOptions,
      parser: (json) => json,
    );

    return SuperadminCountryOption.listFromJson(response.data);
  }

  Future<List<SuperadminMobilePrefixOption>> getMobilePrefixes() async {
    final response = await _apiClient.get<dynamic>(
      ApiEndpoints.public.mobilePrefix,
      options: _readOptions,
      parser: (json) => json,
    );

    return SuperadminMobilePrefixOption.listFromJson(response.data);
  }

  Future<List<SuperadminStateOption>> getStates(String countryCode) async {
    final response = await _apiClient.get<dynamic>(
      ApiEndpoints.public.states(countryCode),
      options: _readOptions,
      parser: (json) => json,
    );

    return SuperadminStateOption.listFromJson(
      response.data,
      countryCode: countryCode,
    );
  }

  Future<List<SuperadminCityOption>> getCities(
    String countryCode,
    String stateCode,
  ) async {
    final response = await _apiClient.get<dynamic>(
      ApiEndpoints.public.cities(countryCode, stateCode),
      options: _readOptions,
      parser: (json) => json,
    );

    return SuperadminCityOption.listFromJson(response.data);
  }

  Future<void> createAdministrator(
    SuperadminCreateAdministratorRequest request,
  ) async {
    await _apiClient.post<void>(
      ApiEndpoints.superadmin.createAdmin,
      data: request.toJson(),
      options: _mutationOptions,
      parser: (_) {},
    );
  }

  Future<void> setAdministratorActive(
    String administratorId, {
    required bool isActive,
  }) async {
    await _apiClient.post<void>(
      ApiEndpoints.superadmin.activateAdmin(administratorId),
      data: <String, dynamic>{
        'isActive': isActive,
      },
      options: _mutationOptions,
      parser: (_) {},
    );
  }

  Future<void> deleteAdministrator(String administratorId) async {
    await _apiClient.delete<void>(
      ApiEndpoints.superadmin.deleteAdmin(administratorId),
      options: _mutationOptions,
      parser: (_) {},
    );
  }

  Future<SuperadminAdministratorLoginOutcome> loginAsAdministrator(
    String administratorId,
  ) async {
    final response = await _apiClient.get<dynamic>(
      ApiEndpoints.superadmin.adminLogin(administratorId),
      options: _mutationOptions,
      parser: (json) => json,
    );

    return SuperadminAdministratorLoginOutcome.fromJson(response.data);
  }
}