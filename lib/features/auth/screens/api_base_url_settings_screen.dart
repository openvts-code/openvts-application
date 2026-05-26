import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/theme/open_vts_colors.dart';
import '../../../core/theme/open_vts_spacing.dart';
import '../../../core/theme/open_vts_typography.dart';
import '../../../shared/helpers/toast_helper.dart';
import '../../../shared/widgets/open_vts_button.dart';
import '../../../shared/widgets/open_vts_card.dart';
import '../../../shared/widgets/open_vts_page_scaffold.dart';
import '../../../shared/widgets/open_vts_text_field.dart';

class ApiBaseUrlSettingsScreen extends ConsumerStatefulWidget {
  const ApiBaseUrlSettingsScreen({super.key});

  @override
  ConsumerState<ApiBaseUrlSettingsScreen> createState() =>
      _ApiBaseUrlSettingsScreenState();
}

class _ApiBaseUrlSettingsScreenState
    extends ConsumerState<ApiBaseUrlSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _customUrlController;

  @override
  void initState() {
    super.initState();
    final currentUrl = ref.read(apiBaseUrlProvider);
    _customUrlController = TextEditingController(
      text: currentUrl == AppConfig.defaultApiBaseUrl ? '' : currentUrl,
    );
  }

  @override
  void dispose() {
    _customUrlController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_formKey.currentState?.validate() != true) {
      return;
    }

    final notifier = ref.read(apiBaseUrlProvider.notifier);
    await notifier.saveCustomUrl(_customUrlController.text);

    if (!mounted) {
      return;
    }

    ToastHelper.show(context, 'API base URL updated');
    Navigator.of(context).pop();
  }

  Future<void> _reset() async {
    final notifier = ref.read(apiBaseUrlProvider.notifier);
    await notifier.resetToDefault();
    _customUrlController.clear();

    if (!mounted) {
      return;
    }

    ToastHelper.show(context, 'API base URL reset to default');
  }

  String? _validateCustomUrl(String? value) {
    final trimmedValue = value?.trim() ?? '';
    if (trimmedValue.isEmpty) {
      return 'Enter a custom URL';
    }

    final uri = Uri.tryParse(trimmedValue);
    final hasValidScheme = uri?.scheme == 'http' || uri?.scheme == 'https';

    if (uri == null || !uri.isAbsolute || !hasValidScheme || uri.host.isEmpty) {
      return 'Enter a valid API URL';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final activeUrl = ref.watch(apiBaseUrlProvider);
    final isUsingDefault = activeUrl == AppConfig.defaultApiBaseUrl;

    return OpenVtsPageScaffold(
      title: 'Base URL Settings',
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              OpenVtsCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Default',
                          style: OpenVtsTypography.titleSmall,
                        ),
                        const Spacer(),
                        if (isUsingDefault)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: OpenVtsSpacing.sm,
                              vertical: OpenVtsSpacing.xs,
                            ),
                            decoration: BoxDecoration(
                              color: OpenVtsColors.surface,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: OpenVtsColors.border),
                            ),
                            child: Text(
                              'Active',
                              style: OpenVtsTypography.meta.copyWith(
                                color: OpenVtsColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: OpenVtsSpacing.sm),
                    SelectableText(
                      AppConfig.defaultApiBaseUrl,
                      style: OpenVtsTypography.body.copyWith(
                        color: OpenVtsColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: OpenVtsSpacing.md),
              OpenVtsCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Custom URL',
                          style: OpenVtsTypography.titleSmall,
                        ),
                        const Spacer(),
                        if (!isUsingDefault)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: OpenVtsSpacing.sm,
                              vertical: OpenVtsSpacing.xs,
                            ),
                            decoration: BoxDecoration(
                              color: OpenVtsColors.surface,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: OpenVtsColors.border),
                            ),
                            child: Text(
                              'Active',
                              style: OpenVtsTypography.meta.copyWith(
                                color: OpenVtsColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: OpenVtsSpacing.md),
                    OpenVtsTextField(
                      label: 'Custom URL',
                      controller: _customUrlController,
                      hintText: 'https://your-server.com/api',
                      keyboardType: TextInputType.url,
                      textInputAction: TextInputAction.done,
                      prefixIcon: Icons.link_rounded,
                      validator: _validateCustomUrl,
                      onFieldSubmitted: (_) => _save(),
                    ),
                    const SizedBox(height: OpenVtsSpacing.sm),
                    Text(
                      'Current: $activeUrl',
                      style: OpenVtsTypography.meta.copyWith(
                        color: OpenVtsColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: OpenVtsSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: OpenVtsButton(
                      label: 'Reset',
                      variant: OpenVtsButtonVariant.secondary,
                      onPressed: _reset,
                    ),
                  ),
                  const SizedBox(width: OpenVtsSpacing.md),
                  Expanded(
                    child: OpenVtsButton(
                      label: 'Save',
                      onPressed: _save,
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
