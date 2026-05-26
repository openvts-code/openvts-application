import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/open_vts_colors.dart';
import '../../../../../core/theme/open_vts_radius.dart';
import '../../../../../core/theme/open_vts_spacing.dart';
import '../../../../../core/theme/open_vts_typography.dart';
import '../../../controllers/user_providers.dart';
import '../../../models/user_dashboard_model.dart';
import 'user_dashboard_widget_card.dart';

class UserUsageLast7DaysWidget extends ConsumerStatefulWidget {
  const UserUsageLast7DaysWidget({
    required this.config,
    required this.refreshTick,
    super.key,
  });

  final UserDashboardWidgetConfig config;
  final int refreshTick;

  @override
  ConsumerState<UserUsageLast7DaysWidget> createState() =>
      _UserUsageLast7DaysWidgetState();
}

class _UserUsageLast7DaysWidgetState
    extends ConsumerState<UserUsageLast7DaysWidget> {
  late String _selectedVehicleId;
  late Future<_UsageViewData> _future;

  @override
  void initState() {
    super.initState();
    _selectedVehicleId = userDashboardPropString(
          widget.config.props,
          const ['vehicleId', 'vehicle_id'],
        ) ??
        'all';
    _future = _load();
  }

  @override
  void didUpdateWidget(covariant UserUsageLast7DaysWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshTick != widget.refreshTick ||
        oldWidget.config.id != widget.config.id) {
      _reload();
    }
  }

  Future<_UsageViewData> _load() async {
    final service = ref.read(userDashboardServiceProvider);
    final vehicleId = _selectedVehicleId == 'all' ? null : _selectedVehicleId;
    final results = await Future.wait<dynamic>([
      service.getVehicles(),
      service.getUsageLast7Days(vehicleId: vehicleId),
    ]);
    final vehicles = results[0] as List<UserDashboardVehicleOption>;
    return _UsageViewData(
      vehicles: vehicles,
      usage: results[1] as UserDashboardUsageLast7Days,
    );
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
      _future = _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_UsageViewData>(
      future: _future,
      builder: (context, snapshot) {
        final isLoading = snapshot.connectionState != ConnectionState.done;
        return UserDashboardWidgetCard(
          title: widget.config.title,
          icon: Icons.bar_chart_rounded,
          isLoading: isLoading,
          onRefresh: _reload,
          child: _buildBody(snapshot),
        );
      },
    );
  }

  Widget _buildBody(AsyncSnapshot<_UsageViewData> snapshot) {
    if (snapshot.hasError) {
      return UserDashboardWidgetError(
        message: snapshot.error.toString(),
        onRetry: _reload,
      );
    }

    final data = snapshot.data;
    if (data == null) {
      return const _UsageSkeleton();
    }

    final usage = data.usage;
    final selectedVehicleId = _validatedVehicleId(data.vehicles);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _VehicleSelector(
          vehicles: data.vehicles,
          value: selectedVehicleId,
          onChanged: _changeVehicle,
        ),
        const SizedBox(height: OpenVtsSpacing.sm),
        Row(
          children: [
            Expanded(
              child: UserDashboardMetricTile(
                label: 'Driven',
                value: userDashboardFormatDistance(usage.totals.drivenKm),
                subtitle: 'last 7 days',
              ),
            ),
            const SizedBox(width: OpenVtsSpacing.xs),
            Expanded(
              child: UserDashboardMetricTile(
                label: 'Engine',
                value: userDashboardFormatHours(usage.totals.engineHours),
                subtitle: selectedVehicleId == 'all'
                    ? 'all vehicles'
                    : _vehicleName(data.vehicles, selectedVehicleId),
              ),
            ),
          ],
        ),
        const SizedBox(height: OpenVtsSpacing.md),
        if (usage.points.isEmpty)
          const UserDashboardWidgetEmpty(
            message: 'No usage data for the selected range.',
            icon: Icons.bar_chart_rounded,
          )
        else
          _UsageChart(points: usage.points),
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

class _UsageChart extends StatelessWidget {
  const _UsageChart({required this.points});

  final List<UserDashboardUsagePoint> points;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 168,
      child: CustomPaint(
        painter: _UsageChartPainter(points),
        size: Size.infinite,
      ),
    );
  }
}

class _UsageChartPainter extends CustomPainter {
  _UsageChartPainter(this.points);

  final List<UserDashboardUsagePoint> points;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty || size.width <= 0 || size.height <= 0) return;

    const left = 4.0;
    const right = 4.0;
    const top = 8.0;
    const bottom = 24.0;
    final chartWidth = math.max(size.width - left - right, 1).toDouble();
    final chartHeight = math.max(size.height - top - bottom, 1).toDouble();
    final origin = Offset(left, top + chartHeight);
    final maxKm = points.fold<double>(
      0,
      (max, point) => math.max(max, point.drivenKm),
    );
    final maxHours = points.fold<double>(
      0,
      (max, point) => math.max(max, point.engineHours),
    );
    final kmScale = math.max(maxKm, 1);
    final hourScale = math.max(maxHours, 1);

    final gridPaint = Paint()
      ..color = OpenVtsColors.border
      ..strokeWidth = 1;
    for (var line = 0; line < 4; line++) {
      final y = top + chartHeight * line / 3;
      canvas.drawLine(
          Offset(left, y), Offset(size.width - right, y), gridPaint);
    }

    final barPaint = Paint()
      ..color = OpenVtsColors.brandInk
      ..style = PaintingStyle.fill;
    final barTrackPaint = Paint()
      ..color = OpenVtsColors.surface
      ..style = PaintingStyle.fill;
    final slot = chartWidth / points.length;
    final barWidth = math.min(18.0, slot * 0.42).toDouble();
    final linePoints = <Offset>[];

    for (var index = 0; index < points.length; index++) {
      final point = points[index];
      final centerX = left + slot * index + slot / 2;
      final trackRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(centerX - barWidth / 2, top, barWidth, chartHeight),
        const Radius.circular(8),
      );
      canvas.drawRRect(trackRect, barTrackPaint);

      final barHeight =
          chartHeight * (point.drivenKm / kmScale).clamp(0.0, 1.0).toDouble();
      final barRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          centerX - barWidth / 2,
          origin.dy - barHeight,
          barWidth,
          barHeight,
        ),
        const Radius.circular(8),
      );
      canvas.drawRRect(barRect, barPaint);

      final hourY = origin.dy -
          chartHeight * (point.engineHours / hourScale).clamp(0.0, 1.0);
      linePoints.add(Offset(centerX, hourY));
    }

    final linePaint = Paint()
      ..color = OpenVtsColors.textTertiary
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final path = Path();
    for (var index = 0; index < linePoints.length; index++) {
      final point = linePoints[index];
      if (index == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    canvas.drawPath(path, linePaint);

    final dotPaint = Paint()..color = OpenVtsColors.textTertiary;
    for (final point in linePoints) {
      canvas.drawCircle(point, 3, dotPaint);
    }

    _drawLabels(canvas, size, slot, left);
    _drawLegend(canvas, size);
  }

  void _drawLabels(Canvas canvas, Size size, double slot, double left) {
    for (var index = 0; index < points.length; index++) {
      final label = points[index].label.trim().isEmpty
          ? points[index].day
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

  void _drawLegend(Canvas canvas, Size size) {
    final driven = _legendPainter('Driven km', OpenVtsColors.brandInk);
    final engine = _legendPainter('Engine hours', OpenVtsColors.textTertiary);
    driven.paint(canvas, const Offset(4, 0));
    engine.paint(canvas, const Offset(92, 0));
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
  bool shouldRepaint(covariant _UsageChartPainter oldDelegate) {
    return oldDelegate.points != points;
  }
}

class _UsageSkeleton extends StatelessWidget {
  const _UsageSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _SkeletonBlock(height: 46),
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
        const _SkeletonBlock(height: 168),
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

class _UsageViewData {
  const _UsageViewData({required this.vehicles, required this.usage});

  final List<UserDashboardVehicleOption> vehicles;
  final UserDashboardUsageLast7Days usage;
}
