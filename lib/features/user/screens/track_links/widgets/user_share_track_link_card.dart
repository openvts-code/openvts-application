import 'package:flutter/material.dart';

import '../../../../../core/theme/open_vts_colors.dart';
import '../../../../../core/theme/open_vts_radius.dart';
import '../../../../../core/theme/open_vts_spacing.dart';
import '../../../../../core/theme/open_vts_typography.dart';
import '../../../../../core/utils/date_time_formatter.dart';
import '../../../../../shared/widgets/open_vts_card.dart';
import '../../../models/user_share_track_link_model.dart';

const DateTimeFormatter _dateFormatter = DateTimeFormatter();

class UserShareTrackLinkCard extends StatelessWidget {
  const UserShareTrackLinkCard({
    required this.link,
    required this.publicUrl,
    required this.onCopy,
    required this.onOpen,
    required this.onQr,
    required this.onEdit,
    required this.onDelete,
    this.isBusy = false,
    super.key,
  });

  final UserShareTrackLink link;
  final String? publicUrl;
  final VoidCallback? onCopy;
  final VoidCallback? onOpen;
  final VoidCallback? onQr;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    final displayUrl =
        _displayValue(publicUrl) ?? _displayValue(link.uniqueCode);
    final vehicleCount = link.vehicleCount;

    return OpenVtsCard(
      padding: const EdgeInsets.all(OpenVtsSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: OpenVtsColors.textPrimary.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(OpenVtsRadius.sm),
                  border: Border.all(color: OpenVtsColors.border),
                ),
                child: const Icon(
                  Icons.link_rounded,
                  size: 19,
                  color: OpenVtsColors.textSecondary,
                ),
              ),
              const SizedBox(width: OpenVtsSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayUrl ?? '-',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: OpenVtsTypography.label.copyWith(
                        color: OpenVtsColors.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      link.uniqueCode.trim().isEmpty
                          ? 'Code -'
                          : 'Code ${link.uniqueCode.trim()}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: OpenVtsTypography.meta.copyWith(
                        color: OpenVtsColors.textSecondary,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: OpenVtsSpacing.xs),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _StatusChip(
                    label: link.statusLabel,
                    color: link.isActive
                        ? OpenVtsColors.success
                        : OpenVtsColors.textSecondary,
                  ),
                  if (link.isExpired) ...[
                    const SizedBox(height: 4),
                    const _StatusChip(
                      label: 'Expired',
                      color: OpenVtsColors.error,
                    ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: OpenVtsSpacing.sm),
          Wrap(
            spacing: OpenVtsSpacing.xs,
            runSpacing: OpenVtsSpacing.xs,
            children: [
              _InfoPill(
                icon: Icons.directions_car_filled_outlined,
                label:
                    '$vehicleCount ${vehicleCount == 1 ? 'vehicle' : 'vehicles'}',
              ),
              if (link.expiryAt != null)
                _InfoPill(
                  icon: Icons.schedule_rounded,
                  label:
                      _dateFormatter.formatDateTime(link.expiryAt!.toLocal()),
                ),
              if (link.createdAt != null)
                _InfoPill(
                  icon: Icons.calendar_today_outlined,
                  label:
                      'Created ${_dateFormatter.formatDate(link.createdAt!.toLocal())}',
                ),
              if (link.isGeofence)
                const _InfoPill(
                  icon: Icons.fence_outlined,
                  label: 'Geofence',
                ),
              if (link.isHistory)
                const _InfoPill(
                  icon: Icons.history_rounded,
                  label: 'History',
                ),
            ],
          ),
          if (link.vehicles.isNotEmpty) ...[
            const SizedBox(height: OpenVtsSpacing.xs),
            Wrap(
              spacing: OpenVtsSpacing.xs,
              runSpacing: OpenVtsSpacing.xs,
              children: [
                for (final vehicle in link.vehicles.take(3))
                  _VehicleChip(vehicle: vehicle),
                if (link.vehicles.length > 3)
                  _InfoPill(
                    icon: Icons.more_horiz_rounded,
                    label: '+${link.vehicles.length - 3}',
                  ),
              ],
            ),
          ],
          const SizedBox(height: OpenVtsSpacing.sm),
          Row(
            children: [
              if (isBusy) ...[
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: OpenVtsSpacing.xs),
              ],
              const Spacer(),
              _ActionIconButton(
                tooltip: 'Copy',
                icon: Icons.copy_rounded,
                onPressed: isBusy ? null : onCopy,
              ),
              _ActionIconButton(
                tooltip: 'Open',
                icon: Icons.open_in_new_rounded,
                onPressed: isBusy ? null : onOpen,
              ),
              _ActionIconButton(
                tooltip: 'QR',
                icon: Icons.qr_code_2_rounded,
                onPressed: isBusy ? null : onQr,
              ),
              _ActionIconButton(
                tooltip: 'Edit',
                icon: Icons.edit_outlined,
                onPressed: isBusy ? null : onEdit,
              ),
              _ActionIconButton(
                tooltip: 'Delete',
                icon: Icons.delete_outline_rounded,
                color: OpenVtsColors.error,
                onPressed: isBusy ? null : onDelete,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionIconButton extends StatelessWidget {
  const _ActionIconButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    this.color,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: SizedBox.square(
        dimension: 34,
        child: IconButton(
          onPressed: onPressed,
          icon: Icon(icon, size: 17),
          color: color ?? OpenVtsColors.textSecondary,
          disabledColor: OpenVtsColors.textTertiary.withValues(alpha: 0.58),
          padding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
          style: IconButton.styleFrom(
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(OpenVtsRadius.sm),
              side: const BorderSide(color: OpenVtsColors.border),
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 260),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: OpenVtsColors.textSecondary.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(OpenVtsRadius.pill),
        border: Border.all(
          color: OpenVtsColors.textSecondary.withValues(alpha: 0.16),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: OpenVtsColors.textSecondary),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: OpenVtsTypography.meta.copyWith(
                color: OpenVtsColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(OpenVtsRadius.pill),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: OpenVtsTypography.meta.copyWith(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _VehicleChip extends StatelessWidget {
  const _VehicleChip({required this.vehicle});

  final UserShareTrackVehicle vehicle;

  @override
  Widget build(BuildContext context) {
    return _InfoPill(
      icon: Icons.directions_car_outlined,
      label: vehicle.displayName,
    );
  }
}

String? _displayValue(String? value) {
  final normalized = value?.trim();
  if (normalized == null || normalized.isEmpty) return null;
  return normalized;
}
