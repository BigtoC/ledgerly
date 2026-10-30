import 'dart:ffi' show Abi;
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart' show DioException;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show PlatformException;

import '../models/app_update.dart';
import '../services/apk_installer_service.dart';
import '../services/app_release_service.dart';
import 'repository_exceptions.dart';

/// How a PackageInstaller session ended, when it ended without the
/// process being replaced.
enum InstallOutcome { success, cancelled, signatureConflict, storage, failed }

/// The update APK could not be downloaded (network or HTTP failure).
class UpdateDownloadException extends RepositoryException {
  const UpdateDownloadException() : super('Update download failed');
}

/// The downloaded APK's SHA-256 does not match the release digest.
class UpdateChecksumException extends RepositoryException {
  const UpdateChecksumException() : super('Update checksum mismatch');
}

/// The update APK could not be written to local storage.
class UpdateStorageException extends RepositoryException {
  const UpdateStorageException() : super('Update could not be stored');
}

/// Finds a newer GitHub release APK built for this device's ABI, then
/// downloads, verifies and installs it.
///
/// Only Android split APKs are published, so on any other ABI this makes
/// no network call and does not read the installed version.
class AppUpdateRepository {
  AppUpdateRepository(
    this._service, {
    required this._installer,
    required this._updatesDir,
    required this._installedVersion,
    required this._abi,
  });

  final AppReleaseService _service;
  final ApkInstallerService _installer;

  /// Existing directory that holds downloaded update APKs.
  final Future<Directory> Function() _updatesDir;
  final Future<String> Function() _installedVersion;
  final Abi _abi;

  /// ABI suffix used in the release APK names
  /// (`ledgerly-vX.Y.Z-<suffix>.apk`).
  static const _apkAbi = {
    Abi.androidArm64: 'arm64-v8a',
    Abi.androidArm: 'armeabi-v7a',
    Abi.androidX64: 'x86_64',
  };

  static final _sha256Digest = RegExp(r'^sha256:([0-9a-fA-F]{64})$');

  /// Whether this device can install a published APK. When false,
  /// [findUpdate] makes no request, so callers need not wait to call it.
  bool get isSupported => _apkAbi.containsKey(_abi);

  /// The https APK for this device's ABI from a release newer than the
  /// installed app, or null: off Android, not newer, no matching asset, or
  /// any failure. Its SHA-256 and size are set only when GitHub publishes
  /// both in the expected form.
  Future<AppUpdate?> findUpdate() async {
    final abi = _apkAbi[_abi];
    if (abi == null) return null;
    try {
      final release = await _service.fetchLatestRelease();
      if (release == null ||
          !isNewerVersion(release.tagName, await _installedVersion())) {
        return null;
      }
      // Only this release's APK for this ABI, named as android-release.yml
      // uploads it. Without one, the release is not an update for this device.
      final apkName = 'ledgerly-${release.tagName}-$abi.apk';
      final asset = release.assets.where((a) => a.name == apkName).firstOrNull;
      final uri = asset == null ? null : Uri.tryParse(asset.url);
      if (asset == null || uri == null || !uri.isScheme('https')) return null;
      final hex = _sha256Digest.firstMatch(asset.digest ?? '')?[1];
      final inApp = hex != null && asset.size != null;
      return AppUpdate(
        version: release.tagName,
        fileName: apkName,
        apkUrl: uri,
        sha256: inApp ? hex.toLowerCase() : null,
        sizeBytes: inApp ? asset.size : null,
      );
    } on Object catch (e) {
      // Best-effort background check: no failure may escape to the
      // unawaited caller, Errors included.
      debugPrint('AppUpdateRepository.findUpdate failed (${e.runtimeType})');
      return null;
    }
  }

  /// Downloads [update] into the updates directory, verifies it against
  /// `update.sha256` and returns the verified APK's path. A file already
  /// verified earlier (e.g. before Android 11 restarted the app on the
  /// permission grant) is reused. [onProgress] gets 0.0–1.0.
  ///
  /// Requires `update.sha256`. Throws [UpdateDownloadException],
  /// [UpdateChecksumException] or [UpdateStorageException].
  Future<String> download(
    AppUpdate update, {
    void Function(double fraction)? onProgress,
  }) async {
    final expected = update.sha256!;
    try {
      final dir = await _updatesDir();
      final apk = File('${dir.path}/${update.fileName}');
      if (await apk.exists() && await _sha256Of(apk) == expected) {
        return apk.path;
      }
      final part = File('${apk.path}.part');
      await _service.download(
        update.apkUrl,
        part.path,
        onProgress: (received, total) {
          if (total > 0) onProgress?.call(received / total);
        },
      );
      if (await _sha256Of(part) != expected) {
        await part.delete();
        throw const UpdateChecksumException();
      }
      return (await part.rename(apk.path)).path;
    } on UpdateChecksumException {
      rethrow;
    } on FileSystemException catch (e) {
      debugPrint('AppUpdateRepository.download failed (${e.runtimeType})');
      throw const UpdateStorageException();
    } on DioException catch (e) {
      debugPrint('AppUpdateRepository.download failed (${e.runtimeType})');
      // dio wraps a failure writing the received bytes, e.g. a full disk.
      if (e.error is FileSystemException) throw const UpdateStorageException();
      throw const UpdateDownloadException();
    } on Object catch (e) {
      debugPrint('AppUpdateRepository.download failed (${e.runtimeType})');
      throw const UpdateDownloadException();
    }
  }

  static Future<String> _sha256Of(File file) async =>
      (await sha256.bind(file.openRead()).first).toString();

  /// Whether Ledgerly may install apps ("Install unknown apps").
  Future<bool> canInstall() => _installer.canRequestInstalls();

  /// Opens the system page where the user allows Ledgerly to install apps.
  Future<void> openInstallSettings() => _installer.openInstallSettings();

  /// Installs the verified APK at [path]. On success Android replaces this
  /// process, so the returned future usually never completes.
  Future<InstallOutcome> install(String path) async {
    try {
      return switch (await _installer.install(path)) {
        0 => InstallOutcome.success,
        3 => InstallOutcome.cancelled,
        5 => InstallOutcome.signatureConflict,
        6 => InstallOutcome.storage,
        _ => InstallOutcome.failed,
      };
    } on PlatformException catch (e) {
      debugPrint('AppUpdateRepository.install failed (${e.runtimeType})');
      return InstallOutcome.failed;
    }
  }

  /// Deletes every file in the updates directory except [keep]'s APK:
  /// partial downloads, and the APK left behind by an update that has
  /// already been installed. Best effort; never throws.
  Future<void> cleanUp({required AppUpdate? keep}) async {
    try {
      final dir = await _updatesDir();
      await for (final entity in dir.list()) {
        if (entity.uri.pathSegments.last != keep?.fileName) {
          await entity.delete(recursive: true);
        }
      }
    } on Object catch (e) {
      debugPrint('AppUpdateRepository.cleanUp failed (${e.runtimeType})');
    }
  }
}

final _semver = RegExp(r'^v?(\d+)\.(\d+)\.(\d+)$');

/// Strict `x.y.z` comparison (optional leading `v`). Input on either side
/// that does not parse, such as a pre-release tag, counts as not newer.
@visibleForTesting
bool isNewerVersion(String latest, String installed) {
  final a = _semver.firstMatch(latest.trim());
  final b = _semver.firstMatch(installed.trim());
  if (a == null || b == null) return false;
  for (var i = 1; i <= 3; i++) {
    final x = int.parse(a[i]!);
    final y = int.parse(b[i]!);
    if (x != y) return x > y;
  }
  return false;
}
