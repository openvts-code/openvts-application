import 'package:flutter/material.dart';

import '../../../../../core/theme/open_vts_colors.dart';
import '../../../../../core/theme/open_vts_radius.dart';
import '../../../../../core/theme/open_vts_spacing.dart';
import '../../../../../core/theme/open_vts_typography.dart';
import '../../../../../shared/widgets/open_vts_card.dart';
import '../../../../../shared/widgets/open_vts_date_time_range_selector.dart';
import '../../../../../shared/widgets/open_vts_search_field.dart';
import '../../../models/superadmin_payments_model.dart';
import '../../../models/superadmin_payments_state.dart';

class SuperadminPaymentsFiltersCard extends StatelessWidget {
  const SuperadminPaymentsFiltersCard({
    required this.state,
    required this.onAdminChanged,
    required this.onRangePresetChanged,
    required this.onCustomRangeChanged,
    required this.onSearchChanged,
    required this.onStatusChanged,
    required this.onClearFilters,
    super.key,
  });

  final SuperadminPaymentsState state;
  final ValueChanged<String?> onAdminChanged;
  final ValueChanged<SuperadminPaymentsRangePreset> onRangePresetChanged;
  final void Function(DateTime? from, DateTime? to) onCustomRangeChanged;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<SuperadminTransactionStatus?> onStatusChanged;
  final VoidCallback onClearFilters;

  @override
  Widget build(BuildContext context) {
    return OpenVtsCard(
      padding: const EdgeInsets.all(OpenVtsSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Filters',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: OpenVtsColors.textPrimary,
                  ),
                ),
              ),
              if (state.hasActiveFilters)
                TextButton(
                  onPressed: onClearFilters,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: OpenVtsSpacing.sm,
                      vertical: OpenVtsSpacing.xs,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Clear',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
            ],
          ),
          const SizedBox(height: OpenVtsSpacing.sm),
          OpenVtsSearchField(
            hintText: 'Search by reference or admin...',
            onChanged: onSearchChanged,
          ),
          const SizedBox(height: OpenVtsSpacing.sm),
          _CollapsibleFiltersSection(
            state: state,
            onAdminChanged: onAdminChanged,
            onRangePresetChanged: onRangePresetChanged,
            onCustomRangeChanged: onCustomRangeChanged,
            onStatusChanged: onStatusChanged,
          ),
        ],
      ),
    );
  }
}

class _CollapsibleFiltersSection extends StatefulWidget {
  const _CollapsibleFiltersSection({
    required this.state,
    required this.onAdminChanged,
    required this.onRangePresetChanged,
    required this.onCustomRangeChanged,
    required this.onStatusChanged,
  });

  final SuperadminPaymentsState state;
  final ValueChanged<String?> onAdminChanged;
  final ValueChanged<SuperadminPaymentsRangePreset> onRangePresetChanged;
  final void Function(DateTime? from, DateTime? to) onCustomRangeChanged;
  final ValueChanged<SuperadminTransactionStatus?> onStatusChanged;

  @override
  State<_CollapsibleFiltersSection> createState() =>
      _CollapsibleFiltersSectionState();
}

class _CollapsibleFiltersSectionState
    extends State<_CollapsibleFiltersSection> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final admins = _resolveAdminOptions();
    final selectedAdmin = widget.state.selectedAdminId;
    final selectedAdminValue =
        admins.any((item) => item.uid == selectedAdmin) ? selectedAdmin : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          borderRadius: BorderRadius.circular(OpenVtsRadius.md),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: OpenVtsSpacing.xs),
            child: Row(
              children: [
                Text(
                  'Advanced Filters',
                  style: OpenVtsTypography.label.copyWith(
                    color: OpenVtsColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: OpenVtsSpacing.xs),
                Icon(
                  _isExpanded
                      ? Icons.expand_less_rounded
                      : Icons.expand_more_rounded,
                  size: 18,
                  color: OpenVtsColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
        if (_isExpanded) ...[
          const SizedBox(height: OpenVtsSpacing.sm),
          DropdownButtonFormField<int?>(
            initialValue: selectedAdminValue,
            isExpanded: true,
            decoration: InputDecoration(
              isDense: true,
              labelText: 'Administrator',
              suffixIcon: widget.state.isLoadingAdmins
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : null,
            ),
            items: [
              const DropdownMenuItem<int?>(
                value: null,
                child: Text('All Admins'),
              ),
              ...admins.map(
                (admin) => DropdownMenuItem<int?>(
                  value: admin.uid,
                  child: _AdminDropdownLabel(admin: admin),
                ),
              ),
            ],
            selectedItemBuilder: (context) => [
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'All Admins',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              ...admins.map(
                (admin) => Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _compactAdminLabel(admin),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
            onChanged: (value) => widget.onAdminChanged(value?.toString()),
          ),
          const SizedBox(height: OpenVtsSpacing.sm),
          Text(
            'Date Range',
            style: OpenVtsTypography.label.copyWith(
              color: OpenVtsColors.textSecondary,
            ),
          ),
          const SizedBox(height: OpenVtsSpacing.xs),
          Wrap(
            spacing: OpenVtsSpacing.xs,
            runSpacing: OpenVtsSpacing.xs,
            children: [
              _FilterChoiceChip(
                label: 'All Time',
                selected: widget.state.rangePreset ==
                    SuperadminPaymentsRangePreset.allTime,
                onTap: () => widget.onRangePresetChanged(
                  SuperadminPaymentsRangePreset.allTime,
                ),
              ),
              _FilterChoiceChip(
                label: 'This Month',
                selected: widget.state.rangePreset ==
                    SuperadminPaymentsRangePreset.thisMonth,
                onTap: () => widget.onRangePresetChanged(
                  SuperadminPaymentsRangePreset.thisMonth,
                ),
              ),
              _FilterChoiceChip(
                label: 'Last 30 Days',
                selected: widget.state.rangePreset ==
                    SuperadminPaymentsRangePreset.last30,
                onTap: () => widget.onRangePresetChanged(
                  SuperadminPaymentsRangePreset.last30,
                ),
              ),
              _FilterChoiceChip(
                label: 'This Year',
                selected: widget.state.rangePreset ==
                    SuperadminPaymentsRangePreset.thisYear,
                onTap: () => widget.onRangePresetChanged(
                  SuperadminPaymentsRangePreset.thisYear,
                ),
              ),
              _FilterChoiceChip(
                label: 'Custom',
                selected: widget.state.rangePreset ==
                    SuperadminPaymentsRangePreset.custom,
                onTap: () => widget.onRangePresetChanged(
                  SuperadminPaymentsRangePreset.custom,
                ),
              ),
            ],
          ),
          if (widget.state.rangePreset ==
              SuperadminPaymentsRangePreset.custom) ...[
            const SizedBox(height: OpenVtsSpacing.sm),
            OpenVtsDateTimeRangeField(
              label: 'Custom Range',
              title: 'Choose Date Range',
              value: OpenVtsDateTimeRange(
                start: widget.state.customFrom,
                end: widget.state.customTo,
              ),
              firstDate: DateTime(2020),
              lastDate: DateTime.now(),
              onChanged: (range) => widget.onCustomRangeChanged(
                range.start == null ? null : DateUtils.dateOnly(range.start!),
                range.end == null ? null : DateUtils.dateOnly(range.end!),
              ),
            ),
          ],
          const SizedBox(height: OpenVtsSpacing.sm),
          Text(
            'Status',
            style: OpenVtsTypography.label.copyWith(
              color: OpenVtsColors.textSecondary,
            ),
          ),
          const SizedBox(height: OpenVtsSpacing.xs),
          Wrap(
            spacing: OpenVtsSpacing.xs,
            runSpacing: OpenVtsSpacing.xs,
            children: [
              _FilterChoiceChip(
                label: 'All',
                selected: widget.state.selectedStatus == null,
                onTap: () => widget.onStatusChanged(null),
              ),
              _FilterChoiceChip(
                label: SuperadminTransactionStatus.success.label,
                selected: widget.state.selectedStatus ==
                    SuperadminTransactionStatus.success,
                onTap: () =>
                    widget.onStatusChanged(SuperadminTransactionStatus.success),
              ),
              _FilterChoiceChip(
                label: SuperadminTransactionStatus.pending.label,
                selected: widget.state.selectedStatus ==
                    SuperadminTransactionStatus.pending,
                onTap: () =>
                    widget.onStatusChanged(SuperadminTransactionStatus.pending),
              ),
              _FilterChoiceChip(
                label: SuperadminTransactionStatus.failed.label,
                selected: widget.state.selectedStatus ==
                    SuperadminTransactionStatus.failed,
                onTap: () =>
                    widget.onStatusChanged(SuperadminTransactionStatus.failed),
              ),
            ],
          ),
        ],
      ],
    );
  }

  String _compactAdminLabel(SuperadminPaymentAdminOption admin) {
    final name = admin.displayName;
    final username = admin.username.trim();
    if (username.isNotEmpty) {
      return '$name · @$username';
    }
    return name;
  }

  List<SuperadminPaymentAdminOption> _resolveAdminOptions() {
    if (widget.state.selectedAdminId == null) {
      return widget.state.admins;
    }

    final selectedId = widget.state.selectedAdminId!;
    final hasSelected =
        widget.state.admins.any((item) => item.uid == selectedId);
    if (hasSelected) {
      return widget.state.admins;
    }

    return [
      SuperadminPaymentAdminOption(
        uid: selectedId,
        name: 'Admin #$selectedId',
        username: '',
        email: '',
        currency: '',
      ),
      ...widget.state.admins,
    ];
  }
}

class _AdminDropdownLabel extends StatelessWidget {
  const _AdminDropdownLabel({required this.admin});

  final SuperadminPaymentAdminOption admin;

  @override
  Widget build(BuildContext context) {
    final username = admin.username.trim();
    final currency = admin.currency.trim();
    final subtitleParts = <String>[
      if (username.isNotEmpty) '@$username',
      if (currency.isNotEmpty) currency,
    ];

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          admin.displayName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (subtitleParts.isNotEmpty)
          Text(
            subtitleParts.join(' • '),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: OpenVtsTypography.meta.copyWith(
              color: OpenVtsColors.textSecondary,
            ),
          ),
      ],
    );
  }
}

class _FilterChoiceChip extends StatelessWidget {
  const _FilterChoiceChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(OpenVtsRadius.md),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 40),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(
            horizontal: OpenVtsSpacing.sm,
            vertical: OpenVtsSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: selected ? OpenVtsColors.brandInk : OpenVtsColors.surface,
            borderRadius: BorderRadius.circular(OpenVtsRadius.md),
            border: Border.all(
              color: selected ? OpenVtsColors.brandInk : OpenVtsColors.border,
            ),
          ),
          child: Text(
            label,
            style: OpenVtsTypography.meta.copyWith(
              color: selected ? OpenVtsColors.white : OpenVtsColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
