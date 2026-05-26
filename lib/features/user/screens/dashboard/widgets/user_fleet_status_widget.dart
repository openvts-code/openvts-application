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

class UserFleetStatusWidget extends ConsumerStatefulWidget {
  const UserFleetStatusWidget({
    required this.config,
    required this.refreshTick,
    super.key,
  });

  final UserDashboardWidgetConfig config;
  final int refreshTick;

  @override
  ConsumerState<UserFleetStatusWidget> createState() =>
      _UserFleetStatusWidgetState();
}

class _UserFleetStatusWidgetState extends ConsumerState<UserFleetStatusWidget> {
  late Future<UserDashboardFleetStatus> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void didUpdateWidget(covariant UserFleetStatusWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshTick != widget.refreshTick ||
        oldWidget.config.id != widget.config.id) {
      _reload();
    }
  }

  Future<UserDashboardFleetStatus> _load() {
    return ref.read(userDashboardServiceProvider).getFleetStatus();
  }

  void _reload() {
    setState(() {
      _future = _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserDashboardFleetStatus>(
      future: _future,
      builder: (context, snapshot) {
        final isLoading = snapshot.connectionState != ConnectionState.done;
        return UserDashboardWidgetCard(
          title: widget.config.title,
          icon: Icons.directions_car_filled_outlined,
          isLoading: isLoading,
          onRefresh: _reload,
          child: _buildBody(snapshot),
        );
      },
    );
  }

  Widget _buildBody(AsyncSnapshot<UserDashboardFleetStatus> snapshot) {
    if (snapshot.hasError) {
      return UserDashboardWidgetError(
        message: snapshot.error.toString(),
        onRetry: _reload,
      );
    }

    final data = snapshot.data;
    if (data == null) {
      return const _FleetStatusSkeleton();
    }

    final totalVehicles = data.totalVehicles == 0
        ? math.max(data.withDevice + data.noDevice, data.buckets.total)
        : data.totalVehicles;
    final bucketTotal = math.max(data.buckets.total, 1);
    final segments = [
      _FleetSegment(
          'Connected', data.buckets.connected, const Color(0xFF17141B)),
      _FleetSegment('Running', data.buckets.running, const Color(0xFF3B3740)),
      _FleetSegment('Idle', data.buckets.idle, const Color(0xFF635D69)),
      _FleetSegment('Stopped', data.buckets.stopped, const Color(0xFF8A8490)),
      _FleetSegment('Inactive', data.buckets.inactive, const Color(0xFFB5AFBC)),
      _FleetSegment('No data', data.buckets.noData, const Color(0xFFDCD8E0)),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: UserDashboardMetricTile(
                label: 'Total',
                value: userDashboardFormatNumber(totalVehicles),
                subtitle: 'vehicles',
              ),
            ),
            const SizedBox(width: OpenVtsSpacing.xs),
            Expanded(
              child: UserDashboardMetricTile(
                label: 'With device',
                value: userDashboardFormatNumber(data.withDevice),
                subtitle: _percentText(data.withDevice, totalVehicles),
              ),
            ),
            const SizedBox(width: OpenVtsSpacing.xs),
            Expanded(
              child: UserDashboardMetricTile(
                label: 'No device',
                value: userDashboardFormatNumber(data.noDevice),
                subtitle: _percentText(data.noDevice, totalVehicles),
              ),
            ),
          ],
        ),
        const SizedBox(height: OpenVtsSpacing.md),
        _FleetSegmentedBar(segments: segments, total: bucketTotal),
        const SizedBox(height: OpenVtsSpacing.sm),
        Wrap(
          spacing: OpenVtsSpacing.xs,
          runSpacing: OpenVtsSpacing.xs,
          children: [
            for (final segment in segments)
              _FleetStatusChip(
                segment: segment,
                percent: _percent(segment.value, bucketTotal),
              ),
          ],
        ),
      ],
    );
  }

  String _percentText(num value, num total) {
    return '${userDashboardFormatDecimal(_percent(value, total))}%';
  }

  double _percent(num value, num total) {
    if (total <= 0) return 0;
    return value / total * 100;
  }
}

class _FleetSegmentedBar extends StatelessWidget {
  const _FleetSegmentedBar({required this.segments, required this.total});

  final List<_FleetSegment> segments;
  final num total;

  @override
  Widget build(BuildContext context) {
    final activeSegments =
        segments.where((segment) => segment.value > 0).toList();

    if (activeSegments.isEmpty) {
      return Container(
        height: 16,
        decoration: BoxDecoration(
          color: OpenVtsColors.surface,
          borderRadius: BorderRadius.circular(OpenVtsRadius.pill),
          border: Border.all(color: OpenVtsColors.border),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(OpenVtsRadius.pill),
      child: SizedBox(
        height: 16,
        child: Row(
          children: [
            for (final segment in activeSegments)
              Expanded(
                flex: math.max((segment.value / total * 1000).round(), 1),
                child: ColoredBox(color: segment.color),
              ),
          ],
        ),
      ),
    );
  }
}

class _FleetStatusChip extends StatelessWidget {
  const _FleetStatusChip({required this.segment, required this.percent});

  final _FleetSegment segment;
  final double percent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: OpenVtsSpacing.xs,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: OpenVtsColors.surface,
        borderRadius: BorderRadius.circular(OpenVtsRadius.pill),
        border: Border.all(color: OpenVtsColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: segment.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            '${segment.label} ${userDashboardFormatNumber(segment.value)}',
            style: OpenVtsTypography.meta.copyWith(
              color: OpenVtsColors.textSecondary,
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '${userDashboardFormatDecimal(percent)}%',
            style: OpenVtsTypography.meta.copyWith(
              color: OpenVtsColors.textTertiary,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _FleetStatusSkeleton extends StatelessWidget {
  const _FleetStatusSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            for (var index = 0; index < 3; index++) ...[
              const Expanded(child: _SkeletonBlock(height: 56)),
              if (index != 2) const SizedBox(width: OpenVtsSpacing.xs),
            ],
          ],
        ),
        const SizedBox(height: OpenVtsSpacing.md),
        const _SkeletonBlock(height: 16),
        const SizedBox(height: OpenVtsSpacing.sm),
        const _SkeletonBlock(height: 56),
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

class _FleetSegment {
  const _FleetSegment(this.label, this.value, this.color);

  final String label;
  final int value;
  final Color color;
}
