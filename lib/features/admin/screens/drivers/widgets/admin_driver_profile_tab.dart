import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/open_vts_colors.dart';
import '../../../../../core/theme/open_vts_radius.dart';
import '../../../../../core/theme/open_vts_spacing.dart';
import '../../../../../core/utils/date_time_formatter.dart';
import '../../../../../shared/helpers/toast_helper.dart';
import '../../../../../shared/widgets/open_vts_card.dart';
import '../../../controllers/admin_driver_details_controller.dart';
import '../../../models/admin_driver_details_model.dart';
import '../../../models/admin_driver_details_state.dart';

class AdminDriverProfileTab extends ConsumerWidget {
  const AdminDriverProfileTab({
    required this.provider,
    required this.state,
    super.key,
  });

  final AutoDisposeStateNotifierProvider<AdminDriverDetailsController,
      AdminDriverDetailsState> provider;
  final AdminDriverDetailsState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(provider.notifier);
    final driver = state.driver;
    if (driver == null) {
      return const OpenVtsCard(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: OpenVtsSpacing.md),
          child: Text('Driver details are unavailable.'),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _IdentityCard(
          driver: driver,
          isUpdatingStatus: state.isUpdatingStatus,
          onToggleStatus: () async {
            final ok = await controller.updateStatus(!driver.isActive);
            if (!context.mounted) return;
            if (ok) {
              ToastHelper.showSuccess(
                !driver.isActive ? 'Driver activated.' : 'Driver deactivated.',
                context: context,
              );
            } else {
              ToastHelper.showError(
                ref.read(provider).sectionErrorMessage ??
                    'Unable to update status.',
                context: context,
              );
            }
          },
        ),
        const SizedBox(height: OpenVtsSpacing.sm),
        _LocationCard(driver: driver),
        const SizedBox(height: OpenVtsSpacing.sm),
        _TimelineCard(driver: driver),
        if (driver.attributes.isNotEmpty) ...[
          const SizedBox(height: OpenVtsSpacing.sm),
          _AdditionalAttributesCard(attributes: driver.attributes),
        ],
        const SizedBox(height: OpenVtsSpacing.lg),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard(
      {required this.title, required this.children, this.trailing});

  final String title;
  final List<Widget> children;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return OpenVtsCard(
      padding: const EdgeInsets.fromLTRB(
        OpenVtsSpacing.md,
        OpenVtsSpacing.sm,
        OpenVtsSpacing.md,
        OpenVtsSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: OpenVtsColors.textTertiary,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: OpenVtsSpacing.xs),
          const Divider(height: 1, color: OpenVtsColors.border),
          const SizedBox(height: OpenVtsSpacing.xs),
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.icon,
    this.valueColor,
  });

  final String label;
  final String value;
  final IconData? icon;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: OpenVtsColors.textTertiary),
            const SizedBox(width: 8),
          ],
          SizedBox(
            width: 96,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: OpenVtsColors.textTertiary,
                height: 1.3,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.trim().isEmpty ? '—' : value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: valueColor ?? OpenVtsColors.textPrimary,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.isActive});
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? OpenVtsColors.success : OpenVtsColors.textTertiary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(OpenVtsRadius.pill),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        isActive ? 'Active' : 'Inactive',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _IdentityCard extends StatelessWidget {
  const _IdentityCard({
    required this.driver,
    required this.isUpdatingStatus,
    required this.onToggleStatus,
  });

  final AdminDriverDetails driver;
  final bool isUpdatingStatus;
  final VoidCallback onToggleStatus;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'IDENTITY',
      trailing: _StatusBadge(isActive: driver.isActive),
      children: [
        _InfoRow(
            label: 'Name',
            value: driver.name,
            icon: Icons.person_outline_rounded),
        _InfoRow(
            label: 'Username',
            value: driver.username,
            icon: Icons.alternate_email_rounded),
        _InfoRow(
            label: 'Email',
            value: driver.email,
            icon: Icons.mail_outline_rounded),
        _InfoRow(
            label: 'Phone', value: driver.phone, icon: Icons.phone_outlined),
        const _InfoRow(
          label: 'Role',
          value: 'Driver',
          icon: Icons.badge_outlined,
        ),
        _InfoRow(
          label: 'Verified',
          value: driver.isVerified ? 'Verified' : 'Unverified',
          icon: Icons.verified_outlined,
          valueColor: driver.isVerified
              ? OpenVtsColors.success
              : OpenVtsColors.textSecondary,
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Icon(
              driver.isActive
                  ? Icons.toggle_on_rounded
                  : Icons.toggle_off_outlined,
              size: 16,
              color: driver.isActive
                  ? OpenVtsColors.success
                  : OpenVtsColors.textTertiary,
            ),
            const SizedBox(width: 8),
            const Text(
              'Account status',
              style: TextStyle(
                fontSize: 11,
                color: OpenVtsColors.textTertiary,
              ),
            ),
            const Spacer(),
            if (isUpdatingStatus)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Switch.adaptive(
                value: driver.isActive,
                onChanged: (_) => onToggleStatus(),
              ),
          ],
        ),
      ],
    );
  }
}

class _LocationCard extends StatelessWidget {
  const _LocationCard({required this.driver});

  final AdminDriverDetails driver;

  @override
  Widget build(BuildContext context) {
    final address = driver.address;
    final fullAddress = address.fullAddress.trim();
    final composedLine = [
      address.addressLine,
      address.cityId,
      address.stateCode,
      address.countryCode,
      address.pincode,
    ].where((v) => v.trim().isNotEmpty && v.trim() != '-').join(', ');

    return _SectionCard(
      title: 'LOCATION',
      children: [
        _InfoRow(
          label: 'Address',
          value: address.addressLine,
          icon: Icons.home_work_outlined,
        ),
        _InfoRow(
            label: 'City',
            value: address.cityId,
            icon: Icons.location_city_outlined),
        _InfoRow(
            label: 'State', value: address.stateCode, icon: Icons.map_outlined),
        _InfoRow(
          label: 'Country',
          value: address.countryCode.isNotEmpty
              ? address.countryCode
              : driver.countryCode,
          icon: Icons.public_outlined,
        ),
        _InfoRow(
            label: 'Pincode',
            value: address.pincode,
            icon: Icons.pin_drop_outlined),
        if (fullAddress.isNotEmpty &&
            fullAddress != '-' &&
            fullAddress != composedLine)
          _InfoRow(
            label: 'Full address',
            value: fullAddress,
            icon: Icons.place_outlined,
          ),
      ],
    );
  }
}

class _TimelineCard extends StatelessWidget {
  const _TimelineCard({required this.driver});

  final AdminDriverDetails driver;

  @override
  Widget build(BuildContext context) {
    final formatter = const DateTimeFormatter();
    return _SectionCard(
      title: 'TIMELINE',
      children: [
        _InfoRow(
          label: 'Created',
          value: driver.createdAt == null
              ? '—'
              : formatter.formatDateTime(driver.createdAt!),
          icon: Icons.event_available_outlined,
        ),
        _InfoRow(
          label: 'Updated',
          value: driver.updatedAt == null
              ? '—'
              : formatter.formatDateTime(driver.updatedAt!),
          icon: Icons.update_outlined,
        ),
      ],
    );
  }
}

class _AdditionalAttributesCard extends StatelessWidget {
  const _AdditionalAttributesCard({required this.attributes});

  final Map<String, dynamic> attributes;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'ADDITIONAL ATTRIBUTES',
      children: attributes.entries
          .map(
            (entry) => _InfoRow(
              label: _labelize(entry.key),
              value: (entry.value?.toString().trim().isNotEmpty ?? false)
                  ? entry.value.toString()
                  : '—',
              icon: Icons.data_object_outlined,
            ),
          )
          .toList(),
    );
  }

  String _labelize(String key) {
    final raw = key.replaceAll('_', ' ').trim();
    if (raw.isEmpty) return key;
    return raw
        .split(RegExp(r'\s+'))
        .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }
}
