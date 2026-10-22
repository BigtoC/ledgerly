// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recurring_rule_form_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(RecurringRuleFormController)
final recurringRuleFormControllerProvider =
    RecurringRuleFormControllerFamily._();

final class RecurringRuleFormControllerProvider
    extends
        $AsyncNotifierProvider<
          RecurringRuleFormController,
          RecurringRuleFormState
        > {
  RecurringRuleFormControllerProvider._({
    required RecurringRuleFormControllerFamily super.from,
    required int? super.argument,
  }) : super(
         retry: null,
         name: r'recurringRuleFormControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  static final $allTransitiveDependencies0 = recurringRulesRepositoryProvider;
  static final $allTransitiveDependencies1 =
      RecurringRulesRepositoryProvider.$allTransitiveDependencies0;
  static final $allTransitiveDependencies2 =
      pendingTransactionRepositoryProvider;
  static final $allTransitiveDependencies3 =
      PendingTransactionRepositoryProvider.$allTransitiveDependencies1;
  static final $allTransitiveDependencies4 = recurringGenerationUseCaseProvider;
  static final $allTransitiveDependencies5 = currencyRepositoryProvider;
  static final $allTransitiveDependencies6 = userPreferencesRepositoryProvider;

  @override
  String debugGetCreateSourceHash() => _$recurringRuleFormControllerHash();

  @override
  String toString() {
    return r'recurringRuleFormControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  RecurringRuleFormController create() => RecurringRuleFormController();

  @override
  bool operator ==(Object other) {
    return other is RecurringRuleFormControllerProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$recurringRuleFormControllerHash() =>
    r'39f51bfafce720b5344ce85f0396ebd06ea8e19f';

final class RecurringRuleFormControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          RecurringRuleFormController,
          AsyncValue<RecurringRuleFormState>,
          RecurringRuleFormState,
          FutureOr<RecurringRuleFormState>,
          int?
        > {
  RecurringRuleFormControllerFamily._()
    : super(
        retry: null,
        name: r'recurringRuleFormControllerProvider',
        dependencies: <ProviderOrFamily>[
          recurringRulesRepositoryProvider,
          pendingTransactionRepositoryProvider,
          recurringGenerationUseCaseProvider,
          currencyRepositoryProvider,
          userPreferencesRepositoryProvider,
        ],
        $allTransitiveDependencies: <ProviderOrFamily>{
          RecurringRuleFormControllerProvider.$allTransitiveDependencies0,
          RecurringRuleFormControllerProvider.$allTransitiveDependencies1,
          RecurringRuleFormControllerProvider.$allTransitiveDependencies2,
          RecurringRuleFormControllerProvider.$allTransitiveDependencies3,
          RecurringRuleFormControllerProvider.$allTransitiveDependencies4,
          RecurringRuleFormControllerProvider.$allTransitiveDependencies5,
          RecurringRuleFormControllerProvider.$allTransitiveDependencies6,
        },
        isAutoDispose: true,
      );

  RecurringRuleFormControllerProvider call({int? ruleId}) =>
      RecurringRuleFormControllerProvider._(argument: ruleId, from: this);

  @override
  String toString() => r'recurringRuleFormControllerProvider';
}

abstract class _$RecurringRuleFormController
    extends $AsyncNotifier<RecurringRuleFormState> {
  late final _$args = ref.$arg as int?;
  int? get ruleId => _$args;

  FutureOr<RecurringRuleFormState> build({int? ruleId});
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<AsyncValue<RecurringRuleFormState>, RecurringRuleFormState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<RecurringRuleFormState>,
                RecurringRuleFormState
              >,
              AsyncValue<RecurringRuleFormState>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(ruleId: _$args));
  }
}
