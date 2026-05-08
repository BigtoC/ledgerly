// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pending_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$pendingControllerHash() => r'7c96c96c44735829d27df403a03174fece04f71a';

/// See also [PendingController].
@ProviderFor(PendingController)
final pendingControllerProvider =
    AutoDisposeStreamNotifierProvider<PendingController, PendingState>.internal(
      PendingController.new,
      name: r'pendingControllerProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$pendingControllerHash,
      dependencies: <ProviderOrFamily>[pendingTransactionRepositoryProvider],
      allTransitiveDependencies: <ProviderOrFamily>{
        pendingTransactionRepositoryProvider,
        ...?pendingTransactionRepositoryProvider.allTransitiveDependencies,
      },
    );

typedef _$PendingController = AutoDisposeStreamNotifier<PendingState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
