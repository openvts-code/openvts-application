import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../core/theme/open_vts_colors.dart';
import '../../../../../core/theme/open_vts_radius.dart';
import '../../../../../core/theme/open_vts_spacing.dart';
import '../../../../../core/theme/open_vts_typography.dart';

class AdminInventoryRoundedSurface extends StatelessWidget {
  const AdminInventoryRoundedSurface({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(OpenVtsSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(OpenVtsRadius.lg),
        border: Border.all(color: inventorySoftBorderColor(context)),
      ),
      child: child,
    );
  }
}

class AdminInventoryCardHeader extends StatelessWidget {
  const AdminInventoryCardHeader({
    required this.icon,
    required this.title,
    required this.isActive,
    required this.onEdit,
    required this.isEditing,
    super.key,
  });

  final IconData icon;
  final String title;
  final bool isActive;
  final VoidCallback onEdit;
  final bool isEditing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          height: 44,
          width: 44,
          decoration: BoxDecoration(
            color: inventorySoftSurfaceColor(context),
            shape: BoxShape.circle,
            border: Border.all(color: inventorySoftBorderColor(context)),
          ),
          alignment: Alignment.center,
          child: Icon(
            icon,
            size: 22,
            color: inventoryPrimaryInkColor(context),
          ),
        ),
        const SizedBox(width: OpenVtsSpacing.sm),
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                  color: inventoryPrimaryInkColor(context),
                ),
          ),
        ),
        AdminInventoryEditButton(
          onPressed: isEditing ? null : onEdit,
          isLoading: isEditing,
        ),
        const SizedBox(width: OpenVtsSpacing.xxs),
        AdminInventoryStatusBadge(
          label: isActive ? 'Active' : 'Inactive',
        ),
      ],
    );
  }
}

class AdminInventoryEditButton extends StatelessWidget {
  const AdminInventoryEditButton({
    required this.onPressed,
    required this.isLoading,
    super.key,
  });

  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 36,
      height: 36,
      child: IconButton(
        onPressed: onPressed,
        tooltip: 'Edit',
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
        icon: isLoading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(
                Icons.edit_outlined,
                size: 18,
                color: inventoryPrimaryInkColor(context),
              ),
      ),
    );
  }
}

class AdminInventoryStatusBadge extends StatelessWidget {
  const AdminInventoryStatusBadge({required this.label, super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: OpenVtsSpacing.sm,
        vertical: OpenVtsSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: inventorySoftSurfaceColor(context),
        borderRadius: BorderRadius.circular(OpenVtsRadius.pill),
        border: Border.all(color: inventorySoftBorderColor(context)),
      ),
      child: Text(
        label,
        style: OpenVtsTypography.label.copyWith(
          color: inventoryPrimaryInkColor(context),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class AdminInventoryInfoField extends StatelessWidget {
  const AdminInventoryInfoField({
    required this.icon,
    required this.label,
    required this.value,
    super.key,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final resolved = value.trim().isEmpty ? '—' : value.trim();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 16,
          color: OpenVtsColors.textSecondary,
        ),
        const SizedBox(width: OpenVtsSpacing.xs),
        Expanded(
          child: RichText(
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            text: TextSpan(
              style: OpenVtsTypography.label.copyWith(
                color: OpenVtsColors.textPrimary,
                height: 1.4,
              ),
              children: [
                TextSpan(
                  text: '${label.toUpperCase()} : ',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                TextSpan(
                  text: resolved,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class AdminInventoryInfoGrid extends StatelessWidget {
  const AdminInventoryInfoGrid({
    required this.leftTop,
    required this.leftBottom,
    required this.rightTop,
    required this.rightBottom,
    super.key,
  });

  final AdminInventoryInfoField leftTop;
  final AdminInventoryInfoField leftBottom;
  final AdminInventoryInfoField rightTop;
  final AdminInventoryInfoField rightBottom;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 420;

        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              leftTop,
              const SizedBox(height: OpenVtsSpacing.xs),
              leftBottom,
              const SizedBox(height: OpenVtsSpacing.xs),
              rightTop,
              const SizedBox(height: OpenVtsSpacing.xs),
              rightBottom,
            ],
          );
        }

        return Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: leftTop),
                const SizedBox(width: OpenVtsSpacing.sm),
                Expanded(child: rightTop),
              ],
            ),
            const SizedBox(height: OpenVtsSpacing.xs),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: leftBottom),
                const SizedBox(width: OpenVtsSpacing.sm),
                Expanded(child: rightBottom),
              ],
            ),
          ],
        );
      },
    );
  }
}

class AdminInventoryCardFooter extends StatelessWidget {
  const AdminInventoryCardFooter({
    required this.createdValue,
    required this.statusLabel,
    super.key,
  });

  final String createdValue;
  final String statusLabel;

  static final DateFormat createdFormat = DateFormat('yyyy-MM-dd HH:mm');

  static String formatCreatedAt(DateTime? value) {
    if (value == null) {
      return '-';
    }
    return createdFormat.format(value.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _CreatedPill(createdValue: createdValue),
        ),
        const SizedBox(width: OpenVtsSpacing.sm),
        _StockStatusPill(label: statusLabel),
      ],
    );
  }
}

class _CreatedPill extends StatelessWidget {
  const _CreatedPill({required this.createdValue});

  final String createdValue;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: OpenVtsSpacing.sm,
        vertical: OpenVtsSpacing.xs + 2,
      ),
      decoration: BoxDecoration(
        color: inventorySoftSurfaceColor(context),
        borderRadius: BorderRadius.circular(OpenVtsRadius.md),
        border: Border.all(color: inventorySoftBorderColor(context)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.schedule_outlined,
            size: 16,
            color: OpenVtsColors.textSecondary,
          ),
          const SizedBox(width: OpenVtsSpacing.xs),
          Expanded(
            child: RichText(
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              text: TextSpan(
                style: OpenVtsTypography.label.copyWith(
                  color: OpenVtsColors.textPrimary,
                  height: 1.4,
                ),
                children: [
                  const TextSpan(
                    text: 'Created : ',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  TextSpan(
                    text: createdValue,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StockStatusPill extends StatelessWidget {
  const _StockStatusPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 108),
      padding: const EdgeInsets.symmetric(
        horizontal: OpenVtsSpacing.md,
        vertical: OpenVtsSpacing.xs + 2,
      ),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: inventorySoftSurfaceColor(context),
        borderRadius: BorderRadius.circular(OpenVtsRadius.md),
        border: Border.all(color: inventorySoftBorderColor(context)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: OpenVtsTypography.label.copyWith(
          color: OpenVtsColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

String formatInventoryStatusLabel(String rawLabel) {
  final normalized = rawLabel.trim().toLowerCase();
  if (normalized.isEmpty) {
    return 'Unknown';
  }

  return normalized
      .split(RegExp(r'\s+'))
      .map(
        (word) => word.isEmpty
            ? word
            : '${word[0].toUpperCase()}${word.substring(1)}',
      )
      .join(' ');
}

Color inventorySoftSurfaceColor(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark
      ? OpenVtsColors.darkSurface
      : OpenVtsColors.background;
}

Color inventorySoftBorderColor(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark
      ? OpenVtsColors.darkBorder
      : OpenVtsColors.border;
}

Color inventoryPrimaryInkColor(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark
      ? OpenVtsColors.darkTextPrimary
      : OpenVtsColors.brandInk;
}
