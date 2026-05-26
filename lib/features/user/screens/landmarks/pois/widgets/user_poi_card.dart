import 'package:flutter/material.dart';

import '../../../../../../core/theme/open_vts_colors.dart';
import '../../../../../../core/theme/open_vts_radius.dart';
import '../../../../../../core/theme/open_vts_spacing.dart';
import '../../../../../../core/theme/open_vts_typography.dart';
import '../../../../../../core/utils/date_time_formatter.dart';
import '../../../../../../shared/widgets/open_vts_card.dart';
import '../../../../../../shared/widgets/open_vts_status_chip.dart';
import '../../../../models/user_landmark_model.dart';
import '../user_poi_constants.dart';

/// Compact POI list card. Renders name, category, status, color dot, icon,
/// tolerance (when set), coordinates, updated date, and edit/delete actions.
class UserPoiCard extends StatelessWidget {
  const UserPoiCard({
    super.key,
    required this.poi,
    required this.isSelected,
    required this.onSelect,
    required this.onEdit,
    required this.onDelete,
    this.isDeleting = false,
  });

  final UserPoi poi;
  final bool isSelected;
  final VoidCallback onSelect;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool isDeleting;

  static const DateTimeFormatter _formatter = DateTimeFormatter();

  @override
  Widget build(BuildContext context) {
    final color = _parseHex(poi.color);
    final inactive = !poi.isActive;

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
                      _IconBadge(slug: poi.iconSlug, color: color),
                      const SizedBox(width: OpenVtsSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                _ColorDot(color: color),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    poi.name.isEmpty
                                        ? 'Untitled POI'
                                        : poi.name,
                                    style:
                                        OpenVtsTypography.titleSmall.copyWith(
                                      color: OpenVtsColors.textPrimary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                OpenVtsStatusChip(
                                  label: labelForUserPoiCategory(poi.category),
                                  type: OpenVtsStatusType.neutral,
                                ),
                                OpenVtsStatusChip(
                                  label: poi.isActive ? 'Active' : 'Inactive',
                                  type: poi.isActive
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
                  if (poi.description.trim().isNotEmpty) ...[
                    const SizedBox(height: OpenVtsSpacing.xs),
                    Text(
                      poi.description.trim(),
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
                          _metaSummary(poi),
                          style: OpenVtsTypography.meta.copyWith(
                            color: OpenVtsColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (poi.updatedAt != null) ...[
                        const SizedBox(width: OpenVtsSpacing.sm),
                        Text(
                          _formatter.formatDate(poi.updatedAt!),
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

  String _metaSummary(UserPoi p) {
    final parts = <String>[];
    final coords = p.coordinates;
    if (coords != null) {
      parts.add(
        '${coords.lat.toStringAsFixed(6)}, ${coords.lon.toStringAsFixed(6)}',
      );
    }
    final tol = p.toleranceMeters;
    if (tol != null && tol > 0) {
      parts.add('±${_formatMeters(tol)}');
    }
    if (parts.isEmpty) return 'No coordinates';
    return parts.join(' • ');
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

class _IconBadge extends StatelessWidget {
  const _IconBadge({required this.slug, required this.color});

  final String slug;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(OpenVtsRadius.sm),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      alignment: Alignment.center,
      child: Icon(iconForUserPoiSlug(slug), size: 16, color: color),
    );
  }
}

class _ColorDot extends StatelessWidget {
  const _ColorDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
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
