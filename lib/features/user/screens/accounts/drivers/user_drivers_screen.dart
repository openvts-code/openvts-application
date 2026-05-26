import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/open_vts_colors.dart';
import '../../../../../core/theme/open_vts_radius.dart';
import '../../../../../core/theme/open_vts_spacing.dart';
import '../../../../../core/theme/open_vts_typography.dart';
import '../../../../../shared/helpers/toast_helper.dart';
import '../../../../../shared/widgets/open_vts_button.dart';
import '../../../../../shared/widgets/open_vts_card.dart';
import '../../../../../shared/widgets/open_vts_empty_state.dart';
import '../../../../../shared/widgets/open_vts_error_view.dart';
import '../../../../../shared/widgets/open_vts_loader.dart';
import '../../../../../shared/widgets/open_vts_page_scaffold.dart';
import '../../../controllers/user_drivers_controller.dart';
import '../../../controllers/user_providers.dart';
import '../../../models/user_driver_model.dart';
import '../../../models/user_drivers_state.dart';
import 'widgets/user_driver_card.dart';
import 'widgets/user_driver_create_sheet.dart';
import 'widgets/user_drivers_filter_bar.dart';
import 'widgets/user_drivers_summary_strip.dart';

class UserDriversScreen extends ConsumerWidget {
  const UserDriversScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(userDriversControllerProvider);
    final controller = ref.read(userDriversControllerProvider.notifier);

    return OpenVtsPageScaffold(
      title: 'Drivers',
      headerMode: OpenVtsPageHeaderMode.closeable,
      padding: const EdgeInsets.fromLTRB(
        OpenVtsSpacing.sm,
        OpenVtsSpacing.xs,
        OpenVtsSpacing.sm,
        0,
      ),
      body: _buildBody(context, ref, state, controller),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    UserDriversState state,
    UserDriversController controller,
  ) {
    if (state.isLoading && state.drivers.isEmpty) {
      return const OpenVtsLoader();
    }

    if (state.errorMessage != null && state.drivers.isEmpty) {
      return OpenVtsErrorView(
        message: state.errorMessage!,
        onRetry: controller.load,
      );
    }

    return RefreshIndicator(
      onRefresh: controller.refresh,
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 920),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              _DriversHeaderCard(
                state: state,
                onCreate: () => _openCreateDriverSheet(context, ref),
                onRefresh: state.isRefreshing ? null : controller.refresh,
              ),
              const SizedBox(height: OpenVtsSpacing.sm),
              UserDriversSummaryStrip(state: state),
              const SizedBox(height: OpenVtsSpacing.sm),
              UserDriversFilterBar(
                state: state,
                onSearchChanged: controller.setSearchQuery,
                onStatusChanged: controller.setStatusFilter,
                onAssignmentChanged: controller.setAssignmentFilter,
                onVerificationChanged: controller.setVerificationFilter,
                onClearFilters: controller.clearFilters,
              ),
              if (state.errorMessage != null) ...[
                const SizedBox(height: OpenVtsSpacing.sm),
                _InlineErrorBanner(message: state.errorMessage!),
              ],
              const SizedBox(height: OpenVtsSpacing.sm),
              if (state.filteredDrivers.isEmpty)
                _EmptyDriversState(
                  hasDrivers: state.hasDrivers,
                  hasActiveFilters: state.hasActiveFilters,
                  onCreate: () => _openCreateDriverSheet(context, ref),
                  onClearFilters: controller.clearFilters,
                )
              else
                for (final driver in state.filteredDrivers) ...[
                  UserDriverCard(driver: driver),
                  if (driver != state.filteredDrivers.last)
                    const SizedBox(height: OpenVtsSpacing.sm),
                ],
              const SizedBox(height: OpenVtsSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openCreateDriverSheet(
      BuildContext context, WidgetRef ref) async {
    final controller = ref.read(userDriversControllerProvider.notifier);

    final created = await showModalBottomSheet<UserDriver>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (_) => UserDriverCreateSheet(
        onSubmit: controller.createDriver,
      ),
    );

    if (!context.mounted || created == null) {
      return;
    }

    ToastHelper.showSuccess('Driver created.', context: context);
  }
}

class _DriversHeaderCard extends StatelessWidget {
  const _DriversHeaderCard({
    required this.state,
    required this.onCreate,
    required this.onRefresh,
  });

  final UserDriversState state;
  final VoidCallback onCreate;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    return OpenVtsCard(
      padding: const EdgeInsets.all(OpenVtsSpacing.sm),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compactActions = constraints.maxWidth < 540;
          final titleBlock = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Drivers',
                style: OpenVtsTypography.label.copyWith(
                  color: OpenVtsColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: OpenVtsSpacing.xxs),
              Text(
                'Manage drivers, assignments, documents, and activity.',
                style: OpenVtsTypography.meta.copyWith(
                  color: OpenVtsColors.textSecondary,
                ),
              ),
            ],
          );

          final actions = Wrap(
            spacing: OpenVtsSpacing.xs,
            runSpacing: OpenVtsSpacing.xs,
            children: [
              SizedBox(
                height: 34,
                child: OpenVtsButton(
                  label: 'Refresh',
                  height: 34,
                  variant: OpenVtsButtonVariant.secondary,
                  trailingIcon: Icons.refresh_rounded,
                  onPressed: onRefresh,
                  isLoading: state.isRefreshing,
                ),
              ),
              SizedBox(
                height: 34,
                child: OpenVtsButton(
                  label: 'Create Driver',
                  height: 34,
                  trailingIcon: Icons.person_add_alt_1_rounded,
                  onPressed: state.isCreating ? null : onCreate,
                ),
              ),
            ],
          );

          if (compactActions) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                titleBlock,
                const SizedBox(height: OpenVtsSpacing.sm),
                actions,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: titleBlock),
              const SizedBox(width: OpenVtsSpacing.sm),
              actions,
            ],
          );
        },
      ),
    );
  }
}

class _InlineErrorBanner extends StatelessWidget {
  const _InlineErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(OpenVtsSpacing.sm),
      decoration: BoxDecoration(
        color: OpenVtsColors.error.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(OpenVtsRadius.sm),
        border: Border.all(color: OpenVtsColors.error.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 16,
            color: OpenVtsColors.error,
          ),
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

class _EmptyDriversState extends StatelessWidget {
  const _EmptyDriversState({
    required this.hasDrivers,
    required this.hasActiveFilters,
    required this.onCreate,
    required this.onClearFilters,
  });

  final bool hasDrivers;
  final bool hasActiveFilters;
  final VoidCallback onCreate;
  final VoidCallback onClearFilters;

  @override
  Widget build(BuildContext context) {
    if (!hasDrivers) {
      return OpenVtsCard(
        child: Column(
          children: [
            const OpenVtsEmptyState(
              title: 'No drivers',
              message: 'Create your first driver to start assignments.',
            ),
            const SizedBox(height: OpenVtsSpacing.sm),
            OpenVtsButton(
              label: 'Create Driver',
              trailingIcon: Icons.person_add_alt_1_rounded,
              onPressed: onCreate,
            ),
          ],
        ),
      );
    }

    if (hasActiveFilters) {
      return OpenVtsCard(
        child: Column(
          children: [
            const OpenVtsEmptyState(
              title: 'No matching drivers',
              message: 'Try adjusting the current filters or search query.',
            ),
            const SizedBox(height: OpenVtsSpacing.sm),
            OpenVtsButton(
              label: 'Clear Filters',
              variant: OpenVtsButtonVariant.secondary,
              trailingIcon: Icons.filter_alt_off_outlined,
              onPressed: onClearFilters,
            ),
          ],
        ),
      );
    }

    return const OpenVtsEmptyState(
      title: 'No drivers available',
      message: 'Pull to refresh or add a new driver.',
    );
  }
}
