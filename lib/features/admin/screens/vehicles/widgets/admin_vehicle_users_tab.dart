import 'package:flutter/material.dart';

import '../../../../../core/theme/open_vts_spacing.dart';
import '../../../../../shared/widgets/open_vts_bottom_sheet.dart';
import '../../../../../shared/widgets/open_vts_button.dart';
import '../../../../../shared/widgets/open_vts_card.dart';
import '../../../../../shared/widgets/open_vts_empty_state.dart';
import '../../../../../shared/widgets/open_vts_loader.dart';
import '../../../models/admin_vehicle_model.dart';

class AdminVehicleUsersTab extends StatelessWidget {
  const AdminVehicleUsersTab({
    super.key,
    required this.isLoading,
    required this.isLinking,
    required this.isUnlinking,
    required this.linkedUsers,
    required this.availableUsers,
    required this.onRefresh,
    required this.onLinkUser,
    required this.onUnlinkUser,
  });

  final bool isLoading;
  final bool isLinking;
  final bool isUnlinking;
  final List<AdminVehicleUserMini> linkedUsers;
  final List<AdminVehicleUserMini> availableUsers;
  final Future<void> Function() onRefresh;
  final Future<void> Function(String userId) onLinkUser;
  final Future<void> Function(String userId) onUnlinkUser;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const OpenVtsLoader();
    }

    return Column(
      children: [
        OpenVtsCard(
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Linked Users (${linkedUsers.length})',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              OpenVtsButton(
                label: 'Assign User',
                variant: OpenVtsButtonVariant.secondary,
                onPressed: availableUsers.isEmpty
                    ? null
                    : () => _openAssignSheet(context),
              ),
            ],
          ),
        ),
        const SizedBox(height: OpenVtsSpacing.sm),
        if (linkedUsers.isEmpty)
          const OpenVtsEmptyState(
            title: 'No linked users',
            message: 'Assign users to this vehicle.',
          )
        else
          ...linkedUsers.map(
            (user) => Padding(
              padding: const EdgeInsets.only(bottom: OpenVtsSpacing.sm),
              child: OpenVtsCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name.isEmpty ? user.mobileDisplay : user.name,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: OpenVtsSpacing.xxs),
                    Text('Username: ${_safe(user.username)}'),
                    Text('Email: ${_safe(user.email)}'),
                    Text('Mobile: ${_safe(user.mobileDisplay)}'),
                    const SizedBox(height: OpenVtsSpacing.sm),
                    Align(
                      alignment: Alignment.centerRight,
                      child: OpenVtsButton(
                        label: 'Unassign',
                        isLoading: isUnlinking,
                        variant: OpenVtsButtonVariant.secondary,
                        onPressed: isUnlinking
                            ? null
                            : () async {
                                await onUnlinkUser(user.id);
                                await onRefresh();
                              },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _openAssignSheet(BuildContext context) {
    return OpenVtsBottomSheet.show<void>(
      context: context,
      title: 'Assign User',
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      child: _AssignUserSheet(
        users: availableUsers,
        isLinking: isLinking,
        onAssign: (userId) async {
          await onLinkUser(userId);
          await onRefresh();
          if (context.mounted) {
            Navigator.of(context).pop();
          }
        },
      ),
    );
  }

  String _safe(String value) => value.trim().isEmpty ? '-' : value.trim();
}

class _AssignUserSheet extends StatefulWidget {
  const _AssignUserSheet({
    required this.users,
    required this.isLinking,
    required this.onAssign,
  });

  final List<AdminVehicleUserMini> users;
  final bool isLinking;
  final Future<void> Function(String userId) onAssign;

  @override
  State<_AssignUserSheet> createState() => _AssignUserSheetState();
}

class _AssignUserSheetState extends State<_AssignUserSheet> {
  String _query = '';
  String? _selectedUserId;

  @override
  Widget build(BuildContext context) {
    final filtered = widget.users.where((user) {
      final q = _query.trim().toLowerCase();
      if (q.isEmpty) return true;
      return <String>[
        user.name,
        user.username,
        user.email,
        user.mobileDisplay,
      ].join(' ').toLowerCase().contains(q);
    }).toList(growable: false);

    return ListView(
      padding: const EdgeInsets.all(OpenVtsSpacing.md),
      children: [
        TextField(
          decoration: const InputDecoration(
            hintText: 'Search unlinked users...',
            prefixIcon: Icon(Icons.search_rounded),
          ),
          onChanged: (value) => setState(() => _query = value),
        ),
        const SizedBox(height: OpenVtsSpacing.sm),
        if (filtered.isEmpty)
          const OpenVtsEmptyState(
            title: 'No users',
            message: 'No unlinked users match your search.',
          )
        else
          ...filtered.map(
            (user) => RadioListTile<String>(
              value: user.id,
              // ignore: deprecated_member_use
              groupValue: _selectedUserId,
              // ignore: deprecated_member_use
              onChanged: (value) => setState(() => _selectedUserId = value),
              title: Text(user.name.isEmpty ? user.mobileDisplay : user.name),
              subtitle: Text(
                [user.username, user.email]
                    .where((item) => item.trim().isNotEmpty)
                    .join(' • '),
              ),
            ),
          ),
        const SizedBox(height: OpenVtsSpacing.sm),
        OpenVtsButton(
          label: 'Assign',
          isLoading: widget.isLinking,
          onPressed: _selectedUserId == null || widget.isLinking
              ? null
              : () => widget.onAssign(_selectedUserId!),
        ),
      ],
    );
  }
}
