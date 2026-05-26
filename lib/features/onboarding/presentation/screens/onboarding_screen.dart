import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_vts/core/providers/shared_preferences_provider.dart';
import 'package:open_vts/core/theme/open_vts_colors.dart';
import 'package:open_vts/features/onboarding/presentation/controllers/onboarding_controller.dart';
import 'package:open_vts/features/onboarding/presentation/widgets/onboarding_page.dart';
import 'package:open_vts/features/onboarding/presentation/widgets/page_indicator.dart';

class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(onboardingControllerProvider.notifier);
    final currentPage = ref.watch(onboardingControllerProvider);
    final pageController = PageController(initialPage: currentPage);

    return Scaffold(
      body: Stack(
        children: [
          PageView(
            controller: pageController,
            onPageChanged: controller.onPageChanged,
            children: controller.pages
                .map((page) => OnboardingPage(page: page))
                .toList(),
          ),
          Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                controller.pages.length,
                (index) => PageIndicator(isActive: index == currentPage),
              ),
            ),
          ),
          Positioned(
            bottom: 60,
            right: 30,
            child: FloatingActionButton(
              backgroundColor: OpenVtsColors.brandInk,
              onPressed: () async {
                if (currentPage < controller.pages.length - 1) {
                  pageController.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.ease,
                  );
                } else {
                  await ref.read(sharedPreferencesProvider).setBool(
                        onboardingCompletedStorageKey,
                        true,
                      );
                  ref.read(onboardingCompletedProvider.notifier).state = true;
                }
              },
              child: const Icon(Icons.arrow_forward, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
