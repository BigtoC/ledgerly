import 'dart:ffi' show Abi;

import 'package:flutter/foundation.dart';

import '../models/app_update.dart';
import '../services/app_release_service.dart';

/// Finds a newer GitHub release APK built for this device's ABI.
///
/// Only Android split APKs are published, so on any other ABI this makes
/// no network call and does not read the installed version.
class AppUpdateRepository {
  AppUpdateRepository(
    this._service, {
    required this._installedVersion,
    required this._abi,
  });

  final AppReleaseService _service;
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
