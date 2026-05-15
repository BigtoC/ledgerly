import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'repository_providers.dart';

part 'default_currency_provider.g.dart';

/// Stream of the user's default currency ISO code, backed by Drift's
/// `watchDefaultCurrency()`. The bootstrap-known initial value is
/// provided synchronously via `initialDefaultCurrencyProvider` so UI
/// tiles do not flicker through a `'USD'` fallback on cold start.
@Riverpod(keepAlive: true, dependencies: [userPreferencesRepository])
Stream<String> defaultCurrency(Ref ref) {
  return ref.watch(userPreferencesRepositoryProvider).watchDefaultCurrency();
}

/// Bootstrap-provided initial value of the default currency. Overridden
/// in `bootstrap.dart` with the value read from `UserPreferencesRepository`
/// before `runApp`, so UI tiles can synchronously resolve the default
/// currency on first frame without going through the AsyncValue
/// loading state.
///
/// Defaults to `'USD'` so widget tests that do not exercise the bootstrap
/// path do not need to override it; production paths always override.
/// Pattern mirrors `initialThemeModeProvider` and
/// `initialPreferredLocaleProvider`.
@Riverpod(keepAlive: true, dependencies: [])
String initialDefaultCurrency(Ref ref) => 'USD';
