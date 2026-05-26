import 'package:flutter/material.dart';

import '../../../../../core/theme/open_vts_colors.dart';
import '../../../../../core/theme/open_vts_radius.dart';
import '../../../../../core/theme/open_vts_spacing.dart';
import '../../../../../core/theme/open_vts_typography.dart';
import '../../../../../shared/widgets/open_vts_card.dart';
import '../../../../../shared/widgets/open_vts_date_time_range_selector.dart';
import '../../../../../shared/widgets/open_vts_search_field.dart';
import '../../../models/user_transactions_model.dart';
import '../../../models/user_transactions_state.dart';

class UserTransactionsFilterCard extends StatefulWidget {
  const UserTransactionsFilterCard({
    required this.searchQuery,
    required this.rangePreset,
    required this.customFrom,
    required this.customTo,
    required this.selectedStatus,
    required this.selectedPaymentMode,
    required this.selectedPaymentType,
    required this.hasActiveFilters,
    required this.onSearchChanged,
    required this.onRangePresetChanged,
    required this.onCustomRangeChanged,
    required this.onStatusChanged,
    required this.onPaymentModeChanged,
    required this.onPaymentTypeChanged,
    required this.onClearFilters,
    super.key,
  });

  final String searchQuery;
  final UserTransactionsRangePreset rangePreset;
  final DateTime? customFrom;
  final DateTime? customTo;
  final UserTransactionStatus? selectedStatus;
  final UserPaymentMode? selectedPaymentMode;
  final String? selectedPaymentType;
  final bool hasActiveFilters;

  final ValueChanged<String> onSearchChanged;
  final ValueChanged<UserTransactionsRangePreset> onRangePresetChanged;
  final void Function(DateTime? from, DateTime? to) onCustomRangeChanged;
  final ValueChanged<UserTransactionStatus?> onStatusChanged;
  final ValueChanged<UserPaymentMode?> onPaymentModeChanged;
  final ValueChanged<String?> onPaymentTypeChanged;
  final VoidCallback onClearFilters;

  @override
  State<UserTransactionsFilterCard> createState() =>
      _UserTransactionsFilterCardState();
}

class _UserTransactionsFilterCardState
    extends State<UserTransactionsFilterCard> {
  int _searchFieldVersion = 0;
  bool _showAdvancedFilters = false;

  @override
  void didUpdateWidget(covariant UserTransactionsFilterCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.searchQuery.trim().isNotEmpty &&
        widget.searchQuery.trim().isEmpty) {
      _searchFieldVersion += 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedPaymentType =
        widget.selectedPaymentType?.trim().toUpperCase();
    final hasAdvancedSelection = widget.selectedPaymentMode != null ||
        (selectedPaymentType != null && selectedPaymentType.isNotEmpty);
    final showAdvancedFilters = _showAdvancedFilters || hasAdvancedSelection;

    return OpenVtsCard(
      padding: const EdgeInsets.all(OpenVtsSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Filters',
                style: OpenVtsTypography.label.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              if (widget.hasActiveFilters)
                TextButton.icon(
                  onPressed: _handleClear,
                  style: TextButton.styleFrom(
                    foregroundColor: OpenVtsColors.textSecondary,
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(
                      horizontal: OpenVtsSpacing.xs,
                    ),
                    minimumSize: const Size(44, 44),
                  ),
                  icon: const Icon(Icons.filter_alt_off_outlined, size: 14),
                  label: Text(
                    'Clear',
                    style: OpenVtsTypography.meta.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: OpenVtsSpacing.xs),
          OpenVtsSearchField(
            key: ValueKey<int>(_searchFieldVersion),
            hintText: 'Search reference, provider, user, vehicle',
            onChanged: widget.onSearchChanged,
          ),
          const SizedBox(height: OpenVtsSpacing.sm),
          const _SectionLabel(text: 'Date Range'),
          const SizedBox(height: OpenVtsSpacing.xs),
          Wrap(
            spacing: OpenVtsSpacing.xs,
            runSpacing: OpenVtsSpacing.xs,
            children: [
              _CompactChoiceChip(
                label: 'This Month',
                selected:
                    widget.rangePreset == UserTransactionsRangePreset.thisMonth,
                onTap: () => widget.onRangePresetChanged(
                  UserTransactionsRangePreset.thisMonth,
                ),
              ),
              _CompactChoiceChip(
                label: 'Last 30 Days',
                selected: widget.rangePreset ==
                    UserTransactionsRangePreset.last30Days,
                onTap: () => widget.onRangePresetChanged(
                  UserTransactionsRangePreset.last30Days,
                ),
              ),
              _CompactChoiceChip(
                label: 'This Year',
                selected:
                    widget.rangePreset == UserTransactionsRangePreset.thisYear,
                onTap: () => widget.onRangePresetChanged(
                  UserTransactionsRangePreset.thisYear,
                ),
              ),
              _CompactChoiceChip(
                label: 'Custom',
                selected:
                    widget.rangePreset == UserTransactionsRangePreset.custom,
                onTap: () => widget.onRangePresetChanged(
                  UserTransactionsRangePreset.custom,
                ),
              ),
            ],
          ),
          if (widget.rangePreset == UserTransactionsRangePreset.custom) ...[
            const SizedBox(height: OpenVtsSpacing.sm),
            OpenVtsDateTimeRangeField(
              label: 'Custom Range',
              value: OpenVtsDateTimeRange(
                start: widget.customFrom,
                end: widget.customTo,
              ),
              onChanged: (range) =>
                  widget.onCustomRangeChanged(range.start, range.end),
              title: 'Choose Date Range',
            ),
          ],
          const SizedBox(height: OpenVtsSpacing.sm),
          const _SectionLabel(text: 'Status'),
          const SizedBox(height: OpenVtsSpacing.xs),
          Wrap(
            spacing: OpenVtsSpacing.xs,
            runSpacing: OpenVtsSpacing.xs,
            children: [
              _CompactChoiceChip(
                label: 'All',
                selected: widget.selectedStatus == null,
                onTap: () => widget.onStatusChanged(null),
              ),
              _CompactChoiceChip(
                label: 'Success',
                selected:
                    widget.selectedStatus == UserTransactionStatus.success,
                onTap: () =>
                    widget.onStatusChanged(UserTransactionStatus.success),
              ),
              _CompactChoiceChip(
                label: 'Pending',
                selected:
                    widget.selectedStatus == UserTransactionStatus.pending,
                onTap: () =>
                    widget.onStatusChanged(UserTransactionStatus.pending),
              ),
              _CompactChoiceChip(
                label: 'Failed',
                selected: widget.selectedStatus == UserTransactionStatus.failed,
                onTap: () =>
                    widget.onStatusChanged(UserTransactionStatus.failed),
              ),
            ],
          ),
          const SizedBox(height: OpenVtsSpacing.sm),
          TextButton.icon(
            onPressed: () {
              setState(() {
                _showAdvancedFilters = !showAdvancedFilters;
              });
            },
            style: TextButton.styleFrom(
              foregroundColor: OpenVtsColors.textSecondary,
              minimumSize: const Size(44, 44),
              padding:
                  const EdgeInsets.symmetric(horizontal: OpenVtsSpacing.xs),
            ),
            icon: Icon(
              showAdvancedFilters
                  ? Icons.expand_less_rounded
                  : Icons.tune_rounded,
              size: 16,
            ),
            label: Text(
              showAdvancedFilters
                  ? 'Hide payment filters'
                  : 'Show payment filters',
              style: OpenVtsTypography.meta.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (showAdvancedFilters) ...[
            const SizedBox(height: OpenVtsSpacing.xs),
            const _SectionLabel(text: 'Payment Mode'),
            const SizedBox(height: OpenVtsSpacing.xs),
            Wrap(
              spacing: OpenVtsSpacing.xs,
              runSpacing: OpenVtsSpacing.xs,
              children: [
                _CompactChoiceChip(
                  label: 'All',
                  selected: widget.selectedPaymentMode == null,
                  onTap: () => widget.onPaymentModeChanged(null),
                ),
                _CompactChoiceChip(
                  label: 'Cash',
                  selected: widget.selectedPaymentMode == UserPaymentMode.cash,
                  onTap: () =>
                      widget.onPaymentModeChanged(UserPaymentMode.cash),
                ),
                _CompactChoiceChip(
                  label: 'UPI',
                  selected: widget.selectedPaymentMode == UserPaymentMode.upi,
                  onTap: () => widget.onPaymentModeChanged(UserPaymentMode.upi),
                ),
                _CompactChoiceChip(
                  label: 'Bank Transfer',
                  selected: widget.selectedPaymentMode ==
                      UserPaymentMode.bankTransfer,
                  onTap: () =>
                      widget.onPaymentModeChanged(UserPaymentMode.bankTransfer),
                ),
                _CompactChoiceChip(
                  label: 'Card',
                  selected: widget.selectedPaymentMode == UserPaymentMode.card,
                  onTap: () =>
                      widget.onPaymentModeChanged(UserPaymentMode.card),
                ),
                _CompactChoiceChip(
                  label: 'Wallet',
                  selected:
                      widget.selectedPaymentMode == UserPaymentMode.wallet,
                  onTap: () =>
                      widget.onPaymentModeChanged(UserPaymentMode.wallet),
                ),
                _CompactChoiceChip(
                  label: 'Razorpay',
                  selected:
                      widget.selectedPaymentMode == UserPaymentMode.razorpay,
                  onTap: () =>
                      widget.onPaymentModeChanged(UserPaymentMode.razorpay),
                ),
                _CompactChoiceChip(
                  label: 'Stripe',
                  selected:
                      widget.selectedPaymentMode == UserPaymentMode.stripe,
                  onTap: () =>
                      widget.onPaymentModeChanged(UserPaymentMode.stripe),
                ),
                _CompactChoiceChip(
                  label: 'Other',
                  selected: widget.selectedPaymentMode == UserPaymentMode.other,
                  onTap: () =>
                      widget.onPaymentModeChanged(UserPaymentMode.other),
                ),
              ],
            ),
            const SizedBox(height: OpenVtsSpacing.sm),
            const _SectionLabel(text: 'Payment Type'),
            const SizedBox(height: OpenVtsSpacing.xs),
            Wrap(
              spacing: OpenVtsSpacing.xs,
              runSpacing: OpenVtsSpacing.xs,
              children: [
                _CompactChoiceChip(
                  label: 'All',
                  selected: selectedPaymentType == null,
                  onTap: () => widget.onPaymentTypeChanged(null),
                ),
                _CompactChoiceChip(
                  label: 'Credit',
                  selected: selectedPaymentType == 'CREDIT',
                  onTap: () => widget.onPaymentTypeChanged('CREDIT'),
                ),
                _CompactChoiceChip(
                  label: 'Debit',
                  selected: selectedPaymentType == 'DEBIT',
                  onTap: () => widget.onPaymentTypeChanged('DEBIT'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _handleClear() {
    widget.onClearFilters();
    setState(() {
      _searchFieldVersion += 1;
      _showAdvancedFilters = false;
    });
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: OpenVtsTypography.meta.copyWith(
        color: OpenVtsColors.textSecondary,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _CompactChoiceChip extends StatelessWidget {
  const _CompactChoiceChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      selected: selected,
      showCheckmark: false,
      onSelected: (_) => onTap(),
      labelPadding: const EdgeInsets.symmetric(horizontal: 2),
      materialTapTargetSize: MaterialTapTargetSize.padded,
      selectedColor: OpenVtsColors.brandInk,
      backgroundColor: OpenVtsColors.surfaceElevated,
      side: BorderSide(
        color: selected ? OpenVtsColors.brandInk : OpenVtsColors.border,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(OpenVtsRadius.pill),
      ),
      label: Text(
        label,
        style: OpenVtsTypography.meta.copyWith(
          color: selected ? OpenVtsColors.white : OpenVtsColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
