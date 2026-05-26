import 'package:flutter/material.dart';

import '../../../../../core/theme/open_vts_colors.dart';
import '../../../../../core/utils/date_time_formatter.dart';

import 'package:open_vts/shared/widgets/support/open_vts_support_ticket_card.dart';
import '../../../models/admin_support_model.dart';

const DateTimeFormatter _dateFormatter = DateTimeFormatter();

class AdminSupportTicketCard extends StatelessWidget {
  const AdminSupportTicketCard({
    required this.ticket,
    required this.tab,
    this.onTap,
    this.isSelected = false,
    super.key,
  });

  final AdminSupportTicketListItem ticket;
  final AdminSupportTab tab;
  final VoidCallback? onTap;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final activityDate =
        ticket.lastMessageAt ?? ticket.updatedAt ?? ticket.createdAt;
    final statusColor = switch (ticket.status) {
      AdminSupportTicketStatus.open => OpenVtsColors.success,
      AdminSupportTicketStatus.inProgress => OpenVtsColors.info,
      AdminSupportTicketStatus.closed => OpenVtsColors.textTertiary,
    };

    final priorityColor = switch (ticket.priority) {
      AdminSupportTicketPriority.high => OpenVtsColors.warning,
      AdminSupportTicketPriority.medium => OpenVtsColors.info,
      AdminSupportTicketPriority.low => OpenVtsColors.textTertiary,
    };

    final roleMeta = _roleMetaLabel;

    return OpenVtsSupportTicketCard(
      title: ticket.title,
      ticketNumber: ticket.displayTicketNo,
      statusLabel: ticket.status.label,
      statusColor: statusColor,
      priorityLabel: ticket.priority.label,
      priorityColor: priorityColor,
      categoryLabel: ticket.category.label,
      extraMetaLabels: roleMeta == null ? const <String>[] : <String>[roleMeta],
      dateLabel: activityDate == null
          ? 'No activity yet'
          : _dateFormatter.formatDateTime(activityDate),
      messageCountLabel: null,
      preview: null,
      isSelected: isSelected,
      onTap: onTap,
    );
  }

  String? get _roleMetaLabel {
    final source =
        tab == AdminSupportTab.userTickets ? ticket.fromUser : ticket.toUser;
    final name = source?.displayName.trim() ?? '';
    if (name.isEmpty || name == '-') {
      return null;
    }

    return tab == AdminSupportTab.userTickets ? 'User $name' : 'To $name';
  }
}


