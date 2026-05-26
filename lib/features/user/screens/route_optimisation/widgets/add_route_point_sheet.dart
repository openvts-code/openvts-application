import 'package:flutter/material.dart';

import '../../../../../core/theme/open_vts_colors.dart';
import '../../../../../core/theme/open_vts_radius.dart';
import '../../../../../core/theme/open_vts_spacing.dart';
import '../../../../../core/theme/open_vts_typography.dart';
import '../../../../../shared/widgets/open_vts_bottom_sheet.dart';

/// User-selected outcome of [showAddRoutePointSheet].
enum AddPointChoice { landmarks, latLng, mapTap }

/// Compact bottom sheet offering the three supported point-creation sources.
///
/// No bulk upload / CSV option is offered by design.
Future<AddPointChoice?> showAddRoutePointSheet(BuildContext context) {
  return OpenVtsBottomSheet.show<AddPointChoice>(
    context: context,
    title: 'Add point',
    initialChildSize: 0.42,
    minChildSize: 0.32,
    maxChildSize: 0.7,
    child: const _AddRoutePointBody(),
  );
}

class _AddRoutePointBody extends StatelessWidget {
  const _AddRoutePointBody();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        OpenVtsSpacing.md,
        OpenVtsSpacing.xs,
        OpenVtsSpacing.md,
        OpenVtsSpacing.md,
      ),
      children: [
        _OptionTile(
          icon: Icons.place_outlined,
          title: 'Select landmarks',
          subtitle: 'Pick existing POIs or geofences.',
          onTap: () => Navigator.of(context).pop(AddPointChoice.landmarks),
        ),
        const SizedBox(height: OpenVtsSpacing.xs),
        _OptionTile(
          icon: Icons.touch_app_outlined,
          title: 'Tap on map',
          subtitle: 'Switch to the map and tap to drop a stop.',
          onTap: () => Navigator.of(context).pop(AddPointChoice.mapTap),
        ),
        const SizedBox(height: OpenVtsSpacing.xs),
        _OptionTile(
          icon: Icons.edit_location_alt_outlined,
          title: 'Enter lat / lng',
          subtitle: 'Type coordinates and a name.',
          onTap: () => Navigator.of(context).pop(AddPointChoice.latLng),
        ),
      ],
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: OpenVtsColors.surfaceElevated,
      borderRadius: BorderRadius.circular(OpenVtsRadius.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(OpenVtsRadius.md),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(OpenVtsSpacing.sm),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(OpenVtsRadius.md),
            border: Border.all(color: OpenVtsColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: OpenVtsColors.surface,
                  borderRadius: BorderRadius.circular(OpenVtsRadius.sm),
                ),
                child: Icon(icon, size: 16, color: OpenVtsColors.textPrimary),
              ),
              const SizedBox(width: OpenVtsSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(title, style: OpenVtsTypography.label),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: OpenVtsTypography.meta.copyWith(
                        color: OpenVtsColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                size: 11,
                color: OpenVtsColors.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
