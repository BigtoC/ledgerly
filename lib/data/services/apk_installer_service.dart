import 'package:flutter/services.dart';

/// Hands a downloaded APK to Android's package installer through the
/// `ledgerly/apk_installer` channel implemented in `MainActivity.kt`.
///
/// Android only: callers check `AppUpdateRepository.isSupported` first.
class ApkInstallerService {
  const ApkInstallerService();

  static const _channel = MethodChannel('ledgerly/apk_installer');

  /// Whether the user has allowed Ledgerly to install apps
  /// ("Install unknown apps"). Always true below Android 8.
  Future<bool> canRequestInstalls() async =>
      await _channel.invokeMethod<bool>('canRequestInstalls') ?? false;

  /// Opens the system "Install unknown apps" page for Ledgerly.
  Future<void> openInstallSettings() =>
      _channel.invokeMethod<void>('openInstallSettings');

  /// Installs the APK at [path] and returns the final
  /// `PackageInstaller.STATUS_*` code. On success Android kills this
  /// process while updating it, so the future usually never completes.
  Future<int> install(String path) async =>
      await _channel.invokeMethod<int>('install', {'path': path}) ?? 1;
}
