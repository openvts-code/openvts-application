import 'package:flutter/material.dart';

import '../../../../../core/theme/open_vts_colors.dart';
import '../../../../../core/theme/open_vts_spacing.dart';
import '../../../../../core/theme/open_vts_typography.dart';

class AdminUserDropdownOption {
  const AdminUserDropdownOption({
    required this.value,
    required this.label,
    this.isFallback = false,
  });

  final String value;
  final String label;
  final bool isFallback;
}

class AdminUserFormSection extends StatelessWidget {
  const AdminUserFormSection({
    required this.title,
    required this.children,
    super.key,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: OpenVtsTypography.label.copyWith(
            color: OpenVtsColors.textSecondary,
          ),
        ),
        const SizedBox(height: OpenVtsSpacing.sm),
        ...children,
      ],
    );
  }
}

class AdminUserDropdownField extends StatelessWidget {
  const AdminUserDropdownField({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    this.hintText,
    this.prefixIcon,
    this.validator,
    this.isLoading = false,
    super.key,
  });

  final String label;
  final String? value;
  final List<AdminUserDropdownOption> options;
  final ValueChanged<String?>? onChanged;
  final String? hintText;
  final IconData? prefixIcon;
  final String? Function(String?)? validator;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final normalizedValue = _normalized(value);
    final menuItems = _menuItems(normalizedValue);
    final safeValue = menuItems.any((item) => item.value == normalizedValue)
        ? normalizedValue
        : null;
    final optionSignature = menuItems.map((item) => item.value ?? '').join('|');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: OpenVtsTypography.label),
        const SizedBox(height: OpenVtsSpacing.xs),
        DropdownButtonFormField<String>(
          key: ValueKey('$label:${safeValue ?? ''}:$optionSignature'),
          initialValue: safeValue,
          isExpanded: true,
          items: menuItems,
          onChanged: isLoading ? null : onChanged,
          validator: validator,
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: prefixIcon == null
                ? null
                : Icon(
                    prefixIcon,
                    size: 20,
                    color: OpenVtsColors.textSecondary,
                  ),
            suffixIcon: isLoading
                ? const Padding(
                    padding: EdgeInsets.all(14),
                    child: SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : null,
          ),
        ),
      ],
    );
  }

  List<DropdownMenuItem<String>> _menuItems(String? normalizedValue) {
    final distinctOptions = <AdminUserDropdownOption>[];
    final seen = <String>{};
    for (final option in options) {
      final optionValue = option.value.trim();
      if (optionValue.isEmpty || seen.contains(optionValue)) {
        continue;
      }
      seen.add(optionValue);
      distinctOptions.add(
        AdminUserDropdownOption(
          value: optionValue,
          label: option.label.trim().isEmpty ? optionValue : option.label,
          isFallback: option.isFallback,
        ),
      );
    }

    if (normalizedValue != null && !seen.contains(normalizedValue)) {
      distinctOptions.insert(
        0,
        AdminUserDropdownOption(
          value: normalizedValue,
          label: '$normalizedValue (current)',
          isFallback: true,
        ),
      );
    }

    return distinctOptions
        .map(
          (option) => DropdownMenuItem<String>(
            value: option.value,
            enabled: !option.isFallback,
            child: Text(
              option.label,
              overflow: TextOverflow.ellipsis,
              style: OpenVtsTypography.body.copyWith(
                color: option.isFallback
                    ? OpenVtsColors.textTertiary
                    : OpenVtsColors.textPrimary,
              ),
            ),
          ),
        )
        .toList(growable: false);
  }
}

String? requiredDropdown(String? value) {
  if (_normalized(value) == null) {
    return 'Required';
  }
  return null;
}

String? _normalized(String? value) {
  final normalized = value?.trim();
  if (normalized == null || normalized.isEmpty) {
    return null;
  }
  return normalized;
}
