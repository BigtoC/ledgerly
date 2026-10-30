// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'csv_import_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(CsvImportController)
final csvImportControllerProvider = CsvImportControllerProvider._();

final class CsvImportControllerProvider
    extends $NotifierProvider<CsvImportController, CsvImportState> {
  CsvImportControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'csvImportControllerProvider',
        isAutoDispose: true,
        dependencies: <ProviderOrFamily>[
          csvImportUseCaseProvider,
          categoryRepositoryProvider,
          accountRepositoryProvider,
          accountTypeRepositoryProvider,
          exchangeRateRepositoryProvider,
          defaultCurrencyProvider,
          initialDefaultCurrencyProvider,
        ],
        $allTransitiveDependencies: <ProviderOrFamily>{
          CsvImportControllerProvider.$allTransitiveDependencies0,
          CsvImportControllerProvider.$allTransitiveDependencies1,
          CsvImportControllerProvider.$allTransitiveDependencies2,
          CsvImportControllerProvider.$allTransitiveDependencies3,
          CsvImportControllerProvider.$allTransitiveDependencies4,
          CsvImportControllerProvider.$allTransitiveDependencies5,
          CsvImportControllerProvider.$allTransitiveDependencies6,
          CsvImportControllerProvider.$allTransitiveDependencies7,
          CsvImportControllerProvider.$allTransitiveDependencies8,
          CsvImportControllerProvider.$allTransitiveDependencies9,
          CsvImportControllerProvider.$allTransitiveDependencies10,
          CsvImportControllerProvider.$allTransitiveDependencies11,
          CsvImportControllerProvider.$allTransitiveDependencies12,
        },
      );

  static final $allTransitiveDependencies0 = csvImportUseCaseProvider;
  static final $allTransitiveDependencies1 =
      CsvImportUseCaseProvider.$allTransitiveDependencies0;
  static final $allTransitiveDependencies2 =
      CsvImportUseCaseProvider.$allTransitiveDependencies1;
  static final $allTransitiveDependencies3 =
      CsvImportUseCaseProvider.$allTransitiveDependencies2;
  static final $allTransitiveDependencies4 =
      CsvImportUseCaseProvider.$allTransitiveDependencies3;
  static final $allTransitiveDependencies5 =
      CsvImportUseCaseProvider.$allTransitiveDependencies4;
  static final $allTransitiveDependencies6 =
      CsvImportUseCaseProvider.$allTransitiveDependencies5;
  static final $allTransitiveDependencies7 =
      CsvImportUseCaseProvider.$allTransitiveDependencies6;
  static final $allTransitiveDependencies8 = exchangeRateRepositoryProvider;
  static final $allTransitiveDependencies9 =
      ExchangeRateRepositoryProvider.$allTransitiveDependencies1;
  static final $allTransitiveDependencies10 =
      ExchangeRateRepositoryProvider.$allTransitiveDependencies2;
  static final $allTransitiveDependencies11 =
      ExchangeRateRepositoryProvider.$allTransitiveDependencies3;
  static final $allTransitiveDependencies12 = initialDefaultCurrencyProvider;

  @override
  String debugGetCreateSourceHash() => _$csvImportControllerHash();

  @$internal
  @override
  CsvImportController create() => CsvImportController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CsvImportState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CsvImportState>(value),
    );
  }
}

String _$csvImportControllerHash() =>
    r'eac5d6d7482d208a0333179ea7e251c21dd9ee87';

abstract class _$CsvImportController extends $Notifier<CsvImportState> {
  CsvImportState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<CsvImportState, CsvImportState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<CsvImportState, CsvImportState>,
              CsvImportState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
