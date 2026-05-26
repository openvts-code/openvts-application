import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/open_vts_colors.dart';
import '../../../../../core/theme/open_vts_radius.dart';
import '../../../../../core/theme/open_vts_spacing.dart';
import '../../../../../core/theme/open_vts_typography.dart';
import '../../../../../shared/helpers/toast_helper.dart';
import '../../../../../shared/widgets/open_vts_button.dart';
import '../../../../../shared/widgets/open_vts_card.dart';
import '../../../controllers/admin_providers.dart';
import '../../../models/admin_support_model.dart';
import '../../../services/admin_support_service.dart';

enum AdminSupportTicketFormMode { user, my }

class AdminSupportTicketForm extends ConsumerStatefulWidget {
  const AdminSupportTicketForm({
    required this.mode,
    this.showHelperCard = true,
    this.contentPadding = const EdgeInsets.all(OpenVtsSpacing.md),
    this.submitLabel = 'Submit ticket',
    this.maxContentWidth = 720,
    super.key,
  });

  final AdminSupportTicketFormMode mode;
  final bool showHelperCard;
  final EdgeInsetsGeometry contentPadding;
  final String submitLabel;
  final double maxContentWidth;

  @override
  ConsumerState<AdminSupportTicketForm> createState() =>
      _AdminSupportTicketFormState();
}

class _AdminSupportTicketFormState
    extends ConsumerState<AdminSupportTicketForm> {
  final TextEditingController _userSearchController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  String? _userId;
  AdminSupportTicketCategory _category = AdminSupportTicketCategory.other;
  AdminSupportTicketPriority _priority = AdminSupportTicketPriority.medium;
  List<PlatformFile> _attachments = <PlatformFile>[];

  bool get _isUserMode => widget.mode == AdminSupportTicketFormMode.user;

  @override
  void initState() {
    super.initState();
    _userSearchController.addListener(_handleUserSearchChanged);
    _scheduleUsersLoadIfNeeded();
  }

  @override
  void didUpdateWidget(covariant AdminSupportTicketForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mode != widget.mode) {
      _scheduleUsersLoadIfNeeded();
    }
  }

  @override
  void dispose() {
    _userSearchController.removeListener(_handleUserSearchChanged);
    _userSearchController.dispose();
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _handleUserSearchChanged() {
    if (_isUserMode) {
      setState(() {});
    }
  }

  void _scheduleUsersLoadIfNeeded() {
    if (!_isUserMode) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      final state = ref.read(adminSupportControllerProvider);
      if (state.users.isEmpty && !state.isLoadingUsers) {
        unawaited(
          ref.read(adminSupportControllerProvider.notifier).loadUsers(),
        );
      }
    });
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

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    final message = _messageController.text.trim();
    if (!_validateUser() ||
        !_validateTitle(title) ||
        !_validateMessage(message)) {
      return;
    }

    final controller = ref.read(adminSupportControllerProvider.notifier);

    try {
      final result = _isUserMode
          ? await controller.createUserTicket(
              AdminSupportCreateTicketRequest(
                fromUserId: _userId,
                title: title,
                message: message,
                category: _category,
                priority: _priority,
                attachments: _attachments,
              ),
            )
          : await controller.createMyTicket(
              AdminSupportCreateTicketRequest(
                title: title,
                message: message,
                category: _category,
                priority: _priority,
                attachments: _attachments,
              ),
            );

      if (!mounted) {
        return;
      }

      ToastHelper.showSuccess('Ticket created.', context: context);
      Navigator.of(context).pop(result.ticketId);
    } catch (_) {
      if (!mounted) {
        return;
      }
      final error = ref.read(adminSupportControllerProvider).errorMessage ??
          'Unable to create ticket.';
      ToastHelper.showError(error, context: context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminSupportControllerProvider);
    final isCreating =
        _isUserMode ? state.isCreatingUserTicket : state.isCreatingMyTicket;
    final users = state.users;
    final filteredUsers = _filterUsers(users, _userSearchController.text);
    final dropdownUsers = _buildDropdownUsers(
      allUsers: users,
      filteredUsers: filteredUsers,
      selectedId: _userId,
    );
    final selectedUserId =
        dropdownUsers.any((user) => user.id == _userId) ? _userId : null;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: widget.contentPadding,
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: widget.maxContentWidth),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (widget.showHelperCard) ...[
                      _CreateTicketHelperCard(mode: widget.mode),
                      const SizedBox(height: OpenVtsSpacing.sm),
                    ],
                    OpenVtsCard(
                      padding: const EdgeInsets.all(OpenVtsSpacing.md),
                      child: _TicketFields(
                        mode: widget.mode,
                        userSearchController: _userSearchController,
                        selectedUserId: selectedUserId,
                        users: dropdownUsers,
                        usersAreLoading: state.isLoadingUsers,
                        titleController: _titleController,
                        messageController: _messageController,
                        category: _category,
                        priority: _priority,
                        attachments: _attachments,
                        isCreating: isCreating,
                        onUserChanged: (value) {
                          setState(() => _userId = value);
                        },
                        onCategoryChanged: (value) {
                          setState(() => _category = value ?? _category);
                        },
                        onPriorityChanged: (value) {
                          setState(() => _priority = value ?? _priority);
                        },
                        onRemoveAttachment: _removeAttachment,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        _TicketFormActionBar(
          submitLabel: widget.submitLabel,
          isCreating: isCreating,
          onAttach: isCreating ? null : _pickAttachments,
          onSubmit: isCreating ? null : _submit,
        ),
      ],
    );
  }

  void _removeAttachment(PlatformFile file) {
    setState(() {
      _attachments = _attachments
          .where(
            (item) =>
                _adminSupportAttachmentIdentity(item) !=
                _adminSupportAttachmentIdentity(file),
          )
          .toList(growable: false);
    });
  }

  bool _validateUser() {
    if (!_isUserMode) {
      return true;
    }
    if ((_userId ?? '').trim().isEmpty) {
      ToastHelper.showError('User is required.', context: context);
      return false;
    }
    return true;
  }

  bool _validateTitle(String value) {
    if (value.trim().isEmpty) {
      ToastHelper.showError('Subject is required.', context: context);
      return false;
    }
    if (value.length > AdminSupportService.maxTitleLength) {
      ToastHelper.showError(
        'Subject must be ${AdminSupportService.maxTitleLength} characters or less.',
        context: context,
      );
      return false;
    }
    if (!_containsLetterOrNumber(value)) {
      ToastHelper.showError(
        'Subject must contain at least one letter or number.',
        context: context,
      );
      return false;
    }
    return true;
  }

  bool _validateMessage(String value) {
    if (value.trim().isEmpty) {
      ToastHelper.showError('Description is required.', context: context);
      return false;
    }
    if (value.length > AdminSupportService.maxMessageLength) {
      ToastHelper.showError(
        'Description must be ${AdminSupportService.maxMessageLength} characters or less.',
        context: context,
      );
      return false;
    }
    if (!_containsLetterOrNumber(value)) {
      ToastHelper.showError(
        'Description must contain at least one letter or number.',
        context: context,
      );
      return false;
    }
    return true;
  }

  List<AdminSupportUserMini> _filterUsers(
    List<AdminSupportUserMini> users,
    String query,
  ) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) {
      return users;
    }

    return users.where((user) {
      final haystack = [
        user.displayName,
        user.username,
        user.email,
        user.phone,
      ].join(' ').toLowerCase();
      return haystack.contains(normalized);
    }).toList(growable: false);
  }

  List<AdminSupportUserMini> _buildDropdownUsers({
    required List<AdminSupportUserMini> allUsers,
    required List<AdminSupportUserMini> filteredUsers,
    required String? selectedId,
  }) {
    final resolved = <AdminSupportUserMini>[...filteredUsers];
    final id = selectedId?.trim();
    if (id == null || id.isEmpty) {
      return resolved;
    }

    AdminSupportUserMini? selected;
    for (final user in allUsers) {
      if (user.id == id) {
        selected = user;
        break;
      }
    }

    final selectedUser = selected;
    if (selectedUser != null &&
        !resolved.any((user) => user.id == selectedUser.id)) {
      resolved.insert(0, selectedUser);
    }

    return resolved;
  }

  bool _containsLetterOrNumber(String value) {
    return RegExp(r'[A-Za-z0-9]').hasMatch(value);
  }
}

class _CreateTicketHelperCard extends StatelessWidget {
  const _CreateTicketHelperCard({required this.mode});

  final AdminSupportTicketFormMode mode;

  @override
  Widget build(BuildContext context) {
    final detail = mode == AdminSupportTicketFormMode.user
        ? 'Select a user, describe the issue, and attach files if needed.'
        : 'Briefly describe the issue and attach files if needed.';

    return OpenVtsCard(
      padding: const EdgeInsets.all(OpenVtsSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'New support ticket',
            style: OpenVtsTypography.titleSmall.copyWith(
              color: OpenVtsColors.textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: OpenVtsSpacing.xxs),
          Text(
            detail,
            style: OpenVtsTypography.meta.copyWith(
              color: OpenVtsColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _TicketFields extends StatelessWidget {
  const _TicketFields({
    required this.mode,
    required this.userSearchController,
    required this.selectedUserId,
    required this.users,
    required this.usersAreLoading,
    required this.titleController,
    required this.messageController,
    required this.category,
    required this.priority,
    required this.attachments,
    required this.isCreating,
    required this.onUserChanged,
    required this.onCategoryChanged,
    required this.onPriorityChanged,
    required this.onRemoveAttachment,
  });

  final AdminSupportTicketFormMode mode;
  final TextEditingController userSearchController;
  final String? selectedUserId;
  final List<AdminSupportUserMini> users;
  final bool usersAreLoading;
  final TextEditingController titleController;
  final TextEditingController messageController;
  final AdminSupportTicketCategory category;
  final AdminSupportTicketPriority priority;
  final List<PlatformFile> attachments;
  final bool isCreating;
  final ValueChanged<String?> onUserChanged;
  final ValueChanged<AdminSupportTicketCategory?> onCategoryChanged;
  final ValueChanged<AdminSupportTicketPriority?> onPriorityChanged;
  final ValueChanged<PlatformFile> onRemoveAttachment;

  @override
  Widget build(BuildContext context) {
    final showUserFields = mode == AdminSupportTicketFormMode.user;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showUserFields) ...[
          TextField(
            controller: userSearchController,
            enabled: !isCreating,
            decoration: _fieldDecoration('Search user').copyWith(
              hintText: 'Name, username, email',
              prefixIcon: const Icon(Icons.search_rounded),
            ),
          ),
          const SizedBox(height: OpenVtsSpacing.sm),
          DropdownButtonFormField<String>(
            initialValue: selectedUserId,
            isDense: true,
            isExpanded: true,
            decoration: _fieldDecoration('User'),
            items: users
                .map(
                  (user) => DropdownMenuItem<String>(
                    value: user.id,
                    child: Text(
                      '${user.displayName} (${user.username})',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(growable: false),
            onChanged: isCreating ? null : onUserChanged,
          ),
          if (users.isEmpty && !usersAreLoading) ...[
            const SizedBox(height: OpenVtsSpacing.xs),
            Text(
              userSearchController.text.trim().isEmpty
                  ? 'No users found.'
                  : 'No users match this search.',
              style: OpenVtsTypography.meta.copyWith(
                color: OpenVtsColors.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: OpenVtsSpacing.sm),
        ],
        TextField(
          controller: titleController,
          enabled: !isCreating,
          maxLength: AdminSupportService.maxTitleLength,
          decoration: _fieldDecoration('Subject'),
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: OpenVtsSpacing.sm),
        LayoutBuilder(
          builder: (context, constraints) {
            final stackFields = constraints.maxWidth < 460;
            final categoryField =
                DropdownButtonFormField<AdminSupportTicketCategory>(
              initialValue: category,
              isDense: true,
              isExpanded: true,
              decoration: _fieldDecoration('Category'),
              items: AdminSupportTicketCategory.values
                  .map(
                    (value) => DropdownMenuItem(
                      value: value,
                      child: Text(value.label),
                    ),
                  )
                  .toList(growable: false),
              onChanged: isCreating ? null : onCategoryChanged,
            );
            final priorityField =
                DropdownButtonFormField<AdminSupportTicketPriority>(
              initialValue: priority,
              isDense: true,
              isExpanded: true,
              decoration: _fieldDecoration('Priority'),
              items: AdminSupportTicketPriority.values
                  .map(
                    (value) => DropdownMenuItem(
                      value: value,
                      child: Text(value.label),
                    ),
                  )
                  .toList(growable: false),
              onChanged: isCreating ? null : onPriorityChanged,
            );

            if (stackFields) {
              return Column(
                children: [
                  categoryField,
                  const SizedBox(height: OpenVtsSpacing.sm),
                  priorityField,
                ],
              );
            }

            return Row(
              children: [
                Expanded(child: categoryField),
                const SizedBox(width: OpenVtsSpacing.sm),
                Expanded(child: priorityField),
              ],
            );
          },
        ),
        const SizedBox(height: OpenVtsSpacing.sm),
        TextField(
          controller: messageController,
          enabled: !isCreating,
          minLines: 5,
          maxLines: 9,
          maxLength: AdminSupportService.maxMessageLength,
          decoration: _fieldDecoration(
            'Description',
          ).copyWith(alignLabelWithHint: true),
        ),
        if (attachments.isNotEmpty) ...[
          const SizedBox(height: OpenVtsSpacing.sm),
          _DraftAttachmentWrap(
            attachments: attachments,
            onRemove: isCreating ? (_) {} : onRemoveAttachment,
          ),
        ],
      ],
    );
  }

  InputDecoration _fieldDecoration(String label) {
    return InputDecoration(
      labelText: label,
      counterText: '',
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: OpenVtsSpacing.sm,
        vertical: OpenVtsSpacing.sm,
      ),
    );
  }
}

class _TicketFormActionBar extends StatelessWidget {
  const _TicketFormActionBar({
    required this.submitLabel,
    required this.isCreating,
    required this.onAttach,
    required this.onSubmit,
  });

  final String submitLabel;
  final bool isCreating;
  final VoidCallback? onAttach;
  final VoidCallback? onSubmit;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          OpenVtsSpacing.md,
          OpenVtsSpacing.sm,
          OpenVtsSpacing.md,
          OpenVtsSpacing.md,
        ),
        decoration: const BoxDecoration(
          color: OpenVtsColors.surface,
          border: Border(top: BorderSide(color: OpenVtsColors.border)),
        ),
        child: Align(
          alignment: Alignment.center,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Row(
              children: [
                IconButton.filledTonal(
                  tooltip: 'Attach files',
                  onPressed: onAttach,
                  icon: const Icon(Icons.attach_file_rounded, size: 18),
                ),
                const SizedBox(width: OpenVtsSpacing.sm),
                Expanded(
                  child: OpenVtsButton(
                    label: submitLabel,
                    onPressed: onSubmit,
                    isLoading: isCreating,
                    trailingIcon: Icons.arrow_forward_rounded,
                    height: 42,
                  ),
                ),
              ],
            ),
          ),
        ),
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
