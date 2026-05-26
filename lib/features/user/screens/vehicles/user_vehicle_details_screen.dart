import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/open_vts_colors.dart';
import '../../../../core/theme/open_vts_radius.dart';
import '../../../../core/theme/open_vts_spacing.dart';
import '../../../../core/theme/open_vts_typography.dart';
import '../../../../shared/widgets/open_vts_card.dart';
import '../../../../shared/widgets/open_vts_error_view.dart';
import '../../../../shared/widgets/open_vts_loader.dart';
import '../../../../shared/widgets/open_vts_page_scaffold.dart';
import '../../controllers/user_providers.dart';
import '../../controllers/user_vehicle_details_controller.dart';
import '../../models/user_vehicle_model.dart';
import '../../models/user_vehicle_state.dart';
import 'widgets/user_vehicle_config_tab.dart';
import 'widgets/user_vehicle_details_tab.dart';
import 'widgets/user_vehicle_documents_tab.dart';
import 'widgets/user_vehicle_sensors_tab.dart';

class UserVehicleDetailsScreen extends ConsumerWidget {
  const UserVehicleDetailsScreen({
    super.key,
    required this.vehicleId,
    this.initialVehicle,
  });

  final String vehicleId;
  final UserVehicleListItem? initialVehicle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = userVehicleDetailsControllerProvider(
      UserVehicleDetailsProviderArgs(
        vehicleId: vehicleId,
        initialVehicle: initialVehicle,
      ),
    );
    final state = ref.watch(provider);
    final controller = ref.read(provider.notifier);
    final vehicle = state.vehicle;
    final title = vehicle?.title ?? _initialVehicleTitle(state.initialVehicle);

    return OpenVtsPageScaffold(
      title: title,
      padding: EdgeInsets.zero,
      leading: IconButton(
        tooltip: 'Back',
        onPressed: () => _close(context),
        icon: const Icon(Icons.arrow_back_rounded, size: 20),
      ),
      actions: [
        _HeaderIconButton(
          tooltip: 'Refresh',
          onPressed: state.isRefreshingCurrentTab
              ? null
              : () => controller.refreshCurrentTab(),
          icon: state.isRefreshingCurrentTab
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.refresh_rounded, size: 18),
        ),
        const SizedBox(width: OpenVtsSpacing.xs),
      ],
      body: _buildBody(context, ref, state, controller),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    UserVehicleDetailsState state,
    UserVehicleDetailsController controller,
  ) {
    if (state.isLoadingVehicle && !state.hasVehicle) {
      return const OpenVtsLoader();
    }

    if (state.errorMessage != null && !state.hasVehicle) {
      return OpenVtsErrorView(
        message: state.errorMessage!,
        onRetry: controller.loadVehicle,
      );
    }

    return RefreshIndicator(
      onRefresh: controller.refreshCurrentTab,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(OpenVtsSpacing.sm),
        children: [
          _VehicleSummaryCard(
            vehicle: state.vehicle,
            initialVehicle: state.initialVehicle,
          ),
          if (state.sectionErrorMessage != null) ...[
            const SizedBox(height: OpenVtsSpacing.sm),
            _InlineError(message: state.sectionErrorMessage!),
          ],
          const SizedBox(height: OpenVtsSpacing.sm),
          _TabChips(
            selected: state.selectedTab,
            onSelect: controller.selectTab,
          ),
          const SizedBox(height: OpenVtsSpacing.sm),
          _TabContent(
            provider: userVehicleDetailsControllerProvider(
              UserVehicleDetailsProviderArgs(
                vehicleId: vehicleId,
                initialVehicle: initialVehicle,
              ),
            ),
          ),
          const SizedBox(height: OpenVtsSpacing.lg),
        ],
      ),
    );
  }

  void _close(BuildContext context) {
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go(RoutePaths.userVehicles);
  }
}

class _TabContent extends ConsumerWidget {
  const _TabContent({required this.provider});

  final AutoDisposeStateNotifierProvider<UserVehicleDetailsController,
      UserVehicleDetailsState> provider;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(provider);

    return switch (state.selectedTab) {
      UserVehicleDetailsTab.details => UserVehicleDetailsTabView(
          provider: provider,
        ),
      UserVehicleDetailsTab.sensors => UserVehicleSensorsTabView(
          provider: provider,
        ),
      UserVehicleDetailsTab.documents => UserVehicleDocumentsTabView(
          provider: provider,
        ),
      UserVehicleDetailsTab.config => UserVehicleConfigTabView(
          provider: provider,
        ),
    };
  }
}

class _VehicleSummaryCard extends StatelessWidget {
  const _VehicleSummaryCard(
      {required this.vehicle, required this.initialVehicle});

  final UserVehicleDetails? vehicle;
  final UserVehicleListItem? initialVehicle;

  @override
  Widget build(BuildContext context) {
    final title = vehicle?.title ?? _initialVehicleTitle(initialVehicle);
    final plate = vehicle?.plateNumber ?? initialVehicle?.plateNumber ?? '';
    final vin = vehicle?.vin ?? initialVehicle?.vin ?? '';
    final imei = vehicle?.imei ?? initialVehicle?.imei ?? '';
    final simNumber = vehicle?.simNumber ?? initialVehicle?.simNumber ?? '';
    final type =
        vehicle?.vehicleType?.name ?? initialVehicle?.vehicleTypeName ?? '';
    final isActive = vehicle?.isActive ?? initialVehicle?.isActive ?? true;
    final isLicenseBlocked =
        vehicle?.isLicenseBlocked ?? initialVehicle?.isLicenseBlocked ?? false;

    return OpenVtsCard(
      padding: const EdgeInsets.all(OpenVtsSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: OpenVtsColors.textPrimary.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(OpenVtsRadius.sm),
                  border: Border.all(color: OpenVtsColors.border),
                ),
                child: const Icon(
                  Icons.directions_car_filled_outlined,
                  size: 20,
                  color: OpenVtsColors.textSecondary,
                ),
              ),
              const SizedBox(width: OpenVtsSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          OpenVtsTypography.titleSmall.copyWith(fontSize: 16),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _joinParts([plate, type]),
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
              _Pill(
                label: isActive ? 'Active' : 'Inactive',
                icon: isActive
                    ? Icons.check_circle_outline_rounded
                    : Icons.pause_circle_outline_rounded,
                color: isActive
                    ? OpenVtsColors.success
                    : OpenVtsColors.textSecondary,
              ),
            ],
          ),
          const SizedBox(height: OpenVtsSpacing.sm),
          Wrap(
            spacing: OpenVtsSpacing.xs,
            runSpacing: OpenVtsSpacing.xs,
            children: [
              if (plate.trim().isNotEmpty)
                _MetaPill(
                    icon: Icons.confirmation_number_outlined, label: plate),
              if (vin.trim().isNotEmpty)
                _MetaPill(icon: Icons.tag_outlined, label: 'VIN ${vin.trim()}'),
              _MetaPill(
                  icon: Icons.memory_outlined, label: 'IMEI ${_display(imei)}'),
              _MetaPill(
                icon: Icons.sim_card_outlined,
                label: 'SIM ${_display(simNumber)}',
              ),
              if (type.trim().isNotEmpty)
                _MetaPill(icon: Icons.category_outlined, label: type.trim()),
              if (isLicenseBlocked)
                const _Pill(
                  label: 'License Blocked',
                  icon: Icons.block_rounded,
                  color: OpenVtsColors.error,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TabChips extends StatelessWidget {
  const _TabChips({required this.selected, required this.onSelect});

  final UserVehicleDetailsTab selected;
  final ValueChanged<UserVehicleDetailsTab> onSelect;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: UserVehicleDetailsTab.values.map((tab) {
          final isSelected = tab == selected;
          return Padding(
            padding: const EdgeInsets.only(right: OpenVtsSpacing.xs),
            child: ChoiceChip(
              selected: isSelected,
              label: Text(_tabLabel(tab)),
              onSelected: (_) => onSelect(tab),
              showCheckmark: false,
              labelStyle: OpenVtsTypography.meta.copyWith(
                fontWeight: FontWeight.w800,
                color: isSelected
                    ? OpenVtsColors.white
                    : OpenVtsColors.textPrimary,
              ),
              selectedColor: OpenVtsColors.brandInk,
              backgroundColor: OpenVtsColors.white,
              side: const BorderSide(color: OpenVtsColors.border),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(OpenVtsRadius.pill),
              ),
            ),
          );
        }).toList(growable: false),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.icon, required this.color});

  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 260),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(OpenVtsRadius.pill),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: OpenVtsTypography.meta.copyWith(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
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
    return _Pill(label: label, icon: icon, color: OpenVtsColors.textSecondary);
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.tooltip,
    required this.onPressed,
    required this.icon,
  });

  final String tooltip;
  final VoidCallback? onPressed;
  final Widget icon;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: icon,
      style: IconButton.styleFrom(
        minimumSize: const Size.square(36),
        padding: EdgeInsets.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
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

String _tabLabel(UserVehicleDetailsTab tab) {
  return switch (tab) {
    UserVehicleDetailsTab.details => 'Vehicle Details',
    UserVehicleDetailsTab.sensors => 'Sensors',
    UserVehicleDetailsTab.documents => 'Documents',
    UserVehicleDetailsTab.config => 'Config',
  };
}

String _initialVehicleTitle(UserVehicleListItem? vehicle) {
  if (vehicle == null) return 'Vehicle';
  if (vehicle.name.trim().isNotEmpty) return vehicle.name.trim();
  if (vehicle.plateNumber.trim().isNotEmpty) return vehicle.plateNumber.trim();
  if (vehicle.imei.trim().isNotEmpty) return vehicle.imei.trim();
  return 'Vehicle';
}

String _display(String? value) {
  final normalized = value?.trim();
  return normalized == null || normalized.isEmpty ? '-' : normalized;
}

String _joinParts(List<String?> parts) {
  final normalized = parts
      .map((item) => item?.trim() ?? '')
      .where((item) => item.isNotEmpty)
      .toList(growable: false);
  return normalized.isEmpty ? '-' : normalized.join(' - ');
}
