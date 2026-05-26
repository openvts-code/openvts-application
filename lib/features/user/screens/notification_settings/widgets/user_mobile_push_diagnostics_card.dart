import 'package:flutter/material.dart';

import '../../../../../core/notifications/mobile_push_state.dart';
import '../../../../../core/theme/open_vts_colors.dart';
import '../../../../../core/theme/open_vts_radius.dart';
import '../../../../../core/theme/open_vts_spacing.dart';
import '../../../../../core/theme/open_vts_typography.dart';
import '../../../../../shared/widgets/open_vts_card.dart';

const String _mobilePushTestTooltip =
    'Initializes mobile push, registers this device token, and sends a test notification.';

class UserMobilePushDiagnosticsCard extends StatelessWidget {
  const UserMobilePushDiagnosticsCard({
    required this.state,
    required this.showActions,
    required this.onRetryRegistration,
    required this.onSendTestNotification,
    super.key,
  });

  final MobilePushState state;
  final bool showActions;
  final VoidCallback? onRetryRegistration;
  final VoidCallback? onSendTestNotification;

  @override
  Widget build(BuildContext context) {
    final lastError = _friendlyMobilePushError(state.lastError);

    return OpenVtsCard(
      padding: EdgeInsets.zero,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(
            horizontal: OpenVtsSpacing.xs,
            vertical: 2,
          ),
          childrenPadding: const EdgeInsets.fromLTRB(
            OpenVtsSpacing.xs,
            0,
            OpenVtsSpacing.xs,
            OpenVtsSpacing.xs,
          ),
          leading: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: OpenVtsColors.surface,
              borderRadius: BorderRadius.circular(OpenVtsRadius.sm),
              border: Border.all(color: OpenVtsColors.border),
            ),
            child: const Icon(
              Icons.phone_android_rounded,
              size: 15,
              color: OpenVtsColors.textSecondary,
            ),
          ),
          title: Text(
            'Mobile Push Diagnostics',
            style: OpenVtsTypography.meta.copyWith(
              color: OpenVtsColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          subtitle: Text(
            '${state.platform.apiValue} - ${state.permissionStatus ?? 'permission unknown'}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: OpenVtsTypography.meta.copyWith(
              color: OpenVtsColors.textTertiary,
            ),
          ),
          children: [
            Wrap(
              spacing: OpenVtsSpacing.xs,
              runSpacing: OpenVtsSpacing.xs,
              children: [
                _DiagnosticPill(
                  label: 'Platform',
                  value: state.platform.apiValue,
                ),
                _DiagnosticPill(
                  label: 'Current step',
                  value: _testStepLabel(state.testStep),
                ),
                _DiagnosticPill(
                  label: 'Firebase initialized',
                  value: state.isInitialized ? 'yes' : 'no',
                ),
                _DiagnosticPill(
                  label: 'Permission',
                  value: _fallback(state.permissionStatus, 'unknown'),
                ),
                _DiagnosticPill(
                  label: 'FCM token last 10',
                  value: _fallback(state.fcmTokenLast10, 'not cached'),
                ),
                _DiagnosticPill(
                  label: 'Registered token last 10',
                  value: _fallback(state.registeredTokenLast10, 'not set'),
                ),
                _DiagnosticPill(
                  label: 'Backend tokens',
                  value:
                      state.registeredTokenCount?.toString() ?? 'not checked',
                ),
                _DiagnosticPill(
                  label: 'Backend verified',
                  value: _backendVerifiedLabel(
                    state.currentTokenVerifiedByBackend,
                    state.registeredTokenCount,
                  ),
                ),
                _DiagnosticPill(
                  label: 'Last checked',
                  value: _formatCheckedAt(state.tokenDiagnosticsUpdatedAt),
                ),
              ],
            ),
            if (lastError != null) ...[
              const SizedBox(height: OpenVtsSpacing.xs),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(OpenVtsSpacing.xs),
                decoration: BoxDecoration(
                  color: OpenVtsColors.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(OpenVtsRadius.sm),
                  border: Border.all(
                    color: OpenVtsColors.error.withValues(alpha: 0.24),
                  ),
                ),
                child: Text(
                  lastError,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: OpenVtsTypography.meta.copyWith(
                    color: OpenVtsColors.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
            if (showActions) ...[
              const SizedBox(height: OpenVtsSpacing.xs),
              Wrap(
                spacing: OpenVtsSpacing.xs,
                runSpacing: OpenVtsSpacing.xs,
                children: [
                  _CompactDiagnosticButton(
                    icon: Icons.sync_rounded,
                    label: 'Retry registration',
                    onTap: onRetryRegistration,
                  ),
                  _CompactDiagnosticButton(
                    icon: Icons.send_to_mobile_rounded,
                    label: 'Send test',
                    tooltip: _mobilePushTestTooltip,
                    isLoading: state.isTesting,
                    onTap: onSendTestNotification,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _fallback(String? value, String fallback) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) {
      return fallback;
    }

    return normalized;
  }

  String _backendVerifiedLabel(bool? value, int? count) {
    if (value == null) {
      return 'not checked';
    }

    final suffix = count == null ? '' : ' ($count)';
    return value ? 'yes$suffix' : 'no$suffix';
  }

  String _testStepLabel(MobilePushTestStep step) {
    switch (step) {
      case MobilePushTestStep.idle:
        return 'Idle';
      case MobilePushTestStep.initializingFirebase:
        return 'Initializing Firebase';
      case MobilePushTestStep.checkingPermission:
        return 'Checking permission';
      case MobilePushTestStep.generatingToken:
        return 'Generating token';
      case MobilePushTestStep.registeringToken:
        return 'Registering token';
      case MobilePushTestStep.verifyingBackendToken:
        return 'Verifying backend token';
      case MobilePushTestStep.sendingBackendTest:
        return 'Sending backend test';
      case MobilePushTestStep.completed:
        return 'Completed';
      case MobilePushTestStep.failed:
        return 'Failed';
    }
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

  String _formatCheckedAt(DateTime? value) {
    if (value == null) {
      return 'not checked';
    }

    final local = value.toLocal();
    final now = DateTime.now();
    final time = '${_twoDigits(local.hour)}:${_twoDigits(local.minute)}';
    if (local.year == now.year &&
        local.month == now.month &&
        local.day == now.day) {
      return time;
    }

    return '${local.month}/${local.day} $time';
  }

  String _twoDigits(int value) {
    if (value >= 10) {
      return value.toString();
    }

    return '0$value';
  }
}

class _DiagnosticPill extends StatelessWidget {
  const _DiagnosticPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 34),
      padding: const EdgeInsets.symmetric(
        horizontal: OpenVtsSpacing.xs,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: OpenVtsColors.surfaceElevated,
        borderRadius: BorderRadius.circular(OpenVtsRadius.sm),
        border: Border.all(color: OpenVtsColors.border),
      ),
      child: RichText(
        text: TextSpan(
          style: OpenVtsTypography.meta.copyWith(
            color: OpenVtsColors.textSecondary,
          ),
          children: [
            TextSpan(text: '$label: '),
            TextSpan(
              text: value,
              style: const TextStyle(
                color: OpenVtsColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompactDiagnosticButton extends StatelessWidget {
  const _CompactDiagnosticButton({
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
        height: 40,
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
