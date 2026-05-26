import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../../core/theme/open_vts_colors.dart';
import '../../../../../../core/theme/open_vts_spacing.dart';
import '../../../../../../core/theme/open_vts_typography.dart';
import '../../../../../../shared/helpers/toast_helper.dart';
import '../../../../../../shared/widgets/open_vts_button.dart';
import '../../../../controllers/user_subuser_details_controller.dart';
import '../../../../models/user_subuser_model.dart';
import '../../../../models/user_subusers_state.dart';

typedef UserSubUserDetailsProvider = AutoDisposeStateNotifierProvider<
    UserSubUserDetailsController, UserSubUserDetailsState>;

class UserSubUserDeleteSheet extends ConsumerWidget {
  const UserSubUserDeleteSheet({
    required this.provider,
    required this.subUser,
    super.key,
  });

  final UserSubUserDetailsProvider provider;
  final UserSubUser subUser;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(provider);
    final isDeleting = state.isDeleting;

    return Padding(
      padding: const EdgeInsets.all(OpenVtsSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _displayName(subUser),
            style: OpenVtsTypography.titleSmall.copyWith(
              color: OpenVtsColors.textPrimary,
            ),
          ),
          const SizedBox(height: OpenVtsSpacing.xs),
          Text(
            'This action permanently removes the sub user and revokes vehicle access. This cannot be undone.',
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
              const SizedBox(width: OpenVtsSpacing.sm),
              Expanded(
                child: OpenVtsButton(
                  label: 'Delete',
                  height: 40,
                  trailingIcon: Icons.delete_outline_rounded,
                  isLoading: isDeleting,
                  onPressed:
                      isDeleting ? null : () => _confirmDelete(context, ref),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final ok = await ref.read(provider.notifier).deleteSubUser();
    if (!context.mounted) {
      return;
    }

    if (ok) {
      Navigator.of(context).pop(true);
      return;
    }

    ToastHelper.showError(
      ref.read(provider).errorMessage ?? 'Unable to delete sub user.',
      context: context,
    );
  }
}

String _displayName(UserSubUser subUser) {
  final name = subUser.name.trim();
  if (name.isNotEmpty) {
    return name;
  }

  final username = subUser.username.trim();
  if (username.isNotEmpty) {
    return username;
  }

  return 'Sub User';
}
