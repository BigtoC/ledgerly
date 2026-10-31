// Guards `availableAppUpdateProvider`: the update check waits for the
// future it is given (the startup FX refresh), runs at most once per
// container, and exposes the update it found. It stops waiting after a
// timeout so a startup refresh that never settles cannot cancel the check,
// and it does not wait at all where no APK can be installed. Stale update
// files are cleaned up once the check has finished, but not after a failed
// check, and a failure never escapes to the unawaited caller.

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:ledgerly/app/bootstrap.dart';
import 'package:ledgerly/app/providers/app_update_provider.dart';
import 'package:ledgerly/data/models/app_update.dart';
import 'package:ledgerly/data/repositories/app_update_repository.dart';

class _MockAppUpdateRepository extends Mock implements AppUpdateRepository {}

final _update = AppUpdate(
  version: 'v0.7.2',
  fileName: 'ledgerly-v0.7.2-arm64-v8a.apk',
  apkUrl: Uri.parse('https://example.com/ledgerly-v0.7.2-arm64-v8a.apk'),
);

void main() {
  late _MockAppUpdateRepository repo;
  late ProviderContainer container;

  setUp(() {
    repo = _MockAppUpdateRepository();
    when(() => repo.isSupported).thenReturn(true);
    when(() => repo.cleanUp(keep: any(named: 'keep'))).thenAnswer((_) async {});
    container = ProviderContainer(
      retry: noProviderRetry,
      overrides: [appUpdateRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);
  });

  test('checks only after the ready future completes', () async {
    when(() => repo.findUpdate()).thenAnswer((_) async => _update);
    final ready = Completer<void>();

    final check = container
        .read(availableAppUpdateProvider.notifier)
        .checkAfter(ready.future);
    await pumpEventQueue();
    verifyNever(() => repo.findUpdate());
    expect(container.read(availableAppUpdateProvider), isNull);

    ready.complete();
    await check;

    verify(() => repo.findUpdate()).called(1);
    expect(container.read(availableAppUpdateProvider), _update);
  });

  test('checks once even when called twice concurrently', () async {
    when(() => repo.findUpdate()).thenAnswer((_) async => _update);
    final notifier = container.read(availableAppUpdateProvider.notifier);

    await Future.wait([
      notifier.checkAfter(Future.value()),
      notifier.checkAfter(Future.value()),
    ]);
    await notifier.checkAfter(Future.value());

    verify(() => repo.findUpdate()).called(1);
  });

  test('a null result keeps the state null', () async {
    when(() => repo.findUpdate()).thenAnswer((_) async => null);

    await container
        .read(availableAppUpdateProvider.notifier)
        .checkAfter(Future.value());

    verify(() => repo.findUpdate()).called(1);
    expect(container.read(availableAppUpdateProvider), isNull);
  });

  test('cleans stale update files, keeping the found update', () async {
    when(() => repo.findUpdate()).thenAnswer((_) async => _update);

    await container
        .read(availableAppUpdateProvider.notifier)
        .checkAfter(Future.value());

    verify(() => repo.cleanUp(keep: _update)).called(1);
  });

  test('a failed check skips clean-up', () async {
    when(() => repo.findUpdate())
        .thenThrow(DioException(requestOptions: RequestOptions(path: '')));

    await container
        .read(availableAppUpdateProvider.notifier)
        .checkAfter(Future.value());

    verifyNever(() => repo.cleanUp(keep: any(named: 'keep')));
  });

  test('an Error during the check does not escape', () async {
    when(() => repo.findUpdate()).thenThrow(StateError('no package info'));

    await container
        .read(availableAppUpdateProvider.notifier)
        .checkAfter(Future.value());

    verifyNever(() => repo.cleanUp(keep: any(named: 'keep')));
  });

  test('checks after the timeout when ready never completes', () {
    fakeAsync((async) {
      when(() => repo.findUpdate()).thenAnswer((_) async => _update);

      unawaited(
        container
            .read(availableAppUpdateProvider.notifier)
            .checkAfter(Completer<void>().future),
      );
      async.elapse(const Duration(seconds: 29));
      verifyNever(() => repo.findUpdate());

      async.elapse(const Duration(seconds: 2));
      verify(() => repo.findUpdate()).called(1);
      expect(container.read(availableAppUpdateProvider), _update);
    });
  });

  test('does not wait for ready where no APK can be installed', () async {
    when(() => repo.isSupported).thenReturn(false);
    when(() => repo.findUpdate()).thenAnswer((_) async => null);

    await container
        .read(availableAppUpdateProvider.notifier)
        .checkAfter(Completer<void>().future);

    verifyNever(() => repo.findUpdate());
  });
}
