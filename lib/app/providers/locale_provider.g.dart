// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'locale_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$initialPreferredLocaleHash() =>
    r'a47461f656c137fcbef03470866c468aa7be6e08';

/// See also [initialPreferredLocale].
@ProviderFor(initialPreferredLocale)
final initialPreferredLocaleProvider = Provider<Locale?>.internal(
  initialPreferredLocale,
  name: r'initialPreferredLocaleProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$initialPreferredLocaleHash,
  dependencies: const <ProviderOrFamily>[],
  allTransitiveDependencies: const <ProviderOrFamily>{},
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef InitialPreferredLocaleRef = ProviderRef<Locale?>;
String _$userLocalePreferenceStreamHash() =>
    r'c842847fca72be055f73981d0ff5c7f966b4e4f9';

/// See also [userLocalePreferenceStream].
@ProviderFor(userLocalePreferenceStream)
final userLocalePreferenceStreamProvider = StreamProvider<Locale?>.internal(
  userLocalePreferenceStream,
  name: r'userLocalePreferenceStreamProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$userLocalePreferenceStreamHash,
  dependencies: <ProviderOrFamily>[userPreferencesRepositoryProvider],
  allTransitiveDependencies: <ProviderOrFamily>{
    userPreferencesRepositoryProvider,
    ...?userPreferencesRepositoryProvider.allTransitiveDependencies,
  },
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef UserLocalePreferenceStreamRef = StreamProviderRef<Locale?>;
String _$userLocalePreferenceHash() =>
    r'ad7f67e9d7cd82b5b6f23372dcf958062e68b2ab';

/// See also [userLocalePreference].
@ProviderFor(userLocalePreference)
final userLocalePreferenceProvider = AutoDisposeProvider<Locale?>.internal(
  userLocalePreference,
  name: r'userLocalePreferenceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$userLocalePreferenceHash,
  dependencies: <ProviderOrFamily>[
    userLocalePreferenceStreamProvider,
    initialPreferredLocaleProvider,
  ],
  allTransitiveDependencies: <ProviderOrFamily>{
    userLocalePreferenceStreamProvider,
    ...?userLocalePreferenceStreamProvider.allTransitiveDependencies,
    initialPreferredLocaleProvider,
    ...?initialPreferredLocaleProvider.allTransitiveDependencies,
  },
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef UserLocalePreferenceRef = AutoDisposeProviderRef<Locale?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
