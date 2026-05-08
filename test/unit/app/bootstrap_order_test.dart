// M4 §7.8 — Bootstrap ordering proof (PRD risk #8: locale at the wrong time).
//
// Uses the `@visibleForTesting bootstrapFor(...)` entry point with spy
// callbacks to assert the ordering constraints the PRD mandates:
//   - DB opens before seed runs.
//   - DB opens before `runApp` is called.
//   - `runApp` is called exactly once.
//   - `runApp` receives a `ProviderScope` wrapping `App`.

import 'dart:io' show File;

import 'package:drift/native.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ledgerly/app/app.dart';
import 'package:ledgerly/app/bootstrap.dart';
import 'package:ledgerly/data/database/app_database.dart';
import 'package:ledgerly/data/services/locale_service.dart';
import 'package:ledgerly/data/use_cases/recurring_generation_use_case.dart';

/// Fixed-locale stub — keeps the seed from reading the OS locale.
class _StubLocaleService implements LocaleService {
  const _StubLocaleService();

  @override
  String get deviceLocale => 'en_US';
}

void main() {
  setUpAll(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  tearDownAll(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = false;
  });

  group('bootstrapFor ordering', () {
    test('openDatabase is called before runApp', () async {
      final log = <String>[];

      await bootstrapFor(
        openDatabase: () async {
          log.add('openDatabase');
          return AppDatabase(NativeDatabase.memory());
        },
        localeService: const _StubLocaleService(),
        runAppFn: (_) => log.add('runApp'),
      );

      expect(log, containsAllInOrder(['openDatabase', 'runApp']));
    });

    test('runApp is called exactly once', () async {
      int callCount = 0;

      await bootstrapFor(
        openDatabase: () async => AppDatabase(NativeDatabase.memory()),
        localeService: const _StubLocaleService(),
        runAppFn: (_) => callCount++,
      );

      expect(callCount, 1);
    });

    test('runApp receives a ProviderScope', () async {
      Widget? launched;

      await bootstrapFor(
        openDatabase: () async => AppDatabase(NativeDatabase.memory()),
        localeService: const _StubLocaleService(),
        runAppFn: (w) => launched = w,
      );

      expect(launched, isA<ProviderScope>());
    });

    test(
      'initialize formatting, eager reads, and seed happen before runApp',
      () async {
        final log = <String>[];
        final db = AppDatabase(NativeDatabase.memory());
        addTearDown(db.close);

        await bootstrapFor(
          openDatabase: () async {
            log.add('openDatabase');
            return db;
          },
          localeService: const _StubLocaleService(),
          initializeDateFormattingFn: (locale) async {
            log.add('initializeDateFormatting:$locale');
          },
          getSplashEnabledFn: (_) async {
            log.add('getSplashEnabled');
            return true;
          },
          getSplashStartDateFn: (_) async {
            log.add('getSplashStartDate');
            return null;
          },
          runFirstRunSeedFn:
              ({
                required db,
                required currencies,
                required categories,
                required accountTypes,
                required accounts,
                required preferences,
                required localeService,
              }) async {
                log.add('runFirstRunSeed');
              },
          runAppFn: (_) => log.add('runApp'),
        );

        expect(
          log,
          containsAllInOrder([
            'openDatabase',
            'initializeDateFormatting:en_US',
            'initializeDateFormatting:zh_TW',
            'initializeDateFormatting:zh_CN',
            'getSplashEnabled',
            'getSplashStartDate',
            'runFirstRunSeed',
            'runApp',
          ]),
        );
      },
    );

    testWidgets('recurring generation is deferred until after runApp', (
      tester,
    ) async {
      final log = <String>[];
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      Widget? launched;

      await tester.runAsync(() async {
        await bootstrapFor(
          openDatabase: () async => db,
          localeService: const _StubLocaleService(),
          runRecurringGenerationFn: (_) async {
            log.add('runRecurringGeneration');
            return const RecurringGenerationResult(outcomes: []);
          },
          runAppFn: (widget) {
            log.add('runApp');
            launched = widget;
          },
        );
      });

      expect(log, ['runApp']);
      expect(launched, isNotNull);

      final app = ((launched as ProviderScope).child as App);
      app.onFirstFrame!.call();
      await tester.runAsync(() async {
        await Future<void>.delayed(Duration.zero);
      });

      expect(log, ['runApp', 'runRecurringGeneration']);
    });

    test('main.dart has only one await (G9 guardrail)', () {
      // Static assertion — reads lib/main.dart and checks that the sole
      // awaited line is `bootstrap()`. Does not execute main().
      final mainSource = File('lib/main.dart').readAsStringSync();
      final awaitLines = mainSource
          .split('\n')
          .where((l) => RegExp(r'^\s*await\b').hasMatch(l))
          .toList();
      expect(
        awaitLines,
        hasLength(1),
        reason: 'lib/main.dart must contain exactly one await (bootstrap())',
      );
      expect(awaitLines.first, contains('bootstrap()'));
    });
  });
}
