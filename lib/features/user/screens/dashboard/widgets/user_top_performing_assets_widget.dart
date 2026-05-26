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

class UserTopPerformingAssetsWidget extends ConsumerStatefulWidget {
  const UserTopPerformingAssetsWidget({
    required this.config,
    required this.refreshTick,
    super.key,
  });

  final UserDashboardWidgetConfig config;
  final int refreshTick;

  @override
  ConsumerState<UserTopPerformingAssetsWidget> createState() =>
      _UserTopPerformingAssetsWidgetState();
}

class _UserTopPerformingAssetsWidgetState
    extends ConsumerState<UserTopPerformingAssetsWidget> {
  _TopAssetsRange _range = _TopAssetsRange.today;
  late Future<UserDashboardTopAssets> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void didUpdateWidget(covariant UserTopPerformingAssetsWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshTick != widget.refreshTick ||
        oldWidget.config.id != widget.config.id) {
      _reload();
    }
  }

  Future<UserDashboardTopAssets> _load() {
    final resolvedRange = _range.resolve();
    return ref.read(userDashboardServiceProvider).getTopPerformingAssets(
          from: resolvedRange.from,
          to: resolvedRange.to,
          limit:
              userDashboardPropInt(widget.config.props, const ['limit']) ?? 10,
        );
  }

  void _reload() {
    setState(() {
      _future = _load();
    });
  }

  void _changeRange(Set<_TopAssetsRange> value) {
    if (value.isEmpty) return;
    setState(() {
      _range = value.first;
      _future = _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserDashboardTopAssets>(
      future: _future,
      builder: (context, snapshot) {
        final isLoading = snapshot.connectionState != ConnectionState.done;
        return UserDashboardWidgetCard(
          title: widget.config.title,
          icon: Icons.leaderboard_outlined,
          isLoading: isLoading,
          onRefresh: _reload,
          child: _buildBody(snapshot),
        );
      },
    );
  }

  Widget _buildBody(AsyncSnapshot<UserDashboardTopAssets> snapshot) {
    if (snapshot.hasError) {
      return UserDashboardWidgetError(
        message: snapshot.error.toString(),
        onRetry: _reload,
      );
    }

    final data = snapshot.data;
    if (data == null) {
      return const _TopAssetsSkeleton();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SegmentedButton<_TopAssetsRange>(
          segments: const [
            ButtonSegment(value: _TopAssetsRange.today, label: Text('Today')),
            ButtonSegment(
                value: _TopAssetsRange.last7Days, label: Text('Last 7 Days')),
            ButtonSegment(
                value: _TopAssetsRange.last30Days, label: Text('Last 30 Days')),
          ],
          selected: {_range},
          showSelectedIcon: false,
          style: ButtonStyle(
            visualDensity: VisualDensity.compact,
            textStyle: WidgetStatePropertyAll(
              OpenVtsTypography.meta.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          onSelectionChanged: _changeRange,
        ),
        const SizedBox(height: OpenVtsSpacing.sm),
        if (data.items.isEmpty)
          const UserDashboardWidgetEmpty(
            message: 'No top assets for this range.',
            icon: Icons.leaderboard_outlined,
          )
        else
          _TopAssetsList(items: data.items.take(10).toList(growable: false)),
      ],
    );
  }
}

class _TopAssetsList extends StatelessWidget {
  const _TopAssetsList({required this.items});

  final List<UserDashboardTopAssetItem> items;

  @override
  Widget build(BuildContext context) {
    final maxKm = items.fold<double>(
      0,
      (max, item) => math.max(max, item.drivenKm),
    );

    return Column(
      children: [
        for (var index = 0; index < items.length; index++) ...[
          _TopAssetRow(
            rank: index + 1,
            item: items[index],
            maxKm: maxKm,
          ),
          if (index != items.length - 1)
            const SizedBox(height: OpenVtsSpacing.sm),
        ],
      ],
    );
  }
}

class _TopAssetRow extends StatelessWidget {
  const _TopAssetRow({
    required this.rank,
    required this.item,
    required this.maxKm,
  });

  final int rank;
  final UserDashboardTopAssetItem item;
  final double maxKm;

  @override
  Widget build(BuildContext context) {
    final percent = (item.drivenKm / math.max(maxKm, 1)).clamp(0.0, 1.0);
    final subtitle = [
      if (item.plateNumber?.trim().isNotEmpty ?? false) item.plateNumber!,
      if (item.imei.trim().isNotEmpty) item.imei,
    ].join(' · ');

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: OpenVtsColors.surface,
            borderRadius: BorderRadius.circular(OpenVtsRadius.sm),
            border: Border.all(color: OpenVtsColors.border),
          ),
          child: Text(
            '$rank',
            style: OpenVtsTypography.meta.copyWith(
              color: OpenVtsColors.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: OpenVtsSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item.vehicleName.trim().isEmpty
                          ? 'Vehicle ${item.vehicleId}'
                          : item.vehicleName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: OpenVtsTypography.label.copyWith(
                        color: OpenVtsColors.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: OpenVtsSpacing.sm),
                  Text(
                    userDashboardFormatDistance(item.drivenKm),
                    style: OpenVtsTypography.meta.copyWith(
                      color: OpenVtsColors.textPrimary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              if (subtitle.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: OpenVtsTypography.meta.copyWith(
                    color: OpenVtsColors.textSecondary,
                  ),
                ),
              ],
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(OpenVtsRadius.pill),
                child: LinearProgressIndicator(
                  value: percent,
                  minHeight: 7,
                  color: OpenVtsColors.brandInk,
                  backgroundColor: OpenVtsColors.surface,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TopAssetsSkeleton extends StatelessWidget {
  const _TopAssetsSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _SkeletonBlock(height: 40),
        const SizedBox(height: OpenVtsSpacing.sm),
        for (var index = 0; index < 5; index++) ...[
          const _SkeletonBlock(height: 42),
          if (index != 4) const SizedBox(height: OpenVtsSpacing.sm),
        ],
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

enum _TopAssetsRange {
  today,
  last7Days,
  last30Days;

  _ResolvedRange resolve() {
    final now = DateTime.now();
    switch (this) {
      case _TopAssetsRange.today:
        return _ResolvedRange(
          from: DateTime(now.year, now.month, now.day),
          to: now,
        );
      case _TopAssetsRange.last7Days:
        return _ResolvedRange(
          from: now.subtract(const Duration(days: 7)),
          to: now,
        );
      case _TopAssetsRange.last30Days:
        return _ResolvedRange(
          from: now.subtract(const Duration(days: 30)),
          to: now,
        );
    }
  }
}

class _ResolvedRange {
  const _ResolvedRange({required this.from, required this.to});

  final DateTime from;
  final DateTime to;
}
