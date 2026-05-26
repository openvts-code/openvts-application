import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/api/api_options.dart';
import '../models/admin_plans_model.dart';

class AdminPlansService {
  AdminPlansService(this._apiClient);

  final ApiClient _apiClient;

  static final _readOptions = normalReadOptions();

  static final _mutationOptions = normalWriteOptions();

  Future<List<AdminPlan>> getPlans({String? refreshKey}) async {
    final response = await _apiClient.get<dynamic>(
      ApiEndpoints.admin.pricingPlans,
      queryParameters: _query(refreshKey),
      options: _readOptions,
      parser: (json) => json,
    );
    return AdminPlan.listFromJson(response.data);
  }

  Future<AdminPlan?> createPlan(AdminPlanMutationRequest request) async {
    final response = await _apiClient.post<dynamic>(
      ApiEndpoints.admin.pricingPlans,
      data: request.toJson(),
      options: _mutationOptions,
      parser: (json) => json,
    );
    final list = AdminPlan.listFromJson(response.data);
    if (list.isNotEmpty) return list.first;
    return null;
  }

  Future<AdminPlan?> updatePlan({
    required String id,
    required AdminPlanMutationRequest request,
  }) async {
    final response = await _apiClient.patch<dynamic>(
      ApiEndpoints.admin.pricingPlanById(id),
      data: request.toJson(),
      options: _mutationOptions,
      parser: (json) => json,
    );
    final list = AdminPlan.listFromJson(response.data);
    if (list.isNotEmpty) return list.first;
    return null;
  }

  Future<List<AdminCurrencyOption>> getCurrencies() async {
    final response = await _apiClient.get<dynamic>(
      ApiEndpoints.public.currencies,
      options: _readOptions,
      parser: (json) => json,
    );
    return AdminCurrencyOption.listFromJson(response.data);
  }

  Map<String, dynamic>? _query(String? refreshKey) {
    final rk = refreshKey?.trim();
    if (rk == null || rk.isEmpty) return null;
    return {'rk': rk};
  }
}
