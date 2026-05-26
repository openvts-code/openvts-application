import 'package:flutter/material.dart';

import '../../../../../../core/theme/open_vts_colors.dart';
import '../../../../../../core/theme/open_vts_radius.dart';
import '../../../../../../core/theme/open_vts_spacing.dart';
import '../../../../../../core/theme/open_vts_typography.dart';
import '../user_poi_constants.dart';

/// Category picker showing preset chips plus a free-text "Custom" entry that
/// matches the backend's free-text category field.
class UserPoiCategoryPicker extends StatefulWidget {
  const UserPoiCategoryPicker({
    super.key,
    required this.value,
    required this.onChanged,
    this.label = 'Category',
  });

  final String value;
  final ValueChanged<String> onChanged;
  final String label;

  @override
  State<UserPoiCategoryPicker> createState() => _UserPoiCategoryPickerState();
}

class _UserPoiCategoryPickerState extends State<UserPoiCategoryPicker> {
  late final TextEditingController _custom;
  late bool _customMode;

  @override
  void initState() {
    super.initState();
    final v = widget.value.trim();
    _customMode = v.isNotEmpty && !_isPreset(v);
    _custom = TextEditingController(text: _customMode ? v : '');
  }

  @override
  void didUpdateWidget(covariant UserPoiCategoryPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    final v = widget.value.trim();
    final isCustom = v.isNotEmpty && !_isPreset(v);
    if (isCustom != _customMode) {
      setState(() {
        _customMode = isCustom;
        _custom.text = isCustom ? v : '';
      });
    }
  }

  @override
  void dispose() {
    _custom.dispose();
    super.dispose();
  }

  bool _isPreset(String value) {
    final needle = value.toLowerCase();
    for (final option in kUserPoiCategories) {
      if (option.value.toLowerCase() == needle) return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final selected = widget.value.trim().toLowerCase();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: OpenVtsTypography.label.copyWith(
            color: OpenVtsColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final option in kUserPoiCategories)
              _CategoryChip(
                icon: option.icon,
                label: option.label,
                selected: !_customMode && option.value == selected,
                onTap: () {
                  setState(() {
                    _customMode = false;
                    _custom.clear();
                  });
                  widget.onChanged(option.value);
                },
              ),
            _CategoryChip(
              icon: Icons.edit_outlined,
              label: 'Custom',
              selected: _customMode,
              onTap: () {
                setState(() => _customMode = true);
                widget.onChanged(_custom.text.trim());
              },
            ),
          ],
        ),
        if (_customMode) ...[
          const SizedBox(height: OpenVtsSpacing.xs),
          TextField(
            controller: _custom,
            style: OpenVtsTypography.body,
            decoration: InputDecoration(
              isDense: true,
              hintText: 'Custom category (e.g. "vendor")',
              hintStyle: OpenVtsTypography.body.copyWith(
                color: OpenVtsColors.textTertiary,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: OpenVtsSpacing.sm,
                vertical: 10,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(OpenVtsRadius.button),
                borderSide: const BorderSide(color: OpenVtsColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(OpenVtsRadius.button),
                borderSide: const BorderSide(color: OpenVtsColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(OpenVtsRadius.button),
                borderSide: const BorderSide(
                  color: OpenVtsColors.brandInk,
                  width: 1.4,
                ),
              ),
            ),
            onChanged: (text) => widget.onChanged(text.trim()),
          ),
        ],
      ],
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(OpenVtsRadius.pill),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? OpenVtsColors.brandInk : OpenVtsColors.surface,
          borderRadius: BorderRadius.circular(OpenVtsRadius.pill),
          border: Border.all(
            color: selected ? OpenVtsColors.brandInk : OpenVtsColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: selected ? OpenVtsColors.white : OpenVtsColors.textPrimary,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: OpenVtsTypography.meta.copyWith(
                color:
                    selected ? OpenVtsColors.white : OpenVtsColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
