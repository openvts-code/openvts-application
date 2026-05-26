import 'package:flutter/material.dart';

import '../../../../../core/theme/open_vts_colors.dart';
import '../../../../../core/theme/open_vts_spacing.dart';
import '../../../../../core/theme/open_vts_typography.dart';
import '../../../../../shared/widgets/open_vts_card.dart';
import '../../../../../shared/widgets/open_vts_status_chip.dart';

class UserVerificationCard extends StatelessWidget {
  const UserVerificationCard({
    required this.isEmailVerified,
    required this.isMobileVerified,
    required this.isRequestingEmailOtp,
    required this.isConfirmingEmailOtp,
    required this.isRequestingWhatsAppOtp,
    required this.isConfirmingWhatsAppOtp,
    required this.onVerifyEmail,
    required this.onVerifyWhatsApp,
    super.key,
  });

  final bool isEmailVerified;
  final bool isMobileVerified;
  final bool isRequestingEmailOtp;
  final bool isConfirmingEmailOtp;
  final bool isRequestingWhatsAppOtp;
  final bool isConfirmingWhatsAppOtp;
  final VoidCallback? onVerifyEmail;
  final VoidCallback? onVerifyWhatsApp;

  @override
  Widget build(BuildContext context) {
    final emailBusy = isRequestingEmailOtp || isConfirmingEmailOtp;
    final whatsappBusy = isRequestingWhatsAppOtp || isConfirmingWhatsAppOtp;

    return OpenVtsCard(
      padding: const EdgeInsets.all(OpenVtsSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Verification',
            style: OpenVtsTypography.label.copyWith(
              color: OpenVtsColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: OpenVtsSpacing.xs),
          Wrap(
            spacing: OpenVtsSpacing.xs,
            runSpacing: OpenVtsSpacing.xs,
            children: [
              OpenVtsStatusChip(
                label: isEmailVerified ? 'Email verified' : 'Email pending',
                type: isEmailVerified
                    ? OpenVtsStatusType.success
                    : OpenVtsStatusType.warning,
              ),
              OpenVtsStatusChip(
                label:
                    isMobileVerified ? 'WhatsApp verified' : 'WhatsApp pending',
                type: isMobileVerified
                    ? OpenVtsStatusType.success
                    : OpenVtsStatusType.warning,
              ),
            ],
          ),
          const SizedBox(height: OpenVtsSpacing.xs),
          Text(
            'Request and confirm OTP to verify email and WhatsApp number.',
            style: OpenVtsTypography.meta.copyWith(
              color: OpenVtsColors.textSecondary,
            ),
          ),
          const SizedBox(height: OpenVtsSpacing.xs),
          Wrap(
            spacing: OpenVtsSpacing.xs,
            runSpacing: OpenVtsSpacing.xs,
            children: [
              OutlinedButton.icon(
                onPressed: isEmailVerified || emailBusy ? null : onVerifyEmail,
                icon: emailBusy
                    ? const SizedBox.square(
                        dimension: 12,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.mark_email_read_outlined, size: 14),
                label: Text(emailBusy ? 'Working...' : 'Verify Email'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 44),
                ),
              ),
              OutlinedButton.icon(
                onPressed:
                    isMobileVerified || whatsappBusy ? null : onVerifyWhatsApp,
                icon: whatsappBusy
                    ? const SizedBox.square(
                        dimension: 12,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.chat_outlined, size: 14),
                label: Text(whatsappBusy ? 'Working...' : 'Verify WhatsApp'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 44),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
