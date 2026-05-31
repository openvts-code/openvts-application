import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../core/config/app_config.dart';
import '../../../../../core/theme/open_vts_colors.dart';
import '../../../../../core/theme/open_vts_radius.dart';
import '../../../../../core/theme/open_vts_spacing.dart';
import '../../../../../core/utils/date_time_formatter.dart';
import '../../../../../shared/helpers/toast_helper.dart';
import '../../../../../shared/widgets/open_vts_button.dart';
import '../../../../../shared/widgets/open_vts_card.dart';
import '../../../../../shared/widgets/open_vts_error_view.dart';
import '../../../../../shared/widgets/open_vts_loader.dart';
import '../../../../../shared/widgets/open_vts_text_field.dart';
import '../../../controllers/superadmin_providers.dart';
import '../../../models/superadmin_admin_details_model.dart';

const int _kMaxFileSizeBytes = 10 * 1024 * 1024;
const List<String> _kBlockedExtensions = <String>['exe', 'js', 'html', 'htm'];
const List<String> _kAllowedExtensions = <String>[
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
];

class AdminDetailsDocumentsTab extends ConsumerStatefulWidget {
  const AdminDetailsDocumentsTab({required this.adminId, super.key});

  final String adminId;

  @override
  ConsumerState<AdminDetailsDocumentsTab> createState() =>
      _AdminDetailsDocumentsTabState();
}

class _AdminDetailsDocumentsTabState
    extends ConsumerState<AdminDetailsDocumentsTab> {
  @override
  Widget build(BuildContext context) {
    final provider = superadminAdminDetailsControllerProvider(widget.adminId);
    final docs = ref.watch(provider.select((s) => s.documents));
    final isLoading = ref.watch(provider.select((s) => s.isLoadingDocuments));
    final hasLoaded = ref.watch(provider.select((s) => s.hasLoadedDocuments));
    final isUploading =
        ref.watch(provider.select((s) => s.isUploadingDocument));
    final errorMessage =
        ref.watch(provider.select((s) => s.documentsErrorMessage));
    final isLoadingTypes =
        ref.watch(provider.select((s) => s.isLoadingDocumentTypes));
    final typesError =
        ref.watch(provider.select((s) => s.documentTypesErrorMessage));
    final controller = ref.read(provider.notifier);

    if (isLoading && !hasLoaded) {
      return const OpenVtsCard(
        padding: EdgeInsets.symmetric(vertical: OpenVtsSpacing.lg),
        child: Center(child: OpenVtsLoader()),
      );
    }

    if (errorMessage != null && !hasLoaded) {
      return OpenVtsCard(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: OpenVtsSpacing.md),
          child: OpenVtsErrorView(
            message: errorMessage.trim().isEmpty
                ? 'Unable to load documents. Retry.'
                : errorMessage,
            onRetry: () => controller.loadDocuments(force: true),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isLoading && hasLoaded) const LinearProgressIndicator(minHeight: 2),
        Row(
          children: [
            Expanded(
              child: Text(
                'Documents (${docs.length})',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: OpenVtsColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: OpenVtsSpacing.xs),
        OpenVtsButton(
          label: 'Upload document',
          onPressed: (isUploading || isLoading)
              ? null
              : () => _openUploadSheet(context),
        ),
        if (isLoadingTypes) ...[
          const SizedBox(height: OpenVtsSpacing.xs),
          const Row(
            children: [
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 8),
              Text(
                'Loading document types…',
                style: TextStyle(
                  fontSize: 11,
                  color: OpenVtsColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
        if (typesError != null) ...[
          const SizedBox(height: OpenVtsSpacing.xs),
          OpenVtsCard(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: OpenVtsSpacing.sm),
              child: OpenVtsErrorView(
                message: typesError.trim().isEmpty
                    ? 'Unable to load document types. Retry.'
                    : typesError,
                onRetry: () => controller.loadDocumentTypes(force: true),
              ),
            ),
          ),
        ],
        if (errorMessage != null && hasLoaded) ...[
          const SizedBox(height: OpenVtsSpacing.xs),
          Text(
            errorMessage.trim().isEmpty
                ? 'Unable to refresh documents.'
                : errorMessage,
            style: const TextStyle(
              fontSize: 11,
              color: OpenVtsColors.error,
            ),
          ),
        ],
        const SizedBox(height: OpenVtsSpacing.sm),
        if (docs.isEmpty)
          const _EmptyState(message: 'No documents uploaded yet.')
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            addAutomaticKeepAlives: false,
            itemCount: docs.length,
            separatorBuilder: (_, __) =>
                const SizedBox(height: OpenVtsSpacing.xs),
            itemBuilder: (context, index) {
              final doc = docs[index];
              return _DocumentCard(
                document: doc,
                onView: () => _viewDocument(context, doc),
                onEdit: () => _openEditSheet(context, doc),
                onDelete: () => _confirmDelete(context, doc),
              );
            },
          ),
      ],
    );
  }

  Future<void> _viewDocument(
    BuildContext context,
    SuperadminAdminDocument doc,
  ) async {
    final url = _resolveFileUrl(doc);
    if (url == null) {
      ToastHelper.showError('File URL is not available.', context: context);
      return;
    }
    try {
      final uri = Uri.parse(url);
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && context.mounted) {
        ToastHelper.showError('Could not open file.', context: context);
      }
    } catch (_) {
      if (context.mounted) {
        ToastHelper.showError('Could not open file.', context: context);
      }
    }
  }

  Future<void> _openUploadSheet(BuildContext context) async {
    final provider = superadminAdminDetailsControllerProvider(widget.adminId);
    final controller = ref.read(provider.notifier);
    var state = ref.read(provider);

    if (!state.hasLoadedDocumentTypes && !state.isLoadingDocumentTypes) {
      await controller.loadDocumentTypes(force: true);
      if (!context.mounted) return;
      state = ref.read(provider);
    }

    final userTypes = state.documentTypes.where((t) => t.isForUser).toList();
    if (userTypes.isEmpty) {
      final typeError = state.documentTypesErrorMessage?.trim();
      ToastHelper.showError(
        (typeError == null || typeError.isEmpty)
            ? 'No USER document types configured.'
            : 'Unable to load document types. Retry.',
        context: context,
      );
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: OpenVtsColors.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _DocumentSheet(
        adminId: widget.adminId,
        existing: null,
      ),
    );
  }

  Future<void> _openEditSheet(
    BuildContext context,
    SuperadminAdminDocument doc,
  ) async {
    final provider = superadminAdminDetailsControllerProvider(widget.adminId);
    final state = ref.read(provider);
    if (!state.hasLoadedDocumentTypes && !state.isLoadingDocumentTypes) {
      await ref.read(provider.notifier).loadDocumentTypes(force: true);
      if (!context.mounted) return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: OpenVtsColors.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _DocumentSheet(
        adminId: widget.adminId,
        existing: doc,
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    SuperadminAdminDocument doc,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: OpenVtsColors.surfaceElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(OpenVtsRadius.md),
        ),
        title: const Text(
          'Delete this document?',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: OpenVtsColors.textPrimary,
          ),
        ),
        content: Text(
          doc.title.isNotEmpty ? doc.title : doc.fileName,
          style: const TextStyle(
            fontSize: 12,
            color: OpenVtsColors.textSecondary,
          ),
        ),
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
      ),
    );
    if (confirmed != true || !mounted) return;
    final provider = superadminAdminDetailsControllerProvider(widget.adminId);
    final ok = await ref.read(provider.notifier).deleteDocument(doc.id);
    if (!mounted) return;
    if (ok) {
      ToastHelper.showSuccess('Document deleted.', context: this.context);
    } else {
      final message = ref.read(provider).documentMutationErrorMessage ??
          'Failed to delete document.';
      ToastHelper.showError(message, context: this.context);
    }
  }
}

String? _resolveFileUrl(SuperadminAdminDocument doc) {
  final directUrl = doc.fileUrl.trim();
  if (directUrl.isNotEmpty) {
    final parsed = Uri.tryParse(directUrl);
    if (parsed != null && parsed.hasScheme && parsed.hasAuthority) {
      return directUrl;
    }
  }

  final path = directUrl.isNotEmpty ? directUrl : doc.filePath.trim();
  if (path.isEmpty) return null;
  if (path.startsWith('http://') || path.startsWith('https://')) return path;
  final normalized = path.startsWith('/') ? path : '/$path';

  if (normalized.startsWith('/uploads') ||
      normalized.startsWith('/api/uploads')) {
    final origin = AppConfig.apiOriginBaseUrl().replaceAll(RegExp(r'/+$'), '');
    return '$origin$normalized';
  }

  final apiBase = AppConfig.apiBaseUrl.replaceAll(RegExp(r'/+$'), '');
  return '$apiBase$normalized';
}

String _fileExtension(SuperadminAdminDocument doc) {
  final source = doc.fileName.isNotEmpty ? doc.fileName : doc.filePath;
  final dot = source.lastIndexOf('.');
  if (dot < 0 || dot >= source.length - 1) return '';
  return source.substring(dot + 1).toUpperCase();
}

// ---------------------------------------------------------------------------
// Document card
// ---------------------------------------------------------------------------

enum _DocAction { view, edit, delete }

class _DocumentCard extends StatelessWidget {
  const _DocumentCard({
    required this.document,
    required this.onView,
    required this.onEdit,
    required this.onDelete,
  });

  final SuperadminAdminDocument document;
  final VoidCallback onView;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final ext = _fileExtension(document);
    final created = document.createdAt;
    final expiry = document.expiryAt;
    const fmt = DateTimeFormatter();

    return OpenVtsCard(
      onTap: onView,
      padding: const EdgeInsets.symmetric(
        horizontal: OpenVtsSpacing.sm,
        vertical: OpenVtsSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ExtensionBadge(extension: ext),
              const SizedBox(width: OpenVtsSpacing.xs),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      document.title.isNotEmpty
                          ? document.title
                          : document.fileName,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: OpenVtsColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      document.docTypeName.isNotEmpty
                          ? document.docTypeName
                          : 'Document',
                      style: const TextStyle(
                        fontSize: 11,
                        color: OpenVtsColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              _ActionsMenu(
                onView: onView,
                onEdit: onEdit,
                onDelete: onDelete,
              ),
            ],
          ),
          if (document.fileName.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              document.fileName,
              style: const TextStyle(
                fontSize: 11,
                color: OpenVtsColors.textTertiary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              if (created != null)
                _MetaChip(
                  icon: Icons.calendar_today_outlined,
                  label: 'Added ${fmt.formatDate(created)}',
                ),
              if (expiry != null) _ExpiryChip(expiryAt: expiry, formatter: fmt),
              _VisibilityChip(isVisible: document.isVisible),
              if (document.tags.isNotEmpty)
                for (final tag in document.tags.take(3))
                  _MetaChip(icon: Icons.label_outline, label: tag),
            ],
          ),
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
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: OpenVtsColors.textPrimary,
        ),
      ),
    );
  }
}

class _ActionsMenu extends StatelessWidget {
  const _ActionsMenu({
    required this.onView,
    required this.onEdit,
    required this.onDelete,
  });

  final VoidCallback onView;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_DocAction>(
      tooltip: 'Actions',
      icon: const Icon(
        Icons.more_vert,
        size: 18,
        color: OpenVtsColors.textSecondary,
      ),
      onSelected: (action) {
        switch (action) {
          case _DocAction.view:
            onView();
          case _DocAction.edit:
            onEdit();
          case _DocAction.delete:
            onDelete();
        }
      },
      itemBuilder: (_) => const [
        PopupMenuItem(
          value: _DocAction.view,
          height: 36,
          child: Text('View', style: TextStyle(fontSize: 12)),
        ),
        PopupMenuItem(
          value: _DocAction.edit,
          height: 36,
          child: Text('Edit', style: TextStyle(fontSize: 12)),
        ),
        PopupMenuItem(
          value: _DocAction.delete,
          height: 36,
          child: Text(
            'Delete',
            style: TextStyle(fontSize: 12, color: OpenVtsColors.error),
          ),
        ),
      ],
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label, this.color});
  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final fg = color ?? OpenVtsColors.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: OpenVtsColors.surface,
        borderRadius: BorderRadius.circular(OpenVtsRadius.sm),
        border: Border.all(color: OpenVtsColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: fg),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 10, color: fg),
          ),
        ],
      ),
    );
  }
}

class _ExpiryChip extends StatelessWidget {
  const _ExpiryChip({required this.expiryAt, required this.formatter});
  final DateTime expiryAt;
  final DateTimeFormatter formatter;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final diff = expiryAt.difference(DateTime(now.year, now.month, now.day));
    final days = diff.inDays;
    final Color color;
    final String label;
    if (days < 0) {
      color = OpenVtsColors.error;
      label = 'Expired ${formatter.formatDate(expiryAt)}';
    } else if (days <= 30) {
      color = OpenVtsColors.warning;
      label = 'Expires in ${days}d';
    } else {
      color = OpenVtsColors.success;
      label = 'Expires ${formatter.formatDate(expiryAt)}';
    }
    return _MetaChip(
      icon: Icons.schedule_outlined,
      label: label,
      color: color,
    );
  }
}

class _VisibilityChip extends StatelessWidget {
  const _VisibilityChip({required this.isVisible});
  final bool isVisible;

  @override
  Widget build(BuildContext context) {
    return _MetaChip(
      icon:
          isVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
      label: isVisible ? 'Visible' : 'Hidden',
      color: isVisible ? OpenVtsColors.success : OpenVtsColors.textSecondary,
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return OpenVtsCard(
      padding: const EdgeInsets.symmetric(vertical: OpenVtsSpacing.lg),
      child: Center(
        child: Text(
          message,
          style: const TextStyle(
            fontSize: 12,
            color: OpenVtsColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Upload / Edit sheet
// ---------------------------------------------------------------------------

class _DocumentSheet extends ConsumerStatefulWidget {
  const _DocumentSheet({required this.adminId, required this.existing});

  final String adminId;
  final SuperadminAdminDocument? existing;

  @override
  ConsumerState<_DocumentSheet> createState() => _DocumentSheetState();
}

class _DocumentSheetState extends ConsumerState<_DocumentSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _title = TextEditingController();
  final TextEditingController _tags = TextEditingController();
  final TextEditingController _description = TextEditingController();

  String? _docTypeId;
  DateTime? _expiryAt;
  bool _isVisible = true;
  PlatformFile? _pickedFile;
  bool _fileError = false;
  bool _picking = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final ex = widget.existing;
    if (ex != null) {
      _title.text = ex.title;
      _tags.text = ex.tags.join(', ');
      _description.text = ex.description;
      _docTypeId = ex.docTypeId.isNotEmpty ? ex.docTypeId : null;
      _expiryAt = ex.expiryAt;
      _isVisible = ex.isVisible;
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _tags.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    if (_picking) return;
    setState(() => _picking = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: _kAllowedExtensions,
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;
      final file = result.files.first;
      final ext = (file.extension ?? '').toLowerCase();
      if (_kBlockedExtensions.contains(ext)) {
        if (mounted) {
          ToastHelper.showError(
            'This file type is not allowed.',
            context: context,
          );
        }
        return;
      }
      if (file.size > _kMaxFileSizeBytes) {
        if (mounted) {
          ToastHelper.showError(
            'File exceeds 10MB limit.',
            context: context,
          );
        }
        return;
      }
      setState(() {
        _pickedFile = file;
        _fileError = false;
      });
    } catch (_) {
      if (mounted) {
        ToastHelper.showError('Could not pick file.', context: context);
      }
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  Future<void> _pickExpiry() async {
    final now = DateTime.now();
    final initial = _expiryAt ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(now) ? now : initial,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 20),
    );
    if (picked != null) {
      setState(() => _expiryAt = picked);
    }
  }

  String _formatYmd(DateTime value) {
    final y = value.year.toString().padLeft(4, '0');
    final m = value.month.toString().padLeft(2, '0');
    final d = value.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  List<String> _parseTags(String raw) {
    return raw
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList(growable: false);
  }

  Future<void> _submit() async {
    final formOk = _formKey.currentState?.validate() ?? false;
    final needsFile = !_isEdit && _pickedFile == null;
    if (needsFile) setState(() => _fileError = true);
    if (!formOk || needsFile) return;

    final provider = superadminAdminDetailsControllerProvider(widget.adminId);
    final controller = ref.read(provider.notifier);
    final request = SuperadminAdminDocumentRequest(
      title: _title.text.trim(),
      docTypeId: _docTypeId ?? '',
      associateId: widget.adminId,
      isVisible: _isVisible,
      tags: _parseTags(_tags.text),
      description: _description.text.trim(),
      expiryAt: _expiryAt == null ? null : _formatYmd(_expiryAt!),
      file: _pickedFile,
    );

    final bool ok;
    if (_isEdit) {
      ok = await controller.updateDocument(
        docId: widget.existing!.id,
        request: request,
      );
    } else {
      ok = await controller.uploadDocument(request);
    }
    if (!mounted) return;
    if (ok) {
      ToastHelper.showSuccess(
        _isEdit ? 'Document updated.' : 'Document uploaded.',
        context: context,
      );
      Navigator.of(context).maybePop();
    } else {
      final message = ref.read(provider).documentMutationErrorMessage ??
          (_isEdit
              ? 'Failed to update document.'
              : 'Failed to upload document.');
      ToastHelper.showError(message, context: context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = superadminAdminDetailsControllerProvider(widget.adminId);
    final isLoading = ref.watch(provider.select((s) => s.isUploadingDocument));
    final docTypes = ref.watch(provider.select(
      (s) => s.documentTypes.where((t) => t.isForUser).toList(growable: false),
    ));
    final isLoadingTypes =
        ref.watch(provider.select((s) => s.isLoadingDocumentTypes));
    final viewInsets = MediaQuery.of(context).viewInsets;

    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _SheetHeader(
              title: _isEdit ? 'Edit document' : 'Upload document',
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  OpenVtsSpacing.md,
                  OpenVtsSpacing.sm,
                  OpenVtsSpacing.md,
                  OpenVtsSpacing.sm,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _DocTypeDropdown(
                        value: _docTypeId,
                        options: docTypes,
                        isLoading: isLoadingTypes,
                        onChanged: (next) => setState(() => _docTypeId = next),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Document type is required.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: OpenVtsSpacing.sm),
                      OpenVtsTextField(
                        label: 'Title',
                        controller: _title,
                        hintText: 'Document title',
                        textInputAction: TextInputAction.next,
                        prefixIcon: Icons.title,
                        validator: (value) {
                          final raw = value?.trim() ?? '';
                          if (raw.isEmpty) return 'Title is required.';
                          if (raw.length > 120) return 'Title is too long.';
                          return null;
                        },
                      ),
                      const SizedBox(height: OpenVtsSpacing.sm),
                      _FilePickerField(
                        pickedFile: _pickedFile,
                        existingFileName:
                            _isEdit ? widget.existing!.fileName : null,
                        onPick: _pickFile,
                        isPicking: _picking,
                        showError: _fileError,
                      ),
                      const SizedBox(height: OpenVtsSpacing.sm),
                      _ExpiryField(
                        value: _expiryAt,
                        onPick: _pickExpiry,
                        onClear: () => setState(() => _expiryAt = null),
                      ),
                      const SizedBox(height: OpenVtsSpacing.sm),
                      OpenVtsTextField(
                        label: 'Tags (comma separated)',
                        controller: _tags,
                        hintText: 'license, insurance',
                        textInputAction: TextInputAction.next,
                        prefixIcon: Icons.label_outline,
                      ),
                      const SizedBox(height: OpenVtsSpacing.sm),
                      OpenVtsTextField(
                        label: 'Description (optional)',
                        controller: _description,
                        hintText: 'Notes about this document',
                        maxLines: 3,
                        prefixIcon: Icons.notes,
                      ),
                      const SizedBox(height: OpenVtsSpacing.sm),
                      _VisibilityToggle(
                        value: _isVisible,
                        onChanged: (v) => setState(() => _isVisible = v),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            _SheetFooter(
              isLoading: isLoading,
              submitLabel: _isEdit ? 'Save changes' : 'Upload',
              onCancel: () => Navigator.of(context).maybePop(),
              onSubmit: _submit,
            ),
          ],
        ),
      ),
    );
  }
}

class _DocTypeDropdown extends StatelessWidget {
  const _DocTypeDropdown({
    required this.value,
    required this.options,
    required this.isLoading,
    required this.onChanged,
    required this.validator,
  });

  final String? value;
  final List<SuperadminDocumentTypeOption> options;
  final bool isLoading;
  final ValueChanged<String?> onChanged;
  final FormFieldValidator<String> validator;

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null && options.any((o) => o.id == value);

    if (options.isEmpty && isLoading) {
      return const SizedBox(
        height: 44,
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 8),
              Text(
                'Loading document types…',
                style: TextStyle(
                  fontSize: 12,
                  color: OpenVtsColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (options.isEmpty && !isLoading) {
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: OpenVtsSpacing.sm,
          vertical: OpenVtsSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: OpenVtsColors.surface,
          borderRadius: BorderRadius.circular(OpenVtsRadius.sm),
          border: Border.all(color: OpenVtsColors.border),
        ),
        child: const Text(
          'No USER document types configured.',
          style: TextStyle(
            fontSize: 12,
            color: OpenVtsColors.textSecondary,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Document type',
          style: TextStyle(
            fontSize: 11,
            color: OpenVtsColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          initialValue: hasValue ? value : null,
          isDense: true,
          hint: Text(
            isLoading ? 'Loading…' : 'Select type',
            style: const TextStyle(
              fontSize: 13,
              color: OpenVtsColors.textTertiary,
            ),
          ),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: OpenVtsSpacing.sm,
              vertical: OpenVtsSpacing.sm,
            ),
            filled: true,
            fillColor: OpenVtsColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(OpenVtsRadius.sm),
              borderSide: const BorderSide(color: OpenVtsColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(OpenVtsRadius.sm),
              borderSide: const BorderSide(color: OpenVtsColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(OpenVtsRadius.sm),
              borderSide: const BorderSide(color: OpenVtsColors.brandInk),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(OpenVtsRadius.sm),
              borderSide: const BorderSide(color: OpenVtsColors.error),
            ),
          ),
          items: options
              .map(
                (o) => DropdownMenuItem<String>(
                  value: o.id,
                  child: Text(
                    o.name,
                    style: const TextStyle(
                      fontSize: 13,
                      color: OpenVtsColors.textPrimary,
                    ),
                  ),
                ),
              )
              .toList(growable: false),
          onChanged: onChanged,
          validator: validator,
        ),
      ],
    );
  }
}

class _FilePickerField extends StatelessWidget {
  const _FilePickerField({
    required this.pickedFile,
    required this.existingFileName,
    required this.onPick,
    required this.isPicking,
    required this.showError,
  });

  final PlatformFile? pickedFile;
  final String? existingFileName;
  final VoidCallback onPick;
  final bool isPicking;
  final bool showError;

  @override
  Widget build(BuildContext context) {
    String label;
    if (pickedFile != null) {
      label = pickedFile!.name;
    } else if (existingFileName != null && existingFileName!.isNotEmpty) {
      label = existingFileName!;
    } else {
      label = 'No file selected';
    }
    final borderColor = showError ? OpenVtsColors.error : OpenVtsColors.border;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'File',
          style: TextStyle(
            fontSize: 11,
            color: OpenVtsColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        InkWell(
          onTap: isPicking ? null : onPick,
          borderRadius: BorderRadius.circular(OpenVtsRadius.sm),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: OpenVtsSpacing.sm,
              vertical: OpenVtsSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: OpenVtsColors.surface,
              borderRadius: BorderRadius.circular(OpenVtsRadius.sm),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.attach_file,
                  size: 16,
                  color: OpenVtsColors.textSecondary,
                ),
                const SizedBox(width: OpenVtsSpacing.xs),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      color: OpenVtsColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isPicking)
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  const Text(
                    'Browse',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: OpenVtsColors.brandInk,
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (showError)
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Text(
              'Please select a file.',
              style: TextStyle(fontSize: 11, color: OpenVtsColors.error),
            ),
          )
        else
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Text(
              'Max 10MB. Blocked: exe, js, html, htm.',
              style: TextStyle(fontSize: 10, color: OpenVtsColors.textTertiary),
            ),
          ),
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
    final label = value == null
        ? 'No expiry date'
        : const DateTimeFormatter().formatDate(value!);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Expiry date (optional)',
          style: TextStyle(
            fontSize: 11,
            color: OpenVtsColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        InkWell(
          onTap: onPick,
          borderRadius: BorderRadius.circular(OpenVtsRadius.sm),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: OpenVtsSpacing.sm,
              vertical: OpenVtsSpacing.sm,
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
                  size: 16,
                  color: OpenVtsColors.textSecondary,
                ),
                const SizedBox(width: OpenVtsSpacing.xs),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: value == null
                          ? OpenVtsColors.textTertiary
                          : OpenVtsColors.textPrimary,
                    ),
                  ),
                ),
                if (value != null)
                  GestureDetector(
                    onTap: onClear,
                    child: const Icon(
                      Icons.close,
                      size: 16,
                      color: OpenVtsColors.textSecondary,
                    ),
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
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: OpenVtsColors.surface,
        borderRadius: BorderRadius.circular(OpenVtsRadius.sm),
        border: Border.all(color: OpenVtsColors.border),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.visibility_outlined,
            size: 16,
            color: OpenVtsColors.textSecondary,
          ),
          const SizedBox(width: OpenVtsSpacing.xs),
          const Expanded(
            child: Text(
              'Visible to admin',
              style: TextStyle(
                fontSize: 12,
                color: OpenVtsColors.textPrimary,
              ),
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeThumbColor: OpenVtsColors.brandInk,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sheet chrome
// ---------------------------------------------------------------------------

class _SheetHeader extends StatelessWidget {
  const _SheetHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        OpenVtsSpacing.md,
        OpenVtsSpacing.sm,
        OpenVtsSpacing.xs,
        0,
      ),
      child: Column(
        children: [
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(top: 6, bottom: OpenVtsSpacing.sm),
            decoration: BoxDecoration(
              color: OpenVtsColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: OpenVtsColors.textPrimary,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 20),
                onPressed: () => Navigator.of(context).maybePop(),
                tooltip: 'Close',
              ),
            ],
          ),
          const Divider(height: 1, color: OpenVtsColors.border),
        ],
      ),
    );
  }
}

class _SheetFooter extends StatelessWidget {
  const _SheetFooter({
    required this.isLoading,
    required this.onCancel,
    required this.onSubmit,
    required this.submitLabel,
  });

  final bool isLoading;
  final VoidCallback onCancel;
  final VoidCallback onSubmit;
  final String submitLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: OpenVtsColors.border)),
        color: OpenVtsColors.surfaceElevated,
      ),
      padding: const EdgeInsets.fromLTRB(
        OpenVtsSpacing.md,
        OpenVtsSpacing.sm,
        OpenVtsSpacing.md,
        OpenVtsSpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: OpenVtsButton(
              label: 'Cancel',
              variant: OpenVtsButtonVariant.secondary,
              onPressed: isLoading ? null : onCancel,
            ),
          ),
          const SizedBox(width: OpenVtsSpacing.sm),
          Expanded(
            child: OpenVtsButton(
              label: submitLabel,
              isLoading: isLoading,
              onPressed: isLoading ? null : onSubmit,
            ),
          ),
        ],
      ),
    );
  }
}
