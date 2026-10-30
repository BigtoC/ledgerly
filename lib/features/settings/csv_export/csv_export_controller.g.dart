// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'csv_export_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(CsvExportController)
final csvExportControllerProvider = CsvExportControllerProvider._();

final class CsvExportControllerProvider
    extends $AsyncNotifierProvider<CsvExportController, CsvExportState> {
  CsvExportControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'csvExportControllerProvider',
        isAutoDispose: true,
        dependencies: <ProviderOrFamily>[csvExportUseCaseProvider],
        $allTransitiveDependencies: <ProviderOrFamily>{
          CsvExportControllerProvider.$allTransitiveDependencies0,
          CsvExportControllerProvider.$allTransitiveDependencies1,
          CsvExportControllerProvider.$allTransitiveDependencies2,
          CsvExportControllerProvider.$allTransitiveDependencies3,
          CsvExportControllerProvider.$allTransitiveDependencies4,
          CsvExportControllerProvider.$allTransitiveDependencies5,
          CsvExportControllerProvider.$allTransitiveDependencies6,
        },
      );

  static final $allTransitiveDependencies0 = csvExportUseCaseProvider;
  static final $allTransitiveDependencies1 =
      CsvExportUseCaseProvider.$allTransitiveDependencies0;
  static final $allTransitiveDependencies2 =
      CsvExportUseCaseProvider.$allTransitiveDependencies1;
  static final $allTransitiveDependencies3 =
      CsvExportUseCaseProvider.$allTransitiveDependencies2;
  static final $allTransitiveDependencies4 =
      CsvExportUseCaseProvider.$allTransitiveDependencies3;
  static final $allTransitiveDependencies5 =
      CsvExportUseCaseProvider.$allTransitiveDependencies4;
  static final $allTransitiveDependencies6 =
      CsvExportUseCaseProvider.$allTransitiveDependencies5;

  @override
  String debugGetCreateSourceHash() => _$csvExportControllerHash();

  @$internal
  @override
  CsvExportController create() => CsvExportController();
}

String _$csvExportControllerHash() =>
    r'3ad4c6db11177d8c3b96c8a6d5dfa10ffca99eb8';

abstract class _$CsvExportController extends $AsyncNotifier<CsvExportState> {
  FutureOr<CsvExportState> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<CsvExportState>, CsvExportState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<CsvExportState>, CsvExportState>,
              AsyncValue<CsvExportState>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
