// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shopping_list_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Reactive total count of all shopping-list drafts.
///
/// Used by the Home screen mini-FAB badge. Returns 0 on error/loading so
/// the badge never breaks the Home screen layout.

@ProviderFor(shoppingListTotalCount)
final shoppingListTotalCountProvider = ShoppingListTotalCountProvider._();

/// Reactive total count of all shopping-list drafts.
///
/// Used by the Home screen mini-FAB badge. Returns 0 on error/loading so
/// the badge never breaks the Home screen layout.

final class ShoppingListTotalCountProvider
    extends $FunctionalProvider<AsyncValue<int>, int, Stream<int>>
    with $FutureModifier<int>, $StreamProvider<int> {
  /// Reactive total count of all shopping-list drafts.
  ///
  /// Used by the Home screen mini-FAB badge. Returns 0 on error/loading so
  /// the badge never breaks the Home screen layout.
  ShoppingListTotalCountProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'shoppingListTotalCountProvider',
        isAutoDispose: true,
        dependencies: <ProviderOrFamily>[shoppingListRepositoryProvider],
        $allTransitiveDependencies: <ProviderOrFamily>[
          ShoppingListTotalCountProvider.$allTransitiveDependencies0,
          ShoppingListTotalCountProvider.$allTransitiveDependencies1,
          ShoppingListTotalCountProvider.$allTransitiveDependencies2,
        ],
      );

  static final $allTransitiveDependencies0 = shoppingListRepositoryProvider;
  static final $allTransitiveDependencies1 =
      ShoppingListRepositoryProvider.$allTransitiveDependencies0;
  static final $allTransitiveDependencies2 =
      ShoppingListRepositoryProvider.$allTransitiveDependencies1;

  @override
  String debugGetCreateSourceHash() => _$shoppingListTotalCountHash();

  @$internal
  @override
  $StreamProviderElement<int> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<int> create(Ref ref) {
    return shoppingListTotalCount(ref);
  }
}

String _$shoppingListTotalCountHash() =>
    r'7b6cbe4a5fa4c1a4f29c0c2a88193749df077a36';

/// One-shot read for archived-safe category name hydration.
///
/// Calls [getById] which returns the row even if archived, so archived names
/// still display in preview rows.

@ProviderFor(shoppingListCategoryById)
final shoppingListCategoryByIdProvider = ShoppingListCategoryByIdFamily._();

/// One-shot read for archived-safe category name hydration.
///
/// Calls [getById] which returns the row even if archived, so archived names
/// still display in preview rows.

final class ShoppingListCategoryByIdProvider
    extends
        $FunctionalProvider<
          AsyncValue<Category?>,
          Category?,
          FutureOr<Category?>
        >
    with $FutureModifier<Category?>, $FutureProvider<Category?> {
  /// One-shot read for archived-safe category name hydration.
  ///
  /// Calls [getById] which returns the row even if archived, so archived names
  /// still display in preview rows.
  ShoppingListCategoryByIdProvider._({
    required ShoppingListCategoryByIdFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'shoppingListCategoryByIdProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  static final $allTransitiveDependencies0 = categoryRepositoryProvider;
  static final $allTransitiveDependencies1 =
      CategoryRepositoryProvider.$allTransitiveDependencies0;

  @override
  String debugGetCreateSourceHash() => _$shoppingListCategoryByIdHash();

  @override
  String toString() {
    return r'shoppingListCategoryByIdProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Category?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Category?> create(Ref ref) {
    final argument = this.argument as int;
    return shoppingListCategoryById(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ShoppingListCategoryByIdProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$shoppingListCategoryByIdHash() =>
    r'563f779b2ffc71271256f4f4e2e0ba437d3e00b1';

/// One-shot read for archived-safe category name hydration.
///
/// Calls [getById] which returns the row even if archived, so archived names
/// still display in preview rows.

final class ShoppingListCategoryByIdFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Category?>, int> {
  ShoppingListCategoryByIdFamily._()
    : super(
        retry: null,
        name: r'shoppingListCategoryByIdProvider',
        dependencies: <ProviderOrFamily>[categoryRepositoryProvider],
        $allTransitiveDependencies: <ProviderOrFamily>[
          ShoppingListCategoryByIdProvider.$allTransitiveDependencies0,
          ShoppingListCategoryByIdProvider.$allTransitiveDependencies1,
        ],
        isAutoDispose: true,
      );

  /// One-shot read for archived-safe category name hydration.
  ///
  /// Calls [getById] which returns the row even if archived, so archived names
  /// still display in preview rows.

  ShoppingListCategoryByIdProvider call(int id) =>
      ShoppingListCategoryByIdProvider._(argument: id, from: this);

  @override
  String toString() => r'shoppingListCategoryByIdProvider';
}

/// One-shot read for archived-safe account name hydration.
///
/// Calls [getById] which returns the row even if archived, so archived names
/// still display in preview rows.

@ProviderFor(shoppingListAccountById)
final shoppingListAccountByIdProvider = ShoppingListAccountByIdFamily._();

/// One-shot read for archived-safe account name hydration.
///
/// Calls [getById] which returns the row even if archived, so archived names
/// still display in preview rows.

final class ShoppingListAccountByIdProvider
    extends
        $FunctionalProvider<AsyncValue<Account?>, Account?, FutureOr<Account?>>
    with $FutureModifier<Account?>, $FutureProvider<Account?> {
  /// One-shot read for archived-safe account name hydration.
  ///
  /// Calls [getById] which returns the row even if archived, so archived names
  /// still display in preview rows.
  ShoppingListAccountByIdProvider._({
    required ShoppingListAccountByIdFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'shoppingListAccountByIdProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  static final $allTransitiveDependencies0 = accountRepositoryProvider;
  static final $allTransitiveDependencies1 =
      AccountRepositoryProvider.$allTransitiveDependencies0;
  static final $allTransitiveDependencies2 =
      AccountRepositoryProvider.$allTransitiveDependencies1;

  @override
  String debugGetCreateSourceHash() => _$shoppingListAccountByIdHash();

  @override
  String toString() {
    return r'shoppingListAccountByIdProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Account?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Account?> create(Ref ref) {
    final argument = this.argument as int;
    return shoppingListAccountById(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ShoppingListAccountByIdProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$shoppingListAccountByIdHash() =>
    r'0fa0fa15c43a9442daebf5e082a3d7837cd4e712';

/// One-shot read for archived-safe account name hydration.
///
/// Calls [getById] which returns the row even if archived, so archived names
/// still display in preview rows.

final class ShoppingListAccountByIdFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Account?>, int> {
  ShoppingListAccountByIdFamily._()
    : super(
        retry: null,
        name: r'shoppingListAccountByIdProvider',
        dependencies: <ProviderOrFamily>[accountRepositoryProvider],
        $allTransitiveDependencies: <ProviderOrFamily>[
          ShoppingListAccountByIdProvider.$allTransitiveDependencies0,
          ShoppingListAccountByIdProvider.$allTransitiveDependencies1,
          ShoppingListAccountByIdProvider.$allTransitiveDependencies2,
        ],
        isAutoDispose: true,
      );

  /// One-shot read for archived-safe account name hydration.
  ///
  /// Calls [getById] which returns the row even if archived, so archived names
  /// still display in preview rows.

  ShoppingListAccountByIdProvider call(int id) =>
      ShoppingListAccountByIdProvider._(argument: id, from: this);

  @override
  String toString() => r'shoppingListAccountByIdProvider';
}

/// One-shot currency lookup by code — used by preview rows to format amounts.
///
/// Returns null when the code is not registered (should not happen in practice
/// since amounts always reference a seeded currency).

@ProviderFor(shoppingListCurrencyByCode)
final shoppingListCurrencyByCodeProvider = ShoppingListCurrencyByCodeFamily._();

/// One-shot currency lookup by code — used by preview rows to format amounts.
///
/// Returns null when the code is not registered (should not happen in practice
/// since amounts always reference a seeded currency).

final class ShoppingListCurrencyByCodeProvider
    extends
        $FunctionalProvider<
          AsyncValue<Currency?>,
          Currency?,
          FutureOr<Currency?>
        >
    with $FutureModifier<Currency?>, $FutureProvider<Currency?> {
  /// One-shot currency lookup by code — used by preview rows to format amounts.
  ///
  /// Returns null when the code is not registered (should not happen in practice
  /// since amounts always reference a seeded currency).
  ShoppingListCurrencyByCodeProvider._({
    required ShoppingListCurrencyByCodeFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'shoppingListCurrencyByCodeProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  static final $allTransitiveDependencies0 = currencyRepositoryProvider;
  static final $allTransitiveDependencies1 =
      CurrencyRepositoryProvider.$allTransitiveDependencies0;

  @override
  String debugGetCreateSourceHash() => _$shoppingListCurrencyByCodeHash();

  @override
  String toString() {
    return r'shoppingListCurrencyByCodeProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Currency?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Currency?> create(Ref ref) {
    final argument = this.argument as String;
    return shoppingListCurrencyByCode(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ShoppingListCurrencyByCodeProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$shoppingListCurrencyByCodeHash() =>
    r'576bb91096444722a47e4e7fdd3ef3271b31d134';

/// One-shot currency lookup by code — used by preview rows to format amounts.
///
/// Returns null when the code is not registered (should not happen in practice
/// since amounts always reference a seeded currency).

final class ShoppingListCurrencyByCodeFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Currency?>, String> {
  ShoppingListCurrencyByCodeFamily._()
    : super(
        retry: null,
        name: r'shoppingListCurrencyByCodeProvider',
        dependencies: <ProviderOrFamily>[currencyRepositoryProvider],
        $allTransitiveDependencies: <ProviderOrFamily>[
          ShoppingListCurrencyByCodeProvider.$allTransitiveDependencies0,
          ShoppingListCurrencyByCodeProvider.$allTransitiveDependencies1,
        ],
        isAutoDispose: true,
      );

  /// One-shot currency lookup by code — used by preview rows to format amounts.
  ///
  /// Returns null when the code is not registered (should not happen in practice
  /// since amounts always reference a seeded currency).

  ShoppingListCurrencyByCodeProvider call(String code) =>
      ShoppingListCurrencyByCodeProvider._(argument: code, from: this);

  @override
  String toString() => r'shoppingListCurrencyByCodeProvider';
}
