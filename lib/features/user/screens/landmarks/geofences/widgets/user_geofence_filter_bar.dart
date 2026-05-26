import 'package:flutter/material.dart';

import '../../../../../../core/theme/open_vts_colors.dart';
import '../../../../../../core/theme/open_vts_radius.dart';
import '../../../../../../core/theme/open_vts_spacing.dart';
import '../../../../../../core/theme/open_vts_typography.dart';
import '../../../../models/user_landmark_model.dart';

/// Compact filter row for the geofence list. Owns no business state — emits
/// callbacks to the parent (which forwards to the controller).
class UserGeofenceFilterBar extends StatelessWidget {
  const UserGeofenceFilterBar({
    super.key,
    required this.searchQuery,
    required this.statusFilter,
    required this.typeFilter,
    required this.onSearchChanged,
    required this.onStatusChanged,
    required this.onTypeChanged,
  });

  final String searchQuery;
  final UserLandmarkStatusFilter statusFilter;
  final UserGeofenceType? typeFilter;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<UserLandmarkStatusFilter> onStatusChanged;
  final ValueChanged<UserGeofenceType?> onTypeChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SearchField(value: searchQuery, onChanged: onSearchChanged),
        const SizedBox(height: OpenVtsSpacing.xs),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              _FilterGroup(
                children: [
                  for (final filter in UserLandmarkStatusFilter.values)
                    _FilterChip(
                      label: _statusLabel(filter),
                      selected: statusFilter == filter,
                      onTap: () => onStatusChanged(filter),
                    ),
                ],
              ),
              const SizedBox(width: OpenVtsSpacing.sm),
              _FilterGroup(
                children: [
                  _FilterChip(
                    label: 'All types',
                    selected: typeFilter == null,
                    onTap: () => onTypeChanged(null),
                  ),
                  for (final type in UserGeofenceType.values)
                    _FilterChip(
                      label: type.label,
                      selected: typeFilter == type,
                      onTap: () => onTypeChanged(type),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _statusLabel(UserLandmarkStatusFilter filter) {
    switch (filter) {
      case UserLandmarkStatusFilter.all:
        return 'All';
      case UserLandmarkStatusFilter.active:
        return 'Active';
      case UserLandmarkStatusFilter.inactive:
        return 'Inactive';
    }
  }
}

class _SearchField extends StatefulWidget {
  const _SearchField({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  State<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<_SearchField> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.value);

  @override
  void didUpdateWidget(covariant _SearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != _controller.text) {
      _controller.text = widget.value;
      _controller.selection = TextSelection.collapsed(
        offset: _controller.text.length,
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: TextField(
        controller: _controller,
        onChanged: widget.onChanged,
        style: OpenVtsTypography.body,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          isDense: true,
          hintText: 'Search by name',
          hintStyle: OpenVtsTypography.body.copyWith(
            color: OpenVtsColors.textTertiary,
          ),
          prefixIcon: const Icon(
            Icons.search,
            size: 18,
            color: OpenVtsColors.textSecondary,
          ),
          suffixIcon: widget.value.isEmpty
              ? null
              : IconButton(
                  iconSize: 16,
                  splashRadius: 18,
                  onPressed: () {
                    _controller.clear();
                    widget.onChanged('');
                  },
                  icon: const Icon(
                    Icons.close,
                    color: OpenVtsColors.textSecondary,
                  ),
                ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: OpenVtsSpacing.sm,
            vertical: 0,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(OpenVtsRadius.button),
            borderSide: const BorderSide(color: OpenVtsColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(OpenVtsRadius.button),
            borderSide: const BorderSide(color: OpenVtsColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(OpenVtsRadius.button),
            borderSide: const BorderSide(
              color: OpenVtsColors.brandInk,
              width: 1.4,
            ),
          ),
        ),
      ),
    );
  }
}

class _FilterGroup extends StatelessWidget {
  const _FilterGroup({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: OpenVtsColors.surface,
        borderRadius: BorderRadius.circular(OpenVtsRadius.pill),
        border: Border.all(color: OpenVtsColors.border),
      ),
      padding: const EdgeInsets.all(2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(width: 2),
            children[i],
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(
          horizontal: OpenVtsSpacing.sm,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: selected ? OpenVtsColors.brandInk : Colors.transparent,
          borderRadius: BorderRadius.circular(OpenVtsRadius.pill),
        ),
        child: Text(
          label,
          style: OpenVtsTypography.meta.copyWith(
            color: selected ? OpenVtsColors.white : OpenVtsColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
