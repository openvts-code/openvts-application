import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/open_vts_colors.dart';
import '../../../../../core/theme/open_vts_spacing.dart';
import '../../../../../core/theme/open_vts_typography.dart';
import '../../../../../shared/widgets/open_vts_card.dart';
import '../../../../../shared/widgets/open_vts_empty_state.dart';
import '../../../../../shared/widgets/open_vts_error_view.dart';
import '../../../../../shared/widgets/open_vts_loader.dart';
import '../../../controllers/admin_calendar_controller.dart';
import '../../../models/admin_calendar_model.dart';

class AdminCalendarDayBottomSheet extends ConsumerWidget {
  const AdminCalendarDayBottomSheet({super.key, required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailsAsync = ref.watch(adminCalendarDayDetailsProvider(date));

    return detailsAsync.when(
      loading: () => const Center(child: OpenVtsLoader()),
      error: (err, stack) => Padding(
        padding: const EdgeInsets.all(OpenVtsSpacing.md),
        child: OpenVtsErrorView(
          message: 'Failed to load details',
          onRetry: () => ref.refresh(adminCalendarDayDetailsProvider(date)),
        ),
      ),
      data: (details) {
        if (details.isEmpty) {
          return const OpenVtsEmptyState(
            title: 'No Data',
            message: 'There are no events on this day',
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(
            OpenVtsSpacing.md,
            OpenVtsSpacing.md,
            OpenVtsSpacing.md,
            OpenVtsSpacing.lg,
          ),
          itemCount: details.length,
          separatorBuilder: (context, index) =>
              const SizedBox(height: OpenVtsSpacing.sm),
          itemBuilder: (context, index) =>
              _CalendarDayEventTile(detail: details[index]),
        );
      },
    );
  }
}

class _CalendarDayEventTile extends ConsumerWidget {
  const _CalendarDayEventTile({required this.detail});

  final AdminCalendarDayDetail detail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final linkedDetailAsync = detail.isUser
        ? ref.watch(adminCalendarUserDetailsProvider(detail.userId!))
        : detail.isVehicle
            ? ref.watch(adminCalendarVehicleDetailsProvider(detail.vehicleId!))
            : const AsyncValue<AdminCalendarLinkedDetail?>.data(null);

    final linkedDetail = linkedDetailAsync.asData?.value;
    final title = _resolveTitle(detail, linkedDetail);
    final subtitle = _resolveSubtitle(detail, linkedDetail);
    final metadata = linkedDetail?.metadata ?? const <String>[];

    return OpenVtsCard(
      padding: const EdgeInsets.all(OpenVtsSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _EventTypeIcon(type: detail.type),
          const SizedBox(width: OpenVtsSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: OpenVtsTypography.label.copyWith(
                          color: OpenVtsColors.textPrimary,
                        ),
                      ),
                    ),
                    if (detail.count > 1) _CountBadge(count: detail.count),
                  ],
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: OpenVtsTypography.meta.copyWith(
                      color: OpenVtsColors.textSecondary,
                    ),
                  ),
                ],
                if (metadata.isNotEmpty) ...[
                  const SizedBox(height: OpenVtsSpacing.xs),
                  for (final item in metadata.take(2))
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        item,
                        style: OpenVtsTypography.meta.copyWith(
                          color: OpenVtsColors.textTertiary,
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
          if (linkedDetailAsync.isLoading)
            const Padding(
              padding: EdgeInsetsDirectional.only(start: OpenVtsSpacing.sm),
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 1.6),
              ),
            ),
        ],
      ),
    );
  }

  String _resolveTitle(
    AdminCalendarDayDetail detail,
    AdminCalendarLinkedDetail? linkedDetail,
  ) {
    if (detail.title.trim().isNotEmpty &&
        detail.title != 'Users' &&
        detail.title != 'Vehicle') {
      return detail.title;
    }
    if (linkedDetail != null && linkedDetail.title.trim().isNotEmpty) {
      return linkedDetail.title;
    }
    return detail.title;
  }

  String _resolveSubtitle(
    AdminCalendarDayDetail detail,
    AdminCalendarLinkedDetail? linkedDetail,
  ) {
    if (detail.subtitle.trim().isNotEmpty) {
      return detail.subtitle;
    }
    return linkedDetail?.subtitle ?? '';
  }
}

class _EventTypeIcon extends StatelessWidget {
  const _EventTypeIcon({required this.type});

  final String type;

  @override
  Widget build(BuildContext context) {
    late final IconData icon;
    late final Color color;

    switch (type) {
      case 'vehicle':
        icon = Icons.directions_car_outlined;
        color = OpenVtsColors.success;
      case 'expiry':
        icon = Icons.warning_amber_rounded;
        color = OpenVtsColors.error;
      case 'users':
      default:
        icon = Icons.person_outline_rounded;
        color = OpenVtsColors.brandInk;
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, size: 18, color: color),
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: OpenVtsSpacing.sm,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: OpenVtsColors.brandInk.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$count',
        style: OpenVtsTypography.meta.copyWith(
          color: OpenVtsColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
