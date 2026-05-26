import 'package:flutter/material.dart';

import '../../../../../core/theme/open_vts_colors.dart';
import '../../../../../core/theme/open_vts_spacing.dart';
import '../../../../../core/theme/open_vts_typography.dart';
import '../../../../../core/utils/date_time_formatter.dart';
import '../../../../../shared/widgets/open_vts_card.dart';
import '../../../models/admin_plans_model.dart';

class AdminPlanCard extends StatelessWidget {
  const AdminPlanCard({
    required this.plan,
    required this.onEdit,
    super.key,
  });

  final AdminPlan plan;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final formatter = const DateTimeFormatter();

    return OpenVtsCard(
      padding: const EdgeInsets.all(OpenVtsSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _value(plan.name),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: OpenVtsTypography.label.copyWith(
                    color: OpenVtsColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text('Edit'),
              ),
            ],
          ),
          const SizedBox(height: OpenVtsSpacing.xs),
          _InfoRow(
            icon: Icons.payments_outlined,
            label: _priceLabel(plan.price, plan.currency),
          ),
          _InfoRow(
            icon: Icons.schedule_rounded,
            label:
                plan.durationDays == null ? '-' : '${plan.durationDays} days',
          ),
          _InfoRow(
            icon: Icons.calendar_today_rounded,
            label: _metaDateLabel(
              createdAt: plan.createdAt,
              updatedAt: plan.updatedAt,
              formatter: formatter,
            ),
          ),
        ],
      ),
    );
  }

  String _value(String value) {
    final normalized = value.trim();
    return normalized.isEmpty ? '-' : normalized;
  }

  String _priceLabel(num? price, String currency) {
    if (price == null) {
      return '-';
    }
    final amount = price % 1 == 0 ? price.toStringAsFixed(0) : price.toString();
    final code = currency.trim();
    return code.isEmpty ? amount : '$code $amount';
  }

  String _metaDateLabel({
    required DateTime? createdAt,
    required DateTime? updatedAt,
    required DateTimeFormatter formatter,
  }) {
    if (updatedAt != null) {
      return 'Updated ${formatter.formatDate(updatedAt)}';
    }
    if (createdAt != null) {
      return 'Created ${formatter.formatDate(createdAt)}';
    }
    return '-';
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: OpenVtsSpacing.xxs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: OpenVtsColors.textSecondary),
          const SizedBox(width: OpenVtsSpacing.xs),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: OpenVtsTypography.meta.copyWith(
                color: OpenVtsColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
