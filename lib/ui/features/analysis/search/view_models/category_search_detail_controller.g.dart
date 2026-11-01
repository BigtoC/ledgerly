// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'category_search_detail_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(CategorySearchDetailController)
final categorySearchDetailControllerProvider =
    CategorySearchDetailControllerFamily._();

final class CategorySearchDetailControllerProvider
    extends
        $StreamNotifierProvider<
          CategorySearchDetailController,
          CategorySearchDetailState
        > {
  CategorySearchDetailControllerProvider._({
    required CategorySearchDetailControllerFamily super.from,
    required ({int categoryId, String query, String currencyCode})
    super.argument,
  }) : super(
         retry: null,
         name: r'categorySearchDetailControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  static final $allTransitiveDependencies0 = transactionRepositoryProvider;
  static final $allTransitiveDependencies1 =
      TransactionRepositoryProvider.$allTransitiveDependencies0;
  static final $allTransitiveDependencies2 = analysisControllerProvider;
  static final $allTransitiveDependencies3 =
      AnalysisControllerProvider.$allTransitiveDependencies2;
  static final $allTransitiveDependencies4 =
      AnalysisControllerProvider.$allTransitiveDependencies3;

  @override
  String debugGetCreateSourceHash() => _$categorySearchDetailControllerHash();

  @override
  String toString() {
    return r'categorySearchDetailControllerProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  CategorySearchDetailController create() => CategorySearchDetailController();

  @override
  bool operator ==(Object other) {
    return other is CategorySearchDetailControllerProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$categorySearchDetailControllerHash() =>
    r'7423c08d6f2325aa72558a50c4c34e5ed22a0be6';

final class CategorySearchDetailControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          CategorySearchDetailController,
          AsyncValue<CategorySearchDetailState>,
          CategorySearchDetailState,
          Stream<CategorySearchDetailState>,
          ({int categoryId, String query, String currencyCode})
        > {
  CategorySearchDetailControllerFamily._()
    : super(
        retry: null,
        name: r'categorySearchDetailControllerProvider',
        dependencies: <ProviderOrFamily>[
          transactionRepositoryProvider,
          analysisControllerProvider,
        ],
        $allTransitiveDependencies: <ProviderOrFamily>{
          CategorySearchDetailControllerProvider.$allTransitiveDependencies0,
          CategorySearchDetailControllerProvider.$allTransitiveDependencies1,
          CategorySearchDetailControllerProvider.$allTransitiveDependencies2,
          CategorySearchDetailControllerProvider.$allTransitiveDependencies3,
          CategorySearchDetailControllerProvider.$allTransitiveDependencies4,
        },
        isAutoDispose: true,
      );

  CategorySearchDetailControllerProvider call({
    required int categoryId,
    required String query,
    required String currencyCode,
  }) => CategorySearchDetailControllerProvider._(
    argument: (
      categoryId: categoryId,
      query: query,
      currencyCode: currencyCode,
    ),
    from: this,
  );

  @override
  String toString() => r'categorySearchDetailControllerProvider';
}

abstract class _$CategorySearchDetailController
    extends $StreamNotifier<CategorySearchDetailState> {
  late final _$args =
      ref.$arg as ({int categoryId, String query, String currencyCode});
  int get categoryId => _$args.categoryId;
  String get query => _$args.query;
  String get currencyCode => _$args.currencyCode;

  Stream<CategorySearchDetailState> build({
    required int categoryId,
    required String query,
    required String currencyCode,
  });
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<CategorySearchDetailState>,
              CategorySearchDetailState
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<CategorySearchDetailState>,
                CategorySearchDetailState
              >,
              AsyncValue<CategorySearchDetailState>,
              Object?,
              Object?
            >;
    return element.handleCreate(
      ref,
      () => build(
        categoryId: _$args.categoryId,
        query: _$args.query,
        currencyCode: _$args.currencyCode,
      ),
    );
  }
}
