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
import '../../../../../shared/widgets/open_vts_error_view.dart';
import '../../../controllers/admin_providers.dart';
import '../../../controllers/admin_user_details_controller.dart';
import '../../../models/admin_user_details_model.dart';

class AdminUserDriversTab extends ConsumerStatefulWidget {
  const AdminUserDriversTab({
    super.key,
    required this.userId,
  });

  final String userId;

  @override
  ConsumerState<AdminUserDriversTab> createState() =>
      _AdminUserDriversTabState();
}

enum _DriverFilter { all, active, inactive }

class _AdminUserDriversTabState extends ConsumerState<AdminUserDriversTab> {
  final _searchController = TextEditingController();
  var _query = '';
  var _filter = _DriverFilter.all;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = adminUserDetailsControllerProvider(widget.userId);
    final state = ref.watch(provider);
    final controller = ref.read(provider.notifier);
    final isInitialLoading = state.isLoadingDrivers &&
        state.linkedDrivers.isEmpty &&
        state.availableDrivers.isEmpty;

    if (isInitialLoading) {
      return const _SectionLoader(title: 'Drivers');
    }

    if (state.sectionErrorMessage != null &&
        state.linkedDrivers.isEmpty &&
        state.availableDrivers.isEmpty) {
      return _SectionErrorCard(
        message: state.sectionErrorMessage!,
        onRetry: controller.loadDrivers,
      );
    }

    final assigned = state.linkedDrivers.where(_matchesFilters).toList();
    final active = state.linkedDrivers.where((d) => d.isActive).length;
    final inactive = state.linkedDrivers.length - active;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StatsGrid(
          total: state.linkedDrivers.length,
          available: state.availableDrivers.length,
          active: active,
          inactive: inactive,
        ),
        const SizedBox(height: OpenVtsSpacing.sm),
        _SummaryCard(
          assignedCount: state.linkedDrivers.length,
          availableCount: state.availableDrivers.length,
          isLoading: state.isLoadingDrivers,
          isAssigning: state.isLinkingDriver,
          onAssign: state.availableDrivers.isEmpty || state.isLinkingDriver
              ? null
              : () => _showAssignSheet(state.availableDrivers, controller),
        ),
        const SizedBox(height: OpenVtsSpacing.sm),
        if (state.sectionErrorMessage != null) ...[
          _InlineError(message: state.sectionErrorMessage!),
          const SizedBox(height: OpenVtsSpacing.sm),
        ],
        _SearchField(
          controller: _searchController,
          onChanged: (value) => setState(() => _query = value),
        ),
        const SizedBox(height: OpenVtsSpacing.xs),
        _FilterChips(
          value: _filter,
          onChanged: (next) => setState(() => _filter = next),
        ),
        const SizedBox(height: OpenVtsSpacing.sm),
        if (assigned.isEmpty)
          _EmptyCard(
            label: _query.trim().isEmpty
                ? 'No assigned drivers'
                : 'No drivers match your search',
          )
        else
          for (final driver in assigned) ...[
            _DriverCard(
              driver: driver,
              isUnassigning: state.isUnlinkingDriver,
              onUnassign: state.isUnlinkingDriver
                  ? null
                  : () => _unassignDriver(controller, driver),
            ),
            if (driver != assigned.last)
              const SizedBox(height: OpenVtsSpacing.sm),
          ],
      ],
    );
  }

  bool _matchesFilters(AdminUserDriver driver) {
    if (!_matchesQuery(driver)) {
      return false;
    }
    switch (_filter) {
      case _DriverFilter.all:
        return true;
      case _DriverFilter.active:
        return driver.isActive;
      case _DriverFilter.inactive:
        return !driver.isActive;
    }
  }

  bool _matchesQuery(AdminUserDriver driver) {
    final normalized = _query.trim().toLowerCase();
    if (normalized.isEmpty) {
      return true;
    }
    return [
      driver.name,
      driver.username,
      driver.email,
      driver.mobile,
      _statusLabel(driver),
      driver.licenseNo,
    ].any((value) => value.toLowerCase().contains(normalized));
  }

  Future<void> _showAssignSheet(
    List<AdminUserDriver> availableDrivers,
    AdminUserDetailsController controller,
  ) {
    final provider = adminUserDetailsControllerProvider(widget.userId);
    return OpenVtsBottomSheet.show<void>(
      context: context,
      title: 'Assign Driver',
      initialChildSize: 0.72,
      minChildSize: 0.42,
      maxChildSize: 0.92,
      child: _AssignDriverSheet(
        drivers: availableDrivers,
        onAssign: (driver) async {
          final ok = await controller.linkDriver(driver.id);
          if (!mounted) {
            return false;
          }
          if (ok) {
            ToastHelper.showSuccess('Driver assigned.', context: context);
          } else {
            ToastHelper.showError(
              ref.read(provider).sectionErrorMessage ??
                  'Unable to assign driver.',
              context: context,
            );
          }
          return ok;
        },
      ),
    );
  }

  Future<void> _unassignDriver(
    AdminUserDetailsController controller,
    AdminUserDriver driver,
  ) async {
    final provider = adminUserDetailsControllerProvider(widget.userId);
    final ok = await controller.unlinkDriver(driver.id);
    if (!mounted) {
      return;
    }
    if (ok) {
      ToastHelper.showSuccess('Driver unassigned.', context: context);
    } else {
      ToastHelper.showError(
        ref.read(provider).sectionErrorMessage ?? 'Unable to unassign driver.',
        context: context,
      );
    }
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({
    required this.total,
    required this.available,
    required this.active,
    required this.inactive,
  });

  final int total;
  final int available;
  final int active;
  final int inactive;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SummaryTile(
            label: 'Drivers',
            value: total.toString(),
            icon: Icons.badge_outlined,
          ),
        ),
        const SizedBox(width: OpenVtsSpacing.xs),
        Expanded(
          child: _SummaryTile(
            label: 'Available',
            value: available.toString(),
            icon: Icons.person_add_alt_rounded,
          ),
        ),
        const SizedBox(width: OpenVtsSpacing.xs),
        Expanded(
          child: _SummaryTile(
            label: 'Active',
            value: active.toString(),
            icon: Icons.check_circle_outline_rounded,
          ),
        ),
        const SizedBox(width: OpenVtsSpacing.xs),
        Expanded(
          child: _SummaryTile(
            label: 'Inactive',
            value: inactive.toString(),
            icon: Icons.pause_circle_outline_rounded,
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

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.assignedCount,
    required this.availableCount,
    required this.isLoading,
    required this.isAssigning,
    required this.onAssign,
  });

  final int assignedCount;
  final int availableCount;
  final bool isLoading;
  final bool isAssigning;
  final VoidCallback? onAssign;

  @override
  Widget build(BuildContext context) {
    return OpenVtsCard(
      padding: const EdgeInsets.all(OpenVtsSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.badge_outlined,
                      size: 17,
                      color: OpenVtsColors.textSecondary,
                    ),
                    const SizedBox(width: OpenVtsSpacing.xs),
                    Text(
                      'Drivers',
                      style: OpenVtsTypography.label.copyWith(
                        color: OpenVtsColors.textPrimary,
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
                const SizedBox(height: OpenVtsSpacing.xs),
                Text(
                  '$assignedCount assigned - $availableCount available',
                  style: OpenVtsTypography.meta.copyWith(
                    color: OpenVtsColors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 34,
            child: OpenVtsButton(
              label: 'Assign Driver',
              height: 34,
              isLoading: isAssigning,
              onPressed: onAssign,
              trailingIcon: Icons.add_rounded,
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.onChanged,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

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
          const Icon(Icons.search,
              size: 16, color: OpenVtsColors.textSecondary),
          const SizedBox(width: OpenVtsSpacing.xs),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: const TextStyle(
                  fontSize: 13, color: OpenVtsColors.textPrimary),
              decoration: const InputDecoration(
                isDense: true,
                hintText: 'Search assigned drivers',
                hintStyle:
                    TextStyle(fontSize: 12, color: OpenVtsColors.textTertiary),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          if (controller.text.isNotEmpty)
            GestureDetector(
              onTap: () {
                controller.clear();
                onChanged('');
              },
              child: const Icon(Icons.close,
                  size: 16, color: OpenVtsColors.textSecondary),
            ),
        ],
      ),
    );
  }
}

class _FilterChips extends StatelessWidget {
  const _FilterChips({required this.value, required this.onChanged});

  final _DriverFilter value;
  final ValueChanged<_DriverFilter> onChanged;

  static const _options = <(_DriverFilter, String)>[
    (_DriverFilter.all, 'All'),
    (_DriverFilter.active, 'Active'),
    (_DriverFilter.inactive, 'Inactive'),
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

class _DriverCard extends StatelessWidget {
  const _DriverCard({
    required this.driver,
    required this.isUnassigning,
    required this.onUnassign,
  });

  final AdminUserDriver driver;
  final bool isUnassigning;
  final VoidCallback? onUnassign;

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
              _DriverAvatar(driver: driver),
              const SizedBox(width: OpenVtsSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _driverTitle(driver),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: OpenVtsColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _driverSubtitle(driver),
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
              _TinyTextButton(
                label: 'Unassign',
                icon: Icons.link_off_rounded,
                isLoading: isUnassigning,
                onPressed: onUnassign,
              ),
            ],
          ),
          const SizedBox(height: OpenVtsSpacing.sm),
          Wrap(
            spacing: OpenVtsSpacing.xs,
            runSpacing: OpenVtsSpacing.xs,
            children: [
              _MetaPill(
                  icon: Icons.person_outline_rounded,
                  label: _statusLabel(driver)),
              if (driver.mobile.trim().isNotEmpty)
                _MetaPill(
                    icon: Icons.call_outlined, label: driver.mobile.trim()),
              if (driver.email.trim().isNotEmpty)
                _MetaPill(
                    icon: Icons.mail_outline_rounded,
                    label: driver.email.trim()),
              if (driver.username.trim().isNotEmpty)
                _MetaPill(
                    icon: Icons.alternate_email_rounded,
                    label: driver.username.trim()),
              if (driver.licenseNo.trim().isNotEmpty)
                _MetaPill(
                    icon: Icons.badge_outlined,
                    label: 'License ${driver.licenseNo.trim()}'),
              if (driver.createdAt != null)
                _MetaPill(
                  icon: Icons.calendar_today_outlined,
                  label:
                      'Added ${const DateTimeFormatter().formatDate(driver.createdAt!.toLocal())}',
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AssignDriverSheet extends StatefulWidget {
  const _AssignDriverSheet({
    required this.drivers,
    required this.onAssign,
  });

  final List<AdminUserDriver> drivers;
  final Future<bool> Function(AdminUserDriver driver) onAssign;

  @override
  State<_AssignDriverSheet> createState() => _AssignDriverSheetState();
}

class _DriverAvatar extends StatelessWidget {
  const _DriverAvatar({required this.driver});

  final AdminUserDriver driver;

  @override
  Widget build(BuildContext context) {
    final initials = _initials(driver.name);
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: OpenVtsColors.background,
        borderRadius: BorderRadius.circular(OpenVtsRadius.pill),
        border: Border.all(color: OpenVtsColors.border),
      ),
      alignment: Alignment.center,
      child: initials.isNotEmpty
          ? Text(
              initials,
              style: OpenVtsTypography.label.copyWith(
                fontWeight: FontWeight.w700,
                color: OpenVtsColors.textPrimary,
              ),
            )
          : const Icon(
              Icons.person_outline_rounded,
              size: 20,
              color: OpenVtsColors.textSecondary,
            ),
    );
  }

  String _initials(String text) {
    final parts = text
        .trim()
        .split(RegExp(r'\\s+'))
        .where((e) => e.isNotEmpty)
        .toList(growable: false);
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
        .toUpperCase();
  }
}

class _AssignDriverSheetState extends State<_AssignDriverSheet> {
  final _searchController = TextEditingController();
  String? _selectedId;
  var _query = '';
  var _isSubmitting = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final matches = widget.drivers.where(_matchesQuery).toList();
    final selectedDriver = _selectedDriver;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(OpenVtsSpacing.md),
          child: TextField(
            controller: _searchController,
            onChanged: (value) => setState(() => _query = value),
            decoration: const InputDecoration(
              hintText: 'Search available drivers',
              prefixIcon: Icon(Icons.search_rounded, size: 18),
            ),
          ),
        ),
        Expanded(
          child: matches.isEmpty
              ? Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: OpenVtsSpacing.md),
                  child: _EmptyCard(
                    label: _query.trim().isEmpty
                        ? 'No available drivers'
                        : 'No drivers match your search',
                  ),
                )
              : ListView.separated(
                  controller: PrimaryScrollController.maybeOf(context),
                  padding: const EdgeInsets.fromLTRB(
                    OpenVtsSpacing.md,
                    0,
                    OpenVtsSpacing.md,
                    OpenVtsSpacing.md,
                  ),
                  itemCount: matches.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: OpenVtsSpacing.xs),
                  itemBuilder: (context, index) {
                    final driver = matches[index];
                    final isSelected = driver.id == _selectedId;
                    return _SelectableDriverTile(
                      driver: driver,
                      isSelected: isSelected,
                      onTap: () => setState(() => _selectedId = driver.id),
                    );
                  },
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
                    onPressed: _isSubmitting
                        ? null
                        : () => Navigator.of(context).pop(),
                  ),
                ),
                const SizedBox(width: OpenVtsSpacing.sm),
                Expanded(
                  child: OpenVtsButton(
                    label: 'Assign',
                    height: 40,
                    isLoading: _isSubmitting,
                    trailingIcon: Icons.check_rounded,
                    onPressed: selectedDriver == null || _isSubmitting
                        ? null
                        : () => _assign(selectedDriver),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  AdminUserDriver? get _selectedDriver {
    final selectedId = _selectedId;
    if (selectedId == null) {
      return null;
    }
    for (final driver in widget.drivers) {
      if (driver.id == selectedId) {
        return driver;
      }
    }
    return null;
  }

  bool _matchesQuery(AdminUserDriver driver) {
    final normalized = _query.trim().toLowerCase();
    if (normalized.isEmpty) {
      return true;
    }
    return [driver.name, driver.username, driver.email, driver.mobile]
        .any((value) => value.toLowerCase().contains(normalized));
  }

  Future<void> _assign(AdminUserDriver driver) async {
    setState(() => _isSubmitting = true);
    final ok = await widget.onAssign(driver);
    if (!mounted) {
      return;
    }
    setState(() => _isSubmitting = false);
    if (ok) {
      Navigator.of(context).pop();
    }
  }
}

class _SelectableDriverTile extends StatelessWidget {
  const _SelectableDriverTile({
    required this.driver,
    required this.isSelected,
    required this.onTap,
  });

  final AdminUserDriver driver;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: OpenVtsColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(OpenVtsRadius.sm),
        side: BorderSide(
          color: isSelected ? OpenVtsColors.brandInk : OpenVtsColors.border,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(OpenVtsRadius.sm),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(OpenVtsSpacing.sm),
          child: Row(
            children: [
              Icon(
                isSelected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_unchecked_rounded,
                size: 18,
                color: isSelected
                    ? OpenVtsColors.brandInk
                    : OpenVtsColors.textTertiary,
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
                      style: OpenVtsTypography.label.copyWith(
                        color: OpenVtsColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _driverSubtitle(driver),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: OpenVtsTypography.meta.copyWith(
                        color: OpenVtsColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TinyTextButton extends StatelessWidget {
  const _TinyTextButton({
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
    return TextButton.icon(
      onPressed: isLoading ? null : onPressed,
      style: TextButton.styleFrom(
        minimumSize: const Size(0, 30),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        foregroundColor: OpenVtsColors.textPrimary,
      ),
      icon: isLoading
          ? const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(icon, size: 14),
      label: Text(
        label,
        style: OpenVtsTypography.meta.copyWith(
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    const color = OpenVtsColors.textSecondary;
    return Container(
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
          Text(
            label,
            style: OpenVtsTypography.meta.copyWith(
              color: color,
              fontSize: 11,
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
        crossAxisAlignment: CrossAxisAlignment.start,
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

class _SectionLoader extends StatelessWidget {
  const _SectionLoader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return OpenVtsCard(
      padding: const EdgeInsets.all(OpenVtsSpacing.md),
      child: Row(
        children: [
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: OpenVtsSpacing.sm),
          Text(
            'Loading $title',
            style: OpenVtsTypography.label.copyWith(
              color: OpenVtsColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionErrorCard extends StatelessWidget {
  const _SectionErrorCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return OpenVtsCard(
      padding: const EdgeInsets.all(OpenVtsSpacing.md),
      child: OpenVtsErrorView(
        message: message,
        onRetry: onRetry,
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return OpenVtsCard(
      padding: const EdgeInsets.symmetric(vertical: OpenVtsSpacing.lg),
      child: Center(
        child: Text(
          label,
          style: OpenVtsTypography.meta.copyWith(
            color: OpenVtsColors.textSecondary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

String _driverTitle(AdminUserDriver driver) {
  final name = driver.name.trim();
  if (name.isNotEmpty) {
    return name;
  }
  return 'Driver';
}

String _driverSubtitle(AdminUserDriver driver) {
  final parts = <String>[];
  if (driver.username.trim().isNotEmpty) {
    parts.add('@${driver.username.trim()}');
  }
  if (driver.email.trim().isNotEmpty) {
    parts.add(driver.email.trim());
  }
  if (driver.mobile.trim().isNotEmpty) {
    parts.add(driver.mobile.trim());
  }
  if (parts.isEmpty) {
    return '—';
  }
  return parts.join(' · ');
}

String _statusLabel(AdminUserDriver driver) {
  return driver.isActive ? 'Active' : 'Inactive';
}
