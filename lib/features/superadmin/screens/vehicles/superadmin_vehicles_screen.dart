import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/open_vts_colors.dart';
import '../../../../core/theme/open_vts_radius.dart';
import '../../../../core/theme/open_vts_spacing.dart';
import '../../../../core/theme/open_vts_typography.dart';
import '../../../../core/utils/date_time_formatter.dart';
import '../../../../shared/widgets/open_vts_card.dart';
import '../../../../shared/widgets/open_vts_empty_state.dart';
import '../../../../shared/widgets/open_vts_error_view.dart';
import '../../../../shared/widgets/open_vts_loader.dart';
import '../../../../shared/widgets/open_vts_page_scaffold.dart';
import '../../../../shared/widgets/open_vts_search_field.dart';
import '../../controllers/superadmin_providers.dart';
import '../../models/superadmin_vehicle_model.dart';

const DateTimeFormatter _vehicleFmt = DateTimeFormatter();
const int _initialVisibleVehicleCount = 20;

class SuperadminVehiclesScreen extends ConsumerStatefulWidget {
  const SuperadminVehiclesScreen({super.key});

  @override
  ConsumerState<SuperadminVehiclesScreen> createState() =>
      _SuperadminVehiclesScreenState();
}

class _SuperadminVehiclesScreenState
    extends ConsumerState<SuperadminVehiclesScreen> {
  String _searchQuery = '';
  bool _isRefreshing = false;
  int _visibleCount = _initialVisibleVehicleCount;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(superadminVehiclePageProvider);

    return OpenVtsPageScaffold(
      title: 'Vehicles',
      headerMode: OpenVtsPageHeaderMode.closeable,
      leading: const _HeaderLogoTile(),
      actions: [
        Padding(
          padding: const EdgeInsetsDirectional.only(end: OpenVtsSpacing.xs),
          child: IconButton(
            tooltip: 'Refresh vehicles',
            onPressed: _isRefreshing ? null : _refreshVehicles,
            icon: _isRefreshing
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh_rounded, size: 20),
          ),
        ),
      ],
      padding: const EdgeInsetsDirectional.fromSTEB(
        OpenVtsSpacing.sm,
        OpenVtsSpacing.xs,
        OpenVtsSpacing.sm,
        OpenVtsSpacing.xs,
      ),
      body: state.when(
        skipLoadingOnRefresh: true,
        loading: () => const OpenVtsLoader(),
        error: (error, stackTrace) => OpenVtsErrorView(
          message: 'Vehicles could not be loaded.',
          onRetry: () {
            _refreshVehicles();
          },
        ),
        data: _buildLoadedState,
      ),
    );
  }

  Widget _buildLoadedState(SuperadminVehiclePage page) {
    final filteredVehicles = _applyFilters(page.items);
    final visibleVehicles =
        filteredVehicles.take(_visibleCount).toList(growable: false);
    final hasMore = visibleVehicles.length < filteredVehicles.length;

    return Column(
      children: [
        _MinimalVehicleSearchBar(
          onSearchChanged: (value) {
            setState(() {
              _searchQuery = value.trim();
              _visibleCount = _initialVisibleVehicleCount;
            });
          },
        ),
        const SizedBox(height: OpenVtsSpacing.xs),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _refreshVehicles,
            child: visibleVehicles.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [
                      SizedBox(height: OpenVtsSpacing.section),
                      OpenVtsEmptyState(
                        title: 'No vehicles found',
                        message: 'Try a different search.',
                      ),
                    ],
                  )
                : ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: visibleVehicles.length + (hasMore ? 1 : 0),
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: OpenVtsSpacing.xs),
                    itemBuilder: (context, index) {
                      if (index == visibleVehicles.length) {
                        return _InlineVehicleLoadMoreFooter(
                          visibleCount: visibleVehicles.length,
                          totalCount: filteredVehicles.length,
                          onPressed: () {
                            setState(() {
                              _visibleCount += _initialVisibleVehicleCount;
                            });
                          },
                        );
                      }

                      return _VehicleCard(vehicle: visibleVehicles[index]);
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Future<void> _refreshVehicles() async {
    if (_isRefreshing) {
      return;
    }

    setState(() {
      _isRefreshing = true;
    });

    try {
      ref.invalidate(superadminVehiclePageProvider);
      await ref.read(superadminVehiclePageProvider.future);
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  List<SuperadminVehicleRecord> _applyFilters(
    List<SuperadminVehicleRecord> vehicles,
  ) {
    final normalizedQuery = _searchQuery.toLowerCase();
    final filtered = vehicles.where((vehicle) {
      final matchesSearch = normalizedQuery.isEmpty ||
          vehicle.searchContent.contains(normalizedQuery);
      return matchesSearch;
    }).toList();

    filtered.sort((left, right) {
      return (right.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0))
          .compareTo(left.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0));
    });
    return filtered;
  }
}

class _HeaderLogoTile extends StatelessWidget {
  const _HeaderLogoTile();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: OpenVtsSpacing.sm),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: Container(
          height: 36,
          width: 36,
          decoration: BoxDecoration(
            color: OpenVtsColors.brandInk,
            borderRadius: BorderRadius.circular(OpenVtsRadius.md),
          ),
          child: const Icon(
            Icons.directions_car_outlined,
            color: OpenVtsColors.white,
            size: 18,
          ),
        ),
      ),
    );
  }
}

class _MinimalVehicleSearchBar extends StatelessWidget {
  const _MinimalVehicleSearchBar({
    required this.onSearchChanged,
  });

  final ValueChanged<String> onSearchChanged;

  @override
  Widget build(BuildContext context) {
    return OpenVtsCard(
      padding: const EdgeInsets.all(OpenVtsSpacing.xs),
      child: OpenVtsSearchField(
        hintText: 'Search vehicles',
        onChanged: onSearchChanged,
      ),
    );
  }
}

class _InlineVehicleLoadMoreFooter extends StatelessWidget {
  const _InlineVehicleLoadMoreFooter({
    required this.visibleCount,
    required this.totalCount,
    required this.onPressed,
  });

  final int visibleCount;
  final int totalCount;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: OpenVtsSpacing.xs),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Showing $visibleCount of $totalCount',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: OpenVtsColors.textSecondary,
                  ),
            ),
            const SizedBox(height: OpenVtsSpacing.xxs),
            TextButton(
              onPressed: onPressed,
              child: const Text('Load more'),
            ),
          ],
        ),
      ),
    );
  }
}

class _VehicleCard extends StatelessWidget {
  const _VehicleCard({required this.vehicle});

  final SuperadminVehicleRecord vehicle;

  @override
  Widget build(BuildContext context) {
    return OpenVtsCard(
      padding: const EdgeInsets.all(OpenVtsSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _VehicleIconBadge(type: vehicle.type),
              const SizedBox(width: OpenVtsSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            vehicle.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: OpenVtsTypography.body.copyWith(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: OpenVtsColors.textPrimary,
                            ),
                          ),
                        ),
                        if (vehicle.plateNumber != '—') ...[
                          const SizedBox(width: OpenVtsSpacing.xs),
                          _PlateChip(label: vehicle.plateNumber),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      vehicle.type,
                      style: OpenVtsTypography.meta.copyWith(
                        color: OpenVtsColors.textSecondary,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              if (vehicle.status != 'Unknown') ...[
                const SizedBox(width: OpenVtsSpacing.xs),
                _StatusChip(label: vehicle.status),
              ],
            ],
          ),
          const SizedBox(height: OpenVtsSpacing.sm),
          _VehicleDetailsPanel(vehicle: vehicle),
        ],
      ),
    );
  }
}

class _VehicleDetailsPanel extends StatelessWidget {
  const _VehicleDetailsPanel({required this.vehicle});

  final SuperadminVehicleRecord vehicle;

  @override
  Widget build(BuildContext context) {
    final localDateTime = vehicle.createdAt?.toLocal();
    final createdLabel = localDateTime == null
        ? '—'
        : '${_vehicleFmt.formatDate(localDateTime)}  ${_vehicleFmt.formatTime(localDateTime)}';

    return LayoutBuilder(
      builder: (context, constraints) {
        final twoColumn = constraints.maxWidth >= 400;

        if (twoColumn) {
          return Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _VehicleInfoRow(
                      icon: Icons.barcode_reader,
                      label: 'IMEI',
                      value: vehicle.imei,
                    ),
                  ),
                  const SizedBox(width: OpenVtsSpacing.md),
                  Expanded(
                    child: _VehicleInfoRow(
                      icon: Icons.person_add_alt_1_outlined,
                      label: 'ADDED BY',
                      value: vehicle.addedBy,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: OpenVtsSpacing.xs),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _VehicleInfoRow(
                      icon: Icons.sim_card_outlined,
                      label: 'SIM',
                      value: vehicle.sim,
                    ),
                  ),
                  const SizedBox(width: OpenVtsSpacing.md),
                  Expanded(
                    child: _VehicleInfoRow(
                      icon: Icons.person_outline_rounded,
                      label: 'PRIMARY USER',
                      value: vehicle.primaryUser,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: OpenVtsSpacing.xs),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: _VehicleInfoRow(
                  icon: Icons.schedule_rounded,
                  label: 'Created',
                  value: createdLabel,
                ),
              ),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _VehicleInfoRow(
              icon: Icons.barcode_reader,
              label: 'IMEI',
              value: vehicle.imei,
            ),
            const SizedBox(height: OpenVtsSpacing.xs),
            _VehicleInfoRow(
              icon: Icons.sim_card_outlined,
              label: 'SIM',
              value: vehicle.sim,
            ),
            const SizedBox(height: OpenVtsSpacing.xs),
            _VehicleInfoRow(
              icon: Icons.person_add_alt_1_outlined,
              label: 'ADDED BY',
              value: vehicle.addedBy,
            ),
            const SizedBox(height: OpenVtsSpacing.xs),
            _VehicleInfoRow(
              icon: Icons.person_outline_rounded,
              label: 'PRIMARY USER',
              value: vehicle.primaryUser,
            ),
            const SizedBox(height: OpenVtsSpacing.xs),
            _VehicleInfoRow(
              icon: Icons.schedule_rounded,
              label: 'Created',
              value: createdLabel,
            ),
          ],
        );
      },
    );
  }
}

class _VehicleInfoRow extends StatelessWidget {
  const _VehicleInfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: OpenVtsColors.textTertiary),
        const SizedBox(width: OpenVtsSpacing.xs),
        Text(
          '$label :  ',
          style: OpenVtsTypography.meta.copyWith(
            color: OpenVtsColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        Flexible(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: OpenVtsTypography.meta.copyWith(
              color: OpenVtsColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _VehicleIconBadge extends StatelessWidget {
  const _VehicleIconBadge({required this.type});

  final String type;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      width: 44,
      decoration: const BoxDecoration(
        color: OpenVtsColors.brandInk,
        shape: BoxShape.circle,
      ),
      child: Icon(
        _vehicleIcon(type),
        color: OpenVtsColors.white,
        size: 20,
      ),
    );
  }
}

class _PlateChip extends StatelessWidget {
  const _PlateChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: OpenVtsSpacing.xs,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: _compactSurfaceColor(context),
        borderRadius: BorderRadius.circular(OpenVtsRadius.pill),
        border: Border.all(color: _compactBorderColor(context)),
      ),
      child: Text(
        label,
        style: OpenVtsTypography.meta.copyWith(
          color: OpenVtsColors.textSecondary,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = switch (label) {
      'Active' => OpenVtsColors.surface,
      'Idle' => OpenVtsColors.warning.withValues(alpha: 0.14),
      'Inactive' => OpenVtsColors.textTertiary.withValues(alpha: 0.16),
      'Offline' => OpenVtsColors.error.withValues(alpha: 0.12),
      _ => OpenVtsColors.info.withValues(alpha: 0.12),
    };

    final foregroundColor = switch (label) {
      'Active' => OpenVtsColors.textPrimary,
      'Idle' => OpenVtsColors.warning,
      'Inactive' => OpenVtsColors.textSecondary,
      'Offline' => OpenVtsColors.error,
      _ => OpenVtsColors.info,
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: OpenVtsSpacing.sm,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(OpenVtsRadius.pill),
      ),
      child: Text(
        label,
        style: OpenVtsTypography.meta.copyWith(
          color: foregroundColor,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

Color _compactSurfaceColor(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark
      ? OpenVtsColors.darkSurface
      : OpenVtsColors.background;
}

Color _compactBorderColor(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark
      ? OpenVtsColors.darkBorder
      : OpenVtsColors.border;
}

/*
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 760;

              final titleSection = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: OpenVtsSpacing.xs,
                    runSpacing: OpenVtsSpacing.xxs,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        vehicle.name,
                        style: OpenVtsTypography.titleSmall.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (vehicle.plateNumber != '—')
                        _PlateChip(label: vehicle.plateNumber),
                    ],
                  ),
                  const SizedBox(height: OpenVtsSpacing.xxs),
                  Wrap(
                    spacing: OpenVtsSpacing.xs,
                    runSpacing: OpenVtsSpacing.xxs,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        vehicle.type,
                        style: OpenVtsTypography.body.copyWith(
                          color: OpenVtsColors.textSecondary,
                        ),
                      ),
                      if (vehicle.status != 'Unknown') ...[
                        Text(
                          '•',
                          style: OpenVtsTypography.body.copyWith(
                            color: OpenVtsColors.textTertiary,
                          ),
                        ),
                        _StatusChip(label: vehicle.status),
                      ],
                    ],
                  ),
                ],
              );

              final timestamp = _VehicleTimestamp(createdAt: vehicle.createdAt);

              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _VehicleIconBadge(type: vehicle.type),
                        const SizedBox(width: OpenVtsSpacing.sm),
                        Expanded(child: titleSection),
                      ],
                    ),
                    const SizedBox(height: OpenVtsSpacing.xs),
                    timestamp,
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _VehicleIconBadge(type: vehicle.type),
                  const SizedBox(width: OpenVtsSpacing.sm),
                  Expanded(child: titleSection),
                  const SizedBox(width: OpenVtsSpacing.md),
                  timestamp,
                ],
              );
            },
          ),
          const SizedBox(height: OpenVtsSpacing.xs),
          const Divider(height: 1, color: OpenVtsColors.border),
          const SizedBox(height: OpenVtsSpacing.xs),
          _VehicleDetailsPanel(vehicle: vehicle),
        ],
      ),
    );
  }
}

class _VehicleIconBadge extends StatelessWidget {
  const _VehicleIconBadge({required this.type});

  final String type;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      width: 44,
      decoration: BoxDecoration(
        color: OpenVtsColors.background,
        borderRadius: BorderRadius.circular(OpenVtsRadius.md),
        border: Border.all(color: OpenVtsColors.border),
      ),
      child: Icon(
        _vehicleIcon(type),
        color: OpenVtsColors.textPrimary,
        size: 22,
      ),
    );
  }
}

class _VehicleTimestamp extends StatelessWidget {
  const _VehicleTimestamp({required this.createdAt});

  final DateTime? createdAt;

  @override
  Widget build(BuildContext context) {
    final localDateTime = createdAt?.toLocal();
    final dateLabel = localDateTime == null
        ? '—'
        : _vehicleFmt.formatDate(localDateTime);
    final timeLabel = localDateTime == null
        ? '—'
        : _vehicleFmt.formatTime(localDateTime);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.schedule_rounded,
          size: 16,
          color: OpenVtsColors.textSecondary,
        ),
        const SizedBox(width: OpenVtsSpacing.xs),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              dateLabel,
              style: OpenVtsTypography.body.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              timeLabel,
              style: OpenVtsTypography.meta.copyWith(
                color: OpenVtsColors.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _VehicleDetailsPanel extends StatelessWidget {
  const _VehicleDetailsPanel({required this.vehicle});

  final SuperadminVehicleRecord vehicle;

  @override
  Widget build(BuildContext context) {
    final deviceSection = _VehicleMetaSection(
      title: 'Device',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _VehicleMetaLine(label: 'IMEI', value: vehicle.imei),
          const SizedBox(height: OpenVtsSpacing.xs),
          _VehicleMetaLine(label: 'SIM', value: vehicle.sim),
        ],
      ),
    );
    final primaryUserSection = _VehicleMetaSection(
      title: 'Primary user',
      child: Text(
        vehicle.primaryUser,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: OpenVtsTypography.body.copyWith(
          color: OpenVtsColors.textPrimary,
        ),
      ),
    );
    final addedBySection = _VehicleMetaSection(
      title: 'Added by',
      child: Text(
        vehicle.addedBy,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: OpenVtsTypography.body.copyWith(
          color: OpenVtsColors.textPrimary,
        ),
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 860) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: deviceSection),
              const _VehicleSectionDivider(),
              Expanded(child: primaryUserSection),
              const _VehicleSectionDivider(),
              Expanded(child: addedBySection),
            ],
          );
        }

        if (constraints.maxWidth >= 560) {
          final itemWidth = (constraints.maxWidth - OpenVtsSpacing.xs) / 2;
          return Wrap(
            spacing: OpenVtsSpacing.xs,
            runSpacing: OpenVtsSpacing.xs,
            children: [
              SizedBox(width: itemWidth, child: deviceSection),
              SizedBox(width: itemWidth, child: primaryUserSection),
              SizedBox(width: itemWidth, child: addedBySection),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            deviceSection,
            const SizedBox(height: OpenVtsSpacing.xs),
            const Divider(height: 1, color: OpenVtsColors.border),
            const SizedBox(height: OpenVtsSpacing.xs),
            primaryUserSection,
            const SizedBox(height: OpenVtsSpacing.xs),
            const Divider(height: 1, color: OpenVtsColors.border),
            const SizedBox(height: OpenVtsSpacing.xs),
            addedBySection,
          ],
        );
      },
    );
  }
}

class _VehicleMetaSection extends StatelessWidget {
  const _VehicleMetaSection({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: OpenVtsTypography.meta.copyWith(
            color: OpenVtsColors.textSecondary,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: OpenVtsSpacing.xxs),
        child,
      ],
    );
  }
}

class _VehicleMetaLine extends StatelessWidget {
  const _VehicleMetaLine({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return RichText(
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        style: OpenVtsTypography.body.copyWith(
          color: OpenVtsColors.textPrimary,
        ),
        children: [
          TextSpan(
            text: '$label  ',
            style: OpenVtsTypography.meta.copyWith(
              color: OpenVtsColors.textSecondary,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
            ),
          ),
          TextSpan(text: value),
        ],
      ),
    );
  }
}

class _VehicleSectionDivider extends StatelessWidget {
  const _VehicleSectionDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 54,
      margin: const EdgeInsets.symmetric(horizontal: OpenVtsSpacing.sm),
      color: OpenVtsColors.border,
    );
  }
}

class _PlateChip extends StatelessWidget {
  const _PlateChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: OpenVtsSpacing.xs,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: OpenVtsColors.background,
        borderRadius: BorderRadius.circular(OpenVtsRadius.md),
        border: Border.all(color: OpenVtsColors.border),
      ),
      child: Text(
        label,
        style: OpenVtsTypography.meta.copyWith(
          color: OpenVtsColors.textSecondary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = switch (label) {
      'Active' => OpenVtsColors.success.withValues(alpha: 0.12),
      'Idle' => OpenVtsColors.warning.withValues(alpha: 0.14),
      'Inactive' => OpenVtsColors.textTertiary.withValues(alpha: 0.16),
      'Offline' => OpenVtsColors.error.withValues(alpha: 0.12),
      _ => OpenVtsColors.info.withValues(alpha: 0.12),
    };

    final foregroundColor = switch (label) {
      'Active' => OpenVtsColors.success,
      'Idle' => OpenVtsColors.warning,
      'Inactive' => OpenVtsColors.textSecondary,
      'Offline' => OpenVtsColors.error,
      _ => OpenVtsColors.info,
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: OpenVtsSpacing.xs,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(OpenVtsRadius.pill),
      ),
      child: Text(
        label,
        style: OpenVtsTypography.meta.copyWith(
          color: foregroundColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

*/

IconData _vehicleIcon(String type) {
  switch (type) {
    case 'Truck':
      return Icons.local_shipping_outlined;
    case 'Bike':
      return Icons.pedal_bike_outlined;
    case 'Bus':
      return Icons.directions_bus_outlined;
    case 'Van':
      return Icons.airport_shuttle_outlined;
    default:
      return Icons.directions_car_outlined;
  }
}
