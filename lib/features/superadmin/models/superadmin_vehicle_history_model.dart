import '../../../shared/models/vehicle_summary.dart';

class SuperadminVehicleHistoryRequest {
  const SuperadminVehicleHistoryRequest({
    required this.vehicle,
    required this.from,
    required this.to,
    required this.stopMinutes,
  });

  final VehicleSummary vehicle;
  final DateTime from;
  final DateTime to;
  final int stopMinutes;

  String get imei => vehicle.imei.trim();

  String get vehicleLabel {
    final name = vehicle.name.trim();
    if (name.isNotEmpty) {
      return name;
    }

    final plateNumber = vehicle.plateNumber.trim();
    if (plateNumber.isNotEmpty) {
      return plateNumber;
    }

    return imei.isEmpty ? 'Vehicle' : imei;
  }
}

class SuperadminVehicleHistoryState {
  const SuperadminVehicleHistoryState({
    required this.request,
    required this.history,
    required this.isLoading,
    required this.errorMessage,
  });

  const SuperadminVehicleHistoryState.initial()
      : request = null,
        history = null,
        isLoading = false,
        errorMessage = null;

  final SuperadminVehicleHistoryRequest? request;
  final SuperadminVehicleHistory? history;
  final bool isLoading;
  final String? errorMessage;

  bool get hasHistory =>
      history != null &&
      (history!.points.isNotEmpty ||
          history!.segments.isNotEmpty ||
          history!.stopMarkers.isNotEmpty);

  SuperadminVehicleHistoryState copyWith({
    SuperadminVehicleHistoryRequest? request,
    SuperadminVehicleHistory? history,
    bool? isLoading,
    String? errorMessage,
    bool clearHistory = false,
    bool clearErrorMessage = false,
  }) {
    return SuperadminVehicleHistoryState(
      request: request ?? this.request,
      history: clearHistory ? null : history ?? this.history,
      isLoading: isLoading ?? this.isLoading,
      errorMessage:
          clearErrorMessage ? null : errorMessage ?? this.errorMessage,
    );
  }
}

class SuperadminVehicleHistory {
  const SuperadminVehicleHistory({
    required this.request,
    required this.points,
    required this.segments,
    required this.stopMarkers,
    required this.overspeedSegments,
    this.analytics = const SuperadminVehicleHistoryAnalytics(),
    this.totalDistanceKm,
    this.maxSpeedKph,
  });

  final SuperadminVehicleHistoryRequest request;
  final List<SuperadminVehicleHistoryPoint> points;
  final List<SuperadminVehicleHistorySegment> segments;
  final List<SuperadminVehicleHistoryStopMarker> stopMarkers;
  final List<SuperadminVehicleHistorySegment> overspeedSegments;
  final SuperadminVehicleHistoryAnalytics analytics;
  final double? totalDistanceKm;
  final double? maxSpeedKph;

  int get pointCount => points.length;

  int get segmentCount => segments.length;

  int get stopCount => stopMarkers.length;

  int get overspeedCount => overspeedSegments.length;

  List<SuperadminVehicleHistoryPoint> get validPathPoints {
    return points
        .where((point) => point.hasCoordinates)
        .toList(growable: false);
  }

  SuperadminVehicleHistoryPoint? get startPoint {
    for (final point in points) {
      if (point.hasCoordinates) {
        return point;
      }
    }

    return null;
  }

  SuperadminVehicleHistoryPoint? get endPoint {
    for (final point in points.reversed) {
      if (point.hasCoordinates) {
        return point;
      }
    }

    return null;
  }

  DateTime? get firstTimestamp {
    for (final point in points) {
      if (point.timestamp != null) {
        return point.timestamp;
      }
    }

    return null;
  }

  DateTime? get lastTimestamp {
    for (final point in points.reversed) {
      if (point.timestamp != null) {
        return point.timestamp;
      }
    }

    return null;
  }
}

class SuperadminVehicleHistoryAnalytics {
  const SuperadminVehicleHistoryAnalytics({
    this.totalDistanceKm,
    this.movingTimeSec,
    this.idleTimeSec,
    this.stopTimeSec,
    this.maxSpeedKph,
    this.avgMovingSpeedKph,
    this.stopsCount,
    this.pointsReturned,
    this.overspeedCount,
  });

  final double? totalDistanceKm;
  final int? movingTimeSec;
  final int? idleTimeSec;
  final int? stopTimeSec;
  final double? maxSpeedKph;
  final double? avgMovingSpeedKph;
  final int? stopsCount;
  final int? pointsReturned;
  final int? overspeedCount;

  double? get averageSpeedKph => avgMovingSpeedKph;

  int? get stopCount => stopsCount;

  Duration? get runningDuration => movingTimeSec == null
      ? null
      : Duration(seconds: movingTimeSec! < 0 ? 0 : movingTimeSec!);

  Duration? get stoppedDuration => stopTimeSec == null
      ? null
      : Duration(seconds: stopTimeSec! < 0 ? 0 : stopTimeSec!);
}

enum SuperadminVehicleHistorySegmentType { drive, idle, stop, overspeed, other }

enum SuperadminVehicleHistorySegmentKind { running, stop, other }

class SuperadminVehicleHistorySegment {
  const SuperadminVehicleHistorySegment({
    required this.id,
    required this.type,
    required this.rawType,
    required this.startIndex,
    required this.endIndex,
    required this.startTime,
    required this.endTime,
    required this.durationSec,
    required this.distanceKm,
    required this.maxSpeedKph,
    required this.avgSpeedKph,
    this.address = '',
    this.reason = '',
    required this.latitude,
    required this.longitude,
    required this.startLatitude,
    required this.startLongitude,
    required this.endLatitude,
    required this.endLongitude,
  });

  final String id;
  final SuperadminVehicleHistorySegmentType type;
  final String rawType;
  final int? startIndex;
  final int? endIndex;
  final DateTime? startTime;
  final DateTime? endTime;
  final int? durationSec;
  final String address;
  final String reason;
  final double? distanceKm;
  final double? maxSpeedKph;
  final double? avgSpeedKph;
  final double? latitude;
  final double? longitude;
  final double? startLatitude;
  final double? startLongitude;
  final double? endLatitude;
  final double? endLongitude;

  Duration? get duration => durationSec == null
      ? null
      : Duration(seconds: durationSec! < 0 ? 0 : durationSec!);

  SuperadminVehicleHistorySegmentKind get kind {
    return switch (type) {
      SuperadminVehicleHistorySegmentType.drive ||
      SuperadminVehicleHistorySegmentType.overspeed =>
        SuperadminVehicleHistorySegmentKind.running,
      SuperadminVehicleHistorySegmentType.idle ||
      SuperadminVehicleHistorySegmentType.stop =>
        SuperadminVehicleHistorySegmentKind.stop,
      SuperadminVehicleHistorySegmentType.other =>
        SuperadminVehicleHistorySegmentKind.other,
    };
  }

  bool get hasCoordinates => latitude != null && longitude != null;

  bool get hasStartCoordinates =>
      startLatitude != null && startLongitude != null;

  bool get hasEndCoordinates => endLatitude != null && endLongitude != null;
}

class SuperadminVehicleHistoryPoint {
  const SuperadminVehicleHistoryPoint({
    required this.serverTime,
    required this.deviceTime,
    required this.latitude,
    required this.longitude,
    required this.speedKph,
    required this.course,
    required this.ignition,
    required this.acc,
    required this.status,
    required this.address,
    required this.eventLabel,
    required this.distanceKm,
    required this.stopDuration,
  });

  final DateTime? serverTime;
  final DateTime? deviceTime;
  final double? latitude;
  final double? longitude;
  final double? speedKph;
  final double? course;
  final bool? ignition;
  final bool? acc;
  final String status;
  final String address;
  final String eventLabel;
  final double? distanceKm;
  final Duration? stopDuration;

  DateTime? get timestamp => serverTime ?? deviceTime;

  bool get hasCoordinates => latitude != null && longitude != null;
}

enum SuperadminVehicleHistoryStopMarkerType { idle, stop, other }

class SuperadminVehicleHistoryStopMarker {
  const SuperadminVehicleHistoryStopMarker({
    required this.segmentId,
    required this.type,
    required this.startTime,
    required this.endTime,
    required this.latitude,
    required this.longitude,
    required this.durationSec,
    this.address = '',
    this.reason = '',
  });

  final String segmentId;
  final SuperadminVehicleHistoryStopMarkerType type;
  final DateTime? startTime;
  final DateTime? endTime;
  final double? latitude;
  final double? longitude;
  final int? durationSec;
  final String address;
  final String reason;

  Duration? get duration => durationSec == null
      ? null
      : Duration(seconds: durationSec! < 0 ? 0 : durationSec!);

  bool get hasCoordinates => latitude != null && longitude != null;
}
