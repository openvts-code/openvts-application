import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../../../core/theme/open_vts_spacing.dart';
import '../../../../../shared/widgets/open_vts_button.dart';
import '../../../models/admin_vehicle_model.dart';

class AdminVehicleDocumentSheet extends StatefulWidget {
  const AdminVehicleDocumentSheet({
    super.key,
    required this.vehicleId,
    required this.docTypes,
    required this.isSubmitting,
    required this.onSubmit,
    this.initial,
  });

  final String vehicleId;
  final List<AdminVehicleDocumentType> docTypes;
  final bool isSubmitting;
  final AdminVehicleDocument? initial;
  final Future<void> Function(AdminVehicleDocumentRequest request) onSubmit;

  @override
  State<AdminVehicleDocumentSheet> createState() =>
      _AdminVehicleDocumentSheetState();
}

class _AdminVehicleDocumentSheetState extends State<AdminVehicleDocumentSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _tagsController;
  late final TextEditingController _descriptionController;

  String? _docTypeId;
  bool _isVisible = true;
  DateTime? _expiryAt;
  PlatformFile? _file;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initial?.title ?? '');
    _tagsController = TextEditingController(text: widget.initial?.tags ?? '');
    _descriptionController =
        TextEditingController(text: widget.initial?.description ?? '');
    _docTypeId = widget.initial?.docTypeId;
    _isVisible = widget.initial?.isVisible ?? true;
    _expiryAt = widget.initial?.expiryAt;
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
    return ListView(
      padding: const EdgeInsets.all(OpenVtsSpacing.md),
      children: [
        Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (v) =>
                    (v ?? '').trim().isEmpty ? 'Title required' : null,
              ),
              const SizedBox(height: OpenVtsSpacing.sm),
              DropdownButtonFormField<String>(
                initialValue: _docTypeId,
                hint: const Text('Document type'),
                items: widget.docTypes
                    .map((type) => DropdownMenuItem<String>(
                          value: type.id,
                          child: Text(type.name),
                        ))
                    .toList(growable: false),
                onChanged: (value) => setState(() => _docTypeId = value),
                validator: (v) =>
                    (v ?? '').trim().isEmpty ? 'Document type required' : null,
              ),
              const SizedBox(height: OpenVtsSpacing.sm),
              SwitchListTile(
                value: _isVisible,
                onChanged: (v) => setState(() => _isVisible = v),
                title: const Text('Visible to user'),
              ),
              const SizedBox(height: OpenVtsSpacing.sm),
              TextFormField(
                controller: _tagsController,
                decoration:
                    const InputDecoration(labelText: 'Tags (comma separated)'),
              ),
              const SizedBox(height: OpenVtsSpacing.sm),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              const SizedBox(height: OpenVtsSpacing.sm),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Expiry date'),
                subtitle: Text(_expiryAt == null ? '-' : _fmtDate(_expiryAt!)),
                trailing: TextButton(
                  onPressed: _pickExpiry,
                  child: const Text('Select'),
                ),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('File'),
                subtitle: Text(_file?.name ??
                    widget.initial?.fileName ??
                    'No file selected'),
                trailing: TextButton(
                  onPressed: _pickFile,
                  child: const Text('Choose'),
                ),
              ),
              const SizedBox(height: OpenVtsSpacing.sm),
              OpenVtsButton(
                label: widget.initial == null
                    ? 'Upload Document'
                    : 'Save Document',
                isLoading: widget.isSubmitting,
                onPressed: widget.isSubmitting ? null : _submit,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _pickExpiry() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _expiryAt ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 30),
    );
    if (selected == null) return;
    setState(() => _expiryAt = selected);
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(withData: true);
    if (result == null || result.files.isEmpty) return;
    setState(() => _file = result.files.first);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (widget.initial == null && _file == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('File is required.')),
      );
      return;
    }

    await widget.onSubmit(
      AdminVehicleDocumentRequest(
        title: _titleController.text.trim(),
        docTypeId: _docTypeId!.trim(),
        vehicleId: widget.vehicleId,
        isVisible: _isVisible,
        tags: _tagsController.text.trim(),
        description: _descriptionController.text.trim(),
        expiryAt: _expiryAt,
        file: _file,
      ),
    );
  }

  String _fmtDate(DateTime value) {
    return '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
  }
}
