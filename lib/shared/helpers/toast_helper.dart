import 'package:flutter/material.dart';

enum ToastType { info, success, error }

class ToastHelper {
  const ToastHelper._();

  static final messengerKey = GlobalKey<ScaffoldMessengerState>();

  static void show(BuildContext? context, String message) {
    _show(message, type: ToastType.info, context: context);
  }

  static void showSuccess(String message, {BuildContext? context}) {
    _show(message, type: ToastType.success, context: context);
  }

  static void showInfo(String message, {BuildContext? context}) {
    _show(message, type: ToastType.info, context: context);
  }

  static void showError(String message, {BuildContext? context}) {
    _show(message, type: ToastType.error, context: context);
  }

  static void _show(
    String message, {
    required ToastType type,
    BuildContext? context,
  }) {
    final messenger = messengerKey.currentState ??
        (context != null ? ScaffoldMessenger.maybeOf(context) : null);

    if (messenger == null) {
      return;
    }

    final themeContext = context ?? messengerKey.currentContext ?? messenger.context;
    final colorScheme = Theme.of(themeContext).colorScheme;
    final icon = switch (type) {
      ToastType.success => Icons.check_circle_outline_rounded,
      ToastType.error => Icons.error_outline_rounded,
      ToastType.info => Icons.info_outline_rounded,
    };

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: colorScheme.inverseSurface,
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          content: Row(
            children: [
              Icon(icon, color: colorScheme.primary, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: Theme.of(themeContext).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onInverseSurface,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
          ),
        ),
      );
  }
}
