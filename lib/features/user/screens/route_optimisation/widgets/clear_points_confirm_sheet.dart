import 'package:flutter/material.dart';

import '../../../../../core/theme/open_vts_colors.dart';
import '../../../../../core/theme/open_vts_radius.dart';
import '../../../../../core/theme/open_vts_spacing.dart';
import '../../../../../core/theme/open_vts_typography.dart';
import '../../../../../shared/widgets/open_vts_bottom_sheet.dart';

/// Calm, low-key confirmation before wiping all stops + the optimisation
/// result from the workspace. Returns `true` only if the user confirmed.
Future<bool> showClearPointsConfirmSheet(
  BuildContext context, {
  required int pointCount,
  required bool hasResult,
}) async {
  final result = await OpenVtsBottomSheet.show<bool>(
    context: context,
    title: 'Clear workspace',
    initialChildSize: 0.36,
    minChildSize: 0.28,
    maxChildSize: 0.6,
    child: _ConfirmBody(pointCount: pointCount, hasResult: hasResult),
  );
  return result ?? false;
}

class _ConfirmBody extends StatelessWidget {
  const _ConfirmBody({required this.pointCount, required this.hasResult});

  final int pointCount;
  final bool hasResult;

  @override
  Widget build(BuildContext context) {
    final summary = StringBuffer();
    if (pointCount == 0) {
      summary.write('There are no stops to clear.');
    } else {
      summary.write('Removes $pointCount stop${pointCount == 1 ? '' : 's'}');
      if (hasResult) summary.write(' and the optimisation result');
      summary.write('. Saved routes are not affected.');
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        OpenVtsSpacing.md,
        OpenVtsSpacing.xs,
        OpenVtsSpacing.md,
        OpenVtsSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(OpenVtsSpacing.sm),
            decoration: BoxDecoration(
              color: OpenVtsColors.surface,
              borderRadius: BorderRadius.circular(OpenVtsRadius.sm),
              border: Border.all(color: OpenVtsColors.border),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.delete_sweep_outlined,
                  size: 16,
                  color: OpenVtsColors.textSecondary,
                ),
                const SizedBox(width: OpenVtsSpacing.xs),
                Expanded(
                  child: Text(
                    summary.toString(),
                    style: OpenVtsTypography.label.copyWith(
                      color: OpenVtsColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: OpenVtsColors.textPrimary,
                    side: const BorderSide(color: OpenVtsColors.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(OpenVtsRadius.button),
                    ),
                    minimumSize: const Size.fromHeight(40),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: OpenVtsSpacing.xs),
              Expanded(
                child: ElevatedButton(
                  onPressed: pointCount == 0 && !hasResult
                      ? null
                      : () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: OpenVtsColors.brandInk,
                    foregroundColor: OpenVtsColors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(OpenVtsRadius.button),
                    ),
                    minimumSize: const Size.fromHeight(40),
                  ),
                  child: const Text('Clear'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
