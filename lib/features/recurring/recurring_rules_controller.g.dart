// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recurring_rules_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$recurringRulesControllerHash() =>
    r'99c023dc86725bb9c07ba6eabf8165650f49e4b4';

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
