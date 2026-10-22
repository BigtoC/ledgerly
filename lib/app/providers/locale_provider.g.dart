// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'locale_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(initialPreferredLocale)
final initialPreferredLocaleProvider = InitialPreferredLocaleProvider._();

final class InitialPreferredLocaleProvider
    extends $FunctionalProvider<Locale?, Locale?, Locale?>
    with $Provider<Locale?> {
  InitialPreferredLocaleProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'initialPreferredLocaleProvider',
        isAutoDispose: false,
        dependencies: <ProviderOrFamily>[],
        $allTransitiveDependencies: <ProviderOrFamily>[],
      );

  @override
  String debugGetCreateSourceHash() => _$initialPreferredLocaleHash();

  @$internal
  @override
  $ProviderElement<Locale?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Locale? create(Ref ref) {
    return initialPreferredLocale(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Locale? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Locale?>(value),
    );
  }
}

String _$initialPreferredLocaleHash() =>
    r'a47461f656c137fcbef03470866c468aa7be6e08';

@ProviderFor(userLocalePreferenceStream)
final userLocalePreferenceStreamProvider =
    UserLocalePreferenceStreamProvider._();

final class UserLocalePreferenceStreamProvider
    extends $FunctionalProvider<AsyncValue<Locale?>, Locale?, Stream<Locale?>>
    with $FutureModifier<Locale?>, $StreamProvider<Locale?> {
  UserLocalePreferenceStreamProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'userLocalePreferenceStreamProvider',
        isAutoDispose: false,
        dependencies: <ProviderOrFamily>[userPreferencesRepositoryProvider],
        $allTransitiveDependencies: <ProviderOrFamily>[
          UserLocalePreferenceStreamProvider.$allTransitiveDependencies0,
          UserLocalePreferenceStreamProvider.$allTransitiveDependencies1,
        ],
      );

  static final $allTransitiveDependencies0 = userPreferencesRepositoryProvider;
  static final $allTransitiveDependencies1 =
      UserPreferencesRepositoryProvider.$allTransitiveDependencies0;

  @override
  String debugGetCreateSourceHash() => _$userLocalePreferenceStreamHash();

  @$internal
  @override
  $StreamProviderElement<Locale?> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<Locale?> create(Ref ref) {
    return userLocalePreferenceStream(ref);
  }
}

String _$userLocalePreferenceStreamHash() =>
    r'c842847fca72be055f73981d0ff5c7f966b4e4f9';

@ProviderFor(userLocalePreference)
final userLocalePreferenceProvider = UserLocalePreferenceProvider._();

final class UserLocalePreferenceProvider
    extends $FunctionalProvider<Locale?, Locale?, Locale?>
    with $Provider<Locale?> {
  UserLocalePreferenceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'userLocalePreferenceProvider',
        isAutoDispose: true,
        dependencies: <ProviderOrFamily>[
          userLocalePreferenceStreamProvider,
          initialPreferredLocaleProvider,
        ],
        $allTransitiveDependencies: <ProviderOrFamily>{
          UserLocalePreferenceProvider.$allTransitiveDependencies0,
          UserLocalePreferenceProvider.$allTransitiveDependencies1,
          UserLocalePreferenceProvider.$allTransitiveDependencies2,
          UserLocalePreferenceProvider.$allTransitiveDependencies3,
        },
      );

  static final $allTransitiveDependencies0 = userLocalePreferenceStreamProvider;
  static final $allTransitiveDependencies1 =
      UserLocalePreferenceStreamProvider.$allTransitiveDependencies0;
  static final $allTransitiveDependencies2 =
      UserLocalePreferenceStreamProvider.$allTransitiveDependencies1;
  static final $allTransitiveDependencies3 = initialPreferredLocaleProvider;

  @override
  String debugGetCreateSourceHash() => _$userLocalePreferenceHash();

  @$internal
  @override
  $ProviderElement<Locale?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Locale? create(Ref ref) {
    return userLocalePreference(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Locale? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Locale?>(value),
    );
  }
}

String _$userLocalePreferenceHash() =>
    r'ad7f67e9d7cd82b5b6f23372dcf958062e68b2ab';
