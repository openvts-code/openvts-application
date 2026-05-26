import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/open_vts_colors.dart';
import '../../../../../core/theme/open_vts_radius.dart';
import '../../../../../core/theme/open_vts_spacing.dart';
import '../../../../../core/theme/open_vts_typography.dart';
import '../../../../../core/utils/date_time_formatter.dart';
import '../../../../../shared/helpers/toast_helper.dart';
import '../../../../../shared/widgets/open_vts_bottom_sheet.dart';
import '../../../../../shared/widgets/open_vts_button.dart';
import '../../../../../shared/widgets/open_vts_card.dart';
import '../../../../../shared/widgets/open_vts_empty_state.dart';
import '../../../../../shared/widgets/open_vts_search_field.dart';
import '../../../controllers/user_vehicle_details_controller.dart';
import '../../../models/user_vehicle_model.dart';
import '../../../models/user_vehicle_state.dart';
import 'user_vehicle_sensor_history_sheet.dart';
import 'user_vehicle_sensor_sheet.dart';

const DateTimeFormatter _dateFormatter = DateTimeFormatter();

class UserVehicleSensorsTabView extends ConsumerStatefulWidget {
  const UserVehicleSensorsTabView({required this.provider, super.key});

  final AutoDisposeStateNotifierProvider<UserVehicleDetailsController,
      UserVehicleDetailsState> provider;

  @override
  ConsumerState<UserVehicleSensorsTabView> createState() =>
      _UserVehicleSensorsTabViewState();
}

class _UserVehicleSensorsTabViewState
    extends ConsumerState<UserVehicleSensorsTabView> {
  Timer? _searchDebounce;
  var _searchQuery = '';

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(widget.provider);
    final controller = ref.read(widget.provider.notifier);
    final isInitialLoading = state.isLoadingSensors && state.sensors.isEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _HeaderCard(
          count: state.sensors.length,
          isLoading: state.isLoadingSensors,
          onAdd: () => _showSensorSheet(context, null),
          onSearchChanged: _onSearchChanged,
        ),
        if (state.sectionErrorMessage != null && !isInitialLoading) ...[
          const SizedBox(height: OpenVtsSpacing.sm),
          _InlineError(message: state.sectionErrorMessage!),
        ],
        const SizedBox(height: OpenVtsSpacing.sm),
        if (isInitialLoading)
          const _LoadingCard(label: 'Loading sensors')
        else if (state.sectionErrorMessage != null && state.sensors.isEmpty)
          _ErrorCard(
            message: state.sectionErrorMessage!,
            onRetry: () => controller.loadSensors(),
          )
        else if (state.sensors.isEmpty)
          _EmptySensorsCard(
            hasSearch: _searchQuery.trim().isNotEmpty,
            onAdd: () => _showSensorSheet(context, null),
          )
        else
          for (final sensor in state.sensors) ...[
            _SensorCard(
              sensor: sensor,
              isBusy: state.isUpdatingSensor ||
                  state.isDeletingSensor ||
                  state.isLoadingSensorHistory,
              onEdit: () => _showSensorSheet(context, sensor),
              onHistory: () => _showHistorySheet(context, sensor),
              onDelete: () => _confirmDeleteSensor(context, sensor),
            ),
            if (sensor != state.sensors.last)
              const SizedBox(height: OpenVtsSpacing.sm),
          ],
      ],
    );
  }

  void _onSearchChanged(String value) {
    _searchQuery = value;
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      ref.read(widget.provider.notifier).loadSensors(search: value);
    });
  }

  Future<void> _showSensorSheet(
    BuildContext context,
    UserVehicleSensor? sensor,
  ) {
    return OpenVtsBottomSheet.show<void>(
      context: context,
      title: sensor == null ? 'Add Sensor' : 'Edit Sensor',
      initialChildSize: 0.78,
      minChildSize: 0.46,
      maxChildSize: 0.94,
      child: UserVehicleSensorSheet(
        provider: widget.provider,
        sensor: sensor,
      ),
    );
  }

  Future<void> _showHistorySheet(
    BuildContext context,
    UserVehicleSensor sensor,
  ) {
    return OpenVtsBottomSheet.show<void>(
      context: context,
      title: 'Sensor History',
      initialChildSize: 0.72,
      minChildSize: 0.48,
      maxChildSize: 0.94,
      child: UserVehicleSensorHistorySheet(
        provider: widget.provider,
        sensor: sensor,
      ),
    );
  }

  Future<void> _confirmDeleteSensor(
    BuildContext context,
    UserVehicleSensor sensor,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete sensor'),
        content: Text('Remove ${sensor.title}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(foregroundColor: OpenVtsColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;
    final ok = await ref.read(widget.provider.notifier).deleteSensor(sensor.id);
    if (!context.mounted) return;
    if (ok) {
      ToastHelper.showSuccess('Sensor deleted.', context: context);
      return;
    }

    ToastHelper.showError(
      ref.read(widget.provider).sectionErrorMessage ??
          'Unable to delete sensor.',
      context: context,
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.count,
    required this.isLoading,
    required this.onAdd,
    required this.onSearchChanged,
  });

  final int count;
  final bool isLoading;
  final VoidCallback onAdd;
  final ValueChanged<String> onSearchChanged;

  @override
  Widget build(BuildContext context) {
    return OpenVtsCard(
      padding: const EdgeInsets.all(OpenVtsSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.sensors_outlined, size: 17),
                    const SizedBox(width: OpenVtsSpacing.xs),
                    Text(
                      'Sensors',
                      style: OpenVtsTypography.label.copyWith(
                        color: OpenVtsColors.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: OpenVtsSpacing.xs),
                    Text(
                      '$count',
                      style: OpenVtsTypography.meta.copyWith(
                        color: OpenVtsColors.textSecondary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (isLoading) ...[
                      const SizedBox(width: OpenVtsSpacing.xs),
                      const SizedBox(
                        width: 13,
                        height: 13,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ],
                  ],
                ),
              ),
              _SmallButton(
                label: 'Add Sensor',
                icon: Icons.add_rounded,
                onPressed: onAdd,
              ),
            ],
          ),
          const SizedBox(height: OpenVtsSpacing.sm),
          OpenVtsSearchField(
            hintText: 'Search sensors',
            onChanged: onSearchChanged,
          ),
        ],
      ),
    );
  }
}

class _SensorCard extends StatelessWidget {
  const _SensorCard({
    required this.sensor,
    required this.isBusy,
    required this.onEdit,
    required this.onHistory,
    required this.onDelete,
  });

  final UserVehicleSensor sensor;
  final bool isBusy;
  final VoidCallback onEdit;
  final VoidCallback onHistory;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return OpenVtsCard(
      padding: const EdgeInsets.all(OpenVtsSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: OpenVtsColors.textPrimary.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(OpenVtsRadius.sm),
                  border: Border.all(color: OpenVtsColors.border),
                ),
                child: Icon(
                  _iconFor(sensor.icon),
                  size: 18,
                  color: OpenVtsColors.textSecondary,
                ),
              ),
              const SizedBox(width: OpenVtsSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sensor.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: OpenVtsTypography.label.copyWith(
                        color: OpenVtsColors.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _joinParts([sensor.icon, sensor.dataType]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: OpenVtsTypography.meta.copyWith(
                        color: OpenVtsColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: OpenVtsSpacing.xs),
              _StatusPill(
                label: sensor.isActive ? 'Active' : 'Inactive',
                color: sensor.isActive
                    ? OpenVtsColors.success
                    : OpenVtsColors.textSecondary,
              ),
              PopupMenuButton<_SensorAction>(
                tooltip: 'Sensor actions',
                enabled: !isBusy,
                icon: isBusy
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.more_vert_rounded, size: 18),
                onSelected: (action) {
                  switch (action) {
                    case _SensorAction.edit:
                      onEdit();
                    case _SensorAction.history:
                      onHistory();
                    case _SensorAction.delete:
                      onDelete();
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: _SensorAction.edit,
                    child: _MenuRow(icon: Icons.edit_outlined, label: 'Edit'),
                  ),
                  PopupMenuItem(
                    value: _SensorAction.history,
                    child: _MenuRow(
                        icon: Icons.timeline_rounded, label: 'History'),
                  ),
                  PopupMenuDivider(height: 8),
                  PopupMenuItem(
                    value: _SensorAction.delete,
                    child: _MenuRow(
                      icon: Icons.delete_outline_rounded,
                      label: 'Delete',
                      isDestructive: true,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: OpenVtsSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: Text(
                  sensor.displayValue,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: OpenVtsTypography.numeric.copyWith(fontSize: 22),
                ),
              ),
              if ((sensor.unit ?? '').trim().isNotEmpty) ...[
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text(
                    sensor.unit!.trim(),
                    style: OpenVtsTypography.meta.copyWith(
                      color: OpenVtsColors.textSecondary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: OpenVtsSpacing.xs),
          Wrap(
            spacing: OpenVtsSpacing.xs,
            runSpacing: OpenVtsSpacing.xs,
            children: [
              _MetaPill(
                icon: Icons.schedule_rounded,
                label: sensor.lastUpdated == null
                    ? 'Not updated'
                    : _dateFormatter
                        .formatDateTime(sensor.lastUpdated!.toLocal()),
              ),
              if (sensor.code.trim().isNotEmpty)
                _MetaPill(icon: Icons.code_rounded, label: sensor.code.trim()),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptySensorsCard extends StatelessWidget {
  const _EmptySensorsCard({required this.hasSearch, required this.onAdd});

  final bool hasSearch;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return OpenVtsCard(
      padding: const EdgeInsets.all(OpenVtsSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OpenVtsEmptyState(
            title: hasSearch ? 'No sensors found' : 'No sensors',
            message: hasSearch
                ? 'Try a different search term.'
                : 'No sensors are configured for this vehicle.',
          ),
          const SizedBox(height: OpenVtsSpacing.sm),
          OpenVtsButton(
            label: 'Add Sensor',
            height: 38,
            trailingIcon: Icons.add_rounded,
            onPressed: onAdd,
          ),
        ],
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return OpenVtsCard(
      padding: const EdgeInsets.all(OpenVtsSpacing.sm),
      child: Row(
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: OpenVtsSpacing.sm),
          Text(
            label,
            style: OpenVtsTypography.meta.copyWith(
              color: OpenVtsColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return OpenVtsCard(
      padding: const EdgeInsets.all(OpenVtsSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            message,
            style: OpenVtsTypography.meta.copyWith(
              color: OpenVtsColors.error,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: OpenVtsSpacing.sm),
          OpenVtsButton(
            label: 'Retry',
            height: 36,
            variant: OpenVtsButtonVariant.secondary,
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(OpenVtsSpacing.sm),
      decoration: BoxDecoration(
        color: OpenVtsColors.error.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(OpenVtsRadius.sm),
        border: Border.all(color: OpenVtsColors.error.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              size: 16, color: OpenVtsColors.error),
          const SizedBox(width: OpenVtsSpacing.xs),
          Expanded(
            child: Text(
              message,
              style: OpenVtsTypography.meta.copyWith(
                color: OpenVtsColors.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallButton extends StatelessWidget {
  const _SmallButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: OpenVtsColors.textPrimary,
          side: const BorderSide(color: OpenVtsColors.border),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(OpenVtsRadius.pill),
          ),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        icon: Icon(icon, size: 15),
        label: Text(
          label,
          style: OpenVtsTypography.meta.copyWith(
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(OpenVtsRadius.pill),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Text(
        label,
        style: OpenVtsTypography.meta.copyWith(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 260),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: OpenVtsColors.textSecondary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(OpenVtsRadius.pill),
        border: Border.all(
            color: OpenVtsColors.textSecondary.withValues(alpha: 0.16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: OpenVtsColors.textSecondary),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: OpenVtsTypography.meta.copyWith(
                color: OpenVtsColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.icon,
    required this.label,
    this.isDestructive = false,
  });

  final IconData icon;
  final String label;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final color =
        isDestructive ? OpenVtsColors.error : OpenVtsColors.textPrimary;
    return Row(
      children: [
        Icon(icon, size: 17, color: color),
        const SizedBox(width: OpenVtsSpacing.sm),
        Text(label, style: OpenVtsTypography.label.copyWith(color: color)),
      ],
    );
  }
}

enum _SensorAction { edit, history, delete }

IconData _iconFor(String? icon) {
  final key = icon?.trim().toLowerCase() ?? '';
  if (key.contains('fuel')) return Icons.local_gas_station_outlined;
  if (key.contains('battery') || key.contains('volt')) {
    return Icons.battery_charging_full_outlined;
  }
  if (key.contains('temp')) return Icons.device_thermostat_outlined;
  if (key.contains('speed') || key.contains('gauge')) {
    return Icons.speed_rounded;
  }
  if (key.contains('engine')) return Icons.settings_outlined;
  if (key.contains('door')) return Icons.sensor_door_outlined;
  return Icons.sensors_outlined;
}

String _joinParts(List<String?> parts) {
  final normalized = parts
      .map((item) => item?.trim() ?? '')
      .where((item) => item.isNotEmpty)
      .toList(growable: false);
  return normalized.isEmpty ? '-' : normalized.join(' - ');
}
