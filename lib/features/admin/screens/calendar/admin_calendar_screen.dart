import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../../core/theme/open_vts_colors.dart';
import '../../../../core/theme/open_vts_radius.dart';
import '../../../../core/theme/open_vts_spacing.dart';
import '../../../../core/theme/open_vts_typography.dart';
import '../../../../shared/widgets/open_vts_bottom_sheet.dart';
import '../../../../shared/widgets/open_vts_error_view.dart';
import '../../../../shared/widgets/open_vts_loader.dart';
import '../../../../shared/widgets/open_vts_page_scaffold.dart';
import '../../controllers/admin_calendar_controller.dart';
import '../../models/admin_calendar_model.dart';
import 'widgets/admin_calendar_day_bottom_sheet.dart';

class AdminCalendarScreen extends ConsumerWidget {
  const AdminCalendarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final focusedDate = ref.watch(adminCalendarFocusedDateProvider);
    final selectedDate = ref.watch(adminCalendarSelectedDateProvider);
    final eventsAsync = ref.watch(adminCalendarEventsProvider);
    final filters = ref.watch(adminCalendarFiltersProvider);
    final selectedOrFocusedDate = selectedDate ?? focusedDate;
    final today = DateTime.now();

    return OpenVtsPageScaffold(
      title: 'Calendar',
      headerMode: OpenVtsPageHeaderMode.closeable,
      leading: const _HeaderLogoTile(),
      padding: const EdgeInsetsDirectional.fromSTEB(
        OpenVtsSpacing.md,
        OpenVtsSpacing.md,
        OpenVtsSpacing.md,
        OpenVtsSpacing.sm,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CalendarToolbar(
            displayedDate: selectedOrFocusedDate,
            focusedDate: focusedDate,
            filters: filters,
            onPreviousMonth: () {
              ref.read(adminCalendarFocusedDateProvider.notifier).state =
                  DateTime(focusedDate.year, focusedDate.month - 1, 1);
            },
            onToday: () {
              final now = DateTime.now();
              ref.read(adminCalendarFocusedDateProvider.notifier).state = now;
              ref.read(adminCalendarSelectedDateProvider.notifier).state = now;
            },
            onNextMonth: () {
              ref.read(adminCalendarFocusedDateProvider.notifier).state =
                  DateTime(focusedDate.year, focusedDate.month + 1, 1);
            },
            onToggleFilter: (value, selected) {
              final notifier = ref.read(adminCalendarFiltersProvider.notifier);
              notifier.state = selected
                  ? <String>[...filters, value]
                  : filters.where((filter) => filter != value).toList();
            },
          ),
          const SizedBox(height: OpenVtsSpacing.sm),
          Expanded(
            child: eventsAsync.when(
              loading: () => const OpenVtsLoader(),
              error: (err, stack) => OpenVtsErrorView(
                message: _calendarErrorMessage(err),
                onRetry: () => ref.refresh(adminCalendarEventsProvider),
              ),
              data: (events) {
                final eventsByDate = <String, AdminCalendarEvent>{
                  for (final event in events) event.date: event,
                };
                const gridHorizontalInset = 6.0;
                const dayGapX = 3.0;
                const dayGapY = 6.0;
                const rowBuffer = 4.0;

                return Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final tableWidth =
                            (constraints.maxWidth - (gridHorizontalInset * 2))
                                .clamp(280.0, 420.0)
                                .toDouble();
                        final columnWidth =
                            (tableWidth / 7).clamp(44.0, 56.0).toDouble();
                        final rowHeight =
                            columnWidth + (dayGapY * 2) + rowBuffer;

                        return Padding(
                          padding: const EdgeInsets.fromLTRB(
                            gridHorizontalInset,
                            OpenVtsSpacing.xs,
                            gridHorizontalInset,
                            0,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                DateFormat('MMMM yyyy').format(focusedDate),
                                textAlign: TextAlign.center,
                                style: OpenVtsTypography.titleMedium.copyWith(
                                  color: OpenVtsColors.textPrimary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: OpenVtsSpacing.md),
                              TableCalendar<AdminCalendarEvent>(
                                shouldFillViewport: false,
                                sixWeekMonthsEnforced: true,
                                rowHeight: rowHeight,
                                firstDay: DateTime.utc(2000, 1, 1),
                                lastDay: DateTime.utc(2050, 12, 31),
                                focusedDay: focusedDate,
                                headerVisible: false,
                                daysOfWeekHeight: 20,
                                startingDayOfWeek: StartingDayOfWeek.sunday,
                                availableCalendarFormats:
                                    const <CalendarFormat, String>{
                                  CalendarFormat.month: 'Month',
                                },
                                selectedDayPredicate: (day) =>
                                    isSameDay(selectedDate, day),
                                eventLoader: (day) {
                                  final event = eventsByDate[_formatDay(day)];
                                  return event == null
                                      ? const <AdminCalendarEvent>[]
                                      : <AdminCalendarEvent>[event];
                                },
                                onDaySelected: (selectedDay, focusedDay) {
                                  ref
                                      .read(adminCalendarSelectedDateProvider
                                          .notifier)
                                      .state = selectedDay;
                                  ref
                                      .read(adminCalendarFocusedDateProvider
                                          .notifier)
                                      .state = focusedDay;
                                  _showDayDetailsSheet(context, selectedDay);
                                },
                                onPageChanged: (focusedDay) {
                                  ref
                                      .read(adminCalendarFocusedDateProvider
                                          .notifier)
                                      .state = focusedDay;
                                },
                                calendarStyle: const CalendarStyle(
                                  outsideDaysVisible: true,
                                  cellMargin: EdgeInsets.zero,
                                  cellPadding: EdgeInsets.zero,
                                  markersMaxCount: 0,
                                ),
                                daysOfWeekStyle: DaysOfWeekStyle(
                                  weekdayStyle: OpenVtsTypography.meta.copyWith(
                                    color: OpenVtsColors.textTertiary,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  weekendStyle: OpenVtsTypography.meta.copyWith(
                                    color: OpenVtsColors.textTertiary,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                calendarBuilders: CalendarBuilders(
                                  defaultBuilder: (context, day, _) =>
                                      _buildDayCell(
                                    day: day,
                                    event: eventsByDate[_formatDay(day)],
                                    visibleFilters: filters,
                                    horizontalGap: dayGapX,
                                    verticalGap: dayGapY,
                                  ),
                                  todayBuilder: (context, day, _) =>
                                      _buildDayCell(
                                    day: day,
                                    event: eventsByDate[_formatDay(day)],
                                    visibleFilters: filters,
                                    horizontalGap: dayGapX,
                                    verticalGap: dayGapY,
                                    isToday: true,
                                  ),
                                  selectedBuilder: (context, day, _) =>
                                      _buildDayCell(
                                    day: day,
                                    event: eventsByDate[_formatDay(day)],
                                    visibleFilters: filters,
                                    horizontalGap: dayGapX,
                                    verticalGap: dayGapY,
                                    isSelected: true,
                                    isToday: isSameDay(day, today),
                                  ),
                                  outsideBuilder: (context, day, _) =>
                                      _buildOutsideDayCell(
                                    day,
                                    horizontalGap: dayGapX,
                                    verticalGap: dayGapY,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showDayDetailsSheet(BuildContext context, DateTime date) {
    OpenVtsBottomSheet.show(
      context: context,
      title: DateFormat('dd MMM yyyy').format(date),
      child: AdminCalendarDayBottomSheet(date: date),
    );
  }

  Widget _buildDayCell({
    required DateTime day,
    required List<String> visibleFilters,
    required double horizontalGap,
    required double verticalGap,
    AdminCalendarEvent? event,
    bool isToday = false,
    bool isSelected = false,
    bool isOutside = false,
  }) {
    final foregroundColor = isSelected
        ? OpenVtsColors.white
        : isOutside
            ? OpenVtsColors.textTertiary
            : isToday
                ? OpenVtsColors.brandInk
                : OpenVtsColors.textPrimary;

    final backgroundColor = isSelected
        ? OpenVtsColors.brandInk
        : isToday
            ? OpenVtsColors.surface
            : OpenVtsColors.surfaceElevated;

    final borderColor = isSelected
        ? OpenVtsColors.brandInk
        : isToday
            ? OpenVtsColors.divider
            : OpenVtsColors.border.withValues(alpha: 0.88);

    final metrics = <_DayMetricData>[];

    if (event != null) {
      if (visibleFilters.contains('users') && event.usersCount > 0) {
        metrics.add(
          _DayMetricData(
            color: isSelected ? OpenVtsColors.white : OpenVtsColors.brandInk,
            label: 'Users',
            value: event.usersCount,
          ),
        );
      }
      if (visibleFilters.contains('vehicle') && event.vehiclesCount > 0) {
        metrics.add(
          _DayMetricData(
            color: isSelected ? OpenVtsColors.white : OpenVtsColors.success,
            label: 'Vehicle',
            value: event.vehiclesCount,
          ),
        );
      }
      if (visibleFilters.contains('expiry') && event.expiryCount > 0) {
        metrics.add(
          _DayMetricData(
            color: isSelected ? OpenVtsColors.white : OpenVtsColors.error,
            label: 'Expiry',
            value: event.expiryCount,
          ),
        );
      }
    }

    final visibleMetricRows = metrics
        .take(2)
        .map(
          (metric) => _DayMetricRow(
            color: metric.color,
            label: metric.label,
            value: metric.value,
            inverted: isSelected,
          ),
        )
        .toList(growable: false);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalGap, vertical: verticalGap),
      child: Center(
        child: AspectRatio(
          aspectRatio: 1,
          child: Container(
            padding: const EdgeInsets.fromLTRB(7, 6, 7, 5),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(OpenVtsRadius.md),
              border: Border.all(color: borderColor),
              boxShadow: isSelected
                  ? <BoxShadow>[
                      BoxShadow(
                        color: OpenVtsColors.brandInk.withValues(alpha: 0.06),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${day.day}',
                  style: OpenVtsTypography.body.copyWith(
                    color: foregroundColor,
                    fontSize: 13,
                    height: 1.0,
                    fontWeight:
                        isSelected || isToday ? FontWeight.w700 : FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ...visibleMetricRows,
                      const Spacer(),
                      if (isToday && !isOutside) _TodayBadge(inverted: isSelected),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOutsideDayCell(
    DateTime day, {
    required double horizontalGap,
    required double verticalGap,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalGap, vertical: verticalGap),
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.only(top: 9),
          child: Text(
            '${day.day}',
            style: OpenVtsTypography.meta.copyWith(
              color: OpenVtsColors.textTertiary.withValues(alpha: 0.72),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  String _formatDay(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _calendarErrorMessage(Object err) {
    if (err is DioException) {
      final responseMessage = _extractResponseMessage(err.response?.data);
      if (responseMessage != null) return responseMessage;

      if (err.type == DioExceptionType.connectionTimeout ||
          err.type == DioExceptionType.receiveTimeout ||
          err.type == DioExceptionType.sendTimeout) {
        return 'The calendar request timed out. Please try again.';
      }

      if (err.type == DioExceptionType.connectionError) {
        return 'Unable to reach the server right now.';
      }

      final message = err.message?.trim();
      if (message != null && message.isNotEmpty) return message;
    }

    final raw = err.toString().trim();
    if (raw.startsWith('Exception: ')) {
      return raw.substring('Exception: '.length).trim();
    }

    return 'Failed to load calendar events.';
  }

  String? _extractResponseMessage(dynamic data) {
    if (data is Map<String, dynamic>) {
      for (final key in const ['message', 'error']) {
        final value = data[key];
        if (value is String && value.trim().isNotEmpty) {
          return value.trim();
        }
      }

      final nestedData = data['data'];
      if (!identical(nestedData, data)) {
        return _extractResponseMessage(nestedData);
      }
    }

    if (data is String && data.trim().isNotEmpty) return data.trim();

    return null;
  }
}

class _HeaderLogoTile extends StatelessWidget {
  const _HeaderLogoTile();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: OpenVtsSpacing.sm),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: Container(
          height: 36,
          width: 36,
          decoration: BoxDecoration(
            color: OpenVtsColors.brandInk,
            borderRadius: BorderRadius.circular(OpenVtsRadius.md),
          ),
          child: const Icon(
            Icons.calendar_month_outlined,
            color: OpenVtsColors.white,
            size: 18,
          ),
        ),
      ),
    );
  }
}

class _CalendarToolbar extends StatelessWidget {
  const _CalendarToolbar({
    required this.displayedDate,
    required this.focusedDate,
    required this.filters,
    required this.onPreviousMonth,
    required this.onToday,
    required this.onNextMonth,
    required this.onToggleFilter,
  });

  final DateTime displayedDate;
  final DateTime focusedDate;
  final List<String> filters;
  final VoidCallback onPreviousMonth;
  final VoidCallback onToday;
  final VoidCallback onNextMonth;
  final void Function(String value, bool selected) onToggleFilter;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                DateFormat('dd MMM yyyy').format(displayedDate),
                style: OpenVtsTypography.titleMedium.copyWith(
                  color: OpenVtsColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            _NavigationButton(
              icon: Icons.chevron_left_rounded,
              onPressed: onPreviousMonth,
            ),
            const SizedBox(width: OpenVtsSpacing.xs),
            FilledButton.tonal(
              style: FilledButton.styleFrom(
                backgroundColor: OpenVtsColors.surface,
                foregroundColor: OpenVtsColors.textPrimary,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: OpenVtsSpacing.md,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(OpenVtsRadius.pill),
                  side: const BorderSide(color: OpenVtsColors.border),
                ),
              ),
              onPressed: onToday,
              child: const Text('Today'),
            ),
            const SizedBox(width: OpenVtsSpacing.xs),
            _NavigationButton(
              icon: Icons.chevron_right_rounded,
              onPressed: onNextMonth,
            ),
          ],
        ),
        const SizedBox(height: OpenVtsSpacing.sm),
        Wrap(
          spacing: OpenVtsSpacing.xs,
          runSpacing: OpenVtsSpacing.xs,
          children: [
            _FilterPill(
              label: 'Users',
              value: 'users',
              icon: Icons.person_outline_rounded,
              selected: filters.contains('users'),
              onChanged: onToggleFilter,
            ),
            _FilterPill(
              label: 'Vehicle',
              value: 'vehicle',
              icon: Icons.directions_car_outlined,
              selected: filters.contains('vehicle'),
              onChanged: onToggleFilter,
            ),
            _FilterPill(
              label: 'Expiry',
              value: 'expiry',
              icon: Icons.warning_amber_rounded,
              selected: filters.contains('expiry'),
              onChanged: onToggleFilter,
            ),
          ],
        ),
      ],
    );
  }
}

class _NavigationButton extends StatelessWidget {
  const _NavigationButton({
    required this.icon,
    required this.onPressed,
  });

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 36,
      height: 36,
      child: IconButton(
        onPressed: onPressed,
        style: IconButton.styleFrom(
          backgroundColor: OpenVtsColors.surface,
          foregroundColor: OpenVtsColors.textPrimary,
          side: const BorderSide(color: OpenVtsColors.border),
        ),
        icon: Icon(icon, size: 18),
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.label,
    required this.value,
    required this.icon,
    required this.selected,
    required this.onChanged,
  });

  final String label;
  final String value;
  final IconData icon;
  final bool selected;
  final void Function(String value, bool selected) onChanged;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      selected: selected,
      onSelected: (nextValue) => onChanged(value, nextValue),
      avatar: Icon(
        icon,
        size: 14,
        color: selected ? OpenVtsColors.white : OpenVtsColors.textSecondary,
      ),
      label: Text(label),
      backgroundColor: OpenVtsColors.surfaceElevated,
      selectedColor: OpenVtsColors.brandInkSoft,
      checkmarkColor: OpenVtsColors.white,
      side: BorderSide(
        color: selected
            ? OpenVtsColors.brandInkSoft.withValues(alpha: 0.9)
            : OpenVtsColors.border.withValues(alpha: 0.85),
      ),
      labelStyle: OpenVtsTypography.meta.copyWith(
        color: selected ? OpenVtsColors.white : OpenVtsColors.textPrimary,
        fontWeight: FontWeight.w600,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(OpenVtsRadius.pill),
      ),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
      elevation: 0,
      pressElevation: 0,
    );
  }
}

class _DayMetricRow extends StatelessWidget {
  const _DayMetricRow({
    required this.color,
    required this.label,
    required this.value,
    required this.inverted,
  });

  final Color color;
  final String label;
  final int value;
  final bool inverted;

  @override
  Widget build(BuildContext context) {
    final labelColor = inverted
        ? OpenVtsColors.white.withValues(alpha: 0.88)
        : OpenVtsColors.textSecondary;
    final valueColor = inverted ? OpenVtsColors.white : OpenVtsColors.textPrimary;

    return Padding(
      padding: const EdgeInsets.only(top: 1),
      child: Row(
        children: [
          Container(
            width: 3.5,
            height: 3.5,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 3),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: OpenVtsTypography.meta.copyWith(
                fontSize: 8,
                color: labelColor,
                fontWeight: FontWeight.w500,
                height: 1.0,
              ),
            ),
          ),
          const SizedBox(width: 2),
          Text(
            '$value',
            style: OpenVtsTypography.meta.copyWith(
              fontSize: 8,
              color: valueColor,
              fontWeight: FontWeight.w700,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

class _DayMetricData {
  const _DayMetricData({
    required this.color,
    required this.label,
    required this.value,
  });

  final Color color;
  final String label;
  final int value;
}

class _TodayBadge extends StatelessWidget {
  const _TodayBadge({required this.inverted});

  final bool inverted;

  @override
  Widget build(BuildContext context) {
    final text = Text(
      'TODAY',
      style: OpenVtsTypography.meta.copyWith(
        fontSize: inverted ? 6.5 : 7,
        height: 1.0,
        color: inverted
            ? OpenVtsColors.white.withValues(alpha: 0.86)
            : OpenVtsColors.white,
        fontWeight: FontWeight.w700,
        letterSpacing: inverted ? 0.25 : 0.3,
      ),
    );

    if (inverted) {
      return text;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 5,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: inverted
            ? OpenVtsColors.white.withValues(alpha: 0.16)
            : OpenVtsColors.brandInk,
        borderRadius: BorderRadius.circular(OpenVtsRadius.pill),
      ),
      child: text,
    );
  }
}
