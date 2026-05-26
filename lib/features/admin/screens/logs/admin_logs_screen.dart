import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/open_vts_colors.dart';
import '../../../../core/theme/open_vts_radius.dart';
import '../../../../core/theme/open_vts_spacing.dart';
import '../../../../core/theme/open_vts_typography.dart';
import '../../../../shared/widgets/open_vts_card.dart';
import '../../../../shared/widgets/open_vts_page_scaffold.dart';
import '../../controllers/admin_providers.dart';
import '../../models/admin_logs_model.dart';
import 'widgets/admin_activity_logs_panel.dart';
import 'widgets/admin_telemetry_logs_panel.dart';
import 'widgets/admin_vehicle_logs_panel.dart';

class AdminLogsScreen extends ConsumerWidget {
  const AdminLogsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(adminLogsControllerProvider);
    final controller = ref.read(adminLogsControllerProvider.notifier);

    return OpenVtsPageScaffold(
      title: 'Logs',
      headerMode: OpenVtsPageHeaderMode.closeable,
      padding: EdgeInsets.zero,
      body: RefreshIndicator(
        onRefresh: controller.refreshCurrentTab,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                OpenVtsSpacing.sm,
                OpenVtsSpacing.sm,
                OpenVtsSpacing.sm,
                OpenVtsSpacing.sm,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  OpenVtsCard(
                    padding: const EdgeInsets.all(OpenVtsSpacing.sm),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Logs', style: OpenVtsTypography.titleSmall),
                        const SizedBox(height: OpenVtsSpacing.xxs),
                        Text(
                          'Activity, vehicle event, and telemetry logs',
                          style: OpenVtsTypography.meta
                              .copyWith(color: OpenVtsColors.textSecondary),
                        ),
                        const SizedBox(height: OpenVtsSpacing.sm),
                        Row(
                          children: [
                            Expanded(
                              child: _TabChip(
                                label: 'Activity Logs',
                                selected:
                                    state.selectedTab == AdminLogsTab.activity,
                                onTap: () =>
                                    controller.selectTab(AdminLogsTab.activity),
                              ),
                            ),
                            const SizedBox(width: OpenVtsSpacing.xs),
                            Expanded(
                              child: _TabChip(
                                label: 'Vehicle Logs',
                                selected:
                                    state.selectedTab == AdminLogsTab.vehicle,
                                onTap: () =>
                                    controller.selectTab(AdminLogsTab.vehicle),
                              ),
                            ),
                            const SizedBox(width: OpenVtsSpacing.xs),
                            Expanded(
                              child: _TabChip(
                                label: 'Telemetry Logs',
                                selected:
                                    state.selectedTab == AdminLogsTab.telemetry,
                                onTap: () => controller
                                    .selectTab(AdminLogsTab.telemetry),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: OpenVtsSpacing.sm),
                  if (state.selectedTab == AdminLogsTab.activity)
                    const SizedBox(height: 1),
                ]),
              ),
            ),
            SliverPadding(
              padding:
                  const EdgeInsets.symmetric(horizontal: OpenVtsSpacing.sm),
              sliver: SliverToBoxAdapter(
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.72,
                  child: switch (state.selectedTab) {
                    AdminLogsTab.activity => const AdminActivityLogsPanel(),
                    AdminLogsTab.vehicle => const AdminVehicleLogsPanel(),
                    AdminLogsTab.telemetry => const AdminTelemetryLogsPanel(),
                  },
                ),
              ),
            ),
            const SliverToBoxAdapter(
              child: SizedBox(height: OpenVtsSpacing.lg),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  const _TabChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(OpenVtsRadius.md),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? OpenVtsColors.brandInk : OpenVtsColors.white,
          borderRadius: BorderRadius.circular(OpenVtsRadius.md),
          border: Border.all(
            color: selected ? OpenVtsColors.brandInk : OpenVtsColors.border,
          ),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: OpenVtsTypography.meta.copyWith(
            color: selected ? OpenVtsColors.white : OpenVtsColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
