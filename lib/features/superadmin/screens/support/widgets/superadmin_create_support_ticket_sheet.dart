import 'package:flutter/material.dart';

import '../../../../../core/theme/open_vts_spacing.dart';
import 'superadmin_support_ticket_form.dart';

class SuperadminCreateSupportTicketSheet extends StatelessWidget {
  const SuperadminCreateSupportTicketSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return const SuperadminSupportTicketForm(
      showHelperCard: false,
      contentPadding: EdgeInsets.all(OpenVtsSpacing.md),
    );
  }
}
