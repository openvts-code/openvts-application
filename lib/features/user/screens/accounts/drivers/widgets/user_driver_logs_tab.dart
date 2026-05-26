import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../../core/theme/open_vts_colors.dart';
import '../../../../../../core/theme/open_vts_radius.dart';
import '../../../../../../core/theme/open_vts_spacing.dart';
import '../../../../../../core/theme/open_vts_typography.dart';
import '../../../../../../core/utils/date_time_formatter.dart';
import '../../../../../../shared/widgets/open_vts_button.dart';
import '../../../../../../shared/widgets/open_vts_card.dart';
import '../../../../../../shared/widgets/open_vts_empty_state.dart';
import '../../../../controllers/user_driver_details_controller.dart';
import '../../../../models/user_driver_model.dart';
import '../../../../models/user_drivers_state.dart';

const DateTimeFormatter _dateFormatter = DateTimeFormatter();

class UserDriverLogsTab extends ConsumerWidget {
  const UserDriverLogsTab({required this.provider, super.key});

  final AutoDisposeStateNotifierProvider<UserDriverDetailsController,
      UserDriverDetailsState> provider;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(provider);
    final controller = ref.read(provider.notifier);
    final isInitialLoading = state.isLoadingLogs && state.logs.isEmpty;

    if (isInitialLoading) {
      return const _LoadingCard(label: 'Loading logs');
    }

    if (state.errorMessage != null && state.logs.isEmpty) {
      return _ErrorCard(
        message: state.errorMessage!,
        onRetry: controller.loadLogs,
      );
    }

    if (state.logs.isEmpty) {
      return const OpenVtsCard(
        padding: EdgeInsets.all(OpenVtsSpacing.md),
        child: OpenVtsEmptyState(
          title: 'No activity logs',
          message: 'Driver assignment and profile activity will appear here.',
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (state.errorMessage != null) ...[
          _InlineError(message: state.errorMessage!),
          const SizedBox(height: OpenVtsSpacing.sm),
        ],
        for (final log in state.logs) ...[
          _LogCard(log: log),
          if (log != state.logs.last) const SizedBox(height: OpenVtsSpacing.sm),
        ],
      ],
    );
  }
}

class _LogCard extends StatelessWidget {
  const _LogCard({required this.log});

  final UserDriverLog log;

  @override
  Widget build(BuildContext context) {
    final title = _activityLabel(log.activity);
    final vehicle = _vehicleLabel(log.vehicle);
    final actor = log.actorName.trim().isEmpty ? '-' : log.actorName.trim();

    return OpenVtsCard(
      padding: const EdgeInsets.all(OpenVtsSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: OpenVtsColors.surface,
              borderRadius: BorderRadius.circular(OpenVtsRadius.sm),
              border: Border.all(color: OpenVtsColors.border),
            ),
            child: Icon(
              _activityIcon(log.activity),
              size: 17,
              color: OpenVtsColors.textSecondary,
            ),
          ),
          const SizedBox(width: OpenVtsSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: OpenVtsTypography.label.copyWith(
                    color: OpenVtsColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _message(log),
                  style: OpenVtsTypography.meta.copyWith(
                    color: OpenVtsColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: OpenVtsSpacing.xs),
                Wrap(
                  spacing: OpenVtsSpacing.xs,
                  runSpacing: OpenVtsSpacing.xs,
                  children: [
                    _MetaPill(
                      icon: Icons.directions_car_outlined,
                      label: vehicle,
                    ),
                    _MetaPill(
                      icon: Icons.person_outline_rounded,
                      label: actor,
                    ),
                    _MetaPill(
                      icon: Icons.schedule_rounded,
                      label: _dateTimeText(log.createdAt),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 280),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: OpenVtsColors.textSecondary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(OpenVtsRadius.pill),
        border: Border.all(
          color: OpenVtsColors.textSecondary.withValues(alpha: 0.16),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: OpenVtsColors.textSecondary),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: OpenVtsTypography.meta.copyWith(
                color: OpenVtsColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return OpenVtsCard(
      padding: const EdgeInsets.all(OpenVtsSpacing.sm),
      child: Row(
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: OpenVtsSpacing.sm),
          Text(
            label,
            style: OpenVtsTypography.meta.copyWith(
              color: OpenVtsColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return OpenVtsCard(
      padding: const EdgeInsets.all(OpenVtsSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            message,
            style: OpenVtsTypography.meta.copyWith(
              color: OpenVtsColors.error,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: OpenVtsSpacing.sm),
          OpenVtsButton(
            label: 'Retry',
            height: 36,
            variant: OpenVtsButtonVariant.secondary,
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(OpenVtsSpacing.sm),
      decoration: BoxDecoration(
        color: OpenVtsColors.error.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(OpenVtsRadius.sm),
        border: Border.all(color: OpenVtsColors.error.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 16,
            color: OpenVtsColors.error,
          ),
          const SizedBox(width: OpenVtsSpacing.xs),
          Expanded(
            child: Text(
              message,
              style: OpenVtsTypography.meta.copyWith(
                color: OpenVtsColors.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _message(UserDriverLog log) {
  final message = log.message.trim();
  if (message.isNotEmpty && message != '-') {
    return message;
  }
  return _activityLabel(log.activity);
}

String _activityLabel(String value) {
  final normalized = value.trim();
  if (normalized.isEmpty) {
    return 'Activity';
  }

  final withSpaces = normalized
      .replaceAll('_', ' ')
      .replaceAll('-', ' ')
      .replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (match) {
    return '${match.group(1)} ${match.group(2)}';
  });

  return withSpaces
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty)
      .map((word) =>
          '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}')
      .join(' ');
}

IconData _activityIcon(String activity) {
  final upper = activity.trim().toUpperCase();
  if (upper.contains('ASSIGN') || upper.contains('LINK')) {
    return Icons.link_rounded;
  }
  if (upper.contains('UNASSIGN') || upper.contains('UNLINK')) {
    return Icons.link_off_rounded;
  }
  if (upper.contains('DELETE') || upper.contains('REMOVE')) {
    return Icons.delete_outline_rounded;
  }
  if (upper.contains('UPDATE') || upper.contains('EDIT')) {
    return Icons.edit_outlined;
  }
  if (upper.contains('UPLOAD') || upper.contains('DOCUMENT')) {
    return Icons.description_outlined;
  }
  return Icons.history_rounded;
}

String _vehicleLabel(UserDriverVehicleMini? vehicle) {
  if (vehicle == null) {
    return '-';
  }

  final merged = [vehicle.name, vehicle.plateNumber]
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty && item != '-')
      .toList(growable: false)
      .join(' - ')
      .trim();

  if (merged.isEmpty) {
    return '-';
  }

  return merged;
}

String _dateTimeText(DateTime? value) {
  if (value == null) {
    return '-';
  }
  return _dateFormatter.formatDateTime(value.toLocal());
}
