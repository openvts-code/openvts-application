import 'package:flutter/material.dart';

import '../../../../../../core/theme/open_vts_colors.dart';
import '../../../../../../core/theme/open_vts_radius.dart';
import '../../../../../../core/theme/open_vts_spacing.dart';
import '../../../../../../core/theme/open_vts_typography.dart';
import '../../../../../../shared/widgets/open_vts_card.dart';
import '../../../../../../shared/widgets/open_vts_search_field.dart';
import '../../../../models/user_drivers_state.dart';

class UserDriversFilterBar extends StatelessWidget {
  const UserDriversFilterBar({
    required this.state,
    required this.onSearchChanged,
    required this.onStatusChanged,
    required this.onAssignmentChanged,
    required this.onVerificationChanged,
    required this.onClearFilters,
    super.key,
  });

  final UserDriversState state;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<UserDriverStatusFilter> onStatusChanged;
  final ValueChanged<UserDriverAssignmentFilter> onAssignmentChanged;
  final ValueChanged<UserDriverVerificationFilter> onVerificationChanged;
  final VoidCallback onClearFilters;

  @override
  Widget build(BuildContext context) {
    return OpenVtsCard(
      padding: const EdgeInsets.all(OpenVtsSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${state.filteredDrivers.length} of ${state.drivers.length} drivers',
                  style: OpenVtsTypography.label.copyWith(
                    color: OpenVtsColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (state.hasActiveFilters)
                TextButton.icon(
                  onPressed: onClearFilters,
                  icon: const Icon(Icons.filter_alt_off_outlined, size: 15),
                  label: Text(
                    'Clear',
                    style: OpenVtsTypography.meta.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: OpenVtsSpacing.xs),
          OpenVtsSearchField(
            hintText: 'Search name, username, email, mobile, vehicle, plate...',
            onChanged: onSearchChanged,
          ),
          const SizedBox(height: OpenVtsSpacing.sm),
          Wrap(
            spacing: OpenVtsSpacing.xs,
            runSpacing: OpenVtsSpacing.xs,
            children: [
              _FilterMenuButton<UserDriverStatusFilter>(
                icon: Icons.toggle_on_outlined,
                title: 'Status',
                selectedLabel: _statusLabel(state.selectedStatusFilter),
                highlighted:
                    state.selectedStatusFilter != UserDriverStatusFilter.all,
                items: const [
                  UserDriverStatusFilter.all,
                  UserDriverStatusFilter.active,
                  UserDriverStatusFilter.inactive,
                ],
                labelFor: _statusLabel,
                onSelected: onStatusChanged,
              ),
              _FilterMenuButton<UserDriverAssignmentFilter>(
                icon: Icons.link_outlined,
                title: 'Assignment',
                selectedLabel: _assignmentLabel(state.selectedAssignmentFilter),
                highlighted: state.selectedAssignmentFilter !=
                    UserDriverAssignmentFilter.all,
                items: const [
                  UserDriverAssignmentFilter.all,
                  UserDriverAssignmentFilter.assigned,
                  UserDriverAssignmentFilter.unassigned,
                ],
                labelFor: _assignmentLabel,
                onSelected: onAssignmentChanged,
              ),
              _FilterMenuButton<UserDriverVerificationFilter>(
                icon: Icons.verified_outlined,
                title: 'Verified',
                selectedLabel:
                    _verificationLabel(state.selectedVerificationFilter),
                highlighted: state.selectedVerificationFilter !=
                    UserDriverVerificationFilter.all,
                items: const [
                  UserDriverVerificationFilter.all,
                  UserDriverVerificationFilter.verified,
                  UserDriverVerificationFilter.unverified,
                ],
                labelFor: _verificationLabel,
                onSelected: onVerificationChanged,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FilterMenuButton<T> extends StatelessWidget {
  const _FilterMenuButton({
    required this.icon,
    required this.title,
    required this.selectedLabel,
    required this.highlighted,
    required this.items,
    required this.labelFor,
    required this.onSelected,
  });

  final IconData icon;
  final String title;
  final String selectedLabel;
  final bool highlighted;
  final List<T> items;
  final String Function(T value) labelFor;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    final backgroundColor =
        highlighted ? OpenVtsColors.brandInk : OpenVtsColors.white;
    final foregroundColor =
        highlighted ? OpenVtsColors.white : OpenVtsColors.textPrimary;

    return PopupMenuButton<T>(
      tooltip: title,
      onSelected: onSelected,
      itemBuilder: (context) {
        return [
          for (final item in items)
            PopupMenuItem<T>(
              value: item,
              child: Text(labelFor(item)),
            ),
        ];
      },
      child: Container(
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(OpenVtsRadius.pill),
          border: Border.all(color: OpenVtsColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: foregroundColor),
            const SizedBox(width: 6),
            Text(
              '$title: $selectedLabel',
              style: OpenVtsTypography.meta.copyWith(
                color: foregroundColor,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.expand_more_rounded, size: 16, color: foregroundColor),
          ],
        ),
      ),
    );
  }
}

String _statusLabel(UserDriverStatusFilter filter) {
  return switch (filter) {
    UserDriverStatusFilter.all => 'All',
    UserDriverStatusFilter.active => 'Active',
    UserDriverStatusFilter.inactive => 'Inactive',
  };
}

String _assignmentLabel(UserDriverAssignmentFilter filter) {
  return switch (filter) {
    UserDriverAssignmentFilter.all => 'All',
    UserDriverAssignmentFilter.assigned => 'Assigned',
    UserDriverAssignmentFilter.unassigned => 'Unassigned',
  };
}

String _verificationLabel(UserDriverVerificationFilter filter) {
  return switch (filter) {
    UserDriverVerificationFilter.all => 'All',
    UserDriverVerificationFilter.verified => 'Verified',
    UserDriverVerificationFilter.unverified => 'Unverified',
  };
}
