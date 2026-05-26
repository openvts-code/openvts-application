import 'package:flutter/material.dart';

import '../../../../../core/theme/open_vts_colors.dart';
import '../../../../../core/theme/open_vts_radius.dart';
import '../../../../../core/theme/open_vts_spacing.dart';
import '../../../../../core/theme/open_vts_typography.dart';
import '../../../../../shared/widgets/open_vts_card.dart';
import '../../../../../shared/widgets/open_vts_date_time_range_selector.dart';
import '../../../models/admin_payments_model.dart';
import '../../../models/admin_payments_state.dart';
import '../../../models/admin_users_model.dart';

class AdminPaymentsFiltersCard extends StatelessWidget {
  const AdminPaymentsFiltersCard({
    required this.state,
    required this.onUserChanged,
    required this.onStatusChanged,
    required this.onModeChanged,
    required this.onRangePresetChanged,
    required this.onCustomRangeChanged,
    required this.onClear,
    required this.onApply,
    super.key,
  });

  final AdminPaymentsState state;
  final ValueChanged<String?> onUserChanged;
  final ValueChanged<AdminPaymentStatus?> onStatusChanged;
  final ValueChanged<AdminPaymentMode?> onModeChanged;
  final ValueChanged<AdminPaymentsRangePreset> onRangePresetChanged;
  final void Function(DateTime? from, DateTime? to) onCustomRangeChanged;
  final VoidCallback onClear;
  final VoidCallback onApply;

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
                  Icons.filter_list_rounded,
                  size: 18,
                  color: OpenVtsColors.textPrimary,
                ),
              ),
              const SizedBox(width: OpenVtsSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Filters', style: OpenVtsTypography.titleSmall),
                    const SizedBox(height: OpenVtsSpacing.xxs),
                    Text(
                      'Refine payments by user, status, mode, and date.',
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
          DropdownButtonFormField<String?>(
            initialValue: state.selectedUserId,
            decoration: const InputDecoration(labelText: 'User'),
            items: [
              const DropdownMenuItem<String?>(
                  value: null, child: Text('All Users')),
              ...state.users.map(
                (u) => DropdownMenuItem<String?>(
                  value: u.id,
                  child: _userLabel(u),
                ),
              ),
            ],
            onChanged: onUserChanged,
          ),
          const SizedBox(height: OpenVtsSpacing.sm),
          _chips(
            'Status',
            [
              _chip('All', state.selectedStatus == null,
                  () => onStatusChanged(null)),
              _chip(
                  'Success',
                  state.selectedStatus == AdminPaymentStatus.success,
                  () => onStatusChanged(AdminPaymentStatus.success)),
              _chip(
                  'Pending',
                  state.selectedStatus == AdminPaymentStatus.pending,
                  () => onStatusChanged(AdminPaymentStatus.pending)),
              _chip('Failed', state.selectedStatus == AdminPaymentStatus.failed,
                  () => onStatusChanged(AdminPaymentStatus.failed)),
            ],
          ),
          const SizedBox(height: OpenVtsSpacing.sm),
          _chips(
            'Payment Mode',
            [
              _chip(
                  'All', state.selectedMode == null, () => onModeChanged(null)),
              ...AdminPaymentMode.values.map((mode) => _chip(mode.label,
                  state.selectedMode == mode, () => onModeChanged(mode))),
            ],
          ),
          const SizedBox(height: OpenVtsSpacing.sm),
          _chips(
            'Date Range',
            [
              _chip(
                  'This Month',
                  state.rangePreset == AdminPaymentsRangePreset.thisMonth,
                  () =>
                      onRangePresetChanged(AdminPaymentsRangePreset.thisMonth)),
              _chip(
                  'Last 30 Days',
                  state.rangePreset == AdminPaymentsRangePreset.last30,
                  () => onRangePresetChanged(AdminPaymentsRangePreset.last30)),
              _chip(
                  'This Year',
                  state.rangePreset == AdminPaymentsRangePreset.thisYear,
                  () =>
                      onRangePresetChanged(AdminPaymentsRangePreset.thisYear)),
              _chip(
                  'Custom',
                  state.rangePreset == AdminPaymentsRangePreset.custom,
                  () => onRangePresetChanged(AdminPaymentsRangePreset.custom)),
            ],
          ),
          if (state.rangePreset == AdminPaymentsRangePreset.custom) ...[
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
                  onPressed: state.hasActiveFilters ? onClear : null,
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
                  onPressed: onApply,
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

  Widget _userLabel(AdminUserListItem user) {
    final username = user.username.trim();
    final text = username.isEmpty ? user.name : '${user.name} (@$username)';
    return Text(text, maxLines: 1, overflow: TextOverflow.ellipsis);
  }

  Widget _chips(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: OpenVtsTypography.label),
        const SizedBox(height: OpenVtsSpacing.xs),
        Wrap(
            spacing: OpenVtsSpacing.xs,
            runSpacing: OpenVtsSpacing.xs,
            children: children),
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
