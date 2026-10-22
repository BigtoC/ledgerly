// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'router.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(router)
final routerProvider = RouterProvider._();

final class RouterProvider
    extends $FunctionalProvider<GoRouter, GoRouter, GoRouter>
    with $Provider<GoRouter> {
  RouterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'routerProvider',
        isAutoDispose: false,
        dependencies: <ProviderOrFamily>[splashGateSnapshotProvider],
        $allTransitiveDependencies: <ProviderOrFamily>[
          RouterProvider.$allTransitiveDependencies0,
          RouterProvider.$allTransitiveDependencies1,
          RouterProvider.$allTransitiveDependencies2,
        ],
      );

  static final $allTransitiveDependencies0 = splashGateSnapshotProvider;
  static final $allTransitiveDependencies1 =
      SplashGateSnapshotProvider.$allTransitiveDependencies0;
  static final $allTransitiveDependencies2 =
      SplashGateSnapshotProvider.$allTransitiveDependencies1;

  @override
  String debugGetCreateSourceHash() => _$routerHash();

  @$internal
  @override
  $ProviderElement<GoRouter> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  GoRouter create(Ref ref) {
    return router(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GoRouter value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GoRouter>(value),
    );
  }
}

String _$routerHash() => r'1ac122eae2e0ba17589a969af5ed6c2e1c4b37bd';
