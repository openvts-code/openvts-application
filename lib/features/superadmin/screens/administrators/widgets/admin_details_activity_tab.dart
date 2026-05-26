import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../../core/theme/open_vts_colors.dart';
import '../../../../../core/theme/open_vts_radius.dart';
import '../../../../../core/theme/open_vts_spacing.dart';
import '../../../../../core/utils/date_time_formatter.dart';
import '../../../../../shared/helpers/toast_helper.dart';
import '../../../../../shared/widgets/open_vts_button.dart';
import '../../../../../shared/widgets/open_vts_card.dart';
import '../../../../../shared/widgets/open_vts_date_time_range_selector.dart';
import '../../../../../shared/widgets/open_vts_error_view.dart';
import '../../../controllers/superadmin_providers.dart';
import '../../../models/superadmin_admin_details_model.dart';

class AdminDetailsActivityTab extends ConsumerStatefulWidget {
  const AdminDetailsActivityTab({required this.adminId, super.key});

  final String adminId;

  @override
  ConsumerState<AdminDetailsActivityTab> createState() =>
      _AdminDetailsActivityTabState();
}

class _AdminDetailsActivityTabState
    extends ConsumerState<AdminDetailsActivityTab> {
  late final TextEditingController _search;
  Timer? _searchDebounce;

  static const List<_ActionGroup> _groups = [
    _ActionGroup('All', ''),
    _ActionGroup('Security', 'AUTH'),
    _ActionGroup('Settings', 'SETTINGS'),
    _ActionGroup('Billing', 'PAYMENT'),
    _ActionGroup('Vehicles', 'VEHICLE'),
    _ActionGroup('Drivers', 'DRIVER'),
  ];

  @override
  void initState() {
    super.initState();
    final initial = ref
        .read(superadminAdminDetailsControllerProvider(widget.adminId))
        .activitySearch;
    _search = TextEditingController(text: initial);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state =
          ref.read(superadminAdminDetailsControllerProvider(widget.adminId));
      if (state.activityLogs.isEmpty && !state.isLoadingActivity) {
        ref
            .read(superadminAdminDetailsControllerProvider(widget.adminId)
                .notifier)
            .loadActivity();
      }
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    final controller = ref.read(
      superadminAdminDetailsControllerProvider(widget.adminId).notifier,
    );
    controller.setActivitySearch(value);
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      controller.loadActivity();
    });
  }

  void _onActionPrefixChanged(String prefix) {
    final controller = ref.read(
      superadminAdminDetailsControllerProvider(widget.adminId).notifier,
    );
    controller.setActivityActionPrefix(prefix);
    controller.loadActivity();
  }

  Future<void> _onPickDateRange() async {
    final state =
        ref.read(superadminAdminDetailsControllerProvider(widget.adminId));
    final result = await OpenVtsDateTimeRangeSelector.show(
      context: context,
      initialValue: OpenVtsDateTimeRange(
        start: state.activityFrom,
        end: state.activityTo,
      ),
      title: 'Activity date range',
    );
    if (result == null) return;
    final controller = ref.read(
      superadminAdminDetailsControllerProvider(widget.adminId).notifier,
    );
    controller.setActivityDateRange(from: result.start, to: result.end);
    controller.loadActivity();
  }

  void _onClearDateRange() {
    final controller = ref.read(
      superadminAdminDetailsControllerProvider(widget.adminId).notifier,
    );
    controller.setActivityDateRange(from: null, to: null);
    controller.loadActivity();
  }

  void _onResetFilters() {
    final controller = ref.read(
      superadminAdminDetailsControllerProvider(widget.adminId).notifier,
    );
    _search.clear();
    controller.setActivitySearch('');
    controller.setActivityActionPrefix('');
    controller.setActivityDateRange(from: null, to: null);
    controller.loadActivity();
  }

  void _openDetailSheet(SuperadminAdminActivityLog log) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: OpenVtsColors.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ActivityDetailSheet(log: log),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state =
        ref.watch(superadminAdminDetailsControllerProvider(widget.adminId));

    final hasDateRange = state.activityFrom != null || state.activityTo != null;
    final hasAnyFilter = _search.text.isNotEmpty ||
        state.activityActionPrefix.isNotEmpty ||
        hasDateRange;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SearchField(controller: _search, onChanged: _onSearchChanged),
        const SizedBox(height: OpenVtsSpacing.sm),
        _GroupChips(
          groups: _groups,
          selected: state.activityActionPrefix,
          onChanged: _onActionPrefixChanged,
        ),
        const SizedBox(height: OpenVtsSpacing.sm),
        _DateRangeRow(
          from: state.activityFrom,
          to: state.activityTo,
          onPick: _onPickDateRange,
          onClear: _onClearDateRange,
        ),
        if (hasAnyFilter) ...[
          const SizedBox(height: OpenVtsSpacing.xs),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: _onResetFilters,
              icon: const Icon(Icons.refresh, size: 14),
              label: const Text('Reset filters'),
              style: TextButton.styleFrom(
                foregroundColor: OpenVtsColors.textSecondary,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: const Size(0, 28),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                textStyle: const TextStyle(fontSize: 12),
              ),
            ),
          ),
        ],
        const SizedBox(height: OpenVtsSpacing.md),
        if (state.sectionErrorMessage != null && state.activityLogs.isEmpty)
          OpenVtsCard(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: OpenVtsSpacing.md),
              child: OpenVtsErrorView(
                message: state.sectionErrorMessage!,
                onRetry: () => ref
                    .read(superadminAdminDetailsControllerProvider(
                            widget.adminId)
                        .notifier)
                    .loadActivity(),
              ),
            ),
          )
        else if (state.activityLogs.isEmpty)
          const OpenVtsCard(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: OpenVtsSpacing.lg),
              child: Center(
                child: Text(
                  'No activity yet.',
                  style: TextStyle(
                    fontSize: 12,
                    color: OpenVtsColors.textSecondary,
                  ),
                ),
              ),
            ),
          )
        else
          Column(
            children: [
              for (final log in state.activityLogs) ...[
                _ActivityCard(log: log, onTap: () => _openDetailSheet(log)),
                const SizedBox(height: OpenVtsSpacing.xs),
              ],
              if (state.activityHasMore) ...[
                const SizedBox(height: OpenVtsSpacing.xs),
                OpenVtsButton(
                  label: 'Load more',
                  variant: OpenVtsButtonVariant.secondary,
                  isLoading: state.isLoadingMoreActivity,
                  onPressed: () => ref
                      .read(superadminAdminDetailsControllerProvider(
                              widget.adminId)
                          .notifier)
                      .loadMoreActivity(),
                ),
              ],
            ],
          ),
      ],
    );
  }
}

class _ActionGroup {
  const _ActionGroup(this.label, this.prefix);
  final String label;
  final String prefix;
}

// ---------------------------------------------------------------------------
// Filter widgets
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
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        hintText: 'Search activity…',
        prefixIcon: const Icon(
          Icons.search,
          size: 18,
          color: OpenVtsColors.textTertiary,
        ),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                splashRadius: 16,
                iconSize: 16,
                icon: const Icon(
                  Icons.close,
                  color: OpenVtsColors.textTertiary,
                ),
                onPressed: () {
                  controller.clear();
                  onChanged('');
                },
              ),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        filled: true,
        fillColor: OpenVtsColors.surface,
        hintStyle: const TextStyle(
          fontSize: 13,
          color: OpenVtsColors.textTertiary,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(OpenVtsRadius.md),
          borderSide: const BorderSide(color: OpenVtsColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(OpenVtsRadius.md),
          borderSide: const BorderSide(color: OpenVtsColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(OpenVtsRadius.md),
          borderSide: const BorderSide(color: OpenVtsColors.brandInk),
        ),
      ),
    );
  }
}

class _GroupChips extends StatelessWidget {
  const _GroupChips({
    required this.groups,
    required this.selected,
    required this.onChanged,
  });

  final List<_ActionGroup> groups;
  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 32,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: groups.length,
        separatorBuilder: (_, __) => const SizedBox(width: OpenVtsSpacing.xs),
        itemBuilder: (_, index) {
          final g = groups[index];
          final isActive = g.prefix == selected;
          return InkWell(
            borderRadius: BorderRadius.circular(OpenVtsRadius.pill),
            onTap: () => onChanged(g.prefix),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: isActive
                    ? OpenVtsColors.brandInk
                    : OpenVtsColors.surface,
                borderRadius: BorderRadius.circular(OpenVtsRadius.pill),
                border: Border.all(
                  color: isActive
                      ? OpenVtsColors.brandInk
                      : OpenVtsColors.border,
                ),
              ),
              child: Text(
                g.label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isActive
                      ? OpenVtsColors.white
                      : OpenVtsColors.textSecondary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DateRangeRow extends StatelessWidget {
  const _DateRangeRow({
    required this.from,
    required this.to,
    required this.onPick,
    required this.onClear,
  });

  final DateTime? from;
  final DateTime? to;
  final VoidCallback onPick;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final formatter = const DateTimeFormatter();
    String? label;
    if (from != null && to != null) {
      label =
          '${formatter.formatDate(from!.toLocal())} – ${formatter.formatDate(to!.toLocal())}';
    } else if (from != null) {
      label = 'From ${formatter.formatDate(from!.toLocal())}';
    } else if (to != null) {
      label = 'Until ${formatter.formatDate(to!.toLocal())}';
    }

    return Row(
      children: [
        Expanded(
          child: InkWell(
            borderRadius: BorderRadius.circular(OpenVtsRadius.md),
            onTap: onPick,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: OpenVtsColors.surface,
                borderRadius: BorderRadius.circular(OpenVtsRadius.md),
                border: Border.all(color: OpenVtsColors.border),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_month_outlined,
                    size: 16,
                    color: OpenVtsColors.textSecondary,
                  ),
                  const SizedBox(width: OpenVtsSpacing.xs),
                  Expanded(
                    child: Text(
                      label ?? 'Select date range',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: label == null
                            ? OpenVtsColors.textTertiary
                            : OpenVtsColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (from != null || to != null) ...[
          const SizedBox(width: OpenVtsSpacing.xs),
          IconButton(
            splashRadius: 16,
            iconSize: 16,
            icon: const Icon(
              Icons.close,
              color: OpenVtsColors.textTertiary,
            ),
            onPressed: onClear,
            tooltip: 'Clear date range',
          ),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Activity card
// ---------------------------------------------------------------------------

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({required this.log, required this.onTap});

  final SuperadminAdminActivityLog log;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final action = _humanizeAction(log.action);
    final icon = _iconForAction(log.action);
    final timeLabel = _formatRelative(log.createdAt);
    final entityLabel = _formatEntity(log.entity, log.entityId);
    final performedBy = log.user?.name.isNotEmpty == true
        ? log.user!.name
        : (log.user?.email.isNotEmpty == true ? log.user!.email : null);
    final platformLine = _platformLine(log);

    return OpenVtsCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(
        horizontal: OpenVtsSpacing.md,
        vertical: OpenVtsSpacing.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: OpenVtsColors.surface,
              borderRadius: BorderRadius.circular(OpenVtsRadius.sm),
              border: Border.all(color: OpenVtsColors.border),
            ),
            alignment: Alignment.center,
            child: Icon(
              icon,
              size: 16,
              color: OpenVtsColors.textSecondary,
            ),
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
                        action,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: OpenVtsColors.textPrimary,
                        ),
                      ),
                    ),
                    if (timeLabel != null) ...[
                      const SizedBox(width: OpenVtsSpacing.xs),
                      Text(
                        timeLabel,
                        style: const TextStyle(
                          fontSize: 11,
                          color: OpenVtsColors.textTertiary,
                        ),
                      ),
                    ],
                  ],
                ),
                if (entityLabel != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    entityLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: OpenVtsColors.textSecondary,
                    ),
                  ),
                ],
                if (performedBy != null) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(
                        Icons.person_outline,
                        size: 12,
                        color: OpenVtsColors.textTertiary,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          performedBy,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            color: OpenVtsColors.textTertiary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                if (platformLine != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    platformLine,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: OpenVtsColors.textTertiary,
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
// Detail sheet
// ---------------------------------------------------------------------------

class _ActivityDetailSheet extends StatelessWidget {
  const _ActivityDetailSheet({required this.log});

  final SuperadminAdminActivityLog log;

  @override
  Widget build(BuildContext context) {
    const formatter = DateTimeFormatter();
    final timeLabel = log.createdAt != null
        ? formatter.formatDateTime(log.createdAt!.toLocal())
        : null;
    final entityLabel = _formatEntity(log.entity, log.entityId);
    final performedBy = log.user?.name.isNotEmpty == true
        ? log.user!.name
        : (log.user?.email.isNotEmpty == true ? log.user!.email : null);

    final metaJson = log.meta.isEmpty
        ? null
        : const JsonEncoder.withIndent('  ').convert(log.meta);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollController) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(
            OpenVtsSpacing.lg,
            OpenVtsSpacing.sm,
            OpenVtsSpacing.lg,
            OpenVtsSpacing.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: OpenVtsColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: OpenVtsSpacing.md),
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: OpenVtsColors.surface,
                      borderRadius: BorderRadius.circular(OpenVtsRadius.sm),
                      border: Border.all(color: OpenVtsColors.border),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      _iconForAction(log.action),
                      size: 18,
                      color: OpenVtsColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: OpenVtsSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _humanizeAction(log.action),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: OpenVtsColors.textPrimary,
                          ),
                        ),
                        if (timeLabel != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            timeLabel,
                            style: const TextStyle(
                              fontSize: 12,
                              color: OpenVtsColors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: OpenVtsSpacing.md),
              const Divider(height: 1, color: OpenVtsColors.border),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding:
                      const EdgeInsets.symmetric(vertical: OpenVtsSpacing.md),
                  children: [
                    if (entityLabel != null)
                      _DetailRow(label: 'Entity', value: entityLabel),
                    if (log.entityId.isNotEmpty)
                      _DetailRow(label: 'Entity ID', value: log.entityId),
                    if (log.ip.isNotEmpty)
                      _DetailRow(label: 'IP', value: log.ip),
                    if (log.browser.isNotEmpty)
                      _DetailRow(label: 'Browser', value: log.browser),
                    if (log.platform.isNotEmpty)
                      _DetailRow(label: 'Platform', value: log.platform),
                    if (performedBy != null)
                      _DetailRow(label: 'Performed by', value: performedBy),
                    if (log.user?.email.isNotEmpty == true &&
                        log.user!.email != performedBy)
                      _DetailRow(label: 'Email', value: log.user!.email),
                    if (metaJson != null) ...[
                      const SizedBox(height: OpenVtsSpacing.md),
                      Row(
                        children: [
                          const Text(
                            'Metadata',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: OpenVtsColors.textSecondary,
                            ),
                          ),
                          const Spacer(),
                          TextButton.icon(
                            onPressed: () async {
                              await Clipboard.setData(
                                ClipboardData(text: metaJson),
                              );
                              if (!context.mounted) return;
                              ToastHelper.showSuccess(
                                'Metadata copied',
                                context: context,
                              );
                            },
                            icon: const Icon(Icons.copy, size: 14),
                            label: const Text('Copy'),
                            style: TextButton.styleFrom(
                              foregroundColor: OpenVtsColors.textSecondary,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              minimumSize: const Size(0, 28),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              textStyle: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: OpenVtsSpacing.xs),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(OpenVtsSpacing.sm),
                        decoration: BoxDecoration(
                          color: OpenVtsColors.surface,
                          borderRadius:
                              BorderRadius.circular(OpenVtsRadius.sm),
                          border: Border.all(color: OpenVtsColors.border),
                        ),
                        child: SelectableText(
                          metaJson,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11,
                            height: 1.4,
                            color: OpenVtsColors.textPrimary,
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
      },
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 108,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: OpenVtsColors.textTertiary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                color: OpenVtsColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

String _humanizeAction(String action) {
  if (action.trim().isEmpty) return 'Activity';
  final parts = action.split(RegExp(r'[._:/]'));
  return parts
      .where((p) => p.isNotEmpty)
      .map(_titleCase)
      .join(' · ');
}

String _titleCase(String value) {
  final lower = value.toLowerCase();
  if (lower.isEmpty) return lower;
  return lower[0].toUpperCase() + lower.substring(1);
}

IconData _iconForAction(String action) {
  final upper = action.toUpperCase();
  if (upper.contains('LOGIN') ||
      upper.contains('LOGOUT') ||
      upper.contains('AUTH')) {
    return Icons.login;
  }
  if (upper.contains('DELETE') || upper.contains('REMOVE')) {
    return Icons.delete_outline;
  }
  if (upper.contains('CREATE') || upper.contains('ADD')) {
    return Icons.add_circle_outline;
  }
  if (upper.contains('UPDATE') ||
      upper.contains('EDIT') ||
      upper.contains('PATCH')) {
    return Icons.edit_outlined;
  }
  if (upper.contains('CREDIT')) {
    return Icons.credit_card;
  }
  if (upper.contains('PAYMENT') ||
      upper.contains('BILLING') ||
      upper.contains('RENEW')) {
    return Icons.account_balance_wallet_outlined;
  }
  if (upper.contains('SETTING') || upper.contains('CONFIG')) {
    return Icons.settings_outlined;
  }
  if (upper.contains('PASSWORD') || upper.contains('KEY')) {
    return Icons.vpn_key_outlined;
  }
  return Icons.bolt_outlined;
}

String? _formatEntity(String entity, String entityId) {
  final e = entity.trim();
  final id = entityId.trim();
  if (e.isEmpty && id.isEmpty) return null;
  if (e.isEmpty) return id;
  if (id.isEmpty) return _titleCase(e);
  return '${_titleCase(e)} • $id';
}

String? _platformLine(SuperadminAdminActivityLog log) {
  final parts = <String>[];
  if (log.platform.isNotEmpty) parts.add(log.platform);
  if (log.browser.isNotEmpty) parts.add(_shortBrowser(log.browser));
  if (log.ip.isNotEmpty) parts.add(log.ip);
  if (parts.isEmpty) return null;
  return parts.join(' • ');
}

String _shortBrowser(String value) {
  final v = value.trim();
  if (v.isEmpty) return v;
  if (v.length <= 48) return v;
  return '${v.substring(0, 45)}…';
}

String? _formatRelative(DateTime? value) {
  if (value == null) return null;
  final now = DateTime.now();
  final diff = now.difference(value.toLocal());
  if (diff.inSeconds < 60 && diff.inSeconds >= 0) return 'just now';
  if (diff.inMinutes < 60 && diff.inMinutes >= 0) {
    return '${diff.inMinutes}m ago';
  }
  if (diff.inHours < 24 && diff.inHours >= 0) {
    return '${diff.inHours}h ago';
  }
  if (diff.inDays < 7 && diff.inDays >= 0) {
    return '${diff.inDays}d ago';
  }
  return DateFormat('dd MMM yyyy').format(value.toLocal());
}
