import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/open_vts_spacing.dart';
import '../../../../../shared/helpers/toast_helper.dart';
import '../../../../../shared/widgets/open_vts_bottom_sheet.dart';
import '../../../../../shared/widgets/open_vts_button.dart';
import '../../../../../shared/widgets/open_vts_text_field.dart';
import '../../../controllers/admin_driver_details_controller.dart';
import '../../../models/admin_driver_details_model.dart';
import '../../../models/admin_driver_details_state.dart';

Future<void> showDriverDocumentSheet({
  required BuildContext context,
  required AutoDisposeStateNotifierProvider<AdminDriverDetailsController,
          AdminDriverDetailsState>
      provider,
  required String driverId,
  required List<AdminDriverDocumentType> documentTypes,
  AdminDriverDocument? existing,
}) {
  return OpenVtsBottomSheet.show<void>(
    context: context,
    title: existing == null ? 'Upload Document' : 'Edit Document',
    initialChildSize: 0.88,
    minChildSize: 0.45,
    maxChildSize: 0.96,
    child: _DriverDocumentSheet(
      provider: provider,
      driverId: driverId,
      documentTypes: documentTypes,
      existing: existing,
    ),
  );
}

class _DriverDocumentSheet extends ConsumerStatefulWidget {
  const _DriverDocumentSheet({
    required this.provider,
    required this.driverId,
    required this.documentTypes,
    required this.existing,
  });

  final AutoDisposeStateNotifierProvider<AdminDriverDetailsController,
      AdminDriverDetailsState> provider;
  final String driverId;
  final List<AdminDriverDocumentType> documentTypes;
  final AdminDriverDocument? existing;

  @override
  ConsumerState<_DriverDocumentSheet> createState() =>
      _DriverDocumentSheetState();
}

class _DriverDocumentSheetState extends ConsumerState<_DriverDocumentSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _docTypeId;
  late final TextEditingController _tags;
  late final TextEditingController _description;
  late final TextEditingController _expiryAt;
  bool _isVisible = true;
  PlatformFile? _file;

  @override
  void initState() {
    super.initState();
    final ex = widget.existing;
    _title = TextEditingController(
      text: ex?.title == '-' ? '' : (ex?.title ?? ''),
    );
    _docTypeId = TextEditingController(
      text: ex?.docTypeId == '-' ? '' : (ex?.docTypeId ?? ''),
    );
    _tags = TextEditingController(
      text: ex?.tags == '-' ? '' : (ex?.tags ?? ''),
    );
    _description = TextEditingController(
      text: ex?.description == '-' ? '' : (ex?.description ?? ''),
    );
    _expiryAt = TextEditingController(
      text: ex?.expiryAt?.toIso8601String().split('T').first ?? '',
    );
    _isVisible = ex?.isVisible ?? true;
  }

  @override
  void dispose() {
    _title.dispose();
    _docTypeId.dispose();
    _tags.dispose();
    _description.dispose();
    _expiryAt.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(widget.provider);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(OpenVtsSpacing.md),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.documentTypes.isNotEmpty)
              Text(
                'Types: ${widget.documentTypes.map((e) => '${e.id}:${e.name}').join(' | ')}',
                style: const TextStyle(fontSize: 11),
              ),
            const SizedBox(height: OpenVtsSpacing.xs),
            OpenVtsTextField(
              label: 'Title',
              controller: _title,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Title is required' : null,
            ),
            const SizedBox(height: OpenVtsSpacing.sm),
            OpenVtsTextField(
              label: 'Document Type ID',
              controller: _docTypeId,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'docTypeId is required'
                  : null,
            ),
            const SizedBox(height: OpenVtsSpacing.sm),
            OpenVtsTextField(label: 'Tags', controller: _tags),
            const SizedBox(height: OpenVtsSpacing.sm),
            OpenVtsTextField(
              label: 'Description',
              controller: _description,
              maxLines: 3,
            ),
            const SizedBox(height: OpenVtsSpacing.sm),
            OpenVtsTextField(
              label: 'Expiry Date (YYYY-MM-DD)',
              controller: _expiryAt,
            ),
            const SizedBox(height: OpenVtsSpacing.sm),
            SwitchListTile.adaptive(
              value: _isVisible,
              onChanged: (value) => setState(() => _isVisible = value),
              contentPadding: EdgeInsets.zero,
              title: const Text('Visible'),
            ),
            const SizedBox(height: OpenVtsSpacing.xs),
            OutlinedButton.icon(
              onPressed: () async {
                final result = await FilePicker.platform.pickFiles(
                  withData: true,
                );
                if (result != null && result.files.isNotEmpty) {
                  setState(() {
                    _file = result.files.first;
                  });
                }
              },
              icon: const Icon(Icons.attach_file_rounded, size: 16),
              label: Text(_file == null ? 'Select File' : _file!.name),
            ),
            const SizedBox(height: OpenVtsSpacing.sm),
            OpenVtsButton(
              label: widget.existing == null ? 'Upload' : 'Save Changes',
              isLoading: state.isUploadingDocument,
              onPressed: state.isUploadingDocument ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (widget.existing == null && _file == null) {
      ToastHelper.showError('File is required.', context: context);
      return;
    }

    final expiry = _expiryAt.text.trim().isEmpty
        ? null
        : DateTime.tryParse(_expiryAt.text.trim());
    final request = AdminDriverDocumentUpsertRequest(
      driverId: widget.driverId,
      title: _title.text,
      docTypeId: _docTypeId.text,
      isVisible: _isVisible,
      tags: _tags.text,
      description: _description.text,
      expiryAt: expiry,
      file: _file,
    );

    final notifier = ref.read(widget.provider.notifier);
    final ok = widget.existing == null
        ? await notifier.uploadDocument(request)
        : await notifier.updateDocument(
            docId: widget.existing!.id,
            request: request,
          );
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop();
      ToastHelper.showSuccess(
        widget.existing == null ? 'Document uploaded.' : 'Document updated.',
        context: context,
      );
    } else {
      ToastHelper.showError(
        ref.read(widget.provider).sectionErrorMessage ??
            'Unable to save document.',
        context: context,
      );
    }
  }
}
