// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_version_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Installed app version and build number, shown in the Settings footer.
///
/// Features read this instead of the package-info service, which the
/// layer rules in `import_analysis_options.yaml` keep out of
/// `lib/features/`.

@ProviderFor(appVersion)
final appVersionProvider = AppVersionProvider._();

/// Installed app version and build number, shown in the Settings footer.
///
/// Features read this instead of the package-info service, which the
/// layer rules in `import_analysis_options.yaml` keep out of
/// `lib/features/`.

final class AppVersionProvider
    extends
        $FunctionalProvider<
          AsyncValue<({String buildNumber, String version})>,
          ({String buildNumber, String version}),
          FutureOr<({String buildNumber, String version})>
        >
    with
        $FutureModifier<({String buildNumber, String version})>,
        $FutureProvider<({String buildNumber, String version})> {
  /// Installed app version and build number, shown in the Settings footer.
  ///
  /// Features read this instead of the package-info service, which the
  /// layer rules in `import_analysis_options.yaml` keep out of
  /// `lib/features/`.
  AppVersionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appVersionProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appVersionHash();

  @$internal
  @override
  $FutureProviderElement<({String buildNumber, String version})> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<({String buildNumber, String version})> create(Ref ref) {
    return appVersion(ref);
  }
}

String _$appVersionHash() => r'e3600f7d64502f2d516be682a5b75914216642ce';
