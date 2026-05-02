// Smoke test for the shared in-memory Drift harness.
//
// The harness lives at `test/unit/repositories/_harness/test_app_database.dart`
// and is owned by M3 Stream C (§4 of the Stream C plan). Stream B's and
// Stream A's repository tests import this file; the smoke test below keeps
// CI green when the sibling repository tests have not merged yet.
//
// Intentionally minimal at Phase 1: ships `newTestAppDatabase()` and asserts
// the DB opens, has `foreign_keys = ON` (the `beforeOpen` pragma from
// `AppDatabase`), and closes cleanly. `TestRepoBundle` / fixture helpers
// land as their sibling repositories merge in later phases.

import 'package:drift/drift.dart' show Variable;
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/data/database/app_database.dart';

import 'test_app_database.dart';

void main() {
  setUpAll(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  tearDownAll(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = false;
  });

  group('newTestAppDatabase()', () {
    test('returns a fresh AppDatabase that opens cleanly', () async {
      final AppDatabase db = newTestAppDatabase();
      addTearDown(() async => db.close());

      expect(db, isA<AppDatabase>());
      expect(db.schemaVersion, 3);
    });

    test('has foreign_keys = ON (the beforeOpen pragma is applied)', () async {
      final AppDatabase db = newTestAppDatabase();
      addTearDown(() async => db.close());

      // Force beforeOpen by touching any table first.
      await db.customSelect('SELECT 1').get();

      final pragma = await db.customSelect('PRAGMA foreign_keys').getSingle();
      expect(pragma.read<int>('foreign_keys'), 1);
    });

    test('each call returns an isolated DB instance', () async {
      final a = newTestAppDatabase();
      final b = newTestAppDatabase();
      addTearDown(() async {
        await a.close();
        await b.close();
      });

      // Insert a currency into `a`; `b` should remain empty.
      await a.customStatement(
        'INSERT INTO currencies (code, decimals) VALUES (?, ?)',
        <Object?>['ZZZ', 0],
      );

      final aRows = await a
          .customSelect(
            'SELECT code FROM currencies WHERE code = ?',
            variables: [Variable.withString('ZZZ')],
          )
          .get();
      final bRows = await b
          .customSelect(
            'SELECT code FROM currencies WHERE code = ?',
            variables: [Variable.withString('ZZZ')],
          )
          .get();

      expect(aRows.length, 1);
      expect(bRows, isEmpty);
    });
  });
}
