import 'package:flutter/material.dart';

import '../../../../../core/theme/open_vts_colors.dart';
import '../../../../../core/theme/open_vts_spacing.dart';
import '../../../../../core/theme/open_vts_typography.dart';
import '../../../../../shared/widgets/open_vts_button.dart';
import '../../../../../shared/widgets/open_vts_card.dart';

class AdminUsersHeader extends StatelessWidget {
  const AdminUsersHeader({
    required this.totalCount,
    required this.visibleCount,
    required this.onCreatePressed,
    required this.isCreating,
    super.key,
  });

  final int totalCount;
  final int visibleCount;
  final VoidCallback onCreatePressed;
  final bool isCreating;

  @override
  Widget build(BuildContext context) {
    return OpenVtsCard(
      padding: const EdgeInsets.all(OpenVtsSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Users',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: OpenVtsTypography.titleSmall.copyWith(
                    color: OpenVtsColors.textPrimary,
                  ),
                ),
                const SizedBox(height: OpenVtsSpacing.xxs),
                Text(
                  'Manage users, login access, contacts, and assigned vehicles.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: OpenVtsTypography.meta.copyWith(
                    color: OpenVtsColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: OpenVtsSpacing.sm),
          SizedBox(
            width: 122,
            child: OpenVtsButton(
              label: 'New User',
              onPressed: onCreatePressed,
              isLoading: isCreating,
              height: 36,
              trailingIcon: Icons.add_rounded,
            ),
          ),
        ],
      ),
    );
  }
}
