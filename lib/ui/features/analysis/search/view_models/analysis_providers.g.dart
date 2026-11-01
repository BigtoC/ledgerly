// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'analysis_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// `id → Category` lookup (active + archived) for search-result tiles.
///
/// `keepAlive` because the kept-alive `AnalysisController` and
/// `ChartsController` listen to it.

@ProviderFor(analysisCategoriesById)
final analysisCategoriesByIdProvider = AnalysisCategoriesByIdProvider._();

/// `id → Category` lookup (active + archived) for search-result tiles.
///
/// `keepAlive` because the kept-alive `AnalysisController` and
/// `ChartsController` listen to it.

final class AnalysisCategoriesByIdProvider
    extends
        $FunctionalProvider<
          AsyncValue<Map<int, Category>>,
          Map<int, Category>,
          Stream<Map<int, Category>>
        >
    with
        $FutureModifier<Map<int, Category>>,
        $StreamProvider<Map<int, Category>> {
  /// `id → Category` lookup (active + archived) for search-result tiles.
  ///
  /// `keepAlive` because the kept-alive `AnalysisController` and
  /// `ChartsController` listen to it.
  AnalysisCategoriesByIdProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'analysisCategoriesByIdProvider',
        isAutoDispose: false,
        dependencies: <ProviderOrFamily>[categoryRepositoryProvider],
        $allTransitiveDependencies: <ProviderOrFamily>[
          AnalysisCategoriesByIdProvider.$allTransitiveDependencies0,
          AnalysisCategoriesByIdProvider.$allTransitiveDependencies1,
        ],
      );

  static final $allTransitiveDependencies0 = categoryRepositoryProvider;
  static final $allTransitiveDependencies1 =
      CategoryRepositoryProvider.$allTransitiveDependencies0;

  @override
  String debugGetCreateSourceHash() => _$analysisCategoriesByIdHash();

  @$internal
  @override
  $StreamProviderElement<Map<int, Category>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<Map<int, Category>> create(Ref ref) {
    return analysisCategoriesById(ref);
  }
}

String _$analysisCategoriesByIdHash() =>
    r'b80c5fc0e16c294d31e9c96145242f77170fa778';

/// `id → Account` lookup (active + archived) for the detail screen's
/// transaction rows.
///
/// `keepAlive` because the kept-alive `ChartsController` listens to it.

@ProviderFor(analysisAccountsById)
final analysisAccountsByIdProvider = AnalysisAccountsByIdProvider._();

/// `id → Account` lookup (active + archived) for the detail screen's
/// transaction rows.
///
/// `keepAlive` because the kept-alive `ChartsController` listens to it.

final class AnalysisAccountsByIdProvider
    extends
        $FunctionalProvider<
          AsyncValue<Map<int, Account>>,
          Map<int, Account>,
          Stream<Map<int, Account>>
        >
    with
        $FutureModifier<Map<int, Account>>,
        $StreamProvider<Map<int, Account>> {
  /// `id → Account` lookup (active + archived) for the detail screen's
  /// transaction rows.
  ///
  /// `keepAlive` because the kept-alive `ChartsController` listens to it.
  AnalysisAccountsByIdProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'analysisAccountsByIdProvider',
        isAutoDispose: false,
        dependencies: <ProviderOrFamily>[accountRepositoryProvider],
        $allTransitiveDependencies: <ProviderOrFamily>[
          AnalysisAccountsByIdProvider.$allTransitiveDependencies0,
          AnalysisAccountsByIdProvider.$allTransitiveDependencies1,
          AnalysisAccountsByIdProvider.$allTransitiveDependencies2,
        ],
      );

  static final $allTransitiveDependencies0 = accountRepositoryProvider;
  static final $allTransitiveDependencies1 =
      AccountRepositoryProvider.$allTransitiveDependencies0;
  static final $allTransitiveDependencies2 =
      AccountRepositoryProvider.$allTransitiveDependencies1;

  @override
  String debugGetCreateSourceHash() => _$analysisAccountsByIdHash();

  @$internal
  @override
  $StreamProviderElement<Map<int, Account>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<Map<int, Account>> create(Ref ref) {
    return analysisAccountsById(ref);
  }
}

String _$analysisAccountsByIdHash() =>
    r'123c77bce83c6d1216e6637c7fd7eb2f7351d138';
