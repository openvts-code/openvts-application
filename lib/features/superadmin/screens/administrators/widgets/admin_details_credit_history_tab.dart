import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/open_vts_colors.dart';
import '../../../../../core/theme/open_vts_radius.dart';
import '../../../../../core/theme/open_vts_spacing.dart';
import '../../../../../core/utils/date_time_formatter.dart';
import '../../../../../shared/helpers/toast_helper.dart';
import '../../../../../shared/widgets/open_vts_button.dart';
import '../../../../../shared/widgets/open_vts_card.dart';
import '../../../../../shared/widgets/open_vts_error_view.dart';
import '../../../../../shared/widgets/open_vts_loader.dart';
import '../../../../../shared/widgets/open_vts_text_field.dart';
import '../../../controllers/superadmin_admin_details_controller.dart';
import '../../../controllers/superadmin_providers.dart';
import '../../../models/superadmin_admin_details_model.dart';

class AdminDetailsCreditHistoryTab extends ConsumerStatefulWidget {
  const AdminDetailsCreditHistoryTab({required this.adminId, super.key});

  final String adminId;

  @override
  ConsumerState<AdminDetailsCreditHistoryTab> createState() =>
      _AdminDetailsCreditHistoryTabState();
}

class _AdminDetailsCreditHistoryTabState
    extends ConsumerState<AdminDetailsCreditHistoryTab> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider =
          superadminAdminDetailsControllerProvider(widget.adminId);
      final state = ref.read(provider);
      if (state.creditLogs.isEmpty && !state.isLoadingCredits) {
        ref.read(provider.notifier).loadCreditLogs();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider =
        superadminAdminDetailsControllerProvider(widget.adminId);
    final state = ref.watch(provider);
    final controller = ref.read(provider.notifier);
    final admin = state.admin;

    if (state.isLoadingCredits && state.creditLogs.isEmpty) {
      return const OpenVtsCard(
        padding: EdgeInsets.symmetric(vertical: OpenVtsSpacing.lg),
        child: Center(child: OpenVtsLoader()),
      );
    }

    if (state.sectionErrorMessage != null && state.creditLogs.isEmpty) {
      return OpenVtsCard(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: OpenVtsSpacing.md),
          child: OpenVtsErrorView(
            message: state.sectionErrorMessage!,
            onRetry: controller.loadCreditLogs,
          ),
        ),
      );
    }

    final currentCredits = admin?.credits ?? 0;
    final logs = state.creditLogs;
    final enriched = _computeBalances(logs, currentCredits);
    final filtered = _applyFilter(enriched, _query);

    final addedCount = logs
        .where((l) => l.activity == SuperadminCreditActivity.assign)
        .length;
    final deductedCount = logs
        .where((l) => l.activity == SuperadminCreditActivity.deduct)
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SummaryGrid(
          currentCredits: currentCredits,
          totalLogs: logs.length,
          addedCount: addedCount,
          deductedCount: deductedCount,
        ),
        const SizedBox(height: OpenVtsSpacing.sm),
        _ActionRow(
          isBusy: state.isUpdatingCredits,
          currentCredits: currentCredits,
          onAdd: () => _openAssignSheet(
            context: context,
            controller: controller,
            activity: SuperadminCreditActivity.assign,
            currentCredits: currentCredits,
          ),
          onDeduct: () => _openAssignSheet(
            context: context,
            controller: controller,
            activity: SuperadminCreditActivity.deduct,
            currentCredits: currentCredits,
          ),
        ),
        const SizedBox(height: OpenVtsSpacing.sm),
        _SearchField(
          controller: _searchController,
          onChanged: (value) => setState(() => _query = value.trim()),
        ),
        const SizedBox(height: OpenVtsSpacing.sm),
        if (logs.isEmpty)
          const _EmptyState(message: 'No credit history yet.')
        else if (filtered.isEmpty)
          const _EmptyState(message: 'No matches for your search.')
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filtered.length,
            separatorBuilder: (_, __) =>
                const SizedBox(height: OpenVtsSpacing.xs),
            itemBuilder: (context, index) {
              return _CreditLogCard(entry: filtered[index]);
            },
          ),
      ],
    );
  }

  Future<void> _openAssignSheet({
    required BuildContext context,
    required SuperadminAdminDetailsController controller,
    required SuperadminCreditActivity activity,
    required int currentCredits,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: OpenVtsColors.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return _AssignCreditsSheet(
          adminId: widget.adminId,
          activity: activity,
          currentCredits: currentCredits,
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Computed entries
// ---------------------------------------------------------------------------

class _CreditEntry {
  const _CreditEntry({required this.log, required this.balanceAfter});

  final SuperadminCreditLog log;
  final int balanceAfter;
}

List<_CreditEntry> _computeBalances(
  List<SuperadminCreditLog> logs,
  int currentCredits,
) {
  final result = <_CreditEntry>[];
  var running = currentCredits;
  for (final log in logs) {
    result.add(_CreditEntry(log: log, balanceAfter: running));
    if (log.activity == SuperadminCreditActivity.assign) {
      running = running - log.credits;
    } else if (log.activity == SuperadminCreditActivity.deduct) {
      running = running + log.credits;
    }
  }
  return result;
}

List<_CreditEntry> _applyFilter(List<_CreditEntry> entries, String query) {
  if (query.isEmpty) return entries;
  const fmt = DateTimeFormatter();
  final q = query.toLowerCase();
  return entries.where((entry) {
    final log = entry.log;
    final date = log.createdAt != null
        ? fmt.formatDateTime(log.createdAt!).toLowerCase()
        : '';
    final activityLabel = _activityDisplay(log.activity).toLowerCase();
    return date.contains(q) ||
        activityLabel.contains(q) ||
        log.credits.toString().contains(q) ||
        entry.balanceAfter.toString().contains(q) ||
        log.vehicleId.toLowerCase().contains(q) ||
        log.id.toLowerCase().contains(q);
  }).toList(growable: false);
}

String _activityDisplay(SuperadminCreditActivity activity) {
  switch (activity) {
    case SuperadminCreditActivity.assign:
      return 'Added';
    case SuperadminCreditActivity.deduct:
      return 'Used';
    case SuperadminCreditActivity.unknown:
      return 'Unknown';
  }
}

// ---------------------------------------------------------------------------
// Summary
// ---------------------------------------------------------------------------

class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid({
    required this.currentCredits,
    required this.totalLogs,
    required this.addedCount,
    required this.deductedCount,
  });

  final int currentCredits;
  final int totalLogs;
  final int addedCount;
  final int deductedCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SummaryTile(
            label: 'Current credits',
            value: currentCredits.toString(),
            icon: Icons.account_balance_wallet_outlined,
          ),
        ),
        const SizedBox(width: OpenVtsSpacing.xs),
        Expanded(
          child: _SummaryTile(
            label: 'Total logs',
            value: totalLogs.toString(),
            icon: Icons.receipt_long_outlined,
          ),
        ),
        const SizedBox(width: OpenVtsSpacing.xs),
        Expanded(
          child: _SummaryTile(
            label: 'Added',
            value: addedCount.toString(),
            icon: Icons.add_circle_outline,
          ),
        ),
        const SizedBox(width: OpenVtsSpacing.xs),
        Expanded(
          child: _SummaryTile(
            label: 'Deducted',
            value: deductedCount.toString(),
            icon: Icons.remove_circle_outline,
          ),
        ),
      ],
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return OpenVtsCard(
      padding: const EdgeInsets.symmetric(
        horizontal: OpenVtsSpacing.xs,
        vertical: OpenVtsSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: OpenVtsColors.textSecondary),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: OpenVtsColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: OpenVtsColors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Action row
// ---------------------------------------------------------------------------

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.isBusy,
    required this.currentCredits,
    required this.onAdd,
    required this.onDeduct,
  });

  final bool isBusy;
  final int currentCredits;
  final VoidCallback onAdd;
  final VoidCallback onDeduct;

  @override
  Widget build(BuildContext context) {
    final canDeduct = currentCredits > 0;
    return Row(
      children: [
        Expanded(
          child: OpenVtsButton(
            label: 'Add credits',
            onPressed: isBusy ? null : onAdd,
          ),
        ),
        const SizedBox(width: OpenVtsSpacing.xs),
        Expanded(
          child: OpenVtsButton(
            label: 'Deduct credits',
            variant: OpenVtsButtonVariant.secondary,
            onPressed: (!canDeduct || isBusy) ? null : onDeduct,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Search
// ---------------------------------------------------------------------------

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: const TextStyle(fontSize: 13, color: OpenVtsColors.textPrimary),
      decoration: InputDecoration(
        isDense: true,
        hintText: 'Search by date, activity, credits, vehicle…',
        hintStyle: const TextStyle(
          fontSize: 12,
          color: OpenVtsColors.textTertiary,
        ),
        prefixIcon: const Icon(
          Icons.search,
          size: 18,
          color: OpenVtsColors.textSecondary,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: OpenVtsSpacing.sm,
          vertical: OpenVtsSpacing.sm,
        ),
        filled: true,
        fillColor: OpenVtsColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(OpenVtsRadius.sm),
          borderSide: const BorderSide(color: OpenVtsColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(OpenVtsRadius.sm),
          borderSide: const BorderSide(color: OpenVtsColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(OpenVtsRadius.sm),
          borderSide: const BorderSide(color: OpenVtsColors.brandInk),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Log card
// ---------------------------------------------------------------------------

class _CreditLogCard extends StatelessWidget {
  const _CreditLogCard({required this.entry});

  final _CreditEntry entry;

  @override
  Widget build(BuildContext context) {
    final log = entry.log;
    final isAdd = log.activity == SuperadminCreditActivity.assign;
    final activityLabel = _activityDisplay(log.activity);
    final icon =
        isAdd ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded;
    final sign = isAdd ? '+' : '−';
    const fmt = DateTimeFormatter();
    final dateLabel = log.createdAt != null
        ? fmt.formatDateTime(log.createdAt!)
        : '—';

    return OpenVtsCard(
      padding: const EdgeInsets.fromLTRB(
        OpenVtsSpacing.sm,
        OpenVtsSpacing.sm,
        OpenVtsSpacing.sm,
        OpenVtsSpacing.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: OpenVtsColors.surface,
              borderRadius: BorderRadius.circular(OpenVtsRadius.sm),
              border: Border.all(color: OpenVtsColors.border),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 16, color: OpenVtsColors.textPrimary),
          ),
          const SizedBox(width: OpenVtsSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        activityLabel,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: OpenVtsColors.textPrimary,
                        ),
                      ),
                    ),
                    Text(
                      '$sign${log.credits}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: OpenVtsColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        dateLabel,
                        style: const TextStyle(
                          fontSize: 11,
                          color: OpenVtsColors.textSecondary,
                        ),
                      ),
                    ),
                    Text(
                      'Balance ${entry.balanceAfter}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: OpenVtsColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                if (log.vehicleId.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: OpenVtsColors.surface,
                      borderRadius: BorderRadius.circular(OpenVtsRadius.sm),
                      border: Border.all(color: OpenVtsColors.border),
                    ),
                    child: Text(
                      'Vehicle ${log.vehicleId}',
                      style: const TextStyle(
                        fontSize: 10,
                        color: OpenVtsColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty state
// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return OpenVtsCard(
      padding: const EdgeInsets.symmetric(vertical: OpenVtsSpacing.lg),
      child: Center(
        child: Text(
          message,
          style: const TextStyle(
            fontSize: 12,
            color: OpenVtsColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Assign / Deduct credits bottom sheet
// ---------------------------------------------------------------------------

class _AssignCreditsSheet extends ConsumerStatefulWidget {
  const _AssignCreditsSheet({
    required this.adminId,
    required this.activity,
    required this.currentCredits,
  });

  final String adminId;
  final SuperadminCreditActivity activity;
  final int currentCredits;

  @override
  ConsumerState<_AssignCreditsSheet> createState() =>
      _AssignCreditsSheetState();
}

class _AssignCreditsSheetState extends ConsumerState<_AssignCreditsSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _credits = TextEditingController();

  @override
  void dispose() {
    _credits.dispose();
    super.dispose();
  }

  bool get _isAdd => widget.activity == SuperadminCreditActivity.assign;

  String get _title => _isAdd ? 'Add credits' : 'Deduct credits';

  String get _submitLabel => _isAdd ? 'Add credits' : 'Deduct credits';

  String? _validate(String? value) {
    final raw = value?.trim() ?? '';
    if (raw.isEmpty) return 'Enter a credit amount.';
    final parsed = int.tryParse(raw);
    if (parsed == null) return 'Credits must be an integer.';
    if (parsed <= 0) return 'Credits must be greater than zero.';
    if (!_isAdd && parsed > widget.currentCredits) {
      return 'Cannot deduct more than ${widget.currentCredits}.';
    }
    return null;
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final provider =
        superadminAdminDetailsControllerProvider(widget.adminId);
    final controller = ref.read(provider.notifier);
    final ok = await controller.updateCredits(
      SuperadminCreditUpdateRequest(
        credits: _credits.text.trim(),
        activity: widget.activity,
      ),
    );
    if (!mounted) return;
    if (ok) {
      ToastHelper.showSuccess(
        _isAdd ? 'Credits added.' : 'Credits deducted.',
        context: context,
      );
      Navigator.of(context).maybePop();
    } else {
      final message =
          ref.read(provider).sectionErrorMessage ?? 'Failed to update credits.';
      ToastHelper.showError(message, context: context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider =
        superadminAdminDetailsControllerProvider(widget.adminId);
    final isLoading = ref.watch(
      provider.select((s) => s.isUpdatingCredits),
    );
    final viewInsets = MediaQuery.of(context).viewInsets;

    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _CreditSheetHeader(title: _title),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  OpenVtsSpacing.md,
                  OpenVtsSpacing.sm,
                  OpenVtsSpacing.md,
                  OpenVtsSpacing.sm,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _InfoTile(
                        label: 'Current credits',
                        value: widget.currentCredits.toString(),
                      ),
                      const SizedBox(height: OpenVtsSpacing.sm),
                      OpenVtsTextField(
                        label: 'Credits',
                        controller: _credits,
                        hintText: 'Enter credit amount',
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.done,
                        validator: _validate,
                        prefixIcon: _isAdd
                            ? Icons.add_circle_outline
                            : Icons.remove_circle_outline,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            _CreditSheetFooter(
              isLoading: isLoading,
              submitLabel: _submitLabel,
              onCancel: () => Navigator.of(context).maybePop(),
              onSubmit: _submit,
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: OpenVtsSpacing.sm,
        vertical: OpenVtsSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: OpenVtsColors.surface,
        borderRadius: BorderRadius.circular(OpenVtsRadius.sm),
        border: Border.all(color: OpenVtsColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: OpenVtsColors.textSecondary,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: OpenVtsColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Local sheet chrome (mirrors profile tab's private widgets)
// ---------------------------------------------------------------------------

class _CreditSheetHeader extends StatelessWidget {
  const _CreditSheetHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        OpenVtsSpacing.md,
        OpenVtsSpacing.sm,
        OpenVtsSpacing.xs,
        0,
      ),
      child: Column(
        children: [
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(top: 6, bottom: OpenVtsSpacing.sm),
            decoration: BoxDecoration(
              color: OpenVtsColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: OpenVtsColors.textPrimary,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 20),
                onPressed: () => Navigator.of(context).maybePop(),
                tooltip: 'Close',
              ),
            ],
          ),
          const Divider(height: 1, color: OpenVtsColors.border),
        ],
      ),
    );
  }
}

class _CreditSheetFooter extends StatelessWidget {
  const _CreditSheetFooter({
    required this.isLoading,
    required this.onCancel,
    required this.onSubmit,
    required this.submitLabel,
  });

  final bool isLoading;
  final VoidCallback onCancel;
  final VoidCallback onSubmit;
  final String submitLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: OpenVtsColors.border)),
        color: OpenVtsColors.surfaceElevated,
      ),
      padding: const EdgeInsets.fromLTRB(
        OpenVtsSpacing.md,
        OpenVtsSpacing.sm,
        OpenVtsSpacing.md,
        OpenVtsSpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: OpenVtsButton(
              label: 'Cancel',
              variant: OpenVtsButtonVariant.secondary,
              onPressed: isLoading ? null : onCancel,
            ),
          ),
          const SizedBox(width: OpenVtsSpacing.sm),
          Expanded(
            child: OpenVtsButton(
              label: submitLabel,
              isLoading: isLoading,
              onPressed: isLoading ? null : onSubmit,
            ),
          ),
        ],
      ),
    );
  }
}

