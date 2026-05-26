import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../core/theme/open_vts_spacing.dart';
import '../../../../../shared/widgets/open_vts_bottom_sheet.dart';
import '../../../../../shared/widgets/open_vts_button.dart';
import '../../../../../shared/widgets/open_vts_card.dart';
import '../../../../../shared/widgets/open_vts_empty_state.dart';
import '../../../../../shared/widgets/open_vts_loader.dart';
import '../../../models/admin_vehicle_model.dart';
import 'admin_vehicle_document_sheet.dart';

class AdminVehicleDocumentsTab extends StatelessWidget {
  const AdminVehicleDocumentsTab({
    super.key,
    required this.vehicleId,
    required this.apiBaseUrl,
    required this.documents,
    required this.docTypes,
    required this.isLoading,
    required this.isUploading,
    required this.isUpdating,
    required this.isDeleting,
    required this.onLoad,
    required this.onUpload,
    required this.onUpdate,
    required this.onDelete,
  });

  final String vehicleId;
  final String apiBaseUrl;
  final List<AdminVehicleDocument> documents;
  final List<AdminVehicleDocumentType> docTypes;
  final bool isLoading;
  final bool isUploading;
  final bool isUpdating;
  final bool isDeleting;
  final Future<void> Function() onLoad;
  final Future<void> Function(AdminVehicleDocumentRequest request) onUpload;
  final Future<void> Function({
    required String docId,
    required AdminVehicleDocumentRequest request,
  }) onUpdate;
  final Future<void> Function(String docId) onDelete;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        OpenVtsCard(
          child: Align(
            alignment: Alignment.centerRight,
            child: OpenVtsButton(
              label: 'Upload Document',
              variant: OpenVtsButtonVariant.secondary,
              onPressed: () => _openDocumentSheet(context),
            ),
          ),
        ),
        const SizedBox(height: OpenVtsSpacing.sm),
        if (isLoading)
          const OpenVtsLoader()
        else if (documents.isEmpty)
          const OpenVtsEmptyState(
            title: 'No documents',
            message: 'Upload documents for this vehicle.',
          )
        else
          ...documents.map(
            (doc) => Padding(
              padding: const EdgeInsets.only(bottom: OpenVtsSpacing.sm),
              child: OpenVtsCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(doc.title,
                        style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: OpenVtsSpacing.xxs),
                    Text('Document type: ${_safe(doc.docTypeName)}'),
                    Text('File: ${_safe(doc.fileName)}'),
                    Text('Expiry: ${_date(doc.expiryAt)}'),
                    Text('Visibility: ${doc.isVisible ? 'Visible' : 'Hidden'}'),
                    Text('Tags: ${_safe(doc.tags)}'),
                    Text('Created: ${_date(doc.createdAt)}'),
                    const SizedBox(height: OpenVtsSpacing.sm),
                    Wrap(
                      spacing: OpenVtsSpacing.xs,
                      runSpacing: OpenVtsSpacing.xs,
                      children: [
                        OutlinedButton(
                          onPressed: () => _openFile(context, doc),
                          child: const Text('Open'),
                        ),
                        OutlinedButton(
                          onPressed: () =>
                              _openDocumentSheet(context, initial: doc),
                          child: const Text('Edit'),
                        ),
                        OutlinedButton(
                          onPressed: isDeleting
                              ? null
                              : () => _confirmDelete(context, doc),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _openDocumentSheet(BuildContext context,
      {AdminVehicleDocument? initial}) {
    return OpenVtsBottomSheet.show<void>(
      context: context,
      title: initial == null ? 'Upload Document' : 'Edit Document',
      initialChildSize: 0.86,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      child: AdminVehicleDocumentSheet(
        vehicleId: vehicleId,
        docTypes: docTypes,
        initial: initial,
        isSubmitting: initial == null ? isUploading : isUpdating,
        onSubmit: (request) async {
          if (initial == null) {
            await onUpload(request);
          } else {
            await onUpdate(docId: initial.id, request: request);
          }
          if (!context.mounted) return;
          await onLoad();
          if (!context.mounted) return;
          Navigator.of(context).pop();
        },
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, AdminVehicleDocument doc) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete document'),
        content: Text('Delete ${doc.title}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    await onDelete(doc.id);
    await onLoad();
  }

  Future<void> _openFile(BuildContext context, AdminVehicleDocument doc) async {
    final uri = _resolveFileUri(doc.url, apiBaseUrl);
    if (uri == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Document URL is unavailable.')),
      );
      return;
    }

    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open document.')),
      );
    }
  }

  Uri? _resolveFileUri(String filePath, String baseUrl) {
    final path = filePath.trim();
    if (path.isEmpty) return null;
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return Uri.tryParse(path);
    }
    final base = baseUrl.trim().replaceAll(RegExp(r'/+$'), '');
    final relative = path.startsWith('/') ? path : '/$path';
    return Uri.tryParse('$base$relative');
  }

  String _safe(String value) => value.trim().isEmpty ? '-' : value.trim();

  String _date(DateTime? value) {
    if (value == null) return '-';
    final local = value.toLocal();
    return '${local.year.toString().padLeft(4, '0')}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
  }
}
