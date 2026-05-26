import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/core_providers.dart';
import '../../../core/router/route_paths.dart';
import '../../../shared/widgets/open_vts_role_home.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/admin_providers.dart';

class AdminHomeScreen extends ConsumerWidget {
  const AdminHomeScreen({super.key});

  static const _items = [
    OpenVtsRoleHomeItem(
      label: 'Dashboard',
      icon: Icons.dashboard_outlined,
      route: RoutePaths.adminDashboard,
    ),
    OpenVtsRoleHomeItem(
      label: 'Users',
      icon: Icons.people_outline_rounded,
      route: RoutePaths.adminUsers,
    ),
    OpenVtsRoleHomeItem(
      label: 'Vehicles',
      icon: Icons.local_shipping_outlined,
      route: RoutePaths.adminVehicles,
    ),
    OpenVtsRoleHomeItem(
      label: 'Drivers',
      icon: Icons.badge_outlined,
      route: RoutePaths.adminDrivers,
    ),
    OpenVtsRoleHomeItem(
      label: 'Team',
      icon: Icons.groups_2_outlined,
      route: RoutePaths.adminTeam,
    ),
    OpenVtsRoleHomeItem(
      label: 'Inventory',
      icon: Icons.inventory_2_outlined,
      route: RoutePaths.adminInventory,
    ),
    OpenVtsRoleHomeItem(
      label: 'Map',
      icon: Icons.map_outlined,
      route: RoutePaths.adminMap,
    ),
    OpenVtsRoleHomeItem(
      label: 'Transactions',
      icon: Icons.receipt_long_outlined,
      route: RoutePaths.adminTransactions,
    ),
    OpenVtsRoleHomeItem(
      label: 'Payments',
      icon: Icons.payments_outlined,
      route: RoutePaths.adminPayments,
    ),
    OpenVtsRoleHomeItem(
      label: 'Support',
      icon: Icons.support_agent_outlined,
      route: RoutePaths.adminSupport,
    ),
    OpenVtsRoleHomeItem(
      label: 'Calendar',
      icon: Icons.calendar_month_outlined,
      route: RoutePaths.adminCalendar,
    ),
    OpenVtsRoleHomeItem(
      label: 'Logs',
      icon: Icons.description_outlined,
      route: RoutePaths.adminLogs,
    ),
    OpenVtsRoleHomeItem(
      label: 'Plans',
      icon: Icons.sell_outlined,
      route: RoutePaths.adminPlans,
    ),
    OpenVtsRoleHomeItem(
      label: 'Settings',
      icon: Icons.settings_outlined,
      route: RoutePaths.adminSettings,
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final user = authState.user;
    final baseUrl = ref.watch(apiBaseUrlProvider);
    final unreadAsync = ref.watch(adminNotificationUnreadBadgeProvider);
    final unreadCount = unreadAsync.maybeWhen(data: (v) => v, orElse: () => 0);

    return OpenVtsRoleHome(
      displayName: user?.name.isNotEmpty == true ? user!.name : 'Admin',
      roleLabel: 'Admin',
      profileImageUrl: resolveProfileImageUrl(baseUrl, user?.profileUrl),
      items: _items,
      onToggleTheme: () => ref.read(themeModeProvider.notifier).toggle(),
      notificationBadgeCount: unreadCount,
      onNotificationsPressed: () {
        ref.invalidate(adminNotificationUnreadBadgeProvider);
        context.push(RoutePaths.adminNotifications);
      },
      onProfilePressed: () => context.push(RoutePaths.adminProfile),
    );
  }
}
