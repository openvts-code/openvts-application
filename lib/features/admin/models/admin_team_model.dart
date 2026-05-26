class AdminTeamListItem {
  const AdminTeamListItem({
    required this.id,
    required this.teamName,
    required this.username,
    required this.isVerified,
    required this.isActive,
    required this.statusLabel,
    required this.email,
    required this.phone,
    required this.mobilePrefix,
    required this.mobileNumber,
    required this.createdAt,
  });

  final String id;
  final String teamName;
  final String username;
  final bool isVerified;
  final bool isActive;
  final String statusLabel;
  final String email;
  final String phone;
  final String mobilePrefix;
  final String mobileNumber;
  final DateTime? createdAt;

  factory AdminTeamListItem.fromJson(Map<String, dynamic> json) {
    final source = _extractTeamMap(json);

    final mobilePrefix =
        _firstString(source, const [
          'mobilePrefix',
          'mobile_prefix',
          'mobileCode',
          'mobile_code',
          'phonePrefix',
          'phone_prefix',
        ]) ??
        '';
    final mobileNumber =
        _firstString(source, const [
          'mobileNumber',
          'mobile_number',
          'mobile',
          'phoneNumber',
          'phone_number',
        ]) ??
        '';

    final explicitPhone = _firstString(source, const ['phone']);
    final phone = _composePhone(
      explicitPhone: explicitPhone,
      prefix: mobilePrefix,
      number: mobileNumber,
    );

    final isActive =
        _parseStatus(
          _firstValue(source, const [
            'isActive',
            'is_active',
            'active',
            'status',
          ]),
        ) ??
        true;

    final isVerified =
        _parseStatus(
          _firstValue(source, const [
            'isVerified',
            'is_verified',
            'verified',
            'isEmailVerified',
            'is_email_verified',
            'emailVerified',
            'email_verified',
          ]),
        ) ??
        isActive;

    return AdminTeamListItem(
      id:
          _firstString(source, const [
            'uid',
            'id',
            '_id',
            'teamId',
            'team_id',
          ]) ??
          '',
      teamName:
          _firstString(source, const [
            'name',
            'teamName',
            'team_name',
            'fullName',
            'full_name',
            'Name',
          ]) ??
          '-',
      username:
          _firstString(source, const ['username', 'userName', 'user_name']) ??
          '-',
      isVerified: isVerified,
      isActive: isActive,
      statusLabel: isActive ? 'Active' : 'Inactive',
      email: _firstString(source, const ['email']) ?? '-',
      phone: phone,
      mobilePrefix: mobilePrefix,
      mobileNumber: mobileNumber,
      createdAt: _firstDate(source, const [
        'createdAt',
        'created_at',
        'created',
        'joinedAt',
        'joined_at',
      ]),
    );
  }

  static List<AdminTeamListItem> listFromJson(dynamic json) {
    return _extractTeamList(json)
        .map(_asMap)
        .where((item) => item.isNotEmpty)
        .map(AdminTeamListItem.fromJson)
        .where((item) => item.id.isNotEmpty)
        .toList(growable: false);
  }

  bool matchesQuery(String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) {
      return true;
    }

    return <String>[
      teamName,
      username,
      email,
      phone,
      statusLabel,
    ].any((value) => value.toLowerCase().contains(normalized));
  }
}

class AdminCreateTeamRequest {
  const AdminCreateTeamRequest({
    required this.name,
    required this.email,
    required this.mobilePrefix,
    required this.mobileNumber,
    required this.username,
    required this.password,
  });

  final String name;
  final String email;
  final String mobilePrefix;
  final String mobileNumber;
  final String username;
  final String password;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'name': name.trim(),
      'email': email.trim(),
      'mobilePrefix': mobilePrefix.trim(),
      'mobileNumber': mobileNumber.trim(),
      'username': username.trim(),
      'password': password.trim(),
    };
  }
}

class AdminTeamMobilePrefixOption {
  const AdminTeamMobilePrefixOption({
    required this.code,
    required this.country,
    required this.label,
  });

  final String code;
  final String country;
  final String label;

  factory AdminTeamMobilePrefixOption.fromJson(Map<String, dynamic> json) {
    final source = _extractTeamMap(json);
    final code =
        _firstString(source, const [
          'mobilePrefix',
          'mobile_prefix',
          'prefix',
          'code',
          'dialCode',
          'dial_code',
          'value',
        ]) ??
        '';
    final country =
        _firstString(source, const [
          'country',
          'countryCode',
          'country_code',
          'name',
          'label',
        ]) ??
        '';

    final label = [
      if (country.isNotEmpty) country,
      if (code.isNotEmpty) code,
    ].join(' • ').trim();

    return AdminTeamMobilePrefixOption(
      code: code,
      country: country,
      label: label.isEmpty ? code : label,
    );
  }

  static List<AdminTeamMobilePrefixOption> listFromJson(dynamic json) {
    final list = _extractTeamList(json);
    return list
        .map(_asMap)
        .where((item) => item.isNotEmpty)
        .map(AdminTeamMobilePrefixOption.fromJson)
        .where((item) => item.code.trim().isNotEmpty)
        .toList(growable: false);
  }
}

List<dynamic> _extractTeamList(dynamic json) {
  if (json is List) {
    return json;
  }

  if (json is Map<String, dynamic>) {
    final direct = _firstList(json, const ['teams', 'items']);
    if (direct != null) {
      return direct;
    }

    final data = json['data'];
    if (data is List) {
      return data;
    }

    if (data is Map<String, dynamic>) {
      final nested = _firstList(data, const ['teams', 'items', 'data']);
      if (nested != null) {
        return nested;
      }
    }
  }

  return const <dynamic>[];
}

Map<String, dynamic> _extractTeamMap(Map<String, dynamic> json) {
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

bool? _parseStatus(dynamic value) {
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

String _composePhone({
  required String? explicitPhone,
  required String prefix,
  required String number,
}) {
  final explicit = explicitPhone?.trim() ?? '';
  if (explicit.isNotEmpty) {
    return explicit;
  }

  final normalizedNumber = number.trim();
  if (normalizedNumber.isEmpty) {
    return '-';
  }

  final normalizedPrefix = prefix.trim();
  if (normalizedPrefix.isEmpty) {
    return normalizedNumber;
  }

  return '$normalizedPrefix $normalizedNumber';
}
