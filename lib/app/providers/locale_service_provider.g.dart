// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'locale_service_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(localeService)
final localeServiceProvider = LocaleServiceProvider._();

final class LocaleServiceProvider
    extends $FunctionalProvider<LocaleService, LocaleService, LocaleService>
    with $Provider<LocaleService> {
  LocaleServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'localeServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$localeServiceHash();

  @$internal
  @override
  $ProviderElement<LocaleService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  LocaleService create(Ref ref) {
    return localeService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LocaleService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LocaleService>(value),
    );
  }
}

String _$localeServiceHash() => r'a3f251a2294f5e6dab4ffbbbbdabec5e517bfb1d';
