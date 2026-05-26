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
import 'package:open_vts/features/superadmin/controllers/superadmin_providers.dart';
import 'package:open_vts/features/superadmin/models/superadmin_support_model.dart';
import 'package:open_vts/features/superadmin/models/superadmin_support_state.dart';
import 'package:open_vts/shared/helpers/toast_helper.dart';
import 'package:open_vts/shared/widgets/open_vts_button.dart';
import 'package:open_vts/shared/widgets/open_vts_empty_state.dart';
import 'package:open_vts/shared/widgets/open_vts_error_view.dart';
import 'package:open_vts/shared/widgets/open_vts_loader.dart';
import 'package:open_vts/shared/widgets/open_vts_page_scaffold.dart';
import 'package:url_launcher/url_launcher.dart';

const DateTimeFormatter _dateFormatter = DateTimeFormatter();
const int _supportMaxAttachmentCount = 5;
const int _supportMaxAttachmentBytes = 5 * 1024 * 1024;
const int _supportMaxMessageLength = 5000;
const List<String> _supportAllowedAttachmentExtensions = <String>[
  'pdf',
  'jpg',
  'jpeg',
  'png',
  'gif',
  'doc',
  'docx',
  'txt',
  'zip',
];

class SuperadminSupportConversationScreen extends StatelessWidget {
  const SuperadminSupportConversationScreen(
      {required this.ticketId, super.key});

  final int ticketId;

  @override
  Widget build(BuildContext context) {
    return OpenVtsPageScaffold(
      title: 'Ticket Conversation',
      headerMode: OpenVtsPageHeaderMode.standard,
      padding: EdgeInsets.zero,
      body: SuperadminSupportConversationPane(ticketId: ticketId),
    );
  }
}

class SuperadminSupportConversationPane extends ConsumerStatefulWidget {
  const SuperadminSupportConversationPane({
    required this.ticketId,
    this.onBack,
    super.key,
  });

  final int ticketId;
  final VoidCallback? onBack;

  @override
  ConsumerState<SuperadminSupportConversationPane> createState() =>
      _SuperadminSupportConversationPaneState();
}

class _SuperadminSupportConversationPaneState
    extends ConsumerState<SuperadminSupportConversationPane> {
  final TextEditingController _replyController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<PlatformFile> _replyAttachments = <PlatformFile>[];
  int? _activeTicketId;
  int _messageCount = 0;
  bool _hasReplyText = false;

  @override
  void initState() {
    super.initState();
    _replyController.addListener(_handleReplyTextChanged);
    _scheduleTicketLoad(force: true);
  }

  @override
  void didUpdateWidget(covariant SuperadminSupportConversationPane oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.ticketId != widget.ticketId) {
      _activeTicketId = null;
      _messageCount = 0;
      _replyAttachments = <PlatformFile>[];
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
      unawaited(_loadTicket());
    });
  }

  Future<void> _loadTicket() {
    return ref
        .read(superadminSupportControllerProvider.notifier)
        .selectTicket(widget.ticketId);
  }

  Future<void> _refreshTicket() {
    return ref
        .read(superadminSupportControllerProvider.notifier)
        .loadSelectedTicket();
  }

  Future<void> _pickReplyAttachments() async {
    final files = await _pickSupportAttachments(
      existing: _replyAttachments,
      maxCount: _supportMaxAttachmentCount,
    );

    if (!mounted || files == null) {
      return;
    }

    final sanitized = _filterInvalidAttachments(context, files);
    if (sanitized.isEmpty && files.isNotEmpty) {
      return;
    }

    setState(() {
      _replyAttachments = sanitized;
    });
  }

  Future<void> _sendReply(SuperadminSupportTicketDetails ticket) async {
    final message = _replyController.text.trim();
    if (message.isEmpty) {
      ToastHelper.showError('Reply message is required.', context: context);
      return;
    }

    if (message.length > _supportMaxMessageLength) {
      ToastHelper.showError(
        'Reply must be $_supportMaxMessageLength characters or less.',
        context: context,
      );
      return;
    }

    if (_replyAttachments.length > _supportMaxAttachmentCount) {
      ToastHelper.showError(
        'You can upload up to $_supportMaxAttachmentCount files.',
        context: context,
      );
      return;
    }

    if (_replyAttachments
        .any((file) => file.size > _supportMaxAttachmentBytes)) {
      ToastHelper.showError(
        'Each attachment must be 5MB or smaller.',
        context: context,
      );
      return;
    }

    try {
      await ref.read(superadminSupportControllerProvider.notifier).sendReply(
            ticketId: ticket.id,
            message: message,
            attachments: _replyAttachments,
          );
      if (!mounted) {
        return;
      }

      _replyController.clear();
      setState(() {
        _replyAttachments = <PlatformFile>[];
      });
      _scheduleScrollToBottom();
      ToastHelper.showSuccess('Reply sent successfully.', context: context);
    } catch (_) {
      if (!mounted) {
        return;
      }
      final error =
          ref.read(superadminSupportControllerProvider).detailsErrorMessage ??
              'Unable to send reply right now.';
      ToastHelper.showError(error, context: context);
    }
  }

  Future<void> _updateStatus(SuperadminSupportTicketDetails details,
      SuperadminSupportTicketStatus status) async {
    if (status == details.status) {
      ToastHelper.showInfo('Ticket status is already ${status.label}.');
      return;
    }

    try {
      await ref
          .read(superadminSupportControllerProvider.notifier)
          .updateStatus(id: details.id, status: status);
      if (!mounted) {
        return;
      }
      ToastHelper.showSuccess('Ticket status updated.', context: context);
    } catch (_) {
      if (!mounted) {
        return;
      }
      final error =
          ref.read(superadminSupportControllerProvider).detailsErrorMessage ??
              'Unable to update ticket status right now.';
      ToastHelper.showError(error, context: context);
    }
  }

  void _syncTimeline(SuperadminSupportTicketDetails detail) {
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

  SuperadminSupportTicketDetails? _selectedDetail(
      SuperadminSupportState state) {
    final selected = state.selectedTicketDetails;
    if (selected == null || selected.id != widget.ticketId) {
      return null;
    }
    return selected;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(superadminSupportControllerProvider);
    final detail = _selectedDetail(state);
    final baseUrl = ref.watch(apiBaseUrlProvider);
    final currentUserId = ref.watch(
      authControllerProvider
          .select((authState) => authState.user?.id.toString() ?? ''),
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
          state: state,
          onBack: widget.onBack,
          onRefresh: () => unawaited(_refreshTicket()),
          isRefreshing: state.isLoadingDetails,
          onUpdateStatus: (status) => unawaited(_updateStatus(detail, status)),
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
            baseUrl: baseUrl,
            currentUserId: currentUserId,
            scrollController: _scrollController,
            onRefresh: _refreshTicket,
          ),
        ),
        if (detail.status == SuperadminSupportTicketStatus.closed)
          const _ClosedTicketNotice()
        else
          _ReplyComposer(
            controller: _replyController,
            attachments: _replyAttachments,
            canSend: _hasReplyText && !state.isReplying,
            isSending: state.isReplying,
            onAttach: state.isReplying ? null : _pickReplyAttachments,
            onRemoveAttachment: (file) {
              setState(
                () => _replyAttachments = _replyAttachments
                    .where(
                      (item) =>
                          _attachmentIdentity(item) !=
                          _attachmentIdentity(file),
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
    required this.state,
    required this.onBack,
    required this.onRefresh,
    required this.isRefreshing,
    required this.onUpdateStatus,
  });

  final SuperadminSupportTicketDetails ticket;
  final SuperadminSupportState state;
  final VoidCallback? onBack;
  final VoidCallback onRefresh;
  final bool isRefreshing;
  final ValueChanged<SuperadminSupportTicketStatus> onUpdateStatus;

  @override
  Widget build(BuildContext context) {
    final fromName = ticket.fromUser?.displayName ??
        (ticket.fromUserId != null ? 'Admin #${ticket.fromUserId}' : 'Admin');
    final fromEmail = ticket.fromUser?.email.trim() ?? '';

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
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _MetaChip(
                  label: ticket.status.label,
                  color: _statusColor(ticket.status)),
              _SupportStatusActionButton(
                status: ticket.status,
                isLoading: state.isUpdatingStatus,
                onSelected: onUpdateStatus,
              ),
              _MetaChip(label: ticket.category.label),
              _MetaChip(
                  label: ticket.priority.label,
                  color: _priorityColor(ticket.priority)),
              _MetaChip(
                  label:
                      'From: $fromName${fromEmail.isNotEmpty ? ' ($fromEmail)' : ''}'),
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

class _SupportStatusActionButton extends StatelessWidget {
  const _SupportStatusActionButton({
    required this.status,
    required this.isLoading,
    required this.onSelected,
  });

  final SuperadminSupportTicketStatus status;
  final bool isLoading;
  final ValueChanged<SuperadminSupportTicketStatus> onSelected;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<SuperadminSupportTicketStatus>(
      enabled: !isLoading,
      tooltip: 'Change status',
      onSelected: onSelected,
      itemBuilder: (context) {
        return SuperadminSupportTicketStatus.values
            .map(
              (status) => PopupMenuItem<SuperadminSupportTicketStatus>(
                value: status,
                child: Text(status.label),
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
    required this.baseUrl,
    required this.currentUserId,
    required this.scrollController,
    required this.onRefresh,
  });

  final SuperadminSupportTicketDetails ticket;
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
              message: 'Replies will appear here once the conversation starts.',
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
          final mine = _isMessageFromSuperadmin(ticket, message, currentUserId);
          return SuperadminSupportMessageBubble(
            message: message,
            isMine: mine,
            baseUrl: baseUrl,
          );
        },
      ),
    );
  }

  bool _isMessageFromSuperadmin(
    SuperadminSupportTicketDetails ticket,
    SuperadminSupportMessage message,
    String? currentUserId,
  ) {
    final senderId = message.senderId.trim();
    if (senderId.isEmpty) {
      return false;
    }

    final toUserId = ticket.toUserId?.toString().trim();
    if (toUserId != null && toUserId.isNotEmpty && senderId == toUserId) {
      return true;
    }

    final normalizedCurrentUserId = currentUserId?.trim();
    if (normalizedCurrentUserId != null && normalizedCurrentUserId.isNotEmpty) {
      return senderId == normalizedCurrentUserId;
    }

    return false;
  }
}

class SuperadminSupportMessageBubble extends StatelessWidget {
  const SuperadminSupportMessageBubble({
    required this.message,
    required this.isMine,
    required this.baseUrl,
    super.key,
  });

  final SuperadminSupportMessage message;
  final bool isMine;
  final String baseUrl;

  @override
  Widget build(BuildContext context) {
    final alignment = isMine ? Alignment.centerRight : Alignment.centerLeft;
    final borderColor = isMine
        ? OpenVtsColors.brandInk.withValues(alpha: 0.18)
        : OpenVtsColors.border;
    final backgroundColor = isMine
        ? OpenVtsColors.brandInk.withValues(alpha: 0.045)
        : Theme.of(context).colorScheme.surface;

    final senderLabel = message.sender?.displayName.trim().isNotEmpty == true
        ? message.sender!.displayName
        : (isMine ? 'You' : 'Admin');

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
                      senderLabel,
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
                      _dateFormatter
                          .formatDateTime(message.createdAt!.toLocal()),
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
                SuperadminSupportMessageAttachmentWrap(
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
}

class SuperadminSupportMessageAttachmentWrap extends StatelessWidget {
  const SuperadminSupportMessageAttachmentWrap({
    required this.attachments,
    required this.baseUrl,
    super.key,
  });

  final List<SuperadminSupportAttachment> attachments;
  final String baseUrl;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: OpenVtsSpacing.xs,
      runSpacing: OpenVtsSpacing.xs,
      children: attachments
          .map(
            (attachment) => _MessageAttachmentChip(
              attachment: attachment,
              baseUrl: baseUrl,
            ),
          )
          .toList(growable: false),
    );
  }
}

class _MessageAttachmentChip extends StatelessWidget {
  const _MessageAttachmentChip({
    required this.attachment,
    required this.baseUrl,
  });

  final SuperadminSupportAttachment attachment;
  final String baseUrl;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(OpenVtsRadius.md),
      onTap: () async {
        final path = attachment.filePath.trim();
        if (path.isEmpty) {
          ToastHelper.showError(
            'Attachment path is not available.',
            context: context,
          );
          return;
        }

        final resolved = _resolveAttachmentUrl(baseUrl, path);
        final uri = Uri.tryParse(resolved);
        if (uri == null) {
          ToastHelper.showError('Unable to open this attachment.',
              context: context);
          return;
        }

        final launched =
            await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (!launched && context.mounted) {
          ToastHelper.showError('Could not open attachment.', context: context);
        }
      },
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
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
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
}

class SuperadminSupportDraftAttachmentWrap extends StatelessWidget {
  const SuperadminSupportDraftAttachmentWrap({
    required this.attachments,
    required this.onRemove,
    super.key,
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
              SuperadminSupportDraftAttachmentWrap(
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
                    maxLength: _supportMaxMessageLength,
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

Future<List<PlatformFile>?> _pickSupportAttachments({
  required List<PlatformFile> existing,
  required int maxCount,
}) async {
  final remaining = maxCount - existing.length;
  if (remaining <= 0) {
    return existing;
  }

  final result = await FilePicker.platform.pickFiles(
    allowMultiple: true,
    withData: true,
    type: FileType.custom,
    allowedExtensions: _supportAllowedAttachmentExtensions,
  );

  if (result == null || result.files.isEmpty) {
    return null;
  }

  final merged = <PlatformFile>[...existing];
  for (final file in result.files) {
    if (merged.length >= maxCount) {
      break;
    }

    final id = _attachmentIdentity(file);
    final alreadyExists =
        merged.any((existingFile) => _attachmentIdentity(existingFile) == id);
    if (!alreadyExists) {
      merged.add(file);
    }
  }

  return merged;
}

String _attachmentIdentity(PlatformFile file) {
  final path = file.path?.trim() ?? '';
  return '${file.name.trim().toLowerCase()}|${file.size}|$path';
}

List<PlatformFile> _filterInvalidAttachments(
  BuildContext context,
  List<PlatformFile> attachments,
) {
  final oversized = attachments
      .where((file) => file.size > _supportMaxAttachmentBytes)
      .toList(growable: false);

  if (oversized.isEmpty) {
    return attachments;
  }

  final preview = oversized
      .take(2)
      .map((file) => file.name.trim())
      .where((name) => name.isNotEmpty)
      .join(', ');
  final overflow = oversized.length - 2;

  final details = preview.isEmpty
      ? ''
      : overflow > 0
          ? ' ($preview, +$overflow more)'
          : ' ($preview)';

  ToastHelper.showError(
    'Some files are over 5MB and were removed$details.',
    context: context,
  );

  return attachments
      .where((file) => file.size <= _supportMaxAttachmentBytes)
      .toList(growable: false);
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

Color _priorityColor(SuperadminSupportTicketPriority priority) {
  switch (priority) {
    case SuperadminSupportTicketPriority.high:
      return OpenVtsColors.warning;
    case SuperadminSupportTicketPriority.medium:
      return OpenVtsColors.brandInk;
    case SuperadminSupportTicketPriority.low:
      return OpenVtsColors.success;
  }
}

Color _statusColor(SuperadminSupportTicketStatus status) {
  switch (status) {
    case SuperadminSupportTicketStatus.open:
      return OpenVtsColors.success;
    case SuperadminSupportTicketStatus.inProgress:
      return OpenVtsColors.warning;
    case SuperadminSupportTicketStatus.closed:
      return OpenVtsColors.textTertiary;
  }
}
