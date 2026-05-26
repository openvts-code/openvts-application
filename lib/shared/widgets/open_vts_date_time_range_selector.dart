import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/open_vts_colors.dart';
import '../../core/theme/open_vts_radius.dart';
import '../../core/theme/open_vts_spacing.dart';
import '../../core/theme/open_vts_typography.dart';
import '../../core/utils/date_time_formatter.dart';
import 'open_vts_button.dart';

class OpenVtsDateTimeRange {
  const OpenVtsDateTimeRange({this.start, this.end});

  const OpenVtsDateTimeRange.empty()
      : start = null,
        end = null;

  final DateTime? start;
  final DateTime? end;

  bool get isEmpty => start == null && end == null;

  bool get isComplete => start != null && end != null;

  OpenVtsDateTimeRange normalized({required bool dateTimeEnabled}) {
    if (isEmpty) {
      return const OpenVtsDateTimeRange.empty();
    }

    final resolvedStart = start ?? end!;
    final resolvedEnd = end ?? start!;

    if (dateTimeEnabled) {
      return resolvedEnd.isBefore(resolvedStart)
          ? OpenVtsDateTimeRange(start: resolvedEnd, end: resolvedStart)
          : OpenVtsDateTimeRange(start: resolvedStart, end: resolvedEnd);
    }

    final startDate = DateUtils.dateOnly(resolvedStart);
    final endDate = DateUtils.dateOnly(resolvedEnd);

    return endDate.isBefore(startDate)
        ? OpenVtsDateTimeRange(start: endDate, end: startDate)
        : OpenVtsDateTimeRange(start: startDate, end: endDate);
  }
}

class OpenVtsDateTimeRangeField extends StatelessWidget {
  const OpenVtsDateTimeRangeField({
    required this.label,
    required this.value,
    required this.onChanged,
    this.dateTimeEnabled = false,
    this.enabled = true,
    this.firstDate,
    this.lastDate,
    this.title,
    this.hintText,
    this.now,
    super.key,
  });

  final String label;
  final OpenVtsDateTimeRange value;
  final ValueChanged<OpenVtsDateTimeRange> onChanged;
  final bool dateTimeEnabled;
  final bool enabled;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final String? title;
  final String? hintText;
  final DateTime? now;

  static const DateTimeFormatter _formatter = DateTimeFormatter();

  @override
  Widget build(BuildContext context) {
    final displayValue = _formatRangeLabel(value);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: OpenVtsTypography.label),
        const SizedBox(height: OpenVtsSpacing.xs),
        InkWell(
          borderRadius: BorderRadius.circular(OpenVtsRadius.md),
          onTap: enabled ? () => _openSelector(context) : null,
          child: InputDecorator(
            decoration: InputDecoration(
              enabled: enabled,
              suffixIcon: const Icon(
                Icons.calendar_month_outlined,
                size: 18,
                color: OpenVtsColors.textTertiary,
              ),
            ),
            child: Text(
              displayValue ?? hintText ?? 'Select date range',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: OpenVtsTypography.body.copyWith(
                color: displayValue == null
                    ? OpenVtsColors.textTertiary
                    : OpenVtsColors.textPrimary,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _openSelector(BuildContext context) async {
    final result = await OpenVtsDateTimeRangeSelector.show(
      context: context,
      initialValue: value,
      dateTimeEnabled: dateTimeEnabled,
      firstDate: firstDate,
      lastDate: lastDate,
      title: title,
      now: now,
    );

    if (result != null) {
      onChanged(result);
    }
  }

  String? _formatRangeLabel(OpenVtsDateTimeRange range) {
    final normalized = range.normalized(dateTimeEnabled: dateTimeEnabled);
    final start = normalized.start;
    final end = normalized.end;

    if (start == null || end == null) {
      return null;
    }

    if (dateTimeEnabled) {
      final startLabel = _formatter.formatDateTime(start.toLocal());
      final endLabel = _formatter.formatDateTime(end.toLocal());
      return startLabel == endLabel ? startLabel : '$startLabel - $endLabel';
    }

    final startLabel = _formatter.formatDate(start.toLocal());
    final endLabel = _formatter.formatDate(end.toLocal());
    return startLabel == endLabel ? startLabel : '$startLabel - $endLabel';
  }
}

class OpenVtsDateTimeRangeSelector extends StatefulWidget {
  const OpenVtsDateTimeRangeSelector({
    this.initialValue = const OpenVtsDateTimeRange.empty(),
    this.dateTimeEnabled = false,
    this.firstDate,
    this.lastDate,
    this.title,
    this.now,
    this.onApply,
    this.onClear,
    this.onCancel,
    this.scrollController,
    super.key,
  });

  final OpenVtsDateTimeRange initialValue;
  final bool dateTimeEnabled;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final String? title;
  final DateTime? now;
  final ValueChanged<OpenVtsDateTimeRange>? onApply;
  final VoidCallback? onClear;
  final VoidCallback? onCancel;
  final ScrollController? scrollController;

  static Future<OpenVtsDateTimeRange?> show({
    required BuildContext context,
    OpenVtsDateTimeRange initialValue = const OpenVtsDateTimeRange.empty(),
    bool dateTimeEnabled = false,
    DateTime? firstDate,
    DateTime? lastDate,
    String? title,
    DateTime? now,
  }) {
    return showModalBottomSheet<OpenVtsDateTimeRange>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final mediaQuery = MediaQuery.of(context);
        final screenSize = mediaQuery.size;
        final useMobileSheet =
            screenSize.width <= 700 || screenSize.height <= 900;
        final targetMobileHeight = dateTimeEnabled ? 610.0 : 530.0;
        final mobileInitial =
            (targetMobileHeight / screenSize.height).clamp(0.72, 0.94);
        final initialChildSize = useMobileSheet ? mobileInitial : 0.88;
        final minChildSize =
            useMobileSheet ? (initialChildSize - 0.1).clamp(0.6, 0.9) : 0.58;
        final maxChildSize =
            useMobileSheet ? (initialChildSize + 0.12).clamp(0.82, 0.98) : 0.96;
        final snapSizes = <double>[minChildSize, initialChildSize, maxChildSize]
          ..sort();

        return SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.only(bottom: mediaQuery.viewInsets.bottom),
            child: DraggableScrollableSheet(
              expand: false,
              initialChildSize: initialChildSize,
              minChildSize: minChildSize,
              maxChildSize: maxChildSize,
              snap: true,
              snapSizes: snapSizes,
              builder: (context, scrollController) {
                return Align(
                  alignment: Alignment.bottomCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: DecoratedBox(
                      decoration: const BoxDecoration(
                        color: OpenVtsColors.surfaceElevated,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(OpenVtsRadius.lg),
                        ),
                      ),
                      child: OpenVtsDateTimeRangeSelector(
                        initialValue: initialValue,
                        dateTimeEnabled: dateTimeEnabled,
                        firstDate: firstDate,
                        lastDate: lastDate,
                        title: title,
                        now: now,
                        scrollController: scrollController,
                        onApply: (range) => Navigator.of(context).pop(range),
                        onClear: () => Navigator.of(context).pop(
                          const OpenVtsDateTimeRange.empty(),
                        ),
                        onCancel: () => Navigator.of(context).pop(),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  @override
  State<OpenVtsDateTimeRangeSelector> createState() =>
      _OpenVtsDateTimeRangeSelectorState();
}

class _OpenVtsDateTimeRangeSelectorState
    extends State<OpenVtsDateTimeRangeSelector> {
  late final DateTime _now;
  late final DateTime _firstDate;
  late final DateTime _lastDate;
  late DateTime _focusedMonth;
  late DateTime _startDate;
  late DateTime _endDate;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  _RangePresetType _selectedPreset = _RangePresetType.custom;

  @override
  void initState() {
    super.initState();

    _now = widget.now ?? DateTime.now();
    _firstDate = DateUtils.dateOnly(widget.firstDate ?? DateTime(2020));
    _lastDate = DateUtils.dateOnly(widget.lastDate ?? DateTime(2100, 12, 31));

    final normalized = widget.initialValue.normalized(
      dateTimeEnabled: widget.dateTimeEnabled,
    );
    final today = _clampDate(DateUtils.dateOnly(_now));
    final initialStart = normalized.start == null
        ? today
        : _clampDate(DateUtils.dateOnly(normalized.start!));
    final initialEnd = normalized.end == null
        ? initialStart
        : _clampDate(DateUtils.dateOnly(normalized.end!));

    _startDate = initialStart;
    _endDate = initialEnd.isBefore(initialStart) ? initialStart : initialEnd;
    _startTime = normalized.start == null
        ? const TimeOfDay(hour: 0, minute: 0)
        : TimeOfDay.fromDateTime(normalized.start!.toLocal());
    _endTime = normalized.end == null
        ? const TimeOfDay(hour: 0, minute: 0)
        : TimeOfDay.fromDateTime(normalized.end!.toLocal());
    _focusedMonth = DateTime(_endDate.year, _endDate.month);
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.title ??
        (widget.dateTimeEnabled
            ? 'Choose Date & Time Range'
            : 'Choose Date Range');

    return LayoutBuilder(
      builder: (context, constraints) {
        final mediaQuery = MediaQuery.of(context);
        final isCompact = _isCompactLayout(
          screenHeight: mediaQuery.size.height,
          availableHeight: constraints.maxHeight,
          width: constraints.maxWidth,
        );
        final sectionSpacing = isCompact ? 6.0 : OpenVtsSpacing.md;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SelectorHeader(
              title: title,
              onClose: widget.onCancel ?? () {},
              compact: isCompact,
            ),
            const Divider(height: 1, color: OpenVtsColors.divider),
            Expanded(
              child: SingleChildScrollView(
                controller: widget.scrollController,
                primary: widget.scrollController == null,
                padding: EdgeInsets.fromLTRB(
                  isCompact ? OpenVtsSpacing.sm : OpenVtsSpacing.md,
                  isCompact ? OpenVtsSpacing.xs : OpenVtsSpacing.md,
                  isCompact ? OpenVtsSpacing.sm : OpenVtsSpacing.md,
                  isCompact ? OpenVtsSpacing.xs : OpenVtsSpacing.sm,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _PresetGrid(
                      presets: _visiblePresets,
                      selectedPreset: _selectedPreset,
                      onSelected: _selectPreset,
                      compact: isCompact,
                    ),
                    SizedBox(
                      height: sectionSpacing,
                    ),
                    _MonthCalendar(
                      focusedMonth: _focusedMonth,
                      firstDate: _firstDate,
                      lastDate: _lastDate,
                      startDate: _startDate,
                      endDate: _endDate,
                      onPreviousMonth: _canMoveMonth(-1)
                          ? () => _moveFocusedMonth(-1)
                          : null,
                      onNextMonth:
                          _canMoveMonth(1) ? () => _moveFocusedMonth(1) : null,
                      onDateSelected: _selectDate,
                      compact: isCompact,
                    ),
                    SizedBox(
                      height: sectionSpacing,
                    ),
                    _SelectedRangeSummary(
                      range: _currentRange,
                      dateTimeEnabled: widget.dateTimeEnabled,
                      compact: isCompact,
                    ),
                    if (widget.dateTimeEnabled) ...[
                      SizedBox(
                        height: sectionSpacing,
                      ),
                      _TimeRangeFields(
                        startTime: _startTime,
                        endTime: _endTime,
                        isValid: _isCurrentRangeValid,
                        compact: isCompact,
                        onStartTap: _pickStartTime,
                        onEndTap: _pickEndTime,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            _SelectorActions(
              canApply: _isCurrentRangeValid,
              compact: isCompact,
              onClear: widget.onClear ?? () {},
              onCancel: widget.onCancel ?? () {},
              onApply: () => widget.onApply?.call(_currentRange),
            ),
          ],
        );
      },
    );
  }

  bool _isCompactLayout({
    required double screenHeight,
    required double availableHeight,
    required double width,
  }) {
    final narrow = width <= 600;
    final shortSheet = availableHeight <= 700;
    final shortScreen = screenHeight <= 860 && width <= 900;
    return narrow || shortSheet || shortScreen;
  }

  Future<void> _pickStartTime() async {
    final selected = await _pickTime(
      initialTime: _startTime,
      helpText: 'Select start time',
    );
    if (!mounted || selected == null) {
      return;
    }

    setState(() {
      _selectedPreset = _RangePresetType.custom;
      _startTime = selected;
    });
  }

  Future<void> _pickEndTime() async {
    final selected = await _pickTime(
      initialTime: _endTime,
      helpText: 'Select end time',
    );
    if (!mounted || selected == null) {
      return;
    }

    setState(() {
      _selectedPreset = _RangePresetType.custom;
      _endTime = selected;
    });
  }

  Future<TimeOfDay?> _pickTime({
    required TimeOfDay initialTime,
    required String helpText,
  }) {
    return showTimePicker(
      context: context,
      initialTime: initialTime,
      helpText: helpText,
      builder: (context, child) {
        final baseTheme = Theme.of(context);
        return Theme(
          data: baseTheme.copyWith(
            colorScheme: baseTheme.colorScheme.copyWith(
              primary: OpenVtsColors.brandInk,
              onPrimary: OpenVtsColors.white,
              surface: OpenVtsColors.surfaceElevated,
              onSurface: OpenVtsColors.textPrimary,
            ),
            timePickerTheme: TimePickerThemeData(
              backgroundColor: OpenVtsColors.surfaceElevated,
              dialBackgroundColor: OpenVtsColors.surface,
              hourMinuteShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(OpenVtsRadius.md),
                side: const BorderSide(color: OpenVtsColors.border),
              ),
              dayPeriodShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(OpenVtsRadius.md),
                side: const BorderSide(color: OpenVtsColors.border),
              ),
              dayPeriodColor: OpenVtsColors.surface,
              dayPeriodTextColor: OpenVtsColors.textPrimary,
              helpTextStyle: OpenVtsTypography.label.copyWith(
                color: OpenVtsColors.textSecondary,
              ),
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }

  List<_RangePreset> get _visiblePresets {
    return <_RangePreset>[
      _RangePreset.custom,
      if (widget.dateTimeEnabled) ..._RangePreset.durationPresets,
      ..._RangePreset.datePresets,
    ];
  }

  bool get _isCurrentRangeValid {
    final range = _currentRange;
    final start = range.start;
    final end = range.end;
    return start != null && end != null && !end.isBefore(start);
  }

  OpenVtsDateTimeRange get _currentRange {
    if (widget.dateTimeEnabled) {
      return OpenVtsDateTimeRange(
        start: _combineDateAndTime(_startDate, _startTime),
        end: _combineDateAndTime(_endDate, _endTime),
      );
    }

    return OpenVtsDateTimeRange(
      start: DateUtils.dateOnly(_startDate),
      end: DateUtils.dateOnly(_endDate),
    ).normalized(dateTimeEnabled: false);
  }

  void _selectPreset(_RangePreset preset) {
    if (preset.type == _RangePresetType.custom) {
      setState(() => _selectedPreset = preset.type);
      return;
    }

    final range = preset.resolve(_now, widget.dateTimeEnabled).normalized(
          dateTimeEnabled: widget.dateTimeEnabled,
        );
    final start = range.start!;
    final end = range.end!;

    setState(() {
      _selectedPreset = preset.type;
      _startDate = _clampDate(DateUtils.dateOnly(start));
      _endDate = _clampDate(DateUtils.dateOnly(end));
      _startTime = TimeOfDay.fromDateTime(start.toLocal());
      _endTime = TimeOfDay.fromDateTime(end.toLocal());
      _focusedMonth = DateTime(_endDate.year, _endDate.month);
    });
  }

  void _selectDate(DateTime date) {
    setState(() {
      _selectedPreset = _RangePresetType.custom;
      final selectedDate = DateUtils.dateOnly(date);
      final hasCompletedRange = !DateUtils.isSameDay(_startDate, _endDate);

      if (hasCompletedRange) {
        _startDate = selectedDate;
        _endDate = selectedDate;
        return;
      }

      if (selectedDate.isBefore(_startDate)) {
        _endDate = _startDate;
        _startDate = selectedDate;
      } else {
        _endDate = selectedDate;
      }
    });
  }

  void _moveFocusedMonth(int amount) {
    setState(() {
      _focusedMonth =
          DateTime(_focusedMonth.year, _focusedMonth.month + amount);
    });
  }

  bool _canMoveMonth(int amount) {
    final nextMonth =
        DateTime(_focusedMonth.year, _focusedMonth.month + amount);
    final firstAllowedMonth = DateTime(_firstDate.year, _firstDate.month);
    final lastAllowedMonth = DateTime(_lastDate.year, _lastDate.month);
    return !nextMonth.isBefore(firstAllowedMonth) &&
        !nextMonth.isAfter(lastAllowedMonth);
  }

  DateTime _clampDate(DateTime date) {
    if (date.isBefore(_firstDate)) {
      return _firstDate;
    }
    if (date.isAfter(_lastDate)) {
      return _lastDate;
    }
    return date;
  }

  DateTime _combineDateAndTime(DateTime date, TimeOfDay time) {
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }
}

class _SelectorHeader extends StatelessWidget {
  const _SelectorHeader({
    required this.title,
    required this.onClose,
    required this.compact,
  });

  final String title;
  final VoidCallback onClose;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final iconSize = compact ? 18.0 : 22.0;
    final actionSize = compact ? 36.0 : 44.0;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        OpenVtsSpacing.md,
        compact ? OpenVtsSpacing.xs : OpenVtsSpacing.md,
        OpenVtsSpacing.md,
        compact ? OpenVtsSpacing.xxs : OpenVtsSpacing.sm,
      ),
      child: Row(
        children: [
          SizedBox(width: actionSize),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: OpenVtsTypography.titleSmall.copyWith(
                color: OpenVtsColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: compact ? 14 : null,
              ),
            ),
          ),
          SizedBox.square(
            dimension: actionSize,
            child: IconButton(
              tooltip: 'Close',
              onPressed: onClose,
              icon: Icon(Icons.close_rounded, size: iconSize),
              style: IconButton.styleFrom(
                backgroundColor: OpenVtsColors.surface,
                foregroundColor: OpenVtsColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PresetGrid extends StatelessWidget {
  const _PresetGrid({
    required this.presets,
    required this.selectedPreset,
    required this.onSelected,
    required this.compact,
  });

  final List<_RangePreset> presets;
  final _RangePresetType selectedPreset;
  final ValueChanged<_RangePreset> onSelected;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return SizedBox(
        height: 38,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: presets.length,
          separatorBuilder: (_, __) => const SizedBox(width: OpenVtsSpacing.xs),
          itemBuilder: (context, index) {
            final preset = presets[index];
            return _PresetCompactChip(
              preset: preset,
              isSelected: preset.type == selectedPreset,
              onTap: () => onSelected(preset),
            );
          },
        ),
      );
    }

    const spacing = OpenVtsSpacing.xs;

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 520
            ? 6
            : constraints.maxWidth >= 420
                ? 4
                : 3;
        final tileWidth =
            (constraints.maxWidth - (spacing * (columns - 1))) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final preset in presets)
              SizedBox(
                width: tileWidth,
                child: _PresetTile(
                  preset: preset,
                  isSelected: preset.type == selectedPreset,
                  onTap: () => onSelected(preset),
                  compact: false,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _PresetTile extends StatelessWidget {
  const _PresetTile({
    required this.preset,
    required this.isSelected,
    required this.onTap,
    required this.compact,
  });

  final _RangePreset preset;
  final bool isSelected;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final foregroundColor =
        isSelected ? OpenVtsColors.white : OpenVtsColors.textPrimary;

    return Material(
      color: isSelected ? OpenVtsColors.brandInk : OpenVtsColors.white,
      borderRadius: BorderRadius.circular(OpenVtsRadius.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(OpenVtsRadius.md),
        onTap: onTap,
        child: Container(
          height: compact ? 62 : 68,
          padding: const EdgeInsets.symmetric(
            horizontal: OpenVtsSpacing.xs,
            vertical: OpenVtsSpacing.xs,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(OpenVtsRadius.md),
            border: Border.all(
              color: isSelected ? OpenVtsColors.brandInk : OpenVtsColors.border,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(preset.icon,
                  size: compact ? 18 : 20, color: foregroundColor),
              SizedBox(height: compact ? 4 : 6),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  preset.label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: OpenVtsTypography.label.copyWith(
                    color: foregroundColor,
                    fontWeight: FontWeight.w600,
                    fontSize: compact ? 11 : null,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PresetCompactChip extends StatelessWidget {
  const _PresetCompactChip({
    required this.preset,
    required this.isSelected,
    required this.onTap,
  });

  final _RangePreset preset;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foregroundColor =
        isSelected ? OpenVtsColors.white : OpenVtsColors.textPrimary;

    return Material(
      color: isSelected ? OpenVtsColors.brandInk : OpenVtsColors.white,
      borderRadius: BorderRadius.circular(OpenVtsRadius.button),
      child: InkWell(
        borderRadius: BorderRadius.circular(OpenVtsRadius.button),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: OpenVtsSpacing.xs,
            vertical: OpenVtsSpacing.xxs,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(OpenVtsRadius.button),
            border: Border.all(
              color: isSelected ? OpenVtsColors.brandInk : OpenVtsColors.border,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(preset.icon, size: 14, color: foregroundColor),
              const SizedBox(width: 6),
              Text(
                preset.label,
                style: OpenVtsTypography.meta.copyWith(
                  color: foregroundColor,
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

class _MonthCalendar extends StatelessWidget {
  const _MonthCalendar({
    required this.focusedMonth,
    required this.firstDate,
    required this.lastDate,
    required this.startDate,
    required this.endDate,
    required this.onPreviousMonth,
    required this.onNextMonth,
    required this.onDateSelected,
    required this.compact,
  });

  final DateTime focusedMonth;
  final DateTime firstDate;
  final DateTime lastDate;
  final DateTime startDate;
  final DateTime endDate;
  final VoidCallback? onPreviousMonth;
  final VoidCallback? onNextMonth;
  final ValueChanged<DateTime> onDateSelected;
  final bool compact;

  static final DateFormat _monthFormat = DateFormat('MMMM yyyy');
  static const List<String> _weekdays = [
    'Su',
    'Mo',
    'Tu',
    'We',
    'Th',
    'Fr',
    'Sa'
  ];

  @override
  Widget build(BuildContext context) {
    final days = _daysForMonth(focusedMonth);

    return Container(
      padding: EdgeInsets.all(compact ? OpenVtsSpacing.xs : OpenVtsSpacing.md),
      decoration: BoxDecoration(
        color: OpenVtsColors.white,
        borderRadius: BorderRadius.circular(OpenVtsRadius.md),
        border: Border.all(color: OpenVtsColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _CalendarNavButton(
                icon: Icons.chevron_left_rounded,
                tooltip: 'Previous month',
                onPressed: onPreviousMonth,
                compact: compact,
              ),
              Expanded(
                child: Text(
                  _monthFormat.format(focusedMonth),
                  textAlign: TextAlign.center,
                  style: OpenVtsTypography.titleSmall.copyWith(
                    color: OpenVtsColors.textPrimary,
                    fontSize: compact ? 14 : null,
                  ),
                ),
              ),
              _CalendarNavButton(
                icon: Icons.chevron_right_rounded,
                tooltip: 'Next month',
                onPressed: onNextMonth,
                compact: compact,
              ),
            ],
          ),
          SizedBox(height: compact ? OpenVtsSpacing.xs : OpenVtsSpacing.sm),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 7,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisExtent: compact ? 22 : 28,
            ),
            itemBuilder: (context, index) => Center(
              child: Text(
                _weekdays[index],
                style: OpenVtsTypography.meta.copyWith(
                  color: OpenVtsColors.textTertiary,
                  fontWeight: FontWeight.w600,
                  fontSize: compact ? 11 : null,
                ),
              ),
            ),
          ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: days.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisExtent: compact ? 32 : 42,
            ),
            itemBuilder: (context, index) {
              final day = days[index];
              final isOutsideMonth = day.month != focusedMonth.month;
              final isDisabled =
                  day.isBefore(firstDate) || day.isAfter(lastDate);
              final isStart = DateUtils.isSameDay(day, startDate);
              final isEnd = DateUtils.isSameDay(day, endDate);
              final isInRange =
                  !day.isBefore(startDate) && !day.isAfter(endDate);

              return _CalendarDayCell(
                day: day,
                isOutsideMonth: isOutsideMonth,
                isDisabled: isDisabled,
                isSelected: isStart || isEnd,
                isInRange: isInRange,
                compact: compact,
                onTap: isDisabled ? null : () => onDateSelected(day),
              );
            },
          ),
        ],
      ),
    );
  }

  List<DateTime> _daysForMonth(DateTime month) {
    final firstOfMonth = DateTime(month.year, month.month);
    final daysBefore = firstOfMonth.weekday % 7;
    final firstVisibleDay = firstOfMonth.subtract(Duration(days: daysBefore));

    return List<DateTime>.generate(
      42,
      (index) => DateUtils.dateOnly(firstVisibleDay.add(Duration(days: index))),
    );
  }
}

class _CalendarNavButton extends StatelessWidget {
  const _CalendarNavButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    required this.compact,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final dimension = compact ? 32.0 : 40.0;

    return SizedBox.square(
      dimension: dimension,
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        icon: Icon(icon, size: compact ? 18 : 22),
        style: IconButton.styleFrom(
          backgroundColor: OpenVtsColors.white,
          foregroundColor: OpenVtsColors.textPrimary,
          disabledForegroundColor: OpenVtsColors.textTertiary,
          side: const BorderSide(color: OpenVtsColors.border),
        ),
      ),
    );
  }
}

class _CalendarDayCell extends StatelessWidget {
  const _CalendarDayCell({
    required this.day,
    required this.isOutsideMonth,
    required this.isDisabled,
    required this.isSelected,
    required this.isInRange,
    required this.compact,
    required this.onTap,
  });

  final DateTime day;
  final bool isOutsideMonth;
  final bool isDisabled;
  final bool isSelected;
  final bool isInRange;
  final bool compact;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final dayColor = isSelected
        ? OpenVtsColors.white
        : isDisabled || isOutsideMonth
            ? OpenVtsColors.textTertiary
            : OpenVtsColors.textPrimary;

    return InkWell(
      borderRadius: BorderRadius.circular(OpenVtsRadius.sm),
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: compact ? 1 : 3),
        decoration: BoxDecoration(
          color: isInRange && !isDisabled
              ? OpenVtsColors.surface
              : Colors.transparent,
          borderRadius: BorderRadius.circular(OpenVtsRadius.sm),
        ),
        alignment: Alignment.center,
        child: Container(
          width: compact ? 28 : 36,
          height: compact ? 28 : 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? OpenVtsColors.brandInk : Colors.transparent,
            borderRadius: BorderRadius.circular(OpenVtsRadius.sm),
          ),
          child: Text(
            '${day.day}',
            style: OpenVtsTypography.body.copyWith(
              color: dayColor,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              fontSize: compact ? 12 : null,
            ),
          ),
        ),
      ),
    );
  }
}

class _SelectedRangeSummary extends StatelessWidget {
  const _SelectedRangeSummary({
    required this.range,
    required this.dateTimeEnabled,
    required this.compact,
  });

  final OpenVtsDateTimeRange range;
  final bool dateTimeEnabled;
  final bool compact;

  static const DateTimeFormatter _formatter = DateTimeFormatter();

  @override
  Widget build(BuildContext context) {
    final start = range.start;
    final end = range.end;

    final startLabel = start == null
        ? '--'
        : dateTimeEnabled
            ? _formatter.formatDateTime(start.toLocal())
            : _formatter.formatDate(start.toLocal());
    final endLabel = end == null
        ? '--'
        : dateTimeEnabled
            ? _formatter.formatDateTime(end.toLocal())
            : _formatter.formatDate(end.toLocal());

    if (compact) {
      return Container(
        padding: const EdgeInsets.all(OpenVtsSpacing.xs),
        decoration: BoxDecoration(
          color: OpenVtsColors.white,
          borderRadius: BorderRadius.circular(OpenVtsRadius.md),
          border: Border.all(color: OpenVtsColors.border),
        ),
        child: Row(
          children: [
            Expanded(
              child: _RangeSummaryValue(
                label: 'From',
                value: startLabel,
                compact: true,
              ),
            ),
            const SizedBox(width: OpenVtsSpacing.xs),
            Expanded(
              child: _RangeSummaryValue(
                label: 'To',
                value: endLabel,
                compact: true,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: EdgeInsets.all(compact ? OpenVtsSpacing.sm : OpenVtsSpacing.md),
      decoration: BoxDecoration(
        color: OpenVtsColors.white,
        borderRadius: BorderRadius.circular(OpenVtsRadius.md),
        border: Border.all(color: OpenVtsColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Selected Range',
            style: OpenVtsTypography.label.copyWith(
              color: OpenVtsColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: OpenVtsSpacing.xs),
          Row(
            children: [
              Expanded(
                child: _RangeSummaryValue(
                  label: 'Start',
                  value: startLabel,
                  compact: compact,
                ),
              ),
              SizedBox(width: compact ? OpenVtsSpacing.xs : OpenVtsSpacing.sm),
              Expanded(
                child: _RangeSummaryValue(
                  label: 'End',
                  value: endLabel,
                  compact: compact,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RangeSummaryValue extends StatelessWidget {
  const _RangeSummaryValue({
    required this.label,
    required this.value,
    required this.compact,
  });

  final String label;
  final String value;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? OpenVtsSpacing.xs : OpenVtsSpacing.sm,
        vertical: compact ? OpenVtsSpacing.xxs : OpenVtsSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: OpenVtsColors.surface,
        borderRadius: BorderRadius.circular(OpenVtsRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: OpenVtsTypography.meta.copyWith(
              color: OpenVtsColors.textTertiary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: OpenVtsTypography.label.copyWith(
              color: OpenVtsColors.textPrimary,
              fontSize: compact ? 10 : null,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _TimeRangeFields extends StatelessWidget {
  const _TimeRangeFields({
    required this.startTime,
    required this.endTime,
    required this.isValid,
    required this.compact,
    required this.onStartTap,
    required this.onEndTap,
  });

  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final bool isValid;
  final bool compact;
  final VoidCallback onStartTap;
  final VoidCallback onEndTap;

  @override
  Widget build(BuildContext context) {
    final fields = LayoutBuilder(
      builder: (context, constraints) {
        final useColumn = constraints.maxWidth < 350;

        if (useColumn) {
          return Column(
            children: [
              _TimePickerField(
                label: 'Start Time',
                value: _formatTime(context, startTime),
                onTap: onStartTap,
                compact: compact,
              ),
              const SizedBox(height: OpenVtsSpacing.xs),
              _TimePickerField(
                label: 'End Time',
                value: _formatTime(context, endTime),
                onTap: onEndTap,
                compact: compact,
              ),
            ],
          );
        }

        return Row(
          children: [
            Expanded(
              child: _TimePickerField(
                label: 'Start Time',
                value: _formatTime(context, startTime),
                onTap: onStartTap,
                compact: compact,
              ),
            ),
            SizedBox(width: compact ? OpenVtsSpacing.xs : OpenVtsSpacing.sm),
            Expanded(
              child: _TimePickerField(
                label: 'End Time',
                value: _formatTime(context, endTime),
                onTap: onEndTap,
                compact: compact,
              ),
            ),
          ],
        );
      },
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        fields,
        if (!isValid) ...[
          const SizedBox(height: OpenVtsSpacing.xs),
          Text(
            'End time must be after start time.',
            style: OpenVtsTypography.meta.copyWith(color: OpenVtsColors.error),
          ),
        ],
      ],
    );
  }

  String _formatTime(BuildContext context, TimeOfDay time) {
    final localizations = MaterialLocalizations.of(context);
    final use24HourFormat = MediaQuery.of(context).alwaysUse24HourFormat;
    return localizations.formatTimeOfDay(
      time,
      alwaysUse24HourFormat: use24HourFormat,
    );
  }
}

class _TimePickerField extends StatelessWidget {
  const _TimePickerField({
    required this.label,
    required this.value,
    required this.onTap,
    required this.compact,
  });

  final String label;
  final String value;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(OpenVtsRadius.md),
        child: Ink(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? OpenVtsSpacing.sm : OpenVtsSpacing.md,
            vertical: compact ? OpenVtsSpacing.xs : OpenVtsSpacing.md,
          ),
          decoration: BoxDecoration(
            color: OpenVtsColors.white,
            borderRadius: BorderRadius.circular(OpenVtsRadius.md),
            border: Border.all(color: OpenVtsColors.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: OpenVtsTypography.label.copyWith(
                        color: OpenVtsColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      value,
                      style: OpenVtsTypography.titleSmall.copyWith(
                        color: OpenVtsColors.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: compact ? 15 : null,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: OpenVtsSpacing.xs),
              Icon(
                Icons.schedule_rounded,
                size: compact ? 18 : 20,
                color: OpenVtsColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectorActions extends StatelessWidget {
  const _SelectorActions({
    required this.canApply,
    required this.compact,
    required this.onClear,
    required this.onCancel,
    required this.onApply,
  });

  final bool canApply;
  final bool compact;
  final VoidCallback onClear;
  final VoidCallback onCancel;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: OpenVtsColors.surfaceElevated,
        border: Border(top: BorderSide(color: OpenVtsColors.border)),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          OpenVtsSpacing.md,
          compact ? OpenVtsSpacing.xs : OpenVtsSpacing.sm,
          OpenVtsSpacing.md,
          compact ? OpenVtsSpacing.xs : OpenVtsSpacing.md,
        ),
        child: Row(
          children: [
            Expanded(
              child: OpenVtsButton(
                label: 'Clear',
                variant: OpenVtsButtonVariant.secondary,
                trailingIcon: Icons.delete_outline_rounded,
                height: compact ? 40 : 46,
                onPressed: onClear,
              ),
            ),
            SizedBox(width: compact ? OpenVtsSpacing.xs : OpenVtsSpacing.sm),
            Expanded(
              child: OpenVtsButton(
                label: 'Cancel',
                variant: OpenVtsButtonVariant.secondary,
                height: compact ? 40 : 46,
                onPressed: onCancel,
              ),
            ),
            SizedBox(width: compact ? OpenVtsSpacing.xs : OpenVtsSpacing.sm),
            Expanded(
              child: OpenVtsButton(
                label: 'Apply',
                height: compact ? 40 : 46,
                onPressed: canApply ? onApply : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RangePreset {
  const _RangePreset({
    required this.type,
    required this.label,
    required this.icon,
    this.duration,
  });

  final _RangePresetType type;
  final String label;
  final IconData icon;
  final Duration? duration;

  static const custom = _RangePreset(
    type: _RangePresetType.custom,
    label: 'Custom',
    icon: Icons.calendar_today_outlined,
  );

  static const durationPresets = <_RangePreset>[
    _RangePreset(
      type: _RangePresetType.lastHour,
      label: 'Last Hour',
      icon: Icons.access_time_rounded,
      duration: Duration(hours: 1),
    ),
    _RangePreset(
      type: _RangePresetType.last3Hours,
      label: 'Last 3 Hours',
      icon: Icons.timer_3_outlined,
      duration: Duration(hours: 3),
    ),
    _RangePreset(
      type: _RangePresetType.last6Hours,
      label: 'Last 6 Hours',
      icon: Icons.history_toggle_off_rounded,
      duration: Duration(hours: 6),
    ),
    _RangePreset(
      type: _RangePresetType.last12Hours,
      label: 'Last 12 Hours',
      icon: Icons.watch_later_outlined,
      duration: Duration(hours: 12),
    ),
    _RangePreset(
      type: _RangePresetType.last24Hours,
      label: 'Last 24 Hours',
      icon: Icons.schedule_rounded,
      duration: Duration(hours: 24),
    ),
  ];

  static const datePresets = <_RangePreset>[
    _RangePreset(
      type: _RangePresetType.today,
      label: 'Today',
      icon: Icons.calendar_view_day_outlined,
    ),
    _RangePreset(
      type: _RangePresetType.yesterday,
      label: 'Yesterday',
      icon: Icons.event_repeat_outlined,
    ),
    _RangePreset(
      type: _RangePresetType.thisWeek,
      label: 'This Week',
      icon: Icons.calendar_view_week_outlined,
    ),
    _RangePreset(
      type: _RangePresetType.lastWeek,
      label: 'Last Week',
      icon: Icons.calendar_month_outlined,
    ),
    _RangePreset(
      type: _RangePresetType.last7Days,
      label: 'Last 7 Days',
      icon: Icons.date_range_outlined,
    ),
    _RangePreset(
      type: _RangePresetType.last30Days,
      label: 'Last 30 Days',
      icon: Icons.calendar_month_outlined,
    ),
  ];

  OpenVtsDateTimeRange resolve(DateTime now, bool dateTimeEnabled) {
    if (duration != null) {
      return OpenVtsDateTimeRange(start: now.subtract(duration!), end: now);
    }

    final today = DateUtils.dateOnly(now);
    final daysSinceSunday = today.weekday % 7;
    final thisWeekStart = today.subtract(Duration(days: daysSinceSunday));

    switch (type) {
      case _RangePresetType.custom:
        return OpenVtsDateTimeRange(start: today, end: today);
      case _RangePresetType.lastHour:
      case _RangePresetType.last3Hours:
      case _RangePresetType.last6Hours:
      case _RangePresetType.last12Hours:
      case _RangePresetType.last24Hours:
        return OpenVtsDateTimeRange(start: now, end: now);
      case _RangePresetType.today:
        return OpenVtsDateTimeRange(
          start: _startOfDay(today),
          end: _endForDate(today, dateTimeEnabled),
        );
      case _RangePresetType.yesterday:
        final yesterday = today.subtract(const Duration(days: 1));
        return OpenVtsDateTimeRange(
          start: _startOfDay(yesterday),
          end: _endForDate(yesterday, dateTimeEnabled),
        );
      case _RangePresetType.thisWeek:
        return OpenVtsDateTimeRange(
          start: _startOfDay(thisWeekStart),
          end: _endForDate(today, dateTimeEnabled),
        );
      case _RangePresetType.lastWeek:
        final lastWeekStart = thisWeekStart.subtract(const Duration(days: 7));
        final lastWeekEnd = lastWeekStart.add(const Duration(days: 6));
        return OpenVtsDateTimeRange(
          start: _startOfDay(lastWeekStart),
          end: _endForDate(lastWeekEnd, dateTimeEnabled),
        );
      case _RangePresetType.last7Days:
        return OpenVtsDateTimeRange(
          start: _startOfDay(today.subtract(const Duration(days: 6))),
          end: _endForDate(today, dateTimeEnabled),
        );
      case _RangePresetType.last30Days:
        return OpenVtsDateTimeRange(
          start: _startOfDay(today.subtract(const Duration(days: 29))),
          end: _endForDate(today, dateTimeEnabled),
        );
    }
  }

  DateTime _startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  DateTime _endForDate(DateTime date, bool dateTimeEnabled) {
    if (!dateTimeEnabled) {
      return DateUtils.dateOnly(date);
    }

    return DateTime(date.year, date.month, date.day, 23, 59);
  }
}

enum _RangePresetType {
  custom,
  lastHour,
  last3Hours,
  last6Hours,
  last12Hours,
  last24Hours,
  today,
  yesterday,
  thisWeek,
  lastWeek,
  last7Days,
  last30Days,
}
