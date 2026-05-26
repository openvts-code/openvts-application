import 'package:flutter/material.dart';

import '../../../live_map/models/live_map_role_config.dart';
import '../../../live_map/screens/live_map_screen.dart';

/// User live-map screen.
///
/// Thin role wrapper around the shared [LiveMapScreen]. The full polished
/// telemetry / overlay / drawer / replay / history / commands UI is exactly
/// the same as the superadmin one — only the underlying endpoints, storage
/// keys, default home route, and command-send mode change, all supplied by
/// [LiveMapRoleConfig.user].
class UserMapScreen extends StatelessWidget {
  const UserMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LiveMapScreen(config: LiveMapRoleConfig.user());
  }
}
