// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'default_currency_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Stream of the user's default currency ISO code, backed by Drift's
/// `watchDefaultCurrency()`. The bootstrap-known initial value is
/// provided synchronously via `initialDefaultCurrencyProvider` so UI
/// tiles do not flicker through a `'USD'` fallback on cold start.

@ProviderFor(defaultCurrency)
final defaultCurrencyProvider = DefaultCurrencyProvider._();

/// Stream of the user's default currency ISO code, backed by Drift's
/// `watchDefaultCurrency()`. The bootstrap-known initial value is
/// provided synchronously via `initialDefaultCurrencyProvider` so UI
/// tiles do not flicker through a `'USD'` fallback on cold start.

final class DefaultCurrencyProvider
    extends $FunctionalProvider<AsyncValue<String>, String, Stream<String>>
    with $FutureModifier<String>, $StreamProvider<String> {
  /// Stream of the user's default currency ISO code, backed by Drift's
  /// `watchDefaultCurrency()`. The bootstrap-known initial value is
  /// provided synchronously via `initialDefaultCurrencyProvider` so UI
  /// tiles do not flicker through a `'USD'` fallback on cold start.
  DefaultCurrencyProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'defaultCurrencyProvider',
        isAutoDispose: false,
        dependencies: <ProviderOrFamily>[userPreferencesRepositoryProvider],
        $allTransitiveDependencies: <ProviderOrFamily>[
          DefaultCurrencyProvider.$allTransitiveDependencies0,
          DefaultCurrencyProvider.$allTransitiveDependencies1,
        ],
      );

  static final $allTransitiveDependencies0 = userPreferencesRepositoryProvider;
  static final $allTransitiveDependencies1 =
      UserPreferencesRepositoryProvider.$allTransitiveDependencies0;

  @override
  String debugGetCreateSourceHash() => _$defaultCurrencyHash();

  @$internal
  @override
  $StreamProviderElement<String> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<String> create(Ref ref) {
    return defaultCurrency(ref);
  }
}

String _$defaultCurrencyHash() => r'343f988e90cf6a3b4600129ca8e88e65d1c98813';

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

@ProviderFor(initialDefaultCurrency)
final initialDefaultCurrencyProvider = InitialDefaultCurrencyProvider._();

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

final class InitialDefaultCurrencyProvider
    extends $FunctionalProvider<String, String, String>
    with $Provider<String> {
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
  InitialDefaultCurrencyProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'initialDefaultCurrencyProvider',
        isAutoDispose: false,
        dependencies: <ProviderOrFamily>[],
        $allTransitiveDependencies: <ProviderOrFamily>[],
      );

  @override
  String debugGetCreateSourceHash() => _$initialDefaultCurrencyHash();

  @$internal
  @override
  $ProviderElement<String> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  String create(Ref ref) {
    return initialDefaultCurrency(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String>(value),
    );
  }
}

String _$initialDefaultCurrencyHash() =>
    r'd96062f6de5f3795d858097d4fd712a620ad1580';
