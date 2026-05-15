// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'category_search_detail_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$categorySearchDetailControllerHash() =>
    r'3cd87813fcae7f567acea292c76b9116f3ec44fd';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

abstract class _$CategorySearchDetailController
    extends BuildlessStreamNotifier<CategorySearchDetailState> {
  late final int categoryId;
  late final String query;
  late final String currencyCode;

  Stream<CategorySearchDetailState> build({
    required int categoryId,
    required String query,
    required String currencyCode,
  });
}

/// See also [CategorySearchDetailController].
@ProviderFor(CategorySearchDetailController)
const categorySearchDetailControllerProvider =
    CategorySearchDetailControllerFamily();

/// See also [CategorySearchDetailController].
class CategorySearchDetailControllerFamily
    extends Family<AsyncValue<CategorySearchDetailState>> {
  /// See also [CategorySearchDetailController].
  const CategorySearchDetailControllerFamily();

  /// See also [CategorySearchDetailController].
  CategorySearchDetailControllerProvider call({
    required int categoryId,
    required String query,
    required String currencyCode,
  }) {
    return CategorySearchDetailControllerProvider(
      categoryId: categoryId,
      query: query,
      currencyCode: currencyCode,
    );
  }

  @override
  CategorySearchDetailControllerProvider getProviderOverride(
    covariant CategorySearchDetailControllerProvider provider,
  ) {
    return call(
      categoryId: provider.categoryId,
      query: provider.query,
      currencyCode: provider.currencyCode,
    );
  }

  static final Iterable<ProviderOrFamily> _dependencies = <ProviderOrFamily>[
    transactionRepositoryProvider,
    analysisControllerProvider,
  ];

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static final Iterable<ProviderOrFamily> _allTransitiveDependencies =
      <ProviderOrFamily>{
        transactionRepositoryProvider,
        ...?transactionRepositoryProvider.allTransitiveDependencies,
        analysisControllerProvider,
        ...?analysisControllerProvider.allTransitiveDependencies,
      };

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'categorySearchDetailControllerProvider';
}

/// See also [CategorySearchDetailController].
class CategorySearchDetailControllerProvider
    extends
        StreamNotifierProviderImpl<
          CategorySearchDetailController,
          CategorySearchDetailState
        > {
  /// See also [CategorySearchDetailController].
  CategorySearchDetailControllerProvider({
    required int categoryId,
    required String query,
    required String currencyCode,
  }) : this._internal(
         () => CategorySearchDetailController()
           ..categoryId = categoryId
           ..query = query
           ..currencyCode = currencyCode,
         from: categorySearchDetailControllerProvider,
         name: r'categorySearchDetailControllerProvider',
         debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
             ? null
             : _$categorySearchDetailControllerHash,
         dependencies: CategorySearchDetailControllerFamily._dependencies,
         allTransitiveDependencies:
             CategorySearchDetailControllerFamily._allTransitiveDependencies,
         categoryId: categoryId,
         query: query,
         currencyCode: currencyCode,
       );

  CategorySearchDetailControllerProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.categoryId,
    required this.query,
    required this.currencyCode,
  }) : super.internal();

  final int categoryId;
  final String query;
  final String currencyCode;

  @override
  Stream<CategorySearchDetailState> runNotifierBuild(
    covariant CategorySearchDetailController notifier,
  ) {
    return notifier.build(
      categoryId: categoryId,
      query: query,
      currencyCode: currencyCode,
    );
  }

  @override
  Override overrideWith(CategorySearchDetailController Function() create) {
    return ProviderOverride(
      origin: this,
      override: CategorySearchDetailControllerProvider._internal(
        () => create()
          ..categoryId = categoryId
          ..query = query
          ..currencyCode = currencyCode,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        categoryId: categoryId,
        query: query,
        currencyCode: currencyCode,
      ),
    );
  }

  @override
  StreamNotifierProviderElement<
    CategorySearchDetailController,
    CategorySearchDetailState
  >
  createElement() {
    return _CategorySearchDetailControllerProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is CategorySearchDetailControllerProvider &&
        other.categoryId == categoryId &&
        other.query == query &&
        other.currencyCode == currencyCode;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, categoryId.hashCode);
    hash = _SystemHash.combine(hash, query.hashCode);
    hash = _SystemHash.combine(hash, currencyCode.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin CategorySearchDetailControllerRef
    on StreamNotifierProviderRef<CategorySearchDetailState> {
  /// The parameter `categoryId` of this provider.
  int get categoryId;

  /// The parameter `query` of this provider.
  String get query;

  /// The parameter `currencyCode` of this provider.
  String get currencyCode;
}

class _CategorySearchDetailControllerProviderElement
    extends
        StreamNotifierProviderElement<
          CategorySearchDetailController,
          CategorySearchDetailState
        >
    with CategorySearchDetailControllerRef {
  _CategorySearchDetailControllerProviderElement(super.provider);

  @override
  int get categoryId =>
      (origin as CategorySearchDetailControllerProvider).categoryId;
  @override
  String get query => (origin as CategorySearchDetailControllerProvider).query;
  @override
  String get currencyCode =>
      (origin as CategorySearchDetailControllerProvider).currencyCode;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
