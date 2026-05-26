import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/open_vts_colors.dart';
import '../../../../../core/theme/open_vts_spacing.dart';
import '../../../../../core/theme/open_vts_typography.dart';
import '../../../../../core/utils/date_time_formatter.dart';
import '../../../../../shared/helpers/toast_helper.dart';
import '../../../../../shared/widgets/open_vts_card.dart';
import '../../../../../shared/widgets/open_vts_empty_state.dart';
import '../../../../../shared/widgets/open_vts_error_view.dart';
import '../../../../../shared/widgets/open_vts_loader.dart';
import '../../../controllers/admin_driver_details_controller.dart';
import '../../../models/admin_driver_details_model.dart';
import '../../../models/admin_driver_details_state.dart';
import 'admin_driver_assign_user_sheet.dart';

class AdminDriverUsersTab extends ConsumerWidget {
  const AdminDriverUsersTab({
    required this.provider,
    required this.state,
    super.key,
  });

  final AutoDisposeStateNotifierProvider<AdminDriverDetailsController,
      AdminDriverDetailsState> provider;
  final AdminDriverDetailsState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(provider.notifier);

    if (state.isLoadingUsers && state.linkedUsers.isEmpty) {
      return const OpenVtsCard(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: OpenVtsSpacing.md),
          child: OpenVtsLoader(),
        ),
      );
    }

    if (state.sectionErrorMessage != null && state.linkedUsers.isEmpty) {
      return OpenVtsErrorView(
        message: state.sectionErrorMessage!,
        onRetry: controller.loadUsers,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton.icon(
          onPressed: state.isAssigningUser
              ? null
              : () => showDriverAssignUserSheet(
                    context: context,
                    provider: provider,
                    users: state.unlinkedUsers,
                  ),
          icon: const Icon(Icons.person_add_alt_1_rounded, size: 16),
          label: const Text('Assign User'),
        ),
        const SizedBox(height: OpenVtsSpacing.sm),
        if (state.linkedUsers.isEmpty)
          const OpenVtsEmptyState(
            title: 'No assigned users',
            message: 'Assign users to this driver.',
          )
        else
          ...state.linkedUsers.map(
            (user) => Padding(
              padding: const EdgeInsets.only(bottom: OpenVtsSpacing.xs),
              child: _UserCard(
                user: user,
                unassigning: state.unassigningUserIds.contains(user.id),
                onUnassign: () async {
                  final yes = await showDialog<bool>(
                    context: context,
                    builder: (dCtx) => AlertDialog(
                      title: const Text('Unassign user'),
                      content: Text('Remove ${user.name} from this driver?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(dCtx).pop(false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(dCtx).pop(true),
                          style: TextButton.styleFrom(
                            foregroundColor: OpenVtsColors.error,
                          ),
                          child: const Text('Unassign'),
                        ),
                      ],
                    ),
                  );
                  if (yes != true) return;
                  final ok = await controller.unassignUser(user.id);
                  if (!context.mounted) return;
                  if (ok) {
                    ToastHelper.showSuccess(
                      'User unassigned.',
                      context: context,
                    );
                  } else {
                    ToastHelper.showError(
                      ref.read(provider).sectionErrorMessage ??
                          'Unable to unassign user.',
                      context: context,
                    );
                  }
                },
              ),
            ),
          ),
      ],
    );
  }
}

class _UserCard extends StatelessWidget {
  const _UserCard({
    required this.user,
    required this.unassigning,
    required this.onUnassign,
  });

  final AdminDriverLinkedUser user;
  final bool unassigning;
  final VoidCallback onUnassign;

  @override
  Widget build(BuildContext context) {
    final f = const DateTimeFormatter();
    return OpenVtsCard(
      padding: const EdgeInsets.all(OpenVtsSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  user.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: OpenVtsTypography.label.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              TextButton(
                onPressed: unassigning ? null : onUnassign,
                child: unassigning
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Unassign'),
              ),
            ],
          ),
          Text('@${user.username}', style: OpenVtsTypography.meta),
          Text(user.phone, style: OpenVtsTypography.meta),
          Text(user.email, style: OpenVtsTypography.meta),
          Text(
            'Status: ${user.isActive == null ? '-' : (user.isActive! ? 'Active' : 'Inactive')}',
            style: OpenVtsTypography.meta,
          ),
          Text(
            'Assigned: ${user.assignedAt == null ? '-' : f.formatDate(user.assignedAt!)}',
            style: OpenVtsTypography.meta,
          ),
        ],
      ),
    );
  }
}
