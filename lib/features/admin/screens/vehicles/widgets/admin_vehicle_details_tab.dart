import 'package:flutter/material.dart';

import '../../../../../core/theme/open_vts_spacing.dart';
import '../../../../../shared/widgets/open_vts_button.dart';
import '../../../../../shared/widgets/open_vts_card.dart';
import '../../../models/admin_vehicle_model.dart';

class AdminVehicleDetailsOverviewTab extends StatelessWidget {
  const AdminVehicleDetailsOverviewTab({
    super.key,
    required this.vehicle,
    required this.onEdit,
    required this.onToggleStatus,
    required this.onDelete,
    required this.isUpdatingStatus,
    required this.isDeleting,
  });

  final AdminVehicleDetails vehicle;
  final VoidCallback onEdit;
  final VoidCallback onToggleStatus;
  final VoidCallback onDelete;
  final bool isUpdatingStatus;
  final bool isDeleting;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        OpenVtsCard(
          child: _Section(
            title: 'Identity',
            rows: [
              _kv('Name', vehicle.name),
              _kv('Plate Number', vehicle.plateNumber),
              _kv('VIN', vehicle.vin),
              _kv('Type', vehicle.vehicleType?.name ?? '-'),
            ],
          ),
        ),
        const SizedBox(height: OpenVtsSpacing.sm),
        OpenVtsCard(
          child: _Section(
            title: 'Device',
            rows: [
              _kv('IMEI', vehicle.imei),
              _kv('SIM', vehicle.simNumber),
              _kv('Speed Variation', _num(vehicle.device?.speedVariation)),
              _kv('Distance Variation',
                  _num(vehicle.device?.distanceVariation)),
              _kv('Odometer', _num(vehicle.device?.odometer)),
              _kv('Engine Hours', _num(vehicle.device?.engineHours)),
              _kv('Ignition Source', vehicle.device?.ignitionSource ?? '-'),
            ],
          ),
        ),
        const SizedBox(height: OpenVtsSpacing.sm),
        OpenVtsCard(
          child: _Section(
            title: 'Ownership',
            rows: [
              _kv('Primary User', vehicle.primaryUser?.name ?? '-'),
              _kv('Plan', vehicle.plan?.name ?? '-'),
            ],
          ),
        ),
        const SizedBox(height: OpenVtsSpacing.sm),
        OpenVtsCard(
          child: _Section(
            title: 'Dates',
            rows: [
              _kv('Created At', _date(vehicle.createdAt)),
              _kv('Updated At', _date(vehicle.updatedAt)),
            ],
          ),
        ),
        const SizedBox(height: OpenVtsSpacing.sm),
        OpenVtsCard(
          child: _Section(
            title: 'Metadata',
            rows: vehicle.vehicleMeta.entries
                .map((entry) => _kv(entry.key, entry.value?.toString() ?? '-'))
                .toList(growable: false),
          ),
        ),
        const SizedBox(height: OpenVtsSpacing.sm),
        OpenVtsCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Actions', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: OpenVtsSpacing.sm),
              Wrap(
                spacing: OpenVtsSpacing.xs,
                runSpacing: OpenVtsSpacing.xs,
                children: [
                  OpenVtsButton(label: 'Edit', onPressed: onEdit),
                  OpenVtsButton(
                    label: vehicle.isActive ? 'Deactivate' : 'Activate',
                    onPressed: isUpdatingStatus ? null : onToggleStatus,
                    isLoading: isUpdatingStatus,
                    variant: OpenVtsButtonVariant.secondary,
                  ),
                  OpenVtsButton(
                    label: 'Delete',
                    onPressed: isDeleting ? null : onDelete,
                    isLoading: isDeleting,
                    variant: OpenVtsButtonVariant.secondary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<_KV> _kv(String label, String value) =>
      [_KV(label: label, value: value.trim().isEmpty ? '-' : value)];

  String _date(DateTime? value) {
    if (value == null) return '-';
    return value
        .toLocal()
        .toIso8601String()
        .replaceFirst('T', ' ')
        .split('.')
        .first;
  }

  String _num(num? value) => value == null ? '-' : value.toString();
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.rows});

  final String title;
  final List<List<_KV>> rows;

  @override
  Widget build(BuildContext context) {
    final flat = rows.expand((e) => e).toList(growable: false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: OpenVtsSpacing.xs),
        ...flat.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text('${item.label}: ${item.value}'),
            )),
      ],
    );
  }
}

class _KV {
  const _KV({required this.label, required this.value});

  final String label;
  final String value;
}
