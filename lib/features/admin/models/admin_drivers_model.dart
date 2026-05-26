class AdminDriverListItem {
  const AdminDriverListItem({
    required this.id,
    required this.firstName,
    required this.email,
    required this.username,
    required this.mobilePrefix,
    required this.mobile,
    required this.phone,
    required this.address,
    required this.fullAddress,
    required this.countryCode,
    required this.stateCode,
    required this.city,
    required this.pincode,
    required this.primaryUserName,
    required this.primaryUserUid,
    required this.isVerified,
    required this.isActive,
    required this.statusLabel,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String firstName;
  final String email;
  final String username;
  final String mobilePrefix;
  final String mobile;
  final String phone;
  final String address;
  final String fullAddress;
  final String countryCode;
  final String stateCode;
  final String city;
  final String pincode;
  final String primaryUserName;
  final String primaryUserUid;
  final bool isVerified;
  final bool isActive;
  final String statusLabel;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory AdminDriverListItem.fromJson(Map<String, dynamic> json) {
    final source = _extractDriverMap(json);
    final addressMap =
        _firstMap(source, const ['address']) ?? const <String, dynamic>{};
    final userPrimaryMap =
        _firstMap(source, const ['userPrimary', 'primaryUser']) ??
            const <String, dynamic>{};

    final prefix = _firstString(source, const [
      'mobilePrefix',
      'mobile_prefix',
      'mobileCode',
      'mobile_code',
      'phonePrefix',
      'phone_prefix',
    ]);
    final number = _firstString(source, const [
      'phone',
      'mobile',
      'mobileNumber',
      'mobile_number',
      'phoneNumber',
      'phone_number',
    ]);

    final phone = (number != null && number.trim().isNotEmpty)
        ? _composePhone(prefix, number)
        : '-';

    final isActive = _parseStatusValue(_firstValue(source, const [
          'isActive',
          'is_active',
          'isactive',
          'active',
          'status',
        ])) ??
        true;
    final isVerified = _parseStatusValue(_firstValue(source, const [
          'isVerified',
          'is_verified',
          'verified',
          'isEmailVerified',
          'isemailvarified',
        ])) ??
        false;
    final addressLine = _firstString(addressMap, const [
          'addressLine',
          'address_line',
          'address',
        ]) ??
        _firstString(source, const ['addressLine', 'address_line']) ??
        '-';
    final fullAddress = _firstString(addressMap, const [
          'fullAddress',
          'full_address',
        ]) ??
        _firstString(source, const ['fullAddress', 'full_address']) ??
        '-';
    final countryCode = _firstString(addressMap, const [
          'countryCode',
          'country_code',
          'country',
        ]) ??
        _firstString(source, const ['countryCode', 'country_code']) ??
        '-';
    final stateCode = _firstString(addressMap, const [
          'stateCode',
          'state_code',
          'state',
        ]) ??
        _firstString(source, const ['stateCode', 'state_code']) ??
        '-';
    final city = _firstString(addressMap, const [
          'cityId',
          'city',
          'cityName',
          'city_id',
        ]) ??
        _firstString(source, const ['cityId', 'city', 'cityName']) ??
        '-';
    final pincode = _firstString(addressMap, const [
          'pincode',
          'pinCode',
          'pin_code',
        ]) ??
        _firstString(source, const ['pincode', 'pinCode']) ??
        '-';
    final bestAddress =
        fullAddress.trim().isNotEmpty && fullAddress.trim() != '-'
            ? fullAddress
            : addressLine;

    return AdminDriverListItem(
      id: _firstString(source, const [
            'id',
            'uid',
            '_id',
            'driverId',
            'driver_id',
          ]) ??
          '',
      firstName: _firstString(source, const [
            'firstName',
            'first_name',
            'name',
            'Name',
            'fullName',
            'full_name',
            'displayName',
            'display_name',
          ]) ??
          '-',
      username: _firstString(source, const [
            'username',
            'userName',
            'user_name',
          ]) ??
          '-',
      email: _firstString(source, const ['email', 'Email']) ?? '-',
      mobilePrefix: prefix ?? '',
      mobile: number ?? '',
      phone: phone,
      address: bestAddress,
      fullAddress: fullAddress,
      countryCode: countryCode,
      stateCode: stateCode,
      city: city,
      pincode: pincode,
      primaryUserName:
          _firstString(userPrimaryMap, const ['name', 'fullName']) ??
              _firstString(source, const ['primaryUserName']) ??
              '-',
      primaryUserUid:
          _firstString(userPrimaryMap, const ['uid', 'id', '_id']) ??
              _firstString(source, const ['primaryUserid', 'primaryUserId']) ??
              '',
      isVerified: isVerified,
      isActive: isActive,
      statusLabel: isActive ? 'Active' : 'Inactive',
      createdAt: _firstDate(source, const [
        'createdAt',
        'created_at',
        'created',
        'joinedAt',
        'joined_at',
      ]),
      updatedAt: _firstDate(source, const [
        'updatedAt',
        'updated_at',
        'updated',
      ]),
    );
  }

  static List<AdminDriverListItem> listFromJson(dynamic json) {
    return _extractDriverList(json)
        .map(_asMap)
        .where((item) => item.isNotEmpty)
        .map(AdminDriverListItem.fromJson)
        .where((item) => item.id.isNotEmpty)
        .toList(growable: false);
  }

  bool matchesQuery(String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) {
      return true;
    }

    return <String>[
      firstName,
      username,
      email,
      phone,
      mobile,
      mobilePrefix,
      address,
      fullAddress,
      countryCode,
      primaryUserName,
      statusLabel,
    ].any((value) => value.toLowerCase().contains(normalized));
  }
}

class AdminDriverCreateRequest {
  const AdminDriverCreateRequest({
    required this.primaryUserid,
    required this.name,
    required this.mobilePrefix,
    required this.mobile,
    required this.email,
    required this.username,
    required this.password,
    required this.countryCode,
    required this.stateCode,
    required this.city,
    required this.address,
    required this.pincode,
  });

  final String primaryUserid;
  final String name;
  final String mobilePrefix;
  final String mobile;
  final String email;
  final String username;
  final String password;
  final String countryCode;
  final String stateCode;
  final String city;
  final String address;
  final String pincode;

  Map<String, dynamic> toJson() {
    final payload = <String, dynamic>{
      'name': name.trim(),
      'mobilePrefix': mobilePrefix.trim(),
      'mobile': mobile.trim(),
      'primaryUserid': primaryUserid.trim(),
      'username': username.trim(),
      'password': password.trim(),
      'countryCode': countryCode.trim(),
    };
    if (email.trim().isNotEmpty) payload['email'] = email.trim();
    if (stateCode.trim().isNotEmpty) payload['stateCode'] = stateCode.trim();
    if (city.trim().isNotEmpty) payload['city'] = city.trim();
    if (address.trim().isNotEmpty) payload['address'] = address.trim();
    if (pincode.trim().isNotEmpty) payload['pincode'] = pincode.trim();
    return payload;
  }
}

List<dynamic> _extractDriverList(dynamic json) {
  if (json is List) {
    return json;
  }

  if (json is Map<String, dynamic>) {
    final direct =
        _firstList(json, const ['drivers', 'driverlist', 'driverslist']);
    if (direct != null) {
      return direct;
    }

    final data = json['data'];
    if (data is List) {
      return data;
    }

    if (data is Map<String, dynamic>) {
      final nested = _firstList(
          data, const ['drivers', 'driverlist', 'driverslist', 'items']);
      if (nested != null) {
        return nested;
      }

      final deepData = data['data'];
      if (deepData is List) {
        return deepData;
      }
    }
  }

  return const <dynamic>[];
}

Map<String, dynamic> _extractDriverMap(Map<String, dynamic> json) {
  final data = json['data'];
  if (data is Map<String, dynamic>) {
    final nestedData = data['data'];
    if (nestedData is Map<String, dynamic>) {
      return nestedData;
    }

    return data;
  }

  return json;
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

List<dynamic>? _firstList(Map<String, dynamic> map, List<String> keys) {
  for (final key in keys) {
    final value = map[key];
    if (value is List) {
      return value;
    }
  }

  return null;
}

Map<String, dynamic>? _firstMap(Map<String, dynamic> map, List<String> keys) {
  for (final key in keys) {
    final value = map[key];
    if (value is Map<String, dynamic>) {
      return value;
    }

    if (value is Map) {
      return value.map((nestedKey, nestedValue) =>
          MapEntry(nestedKey.toString(), nestedValue));
    }
  }

  return null;
}

String? _firstString(Map<String, dynamic> map, List<String> keys) {
  for (final key in keys) {
    final value = map[key];
    if (value == null) {
      continue;
    }

    final asString = value.toString().trim();
    if (asString.isNotEmpty && asString.toLowerCase() != 'null') {
      return asString;
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

bool? _parseStatusValue(dynamic value) {
  if (value is bool) {
    return value;
  }

  if (value is num) {
    if (value == 1) {
      return true;
    }
    if (value == 0) {
      return false;
    }
  }

  if (value is String) {
    final normalized = value.trim().toLowerCase();
    if (normalized.isEmpty) {
      return null;
    }

    if (normalized == 'true' ||
        normalized == 'active' ||
        normalized == 'enabled' ||
        normalized == '1') {
      return true;
    }

    if (normalized == 'false' ||
        normalized == 'inactive' ||
        normalized == 'disabled' ||
        normalized == '0') {
      return false;
    }
  }

  return null;
}

DateTime? _firstDate(Map<String, dynamic> map, List<String> keys) {
  final raw = _firstString(map, keys);
  if (raw == null) {
    return null;
  }

  return DateTime.tryParse(raw);
}

String _composePhone(String? prefix, String number) {
  final cleanPrefix = prefix?.trim() ?? '';
  final cleanNumber = number.trim();
  if (cleanPrefix.isEmpty) {
    return cleanNumber;
  }

  return '$cleanPrefix $cleanNumber';
}
