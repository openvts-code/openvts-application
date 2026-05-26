import 'package:flutter/material.dart';

import '../../../../../core/theme/open_vts_spacing.dart';
import 'admin_support_ticket_form.dart';

class AdminCreateUserTicketSheet extends StatelessWidget {
  const AdminCreateUserTicketSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return const AdminSupportTicketForm(
      mode: AdminSupportTicketFormMode.user,
      showHelperCard: false,
      contentPadding: EdgeInsets.all(OpenVtsSpacing.md),
    );
  }
}
