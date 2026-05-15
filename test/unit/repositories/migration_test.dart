// Migration harness — covers v1, v2, and v3 snapshot checks.
//
// See `docs/plans/m3-repositories-seed/stream-c-preferences-seed-migration.md`
// §3 for the full specification.
//
// The harness proves that each committed snapshot agrees with the live
// `AppDatabase` and that each upgrade path (v1→v3, v2→v3) runs cleanly on
// both empty and seeded DBs. Snapshots live in `drift_schemas/`.
//
// Three non-trivial checks defend against "silently passing" regressions:
//   1. `schemaVersion` / snapshot parity — fails loudly when a schema bump
//      occurs without dumping a new snapshot.
//   2. Seeded-DB open — runs the full first-run seed against the live
//      `AppDatabase` and validates the schema via
//      `GeneratedDatabase.validateDatabaseSchema`.
//   3. `PRAGMA foreign_keys` stays ON after `beforeOpen` runs — a
//      migration that temporarily disables FKs during a table-rebuild must
//      restore the pragma.

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
import '_harness/generated/schema_v3.dart' as v3;
import '_harness/generated/schema_v4.dart' as v4;

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
      expect(db.schemaVersion, 5);
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

    group('v3 snapshot', () {
      test('upgrades v3 DBs to v4 and preserves rows', () async {
        final verifier = SchemaVerifier(GeneratedHelper());
        final schema = await verifier.schemaAt(3);
        final legacyDb = v3.DatabaseAtV3(schema.newConnection());
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

        // New tables exist and are empty.
        final ruleRows = await db.select(db.recurringRules).get();
        expect(ruleRows, isEmpty);
        final pendingRows = await db.select(db.pendingTransactions).get();
        expect(pendingRows, isEmpty);
      });

      test('upgrades empty v3 DB cleanly to v4 schema', () async {
        final verifier = SchemaVerifier(GeneratedHelper());
        final schema = await verifier.schemaAt(3);
        final db = AppDatabase(schema.newConnection());
        addTearDown(() async => db.close());
        await db.customStatement('SELECT 1');
        await verifier.migrateAndValidate(db, db.schemaVersion);
      });

      test('foreign_keys stays ON after a real upgrade run', () async {
        final verifier = SchemaVerifier(GeneratedHelper());
        final connection = await verifier.startAt(3);
        final db = AppDatabase(connection.executor);
        addTearDown(() async => db.close());

        await verifier.migrateAndValidate(db, db.schemaVersion);

        final result = await db.customSelect('PRAGMA foreign_keys').getSingle();
        expect(result.read<int>('foreign_keys'), 1);
      });

      test('partial UNIQUE index enforces recurring idempotency '
          'after v3→v4 upgrade', () async {
        final verifier = SchemaVerifier(GeneratedHelper());
        final connection = await verifier.startAt(3);
        final db = AppDatabase(connection.executor);
        addTearDown(() async => db.close());

        await verifier.migrateAndValidate(db, db.schemaVersion);

        // Seed a currency, account-type, account, category, and rule so
        // the FKs in pending_transactions can be satisfied.
        await db.customStatement(
          'INSERT INTO currencies (code, decimals, symbol, name_l10n_key, '
          'is_token, sort_order) VALUES (?, ?, ?, ?, 0, ?)',
          <Object?>['USD', 2, r'$', 'currency.usd', 1],
        );
        await db.customStatement(
          'INSERT INTO account_types (l10n_key, icon, color, sort_order, '
          'is_archived) VALUES (?, ?, ?, ?, ?)',
          <Object?>['at.cash', 'wallet', 0, 1, 0],
        );
        final atRow = await db
            .customSelect('SELECT id FROM account_types ORDER BY id LIMIT 1')
            .getSingle();
        final atId = atRow.read<int>('id');
        await db.customStatement(
          'INSERT INTO accounts (name, account_type_id, currency, '
          'opening_balance_minor_units, is_archived) '
          'VALUES (?, ?, ?, 0, 0)',
          <Object?>['Cash', atId, 'USD'],
        );
        final accRow = await db
            .customSelect('SELECT id FROM accounts ORDER BY id DESC LIMIT 1')
            .getSingle();
        final accId = accRow.read<int>('id');
        await db.customStatement(
          'INSERT INTO categories (l10n_key, icon, color, type, sort_order, '
          'is_archived) VALUES (?, ?, ?, ?, ?, ?)',
          <Object?>['cat.test', 'tag', 0, 'expense', 1, 0],
        );
        final catRow = await db
            .customSelect('SELECT id FROM categories ORDER BY id DESC LIMIT 1')
            .getSingle();
        final catId = catRow.read<int>('id');
        await db.customStatement(
          'INSERT INTO recurring_rules (name, amount_minor_units, currency, '
          'category_id, account_id, frequency, is_active, is_archived, '
          'next_due_date, created_at, updated_at) '
          'VALUES (?, ?, ?, ?, ?, ?, 1, 0, ?, ?, ?)',
          <Object?>['Test', 100, 'USD', catId, accId, 'daily', 0, 0, 0],
        );
        final ruleRow = await db
            .customSelect(
              'SELECT id FROM recurring_rules ORDER BY id DESC LIMIT 1',
            )
            .getSingle();
        final ruleId = ruleRow.read<int>('id');

        // First insert succeeds.
        await db.customStatement(
          'INSERT INTO pending_transactions (source, amount_minor_units, '
          'currency, account_id, category_id, date, fetched_at, '
          'recurring_rule_id) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
          <Object?>['recurring', 100, 'USD', accId, catId, 0, 0, ruleId],
        );

        // Second insert with same (recurring_rule_id, date) must be rejected.
        expect(
          () async => db.customStatement(
            'INSERT INTO pending_transactions (source, amount_minor_units, '
            'currency, account_id, category_id, date, fetched_at, '
            'recurring_rule_id) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
            <Object?>['recurring', 100, 'USD', accId, catId, 0, 0, ruleId],
          ),
          throwsA(anything),
        );
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

      test('upgrades empty v2 DB cleanly to v3 schema', () async {
        final verifier = SchemaVerifier(GeneratedHelper());
        final schema = await verifier.schemaAt(2);
        final db = AppDatabase(schema.newConnection());
        addTearDown(() async => db.close());
        await db.customStatement('SELECT 1');
        await verifier.migrateAndValidate(db, db.schemaVersion);
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

    group('v5 snapshot', () {
      test('upgrades v4 DBs to v5 and creates exchange_rates table', () async {
        final verifier = SchemaVerifier(GeneratedHelper());
        final schema = await verifier.schemaAt(4);
        // Open a v4 DB with seeded data.
        final legacyDb = v4.DatabaseAtV4(schema.newConnection());
        addTearDown(() async => legacyDb.close());

        // Seed minimal currency fixtures so FK references are valid.
        await legacyDb.customStatement(
          'INSERT INTO currencies (code, decimals, symbol, name_l10n_key, '
          'is_token, sort_order) VALUES (?, ?, ?, ?, 0, ?)',
          <Object?>['USD', 2, r'$', 'currency.usd', 1],
        );
        await legacyDb.customStatement(
          'INSERT INTO currencies (code, decimals, symbol, name_l10n_key, '
          'is_token, sort_order) VALUES (?, ?, ?, ?, 0, ?)',
          <Object?>['EUR', 2, '€', 'currency.eur', 2],
        );
        await legacyDb.close();

        final db = AppDatabase(schema.newConnection());
        addTearDown(() async => db.close());

        await verifier.migrateAndValidate(db, db.schemaVersion);

        // Verify the exchange_rates table exists and is empty.
        final rows = await db.select(db.exchangeRates).get();
        expect(rows, isEmpty);
      });

      test('v5 upgrade on empty DB succeeds', () async {
        final verifier = SchemaVerifier(GeneratedHelper());
        final schema = await verifier.schemaAt(4);
        // Don't seed anything — upgrade an empty v4 DB.
        final db = AppDatabase(schema.newConnection());
        addTearDown(() async => db.close());

        await verifier.migrateAndValidate(db, db.schemaVersion);
      });

      test(
        'exchange_rates FK to currencies is enforced after upgrade',
        () async {
          final verifier = SchemaVerifier(GeneratedHelper());
          final connection = await verifier.startAt(4);
          final db = AppDatabase(connection.executor);
          addTearDown(() async => db.close());

          await verifier.migrateAndValidate(db, db.schemaVersion);

          // Inserting a rate with a non-existent currency code must fail.
          expect(
            () async => db.customStatement(
              'INSERT INTO exchange_rates (base_currency, quote_currency, '
              'rate_scaled_e9, fetched_at) VALUES (?, ?, ?, ?)',
              <Object?>['USD', 'ZZZ', 1000000000, 0],
            ),
            throwsA(anything),
          );
        },
      );

      test('exchange_rates CHECK(rate_scaled_e9 > 0) is enforced', () async {
        final verifier = SchemaVerifier(GeneratedHelper());
        final connection = await verifier.startAt(4);
        final db = AppDatabase(connection.executor);
        addTearDown(() async => db.close());

        await verifier.migrateAndValidate(db, db.schemaVersion);

        await db.customStatement(
          'INSERT INTO currencies (code, decimals, symbol, name_l10n_key, '
          'is_token, sort_order) VALUES (?, ?, ?, ?, 0, ?)',
          <Object?>['USD', 2, r'$', 'currency.usd', 1],
        );
        await db.customStatement(
          'INSERT INTO currencies (code, decimals, symbol, name_l10n_key, '
          'is_token, sort_order) VALUES (?, ?, ?, ?, 0, ?)',
          <Object?>['EUR', 2, '€', 'currency.eur', 2],
        );

        // rate_scaled_e9 = 0 must fail.
        expect(
          () async => db.customStatement(
            'INSERT INTO exchange_rates (base_currency, quote_currency, '
            'rate_scaled_e9, fetched_at) VALUES (?, ?, ?, ?)',
            <Object?>['USD', 'EUR', 0, 0],
          ),
          throwsA(anything),
        );
      });

      test('PRAGMA foreign_keys remains ON after v5 upgrade', () async {
        final verifier = SchemaVerifier(GeneratedHelper());
        final connection = await verifier.startAt(4);
        final db = AppDatabase(connection.executor);
        addTearDown(() async => db.close());

        await verifier.migrateAndValidate(db, db.schemaVersion);

        final fkResult = await db
            .customSelect('PRAGMA foreign_keys')
            .getSingle();
        expect(fkResult.read<int>('foreign_keys'), 1);
      });
    });
  });
}

const int dbVersionForOpenCheck = 5;
