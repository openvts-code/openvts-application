import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../../core/theme/open_vts_colors.dart';
import '../../../../../../core/theme/open_vts_radius.dart';
import '../../../../../../core/theme/open_vts_spacing.dart';
import '../../../../../../core/theme/open_vts_typography.dart';
import '../../../../../../shared/helpers/toast_helper.dart';
import '../../../../../../shared/widgets/open_vts_button.dart';
import '../../../../../../shared/widgets/open_vts_card.dart';
import '../../../../../../shared/widgets/open_vts_empty_state.dart';
import '../../../../controllers/user_subuser_details_controller.dart';
import '../../../../models/user_subuser_model.dart';
import '../../../../models/user_subusers_state.dart';

typedef UserSubUserDetailsProvider = AutoDisposeStateNotifierProvider<
    UserSubUserDetailsController, UserSubUserDetailsState>;

class UserSubUserAssignVehiclesSheet extends ConsumerStatefulWidget {
  const UserSubUserAssignVehiclesSheet({
    required this.provider,
    super.key,
  });

  final UserSubUserDetailsProvider provider;

  @override
  ConsumerState<UserSubUserAssignVehiclesSheet> createState() =>
      _UserSubUserAssignVehiclesSheetState();
}

class _UserSubUserAssignVehiclesSheetState
    extends ConsumerState<UserSubUserAssignVehiclesSheet> {
  var _searchQuery = '';
  final Set<String> _selectedIds = <String>{};

  @override
  void initState() {
    super.initState();
    _selectedIds.addAll(ref.read(widget.provider).selectedVehicleIds);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(widget.provider);
    final available = state.availableVehicles;
    final filtered = _filterVehicles(available, _searchQuery);
    final isLoading = state.isLoadingVehicles && available.isEmpty;
    final isSubmitting = state.isAssigningVehicles;

    return Column(
      children: [
        Expanded(
          child: ListView(
            controller: PrimaryScrollController.maybeOf(context),
            padding: const EdgeInsets.all(OpenVtsSpacing.md),
            children: [
              TextField(
                onChanged: (value) {
                  setState(() => _searchQuery = value.trim());
                },
                decoration: const InputDecoration(
                  hintText: 'Search by name, plate, VIN, IMEI, SIM...',
                  prefixIcon: Icon(Icons.search, size: 20),
                ),
              ),
              const SizedBox(height: OpenVtsSpacing.sm),
              _HeaderRow(
                totalCount: available.length,
                visibleCount: filtered.length,
                selectedCount: _selectedIds.length,
                isLoading: state.isLoadingVehicles,
              ),
              if (state.errorMessage != null) ...[
                const SizedBox(height: OpenVtsSpacing.sm),
                _InlineError(message: state.errorMessage!),
              ],
              const SizedBox(height: OpenVtsSpacing.sm),
              if (isLoading)
                const _LoadingCard(label: 'Loading available vehicles')
              else if (filtered.isEmpty)
                OpenVtsCard(
                  child: OpenVtsEmptyState(
                    title: available.isEmpty
                        ? 'No available vehicles'
                        : 'No matching vehicles',
                    message: available.isEmpty
                        ? 'All vehicles are already assigned to this sub user.'
                        : 'Try a different search query.',
                  ),
                )
              else
                for (var index = 0; index < filtered.length; index++) ...[
                  _VehicleOptionCard(
                    vehicle: filtered[index],
                    isSelected: _selectedIds.contains(filtered[index].id),
                    onTap: () => _toggleSelection(filtered[index].id),
                  ),
                  if (index < filtered.length - 1)
                    const SizedBox(height: OpenVtsSpacing.sm),
                ],
            ],
          ),
        ),
        const Divider(height: 1),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(OpenVtsSpacing.md),
            child: Row(
              children: [
                Expanded(
                  child: OpenVtsButton(
                    label: 'Cancel',
                    height: 40,
                    variant: OpenVtsButtonVariant.secondary,
                    onPressed:
                        isSubmitting ? null : () => Navigator.of(context).pop(),
                  ),
                ),
                const SizedBox(width: OpenVtsSpacing.sm),
                Expanded(
                  child: OpenVtsButton(
                    label: 'Assign Selected',
                    height: 40,
                    trailingIcon: Icons.check_rounded,
                    isLoading: isSubmitting,
                    onPressed: isSubmitting || _selectedIds.isEmpty
                        ? null
                        : _assignVehicles,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _assignVehicles() async {
    if (_selectedIds.isEmpty) {
      ToastHelper.showError('Select at least one vehicle.', context: context);
      return;
    }

    final ids = _selectedIds.toList(growable: false);
    final ok = await ref.read(widget.provider.notifier).assignVehicles(ids);
    if (!mounted) {
      return;
    }

    if (ok) {
      ToastHelper.showSuccess('Vehicles assigned.', context: context);
      Navigator.of(context).pop(true);
      return;
    }

    ToastHelper.showError(
      ref.read(widget.provider).errorMessage ?? 'Unable to assign vehicles.',
      context: context,
    );
  }

  void _toggleSelection(String vehicleId) {
    final id = vehicleId.trim();
    if (id.isEmpty) {
      return;
    }

    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  List<UserSubUserVehicle> _filterVehicles(
    List<UserSubUserVehicle> source,
    String query,
  ) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) {
      return source;
    }

    return source.where((item) {
      return item.searchContent.contains(normalized);
    }).toList(growable: false);
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow({
    required this.totalCount,
    required this.visibleCount,
    required this.selectedCount,
    required this.isLoading,
  });

  final int totalCount;
  final int visibleCount;
  final int selectedCount;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            '$visibleCount of $totalCount vehicles • $selectedCount selected',
            style: OpenVtsTypography.meta.copyWith(
              color: OpenVtsColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        if (isLoading)
          const SizedBox(
            width: 13,
            height: 13,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
      ],
    );
  }
}

class _VehicleOptionCard extends StatelessWidget {
  const _VehicleOptionCard({
    required this.vehicle,
    required this.isSelected,
    required this.onTap,
  });

  final UserSubUserVehicle vehicle;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OpenVtsCard(
      onTap: onTap,
      padding: const EdgeInsets.all(OpenVtsSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: OpenVtsColors.surface,
              borderRadius: BorderRadius.circular(OpenVtsRadius.sm),
              border: Border.all(color: OpenVtsColors.border),
            ),
            child: const Icon(
              Icons.directions_car_filled_outlined,
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
                  _joinParts([vehicle.name, vehicle.plateNumber]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: OpenVtsTypography.label.copyWith(
                    color: OpenVtsColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _joinParts([
                    vehicle.vin.isEmpty ? null : 'VIN ${vehicle.vin}',
                    vehicle.imei.isEmpty ? null : 'IMEI ${vehicle.imei}',
                    vehicle.simNumber.isEmpty
                        ? null
                        : 'SIM ${vehicle.simNumber}',
                  ]),
                  maxLines: 2,
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
          AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected
                  ? OpenVtsColors.brandInk.withValues(alpha: 0.12)
                  : OpenVtsColors.surface,
              border: Border.all(
                color:
                    isSelected ? OpenVtsColors.brandInk : OpenVtsColors.border,
              ),
            ),
            child: Icon(
              isSelected ? Icons.check_rounded : Icons.circle_outlined,
              size: 14,
              color: isSelected
                  ? OpenVtsColors.brandInk
                  : OpenVtsColors.textTertiary,
            ),
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
          const Icon(
            Icons.error_outline_rounded,
            size: 16,
            color: OpenVtsColors.error,
          ),
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

String _joinParts(List<String?> values) {
  final normalized = values
      .map((item) => item?.trim() ?? '')
      .where((item) => item.isNotEmpty)
      .toList(growable: false);

  if (normalized.isEmpty) {
    return '-';
  }

  return normalized.join(' - ');
}
