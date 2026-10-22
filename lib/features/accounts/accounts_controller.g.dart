// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'accounts_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(AccountsController)
final accountsControllerProvider = AccountsControllerProvider._();

final class AccountsControllerProvider
    extends $StreamNotifierProvider<AccountsController, AccountsState> {
  AccountsControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'accountsControllerProvider',
        isAutoDispose: true,
        dependencies: <ProviderOrFamily>[
          accountRepositoryProvider,
          userPreferencesRepositoryProvider,
        ],
        $allTransitiveDependencies: <ProviderOrFamily>{
          AccountsControllerProvider.$allTransitiveDependencies0,
          AccountsControllerProvider.$allTransitiveDependencies1,
          AccountsControllerProvider.$allTransitiveDependencies2,
          AccountsControllerProvider.$allTransitiveDependencies3,
        },
      );

  static final $allTransitiveDependencies0 = accountRepositoryProvider;
  static final $allTransitiveDependencies1 =
      AccountRepositoryProvider.$allTransitiveDependencies0;
  static final $allTransitiveDependencies2 =
      AccountRepositoryProvider.$allTransitiveDependencies1;
  static final $allTransitiveDependencies3 = userPreferencesRepositoryProvider;

  @override
  String debugGetCreateSourceHash() => _$accountsControllerHash();

  @$internal
  @override
  AccountsController create() => AccountsController();
}

String _$accountsControllerHash() =>
    r'ff23d404c2ad2febe4e3599b591092c180ad4c57';

abstract class _$AccountsController extends $StreamNotifier<AccountsState> {
  Stream<AccountsState> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<AccountsState>, AccountsState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<AccountsState>, AccountsState>,
              AsyncValue<AccountsState>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
