import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../models/admin_settings_model.dart';

class AdminSettingsService {
  AdminSettingsService(this._apiClient);

  final ApiClient _apiClient;

  static final Options _readOptions = Options(
    receiveTimeout: const Duration(seconds: 60),
  );
  static final Options _mutationOptions = Options(
    sendTimeout: const Duration(seconds: 60),
    receiveTimeout: const Duration(seconds: 60),
  );
  static final Options _multipartOptions = Options(
    sendTimeout: const Duration(seconds: 60),
    receiveTimeout: const Duration(seconds: 60),
    contentType: Headers.multipartFormDataContentType,
  );

  Future<AdminProfileSettings> getProfile() async {
    final response = await _apiClient.get<dynamic>(
      ApiEndpoints.admin.profile,
      options: _readOptions,
      parser: (json) => json,
    );
    return AdminProfileSettings.fromJson(response.data);
  }

  Future<AdminProfileSettings> updateProfile(
    AdminUpdateProfileRequest request,
  ) async {
    await _apiClient.patch<void>(
      ApiEndpoints.admin.profile,
      data: request.toJson(),
      options: _mutationOptions,
      parser: (_) {},
    );
    return getProfile();
  }

  Future<void> updateCompany(AdminUpdateCompanyRequest request) async {
    await _apiClient.patch<void>(
      ApiEndpoints.admin.companyDetails,
      data: request.toJson(),
      options: _mutationOptions,
      parser: (_) {},
    );
  }

  Future<void> changePassword(AdminChangePasswordRequest request) async {
    await _apiClient.patch<void>(
      ApiEndpoints.admin.updatePassword,
      data: request.toJson(),
      options: _mutationOptions,
      parser: (_) {},
    );
  }

  Future<AdminProfileSettings> uploadProfilePhoto({
    required List<int> bytes,
    required String fileName,
  }) async {
    final formData = FormData();
    formData.fields.add(const MapEntry('type', 'PROFILE'));
    formData.files.add(
      MapEntry(
        'file',
        MultipartFile.fromBytes(
          bytes,
          filename: fileName,
          contentType: _guessContentType(fileName),
        ),
      ),
    );
    await _apiClient.post<void>(
      ApiEndpoints.admin.uploadProfile,
      data: formData,
      options: _multipartOptions,
      parser: (_) {},
    );
    return getProfile();
  }

  Future<void> requestEmailOtp() async {
    await _apiClient.post<void>(
      ApiEndpoints.admin.profileVerifyEmailRequest,
      options: _mutationOptions,
      parser: (_) {},
    );
  }

  Future<void> confirmEmailOtp(String otp) async {
    await _apiClient.post<void>(
      ApiEndpoints.admin.profileVerifyEmailConfirm,
      data: {'otp': otp},
      options: _mutationOptions,
      parser: (_) {},
    );
  }

  Future<void> requestWhatsAppOtp() async {
    await _apiClient.post<void>(
      ApiEndpoints.admin.profileVerifyWhatsAppRequest,
      options: _mutationOptions,
      parser: (_) {},
    );
  }

  Future<void> confirmWhatsAppOtp(String otp) async {
    await _apiClient.post<void>(
      ApiEndpoints.admin.profileVerifyWhatsAppConfirm,
      data: {'otp': otp},
      options: _mutationOptions,
      parser: (_) {},
    );
  }

  Future<bool> getEmailSubscription() async {
    final response = await _apiClient.get<dynamic>(
      ApiEndpoints.admin.profileEmailSubscription,
      options: _readOptions,
      parser: (json) => json,
    );
    final data = response.data;
    if (data is bool) return data;
    if (data is Map) {
      final map = data.cast<String, dynamic>();
      for (final key in const ['isSubscribed', 'subscribed', 'value']) {
        final value = map[key];
        if (value is bool) return value;
        if (value is num) return value != 0;
        if (value is String) {
          final normalized = value.trim().toLowerCase();
          if (normalized == 'true' || normalized == '1') return true;
          if (normalized == 'false' || normalized == '0') return false;
        }
      }
      final inner = map['data'];
      if (inner is bool) return inner;
    }
    return false;
  }

  Future<void> subscribeEmail() async {
    await _apiClient.post<void>(
      ApiEndpoints.admin.profileEmailSubscribe,
      options: _mutationOptions,
      parser: (_) {},
    );
  }

  Future<AdminLocalizationSettings> getLocalization() async {
    final response = await _apiClient.get<dynamic>(
      ApiEndpoints.admin.localization,
      options: _readOptions,
      parser: (json) => json,
    );
    return AdminLocalizationSettings.fromJson(response.data);
  }

  Future<void> updateLocalization(AdminLocalizationSettings request) async {
    await _apiClient.patch<void>(
      ApiEndpoints.admin.localization,
      data: request.toJson(),
      options: _mutationOptions,
      parser: (_) {},
    );
  }

  Future<List<AdminLanguageOption>> getLanguages() async {
    final response = await _apiClient.get<dynamic>(
      ApiEndpoints.public.languages,
      options: _readOptions,
      parser: (json) => json,
    );
    return AdminLanguageOption.listFromJson(response.data);
  }

  Future<List<AdminDateFormatOption>> getDateFormats() async {
    final response = await _apiClient.get<dynamic>(
      ApiEndpoints.public.dateFormats,
      options: _readOptions,
      parser: (json) => json,
    );
    return AdminDateFormatOption.listFromJson(response.data);
  }

  Future<List<String>> getTimezones() async {
    final response = await _apiClient.get<dynamic>(
      ApiEndpoints.public.timezones,
      options: _readOptions,
      parser: (json) => json,
    );
    return _coerceStringList(response.data);
  }

  Future<AdminSmtpSettings> getSmtpSettings() async {
    final response = await _apiClient.get<dynamic>(
      ApiEndpoints.admin.smtpConfig,
      options: _readOptions,
      parser: (json) => json,
    );
    return AdminSmtpSettings.fromJson(response.data);
  }

  Future<void> updateSmtpSettings(AdminSmtpSettings request) async {
    await _apiClient.patch<void>(
      ApiEndpoints.admin.smtpConfig,
      data: request.toJson(),
      options: _mutationOptions,
      parser: (_) {},
    );
  }

  Future<void> testSmtp(String email) async {
    await _apiClient.post<void>(
      ApiEndpoints.admin.testSmtp,
      data: {'email': email},
      options: _mutationOptions,
      parser: (_) {},
    );
  }

  static List<String> _coerceStringList(dynamic data) {
    List<dynamic>? list;
    if (data is List) {
      list = data;
    } else if (data is Map) {
      for (final key in const ['data', 'items', 'timezones', 'list']) {
        final value = data[key];
        if (value is List) {
          list = value;
          break;
        }
      }
    }
    if (list == null) return const <String>[];
    return list
        .map((entry) {
          if (entry is String) return entry;
          if (entry is Map) {
            final map = entry.cast<String, dynamic>();
            for (final key in const ['value', 'name', 'code', 'label']) {
              final value = map[key];
              if (value is String && value.trim().isNotEmpty) {
                return value;
              }
            }
          }
          return entry?.toString() ?? '';
        })
        .where((value) => value.trim().isNotEmpty)
        .toList(growable: false);
  }

  static MediaType? _guessContentType(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.png')) return MediaType('image', 'png');
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) {
      return MediaType('image', 'jpeg');
    }
    if (lower.endsWith('.webp')) return MediaType('image', 'webp');
    return null;
  }
}
