import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../../core/theme/open_vts_colors.dart';
import '../../../../../../core/theme/open_vts_radius.dart';
import '../../../../../../core/theme/open_vts_spacing.dart';
import '../../../../../../core/theme/open_vts_typography.dart';
import '../../../../../../core/utils/date_time_formatter.dart';
import '../../../../../../shared/helpers/toast_helper.dart';
import '../../../../../../shared/widgets/open_vts_button.dart';
import '../../../../../../shared/widgets/open_vts_text_field.dart';
import '../../../../controllers/user_driver_details_controller.dart';
import '../../../../models/user_driver_model.dart';
import '../../../../models/user_drivers_state.dart';

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

class UserDriverDocumentSheet extends ConsumerStatefulWidget {
  const UserDriverDocumentSheet({
    required this.provider,
    this.document,
    super.key,
  });

  final AutoDisposeStateNotifierProvider<UserDriverDetailsController,
      UserDriverDetailsState> provider;
  final UserDriverDocument? document;

  @override
  ConsumerState<UserDriverDocumentSheet> createState() =>
      _UserDriverDocumentSheetState();
}

class _UserDriverDocumentSheetState
    extends ConsumerState<UserDriverDocumentSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _tagsController = TextEditingController();
  final _descriptionController = TextEditingController();

  String? _docTypeId;
  DateTime? _expiryAt;
  bool _isVisible = true;
  bool _isVisibleDriver = false;
  PlatformFile? _file;
  var _isPicking = false;
  var _fileError = false;
  var _tags = const <String>[];

  bool get _isEdit => widget.document != null;

  @override
  void initState() {
    super.initState();
    final document = widget.document;
    if (document != null) {
      _titleController.text = document.title;
      _tagsController.text = document.tags.join(', ');
      _descriptionController.text = document.description;
      _docTypeId = document.docTypeId.isEmpty ? null : document.docTypeId;
      _expiryAt = document.expiryAt;
      _isVisible = document.isVisible;
      _isVisibleDriver = document.isVisibleDriver;
    }
    _tags = _parseTags(_tagsController.text);
    _tagsController.addListener(_refreshTags);
  }

  @override
  void dispose() {
    _tagsController.removeListener(_refreshTags);
    _titleController.dispose();
    _tagsController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(widget.provider);
    final docTypes = state.documentTypes
        .where((type) => type.docFor.isEmpty || type.isForDriver)
        .toList(growable: false);
    final isSubmitting = state.isUploadingDocument;

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
                    types: docTypes,
                    isLoading: state.isLoadingDocuments,
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
                    existingFileName: widget.document?.fileName,
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
                    hintText: 'license, identity, permit',
                    prefixIcon: Icons.label_outline_rounded,
                    textInputAction: TextInputAction.next,
                  ),
                  if (_tags.isNotEmpty) ...[
                    const SizedBox(height: OpenVtsSpacing.xs),
                    Wrap(
                      spacing: OpenVtsSpacing.xs,
                      runSpacing: OpenVtsSpacing.xs,
                      children: [
                        for (final tag in _tags)
                          _TagChip(
                            label: tag,
                            onDelete: () => _removeTag(tag),
                          ),
                      ],
                    ),
                  ],
                  const SizedBox(height: OpenVtsSpacing.sm),
                  OpenVtsTextField(
                    label: 'Notes / Description',
                    controller: _descriptionController,
                    hintText: 'Optional notes',
                    prefixIcon: Icons.notes_rounded,
                    maxLines: 3,
                  ),
                  const SizedBox(height: OpenVtsSpacing.sm),
                  _VisibilityToggle(
                    title: 'Visible',
                    subtitle: _isVisible
                        ? 'Visible in user documents'
                        : 'Hidden from user documents',
                    icon: _isVisible
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    value: _isVisible,
                    onChanged: (value) => setState(() => _isVisible = value),
                  ),
                  const SizedBox(height: OpenVtsSpacing.sm),
                  _VisibilityToggle(
                    title: 'Visible To Driver',
                    subtitle: _isVisibleDriver
                        ? 'Driver can see this document'
                        : 'Driver cannot see this document',
                    icon: _isVisibleDriver
                        ? Icons.shield_outlined
                        : Icons.person_off_outlined,
                    value: _isVisibleDriver,
                    onChanged: (value) {
                      setState(() => _isVisibleDriver = value);
                    },
                  ),
                  if (state.errorMessage != null) ...[
                    const SizedBox(height: OpenVtsSpacing.sm),
                    _InlineError(message: state.errorMessage!),
                  ],
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

  void _refreshTags() {
    if (!mounted) {
      return;
    }
    final next = _parseTags(_tagsController.text);
    if (_listEquals(next, _tags)) {
      return;
    }
    setState(() => _tags = next);
  }

  void _removeTag(String tag) {
    final next = _tags.where((item) => item != tag).toList(growable: false);
    _tagsController.text = next.join(', ');
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
    FocusScope.of(context).unfocus();

    final formOk = _formKey.currentState?.validate() ?? false;
    final needsFile = !_isEdit && _file == null;
    if (needsFile) {
      setState(() => _fileError = true);
    }

    if (!formOk || needsFile) {
      return;
    }

    final request = UserDriverDocumentMutationRequest(
      file: _file,
      fileName: _file?.name ?? (_isEdit ? widget.document?.fileName : null),
      title: _titleController.text.trim(),
      docTypeId: _docTypeId,
      description: _descriptionController.text.trim(),
      tags: _parseTags(_tagsController.text),
      expiryAt: _expiryAt == null ? null : _formatYmd(_expiryAt!),
      isVisible: _isVisible,
      isVisibleDriver: _isVisibleDriver,
    );

    final controller = ref.read(widget.provider.notifier);
    final document = widget.document;
    final result = document == null
        ? await controller.uploadDocument(request)
        : await controller.updateDocument(docId: document.id, request: request);

    if (!mounted) {
      return;
    }

    if (result != null) {
      ToastHelper.showSuccess(
        document == null ? 'Document uploaded.' : 'Document updated.',
        context: context,
      );
      Navigator.of(context).pop(true);
      return;
    }

    ToastHelper.showError(
      ref.read(widget.provider).errorMessage ??
          (document == null
              ? 'Unable to upload document.'
              : 'Unable to update document.'),
      context: context,
    );
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
  final List<UserDriverDocumentType> types;
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
          hint: Text(isLoading ? 'Loading driver types' : 'Select type'),
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
  const _VisibilityToggle({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final IconData icon;
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
          Icon(icon, size: 18, color: OpenVtsColors.textSecondary),
          const SizedBox(width: OpenVtsSpacing.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: OpenVtsTypography.label.copyWith(
                    color: OpenVtsColors.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
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

class _TagChip extends StatelessWidget {
  const _TagChip({required this.label, required this.onDelete});

  final String label;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return InputChip(
      label: Text(
        label,
        style: OpenVtsTypography.meta.copyWith(fontWeight: FontWeight.w700),
      ),
      onDeleted: onDelete,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
      side: const BorderSide(color: OpenVtsColors.border),
      backgroundColor: OpenVtsColors.surface,
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

String _dateText(DateTime? value) {
  if (value == null) return '-';
  return _dateFormatter.formatDate(value.toLocal());
}

String _formatYmd(DateTime value) {
  final year = value.year.toString().padLeft(4, '0');
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}

String _extensionFromName(String value) {
  final normalized = value.trim();
  final dot = normalized.lastIndexOf('.');
  if (dot < 0 || dot >= normalized.length - 1) return '';
  return normalized.substring(dot + 1);
}

List<String> _parseTags(String value) {
  return value
      .split(',')
      .map((tag) => tag.trim())
      .where((tag) => tag.isNotEmpty)
      .toSet()
      .toList(growable: false);
}

bool _listEquals(List<String> left, List<String> right) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
}
