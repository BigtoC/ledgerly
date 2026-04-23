// M4 §7.3 — `SplashGateSnapshot` notifier unit tests.
//
// Tests the duplicate-value no-op guard and notification behaviour directly
// on the public API, then verifies the provider wires the streams correctly.

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:ledgerly/app/providers/repository_providers.dart';
import 'package:ledgerly/app/providers/splash_redirect_provider.dart';
import 'package:ledgerly/data/repositories/user_preferences_repository.dart';

class _MockUserPreferencesRepository extends Mock
    implements UserPreferencesRepository {}

void main() {
  group('SplashGateSnapshot', () {
    test('withInitial sets fields without notifying listeners', () {
      final date = DateTime(2025, 1, 1);
      final snap = SplashGateSnapshot.withInitial(
        enabled: false,
        startDate: date,
      );
      int count = 0;
      snap.addListener(() => count++);

      expect(snap.splashEnabled, false);
      expect(snap.splashStartDate, date);
      expect(count, 0);
    });

    test('updateEnabled notifies exactly once on a real change', () {
      final snap = SplashGateSnapshot.withInitial(
        enabled: true,
        startDate: null,
      );
      int count = 0;
      snap.addListener(() => count++);

      snap.updateEnabled(false);
      expect(count, 1);
      expect(snap.splashEnabled, false);
    });

    test('updateEnabled is a no-op when value is unchanged', () {
      final snap = SplashGateSnapshot.withInitial(
        enabled: true,
        startDate: null,
      );
      int count = 0;
      snap.addListener(() => count++);

      snap.updateEnabled(true); // same value
      expect(count, 0);
    });

    test('updateStartDate notifies exactly once on a real change', () {
      final date = DateTime(2025, 6, 1);
      final snap = SplashGateSnapshot.withInitial(
        enabled: true,
        startDate: null,
      );
      int count = 0;
      snap.addListener(() => count++);

      snap.updateStartDate(date);
      expect(count, 1);
      expect(snap.splashStartDate, date);
    });

    test('updateStartDate is a no-op when value is unchanged', () {
      final date = DateTime(2025, 6, 1);
      final snap = SplashGateSnapshot.withInitial(
        enabled: true,
        startDate: date,
      );
      int count = 0;
      snap.addListener(() => count++);

      snap.updateStartDate(date); // same value
      expect(count, 0);
    });

    test('updateStartDate notifies when changing from non-null to null', () {
      final date = DateTime(2025, 6, 1);
      final snap = SplashGateSnapshot.withInitial(
        enabled: true,
        startDate: date,
      );
      int count = 0;
      snap.addListener(() => count++);

      snap.updateStartDate(null);
      expect(count, 1);
      expect(snap.splashStartDate, isNull);
    });
  });

  group('splashGateSnapshotProvider wires streams', () {
    late _MockUserPreferencesRepository mockRepo;
    late StreamController<bool> enabledCtrl;
    late StreamController<DateTime?> dateCtrl;
    late ProviderContainer container;

    setUp(() {
      mockRepo = _MockUserPreferencesRepository();
      enabledCtrl = StreamController<bool>.broadcast();
      dateCtrl = StreamController<DateTime?>.broadcast();

      when(
        () => mockRepo.watchSplashEnabled(),
      ).thenAnswer((_) => enabledCtrl.stream);
      when(
        () => mockRepo.watchSplashStartDate(),
      ).thenAnswer((_) => dateCtrl.stream);

      container = ProviderContainer(
        overrides: [
          // Override the repo so the provider never touches AppDatabase.
          userPreferencesRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
    });

    tearDown(() {
      container.dispose();
      enabledCtrl.close();
      dateCtrl.close();
    });

    test('notifier reflects enabled stream emissions', () async {
      final snap = container.read(splashGateSnapshotProvider);
      int notifyCount = 0;
      snap.addListener(() => notifyCount++);

      enabledCtrl.add(false);
      await Future<void>.delayed(Duration.zero);

      expect(notifyCount, 1);
      expect(snap.splashEnabled, false);

      // Same value — no notification.
      enabledCtrl.add(false);
      await Future<void>.delayed(Duration.zero);
      expect(notifyCount, 1);
    });

    test('notifier reflects startDate stream emissions', () async {
      final date = DateTime(2025, 3, 15);
      final snap = container.read(splashGateSnapshotProvider);
      int notifyCount = 0;
      snap.addListener(() => notifyCount++);

      dateCtrl.add(date);
      await Future<void>.delayed(Duration.zero);

      expect(notifyCount, 1);
      expect(snap.splashStartDate, date);
    });
  });
}
