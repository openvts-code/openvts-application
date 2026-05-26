import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/open_vts_spacing.dart';
import '../../../../../shared/widgets/open_vts_bottom_sheet.dart';
import '../../../../../shared/widgets/open_vts_button.dart';
import '../../../../../shared/widgets/open_vts_date_time_range_selector.dart';
import '../../../../../shared/widgets/open_vts_empty_state.dart';
import '../../../../../shared/widgets/open_vts_error_view.dart';
import '../../../../../shared/widgets/open_vts_loader.dart';
import '../../../../../shared/widgets/open_vts_search_field.dart';
import '../../../controllers/admin_providers.dart';
import '../widgets/admin_activity_log_card.dart';
import '../widgets/admin_activity_log_detail_sheet.dart';
import '../widgets/admin_logs_filter_widgets.dart';

class AdminActivityLogsPanel extends ConsumerStatefulWidget {
  const AdminActivityLogsPanel({super.key});

  @override
  ConsumerState<AdminActivityLogsPanel> createState() =>
      _AdminActivityLogsPanelState();
}

class _AdminActivityLogsPanelState
    extends ConsumerState<AdminActivityLogsPanel> {
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminLogsControllerProvider);
    final controller = ref.read(adminLogsControllerProvider.notifier);

    if (state.isLoadingActivity && state.activityLogs.isEmpty) {
      return const OpenVtsLoader();
    }
    if (state.sectionErrorMessage != null && state.activityLogs.isEmpty) {
      return OpenVtsErrorView(
        message: state.sectionErrorMessage!,
        onRetry: controller.loadActivityLogs,
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        OpenVtsSearchField(
          hintText: 'Search activity logs...',
          onChanged: (v) {
            controller.setActivityFilters(search: v);
            _debounce?.cancel();
            _debounce = Timer(const Duration(milliseconds: 350), () {
              unawaited(controller.loadActivityLogs());
            });
          },
        ),
        const SizedBox(height: OpenVtsSpacing.sm),
        DropdownButtonFormField<String?>(
          initialValue: state.activityUserId,
          decoration: const InputDecoration(labelText: 'Actor User'),
          items: [
            const DropdownMenuItem<String?>(
                value: null, child: Text('All users')),
            ...state.options.users.map((u) => DropdownMenuItem<String?>(
                  value: u.uid,
                  child: Text(u.displayName, overflow: TextOverflow.ellipsis),
                )),
          ],
          onChanged: (v) {
            controller.setActivityFilters(userId: v);
            unawaited(controller.loadActivityLogs());
          },
        ),
        const SizedBox(height: OpenVtsSpacing.sm),
        Wrap(
          spacing: OpenVtsSpacing.xs,
          runSpacing: OpenVtsSpacing.xs,
          children: [
            _group('All', ''),
            _group('Security', 'AUTH'),
            _group('Settings', 'SETTINGS'),
            _group('Billing', 'PAYMENT'),
            _group('Vehicles', 'VEHICLE'),
            _group('Drivers', 'DRIVER'),
          ].map((w) => w.build(state, controller)).toList(growable: false),
        ),
        const SizedBox(height: OpenVtsSpacing.sm),
        OpenVtsDateTimeRangeField(
          label: 'Date range',
          title: 'Activity date range',
          dateTimeEnabled: true,
          value: OpenVtsDateTimeRange(
              start: state.activityFrom, end: state.activityTo),
          onChanged: (range) {
            controller.setActivityFilters(
              from: range.start,
              to: range.end,
              clearFrom: range.start == null,
              clearTo: range.end == null,
            );
            unawaited(controller.loadActivityLogs());
          },
        ),
        const SizedBox(height: OpenVtsSpacing.sm),
        if (state.activityLogs.isEmpty)
          const OpenVtsEmptyState(
            title: 'No activity logs found',
            message: 'Try changing search or filters.',
          )
        else ...[
          for (final item in state.activityLogs) ...[
            AdminActivityLogCard(
              item: item,
              onTap: () => OpenVtsBottomSheet.show<void>(
                context: context,
                title: 'Activity Detail',
                initialChildSize: 0.75,
                minChildSize: 0.45,
                maxChildSize: 0.95,
                child: AdminActivityLogDetailSheet(item: item),
              ),
            ),
            if (item != state.activityLogs.last)
              const SizedBox(height: OpenVtsSpacing.sm),
          ],
          if (state.activityHasMore) ...[
            const SizedBox(height: OpenVtsSpacing.sm),
            OpenVtsButton(
              label: 'Load More',
              height: 38,
              variant: OpenVtsButtonVariant.secondary,
              isLoading: state.isLoadingMoreActivity,
              onPressed: state.isLoadingMoreActivity
                  ? null
                  : controller.loadMoreActivityLogs,
            ),
          ],
        ],
      ],
    );
  }

  _GroupChip _group(String label, String value) => _GroupChip(label, value);
}

class _GroupChip {
  const _GroupChip(this.label, this.value);
  final String label;
  final String value;

  Widget build(state, controller) {
    return AdminFilterChip(
      label: label,
      selected: state.activityActionPrefix == value,
      onTap: () {
        controller.setActivityFilters(actionPrefix: value);
        controller.loadActivityLogs();
      },
    );
  }
}
