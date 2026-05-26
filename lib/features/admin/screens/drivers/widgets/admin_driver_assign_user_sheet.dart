import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/open_vts_spacing.dart';
import '../../../../../shared/helpers/toast_helper.dart';
import '../../../../../shared/widgets/open_vts_bottom_sheet.dart';
import '../../../../../shared/widgets/open_vts_button.dart';
import '../../../../../shared/widgets/open_vts_empty_state.dart';
import '../../../../../shared/widgets/open_vts_search_field.dart';
import '../../../controllers/admin_driver_details_controller.dart';
import '../../../models/admin_driver_details_model.dart';
import '../../../models/admin_driver_details_state.dart';

Future<void> showDriverAssignUserSheet({
  required BuildContext context,
  required AutoDisposeStateNotifierProvider<AdminDriverDetailsController,
          AdminDriverDetailsState>
      provider,
  required List<AdminDriverLinkedUser> users,
}) {
  return OpenVtsBottomSheet.show<void>(
    context: context,
    title: 'Assign User',
    initialChildSize: 0.72,
    minChildSize: 0.4,
    maxChildSize: 0.94,
    child: _DriverAssignUserSheet(provider: provider, users: users),
  );
}

class _DriverAssignUserSheet extends ConsumerStatefulWidget {
  const _DriverAssignUserSheet({required this.provider, required this.users});

  final AutoDisposeStateNotifierProvider<AdminDriverDetailsController,
      AdminDriverDetailsState> provider;
  final List<AdminDriverLinkedUser> users;

  @override
  ConsumerState<_DriverAssignUserSheet> createState() =>
      _DriverAssignUserSheetState();
}

class _DriverAssignUserSheetState
    extends ConsumerState<_DriverAssignUserSheet> {
  String _query = '';
  String? _selectedId;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(widget.provider);
    final filtered = widget.users.where((u) {
      final q = _query.trim().toLowerCase();
      if (q.isEmpty) return true;
      return [
        u.name,
        u.username,
        u.phone,
        u.email,
      ].any((v) => v.toLowerCase().contains(q));
    }).toList(growable: false);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(OpenVtsSpacing.md),
          child: OpenVtsSearchField(
            hintText: 'Search users...',
            onChanged: (value) => setState(() => _query = value),
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? const OpenVtsEmptyState(
                  title: 'No users available',
                  message: 'No unlinked users found.',
                )
              : ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final user = filtered[index];
                    final selected = _selectedId == user.id;
                    return ListTile(
                      onTap: () => setState(() => _selectedId = user.id),
                      leading: Icon(
                        selected
                            ? Icons.radio_button_checked_rounded
                            : Icons.radio_button_unchecked_rounded,
                        size: 18,
                      ),
                      title: Text(user.name),
                      subtitle: Text('@${user.username} • ${user.phone}'),
                    );
                  },
                ),
        ),
        Padding(
          padding: const EdgeInsets.all(OpenVtsSpacing.md),
          child: OpenVtsButton(
            label: 'Assign',
            isLoading: state.isAssigningUser,
            onPressed: state.isAssigningUser
                ? null
                : () async {
                    final id = _selectedId;
                    if (id == null || id.trim().isEmpty) {
                      ToastHelper.showError(
                        'Select a user first.',
                        context: context,
                      );
                      return;
                    }
                    final ok =
                        await ref.read(widget.provider.notifier).assignUser(id);
                    if (!mounted) return;
                    if (ok) {
                      Navigator.of(this.context).pop();
                      ToastHelper.showSuccess(
                        'User assigned.',
                        context: this.context,
                      );
                    } else {
                      ToastHelper.showError(
                        ref.read(widget.provider).sectionErrorMessage ??
                            'Unable to assign user.',
                        context: this.context,
                      );
                    }
                  },
          ),
        ),
      ],
    );
  }
}
