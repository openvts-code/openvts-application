import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/open_vts_spacing.dart';
import '../../../core/theme/open_vts_typography.dart';
import '../../../shared/widgets/open_vts_loader.dart';
import '../controllers/auth_controller.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(authControllerProvider.notifier).restoreSession();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/brand/icon.png', height: 56, errorBuilder: (_, __, ___) {
              return const Icon(Icons.navigation_outlined, size: 56);
            }),
            const SizedBox(height: OpenVtsSpacing.md),
            const Text('OpenVTS', style: OpenVtsTypography.titleMedium),
            const SizedBox(height: OpenVtsSpacing.lg),
            const OpenVtsLoader(),
          ],
        ),
      ),
    );
  }
}
