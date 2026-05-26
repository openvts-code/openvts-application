import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../../../core/theme/open_vts_colors.dart';
import '../../../../../../core/theme/open_vts_radius.dart';
import '../../../../../../core/theme/open_vts_spacing.dart';
import '../../../../../../core/theme/open_vts_typography.dart';
import '../../../../../../core/utils/date_time_formatter.dart';
import '../../../../../../shared/widgets/open_vts_card.dart';
import '../../../../../../shared/widgets/open_vts_status_chip.dart';
import '../../../../models/user_landmark_model.dart';

/// Compact route list card. Renders name, status chip, color dot,
/// point/distance/tolerance meta, updated date and edit/delete actions.
/// Tapping the card body invokes [onSelect] which fits the route on the map.
class UserRouteCard extends StatelessWidget {
  const UserRouteCard({
    super.key,
    required this.route,
    required this.isSelected,
    required this.onSelect,
    required this.onEdit,
    required this.onDelete,
    this.isDeleting = false,
  });

  final UserRouteLandmark route;
  final bool isSelected;
  final VoidCallback onSelect;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool isDeleting;

  static const DateTimeFormatter _formatter = DateTimeFormatter();

  @override
  Widget build(BuildContext context) {
    final color = _parseHex(route.color);
    final inactive = !route.isActive;

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
                              route.name.isEmpty
                                  ? 'Untitled route'
                                  : route.name,
                              style: OpenVtsTypography.titleSmall.copyWith(
                                color: OpenVtsColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            OpenVtsStatusChip(
                              label: route.isActive ? 'Active' : 'Inactive',
                              type: route.isActive
                                  ? OpenVtsStatusType.success
                                  : OpenVtsStatusType.neutral,
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
                  if (route.description.trim().isNotEmpty) ...[
                    const SizedBox(height: OpenVtsSpacing.xs),
                    Text(
                      route.description.trim(),
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
                          _meta(route),
                          style: OpenVtsTypography.meta.copyWith(
                            color: OpenVtsColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (route.updatedAt != null) ...[
                        const SizedBox(width: OpenVtsSpacing.sm),
                        Text(
                          _formatter.formatDate(route.updatedAt!),
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

  String _meta(UserRouteLandmark r) {
    final coords = r.geodata?.coordinates ?? const <UserGeoPoint>[];
    final tolerance = r.toleranceMeters ?? r.geodata?.toleranceM;
    final parts = <String>[
      if (coords.isNotEmpty) '${coords.length} pts',
      if (coords.length >= 2) _formatMeters(_lengthMeters(coords)),
      if (tolerance != null && tolerance > 0) '±${_formatMeters(tolerance)}',
    ];
    if (parts.isEmpty) return 'Route';
    return parts.join(' • ');
  }

  static double _lengthMeters(List<UserGeoPoint> pts) {
    const earth = 6371000.0;
    double total = 0;
    for (var i = 1; i < pts.length; i++) {
      final a = pts[i - 1];
      final b = pts[i];
      final lat1 = a.lat * math.pi / 180;
      final lat2 = b.lat * math.pi / 180;
      final dLat = (b.lat - a.lat) * math.pi / 180;
      final dLon = (b.lon - a.lon) * math.pi / 180;
      final h = math.sin(dLat / 2) * math.sin(dLat / 2) +
          math.cos(lat1) *
              math.cos(lat2) *
              math.sin(dLon / 2) *
              math.sin(dLon / 2);
      total += 2 * earth * math.asin(math.min(1.0, math.sqrt(h)));
    }
    return total;
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

// `LatLng` import intentionally omitted — distance math here uses only
// raw doubles from `UserGeoPoint`.
