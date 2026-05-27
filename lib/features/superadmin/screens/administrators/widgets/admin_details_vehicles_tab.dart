import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../../core/theme/open_vts_colors.dart';
import '../../../../../core/theme/open_vts_radius.dart';
import '../../../../../core/theme/open_vts_spacing.dart';
import '../../../../../shared/widgets/open_vts_card.dart';
import '../../../../../shared/widgets/open_vts_error_view.dart';
import '../../../../../shared/widgets/open_vts_loader.dart';
import '../../../controllers/superadmin_providers.dart';
import '../../../models/superadmin_admin_details_model.dart';

enum _VehicleFilter { all, activeLicense, blockedLicense, expiring }

class AdminDetailsVehiclesTab extends ConsumerStatefulWidget {
  const AdminDetailsVehiclesTab({required this.adminId, super.key});

  final String adminId;

  @override
  ConsumerState<AdminDetailsVehiclesTab> createState() =>
      _AdminDetailsVehiclesTabState();
}

class _AdminDetailsVehiclesTabState
    extends ConsumerState<AdminDetailsVehiclesTab> {
  final TextEditingController _search = TextEditingController();
  _VehicleFilter _filter = _VehicleFilter.all;

  Timer? _debounce;
  String _debouncedQuery = '';

  List<SuperadminAdminVehicle>? _cachedFiltered;
  List<SuperadminAdminVehicle>? _lastVehicles;
  String? _lastQuery;
  _VehicleFilter? _lastFilter;

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      final q = _search.text.trim().toLowerCase();
      if (q != _debouncedQuery) {
        setState(() => _debouncedQuery = q);
      }
    });
  }

  bool _isExpiringSoon(DateTime? expiry) {
    if (expiry == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final diff = expiry.difference(today).inDays;
    return diff <= 30;
  }

  List<SuperadminAdminVehicle> _getFiltered(
    List<SuperadminAdminVehicle> vehicles,
  ) {
    if (identical(vehicles, _lastVehicles) &&
        _debouncedQuery == _lastQuery &&
        _filter == _lastFilter &&
        _cachedFiltered != null) {
      return _cachedFiltered!;
    }
    _lastVehicles = vehicles;
    _lastQuery = _debouncedQuery;
    _lastFilter = _filter;
    _cachedFiltered = _applyFilters(vehicles);
    return _cachedFiltered!;
  }

  List<SuperadminAdminVehicle> _applyFilters(
    List<SuperadminAdminVehicle> vehicles,
  ) {
    return vehicles.where((v) {
      switch (_filter) {
        case _VehicleFilter.all:
          break;
        case _VehicleFilter.activeLicense:
          if (v.isLicenseBlocked) return false;
        case _VehicleFilter.blockedLicense:
          if (!v.isLicenseBlocked) return false;
        case _VehicleFilter.expiring:
          if (!_isExpiringSoon(v.primaryExpiry)) return false;
      }
      if (_debouncedQuery.isEmpty) return true;
      return v.name.toLowerCase().contains(_debouncedQuery) ||
          v.imei.toLowerCase().contains(_debouncedQuery) ||
          v.simNumber.toLowerCase().contains(_debouncedQuery) ||
          v.vehicleTypeName.toLowerCase().contains(_debouncedQuery) ||
          v.vehicleTypeSlug.toLowerCase().contains(_debouncedQuery);
    }).toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final provider = superadminAdminDetailsControllerProvider(widget.adminId);
    final vehicles = ref.watch(provider.select((s) => s.vehicles));
    final isLoading = ref.watch(provider.select((s) => s.isLoadingVehicles));
    final hasLoaded = ref.watch(provider.select((s) => s.hasLoadedVehicles));
    final errorMessage =
        ref.watch(provider.select((s) => s.vehiclesErrorMessage));
    final controller = ref.read(provider.notifier);

    if (isLoading && !hasLoaded) {
      return const OpenVtsCard(
        padding: EdgeInsets.symmetric(vertical: OpenVtsSpacing.lg),
        child: Center(child: OpenVtsLoader()),
      );
    }

    if (errorMessage != null && !hasLoaded) {
      return OpenVtsCard(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: OpenVtsSpacing.md),
          child: OpenVtsErrorView(
            message: errorMessage.trim().isEmpty
                ? 'Unable to load vehicles. Retry.'
                : errorMessage,
            onRetry: () => controller.loadVehicles(force: true),
          ),
        ),
      );
    }

    final total = vehicles.length;
    final blocked = vehicles.where((v) => v.isLicenseBlocked).length;
    final expiring =
        vehicles.where((v) => _isExpiringSoon(v.primaryExpiry)).length;
    final filtered = _getFiltered(vehicles);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SummaryRow(
          total: total,
          blocked: blocked,
          expiring: expiring,
          isRefreshing: isLoading,
          onRefresh: () => controller.loadVehicles(force: true),
        ),
        if (errorMessage != null && hasLoaded) ...[
          const SizedBox(height: OpenVtsSpacing.xs),
          Text(
            errorMessage.trim().isEmpty
                ? 'Unable to refresh vehicles.'
                : errorMessage,
            style: const TextStyle(
              fontSize: 11,
              color: OpenVtsColors.error,
            ),
          ),
        ],
        const SizedBox(height: OpenVtsSpacing.sm),
        _SearchField(
          controller: _search,
          onChanged: _onSearchChanged,
        ),
        const SizedBox(height: OpenVtsSpacing.xs),
        _FilterChips(
          value: _filter,
          onChanged: (next) => setState(() => _filter = next),
        ),
        const SizedBox(height: OpenVtsSpacing.sm),
        if (vehicles.isEmpty)
          const _EmptyState(message: 'No vehicles assigned.')
        else if (filtered.isEmpty)
          const _EmptyState(message: 'No vehicles match your search.')
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            addAutomaticKeepAlives: false,
            itemCount: filtered.length,
            separatorBuilder: (_, __) =>
                const SizedBox(height: OpenVtsSpacing.xs),
            itemBuilder: (context, index) =>
                _VehicleCard(vehicle: filtered[index]),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Summary
// ---------------------------------------------------------------------------

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.total,
    required this.blocked,
    required this.expiring,
    required this.isRefreshing,
    required this.onRefresh,
  });

  final int total;
  final int blocked;
  final int expiring;
  final bool isRefreshing;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SummaryTile(
            label: 'Vehicles',
            value: total.toString(),
            icon: Icons.directions_car_outlined,
          ),
        ),
        const SizedBox(width: OpenVtsSpacing.xs),
        Expanded(
          child: _SummaryTile(
            label: 'Blocked',
            value: blocked.toString(),
            icon: Icons.lock_outline,
          ),
        ),
        const SizedBox(width: OpenVtsSpacing.xs),
        Expanded(
          child: _SummaryTile(
            label: 'Expiring',
            value: expiring.toString(),
            icon: Icons.schedule_outlined,
          ),
        ),
        const SizedBox(width: OpenVtsSpacing.xs),
        GestureDetector(
          onTap: isRefreshing ? null : onRefresh,
          child: Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: OpenVtsColors.surface,
              borderRadius: BorderRadius.circular(OpenVtsRadius.sm),
              border: Border.all(color: OpenVtsColors.border),
            ),
            child: isRefreshing
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: OpenVtsColors.textSecondary,
                    ),
                  )
                : const Icon(
                    Icons.refresh,
                    size: 16,
                    color: OpenVtsColors.textSecondary,
                  ),
          ),
        ),
      ],
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return OpenVtsCard(
      padding: const EdgeInsets.symmetric(
        horizontal: OpenVtsSpacing.sm,
        vertical: OpenVtsSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: OpenVtsColors.textSecondary),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: OpenVtsColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: OpenVtsColors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Search & filter
// ---------------------------------------------------------------------------

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller, required this.onChanged});
  final TextEditingController controller;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: OpenVtsColors.surface,
        borderRadius: BorderRadius.circular(OpenVtsRadius.sm),
        border: Border.all(color: OpenVtsColors.border),
      ),
      padding: const EdgeInsets.symmetric(horizontal: OpenVtsSpacing.sm),
      child: Row(
        children: [
          const Icon(
            Icons.search,
            size: 16,
            color: OpenVtsColors.textSecondary,
          ),
          const SizedBox(width: OpenVtsSpacing.xs),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: (_) => onChanged(),
              style: const TextStyle(
                fontSize: 13,
                color: OpenVtsColors.textPrimary,
              ),
              decoration: const InputDecoration(
                isDense: true,
                hintText: 'Search name, IMEI, SIM, type',
                hintStyle: TextStyle(
                  fontSize: 12,
                  color: OpenVtsColors.textTertiary,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          if (controller.text.isNotEmpty)
            GestureDetector(
              onTap: () {
                controller.clear();
                onChanged();
              },
              child: const Icon(
                Icons.close,
                size: 16,
                color: OpenVtsColors.textSecondary,
              ),
            ),
        ],
      ),
    );
  }
}

class _FilterChips extends StatelessWidget {
  const _FilterChips({required this.value, required this.onChanged});
  final _VehicleFilter value;
  final ValueChanged<_VehicleFilter> onChanged;

  static const _options = <(_VehicleFilter, String)>[
    (_VehicleFilter.all, 'All'),
    (_VehicleFilter.activeLicense, 'Active'),
    (_VehicleFilter.blockedLicense, 'Blocked'),
    (_VehicleFilter.expiring, 'Expiring'),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < _options.length; i++) ...[
            _FilterChip(
              label: _options[i].$2,
              selected: value == _options[i].$1,
              onTap: () => onChanged(_options[i].$1),
            ),
            if (i < _options.length - 1) const SizedBox(width: 6),
          ],
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(OpenVtsRadius.pill),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? OpenVtsColors.brandInk : OpenVtsColors.surface,
          borderRadius: BorderRadius.circular(OpenVtsRadius.pill),
          border: Border.all(
            color: selected ? OpenVtsColors.brandInk : OpenVtsColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: selected ? OpenVtsColors.white : OpenVtsColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Vehicle card
// ---------------------------------------------------------------------------

class _VehicleCard extends StatelessWidget {
  const _VehicleCard({required this.vehicle});
  final SuperadminAdminVehicle vehicle;

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd MMM yyyy');
    return OpenVtsCard(
      padding: const EdgeInsets.symmetric(
        horizontal: OpenVtsSpacing.sm,
        vertical: OpenVtsSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _VehicleIcon(slug: vehicle.vehicleTypeSlug),
              const SizedBox(width: OpenVtsSpacing.xs),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vehicle.name.isNotEmpty ? vehicle.name : 'Vehicle',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: OpenVtsColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      vehicle.vehicleTypeName.isNotEmpty
                          ? vehicle.vehicleTypeName
                          : '—',
                      style: const TextStyle(
                        fontSize: 11,
                        color: OpenVtsColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (vehicle.isLicenseBlocked) const _BlockedBadge(),
            ],
          ),
          const SizedBox(height: 6),
          if (vehicle.imei.isNotEmpty)
            _MetaRow(label: 'IMEI', value: vehicle.imei),
          if (vehicle.simNumber.isNotEmpty)
            _MetaRow(label: 'SIM', value: vehicle.simNumber),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _MetaChip(
                icon: Icons.schedule_outlined,
                label: _expiryLabel(vehicle.primaryExpiry, fmt),
              ),
              if (vehicle.gmtOffset.isNotEmpty)
                _MetaChip(
                  icon: Icons.public,
                  label: 'GMT ${vehicle.gmtOffset}',
                ),
              if (vehicle.createdAt != null)
                _MetaChip(
                  icon: Icons.calendar_today_outlined,
                  label: 'Added ${fmt.format(vehicle.createdAt!)}',
                ),
            ],
          ),
        ],
      ),
    );
  }
}

String _expiryLabel(DateTime? expiry, DateFormat fmt) {
  if (expiry == null) return 'Expiry not set';
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final dueDay = DateTime(expiry.year, expiry.month, expiry.day);
  final diffDays = dueDay.difference(today).inDays;
  if (diffDays < 0) return 'Expired ${fmt.format(expiry)}';
  if (diffDays == 0) return 'Expires today';
  if (diffDays == 1) return 'Expires tomorrow';
  if (diffDays <= 30) return 'Expires in $diffDays days';
  return 'Expires ${fmt.format(expiry)}';
}

class _VehicleIcon extends StatelessWidget {
  const _VehicleIcon({required this.slug});
  final String slug;

  IconData _iconForSlug(String slug) {
    final s = slug.toLowerCase();
    if (s.contains('truck') || s.contains('lorry')) {
      return Icons.local_shipping_outlined;
    }
    if (s.contains('bike') ||
        s.contains('motor') ||
        s.contains('scooter') ||
        s.contains('moped')) {
      return Icons.two_wheeler_outlined;
    }
    if (s.contains('bus') || s.contains('coach')) {
      return Icons.directions_bus_outlined;
    }
    if (s.contains('van')) return Icons.airport_shuttle_outlined;
    if (s.contains('taxi') || s.contains('cab')) {
      return Icons.local_taxi_outlined;
    }
    if (s.contains('tractor') || s.contains('farm')) {
      return Icons.agriculture_outlined;
    }
    if (s.contains('boat') || s.contains('ship') || s.contains('marine')) {
      return Icons.directions_boat_outlined;
    }
    if (s.contains('cycle') || s.contains('bicycle')) {
      return Icons.directions_bike_outlined;
    }
    return Icons.directions_car_outlined;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: OpenVtsColors.surface,
        borderRadius: BorderRadius.circular(OpenVtsRadius.sm),
        border: Border.all(color: OpenVtsColors.border),
      ),
      child: Icon(
        _iconForSlug(slug),
        size: 20,
        color: OpenVtsColors.textPrimary,
      ),
    );
  }
}

class _BlockedBadge extends StatelessWidget {
  const _BlockedBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: OpenVtsColors.surface,
        borderRadius: BorderRadius.circular(OpenVtsRadius.sm),
        border: Border.all(color: OpenVtsColors.border),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lock_outline, size: 11, color: OpenVtsColors.textPrimary),
          SizedBox(width: 4),
          Text(
            'Blocked',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: OpenVtsColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 40,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: OpenVtsColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                color: OpenVtsColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: OpenVtsColors.surface,
        borderRadius: BorderRadius.circular(OpenVtsRadius.sm),
        border: Border.all(color: OpenVtsColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: OpenVtsColors.textSecondary),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: OpenVtsColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return OpenVtsCard(
      padding: const EdgeInsets.symmetric(vertical: OpenVtsSpacing.lg),
      child: Center(
        child: Text(
          message,
          style: const TextStyle(
            fontSize: 12,
            color: OpenVtsColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
