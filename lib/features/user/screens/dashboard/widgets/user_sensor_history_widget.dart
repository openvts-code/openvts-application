import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/open_vts_colors.dart';
import '../../../../../core/theme/open_vts_radius.dart';
import '../../../../../core/theme/open_vts_spacing.dart';
import '../../../../../core/theme/open_vts_typography.dart';
import '../../../../../shared/widgets/open_vts_date_time_range_selector.dart';
import '../../../controllers/user_providers.dart';
import '../../../models/user_dashboard_model.dart';
import 'user_dashboard_widget_card.dart';

class UserSensorHistoryWidget extends ConsumerStatefulWidget {
  const UserSensorHistoryWidget({
    required this.config,
    required this.refreshTick,
    super.key,
  });

  final UserDashboardWidgetConfig config;
  final int refreshTick;

  @override
  ConsumerState<UserSensorHistoryWidget> createState() =>
      _UserSensorHistoryWidgetState();
}

class _UserSensorHistoryWidgetState
    extends ConsumerState<UserSensorHistoryWidget> {
  String? _selectedVehicleId;
  String? _selectedSensorId;
  late OpenVtsDateTimeRange _range;
  late Future<_SensorHistoryViewData> _future;

  @override
  void initState() {
    super.initState();
    _selectedVehicleId = userDashboardPropString(
      widget.config.props,
      const ['vehicleId', 'vehicle_id'],
    );
    _selectedSensorId = userDashboardPropString(
      widget.config.props,
      const ['sensorId', 'sensor_id'],
    );
    _range = _initialRange(widget.config.props);
    _future = _load();
  }

  @override
  void didUpdateWidget(covariant UserSensorHistoryWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshTick != widget.refreshTick ||
        oldWidget.config.id != widget.config.id) {
      _reload();
    }
  }

  Future<_SensorHistoryViewData> _load() async {
    final service = ref.read(userDashboardServiceProvider);
    final vehicles = await service.getVehicles();
    if (vehicles.isEmpty) {
      return const _SensorHistoryViewData.empty(
        vehicles: [],
        sensors: [],
        message: 'No vehicles available.',
      );
    }

    final vehicleId = _resolveVehicleId(vehicles);
    final sensors = await service.getVehicleSensors(vehicleId);
    if (sensors.isEmpty) {
      return _SensorHistoryViewData.empty(
        vehicles: vehicles,
        sensors: const [],
        selectedVehicleId: vehicleId,
        message:
            'No sensors available for ${_vehicleName(vehicles, vehicleId)}.',
      );
    }

    final sensorId = _resolveSensorId(sensors);
    final normalizedRange = _range.normalized(dateTimeEnabled: true);
    final fallbackRange = _todayRange();
    final from = normalizedRange.start ?? fallbackRange.start!;
    final to = normalizedRange.end ?? fallbackRange.end!;
    final start = from.isAfter(to) ? to : from;
    final end = from.isAfter(to) ? from : to;
    final history = await service.getSensorHistory(
      vehicleId: vehicleId,
      sensorId: sensorId,
      from: start,
      to: end,
      maxPoints: 500,
    );

    return _SensorHistoryViewData(
      vehicles: vehicles,
      sensors: sensors,
      selectedVehicleId: vehicleId,
      selectedSensorId: sensorId,
      history: history,
    );
  }

  String _resolveVehicleId(List<UserDashboardVehicleOption> vehicles) {
    final current = _selectedVehicleId;
    if (current != null && vehicles.any((vehicle) => vehicle.id == current)) {
      return current;
    }
    final next = vehicles.first.id;
    _selectedVehicleId = next;
    return next;
  }

  String _resolveSensorId(List<UserDashboardSensorOption> sensors) {
    final current = _selectedSensorId;
    if (current != null && sensors.any((sensor) => sensor.id == current)) {
      return current;
    }
    final next = sensors.first.id;
    _selectedSensorId = next;
    return next;
  }

  void _reload() {
    setState(() {
      _future = _load();
    });
  }

  void _changeVehicle(String? value) {
    if (value == null || value == _selectedVehicleId) return;
    setState(() {
      _selectedVehicleId = value;
      _selectedSensorId = null;
      _future = _load();
    });
  }

  void _changeSensor(String? value) {
    if (value == null || value == _selectedSensorId) return;
    setState(() {
      _selectedSensorId = value;
      _future = _load();
    });
  }

  void _changeRange(OpenVtsDateTimeRange value) {
    setState(() {
      _range = value.normalized(dateTimeEnabled: true);
      _future = _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_SensorHistoryViewData>(
      future: _future,
      builder: (context, snapshot) {
        final isLoading = snapshot.connectionState != ConnectionState.done;
        return UserDashboardWidgetCard(
          title: widget.config.title,
          icon: Icons.sensors_rounded,
          isLoading: isLoading,
          onRefresh: _reload,
          child: _buildBody(snapshot),
        );
      },
    );
  }

  Widget _buildBody(AsyncSnapshot<_SensorHistoryViewData> snapshot) {
    if (snapshot.hasError) {
      return UserDashboardWidgetError(
        message: snapshot.error.toString(),
        onRetry: _reload,
      );
    }

    final data = snapshot.data;
    if (data == null) {
      return const _SensorHistorySkeleton();
    }

    final history = data.history;
    final selectedSensor = data.selectedSensor;
    final unit = selectedSensor?.unit ?? history?.sensor?.unit ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (data.vehicles.isNotEmpty) ...[
          _VehicleSelector(
            vehicles: data.vehicles,
            value: data.selectedVehicleId,
            onChanged: _changeVehicle,
          ),
          const SizedBox(height: OpenVtsSpacing.sm),
        ],
        if (data.sensors.isNotEmpty) ...[
          _SensorSelector(
            sensors: data.sensors,
            value: data.selectedSensorId,
            onChanged: _changeSensor,
          ),
          const SizedBox(height: OpenVtsSpacing.sm),
        ],
        OpenVtsDateTimeRangeField(
          label: 'Range',
          title: 'Sensor History Range',
          value: _range,
          dateTimeEnabled: true,
          lastDate: DateTime.now(),
          onChanged: _changeRange,
        ),
        const SizedBox(height: OpenVtsSpacing.md),
        if (data.emptyMessage != null)
          UserDashboardWidgetEmpty(
            message: data.emptyMessage!,
            icon: Icons.sensors_off_outlined,
          )
        else if (history != null && !history.supported)
          UserDashboardWidgetEmpty(
            message: history.reason ?? 'This sensor history is not supported.',
            icon: Icons.sensors_off_outlined,
          )
        else if (history == null || history.points.isEmpty)
          const UserDashboardWidgetEmpty(
            message: 'No sensor points for this range.',
            icon: Icons.show_chart_rounded,
          )
        else ...[
          _SensorSummary(
            sensor: selectedSensor ?? history.sensor,
            vehicleName: _vehicleName(data.vehicles, data.selectedVehicleId),
            unit: unit,
          ),
          const SizedBox(height: OpenVtsSpacing.sm),
          _SensorStatsGrid(stats: history.stats, unit: unit),
          const SizedBox(height: OpenVtsSpacing.md),
          _SensorHistoryChart(points: history.points, unit: unit),
        ],
      ],
    );
  }

  static String _vehicleName(
    List<UserDashboardVehicleOption> vehicles,
    String? id,
  ) {
    for (final vehicle in vehicles) {
      if (vehicle.id == id) return vehicle.name;
    }
    return 'selected vehicle';
  }

  static OpenVtsDateTimeRange _initialRange(Map<String, dynamic> props) {
    final from = userDashboardPropDateTime(props, const ['from']);
    final to = userDashboardPropDateTime(props, const ['to']);
    if (from != null || to != null) {
      return OpenVtsDateTimeRange(start: from, end: to)
          .normalized(dateTimeEnabled: true);
    }
    return _todayRange();
  }

  static OpenVtsDateTimeRange _todayRange() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    return OpenVtsDateTimeRange(start: start, end: now);
  }
}

class _VehicleSelector extends StatelessWidget {
  const _VehicleSelector({
    required this.vehicles,
    required this.value,
    required this.onChanged,
  });

  final List<UserDashboardVehicleOption> vehicles;
  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      key: ValueKey(value),
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'Vehicle',
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: OpenVtsSpacing.sm,
          vertical: OpenVtsSpacing.xs,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(OpenVtsRadius.md),
          borderSide: const BorderSide(color: OpenVtsColors.border),
        ),
      ),
      items: [
        for (final vehicle in vehicles)
          DropdownMenuItem<String>(
            value: vehicle.id,
            child: Text(
              _label(vehicle),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
      onChanged: onChanged,
    );
  }

  static String _label(UserDashboardVehicleOption vehicle) {
    final plate = vehicle.plateNumber?.trim();
    if (plate != null && plate.isNotEmpty) {
      return '${vehicle.name} - $plate';
    }
    return vehicle.name;
  }
}

class _SensorSelector extends StatelessWidget {
  const _SensorSelector({
    required this.sensors,
    required this.value,
    required this.onChanged,
  });

  final List<UserDashboardSensorOption> sensors;
  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      key: ValueKey(value),
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'Sensor',
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: OpenVtsSpacing.sm,
          vertical: OpenVtsSpacing.xs,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(OpenVtsRadius.md),
          borderSide: const BorderSide(color: OpenVtsColors.border),
        ),
      ),
      items: [
        for (final sensor in sensors)
          DropdownMenuItem<String>(
            value: sensor.id,
            child: Text(
              _label(sensor),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
      onChanged: onChanged,
    );
  }

  static String _label(UserDashboardSensorOption sensor) {
    final unit = sensor.unit?.trim();
    if (unit != null && unit.isNotEmpty) return '${sensor.name} ($unit)';
    return sensor.name;
  }
}

class _SensorSummary extends StatelessWidget {
  const _SensorSummary({
    required this.sensor,
    required this.vehicleName,
    required this.unit,
  });

  final UserDashboardSensorOption? sensor;
  final String vehicleName;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final sensorName = sensor?.name ?? 'Sensor';
    final unitLabel = unit.trim().isEmpty ? 'No unit' : unit;
    return Container(
      padding: const EdgeInsets.all(OpenVtsSpacing.sm),
      decoration: BoxDecoration(
        color: OpenVtsColors.surface,
        borderRadius: BorderRadius.circular(OpenVtsRadius.md),
        border: Border.all(color: OpenVtsColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: OpenVtsColors.surfaceElevated,
              borderRadius: BorderRadius.circular(OpenVtsRadius.sm),
              border: Border.all(color: OpenVtsColors.border),
            ),
            child: const Icon(
              Icons.sensors_rounded,
              size: 16,
              color: OpenVtsColors.textSecondary,
            ),
          ),
          const SizedBox(width: OpenVtsSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sensorName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: OpenVtsTypography.label.copyWith(
                    color: OpenVtsColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$vehicleName - $unitLabel',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: OpenVtsTypography.meta.copyWith(
                    color: OpenVtsColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SensorStatsGrid extends StatelessWidget {
  const _SensorStatsGrid({required this.stats, required this.unit});

  final UserDashboardSensorHistoryStats stats;
  final String unit;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: OpenVtsSpacing.xs,
      mainAxisSpacing: OpenVtsSpacing.xs,
      childAspectRatio: 2.35,
      children: [
        UserDashboardMetricTile(
          label: 'Min',
          value: _formatSensorValue(stats.min, unit),
        ),
        UserDashboardMetricTile(
          label: 'Max',
          value: _formatSensorValue(stats.max, unit),
        ),
        UserDashboardMetricTile(
          label: 'Avg',
          value: _formatSensorValue(stats.avg, unit),
        ),
        UserDashboardMetricTile(
          label: 'First',
          value: _formatSensorValue(stats.first, unit),
        ),
        UserDashboardMetricTile(
          label: 'Last',
          value: _formatSensorValue(stats.last, unit),
        ),
      ],
    );
  }
}

class _SensorHistoryChart extends StatelessWidget {
  const _SensorHistoryChart({required this.points, required this.unit});

  final List<UserDashboardSensorHistoryPoint> points;
  final String unit;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 172,
      child: CustomPaint(
        painter: _SensorHistoryChartPainter(points: points, unit: unit),
        size: Size.infinite,
      ),
    );
  }
}

class _SensorHistoryChartPainter extends CustomPainter {
  const _SensorHistoryChartPainter({required this.points, required this.unit});

  final List<UserDashboardSensorHistoryPoint> points;
  final String unit;

  @override
  void paint(Canvas canvas, Size size) {
    final validPoints =
        points.where((point) => point.v != null).toList(growable: false);
    if (validPoints.isEmpty || size.width <= 0 || size.height <= 0) return;

    const left = 36.0;
    const right = 10.0;
    const top = 10.0;
    const bottom = 24.0;
    final chartWidth = math.max(size.width - left - right, 1).toDouble();
    final chartHeight = math.max(size.height - top - bottom, 1).toDouble();
    final minValue = validPoints.fold<double>(
      validPoints.first.v!,
      (minValue, point) => math.min(minValue, point.v!),
    );
    final maxValue = validPoints.fold<double>(
      validPoints.first.v!,
      (maxValue, point) => math.max(maxValue, point.v!),
    );
    final valueSpan = math.max(maxValue - minValue, 1).toDouble();
    final startTime = validPoints.first.t;
    final endTime = validPoints.last.t;
    final timeSpanMs = startTime != null && endTime != null
        ? math.max(endTime.difference(startTime).inMilliseconds, 1)
        : 1;

    final gridPaint = Paint()
      ..color = OpenVtsColors.border
      ..strokeWidth = 1;
    for (var line = 0; line < 4; line++) {
      final y = top + chartHeight * line / 3;
      canvas.drawLine(
          Offset(left, y), Offset(size.width - right, y), gridPaint);
    }

    final areaPath = Path();
    final linePath = Path();
    final offsets = <Offset>[];
    for (var index = 0; index < validPoints.length; index++) {
      final point = validPoints[index];
      final x = _xForPoint(
        point,
        index,
        validPoints.length,
        startTime,
        timeSpanMs,
        left,
        chartWidth,
      );
      final value = point.v!;
      final y =
          top + chartHeight - chartHeight * ((value - minValue) / valueSpan);
      final offset = Offset(x, y);
      offsets.add(offset);
      if (index == 0) {
        linePath.moveTo(offset.dx, offset.dy);
        areaPath.moveTo(offset.dx, top + chartHeight);
        areaPath.lineTo(offset.dx, offset.dy);
      } else {
        linePath.lineTo(offset.dx, offset.dy);
        areaPath.lineTo(offset.dx, offset.dy);
      }
    }
    areaPath.lineTo(offsets.last.dx, top + chartHeight);
    areaPath.close();

    canvas.drawPath(
      areaPath,
      Paint()
        ..color = OpenVtsColors.brandInk.withValues(alpha: 0.08)
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      linePath,
      Paint()
        ..color = OpenVtsColors.brandInk
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    final pointPaint = Paint()..color = OpenVtsColors.brandInk;
    for (final offset in offsets.take(24)) {
      canvas.drawCircle(offset, 2.4, pointPaint);
    }

    _paintLabel(
      canvas,
      _axisValue(maxValue),
      const Offset(0, top),
      alignment: TextAlign.left,
    );
    _paintLabel(
      canvas,
      _axisValue(minValue),
      Offset(0, top + chartHeight - 10),
      alignment: TextAlign.left,
    );
    if (validPoints.first.t != null) {
      _paintLabel(
        canvas,
        userDashboardFormatShortTime(validPoints.first.t),
        Offset(left, top + chartHeight + 8),
        alignment: TextAlign.left,
      );
    }
    if (validPoints.last.t != null) {
      _paintLabel(
        canvas,
        userDashboardFormatShortTime(validPoints.last.t),
        Offset(size.width - right, top + chartHeight + 8),
        alignment: TextAlign.right,
      );
    }
  }

  double _xForPoint(
    UserDashboardSensorHistoryPoint point,
    int index,
    int count,
    DateTime? startTime,
    int timeSpanMs,
    double left,
    double chartWidth,
  ) {
    if (point.t != null && startTime != null) {
      final elapsed = point.t!.difference(startTime).inMilliseconds;
      return left + chartWidth * (elapsed / timeSpanMs).clamp(0.0, 1.0);
    }
    final denominator = math.max(count - 1, 1).toDouble();
    return left + chartWidth * index / denominator;
  }

  String _axisValue(double value) {
    final suffix = unit.trim().isEmpty ? '' : ' $unit';
    return '${userDashboardFormatDecimal(value, digits: 1)}$suffix';
  }

  void _paintLabel(
    Canvas canvas,
    String text,
    Offset offset, {
    required TextAlign alignment,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: OpenVtsTypography.meta.copyWith(
          color: OpenVtsColors.textTertiary,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: alignment,
      maxLines: 1,
      ellipsis: '',
    )..layout(maxWidth: 92);

    final dx = switch (alignment) {
      TextAlign.right => offset.dx - painter.width,
      TextAlign.center => offset.dx - painter.width / 2,
      _ => offset.dx,
    };
    painter.paint(canvas, Offset(dx, offset.dy));
  }

  @override
  bool shouldRepaint(covariant _SensorHistoryChartPainter oldDelegate) {
    return oldDelegate.points != points || oldDelegate.unit != unit;
  }
}

class _SensorHistorySkeleton extends StatelessWidget {
  const _SensorHistorySkeleton();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(height: 230);
  }
}

class _SensorHistoryViewData {
  const _SensorHistoryViewData({
    required this.vehicles,
    required this.sensors,
    this.selectedVehicleId,
    this.selectedSensorId,
    this.history,
  }) : emptyMessage = null;

  const _SensorHistoryViewData.empty({
    required this.vehicles,
    required this.sensors,
    required String message,
    this.selectedVehicleId,
  })  : history = null,
        selectedSensorId = null,
        emptyMessage = message;

  final List<UserDashboardVehicleOption> vehicles;
  final List<UserDashboardSensorOption> sensors;
  final String? selectedVehicleId;
  final String? selectedSensorId;
  final UserDashboardSensorHistory? history;
  final String? emptyMessage;

  UserDashboardSensorOption? get selectedSensor {
    for (final sensor in sensors) {
      if (sensor.id == selectedSensorId) return sensor;
    }
    return history?.sensor;
  }
}

String _formatSensorValue(double? value, String unit) {
  if (value == null) return 'No value';
  final suffix = unit.trim().isEmpty ? '' : ' $unit';
  return '${userDashboardFormatDecimal(value, digits: 2)}$suffix';
}
