import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/open_vts_colors.dart';
import '../../../../core/theme/open_vts_radius.dart';
import '../../../../core/theme/open_vts_spacing.dart';
import '../../../../core/theme/open_vts_typography.dart';
import '../../../../core/utils/date_time_formatter.dart';
import '../../../../shared/helpers/toast_helper.dart';
import '../../../../shared/models/user_role.dart';
import '../../../../shared/widgets/open_vts_button.dart';
import '../../../../shared/widgets/open_vts_empty_state.dart';
import '../../../../shared/widgets/open_vts_error_view.dart';
import '../../../../shared/widgets/open_vts_loader.dart';
import '../../../../shared/widgets/open_vts_page_scaffold.dart';
import '../../../auth/controllers/auth_controller.dart';
import '../../../auth/models/current_user.dart';
import '../../../auth/models/login_response.dart';
import '../../controllers/superadmin_administrators_controller.dart';
import '../../controllers/superadmin_providers.dart';
import '../../models/superadmin_administrator_model.dart';
import '../../models/superadmin_administrators_state.dart';

const DateTimeFormatter _administratorsDateFormatter = DateTimeFormatter();
const List<int> _recordsPerPageOptions = <int>[10, 25, 50, 100];

class SuperadminAdministratorsScreen extends ConsumerStatefulWidget {
  const SuperadminAdministratorsScreen({super.key});

  @override
  ConsumerState<SuperadminAdministratorsScreen> createState() =>
      _SuperadminAdministratorsScreenState();
}

class _SuperadminAdministratorsScreenState
    extends ConsumerState<SuperadminAdministratorsScreen> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(superadminAdministratorsControllerProvider);
    final controller = ref.read(
      superadminAdministratorsControllerProvider.notifier,
    );

    return OpenVtsPageScaffold(
      title: 'Administrators',
      headerMode: OpenVtsPageHeaderMode.closeable,
      actions: [
        IconButton(
          tooltip: 'Refresh administrators',
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
      body: state.isInitialLoading && !state.hasItems
          ? const OpenVtsLoader()
          : state.errorMessage != null && !state.hasItems
              ? OpenVtsErrorView(
                  message: state.errorMessage ??
                      'Administrators could not be loaded.',
                  onRetry: controller.refresh,
                )
              : _AdministratorsBody(
                  state: state,
                  controller: controller,
                  onCreate: () => _openCreateAdmin(context),
                  onOpenFilters: () => _openFiltersSheet(context, ref),
                  onOpenSort: () => _openSortSheet(context, ref),
                  onToggleActive: (admin, value) => _handleActiveToggle(
                    context,
                    ref,
                    admin,
                    value,
                  ),
                  onDelete: (admin) => _handleDelete(context, ref, admin),
                  onLogin: (admin) => _handleLogin(context, ref, admin),
                  onOpenDetails: (admin) {
                    context.push(
                      RoutePaths
                          .superadminAdministratorDetailsPath(admin.id),
                      extra: admin,
                    );
                  },
                ),
    );
  }

  void _openCreateAdmin(BuildContext context) {
    context.push(RoutePaths.superadminAdministratorCreate);
  }

  Future<void> _openFiltersSheet(BuildContext context, WidgetRef ref) async {
    final controller =
        ref.read(superadminAdministratorsControllerProvider.notifier);
    final state = ref.read(superadminAdministratorsControllerProvider);

    var selectedRole = state.roleFilter;
    var selectedStatus = state.statusFilter;

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
              title: 'Filter administrators',
              sections: [
                _OptionsSheetSection(
                  label: 'Role',
                  child: Wrap(
                    spacing: OpenVtsSpacing.xs,
                    runSpacing: OpenVtsSpacing.xs,
                    children: SuperadminAdministratorRoleFilter.values
                        .map(
                          (option) => _ChoiceChip(
                            label: option.label,
                            selected: selectedRole == option,
                            onSelected: () =>
                                setSheetState(() => selectedRole = option),
                          ),
                        )
                        .toList(growable: false),
                  ),
                ),
                _OptionsSheetSection(
                  label: 'Status',
                  child: Wrap(
                    spacing: OpenVtsSpacing.xs,
                    runSpacing: OpenVtsSpacing.xs,
                    children: SuperadminAdministratorStatusFilter.values
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
              ],
              primaryActionLabel: 'Apply filters',
              onPrimaryAction: () {
                controller.setRoleFilter(selectedRole);
                controller.setStatusFilter(selectedStatus);
                Navigator.of(sheetContext).pop();
              },
              secondaryActionLabel: 'Reset',
              onSecondaryAction: () {
                setSheetState(() {
                  selectedRole = SuperadminAdministratorRoleFilter.all;
                  selectedStatus = SuperadminAdministratorStatusFilter.all;
                });
              },
            );
          },
        );
      },
    );
  }

  Future<void> _openSortSheet(BuildContext context, WidgetRef ref) async {
    final controller =
        ref.read(superadminAdministratorsControllerProvider.notifier);
    final state = ref.read(superadminAdministratorsControllerProvider);

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
          title: 'Sort administrators',
          sections: [
            _OptionsSheetSection(
              label: 'Order by',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: SuperadminAdministratorSortOption.values
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

  Future<void> _handleActiveToggle(
    BuildContext context,
    WidgetRef ref,
    SuperadminAdministrator administrator,
    bool isActive,
  ) async {
    try {
      await ref
          .read(superadminAdministratorsControllerProvider.notifier)
          .setAdministratorActive(administrator, isActive: isActive);
      if (!context.mounted) {
        return;
      }
      ToastHelper.showSuccess(
        isActive
            ? '${administrator.name} activated.'
            : '${administrator.name} deactivated.',
        context: context,
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      ToastHelper.showError(error.toString(), context: context);
    }
  }

  Future<void> _handleDelete(
    BuildContext context,
    WidgetRef ref,
    SuperadminAdministrator administrator,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete administrator'),
          content: Text(
            'Remove ${administrator.name} from the platform? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => dialogContext.pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => dialogContext.pop(true),
              style: TextButton.styleFrom(
                foregroundColor: OpenVtsColors.error,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      await ref
          .read(superadminAdministratorsControllerProvider.notifier)
          .deleteAdministrator(administrator);
      if (!context.mounted) {
        return;
      }
      ToastHelper.showSuccess(
        '${administrator.name} deleted.',
        context: context,
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      ToastHelper.showError(error.toString(), context: context);
    }
  }

  Future<void> _handleLogin(
    BuildContext context,
    WidgetRef ref,
    SuperadminAdministrator administrator,
  ) async {
    try {
      final outcome = await ref
          .read(superadminAdministratorsControllerProvider.notifier)
          .loginAsAdministrator(administrator);
      if (!context.mounted) {
        return;
      }

      if (outcome.hasSession) {
        final userJson = <String, dynamic>{
          ...?outcome.userJson,
          'role': outcome.userJson?['role'] ?? 'admin',
        };

        final accessToken = outcome.accessToken?.trim();
        if (accessToken == null || accessToken.isEmpty) {
          throw Exception('Admin login did not return an access token.');
        }

        final session = LoginResponse(
          accessToken: accessToken,
          refreshToken: outcome.refreshToken?.trim() ?? '',
          user: CurrentUser.fromJson(userJson).copyWith(role: UserRole.admin),
        );

        await ref.read(authControllerProvider.notifier).setSession(session);
        if (!context.mounted) {
          return;
        }

        ToastHelper.showSuccess(
          'Signed in as ${administrator.name}.',
          context: context,
        );
        context.go(RoutePaths.adminHome);
        return;
      }

      final message = outcome.message?.trim();
      if (message != null && message.isNotEmpty) {
        ToastHelper.showSuccess(message, context: context);
      } else {
        ToastHelper.showInfo(
          'Admin login request completed.',
          context: context,
        );
      }
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      ToastHelper.showError(error.toString(), context: context);
    }
  }
}

// ---------------------------------------------------------------------------
// Body
// ---------------------------------------------------------------------------

class _AdministratorsBody extends StatelessWidget {
  const _AdministratorsBody({
    required this.state,
    required this.controller,
    required this.onCreate,
    required this.onOpenFilters,
    required this.onOpenSort,
    required this.onToggleActive,
    required this.onDelete,
    required this.onLogin,
    required this.onOpenDetails,
  });

  final SuperadminAdministratorsState state;
  final SuperadminAdministratorsController controller;
  final VoidCallback onCreate;
  final VoidCallback onOpenFilters;
  final VoidCallback onOpenSort;
  final void Function(SuperadminAdministrator, bool) onToggleActive;
  final void Function(SuperadminAdministrator) onDelete;
  final void Function(SuperadminAdministrator) onLogin;
  final void Function(SuperadminAdministrator) onOpenDetails;

  @override
  Widget build(BuildContext context) {
    final filteredCount = state.filteredCount;
    final visible = state.visibleAdministrators;
    final hasActiveFilters =
        state.roleFilter != SuperadminAdministratorRoleFilter.all ||
            state.statusFilter != SuperadminAdministratorStatusFilter.all;

    return Column(
      children: [
        _AdministratorsHeaderCard(
          count: filteredCount,
          onCreate: onCreate,
        ),
        const SizedBox(height: OpenVtsSpacing.sm),
        _AdministratorsToolbar(
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
                        title: 'No administrators found',
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

                      final administrator = visible[index];
                      return _AdministratorCard(
                        administrator: administrator,
                        isBusy: state.isToggling(administrator.id) ||
                            state.isDeleting(administrator.id) ||
                            state.isLoggingIn(administrator.id),
                        isToggling: state.isToggling(administrator.id),
                        isDeleting: state.isDeleting(administrator.id),
                        isLoggingIn: state.isLoggingIn(administrator.id),
                        onToggleActive: (value) =>
                            onToggleActive(administrator, value),
                        onDelete: () => onDelete(administrator),
                        onLogin: () => onLogin(administrator),
                        onOpenDetails: () => onOpenDetails(administrator),
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

class _AdministratorsHeaderCard extends StatelessWidget {
  const _AdministratorsHeaderCard({
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
              Icons.groups_2_rounded,
              size: 22,
              color: _primaryInkColor(context),
            ),
          ),
          const SizedBox(width: OpenVtsSpacing.sm),
          Expanded(
            child: Text(
              '$count Administrator${count == 1 ? '' : 's'}',
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
    final foreground =
        isDark ? OpenVtsColors.brandInk : OpenVtsColors.white;

    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.add_rounded, size: 18),
      label: const Text('Create Admin'),
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

class _AdministratorsToolbar extends StatefulWidget {
  const _AdministratorsToolbar({
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
  State<_AdministratorsToolbar> createState() => _AdministratorsToolbarState();
}

class _AdministratorsToolbarState extends State<_AdministratorsToolbar> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.searchQuery);
  }

  @override
  void didUpdateWidget(covariant _AdministratorsToolbar oldWidget) {
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
            tooltip: 'Filter administrators',
            onPressed: widget.onOpenFilters,
            showDot: widget.hasActiveFilters,
          ),
          const SizedBox(width: OpenVtsSpacing.xs),
          _SquareIconButton(
            icon: Icons.swap_vert_rounded,
            tooltip: 'Sort administrators',
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
// Administrator card
// ---------------------------------------------------------------------------

class _AdministratorCard extends StatelessWidget {
  const _AdministratorCard({
    required this.administrator,
    required this.isBusy,
    required this.isToggling,
    required this.isDeleting,
    required this.isLoggingIn,
    required this.onToggleActive,
    required this.onDelete,
    required this.onLogin,
    required this.onOpenDetails,
  });

  final SuperadminAdministrator administrator;
  final bool isBusy;
  final bool isToggling;
  final bool isDeleting;
  final bool isLoggingIn;
  final ValueChanged<bool> onToggleActive;
  final VoidCallback onDelete;
  final VoidCallback onLogin;
  final VoidCallback onOpenDetails;

  @override
  Widget build(BuildContext context) {
    return _RoundedSurface(
      padding: const EdgeInsets.all(OpenVtsSpacing.md),
      onTap: onOpenDetails,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(
            administrator: administrator,
            isBusy: isBusy,
            isToggling: isToggling,
            isLoggingIn: isLoggingIn,
            onToggleActive: onToggleActive,
            onLogin: onLogin,
            onDelete: onDelete,
          ),
          const SizedBox(height: OpenVtsSpacing.md),
          _CardInfoGrid(administrator: administrator),
          const SizedBox(height: OpenVtsSpacing.md),
          _CardMetricsRow(administrator: administrator),
          if (isDeleting) ...[
            const SizedBox(height: OpenVtsSpacing.sm),
            const LinearProgressIndicator(minHeight: 2),
          ],
        ],
      ),
    );
  }
}

class _CardHeader extends StatelessWidget {
  const _CardHeader({
    required this.administrator,
    required this.isBusy,
    required this.isToggling,
    required this.isLoggingIn,
    required this.onToggleActive,
    required this.onLogin,
    required this.onDelete,
  });

  final SuperadminAdministrator administrator;
  final bool isBusy;
  final bool isToggling;
  final bool isLoggingIn;
  final ValueChanged<bool> onToggleActive;
  final VoidCallback onLogin;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _AvatarCircle(administrator: administrator),
        const SizedBox(width: OpenVtsSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                administrator.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                '@${administrator.username == 'â€”' ? 'unknown' : administrator.username}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: OpenVtsTypography.label.copyWith(
                  color: OpenVtsColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: OpenVtsSpacing.xs),
        _StatusToggle(
          isActive: administrator.isActive,
          isBusy: isBusy,
          isToggling: isToggling,
          onChanged: onToggleActive,
        ),
        _CardMenu(
          isBusy: isBusy,
          isLoggingIn: isLoggingIn,
          isActive: administrator.isActive,
          onToggleActive: onToggleActive,
          onLogin: onLogin,
          onDelete: onDelete,
        ),
      ],
    );
  }
}

class _AvatarCircle extends StatelessWidget {
  const _AvatarCircle({required this.administrator});

  final SuperadminAdministrator administrator;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      width: 44,
      decoration: BoxDecoration(
        color: _softSurfaceColor(context),
        shape: BoxShape.circle,
        border: Border.all(color: _softBorderColor(context)),
      ),
      alignment: Alignment.center,
      child: Text(
        administrator.initials,
        style: OpenVtsTypography.label.copyWith(
          fontWeight: FontWeight.w700,
          color: _primaryInkColor(context),
          fontSize: 14,
        ),
      ),
    );
  }
}

class _StatusToggle extends StatelessWidget {
  const _StatusToggle({
    required this.isActive,
    required this.isBusy,
    required this.isToggling,
    required this.onChanged,
  });

  final bool isActive;
  final bool isBusy;
  final bool isToggling;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    if (isToggling) {
      return const SizedBox(
        width: 40,
        height: 32,
        child: Center(
          child: SizedBox.square(
            dimension: 16,
            child: CircularProgressIndicator(strokeWidth: 2.2),
          ),
        ),
      );
    }

    return Tooltip(
      message: isActive ? 'Deactivate administrator' : 'Activate administrator',
      child: Transform.scale(
        scale: 0.85,
        child: Switch(
          value: isActive,
          onChanged: isBusy ? null : onChanged,
          activeThumbColor: OpenVtsColors.white,
          activeTrackColor: _primaryInkColor(context),
          inactiveThumbColor: OpenVtsColors.white,
          inactiveTrackColor: _softBorderColor(context),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
    );
  }
}

class _CardMenu extends StatelessWidget {
  const _CardMenu({
    required this.isBusy,
    required this.isLoggingIn,
    required this.isActive,
    required this.onToggleActive,
    required this.onLogin,
    required this.onDelete,
  });

  final bool isBusy;
  final bool isLoggingIn;
  final bool isActive;
  final ValueChanged<bool> onToggleActive;
  final VoidCallback onLogin;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    if (isLoggingIn) {
      return const Padding(
        padding: EdgeInsetsDirectional.only(start: OpenVtsSpacing.xs),
        child: SizedBox.square(
          dimension: 18,
          child: CircularProgressIndicator(strokeWidth: 2.2),
        ),
      );
    }

    return PopupMenuButton<_AdministratorMenuAction>(
      tooltip: 'More options',
      onSelected: (action) {
        switch (action) {
          case _AdministratorMenuAction.login:
            onLogin();
          case _AdministratorMenuAction.toggleStatus:
            onToggleActive(!isActive);
          case _AdministratorMenuAction.delete:
            onDelete();
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: _AdministratorMenuAction.login,
          child: Row(
            children: [
              Icon(Icons.login_rounded, size: 16),
              SizedBox(width: OpenVtsSpacing.xs),
              Text('Login as admin'),
            ],
          ),
        ),
        PopupMenuItem(
          value: _AdministratorMenuAction.toggleStatus,
          child: Row(
            children: [
              Icon(
                isActive
                    ? Icons.toggle_off_outlined
                    : Icons.toggle_on_outlined,
                size: 16,
              ),
              const SizedBox(width: OpenVtsSpacing.xs),
              Text(isActive ? 'Deactivate' : 'Activate'),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: _AdministratorMenuAction.delete,
          child: Row(
            children: [
              const Icon(
                Icons.delete_outline_rounded,
                size: 16,
                color: OpenVtsColors.error,
              ),
              const SizedBox(width: OpenVtsSpacing.xs),
              Text(
                'Delete',
                style: OpenVtsTypography.label.copyWith(
                  color: OpenVtsColors.error,
                ),
              ),
            ],
          ),
        ),
      ],
      enabled: !isBusy,
      icon: const Icon(
        Icons.more_vert_rounded,
        size: 18,
        color: OpenVtsColors.textSecondary,
      ),
      padding: EdgeInsets.zero,
      splashRadius: 18,
      position: PopupMenuPosition.under,
    );
  }
}

enum _AdministratorMenuAction { login, toggleStatus, delete }

// ---------------------------------------------------------------------------
// Card info rows
// ---------------------------------------------------------------------------

class _CardInfoGrid extends StatelessWidget {
  const _CardInfoGrid({required this.administrator});

  final SuperadminAdministrator administrator;

  @override
  Widget build(BuildContext context) {
    final emailValue = _displayValue(administrator.email);
    final phoneValue = administrator.phoneDisplay;
    final companyValue = _displayValue(administrator.companyName);
    final countryValue = _displayValue(
      administrator.countryCode.trim().isNotEmpty
          ? administrator.countryCode.trim().toUpperCase()
          : administrator.countryName,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 420;

        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _InfoRow(
                icon: Icons.mail_outline_rounded,
                value: emailValue,
              ),
              const SizedBox(height: OpenVtsSpacing.xs),
              _InfoRow(
                icon: Icons.call_outlined,
                value: phoneValue,
              ),
              const SizedBox(height: OpenVtsSpacing.xs),
              _InfoRow(
                icon: Icons.business_outlined,
                value: companyValue,
              ),
              const SizedBox(height: OpenVtsSpacing.xs),
              _InfoRow(
                icon: Icons.outlined_flag_rounded,
                value: countryValue,
              ),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _InfoRow(
                    icon: Icons.mail_outline_rounded,
                    value: emailValue,
                  ),
                ),
                const SizedBox(width: OpenVtsSpacing.sm),
                Expanded(
                  child: _InfoRow(
                    icon: Icons.call_outlined,
                    value: phoneValue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: OpenVtsSpacing.xs),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _InfoRow(
                    icon: Icons.business_outlined,
                    value: companyValue,
                  ),
                ),
                const SizedBox(width: OpenVtsSpacing.sm),
                Expanded(
                  child: _InfoRow(
                    icon: Icons.outlined_flag_rounded,
                    value: countryValue,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.value,
  });

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(
          icon,
          size: 16,
          color: OpenVtsColors.textSecondary,
        ),
        const SizedBox(width: OpenVtsSpacing.xs),
        Expanded(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: OpenVtsTypography.label.copyWith(
              color: OpenVtsColors.textPrimary,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Card metrics row (Vehicles / Credits / Last login)
// ---------------------------------------------------------------------------

class _CardMetricsRow extends StatelessWidget {
  const _CardMetricsRow({required this.administrator});

  final SuperadminAdministrator administrator;

  @override
  Widget build(BuildContext context) {
    final lastLogin = administrator.lastLoginAt;
    final lastLoginValue = lastLogin != null
        ? '${_administratorsDateFormatter.formatDate(lastLogin)} \u2022 ${_administratorsDateFormatter.formatTime(lastLogin)}'
        : (administrator.lastLoginText?.trim().isNotEmpty == true
            ? administrator.lastLoginText!.trim()
            : '\u2014');

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 420;

        if (compact) {
          return Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _MetricCell(
                      icon: Icons.local_shipping_outlined,
                      label: 'Vehicles',
                      value: administrator.totalVehicles.toString(),
                    ),
                  ),
                  const SizedBox(width: OpenVtsSpacing.xs),
                  Expanded(
                    child: _MetricCell(
                      icon: Icons.credit_card_outlined,
                      label: 'Credits',
                      value: administrator.totalCredits.toString(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: OpenVtsSpacing.xs),
              _MetricCell(
                icon: Icons.schedule_outlined,
                label: 'Last login',
                value: lastLoginValue,
              ),
            ],
          );
        }

        return Row(
          children: [
            Expanded(
              child: _MetricCell(
                icon: Icons.local_shipping_outlined,
                label: 'Vehicles',
                value: administrator.totalVehicles.toString(),
              ),
            ),
            const SizedBox(width: OpenVtsSpacing.xs),
            Expanded(
              child: _MetricCell(
                icon: Icons.credit_card_outlined,
                label: 'Credits',
                value: administrator.totalCredits.toString(),
              ),
            ),
            const SizedBox(width: OpenVtsSpacing.xs),
            Expanded(
              flex: 2,
              child: _MetricCell(
                icon: Icons.schedule_outlined,
                label: 'Last login',
                value: lastLoginValue,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _MetricCell extends StatelessWidget {
  const _MetricCell({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: OpenVtsSpacing.sm,
        vertical: OpenVtsSpacing.xs + 2,
      ),
      decoration: BoxDecoration(
        color: _softSurfaceColor(context),
        borderRadius: BorderRadius.circular(OpenVtsRadius.md),
        border: Border.all(color: _softBorderColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 14,
                color: OpenVtsColors.textSecondary,
              ),
              const SizedBox(width: OpenVtsSpacing.xxs + 2),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: OpenVtsTypography.meta.copyWith(
                    color: OpenVtsColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: OpenVtsSpacing.xxs + 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: OpenVtsTypography.label.copyWith(
              color: _primaryInkColor(context),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
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
// Options sheet (Filter/Sort)
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
            if (primaryActionLabel != null || secondaryActionLabel != null) ...[
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
    final background = selected
        ? _primaryInkColor(context)
        : _softSurfaceColor(context);
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
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(OpenVtsRadius.lg);
    final surface = Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: radius,
        border: Border.all(color: _softBorderColor(context)),
      ),
      child: child,
    );

    if (onTap == null) {
      return surface;
    }

    return Material(
      color: Colors.transparent,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: surface,
      ),
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

String _displayValue(String value) {
  final normalized = value.trim();
  return normalized.isEmpty ? '\u2014' : normalized;
}
