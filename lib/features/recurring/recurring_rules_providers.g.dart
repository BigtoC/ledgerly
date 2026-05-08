// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recurring_rules_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$pendingCountForRuleHash() =>
    r'75a854babbe207238995e38fd4e8009f60c604d1';

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

/// Returns the count of pending items for a given rule.
/// Used by the form screen's inline notice. Reads
/// PendingTransactionRepository directly — no need to proxy through
/// RecurringRulesRepository.
///
/// Copied from [pendingCountForRule].
@ProviderFor(pendingCountForRule)
const pendingCountForRuleProvider = PendingCountForRuleFamily();

/// Returns the count of pending items for a given rule.
/// Used by the form screen's inline notice. Reads
/// PendingTransactionRepository directly — no need to proxy through
/// RecurringRulesRepository.
///
/// Copied from [pendingCountForRule].
class PendingCountForRuleFamily extends Family<AsyncValue<int>> {
  /// Returns the count of pending items for a given rule.
  /// Used by the form screen's inline notice. Reads
  /// PendingTransactionRepository directly — no need to proxy through
  /// RecurringRulesRepository.
  ///
  /// Copied from [pendingCountForRule].
  const PendingCountForRuleFamily();

  /// Returns the count of pending items for a given rule.
  /// Used by the form screen's inline notice. Reads
  /// PendingTransactionRepository directly — no need to proxy through
  /// RecurringRulesRepository.
  ///
  /// Copied from [pendingCountForRule].
  PendingCountForRuleProvider call(int ruleId) {
    return PendingCountForRuleProvider(ruleId);
  }

  @override
  PendingCountForRuleProvider getProviderOverride(
    covariant PendingCountForRuleProvider provider,
  ) {
    return call(provider.ruleId);
  }

  static final Iterable<ProviderOrFamily> _dependencies = <ProviderOrFamily>[
    pendingTransactionRepositoryProvider,
  ];

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static final Iterable<ProviderOrFamily> _allTransitiveDependencies =
      <ProviderOrFamily>{
        pendingTransactionRepositoryProvider,
        ...?pendingTransactionRepositoryProvider.allTransitiveDependencies,
      };

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'pendingCountForRuleProvider';
}

/// Returns the count of pending items for a given rule.
/// Used by the form screen's inline notice. Reads
/// PendingTransactionRepository directly — no need to proxy through
/// RecurringRulesRepository.
///
/// Copied from [pendingCountForRule].
class PendingCountForRuleProvider extends AutoDisposeFutureProvider<int> {
  /// Returns the count of pending items for a given rule.
  /// Used by the form screen's inline notice. Reads
  /// PendingTransactionRepository directly — no need to proxy through
  /// RecurringRulesRepository.
  ///
  /// Copied from [pendingCountForRule].
  PendingCountForRuleProvider(int ruleId)
    : this._internal(
        (ref) => pendingCountForRule(ref as PendingCountForRuleRef, ruleId),
        from: pendingCountForRuleProvider,
        name: r'pendingCountForRuleProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$pendingCountForRuleHash,
        dependencies: PendingCountForRuleFamily._dependencies,
        allTransitiveDependencies:
            PendingCountForRuleFamily._allTransitiveDependencies,
        ruleId: ruleId,
      );

  PendingCountForRuleProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.ruleId,
  }) : super.internal();

  final int ruleId;

  @override
  Override overrideWith(
    FutureOr<int> Function(PendingCountForRuleRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: PendingCountForRuleProvider._internal(
        (ref) => create(ref as PendingCountForRuleRef),
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
  AutoDisposeFutureProviderElement<int> createElement() {
    return _PendingCountForRuleProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is PendingCountForRuleProvider && other.ruleId == ruleId;
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
mixin PendingCountForRuleRef on AutoDisposeFutureProviderRef<int> {
  /// The parameter `ruleId` of this provider.
  int get ruleId;
}

class _PendingCountForRuleProviderElement
    extends AutoDisposeFutureProviderElement<int>
    with PendingCountForRuleRef {
  _PendingCountForRuleProviderElement(super.provider);

  @override
  int get ruleId => (origin as PendingCountForRuleProvider).ruleId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
