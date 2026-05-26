import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/router/route_paths.dart';
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
import '../../../controllers/user_providers.dart';
import '../../../controllers/user_subusers_controller.dart';
import '../../../models/user_subuser_model.dart';
import '../../../models/user_subusers_state.dart';
import 'widgets/user_subuser_card.dart';
import 'widgets/user_subuser_create_sheet.dart';
import 'widgets/user_subusers_filter_bar.dart';
import 'widgets/user_subusers_summary_strip.dart';

class UserSubUsersScreen extends ConsumerStatefulWidget {
  const UserSubUsersScreen({super.key});

  @override
  ConsumerState<UserSubUsersScreen> createState() => _UserSubUsersScreenState();
}

class _UserSubUsersScreenState extends ConsumerState<UserSubUsersScreen> {
  UserSubUsersStatusFilter _statusFilter = UserSubUsersStatusFilter.all;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(userSubUsersControllerProvider);
    final controller = ref.read(userSubUsersControllerProvider.notifier);

    final visibleSubUsers = _applyLocalFilters(state.subUsers, _statusFilter);

    return OpenVtsPageScaffold(
      title: 'Sub Users',
      headerMode: OpenVtsPageHeaderMode.closeable,
      padding: const EdgeInsets.fromLTRB(
        OpenVtsSpacing.sm,
        OpenVtsSpacing.xs,
        OpenVtsSpacing.sm,
        0,
      ),
      body: _buildBody(
        context,
        state,
        controller,
        visibleSubUsers,
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    UserSubUsersState state,
    UserSubUsersController controller,
    List<UserSubUser> visibleSubUsers,
  ) {
    if (state.isLoading && state.subUsers.isEmpty) {
      return const OpenVtsLoader();
    }

    if (state.errorMessage != null && state.subUsers.isEmpty) {
      return OpenVtsErrorView(
        message: state.errorMessage!,
        onRetry: controller.loadSubUsers,
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
              _SubUsersHeaderCard(
                state: state,
                onCreate: () => _openCreateSheet(context),
                onRefresh: state.isRefreshing ? null : controller.refresh,
              ),
              const SizedBox(height: OpenVtsSpacing.sm),
              UserSubUsersSummaryStrip(
                totalLoaded: state.subUsers.length,
                totalRemote: state.total,
                activeCount: state.activeCount,
                inactiveCount: state.inactiveCount,
              ),
              const SizedBox(height: OpenVtsSpacing.sm),
              UserSubUsersFilterBar(
                searchQuery: state.searchQuery,
                visibleCount: visibleSubUsers.length,
                loadedCount: state.subUsers.length,
                totalCount: state.total,
                selectedStatusFilter: _statusFilter,
                onSearchChanged: controller.setSearchQuery,
                onStatusChanged: (value) {
                  setState(() => _statusFilter = value);
                },
                onClearFilters: () => _clearFilters(controller),
              ),
              if (state.errorMessage != null) ...[
                const SizedBox(height: OpenVtsSpacing.sm),
                _InlineErrorBanner(message: state.errorMessage!),
              ],
              const SizedBox(height: OpenVtsSpacing.sm),
              if (visibleSubUsers.isEmpty)
                _EmptySubUsersState(
                  hasSubUsers: state.hasSubUsers,
                  hasSearchQuery: state.searchQuery.trim().isNotEmpty,
                  hasStatusFilter:
                      _statusFilter != UserSubUsersStatusFilter.all,
                  onCreate: () => _openCreateSheet(context),
                  onClearSearch: () => _clearFilters(controller),
                )
              else
                for (var index = 0;
                    index < visibleSubUsers.length;
                    index++) ...[
                  UserSubUserCard(
                    subUser: visibleSubUsers[index],
                    isTogglingStatus:
                        state.togglingIds.contains(visibleSubUsers[index].id),
                    onTap: () => _openSubUserDetails(visibleSubUsers[index]),
                    onToggleStatus: (_) => _toggleStatus(
                        context, controller, visibleSubUsers[index]),
                  ),
                  if (index < visibleSubUsers.length - 1)
                    const SizedBox(height: OpenVtsSpacing.sm),
                ],
              const SizedBox(height: OpenVtsSpacing.md),
              _LoadMoreSection(
                hasMore: state.hasMore,
                isLoadingMore: state.isLoadingMore,
                onLoadMore: controller.loadMore,
              ),
              const SizedBox(height: OpenVtsSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }

  List<UserSubUser> _applyLocalFilters(
    List<UserSubUser> source,
    UserSubUsersStatusFilter statusFilter,
  ) {
    return source.where((item) {
      return switch (statusFilter) {
        UserSubUsersStatusFilter.all => true,
        UserSubUsersStatusFilter.active => item.isActive,
        UserSubUsersStatusFilter.inactive => !item.isActive,
      };
    }).toList(growable: false);
  }

  Future<void> _openCreateSheet(BuildContext context) async {
    final controller = ref.read(userSubUsersControllerProvider.notifier);

    final created = await showModalBottomSheet<UserSubUser>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (_) => UserSubUserCreateSheet(
        onSubmit: controller.createSubUser,
      ),
    );

    if (created == null || !context.mounted) {
      return;
    }

    ToastHelper.showSuccess('Sub user created.', context: context);

    final subUserId = created.id.trim();
    if (subUserId.isEmpty) {
      return;
    }

    context.push(RoutePaths.userSubUserDetailsPath(subUserId), extra: created);
  }

  Future<void> _toggleStatus(
    BuildContext context,
    UserSubUsersController controller,
    UserSubUser item,
  ) async {
    final success = await controller.toggleStatus(item.id);
    if (success || !context.mounted) {
      return;
    }

    final message = ref.read(userSubUsersControllerProvider).errorMessage ??
        'Status update failed.';
    ToastHelper.showError(message, context: context);
  }

  void _openSubUserDetails(UserSubUser item) {
    final subUserId = item.id.trim();
    if (subUserId.isEmpty) {
      return;
    }

    context.push(RoutePaths.userSubUserDetailsPath(subUserId), extra: item);
  }

  void _clearFilters(UserSubUsersController controller) {
    if (_statusFilter != UserSubUsersStatusFilter.all) {
      setState(() => _statusFilter = UserSubUsersStatusFilter.all);
    }

    final state = ref.read(userSubUsersControllerProvider);
    if (state.searchQuery.isNotEmpty) {
      controller.setSearchQuery('');
    }
  }
}

class _SubUsersHeaderCard extends StatelessWidget {
  const _SubUsersHeaderCard({
    required this.state,
    required this.onCreate,
    required this.onRefresh,
  });

  final UserSubUsersState state;
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
                'Sub Users',
                style: OpenVtsTypography.label.copyWith(
                  color: OpenVtsColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: OpenVtsSpacing.xxs),
              Text(
                'Manage sub users and vehicle access.',
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
                  label: 'Create Sub User',
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

class _EmptySubUsersState extends StatelessWidget {
  const _EmptySubUsersState({
    required this.hasSubUsers,
    required this.hasSearchQuery,
    required this.hasStatusFilter,
    required this.onCreate,
    required this.onClearSearch,
  });

  final bool hasSubUsers;
  final bool hasSearchQuery;
  final bool hasStatusFilter;
  final VoidCallback onCreate;
  final VoidCallback onClearSearch;

  @override
  Widget build(BuildContext context) {
    if (!hasSubUsers) {
      return OpenVtsCard(
        child: Column(
          children: [
            const OpenVtsEmptyState(
              title: 'No sub users',
              message: 'Create your first sub user to share selected access.',
            ),
            const SizedBox(height: OpenVtsSpacing.sm),
            OpenVtsButton(
              label: 'Create Sub User',
              trailingIcon: Icons.person_add_alt_1_rounded,
              onPressed: onCreate,
            ),
          ],
        ),
      );
    }

    if (hasSearchQuery || hasStatusFilter) {
      return OpenVtsCard(
        child: Column(
          children: [
            const OpenVtsEmptyState(
              title: 'No matching sub users',
              message: 'Try clearing search or status filters.',
            ),
            const SizedBox(height: OpenVtsSpacing.sm),
            OpenVtsButton(
              label: hasSearchQuery && !hasStatusFilter
                  ? 'Clear Search'
                  : 'Clear Filters',
              variant: OpenVtsButtonVariant.secondary,
              trailingIcon: Icons.filter_alt_off_outlined,
              onPressed: onClearSearch,
            ),
          ],
        ),
      );
    }

    return const OpenVtsEmptyState(
      title: 'No sub users available',
      message: 'Pull to refresh or create a new sub user.',
    );
  }
}

class _LoadMoreSection extends StatelessWidget {
  const _LoadMoreSection({
    required this.hasMore,
    required this.isLoadingMore,
    required this.onLoadMore,
  });

  final bool hasMore;
  final bool isLoadingMore;
  final VoidCallback onLoadMore;

  @override
  Widget build(BuildContext context) {
    if (!hasMore && !isLoadingMore) {
      return const SizedBox.shrink();
    }

    if (isLoadingMore) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: OpenVtsSpacing.sm),
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    return Center(
      child: OpenVtsButton(
        label: 'Load More',
        height: 36,
        variant: OpenVtsButtonVariant.secondary,
        trailingIcon: Icons.expand_more_rounded,
        onPressed: onLoadMore,
      ),
    );
  }
}
