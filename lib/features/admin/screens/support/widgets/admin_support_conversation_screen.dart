import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../core/providers/core_providers.dart';
import '../../../../../core/theme/open_vts_colors.dart';
import '../../../../../core/theme/open_vts_radius.dart';
import '../../../../../core/theme/open_vts_spacing.dart';
import '../../../../../core/theme/open_vts_typography.dart';
import '../../../../../core/utils/date_time_formatter.dart';
import '../../../../../shared/helpers/toast_helper.dart';
import '../../../../../shared/widgets/open_vts_button.dart';
import '../../../../../shared/widgets/open_vts_empty_state.dart';
import '../../../../../shared/widgets/open_vts_error_view.dart';
import '../../../../../shared/widgets/open_vts_loader.dart';
import '../../../../../shared/widgets/open_vts_page_scaffold.dart';
import '../../../../auth/controllers/auth_controller.dart';
import '../../../controllers/admin_providers.dart';
import '../../../models/admin_support_model.dart';
import '../../../models/admin_support_state.dart';
import '../../../services/admin_support_service.dart';

const DateTimeFormatter _dateFormatter = DateTimeFormatter();

class AdminSupportConversationScreen extends StatelessWidget {
  const AdminSupportConversationScreen({
    required this.tab,
    required this.ticketId,
    super.key,
  });

  final AdminSupportTab tab;
  final String ticketId;

  @override
  Widget build(BuildContext context) {
    return OpenVtsPageScaffold(
      title: 'Support Ticket',
      headerMode: OpenVtsPageHeaderMode.standard,
      padding: EdgeInsets.zero,
      body: AdminSupportConversationPane(tab: tab, ticketId: ticketId),
    );
  }
}

class AdminSupportConversationPane extends ConsumerStatefulWidget {
  const AdminSupportConversationPane({
    required this.tab,
    required this.ticketId,
    this.onBack,
    super.key,
  });

  final AdminSupportTab tab;
  final String ticketId;
  final VoidCallback? onBack;

  @override
  ConsumerState<AdminSupportConversationPane> createState() =>
      _AdminSupportConversationPaneState();
}

class _AdminSupportConversationPaneState
    extends ConsumerState<AdminSupportConversationPane> {
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
    _scheduleTicketLoad();
  }

  @override
  void didUpdateWidget(covariant AdminSupportConversationPane oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tab != widget.tab || oldWidget.ticketId != widget.ticketId) {
      _activeTicketId = null;
      _messageCount = 0;
      _attachments = <PlatformFile>[];
      _replyController.clear();
      _scheduleTicketLoad();
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

  void _scheduleTicketLoad() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      unawaited(_loadTicket());
    });
  }

  Future<void> _loadTicket() {
    return ref.read(adminSupportControllerProvider.notifier).openTicket(
          tab: widget.tab,
          ticketId: widget.ticketId,
        );
  }

  Future<void> _refreshTicket() {
    return ref.read(adminSupportControllerProvider.notifier).loadTicketDetails(
          tab: widget.tab,
          ticketId: widget.ticketId,
        );
  }

  Future<void> _pickAttachments() async {
    final picked = await _pickAdminSupportAttachments(
      context,
      existing: _attachments,
    );
    if (!mounted || picked == null) {
      return;
    }
    setState(() => _attachments = picked);
  }

  Future<void> _sendReply(AdminSupportTicketDetails ticket) async {
    final message = _replyController.text.trim();
    if (message.isEmpty) {
      ToastHelper.showError('Reply message is required.', context: context);
      return;
    }
    if (message.length > AdminSupportService.maxMessageLength) {
      ToastHelper.showError(
        'Reply must be ${AdminSupportService.maxMessageLength} characters or less.',
        context: context,
      );
      return;
    }

    try {
      await ref.read(adminSupportControllerProvider.notifier).sendReply(
            tab: widget.tab,
            ticketId: ticket.id,
            message: message,
            attachments: _attachments,
          );

      if (!mounted) {
        return;
      }

      _replyController.clear();
      setState(() => _attachments = <PlatformFile>[]);
      _scheduleScrollToBottom();
      ToastHelper.showSuccess('Reply sent.', context: context);
    } catch (_) {
      if (!mounted) {
        return;
      }

      final error =
          ref.read(adminSupportControllerProvider).detailsErrorMessage ??
              'Unable to send reply.';
      ToastHelper.showError(error, context: context);
    }
  }

  Future<void> _updateStatus(
    AdminSupportTicketDetails ticket,
    AdminSupportTicketStatus status,
  ) async {
    if (status == ticket.status) {
      ToastHelper.showInfo('Ticket status is already ${status.label}.',
          context: context);
      return;
    }

    try {
      await ref
          .read(adminSupportControllerProvider.notifier)
          .updateTicketStatus(
            tab: widget.tab,
            ticketId: ticket.id,
            status: status,
          );
      if (!mounted) {
        return;
      }
      ToastHelper.showSuccess('Ticket status updated.', context: context);
    } catch (_) {
      if (!mounted) {
        return;
      }

      final error =
          ref.read(adminSupportControllerProvider).detailsErrorMessage ??
              'Unable to update ticket status.';
      ToastHelper.showError(error, context: context);
    }
  }

  void _syncTimeline(AdminSupportTicketDetails detail) {
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

  AdminSupportTicketDetails? _selectedDetail(AdminSupportState state) {
    final selected = state.selectedTicketDetails;
    if (selected == null ||
        state.selectedTicketId != widget.ticketId ||
        state.selectedTicketTab != widget.tab) {
      return null;
    }
    return selected;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminSupportControllerProvider);
    final detail = _selectedDetail(state);
    final baseUrl = ref.watch(apiBaseUrlProvider);
    final currentUserId = ref.watch(
      authControllerProvider.select((authState) => authState.user?.id ?? ''),
    );

    if (detail != null) {
      _syncTimeline(detail);
    }

    if (state.isLoadingDetails && detail == null) {
      return const Center(child: OpenVtsLoader());
    }

    if (detail == null) {
      return OpenVtsErrorView(
        message:
            state.detailsErrorMessage ?? 'Unable to load this support ticket.',
        onRetry: () => unawaited(_loadTicket()),
      );
    }

    return Column(
      children: [
        _ConversationHeader(
          ticket: detail,
          tab: widget.tab,
          onBack: widget.onBack,
          onRefresh: () => unawaited(_refreshTicket()),
          onStatusChanged: (status) => unawaited(_updateStatus(detail, status)),
          isRefreshing: state.isLoadingDetails,
          isUpdatingStatus: state.isUpdatingStatus,
        ),
        if (state.detailsErrorMessage != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              OpenVtsSpacing.md,
              0,
              OpenVtsSpacing.md,
              OpenVtsSpacing.xs,
            ),
            child:
                _InlineConversationError(message: state.detailsErrorMessage!),
          ),
        Expanded(
          child: _MessageTimeline(
            ticket: detail,
            tab: widget.tab,
            baseUrl: baseUrl,
            currentUserId: currentUserId,
            scrollController: _scrollController,
            onRefresh: _refreshTicket,
          ),
        ),
        if (detail.status == AdminSupportTicketStatus.closed)
          const _ClosedTicketNotice(),
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
                        _adminSupportAttachmentIdentity(item) !=
                        _adminSupportAttachmentIdentity(file),
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
    required this.tab,
    required this.onBack,
    required this.onRefresh,
    required this.onStatusChanged,
    required this.isRefreshing,
    required this.isUpdatingStatus,
  });

  final AdminSupportTicketDetails ticket;
  final AdminSupportTab tab;
  final VoidCallback? onBack;
  final VoidCallback onRefresh;
  final ValueChanged<AdminSupportTicketStatus> onStatusChanged;
  final bool isRefreshing;
  final bool isUpdatingStatus;

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
                      ticket.displayTicketNo,
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
                  color: _statusColor(ticket.status)),
              _StatusActionChip(
                status: ticket.status,
                isLoading: isUpdatingStatus,
                onSelected: onStatusChanged,
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
              if (_roleMetaLabel != null) _MetaChip(label: _roleMetaLabel!),
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

  String? get _roleMetaLabel {
    final source =
        tab == AdminSupportTab.userTickets ? ticket.fromUser : ticket.toUser;
    final name = source?.displayName.trim() ?? '';
    if (name.isEmpty || name == '-') {
      return null;
    }
    return tab == AdminSupportTab.userTickets ? 'User $name' : 'To $name';
  }
}

class _StatusActionChip extends StatelessWidget {
  const _StatusActionChip({
    required this.status,
    required this.isLoading,
    required this.onSelected,
  });

  final AdminSupportTicketStatus status;
  final bool isLoading;
  final ValueChanged<AdminSupportTicketStatus> onSelected;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<AdminSupportTicketStatus>(
      enabled: !isLoading,
      tooltip: 'Update status',
      onSelected: onSelected,
      itemBuilder: (context) {
        return AdminSupportTicketStatus.values
            .map(
              (value) => PopupMenuItem<AdminSupportTicketStatus>(
                value: value,
                child: Row(
                  children: [
                    if (value == status)
                      const Icon(Icons.check_rounded, size: 16),
                    if (value == status) const SizedBox(width: 6),
                    Text(value.label),
                  ],
                ),
              ),
            )
            .toList(growable: false);
      },
      child: _MetaChip(
        label: isLoading ? 'Updating' : 'Update status',
        color: isLoading ? OpenVtsColors.textSecondary : OpenVtsColors.brandInk,
        trailing: isLoading
            ? const SizedBox.square(
                dimension: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.expand_more_rounded, size: 16),
      ),
    );
  }
}

class _MessageTimeline extends StatelessWidget {
  const _MessageTimeline({
    required this.ticket,
    required this.tab,
    required this.baseUrl,
    required this.currentUserId,
    required this.scrollController,
    required this.onRefresh,
  });

  final AdminSupportTicketDetails ticket;
  final AdminSupportTab tab;
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
          return _AdminSupportMessageBubble(
            message: message,
            isCurrentUser: _isOutgoing(
              senderId: message.senderId,
              ticket: ticket,
              tab: tab,
              currentUserId: currentUserId,
            ),
            baseUrl: baseUrl,
          );
        },
      ),
    );
  }

  bool _isOutgoing({
    required AdminSupportTicketDetails ticket,
    required AdminSupportTab tab,
    required String currentUserId,
    required String senderId,
  }) {
    final normalizedSender = senderId.trim();
    if (normalizedSender.isEmpty) return false;

    if (currentUserId.trim().isNotEmpty &&
        normalizedSender == currentUserId.trim()) {
      return true;
    }

    if (tab == AdminSupportTab.userTickets) {
      final adminId = ticket.adminUserId.trim();
      if (adminId.isNotEmpty && adminId == normalizedSender) return true;
      return ticket.fromUserId.trim() != normalizedSender;
    }

    return ticket.toUserId.trim() != normalizedSender;
  }
}

class _AdminSupportMessageBubble extends StatelessWidget {
  const _AdminSupportMessageBubble({
    required this.message,
    required this.isCurrentUser,
    required this.baseUrl,
  });

  final AdminSupportMessage message;
  final bool isCurrentUser;
  final String baseUrl;

  @override
  Widget build(BuildContext context) {
    final alignment =
        isCurrentUser ? Alignment.centerRight : Alignment.centerLeft;
    final borderColor = isCurrentUser
        ? OpenVtsColors.brandInk.withValues(alpha: 0.18)
        : OpenVtsColors.border;
    final backgroundColor = isCurrentUser
        ? OpenVtsColors.brandInk.withValues(alpha: 0.045)
        : Theme.of(context).colorScheme.surface;

    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: Container(
          padding: const EdgeInsets.all(OpenVtsSpacing.sm),
          decoration: BoxDecoration(
            color: backgroundColor,
            border: Border.all(color: borderColor),
            borderRadius: BorderRadius.circular(OpenVtsRadius.md),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      _senderLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: OpenVtsTypography.meta.copyWith(
                        color: OpenVtsColors.textSecondary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (message.createdAt != null) ...[
                    const SizedBox(width: OpenVtsSpacing.xs),
                    Text(
                      _dateFormatter.formatDateTime(message.createdAt!),
                      style: OpenVtsTypography.meta.copyWith(
                        color: OpenVtsColors.textTertiary,
                      ),
                    ),
                  ],
                ],
              ),
              if (message.message.trim().isNotEmpty) ...[
                const SizedBox(height: OpenVtsSpacing.xxs),
                Text(
                  message.message.trim(),
                  style: OpenVtsTypography.body.copyWith(
                    color: OpenVtsColors.textPrimary,
                    height: 1.38,
                  ),
                ),
              ],
              if (message.attachments.isNotEmpty) ...[
                const SizedBox(height: OpenVtsSpacing.xs),
                _MessageAttachmentWrap(
                  attachments: message.attachments,
                  baseUrl: baseUrl,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String get _senderLabel {
    final displayName = message.sender?.displayName.trim() ?? '';
    if (displayName.isNotEmpty && displayName != '-') {
      return displayName;
    }
    return isCurrentUser ? 'You' : 'Support';
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
              _DraftAttachmentWrap(
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
                    maxLength: AdminSupportService.maxMessageLength,
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        OpenVtsSpacing.md,
        OpenVtsSpacing.xs,
        OpenVtsSpacing.md,
        0,
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
          'This ticket is closed. Reply may reopen or move it to In Progress based on backend behavior.',
          style: OpenVtsTypography.body.copyWith(
            color: OpenVtsColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.label, this.color, this.trailing});

  final String label;
  final Color? color;
  final Widget? trailing;

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
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: OpenVtsTypography.meta.copyWith(
              color: chipColor,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: OpenVtsSpacing.xxs),
            trailing!,
          ],
        ],
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

class _DraftAttachmentWrap extends StatelessWidget {
  const _DraftAttachmentWrap({
    required this.attachments,
    required this.onRemove,
  });

  final List<PlatformFile> attachments;
  final ValueChanged<PlatformFile> onRemove;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: OpenVtsSpacing.xs,
      runSpacing: OpenVtsSpacing.xs,
      children: attachments
          .map(
            (file) => Container(
              padding: const EdgeInsetsDirectional.only(
                start: OpenVtsSpacing.sm,
                end: OpenVtsSpacing.xxs,
              ),
              decoration: BoxDecoration(
                border: Border.all(color: OpenVtsColors.border),
                borderRadius: BorderRadius.circular(OpenVtsRadius.pill),
                color: OpenVtsColors.surface,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.insert_drive_file_outlined,
                    size: 14,
                    color: OpenVtsColors.textTertiary,
                  ),
                  const SizedBox(width: OpenVtsSpacing.xxs),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 176),
                    child: Text(
                      file.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: OpenVtsTypography.meta,
                    ),
                  ),
                  const SizedBox(width: OpenVtsSpacing.xxs),
                  IconButton(
                    tooltip: 'Remove attachment',
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 36,
                    ),
                    padding: EdgeInsets.zero,
                    iconSize: 16,
                    onPressed: () => onRemove(file),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
          )
          .toList(growable: false),
    );
  }
}

class _MessageAttachmentWrap extends StatelessWidget {
  const _MessageAttachmentWrap({
    required this.attachments,
    required this.baseUrl,
  });

  final List<AdminSupportAttachment> attachments;
  final String baseUrl;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: OpenVtsSpacing.xs,
      runSpacing: OpenVtsSpacing.xs,
      children: attachments
          .map(
            (attachment) => _UploadedAttachmentChip(
              attachment: attachment,
              baseUrl: baseUrl,
            ),
          )
          .toList(growable: false),
    );
  }
}

class _UploadedAttachmentChip extends StatelessWidget {
  const _UploadedAttachmentChip({
    required this.attachment,
    required this.baseUrl,
  });

  final AdminSupportAttachment attachment;
  final String baseUrl;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(OpenVtsRadius.md),
      onTap: () => _openAttachment(context),
      child: Container(
        constraints: const BoxConstraints(minHeight: 40, maxWidth: 240),
        padding: const EdgeInsets.symmetric(
          horizontal: OpenVtsSpacing.sm,
          vertical: OpenVtsSpacing.xs,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(OpenVtsRadius.md),
          border: Border.all(color: OpenVtsColors.border),
          color: OpenVtsColors.surface,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.insert_drive_file_outlined,
              size: 16,
              color: OpenVtsColors.textSecondary,
            ),
            const SizedBox(width: OpenVtsSpacing.xs),
            Flexible(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    attachment.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: OpenVtsTypography.meta.copyWith(
                      color: OpenVtsColors.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (attachment.sizeBytes > 0)
                    Text(
                      _formatFileSize(attachment.sizeBytes),
                      style: OpenVtsTypography.meta.copyWith(
                        color: OpenVtsColors.textTertiary,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openAttachment(BuildContext context) async {
    final path = attachment.filePath.trim();
    if (path.isEmpty) {
      ToastHelper.showError('Attachment path is not available.',
          context: context);
      return;
    }

    final resolved = _resolveAttachmentUrl(baseUrl, path);
    final uri = Uri.tryParse(resolved);
    if (uri == null) {
      ToastHelper.showError('Unable to open this attachment.',
          context: context);
      return;
    }

    try {
      final launched =
          await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && context.mounted) {
        await Clipboard.setData(ClipboardData(text: resolved));
        if (context.mounted) {
          ToastHelper.showInfo('Could not open file. Link copied.',
              context: context);
        }
      }
    } catch (_) {
      if (context.mounted) {
        ToastHelper.showError('Could not open attachment.', context: context);
      }
    }
  }
}

Future<List<PlatformFile>?> _pickAdminSupportAttachments(
  BuildContext context, {
  required List<PlatformFile> existing,
}) async {
  final remaining = AdminSupportService.maxAttachmentCount - existing.length;
  if (remaining <= 0) {
    ToastHelper.showError(
      'You can upload up to ${AdminSupportService.maxAttachmentCount} files.',
      context: context,
    );
    return existing;
  }

  final result = await FilePicker.platform.pickFiles(
    allowMultiple: true,
    withData: true,
    type: FileType.custom,
    allowedExtensions:
        AdminSupportService.allowedExtensions.toList(growable: false),
  );

  if (!context.mounted || result == null || result.files.isEmpty) {
    return null;
  }

  final merged = <PlatformFile>[...existing];
  final blocked = <String>[];
  final unsupported = <String>[];
  final oversized = <String>[];

  for (final file in result.files) {
    if (merged.length >= AdminSupportService.maxAttachmentCount) {
      break;
    }

    final fileName = file.name.trim().isEmpty ? 'attachment' : file.name.trim();
    final extension = _extensionFromFileName(fileName);
    if (AdminSupportService.blockedExtensions.contains(extension)) {
      blocked.add(fileName);
      continue;
    }
    if (!AdminSupportService.allowedExtensions.contains(extension)) {
      unsupported.add(fileName);
      continue;
    }
    if (file.size > AdminSupportService.maxAttachmentBytes) {
      oversized.add(fileName);
      continue;
    }

    final id = _adminSupportAttachmentIdentity(file);
    final exists = merged.any(
      (item) => _adminSupportAttachmentIdentity(item) == id,
    );
    if (!exists) {
      merged.add(file);
    }
  }

  if (blocked.isNotEmpty) {
    ToastHelper.showError(
      'Blocked file removed: ${_compactFileList(blocked)}',
      context: context,
    );
  }
  if (unsupported.isNotEmpty) {
    ToastHelper.showError(
      'Unsupported file removed: ${_compactFileList(unsupported)}',
      context: context,
    );
  }
  if (oversized.isNotEmpty) {
    ToastHelper.showError(
      'File exceeds 5MB: ${_compactFileList(oversized)}',
      context: context,
    );
  }

  return merged;
}

String _adminSupportAttachmentIdentity(PlatformFile file) {
  final path = file.path?.trim() ?? '';
  return '${file.name.trim().toLowerCase()}|${file.size}|$path';
}

String _extensionFromFileName(String fileName) {
  final normalized = fileName.trim().toLowerCase();
  final index = normalized.lastIndexOf('.');
  if (index < 0 || index == normalized.length - 1) {
    return '';
  }
  return normalized.substring(index + 1);
}

String _compactFileList(List<String> names) {
  final cleaned = names
      .map((name) => name.trim())
      .where((name) => name.isNotEmpty)
      .toList(growable: false);

  if (cleaned.isEmpty) {
    return 'Unknown file';
  }
  if (cleaned.length <= 2) {
    return cleaned.join(', ');
  }
  return '${cleaned.take(2).join(', ')} +${cleaned.length - 2} more';
}

String _formatFileSize(int bytes) {
  if (bytes <= 0) {
    return '';
  }

  const units = <String>['B', 'KB', 'MB', 'GB'];
  var value = bytes.toDouble();
  var unitIndex = 0;

  while (value >= 1024 && unitIndex < units.length - 1) {
    value /= 1024;
    unitIndex++;
  }

  final decimals = value >= 10 || unitIndex == 0 ? 0 : 1;
  return '${value.toStringAsFixed(decimals)} ${units[unitIndex]}';
}

String _resolveAttachmentUrl(String baseUrl, String path) {
  final normalizedPath = path.trim();
  if (normalizedPath.startsWith('http://') ||
      normalizedPath.startsWith('https://')) {
    return normalizedPath;
  }

  final rootUri = Uri.tryParse(baseUrl);
  if (rootUri == null) {
    return normalizedPath;
  }

  var basePath = rootUri.path;
  if (basePath.isEmpty) {
    basePath = '/';
  }
  if (!basePath.endsWith('/')) {
    basePath = '$basePath/';
  }

  final apiRoot = rootUri.replace(
    path: basePath,
    queryParameters: null,
    fragment: null,
  );
  final relativePath = normalizedPath.startsWith('/')
      ? normalizedPath.substring(1)
      : normalizedPath;

  return apiRoot.resolve(relativePath).toString();
}

Color _statusColor(AdminSupportTicketStatus status) {
  switch (status) {
    case AdminSupportTicketStatus.open:
      return OpenVtsColors.success;
    case AdminSupportTicketStatus.inProgress:
      return OpenVtsColors.warning;
    case AdminSupportTicketStatus.closed:
      return OpenVtsColors.textTertiary;
  }
}

Color _priorityColor(AdminSupportTicketPriority priority) {
  switch (priority) {
    case AdminSupportTicketPriority.high:
      return OpenVtsColors.warning;
    case AdminSupportTicketPriority.medium:
      return OpenVtsColors.brandInk;
    case AdminSupportTicketPriority.low:
      return OpenVtsColors.success;
  }
}
