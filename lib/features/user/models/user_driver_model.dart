import 'dart:convert';

import 'package:file_picker/file_picker.dart';

class UserDriver {
  const UserDriver({
    required this.id,
    required this.name,
    required this.mobilePrefix,
    required this.mobile,
    required this.email,
    required this.username,
    required this.countryCode,
    required this.stateCode,
    required this.city,
    required this.address,
    required this.pincode,
    required this.status,
    required this.isActive,
    required this.isVerified,
    required this.createdAt,
    required this.updatedAt,
    required this.attributes,
    required this.addressDetails,
    required this.vehicleAssignment,
  });

  final String id;
  final String name;
  final String mobilePrefix;
  final String mobile;
  final String email;
  final String username;
  final String countryCode;
  final String stateCode;
  final String city;
  final String address;
  final String pincode;
  final String status;
  final bool isActive;
  final bool isVerified;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic> attributes;
  final UserDriverAddress? addressDetails;
  final UserDriverVehicleAssignment? vehicleAssignment;

  UserDriverVehicleMini? get assignedVehicle => vehicleAssignment?.vehicle;
  bool get hasAssignedVehicle => vehicleAssignment?.hasVehicle ?? false;

  String get searchContent {
    return <String>[
      name,
      username,
      email,
      mobilePrefix,
      mobile,
      countryCode,
      stateCode,
      city,
      address,
      pincode,
      assignedVehicle?.name ?? '',
      assignedVehicle?.plateNumber ?? '',
      assignedVehicle?.imei ?? '',
      status,
    ].join(' ').toLowerCase();
  }

  factory UserDriver.fromJson(dynamic json) {
    final source = _extractMapPayload(
      json,
      preferredKeys: const ['driver', 'details', 'item', 'record', 'data'],
    );
    final addressDetails = UserDriverAddress.fromSource(source);
    final vehicleAssignment = _parseDriverVehicleAssignment(source);
    final status = _firstString(source, const [
          'status',
          'driverStatus',
          'driver_status',
          'state',
        ]) ??
        '';

    final isActiveFromStatus = _parseBool(status);
    final isVerifiedFromStatus = _parseVerified(status);

    return UserDriver(
      id: _firstString(source, const ['id', '_id', 'uid', 'driverId']) ?? '',
      name:
          _firstString(source, const ['name', 'fullName', 'displayName']) ?? '',
      mobilePrefix: _firstString(source, const [
            'mobilePrefix',
            'mobile_prefix',
            'mobileCode',
            'mobile_code',
            'countryPrefix',
          ]) ??
          '',
      mobile: _firstString(source, const [
            'mobile',
            'mobileNumber',
            'mobile_number',
            'phone',
            'phoneNumber',
            'contact',
          ]) ??
          '',
      email: _firstString(source, const ['email']) ?? '',
      username: _firstString(source, const ['username', 'userName']) ?? '',
      countryCode:
          _firstString(source, const ['countryCode', 'country_code']) ??
              (addressDetails?.countryCode ?? ''),
      stateCode: _firstString(source, const [
            'stateCode',
            'state_code',
            'StateCode',
          ]) ??
          (addressDetails?.stateCode ?? ''),
      city: _firstString(source, const ['city', 'cityId', 'cityName']) ??
          (addressDetails?.city ?? ''),
      address: _firstString(source, const [
            'address',
            'addressLine',
            'address_line',
            'fullAddress',
          ]) ??
          (addressDetails?.address ?? ''),
      pincode: _firstString(source, const [
            'pincode',
            'postalCode',
            'postal_code',
            'zip',
          ]) ??
          (addressDetails?.pincode ?? ''),
      status: status,
      isActive: _parseBool(_firstValue(source, const [
            'isActive',
            'is_active',
            'isactive',
            'active',
            'status',
          ])) ??
          isActiveFromStatus ??
          true,
      isVerified: _parseBool(_firstValue(source, const [
            'isVerified',
            'is_verified',
            'verified',
            'isEmailVerified',
            'isMobileVerified',
          ])) ??
          isVerifiedFromStatus ??
          false,
      createdAt: _firstDate(source, const [
        'createdAt',
        'created_at',
        'addedAt',
        'added_at',
      ]),
      updatedAt: _firstDate(source, const [
        'updatedAt',
        'updated_at',
      ]),
      attributes: _parseAttributes(_firstValue(source, const [
            'attributes',
            'attribute',
            'meta',
            'metadata',
          ])) ??
          const <String, dynamic>{},
      addressDetails: addressDetails,
      vehicleAssignment: vehicleAssignment,
    );
  }

  static List<UserDriver> listFromJson(dynamic json) {
    return _extractList(json, preferredKeys: const [
      'drivers',
      'items',
      'rows',
      'records',
      'data',
    ]).map(UserDriver.fromJson).where((item) {
      return item.id.trim().isNotEmpty;
    }).toList(growable: false);
  }
}

class UserDriverVehicleAssignment {
  const UserDriverVehicleAssignment({
    required this.id,
    required this.driverId,
    required this.vehicleId,
    required this.vehicle,
    required this.createdAt,
    required this.updatedAt,
    required this.raw,
  });

  final String id;
  final String driverId;
  final String vehicleId;
  final UserDriverVehicleMini? vehicle;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic> raw;

  bool get hasVehicle => vehicleId.isNotEmpty || vehicle != null;

  factory UserDriverVehicleAssignment.fromJson(dynamic json) {
    final source = _extractMapPayload(
      json,
      preferredKeys: const ['driverVehicle', 'assignment', 'item', 'record'],
    );

    final vehicleMap = _firstMap(source, const [
      'vehicle',
      'vehicleDetails',
      'vehicle_details',
      'assignedVehicle',
      'assigned_vehicle',
    ]);

    final vehicle = vehicleMap == null
        ? _parseInlineVehicle(source)
        : UserDriverVehicleMini.fromJson(vehicleMap);

    return UserDriverVehicleAssignment(
      id: _firstString(source, const [
            'id',
            '_id',
            'driverVehicleId',
            'assignmentId',
          ]) ??
          '',
      driverId: _firstString(source, const ['driverId', 'driver_id']) ?? '',
      vehicleId: _firstString(source, const ['vehicleId', 'vehicle_id']) ??
          (vehicle?.id ?? ''),
      vehicle: vehicle,
      createdAt: _firstDate(source, const ['createdAt', 'created_at']),
      updatedAt: _firstDate(source, const ['updatedAt', 'updated_at']),
      raw: source,
    );
  }
}

class UserDriverVehicleMini {
  const UserDriverVehicleMini({
    required this.id,
    required this.name,
    required this.plateNumber,
    required this.imei,
    required this.vin,
    required this.vehicleType,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String plateNumber;
  final String imei;
  final String vin;
  final String vehicleType;
  final DateTime? createdAt;

  String get searchContent {
    return <String>[id, name, plateNumber, imei, vin, vehicleType]
        .join(' ')
        .toLowerCase();
  }

  factory UserDriverVehicleMini.fromJson(dynamic json) {
    final source = _extractMapPayload(
      json,
      preferredKeys: const ['vehicle', 'item', 'record', 'data'],
    );

    return UserDriverVehicleMini(
      id: _firstString(source, const ['id', '_id', 'uid', 'vehicleId']) ?? '',
      name: _firstString(source, const ['name', 'vehicleName']) ?? '',
      plateNumber: _firstString(source, const [
            'plateNumber',
            'plate_number',
            'numberPlate',
            'registrationNumber',
            'vehicleNo',
          ]) ??
          '',
      imei: _firstString(source, const ['imei', 'IMEI', 'deviceImei']) ?? '',
      vin: _firstString(source, const ['vin', 'VIN', 'chassisNo']) ?? '',
      vehicleType: _firstString(source, const [
            'vehicleType',
            'vehicle_type',
            'vehicleTypeName',
            'type',
          ]) ??
          '',
      createdAt: _firstDate(source, const ['createdAt', 'created_at']),
    );
  }

  static List<UserDriverVehicleMini> listFromJson(dynamic json) {
    return _extractList(json, preferredKeys: const [
      'vehicles',
      'items',
      'rows',
      'records',
      'data',
    ]).map(UserDriverVehicleMini.fromJson).where((item) {
      return item.id.isNotEmpty;
    }).toList(growable: false);
  }
}

class UserDriverAddress {
  const UserDriverAddress({
    required this.countryCode,
    required this.stateCode,
    required this.city,
    required this.address,
    required this.pincode,
    required this.fullAddress,
  });

  final String countryCode;
  final String stateCode;
  final String city;
  final String address;
  final String pincode;
  final String fullAddress;

  bool get hasContent {
    return countryCode.isNotEmpty ||
        stateCode.isNotEmpty ||
        city.isNotEmpty ||
        address.isNotEmpty ||
        pincode.isNotEmpty ||
        fullAddress.isNotEmpty;
  }

  factory UserDriverAddress.fromJson(dynamic json) {
    final source = _asMap(json);
    return UserDriverAddress(
      countryCode:
          _firstString(source, const ['countryCode', 'country_code']) ?? '',
      stateCode: _firstString(source, const [
            'stateCode',
            'state_code',
            'StateCode',
          ]) ??
          '',
      city: _firstString(source, const ['city', 'cityId', 'cityName']) ?? '',
      address: _firstString(source, const [
            'address',
            'addressLine',
            'address_line',
          ]) ??
          '',
      pincode: _firstString(source, const [
            'pincode',
            'postalCode',
            'zip',
          ]) ??
          '',
      fullAddress: _firstString(source, const ['fullAddress']) ?? '',
    );
  }

  static UserDriverAddress? fromSource(Map<String, dynamic> source) {
    final nested = _firstMap(source, const [
          'address',
          'addressInfo',
          'address_info',
          'location',
          'addressDetails',
        ]) ??
        const <String, dynamic>{};

    final merged = <String, dynamic>{
      ...nested,
      'countryCode':
          _firstValue(source, const ['countryCode', 'country_code']) ??
              nested['countryCode'] ??
              nested['country_code'],
      'stateCode': _firstValue(source, const [
            'stateCode',
            'state_code',
            'StateCode',
          ]) ??
          nested['stateCode'] ??
          nested['state_code'],
      'city': _firstValue(source, const ['city', 'cityId', 'cityName']) ??
          nested['city'] ??
          nested['cityId'],
      'address': _firstValue(source, const [
            'address',
            'addressLine',
            'address_line',
            'fullAddress',
          ]) ??
          nested['address'] ??
          nested['addressLine'],
      'pincode': _firstValue(source, const [
            'pincode',
            'postalCode',
            'zip',
          ]) ??
          nested['pincode'],
      'fullAddress':
          _firstValue(source, const ['fullAddress']) ?? nested['fullAddress'],
    };

    final parsed = UserDriverAddress.fromJson(merged);
    return parsed.hasContent ? parsed : null;
  }
}

class UserDriverLog {
  const UserDriverLog({
    required this.id,
    required this.activity,
    required this.message,
    required this.vehicle,
    required this.actorId,
    required this.actorName,
    required this.createdAt,
    required this.raw,
  });

  final String id;
  final String activity;
  final String message;
  final UserDriverVehicleMini? vehicle;
  final String actorId;
  final String actorName;
  final DateTime? createdAt;
  final Map<String, dynamic> raw;

  factory UserDriverLog.fromJson(dynamic json) {
    final source = _extractMapPayload(
      json,
      preferredKeys: const ['log', 'item', 'record', 'data'],
    );
    final activity = _firstString(source, const [
          'activity',
          'action',
          'event',
          'type',
        ]) ??
        '';
    final actor = _firstMap(source, const [
          'user',
          'actor',
          'performedBy',
          'performed_by',
          'byUser',
          'by_user',
        ]) ??
        const <String, dynamic>{};
    final vehicleMap = _firstMap(source, const [
      'vehicle',
      'assignedVehicle',
      'assigned_vehicle',
    ]);

    return UserDriverLog(
      id: _firstString(source, const ['id', '_id', 'historyId', 'logId']) ?? '',
      activity: activity,
      message: _firstString(source, const ['message', 'description', 'note']) ??
          activity,
      vehicle: vehicleMap == null
          ? null
          : UserDriverVehicleMini.fromJson(vehicleMap),
      actorId:
          _firstString(actor, const ['uid', 'id', 'userId', 'user_id']) ?? '',
      actorName: _firstString(actor, const ['name', 'username']) ?? '',
      createdAt: _firstDate(source, const ['createdAt', 'created_at']),
      raw: source,
    );
  }

  static List<UserDriverLog> listFromJson(dynamic json) {
    return _extractList(json, preferredKeys: const [
      'logs',
      'items',
      'rows',
      'records',
      'data',
    ]).map(UserDriverLog.fromJson).toList(growable: false);
  }
}

class UserDriverDocument {
  const UserDriverDocument({
    required this.id,
    required this.title,
    required this.docTypeId,
    required this.docTypeName,
    required this.description,
    required this.tags,
    required this.fileName,
    required this.fileType,
    required this.filePath,
    required this.fileUrl,
    required this.expiryAt,
    required this.isVisible,
    required this.isVisibleDriver,
    required this.createdAt,
    required this.updatedAt,
    required this.raw,
  });

  final String id;
  final String title;
  final String docTypeId;
  final String docTypeName;
  final String description;
  final List<String> tags;
  final String fileName;
  final String fileType;
  final String filePath;
  final String fileUrl;
  final DateTime? expiryAt;
  final bool isVisible;
  final bool isVisibleDriver;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic> raw;

  factory UserDriverDocument.fromJson(dynamic json) {
    final source = _extractMapPayload(
      json,
      preferredKeys: const ['document', 'doc', 'item', 'record', 'data'],
    );
    final docType = _firstMap(source, const [
          'docType',
          'doc_type',
          'documentType',
          'document_type',
        ]) ??
        const <String, dynamic>{};

    final filePath = _firstString(source, const [
          'filePath',
          'file_path',
          'path',
        ]) ??
        '';

    return UserDriverDocument(
      id: _firstString(source, const ['id', '_id', 'docId', 'documentId']) ??
          '',
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
          _firstString(docType, const ['name', 'label', 'title']) ??
          '',
      description: _firstString(source, const ['description', 'desc']) ?? '',
      tags: _parseStringList(_firstValue(source, const ['tags', 'tagList'])),
      fileName: _firstString(source, const ['fileName', 'file_name']) ?? '',
      fileType:
          _firstString(source, const ['fileType', 'file_type', 'mime']) ?? '',
      filePath: filePath,
      fileUrl: _firstString(source, const [
            'fileUrl',
            'file_url',
            'url',
          ]) ??
          filePath,
      expiryAt: _firstDate(source, const ['expiryAt', 'expiry_at', 'expiry']),
      isVisible: _parseBool(_firstValue(source, const [
            'isVisible',
            'is_visible',
            'visible',
          ])) ??
          true,
      isVisibleDriver: _parseBool(_firstValue(source, const [
            'isVisibleDriver',
            'is_visible_driver',
            'visibleToDriver',
          ])) ??
          false,
      createdAt: _firstDate(source, const ['createdAt', 'created_at']),
      updatedAt: _firstDate(source, const ['updatedAt', 'updated_at']),
      raw: source,
    );
  }

  static List<UserDriverDocument> listFromJson(dynamic json) {
    return _extractList(json, preferredKeys: const [
      'documents',
      'docs',
      'items',
      'rows',
      'data',
    ]).map(UserDriverDocument.fromJson).toList(growable: false);
  }
}

class UserDriverDocumentType {
  const UserDriverDocumentType({
    required this.id,
    required this.name,
    required this.docFor,
  });

  final String id;
  final String name;
  final String docFor;

  bool get isForDriver => docFor.toUpperCase() == 'DRIVER';

  factory UserDriverDocumentType.fromJson(dynamic json) {
    final source = _asMap(json);
    return UserDriverDocumentType(
      id: _firstString(source, const ['id', '_id', 'typeId']) ?? '',
      name: _firstString(source, const ['name', 'label', 'title']) ?? '',
      docFor: (_firstString(source, const ['docFor', 'doc_for', 'for']) ?? '')
          .toUpperCase(),
    );
  }

  static List<UserDriverDocumentType> listFromJson(dynamic json) {
    return _extractList(json, preferredKeys: const [
      'documentTypes',
      'docTypes',
      'types',
      'items',
      'rows',
      'data',
    ]).map(UserDriverDocumentType.fromJson).where((item) {
      return item.id.isNotEmpty && (item.docFor.isEmpty || item.isForDriver);
    }).toList(growable: false);
  }
}

class UserDriverCountryOption {
  const UserDriverCountryOption({
    required this.value,
    required this.label,
  });

  final String value;
  final String label;

  static List<UserDriverCountryOption> listFromJson(dynamic json) {
    final options = _extractOptionList(json)
        .map((item) {
          final primitive = _parseString(item);
          if (primitive != null) {
            final value = primitive.toUpperCase();
            return UserDriverCountryOption(
              value: value,
              label: primitive,
            );
          }

          final itemMap = _asMap(item);
          if (itemMap.isEmpty) {
            return const UserDriverCountryOption(value: '', label: '');
          }

          final value = (_firstString(itemMap, const [
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

          return UserDriverCountryOption(value: value, label: label);
        })
        .where((item) => item.value.isNotEmpty)
        .toList(growable: false);

    return _distinctByKey(options, (item) => item.value);
  }
}

class UserDriverMobilePrefixOption {
  const UserDriverMobilePrefixOption({
    required this.value,
    required this.label,
    required this.countryCode,
  });

  final String value;
  final String label;
  final String countryCode;

  static List<UserDriverMobilePrefixOption> listFromJson(dynamic json) {
    final options = _extractOptionList(json)
        .map((item) {
          final primitive = _parseString(item);
          if (primitive != null) {
            final value = _normalizeDialCode(primitive);
            return UserDriverMobilePrefixOption(
              value: value,
              label: value,
              countryCode: '',
            );
          }

          final itemMap = _asMap(item);
          if (itemMap.isEmpty) {
            return const UserDriverMobilePrefixOption(
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

          return UserDriverMobilePrefixOption(
            value: value,
            label: label.isEmpty ? value : label,
            countryCode: countryCode,
          );
        })
        .where((item) => item.value.isNotEmpty)
        .toList(growable: false);

    return _distinctByKey(options, (item) => item.value);
  }
}

class UserDriverStateOption {
  const UserDriverStateOption({
    required this.value,
    required this.label,
  });

  final String value;
  final String label;

  static List<UserDriverStateOption> listFromJson(dynamic json) {
    final options = _extractOptionList(json)
        .map((item) {
          final primitive = _parseString(item);
          if (primitive != null) {
            final value = primitive.toUpperCase();
            return UserDriverStateOption(value: value, label: primitive);
          }

          final itemMap = _asMap(item);
          if (itemMap.isEmpty) {
            return const UserDriverStateOption(value: '', label: '');
          }

          final value = (_firstString(itemMap, const [
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

          return UserDriverStateOption(value: value, label: label);
        })
        .where((item) => item.value.isNotEmpty)
        .toList(growable: false);

    return _distinctByKey(options, (item) => item.value);
  }
}

class UserDriverCityOption {
  const UserDriverCityOption({
    required this.value,
    required this.label,
  });

  final String value;
  final String label;

  static List<UserDriverCityOption> listFromJson(dynamic json) {
    final options = _extractOptionList(json)
        .map((item) {
          final primitive = _parseString(item);
          if (primitive != null) {
            return UserDriverCityOption(value: primitive, label: primitive);
          }

          final itemMap = _asMap(item);
          if (itemMap.isEmpty) {
            return const UserDriverCityOption(value: '', label: '');
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

          return UserDriverCityOption(value: value, label: label);
        })
        .where((item) => item.value.isNotEmpty)
        .toList(growable: false);

    return _distinctByKey(options, (item) => item.value);
  }
}

class CreateUserDriverRequest {
  const CreateUserDriverRequest({
    required this.name,
    required this.mobilePrefix,
    required this.mobile,
    this.email,
    required this.username,
    required this.password,
    required this.countryCode,
    this.stateCode,
    this.city,
    this.address,
    this.pincode,
  });

  final String name;
  final String mobilePrefix;
  final String mobile;
  final String? email;
  final String username;
  final String password;
  final String countryCode;
  final String? stateCode;
  final String? city;
  final String? address;
  final String? pincode;

  Map<String, dynamic> toJson() {
    final payload = <String, dynamic>{
      'name': _requiredString(name, 'name'),
      'mobilePrefix': _requiredString(mobilePrefix, 'mobilePrefix'),
      'mobile': _requiredString(mobile, 'mobile'),
      'username': _requiredString(username, 'username'),
      'password': _requiredString(password, 'password'),
      'countryCode': _requiredString(countryCode, 'countryCode'),
    };

    _putIfNotNull(payload, 'email', _optionalString(email));
    _putIfNotNull(payload, 'stateCode', _optionalString(stateCode));
    _putIfNotNull(payload, 'city', _optionalString(city));
    _putIfNotNull(payload, 'address', _optionalString(address));
    _putIfNotNull(payload, 'pincode', _optionalString(pincode));

    return payload;
  }
}

class UpdateUserDriverRequest {
  const UpdateUserDriverRequest({
    this.name,
    this.mobilePrefix,
    this.mobile,
    this.email,
    this.username,
    this.password,
    this.countryCode,
    this.stateCode,
    this.city,
    this.address,
    this.pincode,
    this.isActive,
    this.attributes,
  });

  final String? name;
  final String? mobilePrefix;
  final String? mobile;
  final String? email;
  final String? username;
  final String? password;
  final String? countryCode;
  final String? stateCode;
  final String? city;
  final String? address;
  final String? pincode;
  final bool? isActive;
  final Map<String, dynamic>? attributes;

  Map<String, dynamic> toJson() {
    final payload = <String, dynamic>{};
    _putIfNotNull(payload, 'name', _optionalString(name));
    _putIfNotNull(payload, 'mobilePrefix', _optionalString(mobilePrefix));
    _putIfNotNull(payload, 'mobile', _optionalString(mobile));
    _putIfNotNull(payload, 'email', _optionalString(email));
    _putIfNotNull(payload, 'username', _optionalString(username));
    _putIfNotNull(payload, 'password', _optionalString(password));
    _putIfNotNull(payload, 'countryCode', _optionalString(countryCode));
    _putIfNotNull(payload, 'StateCode', _optionalString(stateCode));
    _putIfNotNull(payload, 'city', _optionalString(city));
    _putIfNotNull(payload, 'address', _optionalString(address));
    _putIfNotNull(payload, 'pincode', _optionalString(pincode));
    if (isActive != null) {
      payload['isactive'] = isActive! ? 'true' : 'false';
    }
    if (attributes != null) {
      payload['attributes'] = Map<String, dynamic>.from(attributes!);
    }
    return payload;
  }
}

class AssignDriverVehicleRequest {
  const AssignDriverVehicleRequest({required this.vehicleId});

  final String vehicleId;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'vehicleId': _idPayloadValue(_requiredString(vehicleId, 'vehicleId')),
    };
  }
}

class UserDriverDocumentMutationRequest {
  const UserDriverDocumentMutationRequest({
    this.file,
    this.fileName,
    this.title,
    this.name,
    this.docTypeId,
    this.description,
    this.notes,
    this.tags = const <String>[],
    this.expiryAt,
    this.expiryDate,
    this.isVisible,
    this.isVisibleDriver,
  });

  final PlatformFile? file;
  final String? fileName;
  final String? title;
  final String? name;
  final String? docTypeId;
  final String? description;
  final String? notes;
  final List<String> tags;
  final String? expiryAt;
  final String? expiryDate;
  final bool? isVisible;
  final bool? isVisibleDriver;

  String? get resolvedTitle {
    return _optionalString(title) ??
        _optionalString(name) ??
        _optionalString(fileName);
  }

  String? get resolvedDescription {
    return _optionalString(description) ?? _optionalString(notes);
  }

  String? get resolvedExpiry {
    return _optionalString(expiryAt) ?? _optionalString(expiryDate);
  }

  bool get hasMutationFields {
    return file != null ||
        _optionalString(fileName) != null ||
        resolvedTitle != null ||
        _optionalString(docTypeId) != null ||
        resolvedDescription != null ||
        tags.where((item) => item.trim().isNotEmpty).isNotEmpty ||
        resolvedExpiry != null ||
        isVisible != null ||
        isVisibleDriver != null;
  }
}

UserDriverVehicleAssignment? _parseDriverVehicleAssignment(
  Map<String, dynamic> source,
) {
  final assignmentRaw = _firstValue(source, const [
    'driverVehicle',
    'driver_vehicle',
    'vehicleAssignment',
    'assignedVehicle',
  ]);

  if (assignmentRaw is List) {
    for (final item in assignmentRaw) {
      final parsed = _parseDriverVehicleAssignment(_asMap(item));
      if (parsed != null && parsed.hasVehicle) {
        return parsed;
      }
    }
    return null;
  }

  final assignmentMap = _asMap(assignmentRaw);
  if (assignmentMap.isNotEmpty) {
    final parsed = UserDriverVehicleAssignment.fromJson(assignmentMap);
    return parsed.hasVehicle ? parsed : null;
  }

  final inlineVehicle = _parseInlineVehicle(source);
  if (inlineVehicle == null) {
    return null;
  }

  return UserDriverVehicleAssignment(
    id: '',
    driverId: _firstString(source, const ['id', '_id', 'driverId']) ?? '',
    vehicleId: inlineVehicle.id,
    vehicle: inlineVehicle,
    createdAt: null,
    updatedAt: null,
    raw: source,
  );
}

UserDriverVehicleMini? _parseInlineVehicle(Map<String, dynamic> source) {
  final candidate = UserDriverVehicleMini.fromJson(source);
  if (candidate.id.isEmpty &&
      candidate.name.isEmpty &&
      candidate.plateNumber.isEmpty &&
      candidate.imei.isEmpty) {
    return null;
  }
  return candidate;
}

Map<String, dynamic>? _parseAttributes(dynamic value) {
  final map = _asMap(value);
  if (map.isNotEmpty) {
    return map;
  }

  if (value is String) {
    final normalized = value.trim();
    if (normalized.isEmpty) {
      return null;
    }
    try {
      final decoded = jsonDecode(normalized);
      final decodedMap = _asMap(decoded);
      return decodedMap.isEmpty ? null : decodedMap;
    } catch (_) {
      return null;
    }
  }

  return null;
}

bool? _parseVerified(dynamic value) {
  if (value is String) {
    final normalized = value.trim().toLowerCase();
    if (normalized == 'verified') return true;
    if (normalized == 'unverified') return false;
  }
  return null;
}

void _putIfNotNull(Map<String, dynamic> payload, String key, Object? value) {
  if (value != null) {
    payload[key] = value;
  }
}

String _requiredString(String value, String field) {
  final normalized = value.trim();
  if (normalized.isEmpty) {
    throw ArgumentError('$field is required.');
  }
  return normalized;
}

String? _optionalString(String? value) {
  final normalized = value?.trim();
  if (normalized == null || normalized.isEmpty) {
    return null;
  }
  return normalized;
}

Object _idPayloadValue(String value) {
  return int.tryParse(value) ?? value;
}

Map<String, dynamic> _extractMapPayload(
  dynamic json, {
  List<String> preferredKeys = const ['data', 'result', 'payload', 'response'],
}) {
  final root = _asMap(json);
  if (root.isEmpty) {
    return const <String, dynamic>{};
  }

  for (final key in preferredKeys) {
    final value = _valueForKey(root, key);
    final map = _asMap(value);
    if (map.isNotEmpty) {
      return map;
    }
  }

  for (final key in const ['driver', 'data', 'result', 'payload', 'response']) {
    final nested = _valueForKey(root, key);
    if (nested == null || identical(nested, json)) {
      continue;
    }
    final nestedMap = _extractMapPayload(nested, preferredKeys: preferredKeys);
    if (nestedMap.isNotEmpty) {
      return nestedMap;
    }
  }

  return root;
}

List<dynamic> _extractList(
  dynamic json, {
  List<String> preferredKeys = const ['items', 'rows', 'records', 'data'],
}) {
  if (json is List) {
    return json;
  }

  final root = _asMap(json);
  if (root.isEmpty) {
    return const <dynamic>[];
  }

  for (final key in preferredKeys) {
    final value = _valueForKey(root, key);
    if (value is List) {
      return value;
    }
  }

  for (final key in const ['data', 'result', 'payload', 'response']) {
    final nested = _valueForKey(root, key);
    if (nested == null || identical(nested, json)) {
      continue;
    }
    final list = _extractList(nested, preferredKeys: preferredKeys);
    if (list.isNotEmpty) {
      return list;
    }
  }

  return const <dynamic>[];
}

List<dynamic> _extractOptionList(dynamic json) {
  return _extractList(
    json,
    preferredKeys: const [
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
    ],
  );
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

Map<String, dynamic>? _firstMap(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = _valueForKey(json, key);
    final map = _asMap(value);
    if (map.isNotEmpty) {
      return map;
    }
  }
  return null;
}

String? _firstString(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = _parseString(_valueForKey(json, key));
    if (value != null) {
      return value;
    }
  }
  return null;
}

String? _parseString(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is String) {
    final normalized = value.trim();
    if (normalized.isEmpty || normalized.toLowerCase() == 'null') {
      return null;
    }
    return normalized;
  }
  if (value is num || value is bool) {
    return value.toString();
  }
  return null;
}

bool? _parseBool(dynamic value) {
  if (value is bool) {
    return value;
  }
  if (value is num) {
    return value != 0;
  }
  if (value is String) {
    final normalized = value.trim().toLowerCase();
    if (normalized.isEmpty) {
      return null;
    }

    if (const {
      'true',
      '1',
      'yes',
      'y',
      'active',
      'enabled',
      'online',
      'verified',
    }.contains(normalized)) {
      return true;
    }

    if (const {
      'false',
      '0',
      'no',
      'n',
      'inactive',
      'disabled',
      'offline',
      'unverified',
    }.contains(normalized)) {
      return false;
    }
  }
  return null;
}

DateTime? _firstDate(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = _parseDate(_valueForKey(json, key));
    if (value != null) {
      return value;
    }
  }
  return null;
}

DateTime? _parseDate(dynamic value) {
  if (value is DateTime) {
    return value;
  }
  if (value is num) {
    final millis = value > 1000000000000 ? value.toInt() : value.toInt() * 1000;
    return DateTime.fromMillisecondsSinceEpoch(millis, isUtc: true).toLocal();
  }
  if (value is String) {
    final normalized = value.trim();
    if (normalized.isEmpty || normalized == '-') {
      return null;
    }

    final numeric = num.tryParse(normalized);
    if (numeric != null) {
      return _parseDate(numeric);
    }

    return DateTime.tryParse(normalized);
  }
  return null;
}

String _normalizeDialCode(String value) {
  final normalized = value.trim();
  if (normalized.isEmpty) {
    return '';
  }
  if (normalized.startsWith('+')) {
    return normalized;
  }
  return '+$normalized';
}

List<T> _distinctByKey<T>(
  List<T> items,
  String Function(T item) keyBuilder,
) {
  final seen = <String>{};
  final result = <T>[];

  for (final item in items) {
    final key = keyBuilder(item).trim().toLowerCase();
    if (key.isEmpty || seen.contains(key)) {
      continue;
    }
    seen.add(key);
    result.add(item);
  }

  return result;
}

List<String> _parseStringList(dynamic value) {
  if (value is List) {
    return value
        .map(_parseString)
        .whereType<String>()
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }

  if (value is String) {
    return value
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }

  return const <String>[];
}
