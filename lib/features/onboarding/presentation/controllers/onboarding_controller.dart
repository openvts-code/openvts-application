import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_vts/core/providers/shared_preferences_provider.dart';
import 'package:open_vts/features/onboarding/models/onboarding_model.dart';

final onboardingControllerProvider =
    StateNotifierProvider<OnboardingController, int>((ref) {
  return OnboardingController();
});

const onboardingCompletedStorageKey = 'onboarding_completed';

final onboardingCompletedProvider = StateProvider<bool>((ref) {
  final sharedPreferences = ref.watch(sharedPreferencesProvider);
  return sharedPreferences.getBool(onboardingCompletedStorageKey) ?? false;
});

class OnboardingController extends StateNotifier<int> {
  OnboardingController() : super(0);

  final List<OnboardingModel> pages = [
    OnboardingModel(
      image: 'assets/images/onboarding_1.png',
      title: 'IMAGINATION',
      subtitle: 'Here you will get unlimited imagination and play your talents',
    ),
    OnboardingModel(
      image: 'assets/images/onboarding_2.png',
      title: 'CREATION',
      subtitle:
          'Music is one of the ways to inspire, it can make you become infinite',
    ),
    OnboardingModel(
      image: 'assets/images/onboarding_3.png',
      title: 'CREATION',
      subtitle:
          'Music is one of the ways to inspire, it can make you become infinite',
    ),
  ];

  void onPageChanged(int index) {
    state = index;
  }

  void nextPage() {
    if (state < pages.length - 1) {
      state++;
    }
  }
}
