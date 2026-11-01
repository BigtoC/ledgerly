// In-app update flow state for the Settings new-version badge.

import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_update_state.freezed.dart';

/// Why the in-app update stopped. Each maps to one SnackBar message.
enum UpdateFailure { network, checksum, storage, signatureConflict, generic }

@freezed
sealed class AppUpdateState with _$AppUpdateState {
  /// Nothing started (or a previous attempt failed and was reported).
  const factory AppUpdateState.idle() = AppUpdateIdle;

  /// Downloading; [percent] is 0–100.
  const factory AppUpdateState.downloading(int percent) = AppUpdateDownloading;

  /// Verified APK at [path]; tapping installs it. [needsPermission] is
  /// true when the "Install unknown apps" page was just opened.
  const factory AppUpdateState.ready(
    String path, {
    @Default(false) bool needsPermission,
  }) = AppUpdateReady;

  /// Handed to Android's installer.
  const factory AppUpdateState.installing(String path) = AppUpdateInstalling;

  /// The last attempt failed; the badge reports it once.
  const factory AppUpdateState.failed(UpdateFailure reason) = AppUpdateFailed;
}
