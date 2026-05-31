// Models for Superadmin → Administrator details page.
//
// Parsers stay permissive to handle backend/web field-name variants
// (snake_case, camelCase, lower-case keys) that the OpenVTS backend
// returns inconsistently across endpoints.

import 'package:file_picker/file_picker.dart';

// ---------------------------------------------------------------------------
// A. SuperadminAdminDetails
// ---------------------------------------------------------------------------

class SuperadminAdminDetails {
  const SuperadminAdminDetails({
    required this.id,
    required this.name,
    required this.username,
    required this.email,
    required this.mobilePrefix,
    required this.mobileNumber,
    required this.mobileDisplay,
    required this.credits,
    required this.totalVehicles,
    required this.recentLogin,
    required this.isActive,
    required this.hasExplicitActiveStatus,
    required this.isEmailVerified,
    required this.countryCode,
    required this.stateCode,
    required this.cityName,
    required this.pincode,
    required this.organization,
    required this.location,
    required this.createdAt,
    required this.updatedAt,
    required this.companies,
    required this.address,
  });

  final String id;
  final String name;
  final String username;
  final String email;
  final String mobilePrefix;
  final String mobileNumber;
  final String mobileDisplay;
  final int credits;
  final int totalVehicles;
  final DateTime? recentLogin;
  final bool isActive;
  final bool hasExplicitActiveStatus;
  final bool isEmailVerified;
  final String countryCode;
  final String stateCode;
  final String cityName;
  final String pincode;
  final String organization;
  final String location;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<SuperadminAdminCompany> companies;
  final SuperadminAdminAddress? address;

  static const Object _unset = Object();

  factory SuperadminAdminDetails.fromJson(dynamic json) {
    final root = _asMap(json);
    final source = _firstMap(root, const [
          'data',
          'admin',
          'user',
          'profile',
          'result',
        ]) ??
        root;

    final companiesList = _firstList(source, const [
          'companies',
          'companyList',
          'company_list',
        ]) ??
        const <dynamic>[];

    final companies = companiesList
        .map(_asMap)
        .where((m) => m.isNotEmpty)
        .map(SuperadminAdminCompany.fromJson)
        .toList(growable: false);

    final addressMap = _firstMap(source, const ['address', 'fullAddress']);
    final addressFromObject =
        addressMap == null ? null : SuperadminAdminAddress.fromJson(addressMap);

    final mobilePrefix = _firstString(source, const [
          'mobilePrefix',
          'mobile_prefix',
          'mobileprefix',
          'phonePrefix',
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
    final mobileDisplay =
        _firstString(source, const ['mobileDisplay', 'mobile_display']) ??
            _composePhone(mobilePrefix, mobileNumber);

    return SuperadminAdminDetails(
      id: _firstString(source, const [
            'uid',
            'id',
            '_id',
            'adminId',
            'adminid',
            'admin_id',
            'userId',
            'user_id',
          ]) ??
          '',
      name: _firstString(source, const [
            'Name',
            'name',
            'fullName',
            'full_name',
            'displayName',
            'adminName',
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
          ]) ??
          '',
      mobilePrefix: mobilePrefix,
      mobileNumber: mobileNumber,
      mobileDisplay: mobileDisplay,
      credits: _firstInt(source, const [
            'credits',
            'credit',
            'availableCredits',
            'creditBalance',
          ]) ??
          0,
      totalVehicles: _firstInt(source, const [
            'totalvehicles',
            'totalVehicles',
            'vehicleCount',
            'vehiclesCount',
            'total_vehicles',
            'total_vehicle',
            'totalVehicle',
          ]) ??
          _firstInt(
            _firstMap(source, const ['_count']) ?? const <String, dynamic>{},
            const ['vehicles'],
          ) ??
          _listLength(source, 'vehicles') ??
          -1,
      recentLogin: _firstDate(source, const [
        'Lastlogin',
        'lastLogin',
        'last_login',
        'lastlogin',
        'lastLoggedIn',
        'last_logged_in',
        'lastLoginAt',
        'lastLoggedInAt',
        'last_logged_in_at',
        'last_login_at',
        'recentLogin',
        'recent_login',
        'loginAt',
        'login_at',
        'lastSeenAt',
        'last_seen_at',
        'lastSeen',
        'last_seen',
        'lastSeenOn',
        'last_seen_on',
        'loggedInAt',
        'logged_in_at',
        'loginDate',
        'login_date',
        'loginTime',
        'login_time',
        'lastActivityAt',
        'last_activity_at',
      ]),
      isActive: _parseBool(
            source['isActive'] ??
                source['is_active'] ??
                source['isactive'] ??
                source['active'] ??
                source['status'] ??
                source['accountStatus'] ??
                source['account_status'],
          ) ??
          false,
      hasExplicitActiveStatus: _parseBool(
            source['isActive'] ??
                source['is_active'] ??
                source['isactive'] ??
                source['active'] ??
                source['status'] ??
                source['accountStatus'] ??
                source['account_status'],
          ) !=
          null,
      isEmailVerified: _parseBool(
            source['isEmailVerified'] ??
                source['isemailvarified'] ??
                source['isemailverified'] ??
                source['is_email_verified'] ??
                source['emailVerified'] ??
                source['email_verified'],
          ) ??
          false,
      countryCode: (_firstString(source, const [
                'countrycode',
                'countryCode',
                'country_code',
                'country',
              ]) ??
              '')
          .toUpperCase(),
      stateCode: _firstString(
              source, const ['stateCode', 'state_code', 'statecode']) ??
          '',
      cityName: _firstString(source, const [
            'cityName',
            'city_name',
            'cityname',
            'city',
          ]) ??
          '',
      pincode: _firstString(source, const [
            'pincode',
            'postalCode',
            'postal_code',
            'zip',
            'zipCode',
          ]) ??
          '',
      organization: _firstString(source, const [
            'companyName',
            'company_name',
            'companyname',
            'company',
            'organization',
            'organisation',
          ]) ??
          '',
      location: _firstString(source, const [
            'fulladdress',
            'fullAddress',
            'location',
            'addressLine',
            'address_line',
          ]) ??
          '',
      createdAt: _firstDate(source, const ['createdAt', 'created_at']),
      updatedAt: _firstDate(source, const ['updatedAt', 'updated_at']),
      companies: companies,
      address: addressFromObject,
    );
  }

  SuperadminAdminDetails copyWith({
    bool? isActive,
    bool? hasExplicitActiveStatus,
    int? totalVehicles,
    Object? recentLogin = _unset,
  }) {
    return SuperadminAdminDetails(
      id: id,
      name: name,
      username: username,
      email: email,
      mobilePrefix: mobilePrefix,
      mobileNumber: mobileNumber,
      mobileDisplay: mobileDisplay,
      credits: credits,
      totalVehicles: totalVehicles ?? this.totalVehicles,
      recentLogin: identical(recentLogin, _unset)
          ? this.recentLogin
          : recentLogin as DateTime?,
      isActive: isActive ?? this.isActive,
      hasExplicitActiveStatus:
          hasExplicitActiveStatus ?? this.hasExplicitActiveStatus,
      isEmailVerified: isEmailVerified,
      countryCode: countryCode,
      stateCode: stateCode,
      cityName: cityName,
      pincode: pincode,
      organization: organization,
      location: location,
      createdAt: createdAt,
      updatedAt: updatedAt,
      companies: companies,
      address: address,
    );
  }
}

// ---------------------------------------------------------------------------
// B. SuperadminAdminCompany
// ---------------------------------------------------------------------------

class SuperadminAdminCompany {
  const SuperadminAdminCompany({
    required this.id,
    required this.name,
    required this.websiteUrl,
    required this.customDomain,
    required this.socialLinks,
    required this.logoLightUrl,
    required this.logoDarkUrl,
    required this.faviconUrl,
    required this.primaryColor,
  });

  final String id;
  final String name;
  final String websiteUrl;
  final String customDomain;
  final Map<String, String> socialLinks;
  final String logoLightUrl;
  final String logoDarkUrl;
  final String faviconUrl;
  final String primaryColor;

  factory SuperadminAdminCompany.fromJson(dynamic json) {
    final source = _asMap(json);
    final social = _firstMap(source, const ['socialLinks', 'social_links']) ??
        const <String, dynamic>{};

    final normalizedSocial = <String, String>{};
    social.forEach((key, value) {
      final v = value?.toString().trim();
      if (v == null || v.isEmpty) return;
      normalizedSocial[key.toString()] = v;
    });

    return SuperadminAdminCompany(
      id: _firstString(source, const ['id', '_id', 'companyId']) ?? '',
      name: _firstString(source, const ['name', 'companyName']) ?? '',
      websiteUrl: _firstString(source, const [
            'websiteUrl',
            'website_url',
            'website',
          ]) ??
          '',
      customDomain: _firstString(source, const [
            'customDomain',
            'custom_domain',
            'domain',
          ]) ??
          '',
      socialLinks: normalizedSocial,
      logoLightUrl: _firstString(source, const [
            'logoLightUrl',
            'logo_light_url',
            'logoLight',
            'logo_light',
          ]) ??
          '',
      logoDarkUrl: _firstString(source, const [
            'logoDarkUrl',
            'logo_dark_url',
            'logoDark',
            'logo_dark',
          ]) ??
          '',
      faviconUrl: _firstString(source, const [
            'faviconUrl',
            'favicon_url',
            'favicon',
          ]) ??
          '',
      primaryColor: _firstString(source, const [
            'primaryColor',
            'primary_color',
            'color',
          ]) ??
          '',
    );
  }
}

// ---------------------------------------------------------------------------
// C. SuperadminAdminAddress
// ---------------------------------------------------------------------------

class SuperadminAdminAddress {
  const SuperadminAdminAddress({
    required this.id,
    required this.addressLine,
    required this.countryCode,
    required this.stateCode,
    required this.cityId,
    required this.cityName,
    required this.pincode,
    required this.fullAddress,
  });

  final String id;
  final String addressLine;
  final String countryCode;
  final String stateCode;
  final String cityId;
  final String cityName;
  final String pincode;
  final String fullAddress;

  factory SuperadminAdminAddress.fromJson(dynamic json) {
    final source = _asMap(json);
    return SuperadminAdminAddress(
      id: _firstString(source, const ['id', '_id', 'addressId']) ?? '',
      addressLine: _firstString(source, const [
            'addressLine',
            'address_line',
            'address',
            'line1',
          ]) ??
          '',
      countryCode: (_firstString(source, const [
                'countryCode',
                'country_code',
                'country',
              ]) ??
              '')
          .toUpperCase(),
      stateCode:
          _firstString(source, const ['stateCode', 'state_code', 'state']) ??
              '',
      cityId: _firstString(source, const [
            'cityId',
            'city_id',
            'cityName',
            'city_name',
            'city',
          ]) ??
          '',
      cityName: _firstString(source, const [
            'cityName',
            'city_name',
            'city',
            'cityId',
            'city_id',
          ]) ??
          '',
      pincode: _firstString(source, const [
            'pincode',
            'postalCode',
            'postal_code',
            'zip',
          ]) ??
          '',
      fullAddress: _firstString(source, const [
            'fullAddress',
            'full_address',
            'fulladdress',
          ]) ??
          '',
    );
  }
}

// ---------------------------------------------------------------------------
// D. SuperadminUpdateAdminRequest
// ---------------------------------------------------------------------------

class SuperadminUpdateAdminRequest {
  const SuperadminUpdateAdminRequest({
    required this.name,
    required this.email,
    required this.mobilePrefix,
    required this.mobileNumber,
    required this.addressLine,
    required this.countryCode,
    required this.stateCode,
    required this.cityName,
    required this.pincode,
  });

  final String name;
  final String email;
  final String mobilePrefix;
  final String mobileNumber;
  final String addressLine;
  final String countryCode;
  final String stateCode;
  final String cityName;
  final String pincode;

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'name': name.trim(),
      'mobilePrefix': mobilePrefix.trim(),
      'mobileNumber': mobileNumber.trim(),
      'addressLine': addressLine.trim(),
      'countryCode': countryCode.trim().toUpperCase(),
      'stateCode': stateCode.trim(),
      'cityName': cityName.trim(),
    };

    void addIfNotEmpty(String key, String value) {
      final v = value.trim();
      if (v.isNotEmpty) json[key] = v;
    }

    addIfNotEmpty('email', email);
    addIfNotEmpty('pincode', pincode);

    return json;
  }
}

// ---------------------------------------------------------------------------
// E. SuperadminAdminPasswordUpdateRequest
// ---------------------------------------------------------------------------

class SuperadminAdminPasswordUpdateRequest {
  const SuperadminAdminPasswordUpdateRequest({
    required this.adminId,
    required this.newPassword,
    required this.confirmPassword,
  });

  final String adminId;
  final String newPassword;
  final String confirmPassword;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'adminid': adminId.trim(),
      'newpassword': newPassword.trim(),
      'confirmpassword': confirmPassword.trim(),
    };
  }
}

// ---------------------------------------------------------------------------
// F. SuperadminAdminCompanyUpdateRequest
// ---------------------------------------------------------------------------

class SuperadminAdminCompanyUpdateRequest {
  const SuperadminAdminCompanyUpdateRequest({
    required this.name,
    required this.websiteUrl,
    required this.customDomain,
    required this.socialLinks,
    required this.primaryColor,
  });

  final String name;
  final String websiteUrl;
  final String customDomain;
  final Map<String, String> socialLinks;
  final String primaryColor;

  Map<String, dynamic> toJson() {
    final social = <String, String>{};
    socialLinks.forEach((key, value) {
      final normalizedKey = key.trim();
      final normalized = value.trim();
      if (normalizedKey.isEmpty || normalized.isEmpty) return;
      social[normalizedKey] = normalized;
    });

    final payload = <String, dynamic>{
      'name': name.trim(),
    };

    final trimmedWebsite = websiteUrl.trim();
    if (trimmedWebsite.isNotEmpty) payload['websiteUrl'] = trimmedWebsite;

    final trimmedDomain = customDomain.trim();
    if (trimmedDomain.isNotEmpty) payload['customDomain'] = trimmedDomain;

    if (social.isNotEmpty) payload['socialLinks'] = social;

    final trimmedColor = primaryColor.trim();
    if (trimmedColor.isNotEmpty) payload['primaryColor'] = trimmedColor;

    return payload;
  }
}

// ---------------------------------------------------------------------------
// G. SuperadminCreditLog
// ---------------------------------------------------------------------------

enum SuperadminCreditActivity { assign, deduct, unknown }

extension SuperadminCreditActivityX on SuperadminCreditActivity {
  String get apiValue {
    switch (this) {
      case SuperadminCreditActivity.assign:
        return 'ASSIGN';
      case SuperadminCreditActivity.deduct:
        return 'DEDUCT';
      case SuperadminCreditActivity.unknown:
        return '';
    }
  }

  String get label {
    switch (this) {
      case SuperadminCreditActivity.assign:
        return 'Assigned';
      case SuperadminCreditActivity.deduct:
        return 'Deducted';
      case SuperadminCreditActivity.unknown:
        return 'Unknown';
    }
  }
}

SuperadminCreditActivity _parseCreditActivity(dynamic value) {
  final normalized = value?.toString().trim().toUpperCase() ?? '';
  switch (normalized) {
    case 'ASSIGN':
    case 'ADD':
    case 'CREDIT':
      return SuperadminCreditActivity.assign;
    case 'DEDUCT':
    case 'DEBIT':
    case 'REMOVE':
      return SuperadminCreditActivity.deduct;
    default:
      return SuperadminCreditActivity.unknown;
  }
}

class SuperadminCreditLog {
  const SuperadminCreditLog({
    required this.id,
    required this.adminUserId,
    required this.credits,
    required this.activity,
    required this.vehicleId,
    required this.createdAt,
  });

  final String id;
  final String adminUserId;
  final int credits;
  final SuperadminCreditActivity activity;
  final String vehicleId;
  final DateTime? createdAt;

  factory SuperadminCreditLog.fromJson(dynamic json) {
    final source = _asMap(json);
    return SuperadminCreditLog(
      id: _firstString(source, const ['id', '_id', 'logId']) ?? '',
      adminUserId: _firstString(source, const [
            'adminUserId',
            'admin_user_id',
            'adminId',
            'adminid',
          ]) ??
          '',
      credits: _firstInt(source, const ['credits', 'credit', 'amount']) ?? 0,
      activity: _parseCreditActivity(
        source['activity'] ?? source['type'] ?? source['action'],
      ),
      vehicleId: _firstString(source, const [
            'vehicleId',
            'vehicle_id',
            'vehicleid',
          ]) ??
          '',
      createdAt: _firstDate(source, const ['createdAt', 'created_at', 'date']),
    );
  }

  static List<SuperadminCreditLog> listFromJson(dynamic json) {
    return _extractList(json)
        .map(_asMap)
        .where((m) => m.isNotEmpty)
        .map(SuperadminCreditLog.fromJson)
        .toList(growable: false);
  }
}

// ---------------------------------------------------------------------------
// H. SuperadminCreditUpdateRequest
// ---------------------------------------------------------------------------

class SuperadminCreditUpdateRequest {
  const SuperadminCreditUpdateRequest({
    required this.credits,
    required this.activity,
  });

  final String credits;
  final SuperadminCreditActivity activity;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'credits': credits.trim(),
      'activity': activity.apiValue,
    };
  }
}

// ---------------------------------------------------------------------------
// I. SuperadminAdminVehicle
// ---------------------------------------------------------------------------

class SuperadminAdminVehicle {
  const SuperadminAdminVehicle({
    required this.id,
    required this.name,
    required this.imei,
    required this.simNumber,
    required this.isLicenseBlocked,
    required this.licenseBlockedAt,
    required this.licenseBlockReason,
    required this.vehicleTypeName,
    required this.vehicleTypeSlug,
    required this.primaryExpiry,
    required this.gmtOffset,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String imei;
  final String simNumber;
  final bool isLicenseBlocked;
  final DateTime? licenseBlockedAt;
  final String licenseBlockReason;
  final String vehicleTypeName;
  final String vehicleTypeSlug;
  final DateTime? primaryExpiry;
  final String gmtOffset;
  final DateTime? createdAt;

  factory SuperadminAdminVehicle.fromJson(dynamic json) {
    final source = _asMap(json);
    final vehicleType =
        _firstMap(source, const ['vehicleType', 'vehicle_type', 'type']) ??
            const <String, dynamic>{};

    return SuperadminAdminVehicle(
      id: _firstString(source, const [
            'id',
            '_id',
            'uid',
            'vehicleId',
            'vehicle_id',
          ]) ??
          '',
      name: _firstString(source, const ['name', 'vehicleName']) ?? '',
      imei: _firstString(source, const [
            'imei',
            'IMEI',
            'deviceImei',
            'device_imei',
            'deviceId',
          ]) ??
          '',
      simNumber: _firstString(source, const [
            'simNumber',
            'sim_number',
            'simno',
            'simNo',
            'sim',
          ]) ??
          '',
      isLicenseBlocked: _parseBool(
            source['isLicenseBlocked'] ??
                source['is_license_blocked'] ??
                source['licenseBlocked'] ??
                source['is_blocked'],
          ) ??
          false,
      licenseBlockedAt: _firstDate(source, const [
        'licenseBlockedAt',
        'license_blocked_at',
        'blockedAt',
      ]),
      licenseBlockReason: _firstString(source, const [
            'licenseBlockReason',
            'license_block_reason',
            'blockReason',
            'reason',
          ]) ??
          '',
      vehicleTypeName: _firstString(source, const [
            'vehicleTypeName',
            'vehicle_type_name',
          ]) ??
          _firstString(vehicleType, const ['name', 'label']) ??
          '',
      vehicleTypeSlug: _firstString(source, const [
            'vehicleTypeSlug',
            'vehicle_type_slug',
          ]) ??
          _firstString(vehicleType, const ['slug', 'code']) ??
          '',
      primaryExpiry: _firstDate(source, const [
        'primaryExpiry',
        'primary_expiry',
        'expiryAt',
        'expiry_at',
        'expiry',
        'licenseExpiry',
        'license_expiry',
      ]),
      gmtOffset: _firstString(source, const [
            'gmtOffset',
            'gmt_offset',
            'timezoneOffset',
          ]) ??
          '',
      createdAt: _firstDate(source, const ['createdAt', 'created_at']),
    );
  }

  static List<SuperadminAdminVehicle> listFromJson(dynamic json) {
    return _extractList(
      json,
      preferredKeys: const [
        'data',
        'items',
        'vehicles',
        'rows',
        'result',
        'records',
        'list',
        'results',
      ],
    )
        .map(_asMap)
        .where((m) => m.isNotEmpty)
        .map(SuperadminAdminVehicle.fromJson)
        .toList(growable: false);
  }
}

// ---------------------------------------------------------------------------
// J. SuperadminAdminDocument
// ---------------------------------------------------------------------------

class SuperadminAdminDocument {
  const SuperadminAdminDocument({
    required this.id,
    required this.title,
    required this.docTypeId,
    required this.docTypeName,
    required this.description,
    required this.tags,
    required this.associateType,
    required this.fileName,
    required this.fileType,
    required this.filePath,
    required this.fileUrl,
    required this.createdAt,
    required this.expiryAt,
    required this.isVisible,
  });

  final String id;
  final String title;
  final String docTypeId;
  final String docTypeName;
  final String description;
  final List<String> tags;
  final String associateType;
  final String fileName;
  final String fileType;
  final String filePath;
  final String fileUrl;
  final DateTime? createdAt;
  final DateTime? expiryAt;
  final bool isVisible;

  factory SuperadminAdminDocument.fromJson(dynamic json) {
    final source = _asMap(json);
    final docType =
        _firstMap(source, const ['docType', 'doc_type', 'documentType']) ??
            const <String, dynamic>{};

    final rawTags = source['tags'] ?? source['tagList'];
    final tags = <String>[];
    if (rawTags is List) {
      for (final tag in rawTags) {
        final v = tag?.toString().trim();
        if (v != null && v.isNotEmpty) tags.add(v);
      }
    } else if (rawTags is String) {
      for (final tag in rawTags.split(',')) {
        final v = tag.trim();
        if (v.isNotEmpty) tags.add(v);
      }
    }

    return SuperadminAdminDocument(
      id: _firstString(source, const ['id', '_id', 'docId']) ?? '',
      title: _firstString(source, const ['title', 'name']) ?? '',
      docTypeId: _firstString(source, const [
            'docTypeId',
            'doc_type_id',
            'documentTypeId',
          ]) ??
          _firstString(docType, const ['id', '_id']) ??
          '',
      docTypeName: _firstString(source, const [
            'docTypeName',
            'doc_type_name',
            'documentTypeName',
          ]) ??
          _firstString(docType, const ['name', 'label']) ??
          '',
      description: _firstString(source, const ['description', 'desc']) ?? '',
      tags: tags,
      associateType: _firstString(source, const [
            'AssociateType',
            'associateType',
            'associate_type',
          ]) ??
          '',
      fileName: _firstString(source, const ['fileName', 'file_name']) ?? '',
      fileType:
          _firstString(source, const ['fileType', 'file_type', 'mime']) ?? '',
      filePath:
          _firstString(source, const ['filePath', 'file_path', 'path']) ?? '',
      fileUrl: _firstString(source, const ['fileUrl', 'file_url', 'url']) ?? '',
      createdAt: _firstDate(source, const ['createdAt', 'created_at']),
      expiryAt: _firstDate(source, const ['expiryAt', 'expiry_at', 'expiry']),
      isVisible: _parseBool(
            source['isVisible'] ?? source['is_visible'] ?? source['visible'],
          ) ??
          true,
    );
  }

  static List<SuperadminAdminDocument> listFromJson(dynamic json) {
    return _extractList(
      json,
      preferredKeys: const ['documents', 'docs', 'items', 'rows', 'data'],
    )
        .map(_asMap)
        .where((m) => m.isNotEmpty)
        .map(SuperadminAdminDocument.fromJson)
        .toList(growable: false);
  }
}

// ---------------------------------------------------------------------------
// K. SuperadminDocumentTypeOption
// ---------------------------------------------------------------------------

class SuperadminDocumentTypeOption {
  const SuperadminDocumentTypeOption({
    required this.id,
    required this.name,
    required this.docFor,
  });

  final String id;
  final String name;
  final String docFor;

  bool get isForUser => docFor.trim().toUpperCase() == 'USER';

  factory SuperadminDocumentTypeOption.fromJson(dynamic json) {
    final source = _asMap(json);
    final normalizedDocFor = (_firstString(source, const [
              'docFor',
              'doc_for',
              'typeFor',
              'type_for',
              'associateType',
              'associate_type',
              'targetType',
              'target_type',
              'for',
            ]) ??
            '')
        .toUpperCase();
    return SuperadminDocumentTypeOption(
      id: _firstString(source, const ['id', '_id', 'typeId']) ?? '',
      name: _firstString(source, const ['name', 'label', 'title']) ?? '',
      docFor: normalizedDocFor,
    );
  }

  static List<SuperadminDocumentTypeOption> listFromJson(dynamic json) {
    return _extractList(
      json,
      preferredKeys: const [
        'documentTypes',
        'documenttypes',
        'types',
        'items',
        'rows',
        'data',
      ],
    )
        .map(_asMap)
        .where((m) => m.isNotEmpty)
        .map(SuperadminDocumentTypeOption.fromJson)
        .toList(growable: false);
  }
}

// ---------------------------------------------------------------------------
// Document upload/edit request (shared by uploadDoc / uploadDocById)
// ---------------------------------------------------------------------------

class SuperadminAdminDocumentRequest {
  const SuperadminAdminDocumentRequest({
    required this.title,
    required this.docTypeId,
    required this.associateId,
    required this.isVisible,
    required this.tags,
    required this.description,
    required this.expiryAt,
    required this.file,
  });

  final String title;
  final String docTypeId;
  final String associateId;
  final bool isVisible;
  final List<String> tags;
  final String description;
  final String? expiryAt;
  final PlatformFile? file;
}

// ---------------------------------------------------------------------------
// L. SuperadminAdminActivityLogPage
// ---------------------------------------------------------------------------

class SuperadminAdminActivityLogPage {
  const SuperadminAdminActivityLogPage({
    required this.items,
    required this.nextCursorId,
    required this.hasMore,
    required this.admin,
  });

  final List<SuperadminAdminActivityLog> items;
  final int? nextCursorId;
  final bool hasMore;
  final SuperadminAdminActivityLogUser? admin;

  factory SuperadminAdminActivityLogPage.fromJson(dynamic json) {
    final root = _asMap(json);
    final source = _firstMap(root, const ['data', 'result']) ?? root;

    final listSource = _firstList(source, const [
          'items',
          'logs',
          'activities',
          'rows',
          'result',
        ]) ??
        (source.containsKey('data') && source['data'] is List
            ? source['data'] as List
            : const <dynamic>[]);

    final items = listSource
        .map(_asMap)
        .where((m) => m.isNotEmpty)
        .map(SuperadminAdminActivityLog.fromJson)
        .toList(growable: false);

    final adminMap = _firstMap(source, const ['admin', 'user']);

    return SuperadminAdminActivityLogPage(
      items: items,
      nextCursorId: _firstInt(source, const [
        'nextCursorId',
        'next_cursor_id',
        'nextCursor',
        'next_cursor',
        'cursorId',
        'cursor_id',
        'cursor',
      ]),
      hasMore: _parseBool(
            source['hasMore'] ?? source['has_more'] ?? source['hasNext'],
          ) ??
          false,
      admin: adminMap == null
          ? null
          : SuperadminAdminActivityLogUser.fromJson(adminMap),
    );
  }
}

// ---------------------------------------------------------------------------
// M. SuperadminAdminActivityLog
// ---------------------------------------------------------------------------

class SuperadminAdminActivityLog {
  const SuperadminAdminActivityLog({
    required this.id,
    required this.action,
    required this.entity,
    required this.entityId,
    required this.meta,
    required this.ip,
    required this.browser,
    required this.platform,
    required this.createdAt,
    required this.user,
  });

  final int id;
  final String action;
  final String entity;
  final String entityId;
  final Map<String, dynamic> meta;
  final String ip;
  final String browser;
  final String platform;
  final DateTime? createdAt;
  final SuperadminAdminActivityLogUser? user;

  factory SuperadminAdminActivityLog.fromJson(dynamic json) {
    final source = _asMap(json);
    final metaRaw = source['meta'] ?? source['metadata'];
    final meta = metaRaw is Map ? _asMap(metaRaw) : const <String, dynamic>{};
    final userMap = _firstMap(source, const ['user', 'admin', 'actor']);

    return SuperadminAdminActivityLog(
      id: _firstInt(source, const ['id', '_id', 'logId']) ?? 0,
      action: _firstString(source, const ['action', 'event']) ?? '',
      entity: _firstString(source, const ['entity', 'target']) ?? '',
      entityId:
          _firstString(source, const ['entityId', 'entity_id', 'targetId']) ??
              '',
      meta: meta,
      ip: _firstString(source, const ['ip', 'ipAddress', 'ip_address']) ?? '',
      browser: _firstString(source, const ['browser', 'userAgent']) ?? '',
      platform: _firstString(source, const ['platform', 'os']) ?? '',
      createdAt: _firstDate(source, const ['createdAt', 'created_at', 'date']),
      user: userMap == null
          ? null
          : SuperadminAdminActivityLogUser.fromJson(userMap),
    );
  }
}

class SuperadminAdminActivityLogUser {
  const SuperadminAdminActivityLogUser({
    required this.id,
    required this.name,
    required this.email,
  });

  final String id;
  final String name;
  final String email;

  factory SuperadminAdminActivityLogUser.fromJson(dynamic json) {
    final source = _asMap(json);
    return SuperadminAdminActivityLogUser(
      id: _firstString(source, const ['id', '_id', 'uid']) ?? '',
      name:
          _firstString(source, const ['name', 'fullName', 'displayName']) ?? '',
      email: _firstString(source, const ['email', 'mail']) ?? '',
    );
  }
}

// ---------------------------------------------------------------------------
// Internal helpers (shared by parsers in this file).
// ---------------------------------------------------------------------------

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, item) => MapEntry(key.toString(), item));
  }
  return const <String, dynamic>{};
}

List<dynamic> _extractList(
  dynamic json, {
  List<String> preferredKeys = const [
    'data',
    'items',
    'rows',
    'records',
    'docs',
    'list',
    'results',
    'logs',
  ],
}) {
  if (json is List) return json;
  final map = _asMap(json);
  for (final key in preferredKeys) {
    final value = _valueForKey(map, key);
    if (value is List) return value;
    if (value is Iterable) return value.toList(growable: false);
  }
  for (final key in const ['data', 'result', 'payload', 'response']) {
    final nested = _valueForKey(map, key);
    if (nested == null || identical(nested, json)) continue;
    final extracted = _extractList(nested, preferredKeys: preferredKeys);
    if (extracted.isNotEmpty) return extracted;
  }
  return const <dynamic>[];
}

dynamic _valueForKey(Map<String, dynamic> json, String key) {
  if (json.containsKey(key)) return json[key];
  final normalizedKey = key.toLowerCase();
  for (final entry in json.entries) {
    if (entry.key.toLowerCase() == normalizedKey) return entry.value;
  }
  return null;
}

Map<String, dynamic>? _firstMap(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = _valueForKey(json, key);
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((k, v) => MapEntry(k.toString(), v));
    }
  }
  return null;
}

List<dynamic>? _firstList(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = _valueForKey(json, key);
    if (value is List) return value;
    if (value is Iterable) return value.toList(growable: false);
  }
  return null;
}

String? _firstString(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = _valueForKey(json, key);
    final normalized = value?.toString().trim();
    if (normalized != null && normalized.isNotEmpty) return normalized;
  }
  return null;
}

int? _firstInt(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = _valueForKey(json, key);
    if (value is int) return value;
    if (value is num) return value.toInt();
    final normalized = value?.toString().trim();
    if (normalized == null || normalized.isEmpty) continue;
    final parsed = int.tryParse(normalized);
    if (parsed != null) return parsed;
    final parsedDouble = double.tryParse(normalized);
    if (parsedDouble != null) return parsedDouble.toInt();
  }
  return null;
}

int? _listLength(Map<String, dynamic> json, String key) {
  final value = _valueForKey(json, key);
  if (value is List) return value.length;
  return null;
}

DateTime? _firstDate(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = _valueForKey(json, key);
    final parsed = _parseDate(value);
    if (parsed != null) return parsed;
  }
  return null;
}

DateTime? _parseDate(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value.toLocal();
  if (value is num) {
    final ms = value.toInt();
    if (ms == 0) return null;
    final isSeconds = ms < 100000000000;
    return DateTime.fromMillisecondsSinceEpoch(
      isSeconds ? ms * 1000 : ms,
      isUtc: true,
    ).toLocal();
  }
  final normalized = value.toString().trim();
  if (normalized.isEmpty) return null;
  return DateTime.tryParse(normalized)?.toLocal();
}

bool? _parseBool(dynamic value) {
  if (value == null) return null;
  if (value is bool) return value;
  if (value is num) return value != 0;
  final normalized = value.toString().trim().toLowerCase();
  switch (normalized) {
    case 'true':
    case '1':
    case 'yes':
    case 'y':
    case 'active':
    case 'enabled':
      return true;
    case 'false':
    case '0':
    case 'no':
    case 'n':
    case 'inactive':
    case 'disabled':
    case 'blocked':
      return false;
  }
  return null;
}

String _composePhone(String prefix, String number) {
  final p = prefix.trim();
  final n = number.trim();
  if (p.isEmpty && n.isEmpty) return '';
  if (p.isEmpty) return n;
  if (n.isEmpty) return p;
  return '$p $n';
}
