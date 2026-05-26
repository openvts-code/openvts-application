import 'package:flutter/material.dart';
import 'package:open_vts/core/theme/open_vts_colors.dart';
import 'package:open_vts/core/theme/open_vts_spacing.dart';
import 'package:open_vts/core/theme/open_vts_typography.dart';
import 'package:open_vts/shared/widgets/open_vts_card.dart';
import 'open_vts_support_chips.dart';

class OpenVtsSupportTicketCard extends StatelessWidget {
  const OpenVtsSupportTicketCard({
    required this.title,
    required this.ticketNumber,
    required this.statusLabel,
    required this.statusColor,
    required this.priorityLabel,
    required this.priorityColor,
    required this.categoryLabel,
    this.extraMetaLabels = const <String>[],
    required this.dateLabel,
    this.messageCountLabel,
    this.preview,
    this.isSelected = false,
    this.onTap,
    super.key,
  });

  final String title;
  final String ticketNumber;
  final String statusLabel;
  final Color statusColor;
  final String priorityLabel;
  final Color priorityColor;
  final String categoryLabel;
  final List<String> extraMetaLabels;
  final String dateLabel;
  final String? messageCountLabel;
  final String? preview;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
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
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: OpenVtsTypography.body.copyWith(
                        color: OpenVtsColors.textPrimary,
                        fontWeight: FontWeight.w800,
                        height: 1.25,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: OpenVtsSpacing.xs),
              Wrap(
                spacing: OpenVtsSpacing.xs,
                runSpacing: OpenVtsSpacing.xxs,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  OpenVtsSupportPlainChip(label: ticketNumber),
                  OpenVtsSupportSoftChip(label: statusLabel, color: statusColor),
                  OpenVtsSupportSoftChip(label: priorityLabel, color: priorityColor),
                  OpenVtsSupportPlainChip(label: categoryLabel),
                  for (final meta in extraMetaLabels) OpenVtsSupportPlainChip(label: meta),
                ],
              ),
              if (preview != null && preview!.trim().isNotEmpty) ...[
                const SizedBox(height: OpenVtsSpacing.xs),
                Text(
                  preview!.trim(),
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
                      dateLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: OpenVtsTypography.meta.copyWith(
                        color: OpenVtsColors.textTertiary,
                      ),
                    ),
                  ),
                  if (messageCountLabel != null) ...[
                    const SizedBox(width: OpenVtsSpacing.xs),
                    Text(
                      messageCountLabel!,
                      style: OpenVtsTypography.meta.copyWith(
                        color: OpenVtsColors.textTertiary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
