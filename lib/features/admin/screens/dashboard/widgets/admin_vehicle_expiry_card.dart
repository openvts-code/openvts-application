import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../../core/router/route_paths.dart';
import '../../../../../core/theme/open_vts_colors.dart';
import '../../../../../core/theme/open_vts_radius.dart';
import '../../../../../core/theme/open_vts_spacing.dart';
import '../../../../../core/theme/open_vts_typography.dart';
import '../../../../../shared/widgets/open_vts_card.dart';
import '../../../models/admin_dashboard_model.dart';

class AdminVehicleExpiryCard extends StatelessWidget {
  const AdminVehicleExpiryCard({
    required this.expiry,
    required this.currency,
    super.key,
  });

  final AdminDashboardExpiry expiry;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final preview = expiry.preview.take(5).toList(growable: false);
    final now = DateTime.now();

    return OpenVtsCard(
      padding: const EdgeInsets.all(OpenVtsSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeading(
            title: 'Vehicle Expiry',
            icon: Icons.calendar_month_outlined,
          ),
          const SizedBox(height: OpenVtsSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _MiniMetric(
                  label: 'This Week',
                  value: _formatCompactNumber(expiry.thisWeek),
                ),
              ),
              const SizedBox(width: OpenVtsSpacing.xs),
              Expanded(
                child: _MiniMetric(
                  label: 'This Month',
                  value: _formatCompactNumber(expiry.thisMonth),
                ),
              ),
            ],
          ),
          if (preview.isNotEmpty) ...[
            const SizedBox(height: OpenVtsSpacing.sm),
            Text(
              'Expiring soon',
              style: OpenVtsTypography.meta.copyWith(
                color: OpenVtsColors.textSecondary,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: OpenVtsSpacing.xxs),
            for (final vehicle in preview) ...[
              _ExpiryPreviewRow(
                vehicle: vehicle,
                now: now,
                fallbackCurrency: currency,
              ),
              if (vehicle != preview.last) const Divider(height: 1),
            ],
          ],
          const SizedBox(height: OpenVtsSpacing.sm),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: () => context.push(RoutePaths.adminVehicles),
              style: OutlinedButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(
                  horizontal: OpenVtsSpacing.xs,
                  vertical: 8,
                ),
                foregroundColor: OpenVtsColors.textPrimary,
                side: const BorderSide(color: OpenVtsColors.border),
                textStyle: OpenVtsTypography.meta.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              icon: const Icon(Icons.arrow_forward_rounded, size: 15),
              label: const Text('Open Vehicles'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: OpenVtsColors.surface,
            borderRadius: BorderRadius.circular(OpenVtsRadius.sm),
            border: Border.all(color: OpenVtsColors.border),
          ),
          child: Icon(icon, size: 16, color: OpenVtsColors.textSecondary),
        ),
        const SizedBox(width: OpenVtsSpacing.xs),
        Flexible(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: OpenVtsTypography.label.copyWith(
              color: OpenVtsColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _MiniMetric extends StatelessWidget {
  const _MiniMetric({required this.label, required this.value});

  final String label;
  final String value;

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
            label,
            style: OpenVtsTypography.meta.copyWith(
              color: OpenVtsColors.textSecondary,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: OpenVtsTypography.numeric.copyWith(
              color: OpenVtsColors.textPrimary,
              fontSize: 21,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpiryPreviewRow extends StatelessWidget {
  const _ExpiryPreviewRow({
    required this.vehicle,
    required this.now,
    required this.fallbackCurrency,
  });

  final AdminExpiryPreviewVehicle vehicle;
  final DateTime now;
  final String fallbackCurrency;

  @override
  Widget build(BuildContext context) {
    final plan = vehicle.plan;
    final amount = plan?.price ?? 0;
    final currency = plan?.currency ?? fallbackCurrency;
    final daysLeft = _daysLeft(vehicle.secondaryExpiry, now);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: OpenVtsSpacing.xs),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: OpenVtsColors.surface,
              borderRadius: BorderRadius.circular(OpenVtsRadius.sm),
              border: Border.all(color: OpenVtsColors.border),
            ),
            child: const Icon(
              Icons.directions_car_outlined,
              size: 15,
              color: OpenVtsColors.textSecondary,
            ),
          ),
          const SizedBox(width: OpenVtsSpacing.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  vehicle.plateNumber ?? vehicle.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: OpenVtsTypography.label.copyWith(
                    color: OpenVtsColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  vehicle.primaryUserName ?? vehicle.imei ?? 'Unassigned',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: OpenVtsTypography.meta.copyWith(
                    color: OpenVtsColors.textSecondary,
                    fontSize: 10.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: OpenVtsSpacing.xs),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 154),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _daysLabel(daysLeft),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: OpenVtsTypography.meta.copyWith(
                    color: OpenVtsColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (plan != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    _formatCurrency(amount, currency),
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
          ),
        ],
      ),
    );
  }
}

int? _daysLeft(DateTime? expiry, DateTime now) {
  if (expiry == null) {
    return null;
  }

  final localExpiry = expiry.toLocal();
  final localNow = now.toLocal();
  if (localExpiry.isBefore(localNow)) {
    return -1;
  }

  return DateUtils.dateOnly(localExpiry)
      .difference(DateUtils.dateOnly(localNow))
      .inDays;
}

String _daysLabel(int? days) {
  if (days == null) {
    return '-';
  }
  if (days < 0) {
    return 'expired';
  }
  if (days == 0) {
    return 'today';
  }
  if (days == 1) {
    return 'tomorrow';
  }
  return 'in $days days';
}

String _formatCurrency(num value, String currency) {
  final code = _normalizeCurrencyCode(currency);
  final locale = code == 'INR' ? 'en_IN' : 'en_US';
  final number = NumberFormat.decimalPattern(locale).format(value.round());

  try {
    return NumberFormat.simpleCurrency(
      locale: locale,
      name: code,
      decimalDigits: 0,
    ).format(value);
  } catch (_) {
    return '$code $number';
  }
}

String _formatCompactNumber(num value) {
  return NumberFormat.compact(locale: 'en_IN').format(value);
}

String _normalizeCurrencyCode(String currency) {
  final raw = currency.trim().toUpperCase();
  const aliases = <String, String>{
    'CA': 'CAD',
    'US': 'USD',
    'IN': 'INR',
    'EU': 'EUR',
    'GB': 'GBP',
    'AE': 'AED',
  };
  return aliases[raw] ?? (raw.isEmpty ? 'USD' : raw);
}
