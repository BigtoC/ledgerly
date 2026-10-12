// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shopping_list_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$shoppingListControllerHash() =>
    r'098f822a64fff44adba994c0696056b0707e850b';

/// See also [ShoppingListController].
@ProviderFor(ShoppingListController)
final shoppingListControllerProvider =
    AutoDisposeStreamNotifierProvider<
      ShoppingListController,
      ShoppingListState
    >.internal(
      ShoppingListController.new,
      name: r'shoppingListControllerProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$shoppingListControllerHash,
      dependencies: <ProviderOrFamily>[shoppingListRepositoryProvider],
      allTransitiveDependencies: <ProviderOrFamily>{
        shoppingListRepositoryProvider,
        ...?shoppingListRepositoryProvider.allTransitiveDependencies,
      },
    );

typedef _$ShoppingListController = AutoDisposeStreamNotifier<ShoppingListState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
