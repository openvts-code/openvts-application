import 'package:flutter/material.dart';

import '../../../../../core/theme/open_vts_spacing.dart';
import '../../../models/admin_inventory_model.dart';
import 'admin_inventory_card_shared.dart';

class AdminInventoryDeviceCard extends StatelessWidget {
  const AdminInventoryDeviceCard({
    required this.device,
    required this.onEdit,
    required this.isEditing,
    super.key,
  });

  final AdminInventoryDevice device;
  final VoidCallback onEdit;
  final bool isEditing;

  @override
  Widget build(BuildContext context) {
    final imei = device.imei.trim().isEmpty ? '—' : device.imei.trim();
    final simValue = device.assignedSimNumber.trim().isEmpty
        ? 'Unassigned'
        : device.assignedSimNumber.trim();

    return AdminInventoryRoundedSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AdminInventoryCardHeader(
            icon: Icons.memory_outlined,
            title: imei,
            isActive: device.isActive,
            onEdit: onEdit,
            isEditing: isEditing,
          ),
          const SizedBox(height: OpenVtsSpacing.md),
          AdminInventoryInfoField(
            icon: Icons.sim_card_outlined,
            label: 'SIM',
            value: simValue,
          ),
          const SizedBox(height: OpenVtsSpacing.md),
          AdminInventoryCardFooter(
            createdValue:
                AdminInventoryCardFooter.formatCreatedAt(device.createdAt),
            statusLabel: formatInventoryStatusLabel(device.statusLabel),
          ),
        ],
      ),
    );
  }
}
