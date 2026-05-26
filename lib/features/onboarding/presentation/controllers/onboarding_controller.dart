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
      title: 'Command Every Vehicle',
      subtitle:
          'See live location, routes, drivers, and activity from one secure control center built for serious fleet operations.',
    ),
    OnboardingModel(
      image: 'assets/images/onboarding_2.png',
      title: 'Your Data Stays Yours',
      subtitle:
          'OpenVTS keeps fleet data inside your own infrastructure, giving your business stronger security and privacy.',
    ),
    OnboardingModel(
      image: 'assets/images/onboarding_3.png',
      title: 'Own The Platform',
      subtitle:
          'No SaaS lock-in. No outside dependency. Run self-hosted GPS software with full control, access, and ownership.',
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
