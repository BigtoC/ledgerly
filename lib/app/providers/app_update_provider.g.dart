// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_update_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
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
    r'65724c10828cde06b7af5a7aeb67813aaeef5240';

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
