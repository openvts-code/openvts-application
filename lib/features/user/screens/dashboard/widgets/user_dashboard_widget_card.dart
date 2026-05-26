import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../core/theme/open_vts_colors.dart';
import '../../../../../core/theme/open_vts_radius.dart';
import '../../../../../core/theme/open_vts_spacing.dart';
import '../../../../../core/theme/open_vts_typography.dart';

class UserDashboardWidgetCard extends StatelessWidget {
  const UserDashboardWidgetCard({
    required this.title,
    required this.icon,
    required this.child,
    this.isLoading = false,
    this.onRefresh,
    this.trailing,
    super.key,
  });

  final String title;
  final IconData icon;
  final Widget child;
  final bool isLoading;
  final VoidCallback? onRefresh;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(OpenVtsRadius.xl),
        border: Border.all(color: OpenVtsColors.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(OpenVtsRadius.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                OpenVtsSpacing.md,
                OpenVtsSpacing.sm,
                OpenVtsSpacing.xs,
                OpenVtsSpacing.sm,
              ),
              child: Row(
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
                      size: 17,
                      color: OpenVtsColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: OpenVtsSpacing.sm),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: OpenVtsTypography.label.copyWith(
                        color: OpenVtsColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (isLoading)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: OpenVtsSpacing.xs,
                      ),
                      child: SizedBox.square(
                        dimension: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                  if (trailing != null) trailing!,
                  if (onRefresh != null)
                    IconButton(
                      tooltip: 'Refresh widget',
                      onPressed: isLoading ? null : onRefresh,
                      style: IconButton.styleFrom(
                        minimumSize: const Size.square(32),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        padding: EdgeInsets.zero,
                        foregroundColor: OpenVtsColors.textSecondary,
                        disabledForegroundColor: OpenVtsColors.textTertiary,
                      ),
                      icon: const Icon(Icons.refresh_rounded, size: 17),
                    ),
                ],
              ),
            ),
            const Divider(height: 1, color: OpenVtsColors.border),
            Padding(
              padding: const EdgeInsets.all(OpenVtsSpacing.md),
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}

class UserDashboardWidgetError extends StatelessWidget {
  const UserDashboardWidgetError({
    required this.message,
    this.onRetry,
    super.key,
  });

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(OpenVtsSpacing.sm),
      decoration: BoxDecoration(
        color: OpenVtsColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(OpenVtsRadius.md),
        border: Border.all(color: OpenVtsColors.error.withValues(alpha: 0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 17,
            color: OpenVtsColors.error,
          ),
          const SizedBox(width: OpenVtsSpacing.xs),
          Expanded(
            child: Text(
              userDashboardErrorText(message),
              style: OpenVtsTypography.meta.copyWith(
                color: OpenVtsColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(width: OpenVtsSpacing.xs),
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(
                minimumSize: const Size(52, 28),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                padding: const EdgeInsets.symmetric(
                  horizontal: OpenVtsSpacing.xs,
                ),
              ),
              child: const Text('Retry'),
            ),
          ],
        ],
      ),
    );
  }
}

class UserDashboardWidgetEmpty extends StatelessWidget {
  const UserDashboardWidgetEmpty({
    required this.message,
    this.icon = Icons.inbox_outlined,
    super.key,
  });

  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: OpenVtsSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 28, color: OpenVtsColors.textTertiary),
          const SizedBox(height: OpenVtsSpacing.xs),
          Text(
            message,
            textAlign: TextAlign.center,
            style: OpenVtsTypography.meta.copyWith(
              color: OpenVtsColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class UserDashboardMetricTile extends StatelessWidget {
  const UserDashboardMetricTile({
    required this.label,
    required this.value,
    this.subtitle,
    super.key,
  });

  final String label;
  final String value;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(OpenVtsSpacing.sm),
      decoration: BoxDecoration(
        color: OpenVtsColors.surface,
        borderRadius: BorderRadius.circular(OpenVtsRadius.md),
        border: Border.all(color: OpenVtsColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: OpenVtsTypography.meta.copyWith(
              color: OpenVtsColors.textTertiary,
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              style: OpenVtsTypography.numeric.copyWith(
                color: OpenVtsColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: OpenVtsTypography.meta.copyWith(
                color: OpenVtsColors.textSecondary,
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class UserDashboardMiniBar extends StatelessWidget {
  const UserDashboardMiniBar({
    required this.label,
    required this.value,
    required this.total,
    this.color = OpenVtsColors.brandInk,
    this.trailing,
    super.key,
  });

  final String label;
  final num value;
  final num total;
  final Color color;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final denominator = math.max(total.toDouble(), 1);
    final percent = (value.toDouble() / denominator).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: OpenVtsTypography.meta.copyWith(
                  color: OpenVtsColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: OpenVtsSpacing.sm),
            Text(
              trailing ?? userDashboardFormatNumber(value),
              style: OpenVtsTypography.meta.copyWith(
                color: OpenVtsColors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(OpenVtsRadius.pill),
          child: LinearProgressIndicator(
            value: percent,
            minHeight: 7,
            color: color,
            backgroundColor: OpenVtsColors.surface,
          ),
        ),
      ],
    );
  }
}

String userDashboardFormatNumber(num value) {
  return NumberFormat.decimalPattern().format(value.round());
}

String userDashboardFormatCompact(num value) {
  return NumberFormat.compact().format(value);
}

String userDashboardFormatDecimal(num value, {int digits = 1}) {
  return value.toStringAsFixed(digits);
}

String userDashboardFormatDistance(num km) {
  return '${userDashboardFormatDecimal(km)} km';
}

String userDashboardFormatHours(num hours) {
  return '${userDashboardFormatDecimal(hours)} h';
}

String userDashboardFormatDateTime(DateTime? value) {
  if (value == null) return 'Not updated yet';
  return DateFormat('dd MMM yyyy, hh:mm a').format(value);
}

String userDashboardFormatShortTime(DateTime? value) {
  if (value == null) return 'No time';
  return DateFormat('dd MMM, hh:mm a').format(value);
}

String userDashboardErrorText(Object error) {
  final text = error.toString().trim();
  if (text.startsWith('Exception: ')) {
    return text.substring('Exception: '.length).trim();
  }
  return text.isEmpty ? 'Widget could not be loaded.' : text;
}

String? userDashboardPropString(
  Map<String, dynamic> props,
  List<String> keys,
) {
  for (final key in keys) {
    final value = props[key];
    if (value == null) continue;
    final text = value.toString().trim();
    if (text.isNotEmpty) return text;
  }
  return null;
}

int? userDashboardPropInt(Map<String, dynamic> props, List<String> keys) {
  final value = userDashboardPropString(props, keys);
  return value == null ? null : int.tryParse(value);
}

DateTime? userDashboardPropDateTime(
  Map<String, dynamic> props,
  List<String> keys,
) {
  final value = userDashboardPropString(props, keys);
  return value == null ? null : DateTime.tryParse(value);
}

DateTime userDashboardDefaultRangeStart({int days = 7}) {
  final now = DateTime.now();
  return now.subtract(Duration(days: days));
}

DateTime userDashboardDefaultRangeEnd() {
  return DateTime.now();
}
