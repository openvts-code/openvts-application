import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_vts/app_entry.dart';

import 'core/notifications/mobile_push_lifecycle_observer.dart';
import 'core/notifications/mobile_push_navigation.dart';
import 'core/notifications/mobile_push_service.dart';
import 'core/providers/core_providers.dart';
import 'core/router/app_router.dart';
import 'core/theme/open_vts_theme.dart';
import 'features/auth/controllers/auth_controller.dart';
import 'features/auth/controllers/auth_state.dart';
import 'shared/helpers/toast_helper.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);

    return _MobilePushLifecycleScope(
      child: MaterialApp.router(
        title: 'OpenVTS',
        debugShowCheckedModeBanner: false,
        scaffoldMessengerKey: ToastHelper.messengerKey,
        theme: OpenVtsTheme.light,
        darkTheme: OpenVtsTheme.dark,
        themeMode: themeMode,
        routerConfig: router,
        builder: (context, child) => AppEntry(
          child: child ?? const SizedBox.shrink(),
        ),
      ),
    );
  }
}

class _MobilePushLifecycleScope extends ConsumerStatefulWidget {
  const _MobilePushLifecycleScope({required this.child});

  final Widget child;

  @override
  ConsumerState<_MobilePushLifecycleScope> createState() =>
      _MobilePushLifecycleScopeState();
}

class _MobilePushLifecycleScopeState
    extends ConsumerState<_MobilePushLifecycleScope> {
  late final MobilePushLifecycleObserver _lifecycleObserver;
  late final MobilePushNavigation _mobilePushNavigation;
  late final MobilePushService _mobilePushService;

  @override
  void initState() {
    super.initState();
    _mobilePushNavigation = MobilePushNavigation(ref);
    _mobilePushService = ref.read(mobilePushServiceProvider)
      ..setNavigationHandler(_mobilePushNavigation.handleNotificationTap)
      ..setNotificationCenterRefreshHook(
        _mobilePushNavigation.handleForegroundMessage,
      );
    _lifecycleObserver = MobilePushLifecycleObserver(onResume: _handleResume)
      ..attach();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      // Run mobile push setup fully in the background after first frame so
      // notification failures cannot delay splash/login/role home rendering.
      Future<void>.microtask(() async {
        if (!mounted) {
          return;
        }

        final authState = ref.read(authControllerProvider);
        final controller = ref.read(mobilePushControllerProvider.notifier);
        controller.updateAuthenticationState(
          isAuthenticated: authState.isAuthenticated,
        );
        // Hydrate cached push state only. Do not trigger remote config
        // fetches or token registration at cold startup — those are gated
        // and performed only after auth/session restore when allowed.
        unawaited(controller.initializeAfterAppStart());
        if (authState.isAuthenticated) {
          unawaited(
            _mobilePushNavigation.consumePendingNotificationTapIfPossible(),
          );
        }
      });
    });
  }

  @override
  void dispose() {
    _mobilePushService
      ..setNavigationHandler(null)
      ..setNotificationCenterRefreshHook(null);
    _lifecycleObserver.detach();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authControllerProvider, (previous, next) {
      final controller = ref.read(mobilePushControllerProvider.notifier);
      controller.updateAuthenticationState(
        isAuthenticated: next.isAuthenticated,
      );

      if (_shouldRegisterForAuthChange(previous, next)) {
        // Attempt background registration only when controller gating allows
        // it (cached permission, cached config, cooldown cleared, etc.).
        if (controller.shouldAttemptBackgroundRegistration) {
          unawaited(controller.registerTokenForCurrentSession());
        }
      }
      if (next.isAuthenticated) {
        unawaited(
          _mobilePushNavigation.consumePendingNotificationTapIfPossible(),
        );
      }
    });

    return widget.child;
  }

  Future<void> _handleResume() async {
    final authState = ref.read(authControllerProvider);
    final controller = ref.read(mobilePushControllerProvider.notifier);
    controller.updateAuthenticationState(
      isAuthenticated: authState.isAuthenticated,
    );

    // Resume path must not await network work and should only attempt
    // fire-and-forget registration when cached gating allows it.
    if (authState.isAuthenticated &&
        controller.shouldAttemptBackgroundRegistration) {
      unawaited(controller.registerTokenForCurrentSession());
    }
  }

  bool _shouldRegisterForAuthChange(AuthState? previous, AuthState next) {
    if (!next.isAuthenticated) {
      return false;
    }

    return previous?.isAuthenticated != true ||
        previous?.user?.id != next.user?.id ||
        previous?.activeRole != next.activeRole;
  }
}
