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
    r'098f822a64fff44adba994c0696056b0707e850b';

abstract class _$ShoppingListController
    extends $StreamNotifier<ShoppingListState> {
  Stream<ShoppingListState> build();
  @$mustCallSuper
  @override
  void runBuild() {
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
    element.handleCreate(ref, build);
  }
}
