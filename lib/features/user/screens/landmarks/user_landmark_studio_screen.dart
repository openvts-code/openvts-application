import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/open_vts_colors.dart';
import '../../../../core/theme/open_vts_radius.dart';
import '../../../../core/theme/open_vts_spacing.dart';
import '../../../../core/theme/open_vts_typography.dart';
import '../../../../shared/widgets/open_vts_button.dart';
import '../../../../shared/widgets/open_vts_card.dart';
import '../../../../shared/widgets/open_vts_page_scaffold.dart';

/// Landing screen for the user-scope Landmark Studio. Surfaces three flows —
/// Geofence, POI and Route — as compact option cards. Mobile renders a single
/// column; tablet widths expand to a two- or three-column grid capped at a
/// readable content width.
class UserLandmarkStudioScreen extends StatelessWidget {
  const UserLandmarkStudioScreen({super.key});

  static const _options = <_LandmarkOption>[
    _LandmarkOption(
      label: 'Geofence',
      description:
          'Draw circles, polygons, rectangles, and line boundaries on the map.',
      cta: 'Open Geofence',
      icon: Icons.hexagon_outlined,
      route: RoutePaths.userLandmarkGeofences,
    ),
    _LandmarkOption(
      label: 'POI',
      description:
          'Create points of interest with category, icon, color, and tolerance radius.',
      cta: 'Open POI',
      icon: Icons.location_on_outlined,
      route: RoutePaths.userLandmarkPois,
    ),
    _LandmarkOption(
      label: 'Route',
      description:
          'Create route lines manually or from source and destination where supported.',
      cta: 'Open Route',
      icon: Icons.alt_route_outlined,
      route: RoutePaths.userLandmarkRoutes,
    ),
  ];

  static const double _maxContentWidth = 920;

  @override
  Widget build(BuildContext context) {
    return OpenVtsPageScaffold(
      title: 'Landmark Studio',
      headerMode: OpenVtsPageHeaderMode.closeable,
      padding: const EdgeInsets.fromLTRB(
        OpenVtsSpacing.md,
        OpenVtsSpacing.sm,
        OpenVtsSpacing.md,
        OpenVtsSpacing.md,
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _maxContentWidth),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final crossAxisCount = width >= 880
                  ? 3
                  : width >= 600
                      ? 2
                      : 1;
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _StudioHeaderCard(),
                    const SizedBox(height: OpenVtsSpacing.sm),
                    _OptionsGrid(
                      options: _options,
                      crossAxisCount: crossAxisCount,
                      onOpen: (route) => context.push(route),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _StudioHeaderCard extends StatelessWidget {
  const _StudioHeaderCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final iconBg =
        isDark ? OpenVtsColors.darkSurface : OpenVtsColors.surfaceElevated;
    final titleColor =
        isDark ? OpenVtsColors.darkTextPrimary : OpenVtsColors.textPrimary;
    final subtitleColor =
        isDark ? OpenVtsColors.darkTextSecondary : OpenVtsColors.textSecondary;

    return OpenVtsCard(
      padding: const EdgeInsets.all(OpenVtsSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(OpenVtsRadius.md),
              border: Border.all(color: OpenVtsColors.border),
            ),
            child: Icon(
              Icons.map_outlined,
              size: 18,
              color: titleColor,
            ),
          ),
          const SizedBox(width: OpenVtsSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Landmark Studio',
                  style: OpenVtsTypography.titleSmall.copyWith(
                    color: titleColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Create and manage geofences, points of interest, and routes.',
                  style: OpenVtsTypography.meta.copyWith(
                    color: subtitleColor,
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

class _OptionsGrid extends StatelessWidget {
  const _OptionsGrid({
    required this.options,
    required this.crossAxisCount,
    required this.onOpen,
  });

  final List<_LandmarkOption> options;
  final int crossAxisCount;
  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context) {
    if (crossAxisCount == 1) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < options.length; i++) ...[
            if (i > 0) const SizedBox(height: OpenVtsSpacing.sm),
            _LandmarkOptionCard(
              option: options[i],
              onTap: () => onOpen(options[i].route),
            ),
          ],
        ],
      );
    }
    return Wrap(
      spacing: OpenVtsSpacing.sm,
      runSpacing: OpenVtsSpacing.sm,
      children: [
        for (final option in options)
          SizedBox(
            width: _columnWidth(context, crossAxisCount),
            child: _LandmarkOptionCard(
              option: option,
              onTap: () => onOpen(option.route),
            ),
          ),
      ],
    );
  }

  double _columnWidth(BuildContext context, int columns) {
    final maxWidth = MediaQuery.sizeOf(context).width.clamp(
          0.0,
          UserLandmarkStudioScreen._maxContentWidth,
        );
    final available = maxWidth -
        (OpenVtsSpacing.md * 2) -
        (OpenVtsSpacing.sm * (columns - 1));
    return available / columns;
  }
}

class _LandmarkOption {
  const _LandmarkOption({
    required this.label,
    required this.description,
    required this.cta,
    required this.icon,
    required this.route,
  });

  final String label;
  final String description;
  final String cta;
  final IconData icon;
  final String route;
}

class _LandmarkOptionCard extends StatelessWidget {
  const _LandmarkOptionCard({required this.option, required this.onTap});

  final _LandmarkOption option;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final iconBg =
        isDark ? OpenVtsColors.darkSurface : OpenVtsColors.surfaceElevated;
    final titleColor =
        isDark ? OpenVtsColors.darkTextPrimary : OpenVtsColors.textPrimary;
    final subtitleColor =
        isDark ? OpenVtsColors.darkTextSecondary : OpenVtsColors.textSecondary;

    return OpenVtsCard(
      onTap: onTap,
      padding: const EdgeInsets.all(OpenVtsSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(OpenVtsRadius.md),
                  border: Border.all(color: OpenVtsColors.border),
                ),
                child: Icon(option.icon, size: 18, color: titleColor),
              ),
              const SizedBox(width: OpenVtsSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      option.label,
                      style: OpenVtsTypography.titleSmall.copyWith(
                        color: titleColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      option.description,
                      style: OpenVtsTypography.meta.copyWith(
                        color: subtitleColor,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: OpenVtsSpacing.xs, top: 2),
                child: Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: subtitleColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: OpenVtsSpacing.sm),
          OpenVtsButton(
            label: option.cta,
            onPressed: onTap,
            variant: OpenVtsButtonVariant.secondary,
            height: 40,
            trailingIcon: Icons.arrow_forward,
          ),
        ],
      ),
    );
  }
}
