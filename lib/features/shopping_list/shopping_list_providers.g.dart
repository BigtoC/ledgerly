// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shopping_list_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$shoppingListPreviewHash() =>
    r'2fda7178ade35486f907ddb5d642b1c1c64546bb';

/// Preview rows: newest 3 drafts.
///
/// Watches [shoppingListRepositoryProvider.watchAll()] and emits the first 3
/// items. The full stream is still used by the card to compute overflow.
///
/// Copied from [shoppingListPreview].
@ProviderFor(shoppingListPreview)
final shoppingListPreviewProvider =
    AutoDisposeStreamProvider<List<ShoppingListItem>>.internal(
      shoppingListPreview,
      name: r'shoppingListPreviewProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$shoppingListPreviewHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ShoppingListPreviewRef =
    AutoDisposeStreamProviderRef<List<ShoppingListItem>>;
String _$shoppingListTotalCountHash() =>
    r'8077e05758c5a6146a5ded1be5c59dc3aa87902a';

/// Full count stream — used alongside [shoppingListPreviewProvider] to
/// compute the overflow count shown in the card.
///
/// Copied from [shoppingListTotalCount].
@ProviderFor(shoppingListTotalCount)
final shoppingListTotalCountProvider = AutoDisposeStreamProvider<int>.internal(
  shoppingListTotalCount,
  name: r'shoppingListTotalCountProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$shoppingListTotalCountHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ShoppingListTotalCountRef = AutoDisposeStreamProviderRef<int>;
String _$shoppingListCategoryByIdHash() =>
    r'd65051e1e179e9ac49d30dd1c509d71fc1c85f08';

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

/// One-shot read for archived-safe category name hydration.
///
/// Calls [getById] which returns the row even if archived, so archived names
/// still display in preview rows.
///
/// Copied from [shoppingListCategoryById].
@ProviderFor(shoppingListCategoryById)
const shoppingListCategoryByIdProvider = ShoppingListCategoryByIdFamily();

/// One-shot read for archived-safe category name hydration.
///
/// Calls [getById] which returns the row even if archived, so archived names
/// still display in preview rows.
///
/// Copied from [shoppingListCategoryById].
class ShoppingListCategoryByIdFamily extends Family<AsyncValue<Category?>> {
  /// One-shot read for archived-safe category name hydration.
  ///
  /// Calls [getById] which returns the row even if archived, so archived names
  /// still display in preview rows.
  ///
  /// Copied from [shoppingListCategoryById].
  const ShoppingListCategoryByIdFamily();

  /// One-shot read for archived-safe category name hydration.
  ///
  /// Calls [getById] which returns the row even if archived, so archived names
  /// still display in preview rows.
  ///
  /// Copied from [shoppingListCategoryById].
  ShoppingListCategoryByIdProvider call(int id) {
    return ShoppingListCategoryByIdProvider(id);
  }

  @override
  ShoppingListCategoryByIdProvider getProviderOverride(
    covariant ShoppingListCategoryByIdProvider provider,
  ) {
    return call(provider.id);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'shoppingListCategoryByIdProvider';
}

/// One-shot read for archived-safe category name hydration.
///
/// Calls [getById] which returns the row even if archived, so archived names
/// still display in preview rows.
///
/// Copied from [shoppingListCategoryById].
class ShoppingListCategoryByIdProvider
    extends AutoDisposeFutureProvider<Category?> {
  /// One-shot read for archived-safe category name hydration.
  ///
  /// Calls [getById] which returns the row even if archived, so archived names
  /// still display in preview rows.
  ///
  /// Copied from [shoppingListCategoryById].
  ShoppingListCategoryByIdProvider(int id)
    : this._internal(
        (ref) =>
            shoppingListCategoryById(ref as ShoppingListCategoryByIdRef, id),
        from: shoppingListCategoryByIdProvider,
        name: r'shoppingListCategoryByIdProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$shoppingListCategoryByIdHash,
        dependencies: ShoppingListCategoryByIdFamily._dependencies,
        allTransitiveDependencies:
            ShoppingListCategoryByIdFamily._allTransitiveDependencies,
        id: id,
      );

  ShoppingListCategoryByIdProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.id,
  }) : super.internal();

  final int id;

  @override
  Override overrideWith(
    FutureOr<Category?> Function(ShoppingListCategoryByIdRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ShoppingListCategoryByIdProvider._internal(
        (ref) => create(ref as ShoppingListCategoryByIdRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        id: id,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<Category?> createElement() {
    return _ShoppingListCategoryByIdProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ShoppingListCategoryByIdProvider && other.id == id;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, id.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin ShoppingListCategoryByIdRef on AutoDisposeFutureProviderRef<Category?> {
  /// The parameter `id` of this provider.
  int get id;
}

class _ShoppingListCategoryByIdProviderElement
    extends AutoDisposeFutureProviderElement<Category?>
    with ShoppingListCategoryByIdRef {
  _ShoppingListCategoryByIdProviderElement(super.provider);

  @override
  int get id => (origin as ShoppingListCategoryByIdProvider).id;
}

String _$shoppingListAccountByIdHash() =>
    r'ee52afda856fc3d51061f4412251f80a459696d2';

/// One-shot read for archived-safe account name hydration.
///
/// Calls [getById] which returns the row even if archived, so archived names
/// still display in preview rows.
///
/// Copied from [shoppingListAccountById].
@ProviderFor(shoppingListAccountById)
const shoppingListAccountByIdProvider = ShoppingListAccountByIdFamily();

/// One-shot read for archived-safe account name hydration.
///
/// Calls [getById] which returns the row even if archived, so archived names
/// still display in preview rows.
///
/// Copied from [shoppingListAccountById].
class ShoppingListAccountByIdFamily extends Family<AsyncValue<Account?>> {
  /// One-shot read for archived-safe account name hydration.
  ///
  /// Calls [getById] which returns the row even if archived, so archived names
  /// still display in preview rows.
  ///
  /// Copied from [shoppingListAccountById].
  const ShoppingListAccountByIdFamily();

  /// One-shot read for archived-safe account name hydration.
  ///
  /// Calls [getById] which returns the row even if archived, so archived names
  /// still display in preview rows.
  ///
  /// Copied from [shoppingListAccountById].
  ShoppingListAccountByIdProvider call(int id) {
    return ShoppingListAccountByIdProvider(id);
  }

  @override
  ShoppingListAccountByIdProvider getProviderOverride(
    covariant ShoppingListAccountByIdProvider provider,
  ) {
    return call(provider.id);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'shoppingListAccountByIdProvider';
}

/// One-shot read for archived-safe account name hydration.
///
/// Calls [getById] which returns the row even if archived, so archived names
/// still display in preview rows.
///
/// Copied from [shoppingListAccountById].
class ShoppingListAccountByIdProvider
    extends AutoDisposeFutureProvider<Account?> {
  /// One-shot read for archived-safe account name hydration.
  ///
  /// Calls [getById] which returns the row even if archived, so archived names
  /// still display in preview rows.
  ///
  /// Copied from [shoppingListAccountById].
  ShoppingListAccountByIdProvider(int id)
    : this._internal(
        (ref) => shoppingListAccountById(ref as ShoppingListAccountByIdRef, id),
        from: shoppingListAccountByIdProvider,
        name: r'shoppingListAccountByIdProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$shoppingListAccountByIdHash,
        dependencies: ShoppingListAccountByIdFamily._dependencies,
        allTransitiveDependencies:
            ShoppingListAccountByIdFamily._allTransitiveDependencies,
        id: id,
      );

  ShoppingListAccountByIdProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.id,
  }) : super.internal();

  final int id;

  @override
  Override overrideWith(
    FutureOr<Account?> Function(ShoppingListAccountByIdRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ShoppingListAccountByIdProvider._internal(
        (ref) => create(ref as ShoppingListAccountByIdRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        id: id,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<Account?> createElement() {
    return _ShoppingListAccountByIdProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ShoppingListAccountByIdProvider && other.id == id;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, id.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin ShoppingListAccountByIdRef on AutoDisposeFutureProviderRef<Account?> {
  /// The parameter `id` of this provider.
  int get id;
}

class _ShoppingListAccountByIdProviderElement
    extends AutoDisposeFutureProviderElement<Account?>
    with ShoppingListAccountByIdRef {
  _ShoppingListAccountByIdProviderElement(super.provider);

  @override
  int get id => (origin as ShoppingListAccountByIdProvider).id;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
