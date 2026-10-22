// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction_form_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(TransactionFormController)
final transactionFormControllerProvider = TransactionFormControllerProvider._();

final class TransactionFormControllerProvider
    extends $NotifierProvider<TransactionFormController, TransactionFormState> {
  TransactionFormControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'transactionFormControllerProvider',
        isAutoDispose: true,
        dependencies: <ProviderOrFamily>[
          transactionRepositoryProvider,
          accountRepositoryProvider,
          categoryRepositoryProvider,
          userPreferencesRepositoryProvider,
          currencyRepositoryProvider,
          shoppingListRepositoryProvider,
          defaultCurrencyProvider,
          exchangeRateRepositoryProvider,
          initialDefaultCurrencyProvider,
        ],
        $allTransitiveDependencies: <ProviderOrFamily>{
          TransactionFormControllerProvider.$allTransitiveDependencies0,
          TransactionFormControllerProvider.$allTransitiveDependencies1,
          TransactionFormControllerProvider.$allTransitiveDependencies2,
          TransactionFormControllerProvider.$allTransitiveDependencies3,
          TransactionFormControllerProvider.$allTransitiveDependencies4,
          TransactionFormControllerProvider.$allTransitiveDependencies5,
          TransactionFormControllerProvider.$allTransitiveDependencies6,
          TransactionFormControllerProvider.$allTransitiveDependencies7,
          TransactionFormControllerProvider.$allTransitiveDependencies8,
          TransactionFormControllerProvider.$allTransitiveDependencies9,
          TransactionFormControllerProvider.$allTransitiveDependencies10,
        },
      );

  static final $allTransitiveDependencies0 = transactionRepositoryProvider;
  static final $allTransitiveDependencies1 =
      TransactionRepositoryProvider.$allTransitiveDependencies0;
  static final $allTransitiveDependencies2 = accountRepositoryProvider;
  static final $allTransitiveDependencies3 =
      AccountRepositoryProvider.$allTransitiveDependencies1;
  static final $allTransitiveDependencies4 = categoryRepositoryProvider;
  static final $allTransitiveDependencies5 = userPreferencesRepositoryProvider;
  static final $allTransitiveDependencies6 = shoppingListRepositoryProvider;
  static final $allTransitiveDependencies7 = defaultCurrencyProvider;
  static final $allTransitiveDependencies8 = exchangeRateRepositoryProvider;
  static final $allTransitiveDependencies9 =
      ExchangeRateRepositoryProvider.$allTransitiveDependencies1;
  static final $allTransitiveDependencies10 = initialDefaultCurrencyProvider;

  @override
  String debugGetCreateSourceHash() => _$transactionFormControllerHash();

  @$internal
  @override
  TransactionFormController create() => TransactionFormController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TransactionFormState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TransactionFormState>(value),
    );
  }
}

String _$transactionFormControllerHash() =>
    r'9f65d377288f0b7dbc3805ae43923e1d18db1976';

abstract class _$TransactionFormController
    extends $Notifier<TransactionFormState> {
  TransactionFormState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<TransactionFormState, TransactionFormState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<TransactionFormState, TransactionFormState>,
              TransactionFormState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
