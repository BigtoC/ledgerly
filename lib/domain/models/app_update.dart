import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_update.freezed.dart';

/// A newer GitHub release APK built for this device's ABI.
@freezed
abstract class AppUpdate with _$AppUpdate {
  const factory AppUpdate({
    /// Release tag, e.g. `v0.7.3`.
    required String version,

    /// Asset name, e.g. `ledgerly-v0.7.3-arm64-v8a.apk`.
    required String fileName,

    /// https `browser_download_url` of the asset.
    required Uri apkUrl,

    /// Lowercase hex SHA-256 from the asset's GitHub `digest`. Null, along
    /// with [sizeBytes], when either is missing or malformed: the update
    /// can then only be opened in the browser.
    String? sha256,

    /// Asset size in bytes, shown before downloading.
    int? sizeBytes,
  }) = _AppUpdate;
}
