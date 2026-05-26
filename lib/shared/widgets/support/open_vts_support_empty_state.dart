import 'package:flutter/material.dart';
import 'package:open_vts/core/theme/open_vts_colors.dart';
import 'package:open_vts/core/theme/open_vts_radius.dart';
import 'package:open_vts/core/theme/open_vts_spacing.dart';
import 'package:open_vts/core/theme/open_vts_typography.dart';
import 'package:open_vts/shared/widgets/open_vts_button.dart';

class OpenVtsSupportEmptyState extends StatelessWidget {
  const OpenVtsSupportEmptyState({
    required this.hasActiveFilters,
    required this.onCreatePressed,
    super.key,
  });

  final bool hasActiveFilters;
  final VoidCallback onCreatePressed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(OpenVtsSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: OpenVtsColors.surface,
                border: Border.all(color: OpenVtsColors.border),
                borderRadius: BorderRadius.circular(OpenVtsRadius.md),
              ),
              child: const Icon(
                Icons.support_agent_rounded,
                size: 20,
                color: OpenVtsColors.textSecondary,
              ),
            ),
            const SizedBox(height: OpenVtsSpacing.sm),
            Text(
              hasActiveFilters ? 'No matching tickets' : 'No tickets',
              textAlign: TextAlign.center,
              style: OpenVtsTypography.titleSmall.copyWith(fontSize: 16),
            ),
            const SizedBox(height: OpenVtsSpacing.xs),
            Text(
              hasActiveFilters
                  ? 'Try a different search or status filter.'
                  : 'Create a ticket and the team will follow up here.',
              textAlign: TextAlign.center,
              style: OpenVtsTypography.body.copyWith(
                color: OpenVtsColors.textSecondary,
              ),
            ),
            if (!hasActiveFilters) ...[
              const SizedBox(height: OpenVtsSpacing.md),
              SizedBox(
                width: 172,
                child: OpenVtsButton(
                  label: 'Create ticket',
                  onPressed: onCreatePressed,
                  trailingIcon: Icons.add_rounded,
                  height: 40,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
