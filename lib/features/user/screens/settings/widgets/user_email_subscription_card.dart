import 'package:flutter/material.dart';

import '../../../../../core/theme/open_vts_colors.dart';
import '../../../../../core/theme/open_vts_spacing.dart';
import '../../../../../core/theme/open_vts_typography.dart';
import '../../../../../shared/widgets/open_vts_button.dart';
import '../../../../../shared/widgets/open_vts_card.dart';
import '../../../../../shared/widgets/open_vts_status_chip.dart';
import '../../../models/user_settings_model.dart';

class UserEmailSubscriptionCard extends StatelessWidget {
  const UserEmailSubscriptionCard({
    required this.subscription,
    required this.isLoading,
    required this.isSubscribing,
    required this.errorMessage,
    required this.onRefresh,
    required this.onSubscribe,
    super.key,
  });

  final UserEmailSubscriptionStatus? subscription;
  final bool isLoading;
  final bool isSubscribing;
  final String? errorMessage;
  final VoidCallback onRefresh;
  final VoidCallback onSubscribe;

  @override
  Widget build(BuildContext context) {
    final status = subscription;
    final isSubscribed = status?.isSubscribed ?? false;

    return OpenVtsCard(
      padding: const EdgeInsets.all(OpenVtsSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Email Subscription',
                  style: OpenVtsTypography.label.copyWith(
                    color: OpenVtsColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Refresh status',
                onPressed: isLoading ? null : onRefresh,
                iconSize: 16,
                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                icon: isLoading
                    ? const SizedBox.square(
                        dimension: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
          const SizedBox(height: OpenVtsSpacing.xxs),
          if (status == null && isLoading)
            Text(
              'Loading subscription status...',
              style: OpenVtsTypography.meta.copyWith(
                color: OpenVtsColors.textSecondary,
              ),
            )
          else ...[
            OpenVtsStatusChip(
              label: isSubscribed ? 'Subscribed' : 'Not subscribed',
              type: isSubscribed
                  ? OpenVtsStatusType.success
                  : OpenVtsStatusType.neutral,
            ),
            const SizedBox(height: OpenVtsSpacing.xs),
            Text(
              isSubscribed
                  ? 'You are subscribed to profile email notifications.'
                  : 'Subscribe to receive profile and account email updates.',
              style: OpenVtsTypography.meta.copyWith(
                color: OpenVtsColors.textSecondary,
              ),
            ),
            if (!isSubscribed) ...[
              const SizedBox(height: OpenVtsSpacing.xs),
              SizedBox(
                width: 150,
                child: OpenVtsButton(
                  label: 'Subscribe',
                  height: 44,
                  isLoading: isSubscribing,
                  onPressed: isSubscribing ? null : onSubscribe,
                ),
              ),
            ],
          ],
          if (errorMessage != null && errorMessage!.trim().isNotEmpty) ...[
            const SizedBox(height: OpenVtsSpacing.xs),
            Text(
              errorMessage!,
              style: OpenVtsTypography.meta.copyWith(
                color: OpenVtsColors.warning,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
