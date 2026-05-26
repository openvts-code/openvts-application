import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../../core/theme/open_vts_colors.dart';
import '../../../../../core/theme/open_vts_radius.dart';
import '../../../../../core/theme/open_vts_spacing.dart';
import '../../../../../core/theme/open_vts_typography.dart';
import '../../../../../core/utils/date_time_formatter.dart';
import '../../../../../shared/helpers/toast_helper.dart';
import '../../../../../shared/widgets/open_vts_bottom_sheet.dart';
import '../../../../../shared/widgets/open_vts_button.dart';
import '../../../../../shared/widgets/open_vts_card.dart';
import '../../../../../shared/widgets/open_vts_text_field.dart';
import '../../../controllers/admin_providers.dart';
import '../../../models/admin_user_details_model.dart';

const DateTimeFormatter _dateFormatter = DateTimeFormatter();
const List<String> _paymentModes = <String>[
  'CASH',
  'BANK_TRANSFER',
  'CARD',
  'UPI',
  'WALLET',
  'CHEQUE',
  'OTHER',
];

class AdminUserPaymentsTab extends ConsumerStatefulWidget {
  const AdminUserPaymentsTab({
    super.key,
    required this.userId,
  });

  final String userId;

  @override
  ConsumerState<AdminUserPaymentsTab> createState() =>
      _AdminUserPaymentsTabState();
}

class _AdminUserPaymentsTabState extends ConsumerState<AdminUserPaymentsTab> {
  @override
  Widget build(BuildContext context) {
    final provider = adminUserDetailsControllerProvider(widget.userId);
    final state = ref.watch(provider);
    final controller = ref.read(provider.notifier);
    final isInitialLoading = state.isLoadingPayments &&
        state.payments.isEmpty &&
        state.paymentsPage == null;

    if (isInitialLoading) {
      return const _SectionLoader(title: 'Payments');
    }

    if (state.sectionErrorMessage != null && state.payments.isEmpty) {
      return _SectionErrorCard(
        message: state.sectionErrorMessage!,
        onRetry: controller.loadPayments,
      );
    }

    final stats = _PaymentStats.from(state.payments);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SummaryCard(
          totalCount: state.paymentsPage?.total ?? state.payments.length,
          isLoading: state.isLoadingPayments,
          isRenewing: state.isRenewingPayment,
          onRenew: state.isRenewingPayment ? null : _showRenewSheet,
        ),
        const SizedBox(height: OpenVtsSpacing.sm),
        _StatsGrid(stats: stats),
        const SizedBox(height: OpenVtsSpacing.sm),
        if (state.sectionErrorMessage != null) ...[
          _InlineError(message: state.sectionErrorMessage!),
          const SizedBox(height: OpenVtsSpacing.sm),
        ],
        if (state.payments.isEmpty)
          const _EmptyCard(label: 'No payments found')
        else
          for (final payment in state.payments) ...[
            _PaymentCard(
              payment: payment,
              onTap: () => _showPaymentDetails(payment),
            ),
            if (payment != state.payments.last)
              const SizedBox(height: OpenVtsSpacing.sm),
          ],
      ],
    );
  }

  Future<void> _showRenewSheet() async {
    final provider = adminUserDetailsControllerProvider(widget.userId);
    final controller = ref.read(provider.notifier);
    final state = ref.read(provider);
    if (state.linkedVehicles.isEmpty && !state.isLoadingVehicles) {
      await controller.loadVehicles();
      if (!mounted) {
        return;
      }
    }

    await OpenVtsBottomSheet.show<void>(
      context: context,
      title: 'Renew Vehicle',
      initialChildSize: 0.86,
      minChildSize: 0.5,
      maxChildSize: 0.96,
      child: _RenewPaymentSheet(userId: widget.userId),
    );
  }

  Future<void> _showPaymentDetails(AdminUserPayment payment) {
    return OpenVtsBottomSheet.show<void>(
      context: context,
      title: 'Transaction Details',
      initialChildSize: 0.78,
      minChildSize: 0.46,
      maxChildSize: 0.94,
      child: _PaymentDetailsSheet(payment: payment),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.totalCount,
    required this.isLoading,
    required this.isRenewing,
    required this.onRenew,
  });

  final int totalCount;
  final bool isLoading;
  final bool isRenewing;
  final VoidCallback? onRenew;

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
                      Icons.payments_outlined,
                      size: 17,
                      color: OpenVtsColors.textSecondary,
                    ),
                    const SizedBox(width: OpenVtsSpacing.xs),
                    Text(
                      'Payments',
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
                  totalCount == 1 ? '1 payment' : '$totalCount payments',
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
              label: 'Renew Vehicle',
              height: 34,
              isLoading: isRenewing,
              onPressed: onRenew,
              trailingIcon: Icons.autorenew_rounded,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.stats});

  final _PaymentStats stats;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - OpenVtsSpacing.sm) / 2;
        return Wrap(
          spacing: OpenVtsSpacing.sm,
          runSpacing: OpenVtsSpacing.sm,
          children: [
            _StatCard(
              width: width,
              label: 'Total Received',
              value: stats.totalReceivedLabel,
              icon: Icons.account_balance_wallet_outlined,
            ),
            _StatCard(
              width: width,
              label: 'Successful',
              value: stats.successfulCount.toString(),
              icon: Icons.check_circle_outline_rounded,
            ),
            _StatCard(
              width: width,
              label: 'Pending / Failed',
              value: '${stats.pendingCount} / ${stats.failedCount}',
              icon: Icons.pending_actions_rounded,
            ),
            _StatCard(
              width: width,
              label: 'Last Payment',
              value: _dateText(stats.lastPaymentAt),
              icon: Icons.event_outlined,
            ),
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.width,
    required this.label,
    required this.value,
    required this.icon,
  });

  final double width;
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: OpenVtsCard(
        padding: const EdgeInsets.all(OpenVtsSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 15, color: OpenVtsColors.textSecondary),
                const SizedBox(width: OpenVtsSpacing.xs),
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
            const SizedBox(height: OpenVtsSpacing.xs),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: OpenVtsTypography.label.copyWith(
                color: OpenVtsColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  const _PaymentCard({required this.payment, required this.onTap});

  final AdminUserPayment payment;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final vehicle = _mapLabel(payment.vehicle, const [
      'name',
      'vehicleName',
      'vehicle_name',
      'plateNumber',
      'plate_number',
      'imei',
    ]);
    final plan = _mapLabel(payment.plan, const [
      'name',
      'planName',
      'plan_name',
      'title',
      'label',
    ]);
    final reference = _joinParts([
      payment.reference,
      payment.provider,
      payment.providerRef,
    ]);

    return OpenVtsCard(
      onTap: onTap,
      padding: const EdgeInsets.all(OpenVtsSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _paymentAmount(payment),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: OpenVtsTypography.label.copyWith(
                        color: OpenVtsColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _joinParts([payment.paymentMode, payment.paymentType]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: OpenVtsTypography.meta.copyWith(
                        color: OpenVtsColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: OpenVtsSpacing.xs),
              _StatusPill(status: payment.status),
            ],
          ),
          const SizedBox(height: OpenVtsSpacing.sm),
          Wrap(
            spacing: OpenVtsSpacing.xs,
            runSpacing: OpenVtsSpacing.xs,
            children: [
              _MetaPill(
                icon: Icons.directions_car_filled_outlined,
                label: _displayValue(vehicle),
              ),
              _MetaPill(
                icon: Icons.workspace_premium_outlined,
                label: _displayValue(plan),
              ),
              _MetaPill(
                icon: Icons.receipt_long_outlined,
                label: _displayValue(reference),
              ),
              _MetaPill(
                icon: Icons.calendar_today_outlined,
                label: _dateTimeText(payment.createdAt),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RenewPaymentSheet extends ConsumerStatefulWidget {
  const _RenewPaymentSheet({required this.userId});

  final String userId;

  @override
  ConsumerState<_RenewPaymentSheet> createState() => _RenewPaymentSheetState();
}

class _RenewPaymentSheetState extends ConsumerState<_RenewPaymentSheet> {
  final _referenceController = TextEditingController();
  final _amountController = TextEditingController();
  final _selectedVehicleIds = <String>{};
  var _paymentMode = 'CASH';

  @override
  void dispose() {
    _referenceController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = adminUserDetailsControllerProvider(widget.userId);
    final state = ref.watch(provider);
    final vehicles = state.linkedVehicles;
    final selectedVehicles = vehicles
        .where((vehicle) => _selectedVehicleIds.contains(vehicle.id))
        .toList(growable: false);
    final estimate = _estimateForVehicles(selectedVehicles);

    return Column(
      children: [
        Expanded(
          child: ListView(
            controller: PrimaryScrollController.maybeOf(context),
            padding: const EdgeInsets.all(OpenVtsSpacing.md),
            children: [
              _EstimateCard(
                selectedCount: _selectedVehicleIds.length,
                estimateLabel: estimate,
              ),
              const SizedBox(height: OpenVtsSpacing.sm),
              _PaymentModeField(
                value: _paymentMode,
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _paymentMode = value);
                  }
                },
              ),
              const SizedBox(height: OpenVtsSpacing.sm),
              OpenVtsTextField(
                label: 'Reference',
                controller: _referenceController,
                hintText: 'Optional receipt or note',
                prefixIcon: Icons.receipt_long_outlined,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: OpenVtsSpacing.sm),
              OpenVtsTextField(
                label: 'Amount override',
                controller: _amountController,
                hintText: 'Optional amount',
                prefixIcon: Icons.payments_outlined,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: OpenVtsSpacing.md),
              Text(
                'Vehicles',
                style: OpenVtsTypography.label.copyWith(
                  color: OpenVtsColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: OpenVtsSpacing.xs),
              if (state.isLoadingVehicles && vehicles.isEmpty)
                const _SectionLoader(title: 'Vehicles')
              else if (vehicles.isEmpty)
                const _EmptyCard(label: 'No linked vehicles available')
              else
                for (final vehicle in vehicles) ...[
                  _SelectableVehicleTile(
                    vehicle: vehicle,
                    isSelected: _selectedVehicleIds.contains(vehicle.id),
                    onTap: () => _toggleVehicle(vehicle.id),
                  ),
                  if (vehicle != vehicles.last)
                    const SizedBox(height: OpenVtsSpacing.xs),
                ],
            ],
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
                    onPressed: state.isRenewingPayment
                        ? null
                        : () => Navigator.of(context).pop(),
                  ),
                ),
                const SizedBox(width: OpenVtsSpacing.sm),
                Expanded(
                  child: OpenVtsButton(
                    label: 'Renew',
                    height: 40,
                    isLoading: state.isRenewingPayment,
                    trailingIcon: Icons.check_rounded,
                    onPressed: state.isRenewingPayment ? null : _submit,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _toggleVehicle(String vehicleId) {
    setState(() {
      if (_selectedVehicleIds.contains(vehicleId)) {
        _selectedVehicleIds.remove(vehicleId);
      } else {
        _selectedVehicleIds.add(vehicleId);
      }
    });
  }

  Future<void> _submit() async {
    if (_selectedVehicleIds.isEmpty) {
      ToastHelper.showError('Select at least one vehicle.', context: context);
      return;
    }

    final amount = _amountController.text.trim();
    if (amount.isNotEmpty && num.tryParse(amount.replaceAll(',', '')) == null) {
      ToastHelper.showError('Enter a valid amount.', context: context);
      return;
    }

    final provider = adminUserDetailsControllerProvider(widget.userId);
    final ok = await ref.read(provider.notifier).renewVehiclesPayment(
          AdminRenewVehiclesPaymentRequest(
            userId: widget.userId,
            vehicleIds: _selectedVehicleIds.toList(growable: false),
            paymentMode: _paymentMode,
            reference: _referenceController.text.trim(),
            amountOverride: amount,
          ),
        );
    if (!mounted) {
      return;
    }

    if (ok) {
      ToastHelper.showSuccess('Vehicle renewal recorded.', context: context);
      Navigator.of(context).pop();
    } else {
      ToastHelper.showError(
        ref.read(provider).sectionErrorMessage ?? 'Unable to renew vehicles.',
        context: context,
      );
    }
  }
}

class _EstimateCard extends StatelessWidget {
  const _EstimateCard({
    required this.selectedCount,
    required this.estimateLabel,
  });

  final int selectedCount;
  final String estimateLabel;

  @override
  Widget build(BuildContext context) {
    return OpenVtsCard(
      padding: const EdgeInsets.all(OpenVtsSpacing.sm),
      child: Row(
        children: [
          const Icon(
            Icons.calculate_outlined,
            size: 18,
            color: OpenVtsColors.textSecondary,
          ),
          const SizedBox(width: OpenVtsSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$selectedCount selected',
                  style: OpenVtsTypography.label.copyWith(
                    color: OpenVtsColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'Estimated total $estimateLabel',
                  style: OpenVtsTypography.meta.copyWith(
                    color: OpenVtsColors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentModeField extends StatelessWidget {
  const _PaymentModeField({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Payment mode', style: OpenVtsTypography.label),
        const SizedBox(height: OpenVtsSpacing.xs),
        DropdownButtonFormField<String>(
          initialValue: value,
          isExpanded: true,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.account_balance_wallet_outlined),
          ),
          items: _paymentModes
              .map(
                (mode) => DropdownMenuItem<String>(
                  value: mode,
                  child: Text(
                    _statusLabel(mode),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(growable: false),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _SelectableVehicleTile extends StatelessWidget {
  const _SelectableVehicleTile({
    required this.vehicle,
    required this.isSelected,
    required this.onTap,
  });

  final AdminUserVehicle vehicle;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final planName = _vehiclePlanName(vehicle);
    final price = _vehiclePlanPrice(vehicle);
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
                    ? Icons.check_circle_rounded
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
                      _vehicleTitle(vehicle),
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
                      _joinParts([vehicle.plateNumber, vehicle.imei, planName]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: OpenVtsTypography.meta.copyWith(
                        color: OpenVtsColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: OpenVtsSpacing.xs),
              Text(
                price == null ? '-' : _formatNumber(price),
                style: OpenVtsTypography.meta.copyWith(
                  color: OpenVtsColors.textSecondary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaymentDetailsSheet extends StatelessWidget {
  const _PaymentDetailsSheet({required this.payment});

  final AdminUserPayment payment;

  @override
  Widget build(BuildContext context) {
    return ListView(
      controller: PrimaryScrollController.maybeOf(context),
      padding: const EdgeInsets.all(OpenVtsSpacing.md),
      children: [
        OpenVtsCard(
          padding: const EdgeInsets.all(OpenVtsSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  _paymentAmount(payment),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: OpenVtsTypography.numeric.copyWith(
                    color: OpenVtsColors.textPrimary,
                    fontSize: 24,
                  ),
                ),
              ),
              const SizedBox(width: OpenVtsSpacing.sm),
              _StatusPill(status: payment.status),
            ],
          ),
        ),
        const SizedBox(height: OpenVtsSpacing.sm),
        _DetailsCard(
          title: 'Details',
          rows: [
            _DetailRowData('Transaction ID', _displayValue(payment.id)),
            _DetailRowData('Date', _dateTimeText(payment.createdAt)),
            _DetailRowData('Status', _statusLabel(payment.status)),
            _DetailRowData('Payment Mode', _statusLabel(payment.paymentMode)),
            _DetailRowData('Payment Type', _statusLabel(payment.paymentType)),
            _DetailRowData('Reference', _displayValue(payment.reference)),
            _DetailRowData('Provider', _displayValue(payment.provider)),
            _DetailRowData('Provider Ref', _displayValue(payment.providerRef)),
          ],
        ),
        const SizedBox(height: OpenVtsSpacing.sm),
        _DetailsCard(
          title: 'Vehicle / Plan',
          rows: [
            _DetailRowData(
              'Vehicle',
              _displayValue(
                _mapLabel(payment.vehicle, const [
                  'name',
                  'vehicleName',
                  'plateNumber',
                  'imei',
                ]),
              ),
            ),
            _DetailRowData(
              'Plan',
              _displayValue(
                _mapLabel(payment.plan, const [
                  'name',
                  'planName',
                  'plan_name',
                  'title',
                ]),
              ),
            ),
          ],
        ),
        if (payment.meta.isNotEmpty) ...[
          const SizedBox(height: OpenVtsSpacing.sm),
          _MetaJsonCard(meta: payment.meta),
        ],
      ],
    );
  }
}

class _DetailsCard extends StatelessWidget {
  const _DetailsCard({required this.title, required this.rows});

  final String title;
  final List<_DetailRowData> rows;

  @override
  Widget build(BuildContext context) {
    return OpenVtsCard(
      padding: const EdgeInsets.all(OpenVtsSpacing.md),
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
          const SizedBox(height: OpenVtsSpacing.sm),
          for (final row in rows) _DetailRow(row: row),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.row});

  final _DetailRowData row;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: OpenVtsSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 104,
            child: Text(
              row.label,
              style: OpenVtsTypography.meta.copyWith(
                color: OpenVtsColors.textTertiary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              row.value,
              style: OpenVtsTypography.meta.copyWith(
                color: OpenVtsColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRowData {
  const _DetailRowData(this.label, this.value);

  final String label;
  final String value;
}

class _MetaJsonCard extends StatelessWidget {
  const _MetaJsonCard({required this.meta});

  final Map<String, dynamic> meta;

  @override
  Widget build(BuildContext context) {
    return OpenVtsCard(
      padding: const EdgeInsets.all(OpenVtsSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Meta',
            style: OpenVtsTypography.label.copyWith(
              color: OpenVtsColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: OpenVtsSpacing.sm),
          SelectableText(
            meta.toString(),
            style: OpenVtsTypography.meta.copyWith(
              color: OpenVtsColors.textPrimary,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(status);
    return _MetaPill(
      icon: _isSuccessStatus(status)
          ? Icons.check_rounded
          : _isFailedStatus(status)
              ? Icons.error_outline_rounded
              : Icons.pending_outlined,
      label: _statusLabel(status),
      color: color,
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({
    required this.icon,
    required this.label,
    this.color = OpenVtsColors.textSecondary,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 17,
                color: OpenVtsColors.error,
              ),
              const SizedBox(width: OpenVtsSpacing.xs),
              Expanded(
                child: Text(
                  'Unable to load payments',
                  style: OpenVtsTypography.label.copyWith(
                    color: OpenVtsColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: OpenVtsSpacing.xs),
          Text(
            message,
            style: OpenVtsTypography.meta.copyWith(
              color: OpenVtsColors.textSecondary,
            ),
          ),
          const SizedBox(height: OpenVtsSpacing.sm),
          OpenVtsButton(
            label: 'Retry',
            height: 34,
            variant: OpenVtsButtonVariant.secondary,
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(OpenVtsSpacing.md),
      decoration: BoxDecoration(
        color: OpenVtsColors.surface,
        borderRadius: BorderRadius.circular(OpenVtsRadius.sm),
        border: Border.all(color: OpenVtsColors.border),
      ),
      child: Text(
        label,
        style: OpenVtsTypography.meta.copyWith(
          color: OpenVtsColors.textSecondary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _PaymentStats {
  const _PaymentStats({
    required this.totalReceived,
    required this.currency,
    required this.successfulCount,
    required this.pendingCount,
    required this.failedCount,
    required this.lastPaymentAt,
  });

  final num totalReceived;
  final String currency;
  final int successfulCount;
  final int pendingCount;
  final int failedCount;
  final DateTime? lastPaymentAt;

  String get totalReceivedLabel {
    final amount = _formatNumber(totalReceived);
    return currency.isEmpty ? amount : '$currency $amount';
  }

  static _PaymentStats from(List<AdminUserPayment> payments) {
    num totalReceived = 0;
    var successful = 0;
    var pending = 0;
    var failed = 0;
    DateTime? lastPaymentAt;
    var currency = '';

    for (final payment in payments) {
      if (_isSuccessStatus(payment.status)) {
        successful++;
        totalReceived += _parseAmount(payment.amount) ?? 0;
        if (currency.isEmpty && payment.currency.trim().isNotEmpty) {
          currency = payment.currency.trim();
        }
      } else if (_isPendingStatus(payment.status)) {
        pending++;
      } else if (_isFailedStatus(payment.status)) {
        failed++;
      }

      final createdAt = payment.createdAt;
      if (createdAt != null &&
          (lastPaymentAt == null || createdAt.isAfter(lastPaymentAt))) {
        lastPaymentAt = createdAt;
      }
    }

    return _PaymentStats(
      totalReceived: totalReceived,
      currency: currency,
      successfulCount: successful,
      pendingCount: pending,
      failedCount: failed,
      lastPaymentAt: lastPaymentAt,
    );
  }
}

String _paymentAmount(AdminUserPayment payment) {
  final amount = _formatAmount(payment.amount);
  final currency = payment.currency.trim();
  return currency.isEmpty ? amount : '$currency $amount';
}

String _formatAmount(String rawAmount) {
  return _formatNumber(_parseAmount(rawAmount) ?? rawAmount.trim());
}

String _formatNumber(Object value) {
  if (value is num) {
    return NumberFormat('#,##0.##', 'en_US').format(value);
  }
  final normalized = value.toString().trim();
  if (normalized.isEmpty) {
    return '0';
  }
  final parsed = _parseAmount(normalized);
  if (parsed == null) {
    return normalized;
  }
  return NumberFormat('#,##0.##', 'en_US').format(parsed);
}

num? _parseAmount(String value) {
  final normalized = value.replaceAll(',', '').trim();
  if (normalized.isEmpty) {
    return null;
  }
  return num.tryParse(normalized);
}

bool _isSuccessStatus(String status) {
  final normalized = _normalizeValue(status);
  return normalized == 'SUCCESS' ||
      normalized == 'SUCCEEDED' ||
      normalized == 'PAID' ||
      normalized == 'COMPLETED' ||
      normalized == 'COMPLETE';
}

bool _isFailedStatus(String status) {
  final normalized = _normalizeValue(status);
  return normalized == 'FAILED' ||
      normalized == 'FAILURE' ||
      normalized == 'CANCELLED' ||
      normalized == 'CANCELED' ||
      normalized == 'DECLINED' ||
      normalized == 'REJECTED' ||
      normalized == 'ERROR';
}

bool _isPendingStatus(String status) {
  final normalized = _normalizeValue(status);
  return normalized == 'PENDING' ||
      normalized == 'PROCESSING' ||
      normalized == 'INITIATED' ||
      normalized == 'IN_PROGRESS';
}

Color _statusColor(String status) {
  if (_isSuccessStatus(status)) {
    return OpenVtsColors.success;
  }
  if (_isFailedStatus(status)) {
    return OpenVtsColors.error;
  }
  return OpenVtsColors.warning;
}

String _statusLabel(String value) {
  final normalized = _normalizeValue(value);
  if (normalized.isEmpty) {
    return '-';
  }
  return normalized
      .split('_')
      .map((part) => part.isEmpty
          ? part
          : '${part.substring(0, 1)}${part.substring(1).toLowerCase()}')
      .join(' ');
}

String _normalizeValue(String value) {
  return value.trim().replaceAll('-', '_').replaceAll(' ', '_').toUpperCase();
}

String _dateText(DateTime? value) {
  if (value == null) {
    return '-';
  }
  return _dateFormatter.formatDate(value.toLocal());
}

String _dateTimeText(DateTime? value) {
  if (value == null) {
    return '-';
  }
  return _dateFormatter.formatDateTime(value.toLocal());
}

String _vehicleTitle(AdminUserVehicle vehicle) {
  for (final value in [vehicle.name, vehicle.plateNumber, vehicle.imei]) {
    final normalized = value.trim();
    if (normalized.isNotEmpty && normalized != '-') {
      return normalized;
    }
  }
  return 'Vehicle';
}

String _vehiclePlanName(AdminUserVehicle vehicle) {
  return _mapLabel(vehicle.plan, const [
    'name',
    'planName',
    'plan_name',
    'title',
    'label',
  ]);
}

num? _vehiclePlanPrice(AdminUserVehicle vehicle) {
  return _numberFromMap(vehicle.plan, const [
    'price',
    'amount',
    'planPrice',
    'plan_price',
    'renewalPrice',
    'renewal_price',
    'cost',
  ]);
}

String _estimateForVehicles(List<AdminUserVehicle> vehicles) {
  num total = 0;
  var knownPrices = 0;
  var currency = '';
  for (final vehicle in vehicles) {
    final price = _vehiclePlanPrice(vehicle);
    if (price == null) {
      continue;
    }
    knownPrices++;
    total += price;
    final planCurrency = _mapLabel(vehicle.plan, const [
      'currency',
      'currencyCode',
      'currency_code',
    ]);
    if (currency.isEmpty && planCurrency.isNotEmpty) {
      currency = planCurrency;
    }
  }
  if (knownPrices == 0) {
    return '-';
  }
  final amount = _formatNumber(total);
  return currency.isEmpty ? amount : '$currency $amount';
}

String _mapLabel(Map<String, dynamic> source, List<String> keys) {
  for (final key in keys) {
    final value = _valueForKey(source, key)?.toString().trim();
    if (value != null && value.isNotEmpty && value != '-') {
      return value;
    }
  }
  return '';
}

num? _numberFromMap(Map<String, dynamic> source, List<String> keys) {
  for (final key in keys) {
    final value = _valueForKey(source, key);
    if (value is num) {
      return value;
    }
    final normalized = value?.toString().replaceAll(',', '').trim();
    if (normalized == null || normalized.isEmpty) {
      continue;
    }
    final parsed = num.tryParse(normalized);
    if (parsed != null) {
      return parsed;
    }
  }
  return null;
}

dynamic _valueForKey(Map<String, dynamic> source, String key) {
  if (source.containsKey(key)) {
    return source[key];
  }
  final normalized = key.toLowerCase();
  for (final entry in source.entries) {
    if (entry.key.toLowerCase() == normalized) {
      return entry.value;
    }
  }
  return null;
}

String _displayValue(String value) {
  final normalized = value.trim();
  if (normalized.isEmpty || normalized == '-') {
    return '-';
  }
  return normalized;
}

String _joinParts(List<String> parts) {
  final normalized = parts
      .map((part) => part.trim())
      .where((part) => part.isNotEmpty && part != '-')
      .toList(growable: false);
  if (normalized.isEmpty) {
    return '-';
  }
  return normalized.join(' - ');
}
