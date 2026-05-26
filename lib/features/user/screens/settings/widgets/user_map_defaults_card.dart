import 'package:flutter/material.dart';

import '../../../../../core/theme/open_vts_colors.dart';
import '../../../../../core/theme/open_vts_spacing.dart';
import '../../../../../core/theme/open_vts_typography.dart';
import 'user_localization_select_card.dart';
import 'user_location_preset_chips.dart';

class UserMapDefaultsCard extends StatelessWidget {
  const UserMapDefaultsCard({
    required this.latitudeController,
    required this.longitudeController,
    required this.mapZoomController,
    required this.latitudeError,
    required this.longitudeError,
    required this.mapZoomError,
    required this.activePresetLabel,
    required this.onLatitudeChanged,
    required this.onLongitudeChanged,
    required this.onMapZoomChanged,
    required this.onPresetSelected,
    super.key,
  });

  final TextEditingController latitudeController;
  final TextEditingController longitudeController;
  final TextEditingController mapZoomController;
  final String? latitudeError;
  final String? longitudeError;
  final String? mapZoomError;
  final String? activePresetLabel;
  final ValueChanged<String> onLatitudeChanged;
  final ValueChanged<String> onLongitudeChanged;
  final ValueChanged<String> onMapZoomChanged;
  final ValueChanged<UserLocationPreset> onPresetSelected;

  @override
  Widget build(BuildContext context) {
    return UserLocalizationSelectCard(
      title: 'Map Defaults',
      subtitle: 'Set default map center and zoom level.',
      icon: Icons.location_on_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 560;
              if (!isWide) {
                return Column(
                  children: [
                    _CoordinateField(
                      label: 'Latitude',
                      hintText: '37.7749',
                      controller: latitudeController,
                      errorText: latitudeError,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: true,
                      ),
                      onChanged: onLatitudeChanged,
                    ),
                    const SizedBox(height: OpenVtsSpacing.xs),
                    _CoordinateField(
                      label: 'Longitude',
                      hintText: '-122.4194',
                      controller: longitudeController,
                      errorText: longitudeError,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: true,
                      ),
                      onChanged: onLongitudeChanged,
                    ),
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _CoordinateField(
                      label: 'Latitude',
                      hintText: '37.7749',
                      controller: latitudeController,
                      errorText: latitudeError,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: true,
                      ),
                      onChanged: onLatitudeChanged,
                    ),
                  ),
                  const SizedBox(width: OpenVtsSpacing.sm),
                  Expanded(
                    child: _CoordinateField(
                      label: 'Longitude',
                      hintText: '-122.4194',
                      controller: longitudeController,
                      errorText: longitudeError,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: true,
                      ),
                      onChanged: onLongitudeChanged,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: OpenVtsSpacing.xs),
          _CoordinateField(
            label: 'Map Zoom',
            hintText: '10',
            controller: mapZoomController,
            errorText: mapZoomError,
            keyboardType: TextInputType.number,
            onChanged: onMapZoomChanged,
          ),
          const SizedBox(height: OpenVtsSpacing.xs),
          Text(
            'Quick presets',
            style: OpenVtsTypography.meta.copyWith(
              color: OpenVtsColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: OpenVtsSpacing.xxs),
          UserLocationPresetChips(
            presets: kUserLocationPresets,
            activePresetLabel: activePresetLabel,
            onPresetSelected: onPresetSelected,
          ),
        ],
      ),
    );
  }
}

class _CoordinateField extends StatelessWidget {
  const _CoordinateField({
    required this.label,
    required this.controller,
    required this.onChanged,
    this.hintText,
    this.errorText,
    this.keyboardType,
  });

  final String label;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String? hintText;
  final String? errorText;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
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
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          textInputAction: TextInputAction.next,
          onChanged: onChanged,
          style: OpenVtsTypography.body,
          decoration: InputDecoration(
            hintText: hintText,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: OpenVtsSpacing.sm,
              vertical: OpenVtsSpacing.sm,
            ),
            errorText: errorText,
          ),
        ),
      ],
    );
  }
}
