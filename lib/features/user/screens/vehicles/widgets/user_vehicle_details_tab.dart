import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/open_vts_colors.dart';
import '../../../../../core/theme/open_vts_radius.dart';
import '../../../../../core/theme/open_vts_spacing.dart';
import '../../../../../core/theme/open_vts_typography.dart';
import '../../../../../core/utils/date_time_formatter.dart';
import '../../../../../shared/widgets/open_vts_bottom_sheet.dart';
import '../../../../../shared/widgets/open_vts_button.dart';
import '../../../../../shared/widgets/open_vts_card.dart';
import '../../../controllers/user_vehicle_details_controller.dart';
import '../../../models/user_vehicle_model.dart';
import '../../../models/user_vehicle_state.dart';
import 'user_vehicle_edit_sheet.dart';

const DateTimeFormatter _dateFormatter = DateTimeFormatter();

class UserVehicleDetailsTabView extends ConsumerWidget {
  const UserVehicleDetailsTabView({required this.provider, super.key});

  final AutoDisposeStateNotifierProvider<UserVehicleDetailsController,
      UserVehicleDetailsState> provider;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(provider);
    final controller = ref.read(provider.notifier);
    final vehicle = state.vehicle;

    if (vehicle == null) {
      return _SectionStateCard(
        title: 'Vehicle details',
        isLoading: state.isLoadingVehicle,
        onRetry: controller.loadVehicle,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: _CompactActionButton(
            label: 'Edit',
            icon: Icons.edit_outlined,
            isLoading: state.isSavingVehicle || state.isLoadingReferenceData,
            onPressed: state.isSavingVehicle
                ? null
                : () => _showEditSheet(context, ref, vehicle),
          ),
        ),
        const SizedBox(height: OpenVtsSpacing.sm),
        _InfoCard(
          title: 'Overview',
          icon: Icons.directions_car_filled_outlined,
          rows: [
            _InfoRow(
              label: 'Vehicle Type',
              value: _display(vehicle.vehicleType?.name),
            ),
            _InfoRow(label: 'GMT Offset', value: _display(vehicle.gmtOffset)),
            _InfoRow(label: 'Created At', value: _dateText(vehicle.createdAt)),
          ],
        ),
        const SizedBox(height: OpenVtsSpacing.sm),
        _InfoCard(
          title: 'Identity',
          icon: Icons.badge_outlined,
          rows: [
            _InfoRow(label: 'Name', value: _display(vehicle.name)),
            _InfoRow(
              label: 'Plate Number',
              value: _display(vehicle.plateNumber),
            ),
            _InfoRow(label: 'VIN', value: _display(vehicle.vin)),
            _InfoRow(label: 'IMEI', value: _display(vehicle.imei)),
            _InfoRow(label: 'SIM Number', value: _display(vehicle.simNumber)),
          ],
        ),
        const SizedBox(height: OpenVtsSpacing.sm),
        _InfoCard(
          title: 'Plan',
          icon: Icons.credit_card_outlined,
          rows: [
            _InfoRow(label: 'Plan Name', value: _display(vehicle.plan?.name)),
            _InfoRow(label: 'Price', value: _numberText(vehicle.plan?.price)),
            _InfoRow(
                label: 'Currency', value: _display(vehicle.plan?.currency)),
          ],
        ),
        const SizedBox(height: OpenVtsSpacing.sm),
        _MetadataCard(meta: vehicle.vehicleMeta),
        const SizedBox(height: OpenVtsSpacing.sm),
        _InfoCard(
          title: 'Device Summary',
          icon: Icons.memory_outlined,
          rows: [
            _InfoRow(
                label: 'Device IMEI', value: _display(vehicle.device?.imei)),
            _InfoRow(
              label: 'Speed Multiplier',
              value: _numberText(vehicle.device?.speedVariation),
            ),
            _InfoRow(
              label: 'Distance Multiplier',
              value: _numberText(vehicle.device?.distanceVariation),
            ),
            _InfoRow(
                label: 'Odometer',
                value: _numberText(vehicle.device?.odometer)),
            _InfoRow(
              label: 'Engine Hours',
              value: _numberText(vehicle.device?.engineHours),
            ),
            _InfoRow(
              label: 'Ignition Source',
              value: _display(vehicle.device?.ignitionSource),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _showEditSheet(
    BuildContext context,
    WidgetRef ref,
    UserVehicleDetails vehicle,
  ) async {
    await ref.read(provider.notifier).loadReferenceData();
    if (!context.mounted) return;

    await OpenVtsBottomSheet.show<void>(
      context: context,
      title: 'Edit Vehicle',
      initialChildSize: 0.88,
      minChildSize: 0.52,
      maxChildSize: 0.96,
      child: UserVehicleEditSheet(
        provider: provider,
        vehicle: vehicle,
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.title,
    required this.icon,
    required this.rows,
  });

  final String title;
  final IconData icon;
  final List<_InfoRow> rows;

  @override
  Widget build(BuildContext context) {
    return OpenVtsCard(
      padding: const EdgeInsets.all(OpenVtsSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(title: title, icon: icon),
          const SizedBox(height: OpenVtsSpacing.xs),
          for (final row in rows) row,
        ],
      ),
    );
  }
}

class _MetadataCard extends StatelessWidget {
  const _MetadataCard({required this.meta});

  final Map<String, dynamic> meta;

  @override
  Widget build(BuildContext context) {
    final entries = meta.entries.toList(growable: false)
      ..sort((left, right) => left.key.compareTo(right.key));
    return OpenVtsCard(
      padding: const EdgeInsets.all(OpenVtsSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardHeader(
              title: 'Vehicle Meta', icon: Icons.data_object_rounded),
          const SizedBox(height: OpenVtsSpacing.xs),
          if (entries.isEmpty)
            Text(
              'No metadata',
              style: OpenVtsTypography.meta.copyWith(
                color: OpenVtsColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            )
          else
            for (final entry in entries)
              _InfoRow(
                label: _titleCase(entry.key),
                value: _display(entry.value?.toString()),
              ),
        ],
      ),
    );
  }
}

class _CardHeader extends StatelessWidget {
  const _CardHeader({required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: OpenVtsColors.textSecondary),
        const SizedBox(width: OpenVtsSpacing.xs),
        Expanded(
          child: Text(
            title,
            style: OpenVtsTypography.label.copyWith(
              color: OpenVtsColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: OpenVtsTypography.meta.copyWith(
                color: OpenVtsColors.textTertiary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: OpenVtsSpacing.sm),
          Flexible(
            flex: 2,
            child: Text(
              value,
              textAlign: TextAlign.end,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: OpenVtsTypography.meta.copyWith(
                color: OpenVtsColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactActionButton extends StatelessWidget {
  const _CompactActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.isLoading = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: OutlinedButton.icon(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: OpenVtsColors.white,
          foregroundColor: OpenVtsColors.textPrimary,
          side: const BorderSide(color: OpenVtsColors.border),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(OpenVtsRadius.pill),
          ),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        icon: isLoading
            ? const SizedBox(
                width: 13,
                height: 13,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(icon, size: 15),
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

class _SectionStateCard extends StatelessWidget {
  const _SectionStateCard({
    required this.title,
    required this.isLoading,
    required this.onRetry,
  });

  final String title;
  final bool isLoading;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return OpenVtsCard(
      padding: const EdgeInsets.all(OpenVtsSpacing.sm),
      child: isLoading
          ? Row(
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: OpenVtsSpacing.sm),
                Text(
                  'Loading $title',
                  style: OpenVtsTypography.meta.copyWith(
                    color: OpenVtsColors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '$title could not be loaded.',
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

String _display(String? value) {
  final normalized = value?.trim();
  return normalized == null || normalized.isEmpty ? '-' : normalized;
}

String _numberText(num? value) {
  if (value == null) return '-';
  if (value == value.roundToDouble()) return value.toInt().toString();
  return value.toString();
}

String _dateText(DateTime? value) {
  if (value == null) return '-';
  return _dateFormatter.formatDate(value.toLocal());
}

String _titleCase(String value) {
  final spaced = value
      .replaceAll('_', ' ')
      .replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (match) {
    return '${match.group(1)} ${match.group(2)}';
  }).trim();
  if (spaced.isEmpty) return '-';
  return spaced
      .split(RegExp(r'\s+'))
      .map((part) => part.isEmpty
          ? part
          : '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}')
      .join(' ');
}
