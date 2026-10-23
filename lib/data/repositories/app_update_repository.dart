import 'dart:ffi' show Abi;

import 'package:flutter/foundation.dart';

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

  /// The https APK URL for this device's ABI from a release newer than the
  /// installed app, or null: off Android, not newer, no matching asset, or
  /// any failure.
  Future<Uri?> findUpdate() async {
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
      return uri != null && uri.isScheme('https') ? uri : null;
    } on Exception catch (e) {
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
