import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/helpers/toast_helper.dart';
import '../../../../shared/widgets/open_vts_page_scaffold.dart';
import '../../../notifications/widgets/notification_center_view.dart';
import '../../controllers/admin_providers.dart';

class AdminNotificationsScreen extends ConsumerWidget {
  const AdminNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(adminNotificationCenterProvider);
    final controller = ref.read(adminNotificationCenterProvider.notifier);

    return OpenVtsPageScaffold(
      title: 'Notifications',
      headerMode: OpenVtsPageHeaderMode.closeable,
      body: NotificationCenterView(
        state: state,
        onRefresh: controller.refresh,
        onRetry: controller.load,
        onLoadMore: controller.loadMore,
        onUnreadOnlyChanged: controller.setUnreadOnly,
        onMarkAllAsRead: () async {
          try {
            final unreadCount = ref.read(
              adminNotificationCenterProvider.select((value) => value.unreadCount),
            );
            await controller.markAllAsRead();
            if (unreadCount > 0) {
              ToastHelper.showSuccess('All notifications marked as read.');
            }
          } catch (_) {
            final message = ref.read(
                  adminNotificationCenterProvider.select(
                    (value) => value.errorMessage,
                  ),
                ) ??
                'Unable to mark notifications as read.';
            ToastHelper.showError(message);
          }
        },
        onMarkAsRead: (id) async {
          try {
            await controller.markAsRead(id);
          } catch (_) {
            final message = ref.read(
                  adminNotificationCenterProvider.select(
                    (value) => value.errorMessage,
                  ),
                ) ??
                'Unable to mark this notification as read.';
            ToastHelper.showError(message);
          }
        },
      ),
    );
  }
}
