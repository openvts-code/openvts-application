import '../../../shared/models/user_role.dart';
import '../../auth/models/current_user.dart';
import '../../auth/models/login_response.dart';

class AdminUserListItem {
  const AdminUserListItem({
    required this.id,
    required this.name,
    required this.username,
    required this.email,
    required this.mobilePrefix,
    required this.mobileNumber,
    required this.mobileDisplay,
    required this.isEmailVerified,
    required this.isActive,
    required this.companyName,
    required this.location,
    required this.countryCode,
    required this.stateCode,
    required this.city,
    required this.pincode,
    required this.vehicleCount,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String username;
  final String email;
  final String mobilePrefix;
  final String mobileNumber;
  final String mobileDisplay;
  final bool isEmailVerified;
  final bool isActive;
  final String companyName;
  final String location;
  final String countryCode;
  final String stateCode;
  final String city;
  final String pincode;
  final int vehicleCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory AdminUserListItem.fromJson(Map<String, dynamic> json) {
    final source = _extractUserMap(json);
    final address =
        _firstMap(source, const ['address']) ?? const <String, dynamic>{};
    final companies =
        _firstList(source, const ['companies']) ?? const <dynamic>[];
    final firstCompany = companies.isEmpty ? null : _asMap(companies.first);
    final mobilePrefix = _firstString(source, const [
          'mobilePrefix',
          'mobile_prefix',
          'mobileprefix',
          'phonePrefix',
          'phone_prefix',
        ]) ??
        '';
    final mobileNumber = _firstString(source, const [
          'mobileNumber',
          'mobile_number',
          'mobile',
          'phoneNumber',
          'phone_number',
          'phone',
        ]) ??
        '';
    final companyName = _firstString(firstCompany ?? const <String, dynamic>{},
            const ['name', 'companyName', 'company_name']) ??
        _firstString(source, const [
          'companyName',
          'company_name',
          'company',
          'organization',
          'organisation',
        ]) ??
        '-';

    return AdminUserListItem(
      id: _firstString(source, const [
            'uid',
            'id',
            '_id',
            'userId',
            'user_id',
          ]) ??
          '',
      name: _firstString(source, const [
            'name',
            'Name',
            'fullName',
            'full_name',
            'displayName',
            'display_name',
          ]) ??
          '',
      username: _firstString(source, const [
            'username',
            'userName',
            'user_name',
            'login',
          ]) ??
          '',
      email: _firstString(source, const [
            'email',
            'Email',
            'mail',
            'primaryEmail',
            'primary_email',
          ]) ??
          '',
      mobilePrefix: mobilePrefix,
      mobileNumber: mobileNumber,
      mobileDisplay: _firstString(source, const [
            'mobileDisplay',
            'mobile_display',
            'phoneDisplay',
            'phone_display',
          ]) ??
          _composeMobileDisplay(mobilePrefix, mobileNumber),
      isEmailVerified: _parseBool(
            _firstValue(source, const [
              'isEmailVerified',
              'is_email_verified',
              'isemailvarified',
              'isEmailVarified',
              'emailVerified',
              'email_verified',
              'verified',
              'isVerified',
              'is_verified',
            ]),
          ) ??
          false,
      isActive: _parseBool(
            _firstValue(source, const [
              'isActive',
              'is_active',
              'isactive',
              'active',
              'status',
            ]),
          ) ??
          true,
      companyName: companyName,
      location: _firstString(address, const [
            'fullAddress',
            'full_address',
            'addressLine',
            'address_line',
          ]) ??
          _firstString(source, const [
            'location',
            'addressLine',
            'address_line',
            'address',
          ]) ??
          '-',
      countryCode: _firstString(source, const [
            'countryCode',
            'country_code',
            'country',
          ]) ??
          _firstString(address, const [
            'countryCode',
            'country_code',
            'country',
          ]) ??
          '',
      stateCode: _firstString(source, const [
            'stateCode',
            'state_code',
            'state',
          ]) ??
          _firstString(address, const [
            'stateCode',
            'state_code',
            'state',
          ]) ??
          '',
      city: _firstString(source, const [
            'city',
            'cityName',
            'city_name',
            'cityId',
            'city_id',
          ]) ??
          _firstString(address, const [
            'city',
            'cityName',
            'city_name',
            'cityId',
            'city_id',
          ]) ??
          '',
      pincode: _firstString(source, const [
            'pincode',
            'pinCode',
            'pin_code',
            'postalCode',
            'postal_code',
            'zip',
          ]) ??
          _firstString(address, const [
            'pincode',
            'pinCode',
            'pin_code',
            'postalCode',
            'postal_code',
            'zip',
          ]) ??
          '',
      vehicleCount: _firstInt(source, const [
            'totalvehicles',
            'totalVehicles',
            'vehicleCount',
            'vehiclesCount',
            'vehicles_count',
            'vehicles',
          ]) ??
          0,
      createdAt: _firstDate(source, const [
        'createdAt',
        'created_at',
        'createdOn',
        'created_on',
      ]),
      updatedAt: _firstDate(source, const [
        'updatedAt',
        'updated_at',
        'modifiedAt',
        'modified_at',
      ]),
    );
  }

  static List<AdminUserListItem> listFromJson(dynamic json) {
    return _extractUserList(json)
        .map(_asMap)
        .where((item) => item.isNotEmpty)
        .map(AdminUserListItem.fromJson)
        .where((item) => item.id.isNotEmpty)
        .toList(growable: false);
  }

  bool matchesQuery(String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) {
      return true;
    }

    return <String>[
      name,
      username,
      email,
      mobilePrefix,
      mobileNumber,
      mobileDisplay,
      companyName,
      location,
      countryCode,
    ].any((value) => value.toLowerCase().contains(normalized));
  }

  AdminUserListItem copyWith({
    String? id,
    String? name,
    String? username,
    String? email,
    String? mobilePrefix,
    String? mobileNumber,
    String? mobileDisplay,
    bool? isEmailVerified,
    bool? isActive,
    String? companyName,
    String? location,
    String? countryCode,
    String? stateCode,
    String? city,
    String? pincode,
    int? vehicleCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AdminUserListItem(
      id: id ?? this.id,
      name: name ?? this.name,
      username: username ?? this.username,
      email: email ?? this.email,
      mobilePrefix: mobilePrefix ?? this.mobilePrefix,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      mobileDisplay: mobileDisplay ?? this.mobileDisplay,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      isActive: isActive ?? this.isActive,
      companyName: companyName ?? this.companyName,
      location: location ?? this.location,
      countryCode: countryCode ?? this.countryCode,
      stateCode: stateCode ?? this.stateCode,
      city: city ?? this.city,
      pincode: pincode ?? this.pincode,
      vehicleCount: vehicleCount ?? this.vehicleCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class AdminUserDetails extends AdminUserListItem {
  const AdminUserDetails({
    required super.id,
    required super.name,
    required super.username,
    required super.email,
    required super.mobilePrefix,
    required super.mobileNumber,
    required super.mobileDisplay,
    required super.isEmailVerified,
    required super.isActive,
    required super.companyName,
    required super.location,
    required super.countryCode,
    required super.stateCode,
    required super.city,
    required super.pincode,
    required super.vehicleCount,
    required super.createdAt,
    required super.updatedAt,
    required this.address,
    required this.companies,
    required this.raw,
  });

  final Map<String, dynamic> address;
  final List<Map<String, dynamic>> companies;
  final Map<String, dynamic> raw;

  factory AdminUserDetails.fromJson(dynamic json, {String? fallbackId}) {
    final source = _extractUserMap(json);
    final base = AdminUserListItem.fromJson(source);
    final address =
        _firstMap(source, const ['address']) ?? const <String, dynamic>{};
    final companies =
        (_firstList(source, const ['companies']) ?? const <dynamic>[])
            .map(_asMap)
            .where((item) => item.isNotEmpty)
            .toList(growable: false);

    return AdminUserDetails(
      id: base.id.isEmpty ? fallbackId ?? '' : base.id,
      name: base.name,
      username: base.username,
      email: base.email,
      mobilePrefix: base.mobilePrefix,
      mobileNumber: base.mobileNumber,
      mobileDisplay: base.mobileDisplay,
      isEmailVerified: base.isEmailVerified,
      isActive: base.isActive,
      companyName: base.companyName,
      location: base.location,
      countryCode: base.countryCode,
      stateCode: base.stateCode,
      city: base.city,
      pincode: base.pincode,
      vehicleCount: base.vehicleCount,
      createdAt: base.createdAt,
      updatedAt: base.updatedAt,
      address: address,
      companies: companies,
      raw: source,
    );
  }
}

class AdminUserCountryOption {
  const AdminUserCountryOption({
    required this.value,
    required this.label,
  });

  final String value;
  final String label;

  static List<AdminUserCountryOption> listFromJson(dynamic json) {
    final options = _extractOptionList(json)
        .map((item) {
          final primitive = _primitiveString(item);
          if (primitive != null) {
            return AdminUserCountryOption(
              value: primitive.toUpperCase(),
              label: primitive,
            );
          }

          final itemMap = _asMap(item);
          if (itemMap.isEmpty) {
            return const AdminUserCountryOption(value: '', label: '');
          }

          final value = (_firstString(itemMap, const [
                    'isoCode',
                    'countryCode',
                    'country_code',
                    'code',
                    'iso2',
                    'country',
                  ]) ??
                  '')
              .toUpperCase();
          final label = _firstString(itemMap, const [
                'name',
                'countryName',
                'country_name',
                'label',
              ]) ??
              value;

          return AdminUserCountryOption(value: value, label: label);
        })
        .where((item) => item.value.isNotEmpty)
        .toList(growable: false);

    return _distinctByValue(options, (item) => item.value);
  }
}

class AdminUserMobilePrefixOption {
  const AdminUserMobilePrefixOption({
    required this.value,
    required this.label,
    required this.countryCode,
  });

  final String value;
  final String label;
  final String countryCode;

  static List<AdminUserMobilePrefixOption> listFromJson(dynamic json) {
    final options = _extractOptionList(json)
        .map((item) {
          final primitive = _primitiveString(item);
          if (primitive != null) {
            final value = _normalizeDialCode(primitive);
            return AdminUserMobilePrefixOption(
              value: value,
              label: value,
              countryCode: '',
            );
          }

          final itemMap = _asMap(item);
          if (itemMap.isEmpty) {
            return const AdminUserMobilePrefixOption(
              value: '',
              label: '',
              countryCode: '',
            );
          }

          final countryCode = (_firstString(itemMap, const [
                    'countryCode',
                    'country_code',
                    'country',
                    'iso2',
                  ]) ??
                  '')
              .toUpperCase();
          final value = _normalizeDialCode(
            _firstString(itemMap, const [
                  'mobilePrefix',
                  'mobile_prefix',
                  'dialCode',
                  'dial_code',
                  'code',
                  'prefix',
                  'value',
                ]) ??
                '',
          );
          final countryName = _firstString(itemMap, const [
            'name',
            'countryName',
            'country_name',
            'label',
          ]);
          final label = [
            value,
            if (countryCode.isNotEmpty) countryCode else countryName,
          ].whereType<String>().where((part) => part.isNotEmpty).join(' ');

          return AdminUserMobilePrefixOption(
            value: value,
            label: label.isEmpty ? value : label,
            countryCode: countryCode,
          );
        })
        .where((item) => item.value.isNotEmpty)
        .toList(growable: false);

    return _distinctByValue(options, (item) => item.value);
  }
}

class AdminUserStateOption {
  const AdminUserStateOption({
    required this.value,
    required this.label,
  });

  final String value;
  final String label;

  static List<AdminUserStateOption> listFromJson(dynamic json) {
    final options = _extractOptionList(json)
        .map((item) {
          final primitive = _primitiveString(item);
          if (primitive != null) {
            return AdminUserStateOption(
              value: primitive.toUpperCase(),
              label: primitive,
            );
          }

          final itemMap = _asMap(item);
          if (itemMap.isEmpty) {
            return const AdminUserStateOption(value: '', label: '');
          }

          final value = (_firstString(itemMap, const [
                    'isoCode',
                    'stateCode',
                    'state_code',
                    'code',
                    'iso2',
                    'state',
                    'value',
                  ]) ??
                  '')
              .toUpperCase();
          final label = _firstString(itemMap, const [
                'name',
                'stateName',
                'state_name',
                'label',
              ]) ??
              value;

          return AdminUserStateOption(value: value, label: label);
        })
        .where((item) => item.value.isNotEmpty)
        .toList(growable: false);

    return _distinctByValue(options, (item) => item.value);
  }
}

class AdminUserCityOption {
  const AdminUserCityOption({
    required this.value,
    required this.label,
  });

  final String value;
  final String label;

  static List<AdminUserCityOption> listFromJson(dynamic json) {
    final options = _extractOptionList(json)
        .map((item) {
          final primitive = _primitiveString(item);
          if (primitive != null) {
            return AdminUserCityOption(value: primitive, label: primitive);
          }

          final itemMap = _asMap(item);
          if (itemMap.isEmpty) {
            return const AdminUserCityOption(value: '', label: '');
          }

          final value = _firstString(itemMap, const [
                'name',
                'cityName',
                'city_name',
                'city',
                'value',
                'cityId',
                'city_id',
                'id',
              ]) ??
              '';
          final label = _firstString(itemMap, const [
                'name',
                'cityName',
                'city_name',
                'city',
                'label',
              ]) ??
              value;

          return AdminUserCityOption(value: value, label: label);
        })
        .where((item) => item.value.isNotEmpty)
        .toList(growable: false);

    return _distinctByValue(options, (item) => item.value);
  }
}

class AdminCreateUserRequest {
  const AdminCreateUserRequest({
    required this.name,
    required this.email,
    required this.mobilePrefix,
    required this.mobileNumber,
    required this.username,
    required this.password,
    required this.companyName,
    required this.address,
    required this.countryCode,
    required this.stateCode,
    required this.city,
    required this.pincode,
  });

  final String name;
  final String email;
  final String mobilePrefix;
  final String mobileNumber;
  final String username;
  final String password;
  final String companyName;
  final String address;
  final String countryCode;
  final String stateCode;
  final String city;
  final String pincode;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'name': name.trim(),
      'email': email.trim(),
      'mobilePrefix': mobilePrefix.trim(),
      'mobileNumber': mobileNumber.trim(),
      'username': username.trim(),
      'password': password,
      'companyName': companyName.trim(),
      'address': address.trim(),
      'countryCode': countryCode.trim().toUpperCase(),
      'stateCode': stateCode.trim(),
      'city': city.trim(),
      'pincode': pincode.trim(),
    };
  }
}

class AdminUpdateUserRequest {
  const AdminUpdateUserRequest({
    this.name,
    this.email,
    this.mobilePrefix,
    this.mobileNumber,
    this.username,
    this.companyName,
    this.address,
    this.countryCode,
    this.stateCode,
    this.city,
    this.pincode,
    this.isActive,
  });

  final String? name;
  final String? email;
  final String? mobilePrefix;
  final String? mobileNumber;
  final String? username;
  final String? companyName;
  final String? address;
  final String? countryCode;
  final String? stateCode;
  final String? city;
  final String? pincode;
  final bool? isActive;

  Map<String, dynamic> toJson() {
    final payload = <String, dynamic>{};
    _putIfNotNull(payload, 'name', name?.trim());
    _putIfNotNull(payload, 'email', email?.trim());
    _putIfNotNull(payload, 'mobilePrefix', mobilePrefix?.trim());
    _putIfNotNull(payload, 'mobileNumber', mobileNumber?.trim());
    _putIfNotNull(payload, 'username', username?.trim());
    _putIfNotNull(payload, 'companyName', companyName?.trim());
    _putIfNotNull(payload, 'address', address?.trim());
    _putIfNotNull(payload, 'countryCode', countryCode?.trim().toUpperCase());
    _putIfNotNull(payload, 'stateCode', stateCode?.trim());
    _putIfNotNull(payload, 'city', city?.trim());
    _putIfNotNull(payload, 'pincode', pincode?.trim());
    _putIfNotNull(payload, 'isActive', isActive);
    return payload;
  }
}

class AdminUpdateUserPasswordRequest {
  const AdminUpdateUserPasswordRequest({required this.newPassword});

  final String newPassword;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{'newPassword': newPassword};
  }
}

class AdminUserLoginResult {
  const AdminUserLoginResult({
    required this.token,
    required this.refreshToken,
    required this.user,
  });

  final String token;
  final String refreshToken;
  final CurrentUser user;

  bool get hasSession => token.trim().isNotEmpty;

  factory AdminUserLoginResult.fromJson(dynamic json) {
    final map = _asMap(json);
    final nested = _firstMap(map, const ['data', 'result', 'session']) ??
        const <String, dynamic>{};
    final tokens = _firstMap(map, const ['tokens', 'auth']) ??
        _firstMap(nested, const ['tokens', 'auth']) ??
        const <String, dynamic>{};
    final userJson = _firstMap(map, const ['user', 'profile', 'account']) ??
        _firstMap(nested, const ['user', 'profile', 'account']) ??
        const <String, dynamic>{};
    final normalizedUserJson = <String, dynamic>{
      ...userJson,
      'role': userJson['role'] ?? 'user',
    };

    return AdminUserLoginResult(
      token: _firstString(map, const [
            'token',
            'accessToken',
            'access_token',
            'jwt',
          ]) ??
          _firstString(tokens, const [
            'token',
            'accessToken',
            'access_token',
            'jwt',
          ]) ??
          '',
      refreshToken: _firstString(map, const [
            'refresh_token',
            'refreshToken',
          ]) ??
          _firstString(tokens, const [
            'refresh_token',
            'refreshToken',
          ]) ??
          '',
      user: CurrentUser.fromJson(normalizedUserJson).copyWith(
        role: UserRole.user,
      ),
    );
  }

  LoginResponse toLoginResponse() {
    return LoginResponse(
      accessToken: token,
      refreshToken: refreshToken,
      user: user,
    );
  }
}

void _putIfNotNull(Map<String, dynamic> payload, String key, Object? value) {
  if (value != null) {
    payload[key] = value;
  }
}

Map<String, dynamic> _extractUserMap(dynamic json) {
  final root = _asMap(json);
  if (root.isEmpty) {
    return const <String, dynamic>{};
  }

  final direct = _firstMap(root, const [
    'user',
    'adminUser',
    'details',
    'profile',
    'result',
    'item',
  ]);
  if (direct != null && direct.isNotEmpty) {
    return direct;
  }

  final data = _firstMap(root, const ['data']);
  if (data != null && data.isNotEmpty) {
    final nested = _firstMap(data, const [
      'user',
      'adminUser',
      'details',
      'profile',
      'result',
      'item',
    ]);
    if (nested != null && nested.isNotEmpty) {
      return nested;
    }
    return data;
  }

  return root;
}

List<dynamic> _extractUserList(dynamic json) {
  if (json is List) {
    return json;
  }

  final root = _asMap(json);
  final direct = _firstList(root, const [
    'userslist',
    'usersList',
    'users',
    'items',
    'records',
    'list',
    'data',
  ]);
  if (direct != null) {
    return direct;
  }

  final data = _firstMap(root, const ['data']);
  if (data != null) {
    final nested = _firstList(data, const [
      'userslist',
      'usersList',
      'users',
      'items',
      'records',
      'list',
      'data',
    ]);
    if (nested != null) {
      return nested;
    }
  }

  return const <dynamic>[];
}

List<dynamic> _extractOptionList(dynamic json) {
  if (json is List) {
    return json;
  }

  final root = _asMap(json);
  final direct = _firstList(root, const [
    'data',
    'items',
    'records',
    'list',
    'countries',
    'mobileprefix',
    'mobilePrefix',
    'mobilePrefixes',
    'states',
    'cities',
  ]);
  if (direct != null) {
    return direct;
  }

  final data = _firstMap(root, const ['data', 'result']);
  if (data != null) {
    final nested = _firstList(data, const [
      'data',
      'items',
      'records',
      'list',
      'countries',
      'mobileprefix',
      'mobilePrefix',
      'mobilePrefixes',
      'states',
      'cities',
    ]);
    if (nested != null) {
      return nested;
    }
  }

  return const <dynamic>[];
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

Map<String, dynamic>? _firstMap(
  Map<String, dynamic> map,
  List<String> keys,
) {
  for (final key in keys) {
    final value = map[key];
    final nested = _asMap(value);
    if (nested.isNotEmpty) {
      return nested;
    }
  }

  return null;
}

List<dynamic>? _firstList(
  Map<String, dynamic> map,
  List<String> keys,
) {
  for (final key in keys) {
    final value = map[key];
    if (value is List) {
      return value;
    }
  }

  return null;
}

dynamic _firstValue(Map<String, dynamic> map, List<String> keys) {
  for (final key in keys) {
    if (map.containsKey(key)) {
      return map[key];
    }
  }

  return null;
}

String? _firstString(Map<String, dynamic> map, List<String> keys) {
  for (final key in keys) {
    final value = map[key];
    final normalized = value?.toString().trim();
    if (normalized != null && normalized.isNotEmpty) {
      return normalized;
    }
  }

  return null;
}

String? _primitiveString(dynamic value) {
  if (value is Map || value is List) {
    return null;
  }

  final normalized = value?.toString().trim();
  if (normalized == null || normalized.isEmpty) {
    return null;
  }
  return normalized;
}

int? _firstInt(Map<String, dynamic> map, List<String> keys) {
  for (final key in keys) {
    final value = map[key];
    final parsed = _parseInt(value);
    if (parsed != null) {
      return parsed;
    }
  }

  return null;
}

DateTime? _firstDate(Map<String, dynamic> map, List<String> keys) {
  for (final key in keys) {
    final parsed = _parseDate(map[key]);
    if (parsed != null) {
      return parsed;
    }
  }

  return null;
}

int? _parseInt(dynamic value) {
  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.toInt();
  }

  if (value is List) {
    return value.length;
  }

  return int.tryParse(value?.toString().trim() ?? '');
}

bool? _parseBool(dynamic value) {
  if (value is bool) {
    return value;
  }

  if (value is num) {
    return value != 0;
  }

  final normalized = value?.toString().trim().toLowerCase();
  switch (normalized) {
    case '1':
    case 'true':
    case 'yes':
    case 'active':
    case 'enabled':
    case 'verified':
    case 'approved':
      return true;
    case '0':
    case 'false':
    case 'no':
    case 'inactive':
    case 'disabled':
    case 'blocked':
    case 'suspended':
    case 'unverified':
    case 'pending':
      return false;
    default:
      return null;
  }
}

DateTime? _parseDate(dynamic value) {
  if (value is DateTime) {
    return value;
  }

  if (value is int) {
    final milliseconds = value.abs() < 10000000000 ? value * 1000 : value;
    return DateTime.fromMillisecondsSinceEpoch(milliseconds);
  }

  if (value is num) {
    final intValue = value.toInt();
    final milliseconds =
        intValue.abs() < 10000000000 ? intValue * 1000 : intValue;
    return DateTime.fromMillisecondsSinceEpoch(milliseconds);
  }

  final normalized = value?.toString().trim();
  if (normalized == null || normalized.isEmpty) {
    return null;
  }

  return DateTime.tryParse(normalized);
}

String _composeMobileDisplay(String prefix, String number) {
  final normalizedPrefix = prefix.trim();
  final normalizedNumber = number.trim();
  if (normalizedPrefix.isEmpty) {
    return normalizedNumber;
  }
  if (normalizedNumber.isEmpty) {
    return normalizedPrefix;
  }
  return '$normalizedPrefix $normalizedNumber';
}

String _normalizeDialCode(String value) {
  final normalized = value.trim();
  if (normalized.isEmpty) {
    return '';
  }
  return normalized.startsWith('+') ? normalized : '+$normalized';
}

List<T> _distinctByValue<T>(List<T> items, String Function(T item) keyOf) {
  final seen = <String>{};
  final distinct = <T>[];
  for (final item in items) {
    final key = keyOf(item);
    if (key.isEmpty || seen.contains(key)) {
      continue;
    }
    seen.add(key);
    distinct.add(item);
  }
  return distinct;
}
