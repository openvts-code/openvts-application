import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../../core/theme/open_vts_colors.dart';
import '../../../../../core/theme/open_vts_radius.dart';
import '../../../../../core/theme/open_vts_spacing.dart';
import '../../../../../core/theme/open_vts_typography.dart';
import '../../../../../core/utils/date_time_formatter.dart';
import '../../../../../shared/widgets/open_vts_bottom_sheet.dart';
import '../../../../../shared/widgets/open_vts_button.dart';
import '../../../../../shared/widgets/open_vts_card.dart';
import '../../../../../shared/widgets/open_vts_date_time_range_selector.dart';
import '../../../controllers/admin_providers.dart';
import '../../../models/admin_user_details_model.dart';

const DateTimeFormatter _dateFormatter = DateTimeFormatter();
const List<_ActionGroup> _actionGroups = <_ActionGroup>[
  _ActionGroup('All', ''),
  _ActionGroup('Security', 'AUTH'),
  _ActionGroup('Settings', 'SETTINGS'),
  _ActionGroup('Billing', 'PAYMENT'),
  _ActionGroup('Vehicles', 'VEHICLE'),
  _ActionGroup('Drivers', 'DRIVER'),
];

class AdminUserLogsTab extends ConsumerStatefulWidget {
  const AdminUserLogsTab({
    super.key,
    required this.userId,
  });

  final String userId;

  @override
  ConsumerState<AdminUserLogsTab> createState() => _AdminUserLogsTabState();
}

class _AdminUserLogsTabState extends ConsumerState<AdminUserLogsTab> {
  late final TextEditingController _searchController;
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    final state = ref.read(adminUserDetailsControllerProvider(widget.userId));
    _searchController = TextEditingController(text: state.logSearch);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = adminUserDetailsControllerProvider(widget.userId);
    final state = ref.watch(provider);
    final controller = ref.read(provider.notifier);
    final hasDateRange = state.logFrom != null || state.logTo != null;
    final hasFilters = state.logSearch.trim().isNotEmpty ||
        state.logActionPrefix.trim().isNotEmpty ||
        hasDateRange;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SearchField(
          controller: _searchController,
          onChanged: _onSearchChanged,
        ),
        const SizedBox(height: OpenVtsSpacing.sm),
        _ActionGroupChips(
          selected: state.logActionPrefix,
          onChanged: _onActionGroupChanged,
        ),
        const SizedBox(height: OpenVtsSpacing.sm),
        OpenVtsDateTimeRangeField(
          label: 'Date range',
          title: 'Activity date range',
          hintText: 'Select date range',
          dateTimeEnabled: true,
          value: OpenVtsDateTimeRange(
            start: state.logFrom,
            end: state.logTo,
          ),
          onChanged: _onDateRangeChanged,
        ),
        if (hasFilters) ...[
          const SizedBox(height: OpenVtsSpacing.xs),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: _resetFilters,
              icon: const Icon(Icons.refresh_rounded, size: 14),
              label: const Text('Reset filters'),
              style: TextButton.styleFrom(
                foregroundColor: OpenVtsColors.textSecondary,
                minimumSize: const Size(0, 30),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
        ],
        const SizedBox(height: OpenVtsSpacing.sm),
        if (state.isLoadingLogs && state.logs.isEmpty)
          const _SectionLoader(title: 'Logs')
        else if (state.sectionErrorMessage != null && state.logs.isEmpty)
          _SectionErrorCard(
            message: state.sectionErrorMessage!,
            onRetry: controller.loadLogs,
          )
        else if (state.logs.isEmpty)
          const _EmptyCard(label: 'No logs found')
        else ...[
          if (state.sectionErrorMessage != null) ...[
            _InlineError(message: state.sectionErrorMessage!),
            const SizedBox(height: OpenVtsSpacing.sm),
          ],
          for (final log in state.logs) ...[
            _LogCard(log: log, onTap: () => _showLogDetails(log)),
            if (log != state.logs.last)
              const SizedBox(height: OpenVtsSpacing.sm),
          ],
          if (state.logsHasMore) ...[
            const SizedBox(height: OpenVtsSpacing.sm),
            OpenVtsButton(
              label: 'Load More',
              height: 38,
              variant: OpenVtsButtonVariant.secondary,
              isLoading: state.isLoadingMoreLogs,
              onPressed: state.isLoadingMoreLogs
                  ? null
                  : () => controller.loadMoreLogs(),
            ),
          ],
        ],
      ],
    );
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    final controller = ref.read(
      adminUserDetailsControllerProvider(widget.userId).notifier,
    );
    controller.setLogFilters(q: value);
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      controller.loadLogs();
    });
  }

  void _onActionGroupChanged(String prefix) {
    final controller = ref.read(
      adminUserDetailsControllerProvider(widget.userId).notifier,
    );
    controller.setLogFilters(actionPrefix: prefix);
    controller.loadLogs();
  }

  void _onDateRangeChanged(OpenVtsDateTimeRange range) {
    final controller = ref.read(
      adminUserDetailsControllerProvider(widget.userId).notifier,
    );
    controller.setLogFilters(
      from: range.start,
      to: range.end,
      clearFrom: range.start == null,
      clearTo: range.end == null,
    );
    controller.loadLogs();
  }

  void _resetFilters() {
    _searchDebounce?.cancel();
    _searchController.clear();
    final controller = ref.read(
      adminUserDetailsControllerProvider(widget.userId).notifier,
    );
    controller.setLogFilters(
      q: '',
      actionPrefix: '',
      clearFrom: true,
      clearTo: true,
    );
    controller.loadLogs();
  }

  Future<void> _showLogDetails(AdminUserActivityLog log) {
    return OpenVtsBottomSheet.show<void>(
      context: context,
      title: 'Activity Detail',
      initialChildSize: 0.74,
      minChildSize: 0.46,
      maxChildSize: 0.94,
      child: _LogDetailSheet(log: log),
    );
  }
}

class _ActionGroup {
  const _ActionGroup(this.label, this.prefix);

  final String label;
  final String prefix;
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      style: OpenVtsTypography.body.copyWith(fontSize: 13),
      decoration: InputDecoration(
        hintText: 'Search logs',
        prefixIcon: const Icon(
          Icons.search_rounded,
          size: 18,
          color: OpenVtsColors.textSecondary,
        ),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                tooltip: 'Clear search',
                onPressed: () {
                  controller.clear();
                  onChanged('');
                },
                icon: const Icon(Icons.close_rounded, size: 17),
              ),
      ),
    );
  }
}

class _ActionGroupChips extends StatelessWidget {
  const _ActionGroupChips({required this.selected, required this.onChanged});

  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 32,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _actionGroups.length,
        separatorBuilder: (context, index) =>
            const SizedBox(width: OpenVtsSpacing.xs),
        itemBuilder: (context, index) {
          final group = _actionGroups[index];
          final isSelected = group.prefix == selected;
          return Material(
            color: isSelected ? OpenVtsColors.brandInk : OpenVtsColors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(OpenVtsRadius.pill),
              side: BorderSide(
                color:
                    isSelected ? OpenVtsColors.brandInk : OpenVtsColors.border,
              ),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(OpenVtsRadius.pill),
              onTap: () => onChanged(group.prefix),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                child: Text(
                  group.label,
                  style: OpenVtsTypography.meta.copyWith(
                    color: isSelected
                        ? OpenVtsColors.white
                        : OpenVtsColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _LogCard extends StatelessWidget {
  const _LogCard({required this.log, required this.onTap});

  final AdminUserActivityLog log;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final entity = _entityLabel(log.entity, log.entityId);
    final platform = _platformLine(log);
    return OpenVtsCard(
      onTap: onTap,
      padding: const EdgeInsets.all(OpenVtsSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: OpenVtsColors.surface,
              borderRadius: BorderRadius.circular(OpenVtsRadius.sm),
              border: Border.all(color: OpenVtsColors.border),
            ),
            child: Icon(
              _iconForAction(log.action),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        _humanizeAction(log.action),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: OpenVtsTypography.label.copyWith(
                          color: OpenVtsColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: OpenVtsSpacing.xs),
                    Text(
                      _relativeTime(log.createdAt),
                      style: OpenVtsTypography.meta.copyWith(
                        color: OpenVtsColors.textTertiary,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
                if (entity.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    entity,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: OpenVtsTypography.meta.copyWith(
                      color: OpenVtsColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                if (platform.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    platform,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: OpenVtsTypography.meta.copyWith(
                      color: OpenVtsColors.textTertiary,
                      fontSize: 11,
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

class _LogDetailSheet extends StatelessWidget {
  const _LogDetailSheet({required this.log});

  final AdminUserActivityLog log;

  @override
  Widget build(BuildContext context) {
    final userLabel = _userLabel(log.user);
    final metaJson = log.meta.isEmpty
        ? '-'
        : const JsonEncoder.withIndent('  ').convert(log.meta);
    return ListView(
      controller: PrimaryScrollController.maybeOf(context),
      padding: const EdgeInsets.all(OpenVtsSpacing.md),
      children: [
        OpenVtsCard(
          padding: const EdgeInsets.all(OpenVtsSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: OpenVtsColors.surface,
                  borderRadius: BorderRadius.circular(OpenVtsRadius.sm),
                  border: Border.all(color: OpenVtsColors.border),
                ),
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
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: OpenVtsTypography.label.copyWith(
                        color: OpenVtsColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _dateTimeText(log.createdAt),
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
        ),
        const SizedBox(height: OpenVtsSpacing.sm),
        _DetailsCard(
          title: 'Details',
          rows: [
            _DetailRowData('Action', _displayValue(log.action)),
            _DetailRowData('Created At', _dateTimeText(log.createdAt)),
            _DetailRowData('Entity', _displayValue(log.entity)),
            _DetailRowData('Entity ID', _displayValue(log.entityId)),
            _DetailRowData('IP', _displayValue(log.ip)),
            _DetailRowData('Browser', _displayValue(log.browser)),
            _DetailRowData('Platform', _displayValue(log.platform)),
            _DetailRowData('User', userLabel),
          ],
        ),
        const SizedBox(height: OpenVtsSpacing.sm),
        OpenVtsCard(
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
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(OpenVtsSpacing.sm),
                decoration: BoxDecoration(
                  color: OpenVtsColors.surface,
                  borderRadius: BorderRadius.circular(OpenVtsRadius.sm),
                  border: Border.all(color: OpenVtsColors.border),
                ),
                child: SelectableText(
                  metaJson,
                  style: OpenVtsTypography.meta.copyWith(
                    color: OpenVtsColors.textPrimary,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ),
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
            width: 94,
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
                  'Unable to load logs',
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

String _humanizeAction(String action) {
  final parts = action
      .trim()
      .split(RegExp(r'[._:/]'))
      .map((part) => part.trim())
      .where((part) => part.isNotEmpty)
      .toList(growable: true);
  if (parts.isEmpty) {
    return 'Activity';
  }
  if (parts.length > 2 && parts.first.toUpperCase() == 'USER') {
    parts.removeAt(0);
  }
  return parts.map(_titleCase).join(' · ');
}

String _titleCase(String value) {
  final normalized = value.trim().replaceAll('_', ' ').replaceAll('-', ' ');
  if (normalized.isEmpty) {
    return normalized;
  }
  return normalized
      .split(RegExp(r'\s+'))
      .map((word) => word.isEmpty
          ? word
          : '${word.substring(0, 1).toUpperCase()}${word.substring(1).toLowerCase()}')
      .join(' ');
}

IconData _iconForAction(String action) {
  final upper = action.toUpperCase();
  if (upper.contains('AUTH') || upper.contains('LOGIN')) {
    return Icons.login_rounded;
  }
  if (upper.contains('PAYMENT') || upper.contains('BILLING')) {
    return Icons.payments_outlined;
  }
  if (upper.contains('VEHICLE')) {
    return Icons.directions_car_filled_outlined;
  }
  if (upper.contains('DRIVER')) {
    return Icons.badge_outlined;
  }
  if (upper.contains('SETTING') || upper.contains('CONFIG')) {
    return Icons.settings_outlined;
  }
  if (upper.contains('DELETE') || upper.contains('REMOVE')) {
    return Icons.delete_outline_rounded;
  }
  if (upper.contains('CREATE') || upper.contains('ADD')) {
    return Icons.add_circle_outline_rounded;
  }
  if (upper.contains('UPDATE') || upper.contains('EDIT')) {
    return Icons.edit_outlined;
  }
  return Icons.history_rounded;
}

String _entityLabel(String entity, String entityId) {
  final normalizedEntity = entity.trim();
  final normalizedId = entityId.trim();
  if (normalizedEntity.isEmpty && normalizedId.isEmpty) {
    return '';
  }
  if (normalizedEntity.isEmpty) {
    return normalizedId;
  }
  if (normalizedId.isEmpty) {
    return _titleCase(normalizedEntity);
  }
  return '${_titleCase(normalizedEntity)} - $normalizedId';
}

String _platformLine(AdminUserActivityLog log) {
  return _joinParts([
    log.platform,
    _shortText(log.browser, 46),
    log.ip,
  ]);
}

String _shortText(String value, int maxLength) {
  final normalized = value.trim();
  if (normalized.length <= maxLength) {
    return normalized;
  }
  return '${normalized.substring(0, maxLength - 3)}...';
}

String _relativeTime(DateTime? value) {
  if (value == null) {
    return '-';
  }
  final now = DateTime.now();
  final diff = now.difference(value.toLocal());
  if (diff.inSeconds >= 0 && diff.inSeconds < 60) {
    return 'just now';
  }
  if (diff.inMinutes >= 0 && diff.inMinutes < 60) {
    return '${diff.inMinutes}m ago';
  }
  if (diff.inHours >= 0 && diff.inHours < 24) {
    return '${diff.inHours}h ago';
  }
  if (diff.inDays >= 0 && diff.inDays < 7) {
    return '${diff.inDays}d ago';
  }
  return DateFormat('dd MMM yyyy').format(value.toLocal());
}

String _dateTimeText(DateTime? value) {
  if (value == null) {
    return '-';
  }
  return _dateFormatter.formatDateTime(value.toLocal());
}

String _userLabel(AdminUserReference? user) {
  if (user == null) {
    return '-';
  }
  final label = _joinParts([user.name, user.username, user.email]);
  if (label.isNotEmpty) {
    return label;
  }
  return _displayValue(user.id);
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
  return normalized.join(' - ');
}
