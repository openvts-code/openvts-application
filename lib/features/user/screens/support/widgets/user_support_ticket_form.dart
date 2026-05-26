import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_vts/core/theme/open_vts_colors.dart';
import 'package:open_vts/core/theme/open_vts_spacing.dart';
import 'package:open_vts/core/theme/open_vts_typography.dart';
import 'package:open_vts/features/user/controllers/user_providers.dart';
import 'package:open_vts/features/user/models/user_support_constraints.dart';
import 'package:open_vts/features/user/models/user_support_model.dart';
import 'package:open_vts/features/user/screens/support/widgets/user_support_attachment_widgets.dart';
import 'package:open_vts/shared/helpers/toast_helper.dart';
import 'package:open_vts/shared/widgets/open_vts_button.dart';
import 'package:open_vts/shared/widgets/open_vts_card.dart';

class UserSupportTicketForm extends ConsumerStatefulWidget {
  const UserSupportTicketForm({
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
  ConsumerState<UserSupportTicketForm> createState() =>
      _UserSupportTicketFormState();
}

class _UserSupportTicketFormState extends ConsumerState<UserSupportTicketForm> {
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  UserSupportTicketCategory _category = UserSupportTicketCategory.other;
  UserSupportTicketPriority _priority = UserSupportTicketPriority.medium;
  List<PlatformFile> _attachments = <PlatformFile>[];

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
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

  Future<void> _submit() async {
    final subject = _subjectController.text.trim();
    final message = _messageController.text.trim();
    if (!_validateSubject(subject) || !_validateMessage(message)) {
      return;
    }

    final controller = ref.read(userSupportControllerProvider.notifier);
    final detail = await controller.createTicket(
      title: subject,
      message: message,
      category: _category,
      priority: _priority,
      attachments: _attachments,
    );

    if (!mounted) {
      return;
    }

    if (detail == null) {
      final error =
          ref.read(userSupportControllerProvider).errorMessage ??
          'Unable to create ticket right now.';
      ToastHelper.showError(error, context: context);
      return;
    }

    ToastHelper.showSuccess('Ticket created.', context: context);
    Navigator.of(context).pop(detail.id);
  }

  @override
  Widget build(BuildContext context) {
    final isCreating = ref.watch(
      userSupportControllerProvider.select((state) => state.isCreating),
    );

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
                      const _CreateTicketHelperCard(),
                      const SizedBox(height: OpenVtsSpacing.sm),
                    ],
                    OpenVtsCard(
                      padding: const EdgeInsets.all(OpenVtsSpacing.md),
                      child: _TicketFields(
                        subjectController: _subjectController,
                        messageController: _messageController,
                        category: _category,
                        priority: _priority,
                        attachments: _attachments,
                        isCreating: isCreating,
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
                userSupportAttachmentIdentity(item) !=
                userSupportAttachmentIdentity(file),
          )
          .toList(growable: false);
    });
  }

  bool _validateSubject(String value) {
    if (value.trim().isEmpty) {
      ToastHelper.showError('Subject is required.', context: context);
      return false;
    }
    if (value.length > userSupportMaxTitleLength) {
      ToastHelper.showError(
        'Subject must be $userSupportMaxTitleLength characters or less.',
        context: context,
      );
      return false;
    }
    if (!userSupportContainsLetterOrNumber(value)) {
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
    if (value.length > userSupportMaxMessageLength) {
      ToastHelper.showError(
        'Description must be $userSupportMaxMessageLength characters or less.',
        context: context,
      );
      return false;
    }
    if (!userSupportContainsLetterOrNumber(value)) {
      ToastHelper.showError(
        'Description must contain at least one letter or number.',
        context: context,
      );
      return false;
    }
    return true;
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
            'Briefly describe the issue and attach files if needed.',
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
    required this.subjectController,
    required this.messageController,
    required this.category,
    required this.priority,
    required this.attachments,
    required this.isCreating,
    required this.onCategoryChanged,
    required this.onPriorityChanged,
    required this.onRemoveAttachment,
  });

  final TextEditingController subjectController;
  final TextEditingController messageController;
  final UserSupportTicketCategory category;
  final UserSupportTicketPriority priority;
  final List<PlatformFile> attachments;
  final bool isCreating;
  final ValueChanged<UserSupportTicketCategory?> onCategoryChanged;
  final ValueChanged<UserSupportTicketPriority?> onPriorityChanged;
  final ValueChanged<PlatformFile> onRemoveAttachment;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: subjectController,
          enabled: !isCreating,
          maxLength: userSupportMaxTitleLength,
          decoration: _fieldDecoration('Subject'),
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: OpenVtsSpacing.sm),
        LayoutBuilder(
          builder: (context, constraints) {
            final stackFields = constraints.maxWidth < 460;
            final categoryField =
                DropdownButtonFormField<UserSupportTicketCategory>(
                  initialValue: category,
                  isDense: true,
                  isExpanded: true,
                  decoration: _fieldDecoration('Category'),
                  items: UserSupportTicketCategory.values
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
                DropdownButtonFormField<UserSupportTicketPriority>(
                  initialValue: priority,
                  isDense: true,
                  isExpanded: true,
                  decoration: _fieldDecoration('Priority'),
                  items: UserSupportTicketPriority.values
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
          maxLength: userSupportMaxMessageLength,
          decoration: _fieldDecoration(
            'Description',
          ).copyWith(alignLabelWithHint: true),
        ),
        if (attachments.isNotEmpty) ...[
          const SizedBox(height: OpenVtsSpacing.sm),
          UserSupportDraftAttachmentWrap(
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
