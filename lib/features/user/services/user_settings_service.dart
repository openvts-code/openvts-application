import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/api/api_exception.dart';
import '../models/user_settings_model.dart';

class UserSettingsService {
  UserSettingsService(this._apiClient);

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

  Future<UserSettingsProfile> getProfile() async {
    final response = await _apiClient.get<dynamic>(
      ApiEndpoints.user.profile,
      options: _readOptions,
      parser: (json) => json,
    );

    return UserSettingsProfile.fromDynamic(response.data);
  }

  Future<UserSettingsProfile> updateProfile(
    UserUpdateProfileRequest request,
  ) async {
    await _apiClient.patch<void>(
      ApiEndpoints.user.profile,
      data: request.toJson(),
      options: _mutationOptions,
      parser: (_) {},
    );

    return getProfile();
  }

  Future<void> updateCompany(UserUpdateCompanyRequest request) async {
    await _apiClient.patch<void>(
      ApiEndpoints.user.companyDetails,
      data: request.toJson(),
      options: _mutationOptions,
      parser: (_) {},
    );
  }

  Future<void> changePassword(UserChangePasswordRequest request) async {
    await _apiClient.patch<void>(
      ApiEndpoints.user.updatePassword,
      data: request.toJson(),
      options: _mutationOptions,
      parser: (_) {},
    );
  }

  Future<UserSettingsProfile> uploadProfilePhoto({
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
      ApiEndpoints.user.uploadProfile,
      data: formData,
      options: _multipartOptions,
      parser: (_) {},
    );

    return getProfile();
  }

  Future<void> requestEmailOtp() async {
    await _apiClient.post<void>(
      ApiEndpoints.user.profileVerifyEmailRequest,
      options: _mutationOptions,
      parser: (_) {},
    );
  }

  Future<void> confirmEmailOtp(String otp) async {
    await _apiClient.post<void>(
      ApiEndpoints.user.profileVerifyEmailConfirm,
      data: UserOtpConfirmRequest(otp: otp).toJson(),
      options: _mutationOptions,
      parser: (_) {},
    );
  }

  Future<void> requestWhatsAppOtp() async {
    await _apiClient.post<void>(
      ApiEndpoints.user.profileVerifyWhatsAppRequest,
      options: _mutationOptions,
      parser: (_) {},
    );
  }

  Future<void> confirmWhatsAppOtp(String otp) async {
    await _apiClient.post<void>(
      ApiEndpoints.user.profileVerifyWhatsAppConfirm,
      data: UserOtpConfirmRequest(otp: otp).toJson(),
      options: _mutationOptions,
      parser: (_) {},
    );
  }

  Future<UserEmailSubscriptionStatus> getEmailSubscription() async {
    final response = await _apiClient.get<dynamic>(
      ApiEndpoints.user.profileEmailSubscription,
      options: _readOptions,
      parser: (json) => json,
    );

    return UserEmailSubscriptionStatus.fromDynamic(response.data);
  }

  Future<UserEmailSubscriptionStatus> subscribeEmail() async {
    final response = await _apiClient.post<dynamic>(
      ApiEndpoints.user.profileEmailSubscribe,
      options: _mutationOptions,
      parser: (json) => json,
    );

    final parsed = UserEmailSubscriptionStatus.fromDynamic(response.data);
    if (parsed.isSubscribed) {
      return parsed;
    }

    return getEmailSubscription();
  }

  Future<UserLocalizationSettings> getLocalization() async {
    try {
      final response = await _apiClient.get<dynamic>(
        ApiEndpoints.user.localization,
        options: _readOptions,
        parser: (json) => json,
      );

      return UserLocalizationSettings.fromDynamic(response.data);
    } catch (error) {
      if (_isLocalizationMissingError(error)) {
        return UserLocalizationSettings.defaults;
      }
      rethrow;
    }
  }

  Future<UserLocalizationSettings> updateLocalization(
    UserLocalizationSettings settings,
  ) async {
    final response = await _apiClient.patch<dynamic>(
      ApiEndpoints.user.localization,
      data: settings.toPatchJson(),
      options: _mutationOptions,
      parser: (json) => json,
    );

    if (response.data == null) {
      return settings;
    }

    return UserLocalizationSettings.fromDynamic(response.data);
  }

  Future<List<UserLanguageOption>> getLanguages() async {
    final response = await _apiClient.get<dynamic>(
      ApiEndpoints.public.languages,
      options: _readOptions,
      parser: (json) => json,
    );

    return UserLanguageOption.listFromDynamic(response.data);
  }

  Future<List<UserDateFormatOption>> getDateFormats() async {
    final response = await _apiClient.get<dynamic>(
      ApiEndpoints.public.dateFormats,
      options: _readOptions,
      parser: (json) => json,
    );

    return UserDateFormatOption.listFromDynamic(response.data);
  }

  Future<List<String>> getTimezones() async {
    final response = await _apiClient.get<dynamic>(
      ApiEndpoints.public.timezones,
      options: _readOptions,
      parser: (json) => json,
    );

    return _coerceStringList(response.data);
  }

  Future<List<UserCountryOption>> getCountries() async {
    final response = await _apiClient.get<dynamic>(
      ApiEndpoints.public.countries,
      options: _readOptions,
      parser: (json) => json,
    );

    return UserCountryOption.listFromDynamic(response.data);
  }

  Future<List<UserMobilePrefixOption>> getMobilePrefixes() async {
    final response = await _apiClient.get<dynamic>(
      ApiEndpoints.public.mobilePrefix,
      options: _readOptions,
      parser: (json) => json,
    );

    return UserMobilePrefixOption.listFromDynamic(response.data);
  }

  Future<List<UserStateOption>> getStates(String countryCode) async {
    final normalizedCountryCode = countryCode.trim().toUpperCase();
    if (normalizedCountryCode.isEmpty) {
      return const <UserStateOption>[];
    }

    final response = await _apiClient.get<dynamic>(
      ApiEndpoints.public.states(normalizedCountryCode),
      options: _readOptions,
      parser: (json) => json,
    );

    return UserStateOption.listFromDynamic(response.data);
  }

  Future<List<UserCityOption>> getCities(
    String countryCode,
    String stateCode,
  ) async {
    final normalizedCountryCode = countryCode.trim().toUpperCase();
    final normalizedStateCode = stateCode.trim().toUpperCase();
    if (normalizedCountryCode.isEmpty || normalizedStateCode.isEmpty) {
      return const <UserCityOption>[];
    }

    final response = await _apiClient.get<dynamic>(
      ApiEndpoints.public.cities(normalizedCountryCode, normalizedStateCode),
      options: _readOptions,
      parser: (json) => json,
    );

    return UserCityOption.listFromDynamic(response.data);
  }

  bool _isLocalizationMissingError(Object error) {
    if (error is ApiException) {
      final message = error.message.trim().toLowerCase();
      if (message.contains('localization') && message.contains('not found')) {
        return true;
      }

      final detailsMessage = _extractErrorMessage(error.details)?.toLowerCase();
      if (detailsMessage != null &&
          detailsMessage.contains('localization') &&
          detailsMessage.contains('not found')) {
        return true;
      }
    }

    if (error is DioException) {
      final message = _extractErrorMessage(error.response?.data)?.toLowerCase();
      if (message != null &&
          message.contains('localization') &&
          message.contains('not found')) {
        return true;
      }
    }

    return false;
  }

  String? _extractErrorMessage(dynamic data) {
    if (data is Map) {
      final map = data.map(
        (key, value) => MapEntry(key.toString(), value),
      );

      for (final key in const ['message', 'error']) {
        final value = map[key];
        if (value is String && value.trim().isNotEmpty) {
          return value.trim();
        }
      }

      final nested = map['data'];
      if (!identical(nested, data)) {
        return _extractErrorMessage(nested);
      }
    }

    if (data is String && data.trim().isNotEmpty) {
      return data.trim();
    }

    return null;
  }

  List<String> _coerceStringList(dynamic data) {
    List<dynamic>? list;

    if (data is List) {
      list = data;
    } else if (data is Map) {
      final map = data.map(
        (key, value) => MapEntry(key.toString(), value),
      );
      for (final key in const ['data', 'items', 'timezones', 'list']) {
        final value = map[key];
        if (value is List) {
          list = value;
          break;
        }

        if (value is Map) {
          final nested = value.map(
            (key, value) => MapEntry(key.toString(), value),
          );
          for (final nestedKey in const ['data', 'items', 'list']) {
            final nestedValue = nested[nestedKey];
            if (nestedValue is List) {
              list = nestedValue;
              break;
            }
          }
          if (list != null) {
            break;
          }
        }
      }
    }

    if (list == null) {
      return const <String>[];
    }

    return list
        .map((entry) {
          if (entry is String) {
            return entry;
          }
          if (entry is Map) {
            final map = entry.map(
              (key, value) => MapEntry(key.toString(), value),
            );
            for (final key in const ['value', 'name', 'code', 'label']) {
              final value = map[key];
              if (value is String && value.trim().isNotEmpty) {
                return value;
              }
            }
          }
          return entry?.toString() ?? '';
        })
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
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
      default:
        return null;
    }
  }
}
