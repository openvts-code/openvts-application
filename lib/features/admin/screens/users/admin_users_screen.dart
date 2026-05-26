import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/open_vts_colors.dart';
import '../../../../core/theme/open_vts_radius.dart';
import '../../../../core/theme/open_vts_spacing.dart';
import '../../../../core/theme/open_vts_typography.dart';
import '../../../../shared/helpers/toast_helper.dart';
import '../../../../shared/widgets/open_vts_bottom_sheet.dart';
import '../../../../shared/widgets/open_vts_button.dart';
import '../../../../shared/widgets/open_vts_empty_state.dart';
import '../../../../shared/widgets/open_vts_error_view.dart';
import '../../../../shared/widgets/open_vts_loader.dart';
import '../../../../shared/widgets/open_vts_page_scaffold.dart';
import '../../controllers/admin_providers.dart';
import '../../controllers/admin_users_controller.dart';
import '../../models/admin_users_model.dart';
import '../../models/admin_users_state.dart';
import 'widgets/admin_edit_user_sheet.dart';
import 'widgets/admin_user_card.dart';
import 'widgets/admin_user_delete_sheet.dart';
import 'widgets/admin_user_password_sheet.dart';

const List<int> _recordsPerPageOptions = <int>[10, 25, 50, 100];

class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      final usersState = ref.read(adminUsersControllerProvider);
      if (!usersState.isLoading &&
          !usersState.isRefreshing &&
          !usersState.hasUsers &&
          usersState.errorMessage == null) {
        ref.read(adminUsersControllerProvider.notifier).load();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminUsersControllerProvider);
    final controller = ref.read(adminUsersControllerProvider.notifier);

    return OpenVtsPageScaffold(
      title: 'Users',
      headerMode: OpenVtsPageHeaderMode.closeable,
      actions: [
        IconButton(
          tooltip: 'Refresh users',
          onPressed: controller.refresh,
          icon: state.isRefreshing
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2.2),
                )
              : const Icon(Icons.refresh_rounded, size: 20),
        ),
      ],
      padding: const EdgeInsetsDirectional.fromSTEB(
        OpenVtsSpacing.sm,
        OpenVtsSpacing.sm,
        OpenVtsSpacing.sm,
        OpenVtsSpacing.sm,
      ),
      body: state.isLoading && !state.hasUsers
          ? const OpenVtsLoader()
          : state.errorMessage != null && !state.hasUsers
              ? OpenVtsErrorView(
                  message:
                      state.errorMessage ?? 'Users could not be loaded.',
                  onRetry: controller.refresh,
                )
              : _UsersBody(
                  state: state,
                  controller: controller,
                  onCreate: _openCreateUser,
                  onOpenFilters: () => _openFiltersSheet(context, ref),
                  onOpenSort: () => _openSortSheet(context, ref),
                  onOpenDetails: _openUserDetails,
                  onStatusChanged: _updateUserStatus,
                  onActionSelected: _handleUserAction,
                ),
    );
  }

  Future<void> _openFiltersSheet(BuildContext context, WidgetRef ref) async {
    final controller = ref.read(adminUsersControllerProvider.notifier);
    final state = ref.read(adminUsersControllerProvider);

    var selectedStatus = state.statusFilter;
    var selectedVerified = state.verifiedFilter;
    var selectedCountry = state.countryFilter;
    final countryCodes = _countryCodes(state.users);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(OpenVtsRadius.xl),
        ),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return _OptionsSheet(
              title: 'Filter users',
              sections: [
                _OptionsSheetSection(
                  label: 'Status',
                  child: Wrap(
                    spacing: OpenVtsSpacing.xs,
                    runSpacing: OpenVtsSpacing.xs,
                    children: AdminUserStatusFilter.values
                        .map(
                          (option) => _ChoiceChip(
                            label: option.label,
                            selected: selectedStatus == option,
                            onSelected: () =>
                                setSheetState(() => selectedStatus = option),
                          ),
                        )
                        .toList(growable: false),
                  ),
                ),
                _OptionsSheetSection(
                  label: 'Email verification',
                  child: Wrap(
                    spacing: OpenVtsSpacing.xs,
                    runSpacing: OpenVtsSpacing.xs,
                    children: AdminUserVerifiedFilter.values
                        .map(
                          (option) => _ChoiceChip(
                            label: option.label,
                            selected: selectedVerified == option,
                            onSelected: () =>
                                setSheetState(() => selectedVerified = option),
                          ),
                        )
                        .toList(growable: false),
                  ),
                ),
                _OptionsSheetSection(
                  label: 'Country',
                  child: Wrap(
                    spacing: OpenVtsSpacing.xs,
                    runSpacing: OpenVtsSpacing.xs,
                    children: [
                      _ChoiceChip(
                        label: 'All Countries',
                        selected: selectedCountry == null,
                        onSelected: () =>
                            setSheetState(() => selectedCountry = null),
                      ),
                      for (final country in countryCodes)
                        _ChoiceChip(
                          label: country,
                          selected: selectedCountry == country,
                          onSelected: () =>
                              setSheetState(() => selectedCountry = country),
                        ),
                    ],
                  ),
                ),
              ],
              primaryActionLabel: 'Apply filters',
              onPrimaryAction: () {
                controller.setStatusFilter(selectedStatus);
                controller.setVerifiedFilter(selectedVerified);
                controller.setCountryFilter(selectedCountry);
                Navigator.of(sheetContext).pop();
              },
              secondaryActionLabel: 'Reset',
              onSecondaryAction: () {
                setSheetState(() {
                  selectedStatus = AdminUserStatusFilter.all;
                  selectedVerified = AdminUserVerifiedFilter.all;
                  selectedCountry = null;
                });
              },
            );
          },
        );
      },
    );
  }

  Future<void> _openSortSheet(BuildContext context, WidgetRef ref) async {
    final controller = ref.read(adminUsersControllerProvider.notifier);
    final state = ref.read(adminUsersControllerProvider);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(OpenVtsRadius.xl),
        ),
      ),
      builder: (sheetContext) {
        return _OptionsSheet(
          title: 'Sort users',
          sections: [
            _OptionsSheetSection(
              label: 'Order by',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: AdminUsersSortOption.values
                    .map(
                      (option) => _RadioRow(
                        label: option.label,
                        selected: state.sortOption == option,
                        onTap: () {
                          controller.setSortOption(option);
                          Navigator.of(sheetContext).pop();
                        },
                      ),
                    )
                    .toList(growable: false),
              ),
            ),
          ],
        );
      },
    );
  }

  void _openCreateUser() {
    context.push(RoutePaths.adminUserCreate);
  }

  Future<void> _showEditUserSheet(AdminUserListItem user) {
    return OpenVtsBottomSheet.show<void>(
      context: context,
      title: 'Edit User',
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.96,
      child: Consumer(
        builder: (context, ref, child) {
          final usersState = ref.watch(adminUsersControllerProvider);
          return AdminEditUserSheet(
            user: user,
            isSubmitting: usersState.isUpdating(user.id),
            onSubmit: (request) async {
              await ref
                  .read(adminUsersControllerProvider.notifier)
                  .updateUser(user.id, request);
              if (!context.mounted) {
                return;
              }
              ToastHelper.showSuccess('User updated.', context: context);
            },
          );
        },
      ),
    );
  }

  Future<void> _showPasswordSheet(AdminUserListItem user) {
    return OpenVtsBottomSheet.show<void>(
      context: context,
      title: 'Change Password',
      initialChildSize: 0.46,
      minChildSize: 0.38,
      maxChildSize: 0.72,
      child: Consumer(
        builder: (context, ref, child) {
          final usersState = ref.watch(adminUsersControllerProvider);
          return AdminUserPasswordSheet(
            user: user,
            isSubmitting: usersState.isUpdating(user.id),
            errorMessage: usersState.errorMessage,
            onSubmit: (newPassword) async {
              await ref
                  .read(adminUsersControllerProvider.notifier)
                  .updateUserPassword(user.id, newPassword);
              if (!context.mounted) {
                return;
              }
              ToastHelper.showSuccess('Password updated.', context: context);
            },
          );
        },
      ),
    );
  }

  Future<void> _showDeleteUserSheet(AdminUserListItem user) {
    return OpenVtsBottomSheet.show<void>(
      context: context,
      title: 'Delete user',
      initialChildSize: 0.34,
      minChildSize: 0.3,
      maxChildSize: 0.5,
      child: Consumer(
        builder: (context, ref, child) {
          final usersState = ref.watch(adminUsersControllerProvider);
          return AdminUserDeleteSheet(
            user: user,
            isDeleting: usersState.isDeleting(user.id),
            errorMessage: usersState.errorMessage,
            onConfirm: () async {
              await ref
                  .read(adminUsersControllerProvider.notifier)
                  .deleteUser(user.id);
              if (!context.mounted) {
                return;
              }
              ToastHelper.showSuccess('User deleted.', context: context);
            },
          );
        },
      ),
    );
  }

  void _openUserDetails(AdminUserListItem user) {
    context.push(RoutePaths.adminUserDetailsPath(user.id), extra: user);
  }

  Future<void> _updateUserStatus(AdminUserListItem user, bool isActive) async {
    try {
      await ref
          .read(adminUsersControllerProvider.notifier)
          .updateUserStatus(user.id, isActive);
      if (!mounted) {
        return;
      }
      ToastHelper.showSuccess(
        isActive ? 'User activated.' : 'User deactivated.',
        context: context,
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      ToastHelper.showError(
        ref.read(adminUsersControllerProvider).errorMessage ??
            'Unable to update user status.',
        context: context,
      );
    }
  }

  Future<void> _loginAsUser(AdminUserListItem user) async {
    try {
      await ref
          .read(adminUsersControllerProvider.notifier)
          .loginAsUser(user.id);
      if (!mounted) {
        return;
      }
      final name = user.name.trim().isNotEmpty
          ? user.name
          : (user.username.trim().isNotEmpty ? user.username : 'user');
      ToastHelper.showSuccess(
        'Signed in as $name.',
        context: context,
      );
      context.go(RoutePaths.userDashboard);
    } catch (_) {
      if (!mounted) {
        return;
      }
      ToastHelper.showError(
        ref.read(adminUsersControllerProvider).errorMessage ??
            'Unable to login as user.',
        context: context,
      );
    }
  }

  void _handleUserAction(AdminUserCardAction action, AdminUserListItem user) {
    switch (action) {
      case AdminUserCardAction.viewDetails:
        _openUserDetails(user);
      case AdminUserCardAction.editUser:
        _showEditUserSheet(user);
      case AdminUserCardAction.changePassword:
        _showPasswordSheet(user);
      case AdminUserCardAction.loginAsUser:
        _loginAsUser(user);
      case AdminUserCardAction.delete:
        _showDeleteUserSheet(user);
    }
  }

  List<String> _countryCodes(List<AdminUserListItem> users) {
    final codes = <String>{
      for (final user in users)
        if (user.countryCode.trim().isNotEmpty)
          user.countryCode.trim().toUpperCase(),
    }.toList()
      ..sort();
    return codes;
  }
}

// ---------------------------------------------------------------------------
// Body
// ---------------------------------------------------------------------------

class _UsersBody extends StatelessWidget {
  const _UsersBody({
    required this.state,
    required this.controller,
    required this.onCreate,
    required this.onOpenFilters,
    required this.onOpenSort,
    required this.onOpenDetails,
    required this.onStatusChanged,
    required this.onActionSelected,
  });

  final AdminUsersState state;
  final AdminUsersController controller;
  final VoidCallback onCreate;
  final VoidCallback onOpenFilters;
  final VoidCallback onOpenSort;
  final void Function(AdminUserListItem) onOpenDetails;
  final void Function(AdminUserListItem, bool) onStatusChanged;
  final void Function(AdminUserCardAction, AdminUserListItem) onActionSelected;

  @override
  Widget build(BuildContext context) {
    final filteredCount = state.filteredCount;
    final visible = state.visibleUsers;
    final hasActiveFilters = state.hasActiveFilters;

    return Column(
      children: [
        _UsersHeaderCard(count: filteredCount, onCreate: onCreate),
        const SizedBox(height: OpenVtsSpacing.sm),
        _UsersToolbar(
          searchQuery: state.searchQuery,
          recordsPerPage: state.recordsPerPage,
          hasActiveFilters: hasActiveFilters,
          onSearchChanged: controller.setSearchQuery,
          onOpenFilters: onOpenFilters,
          onOpenSort: onOpenSort,
          onRecordsChanged: controller.setRecordsPerPage,
        ),
        const SizedBox(height: OpenVtsSpacing.sm),
        Expanded(
          child: RefreshIndicator(
            onRefresh: controller.refresh,
            child: filteredCount == 0
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [
                      SizedBox(height: OpenVtsSpacing.section),
                      OpenVtsEmptyState(
                        title: 'No users found',
                        message: 'Try a different search or filter.',
                      ),
                    ],
                  )
                : ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: visible.length + 1,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: OpenVtsSpacing.sm),
                    itemBuilder: (context, index) {
                      if (index == visible.length) {
                        return _PaginationFooter(
                          currentPage: state.safeCurrentPage,
                          pageCount: state.pageCount,
                          showingCount: visible.length,
                          totalCount: filteredCount,
                          onPrev: () =>
                              controller.goToPage(state.safeCurrentPage - 1),
                          onNext: () =>
                              controller.goToPage(state.safeCurrentPage + 1),
                        );
                      }

                      final user = visible[index];
                      return AdminUserCard(
                        user: user,
                        isUpdating: state.isUpdating(user.id),
                        isDeleting: state.isDeleting(user.id),
                        isLoggingIn: state.isLoggingIn(user.id),
                        onTap: () => onOpenDetails(user),
                        onStatusChanged: (value) =>
                            onStatusChanged(user, value),
                        onActionSelected: (action) =>
                            onActionSelected(action, user),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Header card (count + create button)
// ---------------------------------------------------------------------------

class _UsersHeaderCard extends StatelessWidget {
  const _UsersHeaderCard({
    required this.count,
    required this.onCreate,
  });

  final int count;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return _RoundedSurface(
      padding: const EdgeInsets.fromLTRB(
        OpenVtsSpacing.md,
        OpenVtsSpacing.sm,
        OpenVtsSpacing.sm,
        OpenVtsSpacing.sm,
      ),
      child: Row(
        children: [
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: _softSurfaceColor(context),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.people_outline_rounded,
              size: 22,
              color: _primaryInkColor(context),
            ),
          ),
          const SizedBox(width: OpenVtsSpacing.sm),
          Expanded(
            child: Text(
              '$count User${count == 1 ? '' : 's'}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
            ),
          ),
          const SizedBox(width: OpenVtsSpacing.sm),
          _PrimaryCreateButton(onPressed: onCreate),
        ],
      ),
    );
  }
}

class _PrimaryCreateButton extends StatelessWidget {
  const _PrimaryCreateButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background =
        isDark ? OpenVtsColors.surfaceElevated : OpenVtsColors.brandInk;
    final foreground = isDark ? OpenVtsColors.brandInk : OpenVtsColors.white;

    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.add_rounded, size: 18),
      label: const Text('Create User'),
      style: ElevatedButton.styleFrom(
        backgroundColor: background,
        foregroundColor: foreground,
        elevation: 0,
        padding: const EdgeInsets.symmetric(
          horizontal: OpenVtsSpacing.md,
          vertical: OpenVtsSpacing.sm,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(OpenVtsRadius.md),
        ),
        textStyle: OpenVtsTypography.label.copyWith(
          fontWeight: FontWeight.w600,
        ),
        visualDensity: VisualDensity.compact,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Toolbar (search + filter + sort + records-per-page)
// ---------------------------------------------------------------------------

class _UsersToolbar extends StatefulWidget {
  const _UsersToolbar({
    required this.searchQuery,
    required this.recordsPerPage,
    required this.hasActiveFilters,
    required this.onSearchChanged,
    required this.onOpenFilters,
    required this.onOpenSort,
    required this.onRecordsChanged,
  });

  final String searchQuery;
  final int recordsPerPage;
  final bool hasActiveFilters;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onOpenFilters;
  final VoidCallback onOpenSort;
  final ValueChanged<int> onRecordsChanged;

  @override
  State<_UsersToolbar> createState() => _UsersToolbarState();
}

class _UsersToolbarState extends State<_UsersToolbar> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.searchQuery);
  }

  @override
  void didUpdateWidget(covariant _UsersToolbar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.searchQuery != _searchController.text) {
      _searchController.value = TextEditingValue(
        text: widget.searchQuery,
        selection: TextSelection.collapsed(offset: widget.searchQuery.length),
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _RoundedSurface(
      padding: const EdgeInsets.all(OpenVtsSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: _SearchInput(
              controller: _searchController,
              onChanged: widget.onSearchChanged,
            ),
          ),
          const SizedBox(width: OpenVtsSpacing.xs),
          _SquareIconButton(
            icon: Icons.filter_alt_outlined,
            tooltip: 'Filter users',
            onPressed: widget.onOpenFilters,
            showDot: widget.hasActiveFilters,
          ),
          const SizedBox(width: OpenVtsSpacing.xs),
          _SquareIconButton(
            icon: Icons.swap_vert_rounded,
            tooltip: 'Sort users',
            onPressed: widget.onOpenSort,
          ),
          const SizedBox(width: OpenVtsSpacing.xs),
          _RecordsPerPageDropdown(
            value: widget.recordsPerPage,
            onChanged: widget.onRecordsChanged,
          ),
        ],
      ),
    );
  }
}

class _SearchInput extends StatelessWidget {
  const _SearchInput({
    required this.controller,
    required this.onChanged,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  static const double _height = 40;

  static const TextStyle _baseStyle = TextStyle(
    fontFamily: OpenVtsTypography.primaryFontFamily,
    fontFamilyFallback: OpenVtsTypography.fontFallback,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.2,
    leadingDistribution: TextLeadingDistribution.even,
  );

  @override
  Widget build(BuildContext context) {
    final fillColor = _softSurfaceColor(context);
    final borderColor = _softBorderColor(context);

    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(OpenVtsRadius.md),
      borderSide: BorderSide(color: borderColor),
    );
    final focusedBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(OpenVtsRadius.md),
      borderSide: BorderSide(color: _primaryInkColor(context), width: 1.2),
    );

    return SizedBox(
      height: _height,
      child: ValueListenableBuilder<TextEditingValue>(
        valueListenable: controller,
        builder: (context, value, _) {
          final hasText = value.text.isNotEmpty;
          return TextField(
            controller: controller,
            onChanged: onChanged,
            textAlignVertical: TextAlignVertical.center,
            cursorColor: _primaryInkColor(context),
            cursorWidth: 1.4,
            style: _baseStyle.copyWith(color: OpenVtsColors.textPrimary),
            strutStyle: const StrutStyle(
              fontFamily: OpenVtsTypography.primaryFontFamily,
              fontFamilyFallback: OpenVtsTypography.fontFallback,
              fontSize: 14,
              height: 1.2,
              leading: 0,
              forceStrutHeight: true,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: fillColor,
              isDense: true,
              isCollapsed: false,
              hintText: 'Search by name, email\u2026',
              hintStyle: _baseStyle.copyWith(
                color: OpenVtsColors.textTertiary,
                fontWeight: FontWeight.w400,
              ),
              prefixIcon: const Padding(
                padding: EdgeInsetsDirectional.only(
                  start: OpenVtsSpacing.sm,
                  end: OpenVtsSpacing.xs,
                ),
                child: Icon(
                  Icons.search_rounded,
                  size: 18,
                  color: OpenVtsColors.textSecondary,
                ),
              ),
              prefixIconConstraints: const BoxConstraints(
                minWidth: 0,
                minHeight: _height,
              ),
              suffixIcon: !hasText
                  ? null
                  : Padding(
                      padding: const EdgeInsetsDirectional.only(
                        end: OpenVtsSpacing.xxs,
                      ),
                      child: IconButton(
                        tooltip: 'Clear search',
                        onPressed: () {
                          controller.clear();
                          onChanged('');
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 28,
                          minHeight: 28,
                        ),
                        splashRadius: 16,
                        icon: const Icon(
                          Icons.close_rounded,
                          size: 16,
                          color: OpenVtsColors.textSecondary,
                        ),
                      ),
                    ),
              suffixIconConstraints: const BoxConstraints(
                minWidth: 0,
                minHeight: _height,
              ),
              contentPadding: const EdgeInsetsDirectional.only(
                end: OpenVtsSpacing.sm,
              ),
              border: border,
              enabledBorder: border,
              focusedBorder: focusedBorder,
            ),
          );
        },
      ),
    );
  }
}

class _SquareIconButton extends StatelessWidget {
  const _SquareIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.showDot = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final bool showDot;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: _softSurfaceColor(context),
        borderRadius: BorderRadius.circular(OpenVtsRadius.md),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(OpenVtsRadius.md),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(OpenVtsRadius.md),
                  border: Border.all(color: _softBorderColor(context)),
                ),
                alignment: Alignment.center,
                child: Icon(
                  icon,
                  size: 18,
                  color: _primaryInkColor(context),
                ),
              ),
              if (showDot)
                PositionedDirectional(
                  top: -2,
                  end: -2,
                  child: Container(
                    height: 10,
                    width: 10,
                    decoration: BoxDecoration(
                      color: OpenVtsColors.brandInk,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Theme.of(context).colorScheme.surface,
                        width: 2,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecordsPerPageDropdown extends StatelessWidget {
  const _RecordsPerPageDropdown({
    required this.value,
    required this.onChanged,
  });

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final options = <int>[
      ..._recordsPerPageOptions,
      if (!_recordsPerPageOptions.contains(value)) value,
    ]..sort();

    return Container(
      height: 40,
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: OpenVtsSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: _softSurfaceColor(context),
        borderRadius: BorderRadius.circular(OpenVtsRadius.md),
        border: Border.all(color: _softBorderColor(context)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: value,
          isDense: true,
          icon: const Padding(
            padding: EdgeInsetsDirectional.only(start: 2),
            child: Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 16,
              color: OpenVtsColors.textSecondary,
            ),
          ),
          style: OpenVtsTypography.label.copyWith(
            color: _primaryInkColor(context),
            fontWeight: FontWeight.w600,
          ),
          dropdownColor: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(OpenVtsRadius.md),
          items: options
              .map(
                (option) => DropdownMenuItem<int>(
                  value: option,
                  child: Text('$option'),
                ),
              )
              .toList(growable: false),
          onChanged: (next) {
            if (next != null) {
              onChanged(next);
            }
          },
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Pagination footer
// ---------------------------------------------------------------------------

class _PaginationFooter extends StatelessWidget {
  const _PaginationFooter({
    required this.currentPage,
    required this.pageCount,
    required this.showingCount,
    required this.totalCount,
    required this.onPrev,
    required this.onNext,
  });

  final int currentPage;
  final int pageCount;
  final int showingCount;
  final int totalCount;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final canPrev = currentPage > 1;
    final canNext = currentPage < pageCount;

    return Padding(
      padding: const EdgeInsets.only(top: OpenVtsSpacing.xs),
      child: Column(
        children: [
          Text(
            'Showing $showingCount of $totalCount',
            style: OpenVtsTypography.meta.copyWith(
              color: OpenVtsColors.textSecondary,
            ),
          ),
          if (pageCount > 1) ...[
            const SizedBox(height: OpenVtsSpacing.xs),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _PageButton(
                  icon: Icons.chevron_left_rounded,
                  onPressed: canPrev ? onPrev : null,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: OpenVtsSpacing.sm,
                  ),
                  child: Text(
                    'Page $currentPage of $pageCount',
                    style: OpenVtsTypography.label.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                _PageButton(
                  icon: Icons.chevron_right_rounded,
                  onPressed: canNext ? onNext : null,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _PageButton extends StatelessWidget {
  const _PageButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Material(
      color: enabled
          ? _softSurfaceColor(context)
          : _softSurfaceColor(context).withValues(alpha: 0.6),
      borderRadius: BorderRadius.circular(OpenVtsRadius.md),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(OpenVtsRadius.md),
        child: Container(
          height: 36,
          width: 36,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(OpenVtsRadius.md),
            border: Border.all(color: _softBorderColor(context)),
          ),
          alignment: Alignment.center,
          child: Icon(
            icon,
            size: 18,
            color: enabled
                ? _primaryInkColor(context)
                : OpenVtsColors.textTertiary,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Options sheet (Filter / Sort)
// ---------------------------------------------------------------------------

class _OptionsSheet extends StatelessWidget {
  const _OptionsSheet({
    required this.title,
    required this.sections,
    this.primaryActionLabel,
    this.onPrimaryAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
  });

  final String title;
  final List<_OptionsSheetSection> sections;
  final String? primaryActionLabel;
  final VoidCallback? onPrimaryAction;
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          OpenVtsSpacing.md,
          OpenVtsSpacing.sm,
          OpenVtsSpacing.md,
          OpenVtsSpacing.lg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                height: 4,
                width: 40,
                margin: const EdgeInsets.only(bottom: OpenVtsSpacing.sm),
                decoration: BoxDecoration(
                  color: OpenVtsColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.close_rounded, size: 20),
                  tooltip: 'Close',
                ),
              ],
            ),
            const SizedBox(height: OpenVtsSpacing.sm),
            for (final section in sections) ...[
              Text(
                section.label,
                style: OpenVtsTypography.label.copyWith(
                  color: OpenVtsColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: OpenVtsSpacing.xs),
              section.child,
              const SizedBox(height: OpenVtsSpacing.md),
            ],
            if (primaryActionLabel != null ||
                secondaryActionLabel != null) ...[
              const SizedBox(height: OpenVtsSpacing.xs),
              Row(
                children: [
                  if (secondaryActionLabel != null) ...[
                    Expanded(
                      child: OpenVtsButton(
                        label: secondaryActionLabel!,
                        variant: OpenVtsButtonVariant.secondary,
                        onPressed: onSecondaryAction,
                      ),
                    ),
                    const SizedBox(width: OpenVtsSpacing.sm),
                  ],
                  if (primaryActionLabel != null)
                    Expanded(
                      child: OpenVtsButton(
                        label: primaryActionLabel!,
                        onPressed: onPrimaryAction,
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _OptionsSheetSection {
  const _OptionsSheetSection({required this.label, required this.child});

  final String label;
  final Widget child;
}

class _ChoiceChip extends StatelessWidget {
  const _ChoiceChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final background =
        selected ? _primaryInkColor(context) : _softSurfaceColor(context);
    final foreground = selected
        ? Theme.of(context).colorScheme.surface
        : _primaryInkColor(context);

    return Material(
      color: background,
      borderRadius: BorderRadius.circular(OpenVtsRadius.pill),
      child: InkWell(
        onTap: onSelected,
        borderRadius: BorderRadius.circular(OpenVtsRadius.pill),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: OpenVtsSpacing.md,
            vertical: OpenVtsSpacing.xs,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(OpenVtsRadius.pill),
            border: Border.all(
              color: selected
                  ? _primaryInkColor(context)
                  : _softBorderColor(context),
            ),
          ),
          child: Text(
            label,
            style: OpenVtsTypography.label.copyWith(
              color: foreground,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _RadioRow extends StatelessWidget {
  const _RadioRow({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(OpenVtsRadius.md),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: OpenVtsSpacing.xs,
          vertical: OpenVtsSpacing.sm,
        ),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              size: 18,
              color: selected
                  ? _primaryInkColor(context)
                  : OpenVtsColors.textTertiary,
            ),
            const SizedBox(width: OpenVtsSpacing.sm),
            Expanded(
              child: Text(
                label,
                style: OpenVtsTypography.label.copyWith(
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: _primaryInkColor(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared surface
// ---------------------------------------------------------------------------

class _RoundedSurface extends StatelessWidget {
  const _RoundedSurface({
    required this.child,
    this.padding = const EdgeInsets.all(OpenVtsSpacing.md),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(OpenVtsRadius.lg),
        border: Border.all(color: _softBorderColor(context)),
      ),
      child: child,
    );
  }
}

// ---------------------------------------------------------------------------
// Theme helpers
// ---------------------------------------------------------------------------

Color _softSurfaceColor(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark
      ? OpenVtsColors.darkSurface
      : OpenVtsColors.background;
}

Color _softBorderColor(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark
      ? OpenVtsColors.darkBorder
      : OpenVtsColors.border;
}

Color _primaryInkColor(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark
      ? OpenVtsColors.darkTextPrimary
      : OpenVtsColors.brandInk;
}
