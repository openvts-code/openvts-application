import 'package:flutter/material.dart';

import '../../../live_map/models/live_map_role_config.dart';
import '../../../live_map/screens/live_map_screen.dart';

/// Superadmin live-map screen.
///
/// This is now a thin role wrapper around the shared [LiveMapScreen]. All
/// telemetry / overlay / drawer / replay / history / commands UI lives in
/// `lib/features/live_map/screens/live_map_screen.dart` and is identical
/// across superadmin / admin / user roles. Role-specific endpoints, storage
/// keys, default home route, and command-send mode are supplied by the
/// [LiveMapRoleConfig.superadmin] factory.
class SuperadminMapScreen extends StatelessWidget {
  const SuperadminMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LiveMapScreen(config: LiveMapRoleConfig.superadmin());
  }
}
