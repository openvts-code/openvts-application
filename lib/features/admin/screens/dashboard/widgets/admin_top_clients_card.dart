import 'package:flutter/material.dart';

import '../../../../../core/router/route_paths.dart';
import '../../../../../core/theme/open_vts_colors.dart';
import '../../../../../core/theme/open_vts_spacing.dart';
import '../../../../../core/theme/open_vts_typography.dart';
import '../../../models/admin_dashboard_model.dart';
import 'admin_dashboard_list_card.dart';

class AdminTopClientsCard extends StatelessWidget {
  const AdminTopClientsCard({
    required this.clients,
    required this.currency,
    super.key,
  });

  final List<AdminTopClient> clients;
  final String currency;

  @override
  Widget build(BuildContext context) {
    return AdminDashboardListCard(
      title: 'Top Clients',
      icon: Icons.people_outline_rounded,
      viewAllRoute: RoutePaths.adminUsers,
      emptyTitle: 'No clients yet',
      emptyMessage: 'Client revenue will appear after payments are recorded.',
      itemCount: clients.length,
      itemBuilder: (context, index) {
        return _TopClientRow(client: clients[index], currency: currency);
      },
    );
  }
}

class _TopClientRow extends StatelessWidget {
  const _TopClientRow({required this.client, required this.currency});

  final AdminTopClient client;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final revenue = adminDashboardFormatCurrency(client.revenue, currency);
    final due = adminDashboardFormatCurrency(client.due, currency);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: OpenVtsSpacing.md,
        vertical: OpenVtsSpacing.sm,
      ),
      child: Row(
        children: [
          AdminDashboardInitialsAvatar(name: client.name),
          const SizedBox(width: OpenVtsSpacing.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  client.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: OpenVtsTypography.label.copyWith(
                    color: OpenVtsColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${adminDashboardFormatNumber(client.vehicles)} veh · $revenue',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: OpenVtsTypography.meta.copyWith(
                    color: OpenVtsColors.textSecondary,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Paid ${adminDashboardRelativeDate(client.lastPaymentAt)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: OpenVtsTypography.meta.copyWith(
                    color: OpenVtsColors.textTertiary,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: OpenVtsSpacing.xs),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 112),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  due,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: OpenVtsTypography.meta.copyWith(
                    color: OpenVtsColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'due',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: OpenVtsTypography.meta.copyWith(
                    color: OpenVtsColors.textSecondary,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
