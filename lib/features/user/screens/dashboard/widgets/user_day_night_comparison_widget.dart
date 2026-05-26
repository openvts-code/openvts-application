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

class UserDayNightComparisonWidget extends ConsumerStatefulWidget {
  const UserDayNightComparisonWidget({
    required this.config,
    required this.refreshTick,
    super.key,
  });

  final UserDashboardWidgetConfig config;
  final int refreshTick;

  @override
  ConsumerState<UserDayNightComparisonWidget> createState() =>
      _UserDayNightComparisonWidgetState();
}

class _UserDayNightComparisonWidgetState
    extends ConsumerState<UserDayNightComparisonWidget> {
  late String _selectedVehicleId;
  late OpenVtsDateTimeRange _range;
  _DayNightMetric _metric = _DayNightMetric.drivenKm;
  int _refreshKey = 0;

  @override
  void initState() {
    super.initState();
    _selectedVehicleId = userDashboardPropString(
          widget.config.props,
          const ['vehicleId', 'vehicle_id'],
        ) ??
        'all';
    _range = _initialRange(widget.config.props);
  }

  @override
  void didUpdateWidget(covariant UserDayNightComparisonWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshTick != widget.refreshTick ||
        oldWidget.config.id != widget.config.id) {
      _reload();
    }
  }

  void _reload() => setState(() => _refreshKey++);

  void _changeVehicle(String? value) {
    if (value == null || value == _selectedVehicleId) return;
    setState(() {
      _selectedVehicleId = value;
      _refreshKey++;
    });
  }

  void _changeMetric(Set<_DayNightMetric> value) {
    if (value.isEmpty) return;
    setState(() => _metric = value.first);
  }

  void _changeRange(OpenVtsDateTimeRange value) {
    setState(() {
      _range = value.normalized(dateTimeEnabled: false);
      _refreshKey++;
    });
  }

  String _validatedVehicleId(List<UserDashboardVehicleOption> vehicles) {
    if (_selectedVehicleId == 'all') return 'all';
    final exists = vehicles.any((vehicle) => vehicle.id == _selectedVehicleId);
    if (exists) return _selectedVehicleId;
    _selectedVehicleId = 'all';
    return 'all';
  }

  _ResolvedDateRange _resolvedRange() {
    final fallback = _todayRange();
    final normalized = _range.normalized(dateTimeEnabled: false);
    final start = normalized.start ?? fallback.start!;
    final end = _endOfDay(normalized.end ?? fallback.end!);
    final orderedStart = start.isAfter(end) ? end : start;
    final orderedEnd = start.isAfter(end) ? start : end;

    if (orderedEnd.difference(orderedStart) > const Duration(days: 60)) {
      throw Exception(
          'Day / night comparison supports a maximum range of 60 days.');
    }
    return _ResolvedDateRange(start: orderedStart, end: orderedEnd);
  }

  @override
  Widget build(BuildContext context) {
    final range = _resolvedRange();
    final state = ref.watch(
      userDashboardDayNightProvider(
        UserDashboardRangeArgs(
          widgetId: widget.config.id,
          refreshKey: _refreshKey,
          vehicleId: _selectedVehicleId,
          from: range.start,
          to: range.end,
        ),
      ),
    );
    return UserDashboardWidgetCard(
      title: widget.config.title,
      icon: Icons.dark_mode_outlined,
      isLoading: state.isLoading,
      onRefresh: _reload,
      child: _buildBody(state),
    );
  }

  Widget _buildBody(
    AsyncValue<
            ({
              List<UserDashboardVehicleOption> vehicles,
              UserDashboardDayNightComparison comparison,
            })>
        state,
  ) {
    if (state.hasError) {
      return UserDashboardWidgetError(
        message: state.error.toString(),
        onRetry: _reload,
      );
    }

    final data = state.valueOrNull;
    if (data == null) {
      return const _DayNightSkeleton();
    }

    final comparison = data.comparison;
    final selectedVehicleId = _validatedVehicleId(data.vehicles);
    final dayTotal = _metric.valueOf(comparison.totals.day);
    final nightTotal = _metric.valueOf(comparison.totals.night);
    final dayPercent = _metric.dayPercent(comparison.percentages);
    final nightPercent = _metric.nightPercent(comparison.percentages);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _VehicleSelector(
          vehicles: data.vehicles,
          value: selectedVehicleId,
          onChanged: _changeVehicle,
        ),
        const SizedBox(height: OpenVtsSpacing.sm),
        SegmentedButton<_DayNightMetric>(
          segments: const [
            ButtonSegment(
              value: _DayNightMetric.drivenKm,
              label: Text('Driven KM'),
            ),
            ButtonSegment(
              value: _DayNightMetric.engineHours,
              label: Text('Engine Hours'),
            ),
          ],
          selected: {_metric},
          showSelectedIcon: false,
          style: ButtonStyle(
            visualDensity: VisualDensity.compact,
            textStyle: WidgetStatePropertyAll(
              OpenVtsTypography.meta.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          onSelectionChanged: _changeMetric,
        ),
        const SizedBox(height: OpenVtsSpacing.sm),
        OpenVtsDateTimeRangeField(
          label: 'Range',
          title: 'Day / Night Range',
          value: _range,
          dateTimeEnabled: false,
          lastDate: DateTime.now(),
          onChanged: _changeRange,
        ),
        const SizedBox(height: OpenVtsSpacing.md),
        _DayWindowLabel(dayWindow: comparison.dayWindow),
        const SizedBox(height: OpenVtsSpacing.sm),
        Row(
          children: [
            Expanded(
              child: UserDashboardMetricTile(
                label: 'Day',
                value: _metric.format(dayTotal),
                subtitle: '${userDashboardFormatDecimal(dayPercent)}%',
              ),
            ),
            const SizedBox(width: OpenVtsSpacing.xs),
            Expanded(
              child: UserDashboardMetricTile(
                label: 'Night',
                value: _metric.format(nightTotal),
                subtitle: '${userDashboardFormatDecimal(nightPercent)}%',
              ),
            ),
          ],
        ),
        const SizedBox(height: OpenVtsSpacing.md),
        if (comparison.points.isEmpty)
          const UserDashboardWidgetEmpty(
            message: 'No day or night data for this range.',
            icon: Icons.dark_mode_outlined,
          )
        else
          _DayNightChart(points: comparison.points, metric: _metric),
      ],
    );
  }

  static OpenVtsDateTimeRange _initialRange(Map<String, dynamic> props) {
    final from = userDashboardPropDateTime(props, const ['from']);
    final to = userDashboardPropDateTime(props, const ['to']);
    if (from != null || to != null) {
      return OpenVtsDateTimeRange(start: from, end: to)
          .normalized(dateTimeEnabled: false);
    }
    return _todayRange();
  }

  static OpenVtsDateTimeRange _todayRange() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
    return OpenVtsDateTimeRange(start: start, end: end);
  }

  static DateTime _endOfDay(DateTime value) {
    return DateTime(value.year, value.month, value.day, 23, 59, 59, 999);
  }
}

class _VehicleSelector extends StatelessWidget {
  const _VehicleSelector({
    required this.vehicles,
    required this.value,
    required this.onChanged,
  });

  final List<UserDashboardVehicleOption> vehicles;
  final String value;
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
        const DropdownMenuItem<String>(
          value: 'all',
          child: Text('All Vehicles'),
        ),
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

class _DayWindowLabel extends StatelessWidget {
  const _DayWindowLabel({required this.dayWindow});

  final UserDashboardDayWindow dayWindow;

  @override
  Widget build(BuildContext context) {
    final label = dayWindow.label.trim().isNotEmpty
        ? dayWindow.label
        : '${dayWindow.startHour}:00 - ${dayWindow.endHour}:00';
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: OpenVtsSpacing.sm,
        vertical: OpenVtsSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: OpenVtsColors.surface,
        borderRadius: BorderRadius.circular(OpenVtsRadius.md),
        border: Border.all(color: OpenVtsColors.border),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.wb_twilight_outlined,
            size: 16,
            color: OpenVtsColors.textSecondary,
          ),
          const SizedBox(width: OpenVtsSpacing.xs),
          Expanded(
            child: Text(
              'Day window: $label',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: OpenVtsTypography.meta.copyWith(
                color: OpenVtsColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DayNightChart extends StatelessWidget {
  const _DayNightChart({required this.points, required this.metric});

  final List<UserDashboardDayNightPoint> points;
  final _DayNightMetric metric;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 170,
      child: CustomPaint(
        painter: _DayNightChartPainter(points: points, metric: metric),
        size: Size.infinite,
      ),
    );
  }
}

class _DayNightChartPainter extends CustomPainter {
  const _DayNightChartPainter({required this.points, required this.metric});

  final List<UserDashboardDayNightPoint> points;
  final _DayNightMetric metric;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty || size.width <= 0 || size.height <= 0) return;

    const left = 28.0;
    const right = 8.0;
    const top = 8.0;
    const bottom = 24.0;
    final chartWidth = math.max(size.width - left - right, 1).toDouble();
    final chartHeight = math.max(size.height - top - bottom, 1).toDouble();
    final origin = Offset(left, top + chartHeight);
    final visiblePoints =
        points.length > 14 ? points.sublist(points.length - 14) : points;
    final maxValue = visiblePoints.fold<double>(0, (maxValue, point) {
      return math.max(
        maxValue,
        math.max(metric.valueOf(point.day), metric.valueOf(point.night)),
      );
    });
    final scale = math.max(maxValue, 1).toDouble();

    final gridPaint = Paint()
      ..color = OpenVtsColors.border
      ..strokeWidth = 1;
    for (var line = 0; line < 4; line++) {
      final y = top + chartHeight * line / 3;
      canvas.drawLine(
          Offset(left, y), Offset(size.width - right, y), gridPaint);
    }

    final dayPaint = Paint()
      ..color = OpenVtsColors.brandInk
      ..style = PaintingStyle.fill;
    final nightPaint = Paint()
      ..color = OpenVtsColors.textTertiary
      ..style = PaintingStyle.fill;
    final slot = chartWidth / visiblePoints.length;
    final barWidth = math.min(12.0, slot * 0.24).toDouble();

    for (var index = 0; index < visiblePoints.length; index++) {
      final point = visiblePoints[index];
      final centerX = left + slot * index + slot / 2;
      final dayHeight = chartHeight *
          (metric.valueOf(point.day) / scale).clamp(0.0, 1.0).toDouble();
      final nightHeight = chartHeight *
          (metric.valueOf(point.night) / scale).clamp(0.0, 1.0).toDouble();

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(centerX - barWidth - 1, origin.dy - dayHeight, barWidth,
              dayHeight),
          const Radius.circular(6),
        ),
        dayPaint,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
              centerX + 1, origin.dy - nightHeight, barWidth, nightHeight),
          const Radius.circular(6),
        ),
        nightPaint,
      );

      if (index == 0 ||
          index == visiblePoints.length - 1 ||
          visiblePoints.length <= 7) {
        _paintLabel(
          canvas,
          point.label,
          Offset(centerX, origin.dy + 8),
          alignment: TextAlign.center,
        );
      }
    }

    _paintLabel(canvas, metric.shortLabel, const Offset(0, top),
        alignment: TextAlign.left);
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
    )..layout(maxWidth: 54);
    final dx = alignment == TextAlign.center
        ? offset.dx - painter.width / 2
        : offset.dx;
    painter.paint(canvas, Offset(dx, offset.dy));
  }

  @override
  bool shouldRepaint(covariant _DayNightChartPainter oldDelegate) {
    return oldDelegate.points != points || oldDelegate.metric != metric;
  }
}

class _DayNightSkeleton extends StatelessWidget {
  const _DayNightSkeleton();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(height: 220);
  }
}

class _ResolvedDateRange {
  const _ResolvedDateRange({required this.start, required this.end});

  final DateTime start;
  final DateTime end;
}

enum _DayNightMetric {
  drivenKm,
  engineHours;

  double valueOf(UserDashboardMetricPair pair) {
    return switch (this) {
      _DayNightMetric.drivenKm => pair.drivenKm,
      _DayNightMetric.engineHours => pair.engineHours,
    };
  }

  double dayPercent(UserDashboardDayNightPercentages percentages) {
    return switch (this) {
      _DayNightMetric.drivenKm => percentages.dayDrivenKm,
      _DayNightMetric.engineHours => percentages.dayEngineHours,
    };
  }

  double nightPercent(UserDashboardDayNightPercentages percentages) {
    return switch (this) {
      _DayNightMetric.drivenKm => percentages.nightDrivenKm,
      _DayNightMetric.engineHours => percentages.nightEngineHours,
    };
  }

  String format(num value) {
    return switch (this) {
      _DayNightMetric.drivenKm => userDashboardFormatDistance(value),
      _DayNightMetric.engineHours => userDashboardFormatHours(value),
    };
  }

  String get shortLabel {
    return switch (this) {
      _DayNightMetric.drivenKm => 'km',
      _DayNightMetric.engineHours => 'h',
    };
  }
}
