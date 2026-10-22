// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'categories_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Picker data source (plan §5). Must NOT be `keepAlive: true`.

@ProviderFor(categoriesByType)
final categoriesByTypeProvider = CategoriesByTypeFamily._();

/// Picker data source (plan §5). Must NOT be `keepAlive: true`.

final class CategoriesByTypeProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Category>>,
          List<Category>,
          Stream<List<Category>>
        >
    with $FutureModifier<List<Category>>, $StreamProvider<List<Category>> {
  /// Picker data source (plan §5). Must NOT be `keepAlive: true`.
  CategoriesByTypeProvider._({
    required CategoriesByTypeFamily super.from,
    required CategoryType super.argument,
  }) : super(
         retry: null,
         name: r'categoriesByTypeProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  static final $allTransitiveDependencies0 = categoryRepositoryProvider;
  static final $allTransitiveDependencies1 =
      CategoryRepositoryProvider.$allTransitiveDependencies0;

  @override
  String debugGetCreateSourceHash() => _$categoriesByTypeHash();

  @override
  String toString() {
    return r'categoriesByTypeProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<Category>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<Category>> create(Ref ref) {
    final argument = this.argument as CategoryType;
    return categoriesByType(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is CategoriesByTypeProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$categoriesByTypeHash() => r'87844ad5c286f594c74523adc9505d1e31b94df0';

/// Picker data source (plan §5). Must NOT be `keepAlive: true`.

final class CategoriesByTypeFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<Category>>, CategoryType> {
  CategoriesByTypeFamily._()
    : super(
        retry: null,
        name: r'categoriesByTypeProvider',
        dependencies: <ProviderOrFamily>[categoryRepositoryProvider],
        $allTransitiveDependencies: <ProviderOrFamily>[
          CategoriesByTypeProvider.$allTransitiveDependencies0,
          CategoriesByTypeProvider.$allTransitiveDependencies1,
        ],
        isAutoDispose: true,
      );

  /// Picker data source (plan §5). Must NOT be `keepAlive: true`.

  CategoriesByTypeProvider call(CategoryType type) =>
      CategoriesByTypeProvider._(argument: type, from: this);

  @override
  String toString() => r'categoriesByTypeProvider';
}

@ProviderFor(CategoriesController)
final categoriesControllerProvider = CategoriesControllerProvider._();

final class CategoriesControllerProvider
    extends $StreamNotifierProvider<CategoriesController, CategoriesState> {
  CategoriesControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'categoriesControllerProvider',
        isAutoDispose: true,
        dependencies: <ProviderOrFamily>[categoryRepositoryProvider],
        $allTransitiveDependencies: <ProviderOrFamily>[
          CategoriesControllerProvider.$allTransitiveDependencies0,
          CategoriesControllerProvider.$allTransitiveDependencies1,
        ],
      );

  static final $allTransitiveDependencies0 = categoryRepositoryProvider;
  static final $allTransitiveDependencies1 =
      CategoryRepositoryProvider.$allTransitiveDependencies0;

  @override
  String debugGetCreateSourceHash() => _$categoriesControllerHash();

  @$internal
  @override
  CategoriesController create() => CategoriesController();
}

String _$categoriesControllerHash() =>
    r'a92184686f7227a47927abce8bb55527f206e514';

abstract class _$CategoriesController extends $StreamNotifier<CategoriesState> {
  Stream<CategoriesState> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<CategoriesState>, CategoriesState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<CategoriesState>, CategoriesState>,
              AsyncValue<CategoriesState>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
