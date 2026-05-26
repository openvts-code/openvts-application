import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/open_vts_colors.dart';
import '../../core/theme/open_vts_radius.dart';
import '../../core/theme/open_vts_spacing.dart';
import '../../features/auth/controllers/auth_controller.dart';

enum OpenVtsPageHeaderMode { standard, closeable }

class OpenVtsPageScaffold extends ConsumerWidget {
  const OpenVtsPageScaffold({
    required this.title,
    required this.body,
    this.actions,
    this.leading,
    this.padding = const EdgeInsets.all(OpenVtsSpacing.sm),
    this.headerMode = OpenVtsPageHeaderMode.standard,
    this.onClose,
    super.key,
  });

  final String title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? leading;
  final EdgeInsetsGeometry padding;
  final OpenVtsPageHeaderMode headerMode;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(authControllerProvider.select((state) => state.role));

    return Scaffold(
      appBar: headerMode == OpenVtsPageHeaderMode.closeable
          ? _CloseablePageHeader(
              title: title,
              actions: actions,
              leading: leading,
              onClose: onClose,
              closeFallbackRoute: role?.homePath,
            )
          : AppBar(
              leading: leading,
              title: Text(title),
              actions: actions,
            ),
      body: SafeArea(
        child: Padding(
          padding: padding,
          child: body,
        ),
      ),
    );
  }
}

class _CloseablePageHeader extends StatelessWidget
    implements PreferredSizeWidget {
  const _CloseablePageHeader({
    required this.title,
    this.actions,
    this.leading,
    this.onClose,
    this.closeFallbackRoute,
  });

  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final VoidCallback? onClose;
  final String? closeFallbackRoute;

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final titleStyle = (theme.appBarTheme.titleTextStyle ??
            theme.textTheme.titleSmall)
        ?.copyWith(
          color: isDark
              ? OpenVtsColors.darkTextPrimary
              : OpenVtsColors.textPrimary,
          fontWeight: FontWeight.w600,
        );

    return AppBar(
      automaticallyImplyLeading: false,
      toolbarHeight: preferredSize.height,
      backgroundColor:
          isDark ? OpenVtsColors.darkSurface : OpenVtsColors.surfaceElevated,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.black.withValues(alpha: isDark ? 0.22 : 0.12),
      elevation: 6,
      scrolledUnderElevation: 6,
      leading: leading,
      leadingWidth: leading == null ? null : 60,
      titleSpacing: leading == null ? OpenVtsSpacing.sm : OpenVtsSpacing.xs,
      title: Text(
        title,
        style: titleStyle,
      ),
      actions: [
        ...?actions,
        Padding(
          padding: const EdgeInsets.only(right: OpenVtsSpacing.xs),
          child: IconButton(
            tooltip: 'Close page',
            onPressed: onClose ?? () => _handleClose(context),
            style: IconButton.styleFrom(
              backgroundColor:
                  isDark ? OpenVtsColors.surfaceElevated : OpenVtsColors.brandInk,
              foregroundColor:
                  isDark ? OpenVtsColors.brandInk : OpenVtsColors.white,
              minimumSize: const Size.square(36),
              padding: EdgeInsets.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(OpenVtsRadius.pill),
              ),
            ),
            icon: const Icon(Icons.close_rounded, size: 18),
          ),
        ),
      ],
    );
  }

  void _handleClose(BuildContext context) {
    if (context.canPop()) {
      context.pop();
      return;
    }

    if (closeFallbackRoute != null) {
      context.go(closeFallbackRoute!);
    }
  }
}
