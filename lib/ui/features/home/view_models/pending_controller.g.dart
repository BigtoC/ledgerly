// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pending_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(PendingController)
final pendingControllerProvider = PendingControllerProvider._();

final class PendingControllerProvider
    extends $StreamNotifierProvider<PendingController, PendingState> {
  PendingControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pendingControllerProvider',
        isAutoDispose: false,
        dependencies: <ProviderOrFamily>[pendingTransactionRepositoryProvider],
        $allTransitiveDependencies: <ProviderOrFamily>[
          PendingControllerProvider.$allTransitiveDependencies0,
          PendingControllerProvider.$allTransitiveDependencies1,
          PendingControllerProvider.$allTransitiveDependencies2,
        ],
      );

  static final $allTransitiveDependencies0 =
      pendingTransactionRepositoryProvider;
  static final $allTransitiveDependencies1 =
      PendingTransactionRepositoryProvider.$allTransitiveDependencies0;
  static final $allTransitiveDependencies2 =
      PendingTransactionRepositoryProvider.$allTransitiveDependencies1;

  @override
  String debugGetCreateSourceHash() => _$pendingControllerHash();

  @$internal
  @override
  PendingController create() => PendingController();
}

String _$pendingControllerHash() => r'52bd03d1190f8e8b49e0ebdc5d01579b3c685291';

abstract class _$PendingController extends $StreamNotifier<PendingState> {
  Stream<PendingState> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<PendingState>, PendingState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<PendingState>, PendingState>,
              AsyncValue<PendingState>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
