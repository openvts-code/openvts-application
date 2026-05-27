import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/open_vts_colors.dart';
import '../../../../core/theme/open_vts_radius.dart';
import '../../../../core/theme/open_vts_spacing.dart';
import '../../../../shared/helpers/toast_helper.dart';
import '../../../../shared/widgets/open_vts_card.dart';
import '../../../../shared/widgets/open_vts_error_view.dart';
import '../../../../shared/widgets/open_vts_page_scaffold.dart';
import '../../controllers/superadmin_providers.dart';
import '../../models/superadmin_admin_details_model.dart';
import '../../models/superadmin_admin_details_state.dart';
import '../../models/superadmin_administrator_model.dart';
import 'widgets/admin_details_activity_tab.dart';
import 'widgets/admin_details_credit_history_tab.dart';
import 'widgets/admin_details_documents_tab.dart';
import 'widgets/admin_details_payments_tab.dart';
import 'widgets/admin_details_profile_tab.dart';
import 'widgets/admin_details_vehicles_tab.dart';

class SuperadminAdminDetailsScreen extends ConsumerWidget {
  const SuperadminAdminDetailsScreen({
    required this.adminId,
    this.initialAdmin,
    super.key,
  });

  final String adminId;
  final SuperadminAdministrator? initialAdmin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = superadminAdminDetailsControllerProvider(adminId);

    final adminName = ref.watch(provider.select((s) => s.admin?.name ?? ''));
    final isActive = ref.watch(
      provider
          .select((s) => s.admin?.isActive ?? initialAdmin?.isActive ?? false),
    );
    final isUpdatingStatus =
        ref.watch(provider.select((s) => s.isUpdatingStatus));
    final isDeletingAdmin =
        ref.watch(provider.select((s) => s.isDeletingAdmin));

    final title = adminName.trim().isNotEmpty
        ? adminName
        : (initialAdmin?.name.trim().isNotEmpty == true
            ? initialAdmin!.name
            : 'Administrator');

    return OpenVtsPageScaffold(
      title: title,
      headerMode: OpenVtsPageHeaderMode.closeable,
      onClose: () => Navigator.of(context).maybePop(),
      actions: [
        _HeaderStatusChip(isActive: isActive),
        const SizedBox(width: 4),
        _HeaderMenu(
          isActive: isActive,
          isUpdatingStatus: isUpdatingStatus,
          isDeleting: isDeletingAdmin,
          onRefresh: () => _refreshAll(ref),
          onToggleStatus: () => _handleToggleStatus(context, ref),
          onDelete: () => _handleDelete(context, ref),
        ),
        const SizedBox(width: 4),
      ],
      body: _Body(adminId: adminId, initialAdmin: initialAdmin),
    );
  }

  Future<void> _refreshAll(WidgetRef ref) async {
    final provider = superadminAdminDetailsControllerProvider(adminId);
    final controller = ref.read(provider.notifier);
    final selectedTab = ref.read(provider.select((s) => s.selectedTab));
    await controller.refreshAdmin();
    switch (selectedTab) {
      case SuperadminAdminDetailsTab.profile:
        break;
      case SuperadminAdminDetailsTab.creditHistory:
        await controller.loadCreditLogs(force: true);
        break;
      case SuperadminAdminDetailsTab.payments:
        await controller.loadPayments();
        break;
      case SuperadminAdminDetailsTab.documents:
        await controller.loadDocuments(force: true);
        break;
      case SuperadminAdminDetailsTab.vehicles:
        await controller.loadVehicles(force: true);
        break;
      case SuperadminAdminDetailsTab.adminActivity:
        await controller.loadActivity();
        break;
    }
  }

  Future<void> _handleToggleStatus(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final provider = superadminAdminDetailsControllerProvider(adminId);
    final controller = ref.read(provider.notifier);
    final currentlyActive = ref.read(
      provider
          .select((s) => s.admin?.isActive ?? initialAdmin?.isActive ?? false),
    );
    final next = !currentlyActive;
    final ok = await controller.updateStatus(next);
    if (!context.mounted) return;
    if (ok) {
      ToastHelper.showSuccess(
        next ? 'Administrator activated.' : 'Administrator deactivated.',
        context: context,
      );
    } else {
      final err = ref.read(provider.select((s) => s.sectionErrorMessage));
      ToastHelper.showError(
        err ?? 'Failed to update status.',
        context: context,
      );
    }
  }

  Future<void> _handleDelete(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final provider = superadminAdminDetailsControllerProvider(adminId);
    final controller = ref.read(provider.notifier);
    final adminNameNow = ref.read(provider.select((s) => s.admin?.name ?? ''));
    final name = adminNameNow.trim().isNotEmpty
        ? adminNameNow
        : (initialAdmin?.name.trim().isNotEmpty == true
            ? initialAdmin!.name
            : 'this administrator');

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete administrator'),
          content: Text(
            'Remove $name from the platform? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: OpenVtsColors.error,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;
    if (!context.mounted) return;

    final ok = await controller.deleteAdmin();
    if (!context.mounted) return;
    if (ok) {
      ToastHelper.showSuccess('$name deleted.', context: context);
      Navigator.of(context).maybePop();
    } else {
      final err = ref.read(provider.select((s) => s.sectionErrorMessage));
      ToastHelper.showError(
        err ?? 'Failed to delete administrator.',
        context: context,
      );
    }
  }
}

// ---------------------------------------------------------------------------
// Header widgets
// ---------------------------------------------------------------------------

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

enum _AdminDetailsMenuAction { refresh, toggleStatus, delete }

class _HeaderMenu extends StatelessWidget {
  const _HeaderMenu({
    required this.isActive,
    required this.isUpdatingStatus,
    required this.isDeleting,
    required this.onRefresh,
    required this.onToggleStatus,
    required this.onDelete,
  });

  final bool isActive;
  final bool isUpdatingStatus;
  final bool isDeleting;
  final VoidCallback onRefresh;
  final VoidCallback onToggleStatus;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_AdminDetailsMenuAction>(
      tooltip: 'More actions',
      icon: const Icon(
        Icons.more_vert_rounded,
        size: 20,
        color: OpenVtsColors.textSecondary,
      ),
      onSelected: (value) {
        switch (value) {
          case _AdminDetailsMenuAction.refresh:
            onRefresh();
          case _AdminDetailsMenuAction.toggleStatus:
            onToggleStatus();
          case _AdminDetailsMenuAction.delete:
            onDelete();
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: _AdminDetailsMenuAction.refresh,
          height: 40,
          child: _MenuRow(
            icon: Icons.refresh_rounded,
            label: 'Refresh',
          ),
        ),
        PopupMenuItem(
          value: _AdminDetailsMenuAction.toggleStatus,
          height: 40,
          enabled: !isUpdatingStatus,
          child: _MenuRow(
            icon:
                isActive ? Icons.toggle_off_outlined : Icons.toggle_on_outlined,
            label: isActive ? 'Deactivate' : 'Activate',
          ),
        ),
        PopupMenuItem(
          value: _AdminDetailsMenuAction.delete,
          height: 40,
          enabled: !isDeleting,
          child: const _MenuRow(
            icon: Icons.delete_outline_rounded,
            label: 'Delete admin',
            isDestructive: true,
          ),
        ),
      ],
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.icon,
    required this.label,
    this.isDestructive = false,
  });

  final IconData icon;
  final String label;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final color =
        isDestructive ? OpenVtsColors.error : OpenVtsColors.textPrimary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Body
// ---------------------------------------------------------------------------

class _Body extends ConsumerWidget {
  const _Body({
    required this.adminId,
    required this.initialAdmin,
  });

  final String adminId;
  final SuperadminAdministrator? initialAdmin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = superadminAdminDetailsControllerProvider(adminId);
    final controller = ref.read(provider.notifier);

    final admin = ref.watch(provider.select((s) => s.admin));
    final isLoadingAdmin = ref.watch(provider.select((s) => s.isLoadingAdmin));
    final errorMessage = ref.watch(provider.select((s) => s.errorMessage));
    final selectedTab = ref.watch(provider.select((s) => s.selectedTab));

    final isInitialLoad = isLoadingAdmin && admin == null;

    if (isInitialLoad && initialAdmin == null) {
      return const _SummarySkeleton();
    }

    if (errorMessage != null && admin == null) {
      return Padding(
        padding: const EdgeInsets.all(OpenVtsSpacing.md),
        child: OpenVtsErrorView(
          message: errorMessage,
          onRetry: controller.refreshAdmin,
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await controller.refreshAdmin();
        final tab = ref.read(provider.select((s) => s.selectedTab));
        switch (tab) {
          case SuperadminAdminDetailsTab.profile:
            break;
          case SuperadminAdminDetailsTab.creditHistory:
            await controller.loadCreditLogs(force: true);
          case SuperadminAdminDetailsTab.payments:
            await controller.loadPayments();
          case SuperadminAdminDetailsTab.documents:
            await controller.loadDocuments(force: true);
          case SuperadminAdminDetailsTab.vehicles:
            await controller.loadVehicles(force: true);
          case SuperadminAdminDetailsTab.adminActivity:
            await controller.loadActivity();
        }
      },
      child: ListView(
        padding: const EdgeInsets.all(OpenVtsSpacing.sm),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          _SummaryCard(admin: admin, fallback: initialAdmin),
          const SizedBox(height: OpenVtsSpacing.sm),
          _TabChips(
            selected: selectedTab,
            onSelect: controller.selectTab,
          ),
          const SizedBox(height: OpenVtsSpacing.sm),
          _TabContent(
            adminId: adminId,
            selectedTab: selectedTab,
          ),
          const SizedBox(height: OpenVtsSpacing.lg),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Summary card
// ---------------------------------------------------------------------------

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.admin, required this.fallback});

  final SuperadminAdminDetails? admin;
  final SuperadminAdministrator? fallback;

  @override
  Widget build(BuildContext context) {
    final name = admin?.name.trim().isNotEmpty == true
        ? admin!.name
        : (fallback?.name ?? 'Administrator');
    final username = admin?.username.trim().isNotEmpty == true
        ? admin!.username
        : (fallback?.username ?? '');
    final email = admin?.email.trim().isNotEmpty == true
        ? admin!.email
        : (fallback?.email ?? '');
    final phone = admin?.mobileDisplay.trim().isNotEmpty == true
        ? admin!.mobileDisplay
        : (fallback?.phoneDisplay ?? '');
    final isActive = admin?.isActive ?? fallback?.isActive ?? false;
    final isVerified = admin?.isEmailVerified ?? fallback?.isVerified ?? false;
    final credits = admin?.credits ?? fallback?.totalCredits ?? 0;
    final vehicles = admin?.totalVehicles ?? fallback?.totalVehicles ?? 0;
    final initial = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : '?';

    return OpenVtsCard(
      padding: const EdgeInsets.all(OpenVtsSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                height: 44,
                width: 44,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: OpenVtsColors.surface,
                ),
                child: Text(
                  initial,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: OpenVtsColors.textPrimary,
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
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: OpenVtsColors.textPrimary,
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (username.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        '@$username',
                        style: const TextStyle(
                          fontSize: 12,
                          color: OpenVtsColors.textSecondary,
                          height: 1.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: OpenVtsSpacing.sm),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _Pill(
                    label: isActive ? 'Active' : 'Inactive',
                    color: isActive
                        ? OpenVtsColors.brandInk
                        : OpenVtsColors.textTertiary,
                  ),
                  if (isVerified) ...[
                    const SizedBox(height: 4),
                    const _Pill(
                      label: 'Verified',
                      icon: Icons.verified_outlined,
                      color: OpenVtsColors.success,
                    ),
                  ],
                ],
              ),
            ],
          ),
          if (email.isNotEmpty || phone.isNotEmpty) ...[
            const SizedBox(height: OpenVtsSpacing.sm),
            if (email.isNotEmpty)
              _ContactLine(icon: Icons.mail_outline_rounded, text: email),
            if (email.isNotEmpty && phone.isNotEmpty) const SizedBox(height: 4),
            if (phone.isNotEmpty)
              _ContactLine(icon: Icons.phone_outlined, text: phone),
          ],
          const SizedBox(height: OpenVtsSpacing.md),
          const Divider(height: 1, color: OpenVtsColors.border),
          const SizedBox(height: OpenVtsSpacing.md),
          Row(
            children: [
              Expanded(
                child: _MetricTile(
                  icon: Icons.credit_card_outlined,
                  label: 'Credits',
                  value: credits.toString(),
                ),
              ),
              const SizedBox(width: OpenVtsSpacing.sm),
              Expanded(
                child: _MetricTile(
                  icon: Icons.local_shipping_outlined,
                  label: 'Vehicles',
                  value: vehicles.toString(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ContactLine extends StatelessWidget {
  const _ContactLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: OpenVtsColors.textTertiary),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              color: OpenVtsColors.textSecondary,
              height: 1.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.color, this.icon});

  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(OpenVtsRadius.pill),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
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
      padding: const EdgeInsets.symmetric(
        horizontal: OpenVtsSpacing.sm,
        vertical: OpenVtsSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: OpenVtsColors.surface,
        borderRadius: BorderRadius.circular(OpenVtsRadius.md),
        border: Border.all(color: OpenVtsColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: OpenVtsColors.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: OpenVtsColors.textTertiary,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: OpenVtsColors.textPrimary,
                    height: 1.1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tab chips
// ---------------------------------------------------------------------------

class _TabChips extends StatelessWidget {
  const _TabChips({required this.selected, required this.onSelect});

  final SuperadminAdminDetailsTab selected;
  final ValueChanged<SuperadminAdminDetailsTab> onSelect;

  @override
  Widget build(BuildContext context) {
    const tabs = SuperadminAdminDetailsTab.values;
    return SizedBox(
      height: 32,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: tabs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          final tab = tabs[index];
          final isSelected = tab == selected;
          return _TabChip(
            label: _labelFor(tab),
            icon: _iconFor(tab),
            isSelected: isSelected,
            onTap: () => onSelect(tab),
          );
        },
      ),
    );
  }

  String _labelFor(SuperadminAdminDetailsTab tab) {
    switch (tab) {
      case SuperadminAdminDetailsTab.profile:
        return 'Profile';
      case SuperadminAdminDetailsTab.creditHistory:
        return 'Credits';
      case SuperadminAdminDetailsTab.payments:
        return 'Payments';
      case SuperadminAdminDetailsTab.documents:
        return 'Documents';
      case SuperadminAdminDetailsTab.vehicles:
        return 'Vehicles';
      case SuperadminAdminDetailsTab.adminActivity:
        return 'Activity';
    }
  }

  IconData _iconFor(SuperadminAdminDetailsTab tab) {
    switch (tab) {
      case SuperadminAdminDetailsTab.profile:
        return Icons.person_outline_rounded;
      case SuperadminAdminDetailsTab.creditHistory:
        return Icons.credit_card_outlined;
      case SuperadminAdminDetailsTab.payments:
        return Icons.receipt_long_outlined;
      case SuperadminAdminDetailsTab.documents:
        return Icons.description_outlined;
      case SuperadminAdminDetailsTab.vehicles:
        return Icons.local_shipping_outlined;
      case SuperadminAdminDetailsTab.adminActivity:
        return Icons.history_rounded;
    }
  }
}

class _TabChip extends StatelessWidget {
  const _TabChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bg =
        isSelected ? OpenVtsColors.brandInk : OpenVtsColors.surfaceElevated;
    final fg = isSelected ? OpenVtsColors.white : OpenVtsColors.textPrimary;
    return Material(
      color: bg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(OpenVtsRadius.pill),
        side: BorderSide(
          color: isSelected ? OpenVtsColors.brandInk : OpenVtsColors.border,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(OpenVtsRadius.pill),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: OpenVtsSpacing.sm,
            vertical: 6,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: fg),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: fg,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tab content (placeholder shell)
// ---------------------------------------------------------------------------

class _TabContent extends StatelessWidget {
  const _TabContent({
    required this.adminId,
    required this.selectedTab,
  });

  final String adminId;
  final SuperadminAdminDetailsTab selectedTab;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 120),
      child: KeyedSubtree(
        key: ValueKey<SuperadminAdminDetailsTab>(selectedTab),
        child: _buildTab(selectedTab),
      ),
    );
  }

  Widget _buildTab(SuperadminAdminDetailsTab tab) {
    switch (tab) {
      case SuperadminAdminDetailsTab.profile:
        return AdminDetailsProfileTab(
          key: const PageStorageKey('admin_details_profile'),
          adminId: adminId,
        );
      case SuperadminAdminDetailsTab.creditHistory:
        return AdminDetailsCreditHistoryTab(
          key: const PageStorageKey('admin_details_credits'),
          adminId: adminId,
        );
      case SuperadminAdminDetailsTab.payments:
        return AdminDetailsPaymentsTab(
          key: const PageStorageKey('admin_details_payments'),
          adminId: adminId,
        );
      case SuperadminAdminDetailsTab.documents:
        return AdminDetailsDocumentsTab(
          key: const PageStorageKey('admin_details_documents'),
          adminId: adminId,
        );
      case SuperadminAdminDetailsTab.vehicles:
        return AdminDetailsVehiclesTab(
          key: const PageStorageKey('admin_details_vehicles'),
          adminId: adminId,
        );
      case SuperadminAdminDetailsTab.adminActivity:
        return AdminDetailsActivityTab(
          key: const PageStorageKey('admin_details_activity'),
          adminId: adminId,
        );
    }
  }
}

// ---------------------------------------------------------------------------
// Skeleton
// ---------------------------------------------------------------------------

class _SummarySkeleton extends StatelessWidget {
  const _SummarySkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(OpenVtsSpacing.sm),
      child: OpenVtsCard(
        padding: const EdgeInsets.all(OpenVtsSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _bar(width: 44, height: 44, radius: 22),
                const SizedBox(width: OpenVtsSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _bar(width: 140, height: 12),
                      const SizedBox(height: 6),
                      _bar(width: 90, height: 10),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: OpenVtsSpacing.md),
            _bar(width: double.infinity, height: 10),
            const SizedBox(height: 6),
            _bar(width: 180, height: 10),
          ],
        ),
      ),
    );
  }

  Widget _bar({
    required double width,
    required double height,
    double radius = 4,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: OpenVtsColors.surface,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
