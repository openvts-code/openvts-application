import 'package:flutter/material.dart';

import '../../../../../core/theme/open_vts_colors.dart';
import '../../../../../core/theme/open_vts_spacing.dart';
import '../../../../../core/theme/open_vts_typography.dart';
import '../../../../../shared/helpers/toast_helper.dart';
import '../../../../../shared/widgets/open_vts_button.dart';
import '../../../models/admin_users_model.dart';

class AdminUserDeleteSheet extends StatelessWidget {
  const AdminUserDeleteSheet({
    required this.user,
    required this.isDeleting,
    required this.errorMessage,
    required this.onConfirm,
    super.key,
  });

  final AdminUserListItem user;
  final bool isDeleting;
  final String? errorMessage;
  final Future<void> Function() onConfirm;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(OpenVtsSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _displayName(user),
            style: OpenVtsTypography.titleSmall.copyWith(
              color: OpenVtsColors.textPrimary,
            ),
          ),
          const SizedBox(height: OpenVtsSpacing.xs),
          Text(
            'This action cannot be undone.',
            style: OpenVtsTypography.body.copyWith(
              color: OpenVtsColors.textSecondary,
            ),
          ),
          const Spacer(),
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
              const SizedBox(width: OpenVtsSpacing.xs),
              Expanded(
                child: OpenVtsButton(
                  label: 'Delete',
                  height: 40,
                  isLoading: isDeleting,
                  onPressed: isDeleting ? null : () => _confirm(context),
                  trailingIcon: Icons.delete_outline_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _confirm(BuildContext context) async {
    try {
      await onConfirm();
      if (!context.mounted) {
        return;
      }
      Navigator.of(context).pop();
    } catch (_) {
      if (!context.mounted) {
        return;
      }
      ToastHelper.showError(
        errorMessage ?? 'Unable to delete user.',
        context: context,
      );
    }
  }
}

String _displayName(AdminUserListItem user) {
  final name = user.name.trim();
  if (name.isNotEmpty) {
    return name;
  }
  final username = user.username.trim();
  if (username.isNotEmpty) {
    return username;
  }
  return 'user';
}
