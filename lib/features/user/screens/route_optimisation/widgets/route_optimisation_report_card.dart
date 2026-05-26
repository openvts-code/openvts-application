import 'package:flutter/material.dart';

import '../../../../../core/theme/open_vts_colors.dart';
import '../../../../../core/theme/open_vts_radius.dart';
import '../../../../../core/theme/open_vts_spacing.dart';
import '../../../../../core/theme/open_vts_typography.dart';

/// Compact, collapsible report card with monospaced body.
///
/// Long reports collapse to a fixed window with a fade and a "Show more"
/// toggle so the optimised-order list above stays visible.
class RouteOptimisationReportCard extends StatefulWidget {
  const RouteOptimisationReportCard({
    required this.report,
    super.key,
  });

  final String report;

  @override
  State<RouteOptimisationReportCard> createState() =>
      _RouteOptimisationReportCardState();
}

class _RouteOptimisationReportCardState
    extends State<RouteOptimisationReportCard> {
  bool _expanded = false;

  static const double _collapsedHeight = 140;
  static const int _collapseLineThreshold = 10;

  @override
  Widget build(BuildContext context) {
    final report = widget.report.trim();
    final lineCount = '\n'.allMatches(report).length + 1;
    final canCollapse = lineCount > _collapseLineThreshold;

    final body = SelectableText(
      report.isEmpty ? '(no report)' : report,
      style: OpenVtsTypography.meta.copyWith(
        color: OpenVtsColors.textPrimary,
        fontFamily: 'monospace',
        fontFamilyFallback: const ['Courier', 'Menlo', 'Consolas'],
        height: 1.35,
        fontSize: 11,
      ),
    );

    return Container(
      decoration: BoxDecoration(
        color: OpenVtsColors.surface,
        borderRadius: BorderRadius.circular(OpenVtsRadius.md),
        border: Border.all(color: OpenVtsColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              OpenVtsSpacing.sm,
              6,
              6,
              0,
            ),
            child: Row(
              children: [
                Text(
                  'Report',
                  style: OpenVtsTypography.meta.copyWith(
                    color: OpenVtsColors.textSecondary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
                ),
                const Spacer(),
                if (canCollapse)
                  TextButton(
                    onPressed: () => setState(() => _expanded = !_expanded),
                    style: TextButton.styleFrom(
                      foregroundColor: OpenVtsColors.textSecondary,
                      minimumSize: const Size(0, 28),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    child: Text(
                      _expanded ? 'Show less' : 'Show more',
                      style: OpenVtsTypography.meta.copyWith(
                        color: OpenVtsColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (!canCollapse || _expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                OpenVtsSpacing.sm,
                0,
                OpenVtsSpacing.sm,
                OpenVtsSpacing.sm,
              ),
              child: body,
            )
          else
            SizedBox(
              height: _collapsedHeight,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      OpenVtsSpacing.sm,
                      0,
                      OpenVtsSpacing.sm,
                      OpenVtsSpacing.sm,
                    ),
                    child: ClipRect(
                      child: Align(
                        alignment: Alignment.topLeft,
                        heightFactor: 1,
                        child: body,
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: 36,
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              OpenVtsColors.surface.withValues(alpha: 0),
                              OpenVtsColors.surface,
                            ],
                          ),
                        ),
                      ),
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
