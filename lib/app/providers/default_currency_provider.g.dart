// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'default_currency_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$defaultCurrencyHash() => r'343f988e90cf6a3b4600129ca8e88e65d1c98813';

/// Stream of the user's default currency ISO code, backed by Drift's
/// `watchDefaultCurrency()`. The bootstrap-known initial value is
/// provided synchronously via `initialDefaultCurrencyProvider` so UI
/// tiles do not flicker through a `'USD'` fallback on cold start.
///
/// Copied from [defaultCurrency].
@ProviderFor(defaultCurrency)
final defaultCurrencyProvider = StreamProvider<String>.internal(
  defaultCurrency,
  name: r'defaultCurrencyProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$defaultCurrencyHash,
  dependencies: <ProviderOrFamily>[userPreferencesRepositoryProvider],
  allTransitiveDependencies: <ProviderOrFamily>{
    userPreferencesRepositoryProvider,
    ...?userPreferencesRepositoryProvider.allTransitiveDependencies,
  },
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef DefaultCurrencyRef = StreamProviderRef<String>;
String _$initialDefaultCurrencyHash() =>
    r'd96062f6de5f3795d858097d4fd712a620ad1580';

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
///
/// Copied from [initialDefaultCurrency].
@ProviderFor(initialDefaultCurrency)
final initialDefaultCurrencyProvider = Provider<String>.internal(
  initialDefaultCurrency,
  name: r'initialDefaultCurrencyProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$initialDefaultCurrencyHash,
  dependencies: const <ProviderOrFamily>[],
  allTransitiveDependencies: const <ProviderOrFamily>{},
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef InitialDefaultCurrencyRef = ProviderRef<String>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
