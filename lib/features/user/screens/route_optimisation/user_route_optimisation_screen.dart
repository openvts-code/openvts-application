import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/open_vts_colors.dart';
import '../../../../core/theme/open_vts_radius.dart';
import '../../../../core/theme/open_vts_spacing.dart';
import '../../../../shared/helpers/toast_helper.dart';
import '../../../../shared/widgets/open_vts_page_scaffold.dart';
import '../../controllers/user_providers.dart';
import '../../models/user_route_optimisation_model.dart';
import '../../models/user_route_optimisation_state.dart';
import 'widgets/edit_route_point_sheet.dart';
import 'widgets/route_optimisation_header.dart';
import 'widgets/route_optimisation_map_panel.dart';
import 'widgets/route_optimisation_mobile_tabs.dart';
import 'widgets/route_optimisation_results_panel.dart';
import 'widgets/route_points_panel.dart';

/// Mobile-first Route Optimisation screen.
///
/// Layout:
/// * `< 900px` — stacked layout with a 3-segment pill switching between
///   **Points / Map / Results**.
/// * `>= 900px` — split layout with Points left, Map centre, Results right.
///
/// All business logic lives in `UserRouteOptimisationController` and
/// `UserRouteOptimisationService`. This widget only composes panels, owns
/// the tab state, and surfaces controller toasts via `ToastHelper`.
class UserRouteOptimisationScreen extends ConsumerStatefulWidget {
  const UserRouteOptimisationScreen({super.key});

  @override
  ConsumerState<UserRouteOptimisationScreen> createState() =>
      _UserRouteOptimisationScreenState();
}

class _UserRouteOptimisationScreenState
    extends ConsumerState<UserRouteOptimisationScreen> {
  RouteOptimisationTab _tab = RouteOptimisationTab.points;
  static const double _wideBreakpoint = 900;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref
          .read(userRouteOptimisationControllerProvider.notifier)
          .loadLandmarks();
    });
  }

  void _setTab(RouteOptimisationTab tab) {
    if (_tab == tab) return;
    setState(() => _tab = tab);
  }

  void _showToast(String message, {bool isError = false}) {
    if (isError) {
      ToastHelper.showError(message, context: context);
      return;
    }
    ToastHelper.showSuccess(message, context: context);
  }

  Future<void> _editPointFromMap(
    int index,
    RouteOptimisationPoint point,
  ) async {
    final r = await showEditRoutePointSheet(context, point: point);
    if (r == null || !mounted) return;
    ref.read(userRouteOptimisationControllerProvider.notifier).updatePoint(
          index,
          point.copyWith(name: r.name, lat: r.lat, lon: r.lon),
        );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(userRouteOptimisationControllerProvider);
    final controller =
        ref.read(userRouteOptimisationControllerProvider.notifier);

    ref.listen<UserRouteOptimisationState>(
      userRouteOptimisationControllerProvider,
      (prev, next) {
        if (prev?.result == null && next.result != null) {
          _setTab(RouteOptimisationTab.results);
        }
        if (prev?.clickToAddMode != true && next.clickToAddMode) {
          _setTab(RouteOptimisationTab.map);
        }
        if (next.errorMessage != null &&
            next.errorMessage != prev?.errorMessage) {
          _showToast(next.errorMessage!, isError: true);
          controller.clearError();
        } else if (next.successMessage != null &&
            next.successMessage != prev?.successMessage) {
          _showToast(next.successMessage!);
          controller.clearError();
        }
      },
    );

    return OpenVtsPageScaffold(
      title: 'Route Optimisation',
      headerMode: OpenVtsPageHeaderMode.closeable,
      padding: const EdgeInsets.fromLTRB(
        OpenVtsSpacing.sm,
        OpenVtsSpacing.xs,
        OpenVtsSpacing.sm,
        OpenVtsSpacing.sm,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= _wideBreakpoint;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              RouteOptimisationHeader(state: state),
              const SizedBox(height: OpenVtsSpacing.sm),
              if (!isWide) ...[
                RouteOptimisationMobileTabs(
                  current: _tab,
                  onChanged: _setTab,
                  pointCount: state.points.length,
                  hasResult: state.hasResult,
                ),
                const SizedBox(height: OpenVtsSpacing.sm),
                Expanded(
                  child: _PanelShell(child: _mobileBody()),
                ),
              ] else
                Expanded(child: _wideBody()),
            ],
          );
        },
      ),
    );
  }

  Widget _mobileBody() {
    switch (_tab) {
      case RouteOptimisationTab.points:
        return RoutePointsPanel(
          onTapOnMapRequested: () => _setTab(RouteOptimisationTab.map),
        );
      case RouteOptimisationTab.map:
        return RouteOptimisationMapPanel(onEditPoint: _editPointFromMap);
      case RouteOptimisationTab.results:
        return const RouteOptimisationResultsPanel();
    }
  }

  Widget _wideBody() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: 320,
          child: _PanelShell(
            child: RoutePointsPanel(
              onTapOnMapRequested: () {},
            ),
          ),
        ),
        const SizedBox(width: OpenVtsSpacing.sm),
        Expanded(
          child: _PanelShell(
            child: RouteOptimisationMapPanel(
              onEditPoint: _editPointFromMap,
            ),
          ),
        ),
        const SizedBox(width: OpenVtsSpacing.sm),
        const SizedBox(
          width: 340,
          child: _PanelShell(child: RouteOptimisationResultsPanel()),
        ),
      ],
    );
  }
}

/// Thin bordered container shared by the three panels.
class _PanelShell extends StatelessWidget {
  const _PanelShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: OpenVtsColors.surfaceElevated,
        borderRadius: BorderRadius.circular(OpenVtsRadius.md),
        border: Border.all(color: OpenVtsColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}
