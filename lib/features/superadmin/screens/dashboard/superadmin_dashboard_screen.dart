import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/open_vts_colors.dart';
import '../../../../core/theme/open_vts_radius.dart';
import '../../../../core/theme/open_vts_spacing.dart';
import '../../../../core/theme/open_vts_typography.dart';
import '../../../../core/utils/date_time_formatter.dart';
import '../../../../shared/widgets/open_vts_button.dart';
import '../../../../shared/widgets/open_vts_card.dart';
import '../../../../shared/widgets/open_vts_date_time_range_selector.dart';
import '../../../../shared/widgets/open_vts_empty_state.dart';
import '../../../../shared/widgets/open_vts_error_view.dart';
import '../../../../shared/widgets/open_vts_loader.dart';
import '../../../../shared/widgets/open_vts_page_scaffold.dart';
import '../../controllers/superadmin_providers.dart';
import '../../models/superadmin_dashboard_model.dart';
import '../../models/superadmin_dashboard_state.dart';

const DateTimeFormatter _dashboardDateFormatter = DateTimeFormatter();

class SuperadminDashboardScreen extends ConsumerStatefulWidget {
  const SuperadminDashboardScreen({super.key});

  @override
  ConsumerState<SuperadminDashboardScreen> createState() =>
      _SuperadminDashboardScreenState();
}

class _SuperadminDashboardScreenState
    extends ConsumerState<SuperadminDashboardScreen> {
  _DashboardChartRange _selectedRange = _DashboardChartRange.twelveMonths;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(superadminDashboardControllerProvider);
    final controller =
        ref.read(superadminDashboardControllerProvider.notifier);

    return OpenVtsPageScaffold(
      title: 'Dashboard',
      headerMode: OpenVtsPageHeaderMode.closeable,
      padding: EdgeInsets.zero,
      body: _buildBody(context, state, controller),
    );
  }

  Widget _buildBody(
    BuildContext context,
    SuperadminDashboardState state,
    dynamic controller,
  ) {
    if (state.isInitialLoading && !state.hasData) {
      return const OpenVtsLoader();
    }

    if (!state.hasData) {
      return OpenVtsErrorView(
        message: state.errorMessage ?? 'Dashboard could not be loaded.',
        onRetry: () => controller.load(),
      );
    }

    final dashboard = state.dashboard!;
    final people = dashboard.recentUsers.isNotEmpty
        ? dashboard.recentUsers
        : dashboard.activityActors
            .take(5)
            .map(
              (actor) => SuperadminRecentUser(
                id: actor.id.toString(),
                name: actor.name,
                email: '—',
                createdAt: null,
              ),
            )
            .toList(growable: false);

    return RefreshIndicator(
      color: Theme.of(context).colorScheme.primary,
      onRefresh: () => controller.refresh(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(
          OpenVtsSpacing.sm,
          OpenVtsSpacing.sm,
          OpenVtsSpacing.sm,
          OpenVtsSpacing.lg,
        ),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 920),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (state.isRefreshing)
                    const Padding(
                      padding: EdgeInsets.only(bottom: OpenVtsSpacing.sm),
                      child: LinearProgressIndicator(minHeight: 2),
                    ),
                  if (state.errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: OpenVtsSpacing.sm),
                      child: _InlineErrorBanner(
                        message: state.errorMessage!,
                        onRetry: () => controller.refresh(),
                      ),
                    ),
                  _MetricsGrid(counts: dashboard.counts),
                  const SizedBox(height: OpenVtsSpacing.sm),
                  _AdoptionGrowthSection(
                    points: _pointsForRange(dashboard.adoptionGrowth),
                    selectedRange: _selectedRange,
                    onRangeChanged: (range) {
                      setState(() {
                        _selectedRange = range;
                      });
                    },
                  ),
                  const SizedBox(height: OpenVtsSpacing.sm),
                  _VehicleStatusSection(summary: dashboard.vehicleStatus),
                  const SizedBox(height: OpenVtsSpacing.sm),
                  _RecentVehiclesSection(vehicles: dashboard.recentVehicles),
                  const SizedBox(height: OpenVtsSpacing.sm),
                  _TransactionsSection(transactions: dashboard.transactions),
                  const SizedBox(height: OpenVtsSpacing.sm),
                  _RecentUsersSection(users: people),
                  const SizedBox(height: OpenVtsSpacing.sm),
                  _ActivityLogsSection(
                    logs: dashboard.activityLogs.items,
                    state: state,
                    onOpenFilters: () => _openActivityFilterSheet(context, state),
                    onClearFilters: state.hasActiveFilters
                        ? () => controller.clearFilters()
                        : null,
                    onLoadMore: dashboard.activityLogs.hasMore
                        ? () => controller.loadMoreActivityLogs()
                        : null,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<SuperadminAdoptionPoint> _pointsForRange(
    List<SuperadminAdoptionPoint> points,
  ) {
    if (points.isEmpty) {
      return points;
    }

    switch (_selectedRange) {
      case _DashboardChartRange.twelveMonths:
        if (points.length <= 12) {
          return points;
        }
        return points.sublist(points.length - 12);
      case _DashboardChartRange.sixMonths:
        if (points.length <= 6) {
          return points;
        }
        return points.sublist(points.length - 6);
      case _DashboardChartRange.threeMonths:
        if (points.length <= 3) {
          return points;
        }
        return points.sublist(points.length - 3);
      case _DashboardChartRange.all:
        return points;
    }
  }

  Future<void> _openActivityFilterSheet(
    BuildContext context,
    SuperadminDashboardState state,
  ) async {
    final result = await showModalBottomSheet<_DashboardActivityFilterResult>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(OpenVtsRadius.xl),
        ),
      ),
      builder: (context) {
        var selectedActorId = state.selectedActorId;
        var fromDate = state.fromDate;
        var toDate = state.toDate;
        final actors = state.dashboard?.activityActors ?? const <SuperadminActorOption>[];

        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  OpenVtsSpacing.md,
                  OpenVtsSpacing.xs,
                  OpenVtsSpacing.md,
                  MediaQuery.of(context).viewInsets.bottom + OpenVtsSpacing.lg,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Filter Activity Logs',
                      style: OpenVtsTypography.titleSmall.copyWith(
                        color: OpenVtsColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: OpenVtsSpacing.xs),
                    Text(
                      'Filter by administrator and date range.',
                      style: OpenVtsTypography.body.copyWith(
                        color: OpenVtsColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: OpenVtsSpacing.md),
                    DropdownButtonFormField<int?>(
                      initialValue: selectedActorId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Actor',
                      ),
                      items: [
                        const DropdownMenuItem<int?>(
                          value: null,
                          child: Text('All actors'),
                        ),
                        ...actors.map(
                          (actor) => DropdownMenuItem<int?>(
                            value: actor.id,
                            child: Text(actor.name),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        setModalState(() {
                          selectedActorId = value;
                        });
                      },
                    ),
                    const SizedBox(height: OpenVtsSpacing.sm),
                    OpenVtsDateTimeRangeField(
                      label: 'Date Range',
                      title: 'Choose Date Range',
                      value: OpenVtsDateTimeRange(
                        start: fromDate,
                        end: toDate,
                      ),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                      onChanged: (range) {
                        setModalState(() {
                          fromDate = range.start == null
                              ? null
                              : DateUtils.dateOnly(range.start!);
                          toDate = range.end == null
                              ? null
                              : DateUtils.dateOnly(range.end!);
                        });
                      },
                    ),
                    const SizedBox(height: OpenVtsSpacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: OpenVtsButton(
                            label: 'Clear',
                            variant: OpenVtsButtonVariant.secondary,
                            onPressed: () {
                              Navigator.of(context).pop(
                                const _DashboardActivityFilterResult.clear(),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: OpenVtsSpacing.sm),
                        Expanded(
                          child: OpenVtsButton(
                            label: 'Apply Filters',
                            onPressed: () {
                              Navigator.of(context).pop(
                                _DashboardActivityFilterResult(
                                  actorId: selectedActorId,
                                  fromDate: fromDate,
                                  toDate: toDate,
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (!mounted || result == null) {
      return;
    }

    final controller = ref.read(superadminDashboardControllerProvider.notifier);
    if (result.clearFilters) {
      await controller.clearFilters();
      return;
    }

    await controller.applyFilters(
      actorId: result.actorId,
      from: result.fromDate,
      to: result.toDate,
    );
  }
}

enum _DashboardChartRange {
  twelveMonths('12M'),
  sixMonths('6M'),
  threeMonths('3M'),
  all('All');

  const _DashboardChartRange(this.label);

  final String label;
}

class _MetricsGrid extends StatelessWidget {
  const _MetricsGrid({required this.counts});

  final SuperadminDashboardCounts counts;

  @override
  Widget build(BuildContext context) {
    final metrics = <_MetricTileData>[
      _MetricTileData(
        title: 'All Admins',
        value: counts.totalAdmins,
        icon: Icons.admin_panel_settings_outlined,
      ),
      _MetricTileData(
        title: 'Total Vehicles',
        value: counts.totalVehicles,
        icon: Icons.local_shipping_outlined,
      ),
      _MetricTileData(
        title: 'Active Vehicle',
        value: counts.activeVehicles,
        icon: Icons.bolt_outlined,
      ),
      _MetricTileData(
        title: 'Total Users',
        value: counts.totalUsers,
        icon: Icons.group_outlined,
      ),
      _MetricTileData(
        title: 'License Issued',
        value: counts.licensesIssued,
        icon: Icons.article_outlined,
      ),
      _MetricTileData(
        title: 'License Used',
        value: counts.licensesUsed,
        icon: Icons.adjust_outlined,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth >= 760 ? 3 : 2;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: metrics.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: OpenVtsSpacing.sm,
            crossAxisSpacing: OpenVtsSpacing.sm,
            childAspectRatio: 1.52,
          ),
          itemBuilder: (context, index) => _MetricTile(data: metrics[index]),
        );
      },
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.data});

  final _MetricTileData data;

  @override
  Widget build(BuildContext context) {
    return OpenVtsCard(
      padding: const EdgeInsets.fromLTRB(
        OpenVtsSpacing.md,
        OpenVtsSpacing.md,
        OpenVtsSpacing.md,
        OpenVtsSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  data.title.toUpperCase(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: OpenVtsTypography.meta.copyWith(
                    color: OpenVtsColors.textTertiary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              Icon(
                data.icon,
                size: 16,
                color: OpenVtsColors.textTertiary,
              ),
            ],
          ),
          const Spacer(),
          Text(
            NumberFormat.decimalPattern('en_IN').format(data.value),
            style: OpenVtsTypography.numeric.copyWith(
              fontSize: 19,
              color: OpenVtsColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricTileData {
  const _MetricTileData({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final int value;
  final IconData icon;
}

class _AdoptionGrowthSection extends StatelessWidget {
  const _AdoptionGrowthSection({
    required this.points,
    required this.selectedRange,
    required this.onRangeChanged,
  });

  final List<SuperadminAdoptionPoint> points;
  final _DashboardChartRange selectedRange;
  final ValueChanged<_DashboardChartRange> onRangeChanged;

  @override
  Widget build(BuildContext context) {
    final latestPoint = points.isNotEmpty ? points.last : null;

    return OpenVtsCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              OpenVtsSpacing.md,
              OpenVtsSpacing.md,
              OpenVtsSpacing.md,
              OpenVtsSpacing.sm,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Adoption & Growth',
                        style: OpenVtsTypography.titleSmall.copyWith(
                          color: OpenVtsColors.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: OpenVtsSpacing.xxs),
                      Text(
                        latestPoint == null
                            ? 'Platform growth across users, vehicles, and licenses.'
                            : 'Premium trend view for ${latestPoint.label} across users, vehicles, and license credits.',
                        style: OpenVtsTypography.meta.copyWith(
                          color: OpenVtsColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                _RangeSelector(
                  selectedRange: selectedRange,
                  onRangeChanged: onRangeChanged,
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: OpenVtsSpacing.md),
            child: Wrap(
              spacing: OpenVtsSpacing.md,
              runSpacing: OpenVtsSpacing.xs,
              children: [
                _LegendDot(label: 'Vehicles', color: OpenVtsColors.info),
                _LegendDot(label: 'Users', color: OpenVtsColors.success),
                _LegendDot(label: 'Licenses', color: OpenVtsColors.warning),
              ],
            ),
          ),
          if (latestPoint != null) ...[
            const SizedBox(height: OpenVtsSpacing.sm),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: OpenVtsSpacing.md),
              child: Wrap(
                spacing: OpenVtsSpacing.sm,
                runSpacing: OpenVtsSpacing.sm,
                children: [
                  _ChartSeriesPill(
                    label: 'Vehicles',
                    color: OpenVtsColors.info,
                    value: latestPoint.vehicles,
                    periodLabel: latestPoint.label,
                  ),
                  _ChartSeriesPill(
                    label: 'Users',
                    color: OpenVtsColors.success,
                    value: latestPoint.users,
                    periodLabel: latestPoint.label,
                  ),
                  _ChartSeriesPill(
                    label: 'Licenses',
                    color: OpenVtsColors.warning,
                    value: latestPoint.licenses,
                    periodLabel: latestPoint.label,
                    isPrimary: true,
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: OpenVtsSpacing.md),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              OpenVtsSpacing.md,
              0,
              OpenVtsSpacing.md,
              OpenVtsSpacing.md,
            ),
            child: SizedBox(
              height: 320,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 260),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) {
                  final offsetAnimation = Tween<Offset>(
                    begin: const Offset(0, 0.02),
                    end: Offset.zero,
                  ).animate(animation);

                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: offsetAnimation,
                      child: child,
                    ),
                  );
                },
                child: points.isEmpty
                    ? const OpenVtsEmptyState(
                        key: ValueKey('empty-adoption-chart'),
                        title: 'No adoption data',
                        message: 'The overview response does not include chart points yet.',
                      )
                    : KeyedSubtree(
                        key: ValueKey<String>(
                          '${selectedRange.name}-${points.length}-${points.last.label}',
                        ),
                        child: _AdoptionChart(points: points),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RangeSelector extends StatelessWidget {
  const _RangeSelector({
    required this.selectedRange,
    required this.onRangeChanged,
  });

  final _DashboardChartRange selectedRange;
  final ValueChanged<_DashboardChartRange> onRangeChanged;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: OpenVtsColors.surface,
        borderRadius: BorderRadius.circular(OpenVtsRadius.md),
        border: Border.all(color: OpenVtsColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: _DashboardChartRange.values
              .map(
                (range) {
                  final isSelected = selectedRange == range;

                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(OpenVtsRadius.sm),
                      onTap: () => onRangeChanged(range),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        curve: Curves.easeOutCubic,
                        padding: const EdgeInsets.symmetric(
                          horizontal: OpenVtsSpacing.xs,
                          vertical: OpenVtsSpacing.xxs + 1,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? OpenVtsColors.white
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(OpenVtsRadius.sm),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: OpenVtsColors.brandInk.withValues(alpha: 0.08),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ]
                              : null,
                        ),
                        child: Text(
                          range.label,
                          style: OpenVtsTypography.meta.copyWith(
                            color: isSelected
                                ? OpenVtsColors.textPrimary
                                : OpenVtsColors.textTertiary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              )
              .toList(growable: false),
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: OpenVtsSpacing.xs,
        vertical: OpenVtsSpacing.xxs + 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(OpenVtsRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.18),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
          const SizedBox(width: OpenVtsSpacing.xxs),
          Text(
            label,
            style: OpenVtsTypography.meta.copyWith(
              color: OpenVtsColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartSeriesPill extends StatelessWidget {
  const _ChartSeriesPill({
    required this.label,
    required this.color,
    required this.value,
    required this.periodLabel,
    this.isPrimary = false,
  });

  final String label;
  final Color color;
  final int value;
  final String periodLabel;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 132),
      padding: const EdgeInsets.symmetric(
        horizontal: OpenVtsSpacing.sm,
        vertical: OpenVtsSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: isPrimary
            ? color.withValues(alpha: 0.08)
            : OpenVtsColors.white,
        borderRadius: BorderRadius.circular(OpenVtsRadius.md),
        border: Border.all(
          color: isPrimary
              ? color.withValues(alpha: 0.2)
              : OpenVtsColors.border,
        ),
        boxShadow: [
          BoxShadow(
            color: OpenVtsColors.brandInk.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 4,
            height: 28,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(OpenVtsRadius.pill),
            ),
          ),
          const SizedBox(width: OpenVtsSpacing.xs),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: OpenVtsTypography.meta.copyWith(
                  color: OpenVtsColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _formatCompactMetric(value),
                style: OpenVtsTypography.numeric.copyWith(
                  fontSize: 16,
                  color: OpenVtsColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(width: OpenVtsSpacing.sm),
          Text(
            periodLabel,
            style: OpenVtsTypography.meta.copyWith(
              color: OpenVtsColors.textTertiary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _AdoptionChart extends StatelessWidget {
  const _AdoptionChart({required this.points});

  final List<SuperadminAdoptionPoint> points;

  @override
  Widget build(BuildContext context) {
    final series = _buildSeries(points);
    final maxValue = _chartMax(series);
    final yValues = _chartYValues(maxValue);
    final latestPoint = points.last;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  OpenVtsColors.white,
                  Color.lerp(OpenVtsColors.surface, OpenVtsColors.white, 0.45) ??
                      OpenVtsColors.surface,
                ],
              ),
              borderRadius: BorderRadius.circular(OpenVtsRadius.lg),
              border: Border.all(
                color: OpenVtsColors.border.withValues(alpha: 0.95),
              ),
              boxShadow: [
                BoxShadow(
                  color: OpenVtsColors.brandInk.withValues(alpha: 0.035),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                OpenVtsSpacing.sm,
                OpenVtsSpacing.sm,
                OpenVtsSpacing.sm,
                OpenVtsSpacing.xs,
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Text(
                        'Latest period',
                        style: OpenVtsTypography.meta.copyWith(
                          color: OpenVtsColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: OpenVtsSpacing.xs),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: OpenVtsSpacing.xs,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: OpenVtsColors.surface,
                          borderRadius: BorderRadius.circular(OpenVtsRadius.pill),
                          border: Border.all(color: OpenVtsColors.border),
                        ),
                        child: Text(
                          latestPoint.label,
                          style: OpenVtsTypography.meta.copyWith(
                            color: OpenVtsColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'License peak ${_formatCompactMetric(latestPoint.licenses)}',
                        style: OpenVtsTypography.meta.copyWith(
                          color: OpenVtsColors.warning,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: OpenVtsSpacing.sm),
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          width: 54,
                          child: _YAxisLabels(yValues: yValues),
                        ),
                        const SizedBox(width: OpenVtsSpacing.xs),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(OpenVtsRadius.md),
                            child: CustomPaint(
                              painter: _AdoptionChartPainter(
                                series: series,
                                maxValue: maxValue,
                              ),
                              child: const SizedBox.expand(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: OpenVtsSpacing.xs),
                  const SizedBox(width: 62),
                  Expanded(
                    flex: 0,
                    child: Row(
                      children: [
                        const SizedBox(width: 62),
                        Expanded(child: _XAxisLabels(points: points)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  List<_AdoptionSeries> _buildSeries(List<SuperadminAdoptionPoint> points) {
    return [
      _AdoptionSeries(
        label: 'Vehicles',
        color: OpenVtsColors.info,
        values: points.map((point) => point.vehicles).toList(growable: false),
        fillOpacity: 0.06,
      ),
      _AdoptionSeries(
        label: 'Users',
        color: OpenVtsColors.success,
        values: points.map((point) => point.users).toList(growable: false),
        fillOpacity: 0.07,
      ),
      _AdoptionSeries(
        label: 'Licenses',
        color: OpenVtsColors.warning,
        values: points.map((point) => point.licenses).toList(growable: false),
        fillOpacity: 0.16,
        isPrimary: true,
      ),
    ];
  }

  int _chartMax(List<_AdoptionSeries> series) {
    final highest = series.fold<int>(
      0,
      (max, item) => math.max(
        max,
        item.values.fold<int>(0, (innerMax, value) => math.max(innerMax, value)),
      ),
    );

    if (highest <= 0) {
      return 1;
    }

    final exponent = math.pow(10, (math.log(highest) / math.ln10).floor());
    final magnitude = exponent.toDouble();
    final normalized = highest / magnitude;
    final niceNormalized = normalized <= 1
        ? 1
        : normalized <= 2
            ? 2
            : normalized <= 2.5
                ? 2.5
                : normalized <= 5
                    ? 5
                    : 10;

    return (niceNormalized * magnitude).round();
  }

  List<int> _chartYValues(int maxValue) {
    final divisions = 6;
    return List<int>.generate(
      divisions + 1,
      (index) => ((maxValue / divisions) * index).round(),
    );
  }
}

class _AdoptionChartPainter extends CustomPainter {
  const _AdoptionChartPainter({
    required this.series,
    required this.maxValue,
  });

  final List<_AdoptionSeries> series;
  final int maxValue;

  @override
  void paint(Canvas canvas, Size size) {
    final plotRect = Rect.fromLTWH(
      0,
      OpenVtsSpacing.xxs,
      size.width,
      size.height - OpenVtsSpacing.sm,
    );

    _drawPlotSurface(canvas, plotRect);
    _drawGrid(canvas, plotRect);

    if (series.isEmpty || series.first.values.length < 2) {
      return;
    }

    final stepX = plotRect.width / (series.first.values.length - 1);
    final focusRect = Rect.fromLTWH(
      plotRect.right - (stepX * 1.15),
      plotRect.top,
      stepX * 1.15,
      plotRect.height,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        focusRect,
        const Radius.circular(OpenVtsRadius.md),
      ),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            OpenVtsColors.warning.withValues(alpha: 0.07),
            OpenVtsColors.warning.withValues(alpha: 0.015),
          ],
        ).createShader(focusRect),
    );

    final latestX = plotRect.left + (stepX * (series.first.values.length - 1));
    canvas.drawLine(
      Offset(latestX, plotRect.top),
      Offset(latestX, plotRect.bottom),
      Paint()
        ..color = OpenVtsColors.warning.withValues(alpha: 0.16)
        ..strokeWidth = 1.2,
    );

    for (final item in series) {
      _drawSeries(
        canvas,
        plotRect,
        item,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _AdoptionChartPainter oldDelegate) {
    return oldDelegate.series != series || oldDelegate.maxValue != maxValue;
  }

  void _drawPlotSurface(Canvas canvas, Rect plotRect) {
    canvas.drawRect(
      plotRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            OpenVtsColors.white.withValues(alpha: 0.55),
            OpenVtsColors.surface.withValues(alpha: 0.18),
          ],
        ).createShader(plotRect),
    );
  }

  void _drawGrid(Canvas canvas, Rect plotRect) {
    final gridPaint = Paint()
      ..color = OpenVtsColors.border.withValues(alpha: 0.9)
      ..strokeWidth = 1;

    const gridLines = 6;
    for (var index = 0; index <= gridLines; index++) {
      final y = plotRect.top + (plotRect.height * index / gridLines);
      _drawDashedLine(
        canvas,
        Offset(plotRect.left, y),
        Offset(plotRect.right, y),
        gridPaint,
      );
    }
  }

  void _drawSeries(
    Canvas canvas,
    Rect plotRect,
    _AdoptionSeries series,
  ) {
    final points = _mapValuesToOffsets(series.values, plotRect);
    if (points.length < 2) {
      return;
    }

    final path = _buildSmoothPath(points, plotRect);
    final fillPath = Path.from(path)
      ..lineTo(points.last.dx, plotRect.bottom)
      ..lineTo(points.first.dx, plotRect.bottom)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          series.color.withValues(alpha: series.fillOpacity),
          series.color.withValues(alpha: 0.0),
        ],
      ).createShader(plotRect);
    canvas.drawPath(fillPath, fillPaint);

    final glowPaint = Paint()
      ..color = series.color.withValues(
        alpha: series.isPrimary ? 0.18 : 0.1,
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = series.isPrimary ? 8 : 6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawPath(path, glowPaint);

    final linePaint = Paint()
      ..color = series.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = series.isPrimary ? 2.9 : 2.35
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, linePaint);
    _drawLatestMarker(canvas, points.last, series);
  }

  List<Offset> _mapValuesToOffsets(List<int> values, Rect plotRect) {
    if (values.isEmpty) {
      return const <Offset>[];
    }

    if (values.length == 1) {
      final y = plotRect.bottom - ((values.first / maxValue) * plotRect.height);
      return [Offset(plotRect.left, y.clamp(plotRect.top, plotRect.bottom))];
    }

    return List<Offset>.generate(values.length, (index) {
      final x = plotRect.left + (plotRect.width * index / (values.length - 1));
      final y = plotRect.bottom - ((values[index] / maxValue) * plotRect.height);
      return Offset(x, y.clamp(plotRect.top, plotRect.bottom));
    });
  }

  Path _buildSmoothPath(List<Offset> points, Rect plotRect) {
    final path = Path()..moveTo(points.first.dx, points.first.dy);

    for (var index = 0; index < points.length - 1; index++) {
      final previous = index == 0 ? points[index] : points[index - 1];
      final current = points[index];
      final next = points[index + 1];
      final afterNext = index + 2 < points.length ? points[index + 2] : next;

      final controlPoint1 = Offset(
        current.dx + (next.dx - previous.dx) / 6,
        (current.dy + (next.dy - previous.dy) / 6)
            .clamp(plotRect.top, plotRect.bottom),
      );
      final controlPoint2 = Offset(
        next.dx - (afterNext.dx - current.dx) / 6,
        (next.dy - (afterNext.dy - current.dy) / 6)
            .clamp(plotRect.top, plotRect.bottom),
      );

      path.cubicTo(
        controlPoint1.dx,
        controlPoint1.dy,
        controlPoint2.dx,
        controlPoint2.dy,
        next.dx,
        next.dy,
      );
    }

    return path;
  }

  void _drawLatestMarker(
    Canvas canvas,
    Offset point,
    _AdoptionSeries series,
  ) {
    final haloRadius = series.isPrimary ? 8.5 : 6.5;
    final innerRadius = series.isPrimary ? 4.2 : 3.6;

    canvas.drawCircle(
      point,
      haloRadius,
      Paint()..color = series.color.withValues(alpha: 0.12),
    );
    canvas.drawCircle(
      point,
      haloRadius / 1.8,
      Paint()..color = OpenVtsColors.white,
    );
    canvas.drawCircle(
      point,
      innerRadius,
      Paint()..color = series.color,
    );
  }

  void _drawDashedLine(
    Canvas canvas,
    Offset start,
    Offset end,
    Paint paint,
  ) {
    const dashWidth = 5.0;
    const dashSpace = 4.0;
    final totalDistance = (end - start).distance;
    if (totalDistance == 0) {
      return;
    }
    final direction = (end - start) / totalDistance;
    var distance = 0.0;

    while (distance < totalDistance) {
      final dashStart = start + direction * distance;
      final dashEnd = start + direction * math.min(distance + dashWidth, totalDistance);
      canvas.drawLine(dashStart, dashEnd, paint);
      distance += dashWidth + dashSpace;
    }
  }
}

class _YAxisLabels extends StatelessWidget {
  const _YAxisLabels({required this.yValues});

  final List<int> yValues;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: yValues.reversed
          .map(
            (value) => Text(
              _formatAxisValue(value),
              textAlign: TextAlign.end,
              style: OpenVtsTypography.meta.copyWith(
                color: OpenVtsColors.textTertiary,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          )
          .toList(growable: false),
    );
  }
}

class _XAxisLabels extends StatelessWidget {
  const _XAxisLabels({required this.points});

  final List<SuperadminAdoptionPoint> points;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final useRotation = constraints.maxWidth < 620;
        final interval = constraints.maxWidth < 380
            ? 3
            : constraints.maxWidth < 560
                ? 2
                : 1;

        return SizedBox(
          height: useRotation ? 34 : 18,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List<Widget>.generate(points.length, (index) {
              final point = points[index];
              final showLabel = index == points.length - 1 || index % interval == 0;
              final style = OpenVtsTypography.meta.copyWith(
                color: index == points.length - 1
                    ? OpenVtsColors.textSecondary
                    : OpenVtsColors.textTertiary,
                fontSize: 10,
                fontWeight: index == points.length - 1
                    ? FontWeight.w700
                    : FontWeight.w600,
              );

              return Expanded(
                child: Align(
                  alignment: useRotation
                      ? Alignment.topLeft
                      : Alignment.topCenter,
                  child: !showLabel
                      ? const SizedBox.shrink()
                      : useRotation
                          ? Transform.rotate(
                              angle: -math.pi / 5.2,
                              alignment: Alignment.topLeft,
                              child: Text(
                                point.label,
                                maxLines: 1,
                                overflow: TextOverflow.visible,
                                style: style,
                              ),
                            )
                          : Text(
                              point.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: style,
                            ),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}

class _AdoptionSeries {
  const _AdoptionSeries({
    required this.label,
    required this.color,
    required this.values,
    this.fillOpacity = 0,
    this.isPrimary = false,
  });

  final String label;
  final Color color;
  final List<int> values;
  final double fillOpacity;
  final bool isPrimary;
}

String _formatCompactMetric(int value) {
  if (value >= 1000000) {
    return '${(value / 1000000).toStringAsFixed(2)}M';
  }
  if (value >= 1000) {
    return '${(value / 1000).toStringAsFixed(1)}k';
  }
  return value.toString();
}

String _formatAxisValue(int value) {
  if (value >= 1000) {
    return '${(value / 1000).toStringAsFixed(1)}k';
  }
  return value.toString();
}

class _VehicleStatusSection extends StatelessWidget {
  const _VehicleStatusSection({required this.summary});

  final SuperadminVehicleStatusSummary summary;

  @override
  Widget build(BuildContext context) {
    final statuses = <_VehicleStatusTileData>[
      _VehicleStatusTileData(
        label: 'Connected',
        count: summary.connectedCount,
        color: OpenVtsColors.success,
        icon: Icons.wifi_tethering_outlined,
      ),
      _VehicleStatusTileData(
        label: 'Running',
        count: summary.runningCount,
        color: OpenVtsColors.brandInk,
        icon: Icons.trending_up_outlined,
      ),
      _VehicleStatusTileData(
        label: 'Stop',
        count: summary.stopCount,
        color: OpenVtsColors.warning,
        icon: Icons.pause_circle_outline,
      ),
      _VehicleStatusTileData(
        label: 'Inactive - 48H',
        count: summary.inactiveCount,
        color: OpenVtsColors.divider,
        icon: Icons.warning_amber_outlined,
      ),
      _VehicleStatusTileData(
        label: 'No Data',
        count: summary.noDataCount,
        color: OpenVtsColors.textTertiary,
        icon: Icons.note_alt_outlined,
      ),
    ];

    return OpenVtsCard(
      padding: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(OpenVtsSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: OpenVtsColors.surface,
                    borderRadius: BorderRadius.circular(OpenVtsRadius.md),
                  ),
                  child: const Icon(
                    Icons.local_shipping_outlined,
                    size: 16,
                    color: OpenVtsColors.textPrimary,
                  ),
                ),
                const SizedBox(width: OpenVtsSpacing.xs),
                Text(
                  'Vehicle Status',
                  style: OpenVtsTypography.titleSmall.copyWith(fontSize: 20),
                ),
                const SizedBox(width: OpenVtsSpacing.xs),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: OpenVtsSpacing.xs,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: OpenVtsColors.success.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(OpenVtsRadius.pill),
                  ),
                  child: Text(
                    'LIVE',
                    style: OpenVtsTypography.meta.copyWith(
                      color: OpenVtsColors.success,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      NumberFormat.decimalPattern().format(summary.totalDevices),
                      style: OpenVtsTypography.numeric.copyWith(fontSize: 18),
                    ),
                    Text(
                      'DEVICES',
                      style: OpenVtsTypography.meta.copyWith(
                        color: OpenVtsColors.textTertiary,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: OpenVtsSpacing.md),
            LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = constraints.maxWidth >= 760 ? 3 : 2;

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: statuses.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    mainAxisSpacing: OpenVtsSpacing.sm,
                    crossAxisSpacing: OpenVtsSpacing.sm,
                    childAspectRatio: 1.55,
                  ),
                  itemBuilder: (context, index) => _VehicleStatusTile(
                    data: statuses[index],
                    totalDevices: summary.totalDevices,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _VehicleStatusTile extends StatelessWidget {
  const _VehicleStatusTile({
    required this.data,
    required this.totalDevices,
  });

  final _VehicleStatusTileData data;
  final int totalDevices;

  @override
  Widget build(BuildContext context) {
    final percentage = totalDevices <= 0
        ? 0.0
        : (data.count / totalDevices).clamp(0.0, 1.0);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: OpenVtsColors.white,
        borderRadius: BorderRadius.circular(OpenVtsRadius.md),
        border: Border.all(color: OpenVtsColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(OpenVtsSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(data.icon, size: 12, color: OpenVtsColors.textTertiary),
                const SizedBox(width: OpenVtsSpacing.xxs),
                Expanded(
                  child: Text(
                    data.label.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: OpenVtsTypography.meta.copyWith(
                      color: OpenVtsColors.textTertiary,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.7,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: OpenVtsSpacing.xs),
            RichText(
              text: TextSpan(
                style: OpenVtsTypography.numeric.copyWith(
                  color: OpenVtsColors.textPrimary,
                  fontSize: 18,
                ),
                children: [
                  TextSpan(text: data.count.toString()),
                  TextSpan(
                    text: ' ${(percentage * 100).round()}%',
                    style: OpenVtsTypography.body.copyWith(
                      color: OpenVtsColors.textTertiary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            ClipRRect(
              borderRadius: BorderRadius.circular(OpenVtsRadius.pill),
              child: LinearProgressIndicator(
                value: percentage,
                minHeight: 4,
                backgroundColor: OpenVtsColors.surface,
                color: data.color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VehicleStatusTileData {
  const _VehicleStatusTileData({
    required this.label,
    required this.count,
    required this.color,
    required this.icon,
  });

  final String label;
  final int count;
  final Color color;
  final IconData icon;
}

class _RecentVehiclesSection extends StatelessWidget {
  const _RecentVehiclesSection({required this.vehicles});

  final List<SuperadminRecentVehicle> vehicles;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Recent Vehicles',
      icon: Icons.local_shipping_outlined,
      child: vehicles.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(OpenVtsSpacing.lg),
              child: OpenVtsEmptyState(
                title: 'No recent vehicles',
                message: 'The overview response does not include recent vehicles yet.',
              ),
            )
          : Column(
              children: List<Widget>.generate(vehicles.length, (index) {
                final vehicle = vehicles[index];
                return Column(
                  children: [
                    if (index > 0) const Divider(height: 1, color: OpenVtsColors.border),
                    _RecentVehicleRow(vehicle: vehicle),
                  ],
                );
              }),
            ),
    );
  }
}

class _RecentVehicleRow extends StatelessWidget {
  const _RecentVehicleRow({required this.vehicle});

  final SuperadminRecentVehicle vehicle;

  @override
  Widget build(BuildContext context) {
    final dateText = vehicle.updatedAt == null
        ? '—'
      : _dashboardDateFormatter.formatDate(vehicle.updatedAt!.toLocal());

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: OpenVtsSpacing.md,
        vertical: OpenVtsSpacing.sm,
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(
              color: OpenVtsColors.surface,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.local_shipping_outlined,
              size: 16,
              color: OpenVtsColors.textTertiary,
            ),
          ),
          const SizedBox(width: OpenVtsSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  vehicle.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: OpenVtsTypography.body.copyWith(
                    color: OpenVtsColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  vehicle.subtitle,
                  style: OpenVtsTypography.meta.copyWith(
                    color: OpenVtsColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: OpenVtsSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                vehicle.status,
                style: OpenVtsTypography.meta.copyWith(
                  color: OpenVtsColors.success,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                dateText,
                style: OpenVtsTypography.meta.copyWith(
                  color: OpenVtsColors.textTertiary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TransactionsSection extends StatelessWidget {
  const _TransactionsSection({required this.transactions});

  final List<SuperadminTransaction> transactions;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Transactions',
      icon: Icons.credit_card_outlined,
      trailing: Text(
        'View All',
        style: OpenVtsTypography.meta.copyWith(
          color: OpenVtsColors.textSecondary,
          fontWeight: FontWeight.w700,
        ),
      ),
      child: transactions.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(OpenVtsSpacing.lg),
              child: OpenVtsEmptyState(
                title: 'No transactions',
                message: 'Transaction activity will appear here when available.',
              ),
            )
          : Column(
              children: List<Widget>.generate(transactions.length, (index) {
                final transaction = transactions[index];
                return Column(
                  children: [
                    if (index > 0) const Divider(height: 1, color: OpenVtsColors.border),
                    _TransactionRow(transaction: transaction),
                  ],
                );
              }),
            ),
    );
  }
}

class _TransactionRow extends StatelessWidget {
  const _TransactionRow({required this.transaction});

  final SuperadminTransaction transaction;

  @override
  Widget build(BuildContext context) {
    final amountText = '${transaction.amount.toStringAsFixed(0)} ${transaction.currency}';

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: OpenVtsSpacing.md,
        vertical: OpenVtsSpacing.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(
              color: OpenVtsColors.surface,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.receipt_long_outlined,
              size: 16,
              color: OpenVtsColors.textTertiary,
            ),
          ),
          const SizedBox(width: OpenVtsSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: OpenVtsTypography.body.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  transaction.subtitle,
                  style: OpenVtsTypography.meta.copyWith(
                    color: OpenVtsColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: OpenVtsSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amountText,
                style: OpenVtsTypography.body.copyWith(
                  color: OpenVtsColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                transaction.status.toUpperCase(),
                style: OpenVtsTypography.meta.copyWith(
                  color: OpenVtsColors.success,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RecentUsersSection extends StatelessWidget {
  const _RecentUsersSection({required this.users});

  final List<SuperadminRecentUser> users;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Recent Users',
      icon: Icons.group_outlined,
      child: users.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(OpenVtsSpacing.lg),
              child: OpenVtsEmptyState(
                title: 'No recent users',
                message: 'Recent users will appear here when the dashboard overview returns them.',
              ),
            )
          : Column(
              children: List<Widget>.generate(users.length, (index) {
                final user = users[index];
                return Column(
                  children: [
                    if (index > 0) const Divider(height: 1, color: OpenVtsColors.border),
                    _RecentUserRow(user: user),
                  ],
                );
              }),
            ),
    );
  }
}

class _RecentUserRow extends StatelessWidget {
  const _RecentUserRow({required this.user});

  final SuperadminRecentUser user;

  @override
  Widget build(BuildContext context) {
    final relativeText = _formatRelativeDate(user.createdAt);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: OpenVtsSpacing.md,
        vertical: OpenVtsSpacing.sm,
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: OpenVtsColors.brandInk,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              _userInitials(user),
              style: OpenVtsTypography.meta.copyWith(
                color: OpenVtsColors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: OpenVtsSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: OpenVtsTypography.body.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  user.email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: OpenVtsTypography.meta.copyWith(
                    color: OpenVtsColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: OpenVtsSpacing.sm),
          Text(
            relativeText,
            style: OpenVtsTypography.meta.copyWith(
              color: OpenVtsColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  String _userInitials(SuperadminRecentUser user) {
    if (user.initials != null && user.initials!.trim().isNotEmpty) {
      return user.initials!.trim().toUpperCase();
    }

    final parts = user.name
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList(growable: false);
    if (parts.isEmpty) {
      return 'U';
    }
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
        .toUpperCase();
  }
}

class _ActivityLogsSection extends StatelessWidget {
  const _ActivityLogsSection({
    required this.logs,
    required this.state,
    required this.onOpenFilters,
    this.onClearFilters,
    this.onLoadMore,
  });

  final List<SuperadminActivityLog> logs;
  final SuperadminDashboardState state;
  final VoidCallback onOpenFilters;
  final VoidCallback? onClearFilters;
  final VoidCallback? onLoadMore;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Activity Logs',
      icon: Icons.insights_outlined,
      trailing: IconButton(
        tooltip: 'Filter activity logs',
        onPressed: onOpenFilters,
        icon: Icon(
          Icons.filter_alt_outlined,
          size: 18,
          color: state.hasActiveFilters
              ? OpenVtsColors.brandInk
              : OpenVtsColors.textTertiary,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (state.hasActiveFilters)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                OpenVtsSpacing.md,
                OpenVtsSpacing.sm,
                OpenVtsSpacing.md,
                0,
              ),
              child: Wrap(
                spacing: OpenVtsSpacing.xs,
                runSpacing: OpenVtsSpacing.xs,
                children: [
                  if (state.selectedActorId != null)
                    _FilterChipLabel(
                      label: _actorName(
                        state.dashboard?.activityActors ?? const <SuperadminActorOption>[],
                        state.selectedActorId!,
                      ),
                    ),
                  if (state.fromDate != null)
                    _FilterChipLabel(
                      label: 'From ${_dashboardDateFormatter.formatDate(state.fromDate!.toLocal())}',
                    ),
                  if (state.toDate != null)
                    _FilterChipLabel(
                      label: 'To ${_dashboardDateFormatter.formatDate(state.toDate!.toLocal())}',
                    ),
                  if (onClearFilters != null)
                    GestureDetector(
                      onTap: onClearFilters,
                      child: Text(
                        'Clear',
                        style: OpenVtsTypography.meta.copyWith(
                          color: OpenVtsColors.textSecondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          if (logs.isEmpty)
            const Padding(
              padding: EdgeInsets.all(OpenVtsSpacing.lg),
              child: OpenVtsEmptyState(
                title: 'No activity logs',
                message: 'Recent activity will appear here once the backend returns it.',
              ),
            )
          else
            Column(
              children: List<Widget>.generate(logs.length, (index) {
                final log = logs[index];
                return Column(
                  children: [
                    if (index > 0) const Divider(height: 1, color: OpenVtsColors.border),
                    _ActivityLogRow(log: log),
                  ],
                );
              }),
            ),
          if (onLoadMore != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                OpenVtsSpacing.md,
                0,
                OpenVtsSpacing.md,
                OpenVtsSpacing.md,
              ),
              child: Center(
                child: TextButton(
                  onPressed: state.isLoadingMore ? null : onLoadMore,
                  child: state.isLoadingMore
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Load More'),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _actorName(List<SuperadminActorOption> actors, int actorId) {
    for (final actor in actors) {
      if (actor.id == actorId) {
        return actor.name;
      }
    }
    return 'Actor #$actorId';
  }
}

class _ActivityLogRow extends StatelessWidget {
  const _ActivityLogRow({required this.log});

  final SuperadminActivityLog log;

  @override
  Widget build(BuildContext context) {
    final tone = _activityTone(log.title);
    final relativeText = _formatRelativeDate(log.createdAt, shortUnits: true);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: OpenVtsSpacing.md,
        vertical: OpenVtsSpacing.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: tone.color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              tone.icon,
              size: 16,
              color: tone.color,
            ),
          ),
          const SizedBox(width: OpenVtsSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  log.title,
                  style: OpenVtsTypography.body.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: OpenVtsSpacing.xs,
                  runSpacing: OpenVtsSpacing.xxs,
                  children: [
                    Text(
                      log.actorName,
                      style: OpenVtsTypography.meta.copyWith(
                        color: OpenVtsColors.textTertiary,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: OpenVtsSpacing.xs,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: OpenVtsColors.surface,
                        borderRadius: BorderRadius.circular(OpenVtsRadius.sm),
                        border: Border.all(color: OpenVtsColors.border),
                      ),
                      child: Text(
                        log.actorRole.toUpperCase(),
                        style: OpenVtsTypography.meta.copyWith(
                          color: OpenVtsColors.textSecondary,
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: OpenVtsSpacing.sm),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.schedule_outlined,
                size: 13,
                color: OpenVtsColors.textTertiary,
              ),
              const SizedBox(width: 3),
              Text(
                relativeText,
                style: OpenVtsTypography.meta.copyWith(
                  color: OpenVtsColors.textTertiary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  _ActivityTone _activityTone(String title) {
    final value = title.toLowerCase();
    if (value.contains('login') || value.contains('auth')) {
      return const _ActivityTone(
        icon: Icons.login_rounded,
        color: Color(0xFF8B6FF7),
      );
    }
    if (value.contains('upload')) {
      return const _ActivityTone(
        icon: Icons.cloud_upload_outlined,
        color: OpenVtsColors.textTertiary,
      );
    }
    return const _ActivityTone(
      icon: Icons.add_rounded,
      color: OpenVtsColors.success,
    );
  }
}

class _ActivityTone {
  const _ActivityTone({
    required this.icon,
    required this.color,
  });

  final IconData icon;
  final Color color;
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
    this.trailing,
  });

  final String title;
  final IconData icon;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return OpenVtsCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: OpenVtsSpacing.md,
              vertical: OpenVtsSpacing.sm,
            ),
            child: Row(
              children: [
                Icon(icon, size: 16, color: OpenVtsColors.textPrimary),
                const SizedBox(width: OpenVtsSpacing.xs),
                Expanded(
                  child: Text(
                    title,
                    style: OpenVtsTypography.titleSmall.copyWith(fontSize: 18),
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
          ),
          const Divider(height: 1, color: OpenVtsColors.border),
          child,
        ],
      ),
    );
  }
}

class _InlineErrorBanner extends StatelessWidget {
  const _InlineErrorBanner({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: OpenVtsColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(OpenVtsRadius.md),
        border: Border.all(
          color: OpenVtsColors.error.withValues(alpha: 0.2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(OpenVtsSpacing.sm),
        child: Row(
          children: [
            const Icon(
              Icons.info_outline,
              size: 16,
              color: OpenVtsColors.error,
            ),
            const SizedBox(width: OpenVtsSpacing.xs),
            Expanded(
              child: Text(
                message,
                style: OpenVtsTypography.meta.copyWith(
                  color: OpenVtsColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            TextButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChipLabel extends StatelessWidget {
  const _FilterChipLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: OpenVtsSpacing.xs,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: OpenVtsColors.surface,
        borderRadius: BorderRadius.circular(OpenVtsRadius.pill),
        border: Border.all(color: OpenVtsColors.border),
      ),
      child: Text(
        label,
        style: OpenVtsTypography.meta.copyWith(
          color: OpenVtsColors.textSecondary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _DashboardActivityFilterResult {
  const _DashboardActivityFilterResult({
    this.actorId,
    this.fromDate,
    this.toDate,
    this.clearFilters = false,
  });

  const _DashboardActivityFilterResult.clear()
      : this(clearFilters: true);

  final int? actorId;
  final DateTime? fromDate;
  final DateTime? toDate;
  final bool clearFilters;
}

String _formatRelativeDate(DateTime? date, {bool shortUnits = false}) {
  if (date == null) {
    return '—';
  }

  final now = DateTime.now();
  final localDate = date.toLocal();
  final difference = now.difference(localDate);
  if (difference.inMinutes < 1) {
    return shortUnits ? 'now' : 'just now';
  }
  if (difference.inHours < 1) {
    return '${difference.inMinutes}m ago';
  }
  if (difference.inHours < 24) {
    return '${difference.inHours}h ago';
  }
  if (difference.inDays == 1) {
    return 'yesterday';
  }
  if (difference.inDays < 7) {
    return '${difference.inDays}d ago';
  }
  return DateFormat('dd MMM yyyy').format(localDate);
}
