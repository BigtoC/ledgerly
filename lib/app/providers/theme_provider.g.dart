// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'theme_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(initialThemeMode)
final initialThemeModeProvider = InitialThemeModeProvider._();

final class InitialThemeModeProvider
    extends $FunctionalProvider<ThemeMode?, ThemeMode?, ThemeMode?>
    with $Provider<ThemeMode?> {
  InitialThemeModeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'initialThemeModeProvider',
        isAutoDispose: false,
        dependencies: <ProviderOrFamily>[],
        $allTransitiveDependencies: <ProviderOrFamily>[],
      );

  @override
  String debugGetCreateSourceHash() => _$initialThemeModeHash();

  @$internal
  @override
  $ProviderElement<ThemeMode?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ThemeMode? create(Ref ref) {
    return initialThemeMode(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ThemeMode? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ThemeMode?>(value),
    );
  }
}

String _$initialThemeModeHash() => r'2c6afabe5a82826dd5bbab6aa55b415a08929814';

@ProviderFor(themeModeStream)
final themeModeStreamProvider = ThemeModeStreamProvider._();

final class ThemeModeStreamProvider
    extends
        $FunctionalProvider<AsyncValue<ThemeMode>, ThemeMode, Stream<ThemeMode>>
    with $FutureModifier<ThemeMode>, $StreamProvider<ThemeMode> {
  ThemeModeStreamProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'themeModeStreamProvider',
        isAutoDispose: false,
        dependencies: <ProviderOrFamily>[userPreferencesRepositoryProvider],
        $allTransitiveDependencies: <ProviderOrFamily>[
          ThemeModeStreamProvider.$allTransitiveDependencies0,
          ThemeModeStreamProvider.$allTransitiveDependencies1,
        ],
      );

  static final $allTransitiveDependencies0 = userPreferencesRepositoryProvider;
  static final $allTransitiveDependencies1 =
      UserPreferencesRepositoryProvider.$allTransitiveDependencies0;

  @override
  String debugGetCreateSourceHash() => _$themeModeStreamHash();

  @$internal
  @override
  $StreamProviderElement<ThemeMode> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<ThemeMode> create(Ref ref) {
    return themeModeStream(ref);
  }
}

String _$themeModeStreamHash() => r'fdbe5e87e9b70715ff5a14df88a6dea59f6f9b74';

@ProviderFor(themeMode)
final themeModeProvider = ThemeModeProvider._();

final class ThemeModeProvider
    extends $FunctionalProvider<ThemeMode, ThemeMode, ThemeMode>
    with $Provider<ThemeMode> {
  ThemeModeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'themeModeProvider',
        isAutoDispose: true,
        dependencies: <ProviderOrFamily>[
          initialThemeModeProvider,
          themeModeStreamProvider,
        ],
        $allTransitiveDependencies: <ProviderOrFamily>{
          ThemeModeProvider.$allTransitiveDependencies0,
          ThemeModeProvider.$allTransitiveDependencies1,
          ThemeModeProvider.$allTransitiveDependencies2,
          ThemeModeProvider.$allTransitiveDependencies3,
        },
      );

  static final $allTransitiveDependencies0 = initialThemeModeProvider;
  static final $allTransitiveDependencies1 = themeModeStreamProvider;
  static final $allTransitiveDependencies2 =
      ThemeModeStreamProvider.$allTransitiveDependencies0;
  static final $allTransitiveDependencies3 =
      ThemeModeStreamProvider.$allTransitiveDependencies1;

  @override
  String debugGetCreateSourceHash() => _$themeModeHash();

  @$internal
  @override
  $ProviderElement<ThemeMode> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ThemeMode create(Ref ref) {
    return themeMode(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ThemeMode value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ThemeMode>(value),
    );
  }
}

String _$themeModeHash() => r'ffe15e42f4f820a99e6240223057ba1eb979e13d';
