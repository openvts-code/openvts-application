import 'package:flutter/material.dart';
import 'package:open_vts/features/onboarding/models/onboarding_model.dart';

class OnboardingPage extends StatelessWidget {
  final OnboardingModel page;

  const OnboardingPage({super.key, required this.page});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset(page.image, height: 300),
        const SizedBox(height: 40),
        Text(
          page.title,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            page.subtitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      ],
    );
  }
}
