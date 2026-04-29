// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$homeControllerHash() => r'0c3b3a499419127912fd2e7532dcc5f5c340130d';

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
