import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  const AppConfig._();

  static const appName = 'OpenVTS';
  static const defaultApiBaseUrl = 'https://app.openvts.io/api';

  static String get apiBaseUrl {
    final envValue = dotenv.env['API_BASE_URL'];
    if (envValue != null && envValue.trim().isNotEmpty) {
      return envValue.trim();
    }

    return const String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: defaultApiBaseUrl,
    );
  }

  static bool get useMockData {
    final envValue = dotenv.env['USE_MOCK_DATA'];
    if (envValue != null && envValue.trim().isNotEmpty) {
      return envValue.trim().toLowerCase() == 'true';
    }

    return const bool.fromEnvironment(
      'USE_MOCK_DATA',
      defaultValue: true,
    );
  }

  static const connectTimeoutSeconds = 20;
  static const receiveTimeoutSeconds = 30;
}
