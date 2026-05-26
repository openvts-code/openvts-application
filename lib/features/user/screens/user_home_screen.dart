import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/core_providers.dart';
import '../../../core/router/route_paths.dart';
import '../../../shared/widgets/open_vts_role_home.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/user_providers.dart';

class UserHomeScreen extends ConsumerWidget {
  const UserHomeScreen({super.key});

  static const _items = [
    OpenVtsRoleHomeItem(
      label: 'Dashboard',
      icon: Icons.bar_chart_outlined,
      route: RoutePaths.userDashboard,
    ),
    OpenVtsRoleHomeItem(
      label: 'Vehicles',
      icon: Icons.sync_alt_rounded,
      route: RoutePaths.userVehicles,
    ),
    OpenVtsRoleHomeItem(
      label: 'Maps',
      icon: Icons.map_outlined,
      route: RoutePaths.userMap,
    ),
    OpenVtsRoleHomeItem(
      label: 'Landmarks Studio',
      icon: Icons.place_outlined,
      route: RoutePaths.userLandmarksStudio,
    ),
    OpenVtsRoleHomeItem(
      label: 'Track Links',
      icon: Icons.share_outlined,
      route: RoutePaths.userTrackLinks,
    ),
    OpenVtsRoleHomeItem(
      label: 'Route Optimisation',
      icon: Icons.alt_route_outlined,
      route: RoutePaths.userRouteOptimisation,
    ),
    OpenVtsRoleHomeItem(
      label: 'Support',
      icon: Icons.help_outline_rounded,
      route: RoutePaths.userSupport,
    ),
    OpenVtsRoleHomeItem(
      label: 'Transactions',
      icon: Icons.receipt_long_outlined,
      route: RoutePaths.userTransactions,
    ),
    OpenVtsRoleHomeItem(
      label: 'Settings',
      icon: Icons.settings_outlined,
      route: RoutePaths.userSettings,
    ),
    OpenVtsRoleHomeItem(
      label: 'Accounts',
      icon: Icons.people_outline_rounded,
      route: RoutePaths.userAccounts,
    ),
    OpenVtsRoleHomeItem(
      label: 'Notifications',
      icon: Icons.notifications_none_rounded,
      route: RoutePaths.userNotifications,
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final user = authState.user;
    final baseUrl = ref.watch(apiBaseUrlProvider);
    final unreadAsync = ref.watch(userNotificationUnreadBadgeProvider);
    final unreadCount = unreadAsync.maybeWhen(data: (v) => v, orElse: () => 0);

    return OpenVtsRoleHome(
      displayName: user?.name.isNotEmpty == true ? user!.name : 'User',
      roleLabel: 'User',
      profileImageUrl: resolveProfileImageUrl(baseUrl, user?.profileUrl),
      items: _items,
      onToggleTheme: () => ref.read(themeModeProvider.notifier).toggle(),
      notificationBadgeCount: unreadCount,
      onNotificationsPressed: () {
        ref.invalidate(userNotificationUnreadBadgeProvider);
        context.push(RoutePaths.userNotificationCenter);
      },
      onProfilePressed: () => context.push(RoutePaths.userProfile),
    );
  }
}
