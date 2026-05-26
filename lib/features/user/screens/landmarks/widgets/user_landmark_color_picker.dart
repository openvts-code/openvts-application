import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../core/theme/open_vts_colors.dart';
import '../../../../../core/theme/open_vts_radius.dart';
import '../../../../../core/theme/open_vts_spacing.dart';
import '../../../../../core/theme/open_vts_typography.dart';

/// Curated palette used by Landmark Studio. Kept short and on-brand to avoid
/// the loud rainbow grids common in desktop GIS apps.
const List<String> kUserLandmarkPalette = <String>[
  '#1F6FEB',
  '#0EA5E9',
  '#10B981',
  '#16A34A',
  '#F59E0B',
  '#EF4444',
  '#EC4899',
  '#8B5CF6',
  '#0F172A',
  '#6B6570',
];

/// Compact color picker: a wrap row of preset swatches plus a tight hex
/// text field. Emits normalised `#RRGGBB` strings.
class UserLandmarkColorPicker extends StatefulWidget {
  const UserLandmarkColorPicker({
    super.key,
    required this.value,
    required this.onChanged,
    this.label = 'Color',
    this.presets = kUserLandmarkPalette,
    this.enabled = true,
  });

  final String value;
  final ValueChanged<String> onChanged;
  final String label;
  final List<String> presets;
  final bool enabled;

  @override
  State<UserLandmarkColorPicker> createState() =>
      _UserLandmarkColorPickerState();
}

class _UserLandmarkColorPickerState extends State<UserLandmarkColorPicker> {
  late final TextEditingController _hexController =
      TextEditingController(text: _normalize(widget.value));

  @override
  void didUpdateWidget(covariant UserLandmarkColorPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    final normalised = _normalize(widget.value);
    if (normalised.toUpperCase() != _hexController.text.toUpperCase()) {
      _hexController.text = normalised;
    }
  }

  @override
  void dispose() {
    _hexController.dispose();
    super.dispose();
  }

  void _emit(String hex) {
    final normalised = _normalize(hex);
    if (!_isValid(normalised)) return;
    widget.onChanged(normalised);
  }

  @override
  Widget build(BuildContext context) {
    final current = _normalize(widget.value).toUpperCase();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: OpenVtsTypography.meta.copyWith(
            color: OpenVtsColors.textSecondary,
          ),
        ),
        const SizedBox(height: OpenVtsSpacing.xs),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final hex in widget.presets)
              _Swatch(
                color: _parseHex(hex),
                selected: _normalize(hex).toUpperCase() == current,
                onTap: widget.enabled ? () => _emit(hex) : null,
              ),
          ],
        ),
        const SizedBox(height: OpenVtsSpacing.xs),
        SizedBox(
          height: 38,
          child: TextField(
            controller: _hexController,
            enabled: widget.enabled,
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.allow(RegExp(r'[0-9a-fA-F#]')),
              LengthLimitingTextInputFormatter(7),
            ],
            style: OpenVtsTypography.body,
            decoration: InputDecoration(
              isDense: true,
              prefixIcon: Padding(
                padding: const EdgeInsets.only(
                  left: OpenVtsSpacing.sm,
                  right: OpenVtsSpacing.xs,
                ),
                child: _Swatch(
                  color: _parseHex(current),
                  selected: false,
                  size: 18,
                ),
              ),
              prefixIconConstraints: const BoxConstraints(
                minWidth: 0,
                minHeight: 0,
              ),
              hintText: '#RRGGBB',
              hintStyle: OpenVtsTypography.body.copyWith(
                color: OpenVtsColors.textTertiary,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: OpenVtsSpacing.sm,
                vertical: 0,
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
            onSubmitted: _emit,
            onChanged: (text) {
              final normalised = _normalize(text);
              if (_isValid(normalised)) {
                widget.onChanged(normalised);
              }
            },
          ),
        ),
      ],
    );
  }

  static String _normalize(String hex) {
    var h = hex.trim();
    if (!h.startsWith('#')) h = '#$h';
    return h.toUpperCase();
  }

  static bool _isValid(String hex) {
    final pattern = RegExp(r'^#[0-9A-Fa-f]{6}$');
    return pattern.hasMatch(hex);
  }

  static Color _parseHex(String value) {
    final cleaned = value.replaceAll('#', '');
    if (cleaned.length != 6) return OpenVtsColors.border;
    final parsed = int.tryParse('FF$cleaned', radix: 16);
    if (parsed == null) return OpenVtsColors.border;
    return Color(parsed);
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.color,
    required this.selected,
    this.onTap,
    this.size = 24,
  });

  final Color color;
  final bool selected;
  final VoidCallback? onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    final dot = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? OpenVtsColors.brandInk : OpenVtsColors.border,
          width: selected ? 2 : 1,
        ),
      ),
    );
    if (onTap == null) return dot;
    return InkResponse(
      onTap: onTap,
      radius: size,
      child: dot,
    );
  }
}
