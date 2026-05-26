import 'package:flutter/material.dart';

import '../../../../../core/theme/open_vts_colors.dart';
import '../../../../../core/theme/open_vts_radius.dart';
import '../../../../../core/theme/open_vts_spacing.dart';
import '../../../../../core/theme/open_vts_typography.dart';
import '../../../models/user_route_optimisation_model.dart';

/// Compact, border-led card for a single stop in the route plan.
///
/// Visual:
///   [index] [Name | source chip]               [edit] [more ▾]
///           [lat, lon]                          [start ★] [end ⏹]
///
/// Reorder controls (move-up / move-down) and an optional long-press drag
/// handle are exposed on the right edge.
class RoutePointCard extends StatelessWidget {
  const RoutePointCard({
    required this.index,
    required this.point,
    required this.isStart,
    required this.isEnd,
    required this.totalCount,
    required this.onEdit,
    required this.onDelete,
    required this.onSetStart,
    required this.onSetEnd,
    required this.onClearEnd,
    required this.onMoveUp,
    required this.onMoveDown,
    this.isSelected = false,
    this.onTap,
    this.dragHandle,
    super.key,
  });

  final int index;
  final RouteOptimisationPoint point;
  final bool isStart;
  final bool isEnd;
  final int totalCount;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onSetStart;
  final VoidCallback onSetEnd;
  final VoidCallback? onClearEnd;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;
  final bool isSelected;
  final VoidCallback? onTap;
  final Widget? dragHandle;

  @override
  Widget build(BuildContext context) {
    final borderColor =
        isSelected ? OpenVtsColors.brandInk : OpenVtsColors.border;
    return Material(
      color: OpenVtsColors.surfaceElevated,
      borderRadius: BorderRadius.circular(OpenVtsRadius.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(OpenVtsRadius.md),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(
            OpenVtsSpacing.xs,
            OpenVtsSpacing.xs,
            OpenVtsSpacing.xs,
            OpenVtsSpacing.xs,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(OpenVtsRadius.md),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _IndexBadge(index: index, isStart: isStart, isEnd: isEnd),
                  const SizedBox(width: OpenVtsSpacing.xs),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                point.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: OpenVtsTypography.label,
                              ),
                            ),
                            const SizedBox(width: 6),
                            _SourceChip(source: point.source),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${point.lat.toStringAsFixed(5)}, '
                          '${point.lon.toStringAsFixed(5)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: OpenVtsTypography.meta.copyWith(
                            color: OpenVtsColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (dragHandle != null) dragHandle!,
                  _MoveStack(
                    canUp: index > 0 && onMoveUp != null,
                    canDown: index < totalCount - 1 && onMoveDown != null,
                    onUp: onMoveUp,
                    onDown: onMoveDown,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  if (isStart || isEnd) ...[
                    if (isStart)
                      const _Badge(
                        label: 'Start',
                        bg: OpenVtsColors.brandInk,
                        fg: OpenVtsColors.white,
                      ),
                    if (isStart && isEnd) const SizedBox(width: 4),
                    if (isEnd)
                      _Badge(
                        label: 'End',
                        bg: OpenVtsColors.info,
                        fg: OpenVtsColors.white,
                        onClear: onClearEnd,
                      ),
                    const Spacer(),
                  ] else
                    const Spacer(),
                  _RowAction(
                    icon: Icons.flag_outlined,
                    label: 'Start',
                    onTap: isStart ? null : onSetStart,
                  ),
                  const SizedBox(width: 4),
                  _RowAction(
                    icon: Icons.outlined_flag,
                    label: 'End',
                    onTap: isEnd ? null : onSetEnd,
                  ),
                  const SizedBox(width: 4),
                  _RowAction(
                    icon: Icons.edit_outlined,
                    label: 'Edit',
                    onTap: onEdit,
                  ),
                  const SizedBox(width: 4),
                  _RowAction(
                    icon: Icons.delete_outline,
                    label: 'Delete',
                    onTap: onDelete,
                    danger: true,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IndexBadge extends StatelessWidget {
  const _IndexBadge({
    required this.index,
    required this.isStart,
    required this.isEnd,
  });

  final int index;
  final bool isStart;
  final bool isEnd;

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color fg;
    if (isStart) {
      bg = OpenVtsColors.brandInk;
      fg = OpenVtsColors.white;
    } else if (isEnd) {
      bg = OpenVtsColors.info;
      fg = OpenVtsColors.white;
    } else {
      bg = OpenVtsColors.surface;
      fg = OpenVtsColors.textPrimary;
    }
    return Container(
      width: 26,
      height: 26,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(OpenVtsRadius.sm),
      ),
      child: Text(
        '${index + 1}',
        style: OpenVtsTypography.meta.copyWith(
          color: fg,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SourceChip extends StatelessWidget {
  const _SourceChip({required this.source});

  final RouteOptimisationPointSource source;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: OpenVtsColors.surface,
        borderRadius: BorderRadius.circular(OpenVtsRadius.sm),
        border: Border.all(color: OpenVtsColors.border),
      ),
      child: Text(
        source.label,
        style: OpenVtsTypography.meta.copyWith(
          fontSize: 10,
          color: OpenVtsColors.textSecondary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.label,
    required this.bg,
    required this.fg,
    this.onClear,
  });

  final String label;
  final Color bg;
  final Color fg;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(6, 2, onClear == null ? 6 : 2, 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(OpenVtsRadius.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: OpenVtsTypography.meta.copyWith(
              color: fg,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (onClear != null)
            InkWell(
              onTap: onClear,
              child: Padding(
                padding: const EdgeInsets.only(left: 2),
                child: Icon(Icons.close, size: 12, color: fg),
              ),
            ),
        ],
      ),
    );
  }
}

class _MoveStack extends StatelessWidget {
  const _MoveStack({
    required this.canUp,
    required this.canDown,
    required this.onUp,
    required this.onDown,
  });

  final bool canUp;
  final bool canDown;
  final VoidCallback? onUp;
  final VoidCallback? onDown;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _MoveButton(icon: Icons.keyboard_arrow_up, onTap: canUp ? onUp : null),
        const SizedBox(height: 2),
        _MoveButton(
          icon: Icons.keyboard_arrow_down,
          onTap: canDown ? onDown : null,
        ),
      ],
    );
  }
}

class _MoveButton extends StatelessWidget {
  const _MoveButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return InkWell(
      borderRadius: BorderRadius.circular(OpenVtsRadius.sm),
      onTap: onTap,
      child: Container(
        width: 22,
        height: 18,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: enabled ? OpenVtsColors.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(OpenVtsRadius.sm),
        ),
        child: Icon(
          icon,
          size: 14,
          color:
              enabled ? OpenVtsColors.textPrimary : OpenVtsColors.textTertiary,
        ),
      ),
    );
  }
}

class _RowAction extends StatelessWidget {
  const _RowAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final fg = !enabled
        ? OpenVtsColors.textTertiary
        : danger
            ? OpenVtsColors.error
            : OpenVtsColors.textSecondary;
    return InkWell(
      borderRadius: BorderRadius.circular(OpenVtsRadius.sm),
      onTap: onTap,
      child: Tooltip(
        message: label,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(OpenVtsRadius.sm),
            border: Border.all(
              color: enabled
                  ? (danger
                      ? OpenVtsColors.error.withValues(alpha: 0.4)
                      : OpenVtsColors.border)
                  : OpenVtsColors.border,
            ),
          ),
          child: Icon(icon, size: 13, color: fg),
        ),
      ),
    );
  }
}
