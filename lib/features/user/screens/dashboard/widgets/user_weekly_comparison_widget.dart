import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/open_vts_colors.dart';
import '../../../../../core/theme/open_vts_radius.dart';
import '../../../../../core/theme/open_vts_spacing.dart';
import '../../../../../core/theme/open_vts_typography.dart';
import '../../../../../core/utils/unit_formatter.dart';
import '../../../controllers/user_providers.dart';
import '../../../models/user_dashboard_model.dart';
import 'user_dashboard_widget_card.dart';

class UserWeeklyComparisonWidget extends ConsumerStatefulWidget {
  const UserWeeklyComparisonWidget({
    required this.config,
    required this.refreshTick,
    super.key,
  });

  final UserDashboardWidgetConfig config;
  final int refreshTick;

  @override
  ConsumerState<UserWeeklyComparisonWidget> createState() =>
      _UserWeeklyComparisonWidgetState();
}

class _UserWeeklyComparisonWidgetState
    extends ConsumerState<UserWeeklyComparisonWidget> {
  late String _selectedVehicleId;
  _WeeklyMetric _metric = _WeeklyMetric.drivenKm;
  int _refreshKey = 0;

  @override
  void initState() {
    super.initState();
    _selectedVehicleId = userDashboardPropString(
          widget.config.props,
          const ['vehicleId', 'vehicle_id'],
        ) ??
        'all';
  }

  @override
  void didUpdateWidget(covariant UserWeeklyComparisonWidget oldWidget) {
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

  void _changeMetric(Set<_WeeklyMetric> value) {
    if (value.isEmpty) return;
    setState(() => _metric = value.first);
  }

  @override
  Widget build(BuildContext context) {
    final unitFormatter = ref.watch(unitFormatterProvider);
    final state = ref.watch(
      userDashboardWeeklyProvider(
        UserDashboardVehicleScopedArgs(
          widgetId: widget.config.id,
          refreshKey: _refreshKey,
          vehicleId:
              _selectedVehicleId == 'all' ? null : _selectedVehicleId,
        ),
      ),
    );
    return UserDashboardWidgetCard(
      title: widget.config.title,
      icon: Icons.compare_arrows_rounded,
      isLoading: state.isLoading,
      onRefresh: _reload,
      child: _buildBody(state, unitFormatter),
    );
  }

  Widget _buildBody(
    AsyncValue<
            ({
              List<UserDashboardVehicleOption> vehicles,
              UserDashboardWeeklyComparison comparison,
            })>
        state,
    UnitFormatter unitFormatter,
  ) {
    if (state.hasError) {
      return UserDashboardWidgetError(
        message: state.error.toString(),
        onRetry: _reload,
      );
    }

    final data = state.valueOrNull;
    if (data == null) {
      return const _WeeklySkeleton();
    }

    final comparison = data.comparison;
    final selectedVehicleId = _validatedVehicleId(data.vehicles);
    final thisWeekTotal = _metric.valueOf(comparison.totals.thisWeek);
    final lastWeekTotal = _metric.valueOf(comparison.totals.lastWeek);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _VehicleSelector(
          vehicles: data.vehicles,
          value: selectedVehicleId,
          onChanged: _changeVehicle,
        ),
        const SizedBox(height: OpenVtsSpacing.sm),
        SegmentedButton<_WeeklyMetric>(
          segments: [
            ButtonSegment(
              value: _WeeklyMetric.drivenKm,
              label: Text('Driven ${unitFormatter.distanceLabel.toUpperCase()}'),
            ),
            const ButtonSegment(
              value: _WeeklyMetric.engineHours,
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
        Row(
          children: [
            Expanded(
              child: UserDashboardMetricTile(
                label: 'This week',
                value: _metric.format(thisWeekTotal),
                subtitle: selectedVehicleId == 'all'
                    ? 'all vehicles'
                    : _vehicleName(data.vehicles, selectedVehicleId),
              ),
            ),
            const SizedBox(width: OpenVtsSpacing.xs),
            Expanded(
              child: UserDashboardMetricTile(
                label: 'Last week',
                value: _metric.format(lastWeekTotal),
                subtitle: _deltaText(thisWeekTotal, lastWeekTotal),
              ),
            ),
          ],
        ),
        const SizedBox(height: OpenVtsSpacing.md),
        if (comparison.points.isEmpty)
          const UserDashboardWidgetEmpty(
            message: 'No weekly comparison data.',
            icon: Icons.compare_arrows_rounded,
          )
        else
          _WeeklyComparisonChart(
            points: comparison.points,
            metric: _metric,
          ),
      ],
    );
  }

  String _validatedVehicleId(List<UserDashboardVehicleOption> vehicles) {
    if (_selectedVehicleId == 'all') return 'all';
    final exists = vehicles.any((vehicle) => vehicle.id == _selectedVehicleId);
    return exists ? _selectedVehicleId : 'all';
  }

  String _vehicleName(List<UserDashboardVehicleOption> vehicles, String id) {
    for (final vehicle in vehicles) {
      if (vehicle.id == id) return vehicle.name;
    }
    return 'selected vehicle';
  }

  String _deltaText(double current, double previous) {
    final delta = current - previous;
    final sign = delta >= 0 ? '+' : '';
    return '$sign${_metric.format(delta)} vs last week';
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
      return '${vehicle.name} · $plate';
    }
    return vehicle.name;
  }
}

class _WeeklyComparisonChart extends StatelessWidget {
  const _WeeklyComparisonChart({required this.points, required this.metric});

  final List<UserDashboardWeeklyPoint> points;
  final _WeeklyMetric metric;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 172,
      child: CustomPaint(
        painter: _WeeklyComparisonChartPainter(points, metric),
        size: Size.infinite,
      ),
    );
  }
}

class _WeeklyComparisonChartPainter extends CustomPainter {
  _WeeklyComparisonChartPainter(this.points, this.metric);

  final List<UserDashboardWeeklyPoint> points;
  final _WeeklyMetric metric;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty || size.width <= 0 || size.height <= 0) return;

    const left = 4.0;
    const right = 4.0;
    const top = 8.0;
    const bottom = 26.0;
    final chartWidth = math.max(size.width - left - right, 1);
    final chartHeight = math.max(size.height - top - bottom, 1);
    final baseline = top + chartHeight;
    final maxValue = points.fold<double>(0, (max, point) {
      return math.max(
        max,
        math.max(
            metric.valueOf(point.thisWeek), metric.valueOf(point.lastWeek)),
      );
    });
    final scale = math.max(maxValue, 1);

    final gridPaint = Paint()
      ..color = OpenVtsColors.border
      ..strokeWidth = 1;
    for (var line = 0; line < 4; line++) {
      final y = top + chartHeight * line / 3;
      canvas.drawLine(
          Offset(left, y), Offset(size.width - right, y), gridPaint);
    }

    final slot = chartWidth / points.length;
    final barWidth = math.min(14.0, slot * 0.25);
    final thisPaint = Paint()
      ..color = OpenVtsColors.brandInk
      ..style = PaintingStyle.fill;
    final lastPaint = Paint()
      ..color = OpenVtsColors.textTertiary
      ..style = PaintingStyle.fill;
    final dashPaint = Paint()
      ..color = OpenVtsColors.surfaceElevated.withValues(alpha: 0.85)
      ..strokeWidth = 1;

    for (var index = 0; index < points.length; index++) {
      final point = points[index];
      final centerX = left + slot * index + slot / 2;
      final thisValue = metric.valueOf(point.thisWeek);
      final lastValue = metric.valueOf(point.lastWeek);
      final thisHeight = chartHeight * (thisValue / scale).clamp(0.0, 1.0);
      final lastHeight = chartHeight * (lastValue / scale).clamp(0.0, 1.0);
      final thisRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          centerX - barWidth - 2,
          baseline - thisHeight,
          barWidth,
          thisHeight,
        ),
        const Radius.circular(5),
      );
      final lastRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          centerX + 2,
          baseline - lastHeight,
          barWidth,
          lastHeight,
        ),
        const Radius.circular(5),
      );
      canvas.drawRRect(thisRect, thisPaint);
      canvas.drawRRect(lastRect, lastPaint);
      for (var y = baseline - lastHeight + 4; y < baseline; y += 6) {
        canvas.drawLine(
          Offset(centerX + 3, y),
          Offset(centerX + barWidth + 1, y),
          dashPaint,
        );
      }
    }

    _drawLabels(canvas, size, slot, left);
    _drawLegend(canvas);
  }

  void _drawLabels(Canvas canvas, Size size, double slot, double left) {
    for (var index = 0; index < points.length; index++) {
      final label = points[index].label.trim().isEmpty
          ? 'D${points[index].dayIndex + 1}'
          : points[index].label;
      final painter = TextPainter(
        text: TextSpan(
          text: label.length > 3 ? label.substring(0, 3) : label,
          style: OpenVtsTypography.meta.copyWith(
            color: OpenVtsColors.textTertiary,
            fontSize: 9.5,
            fontWeight: FontWeight.w700,
          ),
        ),
        maxLines: 1,
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: slot);
      final x = left + slot * index + slot / 2 - painter.width / 2;
      painter.paint(canvas, Offset(x, size.height - 14));
    }
  }

  void _drawLegend(Canvas canvas) {
    _legendPainter('This week', OpenVtsColors.brandInk)
        .paint(canvas, const Offset(4, 0));
    _legendPainter('Last week', OpenVtsColors.textTertiary)
        .paint(canvas, const Offset(92, 0));
  }

  TextPainter _legendPainter(String text, Color color) {
    return TextPainter(
      text: TextSpan(
        text: text,
        style: OpenVtsTypography.meta.copyWith(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
  }

  @override
  bool shouldRepaint(covariant _WeeklyComparisonChartPainter oldDelegate) {
    return oldDelegate.points != points || oldDelegate.metric != metric;
  }
}

class _WeeklySkeleton extends StatelessWidget {
  const _WeeklySkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _SkeletonBlock(height: 46),
        const SizedBox(height: OpenVtsSpacing.sm),
        const _SkeletonBlock(height: 40),
        const SizedBox(height: OpenVtsSpacing.sm),
        Row(
          children: [
            for (var index = 0; index < 2; index++) ...[
              const Expanded(child: _SkeletonBlock(height: 58)),
              if (index != 1) const SizedBox(width: OpenVtsSpacing.xs),
            ],
          ],
        ),
        const SizedBox(height: OpenVtsSpacing.md),
        const _SkeletonBlock(height: 172),
      ],
    );
  }
}

class _SkeletonBlock extends StatelessWidget {
  const _SkeletonBlock({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: OpenVtsColors.surface,
        borderRadius: BorderRadius.circular(OpenVtsRadius.md),
        border: Border.all(color: OpenVtsColors.border),
      ),
    );
  }
}

enum _WeeklyMetric {
  drivenKm,
  engineHours;

  double valueOf(UserDashboardMetricPair pair) {
    switch (this) {
      case _WeeklyMetric.drivenKm:
        return pair.drivenKm;
      case _WeeklyMetric.engineHours:
        return pair.engineHours;
    }
  }

  String format(num value) {
    switch (this) {
      case _WeeklyMetric.drivenKm:
        return userDashboardFormatDistance(value);
      case _WeeklyMetric.engineHours:
        return userDashboardFormatHours(value);
    }
  }
}
