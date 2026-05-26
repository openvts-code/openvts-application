import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../core/theme/open_vts_colors.dart';
import '../../../../../core/theme/open_vts_radius.dart';
import '../../../../../core/theme/open_vts_spacing.dart';
import '../../../../../core/theme/open_vts_typography.dart';
import '../../../../../shared/helpers/toast_helper.dart';
import '../../../../../shared/widgets/open_vts_bottom_sheet.dart';
import '../../../../../shared/widgets/open_vts_button.dart';

class UserShareTrackLinkQrSheet extends StatelessWidget {
  const UserShareTrackLinkQrSheet({
    required this.publicUrl,
    super.key,
  });

  final String publicUrl;

  static Future<T?> show<T>({
    required BuildContext context,
    required String publicUrl,
  }) {
    return OpenVtsBottomSheet.show<T>(
      context: context,
      title: 'Track Link QR',
      initialChildSize: 0.58,
      minChildSize: 0.42,
      maxChildSize: 0.78,
      child: UserShareTrackLinkQrSheet(publicUrl: publicUrl),
    );
  }

  @override
  Widget build(BuildContext context) {
    final qrUrl = Uri.https('api.qrserver.com', 'v1/create-qr-code/', {
      'size': '240x240',
      'data': publicUrl,
    }).toString();

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        OpenVtsSpacing.md,
        OpenVtsSpacing.sm,
        OpenVtsSpacing.md,
        OpenVtsSpacing.xl,
      ),
      children: [
        Center(
          child: Container(
            width: 256,
            height: 256,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: OpenVtsColors.white,
              borderRadius: BorderRadius.circular(OpenVtsRadius.lg),
              border: Border.all(color: OpenVtsColors.border),
            ),
            child: Image.network(
              qrUrl,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.none,
              errorBuilder: (context, error, stackTrace) => const Center(
                child: Icon(
                  Icons.qr_code_2_rounded,
                  size: 86,
                  color: OpenVtsColors.textTertiary,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: OpenVtsSpacing.md),
        Container(
          padding: const EdgeInsets.all(OpenVtsSpacing.sm),
          decoration: BoxDecoration(
            color: OpenVtsColors.surfaceElevated,
            borderRadius: BorderRadius.circular(OpenVtsRadius.lg),
            border: Border.all(color: OpenVtsColors.border),
          ),
          child: Text(
            publicUrl,
            style: OpenVtsTypography.meta.copyWith(
              color: OpenVtsColors.textPrimary,
              fontFamily: 'monospace',
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: OpenVtsSpacing.sm),
        Row(
          children: [
            Expanded(
              child: OpenVtsButton(
                label: 'Copy',
                onPressed: () => _copyPublicUrl(context),
                variant: OpenVtsButtonVariant.secondary,
                trailingIcon: Icons.copy_rounded,
                height: 40,
              ),
            ),
            const SizedBox(width: OpenVtsSpacing.sm),
            Expanded(
              child: OpenVtsButton(
                label: 'Open',
                onPressed: () => _openPublicUrl(context),
                trailingIcon: Icons.open_in_new_rounded,
                height: 40,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _copyPublicUrl(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: publicUrl));
    if (!context.mounted) return;
    ToastHelper.showSuccess('Link copied.', context: context);
  }

  Future<void> _openPublicUrl(BuildContext context) async {
    final uri = Uri.tryParse(publicUrl);
    if (uri == null || !uri.hasScheme) {
      ToastHelper.showError('Could not open link.', context: context);
      return;
    }

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!context.mounted) return;
      if (!launched) {
        ToastHelper.showError('Could not open link.', context: context);
      }
    } catch (_) {
      if (!context.mounted) return;
      ToastHelper.showError('Could not open link.', context: context);
    }
  }
}
