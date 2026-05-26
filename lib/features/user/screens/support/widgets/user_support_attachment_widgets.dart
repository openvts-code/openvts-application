import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:open_vts/core/theme/open_vts_colors.dart';
import 'package:open_vts/core/theme/open_vts_radius.dart';
import 'package:open_vts/core/theme/open_vts_spacing.dart';
import 'package:open_vts/core/theme/open_vts_typography.dart';
import 'package:open_vts/features/user/models/user_support_constraints.dart';
import 'package:open_vts/features/user/models/user_support_model.dart';
import 'package:open_vts/shared/helpers/toast_helper.dart';
import 'package:url_launcher/url_launcher.dart';

Future<List<PlatformFile>?> pickUserSupportAttachments(
  BuildContext context, {
  required List<PlatformFile> existing,
  int maxCount = userSupportMaxAttachmentCount,
}) async {
  final remaining = maxCount - existing.length;
  if (remaining <= 0) {
    ToastHelper.showError(
      'You can upload up to $maxCount files.',
      context: context,
    );
    return existing;
  }

  final result = await FilePicker.platform.pickFiles(
    allowMultiple: true,
    withData: true,
    type: FileType.custom,
    allowedExtensions:
        userSupportAllowedAttachmentExtensions.toList(growable: false),
  );

  if (!context.mounted || result == null || result.files.isEmpty) {
    return null;
  }

  final merged = <PlatformFile>[...existing];
  final blocked = <String>[];
  final unsupported = <String>[];
  final oversized = <String>[];

  for (final file in result.files) {
    if (merged.length >= maxCount) {
      break;
    }

    final fileName = file.name.trim().isEmpty ? 'attachment' : file.name.trim();
    final extension = userSupportExtensionFromFileName(fileName);
    if (userSupportBlockedAttachmentExtensions.contains(extension)) {
      blocked.add(fileName);
      continue;
    }
    if (!userSupportAllowedAttachmentExtensions.contains(extension)) {
      unsupported.add(fileName);
      continue;
    }
    if (file.size > userSupportMaxAttachmentBytes) {
      oversized.add(fileName);
      continue;
    }

    final id = userSupportAttachmentIdentity(file);
    final exists =
        merged.any((item) => userSupportAttachmentIdentity(item) == id);
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

class UserSupportDraftAttachmentWrap extends StatelessWidget {
  const UserSupportDraftAttachmentWrap({
    required this.attachments,
    required this.onRemove,
    super.key,
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

class UserSupportMessageAttachmentWrap extends StatelessWidget {
  const UserSupportMessageAttachmentWrap({
    required this.attachments,
    required this.baseUrl,
    super.key,
  });

  final List<UserSupportTicketAttachment> attachments;
  final String baseUrl;

  @override
  Widget build(BuildContext context) {
    if (attachments.isEmpty) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: OpenVtsSpacing.xs,
      runSpacing: OpenVtsSpacing.xs,
      children: attachments
          .map(
            (attachment) => _UploadedAttachmentChip(
              attachment: attachment,
              baseUrl: baseUrl,
            ),
          )
          .toList(growable: false),
    );
  }
}

class _UploadedAttachmentChip extends StatelessWidget {
  const _UploadedAttachmentChip(
      {required this.attachment, required this.baseUrl});

  final UserSupportTicketAttachment attachment;
  final String baseUrl;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(OpenVtsRadius.md),
      onTap: () => _openAttachment(context),
      child: Container(
        constraints: const BoxConstraints(minHeight: 40, maxWidth: 240),
        padding: const EdgeInsets.symmetric(
          horizontal: OpenVtsSpacing.sm,
          vertical: OpenVtsSpacing.xs,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(OpenVtsRadius.md),
          border: Border.all(color: OpenVtsColors.border),
          color: OpenVtsColors.surface,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.insert_drive_file_outlined,
              size: 16,
              color: OpenVtsColors.textSecondary,
            ),
            const SizedBox(width: OpenVtsSpacing.xs),
            Flexible(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    attachment.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: OpenVtsTypography.meta.copyWith(
                      color: OpenVtsColors.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (attachment.sizeBytes > 0)
                    Text(
                      _formatFileSize(attachment.sizeBytes),
                      style: OpenVtsTypography.meta.copyWith(
                        color: OpenVtsColors.textTertiary,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openAttachment(BuildContext context) async {
    final path = attachment.filePath.trim();
    if (path.isEmpty) {
      ToastHelper.showError('Attachment path is not available.',
          context: context);
      return;
    }

    final resolved = _resolveAttachmentUrl(baseUrl, path);
    final uri = Uri.tryParse(resolved);
    if (uri == null) {
      ToastHelper.showError('Unable to open this attachment.',
          context: context);
      return;
    }

    try {
      final launched =
          await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && context.mounted) {
        ToastHelper.showError('Could not open attachment.', context: context);
      }
    } catch (_) {
      if (context.mounted) {
        ToastHelper.showError('Could not open attachment.', context: context);
      }
    }
  }
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

String _formatFileSize(int bytes) {
  if (bytes <= 0) {
    return '';
  }

  const units = <String>['B', 'KB', 'MB', 'GB'];
  var value = bytes.toDouble();
  var unitIndex = 0;

  while (value >= 1024 && unitIndex < units.length - 1) {
    value /= 1024;
    unitIndex++;
  }

  final decimals = value >= 10 || unitIndex == 0 ? 0 : 1;
  return '${value.toStringAsFixed(decimals)} ${units[unitIndex]}';
}

String _resolveAttachmentUrl(String baseUrl, String path) {
  final normalizedPath = path.trim();
  if (normalizedPath.startsWith('http://') ||
      normalizedPath.startsWith('https://')) {
    return normalizedPath;
  }

  final rootUri = Uri.tryParse(baseUrl);
  if (rootUri == null) {
    return normalizedPath;
  }

  var basePath = rootUri.path;
  if (basePath.isEmpty) {
    basePath = '/';
  }
  if (!basePath.endsWith('/')) {
    basePath = '$basePath/';
  }

  final apiRoot = rootUri.replace(
    path: basePath,
    queryParameters: null,
    fragment: null,
  );
  final relativePath = normalizedPath.startsWith('/')
      ? normalizedPath.substring(1)
      : normalizedPath;

  return apiRoot.resolve(relativePath).toString();
}
