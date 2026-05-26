import 'dart:async';

import 'package:flutter/widgets.dart';

class MobilePushLifecycleObserver extends WidgetsBindingObserver {
  MobilePushLifecycleObserver({required this.onResume});

  final FutureOr<void> Function() onResume;

  void attach() {
    WidgetsBinding.instance.addObserver(this);
  }

  void detach() {
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(Future<void>.sync(onResume));
    }
  }
}
