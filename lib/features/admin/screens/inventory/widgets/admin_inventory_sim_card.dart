import 'package:flutter/material.dart';

import '../../../../../core/theme/open_vts_spacing.dart';
import '../../../models/admin_inventory_model.dart';
import 'admin_inventory_card_shared.dart';

class AdminInventorySimCardWidget extends StatelessWidget {
  const AdminInventorySimCardWidget({
    required this.simCard,
    required this.onEdit,
    required this.isEditing,
    super.key,
  });

  final AdminInventorySimCard simCard;
  final VoidCallback onEdit;
  final bool isEditing;

  @override
  Widget build(BuildContext context) {
    final simNumber =
        simCard.simNumber.trim().isEmpty ? '—' : simCard.simNumber.trim();
    final deviceLabel = simCard.associatedDeviceImeis.isNotEmpty
        ? simCard.associatedDeviceImeis.first
        : (simCard.associatedDeviceImei.trim().isEmpty
            ? 'Unassigned'
            : simCard.associatedDeviceImei.trim());

    return AdminInventoryRoundedSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AdminInventoryCardHeader(
            icon: Icons.sim_card_outlined,
            title: simNumber,
            isActive: simCard.isActive,
            onEdit: onEdit,
            isEditing: isEditing,
          ),
          const SizedBox(height: OpenVtsSpacing.md),
          AdminInventoryInfoGrid(
            leftTop: AdminInventoryInfoField(
              icon: Icons.network_cell_rounded,
              label: 'Provider',
              value: simCard.provider,
            ),
            leftBottom: AdminInventoryInfoField(
              icon: Icons.hub_outlined,
              label: 'IMSI',
              value: simCard.imsi,
            ),
            rightTop: AdminInventoryInfoField(
              icon: Icons.tag_rounded,
              label: 'ICCID',
              value: simCard.iccid,
            ),
            rightBottom: AdminInventoryInfoField(
              icon: Icons.link_rounded,
              label: 'Device',
              value: deviceLabel,
            ),
          ),
          const SizedBox(height: OpenVtsSpacing.md),
          AdminInventoryCardFooter(
            createdValue:
                AdminInventoryCardFooter.formatCreatedAt(simCard.createdAt),
            statusLabel: formatInventoryStatusLabel(simCard.statusLabel),
          ),
        ],
      ),
    );
  }
}
