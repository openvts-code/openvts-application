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
const int _maxDocumentBytes = 10 * 1024 * 1024;
const List<String> _blockedDocumentExtensions = <String>[
  'exe',
  'js',
  'html',
  'htm',
];
const List<String> _allowedDocumentExtensions = <String>[
  'pdf',
  'png',
  'jpg',
  'jpeg',
  'webp',
  'gif',
  'doc',
  'docx',
  'xls',
  'xlsx',
  'csv',
  'txt',
  'ppt',
  'pptx',
  'zip',
];

class AdminUserDocumentsTab extends ConsumerStatefulWidget {
  const AdminUserDocumentsTab({
    super.key,
    required this.userId,
  });

  final String userId;

  @override
  ConsumerState<AdminUserDocumentsTab> createState() =>
      _AdminUserDocumentsTabState();
}

class _AdminUserDocumentsTabState extends ConsumerState<AdminUserDocumentsTab> {
  @override
  Widget build(BuildContext context) {
    final provider = adminUserDetailsControllerProvider(widget.userId);
    final state = ref.watch(provider);
    final controller = ref.read(provider.notifier);
    final baseUrl = ref.watch(apiBaseUrlProvider);
    final isInitialLoading =
        state.isLoadingDocuments && state.documents.isEmpty;

    if (isInitialLoading) {
      return const _SectionLoader(title: 'Documents');
    }

    if (state.sectionErrorMessage != null && state.documents.isEmpty) {
      return _SectionErrorCard(
        message: state.sectionErrorMessage!,
        onRetry: controller.loadDocuments,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SummaryCard(
          documentCount: state.documents.length,
          typeCount: state.documentTypes.length,
          isLoading: state.isLoadingDocuments || state.isLoadingDocumentTypes,
          isUploading: state.isUploadingDocument,
          onUpload: state.isUploadingDocument
              ? null
              : () => _showDocumentSheet(existing: null),
        ),
        const SizedBox(height: OpenVtsSpacing.sm),
        if (state.sectionErrorMessage != null) ...[
          _InlineError(message: state.sectionErrorMessage!),
          const SizedBox(height: OpenVtsSpacing.sm),
        ],
        if (state.documents.isEmpty)
          const _EmptyCard(label: 'No documents uploaded')
        else
          for (final document in state.documents) ...[
            _DocumentCard(
              document: document,
              isDeleting: state.isDeletingDocument,
              onView: () => _openDocument(baseUrl, document),
              onEdit: () => _showDocumentSheet(existing: document),
              onDelete: state.isDeletingDocument
                  ? null
                  : () => _confirmDelete(document),
            ),
            if (document != state.documents.last)
              const SizedBox(height: OpenVtsSpacing.sm),
          ],
      ],
    );
  }

  Future<void> _openDocument(String baseUrl, AdminUserDocument document) async {
    final url = _resolveFileUrl(document.filePath, baseUrl);
    if (url == null) {
      ToastHelper.showError('File URL is not available.', context: context);
      return;
    }

    try {
      final launched = await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
      if (!mounted) {
        return;
      }
      if (!launched) {
        ToastHelper.showError('Could not open file.', context: context);
      }
    } catch (_) {
      if (!mounted) {
        return;
      }
      ToastHelper.showError('Could not open file.', context: context);
    }
  }

  Future<void> _showDocumentSheet({required AdminUserDocument? existing}) {
    return OpenVtsBottomSheet.show<void>(
      context: context,
      title: existing == null ? 'Upload Document' : 'Edit Document',
      initialChildSize: 0.86,
      minChildSize: 0.48,
      maxChildSize: 0.96,
      child: _DocumentSheet(
        userId: widget.userId,
        existing: existing,
      ),
    );
  }

  Future<void> _confirmDelete(AdminUserDocument document) async {
    final label = _documentTitle(document);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete document'),
          content: Text('Remove $label from this user?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: TextButton.styleFrom(foregroundColor: OpenVtsColors.error),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    final provider = adminUserDetailsControllerProvider(widget.userId);
    final ok = await ref.read(provider.notifier).deleteDocument(document.id);
    if (!mounted) {
      return;
    }
    if (ok) {
      ToastHelper.showSuccess('Document deleted.', context: context);
    } else {
      ToastHelper.showError(
        ref.read(provider).sectionErrorMessage ?? 'Unable to delete document.',
        context: context,
      );
    }
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.documentCount,
    required this.typeCount,
    required this.isLoading,
    required this.isUploading,
    required this.onUpload,
  });

  final int documentCount;
  final int typeCount;
  final bool isLoading;
  final bool isUploading;
  final VoidCallback? onUpload;

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
                      Icons.description_outlined,
                      size: 17,
                      color: OpenVtsColors.textSecondary,
                    ),
                    const SizedBox(width: OpenVtsSpacing.xs),
                    Text(
                      'Documents',
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
                  '$documentCount files - $typeCount user types',
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
              label: 'Upload',
              height: 34,
              isLoading: isUploading,
              onPressed: onUpload,
              trailingIcon: Icons.upload_file_rounded,
            ),
          ),
        ],
      ),
    );
  }
}

enum _DocumentAction { view, edit, delete }

class _DocumentCard extends StatelessWidget {
  const _DocumentCard({
    required this.document,
    required this.isDeleting,
    required this.onView,
    required this.onEdit,
    required this.onDelete,
  });

  final AdminUserDocument document;
  final bool isDeleting;
  final VoidCallback onView;
  final VoidCallback onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final extension = _fileExtension(document);
    return OpenVtsCard(
      onTap: onView,
      padding: const EdgeInsets.all(OpenVtsSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ExtensionBadge(extension: extension),
              const SizedBox(width: OpenVtsSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _documentTitle(document),
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
                      _displayValue(document.docTypeName),
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
              PopupMenuButton<_DocumentAction>(
                tooltip: 'Document actions',
                enabled: !isDeleting,
                icon: isDeleting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.more_vert_rounded, size: 18),
                onSelected: (action) {
                  switch (action) {
                    case _DocumentAction.view:
                      onView();
                    case _DocumentAction.edit:
                      onEdit();
                    case _DocumentAction.delete:
                      onDelete?.call();
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: _DocumentAction.view,
                    height: 38,
                    child: _MenuRow(
                      icon: Icons.open_in_new_rounded,
                      label: 'View',
                    ),
                  ),
                  PopupMenuItem(
                    value: _DocumentAction.edit,
                    height: 38,
                    child: _MenuRow(icon: Icons.edit_outlined, label: 'Edit'),
                  ),
                  PopupMenuItem(
                    value: _DocumentAction.delete,
                    height: 38,
                    child: _MenuRow(
                      icon: Icons.delete_outline_rounded,
                      label: 'Delete',
                      isDestructive: true,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: OpenVtsSpacing.sm),
          _InfoLine(
            icon: Icons.insert_drive_file_outlined,
            label: _displayValue(document.fileName),
          ),
          const SizedBox(height: OpenVtsSpacing.xs),
          Wrap(
            spacing: OpenVtsSpacing.xs,
            runSpacing: OpenVtsSpacing.xs,
            children: [
              _MetaPill(
                icon: Icons.extension_outlined,
                label: extension.isEmpty ? 'FILE' : extension,
              ),
              _MetaPill(
                icon: Icons.event_outlined,
                label: document.expiryAt == null
                    ? 'No expiry'
                    : 'Expiry ${_dateText(document.expiryAt)}',
              ),
              _MetaPill(
                icon: document.isVisible
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                label: document.isVisible ? 'Visible' : 'Hidden',
                color: document.isVisible
                    ? OpenVtsColors.brandInk
                    : OpenVtsColors.textTertiary,
              ),
              _MetaPill(
                icon: Icons.calendar_today_outlined,
                label: 'Added ${_dateText(document.createdAt)}',
              ),
              for (final tag in document.tags.take(3))
                _MetaPill(icon: Icons.label_outline_rounded, label: tag),
            ],
          ),
        ],
      ),
    );
  }
}

class _DocumentSheet extends ConsumerStatefulWidget {
  const _DocumentSheet({
    required this.userId,
    required this.existing,
  });

  final String userId;
  final AdminUserDocument? existing;

  @override
  ConsumerState<_DocumentSheet> createState() => _DocumentSheetState();
}

class _DocumentSheetState extends ConsumerState<_DocumentSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _tagsController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _docTypeId;
  DateTime? _expiryAt;
  bool _isVisible = true;
  PlatformFile? _file;
  var _isPicking = false;
  var _fileError = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    if (existing != null) {
      _titleController.text = existing.title;
      _tagsController.text = existing.tags.join(', ');
      _descriptionController.text = existing.description;
      _docTypeId = existing.docTypeId.isEmpty ? null : existing.docTypeId;
      _expiryAt = existing.expiryAt;
      _isVisible = existing.isVisible;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _tagsController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = adminUserDetailsControllerProvider(widget.userId);
    final state = ref.watch(provider);
    final userTypes = state.documentTypes
        .where((type) => type.docFor.isEmpty || type.isForUser)
        .toList(growable: false);
    final isSubmitting =
        _isEdit ? state.isUpdatingDocument : state.isUploadingDocument;

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
                  _DocumentTypeField(
                    value: _docTypeId,
                    types: userTypes,
                    isLoading: state.isLoadingDocumentTypes,
                    onChanged: (value) => setState(() => _docTypeId = value),
                  ),
                  const SizedBox(height: OpenVtsSpacing.sm),
                  OpenVtsTextField(
                    label: 'Title',
                    controller: _titleController,
                    hintText: 'Document title',
                    prefixIcon: Icons.title_rounded,
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      final normalized = value?.trim() ?? '';
                      if (normalized.isEmpty) {
                        return 'Title is required.';
                      }
                      if (normalized.length > 120) {
                        return 'Title is too long.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: OpenVtsSpacing.sm),
                  _FilePickerField(
                    file: _file,
                    existingFileName: widget.existing?.fileName,
                    isPicking: _isPicking,
                    showError: _fileError,
                    onPick: _pickFile,
                  ),
                  const SizedBox(height: OpenVtsSpacing.sm),
                  _ExpiryField(
                    value: _expiryAt,
                    onPick: _pickExpiry,
                    onClear: () => setState(() => _expiryAt = null),
                  ),
                  const SizedBox(height: OpenVtsSpacing.sm),
                  OpenVtsTextField(
                    label: 'Tags',
                    controller: _tagsController,
                    hintText: 'license, insurance',
                    prefixIcon: Icons.label_outline_rounded,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: OpenVtsSpacing.sm),
                  OpenVtsTextField(
                    label: 'Description',
                    controller: _descriptionController,
                    hintText: 'Optional notes',
                    prefixIcon: Icons.notes_rounded,
                    maxLines: 3,
                  ),
                  const SizedBox(height: OpenVtsSpacing.sm),
                  _VisibilityToggle(
                    value: _isVisible,
                    onChanged: (value) => setState(() => _isVisible = value),
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
                    onPressed:
                        isSubmitting ? null : () => Navigator.of(context).pop(),
                  ),
                ),
                const SizedBox(width: OpenVtsSpacing.sm),
                Expanded(
                  child: OpenVtsButton(
                    label: _isEdit ? 'Save' : 'Upload',
                    height: 40,
                    isLoading: isSubmitting,
                    trailingIcon: _isEdit
                        ? Icons.check_rounded
                        : Icons.upload_file_rounded,
                    onPressed: isSubmitting ? null : _submit,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickFile() async {
    if (_isPicking) {
      return;
    }
    setState(() => _isPicking = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: _allowedDocumentExtensions,
        withData: true,
      );
      if (!mounted || result == null || result.files.isEmpty) {
        return;
      }

      final file = result.files.first;
      final extension = _extensionFromName(file.name).toLowerCase();
      if (_blockedDocumentExtensions.contains(extension)) {
        ToastHelper.showError('This file type is not allowed.',
            context: context);
        return;
      }
      if (!_allowedDocumentExtensions.contains(extension)) {
        ToastHelper.showError('Unsupported file type.', context: context);
        return;
      }
      if (file.size > _maxDocumentBytes) {
        ToastHelper.showError('File must be 10MB or smaller.',
            context: context);
        return;
      }

      setState(() {
        _file = file;
        _fileError = false;
      });
    } catch (_) {
      if (mounted) {
        ToastHelper.showError('Could not pick file.', context: context);
      }
    } finally {
      if (mounted) {
        setState(() => _isPicking = false);
      }
    }
  }

  Future<void> _pickExpiry() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiryAt ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 20),
    );
    if (picked != null) {
      setState(() => _expiryAt = picked);
    }
  }

  Future<void> _submit() async {
    final formOk = _formKey.currentState?.validate() ?? false;
    final needsFile = !_isEdit && _file == null;
    if (needsFile) {
      setState(() => _fileError = true);
    }
    if (!formOk || needsFile) {
      return;
    }

    final provider = adminUserDetailsControllerProvider(widget.userId);
    final controller = ref.read(provider.notifier);
    final request = AdminUserDocumentRequest(
      title: _titleController.text.trim(),
      docTypeId: _docTypeId ?? '',
      associateType: 'USER',
      associateId: widget.userId,
      isVisible: _isVisible,
      tags: _parseTags(_tagsController.text),
      description: _descriptionController.text.trim(),
      expiryAt: _expiryAt == null ? null : _formatYmd(_expiryAt!),
      file: _file,
    );

    final ok = _isEdit
        ? await controller.updateDocument(
            docId: widget.existing!.id,
            request: request,
          )
        : await controller.uploadDocument(request);
    if (!mounted) {
      return;
    }

    if (ok) {
      ToastHelper.showSuccess(
        _isEdit ? 'Document updated.' : 'Document uploaded.',
        context: context,
      );
      Navigator.of(context).pop();
    } else {
      ToastHelper.showError(
        ref.read(provider).sectionErrorMessage ??
            (_isEdit
                ? 'Unable to update document.'
                : 'Unable to upload document.'),
        context: context,
      );
    }
  }
}

class _DocumentTypeField extends StatelessWidget {
  const _DocumentTypeField({
    required this.value,
    required this.types,
    required this.isLoading,
    required this.onChanged,
  });

  final String? value;
  final List<AdminDocumentTypeOption> types;
  final bool isLoading;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null && types.any((type) => type.id == value);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Document type', style: OpenVtsTypography.label),
        const SizedBox(height: OpenVtsSpacing.xs),
        DropdownButtonFormField<String>(
          initialValue: hasValue ? value : null,
          isExpanded: true,
          hint: Text(isLoading ? 'Loading user types' : 'Select type'),
          decoration:
              const InputDecoration(prefixIcon: Icon(Icons.category_outlined)),
          items: types
              .map(
                (type) => DropdownMenuItem<String>(
                  value: type.id,
                  child: Text(
                    type.name.isEmpty ? type.id : type.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(growable: false),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Document type is required.';
            }
            return null;
          },
          onChanged: isLoading ? null : onChanged,
        ),
      ],
    );
  }
}

class _FilePickerField extends StatelessWidget {
  const _FilePickerField({
    required this.file,
    required this.existingFileName,
    required this.isPicking,
    required this.showError,
    required this.onPick,
  });

  final PlatformFile? file;
  final String? existingFileName;
  final bool isPicking;
  final bool showError;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final currentName = file?.name ?? existingFileName ?? '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('File', style: OpenVtsTypography.label),
        const SizedBox(height: OpenVtsSpacing.xs),
        Container(
          padding: const EdgeInsets.all(OpenVtsSpacing.sm),
          decoration: BoxDecoration(
            color: OpenVtsColors.surface,
            borderRadius: BorderRadius.circular(OpenVtsRadius.sm),
            border: Border.all(
              color: showError ? OpenVtsColors.error : OpenVtsColors.border,
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.attach_file_rounded,
                size: 18,
                color: OpenVtsColors.textSecondary,
              ),
              const SizedBox(width: OpenVtsSpacing.xs),
              Expanded(
                child: Text(
                  currentName.isEmpty ? 'Choose a file' : currentName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: OpenVtsTypography.meta.copyWith(
                    color: currentName.isEmpty
                        ? OpenVtsColors.textTertiary
                        : OpenVtsColors.textPrimary,
                    fontWeight: FontWeight.w700,
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
                        currentName.isEmpty ? 'Browse' : 'Replace',
                        style: OpenVtsTypography.meta.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
              ),
            ],
          ),
        ),
        if (showError) ...[
          const SizedBox(height: 4),
          Text(
            'File is required.',
            style: OpenVtsTypography.meta.copyWith(color: OpenVtsColors.error),
          ),
        ],
      ],
    );
  }
}

class _ExpiryField extends StatelessWidget {
  const _ExpiryField({
    required this.value,
    required this.onPick,
    required this.onClear,
  });

  final DateTime? value;
  final VoidCallback onPick;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Expiry date', style: OpenVtsTypography.label),
        const SizedBox(height: OpenVtsSpacing.xs),
        InkWell(
          borderRadius: BorderRadius.circular(OpenVtsRadius.sm),
          onTap: onPick,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: OpenVtsSpacing.sm,
              vertical: OpenVtsSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: OpenVtsColors.surface,
              borderRadius: BorderRadius.circular(OpenVtsRadius.sm),
              border: Border.all(color: OpenVtsColors.border),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.event_outlined,
                  size: 18,
                  color: OpenVtsColors.textSecondary,
                ),
                const SizedBox(width: OpenVtsSpacing.xs),
                Expanded(
                  child: Text(
                    value == null ? 'No expiry' : _dateText(value),
                    style: OpenVtsTypography.meta.copyWith(
                      color: value == null
                          ? OpenVtsColors.textTertiary
                          : OpenVtsColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (value != null)
                  IconButton(
                    tooltip: 'Clear expiry',
                    onPressed: onClear,
                    icon: const Icon(Icons.close_rounded, size: 17),
                    style: IconButton.styleFrom(
                      minimumSize: const Size.square(30),
                      padding: EdgeInsets.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  )
                else
                  const Icon(
                    Icons.expand_more_rounded,
                    size: 18,
                    color: OpenVtsColors.textSecondary,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _VisibilityToggle extends StatelessWidget {
  const _VisibilityToggle({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: OpenVtsSpacing.sm,
        vertical: OpenVtsSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: OpenVtsColors.surface,
        borderRadius: BorderRadius.circular(OpenVtsRadius.sm),
        border: Border.all(color: OpenVtsColors.border),
      ),
      child: Row(
        children: [
          Icon(
            value ? Icons.visibility_outlined : Icons.visibility_off_outlined,
            size: 18,
            color: OpenVtsColors.textSecondary,
          ),
          const SizedBox(width: OpenVtsSpacing.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Visible to user',
                  style: OpenVtsTypography.label.copyWith(
                    color: OpenVtsColors.textPrimary,
                  ),
                ),
                Text(
                  value ? 'Shown in user documents' : 'Hidden from user',
                  style: OpenVtsTypography.meta.copyWith(
                    color: OpenVtsColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _ExtensionBadge extends StatelessWidget {
  const _ExtensionBadge({required this.extension});

  final String extension;

  @override
  Widget build(BuildContext context) {
    final label = extension.isEmpty ? 'FILE' : extension;
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: OpenVtsColors.surface,
        borderRadius: BorderRadius.circular(OpenVtsRadius.sm),
        border: Border.all(color: OpenVtsColors.border),
      ),
      child: Text(
        label.length > 4 ? label.substring(0, 4) : label,
        style: OpenVtsTypography.meta.copyWith(
          color: OpenVtsColors.textPrimary,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: OpenVtsColors.textTertiary),
        const SizedBox(width: OpenVtsSpacing.xs),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: OpenVtsTypography.meta.copyWith(
              color: OpenVtsColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
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

class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.icon,
    required this.label,
    this.isDestructive = false,
  });

  final IconData icon;
  final String label;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final color =
        isDestructive ? OpenVtsColors.error : OpenVtsColors.textPrimary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: OpenVtsSpacing.xs),
        Text(
          label,
          style: OpenVtsTypography.meta.copyWith(
            color: color,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
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
                  'Unable to load documents',
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

String? _resolveFileUrl(String filePath, String baseUrl) {
  final path = filePath.trim();
  if (path.isEmpty) {
    return null;
  }
  if (path.startsWith('http://') || path.startsWith('https://')) {
    return path;
  }
  final base = baseUrl.trim().replaceAll(RegExp(r'/+$'), '');
  final relative = path.startsWith('/') ? path : '/$path';
  return '$base$relative';
}

String _documentTitle(AdminUserDocument document) {
  for (final value in [document.title, document.fileName]) {
    final normalized = value.trim();
    if (normalized.isNotEmpty && normalized != '-') {
      return normalized;
    }
  }
  return 'Document';
}

String _fileExtension(AdminUserDocument document) {
  for (final value in [document.fileName, document.filePath]) {
    final extension = _extensionFromName(value);
    if (extension.isNotEmpty) {
      return extension.toUpperCase();
    }
  }
  final fileType = document.fileType.trim();
  if (fileType.contains('/')) {
    return fileType.split('/').last.toUpperCase();
  }
  return fileType.toUpperCase();
}

String _extensionFromName(String value) {
  final normalized = value.trim();
  final dot = normalized.lastIndexOf('.');
  if (dot < 0 || dot >= normalized.length - 1) {
    return '';
  }
  return normalized.substring(dot + 1);
}

String _dateText(DateTime? value) {
  if (value == null) {
    return '-';
  }
  return _dateFormatter.formatDate(value.toLocal());
}

String _formatYmd(DateTime value) {
  final year = value.year.toString().padLeft(4, '0');
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}

List<String> _parseTags(String value) {
  return value
      .split(',')
      .map((tag) => tag.trim())
      .where((tag) => tag.isNotEmpty)
      .toList(growable: false);
}

String _displayValue(String value) {
  final normalized = value.trim();
  if (normalized.isEmpty || normalized == '-') {
    return '-';
  }
  return normalized;
}
