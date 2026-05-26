import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:open_vts/core/router/route_paths.dart';
import 'package:open_vts/core/theme/open_vts_colors.dart';
import 'package:open_vts/core/theme/open_vts_radius.dart';
import 'package:open_vts/core/theme/open_vts_spacing.dart';
import 'package:open_vts/core/theme/open_vts_typography.dart';
import 'package:open_vts/features/user/controllers/user_providers.dart';
import 'package:open_vts/features/user/controllers/user_support_controller.dart';
import 'package:open_vts/features/user/models/user_support_model.dart';
import 'package:open_vts/features/user/models/user_support_state.dart';
import 'package:open_vts/features/user/screens/support/widgets/user_support_conversation_screen.dart';
import 'package:open_vts/features/user/screens/support/widgets/user_support_ticket_list_view.dart';
import 'package:open_vts/shared/widgets/open_vts_page_scaffold.dart';

class UserSupportScreen extends ConsumerStatefulWidget {
  const UserSupportScreen({super.key});

  @override
  ConsumerState<UserSupportScreen> createState() => _UserSupportScreenState();
}

class _UserSupportScreenState extends ConsumerState<UserSupportScreen> {
  Timer? _searchDebounce;
  String? _activeSplitTicketId;

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }

  Future<void> _openCreateTicketPage() async {
    final createdTicketId = await context.push<String>(
      RoutePaths.userSupportCreate,
    );

    if (!mounted || createdTicketId == null || createdTicketId.isEmpty) {
      return;
    }

    if (_usesSplitLayout(context)) {
      setState(() => _activeSplitTicketId = createdTicketId);
      await ref
          .read(userSupportControllerProvider.notifier)
          .selectTicket(createdTicketId, force: true);
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            UserSupportConversationScreen(ticketId: createdTicketId),
      ),
    );
  }

  Future<void> _openTicket(UserSupportTicketListItem ticket) async {
    if (_usesSplitLayout(context)) {
      setState(() => _activeSplitTicketId = ticket.id);
      await ref
          .read(userSupportControllerProvider.notifier)
          .selectTicket(ticket.id, force: true);
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => UserSupportConversationScreen(ticketId: ticket.id),
      ),
    );
  }

  void _setSearchQueryDebounced(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 260), () {
      if (!mounted) return;
      ref.read(userSupportControllerProvider.notifier).setSearchQuery(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(userSupportControllerProvider);
    final controller = ref.read(userSupportControllerProvider.notifier);
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
          onPressed: state.isRefreshingList ? null : controller.refreshTickets,
          icon: state.isRefreshingList
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
              activeTicketId: _activeSplitTicketId ?? state.selectedTicket?.id,
              onCreatePressed: _openCreateTicketPage,
              onSearchChanged: _setSearchQueryDebounced,
              onOpenTicket: (ticket) => unawaited(_openTicket(ticket)),
              lastMessagePreview: _lastMessagePreview,
            )
          : UserSupportTicketListView(
              state: state,
              activeTicketId: state.selectedTicket?.id,
              onCreatePressed: _openCreateTicketPage,
              onSearchChanged: _setSearchQueryDebounced,
              onStatusChanged: controller.setStatusFilter,
              onRefresh: controller.refreshTickets,
              onOpenTicket: (ticket) => unawaited(_openTicket(ticket)),
              lastMessagePreview: _lastMessagePreview,
            ),
    );
  }

  bool _usesSplitLayout(BuildContext context) {
    return MediaQuery.sizeOf(context).width >= 920;
  }

  String? _lastMessagePreview(
    UserSupportTicketListItem ticket,
    UserSupportState state,
  ) {
    final selected = state.selectedTicket;
    if (selected == null || selected.id != ticket.id) return null;

    for (final message in selected.messages.reversed) {
      final body = message.message.trim();
      if (body.isNotEmpty) return body;
    }
    return null;
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
    required this.lastMessagePreview,
  });

  final UserSupportState state;
  final UserSupportController controller;
  final String? activeTicketId;
  final VoidCallback onCreatePressed;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<UserSupportTicketListItem> onOpenTicket;
  final String? Function(UserSupportTicketListItem, UserSupportState)
  lastMessagePreview;

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
              child: UserSupportTicketListView(
                state: state,
                activeTicketId: activeTicketId,
                onCreatePressed: onCreatePressed,
                onSearchChanged: onSearchChanged,
                onStatusChanged: controller.setStatusFilter,
                onRefresh: controller.refreshTickets,
                onOpenTicket: onOpenTicket,
                lastMessagePreview: lastMessagePreview,
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
          : UserSupportConversationPane(ticketId: ticketId!),
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
