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
import '../../../../../shared/widgets/open_vts_loader.dart';
import '../../../controllers/superadmin_providers.dart';
import '../../../models/superadmin_support_model.dart';

const int _maxAttachmentCount = 5;
const int _maxAttachmentBytes = 5 * 1024 * 1024;
const int _maxTitleLength = 120;
const int _maxMessageLength = 5000;

const Set<String> _allowedExtensions = <String>{
  'pdf',
  'jpg',
  'jpeg',
  'png',
  'gif',
  'doc',
  'docx',
  'txt',
  'zip',
};

const Set<String> _blockedExtensions = <String>{
  'svg',
  'html',
  'htm',
  'js',
  'exe',
};

class SuperadminSupportTicketForm extends ConsumerStatefulWidget {
  const SuperadminSupportTicketForm({
    this.showHelperCard = true,
    this.contentPadding = const EdgeInsets.all(OpenVtsSpacing.md),
    this.submitLabel = 'Submit ticket',
    this.maxContentWidth = 720,
    super.key,
  });

  final bool showHelperCard;
  final EdgeInsetsGeometry contentPadding;
  final String submitLabel;
  final double maxContentWidth;

  @override
  ConsumerState<SuperadminSupportTicketForm> createState() =>
      _SuperadminSupportTicketFormState();
}

class _SuperadminSupportTicketFormState
    extends ConsumerState<SuperadminSupportTicketForm> {
  final TextEditingController _adminSearchController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  int? _adminId;
  SuperadminSupportTicketCategory _category =
      SuperadminSupportTicketCategory.other;
  SuperadminSupportTicketPriority _priority =
      SuperadminSupportTicketPriority.medium;
  List<PlatformFile> _attachments = <PlatformFile>[];

  @override
  void initState() {
    super.initState();
    _adminSearchController.addListener(_handleAdminSearchChanged);
    _scheduleAdminsLoadIfNeeded();
  }

  @override
  void dispose() {
    _adminSearchController.removeListener(_handleAdminSearchChanged);
    _adminSearchController.dispose();
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _handleAdminSearchChanged() {
    setState(() {});
  }

  void _scheduleAdminsLoadIfNeeded() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      final state = ref.read(superadminSupportControllerProvider);
      if (state.adminsForCreateTicket.isEmpty && !state.isLoadingAdmins) {
        unawaited(
          ref
              .read(superadminSupportControllerProvider.notifier)
              .loadAdminsForCreateTicket(),
        );
      }
    });
  }

  Future<void> _pickAttachments() async {
    final picked = await _pickSuperadminSupportAttachments(
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
    if (!_validateAdmin() ||
        !_validateTitle(title) ||
        !_validateMessage(message)) {
      return;
    }

    try {
      final result = await ref
          .read(superadminSupportControllerProvider.notifier)
          .createTicket(
            adminId: _adminId!,
            title: title,
            message: message,
            category: _category,
            priority: _priority,
            attachments: _attachments,
          );

      if (!mounted) {
        return;
      }

      ToastHelper.showSuccess('Ticket created.', context: context);
      Navigator.of(context).pop(result.ticketId > 0 ? result.ticketId : null);
    } catch (_) {
      if (!mounted) {
        return;
      }

      final error = ref.read(
            superadminSupportControllerProvider
                .select((value) => value.errorMessage),
          ) ??
          'Unable to create support ticket.';
      ToastHelper.showError(error, context: context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(superadminSupportControllerProvider);
    final admins = state.adminsForCreateTicket;

    if (_adminId == null && admins.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _adminId != null) {
          return;
        }
        setState(() => _adminId = admins.first.uid);
      });
    }

    final filteredAdmins = _filterAdmins(admins, _adminSearchController.text);
    final dropdownAdmins = _buildDropdownAdmins(
      allAdmins: admins,
      filteredAdmins: filteredAdmins,
      selectedId: _adminId,
    );
    final selectedAdmin =
        dropdownAdmins.any((admin) => admin.uid == _adminId) ? _adminId : null;

    return Column(
      children: [
        Expanded(
          child: state.isLoadingAdmins && admins.isEmpty
              ? const Center(child: OpenVtsLoader())
              : SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: widget.contentPadding,
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: widget.maxContentWidth,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (widget.showHelperCard) ...[
                            const _CreateTicketHelperCard(),
                            const SizedBox(height: OpenVtsSpacing.sm),
                          ],
                          OpenVtsCard(
                            padding: const EdgeInsets.all(OpenVtsSpacing.md),
                            child: _TicketFields(
                              adminSearchController: _adminSearchController,
                              selectedAdminId: selectedAdmin,
                              admins: dropdownAdmins,
                              adminsAreLoading: state.isLoadingAdmins,
                              titleController: _titleController,
                              messageController: _messageController,
                              category: _category,
                              priority: _priority,
                              attachments: _attachments,
                              isCreating: state.isCreating,
                              onAdminChanged: (value) {
                                setState(() => _adminId = value);
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
          isCreating: state.isCreating,
          onAttach: state.isCreating ? null : _pickAttachments,
          onSubmit: state.isCreating ? null : _submit,
        ),
      ],
    );
  }

  void _removeAttachment(PlatformFile file) {
    setState(() {
      _attachments = _attachments
          .where(
            (item) =>
                _superadminSupportAttachmentIdentity(item) !=
                _superadminSupportAttachmentIdentity(file),
          )
          .toList(growable: false);
    });
  }

  bool _validateAdmin() {
    if (_adminId == null || _adminId! <= 0) {
      ToastHelper.showError(
        'Please select an administrator.',
        context: context,
      );
      return false;
    }
    return true;
  }

  bool _validateTitle(String value) {
    if (value.trim().isEmpty) {
      ToastHelper.showError('Subject is required.', context: context);
      return false;
    }
    if (value.length > _maxTitleLength) {
      ToastHelper.showError(
        'Subject must be $_maxTitleLength characters or less.',
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
    if (value.length > _maxMessageLength) {
      ToastHelper.showError(
        'Description must be $_maxMessageLength characters or less.',
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

  List<SuperadminSupportAdminMini> _filterAdmins(
    List<SuperadminSupportAdminMini> admins,
    String query,
  ) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) {
      return admins;
    }

    return admins.where((admin) {
      final haystack = [
        admin.displayName,
        admin.email,
        admin.phone,
        admin.uid.toString(),
      ].join(' ').toLowerCase();

      return haystack.contains(normalized);
    }).toList(growable: false);
  }

  List<SuperadminSupportAdminMini> _buildDropdownAdmins({
    required List<SuperadminSupportAdminMini> allAdmins,
    required List<SuperadminSupportAdminMini> filteredAdmins,
    required int? selectedId,
  }) {
    final resolved = <SuperadminSupportAdminMini>[...filteredAdmins];
    if (selectedId == null || selectedId <= 0) {
      return resolved;
    }

    SuperadminSupportAdminMini? selected;
    for (final admin in allAdmins) {
      if (admin.uid == selectedId) {
        selected = admin;
        break;
      }
    }

    final selectedAdmin = selected;
    if (selectedAdmin != null &&
        !resolved.any((admin) => admin.uid == selectedAdmin.uid)) {
      resolved.insert(0, selectedAdmin);
    }

    return resolved;
  }

  bool _containsLetterOrNumber(String value) {
    return RegExp(r'[A-Za-z0-9]').hasMatch(value);
  }
}

class _CreateTicketHelperCard extends StatelessWidget {
  const _CreateTicketHelperCard();

  @override
  Widget build(BuildContext context) {
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
            'Select an administrator, describe the issue, and attach files if needed.',
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
    required this.adminSearchController,
    required this.selectedAdminId,
    required this.admins,
    required this.adminsAreLoading,
    required this.titleController,
    required this.messageController,
    required this.category,
    required this.priority,
    required this.attachments,
    required this.isCreating,
    required this.onAdminChanged,
    required this.onCategoryChanged,
    required this.onPriorityChanged,
    required this.onRemoveAttachment,
  });

  final TextEditingController adminSearchController;
  final int? selectedAdminId;
  final List<SuperadminSupportAdminMini> admins;
  final bool adminsAreLoading;
  final TextEditingController titleController;
  final TextEditingController messageController;
  final SuperadminSupportTicketCategory category;
  final SuperadminSupportTicketPriority priority;
  final List<PlatformFile> attachments;
  final bool isCreating;
  final ValueChanged<int?> onAdminChanged;
  final ValueChanged<SuperadminSupportTicketCategory?> onCategoryChanged;
  final ValueChanged<SuperadminSupportTicketPriority?> onPriorityChanged;
  final ValueChanged<PlatformFile> onRemoveAttachment;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: adminSearchController,
          enabled: !isCreating,
          decoration: _fieldDecoration('Search admin').copyWith(
            hintText: 'Name, email, phone',
            prefixIcon: const Icon(Icons.search_rounded),
          ),
        ),
        const SizedBox(height: OpenVtsSpacing.sm),
        DropdownButtonFormField<int>(
          initialValue: selectedAdminId,
          isDense: true,
          isExpanded: true,
          decoration: _fieldDecoration('Admin'),
          items: admins
              .map(
                (admin) => DropdownMenuItem<int>(
                  value: admin.uid,
                  child: Text(
                    '${admin.displayName} (${admin.email.isEmpty ? admin.uid : admin.email})',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(growable: false),
          onChanged: isCreating ? null : onAdminChanged,
        ),
        if (admins.isEmpty && !adminsAreLoading) ...[
          const SizedBox(height: OpenVtsSpacing.xs),
          Text(
            adminSearchController.text.trim().isEmpty
                ? 'No administrators found.'
                : 'No administrators match this search.',
            style: OpenVtsTypography.meta.copyWith(
              color: OpenVtsColors.textSecondary,
            ),
          ),
        ],
        const SizedBox(height: OpenVtsSpacing.sm),
        TextField(
          controller: titleController,
          enabled: !isCreating,
          maxLength: _maxTitleLength,
          decoration: _fieldDecoration('Subject'),
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: OpenVtsSpacing.sm),
        LayoutBuilder(
          builder: (context, constraints) {
            final stackFields = constraints.maxWidth < 460;
            final categoryField =
                DropdownButtonFormField<SuperadminSupportTicketCategory>(
              initialValue: category,
              isDense: true,
              isExpanded: true,
              decoration: _fieldDecoration('Category'),
              items: SuperadminSupportTicketCategory.values
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
                DropdownButtonFormField<SuperadminSupportTicketPriority>(
              initialValue: priority,
              isDense: true,
              isExpanded: true,
              decoration: _fieldDecoration('Priority'),
              items: SuperadminSupportTicketPriority.values
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
          maxLength: _maxMessageLength,
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

Future<List<PlatformFile>?> _pickSuperadminSupportAttachments(
  BuildContext context, {
  required List<PlatformFile> existing,
}) async {
  final remaining = _maxAttachmentCount - existing.length;
  if (remaining <= 0) {
    ToastHelper.showError(
      'You can upload up to $_maxAttachmentCount files.',
      context: context,
    );
    return existing;
  }

  final result = await FilePicker.platform.pickFiles(
    allowMultiple: true,
    withData: true,
    type: FileType.custom,
    allowedExtensions: _allowedExtensions.toList(growable: false),
  );

  if (!context.mounted || result == null || result.files.isEmpty) {
    return null;
  }

  final merged = <PlatformFile>[...existing];
  final blocked = <String>[];
  final unsupported = <String>[];
  final oversized = <String>[];

  for (final file in result.files) {
    if (merged.length >= _maxAttachmentCount) {
      break;
    }

    final fileName = file.name.trim().isEmpty ? 'attachment' : file.name.trim();
    final extension = _extensionFromFileName(fileName);
    if (_blockedExtensions.contains(extension)) {
      blocked.add(fileName);
      continue;
    }
    if (!_allowedExtensions.contains(extension)) {
      unsupported.add(fileName);
      continue;
    }
    if (file.size > _maxAttachmentBytes) {
      oversized.add(fileName);
      continue;
    }

    final id = _superadminSupportAttachmentIdentity(file);
    final exists = merged.any(
      (item) => _superadminSupportAttachmentIdentity(item) == id,
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

String _superadminSupportAttachmentIdentity(PlatformFile file) {
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
