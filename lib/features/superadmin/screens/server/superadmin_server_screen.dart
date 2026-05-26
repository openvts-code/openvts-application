import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/open_vts_colors.dart';
import '../../../../core/theme/open_vts_radius.dart';
import '../../../../core/theme/open_vts_spacing.dart';
import '../../../../core/theme/open_vts_typography.dart';
import '../../../../core/utils/date_time_formatter.dart';
import '../../../../shared/widgets/open_vts_card.dart';
import '../../../../shared/widgets/open_vts_error_view.dart';
import '../../../../shared/widgets/open_vts_page_scaffold.dart';
import '../../controllers/superadmin_providers.dart';
import '../../controllers/superadmin_server_controller.dart';
import '../../models/superadmin_server_model.dart';
import '../../models/superadmin_server_state.dart';

const DateTimeFormatter _serverDateFormatter = DateTimeFormatter();

class SuperadminServerScreen extends ConsumerWidget {
  const SuperadminServerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(superadminServerControllerProvider);
    final controller = ref.read(superadminServerControllerProvider.notifier);

    return OpenVtsPageScaffold(
      title: 'Server',
      headerMode: OpenVtsPageHeaderMode.closeable,
      padding: EdgeInsets.zero,
      body: _ServerPageBody(
        state: state,
        controller: controller,
      ),
    );
  }
}

class _ServerPageBody extends StatelessWidget {
  const _ServerPageBody({
    required this.state,
    required this.controller,
  });

  final SuperadminServerState state;
  final SuperadminServerController controller;

  @override
  Widget build(BuildContext context) {
    final isLoading = state.isInitialLoading && !state.hasData;
    final hasError = !isLoading && !state.hasData && state.errorMessage != null;

    if (hasError) {
      return OpenVtsErrorView(
        message: state.errorMessage ?? 'Server overview could not be loaded.',
        onRetry: () => controller.load(),
      );
    }

    final overview = state.overview;

    return RefreshIndicator(
      color: Theme.of(context).colorScheme.primary,
      onRefresh: controller.refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(
          OpenVtsSpacing.md,
          OpenVtsSpacing.sm,
          OpenVtsSpacing.md,
          OpenVtsSpacing.xl,
        ),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ServerHeroCard(
                    overview: overview,
                    isRefreshing: state.isRefreshing,
                    isLoading: isLoading,
                    onRefresh: controller.refresh,
                  ),
                  const SizedBox(height: OpenVtsSpacing.sm),
                  const _ImportantBanner(),
                  if (state.activeJob != null) ...[
                    const SizedBox(height: OpenVtsSpacing.sm),
                    _ServerJobCard(job: state.activeJob!),
                  ],
                  if (state.errorMessage != null) ...[
                    const SizedBox(height: OpenVtsSpacing.sm),
                    _InlineErrorBanner(
                      message: state.errorMessage!,
                      onRetry: controller.refresh,
                    ),
                  ],
                  const SizedBox(height: OpenVtsSpacing.sm),
                  _MetricsRow(
                    isLoading: isLoading,
                    overview: overview,
                  ),
                  const SizedBox(height: OpenVtsSpacing.sm),
                  if (isLoading)
                    const _ServicesSkeleton()
                  else
                    _ServicesSection(
                      components: overview?.components ?? const [],
                      state: state,
                      onAction: controller.runAction,
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

class _MetricsRow extends StatelessWidget {
  const _MetricsRow({
    required this.isLoading,
    required this.overview,
  });

  final bool isLoading;
  final SuperadminServerOverview? overview;

  @override
  Widget build(BuildContext context) {
    final cards = <Widget>[
      _MetricCard(
        title: 'CPU Usage',
        value: isLoading ? null : _formatPercent(overview?.cpuPercent),
        caption: isLoading ? null : overview?.cpuLoadText,
        icon: Icons.memory_rounded,
        progress: _progressValue(overview?.cpuPercent),
        showProgress: !isLoading && (overview?.cpuPercent ?? 0) > 0,
        isLoading: isLoading,
      ),
      _MetricCard(
        title: 'Memory Usage',
        value: isLoading
            ? null
            : _formatCapacitySummary(
                overview?.memoryPercent,
                overview?.memoryUsedGb,
                overview?.memoryTotalGb,
              ),
        icon: Icons.monitor_heart_outlined,
        progress: _progressValue(overview?.memoryPercent),
        isLoading: isLoading,
      ),
      _MetricCard(
        title: 'Disk Usage',
        value: isLoading
            ? null
            : _formatDiskSummary(
                overview?.diskLabel ?? '',
                overview?.diskPercent,
                overview?.diskUsedGb,
                overview?.diskTotalGb,
              ),
        icon: Icons.storage_rounded,
        progress: _progressValue(overview?.diskPercent),
        isLoading: isLoading,
      ),
      _MetricCard(
        title: 'Server Uptime',
        value: isLoading ? null : overview?.serverUptimeText,
        icon: Icons.dns_rounded,
        showProgress: false,
        isLoading: isLoading,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        if (width >= 600) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (int i = 0; i < cards.length; i++) ...[
                if (i > 0) const SizedBox(width: OpenVtsSpacing.sm),
                Expanded(child: cards[i]),
              ],
            ],
          );
        }

        if (width >= 380) {
          return Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: cards[0]),
                  const SizedBox(width: OpenVtsSpacing.sm),
                  Expanded(child: cards[1]),
                ],
              ),
              const SizedBox(height: OpenVtsSpacing.sm),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: cards[2]),
                  const SizedBox(width: OpenVtsSpacing.sm),
                  Expanded(child: cards[3]),
                ],
              ),
            ],
          );
        }

        return Column(
          children: [
            for (int i = 0; i < cards.length; i++) ...[
              if (i > 0) const SizedBox(height: OpenVtsSpacing.sm),
              cards[i],
            ],
          ],
        );
      },
    );
  }
}

class _ServerHeroCard extends StatelessWidget {
  const _ServerHeroCard({
    required this.overview,
    required this.isRefreshing,
    required this.isLoading,
    required this.onRefresh,
  });

  final SuperadminServerOverview? overview;
  final bool isRefreshing;
  final bool isLoading;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final refreshedAt = overview?.checkedAt;

    return OpenVtsCard(
      padding: const EdgeInsets.all(OpenVtsSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Server Health Monitoring',
            style: OpenVtsTypography.titleSmall.copyWith(
              color: OpenVtsColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: OpenVtsSpacing.xxs),
          Text(
            'Monitor uptime, dependencies, and safe service actions',
            style: OpenVtsTypography.body.copyWith(
              color: OpenVtsColors.textSecondary,
            ),
          ),
          const SizedBox(height: OpenVtsSpacing.md),
          Wrap(
            spacing: OpenVtsSpacing.xs,
            runSpacing: OpenVtsSpacing.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (isLoading)
                const _SkeletonBlock(width: 160, height: 30)
              else
                _HeaderStatusPill(
                  label: 'Local agent: ${overview?.agentStatusText ?? '—'}',
                  isOnline: overview?.isAgentOnline ?? false,
                ),
              _CompactOutlineButton(
                label: isRefreshing ? 'Refreshing' : 'Refresh',
                icon: Icons.refresh_rounded,
                onPressed: (isRefreshing || isLoading)
                    ? null
                    : () => onRefresh(),
                isLoading: isRefreshing,
              ),
            ],
          ),
          const SizedBox(height: OpenVtsSpacing.sm),
          if (isLoading)
            const _SkeletonBlock(width: 180, height: 14)
          else
            Text(
              refreshedAt == null
                  ? 'Last check: —'
                  : 'Last check: ${_serverDateFormatter.formatDateTime(refreshedAt)}',
              style: OpenVtsTypography.meta.copyWith(
                color: OpenVtsColors.textSecondary,
              ),
            ),
        ],
      ),
    );
  }
}

class _ImportantBanner extends StatelessWidget {
  const _ImportantBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(OpenVtsSpacing.md),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF9E8),
        borderRadius: BorderRadius.circular(OpenVtsRadius.lg),
        border: Border.all(color: const Color(0xFFE2C24F)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(
              Icons.warning_amber_rounded,
              size: 18,
              color: Color(0xFFB58817),
            ),
          ),
          const SizedBox(width: OpenVtsSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Important',
                  style: OpenVtsTypography.label.copyWith(
                    color: OpenVtsColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: OpenVtsSpacing.xxs),
                Text(
                  'Stopping Frontend/Backend/Listener can lock you out of the application. This page allows Start and Restart for those services, but Stop is disabled.',
                  style: OpenVtsTypography.body.copyWith(
                    color: OpenVtsColors.textPrimary,
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

class _ServerJobCard extends StatelessWidget {
  const _ServerJobCard({required this.job});

  final SuperadminServerJob job;

  @override
  Widget build(BuildContext context) {
    final statusStyle = _statusVisualsForJob(job.status);

    return OpenVtsCard(
      padding: const EdgeInsets.all(OpenVtsSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Latest Server Action',
                      style: OpenVtsTypography.label.copyWith(
                        color: OpenVtsColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: OpenVtsSpacing.xxs),
                    Text(
                      '${job.componentName} • ${serverActionLabel(job.action)}',
                      style: OpenVtsTypography.titleSmall.copyWith(
                        color: OpenVtsColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              _ServiceStatusPill(
                label: job.status.label,
                dotColor: statusStyle.color,
                backgroundColor: statusStyle.background,
              ),
            ],
          ),
          const SizedBox(height: OpenVtsSpacing.sm),
          Text(
            job.displayMessage,
            style: OpenVtsTypography.body.copyWith(
              color: OpenVtsColors.textPrimary,
            ),
          ),
          if (job.updatedAt != null) ...[
            const SizedBox(height: OpenVtsSpacing.xs),
            Text(
              'Updated ${_serverDateFormatter.formatDateTime(job.updatedAt!)}',
              style: OpenVtsTypography.meta.copyWith(
                color: OpenVtsColors.textSecondary,
              ),
            ),
          ],
          if (!job.isTerminal) ...[
            const SizedBox(height: OpenVtsSpacing.sm),
            const LinearProgressIndicator(minHeight: 2),
          ],
          if (job.logLines.isNotEmpty) ...[
            const SizedBox(height: OpenVtsSpacing.sm),
            ...job.logLines.reversed.take(2).map(
                  (line) => Padding(
                    padding: const EdgeInsets.only(bottom: OpenVtsSpacing.xxs),
                    child: Text(
                      line,
                      style: OpenVtsTypography.meta.copyWith(
                        color: OpenVtsColors.textSecondary,
                      ),
                    ),
                  ),
                ),
          ],
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    this.caption,
    this.progress = 0,
    this.showProgress = true,
    this.isLoading = false,
  });

  final String title;
  final String? value;
  final String? caption;
  final IconData icon;
  final double progress;
  final bool showProgress;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return OpenVtsCard(
      padding: const EdgeInsets.all(OpenVtsSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: OpenVtsTypography.label.copyWith(
                        color: OpenVtsColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: OpenVtsSpacing.xs),
                    if (isLoading)
                      const _SkeletonLine(widthFactor: 0.6, height: 28)
                    else
                      Text(
                        value ?? '—',
                        style: OpenVtsTypography.titleSmall.copyWith(
                          color: OpenVtsColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    if (isLoading) ...[
                      const SizedBox(height: OpenVtsSpacing.xxs),
                      const _SkeletonLine(widthFactor: 0.85, height: 14),
                    ] else if (caption != null &&
                        caption!.trim().isNotEmpty) ...[
                      const SizedBox(height: OpenVtsSpacing.xxs),
                      Text(
                        caption!,
                        style: OpenVtsTypography.meta.copyWith(
                          color: OpenVtsColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                icon,
                size: 18,
                color: OpenVtsColors.textSecondary,
              ),
            ],
          ),
          if (showProgress && !isLoading) ...[
            const SizedBox(height: OpenVtsSpacing.md),
            _MetricProgressBar(progress: progress),
          ] else if (isLoading && showProgress) ...[
            const SizedBox(height: OpenVtsSpacing.md),
            const _SkeletonBlock(height: 5),
          ],
        ],
      ),
    );
  }
}

class _MetricProgressBar extends StatelessWidget {
  const _MetricProgressBar({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final clamped = progress.clamp(0.0, 1.0);
    final color = _progressColor(clamped);

    return ClipRRect(
      borderRadius: BorderRadius.circular(OpenVtsRadius.pill),
      child: Container(
        height: 5,
        color: OpenVtsColors.border,
        alignment: AlignmentDirectional.centerStart,
        child: AnimatedFractionallySizedBox(
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutCubic,
          widthFactor: clamped,
          child: Container(
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(OpenVtsRadius.pill),
            ),
          ),
        ),
      ),
    );
  }

  static Color _progressColor(double fraction) {
    if (fraction >= 0.90) return OpenVtsColors.error;
    if (fraction >= 0.75) return OpenVtsColors.warning;
    return OpenVtsColors.brandInk;
  }
}

class _ServicesSection extends StatelessWidget {
  const _ServicesSection({
    required this.components,
    required this.state,
    required this.onAction,
  });

  final List<SuperadminServerComponent> components;
  final SuperadminServerState state;
  final Future<void> Function(
      {required String componentId, required String action}) onAction;

  @override
  Widget build(BuildContext context) {
    return OpenVtsCard(
      padding: const EdgeInsets.all(OpenVtsSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Services',
                      style: OpenVtsTypography.titleSmall.copyWith(
                        color: OpenVtsColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: OpenVtsSpacing.xxs),
                    Text(
                      components.map((component) => component.name).join(', '),
                      style: OpenVtsTypography.meta.copyWith(
                        color: OpenVtsColors.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: OpenVtsSpacing.sm,
                  vertical: OpenVtsSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F7FB),
                  borderRadius: BorderRadius.circular(OpenVtsRadius.pill),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.bubble_chart_rounded,
                      size: 12,
                      color: OpenVtsColors.info,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'System Metrics',
                      style: OpenVtsTypography.meta.copyWith(
                        color: OpenVtsColors.info,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: OpenVtsSpacing.md),
          LayoutBuilder(
            builder: (context, constraints) {
              final useGrid = constraints.maxWidth >= 480;
              if (!useGrid) {
                return Column(
                  children: components
                      .map(
                        (component) => Padding(
                          padding: const EdgeInsets.only(
                            bottom: OpenVtsSpacing.sm,
                          ),
                          child: _ServiceCard(
                            component: component,
                            isBusy: state.isBusyComponent(component.id),
                            isSubmitting: (action) =>
                                state.isSubmitting(component.id, action),
                            onAction: onAction,
                          ),
                        ),
                      )
                      .toList(growable: false),
                );
              }

              final rows = <Widget>[];
              for (var i = 0; i < components.length; i += 2) {
                final left = components[i];
                final hasRight = i + 1 < components.length;
                rows.add(
                  Padding(
                    padding:
                        const EdgeInsets.only(bottom: OpenVtsSpacing.sm),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _ServiceCard(
                            component: left,
                            isBusy: state.isBusyComponent(left.id),
                            isSubmitting: (action) =>
                                state.isSubmitting(left.id, action),
                            onAction: onAction,
                          ),
                        ),
                        const SizedBox(width: OpenVtsSpacing.sm),
                        if (hasRight)
                          Expanded(
                            child: _ServiceCard(
                              component: components[i + 1],
                              isBusy: state
                                  .isBusyComponent(components[i + 1].id),
                              isSubmitting: (action) => state.isSubmitting(
                                  components[i + 1].id, action),
                              onAction: onAction,
                            ),
                          )
                        else
                          const Expanded(child: SizedBox.shrink()),
                      ],
                    ),
                  ),
                );
              }
              return Column(children: rows);
            },
          ),
        ],
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({
    required this.component,
    required this.isBusy,
    required this.isSubmitting,
    required this.onAction,
  });

  final SuperadminServerComponent component;
  final bool isBusy;
  final bool Function(String action) isSubmitting;
  final Future<void> Function(
      {required String componentId, required String action}) onAction;

  @override
  Widget build(BuildContext context) {
    final statusVisuals = _statusVisualsForComponent(component.status);

    return Container(
      padding: const EdgeInsets.all(OpenVtsSpacing.md),
      decoration: BoxDecoration(
        color: OpenVtsColors.white,
        borderRadius: BorderRadius.circular(OpenVtsRadius.lg),
        border: Border.all(color: OpenVtsColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: OpenVtsSpacing.xs,
            runSpacing: OpenVtsSpacing.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                component.name,
                style: OpenVtsTypography.titleSmall.copyWith(
                  color: OpenVtsColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              _ServiceStatusPill(
                label: component.status.label,
                dotColor: statusVisuals.color,
                backgroundColor: statusVisuals.background,
              ),
            ],
          ),
          const SizedBox(height: OpenVtsSpacing.xxs),
          Text(
            component.description,
            style: OpenVtsTypography.body.copyWith(
              color: OpenVtsColors.textSecondary,
            ),
          ),
          const SizedBox(height: OpenVtsSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _ServiceMetaColumn(
                  label: 'PID',
                  value: component.pidText,
                ),
              ),
              const SizedBox(width: OpenVtsSpacing.md),
              Expanded(
                child: _ServiceMetaColumn(
                  label: 'Uptime',
                  value: component.uptimeText,
                ),
              ),
            ],
          ),
          const SizedBox(height: OpenVtsSpacing.sm),
          _ServiceMetaColumn(
            label: 'Ports',
            value: component.portsText,
          ),
          const SizedBox(height: OpenVtsSpacing.sm),
          Text(
            component.statusMessage,
            style: OpenVtsTypography.body.copyWith(
              color: OpenVtsColors.textSecondary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: OpenVtsSpacing.md),
          Wrap(
            spacing: OpenVtsSpacing.xs,
            runSpacing: OpenVtsSpacing.xs,
            children: component.availableActions
                .where((action) => action != 'stop')
                .map(
                  (action) => _CompactOutlineButton(
                    label: serverActionLabel(action),
                    icon: _iconForAction(action),
                    isLoading: isSubmitting(action),
                    onPressed: isBusy && !isSubmitting(action)
                        ? null
                        : () => onAction(
                              componentId: component.id,
                              action: action,
                            ),
                  ),
                )
                .toList(growable: false),
          ),
        ],
      ),
    );
  }
}

class _ServiceMetaColumn extends StatelessWidget {
  const _ServiceMetaColumn({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label:',
          style: OpenVtsTypography.meta.copyWith(
            color: OpenVtsColors.textSecondary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: OpenVtsTypography.body.copyWith(
            color: OpenVtsColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _CompactOutlineButton extends StatelessWidget {
  const _CompactOutlineButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.isLoading = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: isLoading ? null : onPressed,
      icon: isLoading
          ? const SizedBox(
              height: 14,
              width: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(icon, size: 16),
      label: Text(
        label,
        style: OpenVtsTypography.label.copyWith(
          color: OpenVtsColors.textPrimary,
        ),
      ),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 38),
        padding: const EdgeInsets.symmetric(
          horizontal: OpenVtsSpacing.sm,
          vertical: OpenVtsSpacing.xs,
        ),
        backgroundColor: OpenVtsColors.white,
        foregroundColor: OpenVtsColors.textPrimary,
        side: const BorderSide(color: OpenVtsColors.border),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(OpenVtsRadius.md),
        ),
      ),
    );
  }
}

class _HeaderStatusPill extends StatelessWidget {
  const _HeaderStatusPill({
    required this.label,
    required this.isOnline,
  });

  final String label;
  final bool isOnline;

  @override
  Widget build(BuildContext context) {
    return _ServiceStatusPill(
      label: label,
      dotColor: isOnline ? OpenVtsColors.success : const Color(0xFFD7A82D),
      backgroundColor: isOnline
          ? OpenVtsColors.success.withValues(alpha: 0.10)
          : const Color(0xFFFFF4D6),
    );
  }
}

class _ServiceStatusPill extends StatelessWidget {
  const _ServiceStatusPill({
    required this.label,
    required this.dotColor,
    required this.backgroundColor,
  });

  final String label;
  final Color dotColor;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: OpenVtsSpacing.sm,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(OpenVtsRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: OpenVtsTypography.meta.copyWith(
              color: OpenVtsColors.textPrimary,
              fontWeight: FontWeight.w600,
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
    return OpenVtsCard(
      padding: const EdgeInsets.all(OpenVtsSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: Icon(
              Icons.info_outline_rounded,
              size: 18,
              color: OpenVtsColors.error,
            ),
          ),
          const SizedBox(width: OpenVtsSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: OpenVtsTypography.body.copyWith(
                color: OpenVtsColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: OpenVtsSpacing.sm),
          TextButton(
            onPressed: onRetry,
            child: Text(
              'Retry',
              style: OpenVtsTypography.label.copyWith(
                color: OpenVtsColors.brandInk,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Skeleton / shimmer loading primitives
// ---------------------------------------------------------------------------

class _SkeletonBlock extends StatelessWidget {
  const _SkeletonBlock({this.width, required this.height});

  final double? width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return _ShimmerWrap(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: OpenVtsColors.surface,
          borderRadius: BorderRadius.circular(OpenVtsRadius.sm),
        ),
      ),
    );
  }
}

class _SkeletonLine extends StatelessWidget {
  const _SkeletonLine({this.widthFactor = 1.0, required this.height});

  final double widthFactor;
  final double height;

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      alignment: AlignmentDirectional.centerStart,
      widthFactor: widthFactor,
      child: _ShimmerWrap(
        child: Container(
          height: height,
          decoration: BoxDecoration(
            color: OpenVtsColors.surface,
            borderRadius: BorderRadius.circular(OpenVtsRadius.sm),
          ),
        ),
      ),
    );
  }
}

class _ShimmerWrap extends StatefulWidget {
  const _ShimmerWrap({required this.child});

  final Widget child;

  @override
  State<_ShimmerWrap> createState() => _ShimmerWrapState();
}

class _ShimmerWrapState extends State<_ShimmerWrap>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: const [
                Color(0xFFE7E3EA),
                Color(0xFFF4F3F6),
                Color(0xFFE7E3EA),
              ],
              stops: [
                (_controller.value - 0.3).clamp(0.0, 1.0),
                _controller.value,
                (_controller.value + 0.3).clamp(0.0, 1.0),
              ],
            ).createShader(bounds);
          },
          blendMode: BlendMode.srcATop,
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class _ServicesSkeleton extends StatelessWidget {
  const _ServicesSkeleton();

  @override
  Widget build(BuildContext context) {
    return OpenVtsCard(
      padding: const EdgeInsets.all(OpenVtsSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SkeletonBlock(width: 100, height: 18),
          const SizedBox(height: OpenVtsSpacing.xxs),
          const _SkeletonBlock(width: 240, height: 14),
          const SizedBox(height: OpenVtsSpacing.md),
          for (int i = 0; i < 4; i++) ...[
            Container(
              padding: const EdgeInsets.all(OpenVtsSpacing.md),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(OpenVtsRadius.lg),
                border: Border.all(color: OpenVtsColors.border),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _SkeletonBlock(width: 100, height: 18),
                      SizedBox(width: OpenVtsSpacing.xs),
                      _SkeletonBlock(width: 64, height: 24),
                    ],
                  ),
                  SizedBox(height: OpenVtsSpacing.xs),
                  _SkeletonBlock(width: 200, height: 14),
                  SizedBox(height: OpenVtsSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: _SkeletonBlock(height: 32),
                      ),
                      SizedBox(width: OpenVtsSpacing.md),
                      Expanded(
                        child: _SkeletonBlock(height: 32),
                      ),
                    ],
                  ),
                  SizedBox(height: OpenVtsSpacing.sm),
                  _SkeletonBlock(width: 140, height: 14),
                  SizedBox(height: OpenVtsSpacing.md),
                  _SkeletonBlock(width: 80, height: 36),
                ],
              ),
            ),
            if (i < 3) const SizedBox(height: OpenVtsSpacing.sm),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Status visuals
// ---------------------------------------------------------------------------

class _StatusVisuals {
  const _StatusVisuals({
    required this.color,
    required this.background,
  });

  final Color color;
  final Color background;
}

_StatusVisuals _statusVisualsForComponent(
  SuperadminServerComponentStatus status,
) {
  switch (status) {
    case SuperadminServerComponentStatus.running:
      return _StatusVisuals(
        color: OpenVtsColors.success,
        background: OpenVtsColors.success.withValues(alpha: 0.10),
      );
    case SuperadminServerComponentStatus.stopped:
    case SuperadminServerComponentStatus.offline:
      return _StatusVisuals(
        color: OpenVtsColors.error,
        background: OpenVtsColors.error.withValues(alpha: 0.10),
      );
    case SuperadminServerComponentStatus.degraded:
      return _StatusVisuals(
        color: OpenVtsColors.warning,
        background: OpenVtsColors.warning.withValues(alpha: 0.10),
      );
    case SuperadminServerComponentStatus.unknown:
      return const _StatusVisuals(
        color: OpenVtsColors.textSecondary,
        background: OpenVtsColors.surface,
      );
  }
}

_StatusVisuals _statusVisualsForJob(SuperadminServerJobStatus status) {
  switch (status) {
    case SuperadminServerJobStatus.queued:
      return _StatusVisuals(
        color: OpenVtsColors.info,
        background: OpenVtsColors.info.withValues(alpha: 0.10),
      );
    case SuperadminServerJobStatus.running:
      return _StatusVisuals(
        color: OpenVtsColors.warning,
        background: OpenVtsColors.warning.withValues(alpha: 0.10),
      );
    case SuperadminServerJobStatus.success:
      return _StatusVisuals(
        color: OpenVtsColors.success,
        background: OpenVtsColors.success.withValues(alpha: 0.10),
      );
    case SuperadminServerJobStatus.failed:
      return _StatusVisuals(
        color: OpenVtsColors.error,
        background: OpenVtsColors.error.withValues(alpha: 0.10),
      );
    case SuperadminServerJobStatus.unknown:
      return const _StatusVisuals(
        color: OpenVtsColors.textSecondary,
        background: OpenVtsColors.surface,
      );
  }
}

IconData _iconForAction(String action) {
  switch (action) {
    case 'start':
      return Icons.bolt_rounded;
    case 'reload':
      return Icons.sync_rounded;
    case 'restart':
    default:
      return Icons.refresh_rounded;
  }
}

String _formatPercent(double? value) {
  if (value == null) return '—';
  return '${value.clamp(0, 100).round()}%';
}

String _formatCapacitySummary(
  double? percent,
  double? usedGb,
  double? totalGb,
) {
  final parts = <String>[];
  if (percent != null) {
    parts.add('${percent.clamp(0, 100).round()}%');
  }
  final capacityText = _formatCapacityPair(usedGb, totalGb);
  if (capacityText != null) {
    parts.add(capacityText);
  }
  return parts.isEmpty ? '—' : parts.join(' • ');
}

String _formatDiskSummary(
  String label,
  double? percent,
  double? usedGb,
  double? totalGb,
) {
  final parts = <String>[];
  if (label.trim().isNotEmpty) {
    parts.add(label.trim());
  }
  if (percent != null) {
    parts.add('${percent.clamp(0, 100).round()}%');
  }
  final capacityText = _formatCapacityPair(usedGb, totalGb);
  if (capacityText != null) {
    parts.add(capacityText);
  }
  return parts.isEmpty ? '—' : parts.join(' • ');
}

double _progressValue(double? percent) {
  if (percent == null) return 0;
  return (percent / 100).clamp(0.0, 1.0);
}

String? _formatCapacityPair(double? usedGb, double? totalGb) {
  if (usedGb == null && totalGb == null) return null;

  if (usedGb != null && totalGb != null) {
    final clampedUsed = usedGb.clamp(0.0, totalGb > 0 ? totalGb : usedGb);
    return '${_formatStorageSize(clampedUsed)} / ${_formatStorageSize(totalGb)}';
  }

  if (usedGb != null) return '${_formatStorageSize(usedGb)} used';
  return '${_formatStorageSize(totalGb!)} total';
}

String _formatStorageSize(double gb) {
  if (gb >= 1024) return '${(gb / 1024).toStringAsFixed(1)} TB';
  if (gb >= 1) return '${gb.toStringAsFixed(1)} GB';
  if (gb >= 1 / 1024) return '${(gb * 1024).toStringAsFixed(0)} MB';
  return '${(gb * 1024 * 1024).toStringAsFixed(0)} KB';
}
