import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/router/route_paths.dart';
import '../../../../../core/theme/open_vts_colors.dart';
import '../../../../../core/theme/open_vts_radius.dart';
import '../../../../../core/theme/open_vts_spacing.dart';
import '../../../../../core/theme/open_vts_typography.dart';
import '../../../../../shared/helpers/toast_helper.dart';
import '../../../../../shared/widgets/open_vts_bottom_sheet.dart';
import '../../../../../shared/widgets/open_vts_button.dart';
import '../../../../../shared/widgets/open_vts_card.dart';
import '../../../../../shared/widgets/open_vts_error_view.dart';
import '../../../../../shared/widgets/open_vts_loader.dart';
import '../../../../../shared/widgets/open_vts_page_scaffold.dart';
import '../../../controllers/user_providers.dart';
import '../../../controllers/user_subuser_details_controller.dart';
import '../../../models/user_subuser_model.dart';
import '../../../models/user_subusers_state.dart';
import 'widgets/user_subuser_delete_sheet.dart';
import 'widgets/user_subuser_profile_tab.dart';
import 'widgets/user_subuser_vehicles_tab.dart';

enum _UserSubUserDetailsTab { profile, vehicles, delete }

typedef UserSubUserDetailsProvider = AutoDisposeStateNotifierProvider<
    UserSubUserDetailsController, UserSubUserDetailsState>;

class UserSubUserDetailsScreen extends ConsumerStatefulWidget {
  const UserSubUserDetailsScreen({
    super.key,
    required this.subUserId,
    this.initialSubUser,
  });

  final String subUserId;
  final UserSubUser? initialSubUser;

  @override
  ConsumerState<UserSubUserDetailsScreen> createState() =>
      _UserSubUserDetailsScreenState();
}

class _UserSubUserDetailsScreenState
    extends ConsumerState<UserSubUserDetailsScreen> {
  var _selectedTab = _UserSubUserDetailsTab.profile;

  @override
  Widget build(BuildContext context) {
    final provider = userSubUserDetailsControllerProvider(
      UserSubUserDetailsProviderArgs(
        subUserId: widget.subUserId,
        initialSubUser: widget.initialSubUser,
      ),
    );
    final state = ref.watch(provider);
    final controller = ref.read(provider.notifier);
    final subUser = state.subUser ?? widget.initialSubUser;

    return OpenVtsPageScaffold(
      title: _subUserTitle(subUser),
      padding: EdgeInsets.zero,
      leading: IconButton(
        tooltip: 'Back',
        onPressed: () => _close(context),
        icon: const Icon(Icons.arrow_back_rounded, size: 20),
      ),
      actions: [
        _HeaderIconButton(
          tooltip: 'Refresh',
          onPressed: _isRefreshingCurrentTab(state)
              ? null
              : () => _refreshCurrentTab(provider),
          icon: _isRefreshingCurrentTab(state)
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.refresh_rounded, size: 18),
        ),
        const SizedBox(width: OpenVtsSpacing.xs),
      ],
      body: _buildBody(context, provider, state, controller, subUser),
    );
  }

  Widget _buildBody(
    BuildContext context,
    UserSubUserDetailsProvider provider,
    UserSubUserDetailsState state,
    UserSubUserDetailsController controller,
    UserSubUser? subUser,
  ) {
    if (state.isLoading && subUser == null) {
      return const OpenVtsLoader();
    }

    if (state.errorMessage != null && subUser == null) {
      return OpenVtsErrorView(
        message: state.errorMessage!,
        onRetry: controller.loadInitial,
      );
    }

    return RefreshIndicator(
      onRefresh: () => _refreshCurrentTab(provider),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(OpenVtsSpacing.sm),
        children: [
          _SubUserSummaryCard(
            subUser: subUser,
            assignedCount: state.assignedVehicles.length,
          ),
          if (state.errorMessage != null) ...[
            const SizedBox(height: OpenVtsSpacing.sm),
            _InlineError(message: state.errorMessage!),
          ],
          const SizedBox(height: OpenVtsSpacing.sm),
          _TabChips(
            selectedTab: _selectedTab,
            onSelect: (tab) => setState(() => _selectedTab = tab),
          ),
          const SizedBox(height: OpenVtsSpacing.sm),
          _TabContent(provider: provider, selectedTab: _selectedTab),
          const SizedBox(height: OpenVtsSpacing.lg),
        ],
      ),
    );
  }

  Future<void> _refreshCurrentTab(UserSubUserDetailsProvider provider) async {
    final controller = ref.read(provider.notifier);
    switch (_selectedTab) {
      case _UserSubUserDetailsTab.profile:
        await controller.refresh();
        break;
      case _UserSubUserDetailsTab.vehicles:
        await controller.loadVehicles();
        break;
      case _UserSubUserDetailsTab.delete:
        await controller.refresh();
        break;
    }
  }

  bool _isRefreshingCurrentTab(UserSubUserDetailsState state) {
    switch (_selectedTab) {
      case _UserSubUserDetailsTab.profile:
        return state.isLoading || state.isSaving || state.isTogglingStatus;
      case _UserSubUserDetailsTab.vehicles:
        return state.isLoadingVehicles ||
            state.isAssigningVehicles ||
            state.isUnassigningVehicles;
      case _UserSubUserDetailsTab.delete:
        return state.isDeleting || state.isLoading;
    }
  }

  void _close(BuildContext context) {
    if (context.canPop()) {
      context.pop();
      return;
    }

    context.go(RoutePaths.userSubUsers);
  }
}

class _TabContent extends StatelessWidget {
  const _TabContent({
    required this.provider,
    required this.selectedTab,
  });

  final UserSubUserDetailsProvider provider;
  final _UserSubUserDetailsTab selectedTab;

  @override
  Widget build(BuildContext context) {
    return switch (selectedTab) {
      _UserSubUserDetailsTab.profile =>
        UserSubUserProfileTab(provider: provider),
      _UserSubUserDetailsTab.vehicles =>
        UserSubUserVehiclesTab(provider: provider),
      _UserSubUserDetailsTab.delete => _DeleteTab(provider: provider),
    };
  }
}

class _SubUserSummaryCard extends StatelessWidget {
  const _SubUserSummaryCard({
    required this.subUser,
    required this.assignedCount,
  });

  final UserSubUser? subUser;
  final int assignedCount;

  @override
  Widget build(BuildContext context) {
    final isActive = subUser?.isActive ?? false;

    return OpenVtsCard(
      padding: const EdgeInsets.all(OpenVtsSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: OpenVtsColors.textPrimary.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(OpenVtsRadius.sm),
                  border: Border.all(color: OpenVtsColors.border),
                ),
                child: const Icon(
                  Icons.person_outline_rounded,
                  size: 20,
                  color: OpenVtsColors.textSecondary,
                ),
              ),
              const SizedBox(width: OpenVtsSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _subUserTitle(subUser),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          OpenVtsTypography.titleSmall.copyWith(fontSize: 16),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _usernameLabel(subUser),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: OpenVtsTypography.meta.copyWith(
                        color: OpenVtsColors.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: OpenVtsSpacing.sm),
          Wrap(
            spacing: OpenVtsSpacing.xs,
            runSpacing: OpenVtsSpacing.xs,
            children: [
              _StatusPill(
                label: isActive ? 'Active' : 'Inactive',
                color: isActive
                    ? OpenVtsColors.textSecondary
                    : OpenVtsColors.textTertiary,
                icon: isActive
                    ? Icons.check_circle_outline_rounded
                    : Icons.pause_circle_outline_rounded,
              ),
              _StatusPill(
                label: '$assignedCount assigned vehicles',
                color: OpenVtsColors.brandInk,
                icon: Icons.directions_car_outlined,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TabChips extends StatelessWidget {
  const _TabChips({required this.selectedTab, required this.onSelect});

  final _UserSubUserDetailsTab selectedTab;
  final ValueChanged<_UserSubUserDetailsTab> onSelect;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _UserSubUserDetailsTab.values.map((tab) {
          final isSelected = tab == selectedTab;
          return Padding(
            padding: const EdgeInsets.only(right: OpenVtsSpacing.xs),
            child: ChoiceChip(
              selected: isSelected,
              label: Text(_tabLabel(tab)),
              onSelected: (_) => onSelect(tab),
              showCheckmark: false,
              labelStyle: OpenVtsTypography.meta.copyWith(
                fontWeight: FontWeight.w800,
                color: isSelected
                    ? OpenVtsColors.white
                    : OpenVtsColors.textPrimary,
              ),
              selectedColor: OpenVtsColors.brandInk,
              backgroundColor: OpenVtsColors.white,
              side: const BorderSide(color: OpenVtsColors.border),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(OpenVtsRadius.pill),
              ),
            ),
          );
        }).toList(growable: false),
      ),
    );
  }
}

class _DeleteTab extends ConsumerWidget {
  const _DeleteTab({required this.provider});

  final UserSubUserDetailsProvider provider;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(provider);
    final subUser = state.subUser;

    return OpenVtsCard(
      padding: const EdgeInsets.all(OpenVtsSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Delete Sub User',
            style: OpenVtsTypography.label.copyWith(
              color: OpenVtsColors.error,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: OpenVtsSpacing.xs),
          Text(
            'Deleting this sub user permanently removes account access and vehicle permissions. This action cannot be reversed.',
            style: OpenVtsTypography.meta.copyWith(
              color: OpenVtsColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: OpenVtsSpacing.sm),
          SizedBox(
            height: 36,
            child: OpenVtsButton(
              label: 'Delete Sub User',
              height: 36,
              trailingIcon: Icons.delete_outline_rounded,
              isLoading: state.isDeleting,
              onPressed: subUser == null || state.isDeleting
                  ? null
                  : () => _showDeleteSheet(context, ref, subUser),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showDeleteSheet(
    BuildContext context,
    WidgetRef ref,
    UserSubUser subUser,
  ) async {
    final deleted = await OpenVtsBottomSheet.show<bool>(
      context: context,
      title: 'Delete Sub User',
      initialChildSize: 0.42,
      minChildSize: 0.34,
      maxChildSize: 0.62,
      child: UserSubUserDeleteSheet(
        provider: provider,
        subUser: subUser,
      ),
    );

    if (deleted != true || !context.mounted) {
      return;
    }

    await ref.read(userSubUsersControllerProvider.notifier).refresh();
    if (!context.mounted) {
      return;
    }

    ToastHelper.showSuccess('Sub user deleted.', context: context);
    context.go(RoutePaths.userSubUsers);
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.label,
    required this.color,
    required this.icon,
  });

  final String label;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 280),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(OpenVtsRadius.pill),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: OpenVtsTypography.meta.copyWith(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message});

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

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.tooltip,
    required this.onPressed,
    required this.icon,
  });

  final String tooltip;
  final VoidCallback? onPressed;
  final Widget icon;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: icon,
      style: IconButton.styleFrom(
        minimumSize: const Size.square(36),
        padding: EdgeInsets.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}

String _tabLabel(_UserSubUserDetailsTab tab) {
  return switch (tab) {
    _UserSubUserDetailsTab.profile => 'Profile',
    _UserSubUserDetailsTab.vehicles => 'Vehicles',
    _UserSubUserDetailsTab.delete => 'Delete',
  };
}

String _subUserTitle(UserSubUser? subUser) {
  if (subUser == null) {
    return 'Sub User';
  }

  for (final value in [subUser.name, subUser.username, subUser.email]) {
    final normalized = value.trim();
    if (normalized.isNotEmpty) {
      return normalized;
    }
  }

  return 'Sub User';
}

String _usernameLabel(UserSubUser? subUser) {
  final username = subUser?.username.trim() ?? '';
  if (username.isEmpty) {
    return 'Username not set';
  }
  return '@$username';
}
