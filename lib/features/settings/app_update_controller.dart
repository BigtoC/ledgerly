// In-app update controller (docs/superpowers/plans/2026-10-30-in-app-apk-update.md).
//
// Keep-alive (not a family, so allowed) so a download keeps going when
// the user leaves Settings. build() has no side effects; every await is
// followed by a ref.mounted check.

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../app/providers/repository_providers.dart';
import '../../data/models/app_update.dart';
import '../../data/repositories/app_update_repository.dart';
import 'app_update_state.dart';

part 'app_update_controller.g.dart';

@Riverpod(keepAlive: true)
class AppUpdateController extends _$AppUpdateController {
  @override
  AppUpdateState build() => const AppUpdateState.idle();

  /// The badge tap: downloads and verifies [update] if needed, then
  /// installs it. Ignored while a download is running.
  Future<void> start(AppUpdate update) async {
    final repo = ref.read(appUpdateRepositoryProvider);
    switch (state) {
      case AppUpdateDownloading():
        return;
      case AppUpdateReady(:final path) || AppUpdateInstalling(:final path):
        return _install(repo, path);
      case AppUpdateIdle() || AppUpdateFailed():
        state = const AppUpdateState.downloading(0);
        final String path;
        try {
          path = await repo.download(update, onProgress: _onProgress);
        } on UpdateChecksumException {
          return _fail(UpdateFailure.checksum);
        } on UpdateStorageException {
          return _fail(UpdateFailure.storage);
        } on Object {
          return _fail(UpdateFailure.network);
        }
        if (!ref.mounted) return;
        return _install(repo, path);
    }
  }

  void _onProgress(double fraction) {
    final percent = (fraction * 100).floor().clamp(0, 100);
    if (!ref.mounted) return;
    if (state case AppUpdateDownloading(percent: final p) when p != percent) {
      state = AppUpdateState.downloading(percent);
    }
  }

  /// Bumped by each [_install]; an older call whose number no longer
  /// matches has been replaced by a newer tap and leaves [state] alone.
  int _installAttempt = 0;

  Future<void> _install(AppUpdateRepository repo, String path) async {
    final attempt = ++_installAttempt;
    bool stale() => !ref.mounted || attempt != _installAttempt;
    final bool allowed;
    try {
      allowed = await repo.canInstall();
    } on Object {
      if (!stale()) _fail(UpdateFailure.generic);
      return;
    }
    if (!allowed) {
      if (stale()) return;
      state = AppUpdateState.ready(path, needsPermission: true);
      try {
        await repo.openInstallSettings();
      } on Object {
        if (!stale()) _fail(UpdateFailure.generic);
      }
      return;
    }
    if (stale()) return;
    state = AppUpdateState.installing(path);
    final outcome = await repo.install(path);
    if (stale()) return;
    state = switch (outcome) {
      // Android replaces this process; nothing left to show.
      InstallOutcome.success => AppUpdateState.installing(path),
      InstallOutcome.cancelled => AppUpdateState.ready(path),
      InstallOutcome.signatureConflict => const AppUpdateState.failed(
        UpdateFailure.signatureConflict,
      ),
      InstallOutcome.storage => const AppUpdateState.failed(
        UpdateFailure.storage,
      ),
      InstallOutcome.failed => const AppUpdateState.failed(
        UpdateFailure.generic,
      ),
    };
  }

  void _fail(UpdateFailure reason) {
    if (ref.mounted) state = AppUpdateState.failed(reason);
  }
}
