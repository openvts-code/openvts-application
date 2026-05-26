import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../../core/router/route_paths.dart';
import '../../../../../../core/theme/open_vts_colors.dart';
import '../../../../../../core/theme/open_vts_radius.dart';
import '../../../../../../core/theme/open_vts_spacing.dart';
import '../../../../../../core/theme/open_vts_typography.dart';
import '../../../../../../core/utils/date_time_formatter.dart';
import '../../../../../../shared/helpers/toast_helper.dart';
import '../../../../../../shared/widgets/open_vts_bottom_sheet.dart';
import '../../../../../../shared/widgets/open_vts_card.dart';
import '../../../../controllers/user_providers.dart';
import '../../../../controllers/user_subuser_details_controller.dart';
import '../../../../models/user_subuser_model.dart';
import '../../../../models/user_subusers_state.dart';
import 'user_subuser_delete_sheet.dart';
import 'user_subuser_edit_sheet.dart';

const DateTimeFormatter _dateFormatter = DateTimeFormatter();

typedef UserSubUserDetailsProvider = AutoDisposeStateNotifierProvider<
    UserSubUserDetailsController, UserSubUserDetailsState>;

class UserSubUserProfileTab extends ConsumerWidget {
  const UserSubUserProfileTab({
    required this.provider,
    super.key,
  });

  final UserSubUserDetailsProvider provider;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(provider);
    final controller = ref.read(provider.notifier);
    final subUser = state.subUser;

    if (subUser == null) {
      return _SectionStateCard(
        isLoading: state.isLoading,
        message: state.errorMessage,
        onRetry: controller.loadInitial,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ActionButtons(
          isSaving: state.isSaving,
          isTogglingStatus: state.isTogglingStatus,
          isDeleting: state.isDeleting,
          isActive: subUser.isActive,
          onEdit: () => _showEditSheet(context, subUser),
          onToggleStatus: () => _toggleStatus(context, ref, subUser),
          onDelete: () => _showDeleteSheet(context, ref, subUser),
        ),
        if (state.errorMessage != null) ...[
          const SizedBox(height: OpenVtsSpacing.sm),
          _InlineError(message: state.errorMessage!),
        ],
        const SizedBox(height: OpenVtsSpacing.sm),
        _InfoCard(
          title: 'Profile',
          icon: Icons.person_outline_rounded,
          rows: [
            _InfoRow(label: 'Name', value: _display(subUser.name)),
            _InfoRow(label: 'Username', value: _username(subUser.username)),
            _InfoRow(
              label: 'Status',
              value: subUser.isActive ? 'Active' : 'Inactive',
            ),
          ],
        ),
        const SizedBox(height: OpenVtsSpacing.sm),
        _InfoCard(
          title: 'Contact',
          icon: Icons.call_outlined,
          rows: [
            _InfoRow(label: 'Email', value: _display(subUser.email)),
            _InfoRow(label: 'Mobile', value: _mobile(subUser)),
          ],
        ),
        const SizedBox(height: OpenVtsSpacing.sm),
        _InfoCard(
          title: 'Timeline',
          icon: Icons.schedule_rounded,
          rows: [
            _InfoRow(label: 'Created', value: _dateText(subUser.createdAt)),
            _InfoRow(label: 'Updated', value: _dateText(subUser.updatedAt)),
          ],
        ),
      ],
    );
  }

  Future<void> _showEditSheet(BuildContext context, UserSubUser subUser) {
    return OpenVtsBottomSheet.show<bool>(
      context: context,
      title: 'Edit Sub User',
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.97,
      child: UserSubUserEditSheet(
        provider: provider,
        subUser: subUser,
      ),
    );
  }

  Future<void> _toggleStatus(
    BuildContext context,
    WidgetRef ref,
    UserSubUser subUser,
  ) async {
    final wasActive = subUser.isActive;
    final ok = await ref.read(provider.notifier).toggleStatus();
    if (!context.mounted) {
      return;
    }

    if (ok) {
      ToastHelper.showSuccess(
        wasActive ? 'Sub user deactivated.' : 'Sub user activated.',
        context: context,
      );
      return;
    }

    ToastHelper.showError(
      ref.read(provider).errorMessage ?? 'Unable to update status.',
      context: context,
    );
  }

  Future<void> _showDeleteSheet(
    BuildContext context,
    WidgetRef ref,
    UserSubUser subUser,
  ) async {
    final deleted = await OpenVtsBottomSheet.show<bool>(
      context: context,
      title: 'Delete Sub User',
      initialChildSize: 0.42,
      minChildSize: 0.34,
      maxChildSize: 0.62,
      child: UserSubUserDeleteSheet(
        provider: provider,
        subUser: subUser,
      ),
    );

    if (deleted != true || !context.mounted) {
      return;
    }

    await ref.read(userSubUsersControllerProvider.notifier).refresh();
    if (!context.mounted) {
      return;
    }

    ToastHelper.showSuccess('Sub user deleted.', context: context);
    context.go(RoutePaths.userSubUsers);
  }
}

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({
    required this.isSaving,
    required this.isTogglingStatus,
    required this.isDeleting,
    required this.isActive,
    required this.onEdit,
    required this.onToggleStatus,
    required this.onDelete,
  });

  final bool isSaving;
  final bool isTogglingStatus;
  final bool isDeleting;
  final bool isActive;
  final VoidCallback onEdit;
  final VoidCallback onToggleStatus;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: OpenVtsSpacing.xs,
      runSpacing: OpenVtsSpacing.xs,
      children: [
        _CompactActionButton(
          label: 'Edit Profile',
          icon: Icons.edit_outlined,
          isLoading: isSaving,
          onPressed: isSaving ? null : onEdit,
        ),
        _CompactActionButton(
          label: isActive ? 'Deactivate' : 'Activate',
          icon: isActive
              ? Icons.pause_circle_outline_rounded
              : Icons.check_circle_outline_rounded,
          isLoading: isTogglingStatus,
          onPressed: isTogglingStatus ? null : onToggleStatus,
        ),
        _CompactActionButton(
          label: 'Delete',
          icon: Icons.delete_outline_rounded,
          isDestructive: true,
          isLoading: isDeleting,
          onPressed: isDeleting ? null : onDelete,
        ),
      ],
    );
  }
}

class _CompactActionButton extends StatelessWidget {
  const _CompactActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.isLoading = false,
    this.isDestructive = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final foreground =
        isDestructive ? OpenVtsColors.error : OpenVtsColors.textPrimary;

    return SizedBox(
      height: 34,
      child: OutlinedButton.icon(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: OpenVtsColors.white,
          foregroundColor: foreground,
          side: BorderSide(
            color: isDestructive
                ? OpenVtsColors.error.withValues(alpha: 0.35)
                : OpenVtsColors.border,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(OpenVtsRadius.pill),
          ),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        icon: isLoading
            ? const SizedBox(
                width: 13,
                height: 13,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(icon, size: 15),
        label: Text(
          label,
          style: OpenVtsTypography.meta.copyWith(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: foreground,
          ),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.title,
    required this.icon,
    required this.rows,
  });

  final String title;
  final IconData icon;
  final List<_InfoRow> rows;

  @override
  Widget build(BuildContext context) {
    return OpenVtsCard(
      padding: const EdgeInsets.all(OpenVtsSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: OpenVtsColors.textSecondary),
              const SizedBox(width: OpenVtsSpacing.xs),
              Text(
                title,
                style: OpenVtsTypography.label.copyWith(
                  color: OpenVtsColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: OpenVtsSpacing.xs),
          for (final row in rows) row,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: OpenVtsTypography.meta.copyWith(
                color: OpenVtsColors.textTertiary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: OpenVtsSpacing.sm),
          Flexible(
            flex: 2,
            child: Text(
              value,
              textAlign: TextAlign.end,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: OpenVtsTypography.meta.copyWith(
                color: OpenVtsColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
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

class _SectionStateCard extends StatelessWidget {
  const _SectionStateCard({
    required this.isLoading,
    required this.message,
    required this.onRetry,
  });

  final bool isLoading;
  final String? message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return OpenVtsCard(
      padding: const EdgeInsets.all(OpenVtsSpacing.sm),
      child: isLoading
          ? const Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message ?? 'Unable to load sub user profile.',
                  style: OpenVtsTypography.meta.copyWith(
                    color: OpenVtsColors.error,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: OpenVtsSpacing.sm),
                OutlinedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('Retry'),
                ),
              ],
            ),
    );
  }
}

String _display(String value) {
  final normalized = value.trim();
  return normalized.isEmpty ? '-' : normalized;
}

String _username(String value) {
  final normalized = value.trim();
  if (normalized.isEmpty) {
    return 'Not set';
  }
  return '@$normalized';
}

String _mobile(UserSubUser subUser) {
  final value = [subUser.mobilePrefix.trim(), subUser.mobileNumber.trim()]
      .where((part) => part.isNotEmpty)
      .join(' ')
      .trim();
  return value.isEmpty ? '-' : value;
}

String _dateText(DateTime? value) {
  if (value == null) {
    return '-';
  }
  return _dateFormatter.formatDateTime(value.toLocal());
}
