import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/open_vts_colors.dart';
import '../../core/theme/open_vts_spacing.dart';
import '../../core/theme/open_vts_typography.dart';

class OpenVtsRoleHomeItem {
  const OpenVtsRoleHomeItem({
    required this.label,
    required this.icon,
    required this.route,
  });

  final String label;
  final IconData icon;
  final String route;
}

String? resolveProfileImageUrl(String baseUrl, String? profileUrl) {
  final normalizedProfileUrl = profileUrl?.trim();
  if (normalizedProfileUrl == null || normalizedProfileUrl.isEmpty) {
    return null;
  }

  if (normalizedProfileUrl.startsWith('http://') ||
      normalizedProfileUrl.startsWith('https://')) {
    return normalizedProfileUrl;
  }

  final rootUri = Uri.tryParse(baseUrl);
  if (rootUri == null) {
    return null;
  }

  final originRoot = rootUri.replace(
    path: '/',
    queryParameters: null,
    fragment: null,
  );

  if (normalizedProfileUrl.startsWith('/')) {
    return originRoot.resolve(normalizedProfileUrl).toString();
  }

  var basePath = rootUri.path;
  if (basePath.isEmpty) {
    basePath = '/';
  }
  if (!basePath.endsWith('/')) {
    basePath = '$basePath/';
  }

  final apiRoot = rootUri.replace(
    path: basePath,
    queryParameters: null,
    fragment: null,
  );

  return apiRoot.resolve(normalizedProfileUrl).toString();
}

class OpenVtsRoleHome extends StatelessWidget {
  const OpenVtsRoleHome({
    required this.displayName,
    required this.roleLabel,
    required this.items,
    required this.onToggleTheme,
    required this.onNotificationsPressed,
    required this.onProfilePressed,
    this.notificationBadgeCount = 0,
    this.profileImageUrl,
    super.key,
  });

  final String displayName;
  final String roleLabel;
  final List<OpenVtsRoleHomeItem> items;
  final VoidCallback onToggleTheme;
  final VoidCallback onNotificationsPressed;
  final VoidCallback onProfilePressed;
  final int notificationBadgeCount;
  final String? profileImageUrl;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currentPath = GoRouterState.of(context).uri.path;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final pageHorizontalPadding = _pageHorizontalPadding(screenWidth);
    final headerGap = _headerGap(screenWidth);
    final footerPadding = _footerPadding(screenWidth);
    final logoHeight = _logoHeight(screenWidth);
    final contentHorizontalPadding =
        screenWidth < 520 ? 0.0 : OpenVtsSpacing.sm;
    final gridMainSpacing = _gridMainSpacing(screenWidth);
    final gridCrossSpacing = _gridCrossSpacing(screenWidth);
    final gridChildAspectRatio = _gridChildAspectRatio(screenWidth);
    final topBarColor =
        isDark ? OpenVtsColors.darkSurface : OpenVtsColors.white;
    final cardColor = isDark
        ? OpenVtsColors.darkSurface.withValues(alpha: 0.94)
        : OpenVtsColors.white.withValues(alpha: 0.96);
    final borderColor =
        isDark ? OpenVtsColors.darkBorder : OpenVtsColors.border;
    final secondaryTextColor =
        isDark ? OpenVtsColors.darkTextSecondary : OpenVtsColors.textSecondary;
    final tertiaryTextColor =
        theme.colorScheme.onSurface.withValues(alpha: 0.58);

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? const [
                    OpenVtsColors.darkBackground,
                    OpenVtsColors.brandInk,
                    OpenVtsColors.darkBackground,
                  ]
                : const [
                    Color(0xFFF4F1EC),
                    OpenVtsColors.background,
                    Color(0xFFF7F6F3),
                  ],
          ),
        ),
        child: Column(
          children: [
            SafeArea(
              bottom: false,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: topBarColor,
                  border: Border(
                    bottom: BorderSide(color: borderColor),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: OpenVtsColors.brandInk.withValues(
                        alpha: isDark ? 0.22 : 0.08,
                      ),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: pageHorizontalPadding,
                    vertical: OpenVtsSpacing.xs,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1180),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Fleet OS',
                              style: OpenVtsTypography.titleSmall.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          _TopBarAction(
                            tooltip: isDark ? 'Light mode' : 'Dark mode',
                            icon: isDark
                                ? Icons.light_mode_outlined
                                : Icons.dark_mode_outlined,
                            borderColor: borderColor,
                            onPressed: onToggleTheme,
                          ),
                          const SizedBox(width: OpenVtsSpacing.xxs),
                          _TopBarAction(
                            tooltip: 'Notifications',
                            icon: Icons.notifications_none_rounded,
                            borderColor: borderColor,
                            badgeCount: notificationBadgeCount,
                            onPressed: onNotificationsPressed,
                          ),
                          const SizedBox(width: OpenVtsSpacing.xxs),
                          Tooltip(
                            message: 'Profile',
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                customBorder: const CircleBorder(),
                                onTap: onProfilePressed,
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: borderColor),
                                    color: isDark
                                        ? OpenVtsColors.brandInkSoft
                                        : OpenVtsColors.surface,
                                  ),
                                  child: ClipOval(
                                    child: profileImageUrl == null
                                        ? Center(
                                            child: Text(
                                              _initialsFromName(displayName),
                                              style: OpenVtsTypography.meta
                                                  .copyWith(
                                                color:
                                                    theme.colorScheme.onSurface,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          )
                                        : Image.network(
                                            profileImageUrl!,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) {
                                              return Icon(
                                                Icons.person_outline_rounded,
                                                size: 18,
                                                color:
                                                    theme.colorScheme.onSurface,
                                              );
                                            },
                                          ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: SafeArea(
                top: false,
                child: CustomScrollView(
                  slivers: [
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                        pageHorizontalPadding,
                        headerGap,
                        pageHorizontalPadding,
                        0,
                      ),
                      sliver: SliverToBoxAdapter(
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 980),
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: contentHorizontalPadding,
                              ),
                              child: Column(
                                children: [
                                  Image.asset(
                                    'assets/brand/logo.png',
                                    height: logoHeight,
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, __, ___) {
                                      return Text(
                                        'Open VTS',
                                        style: OpenVtsTypography.brandTitle
                                            .copyWith(
                                          color: theme.colorScheme.onSurface,
                                          fontSize: screenWidth < 520 ? 24 : 30,
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(height: OpenVtsSpacing.xxs),
                                  Text(
                                    '$roleLabel workspace',
                                    style: OpenVtsTypography.meta.copyWith(
                                      color: secondaryTextColor,
                                      letterSpacing: 0.2,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  SizedBox(height: headerGap),
                                  GridView.builder(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount: items.length,
                                    gridDelegate:
                                        SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount:
                                          _gridColumnCount(screenWidth),
                                      mainAxisSpacing: gridMainSpacing,
                                      crossAxisSpacing: gridCrossSpacing,
                                      childAspectRatio: gridChildAspectRatio,
                                    ),
                                    itemBuilder: (context, index) {
                                      final item = items[index];
                                      final isActive =
                                          currentPath == item.route;

                                      return _DesktopLauncherTile(
                                        screenWidth: screenWidth,
                                        label: item.label,
                                        icon: item.icon,
                                        isActive: isActive,
                                        borderColor: borderColor,
                                        backgroundColor: cardColor,
                                        activeColor: theme.colorScheme.primary,
                                        secondaryTextColor: tertiaryTextColor,
                                        onTap: () {
                                          if (!isActive) {
                                            context.push(item.route);
                                          }
                                        },
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          pageHorizontalPadding,
                          screenWidth < 520
                              ? OpenVtsSpacing.xs
                              : OpenVtsSpacing.sm,
                          pageHorizontalPadding,
                          footerPadding,
                        ),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 980),
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: contentHorizontalPadding,
                              ),
                              child: Align(
                                alignment: Alignment.bottomCenter,
                                child: Text(
                                  '© 2026 Open VTS All rights reserved.',
                                  style: OpenVtsTypography.meta.copyWith(
                                    color: secondaryTextColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static int _gridColumnCount(double width) {
    if (width >= 980) return 6;
    if (width >= 760) return 5;
    if (width >= 520) return 4;
    return 3;
  }

  static double _gridMainSpacing(double width) {
    if (width < 520) return OpenVtsSpacing.xs;
    return OpenVtsSpacing.sm;
  }

  static double _pageHorizontalPadding(double width) {
    if (width < 520) return OpenVtsSpacing.sm;
    return OpenVtsSpacing.md;
  }

  static double _logoHeight(double width) {
    if (width < 520) return 54;
    return 72;
  }

  static double _headerGap(double width) {
    if (width < 520) return OpenVtsSpacing.xs;
    return OpenVtsSpacing.sm;
  }

  static double _footerPadding(double width) {
    if (width < 520) return OpenVtsSpacing.md;
    return OpenVtsSpacing.lg;
  }

  static double _gridCrossSpacing(double width) {
    if (width < 520) return OpenVtsSpacing.xs;
    return OpenVtsSpacing.sm;
  }

  static double _gridChildAspectRatio(double width) {
    if (width >= 900) return 1.16;
    if (width >= 700) return 1.08;
    if (width >= 520) return 1.0;
    if (width >= 360) return 0.96;
    return 0.92;
  }

  static _LauncherTileMetrics _tileMetrics(double width) {
    if (width < 360) {
      return const _LauncherTileMetrics(
        iconBoxSize: 50,
        iconSize: 19,
        radius: 15,
        labelFontSize: 10.5,
        labelLineHeight: 1.18,
        labelGap: 4,
      );
    }

    if (width < 520) {
      return const _LauncherTileMetrics(
        iconBoxSize: 54,
        iconSize: 20,
        radius: 16,
        labelFontSize: 11,
        labelLineHeight: 1.18,
        labelGap: 4,
      );
    }

    if (width < 760) {
      return const _LauncherTileMetrics(
        iconBoxSize: 62,
        iconSize: 22,
        radius: 18,
        labelFontSize: 11.5,
        labelLineHeight: 1.16,
        labelGap: 5,
      );
    }

    return const _LauncherTileMetrics(
      iconBoxSize: 72,
      iconSize: 24,
      radius: 22,
      labelFontSize: 12,
      labelLineHeight: 1.15,
      labelGap: 6,
    );
  }

  static String _initialsFromName(String value) {
    final parts = value
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();

    if (parts.isEmpty) {
      return 'OV';
    }

    if (parts.length == 1) {
      return parts.first
          .substring(0, parts.first.length.clamp(1, 2))
          .toUpperCase();
    }

    return (parts.first[0] + parts.last[0]).toUpperCase();
  }
}

class _LauncherTileMetrics {
  const _LauncherTileMetrics({
    required this.iconBoxSize,
    required this.iconSize,
    required this.radius,
    required this.labelFontSize,
    required this.labelLineHeight,
    required this.labelGap,
  });

  final double iconBoxSize;
  final double iconSize;
  final double radius;
  final double labelFontSize;
  final double labelLineHeight;
  final double labelGap;
}

class _DesktopLauncherTile extends StatelessWidget {
  const _DesktopLauncherTile({
    required this.screenWidth,
    required this.label,
    required this.icon,
    required this.isActive,
    required this.borderColor,
    required this.backgroundColor,
    required this.activeColor,
    required this.secondaryTextColor,
    required this.onTap,
  });

  final double screenWidth;
  final String label;
  final IconData icon;
  final bool isActive;
  final Color borderColor;
  final Color backgroundColor;
  final Color activeColor;
  final Color secondaryTextColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final metrics = OpenVtsRoleHome._tileMetrics(screenWidth);
    final labelHorizontalPadding = screenWidth < 360
        ? 1.0
        : screenWidth < 520
            ? 2.0
            : OpenVtsSpacing.xxs;
    final shadowBlur = screenWidth < 520 ? 9.0 : 14.0;
    final shadowOffset = screenWidth < 520 ? 3.0 : 5.0;
    final shadowAlpha = screenWidth < 520 ? 0.04 : 0.05;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(metrics.radius),
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: metrics.iconBoxSize,
              height: metrics.iconBoxSize,
              decoration: BoxDecoration(
                color: isActive
                    ? activeColor.withValues(alpha: 0.08)
                    : backgroundColor,
                borderRadius: BorderRadius.circular(metrics.radius),
                border: Border.all(
                  color: isActive ? activeColor : borderColor,
                ),
                boxShadow: [
                  BoxShadow(
                    color:
                        OpenVtsColors.brandInk.withValues(alpha: shadowAlpha),
                    blurRadius: shadowBlur,
                    offset: Offset(0, shadowOffset),
                  ),
                ],
              ),
              child: Icon(
                icon,
                size: metrics.iconSize,
                color: isActive
                    ? activeColor
                    : Theme.of(context).colorScheme.onSurface,
              ),
            ),
            SizedBox(height: metrics.labelGap),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: labelHorizontalPadding),
              child: Text(
                label,
                style: OpenVtsTypography.meta.copyWith(
                  color: secondaryTextColor,
                  fontWeight: FontWeight.w500,
                  fontSize: metrics.labelFontSize,
                  height: metrics.labelLineHeight,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopBarAction extends StatelessWidget {
  const _TopBarAction({
    required this.tooltip,
    required this.icon,
    required this.borderColor,
    required this.onPressed,
    this.badgeCount = 0,
  });

  final String tooltip;
  final IconData icon;
  final Color borderColor;
  final VoidCallback onPressed;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onPressed,
            child: Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: borderColor),
              ),
              child: Tooltip(
                message: tooltip,
                child: Icon(icon, size: 20),
              ),
            ),
          ),
        ),
        if (badgeCount > 0)
          PositionedDirectional(
            end: -4,
            top: -4,
            child: Container(
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: OpenVtsColors.brandInk,
                borderRadius: BorderRadius.all(Radius.circular(999)),
              ),
              child: Text(
                badgeCount.toString(),
                style: OpenVtsTypography.meta.copyWith(
                  color: OpenVtsColors.white,
                  fontWeight: FontWeight.w700,
                  height: 1,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
