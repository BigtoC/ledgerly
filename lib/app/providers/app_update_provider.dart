import 'dart:ffi' show Abi;

import 'package:package_info_plus/package_info_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/repositories/app_update_repository.dart';
import '../../data/services/app_release_service.dart';
import 'repository_providers.dart';

part 'app_update_provider.g.dart';

/// GitHub release lookup for the app-update check. Unscoped: it shares the
/// app-wide [dioProvider] client and reads nothing from the database.
@Riverpod(keepAlive: true)
AppUpdateRepository appUpdateRepository(Ref ref) => AppUpdateRepository(
  AppReleaseService(ref.watch(dioProvider)),
  installedVersion: () async => (await PackageInfo.fromPlatform()).version,
  abi: Abi.current(),
);

const _readyTimeout = Duration(seconds: 30);

/// APK download URL of a newer release, or null. `build()` has no side
/// effects; `App` triggers [checkAfter] once per launch after the first
/// frame.
@Riverpod(keepAlive: true)
class AvailableAppUpdate extends _$AvailableAppUpdate {
  bool _requested = false;

  @override
  Uri? build() => null;

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
    final url = await repo.findUpdate();
    if (ref.mounted) state = url;
  }
}
