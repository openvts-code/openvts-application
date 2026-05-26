import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/open_vts_colors.dart';
import '../../../../../core/theme/open_vts_radius.dart';
import '../../../../../core/theme/open_vts_spacing.dart';
import '../../../../../core/theme/open_vts_typography.dart';
import '../../../../../core/utils/date_time_formatter.dart';
import '../../../../../shared/widgets/open_vts_button.dart';
import '../../../../../shared/widgets/open_vts_date_time_range_selector.dart';
import '../../../controllers/user_vehicle_details_controller.dart';
import '../../../models/user_vehicle_model.dart';
import '../../../models/user_vehicle_state.dart';

const DateTimeFormatter _dateFormatter = DateTimeFormatter();

class UserVehicleSensorHistorySheet extends ConsumerStatefulWidget {
  const UserVehicleSensorHistorySheet({
    required this.provider,
    required this.sensor,
    super.key,
  });

  final AutoDisposeStateNotifierProvider<UserVehicleDetailsController,
      UserVehicleDetailsState> provider;
  final UserVehicleSensor sensor;

  @override
  ConsumerState<UserVehicleSensorHistorySheet> createState() =>
      _UserVehicleSensorHistorySheetState();
}

class _UserVehicleSensorHistorySheetState
    extends ConsumerState<UserVehicleSensorHistorySheet> {
  late OpenVtsDateTimeRange _range;
  UserVehicleSensorHistory? _history;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _range = OpenVtsDateTimeRange(
      start: now.subtract(const Duration(hours: 24)),
      end: now,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadHistory());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(widget.provider);
    final history = _history;
    final isLoading = state.isLoadingSensorHistory;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        OpenVtsSpacing.md,
        OpenVtsSpacing.sm,
        OpenVtsSpacing.md,
        OpenVtsSpacing.xl,
      ),
      children: [
        _HistoryHeader(sensor: widget.sensor),
        const SizedBox(height: OpenVtsSpacing.md),
        OpenVtsDateTimeRangeField(
          label: 'Range',
          title: 'Sensor History Range',
          value: _range,
          dateTimeEnabled: true,
          lastDate: DateTime.now(),
          onChanged: _changeRange,
        ),
        const SizedBox(height: OpenVtsSpacing.sm),
        OpenVtsButton(
          label: isLoading ? 'Loading...' : 'Reload History',
          height: 38,
          variant: OpenVtsButtonVariant.secondary,
          trailingIcon: Icons.refresh_rounded,
          onPressed: isLoading ? null : _loadHistory,
        ),
        if (state.sectionErrorMessage != null) ...[
          const SizedBox(height: OpenVtsSpacing.sm),
          _InlineError(message: state.sectionErrorMessage!),
        ],
        const SizedBox(height: OpenVtsSpacing.md),
        if (isLoading && history == null)
          const _LoadingHistory()
        else if (history == null)
          const _HistoryEmpty(message: 'Select a range to load history.')
        else if (!history.supported)
          _HistoryEmpty(
              message:
                  history.reason ?? 'History is not supported for this sensor.')
        else if (history.points.isEmpty)
          const _HistoryEmpty(message: 'No history points for this range.')
        else ...[
          _HistoryStatsGrid(stats: _HistoryStats.fromHistory(history)),
          const SizedBox(height: OpenVtsSpacing.md),
          _HistoryChart(points: history.points),
          const SizedBox(height: OpenVtsSpacing.md),
          _HistoryRangeSummary(history: history),
        ],
      ],
    );
  }

  void _changeRange(OpenVtsDateTimeRange value) {
    setState(() => _range = value);
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    if (!mounted) return;
    final normalized = _range.normalized(dateTimeEnabled: true);
    if (!normalized.isComplete) return;

    final history = await ref.read(widget.provider.notifier).loadSensorHistory(
          sensorId: widget.sensor.id,
          from: normalized.start!.toUtc(),
          to: normalized.end!.toUtc(),
          maxPoints: 500,
        );
    if (!mounted) return;
    setState(() => _history = history);
  }
}

class _HistoryHeader extends StatelessWidget {
  const _HistoryHeader({required this.sensor});

  final UserVehicleSensor sensor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(OpenVtsSpacing.sm),
      decoration: BoxDecoration(
        color: OpenVtsColors.surface,
        borderRadius: BorderRadius.circular(OpenVtsRadius.sm),
        border: Border.all(color: OpenVtsColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: OpenVtsColors.white,
              borderRadius: BorderRadius.circular(OpenVtsRadius.sm),
              border: Border.all(color: OpenVtsColors.border),
            ),
            child: const Icon(Icons.timeline_rounded, size: 18),
          ),
          const SizedBox(width: OpenVtsSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sensor.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: OpenVtsTypography.label.copyWith(
                    color: OpenVtsColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  sensor.code.trim().isEmpty
                      ? 'Sensor history'
                      : sensor.code.trim(),
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

class _HistoryStatsGrid extends StatelessWidget {
  const _HistoryStatsGrid({required this.stats});

  final _HistoryStats stats;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: OpenVtsSpacing.xs,
      runSpacing: OpenVtsSpacing.xs,
      children: [
        _StatTile(label: 'Min', value: stats.min),
        _StatTile(label: 'Max', value: stats.max),
        _StatTile(label: 'Avg', value: stats.avg),
        _StatTile(label: 'First', value: stats.first),
        _StatTile(label: 'Last', value: stats.last),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 96,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: OpenVtsSpacing.sm,
          vertical: OpenVtsSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: OpenVtsColors.surface,
          borderRadius: BorderRadius.circular(OpenVtsRadius.sm),
          border: Border.all(color: OpenVtsColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: OpenVtsTypography.meta.copyWith(
                color: OpenVtsColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: OpenVtsTypography.label.copyWith(
                color: OpenVtsColors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryChart extends StatelessWidget {
  const _HistoryChart({required this.points});

  final List<UserVehicleSensorHistoryPoint> points;

  @override
  Widget build(BuildContext context) {
    final values = points
        .map((point) => _numericValue(point.value))
        .nonNulls
        .toList(growable: false);
    if (values.isEmpty) {
      return const _HistoryEmpty(message: 'History values are not numeric.');
    }

    return Container(
      height: 152,
      padding: const EdgeInsets.all(OpenVtsSpacing.sm),
      decoration: BoxDecoration(
        color: OpenVtsColors.surface,
        borderRadius: BorderRadius.circular(OpenVtsRadius.sm),
        border: Border.all(color: OpenVtsColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${values.length} numeric points',
            style: OpenVtsTypography.meta.copyWith(
              color: OpenVtsColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: OpenVtsSpacing.xs),
          Expanded(child: CustomPaint(painter: _HistoryChartPainter(values))),
        ],
      ),
    );
  }
}

class _HistoryRangeSummary extends StatelessWidget {
  const _HistoryRangeSummary({required this.history});

  final UserVehicleSensorHistory history;

  @override
  Widget build(BuildContext context) {
    final firstTime = history.points.first.time;
    final lastTime = history.points.last.time;

    return Container(
      padding: const EdgeInsets.all(OpenVtsSpacing.sm),
      decoration: BoxDecoration(
        color: OpenVtsColors.surface,
        borderRadius: BorderRadius.circular(OpenVtsRadius.sm),
        border: Border.all(color: OpenVtsColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Samples',
            style: OpenVtsTypography.meta.copyWith(
              color: OpenVtsColors.textSecondary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _sampleText(firstTime, lastTime, history.points.length),
            style: OpenVtsTypography.meta.copyWith(
              color: OpenVtsColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingHistory extends StatelessWidget {
  const _LoadingHistory();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(OpenVtsSpacing.sm),
      decoration: BoxDecoration(
        color: OpenVtsColors.surface,
        borderRadius: BorderRadius.circular(OpenVtsRadius.sm),
        border: Border.all(color: OpenVtsColors.border),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: OpenVtsSpacing.sm),
          Text(
            'Loading history',
            style: OpenVtsTypography.meta.copyWith(
              color: OpenVtsColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryEmpty extends StatelessWidget {
  const _HistoryEmpty({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(OpenVtsSpacing.md),
      decoration: BoxDecoration(
        color: OpenVtsColors.surface,
        borderRadius: BorderRadius.circular(OpenVtsRadius.sm),
        border: Border.all(color: OpenVtsColors.border),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: OpenVtsTypography.meta.copyWith(
          color: OpenVtsColors.textSecondary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(OpenVtsSpacing.sm),
      decoration: BoxDecoration(
        color: OpenVtsColors.error.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(OpenVtsRadius.sm),
        border: Border.all(color: OpenVtsColors.error.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              size: 16, color: OpenVtsColors.error),
          const SizedBox(width: OpenVtsSpacing.xs),
          Expanded(
            child: Text(
              message,
              style: OpenVtsTypography.meta.copyWith(
                color: OpenVtsColors.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryChartPainter extends CustomPainter {
  const _HistoryChartPainter(this.values);

  final List<double> values;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty || size.isEmpty) return;

    final gridPaint = Paint()
      ..color = OpenVtsColors.border
      ..strokeWidth = 1;
    final linePaint = Paint()
      ..color = OpenVtsColors.brandInk
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final pointPaint = Paint()
      ..color = OpenVtsColors.brandInk
      ..style = PaintingStyle.fill;

    for (var index = 0; index < 4; index++) {
      final y = size.height * index / 3;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final min = values.reduce((a, b) => a < b ? a : b);
    final max = values.reduce((a, b) => a > b ? a : b);
    final span = max - min;
    final path = Path();

    for (var index = 0; index < values.length; index++) {
      final x = values.length == 1
          ? size.width / 2
          : size.width * index / (values.length - 1);
      final normalized = span == 0 ? 0.5 : (values[index] - min) / span;
      final y = size.height - (normalized * size.height);
      final point = Offset(x, y);
      if (index == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }

    canvas.drawPath(path, linePaint);
    if (values.length <= 24) {
      for (var index = 0; index < values.length; index++) {
        final x = values.length == 1
            ? size.width / 2
            : size.width * index / (values.length - 1);
        final normalized = span == 0 ? 0.5 : (values[index] - min) / span;
        final y = size.height - (normalized * size.height);
        canvas.drawCircle(Offset(x, y), 2.5, pointPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _HistoryChartPainter oldDelegate) {
    return oldDelegate.values != values;
  }
}

class _HistoryStats {
  const _HistoryStats({
    required this.min,
    required this.max,
    required this.avg,
    required this.first,
    required this.last,
  });

  final String min;
  final String max;
  final String avg;
  final String first;
  final String last;

  factory _HistoryStats.fromHistory(UserVehicleSensorHistory history) {
    final stats = history.stats ?? const <String, dynamic>{};
    final values = history.points
        .map((point) => _numericValue(point.value))
        .nonNulls
        .toList(growable: false);

    String fromStats(List<String> keys) {
      for (final key in keys) {
        final value = stats[key];
        if (value != null) return _formatValue(value);
      }
      return '-';
    }

    final computedMin =
        values.isEmpty ? null : values.reduce((a, b) => a < b ? a : b);
    final computedMax =
        values.isEmpty ? null : values.reduce((a, b) => a > b ? a : b);
    final computedAvg =
        values.isEmpty ? null : values.reduce((a, b) => a + b) / values.length;

    return _HistoryStats(
      min: fromStats(const ['min', 'minimum']).replaceIfDash(computedMin),
      max: fromStats(const ['max', 'maximum']).replaceIfDash(computedMax),
      avg: fromStats(const ['avg', 'average', 'mean'])
          .replaceIfDash(computedAvg),
      first:
          fromStats(const ['first']).replaceIfDash(history.points.first.value),
      last: fromStats(const ['last']).replaceIfDash(history.points.last.value),
    );
  }
}

extension _DashReplacement on String {
  String replaceIfDash(Object? value) =>
      this == '-' ? _formatValue(value) : this;
}

double? _numericValue(Object? value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value.trim());
  return null;
}

String _formatValue(Object? value) {
  if (value == null) return '-';
  if (value is double) {
    return value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 2);
  }
  if (value is num) return value.toString();
  final normalized = value.toString().trim();
  return normalized.isEmpty ? '-' : normalized;
}

String _sampleText(DateTime? first, DateTime? last, int count) {
  final firstLabel = first == null
      ? 'unknown'
      : _dateFormatter.formatDateTime(first.toLocal());
  final lastLabel =
      last == null ? 'unknown' : _dateFormatter.formatDateTime(last.toLocal());
  return '$count points from $firstLabel to $lastLabel';
}
