import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../core/theme/open_vts_colors.dart';
import '../../../../../core/theme/open_vts_radius.dart';
import '../../../../../core/theme/open_vts_spacing.dart';
import '../../../../../core/theme/open_vts_typography.dart';
import '../../../../../core/utils/date_time_formatter.dart';
import '../../../../../shared/widgets/open_vts_card.dart';
import '../../../models/user_settings_model.dart';

const DateTimeFormatter _dateTimeFormatter = DateTimeFormatter();

class UserLocalizationPreviewCard extends StatelessWidget {
  const UserLocalizationPreviewCard({
    required this.settings,
    required this.languageLabel,
    super.key,
  });

  final UserLocalizationSettings settings;
  final String languageLabel;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateText = _formatDate(now, settings.dateFormat);
    final timeText = _formatTime(now, settings.use24Hour);

    final directionText =
        settings.layoutDirection == UserLayoutDirection.rtl ? 'RTL' : 'LTR';
    final distanceText =
        settings.units == UserDistanceUnit.miles ? 'Miles' : 'Kilometers';

    final mapText =
        '${settings.defaultLat.toStringAsFixed(4)}, ${settings.defaultLon.toStringAsFixed(4)} · z${settings.mapZoom}';

    return OpenVtsCard(
      padding: const EdgeInsets.all(OpenVtsSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.visibility_outlined,
                size: 14,
                color: OpenVtsColors.textTertiary,
              ),
              const SizedBox(width: 6),
              Text(
                'Localization Preview',
                style: OpenVtsTypography.meta.copyWith(
                  color: OpenVtsColors.textTertiary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: OpenVtsSpacing.xs),
          _PreviewGrid(
            tiles: [
              _PreviewTile(label: 'Language', value: languageLabel),
              _PreviewTile(label: 'Direction', value: directionText),
              _PreviewTile(label: 'Timezone', value: settings.timezoneOffset),
              _PreviewTile(label: 'Date', value: dateText),
              _PreviewTile(label: 'Time', value: timeText),
              _PreviewTile(label: 'Distance Unit', value: distanceText),
              _PreviewTile(label: 'Map Center', value: mapText),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime now, String dateFormat) {
    final normalized = dateFormat.trim();
    if (normalized.isEmpty) {
      return _dateTimeFormatter.formatDate(now);
    }

    try {
      return DateFormat(_toIntlPattern(normalized)).format(now);
    } catch (_) {
      return _dateTimeFormatter.formatDate(now);
    }
  }

  String _formatTime(DateTime now, bool use24Hour) {
    if (!use24Hour) {
      return _dateTimeFormatter.formatTime(now);
    }

    try {
      return DateFormat('HH:mm').format(now);
    } catch (_) {
      return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    }
  }

  String _toIntlPattern(String pattern) {
    return pattern
        .replaceAll('YYYY', 'yyyy')
        .replaceAll('YY', 'yy')
        .replaceAll('DD', 'dd')
        .replaceAll('D', 'd')
        .replaceAll('A', 'a');
  }
}

class _PreviewGrid extends StatelessWidget {
  const _PreviewGrid({required this.tiles});

  final List<Widget> tiles;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 760
            ? 3
            : constraints.maxWidth >= 520
                ? 2
                : 1;
        final spacing = OpenVtsSpacing.xs;
        final totalSpacing = (columns - 1) * spacing;
        final width = (constraints.maxWidth - totalSpacing) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: tiles
              .map((tile) => SizedBox(width: width, child: tile))
              .toList(growable: false),
        );
      },
    );
  }
}

class _PreviewTile extends StatelessWidget {
  const _PreviewTile({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: OpenVtsSpacing.xs,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: OpenVtsColors.surface,
        borderRadius: BorderRadius.circular(OpenVtsRadius.sm),
        border: Border.all(color: OpenVtsColors.border),
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
            style: OpenVtsTypography.body.copyWith(
              color: OpenVtsColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
