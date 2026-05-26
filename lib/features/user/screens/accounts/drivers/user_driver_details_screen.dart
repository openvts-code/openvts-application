import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/router/route_paths.dart';
import '../../../../../core/theme/open_vts_colors.dart';
import '../../../../../core/theme/open_vts_radius.dart';
import '../../../../../core/theme/open_vts_spacing.dart';
import '../../../../../core/theme/open_vts_typography.dart';
import '../../../../../shared/widgets/open_vts_card.dart';
import '../../../../../shared/widgets/open_vts_error_view.dart';
import '../../../../../shared/widgets/open_vts_loader.dart';
import '../../../../../shared/widgets/open_vts_page_scaffold.dart';
import '../../../controllers/user_driver_details_controller.dart';
import '../../../controllers/user_providers.dart';
import '../../../models/user_driver_model.dart';
import '../../../models/user_drivers_state.dart';
import 'widgets/user_driver_documents_tab.dart';
import 'widgets/user_driver_logs_tab.dart';
import 'widgets/user_driver_profile_tab.dart';

enum _UserDriverDetailsTab { profile, documents, logs }

class UserDriverDetailsScreen extends ConsumerStatefulWidget {
  const UserDriverDetailsScreen({
    super.key,
    required this.driverId,
    this.initialDriver,
  });

  final String driverId;
  final UserDriver? initialDriver;

  @override
  ConsumerState<UserDriverDetailsScreen> createState() =>
      _UserDriverDetailsScreenState();
}

class _UserDriverDetailsScreenState
    extends ConsumerState<UserDriverDetailsScreen> {
  var _selectedTab = _UserDriverDetailsTab.profile;

  @override
  Widget build(BuildContext context) {
    final provider = userDriverDetailsControllerProvider(
      UserDriverDetailsProviderArgs(
        driverId: widget.driverId,
        initialDriver: widget.initialDriver,
      ),
    );
    final state = ref.watch(provider);
    final controller = ref.read(provider.notifier);
    final driver = state.driver ?? widget.initialDriver;

    return OpenVtsPageScaffold(
      title: _driverTitle(driver),
      padding: EdgeInsets.zero,
      leading: IconButton(
        tooltip: 'Back',
        onPressed: () => _close(context),
        icon: const Icon(Icons.arrow_back_rounded, size: 20),
      ),
      actions: [
        _HeaderIconButton(
          tooltip: 'Refresh',
          onPressed: _isRefreshingCurrentTab(state)
              ? null
              : () => _refreshCurrentTab(provider),
          icon: _isRefreshingCurrentTab(state)
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.refresh_rounded, size: 18),
        ),
        const SizedBox(width: OpenVtsSpacing.xs),
      ],
      body: _buildBody(context, provider, state, controller, driver),
    );
  }

  Widget _buildBody(
    BuildContext context,
    AutoDisposeStateNotifierProvider<UserDriverDetailsController,
            UserDriverDetailsState>
        provider,
    UserDriverDetailsState state,
    UserDriverDetailsController controller,
    UserDriver? driver,
  ) {
    if (state.isLoading && !state.hasDriver) {
      return const OpenVtsLoader();
    }

    if (state.errorMessage != null && !state.hasDriver) {
      return OpenVtsErrorView(
        message: state.errorMessage!,
        onRetry: controller.loadInitial,
      );
    }

    return RefreshIndicator(
      onRefresh: () => _refreshCurrentTab(provider),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(OpenVtsSpacing.sm),
        children: [
          _DriverSummaryCard(driver: driver),
          if (state.errorMessage != null) ...[
            const SizedBox(height: OpenVtsSpacing.sm),
            _InlineError(message: state.errorMessage!),
          ],
          const SizedBox(height: OpenVtsSpacing.sm),
          _TabChips(
            selectedTab: _selectedTab,
            onSelect: (tab) => setState(() => _selectedTab = tab),
          ),
          const SizedBox(height: OpenVtsSpacing.sm),
          _TabContent(provider: provider, selectedTab: _selectedTab),
          const SizedBox(height: OpenVtsSpacing.lg),
        ],
      ),
    );
  }

  Future<void> _refreshCurrentTab(
    AutoDisposeStateNotifierProvider<UserDriverDetailsController,
            UserDriverDetailsState>
        provider,
  ) async {
    final controller = ref.read(provider.notifier);
    switch (_selectedTab) {
      case _UserDriverDetailsTab.profile:
        await controller.refresh();
        break;
      case _UserDriverDetailsTab.documents:
        await controller.loadDocuments();
        break;
      case _UserDriverDetailsTab.logs:
        await controller.loadLogs();
        break;
    }
  }

  bool _isRefreshingCurrentTab(UserDriverDetailsState state) {
    switch (_selectedTab) {
      case _UserDriverDetailsTab.profile:
        return state.isLoading ||
            state.isSaving ||
            state.isAssigning ||
            state.isUnassigning;
      case _UserDriverDetailsTab.documents:
        return state.isLoadingDocuments || state.isUploadingDocument;
      case _UserDriverDetailsTab.logs:
        return state.isLoadingLogs;
    }
  }

  void _close(BuildContext context) {
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go(RoutePaths.userDrivers);
  }
}

class _TabContent extends StatelessWidget {
  const _TabContent({
    required this.provider,
    required this.selectedTab,
  });

  final AutoDisposeStateNotifierProvider<UserDriverDetailsController,
      UserDriverDetailsState> provider;
  final _UserDriverDetailsTab selectedTab;

  @override
  Widget build(BuildContext context) {
    return switch (selectedTab) {
      _UserDriverDetailsTab.profile => UserDriverProfileTab(provider: provider),
      _UserDriverDetailsTab.documents =>
        UserDriverDocumentsTab(provider: provider),
      _UserDriverDetailsTab.logs => UserDriverLogsTab(provider: provider),
    };
  }
}

class _DriverSummaryCard extends StatelessWidget {
  const _DriverSummaryCard({required this.driver});

  final UserDriver? driver;

  @override
  Widget build(BuildContext context) {
    final assignedVehicle = driver?.assignedVehicle;
    final assignmentLabel = assignedVehicle == null
        ? 'Unassigned'
        : _joinParts([
            assignedVehicle.name,
            assignedVehicle.plateNumber,
            assignedVehicle.imei,
          ]);

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
                  Icons.badge_outlined,
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
                      _driverTitle(driver),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          OpenVtsTypography.titleSmall.copyWith(fontSize: 16),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _usernameLabel(driver),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: OpenVtsTypography.meta.copyWith(
                        color: OpenVtsColors.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: OpenVtsSpacing.sm),
          Wrap(
            spacing: OpenVtsSpacing.xs,
            runSpacing: OpenVtsSpacing.xs,
            children: [
              _StatusPill(
                label: (driver?.isActive ?? false) ? 'Active' : 'Inactive',
                color: (driver?.isActive ?? false)
                    ? OpenVtsColors.success
                    : OpenVtsColors.textSecondary,
                icon: (driver?.isActive ?? false)
                    ? Icons.check_circle_outline_rounded
                    : Icons.pause_circle_outline_rounded,
              ),
              _StatusPill(
                label:
                    (driver?.isVerified ?? false) ? 'Verified' : 'Unverified',
                color: (driver?.isVerified ?? false)
                    ? OpenVtsColors.brandInk
                    : OpenVtsColors.textSecondary,
                icon: (driver?.isVerified ?? false)
                    ? Icons.verified_user_outlined
                    : Icons.shield_outlined,
              ),
              _StatusPill(
                label: assignmentLabel,
                color: assignedVehicle == null
                    ? OpenVtsColors.textSecondary
                    : OpenVtsColors.brandInk,
                icon: Icons.directions_car_outlined,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TabChips extends StatelessWidget {
  const _TabChips({required this.selectedTab, required this.onSelect});

  final _UserDriverDetailsTab selectedTab;
  final ValueChanged<_UserDriverDetailsTab> onSelect;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _UserDriverDetailsTab.values.map((tab) {
          final isSelected = tab == selectedTab;
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

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.label,
    required this.color,
    required this.icon,
  });

  final String label;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 280),
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

String _tabLabel(_UserDriverDetailsTab tab) {
  return switch (tab) {
    _UserDriverDetailsTab.profile => 'Profile',
    _UserDriverDetailsTab.documents => 'Documents',
    _UserDriverDetailsTab.logs => 'Logs',
  };
}

String _driverTitle(UserDriver? driver) {
  if (driver == null) return 'Driver';
  for (final value in [driver.name, driver.username, driver.email]) {
    final normalized = value.trim();
    if (normalized.isNotEmpty && normalized != '-') {
      return normalized;
    }
  }
  return 'Driver';
}

String _usernameLabel(UserDriver? driver) {
  final username = driver?.username.trim() ?? '';
  if (username.isEmpty || username == '-') {
    return 'Username unavailable';
  }
  return '@$username';
}

String _joinParts(List<String?> parts) {
  final normalized = parts
      .map((item) => item?.trim() ?? '')
      .where((item) => item.isNotEmpty && item != '-')
      .toList(growable: false);

  if (normalized.isEmpty) {
    return '-';
  }

  return normalized.join(' - ');
}
