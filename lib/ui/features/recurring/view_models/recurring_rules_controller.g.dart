// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recurring_rules_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(RecurringRulesController)
final recurringRulesControllerProvider = RecurringRulesControllerProvider._();

final class RecurringRulesControllerProvider
    extends
        $StreamNotifierProvider<RecurringRulesController, RecurringRulesState> {
  RecurringRulesControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'recurringRulesControllerProvider',
        isAutoDispose: true,
        dependencies: <ProviderOrFamily>[recurringRulesRepositoryProvider],
        $allTransitiveDependencies: <ProviderOrFamily>[
          RecurringRulesControllerProvider.$allTransitiveDependencies0,
          RecurringRulesControllerProvider.$allTransitiveDependencies1,
        ],
      );

  static final $allTransitiveDependencies0 = recurringRulesRepositoryProvider;
  static final $allTransitiveDependencies1 =
      RecurringRulesRepositoryProvider.$allTransitiveDependencies0;

  @override
  String debugGetCreateSourceHash() => _$recurringRulesControllerHash();

  @$internal
  @override
  RecurringRulesController create() => RecurringRulesController();
}

String _$recurringRulesControllerHash() =>
    r'e20c3ff5bcb374446652903f1dfc58f8f622de11';

abstract class _$RecurringRulesController
    extends $StreamNotifier<RecurringRulesState> {
  Stream<RecurringRulesState> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<RecurringRulesState>, RecurringRulesState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<RecurringRulesState>, RecurringRulesState>,
              AsyncValue<RecurringRulesState>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
