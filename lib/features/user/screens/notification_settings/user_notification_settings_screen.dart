import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/notifications/mobile_push_state.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/theme/open_vts_colors.dart';
import '../../../../core/theme/open_vts_radius.dart';
import '../../../../core/theme/open_vts_spacing.dart';
import '../../../../core/theme/open_vts_typography.dart';
import '../../../../shared/helpers/toast_helper.dart';
import '../../../../shared/widgets/open_vts_button.dart';
import '../../../../shared/widgets/open_vts_card.dart';
import '../../../../shared/widgets/open_vts_empty_state.dart';
import '../../../../shared/widgets/open_vts_error_view.dart';
import '../../../../shared/widgets/open_vts_loader.dart';
import '../../../../shared/widgets/open_vts_page_scaffold.dart';
import '../../../auth/controllers/auth_controller.dart';
import '../../controllers/user_providers.dart';
import '../../models/user_notification_settings_model.dart';
import 'widgets/user_basic_notification_tab.dart';
import 'widgets/user_geofence_notification_tab.dart';
import 'widgets/user_mobile_push_diagnostics_card.dart';
import 'widgets/user_notification_group_tabs.dart';
import 'widgets/user_notification_save_bar.dart';
import 'widgets/user_notification_settings_header.dart';
import 'widgets/user_overspeed_notification_tab.dart';

const double _notificationSettingsMaxWidth = 920;
const String _mobilePushTestTooltip =
    'Initializes mobile push, registers this device token, and sends a test notification.';

class UserNotificationSettingsScreen extends ConsumerWidget {
  const UserNotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _NotificationSettingsDiagnosticsBootstrapper(
      child: _UserNotificationSettingsScreenBody(),
    );
  }
}

/// Triggers mobile push diagnostics fetches only when the Notification
/// Settings screen is mounted, so the GET /auth/push-tokens/me call never
/// runs as part of the cold-start path.
class _NotificationSettingsDiagnosticsBootstrapper
    extends ConsumerStatefulWidget {
  const _NotificationSettingsDiagnosticsBootstrapper({required this.child});

  final Widget child;

  @override
  ConsumerState<_NotificationSettingsDiagnosticsBootstrapper> createState() =>
      _NotificationSettingsDiagnosticsBootstrapperState();
}

class _NotificationSettingsDiagnosticsBootstrapperState
    extends ConsumerState<_NotificationSettingsDiagnosticsBootstrapper> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final controller = ref.read(mobilePushControllerProvider.notifier);
      unawaited(controller.refreshPermissionStatus());
      unawaited(controller.refreshTokenDiagnostics());
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _UserNotificationSettingsScreenBody extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(userNotificationSettingsControllerProvider);
    final controller =
        ref.read(userNotificationSettingsControllerProvider.notifier);
    final authState = ref.watch(authControllerProvider);
    final mobilePushState = ref.watch(mobilePushControllerProvider);
    final mobilePushController =
        ref.read(mobilePushControllerProvider.notifier);

    Future<void> handleSaveRequest() async {
      final before = ref.read(userNotificationSettingsControllerProvider);
      if (!before.isDirty || before.isSaving || before.isTesting) {
        return;
      }

      final previousSavedAt = before.lastSavedAt;
      await controller.save();
      final latest = ref.read(userNotificationSettingsControllerProvider);
      final error = latest.errorMessage?.trim();
      final didSave = latest.lastSavedAt != null &&
          latest.lastSavedAt != previousSavedAt &&
          (error == null || error.isEmpty);

      if (didSave) {
        ToastHelper.showSuccess('Notification settings saved successfully.');
        return;
      }

      if (error != null && error.isNotEmpty) {
        ToastHelper.showError(error);
      }
    }

    Future<void> handleMobilePushFullTest() async {
      final pushController = ref.read(mobilePushControllerProvider.notifier);
      final message = await pushController.sendTestNotification();
      if (message != null && message.trim().isNotEmpty) {
        ToastHelper.showSuccess(_mobilePushSuccessMessage(message));
        return;
      }

      final latest = ref.read(mobilePushControllerProvider);
      ToastHelper.showError(_mobilePushErrorMessage(latest));
    }

    Future<void> handleTestNotification() {
      return handleMobilePushFullTest();
    }

    Future<void> handleRefreshRequest() async {
      final before = ref.read(userNotificationSettingsControllerProvider);
      if (before.isLoading || before.isRefreshing) {
        return;
      }

      if (before.isDirty) {
        final shouldDiscard = await _showRefreshDiscardSheet(context);
        if (!shouldDiscard) {
          return;
        }

        await controller.refresh(discardUnsavedChanges: true);
      } else {
        await controller.refresh();
      }

      final latest = ref.read(userNotificationSettingsControllerProvider);
      final error = latest.errorMessage?.trim();
      if (error != null && error.isNotEmpty) {
        ToastHelper.showError(error);
      }
    }

    Future<void> handleMobilePushRetry() async {
      if (!authState.isAuthenticated) {
        return;
      }

      await mobilePushController
          .requestPermissionAndRegisterForCurrentSession();
      final latest = ref.read(mobilePushControllerProvider);
      final error = latest.lastError?.trim();
      if (error != null && error.isNotEmpty) {
        ToastHelper.showError(error);
        return;
      }

      ToastHelper.showSuccess('Mobile push registration retried.');
    }

    if (state.isLoading && !state.hasData) {
      return const OpenVtsPageScaffold(
        title: 'Notifications',
        headerMode: OpenVtsPageHeaderMode.closeable,
        body: OpenVtsLoader(),
      );
    }

    if (state.errorMessage != null && !state.hasData) {
      return OpenVtsPageScaffold(
        title: 'Notifications',
        headerMode: OpenVtsPageHeaderMode.closeable,
        body: OpenVtsErrorView(
          message: state.errorMessage!,
          onRetry: controller.load,
        ),
      );
    }

    final preferences = state.draftPreferences;
    if (preferences == null) {
      return const OpenVtsPageScaffold(
        title: 'Notifications',
        headerMode: OpenVtsPageHeaderMode.closeable,
        body: OpenVtsEmptyState(
          title: 'No notification settings found',
          message:
              'Try refreshing. If this persists, your account may not have notification preferences yet.',
        ),
      );
    }

    final selectedGroup = state.selectedTab;
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final showSaveBar = state.isDirty || state.isSaving;
    final listBottomPadding =
        showSaveBar ? (116.0 + keyboardInset) : OpenVtsSpacing.lg;
    final isMobilePushBusy =
        mobilePushState.isInitializing || mobilePushState.isTesting;

    Future<void> handleMenuAction(_SettingsMenuAction action) async {
      switch (action) {
        case _SettingsMenuAction.test:
          if (!isMobilePushBusy) {
            unawaited(handleTestNotification());
          }
          break;
        case _SettingsMenuAction.refresh:
          unawaited(handleRefreshRequest());
          break;
        case _SettingsMenuAction.reset:
          if (state.isDirty && !state.isSaving) {
            controller.reset();
          }
          break;
        case _SettingsMenuAction.save:
          if (state.isDirty && !state.isSaving && !state.isTesting) {
            unawaited(handleSaveRequest());
          }
          break;
      }
    }

    return OpenVtsPageScaffold(
      title: 'Notifications',
      headerMode: OpenVtsPageHeaderMode.closeable,
      padding: const EdgeInsets.fromLTRB(
        OpenVtsSpacing.sm,
        OpenVtsSpacing.xs,
        OpenVtsSpacing.sm,
        0,
      ),
      actions: [
        IconButton(
          tooltip: 'Refresh settings',
          onPressed: state.isRefreshing || state.isLoading
              ? null
              : () {
                  unawaited(handleRefreshRequest());
                },
          icon: state.isRefreshing
              ? const SizedBox.square(
                  dimension: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.refresh_rounded, size: 18),
        ),
        _SettingsActionMenu(
          onSelected: (action) {
            unawaited(handleMenuAction(action));
          },
          isDirty: state.isDirty,
          isSaving: state.isSaving,
          isTesting: state.isTesting || isMobilePushBusy,
          isRefreshing: state.isRefreshing,
          isLoading: state.isLoading,
        ),
      ],
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints:
                  const BoxConstraints(maxWidth: _notificationSettingsMaxWidth),
              child: Stack(
                children: [
                  RefreshIndicator(
                    onRefresh: handleRefreshRequest,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.only(bottom: listBottomPadding),
                      children: [
                        if (state.errorMessage != null)
                          Padding(
                            padding: const EdgeInsets.only(
                                bottom: OpenVtsSpacing.sm),
                            child: _InlineErrorBanner(
                              message: state.errorMessage!,
                              onDismiss: controller.clearError,
                            ),
                          ),
                        UserNotificationSettingsHeader(
                          vehicleCount: state.vehicleCount,
                          geofenceCount: state.geofenceCount,
                          isDirty: state.isDirty,
                          lastSavedAt: state.lastSavedAt,
                        ),
                        const SizedBox(height: OpenVtsSpacing.sm),
                        UserNotificationGroupTabs(
                          selectedGroup: selectedGroup,
                          onChanged: controller.setSelectedTab,
                        ),
                        const SizedBox(height: OpenVtsSpacing.sm),
                        _GroupActionsCard(
                          isTestNotifyLoading: mobilePushState.isTesting,
                          onTestNotify: isMobilePushBusy
                              ? null
                              : () {
                                  unawaited(handleTestNotification());
                                },
                          onRefresh: state.isLoading || state.isRefreshing
                              ? null
                              : () {
                                  unawaited(handleRefreshRequest());
                                },
                          onReset: state.isDirty && !state.isSaving
                              ? controller.reset
                              : null,
                        ),
                        const SizedBox(height: OpenVtsSpacing.sm),
                        UserMobilePushDiagnosticsCard(
                          state: mobilePushState,
                          showActions: authState.isAuthenticated,
                          onRetryRegistration: authState.isAuthenticated &&
                                  mobilePushState.isSupported &&
                                  !isMobilePushBusy
                              ? () {
                                  unawaited(handleMobilePushRetry());
                                }
                              : null,
                          onSendTestNotification:
                              authState.isAuthenticated && !isMobilePushBusy
                                  ? () {
                                      unawaited(handleTestNotification());
                                    }
                                  : null,
                        ),
                        const SizedBox(height: OpenVtsSpacing.sm),
                        switch (selectedGroup) {
                          UserNotificationGroup.basic =>
                            UserBasicNotificationTab(
                              preferences: preferences,
                              channelFlags: preferences.channels.flagsFor(
                                UserNotificationGroup.basic,
                              ),
                              onChannelChanged: (channel, value) {
                                controller.updateChannel(
                                  UserNotificationGroup.basic,
                                  channel,
                                  value,
                                );
                              },
                              onVehicleToggle: controller.updateBasicToggle,
                            ),
                          UserNotificationGroup.overspeed =>
                            UserOverspeedNotificationTab(
                              preferences: preferences,
                              channelFlags: preferences.channels.flagsFor(
                                UserNotificationGroup.overspeed,
                              ),
                              onChannelChanged: (channel, value) {
                                controller.updateChannel(
                                  UserNotificationGroup.overspeed,
                                  channel,
                                  value,
                                );
                              },
                              onOverspeedEnabledChanged:
                                  controller.updateOverspeedEnabled,
                              onSpeedLimitChanged:
                                  controller.updateOverspeedLimit,
                            ),
                          UserNotificationGroup.geofence =>
                            UserGeofenceNotificationTab(
                              preferences: preferences,
                              channelFlags: preferences.channels.flagsFor(
                                UserNotificationGroup.geofence,
                              ),
                              onChannelChanged: (channel, value) {
                                controller.updateChannel(
                                  UserNotificationGroup.geofence,
                                  channel,
                                  value,
                                );
                              },
                              onGeofenceToggle: controller.updateGeofenceToggle,
                            ),
                        },
                        const SizedBox(height: OpenVtsSpacing.sm),
                      ],
                    ),
                  ),
                  if (showSaveBar)
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: UserNotificationSaveBar(
                        isSaving: state.isSaving,
                        canSave: state.isDirty &&
                            !state.isSaving &&
                            !state.isTesting,
                        canReset: state.isDirty && !state.isSaving,
                        onSave: () {
                          unawaited(handleSaveRequest());
                        },
                        onReset: controller.reset,
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

String _mobilePushSuccessMessage(String message) {
  final normalized = message.trim();
  if (normalized == 'Mobile test notification sent.') {
    return 'Mobile test notification sent to this device.';
  }

  return normalized;
}

String _mobilePushErrorMessage(MobilePushState state) {
  if (state.tokenDiagnosticsUpdatedAt != null &&
      state.registeredTokenCount == 0 &&
      state.currentTokenVerifiedByBackend == false) {
    return 'No active mobile token found for this user/device.';
  }

  return _friendlyMobilePushError(state.lastError) ??
      'Unable to send mobile test notification right now.';
}

String? _friendlyMobilePushError(String? value) {
  final normalized = value?.trim();
  if (normalized == null || normalized.isEmpty) {
    return null;
  }

  final lower = normalized.toLowerCase();
  if (lower.contains('firebase') && lower.contains('config')) {
    return 'Firebase mobile config is missing. Ask superadmin to configure Android/iOS Firebase settings.';
  }
  if (lower.contains('permission')) {
    return 'Notification permission is not granted. Enable notifications for this app and try again.';
  }
  if (lower.contains('generate fcm token') || lower.contains('fcm token')) {
    if (lower.contains('backend') || lower.contains('registration')) {
      return 'Token generated, but backend registration failed.';
    }
    return 'Unable to generate FCM token for this device.';
  }
  if (lower.contains('registration failed') ||
      lower.contains('register this device')) {
    return 'Token generated, but backend registration failed.';
  }
  if (lower.contains('no active mobile token')) {
    return 'No active mobile token found for this user/device.';
  }
  if (lower.contains('not supported')) {
    return 'Mobile push is not supported on this platform.';
  }
  if (_looksLikeTechnicalMobilePushTrace(normalized)) {
    return 'Unable to send mobile test notification right now.';
  }

  return _sanitizeMobilePushErrorText(normalized);
}

bool _looksLikeTechnicalMobilePushTrace(String value) {
  final lower = value.toLowerCase();
  return lower.contains('\n#') ||
      lower.contains('stack trace') ||
      lower.contains('package:') ||
      lower.contains('dart-sdk') ||
      RegExp(r'(^|\n)\s*at\s+').hasMatch(value);
}

String _sanitizeMobilePushErrorText(String value) {
  final lower = value.toLowerCase();
  if (lower.contains('serviceaccountjson') ||
      lower.contains('service account json') ||
      lower.contains('service_account_json') ||
      lower.contains('private_key') ||
      lower.contains('privatekey') ||
      lower.contains('private key') ||
      lower.contains('-----begin private key-----')) {
    return 'Notification service credentials are misconfigured.';
  }

  final sanitized = value
      .replaceAll(RegExp(r'\s+'), ' ')
      .replaceAll(RegExp(r'[A-Za-z0-9_:-]{40,}'), '[redacted]')
      .trim();
  return sanitized.length > 220 ? sanitized.substring(0, 220) : sanitized;
}

enum _SettingsMenuAction { test, refresh, reset, save }

class _SettingsActionMenu extends StatelessWidget {
  const _SettingsActionMenu({
    required this.onSelected,
    required this.isDirty,
    required this.isSaving,
    required this.isTesting,
    required this.isRefreshing,
    required this.isLoading,
  });

  final ValueChanged<_SettingsMenuAction> onSelected;
  final bool isDirty;
  final bool isSaving;
  final bool isTesting;
  final bool isRefreshing;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_SettingsMenuAction>(
      tooltip: 'Notification actions',
      icon: const Icon(Icons.more_horiz_rounded, size: 20),
      onSelected: onSelected,
      itemBuilder: (context) => [
        PopupMenuItem<_SettingsMenuAction>(
          value: _SettingsMenuAction.test,
          enabled: !isTesting,
          child: _ActionMenuItem(
            icon: Icons.campaign_outlined,
            label: 'Test Mobile Push',
            tooltip: _mobilePushTestTooltip,
            isLoading: isTesting,
          ),
        ),
        PopupMenuItem<_SettingsMenuAction>(
          value: _SettingsMenuAction.refresh,
          enabled: !isRefreshing && !isLoading,
          child: const _ActionMenuItem(
            icon: Icons.refresh_rounded,
            label: 'Refresh',
          ),
        ),
        PopupMenuItem<_SettingsMenuAction>(
          value: _SettingsMenuAction.reset,
          enabled: isDirty && !isSaving,
          child: const _ActionMenuItem(
            icon: Icons.restart_alt_rounded,
            label: 'Reset',
          ),
        ),
        PopupMenuItem<_SettingsMenuAction>(
          value: _SettingsMenuAction.save,
          enabled: isDirty && !isSaving && !isTesting,
          child: const _ActionMenuItem(
            icon: Icons.save_outlined,
            label: 'Save Changes',
          ),
        ),
      ],
    );
  }
}

class _ActionMenuItem extends StatelessWidget {
  const _ActionMenuItem({
    required this.icon,
    required this.label,
    this.tooltip,
    this.isLoading = false,
  });

  final IconData icon;
  final String label;
  final String? tooltip;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final child = Row(
      children: [
        if (isLoading)
          const SizedBox.square(
            dimension: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        else
          Icon(
            icon,
            size: 16,
            color: OpenVtsColors.textSecondary,
          ),
        const SizedBox(width: OpenVtsSpacing.xs),
        Text(
          label,
          style: OpenVtsTypography.meta.copyWith(
            color: OpenVtsColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );

    final message = tooltip;
    if (message == null || message.trim().isEmpty) {
      return child;
    }

    return Tooltip(
      message: message,
      child: child,
    );
  }
}

class _GroupActionsCard extends StatelessWidget {
  const _GroupActionsCard({
    required this.isTestNotifyLoading,
    required this.onTestNotify,
    required this.onRefresh,
    required this.onReset,
  });

  final bool isTestNotifyLoading;
  final VoidCallback? onTestNotify;
  final VoidCallback? onRefresh;
  final VoidCallback? onReset;

  @override
  Widget build(BuildContext context) {
    return OpenVtsCard(
      padding: const EdgeInsets.all(OpenVtsSpacing.xs),
      child: Wrap(
        spacing: OpenVtsSpacing.xs,
        runSpacing: OpenVtsSpacing.xs,
        children: [
          _CompactActionChip(
            icon: Icons.campaign_outlined,
            label: 'Test Mobile Push',
            tooltip: _mobilePushTestTooltip,
            isLoading: isTestNotifyLoading,
            onTap: onTestNotify,
          ),
          _CompactActionChip(
            icon: Icons.refresh_rounded,
            label: 'Refresh',
            onTap: onRefresh,
          ),
          _CompactActionChip(
            icon: Icons.restart_alt_rounded,
            label: 'Reset',
            onTap: onReset,
          ),
        ],
      ),
    );
  }
}

class _CompactActionChip extends StatelessWidget {
  const _CompactActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
    this.tooltip,
    this.isLoading = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final String? tooltip;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null && !isLoading;
    final foregroundColor =
        disabled ? OpenVtsColors.textTertiary : OpenVtsColors.textSecondary;
    final child = InkWell(
      borderRadius: BorderRadius.circular(OpenVtsRadius.pill),
      onTap: isLoading ? null : onTap,
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: OpenVtsSpacing.xs),
        decoration: BoxDecoration(
          color:
              disabled ? OpenVtsColors.surface : OpenVtsColors.surfaceElevated,
          borderRadius: BorderRadius.circular(OpenVtsRadius.pill),
          border: Border.all(color: OpenVtsColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLoading)
              const SizedBox.square(
                dimension: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Icon(
                icon,
                size: 14,
                color: foregroundColor,
              ),
            const SizedBox(width: OpenVtsSpacing.xxs),
            Text(
              label,
              style: OpenVtsTypography.meta.copyWith(
                color: disabled
                    ? OpenVtsColors.textTertiary
                    : OpenVtsColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );

    final message = tooltip;
    if (message == null || message.trim().isEmpty) {
      return child;
    }

    return Tooltip(
      message: message,
      child: child,
    );
  }
}

class _InlineErrorBanner extends StatelessWidget {
  const _InlineErrorBanner({
    required this.message,
    required this.onDismiss,
  });

  final String message;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return OpenVtsCard(
      padding: const EdgeInsets.all(OpenVtsSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: Icon(
              Icons.error_outline_rounded,
              size: 14,
              color: OpenVtsColors.error,
            ),
          ),
          const SizedBox(width: OpenVtsSpacing.xs),
          Expanded(
            child: Text(
              message,
              style: OpenVtsTypography.meta.copyWith(
                color: OpenVtsColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: onDismiss,
            style: TextButton.styleFrom(
              minimumSize: const Size(44, 30),
              padding:
                  const EdgeInsets.symmetric(horizontal: OpenVtsSpacing.xs),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'Dismiss',
              style:
                  OpenVtsTypography.meta.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

Future<bool> _showRefreshDiscardSheet(BuildContext context) async {
  final shouldDiscard = await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) {
      return SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(OpenVtsSpacing.sm),
          child: OpenVtsCard(
            padding: const EdgeInsets.all(OpenVtsSpacing.sm),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Discard unsaved changes?',
                  style: OpenVtsTypography.label.copyWith(
                    color: OpenVtsColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: OpenVtsSpacing.xxs),
                Text(
                  'Refreshing will replace your current unsaved notification edits with the latest server settings.',
                  style: OpenVtsTypography.meta.copyWith(
                    color: OpenVtsColors.textSecondary,
                  ),
                ),
                const SizedBox(height: OpenVtsSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: OpenVtsButton(
                        label: 'Keep Editing',
                        height: 44,
                        variant: OpenVtsButtonVariant.secondary,
                        onPressed: () {
                          Navigator.of(context).pop(false);
                        },
                      ),
                    ),
                    const SizedBox(width: OpenVtsSpacing.xs),
                    Expanded(
                      child: OpenVtsButton(
                        label: 'Discard & Refresh',
                        height: 44,
                        onPressed: () {
                          Navigator.of(context).pop(true);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
  );

  return shouldDiscard ?? false;
}
