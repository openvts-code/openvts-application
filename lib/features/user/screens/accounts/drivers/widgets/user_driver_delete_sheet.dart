import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../../core/theme/open_vts_colors.dart';
import '../../../../../../core/theme/open_vts_spacing.dart';
import '../../../../../../core/theme/open_vts_typography.dart';
import '../../../../../../shared/helpers/toast_helper.dart';
import '../../../../../../shared/widgets/open_vts_button.dart';
import '../../../../controllers/user_driver_details_controller.dart';
import '../../../../models/user_driver_model.dart';
import '../../../../models/user_drivers_state.dart';

class UserDriverDeleteSheet extends ConsumerWidget {
  const UserDriverDeleteSheet({
    required this.provider,
    required this.driver,
    super.key,
  });

  final AutoDisposeStateNotifierProvider<UserDriverDetailsController,
      UserDriverDetailsState> provider;
  final UserDriver driver;

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
            _displayName(driver),
            style: OpenVtsTypography.titleSmall.copyWith(
              color: OpenVtsColors.textPrimary,
            ),
          ),
          const SizedBox(height: OpenVtsSpacing.xs),
          Text(
            'This action cannot be undone. The driver and related assignments will be removed.',
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
                  isLoading: isDeleting,
                  trailingIcon: Icons.delete_outline_rounded,
                  onPressed: isDeleting ? null : () => _confirm(context, ref),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _confirm(BuildContext context, WidgetRef ref) async {
    final ok = await ref.read(provider.notifier).deleteDriver();
    if (!context.mounted) {
      return;
    }

    if (ok) {
      Navigator.of(context).pop(true);
      return;
    }

    ToastHelper.showError(
      ref.read(provider).errorMessage ?? 'Unable to delete driver.',
      context: context,
    );
  }
}

String _displayName(UserDriver driver) {
  final name = driver.name.trim();
  if (name.isNotEmpty) {
    return name;
  }

  final username = driver.username.trim();
  if (username.isNotEmpty) {
    return username;
  }

  return 'Driver';
}
