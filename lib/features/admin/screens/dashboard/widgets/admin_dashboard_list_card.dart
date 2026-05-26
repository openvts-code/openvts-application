import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../../core/theme/open_vts_colors.dart';
import '../../../../../core/theme/open_vts_radius.dart';
import '../../../../../core/theme/open_vts_spacing.dart';
import '../../../../../core/theme/open_vts_typography.dart';
import '../../../../../shared/widgets/open_vts_card.dart';

typedef AdminDashboardListItemBuilder = Widget Function(
  BuildContext context,
  int index,
);

class AdminDashboardListCard extends StatelessWidget {
  const AdminDashboardListCard({
    required this.title,
    required this.icon,
    required this.emptyTitle,
    required this.emptyMessage,
    required this.itemCount,
    required this.itemBuilder,
    this.viewAllRoute,
    this.maxVisibleItems = 5,
    super.key,
  });

  final String title;
  final IconData icon;
  final String emptyTitle;
  final String emptyMessage;
  final int itemCount;
  final AdminDashboardListItemBuilder itemBuilder;
  final String? viewAllRoute;
  final int maxVisibleItems;

  @override
  Widget build(BuildContext context) {
    return OpenVtsCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              OpenVtsSpacing.md,
              OpenVtsSpacing.sm,
              OpenVtsSpacing.sm,
              OpenVtsSpacing.sm,
            ),
            child: Row(
              children: [
                Expanded(
                    child: AdminDashboardListHeading(title: title, icon: icon)),
                if (viewAllRoute != null)
                  _ViewAllButton(
                    onPressed: () => context.push(viewAllRoute!),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (itemCount == 0)
            AdminDashboardCompactEmpty(
              icon: icon,
              title: emptyTitle,
              message: emptyMessage,
            )
          else
            _ListBody(
              itemCount: itemCount,
              maxVisibleItems: maxVisibleItems,
              itemBuilder: itemBuilder,
            ),
        ],
      ),
    );
  }
}

class AdminDashboardListHeading extends StatelessWidget {
  const AdminDashboardListHeading({
    required this.title,
    required this.icon,
    super.key,
  });

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: OpenVtsColors.surface,
            borderRadius: BorderRadius.circular(OpenVtsRadius.sm),
            border: Border.all(color: OpenVtsColors.border),
          ),
          child: Icon(icon, size: 16, color: OpenVtsColors.textSecondary),
        ),
        const SizedBox(width: OpenVtsSpacing.xs),
        Flexible(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: OpenVtsTypography.label.copyWith(
              color: OpenVtsColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class AdminDashboardInitialsAvatar extends StatelessWidget {
  const AdminDashboardInitialsAvatar({
    required this.name,
    this.size = 36,
    super.key,
  });

  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: OpenVtsColors.brandInk,
        shape: BoxShape.circle,
      ),
      child: Text(
        adminDashboardInitials(name),
        maxLines: 1,
        overflow: TextOverflow.clip,
        style: OpenVtsTypography.meta.copyWith(
          color: OpenVtsColors.white,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class AdminDashboardLeadingIcon extends StatelessWidget {
  const AdminDashboardLeadingIcon({required this.icon, super.key});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: OpenVtsColors.surface,
        borderRadius: BorderRadius.circular(OpenVtsRadius.md),
        border: Border.all(color: OpenVtsColors.border),
      ),
      child: Icon(icon, size: 17, color: OpenVtsColors.textSecondary),
    );
  }
}

class AdminDashboardStatusChip extends StatelessWidget {
  const AdminDashboardStatusChip({
    required this.label,
    this.icon,
    this.color = OpenVtsColors.textSecondary,
    super.key,
  });

  final String label;
  final IconData? icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: OpenVtsColors.surface,
        borderRadius: BorderRadius.circular(OpenVtsRadius.pill),
        border: Border.all(color: OpenVtsColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: OpenVtsTypography.meta.copyWith(
                color: OpenVtsColors.textSecondary,
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AdminDashboardCompactEmpty extends StatelessWidget {
  const AdminDashboardCompactEmpty({
    required this.icon,
    required this.title,
    required this.message,
    super.key,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(OpenVtsSpacing.md),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: OpenVtsColors.surface,
                borderRadius: BorderRadius.circular(OpenVtsRadius.md),
                border: Border.all(color: OpenVtsColors.border),
              ),
              child: Icon(icon, size: 18, color: OpenVtsColors.textTertiary),
            ),
            const SizedBox(height: OpenVtsSpacing.xs),
            Text(
              title,
              textAlign: TextAlign.center,
              style: OpenVtsTypography.label.copyWith(
                color: OpenVtsColors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              message,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: OpenVtsTypography.meta.copyWith(
                color: OpenVtsColors.textSecondary,
                fontSize: 10.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ListBody extends StatelessWidget {
  const _ListBody({
    required this.itemCount,
    required this.maxVisibleItems,
    required this.itemBuilder,
  });

  final int itemCount;
  final int maxVisibleItems;
  final AdminDashboardListItemBuilder itemBuilder;

  @override
  Widget build(BuildContext context) {
    final list = _DividedList(itemCount: itemCount, itemBuilder: itemBuilder);
    if (itemCount <= maxVisibleItems) {
      return list;
    }

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: (maxVisibleItems * 68) + (maxVisibleItems - 1),
      ),
      child: SingleChildScrollView(
        primary: false,
        physics: const BouncingScrollPhysics(),
        child: list,
      ),
    );
  }
}

class _DividedList extends StatelessWidget {
  const _DividedList({required this.itemCount, required this.itemBuilder});

  final int itemCount;
  final AdminDashboardListItemBuilder itemBuilder;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var index = 0; index < itemCount; index++) ...[
          if (index > 0) const Divider(height: 1),
          itemBuilder(context, index),
        ],
      ],
    );
  }
}

class _ViewAllButton extends StatelessWidget {
  const _ViewAllButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        foregroundColor: OpenVtsColors.textPrimary,
        textStyle: OpenVtsTypography.meta.copyWith(
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
        ),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('View All'),
          SizedBox(width: 3),
          Icon(Icons.arrow_forward_rounded, size: 14),
        ],
      ),
    );
  }
}

String adminDashboardInitials(String value) {
  final parts =
      value.trim().split(RegExp(r'\s+')).where((part) => part.isNotEmpty);
  final letters = parts.take(2).map((part) => part.characters.first).join();
  if (letters.isNotEmpty) {
    return letters.toUpperCase();
  }

  final compact = value.trim().replaceAll(RegExp(r'\s+'), '');
  if (compact.isEmpty) {
    return '?';
  }
  return compact.characters.take(2).toString().toUpperCase();
}

String adminDashboardFormatCurrency(num value, String currency) {
  final code = _normalizeCurrencyCode(currency);
  final locale = code == 'INR' ? 'en_IN' : 'en_US';
  final number = NumberFormat.decimalPattern(locale).format(value.round());

  if (!_knownCurrencyCodes.contains(code)) {
    return '$code $number';
  }

  try {
    return NumberFormat.simpleCurrency(
      locale: locale,
      name: code,
      decimalDigits: 0,
    ).format(value);
  } catch (_) {
    return '$code $number';
  }
}

String adminDashboardFormatNumber(num value) {
  return NumberFormat.decimalPattern('en_IN').format(value);
}

String adminDashboardRelativeDate(DateTime? value) {
  if (value == null) {
    return '-';
  }

  final now = DateTime.now();
  final localValue = value.toLocal();
  final difference = now.difference(localValue);
  if (difference.isNegative || difference.inMinutes < 1) {
    return 'just now';
  }
  if (difference.inHours < 1) {
    return '${difference.inMinutes}m ago';
  }
  if (difference.inHours < 24) {
    return '${difference.inHours}h ago';
  }
  if (difference.inDays == 1) {
    return 'yesterday';
  }
  if (difference.inDays < 7) {
    return '${difference.inDays}d ago';
  }
  return DateFormat('dd MMM yyyy').format(localValue);
}

String adminDashboardContactLabel(
    {required String email, required String username}) {
  if (email.trim().isNotEmpty) {
    return email.trim();
  }
  if (username.trim().isNotEmpty) {
    return username.trim();
  }
  return '-';
}

const Set<String> _knownCurrencyCodes = <String>{
  'AED',
  'AUD',
  'CAD',
  'CHF',
  'CNY',
  'EUR',
  'GBP',
  'INR',
  'JPY',
  'NZD',
  'SAR',
  'SGD',
  'USD',
};

String _normalizeCurrencyCode(String currency) {
  final raw = currency.trim().toUpperCase();
  const aliases = <String, String>{
    'CA': 'CAD',
    'US': 'USD',
    'IN': 'INR',
    'EU': 'EUR',
    'GB': 'GBP',
    'AE': 'AED',
  };
  return aliases[raw] ?? (raw.isEmpty ? 'USD' : raw);
}
