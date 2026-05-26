import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_vts/core/providers/core_providers.dart';
import 'package:open_vts/core/theme/open_vts_colors.dart';
import 'package:open_vts/core/theme/open_vts_radius.dart';
import 'package:open_vts/core/theme/open_vts_spacing.dart';
import 'package:open_vts/core/theme/open_vts_typography.dart';
import 'package:open_vts/core/utils/date_time_formatter.dart';
import 'package:open_vts/features/auth/controllers/auth_controller.dart';
import 'package:open_vts/features/user/controllers/user_providers.dart';
import 'package:open_vts/features/user/models/user_support_constraints.dart';
import 'package:open_vts/features/user/models/user_support_model.dart';
import 'package:open_vts/features/user/models/user_support_state.dart';
import 'package:open_vts/features/user/screens/support/widgets/user_support_attachment_widgets.dart';
import 'package:open_vts/features/user/screens/support/widgets/user_support_message_bubble.dart';
import 'package:open_vts/shared/helpers/toast_helper.dart';
import 'package:open_vts/shared/widgets/open_vts_button.dart';
import 'package:open_vts/shared/widgets/open_vts_empty_state.dart';
import 'package:open_vts/shared/widgets/open_vts_error_view.dart';
import 'package:open_vts/shared/widgets/open_vts_loader.dart';
import 'package:open_vts/shared/widgets/open_vts_page_scaffold.dart';

const DateTimeFormatter _dateFormatter = DateTimeFormatter();

class UserSupportConversationScreen extends StatelessWidget {
  const UserSupportConversationScreen({required this.ticketId, super.key});

  final String ticketId;

  @override
  Widget build(BuildContext context) {
    return OpenVtsPageScaffold(
      title: 'Support Ticket',
      headerMode: OpenVtsPageHeaderMode.standard,
      padding: EdgeInsets.zero,
      body: UserSupportConversationPane(ticketId: ticketId),
    );
  }
}

class UserSupportConversationPane extends ConsumerStatefulWidget {
  const UserSupportConversationPane({
    required this.ticketId,
    this.onBack,
    super.key,
  });

  final String ticketId;
  final VoidCallback? onBack;

  @override
  ConsumerState<UserSupportConversationPane> createState() =>
      _UserSupportConversationPaneState();
}

class _UserSupportConversationPaneState
    extends ConsumerState<UserSupportConversationPane> {
  final TextEditingController _replyController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<PlatformFile> _attachments = <PlatformFile>[];
  String? _activeTicketId;
  int _messageCount = 0;
  bool _hasReplyText = false;

  @override
  void initState() {
    super.initState();
    _replyController.addListener(_handleReplyTextChanged);
    _scheduleTicketLoad(force: true);
  }

  @override
  void didUpdateWidget(covariant UserSupportConversationPane oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.ticketId != widget.ticketId) {
      _activeTicketId = null;
      _messageCount = 0;
      _attachments = <PlatformFile>[];
      _replyController.clear();
      _scheduleTicketLoad(force: true);
    }
  }

  @override
  void dispose() {
    _replyController.removeListener(_handleReplyTextChanged);
    _replyController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleReplyTextChanged() {
    final hasText = _replyController.text.trim().isNotEmpty;
    if (hasText != _hasReplyText) {
      setState(() => _hasReplyText = hasText);
    }
  }

  void _scheduleTicketLoad({required bool force}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      unawaited(_loadTicket(force: force));
    });
  }

  Future<void> _loadTicket({required bool force}) {
    return ref
        .read(userSupportControllerProvider.notifier)
        .selectTicket(widget.ticketId, force: force);
  }

  Future<void> _refreshTicket() {
    return _loadTicket(force: true);
  }

  Future<void> _pickAttachments() async {
    final picked = await pickUserSupportAttachments(
      context,
      existing: _attachments,
    );
    if (!mounted || picked == null) {
      return;
    }
    setState(() => _attachments = picked);
  }

  Future<void> _sendReply(UserSupportTicketDetail ticket) async {
    final message = _replyController.text.trim();
    if (ticket.isClosed) {
      ToastHelper.showInfo('This ticket is closed.', context: context);
      return;
    }
    if (message.isEmpty) {
      return;
    }
    if (message.length > userSupportMaxMessageLength) {
      ToastHelper.showError(
        'Reply must be $userSupportMaxMessageLength characters or less.',
        context: context,
      );
      return;
    }

    final detail =
        await ref.read(userSupportControllerProvider.notifier).replyToTicket(
              ticketId: ticket.id,
              message: message,
              attachments: _attachments,
            );
    if (!mounted) {
      return;
    }

    if (detail == null) {
      final error = ref.read(userSupportControllerProvider).detailErrorMessage;
      ToastHelper.showError(error ?? 'Unable to send reply.', context: context);
      return;
    }

    _replyController.clear();
    setState(() => _attachments = <PlatformFile>[]);
    _scheduleScrollToBottom();
  }

  void _syncTimeline(UserSupportTicketDetail detail) {
    final ticketChanged = _activeTicketId != detail.id;
    final countChanged = _messageCount != detail.messages.length;

    if (!ticketChanged && !countChanged) {
      return;
    }

    _activeTicketId = detail.id;
    _messageCount = detail.messages.length;
    _scheduleScrollToBottom(jump: ticketChanged);
  }

  void _scheduleScrollToBottom({bool jump = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) {
        return;
      }
      final position = _scrollController.position.maxScrollExtent;
      if (jump) {
        _scrollController.jumpTo(position);
      } else {
        _scrollController.animateTo(
          position,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  UserSupportTicketDetail? _selectedDetail(UserSupportState state) {
    final selected = state.selectedTicket;
    if (selected == null || selected.id != widget.ticketId) {
      return null;
    }
    return selected;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(userSupportControllerProvider);
    final detail = _selectedDetail(state);
    final baseUrl = ref.watch(apiBaseUrlProvider);
    final currentUserId = ref.watch(
      authControllerProvider.select((authState) => authState.user?.id ?? ''),
    );

    if (detail != null) {
      _syncTimeline(detail);
    }

    if (state.isLoadingDetail && detail == null) {
      return const Center(child: OpenVtsLoader());
    }

    if (detail == null) {
      return OpenVtsErrorView(
        message:
            state.detailErrorMessage ?? 'Unable to load this support ticket.',
        onRetry: () => unawaited(_loadTicket(force: true)),
      );
    }

    return Column(
      children: [
        _ConversationHeader(
          ticket: detail,
          onBack: widget.onBack,
          onRefresh: () => unawaited(_refreshTicket()),
          isRefreshing: state.isLoadingDetail,
        ),
        if (state.detailErrorMessage != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              OpenVtsSpacing.md,
              0,
              OpenVtsSpacing.md,
              OpenVtsSpacing.xs,
            ),
            child: _InlineConversationError(message: state.detailErrorMessage!),
          ),
        Expanded(
          child: _MessageTimeline(
            ticket: detail,
            baseUrl: baseUrl,
            currentUserId: currentUserId,
            scrollController: _scrollController,
            onRefresh: _refreshTicket,
          ),
        ),
        if (detail.isClosed)
          const _ClosedTicketNotice()
        else
          _ReplyComposer(
            controller: _replyController,
            attachments: _attachments,
            canSend: _hasReplyText && !state.isReplying,
            isSending: state.isReplying,
            onAttach: state.isReplying ? null : _pickAttachments,
            onRemoveAttachment: (file) {
              setState(
                () => _attachments = _attachments
                    .where(
                      (item) =>
                          userSupportAttachmentIdentity(item) !=
                          userSupportAttachmentIdentity(file),
                    )
                    .toList(growable: false),
              );
            },
            onSend: () => unawaited(_sendReply(detail)),
          ),
      ],
    );
  }
}

class _ConversationHeader extends StatelessWidget {
  const _ConversationHeader({
    required this.ticket,
    required this.onBack,
    required this.onRefresh,
    required this.isRefreshing,
  });

  final UserSupportTicketDetail ticket;
  final VoidCallback? onBack;
  final VoidCallback onRefresh;
  final bool isRefreshing;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        OpenVtsSpacing.md,
        OpenVtsSpacing.sm,
        OpenVtsSpacing.md,
        OpenVtsSpacing.sm,
      ),
      decoration: const BoxDecoration(
        color: OpenVtsColors.surface,
        border: Border(bottom: BorderSide(color: OpenVtsColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (onBack != null) ...[
                IconButton(
                  tooltip: 'Back',
                  onPressed: onBack,
                  icon: const Icon(Icons.arrow_back_rounded),
                  constraints: const BoxConstraints(
                    minWidth: 40,
                    minHeight: 40,
                  ),
                  padding: EdgeInsets.zero,
                ),
                const SizedBox(width: OpenVtsSpacing.xs),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ticket.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: OpenVtsTypography.titleSmall.copyWith(
                        color: OpenVtsColors.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: OpenVtsSpacing.xxs),
                    Text(
                      _ticketNumber(ticket),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: OpenVtsTypography.meta.copyWith(
                        color: OpenVtsColors.textTertiary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: OpenVtsSpacing.sm),
              IconButton(
                tooltip: 'Refresh',
                onPressed: isRefreshing ? null : onRefresh,
                icon: isRefreshing
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
          const SizedBox(height: OpenVtsSpacing.xs),
          Wrap(
            spacing: OpenVtsSpacing.xs,
            runSpacing: OpenVtsSpacing.xs,
            children: [
              _MetaChip(
                label: ticket.status.label,
                color: _statusColor(ticket.status),
              ),
              _MetaChip(
                label: ticket.priority.label,
                color: _priorityColor(ticket.priority),
              ),
              _MetaChip(label: ticket.category.label),
              _MetaChip(
                label:
                    '${ticket.messages.length} ${ticket.messages.length == 1 ? 'message' : 'messages'}',
              ),
              if (ticket.createdAt != null)
                _MetaChip(
                  label:
                      'Created ${_dateFormatter.formatDate(ticket.createdAt!)}',
                ),
              if (ticket.updatedAt != null)
                _MetaChip(
                  label:
                      'Updated ${_dateFormatter.formatDate(ticket.updatedAt!)}',
                ),
              if (ticket.closedAt != null)
                _MetaChip(
                  label:
                      'Closed ${_dateFormatter.formatDate(ticket.closedAt!)}',
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MessageTimeline extends StatelessWidget {
  const _MessageTimeline({
    required this.ticket,
    required this.baseUrl,
    required this.currentUserId,
    required this.scrollController,
    required this.onRefresh,
  });

  final UserSupportTicketDetail ticket;
  final String baseUrl;
  final String currentUserId;
  final ScrollController scrollController;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final messages = ticket.messages;
    if (messages.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
          controller: scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(OpenVtsSpacing.lg),
          children: const [
            SizedBox(height: OpenVtsSpacing.xl),
            OpenVtsEmptyState(
              title: 'No conversation yet',
              message:
                  'Replies will appear here once the ticket conversation starts.',
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.separated(
        controller: scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          OpenVtsSpacing.md,
          OpenVtsSpacing.md,
          OpenVtsSpacing.md,
          OpenVtsSpacing.lg,
        ),
        itemCount: messages.length,
        separatorBuilder: (_, __) => const SizedBox(height: OpenVtsSpacing.sm),
        itemBuilder: (context, index) {
          final message = messages[index];
          return UserSupportMessageBubble(
            message: message,
            isCurrentUser: message.isFromCurrentUser(currentUserId),
            baseUrl: baseUrl,
          );
        },
      ),
    );
  }
}

class _ReplyComposer extends StatelessWidget {
  const _ReplyComposer({
    required this.controller,
    required this.attachments,
    required this.canSend,
    required this.isSending,
    required this.onAttach,
    required this.onRemoveAttachment,
    required this.onSend,
  });

  final TextEditingController controller;
  final List<PlatformFile> attachments;
  final bool canSend;
  final bool isSending;
  final VoidCallback? onAttach;
  final ValueChanged<PlatformFile> onRemoveAttachment;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(OpenVtsSpacing.md),
        decoration: const BoxDecoration(
          color: OpenVtsColors.surface,
          border: Border(top: BorderSide(color: OpenVtsColors.border)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (attachments.isNotEmpty) ...[
              UserSupportDraftAttachmentWrap(
                attachments: attachments,
                onRemove: onRemoveAttachment,
              ),
              const SizedBox(height: OpenVtsSpacing.xs),
            ],
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                IconButton(
                  tooltip: 'Attach file',
                  onPressed: onAttach,
                  constraints: const BoxConstraints(
                    minWidth: 40,
                    minHeight: 40,
                  ),
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.attach_file_rounded),
                ),
                const SizedBox(width: OpenVtsSpacing.xs),
                Expanded(
                  child: TextField(
                    controller: controller,
                    minLines: 1,
                    maxLines: 4,
                    maxLength: userSupportMaxMessageLength,
                    textInputAction: TextInputAction.newline,
                    decoration: const InputDecoration(
                      hintText: 'Write a reply...',
                      counterText: '',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: OpenVtsSpacing.sm,
                        vertical: OpenVtsSpacing.sm,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: OpenVtsSpacing.xs),
                OpenVtsButton(
                  label: 'Send',
                  isLoading: isSending,
                  trailingIcon: isSending ? null : Icons.send_rounded,
                  onPressed: canSend ? onSend : null,
                  height: 40,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ClosedTicketNotice extends StatelessWidget {
  const _ClosedTicketNotice();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(OpenVtsSpacing.md),
        decoration: const BoxDecoration(
          color: OpenVtsColors.surface,
          border: Border(top: BorderSide(color: OpenVtsColors.border)),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: OpenVtsSpacing.sm,
            vertical: OpenVtsSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: OpenVtsColors.surface,
            border: Border.all(color: OpenVtsColors.border),
            borderRadius: BorderRadius.circular(OpenVtsRadius.md),
          ),
          child: Text(
            'This ticket is closed or resolved. Replies are disabled.',
            style: OpenVtsTypography.body.copyWith(
              color: OpenVtsColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.label, this.color});

  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? OpenVtsColors.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: OpenVtsSpacing.sm,
        vertical: OpenVtsSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: chipColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(OpenVtsRadius.pill),
        border: Border.all(color: chipColor.withValues(alpha: 0.18)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: OpenVtsTypography.meta.copyWith(
          color: chipColor,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _InlineConversationError extends StatelessWidget {
  const _InlineConversationError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: OpenVtsSpacing.sm,
        vertical: OpenVtsSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: OpenVtsColors.error.withValues(alpha: 0.07),
        border: Border.all(color: OpenVtsColors.error.withValues(alpha: 0.28)),
        borderRadius: BorderRadius.circular(OpenVtsRadius.md),
      ),
      child: Text(
        message,
        style: OpenVtsTypography.body.copyWith(color: OpenVtsColors.error),
      ),
    );
  }
}

String _ticketNumber(UserSupportTicketDetail ticket) {
  final number = ticket.displayTicketNo.trim();
  if (number.isNotEmpty && number != '-') {
    return number;
  }
  return '#${ticket.id}';
}

Color _statusColor(UserSupportTicketStatus status) {
  switch (status) {
    case UserSupportTicketStatus.open:
      return OpenVtsColors.success;
    case UserSupportTicketStatus.inProgress:
      return OpenVtsColors.warning;
    case UserSupportTicketStatus.closed:
      return OpenVtsColors.textTertiary;
  }
}

Color _priorityColor(UserSupportTicketPriority priority) {
  switch (priority) {
    case UserSupportTicketPriority.high:
      return OpenVtsColors.warning;
    case UserSupportTicketPriority.medium:
      return OpenVtsColors.brandInk;
    case UserSupportTicketPriority.low:
      return OpenVtsColors.success;
  }
}
