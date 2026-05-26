import 'package:flutter/material.dart';

import '../../../../../core/theme/open_vts_colors.dart';
import '../../../../../core/theme/open_vts_spacing.dart';
import '../../../../../core/theme/open_vts_typography.dart';
import '../../../../../shared/widgets/open_vts_button.dart';
import '../../../../../shared/widgets/open_vts_card.dart';

class UserNotificationSaveBar extends StatelessWidget {
  const UserNotificationSaveBar({
    required this.isSaving,
    required this.canSave,
    required this.canReset,
    required this.onSave,
    required this.onReset,
    super.key,
  });

  final bool isSaving;
  final bool canSave;
  final bool canReset;
  final VoidCallback? onSave;
  final VoidCallback? onReset;

  @override
  Widget build(BuildContext context) {
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: keyboardInset),
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(
          0,
          OpenVtsSpacing.xs,
          0,
          OpenVtsSpacing.xs,
        ),
        child: OpenVtsCard(
          padding: const EdgeInsets.all(OpenVtsSpacing.xs),
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 430) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isSaving
                          ? 'Saving changes...'
                          : 'You have unsaved changes.',
                      style: OpenVtsTypography.meta.copyWith(
                        color: OpenVtsColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: OpenVtsSpacing.xs),
                    Row(
                      children: [
                        Expanded(
                          child: OpenVtsButton(
                            label: 'Reset',
                            height: 44,
                            variant: OpenVtsButtonVariant.secondary,
                            onPressed: canReset ? onReset : null,
                          ),
                        ),
                        const SizedBox(width: OpenVtsSpacing.xs),
                        Expanded(
                          flex: 2,
                          child: OpenVtsButton(
                            label: isSaving ? 'Saving...' : 'Save Changes',
                            height: 44,
                            isLoading: isSaving,
                            onPressed: canSave ? onSave : null,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(
                    child: Text(
                      isSaving
                          ? 'Saving changes...'
                          : 'You have unsaved changes.',
                      style: OpenVtsTypography.meta.copyWith(
                        color: OpenVtsColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 98,
                    child: OpenVtsButton(
                      label: 'Reset',
                      height: 44,
                      variant: OpenVtsButtonVariant.secondary,
                      onPressed: canReset ? onReset : null,
                    ),
                  ),
                  const SizedBox(width: OpenVtsSpacing.xs),
                  SizedBox(
                    width: 154,
                    child: OpenVtsButton(
                      label: isSaving ? 'Saving...' : 'Save Changes',
                      height: 44,
                      isLoading: isSaving,
                      onPressed: canSave ? onSave : null,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
