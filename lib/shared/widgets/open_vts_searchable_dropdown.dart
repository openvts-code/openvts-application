import 'package:flutter/material.dart';

import '../../core/theme/open_vts_colors.dart';
import '../../core/theme/open_vts_radius.dart';
import '../../core/theme/open_vts_spacing.dart';
import '../../core/theme/open_vts_typography.dart';

/// A single option rendered inside an [OpenVtsSearchableDropdown].
///
/// [value] is the identity used for selection and equality checks.
/// [label] is the primary display text.
/// [subtitle] is optional secondary text shown below the label.
/// [leading] can be used to render a custom leading widget (e.g. a flag).
/// [searchText] is an additional, non-displayed string included in the
/// fuzzy search corpus (useful for things like dial codes, ISO codes,
/// abbreviations, etc.).
class OpenVtsDropdownOption<T> {
  const OpenVtsDropdownOption({
    required this.value,
    required this.label,
    this.subtitle,
    this.leading,
    this.searchText,
  });

  final T value;
  final String label;
  final String? subtitle;
  final Widget? leading;
  final String? searchText;

  String _matchHaystack() {
    return [
      label,
      subtitle ?? '',
      searchText ?? '',
    ].join(' ').toLowerCase();
  }
}

/// A dropdown that opens a bottom-sheet picker with built-in search.
///
/// Designed to be a drop-in replacement for [DropdownButtonFormField] in
/// long-list scenarios (country / state / city / dial code, etc.) while
/// staying visually consistent with [OpenVtsTextField].
class OpenVtsSearchableDropdown<T> extends StatefulWidget {
  const OpenVtsSearchableDropdown({
    super.key,
    required this.label,
    required this.options,
    required this.onChanged,
    this.value,
    this.hintText,
    this.helperText,
    this.searchHintText,
    this.emptyMessage,
    this.sheetTitle,
    this.leadingIcon,
    this.isLoading = false,
    this.enabled = true,
    this.required = false,
    this.validator,
  });

  /// Label rendered above the field (matches OpenVtsTextField style).
  final String label;

  /// All selectable options. Filtered locally via case-insensitive search.
  final List<OpenVtsDropdownOption<T>> options;

  /// Called whenever the user picks an option.
  final ValueChanged<T?> onChanged;

  /// Currently selected value. Pass `null` for "no selection".
  final T? value;

  /// Placeholder text shown when nothing is selected.
  final String? hintText;

  /// Optional helper text shown below the field (replaced by validator error
  /// when one is present).
  final String? helperText;

  /// Hint shown inside the search box of the picker sheet.
  final String? searchHintText;

  /// Copy used by the empty state when the search returns no results.
  final String? emptyMessage;

  /// Title at the top of the picker sheet. Defaults to [label].
  final String? sheetTitle;

  /// Optional icon shown on the left of the trigger.
  final IconData? leadingIcon;

  /// Show a loading indicator instead of the chevron when true.
  final bool isLoading;

  /// Whether the field can be opened/edited.
  final bool enabled;

  /// Marks the label with a red asterisk and is used by [validator]'s default.
  final bool required;

  /// Optional validator (integrates with surrounding `Form`s via FormField).
  final FormFieldValidator<T>? validator;

  @override
  State<OpenVtsSearchableDropdown<T>> createState() =>
      _OpenVtsSearchableDropdownState<T>();
}

class _OpenVtsSearchableDropdownState<T>
    extends State<OpenVtsSearchableDropdown<T>> {
  final GlobalKey<FormFieldState<T>> _fieldKey = GlobalKey<FormFieldState<T>>();

  @override
  void didUpdateWidget(covariant OpenVtsSearchableDropdown<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      // Defer the FormField mutation to after the current build phase to
      // avoid "setState() called during build" when a parent rebuilds us
      // with a new value (e.g. cascading country -> state -> city resets).
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        final fieldState = _fieldKey.currentState;
        if (fieldState != null && fieldState.value != widget.value) {
          fieldState.didChange(widget.value);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FormField<T>(
      key: _fieldKey,
      initialValue: widget.value,
      enabled: widget.enabled,
      validator: widget.validator,
      builder: (field) => _buildField(context, field),
    );
  }

  Widget _buildField(BuildContext context, FormFieldState<T> field) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasError = field.hasError;
    // Display the externally-controlled `widget.value` rather than the
    // FormField's internal value. The FormField is synced post-frame in
    // [didUpdateWidget]; using it directly here would make cascading parent
    // resets render one frame stale.
    final selectedOption = _findSelected(widget.value);
    final hintColor = isDark
        ? OpenVtsColors.darkTextSecondary.withValues(alpha: 0.7)
        : OpenVtsColors.textTertiary;

    final triggerBorderColor = hasError
        ? OpenVtsColors.error
        : (isDark ? OpenVtsColors.darkBorder : OpenVtsColors.border);
    final triggerBackground = !widget.enabled
        ? (isDark
            ? OpenVtsColors.darkSurface.withValues(alpha: 0.5)
            : OpenVtsColors.surface)
        : (isDark ? OpenVtsColors.darkSurface : OpenVtsColors.white);

    final labelColor = !widget.enabled
        ? OpenVtsColors.textTertiary
        : (isDark
            ? OpenVtsColors.darkTextPrimary
            : OpenVtsColors.textPrimary);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Label(
          label: widget.label,
          required: widget.required,
          color: labelColor,
        ),
        const SizedBox(height: OpenVtsSpacing.xs),
        Semantics(
          button: true,
          enabled: widget.enabled,
          label: '${widget.label} dropdown',
          child: InkWell(
            borderRadius: BorderRadius.circular(OpenVtsRadius.md),
            onTap: widget.enabled && !widget.isLoading
                ? () => _openPicker(context, field)
                : null,
            child: Container(
              constraints: const BoxConstraints(minHeight: 48),
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: triggerBackground,
                borderRadius: BorderRadius.circular(OpenVtsRadius.md),
                border: Border.all(
                  color: triggerBorderColor,
                  width: hasError ? 1.4 : 1,
                ),
              ),
              child: Row(
                children: [
                  if (widget.leadingIcon != null) ...[
                    Icon(
                      widget.leadingIcon,
                      size: 18,
                      color: OpenVtsColors.textSecondary,
                    ),
                    const SizedBox(width: OpenVtsSpacing.sm),
                  ],
                  Expanded(
                    child: _ValueDisplay<T>(
                      option: selectedOption,
                      hintText: widget.hintText ?? 'Select ${widget.label}',
                      hintColor: hintColor,
                    ),
                  ),
                  const SizedBox(width: OpenVtsSpacing.xs),
                  if (widget.isLoading)
                    const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    Icon(
                      Icons.unfold_more_rounded,
                      size: 18,
                      color: widget.enabled
                          ? OpenVtsColors.textSecondary
                          : OpenVtsColors.textTertiary,
                    ),
                ],
              ),
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 6),
          Text(
            field.errorText!,
            style: OpenVtsTypography.meta.copyWith(
              color: OpenVtsColors.error,
              fontWeight: FontWeight.w500,
            ),
          ),
        ] else if (widget.helperText != null) ...[
          const SizedBox(height: 6),
          Text(
            widget.helperText!,
            style: OpenVtsTypography.meta.copyWith(
              color: OpenVtsColors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }

  OpenVtsDropdownOption<T>? _findSelected(T? value) {
    if (value == null) {
      return null;
    }
    for (final option in widget.options) {
      if (option.value == value) {
        return option;
      }
    }
    return null;
  }

  Future<void> _openPicker(
    BuildContext context,
    FormFieldState<T> field,
  ) async {
    final selected = await showModalBottomSheet<_PickerResult<T>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(OpenVtsRadius.xl),
        ),
      ),
      builder: (sheetContext) {
        return _SearchableDropdownSheet<T>(
          title: widget.sheetTitle ?? widget.label,
          options: widget.options,
          selectedValue: widget.value,
          searchHintText: widget.searchHintText ??
              'Search ${widget.label.toLowerCase()}',
          emptyMessage:
              widget.emptyMessage ?? 'No matching ${widget.label.toLowerCase()}',
        );
      },
    );

    if (selected == null) {
      return;
    }

    final nextValue = selected.cleared ? null : selected.option?.value;
    // Safe to update the FormField synchronously here: we are inside a user
    // gesture callback, not a build phase.
    field.didChange(nextValue);
    widget.onChanged(nextValue);
  }
}

// ---------------------------------------------------------------------------
// Trigger sub-widgets
// ---------------------------------------------------------------------------

class _Label extends StatelessWidget {
  const _Label({
    required this.label,
    required this.required,
    required this.color,
  });

  final String label;
  final bool required;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: OpenVtsTypography.label.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (required) ...[
          const SizedBox(width: 2),
          const Text(
            '*',
            style: TextStyle(
              color: OpenVtsColors.error,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ],
    );
  }
}

class _ValueDisplay<T> extends StatelessWidget {
  const _ValueDisplay({
    required this.option,
    required this.hintText,
    required this.hintColor,
  });

  final OpenVtsDropdownOption<T>? option;
  final String hintText;
  final Color hintColor;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark
        ? OpenVtsColors.darkTextPrimary
        : OpenVtsColors.textPrimary;

    if (option == null) {
      return Text(
        hintText,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: OpenVtsTypography.body.copyWith(color: hintColor),
      );
    }

    final hasSubtitle = (option!.subtitle ?? '').trim().isNotEmpty;

    return Row(
      children: [
        if (option!.leading != null) ...[
          option!.leading!,
          const SizedBox(width: OpenVtsSpacing.xs),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                option!.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: OpenVtsTypography.body.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (hasSubtitle)
                Padding(
                  padding: const EdgeInsets.only(top: 1),
                  child: Text(
                    option!.subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: OpenVtsTypography.meta.copyWith(
                      color: OpenVtsColors.textSecondary,
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

// ---------------------------------------------------------------------------
// Picker sheet
// ---------------------------------------------------------------------------

class _PickerResult<T> {
  const _PickerResult.selected(this.option) : cleared = false;
  const _PickerResult.cleared()
      : option = null,
        cleared = true;

  final OpenVtsDropdownOption<T>? option;
  final bool cleared;
}

class _SearchableDropdownSheet<T> extends StatefulWidget {
  const _SearchableDropdownSheet({
    required this.title,
    required this.options,
    required this.selectedValue,
    required this.searchHintText,
    required this.emptyMessage,
  });

  final String title;
  final List<OpenVtsDropdownOption<T>> options;
  final T? selectedValue;
  final String searchHintText;
  final String emptyMessage;

  @override
  State<_SearchableDropdownSheet<T>> createState() =>
      _SearchableDropdownSheetState<T>();
}

class _SearchableDropdownSheetState<T>
    extends State<_SearchableDropdownSheet<T>> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  List<OpenVtsDropdownOption<T>> get _filtered {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) {
      return widget.options;
    }
    return widget.options
        .where((option) => option._matchHaystack().contains(query))
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final maxHeight = mediaQuery.size.height * 0.85;
    final bottomInset = mediaQuery.viewInsets.bottom;
    final filtered = _filtered;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: OpenVtsSpacing.sm),
              Center(
                child: Container(
                  height: 4,
                  width: 40,
                  decoration: BoxDecoration(
                    color: OpenVtsColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: OpenVtsSpacing.md),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: OpenVtsSpacing.md,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.title,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                      ),
                    ),
                    if (widget.selectedValue != null)
                      TextButton(
                        onPressed: () => Navigator.of(context)
                            .pop<_PickerResult<T>>(_PickerResult.cleared()),
                        style: TextButton.styleFrom(
                          foregroundColor: OpenVtsColors.textSecondary,
                          visualDensity: VisualDensity.compact,
                        ),
                        child: const Text('Clear'),
                      ),
                    IconButton(
                      tooltip: 'Close',
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.close_rounded, size: 20),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: OpenVtsSpacing.xs),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: OpenVtsSpacing.md,
                ),
                child: _SheetSearchField(
                  controller: _searchController,
                  focusNode: _searchFocus,
                  hintText: widget.searchHintText,
                  onChanged: (value) => setState(() => _query = value),
                ),
              ),
              const SizedBox(height: OpenVtsSpacing.sm),
              const Divider(height: 1, color: OpenVtsColors.divider),
              Flexible(
                child: filtered.isEmpty
                    ? _EmptyResults(message: widget.emptyMessage)
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(
                          vertical: OpenVtsSpacing.xs,
                        ),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 2),
                        itemBuilder: (context, index) {
                          final option = filtered[index];
                          final isSelected =
                              widget.selectedValue == option.value;
                          return _OptionRow<T>(
                            option: option,
                            isSelected: isSelected,
                            onTap: () => Navigator.of(context).pop(
                              _PickerResult<T>.selected(option),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SheetSearchField extends StatelessWidget {
  const _SheetSearchField({
    required this.controller,
    required this.focusNode,
    required this.hintText,
    required this.onChanged,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String hintText;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fillColor =
        isDark ? OpenVtsColors.darkSurface : OpenVtsColors.background;
    final borderColor =
        isDark ? OpenVtsColors.darkBorder : OpenVtsColors.border;

    return SizedBox(
      height: 44,
      child: ValueListenableBuilder<TextEditingValue>(
        valueListenable: controller,
        builder: (context, value, _) {
          final hasText = value.text.isNotEmpty;
          return TextField(
            controller: controller,
            focusNode: focusNode,
            autofocus: true,
            textAlignVertical: TextAlignVertical.center,
            onChanged: onChanged,
            style: const TextStyle(
              fontFamily: OpenVtsTypography.primaryFontFamily,
              fontFamilyFallback: OpenVtsTypography.fontFallback,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: OpenVtsColors.textPrimary,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: fillColor,
              isDense: true,
              hintText: hintText,
              hintStyle: const TextStyle(
                fontFamily: OpenVtsTypography.primaryFontFamily,
                fontFamilyFallback: OpenVtsTypography.fontFallback,
                fontSize: 14,
                color: OpenVtsColors.textTertiary,
                fontWeight: FontWeight.w400,
              ),
              prefixIcon: const Padding(
                padding: EdgeInsetsDirectional.only(start: 12, end: 8),
                child: Icon(
                  Icons.search_rounded,
                  size: 18,
                  color: OpenVtsColors.textSecondary,
                ),
              ),
              prefixIconConstraints: const BoxConstraints(
                minWidth: 0,
                minHeight: 44,
              ),
              suffixIcon: !hasText
                  ? null
                  : Padding(
                      padding: const EdgeInsetsDirectional.only(end: 4),
                      child: IconButton(
                        tooltip: 'Clear search',
                        onPressed: () {
                          controller.clear();
                          onChanged('');
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 28,
                          minHeight: 28,
                        ),
                        splashRadius: 16,
                        icon: const Icon(
                          Icons.close_rounded,
                          size: 16,
                          color: OpenVtsColors.textSecondary,
                        ),
                      ),
                    ),
              suffixIconConstraints: const BoxConstraints(
                minWidth: 0,
                minHeight: 44,
              ),
              contentPadding: const EdgeInsetsDirectional.only(end: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(OpenVtsRadius.md),
                borderSide: BorderSide(color: borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(OpenVtsRadius.md),
                borderSide: BorderSide(color: borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(OpenVtsRadius.md),
                borderSide: BorderSide(
                  color: isDark
                      ? OpenVtsColors.darkTextPrimary
                      : OpenVtsColors.brandInk,
                  width: 1.2,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _OptionRow<T> extends StatelessWidget {
  const _OptionRow({
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  final OpenVtsDropdownOption<T> option;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasSubtitle = (option.subtitle ?? '').trim().isNotEmpty;
    final background =
        isSelected ? OpenVtsColors.surface : Colors.transparent;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedBackground =
        isDark ? OpenVtsColors.darkSurface : OpenVtsColors.surface;

    return Material(
      color: isSelected ? selectedBackground : background,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: OpenVtsSpacing.md,
            vertical: OpenVtsSpacing.sm + 2,
          ),
          child: Row(
            children: [
              if (option.leading != null) ...[
                option.leading!,
                const SizedBox(width: OpenVtsSpacing.sm),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      option.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: OpenVtsTypography.body.copyWith(
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: OpenVtsColors.textPrimary,
                      ),
                    ),
                    if (hasSubtitle) ...[
                      const SizedBox(height: 2),
                      Text(
                        option.subtitle!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: OpenVtsTypography.meta.copyWith(
                          color: OpenVtsColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: OpenVtsSpacing.sm),
              Icon(
                isSelected
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_off_rounded,
                size: 18,
                color: isSelected
                    ? OpenVtsColors.brandInk
                    : OpenVtsColors.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyResults extends StatelessWidget {
  const _EmptyResults({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: OpenVtsSpacing.lg,
        vertical: OpenVtsSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.search_off_rounded,
            size: 32,
            color: OpenVtsColors.textTertiary,
          ),
          const SizedBox(height: OpenVtsSpacing.xs),
          Text(
            message,
            textAlign: TextAlign.center,
            style: OpenVtsTypography.body.copyWith(
              color: OpenVtsColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
