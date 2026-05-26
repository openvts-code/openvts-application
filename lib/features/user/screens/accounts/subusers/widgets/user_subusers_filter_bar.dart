import 'package:flutter/material.dart';

import '../../../../../../core/theme/open_vts_colors.dart';
import '../../../../../../core/theme/open_vts_radius.dart';
import '../../../../../../core/theme/open_vts_spacing.dart';
import '../../../../../../core/theme/open_vts_typography.dart';
import '../../../../../../shared/widgets/open_vts_card.dart';

enum UserSubUsersStatusFilter { all, active, inactive }

class UserSubUsersFilterBar extends StatefulWidget {
  const UserSubUsersFilterBar({
    required this.searchQuery,
    required this.visibleCount,
    required this.loadedCount,
    required this.totalCount,
    required this.selectedStatusFilter,
    required this.onSearchChanged,
    required this.onStatusChanged,
    required this.onClearFilters,
    super.key,
  });

  final String searchQuery;
  final int visibleCount;
  final int loadedCount;
  final int totalCount;
  final UserSubUsersStatusFilter selectedStatusFilter;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<UserSubUsersStatusFilter> onStatusChanged;
  final VoidCallback onClearFilters;

  @override
  State<UserSubUsersFilterBar> createState() => _UserSubUsersFilterBarState();
}

class _UserSubUsersFilterBarState extends State<UserSubUsersFilterBar> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.searchQuery);
  }

  @override
  void didUpdateWidget(covariant UserSubUsersFilterBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.searchQuery == widget.searchQuery) {
      return;
    }

    final currentText = _searchController.text;
    if (currentText == widget.searchQuery) {
      return;
    }

    _searchController
      ..text = widget.searchQuery
      ..selection = TextSelection.collapsed(offset: widget.searchQuery.length);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasSearch = widget.searchQuery.trim().isNotEmpty;
    final hasStatus =
        widget.selectedStatusFilter != UserSubUsersStatusFilter.all;
    final hasFilters = hasSearch || hasStatus;

    return OpenVtsCard(
      padding: const EdgeInsets.all(OpenVtsSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${widget.visibleCount} visible • ${widget.loadedCount}/${widget.totalCount} loaded',
                  style: OpenVtsTypography.label.copyWith(
                    color: OpenVtsColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (hasFilters)
                TextButton.icon(
                  onPressed: widget.onClearFilters,
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
          TextField(
            controller: _searchController,
            onChanged: (value) {
              setState(() {});
              widget.onSearchChanged(value);
            },
            decoration: InputDecoration(
              hintText: 'Search name, username, email, mobile...',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _searchController.text.trim().isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Clear search',
                      onPressed: () {
                        _searchController.clear();
                        setState(() {});
                        widget.onSearchChanged('');
                      },
                      icon: const Icon(Icons.close_rounded, size: 18),
                    ),
            ),
          ),
          const SizedBox(height: OpenVtsSpacing.sm),
          Wrap(
            spacing: OpenVtsSpacing.xs,
            runSpacing: OpenVtsSpacing.xs,
            children: [
              _StatusChip(
                label: 'All',
                selected:
                    widget.selectedStatusFilter == UserSubUsersStatusFilter.all,
                onTap: () =>
                    widget.onStatusChanged(UserSubUsersStatusFilter.all),
              ),
              _StatusChip(
                label: 'Active',
                selected: widget.selectedStatusFilter ==
                    UserSubUsersStatusFilter.active,
                onTap: () =>
                    widget.onStatusChanged(UserSubUsersStatusFilter.active),
              ),
              _StatusChip(
                label: 'Inactive',
                selected: widget.selectedStatusFilter ==
                    UserSubUsersStatusFilter.inactive,
                onTap: () =>
                    widget.onStatusChanged(UserSubUsersStatusFilter.inactive),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
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
      borderRadius: BorderRadius.circular(OpenVtsRadius.pill),
      onTap: onTap,
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: selected
              ? OpenVtsColors.brandInk.withValues(alpha: 0.9)
              : OpenVtsColors.surface,
          borderRadius: BorderRadius.circular(OpenVtsRadius.pill),
          border: Border.all(
            color: selected ? OpenVtsColors.brandInk : OpenVtsColors.border,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: OpenVtsTypography.meta.copyWith(
              color:
                  selected ? OpenVtsColors.white : OpenVtsColors.textSecondary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}
