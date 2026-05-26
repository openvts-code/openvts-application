import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/open_vts_colors.dart';
import '../../../../../core/theme/open_vts_radius.dart';
import '../../../../../core/theme/open_vts_spacing.dart';
import '../../../../../core/theme/open_vts_typography.dart';
import '../../../../../shared/helpers/toast_helper.dart';
import '../../../../../shared/widgets/open_vts_button.dart';
import '../../../../../shared/widgets/open_vts_card.dart';
import '../../../../../shared/widgets/open_vts_loader.dart';
import '../../../../../shared/widgets/open_vts_text_field.dart';
import '../../../controllers/superadmin_providers.dart';
import '../../../controllers/superadmin_settings_controller.dart';
import '../../../models/superadmin_settings_model.dart';
import '../../../models/superadmin_settings_state.dart';

// =====================================================================
// SMTP settings section
// =====================================================================

class SmtpSettingsSection extends ConsumerStatefulWidget {
  const SmtpSettingsSection({super.key, required this.state});

  final SuperadminSettingsState state;

  @override
  ConsumerState<SmtpSettingsSection> createState() =>
      _SmtpSettingsSectionState();
}

class _SmtpSettingsSectionState extends ConsumerState<SmtpSettingsSection> {
  final _formKey = GlobalKey<FormState>();
  final _senderNameCtrl = TextEditingController();
  final _hostCtrl = TextEditingController();
  final _portCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _replyToCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  SuperadminSmtpType _type = SuperadminSmtpType.none;
  bool _isActive = false;
  bool _obscurePassword = true;
  bool _hydrated = false;

  @override
  void initState() {
    super.initState();
    _hydrate(widget.state.smtp);
  }

  @override
  void didUpdateWidget(covariant SmtpSettingsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = widget.state.smtp;
    if (next != null && !_hydrated) {
      _hydrate(next);
    }
  }

  void _hydrate(SuperadminSmtpSettings? smtp) {
    if (smtp == null) return;
    _senderNameCtrl.text = smtp.senderName ?? '';
    _hostCtrl.text = smtp.host ?? '';
    _portCtrl.text = smtp.port ?? '';
    _emailCtrl.text = smtp.email ?? '';
    _replyToCtrl.text = smtp.replyTo ?? '';
    _usernameCtrl.text = smtp.username ?? '';
    _passwordCtrl.text = smtp.password ?? '';
    _type = smtp.type;
    _isActive = smtp.isActive;
    _hydrated = true;
  }

  @override
  void dispose() {
    _senderNameCtrl.dispose();
    _hostCtrl.dispose();
    _portCtrl.dispose();
    _emailCtrl.dispose();
    _replyToCtrl.dispose();
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  SuperadminSettingsController get _controller =>
      ref.read(superadminSettingsControllerProvider.notifier);

  // -----------------------------------------------------------------
  // Save
  // -----------------------------------------------------------------

  Future<void> _save() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    final request = SuperadminSmtpSettings(
      id: widget.state.smtp?.id,
      senderName: _senderNameCtrl.text.trim(),
      host: _hostCtrl.text.trim(),
      port: _portCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      type: _type,
      username: _usernameCtrl.text.trim(),
      password: _passwordCtrl.text,
      replyTo: _replyToCtrl.text.trim(),
      isActive: _isActive,
    );

    final ok = await _controller.updateSmtp(request);
    if (!mounted) return;
    if (ok) {
      ToastHelper.showSuccess('SMTP settings saved');
      await _controller.loadSmtp();
      if (mounted) {
        setState(() => _hydrated = false);
        _hydrate(ref.read(superadminSettingsControllerProvider).smtp);
      }
    } else {
      ToastHelper.showError(
        ref.read(superadminSettingsControllerProvider).sectionErrorMessage ?? 'Failed to save SMTP settings',
      );
    }
  }

  // -----------------------------------------------------------------
  // Test
  // -----------------------------------------------------------------

  Future<void> _openTestSheet() async {
    final form = _formKey.currentState;
    if (form != null && !form.validate()) {
      ToastHelper.showInfo('Fix validation issues before testing');
      return;
    }
    final fallback = _emailCtrl.text.trim().isNotEmpty
        ? _emailCtrl.text.trim()
        : (widget.state.profile?.email ?? '');
    final email = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: OpenVtsColors.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(OpenVtsRadius.lg),
        ),
      ),
      builder: (ctx) => _TestEmailSheet(initialEmail: fallback),
    );
    if (email == null || email.trim().isEmpty) return;

    final ok = await _controller.testSmtp(email.trim());
    if (!mounted) return;
    if (ok) {
      ToastHelper.showSuccess('Test email sent to ${email.trim()}');
    } else {
      ToastHelper.showError(
        ref.read(superadminSettingsControllerProvider).sectionErrorMessage ?? 'Failed to send test email',
      );
    }
  }

  // -----------------------------------------------------------------
  // Build
  // -----------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final state = widget.state;

    if (state.isLoadingSmtp && state.smtp == null) {
      return const OpenVtsCard(
        padding: EdgeInsets.symmetric(vertical: OpenVtsSpacing.lg),
        child: Center(child: OpenVtsLoader()),
      );
    }

    if (state.smtp == null) {
      return OpenVtsCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              state.sectionErrorMessage ?? 'Could not load SMTP settings.',
              style: const TextStyle(
                fontFamily: OpenVtsTypography.primaryFontFamily,
                fontSize: 12.5,
                color: OpenVtsColors.textSecondary,
              ),
            ),
            const SizedBox(height: OpenVtsSpacing.sm),
            OpenVtsButton(
              label: 'Retry',
              variant: OpenVtsButtonVariant.secondary,
              height: 40,
              onPressed: _controller.loadSmtp,
            ),
          ],
        ),
      );
    }

    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SectionHeader(
            title: 'SMTP',
            subtitle: 'Configure outgoing mail delivery.',
            icon: Icons.mail_outline_rounded,
            trailing: IconButton(
              tooltip: 'Refresh',
              onPressed:
                  state.isLoadingSmtp ? null : _controller.loadSmtp,
              iconSize: 18,
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ),
          const SizedBox(height: OpenVtsSpacing.sm),
          _StatusCard(
            isActive: _isActive,
            onChanged: (v) => setState(() => _isActive = v),
          ),
          const SizedBox(height: OpenVtsSpacing.sm),
          _GroupedCard(
            icon: Icons.person_outline_rounded,
            title: 'Sender',
            subtitle: 'Who recipients see in the inbox.',
            children: [
              OpenVtsTextField(
                label: 'Sender Name',
                controller: _senderNameCtrl,
                hintText: 'OpenVTS Notifications',
                validator: (v) {
                  final s = (v ?? '').trim();
                  if (s.isEmpty) return 'Required';
                  if (s.length > 50) return 'Max 50 characters';
                  return null;
                },
              ),
              const SizedBox(height: OpenVtsSpacing.sm),
              OpenVtsTextField(
                label: 'From Email',
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                hintText: 'noreply@example.com',
                validator: (v) {
                  final s = (v ?? '').trim();
                  if (s.isEmpty) return 'Required';
                  if (!_isEmail(s)) return 'Enter a valid email';
                  return null;
                },
              ),
              const SizedBox(height: OpenVtsSpacing.sm),
              OpenVtsTextField(
                label: 'Reply-To (optional)',
                controller: _replyToCtrl,
                keyboardType: TextInputType.emailAddress,
                hintText: 'support@example.com',
                validator: (v) {
                  final s = (v ?? '').trim();
                  if (s.isEmpty) return null;
                  if (!_isEmail(s)) return 'Enter a valid email';
                  return null;
                },
              ),
            ],
          ),
          const SizedBox(height: OpenVtsSpacing.sm),
          _GroupedCard(
            icon: Icons.dns_outlined,
            title: 'Server',
            subtitle: 'Host, port and encryption.',
            children: [
              OpenVtsTextField(
                label: 'Host',
                controller: _hostCtrl,
                hintText: 'smtp.example.com',
                validator: (v) {
                  final s = (v ?? '').trim();
                  if (s.isEmpty) return 'Required';
                  if (s.length > 100) return 'Max 100 characters';
                  return null;
                },
              ),
              const SizedBox(height: OpenVtsSpacing.sm),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: OpenVtsTextField(
                      label: 'Port',
                      controller: _portCtrl,
                      keyboardType: TextInputType.number,
                      hintText: '587',
                      validator: (v) {
                        final s = (v ?? '').trim();
                        if (s.isEmpty) return 'Required';
                        final n = int.tryParse(s);
                        if (n == null || n < 1 || n > 65535) {
                          return '1–65535';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: OpenVtsSpacing.sm),
                  Expanded(
                    child: _EncryptionDropdown(
                      value: _type,
                      onChanged: (v) {
                        if (v != null) setState(() => _type = v);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: OpenVtsSpacing.sm),
          _GroupedCard(
            icon: Icons.lock_outline_rounded,
            title: 'Credentials',
            subtitle: 'SMTP account login.',
            children: [
              OpenVtsTextField(
                label: 'Username',
                controller: _usernameCtrl,
                hintText: 'apikey or username',
                validator: (v) {
                  final s = (v ?? '').trim();
                  if (s.isEmpty) return 'Required';
                  if (s.length > 100) return 'Max 100 characters';
                  return null;
                },
              ),
              const SizedBox(height: OpenVtsSpacing.sm),
              OpenVtsTextField(
                label: 'Password',
                controller: _passwordCtrl,
                obscureText: _obscurePassword,
                hintText: '••••••••',
                suffixIcon: IconButton(
                  tooltip: _obscurePassword ? 'Show password' : 'Hide password',
                  onPressed: () => setState(
                    () => _obscurePassword = !_obscurePassword,
                  ),
                  iconSize: 18,
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
                validator: (v) {
                  final s = v ?? '';
                  if (s.isEmpty) return 'Required';
                  if (s.length > 200) return 'Max 200 characters';
                  return null;
                },
              ),
            ],
          ),
          const SizedBox(height: OpenVtsSpacing.md),
          Row(
            children: [
              Expanded(
                child: OpenVtsButton(
                  label: 'Save',
                  isLoading: state.isSavingSmtp,
                  height: 44,
                  onPressed: state.isSavingSmtp ? null : _save,
                ),
              ),
              const SizedBox(width: OpenVtsSpacing.sm),
              Expanded(
                child: OpenVtsButton(
                  label: 'Send test email',
                  variant: OpenVtsButtonVariant.secondary,
                  isLoading: state.isTestingSmtp,
                  height: 44,
                  onPressed: state.isTestingSmtp || state.isSavingSmtp
                      ? null
                      : _openTestSheet,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// =====================================================================
// Status (isActive) card
// =====================================================================

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.isActive, required this.onChanged});

  final bool isActive;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return OpenVtsCard(
      padding: const EdgeInsets.symmetric(
        horizontal: OpenVtsSpacing.md,
        vertical: OpenVtsSpacing.sm,
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: OpenVtsColors.surface,
              borderRadius: BorderRadius.circular(OpenVtsRadius.sm),
              border: Border.all(color: OpenVtsColors.border),
            ),
            child: Icon(
              isActive
                  ? Icons.power_settings_new_rounded
                  : Icons.power_off_outlined,
              size: 16,
              color: isActive
                  ? OpenVtsColors.success
                  : OpenVtsColors.textTertiary,
            ),
          ),
          const SizedBox(width: OpenVtsSpacing.xs),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Enable SMTP',
                  style: TextStyle(
                    fontFamily: OpenVtsTypography.primaryFontFamily,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: OpenVtsColors.textPrimary,
                  ),
                ),
                SizedBox(height: 1),
                Text(
                  'Outgoing mail uses this server when active.',
                  style: TextStyle(
                    fontFamily: OpenVtsTypography.primaryFontFamily,
                    fontSize: 11,
                    height: 1.3,
                    color: OpenVtsColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: isActive,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

// =====================================================================
// Encryption dropdown
// =====================================================================

class _EncryptionDropdown extends StatelessWidget {
  const _EncryptionDropdown({
    required this.value,
    required this.onChanged,
  });

  final SuperadminSmtpType value;
  final ValueChanged<SuperadminSmtpType?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Encryption', style: OpenVtsTypography.label),
        const SizedBox(height: OpenVtsSpacing.xs),
        InputDecorator(
          decoration: const InputDecoration(isDense: true),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<SuperadminSmtpType>(
              value: value,
              isExpanded: true,
              icon: const Icon(
                Icons.expand_more_rounded,
                size: 18,
                color: OpenVtsColors.textTertiary,
              ),
              style: const TextStyle(
                fontFamily: OpenVtsTypography.primaryFontFamily,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: OpenVtsColors.textPrimary,
              ),
              items: const [
                DropdownMenuItem(
                  value: SuperadminSmtpType.none,
                  child: Text('None'),
                ),
                DropdownMenuItem(
                  value: SuperadminSmtpType.ssl,
                  child: Text('SSL'),
                ),
                DropdownMenuItem(
                  value: SuperadminSmtpType.tls,
                  child: Text('TLS'),
                ),
              ],
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}

// =====================================================================
// Test email bottom sheet
// =====================================================================

class _TestEmailSheet extends StatefulWidget {
  const _TestEmailSheet({required this.initialEmail});
  final String initialEmail;

  @override
  State<_TestEmailSheet> createState() => _TestEmailSheetState();
}

class _TestEmailSheetState extends State<_TestEmailSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initialEmail);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() != true) return;
    Navigator.of(context).pop(_ctrl.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            OpenVtsSpacing.md,
            OpenVtsSpacing.sm,
            OpenVtsSpacing.md,
            OpenVtsSpacing.md,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: OpenVtsSpacing.sm),
                    decoration: BoxDecoration(
                      color: OpenVtsColors.border,
                      borderRadius: BorderRadius.circular(OpenVtsRadius.pill),
                    ),
                  ),
                ),
                const Text(
                  'Send test email',
                  style: TextStyle(
                    fontFamily: OpenVtsTypography.primaryFontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: OpenVtsColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'A short message will be sent using the current SMTP config.',
                  style: TextStyle(
                    fontFamily: OpenVtsTypography.primaryFontFamily,
                    fontSize: 11.5,
                    height: 1.35,
                    color: OpenVtsColors.textSecondary,
                  ),
                ),
                const SizedBox(height: OpenVtsSpacing.sm),
                OpenVtsTextField(
                  label: 'Recipient email',
                  controller: _ctrl,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.send,
                  hintText: 'recipient@example.com',
                  onFieldSubmitted: (_) => _submit(),
                  validator: (v) {
                    final s = (v ?? '').trim();
                    if (s.isEmpty) return 'Required';
                    if (!_isEmail(s)) return 'Enter a valid email';
                    return null;
                  },
                ),
                const SizedBox(height: OpenVtsSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: OpenVtsButton(
                        label: 'Cancel',
                        variant: OpenVtsButtonVariant.secondary,
                        height: 42,
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                    const SizedBox(width: OpenVtsSpacing.sm),
                    Expanded(
                      child: OpenVtsButton(
                        label: 'Send',
                        height: 42,
                        onPressed: _submit,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// =====================================================================
// Section header (mirrors _SectionCard look)
// =====================================================================

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return OpenVtsCard(
      padding: const EdgeInsets.all(OpenVtsSpacing.md),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: OpenVtsColors.surface,
              borderRadius: BorderRadius.circular(OpenVtsRadius.sm),
              border: Border.all(color: OpenVtsColors.border),
            ),
            child: Icon(icon, size: 16, color: OpenVtsColors.textPrimary),
          ),
          const SizedBox(width: OpenVtsSpacing.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: OpenVtsTypography.primaryFontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: OpenVtsColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontFamily: OpenVtsTypography.primaryFontFamily,
                    fontSize: 11,
                    height: 1.3,
                    color: OpenVtsColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: OpenVtsSpacing.xs),
            trailing!,
          ],
        ],
      ),
    );
  }
}

// =====================================================================
// Grouped sub-card with title row
// =====================================================================

class _GroupedCard extends StatelessWidget {
  const _GroupedCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return OpenVtsCard(
      padding: const EdgeInsets.all(OpenVtsSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: OpenVtsColors.textSecondary),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: OpenVtsTypography.primaryFontFamily,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: OpenVtsColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontFamily: OpenVtsTypography.primaryFontFamily,
                        fontSize: 11,
                        height: 1.3,
                        color: OpenVtsColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: OpenVtsSpacing.sm),
          ...children,
        ],
      ),
    );
  }
}

// =====================================================================
// Helpers
// =====================================================================

final RegExp _emailRegex = RegExp(
  r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$',
);

bool _isEmail(String value) => _emailRegex.hasMatch(value.trim());
