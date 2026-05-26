import 'package:flutter/material.dart';

import '../../../../../core/theme/open_vts_colors.dart';
import '../../../../../core/theme/open_vts_radius.dart';

/// Compact floating zoom + fit controls for the Route Optimisation map.
///
/// Sized for mobile thumbs (32px buttons) without the heft of a desktop
/// toolbar. Only the actions that make sense for a single-screen planner
/// are exposed: zoom in / out and fit-all.
class RouteOptimisationMapControls extends StatelessWidget {
  const RouteOptimisationMapControls({
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onFitAll,
    this.canFit = true,
    super.key,
  });

  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onFitAll;
  final bool canFit;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: OpenVtsColors.surfaceElevated.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(OpenVtsRadius.md),
        border: Border.all(color: OpenVtsColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 6,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _CtlButton(
            icon: Icons.add,
            tooltip: 'Zoom in',
            onPressed: onZoomIn,
          ),
          const _Divider(),
          _CtlButton(
            icon: Icons.remove,
            tooltip: 'Zoom out',
            onPressed: onZoomOut,
          ),
          const _Divider(),
          _CtlButton(
            icon: Icons.center_focus_strong_outlined,
            tooltip: 'Fit all stops',
            onPressed: canFit ? onFitAll : null,
          ),
        ],
      ),
    );
  }
}

class _CtlButton extends StatelessWidget {
  const _CtlButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(OpenVtsRadius.sm),
        child: SizedBox(
          width: 32,
          height: 32,
          child: Icon(
            icon,
            size: 16,
            color: enabled
                ? OpenVtsColors.textPrimary
                : OpenVtsColors.textTertiary,
          ),
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      width: 24,
      color: OpenVtsColors.border,
    );
  }
}
