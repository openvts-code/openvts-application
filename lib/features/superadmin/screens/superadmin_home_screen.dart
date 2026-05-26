import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/core_providers.dart';
import '../../../core/router/route_paths.dart';
import '../../../shared/widgets/open_vts_role_home.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/superadmin_providers.dart';

class SuperadminHomeScreen extends ConsumerWidget {
  const SuperadminHomeScreen({super.key});

  static const _items = [
    OpenVtsRoleHomeItem(
      label: 'Dashboard',
      icon: Icons.dashboard_outlined,
      route: RoutePaths.superadminDashboard,
    ),
    OpenVtsRoleHomeItem(
      label: 'Administrators',
      icon: Icons.admin_panel_settings_outlined,
      route: RoutePaths.superadminAdministrators,
    ),
    OpenVtsRoleHomeItem(
      label: 'Vehicles',
      icon: Icons.local_shipping_outlined,
      route: RoutePaths.superadminVehicles,
    ),
    OpenVtsRoleHomeItem(
      label: 'Map',
      icon: Icons.map_outlined,
      route: RoutePaths.superadminMap,
    ),
    OpenVtsRoleHomeItem(
      label: 'Calendar',
      icon: Icons.calendar_month_outlined,
      route: RoutePaths.superadminCalendar,
    ),
    OpenVtsRoleHomeItem(
      label: 'Server',
      icon: Icons.dns_outlined,
      route: RoutePaths.superadminServer,
    ),
    OpenVtsRoleHomeItem(
      label: 'Support',
      icon: Icons.support_agent_outlined,
      route: RoutePaths.superadminSupport,
    ),
    OpenVtsRoleHomeItem(
      label: 'Payments',
      icon: Icons.payments_outlined,
      route: RoutePaths.superadminPayments,
    ),
    OpenVtsRoleHomeItem(
      label: 'Settings',
      icon: Icons.settings_outlined,
      route: RoutePaths.superadminSettings,
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final user = authState.user;
    final baseUrl = ref.watch(apiBaseUrlProvider);
    final unreadAsync = ref.watch(superadminNotificationUnreadBadgeProvider);
    final unreadCount = unreadAsync.maybeWhen(data: (v) => v, orElse: () => 0);

    return OpenVtsRoleHome(
      displayName: user?.name.isNotEmpty == true ? user!.name : 'Super Admin',
      roleLabel: 'Superadmin',
      profileImageUrl: resolveProfileImageUrl(baseUrl, user?.profileUrl),
      items: _items,
      onToggleTheme: () => ref.read(themeModeProvider.notifier).toggle(),
      notificationBadgeCount: unreadCount,
      onNotificationsPressed: () {
        ref.invalidate(superadminNotificationUnreadBadgeProvider);
        context.push(RoutePaths.superadminNotifications);
      },
      onProfilePressed: () => context.push(RoutePaths.superadminProfile),
    );
  }
}
