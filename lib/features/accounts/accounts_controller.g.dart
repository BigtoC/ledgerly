// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'accounts_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$accountsControllerHash() =>
    r'ff23d404c2ad2febe4e3599b591092c180ad4c57';

/// See also [AccountsController].
@ProviderFor(AccountsController)
final accountsControllerProvider =
    AutoDisposeStreamNotifierProvider<
      AccountsController,
      AccountsState
    >.internal(
      AccountsController.new,
      name: r'accountsControllerProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$accountsControllerHash,
      dependencies: <ProviderOrFamily>[
        accountRepositoryProvider,
        userPreferencesRepositoryProvider,
      ],
      allTransitiveDependencies: <ProviderOrFamily>{
        accountRepositoryProvider,
        ...?accountRepositoryProvider.allTransitiveDependencies,
        userPreferencesRepositoryProvider,
        ...?userPreferencesRepositoryProvider.allTransitiveDependencies,
      },
    );

typedef _$AccountsController = AutoDisposeStreamNotifier<AccountsState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
