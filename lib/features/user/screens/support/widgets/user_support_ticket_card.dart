import 'package:flutter/material.dart';
import 'package:open_vts/core/theme/open_vts_colors.dart';
import 'package:open_vts/core/theme/open_vts_radius.dart';
import 'package:open_vts/core/theme/open_vts_spacing.dart';
import 'package:open_vts/core/theme/open_vts_typography.dart';
import 'package:open_vts/core/utils/date_time_formatter.dart';
import 'package:open_vts/features/user/models/user_support_model.dart';
import 'package:open_vts/shared/widgets/open_vts_card.dart';

const DateTimeFormatter _dateFormatter = DateTimeFormatter();

class UserSupportTicketCard extends StatelessWidget {
  const UserSupportTicketCard({
    required this.ticket,
    this.onTap,
    this.isSelected = false,
    this.lastMessagePreview,
    this.showUnreadIndicator = false,
    super.key,
  });

  final UserSupportTicketListItem ticket;
  final VoidCallback? onTap;
  final bool isSelected;
  final String? lastMessagePreview;
  final bool showUnreadIndicator;

  @override
  Widget build(BuildContext context) {
    final activityDate =
        ticket.lastMessageAt ?? ticket.updatedAt ?? ticket.createdAt;
    final preview = lastMessagePreview?.trim();

    return OpenVtsCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(
        horizontal: OpenVtsSpacing.sm,
        vertical: OpenVtsSpacing.xs,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: BorderDirectional(
            start: BorderSide(
              color: isSelected ? OpenVtsColors.brandInk : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsetsDirectional.only(start: OpenVtsSpacing.xs),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      ticket.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: OpenVtsTypography.body.copyWith(
                        color: OpenVtsColors.textPrimary,
                        fontWeight: FontWeight.w800,
                        height: 1.25,
                      ),
                    ),
                  ),
                  if (showUnreadIndicator) ...[
                    const SizedBox(width: OpenVtsSpacing.xs),
                    const _UnreadDot(),
                  ],
                ],
              ),
              const SizedBox(height: OpenVtsSpacing.xs),
              Wrap(
                spacing: OpenVtsSpacing.xs,
                runSpacing: OpenVtsSpacing.xxs,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _PlainMeta(label: ticket.displayTicketNo),
                  _StatusChip(status: ticket.status),
                  _PriorityChip(priority: ticket.priority),
                  _PlainMeta(label: ticket.category.label),
                ],
              ),
              if (preview != null && preview.isNotEmpty) ...[
                const SizedBox(height: OpenVtsSpacing.xs),
                Text(
                  preview,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: OpenVtsTypography.meta.copyWith(
                    color: OpenVtsColors.textSecondary,
                    height: 1.35,
                  ),
                ),
              ],
              const SizedBox(height: OpenVtsSpacing.xs),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      activityDate == null
                          ? 'No activity yet'
                          : _dateFormatter.formatDateTime(activityDate),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: OpenVtsTypography.meta.copyWith(
                        color: OpenVtsColors.textTertiary,
                      ),
                    ),
                  ),
                  const SizedBox(width: OpenVtsSpacing.xs),
                  Text(
                    '${ticket.messageCount} ${ticket.messageCount == 1 ? 'msg' : 'msgs'}',
                    style: OpenVtsTypography.meta.copyWith(
                      color: OpenVtsColors.textTertiary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final UserSupportTicketStatus status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      UserSupportTicketStatus.open => OpenVtsColors.success,
      UserSupportTicketStatus.inProgress => OpenVtsColors.info,
      UserSupportTicketStatus.closed => OpenVtsColors.textTertiary,
    };

    return _SoftChip(label: status.label, color: color);
  }
}

class _PriorityChip extends StatelessWidget {
  const _PriorityChip({required this.priority});

  final UserSupportTicketPriority priority;

  @override
  Widget build(BuildContext context) {
    final color = switch (priority) {
      UserSupportTicketPriority.high => OpenVtsColors.warning,
      UserSupportTicketPriority.medium => OpenVtsColors.info,
      UserSupportTicketPriority.low => OpenVtsColors.textTertiary,
    };

    return _SoftChip(label: priority.label, color: color);
  }
}

class _SoftChip extends StatelessWidget {
  const _SoftChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: OpenVtsSpacing.xs,
        vertical: OpenVtsSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        border: Border.all(color: color.withValues(alpha: 0.22)),
        borderRadius: BorderRadius.circular(OpenVtsRadius.pill),
      ),
      child: Text(
        label,
        style: OpenVtsTypography.meta.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _PlainMeta extends StatelessWidget {
  const _PlainMeta({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: OpenVtsSpacing.xs,
        vertical: OpenVtsSpacing.xxs,
      ),
      decoration: BoxDecoration(
        border: Border.all(color: OpenVtsColors.border),
        borderRadius: BorderRadius.circular(OpenVtsRadius.pill),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: OpenVtsTypography.meta.copyWith(
          color: OpenVtsColors.textSecondary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _UnreadDot extends StatelessWidget {
  const _UnreadDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      margin: const EdgeInsets.only(top: 6),
      decoration: const BoxDecoration(
        color: OpenVtsColors.brandInk,
        shape: BoxShape.circle,
      ),
    );
  }
}
