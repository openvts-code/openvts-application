import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/api/api_exception.dart';
import '../../../../../core/theme/open_vts_colors.dart';
import '../../../../../core/theme/open_vts_radius.dart';
import '../../../../../core/theme/open_vts_spacing.dart';
import '../../../../../core/theme/open_vts_typography.dart';
import '../../../../../shared/helpers/toast_helper.dart';
import '../../../../../shared/widgets/open_vts_bottom_sheet.dart';
import '../../../../../shared/widgets/open_vts_button.dart';
import '../../../controllers/user_providers.dart';
import '../../../models/user_share_track_link_model.dart';

class UserShareTrackLinkDeleteSheet extends ConsumerWidget {
  const UserShareTrackLinkDeleteSheet({
    required this.link,
    super.key,
  });

  final UserShareTrackLink link;

  static Future<T?> show<T>({
    required BuildContext context,
    required UserShareTrackLink link,
  }) {
    return OpenVtsBottomSheet.show<T>(
      context: context,
      title: 'Delete track link',
      initialChildSize: 0.42,
      minChildSize: 0.32,
      maxChildSize: 0.64,
      child: UserShareTrackLinkDeleteSheet(link: link),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(userShareTrackLinkControllerProvider);
    final endpointId = link.endpointId;
    final isDeleting = state.isDeleting(endpointId);
    final canDelete = endpointId.trim().isNotEmpty && !isDeleting;
    final uniqueCode =
        link.uniqueCode.trim().isEmpty ? '-' : link.uniqueCode.trim();
    final vehicleCount = link.vehicleCount;

    return ListView(
      controller: PrimaryScrollController.maybeOf(context),
      padding: const EdgeInsets.fromLTRB(
        OpenVtsSpacing.md,
        OpenVtsSpacing.md,
        OpenVtsSpacing.md,
        OpenVtsSpacing.md,
      ),
      children: [
        Container(
          padding: const EdgeInsets.all(OpenVtsSpacing.sm),
          decoration: BoxDecoration(
            color: OpenVtsColors.error.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(OpenVtsRadius.lg),
            border: Border.all(
              color: OpenVtsColors.error.withValues(alpha: 0.16),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                size: 20,
                color: OpenVtsColors.error,
              ),
              const SizedBox(width: OpenVtsSpacing.xs),
              Expanded(
                child: Text(
                  'This public tracking link will stop working immediately. This action cannot be undone.',
                  style: OpenVtsTypography.body.copyWith(
                    color: OpenVtsColors.error,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: OpenVtsSpacing.md),
        _DetailRow(
          label: 'Unique code',
          value: uniqueCode,
          icon: Icons.tag_rounded,
        ),
        const SizedBox(height: OpenVtsSpacing.xs),
        _DetailRow(
          label: 'Affected vehicles',
          value: '$vehicleCount ${vehicleCount == 1 ? 'vehicle' : 'vehicles'}',
          icon: Icons.directions_car_outlined,
        ),
        if (endpointId.trim().isEmpty) ...[
          const SizedBox(height: OpenVtsSpacing.sm),
          Text(
            'This link cannot be deleted because its id is missing.',
            style: OpenVtsTypography.meta.copyWith(
              color: OpenVtsColors.error,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
        const SizedBox(height: OpenVtsSpacing.md),
        Row(
          children: [
            Expanded(
              child: OpenVtsButton(
                label: 'Cancel',
                height: 40,
                variant: OpenVtsButtonVariant.secondary,
                onPressed:
                    isDeleting ? null : () => Navigator.of(context).pop(),
              ),
            ),
            const SizedBox(width: OpenVtsSpacing.sm),
            Expanded(
              child: _DeleteButton(
                isLoading: isDeleting,
                onPressed: canDelete ? () => _delete(context, ref) : null,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    try {
      await ref
          .read(userShareTrackLinkControllerProvider.notifier)
          .deleteLink(link);
      if (!context.mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!context.mounted) return;
      ToastHelper.showError(_errorMessage(error), context: context);
    }
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(OpenVtsSpacing.sm),
      decoration: BoxDecoration(
        color: OpenVtsColors.surfaceElevated,
        borderRadius: BorderRadius.circular(OpenVtsRadius.lg),
        border: Border.all(color: OpenVtsColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 17, color: OpenVtsColors.textSecondary),
          const SizedBox(width: OpenVtsSpacing.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: OpenVtsTypography.meta.copyWith(
                    color: OpenVtsColors.textTertiary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: OpenVtsTypography.label.copyWith(
                    color: OpenVtsColors.textPrimary,
                    fontFamily: label == 'Unique code' ? 'monospace' : null,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DeleteButton extends StatelessWidget {
  const _DeleteButton({required this.isLoading, required this.onPressed});

  final bool isLoading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: OpenVtsColors.error,
          foregroundColor: OpenVtsColors.white,
          disabledBackgroundColor: OpenVtsColors.surface,
          disabledForegroundColor: OpenVtsColors.textTertiary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(OpenVtsRadius.button),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.delete_outline_rounded, size: 18),
                  SizedBox(width: 6),
                  Text('Delete', style: OpenVtsTypography.label),
                ],
              ),
      ),
    );
  }
}

String _errorMessage(Object error) {
  if (error is ApiException) return error.message;

  if (error is DioException) {
    final responseMessage = _extractResponseMessage(error.response?.data);
    if (responseMessage != null) return responseMessage;
    final message = error.message?.trim();
    if (message != null && message.isNotEmpty) return message;
  }

  final raw = error.toString().trim();
  if (raw.startsWith('Exception: ')) {
    return raw.substring('Exception: '.length).trim();
  }
  if (raw.startsWith('ApiException')) {
    final parts = raw.split(':');
    if (parts.length > 1) return parts.sublist(1).join(':').trim();
  }
  return raw.isEmpty ? 'Unable to delete track link.' : raw;
}

String? _extractResponseMessage(dynamic data) {
  if (data is Map<String, dynamic>) {
    for (final key in const ['message', 'error']) {
      final value = data[key];
      if (value is String && value.trim().isNotEmpty) return value.trim();
      if (value is List) {
        final parts = value
            .whereType<String>()
            .map((item) => item.trim())
            .where((item) => item.isNotEmpty)
            .toList(growable: false);
        if (parts.isNotEmpty) return parts.join(', ');
      }
    }
    final nestedData = data['data'];
    if (!identical(nestedData, data)) {
      return _extractResponseMessage(nestedData);
    }
  }
  if (data is String && data.trim().isNotEmpty) return data.trim();
  return null;
}
