// TODO(M5): replace entire file with day-counter UI per PRD → Splash Screen.
// Sun-themed background, large day count, rainbow-gradient start date,
// customisable display text / button label, fade transition to Home on tap.
// Golden tests in `test/widget/features/splash/` are mandatory.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers/repository_providers.dart';
import '../../app/providers/splash_redirect_provider.dart';
import '../../l10n/app_localizations.dart';

class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final startDate = ref.watch(splashStartDateProvider).value;

    if (startDate == null) {
      return Scaffold(
        body: Center(
          child: TextButton(
            onPressed: () => ref
                .read(userPreferencesRepositoryProvider)
                .setSplashStartDate(DateTime.now()),
            child: Text(l10n.splashSetStartDate),
          ),
        ),
      );
    }

    return Scaffold(
      body: Center(
        child: TextButton(
          onPressed: () => context.go('/home'),
          child: Text(l10n.splashEnter),
        ),
      ),
    );
  }
}
