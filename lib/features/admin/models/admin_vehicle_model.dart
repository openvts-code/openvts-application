import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

import '../../notifications/models/app_notification.dart';
import '../../superadmin/models/superadmin_vehicle_model.dart';

class AdminVehicleListItem {
  const AdminVehicleListItem({
    required this.id,
    required this.name,
    required this.vin,
    required this.plateNumber,
    required this.isActive,
    required this.isLicenseBlocked,
    required this.licenseBlockedAt,
    required this.licenseBlockReason,
    required this.createdAt,
    required this.updatedAt,
    required this.imei,
    required this.simNumber,
    required this.vehicleType,
    required this.device,
    required this.primaryUser,
  });

  final String id;
  final String name;
  final String vin;
  final String plateNumber;
  final bool isActive;
  final bool isLicenseBlocked;
  final DateTime? licenseBlockedAt;
  final String licenseBlockReason;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String imei;
  final String simNumber;
  final AdminVehicleTypeMini? vehicleType;
  final AdminVehicleDeviceMini? device;
  final AdminVehicleUserMini? primaryUser;

  String get vehicleTypeName => vehicleType?.name ?? '';
  String get primaryUserName => primaryUser?.name ?? '';

  factory AdminVehicleListItem.fromJson(dynamic json) {
    final source = _extractMapPayload(json);
    final deviceMap = _firstMap(source, const ['device', 'tracker', 'unit']);
    final typeMap =
        _firstMap(source, const ['vehicleType', 'vehicle_type', 'vehicletype']);
    final primaryUserMap = _firstMap(source, const [
      'primaryUser',
      'primary_user',
      'userPrimary',
      'user_primary',
      'owner'
    ]);

    final id = _firstString(source, const ['id', '_id', 'vehicleId']) ?? '';
    final plateNumber = _firstString(source,
            const ['plateNumber', 'plate_number', 'plateNo', 'plate_no']) ??
        '';
    final imei = _firstString(source, const ['imei']) ??
        _firstString(deviceMap ?? const <String, dynamic>{}, const ['imei']) ??
        '';
    final simNumber = _firstString(source, const ['simNumber', 'sim_number']) ??
        _firstString(deviceMap ?? const <String, dynamic>{},
            const ['simNumber', 'sim_number', 'simNo', 'sim_no', 'sim']) ??
        _firstString(
            _firstMap(deviceMap ?? const <String, dynamic>{}, const ['sim']) ??
                const <String, dynamic>{},
            const ['simNumber', 'number']) ??
        '';

    return AdminVehicleListItem(
      id: id,
      name: _firstString(source, const ['name', 'vehicleName']) ?? plateNumber,
      vin: _firstString(source, const ['vin', 'VIN']) ?? '',
      plateNumber: plateNumber,
      isActive: _parseVehicleActive(source),
      isLicenseBlocked: _firstBool(source, const [
            'isLicenseBlocked',
            'is_license_blocked',
            'licenseBlocked',
            'license_blocked'
          ]) ??
          false,
      licenseBlockedAt: _firstDate(source, const [
        'licenseBlockedAt',
        'license_blocked_at',
      ]),
      licenseBlockReason: _firstString(
              source, const ['licenseBlockReason', 'license_block_reason']) ??
          '',
      createdAt: _firstDate(source, const ['createdAt', 'created_at']),
      updatedAt: _firstDate(source, const ['updatedAt', 'updated_at']),
      imei: imei,
      simNumber: simNumber,
      vehicleType:
          typeMap == null ? null : AdminVehicleTypeMini.fromJson(typeMap),
      device:
          deviceMap == null ? null : AdminVehicleDeviceMini.fromJson(deviceMap),
      primaryUser: primaryUserMap == null
          ? null
          : AdminVehicleUserMini.fromJson(primaryUserMap),
    );
  }

  static List<AdminVehicleListItem> listFromJson(dynamic json) {
    return _extractVehicleList(json)
        .map(AdminVehicleListItem.fromJson)
        .where((item) => item.id.isNotEmpty)
        .toList(growable: false);
  }
}

class AdminVehicleDetails {
  const AdminVehicleDetails({
    required this.id,
    required this.name,
    required this.vin,
    required this.plateNumber,
    required this.isActive,
    required this.isLicenseBlocked,
    required this.createdAt,
    required this.updatedAt,
    required this.imei,
    required this.simNumber,
    required this.vehicleType,
    required this.vehicleTypeId,
    required this.device,
    required this.primaryUser,
    required this.gmtOffset,
    required this.vehicleMeta,
    required this.plan,
  });

  final String id;
  final String name;
  final String vin;
  final String plateNumber;
  final bool isActive;
  final bool isLicenseBlocked;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String imei;
  final String simNumber;
  final AdminVehicleTypeMini? vehicleType;
  final String vehicleTypeId;
  final AdminVehicleDeviceMini? device;
  final AdminVehicleUserMini? primaryUser;
  final String gmtOffset;
  final Map<String, dynamic> vehicleMeta;
  final AdminVehiclePlanMini? plan;

  factory AdminVehicleDetails.fromJson(dynamic json, {String? fallbackId}) {
    final source = _extractMapPayload(json);
    final deviceMap = _firstMap(source, const ['device', 'tracker', 'unit']);
    final typeMap =
        _firstMap(source, const ['vehicleType', 'vehicle_type', 'vehicletype']);
    final primaryUserMap = _firstMap(source, const [
      'primaryUser',
      'primary_user',
      'userPrimary',
      'user_primary',
      'owner'
    ]);
    final planMap =
        _firstMap(source, const ['plan', 'pricingPlan', 'pricing_plan']);

    return AdminVehicleDetails(
      id: _firstString(source, const ['id', '_id', 'vehicleId']) ??
          fallbackId ??
          '',
      name: _firstString(source, const ['name', 'vehicleName']) ?? '',
      vin: _firstString(source, const ['vin', 'VIN']) ?? '',
      plateNumber:
          _firstString(source, const ['plateNumber', 'plate_number']) ?? '',
      isActive: _parseVehicleActive(source),
      isLicenseBlocked: _firstBool(source, const [
            'isLicenseBlocked',
            'is_license_blocked',
            'licenseBlocked',
            'license_blocked'
          ]) ??
          false,
      createdAt: _firstDate(source, const ['createdAt', 'created_at']),
      updatedAt: _firstDate(source, const ['updatedAt', 'updated_at']),
      imei: _firstString(source, const ['imei']) ??
          _firstString(
              deviceMap ?? const <String, dynamic>{}, const ['imei']) ??
          '',
      simNumber: _firstString(source, const ['simNumber', 'sim_number']) ??
          _firstString(deviceMap ?? const <String, dynamic>{},
              const ['simNumber', 'sim_number', 'sim']) ??
          '',
      vehicleType:
          typeMap == null ? null : AdminVehicleTypeMini.fromJson(typeMap),
      vehicleTypeId: _firstString(
              source, const ['vehicleTypeId', 'vehicle_type_id']) ??
          _firstString(typeMap ?? const <String, dynamic>{}, const ['id']) ??
          '',
      device:
          deviceMap == null ? null : AdminVehicleDeviceMini.fromJson(deviceMap),
      primaryUser: primaryUserMap == null
          ? null
          : AdminVehicleUserMini.fromJson(primaryUserMap),
      gmtOffset: _firstString(source, const ['gmtOffset', 'gmt_offset']) ?? '',
      vehicleMeta: _firstMap(source, const ['vehicleMeta', 'vehicle_meta']) ??
          const <String, dynamic>{},
      plan: planMap == null ? null : AdminVehiclePlanMini.fromJson(planMap),
    );
  }
}

class AdminVehicleTypeMini {
  const AdminVehicleTypeMini(
      {required this.id, required this.name, required this.slug});

  final String id;
  final String name;
  final String slug;

  factory AdminVehicleTypeMini.fromJson(dynamic json) {
    final source = _asMap(json);
    return AdminVehicleTypeMini(
      id: _firstString(source, const ['id', '_id']) ?? '',
      name: _firstString(source, const ['name', 'label', 'title']) ?? '',
      slug: _firstString(source, const ['slug', 'code']) ?? '',
    );
  }
}

class AdminVehicleTypeOption {
  const AdminVehicleTypeOption(
      {required this.id, required this.name, required this.slug});

  final String id;
  final String name;
  final String slug;

  factory AdminVehicleTypeOption.fromJson(dynamic json) {
    final source = _asMap(json);
    return AdminVehicleTypeOption(
      id: _firstString(source, const ['id', '_id']) ?? '',
      name: _firstString(source, const ['name', 'label']) ?? '',
      slug: _firstString(source, const ['slug', 'code']) ?? '',
    );
  }

  static List<AdminVehicleTypeOption> listFromJson(dynamic json) {
    return _extractList(json)
        .map(AdminVehicleTypeOption.fromJson)
        .where((item) => item.id.isNotEmpty)
        .toList(growable: false);
  }
}

class AdminVehicleDeviceMini {
  const AdminVehicleDeviceMini({
    required this.id,
    required this.imei,
    required this.simNumber,
    required this.speedVariation,
    required this.distanceVariation,
    required this.odometer,
    required this.engineHours,
    required this.ignitionSource,
    required this.liveOdometer,
    required this.liveEngineHours,
  });

  final String id;
  final String imei;
  final String simNumber;
  final double? speedVariation;
  final double? distanceVariation;
  final double? odometer;
  final double? engineHours;
  final String ignitionSource;
  final bool? liveOdometer;
  final bool? liveEngineHours;

  factory AdminVehicleDeviceMini.fromJson(dynamic json) {
    final source = _asMap(json);
    return AdminVehicleDeviceMini(
      id: _firstString(source, const ['id', '_id']) ?? '',
      imei: _firstString(source, const ['imei']) ?? '',
      simNumber:
          _firstString(source, const ['simNumber', 'sim_number', 'sim']) ??
              _firstString(
                  _firstMap(source, const ['sim']) ?? const <String, dynamic>{},
                  const ['simNumber', 'number']) ??
              '',
      speedVariation:
          _firstDouble(source, const ['speedVariation', 'speed_variation']),
      distanceVariation: _firstDouble(
          source, const ['distanceVariation', 'distance_variation']),
      odometer: _firstDouble(source, const ['odometer']),
      engineHours: _firstDouble(source, const ['engineHours', 'engine_hours']),
      ignitionSource:
          _firstString(source, const ['ignitionSource', 'ignition_source']) ??
              '',
      liveOdometer: _firstBool(source, const ['liveOdometer', 'live_odometer']),
      liveEngineHours:
          _firstBool(source, const ['liveEngineHours', 'live_engine_hours']),
    );
  }
}

class AdminVehicleUserMini {
  const AdminVehicleUserMini({
    required this.uid,
    required this.id,
    required this.name,
    required this.username,
    required this.email,
    required this.mobilePrefix,
    required this.mobileNumber,
    required this.mobileDisplay,
  });

  final String uid;
  final String id;
  final String name;
  final String username;
  final String email;
  final String mobilePrefix;
  final String mobileNumber;
  final String mobileDisplay;

  factory AdminVehicleUserMini.fromJson(dynamic json) {
    final source = _extractMapPayload(json);
    final uid = _firstString(source, const [
          'uid',
          'userId',
          'user_id',
          'id',
          '_id',
        ]) ??
        '';
    final prefix = _firstString(source, const [
          'mobilePrefix',
          'mobile_prefix',
          'mobileprefix',
          'phonePrefix',
          'phone_prefix',
        ]) ??
        '';
    final number = _firstString(source, const [
          'mobileNumber',
          'mobile_number',
          'mobile',
          'phoneNumber',
          'phone_number',
          'phone',
          'contactNumber',
          'contact_number',
        ]) ??
        '';
    final id = _firstString(source, const [
          'id',
          '_id',
          'uid',
          'userId',
          'user_id',
        ]) ??
        uid;

    if (kDebugMode && id.isNotEmpty) {
      debugPrint('[AdminVehicleUserMini] parsed user: id=$id, uid=$uid, name=${_firstString(source, const ['name', 'fullName', 'full_name'])}');
    }

    return AdminVehicleUserMini(
      uid: uid,
      id: id,
      name: _firstString(source, const [
            'name',
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
      mobilePrefix: prefix,
      mobileNumber: number,
      mobileDisplay: _firstString(source, const [
            'mobileDisplay',
            'mobile_display',
            'phoneDisplay',
            'phone_display',
          ]) ??
          [prefix.trim(), number.trim()]
              .where((part) => part.isNotEmpty)
              .join(' '),
    );
  }

  static List<AdminVehicleUserMini> listFromJson(dynamic json) {
    final list = _extractUserList(json);
    return list
        .map(AdminVehicleUserMini.fromJson)
        .where((item) => item.id.isNotEmpty || item.uid.isNotEmpty)
        .toList(growable: false);
  }
}

class AdminVehiclePlanMini {
  const AdminVehiclePlanMini({
    required this.id,
    required this.name,
    required this.price,
    required this.currency,
  });

  final String id;
  final String name;
  final double? price;
  final String currency;

  factory AdminVehiclePlanMini.fromJson(dynamic json) {
    final source = _asMap(json);
    return AdminVehiclePlanMini(
      id: _firstString(source, const ['id', '_id']) ?? '',
      name: _firstString(source, const ['name', 'title']) ?? '',
      price: _firstDouble(source, const ['price', 'amount']),
      currency: _firstString(source, const ['currency', 'currencyCode']) ?? '',
    );
  }
}

class AdminCreateVehicleRequest {
  const AdminCreateVehicleRequest({
    required this.name,
    required this.vin,
    required this.plateNumber,
    required this.deviceId,
    required this.vehicleTypeId,
    required this.primaryUserId,
    required this.planId,
  });

  final String name;
  final String vin;
  final String plateNumber;
  final dynamic deviceId;
  final dynamic vehicleTypeId;
  final dynamic primaryUserId;
  final dynamic planId;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'name': name.trim(),
        'vin': vin.trim(),
        'plateNumber': plateNumber.trim(),
        'deviceId': deviceId is String ? int.tryParse(deviceId) ?? deviceId : deviceId,
        'vehicleTypeId': vehicleTypeId is String ? int.tryParse(vehicleTypeId) ?? vehicleTypeId : vehicleTypeId,
        'primaryUserId': primaryUserId is String ? int.tryParse(primaryUserId) ?? primaryUserId : primaryUserId,
        'planId': planId is String ? int.tryParse(planId) ?? planId : planId,
      };
}

class AdminUpdateVehicleRequest {
  const AdminUpdateVehicleRequest({
    required this.name,
    required this.vin,
    required this.plateNumber,
    required this.vehicleTypeId,
    required this.gmtOffset,
    required this.isActive,
    required this.vehicleMeta,
  });

  final String name;
  final String vin;
  final String plateNumber;
  final int vehicleTypeId;
  final String gmtOffset;
  final bool isActive;
  final Map<String, dynamic> vehicleMeta;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'name': name.trim(),
        'vin': vin.trim(),
        'plateNumber': plateNumber.trim(),
        'vehicleTypeId': vehicleTypeId,
        'gmtOffset': gmtOffset.trim(),
        'isActive': isActive,
        'vehicleMeta': vehicleMeta,
      };
}

class AdminVehicleConfigUpdateRequest {
  const AdminVehicleConfigUpdateRequest({
    required this.speedVariation,
    required this.distanceVariation,
    required this.odometer,
    required this.engineHours,
    required this.ignitionSource,
  }) : assert(ignitionSource == 'ACC' || ignitionSource == 'MOTION');

  final double speedVariation;
  final double distanceVariation;
  final double odometer;
  final double engineHours;
  final String ignitionSource;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'speedVariation': speedVariation,
        'distanceVariation': distanceVariation,
        'odometer': odometer,
        'engineHours': engineHours,
        'ignitionSource': ignitionSource,
      };
}

typedef AdminVehicleLogPage = SuperadminVehicleLogPage;
typedef AdminVehicleLogItem = SuperadminVehicleLog;
typedef AdminVehicleEventPage = SuperadminVehicleEventPage;
typedef AdminVehicleEventItem = AppNotification;
typedef AdminVehicleCommandHistoryPage = SuperadminCommandHistoryPage;
typedef AdminVehicleCommandItem = SuperadminCommandHistoryItem;
typedef AdminCommandStatus = SuperadminCommandStatus;
typedef AdminVehicleSensor = SuperadminVehicleSensor;
typedef AdminVehicleSensorPage = SuperadminVehicleSensorPage;
typedef AdminVehicleSensorRunResult = SuperadminSendCommandResult;

class AdminVehicleSensorTelemetry {
  const AdminVehicleSensorTelemetry({
    required this.hasTelemetry,
    this.serverTime,
    this.deviceTime,
  });

  final bool hasTelemetry;
  final DateTime? serverTime;
  final DateTime? deviceTime;

  factory AdminVehicleSensorTelemetry.fromJson(dynamic json) {
    final source = _asMap(json);
    return AdminVehicleSensorTelemetry(
      hasTelemetry:
          _firstBool(source, const ['hasTelemetry', 'has_telemetry']) ?? false,
      serverTime: _firstDate(source, const ['serverTime', 'server_time']),
      deviceTime: _firstDate(source, const ['deviceTime', 'device_time']),
    );
  }
}

typedef AdminCustomCommand = SuperadminCustomCommand;
typedef AdminSystemVariable = SuperadminSystemVariable;
typedef AdminSendCommandResult = SuperadminSendCommandResult;

class AdminVehicleDocument {
  const AdminVehicleDocument({
    required this.id,
    required this.title,
    required this.docTypeId,
    required this.docTypeName,
    required this.url,
    required this.fileName,
    required this.isVisible,
    required this.tags,
    required this.description,
    required this.expiryAt,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String docTypeId;
  final String docTypeName;
  final String url;
  final String fileName;
  final bool isVisible;
  final String tags;
  final String description;
  final DateTime? expiryAt;
  final DateTime? createdAt;

  factory AdminVehicleDocument.fromJson(dynamic json) {
    final source = _asMap(json);
    final docType = _firstMap(source, const ['docType', 'documentType']);
    return AdminVehicleDocument(
      id: _firstString(source, const ['id', '_id']) ?? '',
      title: _firstString(source, const ['title', 'name']) ?? '',
      docTypeId: _firstString(source, const ['docTypeId', 'doc_type_id']) ??
          _firstString(docType ?? const <String, dynamic>{}, const ['id']) ??
          '',
      docTypeName: _firstString(
              source, const ['docTypeName', 'doc_type_name']) ??
          _firstString(docType ?? const <String, dynamic>{}, const ['name']) ??
          '',
      url: _firstString(source, const ['url', 'fileUrl', 'file_url']) ?? '',
      fileName: _firstString(source, const [
            'fileName',
            'file_name',
            'originalName',
            'original_name',
            'name'
          ]) ??
          '',
      isVisible: _firstBool(source, const ['isVisible', 'is_visible']) ?? true,
      tags: _firstString(source, const ['tags']) ?? '',
      description: _firstString(source, const ['description']) ?? '',
      expiryAt: _firstDate(source, const ['expiryAt', 'expiry_at']),
      createdAt: _firstDate(source, const ['createdAt', 'created_at']),
    );
  }

  static List<AdminVehicleDocument> listFromJson(dynamic json) {
    return _extractList(json)
        .map(AdminVehicleDocument.fromJson)
        .where((item) => item.id.isNotEmpty)
        .toList(growable: false);
  }
}

class AdminVehicleDocumentType {
  const AdminVehicleDocumentType({
    required this.id,
    required this.name,
    required this.slug,
  });

  final String id;
  final String name;
  final String slug;

  factory AdminVehicleDocumentType.fromJson(dynamic json) {
    final source = _asMap(json);
    return AdminVehicleDocumentType(
      id: _firstString(source, const ['id', '_id']) ?? '',
      name: _firstString(source, const ['name', 'title']) ?? '',
      slug: _firstString(source, const ['slug', 'code']) ?? '',
    );
  }

  static List<AdminVehicleDocumentType> listFromJson(dynamic json) {
    return _extractList(json)
        .map(AdminVehicleDocumentType.fromJson)
        .where((item) => item.id.isNotEmpty)
        .toList(growable: false);
  }
}

class AdminQuickDeviceOption {
  const AdminQuickDeviceOption({
    required this.id,
    required this.imei,
    required this.simNumber,
    required this.name,
  });

  final String id;
  final String imei;
  final String simNumber;
  final String name;

  factory AdminQuickDeviceOption.fromJson(dynamic json) {
    final source = _asMap(json);
    return AdminQuickDeviceOption(
      id: _firstString(source, const ['id', '_id']) ?? '',
      imei: _firstString(source, const ['imei']) ?? '',
      simNumber: _firstString(source, const ['simNumber', 'sim_number']) ?? '',
      name: _firstString(source, const ['name', 'label', 'title']) ?? '',
    );
  }

  static List<AdminQuickDeviceOption> listFromJson(dynamic json) {
    return _extractList(json)
        .map(AdminQuickDeviceOption.fromJson)
        .where((item) => item.id.isNotEmpty)
        .toList(growable: false);
  }
}

class AdminPricingPlanOption {
  const AdminPricingPlanOption({
    required this.id,
    required this.name,
    required this.price,
    required this.currency,
  });

  final String id;
  final String name;
  final double? price;
  final String currency;

  factory AdminPricingPlanOption.fromJson(dynamic json) {
    final source = _asMap(json);
    return AdminPricingPlanOption(
      id: _firstString(source, const ['id', '_id']) ?? '',
      name: _firstString(source, const ['name', 'title']) ?? '',
      price: _firstDouble(source, const ['price', 'amount']),
      currency: _firstString(source, const ['currency', 'currencyCode']) ?? '',
    );
  }

  static List<AdminPricingPlanOption> listFromJson(dynamic json) {
    return _extractList(json)
        .map(AdminPricingPlanOption.fromJson)
        .where((item) => item.id.isNotEmpty)
        .toList(growable: false);
  }
}

class AdminVehicleDocumentRequest {
  const AdminVehicleDocumentRequest({
    required this.title,
    required this.docTypeId,
    required this.vehicleId,
    required this.isVisible,
    required this.tags,
    required this.description,
    this.expiryAt,
    this.file,
  });

  final String title;
  final String docTypeId;
  final String vehicleId;
  final bool isVisible;
  final String tags;
  final String description;
  final DateTime? expiryAt;
  final PlatformFile? file;
}

class AdminVehicleSensorUpsertRequest {
  const AdminVehicleSensorUpsertRequest({
    required this.name,
    required this.unit,
    required this.code,
    required this.isActive,
    this.icon = '',
    this.slug = '',
    this.formula = '',
    this.meta = const <String, dynamic>{},
  });

  final String name;
  final String icon;
  final String code;
  final String slug;
  final String unit;
  final String formula;
  final bool isActive;
  final Map<String, dynamic> meta;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'name': name,
        'icon': icon,
        'code': code,
        'slug': slug.trim().isEmpty ? code : slug,
        'unit': unit,
        'formula': formula.trim().isEmpty ? code : formula,
        'isActive': isActive,
        'meta': meta,
      };
}

class AdminVehicleSensorRunRequest {
  const AdminVehicleSensorRunRequest({
    required this.code,
    this.payload = const <String, dynamic>{},
  });

  final String code;
  final Map<String, dynamic> payload;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'code': code,
        'payload': payload,
      };
}

bool _parseVehicleActive(Map<String, dynamic> source) {
  final raw = _firstValue(source, const ['isActive', 'is_active', 'status']);
  if (raw == null) {
    return true;
  }
  if (raw is bool) {
    return raw;
  }
  if (raw is num) {
    return raw > 0;
  }
  final text = raw.toString().trim().toLowerCase();
  if (text.isEmpty) {
    return true;
  }
  if (text == 'active' || text == 'online' || text == 'enabled') {
    return true;
  }
  if (text == 'inactive' || text == 'disabled' || text == 'offline') {
    return false;
  }
  return text == 'true' || text == '1' || text == 'yes';
}

List<dynamic> _extractVehicleList(dynamic json) {
  if (json is List) {
    return json;
  }

  final source = _asMap(json);
  final data = _asMap(source['data']);

  return _firstList(source, const ['vehicles']) ??
      _firstList(data, const ['vehicles']) ??
      _firstList(source, const ['data']) ??
      _firstList(data, const ['data']) ??
      _extractList(source);
}

Map<String, dynamic> _extractMapPayload(dynamic json) {
  final source = _asMap(json);
  if (source.isEmpty) {
    return const <String, dynamic>{};
  }

  final data = _asMap(source['data']);

  for (final key in const ['vehicle', 'details', 'item', 'result']) {
    final nested =
        _firstMap(source, <String>[key]) ?? _firstMap(data, <String>[key]);
    if (nested != null && nested.isNotEmpty) {
      return nested;
    }
  }

  if (data.isNotEmpty && _firstMap(data, const ['data']) != null) {
    return _firstMap(data, const ['data'])!;
  }

  return data.isNotEmpty ? data : source;
}

List<dynamic> _extractList(dynamic json) {
  if (json is List) {
    return json;
  }
  final source = _asMap(json);
  if (source.isEmpty) {
    return const <dynamic>[];
  }

  return _firstList(source,
          const ['users', 'result', 'items', 'rows', 'records', 'docs']) ??
      _firstList(source, const ['data']) ??
      _firstList(_asMap(source['data']),
          const ['users', 'items', 'rows', 'records', 'docs']) ??
      _firstList(_asMap(source['data']), const ['data']) ??
      const <dynamic>[];
}

List<dynamic> _extractUserList(dynamic json) {
  if (json is List) {
    return json;
  }
  final source = _asMap(json);
  if (source.isEmpty) {
    return const <dynamic>[];
  }

  final data = _asMap(source['data']);
  final result = _asMap(source['result']);

  return _firstList(source, const [
        'userslist',
        'usersList',
        'users',
        'items',
        'rows',
        'records',
        'docs',
        'list',
        'result',
        'data',
      ]) ??
      _firstList(data, const [
        'userslist',
        'usersList',
        'users',
        'items',
        'rows',
        'records',
        'docs',
        'list',
        'result',
        'data',
      ]) ??
      _firstList(result, const [
        'userslist',
        'usersList',
        'users',
        'items',
        'rows',
        'records',
        'docs',
        'list',
      ]) ??
      const <dynamic>[];
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

List<dynamic>? _firstList(Map<String, dynamic> source, List<String> keys) {
  for (final key in keys) {
    final value = source[key];
    if (value is List) {
      return value;
    }
  }
  return null;
}

Map<String, dynamic>? _firstMap(
    Map<String, dynamic> source, List<String> keys) {
  for (final key in keys) {
    final value = _asMap(source[key]);
    if (value.isNotEmpty) {
      return value;
    }
  }
  return null;
}

dynamic _firstValue(Map<String, dynamic> source, List<String> keys) {
  for (final key in keys) {
    if (source.containsKey(key)) {
      return source[key];
    }
  }
  return null;
}

String? _firstString(Map<String, dynamic> source, List<String> keys) {
  final value = _firstValue(source, keys);
  if (value == null) {
    return null;
  }
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

bool? _firstBool(Map<String, dynamic> source, List<String> keys) {
  final value = _firstValue(source, keys);
  if (value == null) {
    return null;
  }
  if (value is bool) {
    return value;
  }
  if (value is num) {
    return value > 0;
  }
  final text = value.toString().trim().toLowerCase();
  if (text.isEmpty) {
    return null;
  }
  if (text == 'true' || text == '1' || text == 'yes' || text == 'active') {
    return true;
  }
  if (text == 'false' || text == '0' || text == 'no' || text == 'inactive') {
    return false;
  }
  return null;
}

double? _firstDouble(Map<String, dynamic> source, List<String> keys) {
  final value = _firstValue(source, keys);
  if (value == null) {
    return null;
  }
  if (value is num) {
    return value.toDouble();
  }
  return double.tryParse(value.toString().trim());
}

DateTime? _firstDate(Map<String, dynamic> source, List<String> keys) {
  final value = _firstValue(source, keys);
  if (value == null) {
    return null;
  }
  if (value is DateTime) {
    return value;
  }
  if (value is num) {
    final intValue = value.toInt();
    return DateTime.fromMillisecondsSinceEpoch(
      intValue > 1000000000000 ? intValue : intValue * 1000,
      isUtc: true,
    ).toLocal();
  }
  return DateTime.tryParse(value.toString().trim())?.toLocal();
}
