import 'package:flutter/material.dart';

import '../../../models/user_dashboard_model.dart';
import 'user_day_night_comparison_widget.dart';
import 'user_fleet_status_widget.dart';
import 'user_recent_alerts_widget.dart';
import 'user_send_command_dashboard_widget.dart';
import 'user_sensor_history_widget.dart';
import 'user_top_performing_assets_widget.dart';
import 'user_unknown_dashboard_widget.dart';
import 'user_usage_last_7_days_widget.dart';
import 'user_weekly_comparison_widget.dart';

class UserDashboardWidgetDefinition {
  const UserDashboardWidgetDefinition({
    required this.title,
    required this.icon,
    required this.builder,
  });

  final String title;
  final IconData icon;
  final UserDashboardWidgetBuilder builder;
}

typedef UserDashboardWidgetBuilder = Widget Function(
  UserDashboardWidgetConfig config,
  int refreshTick,
);

final Map<String, UserDashboardWidgetDefinition> userDashboardWidgetRegistry = {
  'component_1': UserDashboardWidgetDefinition(
    title: 'Fleet Status',
    icon: Icons.directions_car_filled_outlined,
    builder: (config, refreshTick) => UserFleetStatusWidget(
      config: config,
      refreshTick: refreshTick,
    ),
  ),
  'fleet_status': UserDashboardWidgetDefinition(
    title: 'Fleet Status',
    icon: Icons.directions_car_filled_outlined,
    builder: (config, refreshTick) => UserFleetStatusWidget(
      config: config,
      refreshTick: refreshTick,
    ),
  ),
  'component_2': UserDashboardWidgetDefinition(
    title: '7-Day Usage',
    icon: Icons.bar_chart_rounded,
    builder: (config, refreshTick) => UserUsageLast7DaysWidget(
      config: config,
      refreshTick: refreshTick,
    ),
  ),
  'usage_last_7_days': UserDashboardWidgetDefinition(
    title: '7-Day Usage',
    icon: Icons.bar_chart_rounded,
    builder: (config, refreshTick) => UserUsageLast7DaysWidget(
      config: config,
      refreshTick: refreshTick,
    ),
  ),
  'component_3': UserDashboardWidgetDefinition(
    title: 'Recent Alerts',
    icon: Icons.notifications_active_outlined,
    builder: (config, refreshTick) => UserRecentAlertsWidget(
      config: config,
      refreshTick: refreshTick,
    ),
  ),
  'recent_alerts': UserDashboardWidgetDefinition(
    title: 'Recent Alerts',
    icon: Icons.notifications_active_outlined,
    builder: (config, refreshTick) => UserRecentAlertsWidget(
      config: config,
      refreshTick: refreshTick,
    ),
  ),
  'component_4': UserDashboardWidgetDefinition(
    title: 'Weekly Comparison',
    icon: Icons.compare_arrows_rounded,
    builder: (config, refreshTick) => UserWeeklyComparisonWidget(
      config: config,
      refreshTick: refreshTick,
    ),
  ),
  'weekly_comparison': UserDashboardWidgetDefinition(
    title: 'Weekly Comparison',
    icon: Icons.compare_arrows_rounded,
    builder: (config, refreshTick) => UserWeeklyComparisonWidget(
      config: config,
      refreshTick: refreshTick,
    ),
  ),
  'component_5': UserDashboardWidgetDefinition(
    title: 'Top Performing Assets',
    icon: Icons.leaderboard_outlined,
    builder: (config, refreshTick) => UserTopPerformingAssetsWidget(
      config: config,
      refreshTick: refreshTick,
    ),
  ),
  'top_performing_assets': UserDashboardWidgetDefinition(
    title: 'Top Performing Assets',
    icon: Icons.leaderboard_outlined,
    builder: (config, refreshTick) => UserTopPerformingAssetsWidget(
      config: config,
      refreshTick: refreshTick,
    ),
  ),
  'component_6': UserDashboardWidgetDefinition(
    title: 'Sensor History',
    icon: Icons.sensors_rounded,
    builder: (config, refreshTick) => UserSensorHistoryWidget(
      config: config,
      refreshTick: refreshTick,
    ),
  ),
  'sensor_history': UserDashboardWidgetDefinition(
    title: 'Sensor History',
    icon: Icons.sensors_rounded,
    builder: (config, refreshTick) => UserSensorHistoryWidget(
      config: config,
      refreshTick: refreshTick,
    ),
  ),
  'component_7': UserDashboardWidgetDefinition(
    title: 'Send Command',
    icon: Icons.terminal_rounded,
    builder: (config, refreshTick) => UserSendCommandDashboardWidget(
      config: config,
      refreshTick: refreshTick,
    ),
  ),
  'send_command': UserDashboardWidgetDefinition(
    title: 'Send Command',
    icon: Icons.terminal_rounded,
    builder: (config, refreshTick) => UserSendCommandDashboardWidget(
      config: config,
      refreshTick: refreshTick,
    ),
  ),
  'component_9': UserDashboardWidgetDefinition(
    title: 'Day / Night Comparison',
    icon: Icons.dark_mode_outlined,
    builder: (config, refreshTick) => UserDayNightComparisonWidget(
      config: config,
      refreshTick: refreshTick,
    ),
  ),
  'day_night_comparison': UserDashboardWidgetDefinition(
    title: 'Day / Night Comparison',
    icon: Icons.dark_mode_outlined,
    builder: (config, refreshTick) => UserDayNightComparisonWidget(
      config: config,
      refreshTick: refreshTick,
    ),
  ),
};

Widget buildUserDashboardWidget({
  required UserDashboardWidgetConfig config,
  required int refreshTick,
}) {
  final definition = userDashboardWidgetRegistry[config.type];
  if (definition == null) {
    return UserUnknownDashboardWidget(config: config);
  }

  return definition.builder(config, refreshTick);
}
