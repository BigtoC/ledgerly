// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shopping_list_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ShoppingListController)
final shoppingListControllerProvider = ShoppingListControllerProvider._();

final class ShoppingListControllerProvider
    extends $StreamNotifierProvider<ShoppingListController, ShoppingListState> {
  ShoppingListControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'shoppingListControllerProvider',
        isAutoDispose: true,
        dependencies: <ProviderOrFamily>[shoppingListRepositoryProvider],
        $allTransitiveDependencies: <ProviderOrFamily>[
          ShoppingListControllerProvider.$allTransitiveDependencies0,
          ShoppingListControllerProvider.$allTransitiveDependencies1,
          ShoppingListControllerProvider.$allTransitiveDependencies2,
        ],
      );

  static final $allTransitiveDependencies0 = shoppingListRepositoryProvider;
  static final $allTransitiveDependencies1 =
      ShoppingListRepositoryProvider.$allTransitiveDependencies0;
  static final $allTransitiveDependencies2 =
      ShoppingListRepositoryProvider.$allTransitiveDependencies1;

  @override
  String debugGetCreateSourceHash() => _$shoppingListControllerHash();

  @$internal
  @override
  ShoppingListController create() => ShoppingListController();
}

String _$shoppingListControllerHash() =>
    r'418db770bbd1ea7513631adad87b6c8d5e6fb103';

abstract class _$ShoppingListController
    extends $StreamNotifier<ShoppingListState> {
  Stream<ShoppingListState> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<ShoppingListState>, ShoppingListState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<ShoppingListState>, ShoppingListState>,
              AsyncValue<ShoppingListState>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
