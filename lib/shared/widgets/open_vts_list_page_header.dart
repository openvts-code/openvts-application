import 'package:flutter/material.dart';

import '../../core/theme/open_vts_colors.dart';
import '../../core/theme/open_vts_radius.dart';
import '../../core/theme/open_vts_spacing.dart';
import '../../core/theme/open_vts_typography.dart';
import 'open_vts_button.dart';

const List<int> openVtsListPageRecordsOptions = <int>[10, 25, 50, 100];

class OpenVtsListPageHeaderCard extends StatelessWidget {
  const OpenVtsListPageHeaderCard({
    super.key,
    required this.icon,
    required this.countLabel,
    required this.createLabel,
    required this.onCreate,
    this.isCreateLoading = false,
    this.footer,
  });

  final IconData icon;
  final String countLabel;
  final String createLabel;
  final VoidCallback onCreate;
  final bool isCreateLoading;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return OpenVtsListPageRoundedSurface(
      padding: const EdgeInsets.fromLTRB(
        OpenVtsSpacing.md,
        OpenVtsSpacing.sm,
        OpenVtsSpacing.sm,
        OpenVtsSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                height: 44,
                width: 44,
                decoration: BoxDecoration(
                  color: OpenVtsListPageTheme.softSurfaceColor(context),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(
                  icon,
                  size: 22,
                  color: OpenVtsListPageTheme.primaryInkColor(context),
                ),
              ),
              const SizedBox(width: OpenVtsSpacing.sm),
              Expanded(
                child: Text(
                  countLabel,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                ),
              ),
              const SizedBox(width: OpenVtsSpacing.sm),
              OpenVtsListPageCreateButton(
                label: createLabel,
                onPressed: onCreate,
                isLoading: isCreateLoading,
              ),
            ],
          ),
          if (footer != null) ...[
            const SizedBox(height: OpenVtsSpacing.sm),
            footer!,
          ],
        ],
      ),
    );
  }
}

class OpenVtsListPageCreateButton extends StatelessWidget {
  const OpenVtsListPageCreateButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background =
        isDark ? OpenVtsColors.surfaceElevated : OpenVtsColors.brandInk;
    final foreground = isDark ? OpenVtsColors.brandInk : OpenVtsColors.white;

    return ElevatedButton.icon(
      onPressed: isLoading ? null : onPressed,
      icon: isLoading
          ? SizedBox.square(
              dimension: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: foreground,
              ),
            )
          : const Icon(Icons.add_rounded, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: background,
        foregroundColor: foreground,
        disabledBackgroundColor: background.withValues(alpha: 0.72),
        disabledForegroundColor: foreground.withValues(alpha: 0.72),
        elevation: 0,
        padding: const EdgeInsets.symmetric(
          horizontal: OpenVtsSpacing.md,
          vertical: OpenVtsSpacing.sm,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(OpenVtsRadius.md),
        ),
        textStyle: OpenVtsTypography.label.copyWith(
          fontWeight: FontWeight.w600,
        ),
        visualDensity: VisualDensity.compact,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}

class OpenVtsListPageToolbar extends StatefulWidget {
  const OpenVtsListPageToolbar({
    super.key,
    required this.searchQuery,
    required this.hintText,
    required this.onSearchChanged,
    this.filterTooltip,
    this.onOpenFilters,
    this.hasActiveFilters = false,
    this.sortTooltip,
    this.onOpenSort,
    this.recordsPerPage,
    this.onRecordsChanged,
    this.recordsOptions = openVtsListPageRecordsOptions,
  });

  final String searchQuery;
  final String hintText;
  final ValueChanged<String> onSearchChanged;
  final String? filterTooltip;
  final VoidCallback? onOpenFilters;
  final bool hasActiveFilters;
  final String? sortTooltip;
  final VoidCallback? onOpenSort;
  final int? recordsPerPage;
  final ValueChanged<int>? onRecordsChanged;
  final List<int> recordsOptions;

  @override
  State<OpenVtsListPageToolbar> createState() => _OpenVtsListPageToolbarState();
}

class _OpenVtsListPageToolbarState extends State<OpenVtsListPageToolbar> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.searchQuery);
  }

  @override
  void didUpdateWidget(covariant OpenVtsListPageToolbar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.searchQuery != _searchController.text) {
      _searchController.value = TextEditingValue(
        text: widget.searchQuery,
        selection: TextSelection.collapsed(offset: widget.searchQuery.length),
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return OpenVtsListPageRoundedSurface(
      padding: const EdgeInsets.all(OpenVtsSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: OpenVtsListPageSearchInput(
              controller: _searchController,
              hintText: widget.hintText,
              onChanged: widget.onSearchChanged,
            ),
          ),
          if (widget.onOpenFilters != null) ...[
            const SizedBox(width: OpenVtsSpacing.xs),
            OpenVtsListPageSquareIconButton(
              icon: Icons.filter_alt_outlined,
              tooltip: widget.filterTooltip ?? 'Filter',
              onPressed: widget.onOpenFilters!,
              showDot: widget.hasActiveFilters,
            ),
          ],
          if (widget.onOpenSort != null) ...[
            const SizedBox(width: OpenVtsSpacing.xs),
            OpenVtsListPageSquareIconButton(
              icon: Icons.swap_vert_rounded,
              tooltip: widget.sortTooltip ?? 'Sort',
              onPressed: widget.onOpenSort!,
            ),
          ],
          if (widget.recordsPerPage != null &&
              widget.onRecordsChanged != null) ...[
            const SizedBox(width: OpenVtsSpacing.xs),
            OpenVtsListPageRecordsDropdown(
              value: widget.recordsPerPage!,
              options: widget.recordsOptions,
              onChanged: widget.onRecordsChanged!,
            ),
          ],
        ],
      ),
    );
  }
}

class OpenVtsListPageSearchInput extends StatelessWidget {
  const OpenVtsListPageSearchInput({
    super.key,
    required this.controller,
    required this.hintText,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String> onChanged;

  static const double _height = 40;

  static const TextStyle _baseStyle = TextStyle(
    fontFamily: OpenVtsTypography.primaryFontFamily,
    fontFamilyFallback: OpenVtsTypography.fontFallback,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.2,
    leadingDistribution: TextLeadingDistribution.even,
  );

  @override
  Widget build(BuildContext context) {
    final fillColor = OpenVtsListPageTheme.softSurfaceColor(context);
    final borderColor = OpenVtsListPageTheme.softBorderColor(context);

    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(OpenVtsRadius.md),
      borderSide: BorderSide(color: borderColor),
    );
    final focusedBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(OpenVtsRadius.md),
      borderSide: BorderSide(
        color: OpenVtsListPageTheme.primaryInkColor(context),
        width: 1.2,
      ),
    );

    return SizedBox(
      height: _height,
      child: ValueListenableBuilder<TextEditingValue>(
        valueListenable: controller,
        builder: (context, value, _) {
          final hasText = value.text.isNotEmpty;
          return TextField(
            controller: controller,
            onChanged: onChanged,
            textAlignVertical: TextAlignVertical.center,
            cursorColor: OpenVtsListPageTheme.primaryInkColor(context),
            cursorWidth: 1.4,
            style: _baseStyle.copyWith(color: OpenVtsColors.textPrimary),
            strutStyle: const StrutStyle(
              fontFamily: OpenVtsTypography.primaryFontFamily,
              fontFamilyFallback: OpenVtsTypography.fontFallback,
              fontSize: 14,
              height: 1.2,
              leading: 0,
              forceStrutHeight: true,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: fillColor,
              isDense: true,
              isCollapsed: false,
              hintText: hintText,
              hintStyle: _baseStyle.copyWith(
                color: OpenVtsColors.textTertiary,
                fontWeight: FontWeight.w400,
              ),
              prefixIcon: const Padding(
                padding: EdgeInsetsDirectional.only(
                  start: OpenVtsSpacing.sm,
                  end: OpenVtsSpacing.xs,
                ),
                child: Icon(
                  Icons.search_rounded,
                  size: 18,
                  color: OpenVtsColors.textSecondary,
                ),
              ),
              prefixIconConstraints: const BoxConstraints(
                minWidth: 0,
                minHeight: _height,
              ),
              suffixIcon: !hasText
                  ? null
                  : Padding(
                      padding: const EdgeInsetsDirectional.only(
                        end: OpenVtsSpacing.xxs,
                      ),
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
                minHeight: _height,
              ),
              contentPadding: const EdgeInsetsDirectional.only(
                end: OpenVtsSpacing.sm,
              ),
              border: border,
              enabledBorder: border,
              focusedBorder: focusedBorder,
            ),
          );
        },
      ),
    );
  }
}

class OpenVtsListPageSquareIconButton extends StatelessWidget {
  const OpenVtsListPageSquareIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.showDot = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final bool showDot;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: OpenVtsListPageTheme.softSurfaceColor(context),
        borderRadius: BorderRadius.circular(OpenVtsRadius.md),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(OpenVtsRadius.md),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(OpenVtsRadius.md),
                  border: Border.all(
                    color: OpenVtsListPageTheme.softBorderColor(context),
                  ),
                ),
                alignment: Alignment.center,
                child: Icon(
                  icon,
                  size: 18,
                  color: OpenVtsListPageTheme.primaryInkColor(context),
                ),
              ),
              if (showDot)
                PositionedDirectional(
                  top: -2,
                  end: -2,
                  child: Container(
                    height: 10,
                    width: 10,
                    decoration: BoxDecoration(
                      color: OpenVtsColors.brandInk,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Theme.of(context).colorScheme.surface,
                        width: 2,
                      ),
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

class OpenVtsListPageRecordsDropdown extends StatelessWidget {
  const OpenVtsListPageRecordsDropdown({
    super.key,
    required this.value,
    required this.onChanged,
    this.options = openVtsListPageRecordsOptions,
  });

  final int value;
  final ValueChanged<int> onChanged;
  final List<int> options;

  @override
  Widget build(BuildContext context) {
    final resolvedOptions = <int>[
      ...options,
      if (!options.contains(value)) value,
    ]..sort();

    return Container(
      height: 40,
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: OpenVtsSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: OpenVtsListPageTheme.softSurfaceColor(context),
        borderRadius: BorderRadius.circular(OpenVtsRadius.md),
        border: Border.all(color: OpenVtsListPageTheme.softBorderColor(context)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: value,
          isDense: true,
          icon: const Padding(
            padding: EdgeInsetsDirectional.only(start: 2),
            child: Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 16,
              color: OpenVtsColors.textSecondary,
            ),
          ),
          style: OpenVtsTypography.label.copyWith(
            color: OpenVtsListPageTheme.primaryInkColor(context),
            fontWeight: FontWeight.w600,
          ),
          dropdownColor: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(OpenVtsRadius.md),
          items: resolvedOptions
              .map(
                (option) => DropdownMenuItem<int>(
                  value: option,
                  child: Text('$option'),
                ),
              )
              .toList(growable: false),
          onChanged: (next) {
            if (next != null) {
              onChanged(next);
            }
          },
        ),
      ),
    );
  }
}

class OpenVtsListPagePaginationFooter extends StatelessWidget {
  const OpenVtsListPagePaginationFooter({
    super.key,
    required this.currentPage,
    required this.pageCount,
    required this.showingCount,
    required this.totalCount,
    required this.onPrev,
    required this.onNext,
  });

  final int currentPage;
  final int pageCount;
  final int showingCount;
  final int totalCount;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final canPrev = currentPage > 1;
    final canNext = currentPage < pageCount;

    return Padding(
      padding: const EdgeInsets.only(top: OpenVtsSpacing.xs),
      child: Column(
        children: [
          Text(
            'Showing $showingCount of $totalCount',
            style: OpenVtsTypography.meta.copyWith(
              color: OpenVtsColors.textSecondary,
            ),
          ),
          if (pageCount > 1) ...[
            const SizedBox(height: OpenVtsSpacing.xs),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OpenVtsListPagePageButton(
                  icon: Icons.chevron_left_rounded,
                  onPressed: canPrev ? onPrev : null,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: OpenVtsSpacing.sm,
                  ),
                  child: Text(
                    'Page $currentPage of $pageCount',
                    style: OpenVtsTypography.label.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                OpenVtsListPagePageButton(
                  icon: Icons.chevron_right_rounded,
                  onPressed: canNext ? onNext : null,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class OpenVtsListPagePageButton extends StatelessWidget {
  const OpenVtsListPagePageButton({
    super.key,
    required this.icon,
    required this.onPressed,
  });

  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Material(
      color: enabled
          ? OpenVtsListPageTheme.softSurfaceColor(context)
          : OpenVtsListPageTheme.softSurfaceColor(context)
              .withValues(alpha: 0.6),
      borderRadius: BorderRadius.circular(OpenVtsRadius.md),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(OpenVtsRadius.md),
        child: Container(
          height: 36,
          width: 36,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(OpenVtsRadius.md),
            border: Border.all(
              color: OpenVtsListPageTheme.softBorderColor(context),
            ),
          ),
          alignment: Alignment.center,
          child: Icon(
            icon,
            size: 18,
            color: enabled
                ? OpenVtsListPageTheme.primaryInkColor(context)
                : OpenVtsColors.textTertiary,
          ),
        ),
      ),
    );
  }
}

class OpenVtsListPageOptionsSheet extends StatelessWidget {
  const OpenVtsListPageOptionsSheet({
    super.key,
    required this.title,
    required this.sections,
    this.primaryActionLabel,
    this.onPrimaryAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
  });

  final String title;
  final List<OpenVtsListPageOptionsSection> sections;
  final String? primaryActionLabel;
  final VoidCallback? onPrimaryAction;
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          OpenVtsSpacing.md,
          OpenVtsSpacing.sm,
          OpenVtsSpacing.md,
          OpenVtsSpacing.lg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                height: 4,
                width: 40,
                margin: const EdgeInsets.only(bottom: OpenVtsSpacing.sm),
                decoration: BoxDecoration(
                  color: OpenVtsColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.close_rounded, size: 20),
                  tooltip: 'Close',
                ),
              ],
            ),
            const SizedBox(height: OpenVtsSpacing.sm),
            for (final section in sections) ...[
              Text(
                section.label,
                style: OpenVtsTypography.label.copyWith(
                  color: OpenVtsColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: OpenVtsSpacing.xs),
              section.child,
              const SizedBox(height: OpenVtsSpacing.md),
            ],
            if (primaryActionLabel != null || secondaryActionLabel != null) ...[
              const SizedBox(height: OpenVtsSpacing.xs),
              Row(
                children: [
                  if (secondaryActionLabel != null) ...[
                    Expanded(
                      child: OpenVtsButton(
                        label: secondaryActionLabel!,
                        variant: OpenVtsButtonVariant.secondary,
                        onPressed: onSecondaryAction,
                      ),
                    ),
                    const SizedBox(width: OpenVtsSpacing.sm),
                  ],
                  if (primaryActionLabel != null)
                    Expanded(
                      child: OpenVtsButton(
                        label: primaryActionLabel!,
                        onPressed: onPrimaryAction,
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class OpenVtsListPageOptionsSection {
  const OpenVtsListPageOptionsSection({
    required this.label,
    required this.child,
  });

  final String label;
  final Widget child;
}

class OpenVtsListPageChoiceChip extends StatelessWidget {
  const OpenVtsListPageChoiceChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final background = selected
        ? OpenVtsListPageTheme.primaryInkColor(context)
        : OpenVtsListPageTheme.softSurfaceColor(context);
    final foreground = selected
        ? Theme.of(context).colorScheme.surface
        : OpenVtsListPageTheme.primaryInkColor(context);

    return Material(
      color: background,
      borderRadius: BorderRadius.circular(OpenVtsRadius.pill),
      child: InkWell(
        onTap: onSelected,
        borderRadius: BorderRadius.circular(OpenVtsRadius.pill),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: OpenVtsSpacing.md,
            vertical: OpenVtsSpacing.xs,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(OpenVtsRadius.pill),
            border: Border.all(
              color: selected
                  ? OpenVtsListPageTheme.primaryInkColor(context)
                  : OpenVtsListPageTheme.softBorderColor(context),
            ),
          ),
          child: Text(
            label,
            style: OpenVtsTypography.label.copyWith(
              color: foreground,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class OpenVtsListPageRadioRow extends StatelessWidget {
  const OpenVtsListPageRadioRow({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(OpenVtsRadius.md),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: OpenVtsSpacing.xs,
          vertical: OpenVtsSpacing.sm,
        ),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              size: 18,
              color: selected
                  ? OpenVtsListPageTheme.primaryInkColor(context)
                  : OpenVtsColors.textTertiary,
            ),
            const SizedBox(width: OpenVtsSpacing.sm),
            Expanded(
              child: Text(
                label,
                style: OpenVtsTypography.label.copyWith(
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: OpenVtsListPageTheme.primaryInkColor(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OpenVtsListPageRoundedSurface extends StatelessWidget {
  const OpenVtsListPageRoundedSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(OpenVtsSpacing.md),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(OpenVtsRadius.lg),
        border: Border.all(color: OpenVtsListPageTheme.softBorderColor(context)),
      ),
      child: child,
    );
  }
}

class OpenVtsListPageTheme {
  OpenVtsListPageTheme._();

  static Color softSurfaceColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? OpenVtsColors.darkSurface
        : OpenVtsColors.background;
  }

  static Color softBorderColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? OpenVtsColors.darkBorder
        : OpenVtsColors.border;
  }

  static Color primaryInkColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? OpenVtsColors.darkTextPrimary
        : OpenVtsColors.brandInk;
  }
}
