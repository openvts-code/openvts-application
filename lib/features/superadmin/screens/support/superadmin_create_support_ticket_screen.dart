import 'package:flutter/material.dart';

import '../../../../core/theme/open_vts_spacing.dart';
import '../../../../shared/widgets/open_vts_page_scaffold.dart';
import 'widgets/superadmin_support_ticket_form.dart';

class SuperadminCreateSupportTicketScreen extends StatelessWidget {
  const SuperadminCreateSupportTicketScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const OpenVtsPageScaffold(
      title: 'Create Ticket',
      headerMode: OpenVtsPageHeaderMode.closeable,
      padding: EdgeInsets.zero,
      body: SuperadminSupportTicketForm(
        contentPadding: EdgeInsets.all(OpenVtsSpacing.sm),
      ),
    );
  }
}
