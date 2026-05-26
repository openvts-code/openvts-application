import 'dart:convert';

import 'package:file_picker/file_picker.dart';

class AdminUserDetails {
  const AdminUserDetails({
    required this.id,
    required this.name,
    required this.username,
    required this.email,
    required this.mobilePrefix,
    required this.mobileNumber,
    required this.mobileDisplay,
    required this.isEmailVerified,
    required this.isActive,
    required this.organization,
    required this.location,
    required this.countryCode,
    required this.vehicleCount,
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
  final bool isEmailVerified;
  final bool isActive;
  final String organization;
  final String location;
  final String countryCode;
  final int vehicleCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<AdminUserCompany> companies;
  final AdminUserAddress? address;

  factory AdminUserDetails.fromJson(dynamic json, {String? fallbackId}) {
    final source = _extractMapPayload(
      json,
      preferredKeys: const [
        'user',
        'adminUser',
        'details',
        'profile',
        'result',
        'item',
      ],
    );
    final companyMaps = _firstList(source, const [
          'companies',
          'companyList',
          'company_list',
        ]) ??
        const <dynamic>[];
    final companies = companyMaps
        .map(AdminUserCompany.fromJson)
        .where((item) => item.hasContent)
        .toList(growable: false);
    final firstCompany = companies.isEmpty ? null : companies.first;
    final addressMap = _firstMap(source, const ['address', 'userAddress']);
    final address =
        addressMap == null ? null : AdminUserAddress.fromJson(addressMap);

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

    final organization = _firstString(source, const [
          'organization',
          'organisation',
          'companyName',
          'company_name',
          'company',
          'businessName',
          'business_name',
        ]) ??
        firstCompany?.name ??
        '';

    final location =
        _firstString(addressMap ?? const <String, dynamic>{}, const [
              'fullAddress',
              'full_address',
              'fulladdress',
              'addressLine',
              'address_line',
            ]) ??
            _firstString(source, const [
              'location',
              'fullAddress',
              'full_address',
              'addressLine',
              'address_line',
              'address',
            ]) ??
            '';

    return AdminUserDetails(
      id: _firstString(source, const [
            'uid',
            'id',
            '_id',
            'userId',
            'user_id',
          ]) ??
          fallbackId ??
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
      isEmailVerified: _parseBool(_firstValue(source, const [
            'isEmailVerified',
            'is_email_verified',
            'isemailvarified',
            'isEmailVarified',
            'isemailverified',
            'emailVerified',
            'email_verified',
            'verified',
            'isVerified',
            'is_verified',
          ])) ??
          false,
      isActive: _parseBool(_firstValue(source, const [
            'isActive',
            'is_active',
            'isactive',
            'active',
            'status',
          ])) ??
          true,
      organization: organization,
      location: location,
      countryCode: (_firstString(source, const [
                'countryCode',
                'country_code',
                'countrycode',
                'country',
              ]) ??
              address?.countryCode ??
              '')
          .toUpperCase(),
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
      companies: companies,
      address: address,
    );
  }

  AdminUserDetails copyWith({
    bool? isActive,
    int? vehicleCount,
    AdminUserAddress? address,
    List<AdminUserCompany>? companies,
  }) {
    return AdminUserDetails(
      id: id,
      name: name,
      username: username,
      email: email,
      mobilePrefix: mobilePrefix,
      mobileNumber: mobileNumber,
      mobileDisplay: mobileDisplay,
      isEmailVerified: isEmailVerified,
      isActive: isActive ?? this.isActive,
      organization: organization,
      location: location,
      countryCode: countryCode,
      vehicleCount: vehicleCount ?? this.vehicleCount,
      createdAt: createdAt,
      updatedAt: updatedAt,
      companies: companies ?? this.companies,
      address: address ?? this.address,
    );
  }
}

class AdminUserCompany {
  const AdminUserCompany({
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

  bool get hasContent =>
      id.isNotEmpty ||
      name.isNotEmpty ||
      websiteUrl.isNotEmpty ||
      customDomain.isNotEmpty ||
      socialLinks.isNotEmpty ||
      logoLightUrl.isNotEmpty ||
      logoDarkUrl.isNotEmpty ||
      faviconUrl.isNotEmpty ||
      primaryColor.isNotEmpty;

  factory AdminUserCompany.fromJson(dynamic json) {
    final source = _extractMapPayload(
      json,
      preferredKeys: const ['company', 'details', 'result', 'item'],
    );

    return AdminUserCompany(
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
      socialLinks: _stringMap(
        _firstValue(source, const ['socialLinks', 'social_links', 'social']),
      ),
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

  static AdminUserCompany? maybeFromJson(dynamic json) {
    final list = _extractList(
      json,
      preferredKeys: const ['companies', 'companyList', 'items', 'data'],
    );
    if (list.isNotEmpty) {
      final company = AdminUserCompany.fromJson(list.first);
      return company.hasContent ? company : null;
    }

    final company = AdminUserCompany.fromJson(json);
    return company.hasContent ? company : null;
  }
}

class AdminUserAddress {
  const AdminUserAddress({
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

  factory AdminUserAddress.fromJson(dynamic json) {
    final source = _asMap(json);
    return AdminUserAddress(
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
      cityId: _firstString(source, const ['cityId', 'city_id']) ?? '',
      cityName:
          _firstString(source, const ['cityName', 'city_name', 'city']) ?? '',
      pincode: _firstString(source, const [
            'pincode',
            'pinCode',
            'pin_code',
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

class AdminUpdateUserDetailsRequest {
  const AdminUpdateUserDetailsRequest({
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
    final active = isActive;
    if (active != null) {
      payload['isActive'] = active.toString();
    }
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

class AdminUpdateUserCompanyRequest {
  const AdminUpdateUserCompanyRequest({
    required this.name,
    required this.websiteUrl,
    required this.customDomain,
    required this.socialLinks,
    required this.primaryColor,
  });

  static const allowedPrimaryColors = <String>{
    'Black',
    'Blue',
    'Green',
    'Purple',
    'Pink',
    'Orange',
  };

  final String name;
  final String websiteUrl;
  final String customDomain;
  final Map<String, String> socialLinks;
  final String primaryColor;

  Map<String, dynamic> toJson() {
    final social = <String, dynamic>{};
    socialLinks.forEach((key, value) {
      final normalizedKey = key.trim();
      final normalizedValue = value.trim();
      if (normalizedKey.isEmpty || normalizedValue.isEmpty) return;
      social[normalizedKey] = normalizedValue;
    });

    final payload = <String, dynamic>{'name': name.trim()};
    _putIfNotNull(payload, 'websiteUrl', _optionalString(websiteUrl));
    _putIfNotNull(payload, 'customDomain', _optionalString(customDomain));
    if (social.isNotEmpty) {
      payload['socialLinks'] = social;
    }
    _putIfNotNull(
      payload,
      'primaryColor',
      _optionalString(_normalizePrimaryColor(primaryColor)),
    );
    return payload;
  }

  String _normalizePrimaryColor(String value) {
    final normalized = value.trim();
    for (final color in allowedPrimaryColors) {
      if (color.toLowerCase() == normalized.toLowerCase()) {
        return color;
      }
    }
    return normalized;
  }
}

class AdminUserVehicle {
  const AdminUserVehicle({
    required this.id,
    required this.name,
    required this.vin,
    required this.plateNumber,
    required this.imei,
    required this.simNumber,
    required this.isLicenseBlocked,
    required this.licenseBlockedAt,
    required this.licenseBlockReason,
    required this.secondaryExpiry,
    required this.plan,
    required this.device,
  });

  final String id;
  final String name;
  final String vin;
  final String plateNumber;
  final String imei;
  final String simNumber;
  final bool isLicenseBlocked;
  final DateTime? licenseBlockedAt;
  final String licenseBlockReason;
  final DateTime? secondaryExpiry;
  final Map<String, dynamic> plan;
  final Map<String, dynamic> device;

  factory AdminUserVehicle.fromJson(dynamic json) {
    final source = _asMap(json);
    return AdminUserVehicle(
      id: _firstString(source, const ['id', '_id', 'vehicleId']) ?? '',
      name: _firstString(source, const [
            'name',
            'vehicleName',
            'vehicle_name',
            'displayName',
          ]) ??
          '',
      vin: _firstString(source, const ['vin', 'VIN', 'chassisNo']) ?? '',
      plateNumber: _firstString(source, const [
            'plateNumber',
            'plate_number',
            'numberPlate',
            'registrationNumber',
            'registration_no',
            'vehicleNo',
          ]) ??
          '',
      imei: _firstString(source, const ['imei', 'IMEI', 'deviceImei']) ?? '',
      simNumber: _firstString(source, const [
            'simNumber',
            'sim_number',
            'simno',
            'simNo',
            'sim',
          ]) ??
          '',
      isLicenseBlocked: _parseBool(_firstValue(source, const [
            'isLicenseBlocked',
            'is_license_blocked',
            'licenseBlocked',
          ])) ??
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
      secondaryExpiry: _firstDate(source, const [
        'secondaryExpiry',
        'secondary_expiry',
        'secondaryPlanExpiry',
        'expiryAt',
        'expiry_at',
      ]),
      plan: _firstMap(source, const ['plan', 'subscriptionPlan']) ??
          const <String, dynamic>{},
      device: _firstMap(source, const ['device', 'gpsDevice', 'tracker']) ??
          const <String, dynamic>{},
    );
  }

  static List<AdminUserVehicle> listFromJson(dynamic json) {
    return _extractList(json, preferredKeys: const [
      'vehicles',
      'linkedVehicles',
      'unlinkedVehicles',
      'items',
      'rows',
      'data',
    ]).map(AdminUserVehicle.fromJson).toList(growable: false);
  }
}

class AdminUserDriver {
  const AdminUserDriver({
    required this.id,
    required this.name,
    required this.mobilePrefix,
    required this.mobile,
    required this.email,
    required this.username,
    required this.licenseNo,
    required this.isActive,
    required this.address,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String mobilePrefix;
  final String mobile;
  final String email;
  final String username;
  final String licenseNo;
  final bool isActive;
  final String address;
  final DateTime? createdAt;

  factory AdminUserDriver.fromJson(dynamic json) {
    final source = _asMap(json);
    final addressMap = _firstMap(source, const ['address', 'driverAddress']);
    return AdminUserDriver(
      id: _firstString(source, const ['id', '_id', 'driverId', 'uid']) ?? '',
      name: _firstString(source, const [
            'name',
            'Name',
            'fullName',
            'full_name',
            'driverName',
          ]) ??
          '',
      mobilePrefix: _firstString(source, const [
            'mobilePrefix',
            'mobile_prefix',
            'phonePrefix',
          ]) ??
          '',
      mobile: _firstString(source, const [
            'mobile',
            'mobileNumber',
            'mobile_number',
            'phone',
          ]) ??
          '',
      email: _firstString(source, const ['email', 'Email', 'mail']) ?? '',
      username:
          _firstString(source, const ['username', 'userName', 'user_name']) ??
              '',
      licenseNo: _firstString(source, const [
            'licenseNo',
            'license_no',
            'licenseNumber',
            'license_number',
          ]) ??
          '',
      isActive: _parseBool(_firstValue(source, const [
            'isActive',
            'is_active',
            'status',
            'active',
          ])) ??
          true,
      address: _firstString(addressMap ?? const <String, dynamic>{}, const [
            'fullAddress',
            'full_address',
            'addressLine',
            'address_line',
          ]) ??
          _firstString(source, const ['address', 'location']) ??
          '',
      createdAt: _firstDate(source, const ['createdAt', 'created_at']),
    );
  }

  static List<AdminUserDriver> listFromJson(dynamic json) {
    return _extractList(json, preferredKeys: const [
      'drivers',
      'linkedDrivers',
      'unlinkedDrivers',
      'items',
      'rows',
      'data',
    ]).map(AdminUserDriver.fromJson).toList(growable: false);
  }
}

class AdminUserDocument {
  const AdminUserDocument({
    required this.id,
    required this.title,
    required this.docTypeId,
    required this.docTypeName,
    required this.description,
    required this.tags,
    required this.associateType,
    required this.associateId,
    required this.fileName,
    required this.fileType,
    required this.filePath,
    required this.expiryAt,
    required this.isVisible,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String docTypeId;
  final String docTypeName;
  final String description;
  final List<String> tags;
  final String associateType;
  final String associateId;
  final String fileName;
  final String fileType;
  final String filePath;
  final DateTime? expiryAt;
  final bool isVisible;
  final DateTime? createdAt;

  factory AdminUserDocument.fromJson(dynamic json) {
    final source = _asMap(json);
    final docType = _firstMap(source, const [
          'docType',
          'doc_type',
          'documentType',
        ]) ??
        const <String, dynamic>{};
    return AdminUserDocument(
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
      tags: _parseStringList(_firstValue(source, const ['tags', 'tagList'])),
      associateType: _firstString(source, const [
            'AssociateType',
            'associateType',
            'associate_type',
          ]) ??
          '',
      associateId: _firstString(source, const [
            'associateId',
            'associate_id',
            'userId',
            'user_id',
          ]) ??
          '',
      fileName: _firstString(source, const ['fileName', 'file_name']) ?? '',
      fileType:
          _firstString(source, const ['fileType', 'file_type', 'mime']) ?? '',
      filePath: _firstString(source, const [
            'filePath',
            'file_path',
            'fileUrl',
            'file_url',
            'url',
            'path',
          ]) ??
          '',
      expiryAt: _firstDate(source, const ['expiryAt', 'expiry_at', 'expiry']),
      isVisible: _parseBool(_firstValue(source, const [
            'isVisible',
            'is_visible',
            'visible',
          ])) ??
          true,
      createdAt: _firstDate(source, const ['createdAt', 'created_at']),
    );
  }

  static List<AdminUserDocument> listFromJson(dynamic json) {
    return _extractList(json, preferredKeys: const [
      'documents',
      'docs',
      'items',
      'rows',
      'data',
    ]).map(AdminUserDocument.fromJson).toList(growable: false);
  }
}

class AdminDocumentTypeOption {
  const AdminDocumentTypeOption({
    required this.id,
    required this.name,
    required this.docFor,
  });

  final String id;
  final String name;
  final String docFor;

  bool get isForUser => docFor.toUpperCase() == 'USER';

  factory AdminDocumentTypeOption.fromJson(dynamic json) {
    final source = _asMap(json);
    return AdminDocumentTypeOption(
      id: _firstString(source, const ['id', '_id', 'typeId']) ?? '',
      name: _firstString(source, const ['name', 'label', 'title']) ?? '',
      docFor: (_firstString(source, const ['docFor', 'doc_for', 'for']) ?? '')
          .toUpperCase(),
    );
  }

  static List<AdminDocumentTypeOption> listFromJson(dynamic json) {
    return _extractList(json, preferredKeys: const [
      'documentTypes',
      'docTypes',
      'types',
      'items',
      'rows',
      'data',
    ]).map(AdminDocumentTypeOption.fromJson).where((item) {
      return item.id.isNotEmpty && (item.docFor.isEmpty || item.isForUser);
    }).toList(growable: false);
  }
}

class AdminUserDocumentRequest {
  const AdminUserDocumentRequest({
    required this.title,
    required this.docTypeId,
    required this.associateId,
    this.associateType = 'USER',
    this.isVisible = true,
    this.tags = const <String>[],
    this.description = '',
    this.expiryAt,
    this.file,
  });

  final String title;
  final String docTypeId;
  final String associateType;
  final String associateId;
  final bool isVisible;
  final List<String> tags;
  final String description;
  final String? expiryAt;
  final PlatformFile? file;
}

class AdminUserTicket {
  const AdminUserTicket({
    required this.id,
    required this.ticketNo,
    required this.title,
    required this.status,
    required this.category,
    required this.priority,
    required this.lastMessageAt,
    required this.createdAt,
    required this.fromUser,
    required this.toUser,
    required this.messages,
  });

  final String id;
  final String ticketNo;
  final String title;
  final String status;
  final String category;
  final String priority;
  final DateTime? lastMessageAt;
  final DateTime? createdAt;
  final AdminUserReference? fromUser;
  final AdminUserReference? toUser;
  final List<AdminUserTicketMessage> messages;

  factory AdminUserTicket.fromJson(dynamic json) {
    final source = _extractMapPayload(
      json,
      preferredKeys: const ['ticket', 'details', 'result', 'item'],
    );
    final fromUserMap =
        _firstMap(source, const ['fromUser', 'from_user', 'from']);
    final toUserMap = _firstMap(source, const ['toUser', 'to_user', 'to']);
    final messages = _extractList(source, preferredKeys: const [
      'messages',
      'ticketMessages',
      'replies',
    ]).map(AdminUserTicketMessage.fromJson).toList(growable: false);

    return AdminUserTicket(
      id: _firstString(source, const ['id', '_id', 'ticketId']) ?? '',
      ticketNo: _firstString(source, const [
            'ticketNo',
            'ticket_no',
            'ticketNumber',
            'number',
          ]) ??
          '',
      title: _firstString(source, const ['title', 'subject']) ?? '',
      status: _firstString(source, const ['status', 'state']) ?? '',
      category: _firstString(source, const ['category', 'type']) ?? '',
      priority: _firstString(source, const ['priority']) ?? '',
      lastMessageAt: _firstDate(source, const [
        'lastMessageAt',
        'last_message_at',
        'updatedAt',
        'updated_at',
      ]),
      createdAt: _firstDate(source, const ['createdAt', 'created_at']),
      fromUser:
          fromUserMap == null ? null : AdminUserReference.fromJson(fromUserMap),
      toUser: toUserMap == null ? null : AdminUserReference.fromJson(toUserMap),
      messages: messages,
    );
  }

  static List<AdminUserTicket> listFromJson(dynamic json) {
    return _extractList(json, preferredKeys: const [
      'tickets',
      'items',
      'rows',
      'data',
    ]).map(AdminUserTicket.fromJson).toList(growable: false);
  }
}

class AdminUserTicketMessage {
  const AdminUserTicketMessage({
    required this.id,
    required this.message,
    required this.senderId,
    required this.createdAt,
    required this.sender,
    required this.attachments,
  });

  final String id;
  final String message;
  final String senderId;
  final DateTime? createdAt;
  final AdminUserReference? sender;
  final List<Map<String, dynamic>> attachments;

  factory AdminUserTicketMessage.fromJson(dynamic json) {
    final source = _extractMapPayload(
      json,
      preferredKeys: const ['message', 'reply', 'item'],
    );
    final senderMap = _firstMap(source, const ['sender', 'user', 'fromUser']);
    return AdminUserTicketMessage(
      id: _firstString(source, const ['id', '_id', 'messageId']) ?? '',
      message: _firstString(source, const ['message', 'body', 'text']) ?? '',
      senderId: _firstString(source, const [
            'senderId',
            'sender_id',
            'userId',
            'user_id',
          ]) ??
          '',
      createdAt: _firstDate(source, const ['createdAt', 'created_at']),
      sender: senderMap == null ? null : AdminUserReference.fromJson(senderMap),
      attachments: _parseMapList(
        _firstValue(source, const ['attachments', 'files']),
      ),
    );
  }
}

class AdminUserPayment {
  const AdminUserPayment({
    required this.id,
    required this.amount,
    required this.currency,
    required this.status,
    required this.paymentMode,
    required this.paymentType,
    required this.reference,
    required this.provider,
    required this.providerRef,
    required this.createdAt,
    required this.fromUser,
    required this.toUser,
    required this.recordedBy,
    required this.vehicle,
    required this.plan,
    required this.meta,
  });

  final String id;
  final String amount;
  final String currency;
  final String status;
  final String paymentMode;
  final String paymentType;
  final String reference;
  final String provider;
  final String providerRef;
  final DateTime? createdAt;
  final AdminUserReference? fromUser;
  final AdminUserReference? toUser;
  final AdminUserReference? recordedBy;
  final Map<String, dynamic> vehicle;
  final Map<String, dynamic> plan;
  final Map<String, dynamic> meta;

  factory AdminUserPayment.fromJson(dynamic json) {
    final source = _asMap(json);
    final fromUserMap =
        _firstMap(source, const ['fromUser', 'from_user', 'from']);
    final toUserMap = _firstMap(source, const ['toUser', 'to_user', 'to']);
    final recordedByMap = _firstMap(source, const [
      'recordedBy',
      'recorded_by',
      'recordedByUser',
      'createdBy',
    ]);

    return AdminUserPayment(
      id: _firstString(
              source, const ['id', '_id', 'paymentId', 'transactionId']) ??
          '',
      amount: _amountString(_firstValue(source, const ['amount', 'value'])),
      currency: _firstString(source, const ['currency', 'currencyCode']) ?? '',
      status:
          _firstString(source, const ['status', 'paymentStatus', 'state']) ??
              '',
      paymentMode:
          _firstString(source, const ['paymentMode', 'payment_mode', 'mode']) ??
              '',
      paymentType:
          _firstString(source, const ['paymentType', 'payment_type', 'type']) ??
              '',
      reference: _firstString(source, const ['reference', 'ref']) ?? '',
      provider: _firstString(source, const ['provider', 'gateway']) ?? '',
      providerRef: _firstString(source, const [
            'providerRef',
            'provider_ref',
            'gatewayRef',
            'gateway_ref',
          ]) ??
          '',
      createdAt: _firstDate(source, const ['createdAt', 'created_at', 'date']),
      fromUser:
          fromUserMap == null ? null : AdminUserReference.fromJson(fromUserMap),
      toUser: toUserMap == null ? null : AdminUserReference.fromJson(toUserMap),
      recordedBy: recordedByMap == null
          ? null
          : AdminUserReference.fromJson(recordedByMap),
      vehicle:
          _firstMap(source, const ['vehicle']) ?? const <String, dynamic>{},
      plan: _firstMap(source, const ['plan']) ?? const <String, dynamic>{},
      meta: _firstMap(source, const ['meta', 'metadata']) ??
          const <String, dynamic>{},
    );
  }
}

class AdminUserPaymentPage {
  const AdminUserPaymentPage({
    required this.page,
    required this.limit,
    required this.total,
    required this.items,
  });

  final int page;
  final int limit;
  final int total;
  final List<AdminUserPayment> items;

  bool get hasMore => page * limit < total;

  factory AdminUserPaymentPage.fromJson(
    dynamic json, {
    int defaultPage = 1,
    int defaultLimit = 100,
  }) {
    if (json is List) {
      final items = json.map(AdminUserPayment.fromJson).toList(growable: false);
      return AdminUserPaymentPage(
        page: defaultPage,
        limit: defaultLimit,
        total: items.length,
        items: items,
      );
    }

    final source = _extractMapPayload(json);
    final items = _extractList(source, preferredKeys: const [
      'items',
      'payments',
      'transactions',
      'rows',
      'data',
    ]).map(AdminUserPayment.fromJson).toList(growable: false);

    return AdminUserPaymentPage(
      page: _firstInt(source, const ['page', 'currentPage', 'current_page']) ??
          defaultPage,
      limit: _firstInt(source, const ['limit', 'pageSize', 'perPage']) ??
          defaultLimit,
      total: _firstInt(source, const ['total', 'totalCount', 'count']) ??
          items.length,
      items: items,
    );
  }
}

class AdminRenewVehiclesPaymentRequest {
  const AdminRenewVehiclesPaymentRequest({
    required this.userId,
    required this.vehicleIds,
    required this.paymentMode,
    this.reference,
    this.amountOverride,
  });

  final String userId;
  final List<String> vehicleIds;
  final String paymentMode;
  final String? reference;
  final String? amountOverride;

  Map<String, dynamic> toJson() {
    final normalizedReference = reference?.trim();
    final normalizedAmount = amountOverride?.trim();
    return <String, dynamic>{
      'userId': _idPayloadValue(userId),
      'vehicleIds': vehicleIds.map(_idPayloadValue).toList(growable: false),
      'paymentMode': paymentMode.trim().toUpperCase(),
      if (normalizedReference != null && normalizedReference.isNotEmpty)
        'reference': normalizedReference,
      if (normalizedAmount != null && normalizedAmount.isNotEmpty)
        'amountOverride': normalizedAmount,
    };
  }
}

class AdminUserActivityLog {
  const AdminUserActivityLog({
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
  final AdminUserReference? user;

  factory AdminUserActivityLog.fromJson(dynamic json) {
    final source = _asMap(json);
    final userMap = _firstMap(source, const ['user', 'actor', 'admin']);
    return AdminUserActivityLog(
      id: _firstInt(source, const ['id', '_id', 'logId']) ?? 0,
      action: _firstString(source, const ['action', 'event']) ?? '',
      entity: _firstString(source, const ['entity', 'target']) ?? '',
      entityId:
          _firstString(source, const ['entityId', 'entity_id', 'targetId']) ??
              '',
      meta: _firstMap(source, const ['meta', 'metadata']) ??
          const <String, dynamic>{},
      ip: _firstString(source, const ['ip', 'ipAddress', 'ip_address']) ?? '',
      browser: _firstString(source, const ['browser', 'userAgent']) ?? '',
      platform: _firstString(source, const ['platform', 'os']) ?? '',
      createdAt: _firstDate(source, const ['createdAt', 'created_at', 'date']),
      user: userMap == null ? null : AdminUserReference.fromJson(userMap),
    );
  }
}

class AdminUserActivityLogPage {
  const AdminUserActivityLogPage({
    required this.items,
    required this.nextCursorId,
    required this.hasMore,
  });

  final List<AdminUserActivityLog> items;
  final int? nextCursorId;
  final bool hasMore;

  factory AdminUserActivityLogPage.fromJson(dynamic json) {
    if (json is List) {
      return AdminUserActivityLogPage(
        items: json.map(AdminUserActivityLog.fromJson).toList(growable: false),
        nextCursorId: null,
        hasMore: false,
      );
    }

    final source = _extractMapPayload(json);
    final items = _extractList(source, preferredKeys: const [
      'items',
      'logs',
      'activities',
      'rows',
      'data',
    ]).map(AdminUserActivityLog.fromJson).toList(growable: false);

    return AdminUserActivityLogPage(
      items: items,
      nextCursorId: _firstInt(source, const [
        'nextCursorId',
        'next_cursor_id',
        'cursorId',
        'cursor_id',
      ]),
      hasMore: _parseBool(
            _firstValue(source, const ['hasMore', 'has_more', 'hasNext']),
          ) ??
          false,
    );
  }
}

class AdminUserReference {
  const AdminUserReference({
    required this.id,
    required this.name,
    required this.username,
    required this.email,
  });

  final String id;
  final String name;
  final String username;
  final String email;

  factory AdminUserReference.fromJson(dynamic json) {
    final source = _asMap(json);
    return AdminUserReference(
      id: _firstString(source, const ['uid', 'id', '_id', 'userId']) ?? '',
      name: _firstString(source, const [
            'name',
            'Name',
            'fullName',
            'full_name',
            'displayName',
          ]) ??
          '',
      username:
          _firstString(source, const ['username', 'userName', 'user_name']) ??
              '',
      email: _firstString(source, const ['email', 'Email', 'mail']) ?? '',
    );
  }
}

void _putIfNotNull(Map<String, dynamic> payload, String key, Object? value) {
  if (value != null) {
    payload[key] = value;
  }
}

String? _optionalString(String value) {
  final normalized = value.trim();
  if (normalized.isEmpty) {
    return null;
  }
  return normalized;
}

Map<String, dynamic> _extractMapPayload(
  dynamic json, {
  List<String> preferredKeys = const ['data', 'result', 'payload', 'response'],
}) {
  final root = _asMap(json);
  if (root.isEmpty) {
    return const <String, dynamic>{};
  }

  final preferred = _firstMap(root, preferredKeys);
  if (preferred != null && preferred.isNotEmpty) {
    return preferred;
  }

  final data = _firstMap(root, const ['data', 'result', 'payload', 'response']);
  if (data != null && data.isNotEmpty) {
    final nested = _firstMap(data, preferredKeys);
    if (nested != null && nested.isNotEmpty) {
      return nested;
    }
    return data;
  }

  return root;
}

List<dynamic> _extractList(
  dynamic json, {
  List<String> preferredKeys = const [
    'items',
    'rows',
    'records',
    'list',
    'data',
  ],
}) {
  if (json is List) {
    return json;
  }

  final root = _asMap(json);
  for (final key in preferredKeys) {
    final value = _valueForKey(root, key);
    if (value is List) {
      return value;
    }
  }

  for (final key in const ['data', 'result', 'payload', 'response']) {
    final nested = _valueForKey(root, key);
    if (nested == null || identical(nested, json)) continue;
    final list = _extractList(nested, preferredKeys: preferredKeys);
    if (list.isNotEmpty) {
      return list;
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

dynamic _valueForKey(Map<String, dynamic> json, String key) {
  if (json.containsKey(key)) {
    return json[key];
  }

  final normalizedKey = key.toLowerCase();
  for (final entry in json.entries) {
    if (entry.key.toLowerCase() == normalizedKey) {
      return entry.value;
    }
  }
  return null;
}

dynamic _firstValue(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = _valueForKey(json, key);
    if (value != null) {
      return value;
    }
  }
  return null;
}

Map<String, dynamic>? _firstMap(
  Map<String, dynamic> json,
  List<String> keys,
) {
  for (final key in keys) {
    final value = _valueForKey(json, key);
    final map = _asMap(value);
    if (map.isNotEmpty) {
      return map;
    }
  }
  return null;
}

List<dynamic>? _firstList(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = _valueForKey(json, key);
    if (value is List) {
      return value;
    }
    if (value is Iterable) {
      return value.toList(growable: false);
    }
  }
  return null;
}

String? _firstString(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = _valueForKey(json, key);
    final normalized = value?.toString().trim();
    if (normalized != null && normalized.isNotEmpty) {
      return normalized;
    }
  }
  return null;
}

int? _firstInt(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final parsed = _parseInt(_valueForKey(json, key));
    if (parsed != null) {
      return parsed;
    }
  }
  return null;
}

DateTime? _firstDate(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final parsed = _parseDate(_valueForKey(json, key));
    if (parsed != null) {
      return parsed;
    }
  }
  return null;
}

int? _parseInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  final normalized = value?.toString().trim();
  if (normalized == null || normalized.isEmpty) return null;
  return int.tryParse(normalized) ?? double.tryParse(normalized)?.toInt();
}

DateTime? _parseDate(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value.toLocal();
  if (value is num) {
    final milliseconds = value.toInt().abs() < 10000000000
        ? value.toInt() * 1000
        : value.toInt();
    return DateTime.fromMillisecondsSinceEpoch(milliseconds, isUtc: true)
        .toLocal();
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
    case '1':
    case 'true':
    case 'yes':
    case 'y':
    case 'active':
    case 'enabled':
    case 'verified':
    case 'approved':
      return true;
    case '0':
    case 'false':
    case 'no':
    case 'n':
    case 'inactive':
    case 'disabled':
    case 'blocked':
    case 'suspended':
    case 'unverified':
    case 'pending':
      return false;
  }
  return null;
}

Map<String, String> _stringMap(dynamic value) {
  dynamic resolved = value;
  if (value is String) {
    final trimmed = value.trim();
    if (trimmed.startsWith('{') && trimmed.endsWith('}')) {
      try {
        resolved = _decodeJson(trimmed);
      } catch (_) {
        resolved = null;
      }
    }
  }
  final source = _asMap(resolved);
  if (source.isEmpty) {
    return const <String, String>{};
  }
  final result = <String, String>{};
  source.forEach((key, item) {
    final normalized = item?.toString().trim();
    if (normalized == null || normalized.isEmpty) return;
    result[key] = normalized;
  });
  return result;
}

dynamic _decodeJson(String source) {
  try {
    return jsonDecode(source);
  } catch (_) {
    return null;
  }
}

List<String> _parseStringList(dynamic value) {
  if (value is List) {
    return value
        .map((item) => item?.toString().trim() ?? '')
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }
  final normalized = value?.toString().trim();
  if (normalized == null || normalized.isEmpty) {
    return const <String>[];
  }
  return normalized
      .split(',')
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toList(growable: false);
}

List<Map<String, dynamic>> _parseMapList(dynamic value) {
  if (value is! List) {
    return const <Map<String, dynamic>>[];
  }
  return value
      .map(_asMap)
      .where((item) => item.isNotEmpty)
      .toList(growable: false);
}

String _composeMobileDisplay(String prefix, String number) {
  final normalizedPrefix = prefix.trim();
  final normalizedNumber = number.trim();
  if (normalizedPrefix.isEmpty) return normalizedNumber;
  if (normalizedNumber.isEmpty) return normalizedPrefix;
  return '$normalizedPrefix $normalizedNumber';
}

String _amountString(dynamic value) {
  if (value == null) return '0';
  if (value is num) return value.toString();
  final normalized = value.toString().replaceAll(',', '').trim();
  return normalized.isEmpty ? '0' : normalized;
}

Object _idPayloadValue(String id) {
  final normalized = id.trim();
  return int.tryParse(normalized) ?? normalized;
}
