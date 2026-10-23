// Guards `availableAppUpdateProvider`: the update check waits for the
// future it is given (the startup FX refresh), runs at most once per
// container, and exposes the APK URL it found.

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:ledgerly/app/bootstrap.dart';
import 'package:ledgerly/app/providers/app_update_provider.dart';
import 'package:ledgerly/data/repositories/app_update_repository.dart';

class _MockAppUpdateRepository extends Mock implements AppUpdateRepository {}

final _apkUrl = Uri.parse('https://example.com/ledgerly-v0.7.2-arm64-v8a.apk');

void main() {
  late _MockAppUpdateRepository repo;
  late ProviderContainer container;

  setUp(() {
    repo = _MockAppUpdateRepository();
    container = ProviderContainer(
      retry: noProviderRetry,
      overrides: [appUpdateRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);
  });

  test('initial state is null', () {
    expect(container.read(availableAppUpdateProvider), isNull);
  });

  test('checks only after the ready future completes', () async {
    when(() => repo.findUpdate()).thenAnswer((_) async => _apkUrl);
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
    expect(container.read(availableAppUpdateProvider), _apkUrl);
  });

  test('checks once even when called twice concurrently', () async {
    when(() => repo.findUpdate()).thenAnswer((_) async => _apkUrl);
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
}
