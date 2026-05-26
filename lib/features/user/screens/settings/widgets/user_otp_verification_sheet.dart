import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../core/theme/open_vts_colors.dart';
import '../../../../../core/theme/open_vts_radius.dart';
import '../../../../../core/theme/open_vts_spacing.dart';
import '../../../../../core/theme/open_vts_typography.dart';
import '../../../../../shared/widgets/open_vts_button.dart';

class UserOtpVerificationSheet extends StatefulWidget {
  const UserOtpVerificationSheet({
    required this.title,
    required this.subtitle,
    required this.onConfirm,
    required this.onResend,
    super.key,
  });

  final String title;
  final String subtitle;
  final Future<bool> Function(String otp) onConfirm;
  final Future<bool> Function() onResend;

  @override
  State<UserOtpVerificationSheet> createState() =>
      _UserOtpVerificationSheetState();
}

class _UserOtpVerificationSheetState extends State<UserOtpVerificationSheet> {
  final _otpController = TextEditingController();
  bool _isSubmitting = false;
  bool _isResending = false;
  String? _errorText;

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      setState(() {
        _errorText = 'Enter the 6-digit OTP.';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorText = null;
    });

    final ok = await widget.onConfirm(otp);
    if (!mounted) {
      return;
    }

    setState(() {
      _isSubmitting = false;
      if (!ok) {
        _errorText = 'Unable to verify OTP. Please try again.';
      }
    });

    if (ok) {
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _resend() async {
    setState(() {
      _isResending = true;
      _errorText = null;
    });

    final ok = await widget.onResend();
    if (!mounted) {
      return;
    }

    setState(() {
      _isResending = false;
      if (!ok) {
        _errorText = 'Unable to resend OTP right now.';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final insets = MediaQuery.viewInsetsOf(context).bottom;

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: OpenVtsColors.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(OpenVtsRadius.lg),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            OpenVtsSpacing.md,
            OpenVtsSpacing.md,
            OpenVtsSpacing.md,
            OpenVtsSpacing.md + insets,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.title,
                style: OpenVtsTypography.label.copyWith(
                  color: OpenVtsColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: OpenVtsSpacing.xxs),
              Text(
                widget.subtitle,
                style: OpenVtsTypography.meta.copyWith(
                  color: OpenVtsColors.textSecondary,
                ),
              ),
              const SizedBox(height: OpenVtsSpacing.sm),
              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
                maxLength: 6,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                decoration: const InputDecoration(
                  labelText: 'OTP',
                  hintText: 'Enter 6-digit code',
                  counterText: '',
                ),
              ),
              if (_errorText != null) ...[
                const SizedBox(height: OpenVtsSpacing.xxs),
                Text(
                  _errorText!,
                  style: OpenVtsTypography.meta.copyWith(
                    color: OpenVtsColors.warning,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: OpenVtsSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: OpenVtsButton(
                      label: _isResending ? 'Resending...' : 'Resend OTP',
                      variant: OpenVtsButtonVariant.secondary,
                      height: 44,
                      onPressed: _isResending || _isSubmitting ? null : _resend,
                    ),
                  ),
                  const SizedBox(width: OpenVtsSpacing.xs),
                  Expanded(
                    child: OpenVtsButton(
                      label: 'Verify',
                      height: 44,
                      isLoading: _isSubmitting,
                      onPressed: _isSubmitting || _isResending ? null : _submit,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
