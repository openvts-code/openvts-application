import 'package:flutter/material.dart';

import '../../../../../core/theme/open_vts_colors.dart';
import '../../../../../core/theme/open_vts_radius.dart';
import '../../../../../core/theme/open_vts_spacing.dart';
import '../../../../../core/theme/open_vts_typography.dart';

class UserLocationPreset {
  const UserLocationPreset({
    required this.label,
    required this.latitude,
    required this.longitude,
    required this.zoom,
  });

  final String label;
  final double latitude;
  final double longitude;
  final int zoom;
}

const List<UserLocationPreset> kUserLocationPresets = <UserLocationPreset>[
  UserLocationPreset(
    label: 'San Francisco',
    latitude: 37.7749,
    longitude: -122.4194,
    zoom: 11,
  ),
  UserLocationPreset(
    label: 'London',
    latitude: 51.5074,
    longitude: -0.1278,
    zoom: 11,
  ),
  UserLocationPreset(
    label: 'Dubai',
    latitude: 25.2048,
    longitude: 55.2708,
    zoom: 11,
  ),
  UserLocationPreset(
    label: 'Delhi',
    latitude: 28.6139,
    longitude: 77.2090,
    zoom: 11,
  ),
];

class UserLocationPresetChips extends StatelessWidget {
  const UserLocationPresetChips({
    required this.presets,
    required this.onPresetSelected,
    this.activePresetLabel,
    super.key,
  });

  final List<UserLocationPreset> presets;
  final ValueChanged<UserLocationPreset> onPresetSelected;
  final String? activePresetLabel;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: presets
          .map(
            (preset) => _PresetChip(
              label: preset.label,
              isActive: _isActive(preset),
              onTap: () => onPresetSelected(preset),
            ),
          )
          .toList(growable: false),
    );
  }

  bool _isActive(UserLocationPreset preset) {
    final active = activePresetLabel?.trim();
    if (active == null || active.isEmpty) {
      return false;
    }
    return preset.label.toLowerCase() == active.toLowerCase();
  }
}

class _PresetChip extends StatelessWidget {
  const _PresetChip({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground =
        isActive ? OpenVtsColors.white : OpenVtsColors.textPrimary;
    final background =
        isActive ? OpenVtsColors.brandInk : OpenVtsColors.surface;

    return Semantics(
      button: true,
      selected: isActive,
      label: 'Apply preset $label',
      child: InkWell(
        borderRadius: BorderRadius.circular(OpenVtsRadius.pill),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.symmetric(
            horizontal: OpenVtsSpacing.xs,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(OpenVtsRadius.pill),
            border: Border.all(color: OpenVtsColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.place_outlined, size: 12, color: foreground),
              const SizedBox(width: 4),
              Text(
                label,
                style: OpenVtsTypography.meta.copyWith(
                  color: foreground,
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
