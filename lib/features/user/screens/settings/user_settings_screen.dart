import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/app_preferences_provider.dart';
import '../../../../core/theme/open_vts_colors.dart';
import '../../../../core/theme/open_vts_radius.dart';
import '../../../../core/theme/open_vts_spacing.dart';
import '../../../../core/theme/open_vts_typography.dart';
import '../../../../shared/helpers/toast_helper.dart';
import '../../../../shared/widgets/open_vts_button.dart';
import '../../../../shared/widgets/open_vts_error_view.dart';
import '../../../../shared/widgets/open_vts_loader.dart';
import '../../../../shared/widgets/open_vts_page_scaffold.dart';
import '../../controllers/user_providers.dart';
import '../../models/user_settings_model.dart';
import '../../models/user_settings_state.dart';
import 'widgets/user_localization_settings_tab.dart';
import 'widgets/user_profile_settings_tab.dart';
import 'widgets/user_settings_header.dart';
import 'widgets/user_settings_save_bar.dart';
import 'widgets/user_settings_tab_selector.dart';

const double _settingsMaxWidth = 920;

class UserSettingsScreen extends ConsumerStatefulWidget {
  const UserSettingsScreen({super.key});

  @override
  ConsumerState<UserSettingsScreen> createState() => _UserSettingsScreenState();
}

class _UserSettingsScreenState extends ConsumerState<UserSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    ref.listen<UserSettingsState>(
      userSettingsControllerProvider,
      _handleStateTransition,
    );

    final state = ref.watch(userSettingsControllerProvider);
    final controller = ref.read(userSettingsControllerProvider.notifier);

    final isProfileFirstLoad =
        !state.hasProfile && (state.isLoadingInitial || state.isLoadingProfile);
    if (isProfileFirstLoad) {
      return const OpenVtsPageScaffold(
        title: 'Settings',
        headerMode: OpenVtsPageHeaderMode.closeable,
        body: OpenVtsLoader(),
      );
    }

    final profileFailureMessage =
        _firstMeaningful(state.profileErrorMessage, state.errorMessage);
    final didProfileLoadFail =
        !state.hasProfile && profileFailureMessage != null;
    if (didProfileLoadFail) {
      return OpenVtsPageScaffold(
        title: 'Settings',
        headerMode: OpenVtsPageHeaderMode.closeable,
        body: OpenVtsErrorView(
          message: profileFailureMessage,
          onRetry: controller.loadProfile,
        ),
      );
    }

    final selectedTab = state.selectedTab;
    final isProfileTab = selectedTab == UserSettingsTab.profile;
    final currentTabDirty =
        isProfileTab ? state.isProfileDirty : state.isLocalizationDirty;
    final currentTabSaving =
        isProfileTab ? state.isSavingProfile : state.isSavingLocalization;
    final canResetCurrentTab = currentTabDirty && !currentTabSaving;
    final canSaveCurrentTab =
        isProfileTab ? state.canSaveProfile : state.canSaveLocalization;

    final listBottomPadding = currentTabDirty || currentTabSaving
        ? 116.0 + MediaQuery.paddingOf(context).bottom
        : OpenVtsSpacing.md;

    Future<void> onRefreshCurrentTab() async {
      if (state.hasAnyBusyState) {
        return;
      }

      final shouldDiscardUnsaved = currentTabDirty;
      if (shouldDiscardUnsaved) {
        final confirmed = await _confirmDiscardAndRefresh(
          context,
          tabLabel: isProfileTab ? 'Profile' : 'Localization',
        );
        if (!confirmed) {
          return;
        }
      }

      await controller.refreshCurrentTab(
        discardUnsaved: shouldDiscardUnsaved,
      );
    }

    Future<void> onSaveCurrentTab() async {
      final saved = isProfileTab
          ? await controller.saveProfile()
          : await controller.saveLocalization();
      if (!mounted || !saved) {
        return;
      }

      if (!isProfileTab) {
        final loc = ref.read(userSettingsControllerProvider).localization;
        if (loc != null) {
          await ref
              .read(appLocalizationPreferencesProvider.notifier)
              .applyFromUserSettings(
                languageCode: loc.language,
                dateFormat: loc.dateFormat,
                timeFormat: loc.use24Hour ? '24H' : '12H',
                theme: loc.theme.apiValue,
                timezone: loc.timezoneOffset,
              );
        }
        if (!mounted) return;
      }

      ToastHelper.showSuccess(
        isProfileTab
            ? 'Profile settings updated.'
            : 'Localization settings updated.',
      );
    }

    void onResetCurrentTab() {
      if (isProfileTab) {
        controller.resetProfileDraft();
      } else {
        controller.resetLocalizationDraft();
      }
    }

    return OpenVtsPageScaffold(
      title: 'Settings',
      headerMode: OpenVtsPageHeaderMode.closeable,
      padding: const EdgeInsets.fromLTRB(
        OpenVtsSpacing.sm,
        OpenVtsSpacing.xs,
        OpenVtsSpacing.sm,
        0,
      ),
      actions: [
        IconButton(
          tooltip: 'Refresh current tab',
          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          onPressed: state.hasAnyBusyState
              ? null
              : () {
                  unawaited(onRefreshCurrentTab());
                },
          icon: state.hasAnyBusyState
              ? const SizedBox.square(
                  dimension: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.refresh_rounded, size: 18),
        ),
      ],
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: _settingsMaxWidth),
              child: Stack(
                children: [
                  RefreshIndicator(
                    onRefresh: onRefreshCurrentTab,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.only(bottom: listBottomPadding),
                      children: [
                        UserSettingsHeader(
                          selectedTab: selectedTab,
                          isCurrentTabDirty: currentTabDirty,
                          isCurrentTabSaving: currentTabSaving,
                          lastUpdatedAt: state.profile?.updatedAt,
                        ),
                        const SizedBox(height: OpenVtsSpacing.sm),
                        UserSettingsTabSelector(
                          selectedTab: selectedTab,
                          onChanged: controller.selectTab,
                        ),
                        const SizedBox(height: OpenVtsSpacing.sm),
                        if (state.errorMessage != null &&
                            state.errorMessage!.trim().isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(
                                bottom: OpenVtsSpacing.sm),
                            child: _InlineNoticeBanner(
                              message: state.errorMessage!,
                              tone: _NoticeTone.error,
                              onDismiss: controller.clearErrorMessage,
                            ),
                          ),
                        if (!isProfileTab &&
                            state.localizationErrorMessage != null &&
                            state.localizationErrorMessage!.trim().isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(
                                bottom: OpenVtsSpacing.sm),
                            child: _InlineNoticeBanner(
                              message:
                                  'Using safe defaults. ${state.localizationErrorMessage!}',
                              tone: _NoticeTone.warning,
                              onDismiss:
                                  controller.clearLocalizationErrorMessage,
                            ),
                          ),
                        if (isProfileTab &&
                            state.profileErrorMessage != null &&
                            state.profileErrorMessage!.trim().isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(
                                bottom: OpenVtsSpacing.sm),
                            child: _InlineNoticeBanner(
                              message: state.profileErrorMessage!,
                              tone: _NoticeTone.error,
                              onDismiss: controller.clearProfileErrorMessage,
                            ),
                          ),
                        if (isProfileTab)
                          UserProfileSettingsTab(
                            state: state,
                            controller: controller,
                          )
                        else
                          UserLocalizationSettingsTab(
                            state: state,
                            controller: controller,
                          ),
                        const SizedBox(height: OpenVtsSpacing.sm),
                      ],
                    ),
                  ),
                  if (currentTabDirty || currentTabSaving)
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: UserSettingsSaveBar(
                        selectedTab: selectedTab,
                        isSaving: currentTabSaving,
                        canSave: canSaveCurrentTab,
                        canReset: canResetCurrentTab,
                        onSave: () {
                          unawaited(onSaveCurrentTab());
                        },
                        onReset: onResetCurrentTab,
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _handleStateTransition(
    UserSettingsState? previous,
    UserSettingsState next,
  ) {
    final previousError = previous?.errorMessage?.trim();
    final currentError = next.errorMessage?.trim();
    if (currentError != null &&
        currentError.isNotEmpty &&
        currentError != previousError) {
      ToastHelper.showError(currentError);
    }

    final previousProfileError = previous?.profileErrorMessage?.trim();
    final currentProfileError = next.profileErrorMessage?.trim();
    if (currentProfileError != null &&
        currentProfileError.isNotEmpty &&
        currentProfileError != previousProfileError) {
      ToastHelper.showError(currentProfileError);
    }

    final previousLocalizationError =
        previous?.localizationErrorMessage?.trim();
    final currentLocalizationError = next.localizationErrorMessage?.trim();
    if (currentLocalizationError != null &&
        currentLocalizationError.isNotEmpty &&
        currentLocalizationError != previousLocalizationError) {
      ToastHelper.showError(currentLocalizationError);
    }
  }

  String? _firstMeaningful(String? first, String? second) {
    final a = first?.trim();
    if (a != null && a.isNotEmpty) {
      return a;
    }
    final b = second?.trim();
    if (b != null && b.isNotEmpty) {
      return b;
    }
    return null;
  }

  Future<bool> _confirmDiscardAndRefresh(
    BuildContext context, {
    required String tabLabel,
  }) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final insets = MediaQuery.viewInsetsOf(sheetContext).bottom;

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
                OpenVtsSpacing.sm + insets,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Discard unsaved changes?',
                    style: OpenVtsTypography.label.copyWith(
                      color: OpenVtsColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: OpenVtsSpacing.xs),
                  Text(
                    '$tabLabel has unsaved edits. Refreshing now will discard them.',
                    style: OpenVtsTypography.body.copyWith(
                      color: OpenVtsColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: OpenVtsSpacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: OpenVtsButton(
                          label: 'Keep Editing',
                          height: 44,
                          variant: OpenVtsButtonVariant.secondary,
                          onPressed: () {
                            Navigator.of(sheetContext).pop(false);
                          },
                        ),
                      ),
                      const SizedBox(width: OpenVtsSpacing.xs),
                      Expanded(
                        child: OpenVtsButton(
                          label: 'Discard & Refresh',
                          height: 44,
                          onPressed: () {
                            Navigator.of(sheetContext).pop(true);
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    return result == true;
  }
}

enum _NoticeTone { warning, error }

class _InlineNoticeBanner extends StatelessWidget {
  const _InlineNoticeBanner({
    required this.message,
    required this.tone,
    this.onDismiss,
  });

  final String message;
  final _NoticeTone tone;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final isWarning = tone == _NoticeTone.warning;
    final foreground = isWarning ? OpenVtsColors.warning : OpenVtsColors.error;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: foreground.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(OpenVtsRadius.md),
        border: Border.all(color: foreground.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          OpenVtsSpacing.sm,
          OpenVtsSpacing.xs,
          OpenVtsSpacing.xs,
          OpenVtsSpacing.xs,
        ),
        child: Row(
          children: [
            Icon(
              isWarning
                  ? Icons.warning_amber_rounded
                  : Icons.error_outline_rounded,
              size: 17,
              color: foreground,
            ),
            const SizedBox(width: OpenVtsSpacing.xs),
            Expanded(
              child: Text(
                message,
                style: OpenVtsTypography.body.copyWith(color: foreground),
              ),
            ),
            if (onDismiss != null)
              IconButton(
                tooltip: 'Dismiss',
                onPressed: onDismiss,
                iconSize: 16,
                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                icon: Icon(Icons.close_rounded, color: foreground),
              ),
          ],
        ),
      ),
    );
  }
}
