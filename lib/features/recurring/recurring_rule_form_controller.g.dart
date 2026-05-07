// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recurring_rule_form_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$recurringRuleFormControllerHash() =>
    r'a92c3ffa5187ec3a2795a75870f013335c72bade';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

abstract class _$RecurringRuleFormController
    extends BuildlessAutoDisposeAsyncNotifier<RecurringRuleFormState> {
  late final int? ruleId;

  FutureOr<RecurringRuleFormState> build({int? ruleId});
}

/// See also [RecurringRuleFormController].
@ProviderFor(RecurringRuleFormController)
const recurringRuleFormControllerProvider = RecurringRuleFormControllerFamily();

/// See also [RecurringRuleFormController].
class RecurringRuleFormControllerFamily
    extends Family<AsyncValue<RecurringRuleFormState>> {
  /// See also [RecurringRuleFormController].
  const RecurringRuleFormControllerFamily();

  /// See also [RecurringRuleFormController].
  RecurringRuleFormControllerProvider call({int? ruleId}) {
    return RecurringRuleFormControllerProvider(ruleId: ruleId);
  }

  @override
  RecurringRuleFormControllerProvider getProviderOverride(
    covariant RecurringRuleFormControllerProvider provider,
  ) {
    return call(ruleId: provider.ruleId);
  }

  static final Iterable<ProviderOrFamily> _dependencies = <ProviderOrFamily>{
    recurringRulesRepositoryProvider,
    pendingTransactionRepositoryProvider,
    recurringGenerationUseCaseProvider,
    currencyRepositoryProvider,
    userPreferencesRepositoryProvider,
  };

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static final Iterable<ProviderOrFamily> _allTransitiveDependencies =
      <ProviderOrFamily>{
        recurringRulesRepositoryProvider,
        ...?recurringRulesRepositoryProvider.allTransitiveDependencies,
        pendingTransactionRepositoryProvider,
        ...?pendingTransactionRepositoryProvider.allTransitiveDependencies,
        recurringGenerationUseCaseProvider,
        ...?recurringGenerationUseCaseProvider.allTransitiveDependencies,
        currencyRepositoryProvider,
        ...?currencyRepositoryProvider.allTransitiveDependencies,
        userPreferencesRepositoryProvider,
        ...?userPreferencesRepositoryProvider.allTransitiveDependencies,
      };

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'recurringRuleFormControllerProvider';
}

/// See also [RecurringRuleFormController].
class RecurringRuleFormControllerProvider
    extends
        AutoDisposeAsyncNotifierProviderImpl<
          RecurringRuleFormController,
          RecurringRuleFormState
        > {
  /// See also [RecurringRuleFormController].
  RecurringRuleFormControllerProvider({int? ruleId})
    : this._internal(
        () => RecurringRuleFormController()..ruleId = ruleId,
        from: recurringRuleFormControllerProvider,
        name: r'recurringRuleFormControllerProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$recurringRuleFormControllerHash,
        dependencies: RecurringRuleFormControllerFamily._dependencies,
        allTransitiveDependencies:
            RecurringRuleFormControllerFamily._allTransitiveDependencies,
        ruleId: ruleId,
      );

  RecurringRuleFormControllerProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.ruleId,
  }) : super.internal();

  final int? ruleId;

  @override
  FutureOr<RecurringRuleFormState> runNotifierBuild(
    covariant RecurringRuleFormController notifier,
  ) {
    return notifier.build(ruleId: ruleId);
  }

  @override
  Override overrideWith(RecurringRuleFormController Function() create) {
    return ProviderOverride(
      origin: this,
      override: RecurringRuleFormControllerProvider._internal(
        () => create()..ruleId = ruleId,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        ruleId: ruleId,
      ),
    );
  }

  @override
  AutoDisposeAsyncNotifierProviderElement<
    RecurringRuleFormController,
    RecurringRuleFormState
  >
  createElement() {
    return _RecurringRuleFormControllerProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is RecurringRuleFormControllerProvider &&
        other.ruleId == ruleId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, ruleId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin RecurringRuleFormControllerRef
    on AutoDisposeAsyncNotifierProviderRef<RecurringRuleFormState> {
  /// The parameter `ruleId` of this provider.
  int? get ruleId;
}

class _RecurringRuleFormControllerProviderElement
    extends
        AutoDisposeAsyncNotifierProviderElement<
          RecurringRuleFormController,
          RecurringRuleFormState
        >
    with RecurringRuleFormControllerRef {
  _RecurringRuleFormControllerProviderElement(super.provider);

  @override
  int? get ruleId => (origin as RecurringRuleFormControllerProvider).ruleId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
