import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/open_vts_colors.dart';
import '../../../../../core/theme/open_vts_radius.dart';
import '../../../../../core/theme/open_vts_spacing.dart';
import '../../../../../core/theme/open_vts_typography.dart';
import '../../../../../shared/helpers/toast_helper.dart';
import '../../../../../shared/widgets/open_vts_bottom_sheet.dart';
import '../../../../../shared/widgets/open_vts_button.dart';
import '../../../../../shared/widgets/open_vts_empty_state.dart';
import '../../../controllers/user_providers.dart';
import '../../../models/user_landmark_model.dart';
import '../../../utils/user_landmark_kml_export.dart';

/// Compact bottom sheet that produces a KML export of the currently loaded
/// items for a given entity type and offers Save / Copy actions.
///
/// All data comes from the entity's controller — no service calls happen
/// here. Save uses `file_picker`'s native save dialog (already a project
/// dependency) so no extra package is required.
class UserLandmarkExportSheet {
  const UserLandmarkExportSheet._();

  static Future<void> show({
    required BuildContext context,
    required UserLandmarkEntityType entityType,
  }) {
    return OpenVtsBottomSheet.show<void>(
      context: context,
      title: 'Export ${_entityLabel(entityType)} as KML',
      initialChildSize: 0.62,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      draggableChildBuilder: (ctx, scrollController) {
        return _ExportBody(
          entityType: entityType,
          scrollController: scrollController,
        );
      },
    );
  }
}

class _ExportBody extends ConsumerWidget {
  const _ExportBody({
    required this.entityType,
    required this.scrollController,
  });

  final UserLandmarkEntityType entityType;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final _ExportPayload payload = _buildPayload(ref, entityType);

    if (payload.count == 0) {
      return ListView(
        controller: scrollController,
        padding: const EdgeInsets.all(OpenVtsSpacing.md),
        children: const [
          OpenVtsEmptyState(
            title: 'Nothing to export',
            message: 'Create at least one item before exporting.',
          ),
        ],
      );
    }

    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(
        OpenVtsSpacing.md,
        OpenVtsSpacing.sm,
        OpenVtsSpacing.md,
        OpenVtsSpacing.lg,
      ),
      children: [
        _SummaryRow(
          label: '${payload.count} ${_entityLabel(entityType).toLowerCase()}',
          fileName: payload.suggestedFileName,
        ),
        const SizedBox(height: OpenVtsSpacing.sm),
        _PreviewBox(content: payload.kml),
        const SizedBox(height: OpenVtsSpacing.md),
        _ActionRow(payload: payload),
      ],
    );
  }

  _ExportPayload _buildPayload(WidgetRef ref, UserLandmarkEntityType type) {
    switch (type) {
      case UserLandmarkEntityType.geofence:
        final items = ref.read(userGeofencesControllerProvider).geofences;
        return _ExportPayload(
          count: items.length,
          kml: UserLandmarkKmlExport.forGeofences(items),
          suggestedFileName: _fileName('geofences'),
        );
      case UserLandmarkEntityType.poi:
        final items = ref.read(userPoisControllerProvider).pois;
        return _ExportPayload(
          count: items.length,
          kml: UserLandmarkKmlExport.forPois(items),
          suggestedFileName: _fileName('pois'),
        );
      case UserLandmarkEntityType.route:
        final items = ref.read(userRoutesControllerProvider).routes;
        return _ExportPayload(
          count: items.length,
          kml: UserLandmarkKmlExport.forRoutes(items),
          suggestedFileName: _fileName('routes'),
        );
    }
  }

  static String _fileName(String slug) {
    final now = DateTime.now();
    String two(int v) => v.toString().padLeft(2, '0');
    return 'openvts_${slug}_'
        '${now.year}${two(now.month)}${two(now.day)}_'
        '${two(now.hour)}${two(now.minute)}.kml';
  }
}

class _ExportPayload {
  const _ExportPayload({
    required this.count,
    required this.kml,
    required this.suggestedFileName,
  });

  final int count;
  final String kml;
  final String suggestedFileName;
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.fileName});

  final String label;
  final String fileName;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: OpenVtsSpacing.sm,
        vertical: OpenVtsSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: OpenVtsColors.surface,
        borderRadius: BorderRadius.circular(OpenVtsRadius.md),
        border: Border.all(color: OpenVtsColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.file_download_outlined,
              size: 18, color: OpenVtsColors.brandInk),
          const SizedBox(width: OpenVtsSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: OpenVtsTypography.label.copyWith(
                    color: OpenVtsColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  fileName,
                  style: OpenVtsTypography.meta.copyWith(
                    color: OpenVtsColors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewBox extends StatelessWidget {
  const _PreviewBox({required this.content});

  final String content;

  @override
  Widget build(BuildContext context) {
    final preview = content.length > 4000
        ? '${content.substring(0, 4000)}\n\u2026'
        : content;
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: OpenVtsColors.background,
        borderRadius: BorderRadius.circular(OpenVtsRadius.md),
        border: Border.all(color: OpenVtsColors.border),
      ),
      child: Scrollbar(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(OpenVtsSpacing.sm),
          child: SelectableText(
            preview,
            style: OpenVtsTypography.meta.copyWith(
              fontFamily: 'monospace',
              color: OpenVtsColors.textSecondary,
              height: 1.3,
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionRow extends StatefulWidget {
  const _ActionRow({required this.payload});

  final _ExportPayload payload;

  @override
  State<_ActionRow> createState() => _ActionRowState();
}

class _ActionRowState extends State<_ActionRow> {
  bool _saving = false;

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    String? message;
    var didSave = false;
    try {
      final bytes = Uint8List.fromList(utf8.encode(widget.payload.kml));
      final path = await FilePicker.platform.saveFile(
        dialogTitle: 'Save KML export',
        fileName: widget.payload.suggestedFileName,
        bytes: bytes,
        type: FileType.custom,
        allowedExtensions: const ['kml'],
      );
      if (path != null) {
        didSave = true;
        message = 'Saved to $path';
      }
    } catch (e) {
      message = 'Save failed: $e';
    } finally {
      if (mounted) setState(() => _saving = false);
    }
    if (mounted && message != null) {
      if (didSave) {
        ToastHelper.showSuccess(message, context: context);
      } else {
        ToastHelper.showError(message, context: context);
      }
    }
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.payload.kml));
    if (!mounted) return;
    ToastHelper.showSuccess('KML copied to clipboard', context: context);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OpenVtsButton(
            label: 'Copy KML',
            onPressed: _copy,
            variant: OpenVtsButtonVariant.secondary,
            trailingIcon: Icons.copy_outlined,
          ),
        ),
        const SizedBox(width: OpenVtsSpacing.sm),
        Expanded(
          child: OpenVtsButton(
            label: 'Save .kml',
            onPressed: _save,
            isLoading: _saving,
            trailingIcon: Icons.save_alt_outlined,
          ),
        ),
      ],
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
