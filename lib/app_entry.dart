import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_vts/features/onboarding/presentation/controllers/onboarding_controller.dart';
import 'package:open_vts/features/onboarding/presentation/screens/onboarding_screen.dart';

class AppEntry extends ConsumerWidget {
  const AppEntry({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onboardingCompleted = ref.watch(onboardingCompletedProvider);

    return onboardingCompleted ? child : const OnboardingScreen();
  }
}
