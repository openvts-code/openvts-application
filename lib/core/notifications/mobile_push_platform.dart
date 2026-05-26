import 'package:flutter/foundation.dart';

enum MobilePushPlatform {
  android,
  ios,
  unsupported;

  String get apiValue {
    switch (this) {
      case MobilePushPlatform.android:
        return 'android';
      case MobilePushPlatform.ios:
        return 'ios';
      case MobilePushPlatform.unsupported:
        return 'unsupported';
    }
  }

  bool get isSupported => this != MobilePushPlatform.unsupported;

  static MobilePushPlatform fromCurrentPlatform() {
    if (kIsWeb) {
      return MobilePushPlatform.unsupported;
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return MobilePushPlatform.android;
      case TargetPlatform.iOS:
        return MobilePushPlatform.ios;
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
        return MobilePushPlatform.unsupported;
    }
  }

  static MobilePushPlatform fromApiValue(String? value) {
    switch (value?.trim().toLowerCase()) {
      case 'android':
        return MobilePushPlatform.android;
      case 'ios':
        return MobilePushPlatform.ios;
      default:
        return MobilePushPlatform.unsupported;
    }
  }
}
