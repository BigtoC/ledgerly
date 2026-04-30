// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'theme_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$initialThemeModeHash() => r'2c6afabe5a82826dd5bbab6aa55b415a08929814';

/// See also [initialThemeMode].
@ProviderFor(initialThemeMode)
final initialThemeModeProvider = Provider<ThemeMode?>.internal(
  initialThemeMode,
  name: r'initialThemeModeProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$initialThemeModeHash,
  dependencies: const <ProviderOrFamily>[],
  allTransitiveDependencies: const <ProviderOrFamily>{},
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef InitialThemeModeRef = ProviderRef<ThemeMode?>;
String _$themeModeStreamHash() => r'fdbe5e87e9b70715ff5a14df88a6dea59f6f9b74';

/// See also [themeModeStream].
@ProviderFor(themeModeStream)
final themeModeStreamProvider = StreamProvider<ThemeMode>.internal(
  themeModeStream,
  name: r'themeModeStreamProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$themeModeStreamHash,
  dependencies: <ProviderOrFamily>[userPreferencesRepositoryProvider],
  allTransitiveDependencies: <ProviderOrFamily>{
    userPreferencesRepositoryProvider,
    ...?userPreferencesRepositoryProvider.allTransitiveDependencies,
  },
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ThemeModeStreamRef = StreamProviderRef<ThemeMode>;
String _$themeModeHash() => r'ffe15e42f4f820a99e6240223057ba1eb979e13d';

/// See also [themeMode].
@ProviderFor(themeMode)
final themeModeProvider = AutoDisposeProvider<ThemeMode>.internal(
  themeMode,
  name: r'themeModeProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$themeModeHash,
  dependencies: <ProviderOrFamily>[
    initialThemeModeProvider,
    themeModeStreamProvider,
  ],
  allTransitiveDependencies: <ProviderOrFamily>{
    initialThemeModeProvider,
    ...?initialThemeModeProvider.allTransitiveDependencies,
    themeModeStreamProvider,
    ...?themeModeStreamProvider.allTransitiveDependencies,
  },
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ThemeModeRef = AutoDisposeProviderRef<ThemeMode>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
