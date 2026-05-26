import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../core/theme/open_vts_colors.dart';
import '../../../../../core/theme/open_vts_radius.dart';
import '../../../../../core/theme/open_vts_spacing.dart';
import '../../../../../core/theme/open_vts_typography.dart';
import '../../../../../shared/helpers/toast_helper.dart';
import '../../../../../shared/widgets/open_vts_empty_state.dart';
import '../../../controllers/user_providers.dart';
import '../../../controllers/user_route_optimisation_controller.dart';
import '../../../models/user_route_optimisation_model.dart';
import 'route_optimisation_metric_strip.dart';
import 'route_optimisation_report_card.dart';
import 'save_optimised_route_sheet.dart';

/// Right-hand "Results" panel for the Route Optimisation screen.
///
/// Stateless from a business perspective: every action button delegates to
/// `userRouteOptimisationControllerProvider`. The screen handles toasts via
/// the existing `errorMessage` / `successMessage` listener.
class RouteOptimisationResultsPanel extends ConsumerWidget {
  const RouteOptimisationResultsPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(userRouteOptimisationControllerProvider);
    final controller =
        ref.read(userRouteOptimisationControllerProvider.notifier);
    final result = state.result;

    if (result == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(
          horizontal: OpenVtsSpacing.lg,
          vertical: OpenVtsSpacing.xl,
        ),
        child: Center(
          child: OpenVtsEmptyState(
            title: 'No optimisation yet',
            message: 'Add at least two points and optimise the route.',
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        OpenVtsSpacing.md,
        OpenVtsSpacing.sm,
        OpenVtsSpacing.md,
        OpenVtsSpacing.lg,
      ),
      children: [
        RouteOptimisationMetricStrip(result: result),
        const SizedBox(height: OpenVtsSpacing.md),
        _OptimisedOrderList(state: state, result: result),
        const SizedBox(height: OpenVtsSpacing.md),
        RouteOptimisationReportCard(report: result.logs),
        const SizedBox(height: OpenVtsSpacing.md),
        _ActionsGrid(
          state: state,
          controller: controller,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Optimised order list
// ---------------------------------------------------------------------------

class _OptimisedOrderList extends StatelessWidget {
  const _OptimisedOrderList({required this.state, required this.result});

  final dynamic state;
  final RouteOptimisationResult result;

  @override
  Widget build(BuildContext context) {
    final order = result.optimizedOrder;
    final points = state.points as List<RouteOptimisationPoint>;
    final roundTrip = state.roundTrip as bool;

    return Container(
      decoration: BoxDecoration(
        color: OpenVtsColors.surface,
        borderRadius: BorderRadius.circular(OpenVtsRadius.md),
        border: Border.all(color: OpenVtsColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              OpenVtsSpacing.sm,
              OpenVtsSpacing.xs,
              OpenVtsSpacing.sm,
              0,
            ),
            child: Row(
              children: [
                Text(
                  'Optimised order',
                  style: OpenVtsTypography.meta.copyWith(
                    color: OpenVtsColors.textSecondary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
                ),
                const Spacer(),
                if (roundTrip)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: OpenVtsColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(OpenVtsRadius.pill),
                      border: Border.all(color: OpenVtsColors.border),
                    ),
                    child: Text(
                      'Round trip',
                      style: OpenVtsTypography.meta.copyWith(
                        color: OpenVtsColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          for (var i = 0; i < order.length; i++)
            _OrderRow(
              displayIndex: i + 1,
              point: points[order[i]],
              isStart: i == 0,
              isEnd: !roundTrip && i == order.length - 1,
              isLast: i == order.length - 1,
            ),
          if (roundTrip && order.isNotEmpty)
            _OrderRow(
              displayIndex: order.length + 1,
              point: points[order.first],
              isStart: false,
              isEnd: true,
              isLast: true,
              returnLeg: true,
            ),
        ],
      ),
    );
  }
}

class _OrderRow extends StatelessWidget {
  const _OrderRow({
    required this.displayIndex,
    required this.point,
    required this.isStart,
    required this.isEnd,
    required this.isLast,
    this.returnLeg = false,
  });

  final int displayIndex;
  final RouteOptimisationPoint point;
  final bool isStart;
  final bool isEnd;
  final bool isLast;
  final bool returnLeg;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        OpenVtsSpacing.sm,
        6,
        OpenVtsSpacing.sm,
        6,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _IndexBadge(index: displayIndex),
          const SizedBox(width: OpenVtsSpacing.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        returnLeg ? '${point.name} (return)' : point.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: OpenVtsTypography.label.copyWith(
                          color: OpenVtsColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (isStart) ...[
                      const SizedBox(width: 6),
                      const _Badge(
                        text: 'Start',
                        color: OpenVtsColors.brandInk,
                      ),
                    ],
                    if (isEnd) ...[
                      const SizedBox(width: 6),
                      const _Badge(
                        text: 'End',
                        color: OpenVtsColors.info,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${point.source.label} · '
                  '${point.lat.toStringAsFixed(5)}, '
                  '${point.lon.toStringAsFixed(5)}',
                  style: OpenVtsTypography.meta.copyWith(
                    color: OpenVtsColors.textTertiary,
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

class _IndexBadge extends StatelessWidget {
  const _IndexBadge({required this.index});
  final int index;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: OpenVtsColors.surfaceElevated,
        borderRadius: BorderRadius.circular(OpenVtsRadius.pill),
        border: Border.all(color: OpenVtsColors.border),
      ),
      child: Text(
        '$index',
        style: OpenVtsTypography.meta.copyWith(
          color: OpenVtsColors.textPrimary,
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text, required this.color});
  final String text;
  final Color color;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(OpenVtsRadius.pill),
      ),
      child: Text(
        text,
        style: OpenVtsTypography.meta.copyWith(
          color: OpenVtsColors.white,
          fontWeight: FontWeight.w700,
          fontSize: 10,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Action grid
// ---------------------------------------------------------------------------

class _ActionsGrid extends StatelessWidget {
  const _ActionsGrid({required this.state, required this.controller});

  final dynamic state;
  final UserRouteOptimisationController controller;

  Future<void> _openInMaps(BuildContext context) async {
    final url = controller.buildGoogleMapsUrl();
    if (url.isEmpty) return;
    final uri = Uri.parse(url);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ToastHelper.showError('Could not open Google Maps.', context: context);
    }
  }

  Future<void> _copyMapsUrl(BuildContext context) async {
    final url = controller.buildGoogleMapsUrl();
    if (url.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: url));
    if (!context.mounted) return;
    ToastHelper.showSuccess('Google Maps link copied.', context: context);
  }

  Future<void> _save(BuildContext context) async {
    await showSaveOptimisedRouteSheet(context);
  }

  @override
  Widget build(BuildContext context) {
    final canShare = controller.buildGoogleMapsUrl().isNotEmpty;
    final isSaving = state.isSavingRoute as bool;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: _ActionButton(
                label: 'Apply order',
                icon: Icons.playlist_add_check_outlined,
                primary: true,
                onPressed: controller.applyOptimisedOrder,
              ),
            ),
            const SizedBox(width: OpenVtsSpacing.xs),
            Expanded(
              child: _ActionButton(
                label: isSaving ? 'Saving…' : 'Save as Route',
                icon: Icons.bookmark_add_outlined,
                primary: true,
                onPressed: isSaving ? null : () => _save(context),
              ),
            ),
          ],
        ),
        const SizedBox(height: OpenVtsSpacing.xs),
        Row(
          children: [
            Expanded(
              child: _ActionButton(
                label: 'Open in Maps',
                icon: Icons.map_outlined,
                onPressed: canShare ? () => _openInMaps(context) : null,
              ),
            ),
            const SizedBox(width: OpenVtsSpacing.xs),
            Expanded(
              child: _ActionButton(
                label: 'Copy Maps URL',
                icon: Icons.link,
                onPressed: canShare ? () => _copyMapsUrl(context) : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: OpenVtsSpacing.xs),
        Row(
          children: [
            Expanded(
              child: _ActionButton(
                label: 'Copy JSON',
                icon: Icons.data_object,
                onPressed: controller.copyJson,
              ),
            ),
            const SizedBox(width: OpenVtsSpacing.xs),
            Expanded(
              child: _ActionButton(
                label: 'Copy report',
                icon: Icons.description_outlined,
                onPressed: controller.copyReport,
              ),
            ),
          ],
        ),
        const SizedBox(height: OpenVtsSpacing.xs),
        _ActionButton(
          label: 'Clear result',
          icon: Icons.close,
          subtle: true,
          onPressed: controller.clearResult,
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.primary = false,
    this.subtle = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool primary;
  final bool subtle;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final Color bg;
    final Color fg;
    final Color border;
    if (primary) {
      bg = enabled ? OpenVtsColors.brandInk : OpenVtsColors.surface;
      fg = enabled ? OpenVtsColors.white : OpenVtsColors.textTertiary;
      border = bg;
    } else if (subtle) {
      bg = Colors.transparent;
      fg = enabled ? OpenVtsColors.textSecondary : OpenVtsColors.textTertiary;
      border = Colors.transparent;
    } else {
      bg = OpenVtsColors.surface;
      fg = enabled ? OpenVtsColors.textPrimary : OpenVtsColors.textTertiary;
      border = OpenVtsColors.border;
    }

    return SizedBox(
      height: 36,
      child: Material(
        color: bg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(OpenVtsRadius.sm),
          side: BorderSide(color: border),
        ),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(OpenVtsRadius.sm),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 15, color: fg),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: OpenVtsTypography.meta.copyWith(
                      color: fg,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
