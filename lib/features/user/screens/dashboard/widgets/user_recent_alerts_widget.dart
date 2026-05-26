import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/open_vts_colors.dart';
import '../../../../../core/theme/open_vts_radius.dart';
import '../../../../../core/theme/open_vts_spacing.dart';
import '../../../../../core/theme/open_vts_typography.dart';
import '../../../controllers/user_providers.dart';
import '../../../models/user_dashboard_model.dart';
import 'user_dashboard_widget_card.dart';

class UserRecentAlertsWidget extends ConsumerStatefulWidget {
  const UserRecentAlertsWidget({
    required this.config,
    required this.refreshTick,
    super.key,
  });

  final UserDashboardWidgetConfig config;
  final int refreshTick;

  @override
  ConsumerState<UserRecentAlertsWidget> createState() =>
      _UserRecentAlertsWidgetState();
}

class _UserRecentAlertsWidgetState
    extends ConsumerState<UserRecentAlertsWidget> {
  static const _refreshInterval = Duration(seconds: 30);

  late String _selectedVehicleId;
  final Set<String> _locallyReadIds = <String>{};
  Timer? _refreshTimer;
  bool _isRequestInFlight = false;
  int _refreshKey = 0;

  @override
  void initState() {
    super.initState();
    _selectedVehicleId = userDashboardPropString(
          widget.config.props,
          const ['vehicleId', 'vehicle_id'],
        ) ??
        'all';
    _startRefreshTimer();
  }

  @override
  void didUpdateWidget(covariant UserRecentAlertsWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshTick != widget.refreshTick ||
        oldWidget.config.id != widget.config.id) {
      _reload(forceRefresh: true);
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startRefreshTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(_refreshInterval, (_) {
      if (!mounted) return;
      _reload();
    });
  }

  void _reload({bool forceRefresh = false}) {
    if (_isRequestInFlight) {
      return;
    }
    setState(() => _refreshKey++);
  }

  void _changeVehicle(String? value) {
    if (value == null || value == _selectedVehicleId) return;
    if (_isRequestInFlight) {
      return;
    }
    setState(() {
      _selectedVehicleId = value;
      _refreshKey++;
    });
  }

  String _validatedVehicleId(List<UserDashboardVehicleOption> vehicles) {
    if (_selectedVehicleId == 'all') return 'all';
    final exists = vehicles.any((vehicle) => vehicle.id == _selectedVehicleId);
    if (exists) return _selectedVehicleId;
    _selectedVehicleId = 'all';
    return 'all';
  }

  bool _isRead(UserDashboardAlertItem item) {
    return item.isRead || _locallyReadIds.contains(item.id);
  }

  Future<void> _openAlertDetail(UserDashboardAlertItem item) async {
    if (item.id.trim().isEmpty) return;

    final detailProvider = userDashboardRecentAlertDetailProvider(item.id);
    final detailFuture = ref.read(detailProvider.future);
    if (!_isRead(item)) {
      unawaited(_markReadAfterDetail(detailFuture, item.id));
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final mediaQuery = MediaQuery.of(context);
        return SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.only(bottom: mediaQuery.viewInsets.bottom),
            child: DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.72,
              minChildSize: 0.45,
              maxChildSize: 0.94,
              builder: (context, scrollController) {
                return Align(
                  alignment: Alignment.bottomCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: _AlertDetailSheet(
                      initialItem: item,
                      detailProvider: detailProvider,
                      scrollController: scrollController,
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> _markReadAfterDetail(
    Future<UserDashboardAlertDetail> detailFuture,
    String id,
  ) async {
    try {
      await detailFuture;
      await ref
          .read(userDashboardControllerProvider.notifier)
          .markRecentAlertRead(id);
      if (!mounted) return;
      setState(() => _locallyReadIds.add(id));
    } catch (_) {
      // Detail or read failures stay local to the sheet/card.
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(
      userDashboardRecentAlertsProvider(
        UserDashboardVehicleScopedArgs(
          widgetId: widget.config.id,
          refreshKey: _refreshKey,
          vehicleId:
              _selectedVehicleId == 'all' ? null : _selectedVehicleId,
        ),
      ),
    );
    _isRequestInFlight = state.isLoading;
    return UserDashboardWidgetCard(
      title: widget.config.title,
      icon: Icons.notifications_active_outlined,
      isLoading: state.isLoading,
      onRefresh: () => _reload(forceRefresh: true),
      child: _buildBody(state),
    );
  }

  Widget _buildBody(
    AsyncValue<
            ({
              List<UserDashboardVehicleOption> vehicles,
              UserDashboardRecentAlertsPage page,
            })>
        state,
  ) {
    if (state.hasError) {
      return UserDashboardWidgetError(
        message: state.error.toString(),
        onRetry: () => _reload(forceRefresh: true),
      );
    }

    final data = state.valueOrNull;
    if (data == null) {
      return const _RecentAlertsSkeleton();
    }

    final selectedVehicleId = _validatedVehicleId(data.vehicles);
    final items = data.page.items;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _VehicleSelector(
          vehicles: data.vehicles,
          value: selectedVehicleId,
          onChanged: _changeVehicle,
        ),
        const SizedBox(height: OpenVtsSpacing.sm),
        if (items.isEmpty)
          const UserDashboardWidgetEmpty(
            message: 'No recent alerts.',
            icon: Icons.notifications_none_rounded,
          )
        else ...[
          for (var index = 0; index < items.take(10).length; index++) ...[
            _AlertRow(
              item: items[index],
              isRead: _isRead(items[index]),
              onTap: () => _openAlertDetail(items[index]),
            ),
            if (index != items.take(10).length - 1)
              const Divider(
                height: OpenVtsSpacing.md,
                color: OpenVtsColors.border,
              ),
          ],
          if (items.length > 10) ...[
            const SizedBox(height: OpenVtsSpacing.xs),
            Text(
              'Showing 10 of ${items.length} latest alerts',
              textAlign: TextAlign.center,
              style: OpenVtsTypography.meta.copyWith(
                color: OpenVtsColors.textTertiary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ],
    );
  }
}

class _VehicleSelector extends StatelessWidget {
  const _VehicleSelector({
    required this.vehicles,
    required this.value,
    required this.onChanged,
  });

  final List<UserDashboardVehicleOption> vehicles;
  final String value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      key: ValueKey(value),
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'Vehicle',
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: OpenVtsSpacing.sm,
          vertical: OpenVtsSpacing.xs,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(OpenVtsRadius.md),
          borderSide: const BorderSide(color: OpenVtsColors.border),
        ),
      ),
      items: [
        const DropdownMenuItem<String>(
          value: 'all',
          child: Text('All Vehicles'),
        ),
        for (final vehicle in vehicles)
          DropdownMenuItem<String>(
            value: vehicle.id,
            child: Text(
              _label(vehicle),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
      onChanged: onChanged,
    );
  }

  static String _label(UserDashboardVehicleOption vehicle) {
    final plate = vehicle.plateNumber?.trim();
    if (plate != null && plate.isNotEmpty) {
      return '${vehicle.name} - $plate';
    }
    return vehicle.name;
  }
}

class _AlertRow extends StatelessWidget {
  const _AlertRow({
    required this.item,
    required this.isRead,
    required this.onTap,
  });

  final UserDashboardAlertItem item;
  final bool isRead;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final severity = _SeverityStyle.from(item);
    final vehicle = _vehicleLabel(item);
    final title = item.title.trim().isEmpty ? item.source : item.title;

    return InkWell(
      borderRadius: BorderRadius.circular(OpenVtsRadius.md),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: OpenVtsSpacing.xxs),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 9,
                  height: 9,
                  margin: const EdgeInsets.only(top: 6),
                  decoration: BoxDecoration(
                    color: severity.color,
                    shape: BoxShape.circle,
                  ),
                ),
                if (!isRead) ...[
                  const SizedBox(height: 6),
                  Container(
                    width: 5,
                    height: 5,
                    decoration: const BoxDecoration(
                      color: OpenVtsColors.brandInk,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(width: OpenVtsSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: OpenVtsTypography.label.copyWith(
                            color: OpenVtsColors.textPrimary,
                            fontWeight:
                                isRead ? FontWeight.w700 : FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(width: OpenVtsSpacing.xs),
                      _AlertChip(label: severity.label, color: severity.color),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Wrap(
                    spacing: OpenVtsSpacing.xs,
                    runSpacing: 2,
                    children: [
                      _MetaText(
                          item.source.isEmpty ? 'Source unknown' : item.source),
                      _MetaText(vehicle),
                      _MetaText(userDashboardFormatShortTime(item.createdAt)),
                    ],
                  ),
                  if (item.message.trim().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      item.message,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: OpenVtsTypography.meta.copyWith(
                        color: OpenVtsColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: OpenVtsSpacing.xs),
            const Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: OpenVtsColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }

  static String _vehicleLabel(UserDashboardAlertItem item) {
    if (item.vehicleName.trim().isNotEmpty) return item.vehicleName;
    final plate = item.plateNumber?.trim();
    if (plate != null && plate.isNotEmpty) return plate;
    return item.vehicleId.trim().isEmpty ? 'Vehicle unknown' : item.vehicleId;
  }
}

class _AlertDetailSheet extends StatelessWidget {
  const _AlertDetailSheet({
    required this.initialItem,
    required this.detailProvider,
    required this.scrollController,
  });

  final UserDashboardAlertItem initialItem;
  final AutoDisposeFutureProvider<UserDashboardAlertDetail> detailProvider;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(detailProvider);
        final alert = state.valueOrNull ?? initialItem;
          final severity = _SeverityStyle.from(alert);
        return DecoratedBox(
          decoration: const BoxDecoration(
            color: OpenVtsColors.surfaceElevated,
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(OpenVtsRadius.lg)),
          ),
          child: ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(
            OpenVtsSpacing.md,
            OpenVtsSpacing.sm,
            OpenVtsSpacing.md,
            OpenVtsSpacing.lg,
          ),
          children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: OpenVtsColors.border,
                    borderRadius: BorderRadius.circular(OpenVtsRadius.pill),
                  ),
                ),
              ),
              const SizedBox(height: OpenVtsSpacing.md),
              Row(
                children: [
                  _AlertChip(label: severity.label, color: severity.color),
                  const SizedBox(width: OpenVtsSpacing.xs),
                  _AlertChip(
                    label:
                        alert.source.isEmpty ? 'Source unknown' : alert.source,
                    color: OpenVtsColors.textSecondary,
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, size: 18),
                  ),
                ],
              ),
              const SizedBox(height: OpenVtsSpacing.sm),
              Text(
                alert.title.trim().isEmpty ? alert.source : alert.title,
                style: OpenVtsTypography.titleSmall.copyWith(
                  color: OpenVtsColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: OpenVtsSpacing.xs),
              Text(
                _detailVehicleLabel(alert),
                style: OpenVtsTypography.label.copyWith(
                  color: OpenVtsColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                userDashboardFormatDateTime(alert.createdAt),
                style: OpenVtsTypography.meta.copyWith(
                  color: OpenVtsColors.textTertiary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: OpenVtsSpacing.md),
              _DetailSection(
                title: 'Message',
                child: Text(
                  alert.message.trim().isEmpty
                      ? 'No message provided.'
                      : alert.message,
                  style: OpenVtsTypography.body.copyWith(
                    color: OpenVtsColors.textPrimary,
                  ),
                ),
              ),
              if ((alert.meta ?? const <String, dynamic>{}).isNotEmpty) ...[
                const SizedBox(height: OpenVtsSpacing.sm),
                _DetailSection(
                  title: 'Details',
                  child: Column(
                    children: [
                      for (final entry in alert.meta!.entries) ...[
                        _DetailKeyValue(
                          label: entry.key,
                          value: entry.value?.toString() ?? 'No value',
                        ),
                        if (entry.key != alert.meta!.keys.last)
                          const Divider(height: OpenVtsSpacing.sm),
                      ],
                    ],
                  ),
                ),
              ],
              if (state.isLoading) ...[
                const SizedBox(height: OpenVtsSpacing.md),
                const LinearProgressIndicator(minHeight: 2),
              ],
              if (state.hasError) ...[
                const SizedBox(height: OpenVtsSpacing.md),
                UserDashboardWidgetError(message: state.error.toString()),
              ],
              if (state.valueOrNull != null &&
                  state.valueOrNull!.deliveries.isNotEmpty) ...[
                const SizedBox(height: OpenVtsSpacing.md),
                _DetailSection(
                  title: 'Delivery Logs',
                  child:
                      _DeliveryLogList(deliveries: state.valueOrNull!.deliveries),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  static String _detailVehicleLabel(UserDashboardAlertItem item) {
    final parts = <String>[
      if (item.vehicleName.trim().isNotEmpty) item.vehicleName,
      if ((item.plateNumber ?? '').trim().isNotEmpty) item.plateNumber!.trim(),
      if ((item.imei ?? '').trim().isNotEmpty) item.imei!.trim(),
    ];
    return parts.isEmpty ? 'Vehicle unknown' : parts.join(' - ');
  }
}

class _DeliveryLogList extends StatelessWidget {
  const _DeliveryLogList({required this.deliveries});

  final List<UserDashboardAlertDelivery> deliveries;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var index = 0; index < deliveries.length; index++) ...[
          _DeliveryLogRow(delivery: deliveries[index]),
          if (index != deliveries.length - 1)
            const Divider(height: OpenVtsSpacing.md),
        ],
      ],
    );
  }
}

class _DeliveryLogRow extends StatelessWidget {
  const _DeliveryLogRow({required this.delivery});

  final UserDashboardAlertDelivery delivery;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: OpenVtsColors.surface,
            borderRadius: BorderRadius.circular(OpenVtsRadius.sm),
            border: Border.all(color: OpenVtsColors.border),
          ),
          child: const Icon(
            Icons.mail_outline_rounded,
            size: 15,
            color: OpenVtsColors.textSecondary,
          ),
        ),
        const SizedBox(width: OpenVtsSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                delivery.channel.isEmpty ? 'Channel unknown' : delivery.channel,
                style: OpenVtsTypography.label.copyWith(
                  color: OpenVtsColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                [
                  delivery.status.isEmpty ? 'No status' : delivery.status,
                  if (delivery.deliveredAt != null)
                    userDashboardFormatShortTime(delivery.deliveredAt)
                  else if (delivery.sentAt != null)
                    userDashboardFormatShortTime(delivery.sentAt),
                ].join(' - '),
                style: OpenVtsTypography.meta.copyWith(
                  color: OpenVtsColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if ((delivery.failureReason ?? '').trim().isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  delivery.failureReason!,
                  style: OpenVtsTypography.meta.copyWith(
                    color: OpenVtsColors.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(OpenVtsSpacing.sm),
      decoration: BoxDecoration(
        color: OpenVtsColors.surface,
        borderRadius: BorderRadius.circular(OpenVtsRadius.md),
        border: Border.all(color: OpenVtsColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: OpenVtsTypography.meta.copyWith(
              color: OpenVtsColors.textTertiary,
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: OpenVtsSpacing.xs),
          child,
        ],
      ),
    );
  }
}

class _DetailKeyValue extends StatelessWidget {
  const _DetailKeyValue({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 108,
          child: Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: OpenVtsTypography.meta.copyWith(
              color: OpenVtsColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: OpenVtsSpacing.xs),
        Expanded(
          child: Text(
            value,
            style: OpenVtsTypography.meta.copyWith(
              color: OpenVtsColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _AlertChip extends StatelessWidget {
  const _AlertChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: OpenVtsSpacing.xs, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(OpenVtsRadius.pill),
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: OpenVtsTypography.meta.copyWith(
          color: color,
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _MetaText extends StatelessWidget {
  const _MetaText(this.value);

  final String value;

  @override
  Widget build(BuildContext context) {
    return Text(
      value,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: OpenVtsTypography.meta.copyWith(
        color: OpenVtsColors.textTertiary,
        fontSize: 10.5,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _RecentAlertsSkeleton extends StatelessWidget {
  const _RecentAlertsSkeleton();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(height: 180);
  }
}

class _SeverityStyle {
  const _SeverityStyle({required this.label, required this.color});

  final String label;
  final Color color;

  static _SeverityStyle from(UserDashboardAlertItem item) {
    final severity = item.severity.toUpperCase();
    final source = item.source.toUpperCase();
    final title = item.title.toUpperCase();

    if (severity == 'CRITICAL' ||
        title.contains('SOS') ||
        title.contains('ALARM')) {
      return const _SeverityStyle(
          label: 'Critical', color: OpenVtsColors.error);
    }
    if (severity == 'WARNING' || source.contains('OVERSPEED')) {
      return const _SeverityStyle(
          label: 'Warning', color: OpenVtsColors.warning);
    }
    if (source.contains('IGNITION') || title.contains('IGNITION')) {
      return const _SeverityStyle(
          label: 'Ignition', color: OpenVtsColors.success);
    }
    if (source.contains('GEOFENCE') || title.contains('GEOFENCE')) {
      return const _SeverityStyle(label: 'Geofence', color: OpenVtsColors.info);
    }
    return const _SeverityStyle(
        label: 'Info', color: OpenVtsColors.textSecondary);
  }
}
