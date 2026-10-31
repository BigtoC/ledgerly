// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'service_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Shared HTTP client for every HTTP service. Conservative timeouts; the
/// client is closed when the owning container is disposed.

@ProviderFor(dio)
final dioProvider = DioProvider._();

/// Shared HTTP client for every HTTP service. Conservative timeouts; the
/// client is closed when the owning container is disposed.

final class DioProvider extends $FunctionalProvider<Dio, Dio, Dio>
    with $Provider<Dio> {
  /// Shared HTTP client for every HTTP service. Conservative timeouts; the
  /// client is closed when the owning container is disposed.
  DioProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dioProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dioHash();

  @$internal
  @override
  $ProviderElement<Dio> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Dio create(Ref ref) {
    return dio(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Dio value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Dio>(value),
    );
  }
}

String _$dioHash() => r'609f409fd9322951631485f1281f0561805462f7';

/// Exchange-rate HTTP service. Uses the shared [dioProvider] client.

@ProviderFor(exchangeRateService)
final exchangeRateServiceProvider = ExchangeRateServiceProvider._();

/// Exchange-rate HTTP service. Uses the shared [dioProvider] client.

final class ExchangeRateServiceProvider
    extends
        $FunctionalProvider<
          ExchangeRateService,
          ExchangeRateService,
          ExchangeRateService
        >
    with $Provider<ExchangeRateService> {
  /// Exchange-rate HTTP service. Uses the shared [dioProvider] client.
  ExchangeRateServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'exchangeRateServiceProvider',
        isAutoDispose: false,
        dependencies: <ProviderOrFamily>[],
        $allTransitiveDependencies: <ProviderOrFamily>[],
      );

  @override
  String debugGetCreateSourceHash() => _$exchangeRateServiceHash();

  @$internal
  @override
  $ProviderElement<ExchangeRateService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ExchangeRateService create(Ref ref) {
    return exchangeRateService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ExchangeRateService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ExchangeRateService>(value),
    );
  }
}

String _$exchangeRateServiceHash() =>
    r'54cac23382bca3bc90ff6bca49f4643fc47a093d';

/// System file picker for CSV import. Tests override it with a fake that
/// returns fixture bytes.

@ProviderFor(csvFileService)
final csvFileServiceProvider = CsvFileServiceProvider._();

/// System file picker for CSV import. Tests override it with a fake that
/// returns fixture bytes.

final class CsvFileServiceProvider
    extends $FunctionalProvider<CsvFileService, CsvFileService, CsvFileService>
    with $Provider<CsvFileService> {
  /// System file picker for CSV import. Tests override it with a fake that
  /// returns fixture bytes.
  CsvFileServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'csvFileServiceProvider',
        isAutoDispose: false,
        dependencies: <ProviderOrFamily>[],
        $allTransitiveDependencies: <ProviderOrFamily>[],
      );

  @override
  String debugGetCreateSourceHash() => _$csvFileServiceHash();

  @$internal
  @override
  $ProviderElement<CsvFileService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  CsvFileService create(Ref ref) {
    return csvFileService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CsvFileService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CsvFileService>(value),
    );
  }
}

String _$csvFileServiceHash() => r'55d5f03b94b6deba083b3656e22a9bc1598b0cb1';
