import 'package:flutter/material.dart';

import '../../../../../core/theme/open_vts_colors.dart';
import '../../../../../core/theme/open_vts_radius.dart';
import '../../../../../core/theme/open_vts_spacing.dart';
import '../../../../../core/theme/open_vts_typography.dart';
import '../../../../../shared/widgets/open_vts_card.dart';
import '../../../../../shared/widgets/open_vts_date_time_range_selector.dart';
import '../../../models/admin_transactions_model.dart';
import '../../../models/admin_transactions_state.dart';

class AdminTransactionsFiltersCard extends StatelessWidget {
  const AdminTransactionsFiltersCard({
    required this.state,
    required this.onStatusChanged,
    required this.onModeChanged,
    required this.onTypeChanged,
    required this.onRangePresetChanged,
    required this.onCustomRangeChanged,
    required this.onClearFilters,
    required this.onApplyFilters,
    super.key,
  });

  final AdminTransactionsState state;
  final ValueChanged<AdminTransactionStatus?> onStatusChanged;
  final ValueChanged<AdminPaymentMode?> onModeChanged;
  final ValueChanged<AdminPaymentType?> onTypeChanged;
  final ValueChanged<AdminTransactionsRangePreset> onRangePresetChanged;
  final void Function(DateTime? from, DateTime? to) onCustomRangeChanged;
  final VoidCallback onClearFilters;
  final VoidCallback onApplyFilters;

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
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: OpenVtsColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(OpenVtsRadius.md),
                  border: Border.all(color: OpenVtsColors.border),
                ),
                child: const Icon(
                  Icons.tune_rounded,
                  size: 18,
                  color: OpenVtsColors.textPrimary,
                ),
              ),
              const SizedBox(width: OpenVtsSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Filters',
                      style: OpenVtsTypography.titleSmall.copyWith(
                        color: OpenVtsColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: OpenVtsSpacing.xxs),
                    Text(
                      'Refine transactions by status, mode, type, and date.',
                      style: OpenVtsTypography.meta.copyWith(
                        color: OpenVtsColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: OpenVtsSpacing.md),
          _section(
            title: 'Status',
            child: Wrap(
              spacing: OpenVtsSpacing.xs,
              runSpacing: OpenVtsSpacing.xs,
              children: [
                _chip(
                  'All',
                  state.selectedStatus == null,
                  () => onStatusChanged(null),
                ),
                _chip(
                  'Success',
                  state.selectedStatus == AdminTransactionStatus.success,
                  () => onStatusChanged(AdminTransactionStatus.success),
                ),
                _chip(
                  'Pending',
                  state.selectedStatus == AdminTransactionStatus.pending,
                  () => onStatusChanged(AdminTransactionStatus.pending),
                ),
                _chip(
                  'Failed',
                  state.selectedStatus == AdminTransactionStatus.failed,
                  () => onStatusChanged(AdminTransactionStatus.failed),
                ),
              ],
            ),
          ),
          const SizedBox(height: OpenVtsSpacing.sm),
          _section(
            title: 'Payment Mode',
            child: Wrap(
              spacing: OpenVtsSpacing.xs,
              runSpacing: OpenVtsSpacing.xs,
              children: [
                _chip(
                  'All',
                  state.selectedMode == null,
                  () => onModeChanged(null),
                ),
                ...AdminPaymentMode.values.map(
                  (mode) => _chip(
                    mode.label,
                    state.selectedMode == mode,
                    () => onModeChanged(mode),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: OpenVtsSpacing.sm),
          _section(
            title: 'Payment Type',
            child: Wrap(
              spacing: OpenVtsSpacing.xs,
              runSpacing: OpenVtsSpacing.xs,
              children: [
                _chip(
                  'All',
                  state.selectedType == null,
                  () => onTypeChanged(null),
                ),
                _chip(
                  'Credit',
                  state.selectedType == AdminPaymentType.credit,
                  () => onTypeChanged(AdminPaymentType.credit),
                ),
                _chip(
                  'Debit',
                  state.selectedType == AdminPaymentType.debit,
                  () => onTypeChanged(AdminPaymentType.debit),
                ),
              ],
            ),
          ),
          const SizedBox(height: OpenVtsSpacing.sm),
          _section(
            title: 'Date Range',
            child: Wrap(
              spacing: OpenVtsSpacing.xs,
              runSpacing: OpenVtsSpacing.xs,
              children: [
                _chip(
                  'This Month',
                  state.rangePreset == AdminTransactionsRangePreset.thisMonth,
                  () => onRangePresetChanged(
                    AdminTransactionsRangePreset.thisMonth,
                  ),
                ),
                _chip(
                  'Last 30 Days',
                  state.rangePreset == AdminTransactionsRangePreset.last30,
                  () => onRangePresetChanged(AdminTransactionsRangePreset.last30),
                ),
                _chip(
                  'This Year',
                  state.rangePreset == AdminTransactionsRangePreset.thisYear,
                  () => onRangePresetChanged(AdminTransactionsRangePreset.thisYear),
                ),
                _chip(
                  'Custom',
                  state.rangePreset == AdminTransactionsRangePreset.custom,
                  () => onRangePresetChanged(AdminTransactionsRangePreset.custom),
                ),
              ],
            ),
          ),
          if (state.rangePreset == AdminTransactionsRangePreset.custom) ...[
            const SizedBox(height: OpenVtsSpacing.sm),
            OpenVtsDateTimeRangeField(
              label: 'Custom Range',
              title: 'Choose Date Range',
              value: OpenVtsDateTimeRange(
                  start: state.customFrom, end: state.customTo),
              firstDate: DateTime(2020),
              lastDate: DateTime.now(),
              onChanged: (range) =>
                  onCustomRangeChanged(range.start, range.end),
            ),
          ],
          const SizedBox(height: OpenVtsSpacing.md),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: state.hasActiveFilters ? onClearFilters : null,
                  icon: const Icon(Icons.restart_alt_rounded, size: 16),
                  label: const Text('Clear'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(44),
                    side: const BorderSide(color: OpenVtsColors.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(OpenVtsRadius.md),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: OpenVtsSpacing.sm),
              Expanded(
                child: FilledButton.icon(
                  onPressed: onApplyFilters,
                  icon: const Icon(Icons.check_circle_outline_rounded, size: 16),
                  label: const Text('Apply Filters'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(44),
                    backgroundColor: OpenVtsColors.brandInk,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(OpenVtsRadius.md),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _section({
    required String title,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: OpenVtsTypography.label.copyWith(
            color: OpenVtsColors.textPrimary,
          ),
        ),
        const SizedBox(height: OpenVtsSpacing.xs),
        child,
      ],
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(OpenVtsRadius.pill),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 46, minWidth: 88),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(
            horizontal: OpenVtsSpacing.md,
            vertical: OpenVtsSpacing.xs,
          ),
          decoration: BoxDecoration(
            color:
                selected ? OpenVtsColors.brandInk : OpenVtsColors.surfaceElevated,
            borderRadius: BorderRadius.circular(OpenVtsRadius.pill),
            border: Border.all(
              color: selected ? OpenVtsColors.brandInk : OpenVtsColors.border,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selected) ...[
                const Icon(
                  Icons.check_circle_outline_rounded,
                  size: 14,
                  color: OpenVtsColors.white,
                ),
                const SizedBox(width: OpenVtsSpacing.xxs),
              ],
              Text(
                label,
                style: OpenVtsTypography.meta.copyWith(
                  color: selected
                      ? OpenVtsColors.white
                      : OpenVtsColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
