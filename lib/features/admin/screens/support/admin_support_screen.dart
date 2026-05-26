import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/open_vts_colors.dart';
import '../../../../core/theme/open_vts_radius.dart';
import '../../../../core/theme/open_vts_spacing.dart';
import '../../../../core/theme/open_vts_typography.dart';
import '../../../../shared/widgets/open_vts_page_scaffold.dart';
import '../../controllers/admin_providers.dart';
import '../../controllers/admin_support_controller.dart';
import '../../models/admin_support_model.dart';
import '../../models/admin_support_state.dart';
import 'widgets/admin_support_conversation_screen.dart';
import 'widgets/admin_support_ticket_list_view.dart';

class AdminSupportScreen extends ConsumerWidget {
  const AdminSupportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(adminSupportControllerProvider);
    final controller = ref.read(adminSupportControllerProvider.notifier);
    final useSplitLayout = _usesSplitLayout(context);
    final activeTicketId = state.selectedTicketTab == state.selectedTab
        ? state.selectedTicketId
        : null;

    return OpenVtsPageScaffold(
      title: 'Support',
      headerMode: OpenVtsPageHeaderMode.closeable,
      padding: const EdgeInsets.fromLTRB(
        OpenVtsSpacing.md,
        OpenVtsSpacing.xs,
        OpenVtsSpacing.md,
        0,
      ),
      actions: [
        IconButton(
          tooltip: 'Refresh tickets',
          onPressed: state.isLoadingCurrentTab
              ? null
              : () => unawaited(controller.refreshCurrentTab()),
          icon: state.isLoadingCurrentTab
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.refresh_rounded, size: 20),
        ),
      ],
      body: useSplitLayout
          ? _SplitSupportLayout(
              state: state,
              controller: controller,
              activeTicketId: activeTicketId,
              onCreatePressed: () =>
                  unawaited(_openCreatePage(context, ref, state.selectedTab)),
              onOpenTicket: (ticket) => unawaited(
                _openTicket(
                  context,
                  ref,
                  tab: state.selectedTab,
                  ticketId: ticket.id,
                ),
              ),
            )
          : AdminSupportTicketListView(
              state: state,
              activeTicketId: activeTicketId,
              onCreatePressed: () =>
                  unawaited(_openCreatePage(context, ref, state.selectedTab)),
              onTabChanged: (tab) => unawaited(controller.selectTab(tab)),
              onSearchChanged: (value) =>
                  controller.setSearchQuery(state.selectedTab, value),
              onStatusChanged: (status) => unawaited(
                controller.setStatusFilter(state.selectedTab, status),
              ),
              onRefresh: controller.refreshCurrentTab,
              onLoadMore: () => controller.loadMore(state.selectedTab),
              onOpenTicket: (ticket) => unawaited(
                _openTicket(
                  context,
                  ref,
                  tab: state.selectedTab,
                  ticketId: ticket.id,
                ),
              ),
            ),
    );
  }

  Future<void> _openCreatePage(
    BuildContext context,
    WidgetRef ref,
    AdminSupportTab tab,
  ) async {
    final mode = tab == AdminSupportTab.userTickets ? 'user' : 'my';
    final route = Uri(
      path: RoutePaths.adminSupportCreate,
      queryParameters: <String, String>{'mode': mode},
    ).toString();
    final ticketId = await context.push<String>(route);

    if (!context.mounted || ticketId == null || ticketId.trim().isEmpty) {
      return;
    }

    await _openTicket(
      context,
      ref,
      tab: tab,
      ticketId: ticketId,
    );
  }

  Future<void> _openTicket(
    BuildContext context,
    WidgetRef ref, {
    required AdminSupportTab tab,
    required String ticketId,
  }) async {
    if (_usesSplitLayout(context)) {
      await ref
          .read(adminSupportControllerProvider.notifier)
          .openTicket(tab: tab, ticketId: ticketId);
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            AdminSupportConversationScreen(tab: tab, ticketId: ticketId),
      ),
    );
  }

  bool _usesSplitLayout(BuildContext context) {
    return MediaQuery.sizeOf(context).width >= 920;
  }
}

class _SplitSupportLayout extends StatelessWidget {
  const _SplitSupportLayout({
    required this.state,
    required this.controller,
    required this.activeTicketId,
    required this.onCreatePressed,
    required this.onOpenTicket,
  });

  final AdminSupportState state;
  final AdminSupportController controller;
  final String? activeTicketId;
  final VoidCallback onCreatePressed;
  final ValueChanged<AdminSupportTicketListItem> onOpenTicket;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final listWidth = constraints.maxWidth >= 1180 ? 430.0 : 382.0;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: listWidth,
              child: AdminSupportTicketListView(
                state: state,
                activeTicketId: activeTicketId,
                onCreatePressed: onCreatePressed,
                onTabChanged: (tab) => unawaited(controller.selectTab(tab)),
                onSearchChanged: (value) =>
                    controller.setSearchQuery(state.selectedTab, value),
                onStatusChanged: (status) => unawaited(
                  controller.setStatusFilter(state.selectedTab, status),
                ),
                onRefresh: controller.refreshCurrentTab,
                onLoadMore: () => controller.loadMore(state.selectedTab),
                onOpenTicket: onOpenTicket,
              ),
            ),
            const SizedBox(width: OpenVtsSpacing.md),
            Expanded(
              child: _ConversationSplitPanel(
                tab: state.selectedTicketTab ?? state.selectedTab,
                ticketId: activeTicketId,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ConversationSplitPanel extends StatelessWidget {
  const _ConversationSplitPanel({
    required this.tab,
    required this.ticketId,
  });

  final AdminSupportTab tab;
  final String? ticketId;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: OpenVtsColors.surfaceElevated,
        border: Border.all(color: OpenVtsColors.border),
        borderRadius: BorderRadius.circular(OpenVtsRadius.md),
      ),
      clipBehavior: Clip.antiAlias,
      child: ticketId == null
          ? const _SelectTicketPlaceholder()
          : AdminSupportConversationPane(tab: tab, ticketId: ticketId!),
    );
  }
}

class _SelectTicketPlaceholder extends StatelessWidget {
  const _SelectTicketPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(OpenVtsSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: OpenVtsColors.surface,
                border: Border.all(color: OpenVtsColors.border),
                borderRadius: BorderRadius.circular(OpenVtsRadius.md),
              ),
              child: const Icon(
                Icons.forum_outlined,
                size: 22,
                color: OpenVtsColors.textSecondary,
              ),
            ),
            const SizedBox(height: OpenVtsSpacing.sm),
            Text(
              'Select a ticket',
              style: OpenVtsTypography.titleSmall.copyWith(fontSize: 16),
            ),
            const SizedBox(height: OpenVtsSpacing.xs),
            Text(
              'Open a support ticket to review the full conversation.',
              textAlign: TextAlign.center,
              style: OpenVtsTypography.body.copyWith(
                color: OpenVtsColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
