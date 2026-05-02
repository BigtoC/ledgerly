// Migration harness — activates the v1 snapshot checks.
//
// See `docs/plans/m3-repositories-seed/stream-c-preferences-seed-migration.md`
// §3 for the full specification.
//
// MVP has only `drift_schemas/drift_schema_v1.json`, so the harness proves
// that the snapshot and the live `AppDatabase` agree on the v1 shape on
// both empty and seeded DBs. The Phase 2 slot (v1→v2) is marked with a
// `TODO(phase-2):` comment rather than a `skip:`'d test so the file stays
// compile-clean and grep-discoverable.
//
// Three non-trivial checks defend against "silently passing with only v1"
// (Stream C plan §3.4):
//   1. `schemaVersion` / snapshot parity — fails loudly when Phase 2
//      bumps `AppDatabase.schemaVersion` without dumping a new snapshot.
//   2. Seeded-DB open — runs the full first-run seed against the live
//      `AppDatabase` and validates the schema via
//      `GeneratedDatabase.validateDatabaseSchema`.
//   3. `PRAGMA foreign_keys` stays ON after `beforeOpen` runs — a
//      Phase-2 migration that temporarily disables FKs during a
//      table-rebuild must restore the pragma.

import 'package:drift/native.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/data/database/app_database.dart';
import 'package:ledgerly/data/repositories/account_repository.dart';
import 'package:ledgerly/data/repositories/account_type_repository.dart';
import 'package:ledgerly/data/repositories/category_repository.dart';
import 'package:ledgerly/data/repositories/currency_repository.dart';
import 'package:ledgerly/data/repositories/user_preferences_repository.dart';
import 'package:ledgerly/data/seed/first_run_seed.dart';
import 'package:ledgerly/data/services/locale_service.dart';

import '_harness/generated/schema.dart';
import '_harness/generated/schema_v1.dart' as v1;
import '_harness/generated/schema_v2.dart' as v2;

/// Fixed-locale stub for the migration test. The locale-dependent unit
/// tests live in `test/unit/seed/first_run_seed_test.dart`; here we only
/// need a deterministic currency (`USD`) so the assertions that mention
/// `accounts.currency == 'USD'` remain stable across CI hosts.
class _FakeLocaleService implements LocaleService {
  const _FakeLocaleService();
  @override
  String get deviceLocale => 'en_US';
}

void main() {
  group('migrations', () {
    test('current schemaVersion matches the latest committed snapshot', () {
      // Trivial but catches the "bumped schemaVersion without dumping a
      // snapshot" mistake next time Phase 2 touches the file.
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(() async => db.close());
      expect(db.schemaVersion, 3);
      // The drift_dev-generated helper should advance with the new snapshot.
      expect(GeneratedHelper.versions, contains(db.schemaVersion));
      expect(GeneratedHelper.versions.last, db.schemaVersion);
    });

    group('v1 snapshot', () {
      test('upgrades v1 DBs to the live schema and preserves rows', () async {
        final verifier = SchemaVerifier(GeneratedHelper());
        final schema = await verifier.schemaAt(1);
        final legacyDb = v1.DatabaseAtV1(schema.newConnection());
        addTearDown(() async => legacyDb.close());

        await legacyDb.customStatement(
          'INSERT INTO currencies (code, decimals, symbol, name_l10n_key, '
          'is_token, sort_order) VALUES (?, ?, ?, ?, 0, ?)',
          <Object?>['USD', 2, r'$', 'currency.usd', 1],
        );
        await legacyDb.close();

        final db = AppDatabase(schema.newConnection());
        addTearDown(() async => db.close());

        await verifier.migrateAndValidate(db, db.schemaVersion);

        final rows = await db.select(db.currencies).get();
        expect(rows, hasLength(1));
        expect(rows.single.code, 'USD');
        expect(rows.single.customName, isNull);
      });

      test('opens cleanly on an empty DB and matches the committed '
          'schema', () async {
        final verifier = SchemaVerifier(GeneratedHelper());

        // `schemaAt` materialises the v1 DDL from the committed JSON
        // snapshot; `startAt` loads that DDL into a live native DB.
        final schema = await verifier.schemaAt(dbVersionForOpenCheck);
        final db = AppDatabase(schema.newConnection());
        addTearDown(() async => db.close());

        // Force `beforeOpen` + `onCreate` / `onUpgrade`. onUpgrade(1 → 1)
        // is a no-op; onCreate is skipped because the snapshot already
        // created every table.
        await db.customStatement('SELECT 1');
        expect(db.schemaVersion, dbVersionForOpenCheck);

        // Cross-check the live DB's schema vs. the generated expectation.
        // If the snapshot drifted from the code (e.g. someone renamed a
        // column in the table file without dumping), this throws
        // `SchemaMismatch` with a diff in the message.
        await db.validateDatabaseSchema();
      });

      test('opens cleanly on a seeded DB (first-run seed committed)', () async {
        final db = AppDatabase(NativeDatabase.memory());
        addTearDown(() async => db.close());

        final currencies = DriftCurrencyRepository(db);
        final categories = DriftCategoryRepository(db);
        final accountTypes = DriftAccountTypeRepository(db, currencies);
        final accounts = DriftAccountRepository(db, currencies);
        final preferences = DriftUserPreferencesRepository(db);

        await runFirstRunSeed(
          db: db,
          currencies: currencies,
          categories: categories,
          accountTypes: accountTypes,
          accounts: accounts,
          preferences: preferences,
          localeService: const _FakeLocaleService(),
        );

        // Sanity row counts — if any FK / CHECK / default drifted from the
        // snapshot, the seed would have thrown before we reach these.
        expect(
          await currencies.watchAll(includeTokens: false).first,
          hasLength(11),
        );
        expect(await categories.watchAll().first, hasLength(18));
        expect(await accountTypes.watchAll().first, hasLength(2));
        final all = await accounts.watchAll().first;
        expect(all, hasLength(1));
        expect(all.single.currency.code, 'USD');

        // Schema still matches the generated v1 expectation after the
        // full seed has written rows.
        await db.validateDatabaseSchema();
      });

      test('foreign_keys stays ON after a real upgrade run', () async {
        final verifier = SchemaVerifier(GeneratedHelper());
        final connection = await verifier.startAt(1);
        final db = AppDatabase(connection.executor);
        addTearDown(() async => db.close());

        await verifier.migrateAndValidate(db, db.schemaVersion);

        final result = await db.customSelect('PRAGMA foreign_keys').getSingle();
        expect(result.read<int>('foreign_keys'), 1);
      });

      test('v1 DDL accepts v1-shaped inserts', () async {
        // Defends against the harness silently passing with a schema that
        // diverged from the snapshot: we exercise a real CRUD path on the
        // snapshot-materialised DB.
        final verifier = SchemaVerifier(GeneratedHelper());
        final schema = await verifier.schemaAt(1);
        final legacyDb = v1.DatabaseAtV1(schema.newConnection());
        addTearDown(() async => legacyDb.close());

        await legacyDb.customStatement(
          'INSERT INTO currencies (code, decimals, is_token) '
          "VALUES ('ZZZ', 0, 0)",
        );
        final row = await legacyDb
            .customSelect("SELECT code FROM currencies WHERE code = 'ZZZ'")
            .getSingle();
        expect(row.read<String>('code'), 'ZZZ');
      });
    });

    group('v2 snapshot', () {
      test('upgrades v2 DBs to the live schema', () async {
        final verifier = SchemaVerifier(GeneratedHelper());
        final schema = await verifier.schemaAt(2);
        final legacyDb = v2.DatabaseAtV2(schema.newConnection());
        addTearDown(() async => legacyDb.close());

        await legacyDb.customStatement(
          'INSERT INTO currencies (code, decimals, symbol, name_l10n_key, '
          'is_token, sort_order) VALUES (?, ?, ?, ?, 0, ?)',
          <Object?>['USD', 2, r'$', 'currency.usd', 1],
        );
        await legacyDb.close();

        final db = AppDatabase(schema.newConnection());
        addTearDown(() async => db.close());

        await verifier.migrateAndValidate(db, db.schemaVersion);

        // Existing currency row survived the migration.
        final rows = await db.select(db.currencies).get();
        expect(rows, hasLength(1));
        expect(rows.single.code, 'USD');

        // New table exists and is empty.
        final itemRows = await db.select(db.shoppingListItems).get();
        expect(itemRows, isEmpty);
      });

      test('opens cleanly on an empty DB', () async {
        final verifier = SchemaVerifier(GeneratedHelper());
        final schema = await verifier.schemaAt(dbVersionForOpenCheck);
        final db = AppDatabase(schema.newConnection());
        addTearDown(() async => db.close());

        await db.customStatement('SELECT 1');
        expect(db.schemaVersion, dbVersionForOpenCheck);
        await db.validateDatabaseSchema();
      });

      test('foreign_keys stays ON after a real upgrade run', () async {
        final verifier = SchemaVerifier(GeneratedHelper());
        final connection = await verifier.startAt(2);
        final db = AppDatabase(connection.executor);
        addTearDown(() async => db.close());

        await verifier.migrateAndValidate(db, db.schemaVersion);

        final result = await db.customSelect('PRAGMA foreign_keys').getSingle();
        expect(result.read<int>('foreign_keys'), 1);
      });
    });
  });
}

const int dbVersionForOpenCheck = 3;
