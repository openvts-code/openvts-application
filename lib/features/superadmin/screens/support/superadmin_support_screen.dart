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
import '../../controllers/superadmin_providers.dart';
import '../../controllers/superadmin_support_controller.dart';
import '../../models/superadmin_support_model.dart';
import '../../models/superadmin_support_state.dart';
import 'widgets/superadmin_support_conversation_screen.dart';
import 'widgets/superadmin_support_ticket_list_view.dart';

class SuperadminSupportScreen extends ConsumerStatefulWidget {
  const SuperadminSupportScreen({super.key});

  @override
  ConsumerState<SuperadminSupportScreen> createState() =>
      _SuperadminSupportScreenState();
}

class _SuperadminSupportScreenState extends ConsumerState<SuperadminSupportScreen> {
  Timer? _searchDebounce;
  int? _activeSplitTicketId;

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }

  Future<void> _openCreateTicketPage() async {
    final createdTicketId = await context.push<int>(
      RoutePaths.superadminSupportCreate,
    );

    if (!mounted || createdTicketId == null || createdTicketId <= 0) {
      return;
    }

    if (_usesSplitLayout(context)) {
      setState(() => _activeSplitTicketId = createdTicketId);
      await ref
          .read(superadminSupportControllerProvider.notifier)
          .selectTicket(createdTicketId);
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            SuperadminSupportConversationScreen(ticketId: createdTicketId),
      ),
    );
  }

  Future<void> _openTicket(SuperadminSupportTicketListItem ticket) async {
    if (_usesSplitLayout(context)) {
      setState(() => _activeSplitTicketId = ticket.id);
      await ref
          .read(superadminSupportControllerProvider.notifier)
          .selectTicket(ticket.id);
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SuperadminSupportConversationScreen(ticketId: ticket.id),
      ),
    );
  }

  void _setSearchQueryDebounced(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 260), () {
      if (!mounted) return;
      ref.read(superadminSupportControllerProvider.notifier).setSearchQuery(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(superadminSupportControllerProvider);
    final controller = ref.read(superadminSupportControllerProvider.notifier);
    final useSplitLayout = _usesSplitLayout(context);

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
          onPressed: state.isLoadingTickets ? null : controller.refreshTickets,
          icon: state.isLoadingTickets
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
              activeTicketId: _activeSplitTicketId ?? state.selectedTicketId,
              onCreatePressed: _openCreateTicketPage,
              onSearchChanged: _setSearchQueryDebounced,
              onOpenTicket: (ticket) => unawaited(_openTicket(ticket)),
            )
          : SuperadminSupportTicketListView(
              state: state,
              activeTicketId: state.selectedTicketId,
              onCreatePressed: _openCreateTicketPage,
              onSearchChanged: _setSearchQueryDebounced,
              onStatusChanged: controller.setStatusFilter,
              onRefresh: controller.refreshTickets,
              onOpenTicket: (ticket) => unawaited(_openTicket(ticket)),
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
    required this.onSearchChanged,
    required this.onOpenTicket,
  });

  final SuperadminSupportState state;
  final SuperadminSupportController controller;
  final int? activeTicketId;
  final VoidCallback onCreatePressed;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<SuperadminSupportTicketListItem> onOpenTicket;

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
              child: SuperadminSupportTicketListView(
                state: state,
                activeTicketId: activeTicketId,
                onCreatePressed: onCreatePressed,
                onSearchChanged: onSearchChanged,
                onStatusChanged: controller.setStatusFilter,
                onRefresh: controller.refreshTickets,
                onOpenTicket: onOpenTicket,
              ),
            ),
            const SizedBox(width: OpenVtsSpacing.md),
            Expanded(child: _ConversationSplitPanel(ticketId: activeTicketId)),
          ],
        );
      },
    );
  }
}

class _ConversationSplitPanel extends StatelessWidget {
  const _ConversationSplitPanel({required this.ticketId});

  final int? ticketId;

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
          : SuperadminSupportConversationPane(ticketId: ticketId!),
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
