import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../core/config/app_config.dart';
import '../../../../../core/theme/open_vts_colors.dart';
import '../../../../../core/theme/open_vts_spacing.dart';
import '../../../../../core/theme/open_vts_typography.dart';
import '../../../../../core/utils/date_time_formatter.dart';
import '../../../../../shared/helpers/toast_helper.dart';
import '../../../../../shared/widgets/open_vts_card.dart';
import '../../../../../shared/widgets/open_vts_empty_state.dart';
import '../../../../../shared/widgets/open_vts_error_view.dart';
import '../../../../../shared/widgets/open_vts_loader.dart';
import '../../../controllers/admin_driver_details_controller.dart';
import '../../../models/admin_driver_details_model.dart';
import '../../../models/admin_driver_details_state.dart';
import 'admin_driver_document_sheet.dart';

class AdminDriverDocumentsTab extends ConsumerWidget {
  const AdminDriverDocumentsTab({
    required this.provider,
    required this.state,
    super.key,
  });

  final AutoDisposeStateNotifierProvider<AdminDriverDetailsController,
      AdminDriverDetailsState> provider;
  final AdminDriverDetailsState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(provider.notifier);

    if (state.isLoadingDocuments && state.documents.isEmpty) {
      return const OpenVtsCard(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: OpenVtsSpacing.md),
          child: OpenVtsLoader(),
        ),
      );
    }

    if (state.sectionErrorMessage != null && state.documents.isEmpty) {
      return OpenVtsErrorView(
        message: state.sectionErrorMessage!,
        onRetry: controller.loadDocuments,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton.icon(
          onPressed: state.isUploadingDocument
              ? null
              : () => showDriverDocumentSheet(
                    context: context,
                    provider: provider,
                    driverId: state.driverId,
                    documentTypes: state.documentTypes,
                  ),
          icon: const Icon(Icons.upload_file_rounded, size: 16),
          label: const Text('Upload Document'),
        ),
        const SizedBox(height: OpenVtsSpacing.sm),
        if (state.documents.isEmpty)
          const OpenVtsEmptyState(
            title: 'No driver documents',
            message: 'Upload a document to get started.',
          )
        else
          ...state.documents.map(
            (doc) => Padding(
              padding: const EdgeInsets.only(bottom: OpenVtsSpacing.xs),
              child: _DocCard(
                doc: doc,
                onView: () => _openFile(context, doc),
                onEdit: () => showDriverDocumentSheet(
                  context: context,
                  provider: provider,
                  driverId: state.driverId,
                  existing: doc,
                  documentTypes: state.documentTypes,
                ),
                onDelete: () async {
                  final yes = await showDialog<bool>(
                    context: context,
                    builder: (dCtx) => AlertDialog(
                      title: const Text('Delete document'),
                      content: Text('Delete ${doc.title}?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(dCtx).pop(false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(dCtx).pop(true),
                          style: TextButton.styleFrom(
                            foregroundColor: OpenVtsColors.error,
                          ),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );
                  if (yes != true) return;
                  final ok = await controller.deleteDocument(doc.id);
                  if (!context.mounted) return;
                  if (ok) {
                    ToastHelper.showSuccess(
                      'Document deleted.',
                      context: context,
                    );
                  } else {
                    ToastHelper.showError(
                      ref.read(provider).sectionErrorMessage ??
                          'Unable to delete document.',
                      context: context,
                    );
                  }
                },
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _openFile(BuildContext context, AdminDriverDocument doc) async {
    final path = doc.fileUrl.trim().isNotEmpty
        ? doc.fileUrl.trim()
        : doc.filePath.trim();
    if (path.isEmpty) {
      ToastHelper.showError('No file available.', context: context);
      return;
    }

    final url = path.startsWith('http://') || path.startsWith('https://')
        ? path
        : '${AppConfig.apiBaseUrl.replaceAll(RegExp(r'/+$'), '')}${path.startsWith('/') ? path : '/$path'}';
    try {
      final ok = await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
      if (!ok && context.mounted) {
        ToastHelper.showError('Unable to open file.', context: context);
      }
    } catch (_) {
      if (context.mounted) {
        ToastHelper.showError('Unable to open file.', context: context);
      }
    }
  }
}

class _DocCard extends StatelessWidget {
  const _DocCard({
    required this.doc,
    required this.onView,
    required this.onEdit,
    required this.onDelete,
  });

  final AdminDriverDocument doc;
  final VoidCallback onView;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final f = const DateTimeFormatter();
    return OpenVtsCard(
      padding: const EdgeInsets.all(OpenVtsSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  doc.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: OpenVtsTypography.label.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              PopupMenuButton<_DocAction>(
                onSelected: (value) {
                  switch (value) {
                    case _DocAction.view:
                      onView();
                      break;
                    case _DocAction.edit:
                      onEdit();
                      break;
                    case _DocAction.delete:
                      onDelete();
                      break;
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: _DocAction.view,
                    child: Text('View/Download'),
                  ),
                  PopupMenuItem(value: _DocAction.edit, child: Text('Edit')),
                  PopupMenuItem(
                    value: _DocAction.delete,
                    child: Text('Delete'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: OpenVtsSpacing.xxs),
          Text('Type: ${doc.docTypeName}', style: OpenVtsTypography.meta),
          Text('Status: ${doc.status}', style: OpenVtsTypography.meta),
          Text('File: ${doc.fileName}', style: OpenVtsTypography.meta),
          Text(
            'Uploaded: ${doc.createdAt == null ? '-' : f.formatDate(doc.createdAt!)}',
            style: OpenVtsTypography.meta,
          ),
          Text(
            'Expiry: ${doc.expiryAt == null ? '-' : f.formatDate(doc.expiryAt!)}',
            style: OpenVtsTypography.meta,
          ),
          Text(
            'Visibility: ${doc.isVisible ? 'Visible' : 'Hidden'}',
            style: OpenVtsTypography.meta,
          ),
        ],
      ),
    );
  }
}

enum _DocAction { view, edit, delete }
