import 'package:flutter/material.dart';
import 'package:open_vts/core/theme/open_vts_colors.dart';

class PageIndicator extends StatelessWidget {
  final bool isActive;

  const PageIndicator({super.key, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      margin: const EdgeInsets.symmetric(horizontal: 4.0),
      height: isActive ? 12.0 : 8.0,
      width: isActive ? 12.0 : 8.0,
      decoration: BoxDecoration(
        color: isActive ? OpenVtsColors.brandInk : OpenVtsColors.border,
        borderRadius: const BorderRadius.all(Radius.circular(12)),
      ),
    );
  }
}
