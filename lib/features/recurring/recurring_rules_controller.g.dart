// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recurring_rules_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$recurringRulesControllerHash() =>
    r'b18d5d03042b32f65cfb50e1a43fc04d834a1e1c';

/// See also [RecurringRulesController].
@ProviderFor(RecurringRulesController)
final recurringRulesControllerProvider =
    AutoDisposeStreamNotifierProvider<
      RecurringRulesController,
      RecurringRulesState
    >.internal(
      RecurringRulesController.new,
      name: r'recurringRulesControllerProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$recurringRulesControllerHash,
      dependencies: <ProviderOrFamily>[recurringRulesRepositoryProvider],
      allTransitiveDependencies: <ProviderOrFamily>{
        recurringRulesRepositoryProvider,
        ...?recurringRulesRepositoryProvider.allTransitiveDependencies,
      },
    );

typedef _$RecurringRulesController =
    AutoDisposeStreamNotifier<RecurringRulesState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
