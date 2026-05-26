import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/open_vts_colors.dart';
import '../../../../core/theme/open_vts_radius.dart';
import '../../../../core/theme/open_vts_spacing.dart';
import '../../../../core/theme/open_vts_typography.dart';
import '../../../../shared/helpers/toast_helper.dart';
import '../../../../shared/widgets/open_vts_card.dart';
import '../../../../shared/widgets/open_vts_error_view.dart';
import '../../../../shared/widgets/open_vts_loader.dart';
import '../../../../shared/widgets/open_vts_page_scaffold.dart';
import '../../controllers/admin_driver_details_controller.dart';
import '../../controllers/admin_providers.dart';
import '../../models/admin_driver_details_state.dart';
import '../../models/admin_drivers_model.dart';
import 'widgets/admin_driver_documents_tab.dart';
import 'widgets/admin_driver_edit_sheet.dart';
import 'widgets/admin_driver_password_sheet.dart';
import 'widgets/admin_driver_profile_tab.dart';
import 'widgets/admin_driver_users_tab.dart';

class AdminDriverDetailsScreen extends ConsumerWidget {
  const AdminDriverDetailsScreen({
    super.key,
    required this.driverId,
    this.initialDriver,
  });

  final String driverId;
  final AdminDriverListItem? initialDriver;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = adminDriverDetailsControllerProvider(driverId);
    final state = ref.watch(provider);
    final controller = ref.read(provider.notifier);

    final driver = state.driver;
    final isActive = driver?.isActive ?? initialDriver?.isActive ?? false;
    final title = driver?.name.trim().isNotEmpty == true
        ? driver!.name
        : (initialDriver?.firstName.trim().isNotEmpty == true
            ? initialDriver!.firstName
            : 'Driver');

    return OpenVtsPageScaffold(
      title: title,
      headerMode: OpenVtsPageHeaderMode.closeable,
      onClose: () {
        if (context.canPop()) {
          context.pop();
          return;
        }
        context.go(RoutePaths.adminDrivers);
      },
      actions: [
        _HeaderStatusChip(isActive: isActive),
        const SizedBox(width: 4),
        PopupMenuButton<_DriverMenuAction>(
          tooltip: 'Driver actions',
          icon: const Icon(
            Icons.more_vert_rounded,
            size: 20,
            color: OpenVtsColors.textSecondary,
          ),
          onSelected: (value) async {
            switch (value) {
              case _DriverMenuAction.refresh:
                await controller.refreshCurrentTab();
                break;
              case _DriverMenuAction.edit:
                await showDriverEditSheet(context: context, provider: provider);
                break;
              case _DriverMenuAction.toggleStatus:
                final current =
                    driver?.isActive ?? (initialDriver?.isActive ?? false);
                final ok = await controller.updateStatus(!current);
                if (context.mounted) {
                  if (ok) {
                    ToastHelper.showSuccess(
                      !current ? 'Driver activated.' : 'Driver deactivated.',
                      context: context,
                    );
                  } else {
                    ToastHelper.showError(
                      ref.read(provider).sectionErrorMessage ??
                          'Unable to update status.',
                      context: context,
                    );
                  }
                }
                break;
              case _DriverMenuAction.password:
                await showDriverPasswordSheet(
                  context: context,
                  provider: provider,
                );
                break;
              case _DriverMenuAction.delete:
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (dialogContext) {
                    return AlertDialog(
                      title: const Text('Delete driver account'),
                      content: Text(
                        'Delete ${driver?.name ?? initialDriver?.firstName ?? 'this driver'}? '
                        'This removes the driver account and assignments.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () =>
                              Navigator.of(dialogContext).pop(false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () =>
                              Navigator.of(dialogContext).pop(true),
                          style: TextButton.styleFrom(
                            foregroundColor: OpenVtsColors.error,
                          ),
                          child: const Text('Delete'),
                        ),
                      ],
                    );
                  },
                );
                if (confirmed != true) break;
                final ok = await controller.deleteDriver();
                if (context.mounted) {
                  if (ok) {
                    ToastHelper.showSuccess('Driver deleted.',
                        context: context);
                    ref.invalidate(adminDriversControllerProvider);
                    context.go(RoutePaths.adminDrivers);
                  } else {
                    ToastHelper.showError(
                      ref.read(provider).sectionErrorMessage ??
                          'Unable to delete driver.',
                      context: context,
                    );
                  }
                }
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: _DriverMenuAction.refresh,
              height: 40,
              child: _MenuRow(icon: Icons.refresh_rounded, label: 'Refresh'),
            ),
            const PopupMenuItem(
              value: _DriverMenuAction.edit,
              height: 40,
              child: _MenuRow(icon: Icons.edit_rounded, label: 'Edit Profile'),
            ),
            PopupMenuItem(
              value: _DriverMenuAction.toggleStatus,
              height: 40,
              child: _MenuRow(
                icon: (driver?.isActive ?? initialDriver?.isActive ?? false)
                    ? Icons.toggle_off_outlined
                    : Icons.toggle_on_outlined,
                label: (driver?.isActive ?? initialDriver?.isActive ?? false)
                    ? 'Set Inactive'
                    : 'Set Active',
              ),
            ),
            const PopupMenuItem(
              value: _DriverMenuAction.password,
              height: 40,
              child: _MenuRow(
                icon: Icons.key_rounded,
                label: 'Update Password',
              ),
            ),
            const PopupMenuDivider(height: 1),
            const PopupMenuItem(
              value: _DriverMenuAction.delete,
              height: 40,
              child: _MenuRow(
                icon: Icons.delete_outline_rounded,
                label: 'Delete Account',
                destructive: true,
              ),
            ),
          ],
        ),
        const SizedBox(width: 4),
      ],
      body: RefreshIndicator(
        onRefresh: controller.refreshCurrentTab,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(OpenVtsSpacing.sm),
          children: [
            if (state.isLoadingDriver &&
                driver == null &&
                initialDriver == null)
              const SizedBox(height: 220, child: OpenVtsLoader())
            else if (state.errorMessage != null &&
                driver == null &&
                initialDriver == null)
              OpenVtsErrorView(
                message: state.errorMessage!,
                onRetry: controller.loadInitial,
              )
            else
              _SummaryCard(driver: driver, initialDriver: initialDriver),
            const SizedBox(height: OpenVtsSpacing.sm),
            _TabChips(
              selected: state.selectedTab,
              onSelect: controller.selectTab,
            ),
            const SizedBox(height: OpenVtsSpacing.sm),
            _TabContent(state: state, provider: provider),
          ],
        ),
      ),
    );
  }
}

enum _DriverMenuAction { refresh, edit, toggleStatus, password, delete }

class _HeaderStatusChip extends StatelessWidget {
  const _HeaderStatusChip({required this.isActive});

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final color =
        isActive ? OpenVtsColors.brandInk : OpenVtsColors.textTertiary;
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(OpenVtsRadius.pill),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Text(
          isActive ? 'Active' : 'Inactive',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.icon,
    required this.label,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive ? OpenVtsColors.error : OpenVtsColors.textPrimary;
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: OpenVtsSpacing.xs),
        Text(label, style: TextStyle(color: color, fontSize: 12.5)),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.driver, required this.initialDriver});

  final dynamic driver;
  final AdminDriverListItem? initialDriver;

  @override
  Widget build(BuildContext context) {
    final name = driver?.name ?? initialDriver?.firstName ?? 'Driver';
    final username = driver?.username ?? initialDriver?.username ?? '—';
    final email = driver?.email ?? '—';
    final phone = driver?.phone ?? initialDriver?.phone ?? '—';
    final isActive = driver?.isActive ?? initialDriver?.isActive ?? false;
    final isVerified = driver?.isVerified ?? false;

    return OpenVtsCard(
      padding: const EdgeInsets.all(OpenVtsSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56,
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: OpenVtsColors.background,
                  borderRadius: BorderRadius.circular(OpenVtsRadius.pill),
                  border: Border.all(color: OpenVtsColors.border),
                ),
                child: Text(
                  _initials(name),
                  style: OpenVtsTypography.label.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: OpenVtsSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: OpenVtsTypography.body.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: OpenVtsSpacing.xxs),
                    Text(
                      '@$username',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: OpenVtsTypography.meta.copyWith(
                        color: OpenVtsColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: OpenVtsSpacing.xs),
                    Wrap(
                      spacing: OpenVtsSpacing.xs,
                      runSpacing: OpenVtsSpacing.xs,
                      children: [
                        _MiniChip(
                          label: isActive ? 'Active' : 'Inactive',
                          active: isActive,
                        ),
                        _MiniChip(
                          label: isVerified ? 'Verified' : 'Unverified',
                          active: isVerified,
                        ),
                        const _MiniChip(label: 'Driver', active: false),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: OpenVtsSpacing.sm),
          const Divider(height: 1, color: OpenVtsColors.border),
          const SizedBox(height: OpenVtsSpacing.sm),
          _SummaryRow(
            icon: Icons.mail_outline_rounded,
            label: 'Email',
            value: email,
          ),
          const SizedBox(height: OpenVtsSpacing.xs),
          _SummaryRow(
            icon: Icons.phone_outlined,
            label: 'Phone',
            value: phone,
          ),
        ],
      ),
    );
  }

  String _initials(String text) {
    final parts =
        text.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) return '--';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: OpenVtsColors.textTertiary),
        const SizedBox(width: 8),
        SizedBox(
          width: 56,
          child: Text(
            label,
            style: OpenVtsTypography.meta.copyWith(
              color: OpenVtsColors.textTertiary,
              fontSize: 11,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value.trim().isEmpty ? '—' : value,
            style: OpenVtsTypography.meta.copyWith(
              color: OpenVtsColors.textPrimary,
              fontWeight: FontWeight.w500,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }
}

class _MiniChip extends StatelessWidget {
  const _MiniChip({required this.label, required this.active});

  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = active ? OpenVtsColors.success : OpenVtsColors.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(OpenVtsRadius.pill),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: OpenVtsTypography.meta.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _TabChips extends StatelessWidget {
  const _TabChips({required this.selected, required this.onSelect});

  final AdminDriverDetailsTab selected;
  final ValueChanged<AdminDriverDetailsTab> onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _Chip(
            label: 'Profile',
            selected: selected == AdminDriverDetailsTab.profile,
            onTap: () => onSelect(AdminDriverDetailsTab.profile),
          ),
          const SizedBox(width: OpenVtsSpacing.xs),
          _Chip(
            label: 'Documents',
            selected: selected == AdminDriverDetailsTab.documents,
            onTap: () => onSelect(AdminDriverDetailsTab.documents),
          ),
          const SizedBox(width: OpenVtsSpacing.xs),
          _Chip(
            label: 'Users',
            selected: selected == AdminDriverDetailsTab.users,
            onTap: () => onSelect(AdminDriverDetailsTab.users),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? OpenVtsColors.brandInk : OpenVtsColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(OpenVtsRadius.pill),
        side: BorderSide(
          color: selected ? OpenVtsColors.brandInk : OpenVtsColors.border,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(OpenVtsRadius.pill),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          child: Text(
            label,
            style: OpenVtsTypography.meta.copyWith(
              color: selected ? OpenVtsColors.white : OpenVtsColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _TabContent extends ConsumerWidget {
  const _TabContent({required this.state, required this.provider});

  final AdminDriverDetailsState state;
  final AutoDisposeStateNotifierProvider<AdminDriverDetailsController,
      AdminDriverDetailsState> provider;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    switch (state.selectedTab) {
      case AdminDriverDetailsTab.profile:
        return AdminDriverProfileTab(provider: provider, state: state);
      case AdminDriverDetailsTab.documents:
        return AdminDriverDocumentsTab(provider: provider, state: state);
      case AdminDriverDetailsTab.users:
        return AdminDriverUsersTab(provider: provider, state: state);
    }
  }
}
