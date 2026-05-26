import 'package:flutter/material.dart';

import '../../../../../../core/theme/open_vts_colors.dart';
import '../../../../../../core/theme/open_vts_radius.dart';
import '../../../../../../core/theme/open_vts_spacing.dart';
import '../../../../../../core/theme/open_vts_typography.dart';
import '../../../../../../core/utils/date_time_formatter.dart';
import '../../../../../../shared/widgets/open_vts_card.dart';
import '../../../../../../shared/widgets/open_vts_status_chip.dart';
import '../../../../models/user_landmark_model.dart';

/// Compact geofence list card. Renders name, type + status chips, a color
/// dot, description preview, geometry meta (radius / tolerance / point count),
/// updated date, and edit/delete actions. Tapping the card body invokes
/// [onSelect].
class UserGeofenceCard extends StatelessWidget {
  const UserGeofenceCard({
    super.key,
    required this.geofence,
    required this.isSelected,
    required this.onSelect,
    required this.onEdit,
    required this.onDelete,
    this.isDeleting = false,
  });

  final UserGeofence geofence;
  final bool isSelected;
  final VoidCallback onSelect;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool isDeleting;

  static const DateTimeFormatter _formatter = DateTimeFormatter();

  @override
  Widget build(BuildContext context) {
    final color = _parseHex(geofence.color);
    final inactive = !geofence.isActive;

    return Stack(
      children: [
        Opacity(
          opacity: inactive ? 0.78 : 1,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(OpenVtsRadius.lg),
              border: isSelected
                  ? Border.all(color: OpenVtsColors.brandInk, width: 1.4)
                  : null,
            ),
            child: OpenVtsCard(
              onTap: onSelect,
              padding: const EdgeInsets.all(OpenVtsSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ColorDot(color: color),
                      const SizedBox(width: OpenVtsSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              geofence.name.isEmpty
                                  ? 'Untitled geofence'
                                  : geofence.name,
                              style: OpenVtsTypography.titleSmall.copyWith(
                                color: OpenVtsColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                OpenVtsStatusChip(
                                  label: geofence.type.label,
                                  type: OpenVtsStatusType.neutral,
                                ),
                                OpenVtsStatusChip(
                                  label:
                                      geofence.isActive ? 'Active' : 'Inactive',
                                  type: geofence.isActive
                                      ? OpenVtsStatusType.success
                                      : OpenVtsStatusType.neutral,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      _RowAction(
                        icon: Icons.edit_outlined,
                        tooltip: 'Edit',
                        onTap: onEdit,
                      ),
                      _RowAction(
                        icon: Icons.delete_outline,
                        tooltip: 'Delete',
                        onTap: isDeleting ? null : onDelete,
                        destructive: true,
                      ),
                    ],
                  ),
                  if (geofence.description.trim().isNotEmpty) ...[
                    const SizedBox(height: OpenVtsSpacing.xs),
                    Text(
                      geofence.description.trim(),
                      style: OpenVtsTypography.meta.copyWith(
                        color: OpenVtsColors.textSecondary,
                        height: 1.35,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: OpenVtsSpacing.xs),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _geometrySummary(geofence),
                          style: OpenVtsTypography.meta.copyWith(
                            color: OpenVtsColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (geofence.updatedAt != null) ...[
                        const SizedBox(width: OpenVtsSpacing.sm),
                        Text(
                          _formatter.formatDate(geofence.updatedAt!),
                          style: OpenVtsTypography.meta.copyWith(
                            color: OpenVtsColors.textTertiary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        if (isDeleting)
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: OpenVtsColors.surfaceElevated.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(OpenVtsRadius.lg),
                ),
                child: const Center(
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  String _geometrySummary(UserGeofence g) {
    switch (g.type) {
      case UserGeofenceType.circle:
        final radius = g.radius;
        if (radius == null || radius <= 0) return 'Circle';
        return 'Radius ${_formatMeters(radius)}';
      case UserGeofenceType.polygon:
        final count = (g.geodata is UserPolygonGeoData)
            ? (g.geodata as UserPolygonGeoData).coordinates.length
            : 0;
        if (count == 0) return 'Polygon';
        return '$count vertices';
      case UserGeofenceType.line:
        final count = (g.geodata is UserLineGeoData)
            ? (g.geodata as UserLineGeoData).coordinates.length
            : 0;
        final tolerance = g.toleranceMeters ??
            (g.geodata is UserLineGeoData
                ? (g.geodata as UserLineGeoData).toleranceM
                : null);
        final parts = <String>[
          if (count > 0) '$count points',
          if (tolerance != null && tolerance > 0)
            'Tolerance ${_formatMeters(tolerance)}',
        ];
        return parts.isEmpty ? 'Line' : parts.join(' • ');
    }
  }

  static String _formatMeters(double meters) {
    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(meters >= 10000 ? 1 : 2)} km';
    }
    return '${meters.toStringAsFixed(meters >= 100 ? 0 : 1)} m';
  }

  static Color _parseHex(String value) {
    final cleaned = value.replaceAll('#', '').trim();
    if (cleaned.length != 6) return OpenVtsColors.textTertiary;
    final parsed = int.tryParse('FF$cleaned', radix: 16);
    if (parsed == null) return OpenVtsColors.textTertiary;
    return Color(parsed);
  }
}

class _ColorDot extends StatelessWidget {
  const _ColorDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      height: 12,
      margin: const EdgeInsets.only(top: 5),
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: OpenVtsColors.border),
      ),
    );
  }
}

class _RowAction extends StatelessWidget {
  const _RowAction({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    final color =
        destructive ? OpenVtsColors.error : OpenVtsColors.textSecondary;
    return Tooltip(
      message: tooltip,
      child: InkResponse(
        onTap: onTap,
        radius: 22,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(
            icon,
            size: 18,
            color: disabled ? OpenVtsColors.textTertiary : color,
          ),
        ),
      ),
    );
  }
}
