import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/open_vts_colors.dart';
import '../../../../core/theme/open_vts_radius.dart';
import '../../../../core/theme/open_vts_spacing.dart';
import '../../../../core/theme/open_vts_typography.dart';
import '../../../../core/utils/date_time_formatter.dart';
import '../../../../shared/widgets/open_vts_card.dart';
import '../../../../shared/widgets/open_vts_error_view.dart';
import '../../../../shared/widgets/open_vts_loader.dart';
import '../../../../shared/widgets/open_vts_page_scaffold.dart';
import '../../controllers/admin_dashboard_controller.dart';
import '../../controllers/admin_providers.dart';
import '../../models/admin_dashboard_model.dart';
import '../../models/admin_dashboard_state.dart';
import 'widgets/admin_growth_chart_card.dart';
import 'widgets/admin_recent_payments_card.dart';
import 'widgets/admin_recent_users_card.dart';
import 'widgets/admin_recent_vehicles_card.dart';
import 'widgets/admin_top_clients_card.dart';
import 'widgets/admin_vehicle_expiry_card.dart';

const DateTimeFormatter _dateFormatter = DateTimeFormatter();
const double _dashboardMaxWidth = 920;

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(adminDashboardControllerProvider);
    final controller = ref.read(adminDashboardControllerProvider.notifier);

    return OpenVtsPageScaffold(
      title: 'Dashboard',
      headerMode: OpenVtsPageHeaderMode.closeable,
      padding: EdgeInsets.zero,
      body: _buildBody(context, state, controller),
    );
  }

  Widget _buildBody(
    BuildContext context,
    AdminDashboardState state,
    AdminDashboardController controller,
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
              constraints: const BoxConstraints(maxWidth: _dashboardMaxWidth),
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
                  _DashboardHeader(
                    dashboard: dashboard,
                    isRefreshing: state.isRefreshing,
                    onRefresh: () => controller.refresh(),
                    onCurrencyChanged: (currency) =>
                        controller.changeCurrency(currency),
                  ),
                  const SizedBox(height: OpenVtsSpacing.sm),
                  _KpiGrid(dashboard: dashboard),
                  const SizedBox(height: OpenVtsSpacing.sm),
                  _VehicleLiveStatusSection(
                    status: dashboard.vehicleLiveStatus,
                    totalVehicles: dashboard.totals.totalVehicles,
                  ),
                  const SizedBox(height: OpenVtsSpacing.sm),
                  _RevenueForecastSection(dashboard: dashboard),
                  const SizedBox(height: OpenVtsSpacing.sm),
                  AdminGrowthChartCard(points: dashboard.graph),
                  const SizedBox(height: OpenVtsSpacing.sm),
                  AdminVehicleExpiryCard(
                    expiry: dashboard.expiry,
                    currency: dashboard.selectedCurrency,
                  ),
                  const SizedBox(height: OpenVtsSpacing.sm),
                  AdminTopClientsCard(
                    clients: dashboard.topClients,
                    currency: dashboard.selectedCurrency,
                  ),
                  const SizedBox(height: OpenVtsSpacing.sm),
                  AdminRecentUsersCard(users: dashboard.recent.users),
                  const SizedBox(height: OpenVtsSpacing.sm),
                  AdminRecentVehiclesCard(
                    vehicles: dashboard.recent.vehicles,
                  ),
                  const SizedBox(height: OpenVtsSpacing.sm),
                  AdminRecentPaymentsCard(
                    payments: dashboard.recent.payments,
                    fallbackCurrency: dashboard.selectedCurrency,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({
    required this.dashboard,
    required this.isRefreshing,
    required this.onRefresh,
    required this.onCurrencyChanged,
  });

  final AdminDashboardSummary dashboard;
  final bool isRefreshing;
  final Future<void> Function() onRefresh;
  final ValueChanged<String> onCurrencyChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final controls = _DashboardControls(
          dashboard: dashboard,
          isRefreshing: isRefreshing,
          onRefresh: onRefresh,
          onCurrencyChanged: onCurrencyChanged,
          alignment: constraints.maxWidth < 560
              ? WrapAlignment.start
              : WrapAlignment.end,
        );

        final title = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dashboard',
              style: OpenVtsTypography.titleSmall.copyWith(
                color: OpenVtsColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              'Fleet management overview · Admin Panel',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: OpenVtsTypography.meta.copyWith(
                color: OpenVtsColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        );

        if (constraints.maxWidth < 560) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              title,
              const SizedBox(height: OpenVtsSpacing.xs),
              controls,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: title),
            const SizedBox(width: OpenVtsSpacing.sm),
            Flexible(child: controls),
          ],
        );
      },
    );
  }
}

class _DashboardControls extends StatelessWidget {
  const _DashboardControls({
    required this.dashboard,
    required this.isRefreshing,
    required this.onRefresh,
    required this.onCurrencyChanged,
    required this.alignment,
  });

  final AdminDashboardSummary dashboard;
  final bool isRefreshing;
  final Future<void> Function() onRefresh;
  final ValueChanged<String> onCurrencyChanged;
  final WrapAlignment alignment;

  @override
  Widget build(BuildContext context) {
    final currencies = dashboard.availableCurrencies
        .map((currency) => currency.trim().toUpperCase())
        .where((currency) => currency.isNotEmpty)
        .toSet()
        .toList(growable: false);
    final selectedCurrency = currencies.contains(dashboard.selectedCurrency)
        ? dashboard.selectedCurrency
        : currencies.isNotEmpty
            ? currencies.first
            : dashboard.selectedCurrency;

    return Wrap(
      alignment: alignment,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: OpenVtsSpacing.xs,
      runSpacing: OpenVtsSpacing.xs,
      children: [
        if (currencies.length > 1)
          _CurrencySelector(
            currencies: currencies,
            selectedCurrency: selectedCurrency,
            onChanged: onCurrencyChanged,
          ),
        _UpdatedTimePill(
          generatedAt: dashboard.generatedAt,
          isRefreshing: isRefreshing,
        ),
        _RefreshIconButton(
          isRefreshing: isRefreshing,
          onRefresh: onRefresh,
        ),
      ],
    );
  }
}

class _CurrencySelector extends StatelessWidget {
  const _CurrencySelector({
    required this.currencies,
    required this.selectedCurrency,
    required this.onChanged,
  });

  final List<String> currencies;
  final String selectedCurrency;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: OpenVtsSpacing.xs),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(OpenVtsRadius.pill),
        border: Border.all(color: OpenVtsColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedCurrency,
          isDense: true,
          borderRadius: BorderRadius.circular(OpenVtsRadius.md),
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 16),
          items: currencies
              .map(
                (currency) => DropdownMenuItem<String>(
                  value: currency,
                  child: Text(
                    currency,
                    style: OpenVtsTypography.meta.copyWith(
                      color: OpenVtsColors.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              )
              .toList(growable: false),
          onChanged: (value) {
            if (value != null) {
              onChanged(value);
            }
          },
        ),
      ),
    );
  }
}

class _UpdatedTimePill extends StatelessWidget {
  const _UpdatedTimePill({
    required this.generatedAt,
    required this.isRefreshing,
  });

  final DateTime? generatedAt;
  final bool isRefreshing;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: OpenVtsSpacing.sm),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(OpenVtsRadius.pill),
        border: Border.all(color: OpenVtsColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isRefreshing) ...[
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: OpenVtsSpacing.xxs),
            Text(
              'Refreshing',
              style: OpenVtsTypography.meta.copyWith(
                color: OpenVtsColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ] else ...[
            const Icon(
              Icons.schedule_rounded,
              size: 14,
              color: OpenVtsColors.textTertiary,
            ),
            const SizedBox(width: OpenVtsSpacing.xxs),
            Text(
              'Updated ${formatTimeSafe(generatedAt)}',
              style: OpenVtsTypography.meta.copyWith(
                color: OpenVtsColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RefreshIconButton extends StatelessWidget {
  const _RefreshIconButton({
    required this.isRefreshing,
    required this.onRefresh,
  });

  final bool isRefreshing;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Refresh dashboard',
      onPressed: isRefreshing ? null : () => onRefresh(),
      style: IconButton.styleFrom(
        minimumSize: const Size.square(34),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        padding: EdgeInsets.zero,
        backgroundColor: Theme.of(context).colorScheme.surface,
        disabledBackgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: OpenVtsColors.textPrimary,
        disabledForegroundColor: OpenVtsColors.textTertiary,
        side: const BorderSide(color: OpenVtsColors.border),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(OpenVtsRadius.pill),
        ),
      ),
      icon: const Icon(Icons.refresh_rounded, size: 17),
    );
  }
}

class _KpiGrid extends StatelessWidget {
  const _KpiGrid({required this.dashboard});

  final AdminDashboardSummary dashboard;

  @override
  Widget build(BuildContext context) {
    final currency = dashboard.selectedCurrency;
    final kpis = <_KpiData>[
      _KpiData(
        title: 'All Vehicles',
        value: formatCompactNumber(dashboard.totals.totalVehicles),
        subtitle: '${formatNumber(dashboard.totals.totalVehicles)} registered',
        icon: Icons.directions_car_outlined,
      ),
      _KpiData(
        title: 'All Users',
        value: formatCompactNumber(dashboard.totals.totalUsers),
        subtitle: '${formatNumber(dashboard.totals.totalUsers)} registered',
        icon: Icons.group_outlined,
      ),
      _KpiData(
        title: 'Last Month Revenue',
        value: formatCurrency(dashboard.revenue.lastMonthRevenue, currency),
        icon: _currencyIcon(currency),
      ),
      _KpiData(
        title: 'Pending Payments',
        value: formatCurrency(dashboard.revenue.pendingAmount, currency),
        subtitle: '${dashboard.revenue.pendingCount} invoices',
        icon: Icons.credit_card_outlined,
      ),
      _KpiData(
        title: 'Vehicle Expiry',
        value: '${dashboard.expiry.thisWeek} / ${dashboard.expiry.thisMonth}',
        subtitle: 'wk / mo',
        icon: Icons.calendar_today_outlined,
      ),
      _KpiData(
        title: 'Device Installs',
        value: formatCompactNumber(dashboard.installs.thisMonth),
        subtitle: 'this month',
        icon: Icons.build_outlined,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth >= 760 ? 3 : 2;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: kpis.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: OpenVtsSpacing.sm,
            crossAxisSpacing: OpenVtsSpacing.sm,
            childAspectRatio: crossAxisCount == 3 ? 1.7 : 1.42,
          ),
          itemBuilder: (context, index) => _KpiCard(data: kpis[index]),
        );
      },
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({required this.data});

  final _KpiData data;

  @override
  Widget build(BuildContext context) {
    return OpenVtsCard(
      padding: const EdgeInsets.all(OpenVtsSpacing.sm),
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
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                width: 27,
                height: 27,
                decoration: BoxDecoration(
                  color: OpenVtsColors.surface,
                  borderRadius: BorderRadius.circular(OpenVtsRadius.sm),
                  border: Border.all(color: OpenVtsColors.border),
                ),
                child: Icon(
                  data.icon,
                  size: 16,
                  color: OpenVtsColors.textSecondary,
                ),
              ),
            ],
          ),
          const Spacer(),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              data.value,
              maxLines: 1,
              style: OpenVtsTypography.numeric.copyWith(
                color: OpenVtsColors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (data.subtitle != null) ...[
            const SizedBox(height: 3),
            Text(
              data.subtitle!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: OpenVtsTypography.meta.copyWith(
                color: OpenVtsColors.textSecondary,
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _VehicleLiveStatusSection extends StatelessWidget {
  const _VehicleLiveStatusSection({
    required this.status,
    required this.totalVehicles,
  });

  final AdminVehicleLiveStatus status;
  final int totalVehicles;

  @override
  Widget build(BuildContext context) {
    final segments = <_StatusSegment>[
      _StatusSegment(
        label: 'Connected',
        value: status.connected,
        icon: Icons.wifi_rounded,
        color: const Color(0xFF111827),
      ),
      _StatusSegment(
        label: 'Running',
        value: status.running,
        icon: Icons.speed_outlined,
        color: const Color(0xFF3F3F46),
      ),
      _StatusSegment(
        label: 'Stop',
        value: status.stop,
        icon: Icons.pause_circle_outline_rounded,
        color: const Color(0xFF6B7280),
      ),
      _StatusSegment(
        label: 'Inactive',
        value: status.inactive,
        icon: Icons.warning_amber_rounded,
        color: const Color(0xFF9EA7B0),
      ),
      _StatusSegment(
        label: 'No Data',
        value: status.noData,
        icon: Icons.storage_outlined,
        color: const Color(0xFFD6DEE5),
      ),
    ];
    final barTotal = math.max(status.installedDevices, 1);

    return OpenVtsCard(
      padding: const EdgeInsets.all(OpenVtsSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeading(
            title: 'Vehicle Live Status',
            icon: Icons.directions_car_outlined,
            badge: 'Live',
          ),
          const SizedBox(height: OpenVtsSpacing.sm),
          Wrap(
            spacing: OpenVtsSpacing.xs,
            runSpacing: OpenVtsSpacing.xs,
            children: [
              _MetricPill(
                label: 'Vehicles',
                value: formatNumber(totalVehicles),
                icon: Icons.directions_car_outlined,
              ),
              _MetricPill(
                label: 'Devices Installed',
                value: formatNumber(status.installedDevices),
                icon: Icons.memory_outlined,
              ),
            ],
          ),
          const SizedBox(height: OpenVtsSpacing.sm),
          Wrap(
            spacing: OpenVtsSpacing.xs,
            runSpacing: OpenVtsSpacing.xs,
            children: [
              for (final segment in segments)
                _StatusPill(
                  label: segment.label,
                  value: segment.value,
                  icon: segment.icon,
                ),
              _StatusPill(
                label: 'No Device',
                value: status.noDevice,
                icon: Icons.wifi_off_outlined,
              ),
            ],
          ),
          const SizedBox(height: OpenVtsSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(OpenVtsRadius.pill),
            child: SizedBox(
              height: 10,
              child: ColoredBox(
                color: OpenVtsColors.surface,
                child: Row(
                  children: [
                    for (final segment in segments)
                      if (segment.value > 0)
                        Expanded(
                          flex: math.max(
                            1,
                            ((segment.value / barTotal) * 1000).round(),
                          ),
                          child: ColoredBox(
                            color: segment.color,
                          ),
                        ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: OpenVtsSpacing.xs),
          Wrap(
            spacing: OpenVtsSpacing.sm,
            runSpacing: OpenVtsSpacing.xxs,
            children: [
              for (final segment in segments)
                _StatusLegendItem(
                  label: segment.label,
                  percent: _statusPercent(segment.value, barTotal),
                  color: segment.color,
                ),
              if (status.noDevice > 0)
                _StatusLegendItem(
                  label: 'No Device',
                  count: status.noDevice,
                  color: OpenVtsColors.textTertiary,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RevenueForecastSection extends StatelessWidget {
  const _RevenueForecastSection({required this.dashboard});

  final AdminDashboardSummary dashboard;

  @override
  Widget build(BuildContext context) {
    final revenue = dashboard.revenue;
    final currency = dashboard.selectedCurrency;
    final currentMonthRevenue = revenue.thisMonthRevenue;
    final target = revenue.projectedThisMonth;
    final projected = revenue.projectedThisMonth;
    final collectedPct = _progressPercent(currentMonthRevenue, target);
    final projectedPct = _progressPercent(projected, target);
    final delta = projected - target;

    return OpenVtsCard(
      padding: const EdgeInsets.all(OpenVtsSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeading(
            title: 'Revenue Forecast',
            icon: Icons.trending_up_rounded,
          ),
          const SizedBox(height: OpenVtsSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: _PrimaryValueBlock(
                  label: 'This month',
                  value: formatCurrency(currentMonthRevenue, currency),
                ),
              ),
              const SizedBox(width: OpenVtsSpacing.sm),
              _InlineMetric(
                label: 'Target',
                value: formatCurrency(target, currency),
              ),
            ],
          ),
          const SizedBox(height: OpenVtsSpacing.sm),
          Row(
            children: [
              Text(
                '${collectedPct.round()}% collected',
                style: OpenVtsTypography.meta.copyWith(
                  color: OpenVtsColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: OpenVtsSpacing.sm),
              Expanded(
                child: Text(
                  'Projected ${formatCurrency(projected, currency)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: OpenVtsTypography.meta.copyWith(
                    color: OpenVtsColors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: OpenVtsSpacing.xs),
          _RevenueProgressBar(
            collectedPct: collectedPct,
            projectedPct: projectedPct,
          ),
          const SizedBox(height: OpenVtsSpacing.sm),
          Row(
            children: [
              const _RevenueLegendItem(
                label: 'Collected',
                color: OpenVtsColors.brandInk,
              ),
              const SizedBox(width: OpenVtsSpacing.sm),
              _RevenueLegendItem(
                label: 'Projected',
                color: OpenVtsColors.brandInk.withValues(alpha: 0.45),
              ),
              const SizedBox(width: OpenVtsSpacing.sm),
              Expanded(
                child: Text(
                  'Delta ${formatCurrency(delta, currency)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: OpenVtsTypography.meta.copyWith(
                    color: OpenVtsColors.textSecondary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: OpenVtsSpacing.sm),
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    _InfoRow(
                      label: 'Last month revenue',
                      value: formatCurrency(revenue.lastMonthRevenue, currency),
                    ),
                    _InfoRow(
                      label: 'Pending payments',
                      value:
                          '${formatCurrency(revenue.pendingAmount, currency)} · '
                          '${revenue.pendingCount} invoices',
                    ),
                  ],
                ),
              ),
              const SizedBox(width: OpenVtsSpacing.sm),
              OutlinedButton.icon(
                onPressed: () => context.push(RoutePaths.adminPayments),
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(
                    horizontal: OpenVtsSpacing.xs,
                    vertical: 8,
                  ),
                  foregroundColor: OpenVtsColors.textPrimary,
                  side: const BorderSide(color: OpenVtsColors.border),
                  textStyle: OpenVtsTypography.meta.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                icon: const Icon(Icons.arrow_forward_rounded, size: 15),
                label: const Text('View Payments'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.title,
    required this.icon,
    this.badge,
  });

  final String title;
  final IconData icon;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: OpenVtsColors.surface,
            borderRadius: BorderRadius.circular(OpenVtsRadius.sm),
            border: Border.all(color: OpenVtsColors.border),
          ),
          child: Icon(icon, size: 16, color: OpenVtsColors.textSecondary),
        ),
        const SizedBox(width: OpenVtsSpacing.xs),
        Flexible(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: OpenVtsTypography.label.copyWith(
              color: OpenVtsColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        if (badge != null) ...[
          const SizedBox(width: OpenVtsSpacing.xs),
          _TextBadge(label: badge!),
        ],
      ],
    );
  }
}

class _TextBadge extends StatelessWidget {
  const _TextBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: OpenVtsColors.surface,
        borderRadius: BorderRadius.circular(OpenVtsRadius.pill),
        border: Border.all(color: OpenVtsColors.border),
      ),
      child: Text(
        label.toUpperCase(),
        style: OpenVtsTypography.meta.copyWith(
          color: OpenVtsColors.textSecondary,
          fontSize: 9.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  const _MetricPill({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: OpenVtsSpacing.xs,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(OpenVtsRadius.md),
        border: Border.all(color: OpenVtsColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: OpenVtsColors.textTertiary),
          const SizedBox(width: OpenVtsSpacing.xxs),
          Text(
            label,
            style: OpenVtsTypography.meta.copyWith(
              color: OpenVtsColors.textSecondary,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: OpenVtsSpacing.xxs),
          Text(
            value,
            style: OpenVtsTypography.meta.copyWith(
              color: OpenVtsColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final int value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: OpenVtsColors.surface,
        borderRadius: BorderRadius.circular(OpenVtsRadius.md),
        border: Border.all(color: OpenVtsColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: OpenVtsColors.textSecondary),
          const SizedBox(width: OpenVtsSpacing.xxs),
          Text(
            label,
            style: OpenVtsTypography.meta.copyWith(
              color: OpenVtsColors.textSecondary,
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: OpenVtsSpacing.xxs),
          Text(
            formatNumber(value),
            style: OpenVtsTypography.meta.copyWith(
              color: OpenVtsColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusLegendItem extends StatelessWidget {
  const _StatusLegendItem({
    required this.label,
    required this.color,
    this.percent,
    this.count,
  });

  final String label;
  final Color color;
  final int? percent;
  final int? count;

  @override
  Widget build(BuildContext context) {
    final trailing = count == null ? '$percent%' : formatNumber(count!);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: OpenVtsSpacing.xxs),
        Text(
          '$label · $trailing',
          style: OpenVtsTypography.meta.copyWith(
            color: OpenVtsColors.textSecondary,
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _RevenueProgressBar extends StatelessWidget {
  const _RevenueProgressBar({
    required this.collectedPct,
    required this.projectedPct,
  });

  final double collectedPct;
  final double projectedPct;

  @override
  Widget build(BuildContext context) {
    final markerLeft = (projectedPct.clamp(0, 100) / 100).toDouble();

    return SizedBox(
      height: 12,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final markerDx = (constraints.maxWidth * markerLeft)
              .clamp(1.0, constraints.maxWidth - 2);

          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                top: 2,
                bottom: 2,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(OpenVtsRadius.pill),
                  child: ColoredBox(
                    color: OpenVtsColors.surface,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor:
                            (collectedPct.clamp(0, 100) / 100).toDouble(),
                        child: const ColoredBox(
                          color: OpenVtsColors.brandInk,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: markerDx - 1,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 2,
                  decoration: BoxDecoration(
                    color: OpenVtsColors.brandInk.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(OpenVtsRadius.pill),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _RevenueLegendItem extends StatelessWidget {
  const _RevenueLegendItem({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: OpenVtsSpacing.xxs),
        Text(
          label,
          style: OpenVtsTypography.meta.copyWith(
            color: OpenVtsColors.textSecondary,
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _PrimaryValueBlock extends StatelessWidget {
  const _PrimaryValueBlock({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: OpenVtsTypography.meta.copyWith(
            color: OpenVtsColors.textSecondary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 3),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            maxLines: 1,
            style: OpenVtsTypography.numeric.copyWith(
              color: OpenVtsColors.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _InlineMetric extends StatelessWidget {
  const _InlineMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          label,
          style: OpenVtsTypography.meta.copyWith(
            color: OpenVtsColors.textSecondary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 3),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerRight,
          child: Text(
            value,
            maxLines: 1,
            style: OpenVtsTypography.label.copyWith(
              color: OpenVtsColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: OpenVtsSpacing.xs),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: OpenVtsTypography.meta.copyWith(
                color: OpenVtsColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: OpenVtsSpacing.sm),
          Flexible(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              style: OpenVtsTypography.meta.copyWith(
                color: OpenVtsColors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
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
        color: OpenVtsColors.error.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(OpenVtsRadius.md),
        border: Border.all(
          color: OpenVtsColors.error.withValues(alpha: 0.18),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(OpenVtsSpacing.sm),
        child: Row(
          children: [
            const Icon(
              Icons.info_outline_rounded,
              size: 16,
              color: OpenVtsColors.error,
            ),
            const SizedBox(width: OpenVtsSpacing.xs),
            Expanded(
              child: Text(
                message,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: OpenVtsTypography.meta.copyWith(
                  color: OpenVtsColors.textPrimary,
                  fontWeight: FontWeight.w600,
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

class _KpiData {
  const _KpiData({
    required this.title,
    required this.value,
    required this.icon,
    this.subtitle,
  });

  final String title;
  final String value;
  final IconData icon;
  final String? subtitle;
}

class _StatusSegment {
  const _StatusSegment({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final int value;
  final IconData icon;
  final Color color;
}

const Set<String> _knownCurrencyCodes = <String>{
  'AED',
  'AUD',
  'CAD',
  'CHF',
  'CNY',
  'EUR',
  'GBP',
  'INR',
  'JPY',
  'NZD',
  'SAR',
  'SGD',
  'USD',
};

String formatCurrency(num value, String currency) {
  final code = _normalizeCurrencyCode(currency);
  final locale = code == 'INR' ? 'en_IN' : 'en_US';
  final number = NumberFormat.decimalPattern(locale).format(value.round());

  if (!_knownCurrencyCodes.contains(code)) {
    return '$code $number';
  }

  try {
    return NumberFormat.simpleCurrency(
      locale: locale,
      name: code,
      decimalDigits: 0,
    ).format(value);
  } catch (_) {
    return '$code $number';
  }
}

String formatCompactNumber(num value) {
  return NumberFormat.compact(locale: 'en_IN').format(value);
}

String formatNumber(num value) {
  return NumberFormat.decimalPattern('en_IN').format(value);
}

String formatDateSafe(DateTime? value) {
  if (value == null) {
    return '-';
  }
  return _dateFormatter.formatDate(value.toLocal());
}

String formatTimeSafe(DateTime? value) {
  if (value == null) {
    return '-';
  }
  return _dateFormatter.formatTime(value.toLocal());
}

String _normalizeCurrencyCode(String currency) {
  final raw = currency.trim().toUpperCase();
  const aliases = <String, String>{
    'CA': 'CAD',
    'US': 'USD',
    'IN': 'INR',
    'EU': 'EUR',
    'GB': 'GBP',
    'AE': 'AED',
  };
  return aliases[raw] ?? (raw.isEmpty ? 'USD' : raw);
}

IconData _currencyIcon(String currency) {
  return _normalizeCurrencyCode(currency) == 'INR'
      ? Icons.currency_rupee_rounded
      : Icons.account_balance_wallet_outlined;
}

int _statusPercent(int value, int total) {
  if (total <= 0) {
    return 0;
  }
  return ((value / total) * 100).clamp(0, 100).round();
}

double _progressPercent(num value, num total) {
  if (total <= 0) {
    return 0;
  }
  return ((value / total) * 100).clamp(0, 100).toDouble();
}
