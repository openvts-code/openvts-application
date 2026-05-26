import 'package:flutter/material.dart';

import '../../../../../core/theme/open_vts_colors.dart';
import '../../../../../core/theme/open_vts_spacing.dart';
import '../../../../../core/theme/open_vts_typography.dart';
import '../../../models/user_dashboard_model.dart';
import 'user_dashboard_widget_card.dart';

class UserUnknownDashboardWidget extends StatelessWidget {
  const UserUnknownDashboardWidget({
    required this.config,
    super.key,
  });

  final UserDashboardWidgetConfig config;

  @override
  Widget build(BuildContext context) {
    return UserDashboardWidgetCard(
      title: 'Unsupported widget',
      icon: Icons.extension_off_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Unsupported widget',
            style: OpenVtsTypography.label.copyWith(
              color: OpenVtsColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: OpenVtsSpacing.xs),
          Text(
            'type: ${config.type}',
            style: OpenVtsTypography.meta.copyWith(
              color: OpenVtsColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
