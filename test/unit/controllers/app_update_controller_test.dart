// Guards AppUpdateController: download → permission → install, progress
// throttling, typed failures, and ignoring taps while downloading.

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:ledgerly/app/bootstrap.dart';
import 'package:ledgerly/app/providers/repository_providers.dart';
import 'package:ledgerly/data/models/app_update.dart';
import 'package:ledgerly/data/repositories/app_update_repository.dart';
import 'package:ledgerly/features/settings/app_update_controller.dart';
import 'package:ledgerly/features/settings/app_update_state.dart';

class _MockRepo extends Mock implements AppUpdateRepository {}

final _update = AppUpdate(
  version: 'v0.7.4',
  fileName: 'ledgerly-v0.7.4-arm64-v8a.apk',
  apkUrl: Uri.parse('https://example.com/a.apk'),
  sha256: 'ab' * 32,
  sizeBytes: 100,
);
const _path = '/cache/updates/ledgerly-v0.7.4-arm64-v8a.apk';

void main() {
  late _MockRepo repo;
  late ProviderContainer container;
  late List<AppUpdateState> states;

  setUpAll(() => registerFallbackValue(_update));

  setUp(() {
    repo = _MockRepo();
    container = ProviderContainer(
      retry: noProviderRetry,
      overrides: [appUpdateRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);
    states = [];
    container.listen(
      appUpdateControllerProvider,
      (_, next) => states.add(next),
      fireImmediately: true,
    );
    when(() => repo.canInstall()).thenAnswer((_) async => true);
    when(() => repo.openInstallSettings()).thenAnswer((_) async {});
  });

  AppUpdateController controller() =>
      container.read(appUpdateControllerProvider.notifier);

  void stubDownload({List<double> progress = const []}) {
    when(() => repo.download(any(), onProgress: any(named: 'onProgress')))
        .thenAnswer((inv) async {
          final cb = inv.namedArguments[#onProgress] as void Function(double)?;
          progress.forEach(cb!);
          return _path;
        });
  }

  test(
    'downloads, then installs; progress emits once per whole percent',
    () async {
      stubDownload(progress: [0.001, 0.004, 0.5, 0.501, 1.0]);
      when(() => repo.install(_path))
          .thenAnswer((_) => Completer<InstallOutcome>().future);

      unawaited(controller().start(_update));
      await pumpEventQueue();

      expect(states, [
        const AppUpdateState.idle(),
        const AppUpdateState.downloading(0),
        const AppUpdateState.downloading(50),
        const AppUpdateState.downloading(100),
        const AppUpdateState.installing(_path),
      ]);
    },
  );

  test(
    'without install permission opens settings and waits in ready',
    () async {
      stubDownload();
      when(() => repo.canInstall()).thenAnswer((_) async => false);

      await controller().start(_update);

      expect(
        states.last,
        const AppUpdateState.ready(_path, needsPermission: true),
      );
      verify(() => repo.openInstallSettings()).called(1);
      verifyNever(() => repo.install(any()));
    },
  );

  test('a failing install-permission check fails with generic', () async {
    stubDownload();
    when(() => repo.canInstall()).thenThrow(Exception('channel'));

    await controller().start(_update);

    expect(states.last, const AppUpdateState.failed(UpdateFailure.generic));
  });

  test('failing to open install settings fails with generic', () async {
    stubDownload();
    when(() => repo.canInstall()).thenAnswer((_) async => false);
    when(() => repo.openInstallSettings()).thenThrow(Exception('channel'));

    await controller().start(_update);

    expect(states.last, const AppUpdateState.failed(UpdateFailure.generic));
  });

  test('tapping again from ready installs without re-downloading', () async {
    stubDownload();
    when(() => repo.canInstall()).thenAnswer((_) async => false);
    await controller().start(_update);
    when(() => repo.canInstall()).thenAnswer((_) async => true);
    when(() => repo.install(_path))
        .thenAnswer((_) async => InstallOutcome.cancelled);

    await controller().start(_update);

    verify(() => repo.download(any(), onProgress: any(named: 'onProgress')))
        .called(1);
    expect(states.last, const AppUpdateState.ready(_path));
  });

  test('a newer install tap keeps installing when the older one '
      'reports back', () async {
    stubDownload();
    when(() => repo.canInstall()).thenAnswer((_) async => false);
    await controller().start(_update);
    when(() => repo.canInstall()).thenAnswer((_) async => true);
    final first = Completer<InstallOutcome>();
    var calls = 0;
    when(() => repo.install(_path)).thenAnswer(
      (_) => ++calls == 1 ? first.future : Completer<InstallOutcome>().future,
    );

    unawaited(controller().start(_update));
    await pumpEventQueue();
    unawaited(controller().start(_update));
    await pumpEventQueue();
    first.complete(InstallOutcome.cancelled);
    await pumpEventQueue();

    verify(() => repo.install(_path)).called(2);
    expect(states.last, const AppUpdateState.installing(_path));
  });

  test('a tap while downloading is ignored', () async {
    final gate = Completer<String>();
    when(() => repo.download(any(), onProgress: any(named: 'onProgress')))
        .thenAnswer((_) => gate.future);

    unawaited(controller().start(_update));
    await controller().start(_update);

    verify(() => repo.download(any(), onProgress: any(named: 'onProgress')))
        .called(1);
  });

  for (final (error, reason) in [
    (const UpdateDownloadException(), UpdateFailure.network),
    (const UpdateChecksumException(), UpdateFailure.checksum),
    (const UpdateStorageException(), UpdateFailure.storage),
  ]) {
    test('${error.runtimeType} fails with $reason', () async {
      when(() => repo.download(any(), onProgress: any(named: 'onProgress')))
          .thenThrow(error);
      await controller().start(_update);
      expect(states.last, AppUpdateState.failed(reason));
    });
  }

  for (final (outcome, expected) in [
    (InstallOutcome.cancelled, const AppUpdateState.ready(_path)),
    (
      InstallOutcome.signatureConflict,
      const AppUpdateState.failed(UpdateFailure.signatureConflict),
    ),
    (
      InstallOutcome.storage,
      const AppUpdateState.failed(UpdateFailure.storage),
    ),
    (InstallOutcome.failed, const AppUpdateState.failed(UpdateFailure.generic)),
  ]) {
    test('install $outcome → $expected', () async {
      stubDownload();
      when(() => repo.install(_path)).thenAnswer((_) async => outcome);
      await controller().start(_update);
      expect(states.last, expected);
    });
  }

  test('after a failure, a tap starts over', () async {
    when(() => repo.download(any(), onProgress: any(named: 'onProgress')))
        .thenThrow(const UpdateDownloadException());
    await controller().start(_update);
    stubDownload();
    when(() => repo.install(_path))
        .thenAnswer((_) async => InstallOutcome.cancelled);

    await controller().start(_update);

    expect(states.last, const AppUpdateState.ready(_path));
  });
}
