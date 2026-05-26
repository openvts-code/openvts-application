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
    final admins = _resolveAdminOptions();
    final selectedAdmin = state.selectedAdminId;
    final selectedAdminValue =
        admins.any((item) => item.uid == selectedAdmin) ? selectedAdmin : null;

    return OpenVtsCard(
      padding: const EdgeInsets.all(OpenVtsSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Filters',
                  style: OpenVtsTypography.titleSmall.copyWith(
                    color: OpenVtsColors.textPrimary,
                  ),
                ),
              ),
              if (state.hasActiveFilters)
                TextButton(
                  onPressed: onClearFilters,
                  child: const Text('Clear filters'),
                ),
            ],
          ),
          const SizedBox(height: OpenVtsSpacing.sm),
          DropdownButtonFormField<int?>(
            initialValue: selectedAdminValue,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: 'Administrator',
              suffixIcon: state.isLoadingAdmins
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
            onChanged: (value) => onAdminChanged(value?.toString()),
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
                label: 'This Month',
                selected: state.rangePreset ==
                    SuperadminPaymentsRangePreset.thisMonth,
                onTap: () => onRangePresetChanged(
                  SuperadminPaymentsRangePreset.thisMonth,
                ),
              ),
              _FilterChoiceChip(
                label: 'Last 30 Days',
                selected:
                    state.rangePreset == SuperadminPaymentsRangePreset.last30,
                onTap: () => onRangePresetChanged(
                  SuperadminPaymentsRangePreset.last30,
                ),
              ),
              _FilterChoiceChip(
                label: 'This Year',
                selected:
                    state.rangePreset == SuperadminPaymentsRangePreset.thisYear,
                onTap: () => onRangePresetChanged(
                  SuperadminPaymentsRangePreset.thisYear,
                ),
              ),
              _FilterChoiceChip(
                label: 'Custom',
                selected:
                    state.rangePreset == SuperadminPaymentsRangePreset.custom,
                onTap: () => onRangePresetChanged(
                  SuperadminPaymentsRangePreset.custom,
                ),
              ),
            ],
          ),
          if (state.rangePreset == SuperadminPaymentsRangePreset.custom) ...[
            const SizedBox(height: OpenVtsSpacing.sm),
            OpenVtsDateTimeRangeField(
              label: 'Custom Range',
              title: 'Choose Date Range',
              value: OpenVtsDateTimeRange(
                start: state.customFrom,
                end: state.customTo,
              ),
              firstDate: DateTime(2020),
              lastDate: DateTime.now(),
              onChanged: (range) => onCustomRangeChanged(
                range.start == null ? null : DateUtils.dateOnly(range.start!),
                range.end == null ? null : DateUtils.dateOnly(range.end!),
              ),
            ),
          ],
          const SizedBox(height: OpenVtsSpacing.sm),
          OpenVtsSearchField(
            hintText: 'Search reference, provider, admin...',
            onChanged: onSearchChanged,
          ),
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
                selected: state.selectedStatus == null,
                onTap: () => onStatusChanged(null),
              ),
              _FilterChoiceChip(
                label: SuperadminTransactionStatus.success.label,
                selected:
                    state.selectedStatus == SuperadminTransactionStatus.success,
                onTap: () =>
                    onStatusChanged(SuperadminTransactionStatus.success),
              ),
              _FilterChoiceChip(
                label: SuperadminTransactionStatus.pending.label,
                selected:
                    state.selectedStatus == SuperadminTransactionStatus.pending,
                onTap: () =>
                    onStatusChanged(SuperadminTransactionStatus.pending),
              ),
              _FilterChoiceChip(
                label: SuperadminTransactionStatus.failed.label,
                selected:
                    state.selectedStatus == SuperadminTransactionStatus.failed,
                onTap: () =>
                    onStatusChanged(SuperadminTransactionStatus.failed),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<SuperadminPaymentAdminOption> _resolveAdminOptions() {
    if (state.selectedAdminId == null) {
      return state.admins;
    }

    final selectedId = state.selectedAdminId!;
    final hasSelected = state.admins.any((item) => item.uid == selectedId);
    if (hasSelected) {
      return state.admins;
    }

    return [
      SuperadminPaymentAdminOption(
        uid: selectedId,
        name: 'Admin #$selectedId',
        username: '',
        email: '',
        currency: '',
      ),
      ...state.admins,
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
