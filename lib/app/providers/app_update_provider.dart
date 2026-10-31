import 'dart:ffi' show Abi;
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/models/app_update.dart';
import '../../data/repositories/app_update_repository.dart';
import '../../data/services/apk_installer_service.dart';
import '../../data/services/app_release_service.dart';
import 'service_providers.dart';

part 'app_update_provider.g.dart';

/// GitHub release lookup for the app-update check. Unscoped: it shares the
/// app-wide [dioProvider] client and reads nothing from the database.
@Riverpod(keepAlive: true)
AppUpdateRepository appUpdateRepository(Ref ref) => AppUpdateRepository(
  AppReleaseService(ref.watch(dioProvider)),
  installer: const ApkInstallerService(),
  updatesDir: () async =>
      Directory('${(await getTemporaryDirectory()).path}/updates')
          .create(recursive: true),
  installedVersion: () async => (await PackageInfo.fromPlatform()).version,
  abi: Abi.current(),
);

const _readyTimeout = Duration(seconds: 30);

/// The newer release, or null. `build()` has no side effects; `App`
/// triggers [checkAfter] once per launch after the first frame.
@Riverpod(keepAlive: true)
class AvailableAppUpdate extends _$AvailableAppUpdate {
  bool _requested = false;

  @override
  AppUpdate? build() => null;

  /// Waits for [ready] (the startup FX refresh), then checks for a newer
  /// release. Stops waiting after [_readyTimeout], so a refresh that never
  /// settles cannot cancel the check. Later calls are no-ops.
  Future<void> checkAfter(Future<void> ready) async {
    if (_requested) return;
    _requested = true;
    final repo = ref.read(appUpdateRepositoryProvider);
    // Nothing to check here, so don't wait (or start a timer).
    if (!repo.isSupported) return;
    await ready.timeout(_readyTimeout, onTimeout: () {});
    if (!ref.mounted) return;
    final AppUpdate? update;
    try {
      update = await repo.findUpdate();
    } on Object catch (e) {
      // Best-effort background check: no failure may escape to the
      // unawaited caller, Errors included. Skip clean-up too: a failed
      // check says nothing about which downloaded APK is still current.
      debugPrint('AvailableAppUpdate.checkAfter failed (${e.runtimeType})');
      return;
    }
    await repo.cleanUp(keep: update);
    if (ref.mounted) state = update;
  }
}
