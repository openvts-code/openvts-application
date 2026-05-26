import 'package:flutter/material.dart';

import '../../../../../core/theme/open_vts_spacing.dart';
import 'admin_support_ticket_form.dart';

class AdminCreateMyTicketSheet extends StatelessWidget {
  const AdminCreateMyTicketSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return const AdminSupportTicketForm(
      mode: AdminSupportTicketFormMode.my,
      showHelperCard: false,
      contentPadding: EdgeInsets.all(OpenVtsSpacing.md),
    );
  }
}
