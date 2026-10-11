// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$homeControllerHash() => r'5bb19558a9be7a13e833b2e562483d698c9327c4';

/// See also [HomeController].
@ProviderFor(HomeController)
final homeControllerProvider =
    StreamNotifierProvider<HomeController, HomeState>.internal(
      HomeController.new,
      name: r'homeControllerProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$homeControllerHash,
      dependencies: <ProviderOrFamily>[transactionRepositoryProvider],
      allTransitiveDependencies: <ProviderOrFamily>{
        transactionRepositoryProvider,
        ...?transactionRepositoryProvider.allTransitiveDependencies,
      },
    );

typedef _$HomeController = StreamNotifier<HomeState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
