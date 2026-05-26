import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/open_vts_colors.dart';
import '../../../../core/theme/open_vts_spacing.dart';
import '../../../../core/theme/open_vts_typography.dart';
import '../../../../shared/widgets/open_vts_bottom_sheet.dart';
import '../../../../shared/widgets/open_vts_card.dart';
import '../../../../shared/widgets/open_vts_empty_state.dart';
import '../../../../shared/widgets/open_vts_error_view.dart';
import '../../../../shared/widgets/open_vts_loader.dart';
import '../../../../shared/widgets/open_vts_page_scaffold.dart';
import '../../../../shared/widgets/open_vts_search_field.dart';
import '../../controllers/admin_plans_controller.dart';
import '../../controllers/admin_providers.dart';
import '../../models/admin_plans_model.dart';
import '../../models/admin_plans_state.dart';
import 'widgets/admin_plan_card.dart';
import 'widgets/admin_plan_form_sheet.dart';

class AdminPlansScreen extends ConsumerWidget {
  const AdminPlansScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(adminPlansControllerProvider);
    final controller = ref.read(adminPlansControllerProvider.notifier);

    return OpenVtsPageScaffold(
      title: 'Plans',
      headerMode: OpenVtsPageHeaderMode.closeable,
      padding: EdgeInsets.zero,
      body: RefreshIndicator(
        onRefresh: controller.refresh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                OpenVtsSpacing.sm,
                OpenVtsSpacing.sm,
                OpenVtsSpacing.sm,
                0,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _PlansHeaderCard(
                    isSubmitting: state.isCreating || state.isUpdating,
                    onAddPressed: () => _showCreatePlanSheet(context),
                  ),
                  const SizedBox(height: OpenVtsSpacing.sm),
                  _CountText(
                    filteredCount: state.filteredPlans.length,
                    totalCount: state.plans.length,
                  ),
                  const SizedBox(height: OpenVtsSpacing.xs),
                  OpenVtsSearchField(
                    hintText: 'Search plans, currency, duration, price...',
                    onChanged: controller.setSearchQuery,
                  ),
                  const SizedBox(height: OpenVtsSpacing.sm),
                ]),
              ),
            ),
            _buildContentSliver(context, state, controller),
            const SliverToBoxAdapter(
              child: SizedBox(height: OpenVtsSpacing.lg),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentSliver(
    BuildContext context,
    AdminPlansState state,
    AdminPlansController controller,
  ) {
    if (state.isLoading && !state.hasPlans) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: OpenVtsLoader(),
      );
    }

    final errorMessage = state.errorMessage;
    if (errorMessage != null && !state.hasPlans) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: OpenVtsErrorView(
          message: errorMessage,
          onRetry: controller.load,
        ),
      );
    }

    if (state.filteredPlans.isEmpty) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: OpenVtsEmptyState(
          title: 'No plans found',
          message: 'Add a new plan or change your search.',
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: OpenVtsSpacing.sm),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          if (index.isOdd) {
            return const SizedBox(height: OpenVtsSpacing.sm);
          }
          final planIndex = index ~/ 2;
          final plan = state.filteredPlans[planIndex];
          return AdminPlanCard(
            plan: plan,
            onEdit: () => _showEditPlanSheet(context, plan),
          );
        }, childCount: state.filteredPlans.length * 2 - 1),
      ),
    );
  }

  Future<void> _showCreatePlanSheet(BuildContext context) {
    return OpenVtsBottomSheet.show<void>(
      context: context,
      title: 'Add Plan',
      initialChildSize: 0.82,
      minChildSize: 0.45,
      maxChildSize: 0.96,
      child: const AdminPlanFormSheet.create(),
    );
  }

  Future<void> _showEditPlanSheet(BuildContext context, AdminPlan plan) {
    return OpenVtsBottomSheet.show<void>(
      context: context,
      title: 'Edit Plan',
      initialChildSize: 0.82,
      minChildSize: 0.45,
      maxChildSize: 0.96,
      child: AdminPlanFormSheet.edit(initialPlan: plan),
    );
  }
}

class _PlansHeaderCard extends StatelessWidget {
  const _PlansHeaderCard({
    required this.onAddPressed,
    required this.isSubmitting,
  });

  final VoidCallback onAddPressed;
  final bool isSubmitting;

  @override
  Widget build(BuildContext context) {
    return OpenVtsCard(
      padding: const EdgeInsets.all(OpenVtsSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Plans',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: OpenVtsTypography.titleSmall.copyWith(
                    color: OpenVtsColors.textPrimary,
                  ),
                ),
                const SizedBox(height: OpenVtsSpacing.xxs),
                Text(
                  'Manage subscription pricing plans.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: OpenVtsTypography.meta.copyWith(
                    color: OpenVtsColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: OpenVtsSpacing.sm),
          SizedBox(
            width: 122,
            child: FilledButton.icon(
              onPressed: isSubmitting ? null : onAddPressed,
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text('Add Plan'),
            ),
          ),
        ],
      ),
    );
  }
}

class _CountText extends StatelessWidget {
  const _CountText({required this.filteredCount, required this.totalCount});

  final int filteredCount;
  final int totalCount;

  @override
  Widget build(BuildContext context) {
    return Text(
      '$filteredCount of $totalCount plans',
      style: OpenVtsTypography.meta.copyWith(
        color: OpenVtsColors.textSecondary,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
