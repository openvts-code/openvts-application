import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/open_vts_spacing.dart';
import '../../../../shared/widgets/open_vts_page_scaffold.dart';
import '../../controllers/admin_providers.dart';
import '../../models/admin_support_model.dart';
import 'widgets/admin_support_ticket_form.dart';

class AdminCreateSupportTicketScreen extends ConsumerWidget {
  const AdminCreateSupportTicketScreen({this.mode, super.key});

  final String? mode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedTab = ref.watch(
      adminSupportControllerProvider.select((state) => state.selectedTab),
    );
    final resolvedMode = _resolveMode(mode, selectedTab);

    return OpenVtsPageScaffold(
      title: 'Create Ticket',
      headerMode: OpenVtsPageHeaderMode.closeable,
      padding: EdgeInsets.zero,
      body: AdminSupportTicketForm(
        mode: resolvedMode == _AdminCreateMode.user
            ? AdminSupportTicketFormMode.user
            : AdminSupportTicketFormMode.my,
        contentPadding: const EdgeInsets.all(OpenVtsSpacing.sm),
      ),
    );
  }

  _AdminCreateMode _resolveMode(String? rawMode, AdminSupportTab selectedTab) {
    switch (rawMode?.trim().toLowerCase()) {
      case 'user':
        return _AdminCreateMode.user;
      case 'my':
        return _AdminCreateMode.my;
      default:
        return selectedTab == AdminSupportTab.userTickets
            ? _AdminCreateMode.user
            : _AdminCreateMode.my;
    }
  }
}

enum _AdminCreateMode { user, my }
