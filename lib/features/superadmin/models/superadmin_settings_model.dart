import 'dart:typed_data';

// =====================================================================
// Enums
// =====================================================================

enum SuperadminSettingsSection {
  profile,
  whiteLabel,
  smtp,
  localization,
  general,
}

enum SuperadminSmtpType {
  none,
  ssl,
  tls;

  String get apiValue {
    switch (this) {
      case SuperadminSmtpType.none:
        return 'NONE';
      case SuperadminSmtpType.ssl:
        return 'SSL';
      case SuperadminSmtpType.tls:
        return 'TLS';
    }
  }

  static SuperadminSmtpType fromValue(dynamic value) {
    final normalized = value?.toString().trim().toUpperCase();
    switch (normalized) {
      case 'SSL':
        return SuperadminSmtpType.ssl;
      case 'TLS':
        return SuperadminSmtpType.tls;
      case 'NONE':
      case '':
      case null:
        return SuperadminSmtpType.none;
      default:
        return SuperadminSmtpType.none;
    }
  }
}

enum SuperadminLayoutDirection {
  ltr,
  rtl;

  String get apiValue =>
      this == SuperadminLayoutDirection.rtl ? 'RTL' : 'LTR';

  static SuperadminLayoutDirection fromValue(dynamic value) {
    final normalized = value?.toString().trim().toUpperCase();
    return normalized == 'RTL'
        ? SuperadminLayoutDirection.rtl
        : SuperadminLayoutDirection.ltr;
  }
}

enum SuperadminTheme {
  light,
  dark,
  system;

  String get apiValue {
    switch (this) {
      case SuperadminTheme.light:
        return 'LIGHT';
      case SuperadminTheme.dark:
        return 'DARK';
      case SuperadminTheme.system:
        return 'SYSTEM';
    }
  }

  static SuperadminTheme fromValue(dynamic value) {
    final normalized = value?.toString().trim().toUpperCase();
    switch (normalized) {
      case 'LIGHT':
        return SuperadminTheme.light;
      case 'DARK':
        return SuperadminTheme.dark;
      case 'SYSTEM':
      default:
        return SuperadminTheme.system;
    }
  }
}

enum SuperadminUnits {
  km,
  miles;

  String get apiValue =>
      this == SuperadminUnits.miles ? 'MILES' : 'KM';

  static SuperadminUnits fromValue(dynamic value) {
    final normalized = value?.toString().trim().toUpperCase();
    return normalized == 'MILES' ? SuperadminUnits.miles : SuperadminUnits.km;
  }
}

enum SuperadminGeocodingPrecision {
  twoDigit,
  threeDigit;

  String get apiValue =>
      this == SuperadminGeocodingPrecision.threeDigit
          ? 'THREE_DIGIT'
          : 'TWO_DIGIT';

  static SuperadminGeocodingPrecision fromValue(dynamic value) {
    final normalized = value?.toString().trim().toUpperCase();
    return normalized == 'THREE_DIGIT'
        ? SuperadminGeocodingPrecision.threeDigit
        : SuperadminGeocodingPrecision.twoDigit;
  }
}

// =====================================================================
// File attachment helper for multipart uploads
// =====================================================================

class FileAttachment {
  const FileAttachment({
    required this.bytes,
    required this.fileName,
    this.contentType,
  });

  final Uint8List bytes;
  final String fileName;
  final String? contentType;
}

// =====================================================================
// Profile
// =====================================================================

class SuperadminAddressSettings {
  const SuperadminAddressSettings({
    this.id,
    this.addressLine,
    this.countryCode,
    this.stateCode,
    this.cityName,
    this.cityId,
    this.pincode,
    this.fullAddress,
  });

  final int? id;
  final String? addressLine;
  final String? countryCode;
  final String? stateCode;
  final String? cityName;
  final int? cityId;
  final String? pincode;
  final String? fullAddress;

  factory SuperadminAddressSettings.fromJson(dynamic json) {
    final source = _asMap(json);
    return SuperadminAddressSettings(
      id: _firstInt(source, const ['id', 'addressId']),
      addressLine: _firstString(source, const ['addressLine', 'address', 'line']),
      countryCode: _firstString(source, const ['countryCode', 'country']),
      stateCode: _firstString(source, const ['stateCode', 'state']),
      cityName: _firstString(source, const ['cityName', 'city']),
      cityId: _firstInt(source, const ['cityId']),
      pincode: _firstString(source, const ['pincode', 'pinCode', 'zip', 'zipCode']),
      fullAddress: _firstString(source, const ['fullAddress', 'formatted']),
    );
  }

  SuperadminAddressSettings copyWith({
    int? id,
    String? addressLine,
    String? countryCode,
    String? stateCode,
    String? cityName,
    int? cityId,
    String? pincode,
    String? fullAddress,
  }) {
    return SuperadminAddressSettings(
      id: id ?? this.id,
      addressLine: addressLine ?? this.addressLine,
      countryCode: countryCode ?? this.countryCode,
      stateCode: stateCode ?? this.stateCode,
      cityName: cityName ?? this.cityName,
      cityId: cityId ?? this.cityId,
      pincode: pincode ?? this.pincode,
      fullAddress: fullAddress ?? this.fullAddress,
    );
  }
}

class SuperadminSocialLinks {
  const SuperadminSocialLinks({
    this.facebook,
    this.twitter,
    this.linkedin,
    this.instagram,
    this.youtube,
    this.github,
  });

  final String? facebook;
  final String? twitter;
  final String? linkedin;
  final String? instagram;
  final String? youtube;
  final String? github;

  factory SuperadminSocialLinks.fromJson(dynamic json) {
    final source = _asMap(json);
    return SuperadminSocialLinks(
      facebook: _firstString(source, const ['facebook']),
      twitter: _firstString(source, const ['twitter', 'x']),
      linkedin: _firstString(source, const ['linkedin']),
      instagram: _firstString(source, const ['instagram']),
      youtube: _firstString(source, const ['youtube']),
      github: _firstString(source, const ['github']),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'facebook': facebook ?? '',
        'twitter': twitter ?? '',
        'linkedin': linkedin ?? '',
        'instagram': instagram ?? '',
        'youtube': youtube ?? '',
        'github': github ?? '',
      };

  Map<String, dynamic> toJsonNonEmpty() {
    final result = <String, dynamic>{};
    void put(String key, String? value) {
      final trimmed = value?.trim();
      if (trimmed != null && trimmed.isNotEmpty) {
        result[key] = trimmed;
      }
    }

    put('facebook', facebook);
    put('twitter', twitter);
    put('linkedin', linkedin);
    put('instagram', instagram);
    put('youtube', youtube);
    put('github', github);
    return result;
  }

  SuperadminSocialLinks copyWith({
    String? facebook,
    String? twitter,
    String? linkedin,
    String? instagram,
    String? youtube,
    String? github,
  }) {
    return SuperadminSocialLinks(
      facebook: facebook ?? this.facebook,
      twitter: twitter ?? this.twitter,
      linkedin: linkedin ?? this.linkedin,
      instagram: instagram ?? this.instagram,
      youtube: youtube ?? this.youtube,
      github: github ?? this.github,
    );
  }
}

class SuperadminCompanySettings {
  const SuperadminCompanySettings({
    this.id,
    this.name,
    this.websiteUrl,
    this.customDomain,
    this.socialLinks,
    this.logoLightUrl,
    this.logoDarkUrl,
    this.faviconUrl,
    this.primaryColor,
  });

  final int? id;
  final String? name;
  final String? websiteUrl;
  final String? customDomain;
  final SuperadminSocialLinks? socialLinks;
  final String? logoLightUrl;
  final String? logoDarkUrl;
  final String? faviconUrl;
  final String? primaryColor;

  factory SuperadminCompanySettings.fromJson(dynamic json) {
    final source = _asMap(json);
    return SuperadminCompanySettings(
      id: _firstInt(source, const ['id', 'companyId']),
      name: _firstString(source, const ['name', 'companyName', 'Name']),
      websiteUrl: _firstString(source, const ['websiteUrl', 'website']),
      customDomain: _firstString(source, const ['customDomain', 'domain']),
      socialLinks: source['socialLinks'] != null
          ? SuperadminSocialLinks.fromJson(source['socialLinks'])
          : null,
      logoLightUrl: _firstString(source, const ['logoLightUrl', 'logoLight']),
      logoDarkUrl: _firstString(source, const ['logoDarkUrl', 'logoDark']),
      faviconUrl: _firstString(source, const ['faviconUrl', 'favicon']),
      primaryColor: _firstString(source, const ['primaryColor', 'color']),
    );
  }

  SuperadminCompanySettings copyWith({
    int? id,
    String? name,
    String? websiteUrl,
    String? customDomain,
    SuperadminSocialLinks? socialLinks,
    String? logoLightUrl,
    String? logoDarkUrl,
    String? faviconUrl,
    String? primaryColor,
  }) {
    return SuperadminCompanySettings(
      id: id ?? this.id,
      name: name ?? this.name,
      websiteUrl: websiteUrl ?? this.websiteUrl,
      customDomain: customDomain ?? this.customDomain,
      socialLinks: socialLinks ?? this.socialLinks,
      logoLightUrl: logoLightUrl ?? this.logoLightUrl,
      logoDarkUrl: logoDarkUrl ?? this.logoDarkUrl,
      faviconUrl: faviconUrl ?? this.faviconUrl,
      primaryColor: primaryColor ?? this.primaryColor,
    );
  }
}

class SuperadminProfileSettings {
  const SuperadminProfileSettings({
    this.uid,
    this.name,
    this.username,
    this.email,
    this.mobilePrefix,
    this.mobileNumber,
    this.profileUrl,
    this.credits,
    this.createdAt,
    this.updatedAt,
    this.isEmailVerified = false,
    this.emailVerifiedAt,
    this.isMobileVerified = false,
    this.mobileVerifiedAt,
    this.company,
    this.address,
  });

  final int? uid;
  final String? name;
  final String? username;
  final String? email;
  final String? mobilePrefix;
  final String? mobileNumber;
  final String? profileUrl;
  final double? credits;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool isEmailVerified;
  final DateTime? emailVerifiedAt;
  final bool isMobileVerified;
  final DateTime? mobileVerifiedAt;
  final SuperadminCompanySettings? company;
  final SuperadminAddressSettings? address;

  factory SuperadminProfileSettings.fromJson(dynamic json) {
    final source = _unwrap(json);

    // Company may be in either `company` or first element of `companies`.
    Map<String, dynamic>? companyMap;
    final directCompany = _asMap(source['company']);
    if (directCompany.isNotEmpty) {
      companyMap = directCompany;
    } else {
      final companies = source['companies'];
      if (companies is List && companies.isNotEmpty) {
        final first = _asMap(companies.first);
        if (first.isNotEmpty) {
          companyMap = first;
        }
      }
    }

    final addressMap = _firstMap(source, const ['address', 'profileAddress']);

    return SuperadminProfileSettings(
      uid: _firstInt(source, const ['uid', 'id', 'userId']),
      name: _firstString(source, const ['name', 'Name', 'fullName']),
      username: _firstString(source, const ['username', 'userName']),
      email: _firstString(source, const ['email']),
      mobilePrefix: _firstString(source, const ['mobilePrefix', 'phonePrefix']),
      mobileNumber: _firstString(source, const ['mobileNumber', 'phoneNumber', 'mobile']),
      profileUrl: _firstString(source, const ['profileUrl', 'avatar', 'profile']),
      credits: _firstDouble(source, const ['credits', 'balance']),
      createdAt: _firstDate(source, const ['createdAt', 'created']),
      updatedAt: _firstDate(source, const ['updatedAt', 'modified']),
      isEmailVerified: _firstBool(
            source,
            const ['isEmailVerified', 'emailVerified'],
          ) ??
          false,
      emailVerifiedAt: _firstDate(source, const ['emailVerifiedAt']),
      isMobileVerified: _firstBool(
            source,
            const ['isMobileVerified', 'mobileVerified'],
          ) ??
          false,
      mobileVerifiedAt: _firstDate(source, const ['mobileVerifiedAt']),
      company: companyMap != null
          ? SuperadminCompanySettings.fromJson(companyMap)
          : null,
      address: addressMap != null
          ? SuperadminAddressSettings.fromJson(addressMap)
          : null,
    );
  }

  SuperadminProfileSettings copyWith({
    int? uid,
    String? name,
    String? username,
    String? email,
    String? mobilePrefix,
    String? mobileNumber,
    String? profileUrl,
    double? credits,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isEmailVerified,
    DateTime? emailVerifiedAt,
    bool? isMobileVerified,
    DateTime? mobileVerifiedAt,
    SuperadminCompanySettings? company,
    SuperadminAddressSettings? address,
  }) {
    return SuperadminProfileSettings(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      username: username ?? this.username,
      email: email ?? this.email,
      mobilePrefix: mobilePrefix ?? this.mobilePrefix,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      profileUrl: profileUrl ?? this.profileUrl,
      credits: credits ?? this.credits,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      emailVerifiedAt: emailVerifiedAt ?? this.emailVerifiedAt,
      isMobileVerified: isMobileVerified ?? this.isMobileVerified,
      mobileVerifiedAt: mobileVerifiedAt ?? this.mobileVerifiedAt,
      company: company ?? this.company,
      address: address ?? this.address,
    );
  }
}

// =====================================================================
// Profile update request payloads
// =====================================================================

class SuperadminUpdateProfileRequest {
  const SuperadminUpdateProfileRequest({
    this.name,
    this.email,
    this.mobilePrefix,
    this.mobileNumber,
    this.addressLine,
    this.countryCode,
    this.stateCode,
    this.cityName,
    this.pincode,
  });

  final String? name;
  final String? email;
  final String? mobilePrefix;
  final String? mobileNumber;
  final String? addressLine;
  final String? countryCode;
  final String? stateCode;
  final String? cityName;
  final String? pincode;

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (name != null) json['name'] = name;
    if (email != null) json['email'] = email;
    if (mobilePrefix != null) json['mobilePrefix'] = mobilePrefix;
    if (mobileNumber != null) json['mobileNumber'] = mobileNumber;
    if (addressLine != null) json['addressLine'] = addressLine;
    if (countryCode != null) json['countryCode'] = countryCode;
    if (stateCode != null) json['stateCode'] = stateCode;
    if (cityName != null) json['cityName'] = cityName;
    if (pincode != null) json['pincode'] = pincode;
    return json;
  }
}

class SuperadminUpdateCompanyRequest {
  const SuperadminUpdateCompanyRequest({
    this.name,
    this.websiteUrl,
    this.customDomain,
    this.socialLinks,
    this.primaryColor,
  });

  final String? name;
  final String? websiteUrl;
  final String? customDomain;
  final SuperadminSocialLinks? socialLinks;
  final String? primaryColor;

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    final trimmedName = name?.trim();
    if (trimmedName != null && trimmedName.isNotEmpty) {
      json['name'] = trimmedName;
    }
    final normalizedWebsite = _normalizeOptionalUrl(websiteUrl);
    if (normalizedWebsite != null) {
      json['websiteUrl'] = normalizedWebsite;
    }
    final trimmedDomain = customDomain?.trim();
    if (trimmedDomain != null && trimmedDomain.isNotEmpty) {
      json['customDomain'] = trimmedDomain;
    }
    if (socialLinks != null) {
      final compact = socialLinks!.toJsonNonEmpty();
      if (compact.isNotEmpty) {
        json['socialLinks'] = compact;
      }
    }
    final trimmedColor = primaryColor?.trim();
    if (trimmedColor != null && trimmedColor.isNotEmpty) {
      json['primaryColor'] = trimmedColor;
    }
    return json;
  }
}

String? _normalizeOptionalUrl(String? value) {
  final raw = value?.trim();
  if (raw == null || raw.isEmpty) return null;
  if (raw.startsWith('http://') || raw.startsWith('https://')) return raw;
  return 'https://$raw';
}

class SuperadminChangePasswordRequest {
  const SuperadminChangePasswordRequest({
    required this.currentPassword,
    required this.newPassword,
  });

  final String currentPassword;
  final String newPassword;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      };
}

// =====================================================================
// White Label
// =====================================================================

class SuperadminWhiteLabelSettings {
  const SuperadminWhiteLabelSettings({
    this.id,
    this.customDomain,
    this.logoLightUrl,
    this.logoDarkUrl,
    this.faviconUrl,
    this.primaryColor,
  });

  final int? id;
  final String? customDomain;
  final String? logoLightUrl;
  final String? logoDarkUrl;
  final String? faviconUrl;
  final String? primaryColor;

  factory SuperadminWhiteLabelSettings.fromJson(dynamic json) {
    final source = _unwrap(json);
    return SuperadminWhiteLabelSettings(
      id: _firstInt(source, const ['id', 'companyId']),
      customDomain: _firstString(source, const ['customDomain', 'domain']),
      logoLightUrl: _firstString(source, const ['logoLightUrl', 'logoLight']),
      logoDarkUrl: _firstString(source, const ['logoDarkUrl', 'logoDark']),
      faviconUrl: _firstString(source, const ['faviconUrl', 'favicon']),
      primaryColor: _firstString(source, const ['primaryColor', 'color']),
    );
  }

  SuperadminWhiteLabelSettings copyWith({
    int? id,
    String? customDomain,
    String? logoLightUrl,
    String? logoDarkUrl,
    String? faviconUrl,
    String? primaryColor,
  }) {
    return SuperadminWhiteLabelSettings(
      id: id ?? this.id,
      customDomain: customDomain ?? this.customDomain,
      logoLightUrl: logoLightUrl ?? this.logoLightUrl,
      logoDarkUrl: logoDarkUrl ?? this.logoDarkUrl,
      faviconUrl: faviconUrl ?? this.faviconUrl,
      primaryColor: primaryColor ?? this.primaryColor,
    );
  }
}

// =====================================================================
// SMTP
// =====================================================================

class SuperadminSmtpSettings {
  const SuperadminSmtpSettings({
    this.id,
    this.senderName,
    this.host,
    this.port,
    this.email,
    this.type = SuperadminSmtpType.none,
    this.username,
    this.password,
    this.replyTo,
    this.isActive = false,
  });

  final int? id;
  final String? senderName;
  final String? host;
  final String? port;
  final String? email;
  final SuperadminSmtpType type;
  final String? username;
  final String? password;
  final String? replyTo;
  final bool isActive;

  factory SuperadminSmtpSettings.fromJson(dynamic json) {
    final source = _unwrap(json);
    return SuperadminSmtpSettings(
      id: _firstInt(source, const ['id']),
      senderName: _firstString(source, const ['senderName', 'fromName']),
      host: _firstString(source, const ['host']),
      port: _firstString(source, const ['port']),
      email: _firstString(source, const ['email']),
      type: SuperadminSmtpType.fromValue(source['type']),
      username: _firstString(source, const ['username', 'user']),
      password: _firstString(source, const ['password']),
      replyTo: _firstString(source, const ['replyTo']),
      isActive: _firstBool(source, const ['isActive', 'active']) ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'senderName': senderName?.trim() ?? '',
      'host': host?.trim() ?? '',
      'port': port?.trim() ?? '',
      'email': email?.trim() ?? '',
      'type': type.apiValue,
      'username': username?.trim() ?? '',
      'password': password ?? '',
      'isActive': isActive ? 'true' : 'false',
    };
    final replyToTrimmed = replyTo?.trim();
    if (replyToTrimmed != null && replyToTrimmed.isNotEmpty) {
      json['replyTo'] = replyToTrimmed;
    }
    return json;
  }

  SuperadminSmtpSettings copyWith({
    int? id,
    String? senderName,
    String? host,
    String? port,
    String? email,
    SuperadminSmtpType? type,
    String? username,
    String? password,
    String? replyTo,
    bool? isActive,
  }) {
    return SuperadminSmtpSettings(
      id: id ?? this.id,
      senderName: senderName ?? this.senderName,
      host: host ?? this.host,
      port: port ?? this.port,
      email: email ?? this.email,
      type: type ?? this.type,
      username: username ?? this.username,
      password: password ?? this.password,
      replyTo: replyTo ?? this.replyTo,
      isActive: isActive ?? this.isActive,
    );
  }
}

// =====================================================================
// Localization
// =====================================================================

class SuperadminLocalizationSettings {
  const SuperadminLocalizationSettings({
    this.language = 'en',
    this.layoutDirection = SuperadminLayoutDirection.ltr,
    this.dateFormat = 'YYYY-MM-DD',
    this.use24Hour = true,
    this.theme = SuperadminTheme.system,
    this.timezoneOffset = '+00:00',
    this.units = SuperadminUnits.km,
    this.defaultLat = 0,
    this.defaultLon = 0,
    this.mapZoom = 10,
  });

  final String language;
  final SuperadminLayoutDirection layoutDirection;
  final String dateFormat;
  final bool use24Hour;
  final SuperadminTheme theme;
  final String timezoneOffset;
  final SuperadminUnits units;
  final double defaultLat;
  final double defaultLon;
  final int mapZoom;

  factory SuperadminLocalizationSettings.fromJson(dynamic json) {
    final source = _unwrap(json);
    return SuperadminLocalizationSettings(
      language: _firstString(source, const ['language', 'lang']) ?? 'en',
      layoutDirection:
          SuperadminLayoutDirection.fromValue(source['layoutDirection']),
      dateFormat:
          _firstString(source, const ['dateFormat']) ?? 'YYYY-MM-DD',
      use24Hour: _firstBool(source, const ['use24Hour']) ?? true,
      theme: SuperadminTheme.fromValue(source['theme']),
      timezoneOffset:
          _firstString(source, const ['timezoneOffset', 'timezone']) ??
              '+00:00',
      units: SuperadminUnits.fromValue(source['units']),
      defaultLat: _firstDouble(source, const ['defaultLat', 'lat']) ?? 0,
      defaultLon: _firstDouble(source, const ['defaultLon', 'lon', 'lng']) ?? 0,
      mapZoom: _firstInt(source, const ['mapZoom', 'zoom']) ?? 10,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'language': language,
        'layoutDirection': layoutDirection.apiValue,
        'dateFormat': dateFormat,
        'use24Hour': use24Hour,
        'theme': theme.apiValue,
        'timezoneOffset': timezoneOffset,
        'units': units.apiValue,
        'defaultLat': defaultLat,
        'defaultLon': defaultLon,
        'mapZoom': mapZoom,
      };

  SuperadminLocalizationSettings copyWith({
    String? language,
    SuperadminLayoutDirection? layoutDirection,
    String? dateFormat,
    bool? use24Hour,
    SuperadminTheme? theme,
    String? timezoneOffset,
    SuperadminUnits? units,
    double? defaultLat,
    double? defaultLon,
    int? mapZoom,
  }) {
    return SuperadminLocalizationSettings(
      language: language ?? this.language,
      layoutDirection: layoutDirection ?? this.layoutDirection,
      dateFormat: dateFormat ?? this.dateFormat,
      use24Hour: use24Hour ?? this.use24Hour,
      theme: theme ?? this.theme,
      timezoneOffset: timezoneOffset ?? this.timezoneOffset,
      units: units ?? this.units,
      defaultLat: defaultLat ?? this.defaultLat,
      defaultLon: defaultLon ?? this.defaultLon,
      mapZoom: mapZoom ?? this.mapZoom,
    );
  }
}

class SuperadminLanguageOption {
  const SuperadminLanguageOption({
    required this.code,
    required this.label,
  });

  final String code;
  final String label;

  factory SuperadminLanguageOption.fromJson(dynamic json) {
    final source = _asMap(json);
    final code = _firstString(source, const ['code', 'value', 'key']) ?? '';
    final label = _firstString(source, const ['label', 'name', 'title']) ?? code;
    return SuperadminLanguageOption(code: code, label: label);
  }

  static List<SuperadminLanguageOption> listFromJson(dynamic json) {
    final list = _extractList(json, keys: const ['languages', 'items', 'data']);
    return list
        .map(SuperadminLanguageOption.fromJson)
        .where((entry) => entry.code.isNotEmpty)
        .toList(growable: false);
  }
}

class SuperadminDateFormatOption {
  const SuperadminDateFormatOption({
    required this.value,
    required this.label,
  });

  final String value;
  final String label;

  factory SuperadminDateFormatOption.fromJson(dynamic json) {
    if (json is String) {
      return SuperadminDateFormatOption(value: json, label: json);
    }
    final source = _asMap(json);
    final value = _firstString(source, const ['value', 'format', 'code']) ?? '';
    final label = _firstString(source, const ['label', 'name', 'title']) ?? value;
    return SuperadminDateFormatOption(value: value, label: label);
  }

  static List<SuperadminDateFormatOption> listFromJson(dynamic json) {
    final list =
        _extractList(json, keys: const ['dateFormats', 'items', 'data']);
    return list
        .map(SuperadminDateFormatOption.fromJson)
        .where((entry) => entry.value.isNotEmpty)
        .toList(growable: false);
  }
}

// =====================================================================
// Software Config
// =====================================================================

class SuperadminSoftwareConfig {
  const SuperadminSoftwareConfig({
    this.geocodingPrecision = SuperadminGeocodingPrecision.twoDigit,
    this.backupDays = 365,
    this.allowDemoLogin = false,
    this.allowSignup = false,
    this.signupCredits = 0,
  });

  final SuperadminGeocodingPrecision geocodingPrecision;
  final int backupDays;
  final bool allowDemoLogin;
  final bool allowSignup;
  final int signupCredits;

  factory SuperadminSoftwareConfig.fromJson(dynamic json) {
    final source = _unwrap(json);
    return SuperadminSoftwareConfig(
      geocodingPrecision: SuperadminGeocodingPrecision.fromValue(
        source['geocodingPrecision'],
      ),
      backupDays: _firstInt(source, const ['backupDays']) ?? 365,
      allowDemoLogin:
          _firstBool(source, const ['allowDemoLogin']) ?? false,
      allowSignup: _firstBool(source, const ['allowSignup']) ?? false,
      signupCredits: _firstInt(source, const ['signupCredits']) ?? 0,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'geocodingPrecision': geocodingPrecision.apiValue,
        'backupDays': backupDays,
        'allowDemoLogin': allowDemoLogin,
        'allowSignup': allowSignup,
        'signupCredits': signupCredits,
      };

  SuperadminSoftwareConfig copyWith({
    SuperadminGeocodingPrecision? geocodingPrecision,
    int? backupDays,
    bool? allowDemoLogin,
    bool? allowSignup,
    int? signupCredits,
  }) {
    return SuperadminSoftwareConfig(
      geocodingPrecision: geocodingPrecision ?? this.geocodingPrecision,
      backupDays: backupDays ?? this.backupDays,
      allowDemoLogin: allowDemoLogin ?? this.allowDemoLogin,
      allowSignup: allowSignup ?? this.allowSignup,
      signupCredits: signupCredits ?? this.signupCredits,
    );
  }
}

// =====================================================================
// Data retention
// =====================================================================

class SuperadminDataRetentionTableResult {
  const SuperadminDataRetentionTableResult({
    this.database,
    this.tableName,
    this.dateColumn,
    this.deletedRows = 0,
    this.olderRows = 0,
    this.failed = false,
    this.errorMessage,
    this.durationMs,
  });

  final String? database;
  final String? tableName;
  final String? dateColumn;
  final int deletedRows;
  final int olderRows;
  final bool failed;
  final String? errorMessage;
  final int? durationMs;

  factory SuperadminDataRetentionTableResult.fromJson(dynamic json) {
    final source = _asMap(json);
    return SuperadminDataRetentionTableResult(
      database: _firstString(source, const ['database', 'db']),
      tableName: _firstString(source, const ['tableName', 'table']),
      dateColumn: _firstString(source, const ['dateColumn', 'column']),
      deletedRows: _firstInt(source, const ['deletedRows', 'deleted']) ?? 0,
      olderRows: _firstInt(source, const ['olderRows', 'older']) ?? 0,
      failed: _firstBool(source, const ['failed']) ?? false,
      errorMessage:
          _firstString(source, const ['errorMessage', 'error', 'message']),
      durationMs: _firstInt(source, const ['durationMs', 'duration']),
    );
  }
}

class SuperadminDataRetentionSummary {
  const SuperadminDataRetentionSummary({
    this.startedAt,
    this.finishedAt,
    this.durationMs,
    this.retentionDays,
    this.cutoff,
    this.dryRun = false,
    this.manual = false,
    this.skipped = false,
    this.skipReason,
    this.tables = const [],
    this.totalDeletedRows = 0,
    this.totalOlderRows = 0,
    this.failedTables = 0,
  });

  final DateTime? startedAt;
  final DateTime? finishedAt;
  final int? durationMs;
  final int? retentionDays;
  final DateTime? cutoff;
  final bool dryRun;
  final bool manual;
  final bool skipped;
  final String? skipReason;
  final List<SuperadminDataRetentionTableResult> tables;
  final int totalDeletedRows;
  final int totalOlderRows;
  final int failedTables;

  factory SuperadminDataRetentionSummary.fromJson(dynamic json) {
    final source = _unwrap(json);
    final tablesList =
        _extractList(source['tables'], keys: const ['tables', 'items']);
    return SuperadminDataRetentionSummary(
      startedAt: _firstDate(source, const ['startedAt', 'started']),
      finishedAt: _firstDate(source, const ['finishedAt', 'finished']),
      durationMs: _firstInt(source, const ['durationMs', 'duration']),
      retentionDays: _firstInt(source, const ['retentionDays']),
      cutoff: _firstDate(source, const ['cutoff']),
      dryRun: _firstBool(source, const ['dryRun']) ?? false,
      manual: _firstBool(source, const ['manual']) ?? false,
      skipped: _firstBool(source, const ['skipped']) ?? false,
      skipReason: _firstString(source, const ['skipReason']),
      tables: tablesList
          .map(SuperadminDataRetentionTableResult.fromJson)
          .toList(growable: false),
      totalDeletedRows: _firstInt(source, const ['totalDeletedRows']) ?? 0,
      totalOlderRows: _firstInt(source, const ['totalOlderRows']) ?? 0,
      failedTables: _firstInt(source, const ['failedTables']) ?? 0,
    );
  }
}

// =====================================================================
// Tolerant parser helpers
// =====================================================================

/// Unwraps an API response that may be:
/// - direct object
/// - `{ data: object }`
/// - `{ data: { data: object } }`
/// - `{ action, message, data }`
Map<String, dynamic> _unwrap(dynamic value) {
  var current = value;
  for (var i = 0; i < 4; i++) {
    if (current is! Map) {
      break;
    }
    final map = _asMap(current);
    if (map.containsKey('data') &&
        (map['data'] is Map || map['data'] is List)) {
      current = map['data'];
      continue;
    }
    return map;
  }
  return _asMap(current);
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

dynamic _firstValue(Map<String, dynamic> source, List<String> keys) {
  for (final key in keys) {
    if (source.containsKey(key) && source[key] != null) {
      return source[key];
    }
  }
  return null;
}

String? _firstString(Map<String, dynamic> source, List<String> keys) {
  final value = _firstValue(source, keys);
  if (value == null) return null;
  final normalized = value.toString().trim();
  return normalized.isEmpty ? null : normalized;
}

int? _firstInt(Map<String, dynamic> source, List<String> keys) {
  final value = _firstValue(source, keys);
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString().trim());
}

double? _firstDouble(Map<String, dynamic> source, List<String> keys) {
  final value = _firstValue(source, keys);
  if (value == null) return null;
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString().trim());
}

bool? _firstBool(Map<String, dynamic> source, List<String> keys) {
  final value = _firstValue(source, keys);
  if (value == null) return null;
  if (value is bool) return value;
  if (value is num) return value != 0;
  final normalized = value.toString().trim().toLowerCase();
  switch (normalized) {
    case 'true':
    case '1':
    case 'yes':
    case 'y':
      return true;
    case 'false':
    case '0':
    case 'no':
    case 'n':
      return false;
  }
  return null;
}

DateTime? _firstDate(Map<String, dynamic> source, List<String> keys) {
  final value = _firstValue(source, keys);
  if (value == null) return null;
  if (value is DateTime) return value;
  final str = value.toString().trim();
  if (str.isEmpty) return null;
  return DateTime.tryParse(str);
}

Map<String, dynamic>? _firstMap(
  Map<String, dynamic> source,
  List<String> keys,
) {
  for (final key in keys) {
    final nested = _asMap(source[key]);
    if (nested.isNotEmpty) {
      return nested;
    }
  }
  return null;
}

List<dynamic> _extractList(
  dynamic source, {
  required List<String> keys,
  int depth = 0,
}) {
  if (source is List) {
    return source;
  }
  if (depth > 4) {
    return const <dynamic>[];
  }
  final map = _asMap(source);
  if (map.isEmpty) {
    return const <dynamic>[];
  }
  for (final key in keys) {
    final value = map[key];
    if (value is List) {
      return value;
    }
  }
  for (final candidate in <dynamic>[
    map['data'],
    map['items'],
    map['rows'],
    map['records'],
    map['result'],
    map['results'],
    map['payload'],
    map['response'],
  ]) {
    if (candidate is List) {
      return candidate;
    }
    if (candidate is Map) {
      final nested = _extractList(candidate, keys: keys, depth: depth + 1);
      if (nested.isNotEmpty) {
        return nested;
      }
    }
  }
  return const <dynamic>[];
}
