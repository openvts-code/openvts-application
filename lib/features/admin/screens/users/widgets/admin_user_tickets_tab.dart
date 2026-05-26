import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../core/providers/core_providers.dart';
import '../../../../../core/theme/open_vts_colors.dart';
import '../../../../../core/theme/open_vts_radius.dart';
import '../../../../../core/theme/open_vts_spacing.dart';
import '../../../../../core/theme/open_vts_typography.dart';
import '../../../../../core/utils/date_time_formatter.dart';
import '../../../../../shared/helpers/toast_helper.dart';
import '../../../../../shared/widgets/open_vts_bottom_sheet.dart';
import '../../../../../shared/widgets/open_vts_button.dart';
import '../../../../../shared/widgets/open_vts_card.dart';
import '../../../../../shared/widgets/open_vts_text_field.dart';
import '../../../controllers/admin_providers.dart';
import '../../../models/admin_user_details_model.dart';

const DateTimeFormatter _dateFormatter = DateTimeFormatter();
const int _maxAttachmentCount = 5;
const int _maxAttachmentBytes = 5 * 1024 * 1024;
const int _maxMessageLength = 5000;
const List<String> _ticketCategories = <String>[
  'SERVER',
  'NOTIFICATIONS',
  'MAPS',
  'BILLING',
  'INSTALLATION',
  'OTHER',
];
const List<String> _ticketPriorities = <String>['LOW', 'MEDIUM', 'HIGH'];
const List<String> _ticketStatuses = <String>['OPEN', 'IN_PROGRESS', 'CLOSED'];
const List<String> _allowedAttachmentExtensions = <String>[
  'pdf',
  'jpg',
  'jpeg',
  'png',
  'gif',
  'webp',
  'doc',
  'docx',
  'xls',
  'xlsx',
  'csv',
  'txt',
  'zip',
];
const List<String> _blockedAttachmentExtensions = <String>[
  'exe',
  'js',
  'html',
  'htm',
];

class AdminUserTicketsTab extends ConsumerStatefulWidget {
  const AdminUserTicketsTab({
    super.key,
    required this.userId,
  });

  final String userId;

  @override
  ConsumerState<AdminUserTicketsTab> createState() =>
      _AdminUserTicketsTabState();
}

class _AdminUserTicketsTabState extends ConsumerState<AdminUserTicketsTab> {
  final _searchController = TextEditingController();
  var _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = adminUserDetailsControllerProvider(widget.userId);
    final state = ref.watch(provider);
    final controller = ref.read(provider.notifier);
    final tickets = state.tickets.where(_matchesQuery).toList();
    final isInitialLoading = state.isLoadingTickets && state.tickets.isEmpty;

    if (isInitialLoading) {
      return const _SectionLoader(title: 'Tickets');
    }

    if (state.sectionErrorMessage != null && state.tickets.isEmpty) {
      return _SectionErrorCard(
        message: state.sectionErrorMessage!,
        onRetry: controller.loadTickets,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SummaryCard(
          ticketCount: state.tickets.length,
          isLoading: state.isLoadingTickets,
          isCreating: state.isCreatingTicket,
          onCreate: state.isCreatingTicket ? null : _showCreateTicketSheet,
        ),
        const SizedBox(height: OpenVtsSpacing.sm),
        if (state.sectionErrorMessage != null) ...[
          _InlineError(message: state.sectionErrorMessage!),
          const SizedBox(height: OpenVtsSpacing.sm),
        ],
        _SearchField(
          controller: _searchController,
          hintText: 'Search tickets',
          onChanged: (value) => setState(() => _query = value),
        ),
        const SizedBox(height: OpenVtsSpacing.sm),
        if (tickets.isEmpty)
          _EmptyCard(
            label: _query.trim().isEmpty
                ? 'No tickets found'
                : 'No tickets match your search',
          )
        else
          for (final ticket in tickets) ...[
            _TicketCard(
              ticket: ticket,
              isLoadingDetails: state.isLoadingTicketDetails &&
                  state.selectedTicket?.id == ticket.id,
              onTap: () => _showTicketConversation(ticket.id),
            ),
            if (ticket != tickets.last)
              const SizedBox(height: OpenVtsSpacing.sm),
          ],
      ],
    );
  }

  bool _matchesQuery(AdminUserTicket ticket) {
    final normalized = _query.trim().toLowerCase();
    if (normalized.isEmpty) {
      return true;
    }
    return [
      ticket.title,
      ticket.ticketNo,
      ticket.status,
      ticket.priority,
      ticket.category,
    ].any((value) => value.toLowerCase().contains(normalized));
  }

  Future<void> _showCreateTicketSheet() async {
    final ticketId = await OpenVtsBottomSheet.show<String>(
      context: context,
      title: 'New Ticket',
      initialChildSize: 0.86,
      minChildSize: 0.5,
      maxChildSize: 0.96,
      child: _CreateTicketSheet(userId: widget.userId),
    );
    if (!mounted || ticketId == null || ticketId.trim().isEmpty) {
      return;
    }
    await _showTicketConversation(ticketId);
  }

  Future<void> _showTicketConversation(String ticketId) {
    return OpenVtsBottomSheet.show<void>(
      context: context,
      title: 'Ticket Conversation',
      initialChildSize: 0.9,
      minChildSize: 0.52,
      maxChildSize: 0.96,
      child: _TicketConversationSheet(
        userId: widget.userId,
        ticketId: ticketId,
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.ticketCount,
    required this.isLoading,
    required this.isCreating,
    required this.onCreate,
  });

  final int ticketCount;
  final bool isLoading;
  final bool isCreating;
  final VoidCallback? onCreate;

  @override
  Widget build(BuildContext context) {
    return OpenVtsCard(
      padding: const EdgeInsets.all(OpenVtsSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.confirmation_number_outlined,
                      size: 17,
                      color: OpenVtsColors.textSecondary,
                    ),
                    const SizedBox(width: OpenVtsSpacing.xs),
                    Text(
                      'Tickets',
                      style: OpenVtsTypography.label.copyWith(
                        color: OpenVtsColors.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (isLoading) ...[
                      const SizedBox(width: OpenVtsSpacing.xs),
                      const SizedBox(
                        width: 13,
                        height: 13,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: OpenVtsSpacing.xs),
                Text(
                  ticketCount == 1 ? '1 ticket' : '$ticketCount tickets',
                  style: OpenVtsTypography.meta.copyWith(
                    color: OpenVtsColors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 34,
            child: OpenVtsButton(
              label: 'Create',
              height: 34,
              isLoading: isCreating,
              onPressed: onCreate,
              trailingIcon: Icons.add_rounded,
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.hintText,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      style: OpenVtsTypography.body.copyWith(fontSize: 13),
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: const Icon(
          Icons.search_rounded,
          size: 18,
          color: OpenVtsColors.textSecondary,
        ),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                tooltip: 'Clear search',
                onPressed: () {
                  controller.clear();
                  onChanged('');
                },
                icon: const Icon(Icons.close_rounded, size: 17),
              ),
      ),
    );
  }
}

class _TicketCard extends StatelessWidget {
  const _TicketCard({
    required this.ticket,
    required this.isLoadingDetails,
    required this.onTap,
  });

  final AdminUserTicket ticket;
  final bool isLoadingDetails;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OpenVtsCard(
      onTap: onTap,
      padding: const EdgeInsets.all(OpenVtsSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _ticketTitle(ticket),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: OpenVtsTypography.label.copyWith(
                        color: OpenVtsColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _displayValue(ticket.ticketNo),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: OpenVtsTypography.meta.copyWith(
                        color: OpenVtsColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: OpenVtsSpacing.xs),
              if (isLoadingDetails)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                _StatusPill(status: ticket.status),
            ],
          ),
          const SizedBox(height: OpenVtsSpacing.sm),
          Wrap(
            spacing: OpenVtsSpacing.xs,
            runSpacing: OpenVtsSpacing.xs,
            children: [
              _MetaPill(
                icon: Icons.flag_outlined,
                label: _statusLabel(ticket.priority),
              ),
              _MetaPill(
                icon: Icons.category_outlined,
                label: _statusLabel(ticket.category),
              ),
              _MetaPill(
                icon: Icons.mark_chat_read_outlined,
                label: 'Last ${_dateTimeText(ticket.lastMessageAt)}',
              ),
              _MetaPill(
                icon: Icons.calendar_today_outlined,
                label: 'Created ${_dateTimeText(ticket.createdAt)}',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CreateTicketSheet extends ConsumerStatefulWidget {
  const _CreateTicketSheet({required this.userId});

  final String userId;

  @override
  ConsumerState<_CreateTicketSheet> createState() => _CreateTicketSheetState();
}

class _CreateTicketSheetState extends ConsumerState<_CreateTicketSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  var _category = 'OTHER';
  var _priority = 'MEDIUM';
  var _attachments = <PlatformFile>[];
  var _isPicking = false;

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = adminUserDetailsControllerProvider(widget.userId);
    final state = ref.watch(provider);

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            controller: PrimaryScrollController.maybeOf(context),
            padding: const EdgeInsets.all(OpenVtsSpacing.md),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  OpenVtsTextField(
                    label: 'Title',
                    controller: _titleController,
                    hintText: 'Short issue title',
                    prefixIcon: Icons.title_rounded,
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      final normalized = value?.trim() ?? '';
                      if (normalized.isEmpty) {
                        return 'Title is required.';
                      }
                      if (normalized.length > 160) {
                        return 'Title is too long.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: OpenVtsSpacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: _OptionDropdown(
                          label: 'Category',
                          value: _category,
                          values: _ticketCategories,
                          icon: Icons.category_outlined,
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _category = value);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: OpenVtsSpacing.sm),
                      Expanded(
                        child: _OptionDropdown(
                          label: 'Priority',
                          value: _priority,
                          values: _ticketPriorities,
                          icon: Icons.flag_outlined,
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _priority = value);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: OpenVtsSpacing.sm),
                  OpenVtsTextField(
                    label: 'Message',
                    controller: _messageController,
                    hintText: 'Describe the request or issue',
                    prefixIcon: Icons.notes_rounded,
                    maxLines: 5,
                    validator: (value) {
                      final normalized = value?.trim() ?? '';
                      if (normalized.isEmpty) {
                        return 'Message is required.';
                      }
                      if (normalized.length > _maxMessageLength) {
                        return 'Message is too long.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: OpenVtsSpacing.sm),
                  _AttachmentPicker(
                    attachments: _attachments,
                    isPicking: _isPicking,
                    onPick: _pickAttachments,
                    onRemove: (file) {
                      setState(() {
                        _attachments = _attachments
                            .where((item) =>
                                _attachmentIdentity(item) !=
                                _attachmentIdentity(file))
                            .toList(growable: false);
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
        const Divider(height: 1),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(OpenVtsSpacing.md),
            child: Row(
              children: [
                Expanded(
                  child: OpenVtsButton(
                    label: 'Cancel',
                    height: 40,
                    variant: OpenVtsButtonVariant.secondary,
                    onPressed: state.isCreatingTicket
                        ? null
                        : () => Navigator.of(context).pop(),
                  ),
                ),
                const SizedBox(width: OpenVtsSpacing.sm),
                Expanded(
                  child: OpenVtsButton(
                    label: 'Create',
                    height: 40,
                    isLoading: state.isCreatingTicket,
                    trailingIcon: Icons.check_rounded,
                    onPressed: state.isCreatingTicket ? null : _submit,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickAttachments() async {
    if (_isPicking) {
      return;
    }
    if (_attachments.length >= _maxAttachmentCount) {
      ToastHelper.showError(
        'You can upload up to $_maxAttachmentCount files.',
        context: context,
      );
      return;
    }

    setState(() => _isPicking = true);
    try {
      final files = await _pickTicketAttachments(existing: _attachments);
      if (!mounted || files == null) {
        return;
      }
      setState(() => _attachments = files);
    } finally {
      if (mounted) {
        setState(() => _isPicking = false);
      }
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final provider = adminUserDetailsControllerProvider(widget.userId);
    final ok = await ref.read(provider.notifier).createTicket(
          title: _titleController.text.trim(),
          message: _messageController.text.trim(),
          category: _category,
          priority: _priority,
          attachments: _attachments,
        );
    if (!mounted) {
      return;
    }

    if (ok) {
      ToastHelper.showSuccess('Ticket created.', context: context);
      Navigator.of(context).pop(ref.read(provider).selectedTicket?.id);
    } else {
      ToastHelper.showError(
        ref.read(provider).sectionErrorMessage ?? 'Unable to create ticket.',
        context: context,
      );
    }
  }
}

class _TicketConversationSheet extends ConsumerStatefulWidget {
  const _TicketConversationSheet({
    required this.userId,
    required this.ticketId,
  });

  final String userId;
  final String ticketId;

  @override
  ConsumerState<_TicketConversationSheet> createState() =>
      _TicketConversationSheetState();
}

class _TicketConversationSheetState
    extends ConsumerState<_TicketConversationSheet> {
  final _replyController = TextEditingController();
  var _replyAttachments = <PlatformFile>[];
  var _isPicking = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final provider = adminUserDetailsControllerProvider(widget.userId);
      final state = ref.read(provider);
      if (state.selectedTicket?.id != widget.ticketId &&
          !state.isLoadingTicketDetails) {
        ref.read(provider.notifier).openTicket(widget.ticketId);
      }
    });
  }

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = adminUserDetailsControllerProvider(widget.userId);
    final state = ref.watch(provider);
    final controller = ref.read(provider.notifier);
    final baseUrl = ref.watch(apiBaseUrlProvider);
    final ticket = state.selectedTicket?.id == widget.ticketId
        ? state.selectedTicket
        : _ticketFromList(state.tickets, widget.ticketId);

    if (state.isLoadingTicketDetails && ticket == null) {
      return const Padding(
        padding: EdgeInsets.all(OpenVtsSpacing.md),
        child: _SectionLoader(title: 'Ticket details'),
      );
    }

    if (state.sectionErrorMessage != null && ticket == null) {
      return Padding(
        padding: const EdgeInsets.all(OpenVtsSpacing.md),
        child: _SectionErrorCard(
          message: state.sectionErrorMessage!,
          onRetry: () => controller.openTicket(widget.ticketId),
        ),
      );
    }

    if (ticket == null) {
      return const Padding(
        padding: EdgeInsets.all(OpenVtsSpacing.md),
        child: _EmptyCard(label: 'Ticket details are not available'),
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView(
            primary: false,
            padding: const EdgeInsets.all(OpenVtsSpacing.md),
            children: [
              _TicketDetailsHeader(
                ticket: ticket,
                isUpdatingStatus: state.isUpdatingTicketStatus,
                onStatusSelected: (status) => _updateStatus(ticket, status),
              ),
              if (state.sectionErrorMessage != null) ...[
                const SizedBox(height: OpenVtsSpacing.sm),
                _InlineError(message: state.sectionErrorMessage!),
              ],
              const SizedBox(height: OpenVtsSpacing.sm),
              if (state.isLoadingTicketDetails && ticket.messages.isEmpty)
                const _SectionLoader(title: 'Messages')
              else if (ticket.messages.isEmpty)
                const _EmptyCard(label: 'No messages yet')
              else
                for (final message in ticket.messages) ...[
                  _MessageBubble(
                    message: message,
                    ticket: ticket,
                    baseUrl: baseUrl,
                    onOpenAttachment: (url) => _openUrl(url),
                  ),
                  if (message != ticket.messages.last)
                    const SizedBox(height: OpenVtsSpacing.sm),
                ],
            ],
          ),
        ),
        const Divider(height: 1),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(OpenVtsSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _replyController,
                  minLines: 2,
                  maxLines: 4,
                  maxLength: _maxMessageLength,
                  style: OpenVtsTypography.body.copyWith(fontSize: 13),
                  decoration: const InputDecoration(
                    hintText: 'Write a reply',
                    prefixIcon: Icon(Icons.reply_rounded),
                  ),
                ),
                if (_replyAttachments.isNotEmpty) ...[
                  const SizedBox(height: OpenVtsSpacing.xs),
                  _DraftAttachmentWrap(
                    attachments: _replyAttachments,
                    onRemove: (file) {
                      setState(() {
                        _replyAttachments = _replyAttachments
                            .where((item) =>
                                _attachmentIdentity(item) !=
                                _attachmentIdentity(file))
                            .toList(growable: false);
                      });
                    },
                  ),
                ],
                const SizedBox(height: OpenVtsSpacing.sm),
                Row(
                  children: [
                    SizedBox(
                      width: 108,
                      child: OpenVtsButton(
                        label: 'Attach',
                        height: 38,
                        variant: OpenVtsButtonVariant.secondary,
                        isLoading: _isPicking,
                        onPressed: state.isReplyingTicket
                            ? null
                            : _pickReplyAttachments,
                      ),
                    ),
                    const SizedBox(width: OpenVtsSpacing.sm),
                    Expanded(
                      child: OpenVtsButton(
                        label: 'Send',
                        height: 38,
                        isLoading: state.isReplyingTicket,
                        trailingIcon: Icons.send_rounded,
                        onPressed: state.isReplyingTicket
                            ? null
                            : () => _sendReply(ticket),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickReplyAttachments() async {
    if (_isPicking) {
      return;
    }
    if (_replyAttachments.length >= _maxAttachmentCount) {
      ToastHelper.showError(
        'You can upload up to $_maxAttachmentCount files.',
        context: context,
      );
      return;
    }

    setState(() => _isPicking = true);
    try {
      final files = await _pickTicketAttachments(existing: _replyAttachments);
      if (!mounted || files == null) {
        return;
      }
      setState(() => _replyAttachments = files);
    } finally {
      if (mounted) {
        setState(() => _isPicking = false);
      }
    }
  }

  Future<void> _sendReply(AdminUserTicket ticket) async {
    final message = _replyController.text.trim();
    if (message.isEmpty) {
      ToastHelper.showError('Reply message is required.', context: context);
      return;
    }
    if (message.length > _maxMessageLength) {
      ToastHelper.showError('Reply is too long.', context: context);
      return;
    }

    final provider = adminUserDetailsControllerProvider(widget.userId);
    final ok = await ref.read(provider.notifier).replyTicket(
          ticketId: ticket.id,
          message: message,
          attachments: _replyAttachments,
        );
    if (!mounted) {
      return;
    }

    if (ok) {
      _replyController.clear();
      setState(() => _replyAttachments = <PlatformFile>[]);
      ToastHelper.showSuccess('Reply sent.', context: context);
    } else {
      ToastHelper.showError(
        ref.read(provider).sectionErrorMessage ?? 'Unable to send reply.',
        context: context,
      );
    }
  }

  Future<void> _updateStatus(AdminUserTicket ticket, String status) async {
    final current = _normalizeValue(ticket.status);
    if (current == status) {
      ToastHelper.showInfo('Ticket is already ${_statusLabel(status)}.',
          context: context);
      return;
    }

    final provider = adminUserDetailsControllerProvider(widget.userId);
    final ok = await ref.read(provider.notifier).updateTicketStatus(
          ticket.id,
          status,
        );
    if (!mounted) {
      return;
    }

    if (ok) {
      ToastHelper.showSuccess('Ticket status updated.', context: context);
    } else {
      ToastHelper.showError(
        ref.read(provider).sectionErrorMessage ?? 'Unable to update status.',
        context: context,
      );
    }
  }

  Future<void> _openUrl(String url) async {
    try {
      final launched = await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
      if (!mounted) {
        return;
      }
      if (!launched) {
        ToastHelper.showError('Could not open attachment.', context: context);
      }
    } catch (_) {
      if (!mounted) {
        return;
      }
      ToastHelper.showError('Could not open attachment.', context: context);
    }
  }
}

class _TicketDetailsHeader extends StatelessWidget {
  const _TicketDetailsHeader({
    required this.ticket,
    required this.isUpdatingStatus,
    required this.onStatusSelected,
  });

  final AdminUserTicket ticket;
  final bool isUpdatingStatus;
  final ValueChanged<String> onStatusSelected;

  @override
  Widget build(BuildContext context) {
    return OpenVtsCard(
      padding: const EdgeInsets.all(OpenVtsSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _ticketTitle(ticket),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: OpenVtsTypography.label.copyWith(
                        color: OpenVtsColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _displayValue(ticket.ticketNo),
                      style: OpenVtsTypography.meta.copyWith(
                        color: OpenVtsColors.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: OpenVtsSpacing.xs),
              _StatusAction(
                status: ticket.status,
                isLoading: isUpdatingStatus,
                onSelected: onStatusSelected,
              ),
            ],
          ),
          const SizedBox(height: OpenVtsSpacing.sm),
          Wrap(
            spacing: OpenVtsSpacing.xs,
            runSpacing: OpenVtsSpacing.xs,
            children: [
              _MetaPill(
                icon: Icons.category_outlined,
                label: _statusLabel(ticket.category),
              ),
              _MetaPill(
                icon: Icons.flag_outlined,
                label: _statusLabel(ticket.priority),
              ),
              _MetaPill(
                icon: Icons.mark_chat_read_outlined,
                label: 'Last ${_dateTimeText(ticket.lastMessageAt)}',
              ),
              _MetaPill(
                icon: Icons.calendar_today_outlined,
                label: 'Created ${_dateTimeText(ticket.createdAt)}',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusAction extends StatelessWidget {
  const _StatusAction({
    required this.status,
    required this.isLoading,
    required this.onSelected,
  });

  final String status;
  final bool isLoading;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'Change status',
      enabled: !isLoading,
      onSelected: onSelected,
      itemBuilder: (context) => _ticketStatuses
          .map(
            (status) => PopupMenuItem<String>(
              value: status,
              height: 38,
              child: Text(
                _statusLabel(status),
                style: OpenVtsTypography.meta.copyWith(
                  color: OpenVtsColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          )
          .toList(growable: false),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: OpenVtsColors.surface,
          borderRadius: BorderRadius.circular(OpenVtsRadius.pill),
          border: Border.all(color: OpenVtsColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLoading)
              const SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              const Icon(Icons.swap_horiz_rounded, size: 13),
            const SizedBox(width: 4),
            Text(
              _statusLabel(status),
              style: OpenVtsTypography.meta.copyWith(
                color: OpenVtsColors.textPrimary,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
            const Icon(Icons.expand_more_rounded, size: 14),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.ticket,
    required this.baseUrl,
    required this.onOpenAttachment,
  });

  final AdminUserTicketMessage message;
  final AdminUserTicket ticket;
  final String baseUrl;
  final ValueChanged<String> onOpenAttachment;

  @override
  Widget build(BuildContext context) {
    final isUserMessage = _isFromUser(ticket, message);
    final color = isUserMessage ? OpenVtsColors.surface : OpenVtsColors.white;
    final sender = _senderLabel(message, isUserMessage: isUserMessage);
    return Container(
      padding: const EdgeInsets.all(OpenVtsSpacing.sm),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(OpenVtsRadius.sm),
        border: Border.all(color: OpenVtsColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  sender,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: OpenVtsTypography.meta.copyWith(
                    color: OpenVtsColors.textSecondary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                _dateTimeText(message.createdAt),
                style: OpenVtsTypography.meta.copyWith(
                  color: OpenVtsColors.textTertiary,
                  fontSize: 10,
                ),
              ),
            ],
          ),
          const SizedBox(height: OpenVtsSpacing.xs),
          Text(
            _displayValue(message.message),
            style: OpenVtsTypography.body.copyWith(
              color: OpenVtsColors.textPrimary,
              fontSize: 13,
            ),
          ),
          if (message.attachments.isNotEmpty) ...[
            const SizedBox(height: OpenVtsSpacing.xs),
            Wrap(
              spacing: OpenVtsSpacing.xs,
              runSpacing: OpenVtsSpacing.xs,
              children: [
                for (final attachment in message.attachments)
                  _RemoteAttachmentChip(
                    name: _attachmentName(attachment),
                    onTap: () {
                      final url = _attachmentUrl(attachment, baseUrl);
                      if (url == null) {
                        ToastHelper.showError(
                          'Attachment URL is not available.',
                          context: context,
                        );
                        return;
                      }
                      onOpenAttachment(url);
                    },
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _OptionDropdown extends StatelessWidget {
  const _OptionDropdown({
    required this.label,
    required this.value,
    required this.values,
    required this.icon,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<String> values;
  final IconData icon;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: OpenVtsTypography.label),
        const SizedBox(height: OpenVtsSpacing.xs),
        DropdownButtonFormField<String>(
          initialValue: value,
          isExpanded: true,
          decoration: InputDecoration(prefixIcon: Icon(icon)),
          items: values
              .map(
                (value) => DropdownMenuItem<String>(
                  value: value,
                  child: Text(
                    _statusLabel(value),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(growable: false),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _AttachmentPicker extends StatelessWidget {
  const _AttachmentPicker({
    required this.attachments,
    required this.isPicking,
    required this.onPick,
    required this.onRemove,
  });

  final List<PlatformFile> attachments;
  final bool isPicking;
  final VoidCallback onPick;
  final ValueChanged<PlatformFile> onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(OpenVtsSpacing.sm),
      decoration: BoxDecoration(
        color: OpenVtsColors.surface,
        borderRadius: BorderRadius.circular(OpenVtsRadius.sm),
        border: Border.all(color: OpenVtsColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.attach_file_rounded,
                size: 18,
                color: OpenVtsColors.textSecondary,
              ),
              const SizedBox(width: OpenVtsSpacing.xs),
              Expanded(
                child: Text(
                  'Attachments',
                  style: OpenVtsTypography.label.copyWith(
                    color: OpenVtsColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              TextButton(
                onPressed: isPicking ? null : onPick,
                style: TextButton.styleFrom(
                  minimumSize: const Size(0, 30),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: isPicking
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        'Add',
                        style: OpenVtsTypography.meta.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
              ),
            ],
          ),
          if (attachments.isEmpty)
            Text(
              'Optional files, up to $_maxAttachmentCount.',
              style: OpenVtsTypography.meta.copyWith(
                color: OpenVtsColors.textSecondary,
              ),
            )
          else ...[
            const SizedBox(height: OpenVtsSpacing.xs),
            _DraftAttachmentWrap(
              attachments: attachments,
              onRemove: onRemove,
            ),
          ],
        ],
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
      children: [
        for (final file in attachments)
          InputChip(
            label: Text(
              file.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: OpenVtsTypography.meta.copyWith(fontSize: 11),
            ),
            onDeleted: () => onRemove(file),
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
      ],
    );
  }
}

class _RemoteAttachmentChip extends StatelessWidget {
  const _RemoteAttachmentChip({required this.name, required this.onTap});

  final String name;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      avatar: const Icon(Icons.attach_file_rounded, size: 14),
      label: Text(
        name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: OpenVtsTypography.meta.copyWith(fontSize: 11),
      ),
      onPressed: onTap,
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final normalized = _normalizeValue(status);
    final color = switch (normalized) {
      'CLOSED' => OpenVtsColors.textTertiary,
      'IN_PROGRESS' => OpenVtsColors.brandInk,
      _ => OpenVtsColors.textSecondary,
    };
    return _MetaPill(
      icon: normalized == 'CLOSED'
          ? Icons.lock_outline_rounded
          : Icons.confirmation_number_outlined,
      label: _statusLabel(status),
      color: color,
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({
    required this.icon,
    required this.label,
    this.color = OpenVtsColors.textSecondary,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(OpenVtsRadius.pill),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: OpenVtsTypography.meta.copyWith(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(OpenVtsSpacing.sm),
      decoration: BoxDecoration(
        color: OpenVtsColors.error.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(OpenVtsRadius.sm),
        border: Border.all(color: OpenVtsColors.error.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 16,
            color: OpenVtsColors.error,
          ),
          const SizedBox(width: OpenVtsSpacing.xs),
          Expanded(
            child: Text(
              message,
              style: OpenVtsTypography.meta.copyWith(
                color: OpenVtsColors.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLoader extends StatelessWidget {
  const _SectionLoader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return OpenVtsCard(
      padding: const EdgeInsets.all(OpenVtsSpacing.md),
      child: Row(
        children: [
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: OpenVtsSpacing.sm),
          Text(
            'Loading $title',
            style: OpenVtsTypography.label.copyWith(
              color: OpenVtsColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionErrorCard extends StatelessWidget {
  const _SectionErrorCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return OpenVtsCard(
      padding: const EdgeInsets.all(OpenVtsSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 17,
                color: OpenVtsColors.error,
              ),
              const SizedBox(width: OpenVtsSpacing.xs),
              Expanded(
                child: Text(
                  'Unable to load tickets',
                  style: OpenVtsTypography.label.copyWith(
                    color: OpenVtsColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: OpenVtsSpacing.xs),
          Text(
            message,
            style: OpenVtsTypography.meta.copyWith(
              color: OpenVtsColors.textSecondary,
            ),
          ),
          const SizedBox(height: OpenVtsSpacing.sm),
          OpenVtsButton(
            label: 'Retry',
            height: 34,
            variant: OpenVtsButtonVariant.secondary,
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(OpenVtsSpacing.md),
      decoration: BoxDecoration(
        color: OpenVtsColors.surface,
        borderRadius: BorderRadius.circular(OpenVtsRadius.sm),
        border: Border.all(color: OpenVtsColors.border),
      ),
      child: Text(
        label,
        style: OpenVtsTypography.meta.copyWith(
          color: OpenVtsColors.textSecondary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

Future<List<PlatformFile>?> _pickTicketAttachments({
  required List<PlatformFile> existing,
}) async {
  final result = await FilePicker.platform.pickFiles(
    allowMultiple: true,
    type: FileType.custom,
    allowedExtensions: _allowedAttachmentExtensions,
    withData: true,
  );
  if (result == null || result.files.isEmpty) {
    return null;
  }

  final merged = <PlatformFile>[...existing];
  for (final file in result.files) {
    if (merged.length >= _maxAttachmentCount) {
      break;
    }
    final extension = _extensionFromName(file.name).toLowerCase();
    if (_blockedAttachmentExtensions.contains(extension)) {
      continue;
    }
    if (!_allowedAttachmentExtensions.contains(extension)) {
      continue;
    }
    if (file.size > _maxAttachmentBytes) {
      continue;
    }
    final id = _attachmentIdentity(file);
    if (!merged.any((item) => _attachmentIdentity(item) == id)) {
      merged.add(file);
    }
  }
  return merged;
}

String _attachmentIdentity(PlatformFile file) {
  return '${file.name}:${file.size}:${file.path ?? ''}';
}

AdminUserTicket? _ticketFromList(
    List<AdminUserTicket> tickets, String ticketId) {
  for (final ticket in tickets) {
    if (ticket.id == ticketId) {
      return ticket;
    }
  }
  return null;
}

bool _isFromUser(AdminUserTicket ticket, AdminUserTicketMessage message) {
  final senderId = message.senderId.trim();
  final fromUserId = ticket.fromUser?.id.trim() ?? '';
  return senderId.isNotEmpty && fromUserId.isNotEmpty && senderId == fromUserId;
}

String _senderLabel(
  AdminUserTicketMessage message, {
  required bool isUserMessage,
}) {
  final sender = message.sender;
  if (sender != null) {
    for (final value in [sender.name, sender.username, sender.email]) {
      final normalized = value.trim();
      if (normalized.isNotEmpty && normalized != '-') {
        return normalized;
      }
    }
  }
  if (isUserMessage) {
    return 'User';
  }
  return 'Support';
}

String _ticketTitle(AdminUserTicket ticket) {
  final normalized = ticket.title.trim();
  if (normalized.isNotEmpty && normalized != '-') {
    return normalized;
  }
  return 'Support ticket';
}

String _dateTimeText(DateTime? value) {
  if (value == null) {
    return '-';
  }
  return _dateFormatter.formatDateTime(value.toLocal());
}

String _statusLabel(String value) {
  final normalized = _normalizeValue(value);
  if (normalized.isEmpty) {
    return '-';
  }
  return normalized
      .split('_')
      .map((part) => part.isEmpty
          ? part
          : '${part.substring(0, 1)}${part.substring(1).toLowerCase()}')
      .join(' ');
}

String _normalizeValue(String value) {
  return value.trim().replaceAll('-', '_').replaceAll(' ', '_').toUpperCase();
}

String _displayValue(String value) {
  final normalized = value.trim();
  if (normalized.isEmpty || normalized == '-') {
    return '-';
  }
  return normalized;
}

String _extensionFromName(String value) {
  final normalized = value.trim();
  final dot = normalized.lastIndexOf('.');
  if (dot < 0 || dot >= normalized.length - 1) {
    return '';
  }
  return normalized.substring(dot + 1);
}

String _attachmentName(Map<String, dynamic> attachment) {
  for (final key in const [
    'fileName',
    'file_name',
    'originalName',
    'original_name',
    'name',
    'title',
  ]) {
    final value = attachment[key]?.toString().trim();
    if (value != null && value.isNotEmpty) {
      return value;
    }
  }
  return 'Attachment';
}

String? _attachmentUrl(Map<String, dynamic> attachment, String baseUrl) {
  for (final key in const [
    'filePath',
    'file_path',
    'fileUrl',
    'file_url',
    'url',
    'path',
  ]) {
    final value = attachment[key]?.toString().trim();
    if (value == null || value.isEmpty) {
      continue;
    }
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return value;
    }
    final base = baseUrl.trim().replaceAll(RegExp(r'/+$'), '');
    final relative = value.startsWith('/') ? value : '/$value';
    return '$base$relative';
  }
  return null;
}
