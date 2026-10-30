// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_update_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// GitHub release lookup for the app-update check. Unscoped: it shares the
/// app-wide [dioProvider] client and reads nothing from the database.

@ProviderFor(appUpdateRepository)
final appUpdateRepositoryProvider = AppUpdateRepositoryProvider._();

/// GitHub release lookup for the app-update check. Unscoped: it shares the
/// app-wide [dioProvider] client and reads nothing from the database.

final class AppUpdateRepositoryProvider
    extends
        $FunctionalProvider<
          AppUpdateRepository,
          AppUpdateRepository,
          AppUpdateRepository
        >
    with $Provider<AppUpdateRepository> {
  /// GitHub release lookup for the app-update check. Unscoped: it shares the
  /// app-wide [dioProvider] client and reads nothing from the database.
  AppUpdateRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appUpdateRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appUpdateRepositoryHash();

  @$internal
  @override
  $ProviderElement<AppUpdateRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AppUpdateRepository create(Ref ref) {
    return appUpdateRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppUpdateRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppUpdateRepository>(value),
    );
  }
}

String _$appUpdateRepositoryHash() =>
    r'27feb361942b9a87e74db8d0a4b1e559911e1c3c';

/// The newer release, or null. `build()` has no side effects; `App`
/// triggers [checkAfter] once per launch after the first frame.

@ProviderFor(AvailableAppUpdate)
final availableAppUpdateProvider = AvailableAppUpdateProvider._();

/// The newer release, or null. `build()` has no side effects; `App`
/// triggers [checkAfter] once per launch after the first frame.
final class AvailableAppUpdateProvider
    extends $NotifierProvider<AvailableAppUpdate, AppUpdate?> {
  /// The newer release, or null. `build()` has no side effects; `App`
  /// triggers [checkAfter] once per launch after the first frame.
  AvailableAppUpdateProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'availableAppUpdateProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$availableAppUpdateHash();

  @$internal
  @override
  AvailableAppUpdate create() => AvailableAppUpdate();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppUpdate? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppUpdate?>(value),
    );
  }
}

String _$availableAppUpdateHash() =>
    r'77e609b51f4dcdf32cd95a771e52cb3ffe9f87de';

/// The newer release, or null. `build()` has no side effects; `App`
/// triggers [checkAfter] once per launch after the first frame.

abstract class _$AvailableAppUpdate extends $Notifier<AppUpdate?> {
  AppUpdate? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AppUpdate?, AppUpdate?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AppUpdate?, AppUpdate?>,
              AppUpdate?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
