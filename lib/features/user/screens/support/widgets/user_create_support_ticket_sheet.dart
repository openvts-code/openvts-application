import 'package:flutter/material.dart';
import 'package:open_vts/core/theme/open_vts_spacing.dart';
import 'package:open_vts/features/user/screens/support/widgets/user_support_ticket_form.dart';

class UserCreateSupportTicketSheet extends StatelessWidget {
  const UserCreateSupportTicketSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final height = MediaQuery.sizeOf(context).height;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SafeArea(
        child: SizedBox(
          height: height * 0.9,
          child: const UserSupportTicketForm(
            showHelperCard: false,
            contentPadding: EdgeInsets.symmetric(
              horizontal: OpenVtsSpacing.md,
              vertical: OpenVtsSpacing.sm,
            ),
          ),
        ),
      ),
    );
  }
}
