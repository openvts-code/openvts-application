import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../../core/providers/core_providers.dart';
import '../../../../../../core/theme/open_vts_colors.dart';
import '../../../../../../core/theme/open_vts_radius.dart';
import '../../../../../../core/theme/open_vts_spacing.dart';
import '../../../../../../core/theme/open_vts_typography.dart';
import '../../../../../../core/utils/date_time_formatter.dart';
import '../../../../../../shared/helpers/toast_helper.dart';
import '../../../../../../shared/widgets/open_vts_bottom_sheet.dart';
import '../../../../../../shared/widgets/open_vts_button.dart';
import '../../../../../../shared/widgets/open_vts_card.dart';
import '../../../../../../shared/widgets/open_vts_empty_state.dart';
import '../../../../controllers/user_driver_details_controller.dart';
import '../../../../models/user_driver_model.dart';
import '../../../../models/user_drivers_state.dart';
import 'user_driver_document_sheet.dart';

const DateTimeFormatter _dateFormatter = DateTimeFormatter();

class UserDriverDocumentsTab extends ConsumerWidget {
  const UserDriverDocumentsTab({required this.provider, super.key});

  final AutoDisposeStateNotifierProvider<UserDriverDetailsController,
      UserDriverDetailsState> provider;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(provider);
    final controller = ref.read(provider.notifier);
    final baseUrl = ref.watch(apiBaseUrlProvider);
    final isInitialLoading =
        state.isLoadingDocuments && state.documents.isEmpty;

    if (isInitialLoading) {
      return const _LoadingCard(label: 'Loading documents');
    }

    if (state.errorMessage != null && state.documents.isEmpty) {
      return _ErrorCard(
        message: state.errorMessage!,
        onRetry: controller.loadDocuments,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SummaryCard(
          documentCount: state.documents.length,
          typeCount: state.documentTypes.length,
          isLoading: state.isLoadingDocuments,
          isUploading: state.isUploadingDocument,
          onUpload: state.isUploadingDocument
              ? null
              : () => _showDocumentSheet(context, null),
        ),
        if (state.errorMessage != null) ...[
          const SizedBox(height: OpenVtsSpacing.sm),
          _InlineError(message: state.errorMessage!),
        ],
        const SizedBox(height: OpenVtsSpacing.sm),
        if (state.documents.isEmpty)
          _EmptyDocumentsCard(onUpload: () => _showDocumentSheet(context, null))
        else
          for (final document in state.documents) ...[
            _DocumentCard(
              document: document,
              isBusy: state.isUploadingDocument,
              onView: () => _openDocument(context, baseUrl, document),
              onEdit: () => _showDocumentSheet(context, document),
              onDelete: state.isUploadingDocument
                  ? null
                  : () => _confirmDeleteDocument(context, ref, document),
            ),
            if (document != state.documents.last)
              const SizedBox(height: OpenVtsSpacing.sm),
          ],
      ],
    );
  }

  Future<void> _showDocumentSheet(
    BuildContext context,
    UserDriverDocument? document,
  ) {
    return OpenVtsBottomSheet.show<bool>(
      context: context,
      title: document == null ? 'Upload Document' : 'Edit Document',
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.96,
      child: UserDriverDocumentSheet(
        provider: provider,
        document: document,
      ),
    );
  }

  Future<void> _openDocument(
    BuildContext context,
    String baseUrl,
    UserDriverDocument document,
  ) async {
    final url = _resolveDocumentUrl(document, baseUrl);
    if (url == null) {
      ToastHelper.showError('File URL is not available.', context: context);
      return;
    }

    try {
      final launched = await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
      if (!context.mounted) {
        return;
      }
      if (!launched) {
        ToastHelper.showError('Could not open file.', context: context);
      }
    } catch (_) {
      if (context.mounted) {
        ToastHelper.showError('Could not open file.', context: context);
      }
    }
  }

  Future<void> _confirmDeleteDocument(
    BuildContext context,
    WidgetRef ref,
    UserDriverDocument document,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete document'),
        content: const Text('Delete this document?'),
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

    if (confirmed != true || !context.mounted) {
      return;
    }

    final ok = await ref.read(provider.notifier).deleteDocument(document.id);
    if (!context.mounted) {
      return;
    }

    if (ok) {
      ToastHelper.showSuccess('Document deleted.', context: context);
      return;
    }

    ToastHelper.showError(
      ref.read(provider).errorMessage ?? 'Unable to delete document.',
      context: context,
    );
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
      padding: const EdgeInsets.all(OpenVtsSpacing.sm),
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
                  '$documentCount files - $typeCount document types',
                  style: OpenVtsTypography.meta.copyWith(
                    color: OpenVtsColors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: OpenVtsSpacing.sm),
          SizedBox(
            width: 150,
            height: 34,
            child: OpenVtsButton(
              label: 'Upload',
              height: 34,
              isLoading: isUploading,
              trailingIcon: Icons.upload_file_rounded,
              onPressed: onUpload,
            ),
          ),
        ],
      ),
    );
  }
}

class _DocumentCard extends StatelessWidget {
  const _DocumentCard({
    required this.document,
    required this.isBusy,
    required this.onView,
    required this.onEdit,
    required this.onDelete,
  });

  final UserDriverDocument document;
  final bool isBusy;
  final VoidCallback onView;
  final VoidCallback onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final extension = _fileExtension(document);

    return OpenVtsCard(
      onTap: onView,
      padding: const EdgeInsets.all(OpenVtsSpacing.sm),
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
                      _display(document.docTypeName),
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
                enabled: !isBusy,
                icon: isBusy
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
            label: _display(document.fileName),
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
                icon: document.isVisibleDriver
                    ? Icons.shield_outlined
                    : Icons.person_off_outlined,
                label: document.isVisibleDriver
                    ? 'Visible to Driver'
                    : 'Hidden from Driver',
                color: document.isVisibleDriver
                    ? OpenVtsColors.brandInk
                    : OpenVtsColors.textTertiary,
              ),
              _MetaPill(
                icon: Icons.calendar_today_outlined,
                label: 'Added ${_dateText(document.createdAt)}',
              ),
              for (final tag in document.tags.take(4))
                _MetaPill(icon: Icons.label_outline_rounded, label: tag),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyDocumentsCard extends StatelessWidget {
  const _EmptyDocumentsCard({required this.onUpload});

  final VoidCallback onUpload;

  @override
  Widget build(BuildContext context) {
    return OpenVtsCard(
      padding: const EdgeInsets.all(OpenVtsSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const OpenVtsEmptyState(
            title: 'No documents uploaded',
            message: 'Upload driver files like license or identity proofs.',
          ),
          const SizedBox(height: OpenVtsSpacing.sm),
          OpenVtsButton(
            label: 'Upload Document',
            height: 38,
            trailingIcon: Icons.upload_file_rounded,
            onPressed: onUpload,
          ),
        ],
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return OpenVtsCard(
      padding: const EdgeInsets.all(OpenVtsSpacing.sm),
      child: Row(
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: OpenVtsSpacing.sm),
          Text(
            label,
            style: OpenVtsTypography.meta.copyWith(
              color: OpenVtsColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return OpenVtsCard(
      padding: const EdgeInsets.all(OpenVtsSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            message,
            style: OpenVtsTypography.meta.copyWith(
              color: OpenVtsColors.error,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: OpenVtsSpacing.sm),
          OpenVtsButton(
            label: 'Retry',
            height: 36,
            variant: OpenVtsButtonVariant.secondary,
            onPressed: onRetry,
          ),
        ],
      ),
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
      constraints: const BoxConstraints(maxWidth: 260),
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
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: OpenVtsTypography.meta.copyWith(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
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

enum _DocumentAction { view, edit, delete }

String? _resolveDocumentUrl(UserDriverDocument document, String baseUrl) {
  final fileUrl = document.fileUrl.trim();
  if (fileUrl.isNotEmpty) {
    return _resolveFilePath(fileUrl, baseUrl);
  }

  final filePath = document.filePath.trim();
  if (filePath.isNotEmpty) {
    return _resolveFilePath(filePath, baseUrl);
  }

  return null;
}

String? _resolveFilePath(String raw, String baseUrl) {
  final normalized = raw.trim();
  if (normalized.isEmpty) return null;
  if (normalized.startsWith('http://') || normalized.startsWith('https://')) {
    return normalized;
  }
  final resolvedBase = baseUrl.trim().replaceAll(RegExp(r'/+$'), '');
  if (resolvedBase.isEmpty) return normalized;
  if (normalized.startsWith('/')) return '$resolvedBase$normalized';
  return '$resolvedBase/$normalized';
}

String _documentTitle(UserDriverDocument document) {
  for (final value in [document.title, document.fileName]) {
    final normalized = value.trim();
    if (normalized.isNotEmpty && normalized != '-') return normalized;
  }
  return 'Document';
}

String _fileExtension(UserDriverDocument document) {
  for (final value in [document.fileName, document.filePath]) {
    final extension = _extensionFromName(value);
    if (extension.isNotEmpty) return extension.toUpperCase();
  }
  final fileType = document.fileType.trim();
  if (fileType.contains('/')) return fileType.split('/').last.toUpperCase();
  return fileType.toUpperCase();
}

String _extensionFromName(String value) {
  final normalized = value.trim();
  final dot = normalized.lastIndexOf('.');
  if (dot < 0 || dot >= normalized.length - 1) return '';
  return normalized.substring(dot + 1);
}

String _dateText(DateTime? value) {
  if (value == null) return '-';
  return _dateFormatter.formatDate(value.toLocal());
}

String _display(String value) {
  final normalized = value.trim();
  if (normalized.isEmpty || normalized == '-') return '-';
  return normalized;
}
