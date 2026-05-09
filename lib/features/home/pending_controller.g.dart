// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pending_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$pendingControllerHash() => r'c872ee5f5e7cbe01d687d50374665713e11c6986';

/// See also [PendingController].
@ProviderFor(PendingController)
final pendingControllerProvider =
    StreamNotifierProvider<PendingController, PendingState>.internal(
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

typedef _$PendingController = StreamNotifier<PendingState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
