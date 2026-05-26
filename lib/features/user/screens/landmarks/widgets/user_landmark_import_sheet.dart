import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../core/config/app_config.dart';
import '../../../../../core/theme/open_vts_colors.dart';
import '../../../../../core/theme/open_vts_radius.dart';
import '../../../../../core/theme/open_vts_spacing.dart';
import '../../../../../core/theme/open_vts_typography.dart';
import '../../../../../shared/helpers/toast_helper.dart';
import '../../../../../shared/widgets/open_vts_bottom_sheet.dart';
import '../../../../../shared/widgets/open_vts_button.dart';
import '../../../controllers/user_providers.dart';
import '../../../models/user_landmark_model.dart';
import '../../../utils/user_landmark_csv_parser.dart';

/// Compact bottom sheet for bulk CSV import of geofences / POIs / routes.
/// Flow: pick CSV → parse + validate → preview → upload via bulk-job
/// controller → poll real progress → show failed rows + CSV download link.
class UserLandmarkImportSheet {
  const UserLandmarkImportSheet._();

  static Future<void> show({
    required BuildContext context,
    required UserLandmarkEntityType entityType,
  }) {
    return OpenVtsBottomSheet.show<void>(
      context: context,
      title: 'Import ${_entityLabel(entityType)} CSV',
      initialChildSize: 0.78,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      draggableChildBuilder: (ctx, scrollController) {
        return _ImportBody(
          entityType: entityType,
          scrollController: scrollController,
        );
      },
    );
  }
}

class _ImportBody extends ConsumerStatefulWidget {
  const _ImportBody({
    required this.entityType,
    required this.scrollController,
  });

  final UserLandmarkEntityType entityType;
  final ScrollController scrollController;

  @override
  ConsumerState<_ImportBody> createState() => _ImportBodyState();
}

class _ImportBodyState extends ConsumerState<_ImportBody> {
  String? _fileName;
  UserLandmarkCsvParseResult? _parse;
  String? _parseError;

  Future<void> _pickFile() async {
    setState(() {
      _parseError = null;
    });
    try {
      final result = await FilePicker.platform.pickFiles(
        dialogTitle: 'Pick CSV',
        type: FileType.custom,
        allowedExtensions: const ['csv'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;
      final file = result.files.first;
      final bytes = file.bytes;
      if (bytes == null) {
        setState(() => _parseError = 'Could not read file contents.');
        return;
      }
      final text = utf8.decode(bytes, allowMalformed: true);
      final parsed = UserLandmarkCsvParser.parseForEntity(
        text,
        widget.entityType,
      );
      setState(() {
        _fileName = file.name;
        _parse = parsed;
      });
    } catch (e) {
      setState(() => _parseError = 'Failed to read CSV: $e');
    }
  }

  Future<void> _upload() async {
    final parse = _parse;
    if (parse == null || parse.validRows.isEmpty) return;
    try {
      await ref.read(userLandmarkBulkJobControllerProvider.notifier).start(
            CreateUserLandmarkBulkJobRequest(
              entityType: widget.entityType,
              rows: parse.validRows,
            ),
          );
      await _refreshOwnerList();
    } catch (_) {
      // Error surfaces through the controller's state; the UI displays it.
    }
  }

  Future<void> _refreshOwnerList() async {
    switch (widget.entityType) {
      case UserLandmarkEntityType.geofence:
        await ref.read(userGeofencesControllerProvider.notifier).refresh();
        break;
      case UserLandmarkEntityType.poi:
        await ref.read(userPoisControllerProvider.notifier).refresh();
        break;
      case UserLandmarkEntityType.route:
        await ref.read(userRoutesControllerProvider.notifier).refresh();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final jobState = ref.watch(userLandmarkBulkJobControllerProvider);
    final hasParse = _parse != null;
    final canUpload = hasParse &&
        _parse!.validRows.isNotEmpty &&
        !jobState.isUploading &&
        !jobState.isLoading;

    return ListView(
      controller: widget.scrollController,
      padding: const EdgeInsets.fromLTRB(
        OpenVtsSpacing.md,
        OpenVtsSpacing.sm,
        OpenVtsSpacing.md,
        OpenVtsSpacing.lg,
      ),
      children: [
        _TemplateRow(entityType: widget.entityType),
        const SizedBox(height: OpenVtsSpacing.sm),
        _PickerRow(
          fileName: _fileName,
          onPick: _pickFile,
          disabled: jobState.isUploading || jobState.isLoading,
        ),
        if (_parseError != null) ...[
          const SizedBox(height: OpenVtsSpacing.xs),
          Text(
            _parseError!,
            style: OpenVtsTypography.meta.copyWith(color: OpenVtsColors.error),
          ),
        ],
        if (hasParse) ...[
          const SizedBox(height: OpenVtsSpacing.sm),
          _ValidationSummary(parse: _parse!),
        ],
        const SizedBox(height: OpenVtsSpacing.md),
        OpenVtsButton(
          label: 'Upload ${_parse?.validRows.length ?? 0} rows',
          onPressed: canUpload ? _upload : null,
          isLoading: jobState.isUploading,
        ),
        if (jobState.job != null) ...[
          const SizedBox(height: OpenVtsSpacing.md),
          _JobProgress(state: jobState),
        ],
        if (jobState.errorMessage != null) ...[
          const SizedBox(height: OpenVtsSpacing.xs),
          Text(
            jobState.errorMessage!,
            style: OpenVtsTypography.meta.copyWith(color: OpenVtsColors.error),
          ),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------

class _TemplateRow extends StatelessWidget {
  const _TemplateRow({required this.entityType});

  final UserLandmarkEntityType entityType;

  @override
  Widget build(BuildContext context) {
    final header = UserLandmarkCsvParser.templateHeader(entityType).join(',');
    return Container(
      padding: const EdgeInsets.all(OpenVtsSpacing.sm),
      decoration: BoxDecoration(
        color: OpenVtsColors.surface,
        borderRadius: BorderRadius.circular(OpenVtsRadius.md),
        border: Border.all(color: OpenVtsColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.table_chart_outlined,
              size: 18, color: OpenVtsColors.brandInk),
          const SizedBox(width: OpenVtsSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CSV template',
                  style: OpenVtsTypography.label.copyWith(
                    color: OpenVtsColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  header,
                  style: OpenVtsTypography.meta.copyWith(
                    color: OpenVtsColors.textSecondary,
                    fontFamily: 'monospace',
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Copy header',
            iconSize: 18,
            color: OpenVtsColors.textSecondary,
            icon: const Icon(Icons.copy_outlined),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: header));
              if (!context.mounted) return;
              ToastHelper.showSuccess('Header copied', context: context);
            },
          ),
        ],
      ),
    );
  }
}

class _PickerRow extends StatelessWidget {
  const _PickerRow({
    required this.fileName,
    required this.onPick,
    required this.disabled,
  });

  final String? fileName;
  final VoidCallback onPick;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: OpenVtsSpacing.sm,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: OpenVtsColors.background,
              borderRadius: BorderRadius.circular(OpenVtsRadius.button),
              border: Border.all(color: OpenVtsColors.border),
            ),
            child: Text(
              fileName ?? 'No file selected',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: OpenVtsTypography.body.copyWith(
                color: fileName == null
                    ? OpenVtsColors.textTertiary
                    : OpenVtsColors.textPrimary,
              ),
            ),
          ),
        ),
        const SizedBox(width: OpenVtsSpacing.sm),
        OpenVtsButton(
          label: 'Pick CSV',
          onPressed: disabled ? null : onPick,
          variant: OpenVtsButtonVariant.secondary,
          trailingIcon: Icons.upload_file_outlined,
        ),
      ],
    );
  }
}

class _ValidationSummary extends StatelessWidget {
  const _ValidationSummary({required this.parse});

  final UserLandmarkCsvParseResult parse;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(OpenVtsSpacing.sm),
      decoration: BoxDecoration(
        color: OpenVtsColors.surface,
        borderRadius: BorderRadius.circular(OpenVtsRadius.md),
        border: Border.all(color: OpenVtsColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Pill(
                label: '${parse.validRows.length} valid',
                color: OpenVtsColors.success,
              ),
              const SizedBox(width: 6),
              _Pill(
                label: '${parse.invalidRows.length} invalid',
                color: parse.invalidRows.isEmpty
                    ? OpenVtsColors.textTertiary
                    : OpenVtsColors.warning,
              ),
            ],
          ),
          if (parse.invalidRows.isNotEmpty) ...[
            const SizedBox(height: OpenVtsSpacing.sm),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 140),
              child: ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: parse.invalidRows.length,
                separatorBuilder: (_, __) => const Divider(
                  height: 8,
                  color: OpenVtsColors.divider,
                ),
                itemBuilder: (_, i) {
                  final row = parse.invalidRows[i];
                  return Text(
                    'Row ${row.rowNumber}: ${row.error}',
                    style: OpenVtsTypography.meta.copyWith(
                      color: OpenVtsColors.textSecondary,
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _JobProgress extends ConsumerWidget {
  const _JobProgress({required this.state});

  final dynamic state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final UserLandmarkBulkJob job = state.job as UserLandmarkBulkJob;
    final progress = job.progress;
    return Container(
      padding: const EdgeInsets.all(OpenVtsSpacing.sm),
      decoration: BoxDecoration(
        color: OpenVtsColors.surface,
        borderRadius: BorderRadius.circular(OpenVtsRadius.md),
        border: Border.all(color: OpenVtsColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  job.status.label,
                  style: OpenVtsTypography.label.copyWith(
                    color: OpenVtsColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '${job.processed}/${job.total}',
                style: OpenVtsTypography.meta.copyWith(
                  color: OpenVtsColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(OpenVtsRadius.pill),
            child: LinearProgressIndicator(
              value: job.total > 0 ? progress : null,
              minHeight: 6,
              backgroundColor: OpenVtsColors.divider,
              valueColor: const AlwaysStoppedAnimation<Color>(
                OpenVtsColors.brandInk,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              _Pill(
                label: '${job.succeeded} ok',
                color: OpenVtsColors.success,
              ),
              const SizedBox(width: 6),
              _Pill(
                label: '${job.failed} failed',
                color: job.failed > 0
                    ? OpenVtsColors.error
                    : OpenVtsColors.textTertiary,
              ),
            ],
          ),
          if (job.failedRows.isNotEmpty) ...[
            const SizedBox(height: OpenVtsSpacing.sm),
            Text(
              'Failed rows',
              style: OpenVtsTypography.meta.copyWith(
                color: OpenVtsColors.textTertiary,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 4),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 140),
              child: ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: job.failedRows.length,
                separatorBuilder: (_, __) => const Divider(
                  height: 8,
                  color: OpenVtsColors.divider,
                ),
                itemBuilder: (_, i) {
                  final row = job.failedRows[i];
                  final prefix = row.index != null ? 'Row ${row.index}: ' : '';
                  return Text(
                    '$prefix${row.name.isEmpty ? "(unnamed)" : row.name}'
                    ' — ${row.errorMessage}',
                    style: OpenVtsTypography.meta.copyWith(
                      color: OpenVtsColors.textSecondary,
                    ),
                  );
                },
              ),
            ),
          ],
          if (job.failed > 0 && job.isTerminal) ...[
            const SizedBox(height: OpenVtsSpacing.sm),
            _FailedCsvButton(jobId: job.id),
          ],
        ],
      ),
    );
  }
}

class _FailedCsvButton extends ConsumerWidget {
  const _FailedCsvButton({required this.jobId});

  final String jobId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return OpenVtsButton(
      label: 'Open failed rows CSV',
      variant: OpenVtsButtonVariant.secondary,
      trailingIcon: Icons.open_in_new,
      onPressed: () async {
        final path = await ref
            .read(userLandmarkBulkJobControllerProvider.notifier)
            .failedCsvPath();
        if (path == null) return;
        final url = Uri.parse('${AppConfig.apiBaseUrl}$path');
        final ok = await launchUrl(
          url,
          mode: LaunchMode.externalApplication,
        );
        if (!ok && context.mounted) {
          ToastHelper.showError('Could not open URL', context: context);
        }
      },
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(OpenVtsRadius.pill),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: OpenVtsTypography.meta.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

String _entityLabel(UserLandmarkEntityType t) {
  switch (t) {
    case UserLandmarkEntityType.geofence:
      return 'Geofences';
    case UserLandmarkEntityType.poi:
      return 'POIs';
    case UserLandmarkEntityType.route:
      return 'Routes';
  }
}
