import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/api/api_exception.dart';
import '../../../../../core/theme/open_vts_colors.dart';
import '../../../../../core/theme/open_vts_radius.dart';
import '../../../../../core/theme/open_vts_spacing.dart';
import '../../../../../core/theme/open_vts_typography.dart';
import '../../../../../core/utils/date_time_formatter.dart';
import '../../../../../shared/helpers/toast_helper.dart';
import '../../../../../shared/widgets/open_vts_bottom_sheet.dart';
import '../../../../../shared/widgets/open_vts_button.dart';
import '../../../../../shared/widgets/open_vts_loader.dart';
import '../../../../../shared/widgets/open_vts_search_field.dart';
import '../../../controllers/user_providers.dart';
import '../../../models/user_share_track_link_model.dart';

const DateTimeFormatter _dateFormatter = DateTimeFormatter();

class UserShareTrackLinkFormSheet extends ConsumerStatefulWidget {
  const UserShareTrackLinkFormSheet({
    required this.scrollController,
    this.link,
    super.key,
  });

  final ScrollController scrollController;
  final UserShareTrackLink? link;

  static Future<T?> show<T>({
    required BuildContext context,
    UserShareTrackLink? link,
  }) {
    return OpenVtsBottomSheet.show<T>(
      context: context,
      title: link == null ? 'New Track Link' : 'Edit Track Link',
      initialChildSize: 0.86,
      minChildSize: 0.48,
      maxChildSize: 0.96,
      draggableChildBuilder: (context, scrollController) {
        return UserShareTrackLinkFormSheet(
          scrollController: scrollController,
          link: link,
        );
      },
    );
  }

  @override
  ConsumerState<UserShareTrackLinkFormSheet> createState() =>
      _UserShareTrackLinkFormSheetState();
}

class _UserShareTrackLinkFormSheetState
    extends ConsumerState<UserShareTrackLinkFormSheet> {
  late Future<List<UserShareTrackVehicle>> _vehiclesFuture;
  late DateTime _expiryAt;
  late bool _isGeofence;
  late bool _isHistory;
  late bool _isActive;
  late Set<String> _selectedVehicleIds;

  UserShareTrackLink? _activeLink;
  String _vehicleQuery = '';
  bool _isLoadingDetails = false;
  String? _detailsError;

  bool get _isEditing => widget.link != null;

  @override
  void initState() {
    super.initState();
    _vehiclesFuture = _loadVehicles();
    _setCreateDefaults();

    final link = widget.link;
    if (link != null) {
      _setFromLink(link);
      unawaited(_loadLatestDetails(link.endpointId));
    }
  }

  Future<List<UserShareTrackVehicle>> _loadVehicles() {
    return ref.read(userShareTrackLinkControllerProvider.notifier).getVehicles();
  }

  Future<void> _loadLatestDetails(String id) async {
    setState(() {
      _isLoadingDetails = true;
      _detailsError = null;
    });

    try {
      final latest = await ref
          .read(userShareTrackLinkControllerProvider.notifier)
          .getLinkDetails(id);
      if (!mounted) return;
      setState(() {
        _setFromLink(latest);
        _isLoadingDetails = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoadingDetails = false;
        _detailsError = _errorMessage(error);
      });
    }
  }

  void _setCreateDefaults() {
    _activeLink = null;
    _expiryAt = DateTime.now().add(const Duration(hours: 24));
    _isGeofence = false;
    _isHistory = false;
    _isActive = true;
    _selectedVehicleIds = <String>{};
  }

  void _setFromLink(UserShareTrackLink link) {
    _activeLink = link;
    _expiryAt = link.expiryAt?.toLocal() ??
        DateTime.now().add(const Duration(hours: 24));
    _isGeofence = link.isGeofence;
    _isHistory = link.isHistory;
    _isActive = link.isActive;
    _selectedVehicleIds = {
      for (final vehicle in link.vehicles) vehicle.id,
    };
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(userShareTrackLinkControllerProvider);
    final isSaving = _isEditing
        ? state.isUpdating(widget.link!.endpointId)
        : state.isCreating;

    return Column(
      children: [
        if (_isLoadingDetails) const LinearProgressIndicator(minHeight: 2),
        Expanded(
          child: ListView(
            controller: widget.scrollController,
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(
              OpenVtsSpacing.md,
              OpenVtsSpacing.sm,
              OpenVtsSpacing.md,
              OpenVtsSpacing.lg,
            ),
            children: [
              _SectionLabel(
                title: _isEditing ? 'Edit Track Link' : 'New Track Link',
                subtitle: 'Choose vehicles, expiry, and sharing options.',
              ),
              if (_detailsError != null) ...[
                const SizedBox(height: OpenVtsSpacing.sm),
                _InlineNotice(
                  icon: Icons.info_outline_rounded,
                  message: _detailsError!,
                  color: OpenVtsColors.warning,
                ),
              ],
              const SizedBox(height: OpenVtsSpacing.md),
              _SectionLabel(
                title: 'Vehicle Selection',
                subtitle: '${_selectedVehicleIds.length} selected',
                compact: true,
              ),
              const SizedBox(height: OpenVtsSpacing.xs),
              FutureBuilder<List<UserShareTrackVehicle>>(
                future: _vehiclesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const _VehicleListFrame(
                      child: OpenVtsLoader(),
                    );
                  }

                  if (snapshot.hasError) {
                    return _InlineRetry(
                      message: 'Unable to load vehicles.',
                      onRetry: () {
                        setState(() {
                          _vehiclesFuture = _loadVehicles();
                        });
                      },
                    );
                  }

                  final vehicles = _mergeVehicles(
                    snapshot.data ?? const <UserShareTrackVehicle>[],
                  );

                  if (vehicles.isEmpty) {
                    return const _VehicleListFrame(
                      child: _MutedPanel(
                        icon: Icons.directions_car_outlined,
                        title: 'No vehicles available',
                        message: 'Only assigned user vehicles can be shared.',
                      ),
                    );
                  }

                  final filteredVehicles = _filteredVehicles(vehicles);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      OpenVtsSearchField(
                        hintText: 'Search vehicles...',
                        onChanged: (value) {
                          setState(() {
                            _vehicleQuery = value.trim().toLowerCase();
                          });
                        },
                      ),
                      const SizedBox(height: OpenVtsSpacing.xs),
                      _VehicleListFrame(
                        child: filteredVehicles.isEmpty
                            ? const _MutedPanel(
                                icon: Icons.search_off_rounded,
                                title: 'No vehicles found',
                                message: 'Try a different name or plate.',
                              )
                            : ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                padding: const EdgeInsets.symmetric(
                                  vertical: OpenVtsSpacing.xs,
                                ),
                                itemCount: filteredVehicles.length,
                                separatorBuilder: (context, index) =>
                                    const Divider(
                                  height: 1,
                                  color: OpenVtsColors.divider,
                                ),
                                itemBuilder: (context, index) {
                                  final vehicle = filteredVehicles[index];
                                  final selected =
                                      _selectedVehicleIds.contains(vehicle.id);
                                  final disabled =
                                      vehicle.isLicenseBlocked && !selected;
                                  return _VehicleSelectRow(
                                    vehicle: vehicle,
                                    selected: selected,
                                    disabled: disabled,
                                    onChanged: disabled
                                        ? null
                                        : () => setState(
                                              () => _toggleVehicle(vehicle.id),
                                            ),
                                  );
                                },
                              ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: OpenVtsSpacing.md),
              const _SectionLabel(
                title: 'Expiry Date/Time',
                subtitle: 'The link expires automatically.',
                compact: true,
              ),
              const SizedBox(height: OpenVtsSpacing.xs),
              Row(
                children: [
                  Expanded(
                    child: _PickerTile(
                      label: 'Date',
                      value: _dateFormatter.formatDate(_expiryAt),
                      icon: Icons.calendar_today_outlined,
                      onTap: _pickDate,
                    ),
                  ),
                  const SizedBox(width: OpenVtsSpacing.sm),
                  Expanded(
                    child: _PickerTile(
                      label: 'Time',
                      value: _dateFormatter.formatTime(_expiryAt),
                      icon: Icons.schedule_rounded,
                      onTap: _pickTime,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: OpenVtsSpacing.md),
              const _SectionLabel(
                title: 'Options',
                subtitle: 'Control what viewers can see.',
                compact: true,
              ),
              const SizedBox(height: OpenVtsSpacing.xs),
              _ToggleRow(
                title: 'Show Geofence',
                subtitle: 'Display assigned geofence context.',
                value: _isGeofence,
                onChanged: isSaving
                    ? null
                    : (value) => setState(() => _isGeofence = value),
              ),
              const SizedBox(height: OpenVtsSpacing.xs),
              _ToggleRow(
                title: 'Allow History',
                subtitle: 'Allow route history access.',
                value: _isHistory,
                onChanged: isSaving
                    ? null
                    : (value) => setState(() => _isHistory = value),
              ),
              if (_isEditing) ...[
                const SizedBox(height: OpenVtsSpacing.md),
                const _SectionLabel(
                  title: 'Status',
                  subtitle: 'Disable without deleting the link.',
                  compact: true,
                ),
                const SizedBox(height: OpenVtsSpacing.xs),
                _ToggleRow(
                  title: 'Active',
                  subtitle: 'Enable this public link.',
                  value: _isActive,
                  onChanged: isSaving
                      ? null
                      : (value) => setState(() => _isActive = value),
                ),
              ],
            ],
          ),
        ),
        _ActionBar(
          isSaving: isSaving,
          isEditing: _isEditing,
          onCancel: isSaving ? null : () => Navigator.of(context).pop(),
          onSave: isSaving ? null : _submit,
        ),
      ],
    );
  }

  List<UserShareTrackVehicle> _mergeVehicles(
    List<UserShareTrackVehicle> vehicles,
  ) {
    final byId = <String, UserShareTrackVehicle>{
      for (final vehicle in vehicles) vehicle.id: vehicle,
    };

    for (final vehicle
        in _activeLink?.vehicles ?? const <UserShareTrackVehicle>[]) {
      byId.putIfAbsent(vehicle.id, () => vehicle);
    }

    final merged = byId.values.toList(growable: false);
    return merged
      ..sort((a, b) {
        final aSelected = _selectedVehicleIds.contains(a.id);
        final bSelected = _selectedVehicleIds.contains(b.id);
        if (aSelected != bSelected) return aSelected ? -1 : 1;
        return a.displayName.toLowerCase().compareTo(
              b.displayName.toLowerCase(),
            );
      });
  }

  List<UserShareTrackVehicle> _filteredVehicles(
    List<UserShareTrackVehicle> vehicles,
  ) {
    if (_vehicleQuery.isEmpty) return vehicles;
    return vehicles.where((vehicle) {
      final plate = vehicle.plateNumber?.toLowerCase() ?? '';
      return vehicle.name.toLowerCase().contains(_vehicleQuery) ||
          plate.contains(_vehicleQuery);
    }).toList(growable: false);
  }

  void _toggleVehicle(String id) {
    if (_selectedVehicleIds.contains(id)) {
      _selectedVehicleIds.remove(id);
      return;
    }
    _selectedVehicleIds.add(id);
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiryAt.isBefore(now) ? now : _expiryAt,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 5),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _expiryAt = DateTime(
        picked.year,
        picked.month,
        picked.day,
        _expiryAt.hour,
        _expiryAt.minute,
      );
    });
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_expiryAt),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _expiryAt = DateTime(
        _expiryAt.year,
        _expiryAt.month,
        _expiryAt.day,
        picked.hour,
        picked.minute,
      );
    });
  }

  Future<void> _submit() async {
    if (_selectedVehicleIds.isEmpty) {
      ToastHelper.showError('Select at least one vehicle.', context: context);
      return;
    }

    if (!_expiryAt.isAfter(DateTime.now())) {
      ToastHelper.showError('Expiry must be in the future.', context: context);
      return;
    }

    final vehicleIds = _selectedVehicleIdsAsInts();
    if (vehicleIds == null || vehicleIds.isEmpty) {
      ToastHelper.showError(
        'One or more selected vehicles are invalid.',
        context: context,
      );
      return;
    }

    final controller = ref.read(userShareTrackLinkControllerProvider.notifier);

    try {
      final message = _isEditing
          ? await controller.updateLink(
              widget.link!.endpointId,
              UserUpdateShareTrackLinkRequest(
                vehicleIds: vehicleIds,
                expiryAt: _expiryAt,
                isGeofence: _isGeofence,
                isHistory: _isHistory,
                isActive: _isActive,
              ),
            )
          : await controller.createLink(
              UserCreateShareTrackLinkRequest(
                vehicleIds: vehicleIds,
                expiryAt: _expiryAt,
                isGeofence: _isGeofence,
                isHistory: _isHistory,
              ),
            );

      if (!mounted) return;
      ToastHelper.showSuccess(
        _successMessage(
          message,
          fallback: _isEditing ? 'Track link updated.' : 'Track link created.',
        ),
        context: context,
      );
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      ToastHelper.showError(_errorMessage(error), context: context);
    }
  }

  List<int>? _selectedVehicleIdsAsInts() {
    final ids = <int>{};
    for (final rawId in _selectedVehicleIds) {
      final parsed = int.tryParse(rawId.trim());
      if (parsed == null || parsed <= 0) return null;
      ids.add(parsed);
    }
    return ids.toList(growable: false);
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({
    required this.title,
    required this.subtitle,
    this.compact = false,
  });

  final String title;
  final String subtitle;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: OpenVtsTypography.titleSmall.copyWith(
                  fontSize: compact ? 14 : 16,
                  color: OpenVtsColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: OpenVtsTypography.meta.copyWith(
                  color: OpenVtsColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _VehicleListFrame extends StatelessWidget {
  const _VehicleListFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 112),
      decoration: BoxDecoration(
        color: OpenVtsColors.surfaceElevated,
        borderRadius: BorderRadius.circular(OpenVtsRadius.lg),
        border: Border.all(color: OpenVtsColors.border),
      ),
      child: child,
    );
  }
}

class _VehicleSelectRow extends StatelessWidget {
  const _VehicleSelectRow({
    required this.vehicle,
    required this.selected,
    required this.disabled,
    required this.onChanged,
  });

  final UserShareTrackVehicle vehicle;
  final bool selected;
  final bool disabled;
  final VoidCallback? onChanged;

  @override
  Widget build(BuildContext context) {
    final titleColor =
        disabled ? OpenVtsColors.textTertiary : OpenVtsColors.textPrimary;

    return InkWell(
      onTap: onChanged,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: OpenVtsSpacing.xs,
          vertical: 7,
        ),
        child: Row(
          children: [
            Checkbox(
              value: selected,
              onChanged: onChanged == null ? null : (_) => onChanged!(),
              activeColor: OpenVtsColors.brandInk,
              visualDensity: VisualDensity.compact,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          vehicle.name.trim().isEmpty
                              ? 'Vehicle'
                              : vehicle.name.trim(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: OpenVtsTypography.label.copyWith(
                            color: titleColor,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      if (vehicle.isLicenseBlocked) ...[
                        const SizedBox(width: OpenVtsSpacing.xs),
                        const _LicenseBlockedChip(),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _vehicleSubtitle(vehicle),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: OpenVtsTypography.meta.copyWith(
                      color: OpenVtsColors.textTertiary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LicenseBlockedChip extends StatelessWidget {
  const _LicenseBlockedChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: OpenVtsColors.error.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(OpenVtsRadius.pill),
        border: Border.all(color: OpenVtsColors.error.withValues(alpha: 0.16)),
      ),
      child: Text(
        'License blocked',
        style: OpenVtsTypography.meta.copyWith(
          color: OpenVtsColors.error,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _PickerTile extends StatelessWidget {
  const _PickerTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(OpenVtsRadius.lg),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(OpenVtsSpacing.sm),
        decoration: BoxDecoration(
          color: OpenVtsColors.surfaceElevated,
          borderRadius: BorderRadius.circular(OpenVtsRadius.lg),
          border: Border.all(color: OpenVtsColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 15, color: OpenVtsColors.textSecondary),
                const SizedBox(width: 5),
                Expanded(
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
            const SizedBox(height: 5),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: OpenVtsTypography.label.copyWith(
                color: OpenVtsColors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: OpenVtsSpacing.sm,
        vertical: OpenVtsSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: OpenVtsColors.surfaceElevated,
        borderRadius: BorderRadius.circular(OpenVtsRadius.lg),
        border: Border.all(color: OpenVtsColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: OpenVtsTypography.label.copyWith(
                    color: OpenVtsColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: OpenVtsTypography.meta.copyWith(
                    color: OpenVtsColors.textTertiary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: OpenVtsColors.brandInk,
          ),
        ],
      ),
    );
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.isSaving,
    required this.isEditing,
    required this.onCancel,
    required this.onSave,
  });

  final bool isSaving;
  final bool isEditing;
  final VoidCallback? onCancel;
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          OpenVtsSpacing.md,
          OpenVtsSpacing.sm,
          OpenVtsSpacing.md,
          OpenVtsSpacing.md,
        ),
        decoration: const BoxDecoration(
          color: OpenVtsColors.surfaceElevated,
          border: Border(top: BorderSide(color: OpenVtsColors.divider)),
        ),
        child: Row(
          children: [
            Expanded(
              child: OpenVtsButton(
                label: 'Cancel',
                onPressed: onCancel,
                variant: OpenVtsButtonVariant.secondary,
                height: 42,
              ),
            ),
            const SizedBox(width: OpenVtsSpacing.sm),
            Expanded(
              child: OpenVtsButton(
                label: isSaving
                    ? 'Saving...'
                    : isEditing
                        ? 'Save'
                        : 'Create',
                onPressed: onSave,
                isLoading: isSaving,
                height: 42,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MutedPanel extends StatelessWidget {
  const _MutedPanel({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(OpenVtsSpacing.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 22, color: OpenVtsColors.textTertiary),
          const SizedBox(height: OpenVtsSpacing.xs),
          Text(
            title,
            textAlign: TextAlign.center,
            style: OpenVtsTypography.label.copyWith(
              color: OpenVtsColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            message,
            textAlign: TextAlign.center,
            style: OpenVtsTypography.meta.copyWith(
              color: OpenVtsColors.textSecondary,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineRetry extends StatelessWidget {
  const _InlineRetry({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return _InlineNotice(
      icon: Icons.error_outline_rounded,
      message: message,
      color: OpenVtsColors.error,
      trailing: TextButton(
        onPressed: onRetry,
        child: const Text('Retry'),
      ),
    );
  }
}

class _InlineNotice extends StatelessWidget {
  const _InlineNotice({
    required this.icon,
    required this.message,
    required this.color,
    this.trailing,
  });

  final IconData icon;
  final String message;
  final Color color;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(OpenVtsSpacing.sm),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(OpenVtsRadius.lg),
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: OpenVtsSpacing.xs),
          Expanded(
            child: Text(
              message,
              style: OpenVtsTypography.meta.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

String _vehicleSubtitle(UserShareTrackVehicle vehicle) {
  final plate = vehicle.plateNumber?.trim();
  if (plate != null && plate.isNotEmpty) return plate;
  return 'Vehicle ID ${vehicle.id}';
}

String _successMessage(String? message, {required String fallback}) {
  final normalized = message?.trim();
  if (normalized == null || normalized.isEmpty) return fallback;
  return normalized;
}

String _errorMessage(Object error) {
  if (error is ApiException) {
    return error.message;
  }

  if (error is DioException) {
    final responseMessage = _extractResponseMessage(error.response?.data);
    if (responseMessage != null) return responseMessage;
    final message = error.message?.trim();
    if (message != null && message.isNotEmpty) return message;
  }

  final raw = error.toString().trim();
  if (raw.startsWith('Exception: ')) {
    return raw.substring('Exception: '.length).trim();
  }
  if (raw.startsWith('ApiException')) {
    final parts = raw.split(':');
    if (parts.length > 1) return parts.sublist(1).join(':').trim();
  }
  return raw.isEmpty ? 'Something went wrong.' : raw;
}

String? _extractResponseMessage(dynamic data) {
  if (data is Map<String, dynamic>) {
    for (final key in const ['message', 'error']) {
      final value = data[key];
      if (value is String && value.trim().isNotEmpty) return value.trim();
      if (value is List) {
        final parts = value
            .whereType<String>()
            .map((item) => item.trim())
            .where((item) => item.isNotEmpty)
            .toList(growable: false);
        if (parts.isNotEmpty) return parts.join(', ');
      }
    }
    final nestedData = data['data'];
    if (!identical(nestedData, data)) {
      return _extractResponseMessage(nestedData);
    }
  }
  if (data is String && data.trim().isNotEmpty) return data.trim();
  return null;
}
