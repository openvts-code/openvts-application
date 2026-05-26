import 'package:flutter/material.dart';

import '../../../../../core/theme/open_vts_colors.dart';
import '../../../../../core/theme/open_vts_radius.dart';
import '../../../../../core/theme/open_vts_spacing.dart';
import '../../../../../core/theme/open_vts_typography.dart';
import '../../../../../shared/widgets/open_vts_card.dart';

class UserLocalizationSelectCard extends StatelessWidget {
  const UserLocalizationSelectCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.child,
    this.trailing,
    super.key,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return OpenVtsCard(
      padding: const EdgeInsets.all(OpenVtsSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: OpenVtsColors.surface,
                  borderRadius: BorderRadius.circular(OpenVtsRadius.sm),
                  border: Border.all(color: OpenVtsColors.border),
                ),
                child: Icon(
                  icon,
                  size: 15,
                  color: OpenVtsColors.textSecondary,
                ),
              ),
              const SizedBox(width: OpenVtsSpacing.xs),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: OpenVtsTypography.label.copyWith(
                        color: OpenVtsColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: OpenVtsSpacing.xxs),
                    Text(
                      subtitle,
                      style: OpenVtsTypography.meta.copyWith(
                        color: OpenVtsColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: OpenVtsSpacing.xs),
                trailing!,
              ],
            ],
          ),
          const SizedBox(height: OpenVtsSpacing.sm),
          child,
        ],
      ),
    );
  }
}

class UserLocalizationOption<T> {
  const UserLocalizationOption({
    required this.value,
    required this.label,
    this.searchTokens = const <String>[],
    this.subtitle,
  });

  final T value;
  final String label;
  final List<String> searchTokens;
  final String? subtitle;
}

class UserLocalizationPickerTile extends StatelessWidget {
  const UserLocalizationPickerTile({
    required this.label,
    required this.valueLabel,
    required this.onTap,
    this.hintText,
    super.key,
  });

  final String label;
  final String? valueLabel;
  final String? hintText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final value = valueLabel?.trim();
    final hasValue = value != null && value.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: OpenVtsTypography.meta.copyWith(
            color: OpenVtsColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: OpenVtsSpacing.xxs),
        Semantics(
          button: true,
          label: '$label picker',
          child: InkWell(
            borderRadius: BorderRadius.circular(OpenVtsRadius.sm),
            onTap: onTap,
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(minHeight: 44),
              padding: const EdgeInsets.symmetric(
                horizontal: OpenVtsSpacing.sm,
                vertical: OpenVtsSpacing.xs,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(OpenVtsRadius.sm),
                border: Border.all(color: OpenVtsColors.border),
                color: OpenVtsColors.surface,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      hasValue ? value : (hintText ?? 'Select'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: OpenVtsTypography.body.copyWith(
                        color: hasValue
                            ? OpenVtsColors.textPrimary
                            : OpenVtsColors.textTertiary,
                      ),
                    ),
                  ),
                  const SizedBox(width: OpenVtsSpacing.xxs),
                  const Icon(
                    Icons.expand_more_rounded,
                    size: 18,
                    color: OpenVtsColors.textTertiary,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class UserLocalizationSegmentOption<T> {
  const UserLocalizationSegmentOption({
    required this.value,
    required this.label,
  });

  final T value;
  final String label;
}

class UserLocalizationSegmentedControl<T> extends StatelessWidget {
  const UserLocalizationSegmentedControl({
    required this.value,
    required this.segments,
    required this.onChanged,
    this.semanticsLabel,
    super.key,
  });

  final T value;
  final List<UserLocalizationSegmentOption<T>> segments;
  final ValueChanged<T> onChanged;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: semanticsLabel,
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: OpenVtsColors.surface,
          borderRadius: BorderRadius.circular(OpenVtsRadius.sm),
          border: Border.all(color: OpenVtsColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: segments
              .map(
                (segment) => _SegmentButton(
                  label: segment.label,
                  selected: segment.value == value,
                  onTap: () => onChanged(segment.value),
                ),
              )
              .toList(growable: false),
        ),
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  const _SegmentButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        borderRadius: BorderRadius.circular(OpenVtsRadius.sm - 2),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          constraints: const BoxConstraints(minHeight: 44, minWidth: 44),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? OpenVtsColors.brandInk : Colors.transparent,
            borderRadius: BorderRadius.circular(OpenVtsRadius.sm - 2),
          ),
          child: Center(
            child: Text(
              label,
              style: OpenVtsTypography.meta.copyWith(
                color:
                    selected ? OpenVtsColors.white : OpenVtsColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Future<T?> showLocalizationOptionPicker<T>({
  required BuildContext context,
  required String title,
  required List<UserLocalizationOption<T>> options,
  required T? selectedValue,
  String searchHintText = 'Search',
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) {
      return _LocalizationOptionPickerSheet<T>(
        title: title,
        options: options,
        selectedValue: selectedValue,
        searchHintText: searchHintText,
      );
    },
  );
}

class _LocalizationOptionPickerSheet<T> extends StatefulWidget {
  const _LocalizationOptionPickerSheet({
    required this.title,
    required this.options,
    required this.selectedValue,
    required this.searchHintText,
  });

  final String title;
  final List<UserLocalizationOption<T>> options;
  final T? selectedValue;
  final String searchHintText;

  @override
  State<_LocalizationOptionPickerSheet<T>> createState() =>
      _LocalizationOptionPickerSheetState<T>();
}

class _LocalizationOptionPickerSheetState<T>
    extends State<_LocalizationOptionPickerSheet<T>> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final insets = MediaQuery.viewInsetsOf(context).bottom;
    final options = _filteredOptions();

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: OpenVtsColors.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(OpenVtsRadius.lg),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            OpenVtsSpacing.md,
            OpenVtsSpacing.md,
            OpenVtsSpacing.md,
            OpenVtsSpacing.sm + insets,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.title,
                style: OpenVtsTypography.label.copyWith(
                  color: OpenVtsColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: OpenVtsSpacing.xs),
              TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _query = value;
                  });
                },
                decoration: InputDecoration(
                  hintText: widget.searchHintText,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: OpenVtsSpacing.sm,
                    vertical: OpenVtsSpacing.xs,
                  ),
                  prefixIcon: const Icon(Icons.search_rounded, size: 16),
                ),
              ),
              const SizedBox(height: OpenVtsSpacing.xs),
              Flexible(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 320),
                  child: options.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: Text(
                              'No options found.',
                              style: OpenVtsTypography.meta.copyWith(
                                color: OpenVtsColors.textSecondary,
                              ),
                            ),
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          itemCount: options.length,
                          separatorBuilder: (_, __) => const Divider(
                            height: 1,
                            color: OpenVtsColors.border,
                          ),
                          itemBuilder: (context, index) {
                            final option = options[index];
                            final isSelected =
                                option.value == widget.selectedValue;
                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: OpenVtsSpacing.xs,
                                vertical: 0,
                              ),
                              title: Text(
                                option.label,
                                style: OpenVtsTypography.body.copyWith(
                                  color: OpenVtsColors.textPrimary,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                ),
                              ),
                              subtitle: option.subtitle == null
                                  ? null
                                  : Text(
                                      option.subtitle!,
                                      style: OpenVtsTypography.meta.copyWith(
                                        color: OpenVtsColors.textSecondary,
                                      ),
                                    ),
                              trailing: isSelected
                                  ? const Icon(
                                      Icons.check_rounded,
                                      size: 16,
                                      color: OpenVtsColors.success,
                                    )
                                  : null,
                              onTap: () {
                                Navigator.of(context).pop(option.value);
                              },
                            );
                          },
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<UserLocalizationOption<T>> _filteredOptions() {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) {
      return widget.options;
    }

    return widget.options.where((option) {
      if (option.label.toLowerCase().contains(query)) {
        return true;
      }

      if (option.subtitle?.toLowerCase().contains(query) == true) {
        return true;
      }

      for (final token in option.searchTokens) {
        if (token.toLowerCase().contains(query)) {
          return true;
        }
      }
      return false;
    }).toList(growable: false);
  }
}
