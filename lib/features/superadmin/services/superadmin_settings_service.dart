import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../models/superadmin_settings_model.dart';

class SuperadminSettingsService {
  SuperadminSettingsService(this._apiClient);

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

  // ---------------------------------------------------------------
  // Profile
  // ---------------------------------------------------------------

  Future<SuperadminProfileSettings> getProfile() async {
    final response = await _apiClient.get<dynamic>(
      ApiEndpoints.superadmin.profile,
      options: _readOptions,
      parser: (json) => json,
    );
    return SuperadminProfileSettings.fromJson(response.data);
  }

  Future<SuperadminProfileSettings> updateProfile(
    SuperadminUpdateProfileRequest request,
  ) async {
    await _apiClient.patch<void>(
      ApiEndpoints.superadmin.profile,
      data: request.toJson(),
      options: _mutationOptions,
      parser: (_) {},
    );
    return getProfile();
  }

  Future<void> updateCompany(
    SuperadminUpdateCompanyRequest request,
  ) async {
    await _apiClient.patch<void>(
      ApiEndpoints.superadmin.companyDetails,
      data: request.toJson(),
      options: _mutationOptions,
      parser: (_) {},
    );
  }

  Future<void> changePassword(
    SuperadminChangePasswordRequest request,
  ) async {
    await _apiClient.patch<void>(
      ApiEndpoints.superadmin.updatePassword,
      data: request.toJson(),
      options: _mutationOptions,
      parser: (_) {},
    );
  }

  Future<SuperadminProfileSettings> uploadProfilePhoto({
    required String userId,
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
      ApiEndpoints.superadmin.uploadProfile(userId),
      data: formData,
      options: _multipartOptions,
      parser: (_) {},
    );
    return getProfile();
  }

  Future<void> requestEmailOtp() async {
    await _apiClient.post<void>(
      ApiEndpoints.superadmin.profileVerifyEmailRequest,
      options: _mutationOptions,
      parser: (_) {},
    );
  }

  Future<void> confirmEmailOtp(String otp) async {
    await _apiClient.post<void>(
      ApiEndpoints.superadmin.profileVerifyEmailConfirm,
      data: <String, dynamic>{'otp': otp},
      options: _mutationOptions,
      parser: (_) {},
    );
  }

  Future<void> requestWhatsAppOtp() async {
    await _apiClient.post<void>(
      ApiEndpoints.superadmin.profileVerifyWhatsAppRequest,
      options: _mutationOptions,
      parser: (_) {},
    );
  }

  Future<void> confirmWhatsAppOtp(String otp) async {
    await _apiClient.post<void>(
      ApiEndpoints.superadmin.profileVerifyWhatsAppConfirm,
      data: <String, dynamic>{'otp': otp},
      options: _mutationOptions,
      parser: (_) {},
    );
  }

  Future<bool> getEmailSubscription() async {
    final response = await _apiClient.get<dynamic>(
      ApiEndpoints.superadmin.profileEmailSubscription,
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
      // Walk nested data wrapper.
      final inner = map['data'];
      if (inner is bool) return inner;
      if (inner is Map) {
        final innerMap = inner.cast<String, dynamic>();
        for (final key in const ['isSubscribed', 'subscribed', 'value']) {
          final value = innerMap[key];
          if (value is bool) return value;
          if (value is num) return value != 0;
        }
      }
    }
    return false;
  }

  Future<void> subscribeEmail() async {
    await _apiClient.post<void>(
      ApiEndpoints.superadmin.profileEmailSubscribe,
      options: _mutationOptions,
      parser: (_) {},
    );
  }

  // ---------------------------------------------------------------
  // White Label
  // ---------------------------------------------------------------

  Future<SuperadminWhiteLabelSettings> getWhiteLabel() async {
    final response = await _apiClient.get<dynamic>(
      ApiEndpoints.superadmin.whiteLabel,
      options: _readOptions,
      parser: (json) => json,
    );
    return SuperadminWhiteLabelSettings.fromJson(response.data);
  }

  Future<SuperadminWhiteLabelSettings> updateWhiteLabel({
    String? customDomain,
    String? primaryColor,
    FileAttachment? logoLight,
    FileAttachment? logoDark,
    FileAttachment? favicon,
    String? logoLightUrl,
    String? logoDarkUrl,
    String? faviconUrl,
  }) async {
    final formData = FormData();

    if (customDomain != null) {
      formData.fields.add(MapEntry('customDomain', customDomain));
    }
    if (primaryColor != null) {
      formData.fields.add(MapEntry('primaryColor', primaryColor));
    }

    void addFileOrUrl(String fieldName, FileAttachment? file, String? url) {
      if (file != null) {
        formData.files.add(
          MapEntry(
            fieldName,
            MultipartFile.fromBytes(
              file.bytes,
              filename: file.fileName,
              contentType: file.contentType != null
                  ? MediaType.parse(file.contentType!)
                  : _guessContentType(file.fileName),
            ),
          ),
        );
      } else if (url != null) {
        formData.fields.add(MapEntry(fieldName, url));
      }
    }

    addFileOrUrl('logoLightUrl', logoLight, logoLightUrl);
    addFileOrUrl('logoDarkUrl', logoDark, logoDarkUrl);
    addFileOrUrl('faviconUrl', favicon, faviconUrl);

    final response = await _apiClient.patch<dynamic>(
      ApiEndpoints.superadmin.whiteLabel,
      data: formData,
      options: _multipartOptions,
      parser: (json) => json,
    );
    return SuperadminWhiteLabelSettings.fromJson(response.data);
  }

  // ---------------------------------------------------------------
  // SMTP
  // ---------------------------------------------------------------

  Future<SuperadminSmtpSettings> getSmtpSettings() async {
    final response = await _apiClient.get<dynamic>(
      ApiEndpoints.superadmin.smtpSettings,
      options: _readOptions,
      parser: (json) => json,
    );
    return SuperadminSmtpSettings.fromJson(response.data);
  }

  Future<void> updateSmtpSettings(SuperadminSmtpSettings request) async {
    await _apiClient.patch<void>(
      ApiEndpoints.superadmin.smtpSettings,
      data: request.toJson(),
      options: _mutationOptions,
      parser: (_) {},
    );
  }

  Future<void> testSmtp(String email) async {
    await _apiClient.post<void>(
      ApiEndpoints.superadmin.testSmtp,
      data: <String, dynamic>{'email': email},
      options: _mutationOptions,
      parser: (_) {},
    );
  }

  // ---------------------------------------------------------------
  // Localization
  // ---------------------------------------------------------------

  Future<SuperadminLocalizationSettings> getLocalization() async {
    final response = await _apiClient.get<dynamic>(
      ApiEndpoints.superadmin.localization,
      options: _readOptions,
      parser: (json) => json,
    );
    return SuperadminLocalizationSettings.fromJson(response.data);
  }

  Future<void> updateLocalization(
    SuperadminLocalizationSettings request,
  ) async {
    await _apiClient.patch<void>(
      ApiEndpoints.superadmin.localization,
      data: request.toJson(),
      options: _mutationOptions,
      parser: (_) {},
    );
  }

  Future<List<SuperadminLanguageOption>> getLanguages() async {
    final response = await _apiClient.get<dynamic>(
      ApiEndpoints.public.languages,
      options: _readOptions,
      parser: (json) => json,
    );
    return SuperadminLanguageOption.listFromJson(response.data);
  }

  Future<List<SuperadminDateFormatOption>> getDateFormats() async {
    final response = await _apiClient.get<dynamic>(
      ApiEndpoints.public.dateFormats,
      options: _readOptions,
      parser: (json) => json,
    );
    return SuperadminDateFormatOption.listFromJson(response.data);
  }

  Future<List<String>> getTimezones() async {
    final response = await _apiClient.get<dynamic>(
      ApiEndpoints.public.timezones,
      options: _readOptions,
      parser: (json) => json,
    );
    final data = response.data;
    return _coerceStringList(data);
  }

  // ---------------------------------------------------------------
  // Software config / data retention
  // ---------------------------------------------------------------

  Future<SuperadminSoftwareConfig> getSoftwareConfig() async {
    final response = await _apiClient.get<dynamic>(
      ApiEndpoints.superadmin.softwareConfig,
      options: _readOptions,
      parser: (json) => json,
    );
    return SuperadminSoftwareConfig.fromJson(response.data);
  }

  Future<void> updateSoftwareConfig(SuperadminSoftwareConfig request) async {
    await _apiClient.patch<void>(
      ApiEndpoints.superadmin.softwareConfig,
      data: request.toJson(),
      options: _mutationOptions,
      parser: (_) {},
    );
  }

  Future<SuperadminDataRetentionSummary?> previewDataRetention() async {
    final response = await _apiClient.get<dynamic>(
      ApiEndpoints.superadmin.dataRetentionPreview,
      options: _readOptions,
      parser: (json) => json,
    );
    if (response.data == null) return null;
    return SuperadminDataRetentionSummary.fromJson(response.data);
  }

  Future<SuperadminDataRetentionSummary?> runDataRetention({
    required bool dryRun,
  }) async {
    final response = await _apiClient.post<dynamic>(
      ApiEndpoints.superadmin.dataRetentionRun,
      data: <String, dynamic>{'dryRun': dryRun},
      options: _mutationOptions,
      parser: (json) => json,
    );
    if (response.data == null) return null;
    return SuperadminDataRetentionSummary.fromJson(response.data);
  }

  // ---------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------

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
        if (value is Map) {
          for (final innerKey in const ['data', 'items', 'list']) {
            final inner = value[innerKey];
            if (inner is List) {
              list = inner;
              break;
            }
          }
          if (list != null) break;
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
              final v = map[key];
              if (v is String && v.trim().isNotEmpty) return v;
            }
          }
          return entry?.toString() ?? '';
        })
        .where((value) => value.trim().isNotEmpty)
        .toList(growable: false);
  }

  static MediaType? _guessContentType(String fileName) {
    final lower = fileName.toLowerCase();
    final dot = lower.lastIndexOf('.');
    if (dot < 0 || dot == lower.length - 1) {
      return null;
    }
    final ext = lower.substring(dot + 1);
    switch (ext) {
      case 'png':
        return MediaType('image', 'png');
      case 'jpg':
      case 'jpeg':
        return MediaType('image', 'jpeg');
      case 'gif':
        return MediaType('image', 'gif');
      case 'webp':
        return MediaType('image', 'webp');
      case 'ico':
        return MediaType('image', 'x-icon');
      case 'svg':
        return MediaType('image', 'svg+xml');
      default:
        return null;
    }
  }
}
