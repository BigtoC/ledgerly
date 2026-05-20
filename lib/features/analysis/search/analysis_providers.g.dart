// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'analysis_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$analysisCategoriesByIdHash() =>
    r'db2c97eed6e1868d49af05b9be394622f01e5f64';

/// `id → Category` lookup (active + archived) for search-result tiles.
///
/// Copied from [analysisCategoriesById].
@ProviderFor(analysisCategoriesById)
final analysisCategoriesByIdProvider =
    AutoDisposeStreamProvider<Map<int, Category>>.internal(
      analysisCategoriesById,
      name: r'analysisCategoriesByIdProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$analysisCategoriesByIdHash,
      dependencies: <ProviderOrFamily>[categoryRepositoryProvider],
      allTransitiveDependencies: <ProviderOrFamily>{
        categoryRepositoryProvider,
        ...?categoryRepositoryProvider.allTransitiveDependencies,
      },
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AnalysisCategoriesByIdRef =
    AutoDisposeStreamProviderRef<Map<int, Category>>;
String _$analysisAccountsByIdHash() =>
    r'e88ec353816afaf41e580634741f531f7b1b0949';

/// `id → Account` lookup (active + archived) for the detail screen's
/// transaction rows.
///
/// Copied from [analysisAccountsById].
@ProviderFor(analysisAccountsById)
final analysisAccountsByIdProvider =
    AutoDisposeStreamProvider<Map<int, Account>>.internal(
      analysisAccountsById,
      name: r'analysisAccountsByIdProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$analysisAccountsByIdHash,
      dependencies: <ProviderOrFamily>[accountRepositoryProvider],
      allTransitiveDependencies: <ProviderOrFamily>{
        accountRepositoryProvider,
        ...?accountRepositoryProvider.allTransitiveDependencies,
      },
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AnalysisAccountsByIdRef =
    AutoDisposeStreamProviderRef<Map<int, Account>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
