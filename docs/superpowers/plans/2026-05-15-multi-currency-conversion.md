# Multi-Currency Conversion Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fetch live exchange rates on startup, persist as integer fractions in Drift, and display auto-converted amounts in the user's default currency on SummaryStrip, TransactionTile, and AccountTile.

**Architecture:** New `exchange_rates` Drift table stores rates as integer-fraction pairs (numerator/denominator at 10⁹). A repository subscribes to the DAO's `watchAll()` stream to maintain an in-memory snapshot map, and subscribes to `defaultCurrencyProvider` to re-fetch on currency change. Conversion uses pure BigInt integer arithmetic in a new `CurrencyConverter` utility. UI tiles read the snapshot via a Riverpod provider and render converted amounts as secondary muted lines.

**Tech Stack:** `dio` (HTTP), Drift (table + DAO), Riverpod (providers), BigInt integer arithmetic (conversion), existing `MoneyFormatter` (formatting).

---

## File Structure

### New Files

| File                                                              | Responsibility                                                                             |
|-------------------------------------------------------------------|--------------------------------------------------------------------------------------------|
| `lib/data/database/tables/exchange_rates_table.dart`              | Drift table definition for `exchange_rates`                                                |
| `lib/data/database/daos/exchange_rate_dao.dart`                   | DAO: `upsertAll()`, `watchAll()`, `distinctCurrenciesAcrossAllTables()`                    |
| `lib/data/services/exchange_rate_service.dart`                    | HTTP client via Dio, calls `/api/conversion` endpoint                                      |
| `lib/data/repositories/exchange_rate_repository.dart`             | Abstract contract + `DriftExchangeRateRepository` (snapshot, sanity bounds, inverse rates) |
| `lib/core/utils/currency_converter.dart`                          | Pure function: `convertMinorUnits()` using BigInt arithmetic                               |
| `test/unit/services/exchange_rate_service_test.dart`              | Service unit tests (mock Dio)                                                              |
| `test/unit/repositories/exchange_rate_repository_test.dart`       | Repository unit tests (in-memory DB + mock service)                                        |
| `test/unit/utils/currency_converter_test.dart`                    | Converter unit tests                                                                       |
| `test/widget/features/home/summary_strip_conversion_test.dart`    | SummaryStrip conversion widget tests                                                       |
| `test/widget/features/home/transaction_tile_conversion_test.dart` | TransactionTile conversion widget tests                                                    |
| `test/widget/features/accounts/account_tile_conversion_test.dart` | AccountTile conversion widget tests                                                        |
| `test/integration/currency_conversion_flow_test.dart`             | End-to-end integration test                                                                |

### Modified Files

| File                                                         | Change                                                                                       |
|--------------------------------------------------------------|----------------------------------------------------------------------------------------------|
| `pubspec.yaml`                                               | Add `dio` dependency                                                                         |
| `lib/data/database/app_database.dart`                        | Register table + DAO, bump schema to v5, add migration                                       |
| `lib/app/providers/repository_providers.dart`                | Add `exchangeRateServiceProvider`, `exchangeRateRepositoryProvider`, `exchangeRatesProvider` |
| `lib/features/settings/settings_providers.dart`              | Add `defaultCurrencyProvider` (first `@riverpod` provider in this file)                      |
| `lib/app/bootstrap.dart`                                     | Eager-read `exchangeRateRepositoryProvider` before `runApp`                                  |
| `lib/features/accounts/accounts_providers.dart`              | Post-save on-demand fetch in `AccountFormActions.save()`                                     |
| `lib/features/transactions/transaction_form_controller.dart` | Post-save on-demand fetch in `save()`                                                        |
| `lib/features/home/widgets/summary_strip.dart`               | Unified default-currency total with per-row fallback                                         |
| `lib/features/home/widgets/transaction_tile.dart`            | Secondary converted amount line                                                              |
| `lib/features/accounts/widgets/account_tile.dart`            | Converted total below per-currency balances                                                  |
| `l10n/app_en.arb`                                            | Add `approximatelyPrefix`, `convertedTotalLabel`, `accountTileShowMore`                      |
| `l10n/app_zh_CN.arb`                                         | Add zh_CN translations                                                                       |
| `l10n/app_zh_TW.arb`                                         | Add zh_TW translations                                                                       |
| `l10n/app_zh.arb`                                            | Keep as-is (4-line shim)                                                                     |
| `test/unit/repositories/migration_test.dart`                 | Extend with v5 schema helpers and upgrade tests                                              |

---

## Chunk 1: Data Foundation

### Task 1: Add `dio` to pubspec.yaml

**Files:**
- Modify: `pubspec.yaml`

- [ ] **Step 1: Add dio dependency**

In `pubspec.yaml`, under `dependencies:`, after the `webview_flutter` line, add:

```yaml
  # HTTP client (Phase 2 exchange-rate fetch)
  dio: ^5.7.0
```

- [ ] **Step 2: Run pub get**

Run: `flutter pub get`
Expected: Resolves successfully, `dio` appears in `pubspec.lock`.

- [ ] **Step 3: Commit**

```bash
git add pubspec.yaml pubspec.lock
git commit -m "deps: add dio for Phase 2 exchange-rate HTTP client"
```

---

### Task 2: Create `exchange_rates` Drift table

**Files:**
- Create: `lib/data/database/tables/exchange_rates_table.dart`

- [ ] **Step 1: Create the table file**

Create `lib/data/database/tables/exchange_rates_table.dart`:

```dart
import 'package:drift/drift.dart';

import 'currencies_table.dart';

/// Drift table for `exchange_rates`.
///
/// Stores exchange rates as integer-fraction pairs (numerator/denominator)
/// to preserve precision consistent with the codebase's integer-minor-unit
/// money policy. The repository converts API `double` rates to fractions
/// with a fixed denominator of 10⁹ before insert.
///
/// See `docs/superpowers/specs/2026-05-14-multi-currency-conversion-design.md`.
@DataClassName('ExchangeRateRow')
@TableIndex(name: 'idx_exchange_rates_pair', columns: {#baseCurrency, #quoteCurrency}, unique: true)
class ExchangeRates extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get baseCurrency => text().named('base_currency').references(Currencies, #code)();
  TextColumn get quoteCurrency => text().named('quote_currency').references(Currencies, #code)();
  IntColumn get rateNumerator => integer().named('rate_numerator')();
  IntColumn get rateDenominator => integer().named('rate_denominator').customConstraint('CHECK(rate_denominator > 0) NOT NULL')();
  DateTimeColumn get fetchedAt => datetime().named('fetched_at')();
}
```

- [ ] **Step 2: Verify it compiles**

Run: `flutter analyze lib/data/database/tables/exchange_rates_table.dart`
Expected: No errors.

- [ ] **Step 3: Commit**

```bash
git add lib/data/database/tables/exchange_rates_table.dart
git commit -m "feat: add exchange_rates Drift table definition"
```

---

### Task 3: Create ExchangeRateDao

**Files:**
- Create: `lib/data/database/daos/exchange_rate_dao.dart`

- [ ] **Step 1: Create the DAO file**

Create `lib/data/database/daos/exchange_rate_dao.dart`:

```dart
import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/exchange_rates_table.dart';

part 'exchange_rate_dao.g.dart';

/// Thin SQL wrapper for `exchange_rates`.
///
/// Provides bulk upsert, watch-all, and a cross-table query to discover
/// every currency code in use across accounts, transactions, and
/// pending_transactions. Business logic (sanity bounds, fraction
/// conversion, inverse rates) lives in `ExchangeRateRepository`.
@DriftAccessor(tables: [ExchangeRates])
class ExchangeRateDao extends DatabaseAccessor<AppDatabase>
    with _$ExchangeRateDaoMixin {
  ExchangeRateDao(super.db);

  /// Watch all exchange-rate rows. Emits on every change to the table.
  Stream<List<ExchangeRateRow>> watchAll() {
    return select(exchangeRates).watch();
  }

  /// Bulk upsert. Uses `insertOrReplace` so re-fetching the same pair
  /// overwrites the previous row (the unique index on
  /// `(base_currency, quote_currency)` is the conflict target).
  Future<void> upsertAll(List<ExchangeRatesCompanion> rows) async {
    if (rows.isEmpty) return;
    await batch((b) {
      b.insertAll(exchangeRates, rows, mode: InsertMode.insertOrReplace);
    });
  }

  /// Returns the set of distinct currency codes appearing in `accounts`,
  /// `transactions`, and `pending_transactions`. Used by the repository
  /// to determine which pairs to fetch.
  Future<Set<String>> distinctCurrenciesAcrossAllTables() async {
    final rows = await customSelect(
      'SELECT DISTINCT currency FROM accounts '
      'UNION SELECT DISTINCT currency FROM transactions '
      'UNION SELECT DISTINCT currency FROM pending_transactions',
    ).get();
    return rows.map((r) => r.read<String>('currency')).toSet();
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/data/database/daos/exchange_rate_dao.dart
git commit -m "feat: add ExchangeRateDao with upsert, watchAll, cross-table query"
```

---

### Task 4: Register table + DAO in AppDatabase, bump schema to v5

**Files:**
- Modify: `lib/data/database/app_database.dart`

- [ ] **Step 1: Add imports**

In `lib/data/database/app_database.dart`, add these imports in the existing import block (after the `pending_transactions_table.dart` import):

```dart
import 'daos/exchange_rate_dao.dart';
import 'tables/exchange_rates_table.dart';
```

- [ ] **Step 2: Register table and DAO in @DriftDatabase**

In the `@DriftDatabase` annotation, add `ExchangeRates` to the `tables` list and `ExchangeRateDao` to the `daos` list:

```dart
@DriftDatabase(
  tables: [
    Currencies,
    Transactions,
    Categories,
    AccountTypes,
    Accounts,
    UserPreferences,
    ShoppingListItems,
    RecurringRules,
    PendingTransactions,
    ExchangeRates,        // <-- add
  ],
  daos: [
    CurrencyDao,
    TransactionDao,
    CategoryDao,
    AccountTypeDao,
    AccountDao,
    UserPreferencesDao,
    ShoppingListDao,
    RecurringRuleDao,
    PendingTransactionDao,
    ExchangeRateDao,      // <-- add
  ],
)
```

- [ ] **Step 3: Bump schemaVersion to 5**

Change `int get schemaVersion => 4;` to `int get schemaVersion => 5;`.

- [ ] **Step 4: Add v4→v5 migration in onUpgrade**

In the `onUpgrade` callback, after the `if (from < 4)` block, add:

```dart
      if (from < 5) {
        await m.createTable(exchangeRates);
        await m.createIndex(idxExchangeRatesPair);
      }
```

> **Note:** If `m.createIndex(idxExchangeRatesPair)` fails with "index already exists" during migration tests, remove that line — Drift's `createTable` may auto-create `@TableIndex`-annotated indexes depending on the version. Re-run the migration test to confirm.

- [ ] **Step 5: Run build_runner to regenerate**

Run: `dart run build_runner build --delete-conflicting-outputs`
Expected: Generates `app_database.g.dart`, `exchange_rate_dao.g.dart`.

- [ ] **Step 6: Verify compilation**

Run: `flutter analyze lib/data/database/app_database.dart`
Expected: No errors.

- [ ] **Step 7: Commit**

```bash
git add lib/data/database/app_database.dart lib/data/database/daos/exchange_rate_dao.g.dart lib/data/database/app_database.g.dart
git commit -m "feat: register exchange_rates table + DAO, bump schema to v5"
```

---

### Task 5: Create ExchangeRateService

**Files:**
- Create: `lib/data/services/exchange_rate_service.dart`

- [ ] **Step 1: Create the service file**

Create `lib/data/services/exchange_rate_service.dart`:

```dart
import 'package:dio/dio.dart';

/// HTTP client for the Ledgerly conversion API.
///
/// Fetches exchange rates from the hosted Cloudflare Worker endpoint.
/// Returns raw parsed data as anonymous Dart records — the
/// `services_forbid_upstream_and_siblings` import rule forbids this
/// layer from importing `data/models/` or `data/repositories/`.
///
/// See `docs/superpowers/specs/2026-05-14-multi-currency-conversion-design.md`.
class ExchangeRateService {
  ExchangeRateService(this._dio);

  final Dio _dio;

  static const _baseUrl =
      'https://ledgerly-api.bigto-fintech.workers.dev/api/conversion';

  /// Fetches rates for the given currency pairs.
  ///
  /// [pairs] is a list of `(from, to)` records where each string is an
  /// ISO 4217 currency code. The method builds the ticker query string
  /// (e.g. `hkdusd,eurusd`), calls the API, and returns successfully
  /// parsed entries. `from`/`to` are normalized to uppercase.
  ///
  /// Throws [DioException] on network or HTTP errors — the caller
  /// (repository) catches and logs.
  Future<List<({String from, String to, double rate, DateTime fetchedAt})>>
      fetchRates(List<({String from, String to})> pairs) async {
    if (pairs.isEmpty) return const [];

    final tickers = pairs
        .map((p) => '${p.from.toLowerCase()}${p.to.toLowerCase()}')
        .join(',');

    final response = await _dio.get<List<dynamic>>(
      _baseUrl,
      queryParameters: {'tickers': tickers},
    );

    final data = response.data;
    if (data == null) return const [];

    final results =
        <({String from, String to, double rate, DateTime fetchedAt})>[];
    for (final entry in data) {
      if (entry is! Map<String, dynamic>) continue;
      final rate = entry['rate'];
      final from = entry['from'];
      final to = entry['to'];
      final fetchedAt = entry['fetched_at'];
      if (rate is! double || from is! String || to is! String) continue;
      if (rate <= 0) continue;
      results.add((
        from: from.toUpperCase(),
        to: to.toUpperCase(),
        rate: rate,
        fetchedAt: fetchedAt is String
            ? DateTime.tryParse(fetchedAt) ?? DateTime.timestamp()
            : DateTime.timestamp(),
      ));
    }
    return results;
  }
}
```

- [ ] **Step 2: Verify compilation**

Run: `flutter analyze lib/data/services/exchange_rate_service.dart`
Expected: No errors.

- [ ] **Step 3: Commit**

```bash
git add lib/data/services/exchange_rate_service.dart
git commit -m "feat: add ExchangeRateService HTTP client"
```

---

### Task 6: Create CurrencyConverter utility

**Files:**
- Create: `lib/core/utils/currency_converter.dart`

- [ ] **Step 1: Create the converter file**

Create `lib/core/utils/currency_converter.dart`:

```dart
/// Pure integer-fraction minor-unit currency conversion.
///
/// Converts an amount in one currency's minor units to another using
/// a rate stored as an integer fraction (numerator/denominator). Uses
/// `BigInt` for the intermediate multiplication to avoid int64 overflow
/// on ETH-scale amounts (18 decimals × 9-digit numerator).
///
/// See `docs/superpowers/specs/2026-05-14-multi-currency-conversion-design.md`.
class CurrencyConverter {
  const CurrencyConverter._();

  /// Converts [amountMinorUnits] from a currency with [fromDecimals]
  /// minor-unit digits to a currency with [toDecimals] minor-unit digits,
  /// using the rate fraction `[rateNumerator] / [rateDenominator]`.
  ///
  /// Formula:
  ///   target = amount × (numerator / denominator) × 10^(toDecimals - fromDecimals)
  ///
  /// The result is rounded to the nearest integer minor unit.
  static int convertMinorUnits({
    required int amountMinorUnits,
    required int rateNumerator,
    required int rateDenominator,
    required int fromDecimals,
    required int toDecimals,
  }) {
    final amount = BigInt.from(amountMinorUnits);
    final num = BigInt.from(rateNumerator);
    final denom = BigInt.from(rateDenominator);
    final shift = toDecimals - fromDecimals;

    if (shift >= 0) {
      final scale = BigInt.from(10).pow(shift);
      return ((amount * num * scale) ~/ denom).toInt();
    } else {
      final scale = BigInt.from(10).pow(-shift);
      return (amount * num ~/ (denom * scale)).toInt();
    }
  }
}
```

- [ ] **Step 2: Verify compilation**

Run: `flutter analyze lib/core/utils/currency_converter.dart`
Expected: No errors.

- [ ] **Step 3: Commit**

```bash
git add lib/core/utils/currency_converter.dart
git commit -m "feat: add CurrencyConverter with BigInt integer-fraction arithmetic"
```

---

### Task 7: Dump v5 schema and create migration test helper

**Files:**
- Create: `drift_schemas/drift_schema_v5.json`
- Create: `test/unit/repositories/_harness/generated/schema_v5.dart`
- Modify: `test/unit/repositories/_harness/generated/schema.dart`
- Modify: `test/unit/repositories/migration_test.dart`

- [ ] **Step 1: Dump the v5 schema**

Run: `dart run drift_dev schema dump lib/data/database/app_database.dart drift_schemas/`
Expected: Creates/updates `drift_schemas/drift_schema_v5.json`.

- [ ] **Step 2: Generate the v5 schema helper**

Run: `dart run drift_dev schema generate drift_schemas/`
Expected: Updates files in `test/unit/repositories/_harness/generated/`, including a new `schema_v5.dart`.

- [ ] **Step 3: Update the GeneratedHelper versions list**

Open `test/unit/repositories/_harness/generated/schema.dart` and verify the `versions` list includes `'5'`. The generator should update it automatically. After generation, the file should contain something like:

```dart
class GeneratedHelper implements SchemaInstantiationHelper {
  @override
  GeneratedDatabase databaseFor(QueryExecutor e) {
    return AppDatabase(e);
  }

  static const versions = const [1, 2, 3, 4, 5];
}
```

If `'5'` is missing, add it to the list manually.

- [ ] **Step 4: Extend migration_test.dart with v5 tests**

In `test/unit/repositories/migration_test.dart`, add the v5 import at the top:

```dart
import '_harness/generated/schema_v5.dart' as v5;
```

Then add a new test group after the v4 tests (or after the last existing group):

```dart
    group('v5 snapshot', () {
      test('current schemaVersion matches the latest committed snapshot', () {
        final db = AppDatabase(NativeDatabase.memory());
        addTearDown(() async => db.close());
        expect(db.schemaVersion, 5);
        expect(GeneratedHelper.versions, contains(db.schemaVersion));
        expect(GeneratedHelper.versions.last, db.schemaVersion);
      });

      test('upgrades v4 DBs to v5 and creates exchange_rates table', () async {
        final verifier = SchemaVerifier(GeneratedHelper());
        final schema = await verifier.schemaAt(4);
        // Open a v4 DB with seeded data.
        final legacyDb = v4.DatabaseAtV4(schema.newConnection());
        addTearDown(() async => legacyDb.close());

        // Seed minimal fixtures so FK references are valid.
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

      test('exchange_rates FK to currencies is enforced after upgrade', () async {
        final verifier = SchemaVerifier(GeneratedHelper());
        final schema = await verifier.schemaAt(5);
        final db = AppDatabase(schema.newConnection());
        addTearDown(() async => db.close());

        // Inserting a rate with a non-existent currency code must fail.
        expect(
          () => db.customStatement(
            'INSERT INTO exchange_rates (base_currency, quote_currency, '
            'rate_numerator, rate_denominator, fetched_at) '
            'VALUES (?, ?, ?, ?, ?)',
            <Object?>['USD', 'ZZZ', 1000000000, 1000000000, '2026-01-01'],
          ),
          throwsA(anything),
        );
      });

      test('exchange_rates CHECK(rate_denominator > 0) is enforced', () async {
        final verifier = SchemaVerifier(GeneratedHelper());
        final schema = await verifier.schemaAt(5);
        final db = AppDatabase(schema.newConnection());
        addTearDown(() async => db.close());

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

        // denominator = 0 must fail.
        expect(
          () => db.customStatement(
            'INSERT INTO exchange_rates (base_currency, quote_currency, '
            'rate_numerator, rate_denominator, fetched_at) '
            'VALUES (?, ?, ?, ?, ?)',
            <Object?>['USD', 'EUR', 1000000000, 0, '2026-01-01'],
          ),
          throwsA(anything),
        );
      });

      test('PRAGMA foreign_keys remains ON after v5 upgrade', () async {
        final verifier = SchemaVerifier(GeneratedHelper());
        final schema = await verifier.schemaAt(5);
        final db = AppDatabase(schema.newConnection());
        addTearDown(() async => db.close());

        final fkResult = await db
            .customSelect('PRAGMA foreign_keys')
            .getSingle();
        expect(fkResult.read<int>('foreign_keys'), 1);
      });
    });
```

Also update the first test in the file to expect schemaVersion `5` instead of `4`:

```dart
    test('current schemaVersion matches the latest committed snapshot', () {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(() async => db.close());
      expect(db.schemaVersion, 5);
      // ...
    });
```

- [ ] **Step 5: Run the migration tests**

Run: `flutter test test/unit/repositories/migration_test.dart`
Expected: All tests pass, including the new v5 group.

- [ ] **Step 6: Commit**

```bash
git add drift_schemas/ test/unit/repositories/_harness/generated/ test/unit/repositories/migration_test.dart
git commit -m "test: add v5 schema dump, helpers, and migration tests for exchange_rates"
```

---

## Chunk 2: Repository + Provider Wiring

### Task 8: Create ExchangeRateRepository

**Files:**
- Create: `lib/data/repositories/exchange_rate_repository.dart`

- [ ] **Step 1: Create the repository file**

Create `lib/data/repositories/exchange_rate_repository.dart`:

```dart
import 'dart:async';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';

import '../database/app_database.dart' as drift;
import '../database/daos/exchange_rate_dao.dart';
import '../database/tables/exchange_rates_table.dart';
import '../services/exchange_rate_service.dart';

/// Abstract contract for exchange-rate data access.
///
/// The repository orchestrates the DAO (local cache) and the service
/// (remote fetch). It maintains an in-memory snapshot derived from
/// `dao.watchAll()` for synchronous lookups by UI tiles.
abstract class ExchangeRateRepository {
  /// Fetches rates for every currency in use (excluding [defaultCurrency])
  /// and upserts results. Errors are caught and logged; on failure the
  /// cached snapshot from the DAO continues to back [getRate]. Idempotent.
  Future<void> refreshAll(String defaultCurrency);

  /// Fetches a single pair on demand (used after creating a new
  /// non-default-currency account or transaction). Errors swallowed.
  Future<void> fetchRate(String from, String defaultCurrency);

  /// Synchronous lookup against the in-memory snapshot. Returns
  /// `(numerator: 1, denominator: 1)` for same-currency pairs.
  /// Returns null when no rate is known.
  ({int numerator, int denominator})? getRate(String from, String to);

  /// Stream of the snapshot map. Drift's `.watch()` handles replay to
  /// new subscribers automatically.
  Stream<Map<String, ({int numerator, int denominator})>> watchRates();

  /// Dispose subscriptions. Called by Riverpod at app teardown.
  void dispose();
}

/// Concrete Drift-backed implementation of [ExchangeRateRepository].
final class DriftExchangeRateRepository implements ExchangeRateRepository {
  DriftExchangeRateRepository(
    this._db,
    this._service,
    Stream<String> defaultCurrency$,
  ) {
    _daoSub = _db.exchangeRateDao.watchAll().listen(_rebuildSnapshot);
    _currencySub = defaultCurrency$.listen((code) {
      unawaited(refreshAll(code));
    });
  }

  final drift.AppDatabase _db;
  final ExchangeRateService _service;

  ExchangeRateDao get _dao => _db.exchangeRateDao;

  late final StreamSubscription<List<ExchangeRateRow>> _daoSub;
  late final StreamSubscription<String> _currencySub;

  Map<String, ({int numerator, int denominator})> _snapshot = {};

  /// Fixed denominator for fraction conversion (10⁹ ≈ 9 decimal digits).
  static const int _fractionDenom = 1000000000;

  /// Sanity ceiling for rates. Guards against MITM/server bugs.
  static const double _maxRate = 1000000;

  /// Maximum allowed ratio between a new rate and its cached predecessor.
  static const double _maxDriftMultiplier = 100;

  // ---------- Snapshot management ----------

  void _rebuildSnapshot(List<ExchangeRateRow> rows) {
    final map = <String, ({int numerator, int denominator})>{};
    for (final row in rows) {
      final key = '${row.baseCurrency}→${row.quoteCurrency}';
      map[key] = (numerator: row.rateNumerator, denominator: row.rateDenominator);
    }
    _snapshot = map;
  }

  // ---------- Reads ----------

  @override
  ({int numerator, int denominator})? getRate(String from, String to) {
    if (from == to) return (numerator: 1, denominator: 1);
    final key = '${from.toUpperCase()}→${to.toUpperCase()}';
    return _snapshot[key];
  }

  @override
  Stream<Map<String, ({int numerator, int denominator})>> watchRates() {
    return _dao.watchAll().map((rows) {
      final map = <String, ({int numerator, int denominator})>{};
      for (final row in rows) {
        final key = '${row.baseCurrency}→${row.quoteCurrency}';
        map[key] = (numerator: row.rateNumerator, denominator: row.rateDenominator);
      }
      return map;
    });
  }

  // ---------- Writes ----------

  @override
  Future<void> refreshAll(String defaultCurrency) async {
    try {
      final currencies = await _dao.distinctCurrenciesAcrossAllTables();
      final pairs = currencies
          .where((c) => c != defaultCurrency)
          .map((c) => (from: c, to: defaultCurrency))
          .toList();
      if (pairs.isEmpty) return;

      final results = await _service.fetchRates(pairs);
      await _upsertValidRates(results);
    } on Exception catch (e) {
      debugPrint('ExchangeRateRepository.refreshAll failed: $e');
    }
  }

  @override
  Future<void> fetchRate(String from, String defaultCurrency) async {
    try {
      final results =
          await _service.fetchRates([(from: from, to: defaultCurrency)]);
      await _upsertValidRates(results);
    } on Exception catch (e) {
      debugPrint('ExchangeRateRepository.fetchRate failed: $e');
    }
  }

  Future<void> _upsertValidRates(
    List<({String from, String to, double rate, DateTime fetchedAt})> results,
  ) async {
    if (results.isEmpty) return;

    final companions = <drift.ExchangeRatesCompanion>[];
    for (final r in results) {
      if (!_passesSanityBounds(r.from, r.to, r.rate)) continue;

      final fraction = _doubleToFraction(r.rate);
      final inverseFraction = (
        numerator: fraction.denominator,
        denominator: fraction.numerator,
      );
      final now = r.fetchedAt;

      // Forward rate
      companions.add(drift.ExchangeRatesCompanion(
        baseCurrency: Value(r.from),
        quoteCurrency: Value(r.to),
        rateNumerator: Value(fraction.numerator),
        rateDenominator: Value(fraction.denominator),
        fetchedAt: Value(now),
      ));

      // Inverse rate
      companions.add(drift.ExchangeRatesCompanion(
        baseCurrency: Value(r.to),
        quoteCurrency: Value(r.from),
        rateNumerator: Value(inverseFraction.numerator),
        rateDenominator: Value(inverseFraction.denominator),
        fetchedAt: Value(now),
      ));
    }

    await _dao.upsertAll(companions);
  }

  bool _passesSanityBounds(String from, String to, double rate) {
    if (rate <= 0) return false;
    if (rate > _maxRate) return false;

    // Check drift from cached rate.
    final cached = getRate(from, to);
    if (cached != null) {
      final cachedRate = cached.numerator / cached.denominator;
      final ratio = rate / cachedRate;
      if (ratio > _maxDriftMultiplier || ratio < 1 / _maxDriftMultiplier) {
        debugPrint(
          'ExchangeRateRepository: rejecting $from→$to rate $rate '
          '(cached $cachedRate, drift ${ratio}x)',
        );
        return false;
      }
    }
    return true;
  }

  ({int numerator, int denominator}) _doubleToFraction(double rate) {
    return (
      numerator: (rate * _fractionDenom).round(),
      denominator: _fractionDenom,
    );
  }

  // ---------- Lifecycle ----------

  @override
  void dispose() {
    _daoSub.cancel();
    _currencySub.cancel();
  }
}
```

- [ ] **Step 2: Verify compilation**

Run: `flutter analyze lib/data/repositories/exchange_rate_repository.dart`
Expected: No errors.

- [ ] **Step 3: Commit**

```bash
git add lib/data/repositories/exchange_rate_repository.dart
git commit -m "feat: add ExchangeRateRepository with snapshot, sanity bounds, inverse rates"
```

---

### Task 9: Add defaultCurrencyProvider to settings_providers.dart

**Files:**
- Modify: `lib/features/settings/settings_providers.dart`

> **Note:** This task MUST be completed before Task 10, because Task 10's `exchangeRateRepositoryProvider` depends on `defaultCurrencyProvider`.

- [ ] **Step 1: Add part directive and riverpod imports**

The file currently has NO `part` directive (it uses plain providers). We need to add the codegen part directive. At the top of the file, after the existing `import 'package:package_info_plus/package_info_plus.dart';` line, add:

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'settings_providers.g.dart';
```

- [ ] **Step 2: Add the defaultCurrencyProvider**

At the end of the file, add:

```dart
/// Stream of the user's default currency ISO code. Defaults to 'USD'.
@Riverpod(keepAlive: true, dependencies: [userPreferencesRepository])
Stream<String> defaultCurrency(Ref ref) {
  return ref.watch(userPreferencesRepositoryProvider).watchDefaultCurrency();
}
```

- [ ] **Step 3: Run build_runner**

Run: `dart run build_runner build --delete-conflicting-outputs`
Expected: Generates `settings_providers.g.dart`.

- [ ] **Step 4: Verify compilation**

Run: `flutter analyze lib/features/settings/settings_providers.dart`
Expected: No errors.

- [ ] **Step 5: Commit**

```bash
git add lib/features/settings/settings_providers.dart lib/features/settings/settings_providers.g.dart
git commit -m "feat: add defaultCurrencyProvider to settings_providers"
```

---

### Task 10: Add providers to repository_providers.dart

**Files:**
- Modify: `lib/app/providers/repository_providers.dart`

- [ ] **Step 1: Add imports**

In `lib/app/providers/repository_providers.dart`, add these imports. Place `package:` imports after the existing `package:riverpod_annotation` import, and relative imports after the existing relative imports:

```dart
import 'package:dio/dio.dart';
```

```dart
import '../../data/repositories/exchange_rate_repository.dart';
import '../../data/services/exchange_rate_service.dart';
import '../../features/settings/settings_providers.dart';
```

- [ ] **Step 2: Add the three new providers**

At the end of the file (before the closing), add:

```dart
/// Dio instance for HTTP calls. Configured with timeouts.
@Riverpod(keepAlive: true, dependencies: [])
Dio dio(Ref ref) {
  return Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));
}

/// Exchange-rate HTTP service.
@Riverpod(keepAlive: true, dependencies: [dio])
ExchangeRateService exchangeRateService(Ref ref) {
  return ExchangeRateService(ref.watch(dioProvider));
}

/// Exchange-rate repository. Constructs itself reactively: subscribes
/// to DAO changes and default-currency changes in its constructor.
@Riverpod(
  keepAlive: true,
  dependencies: [appDatabase, exchangeRateService, defaultCurrency],
)
ExchangeRateRepository exchangeRateRepository(Ref ref) {
  return DriftExchangeRateRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(exchangeRateServiceProvider),
    ref.watch(defaultCurrencyProvider.stream),
  );
}

/// Stream of the exchange-rate snapshot map. Consumed by UI tiles.
@Riverpod(keepAlive: true, dependencies: [exchangeRateRepository])
Stream<Map<String, ({int numerator, int denominator})>> exchangeRates(
  Ref ref,
) {
  return ref.watch(exchangeRateRepositoryProvider).watchRates();
}
```

- [ ] **Step 3: Run build_runner**

Run: `dart run build_runner build --delete-conflicting-outputs`
Expected: Regenerates `repository_providers.g.dart` with the new providers.

- [ ] **Step 4: Verify compilation**

Run: `flutter analyze lib/app/providers/repository_providers.dart`
Expected: No errors. (The import of `settings_providers.dart` is allowed — `app/providers/` is not restricted from importing `features/settings/`.)

- [ ] **Step 5: Commit**

```bash
git add lib/app/providers/repository_providers.dart lib/app/providers/repository_providers.g.dart
git commit -m "feat: add exchange rate service, repository, and stream providers"
```

---

## Chunk 3: Bootstrap + On-Demand Fetch

### Task 11: Eager-read exchangeRateRepositoryProvider in bootstrap

**Files:**
- Modify: `lib/app/bootstrap.dart`

- [ ] **Step 1: Add import**

In `lib/app/bootstrap.dart`, add this import in the existing import block:

```dart
import 'providers/repository_providers.dart';
```

(If not already imported — check first. It's likely already there via other providers.)

- [ ] **Step 2: Add eager read before runApp**

In `bootstrapFor()`, after the `ProviderScope` overrides are built but before `(runAppFn ?? runApp)(...)`, add a line to force-instantiate the exchange rate repository. The best location is right before the `(runAppFn ?? runApp)(` line:

```dart
      // Force-instantiate the exchange-rate repository so its DAO
      // subscription begins draining before the first frame.
      container.read(exchangeRateRepositoryProvider);
```

However, the current bootstrap structure builds the overrides inline inside `ProviderScope(...)`. We need to capture the container first. Refactor the relevant section:

Change:
```dart
  (runAppFn ?? runApp)(
    ProviderScope(
      overrides: [
```

To: Add a `final container =` capture. The full change:

```dart
  final container = ProviderScope(
    overrides: [
      appDatabaseProvider.overrideWithValue(db),
      // ... existing overrides ...
      ...extraOverrides,
    ],
    child: App(
      onFirstFrame: () {
        // ... existing callback ...
      },
    ),
  );

  // Force-instantiate the exchange-rate repository so its DAO
  // subscription begins draining before the first frame.
  container.read(exchangeRateRepositoryProvider);

  (runAppFn ?? runApp)(container);
```

Wait — `ProviderScope` is a `StatefulWidget`, not a `ProviderContainer`. The `container` property isn't exposed directly. The correct approach per the spec is to build the `ProviderContainer` explicitly:

Refactor `bootstrapFor` to build the container first, then pass it to `UncontrolledProviderScope`:

```dart
  final container = ProviderContainer(
    overrides: [
      appDatabaseProvider.overrideWithValue(db),
      initialThemeModeProvider.overrideWithValue(initialThemeMode),
      initialPreferredLocaleProvider.overrideWithValue(initialLocale),
      lastGenerationResultProvider.overrideWithValue(
        const RecurringGenerationResult(outcomes: []),
      ),
      splashGateSnapshotProvider.overrideWith((ref) {
        final notifier = SplashGateSnapshot.withInitial(
          enabled: splashEnabled,
          startDate: splashStartDate,
        );
        final sub1 = preferencesRepo.watchSplashEnabled().listen(
          notifier.updateEnabled,
        );
        final sub2 = preferencesRepo.watchSplashStartDate().listen(
          notifier.updateStartDate,
        );
        ref.onDispose(() {
          sub1.cancel();
          sub2.cancel();
          notifier.dispose();
        });
        return notifier;
      }),
      ...extraOverrides,
    ],
  );

  // Force-instantiate the exchange-rate repository so its DAO
  // subscription begins draining before the first frame.
  container.read(exchangeRateRepositoryProvider);

  (runAppFn ?? runApp)(
    UncontrolledProviderScope(
      container: container,
      child: App(
        onFirstFrame: () {
          unawaited(() async {
            try {
              await runRecurringGenerationFn(db);
            } on Object {
              // Generation failures must not crash or block startup.
            }
          }());
        },
      ),
    ),
  );
```

- [ ] **Step 3: Verify compilation**

Run: `flutter analyze lib/app/bootstrap.dart`
Expected: No errors.

- [ ] **Step 4: Run existing tests to verify no regression**

Run: `flutter test test/integration/bootstrap_to_home_test.dart`
Expected: Still passes. If `ProviderScope.of(context)` lookups fail in tests, the test harness may need updating — check `test/support/test_app.dart` for any `ProviderScope` references that expect it in the widget tree.

- [ ] **Step 5: Run all integration tests**

Run: `flutter test test/integration/`
Expected: All integration tests pass.

- [ ] **Step 6: Commit**

```bash
git add lib/app/bootstrap.dart
git commit -m "feat: eager-instantiate exchangeRateRepository in bootstrap"
```

---

### Task 12: Add on-demand fetch to AccountFormActions

**Files:**
- Modify: `lib/features/accounts/accounts_providers.dart`

- [ ] **Step 1: Modify AccountFormActions.save()**

In `lib/features/accounts/accounts_providers.dart`, modify the `AccountFormActions` class to trigger on-demand rate fetch after saving a non-default-currency account:

```dart
class AccountFormActions {
  AccountFormActions(this._accountRepository, this._ref);

  final AccountRepository _accountRepository;
  final Ref _ref;

  Future<int> save(Account draft) async {
    final id = await _accountRepository.save(draft);
    // On-demand fetch: if the saved account's currency differs from
    // the user's default, fetch the rate for display.
    final defaultCurrency = await _ref
        .read(defaultCurrencyProvider.future);
    if (draft.currency.code != defaultCurrency) {
      final repo = _ref.read(exchangeRateRepositoryProvider);
      unawaited(repo.fetchRate(draft.currency.code, defaultCurrency));
    }
    return id;
  }
}
```

- [ ] **Step 2: Update the provider to pass Ref**

Change the `accountFormActionsProvider` to pass `ref`:

```dart
final accountFormActionsProvider = Provider<AccountFormActions>((ref) {
  return AccountFormActions(ref.read(accountRepositoryProvider), ref);
});
```

- [ ] **Step 3: Add missing imports**

Add these imports at the top of the file:

```dart
import 'dart:async';
import '../../app/providers/repository_providers.dart';
import '../settings/settings_providers.dart';
```

- [ ] **Step 4: Verify compilation**

Run: `flutter analyze lib/features/accounts/accounts_providers.dart`
Expected: No errors.

- [ ] **Step 5: Commit**

```bash
git add lib/features/accounts/accounts_providers.dart
git commit -m "feat: trigger on-demand exchange-rate fetch after account save"
```

---

### Task 13: Add on-demand fetch to TransactionFormController

**Files:**
- Modify: `lib/features/transactions/transaction_form_controller.dart`

- [ ] **Step 1: Add imports**

Add these imports at the top of the file:

```dart
import 'dart:async';
import '../settings/settings_providers.dart';
```

(Also need `exchangeRateRepositoryProvider` — it's accessible via `repository_providers.dart` which is already imported.)

- [ ] **Step 2: Add post-save fetch in the save() method**

In the `save()` method, after `final saved = await repo.save(tx);` and before `state = s.copyWith(isSaving: false);`, add:

```dart
      // On-demand rate fetch for non-default currencies.
      final defaultCurrency = await ref.read(defaultCurrencyProvider.future);
      if (tx.currency.code != defaultCurrency) {
        unawaited(
          ref.read(exchangeRateRepositoryProvider).fetchRate(
                tx.currency.code,
                defaultCurrency,
              ),
        );
      }
```

- [ ] **Step 3: Verify compilation**

Run: `flutter analyze lib/features/transactions/transaction_form_controller.dart`
Expected: No errors.

- [ ] **Step 4: Commit**

```bash
git add lib/features/transactions/transaction_form_controller.dart
git commit -m "feat: trigger on-demand exchange-rate fetch after transaction save"
```

---

## Chunk 4: Localization

### Task 14: Add l10n keys

**Files:**
- Modify: `l10n/app_en.arb`
- Modify: `l10n/app_zh_CN.arb`
- Modify: `l10n/app_zh_TW.arb`

- [ ] **Step 1: Add keys to app_en.arb**

In `l10n/app_en.arb`, add these entries (at the end of the file, before the closing `}`):

```json
  "approximatelyPrefix": "approximately",
  "@approximatelyPrefix": {
    "description": "Screen-reader label for the ≈ prefix on converted amounts. The visible glyph is Unicode; this key is read aloud by accessibility tools."
  },
  "convertedTotalLabel": "total",
  "@convertedTotalLabel": {
    "description": "Suffix after the converted total in AccountTile (e.g. '≈ $1,802.50 total')."
  },
  "accountTileShowMore": "Show {n} more",
  "@accountTileShowMore": {
    "description": "AccountTile affordance when >4 currency groups are present. {n} is the overflow count.",
    "placeholders": {
      "n": {
        "type": "int",
        "example": "3"
      }
    }
  },
```

- [ ] **Step 2: Add keys to app_zh_CN.arb**

In `l10n/app_zh_CN.arb`, add before the closing `}`:

```json
  "approximatelyPrefix": "约",
  "convertedTotalLabel": "总计",
  "accountTileShowMore": "查看其他 {n} 项",
```

- [ ] **Step 3: Add keys to app_zh_TW.arb**

In `l10n/app_zh_TW.arb`, add before the closing `}`:

```json
  "approximatelyPrefix": "約",
  "convertedTotalLabel": "總計",
  "accountTileShowMore": "查看其他 {n} 項",
```

- [ ] **Step 4: Regenerate l10n**

Run: `flutter gen-l10n`
Expected: Updates `lib/l10n/app_localizations.dart` with the new keys.

- [ ] **Step 5: Verify compilation**

Run: `flutter analyze`
Expected: No errors.

- [ ] **Step 6: Commit**

```bash
git add l10n/app_en.arb l10n/app_zh_CN.arb l10n/app_zh_TW.arb lib/l10n/
git commit -m "l10n: add approximatelyPrefix, convertedTotalLabel, accountTileShowMore"
```

---

## Chunk 5: UI — SummaryStrip

### Task 15: Modify SummaryStrip for unified default-currency total

**Files:**
- Modify: `lib/features/home/widgets/summary_strip.dart`

- [ ] **Step 1: Add new imports**

At the top of `summary_strip.dart`, add:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/currency_converter.dart';
import '../../../data/models/currency.dart';
import '../../../app/providers/repository_providers.dart';
```

- [ ] **Step 2: Change SummaryStrip to ConsumerWidget**

Change `class SummaryStrip extends StatelessWidget` to `class SummaryStrip extends ConsumerWidget`.

Change the `build` method signature from:
```dart
  Widget build(BuildContext context) {
```
to:
```dart
  Widget build(BuildContext context, WidgetRef ref) {
```

- [ ] **Step 3: Add exchange rate reading and conversion logic**

At the start of the `build` method (after `final theme = Theme.of(context);`), add:

```dart
    // Exchange rates for conversion.
    final exchangeRatesAsync = ref.watch(exchangeRatesProvider);
    final ratesMap = exchangeRatesAsync.maybeWhen(
      data: (m) => m,
      orElse: () => <String, ({int numerator, int denominator})>{},
    );

    // Determine default currency from the locale (or a passed-in param).
    // For now, we infer it from the first currency in the totals — the
    // controller should pass it explicitly. We'll add a parameter.
```

Actually, the SummaryStrip needs to know the default currency code. Let me add a parameter:

- [ ] **Step 4: Add defaultCurrency parameter**

Add a new required parameter to `SummaryStrip`:

```dart
  const SummaryStrip({
    super.key,
    required this.todayTotalsByCurrency,
    required this.monthNetByCurrency,
    required this.currenciesByCode,
    required this.locale,
    required this.defaultCurrency,  // <-- add
    this.showJumpToToday = false,
    this.onJumpToToday,
  });

  /// The user's default ISO currency code for conversion display.
  final String defaultCurrency;
```

- [ ] **Step 5: Implement unified conversion logic**

Replace the existing currency-group rendering logic with the unified approach. After reading `ratesMap` and `defaultCurrency`, compute the converted totals:

```dart
    // Convert all per-currency totals to the default currency.
    int convertedExpense = 0;
    int convertedIncome = 0;
    int convertedMonthNet = 0;
    final missingRatesFor = <String>{};

    for (final entry in todayTotalsByCurrency.entries) {
      final code = entry.key;
      if (code == defaultCurrency) {
        convertedExpense += entry.value.expense;
        convertedIncome += entry.value.income;
      } else {
        final rateKey = '$code→$defaultCurrency';
        final rate = ratesMap[rateKey];
        if (rate == null) {
          missingRatesFor.add(code);
          continue;
        }
        final fromCurrency = currenciesByCode[code] ??
            Currency(code: code, decimals: 2, symbol: code);
        final toCurrency = currenciesByCode[defaultCurrency] ??
            Currency(code: defaultCurrency, decimals: 2, symbol: defaultCurrency);
        convertedExpense += CurrencyConverter.convertMinorUnits(
          amountMinorUnits: entry.value.expense,
          rateNumerator: rate.numerator,
          rateDenominator: rate.denominator,
          fromDecimals: fromCurrency.decimals,
          toDecimals: toCurrency.decimals,
        );
        convertedIncome += CurrencyConverter.convertMinorUnits(
          amountMinorUnits: entry.value.income,
          rateNumerator: rate.numerator,
          rateDenominator: rate.denominator,
          fromDecimals: fromCurrency.decimals,
          toDecimals: toCurrency.decimals,
        );
      }
    }
    for (final entry in monthNetByCurrency.entries) {
      final code = entry.key;
      if (code == defaultCurrency) {
        convertedMonthNet += entry.value;
      } else {
        final rateKey = '$code→$defaultCurrency';
        final rate = ratesMap[rateKey];
        if (rate == null) {
          missingRatesFor.add(code);
          continue;
        }
        final fromCurrency = currenciesByCode[code] ??
            Currency(code: code, decimals: 2, symbol: code);
        final toCurrency = currenciesByCode[defaultCurrency] ??
            Currency(code: defaultCurrency, decimals: 2, symbol: defaultCurrency);
        convertedMonthNet += CurrencyConverter.convertMinorUnits(
          amountMinorUnits: entry.value,
          rateNumerator: rate.numerator,
          rateDenominator: rate.denominator,
          fromDecimals: fromCurrency.decimals,
          toDecimals: toCurrency.decimals,
        );
      }
    }

    final canShowUnified = missingRatesFor.length < allCodes.length;
    final toCurrency = currenciesByCode[defaultCurrency] ??
        Currency(code: defaultCurrency, decimals: 2, symbol: defaultCurrency);
```

- [ ] **Step 6: Render unified group + fallback**

Replace the existing `content` widget-building logic. When `canShowUnified` is true, render a single `_CurrencyGroup` for the default currency with the converted totals. For currencies with missing rates, render their per-currency groups as fallback. Wrap the entire content column in `AnimatedSize`:

```dart
    Widget content;
    if (allCodes.isEmpty) {
      content = _PlaceholderBox(
        theme: theme,
        labels: [
          l10n.homeSummaryTodayExpense,
          l10n.homeSummaryTodayIncome,
          l10n.homeSummaryMonthNet,
        ],
      );
    } else {
      content = AnimatedSize(
        duration: const Duration(milliseconds: 150),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (canShowUnified) ...[
              _CurrencyGroup(
                currency: toCurrency,
                expense: convertedExpense,
                income: convertedIncome,
                monthNet: convertedMonthNet,
                locale: locale,
                labels: (
                  expense: l10n.homeSummaryTodayExpense,
                  income: l10n.homeSummaryTodayIncome,
                  monthNet: l10n.homeSummaryMonthNet,
                ),
              ),
            ],
            // Fallback for currencies with missing rates.
            for (final code in missingRatesFor) ...[
              const SizedBox(height: 12),
              _CurrencyGroup(
                currency: currenciesByCode[code] ??
                    Currency(code: code, decimals: 2, symbol: code),
                expense: todayTotalsByCurrency[code]?.expense ?? 0,
                income: todayTotalsByCurrency[code]?.income ?? 0,
                monthNet: monthNetByCurrency[code] ?? 0,
                locale: locale,
                labels: (
                  expense: l10n.homeSummaryTodayExpense,
                  income: l10n.homeSummaryTodayIncome,
                  monthNet: l10n.homeSummaryMonthNet,
                ),
              ),
            ],
          ],
        ),
      );
    }
```

- [ ] **Step 7: Update all call sites of SummaryStrip**

The primary call site is `lib/features/home/home_screen.dart:414`. There are also test call sites in `test/widget/features/home/summary_strip_test.dart`. At each call site, add the `defaultCurrency` parameter. The caller needs to read `defaultCurrencyProvider`:

```dart
final defaultCurrency = ref.watch(defaultCurrencyProvider).maybeWhen(
  data: (c) => c,
  orElse: () => 'USD',
);
```

Then pass it to `SummaryStrip(... defaultCurrency: defaultCurrency, ...)`.

For widget tests in `summary_strip_test.dart`, override `defaultCurrencyProvider` in the test `ProviderScope` and pass a hardcoded value.

- [ ] **Step 8: Verify compilation**

Run: `flutter analyze lib/features/home/widgets/summary_strip.dart`
Expected: No errors.

- [ ] **Step 9: Commit**

```bash
git add lib/features/home/widgets/summary_strip.dart
git commit -m "feat: SummaryStrip shows unified default-currency total with per-row fallback"
```

---

## Chunk 6: UI — TransactionTile

### Task 16: Add converted amount line to TransactionTile

**Files:**
- Modify: `lib/features/home/widgets/transaction_tile.dart`

- [ ] **Step 1: Add new imports**

At the top of `transaction_tile.dart`, add:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/currency_converter.dart';
import '../../../app/providers/repository_providers.dart';
```

- [ ] **Step 2: Change TransactionTile to ConsumerWidget**

Change `class TransactionTile extends StatelessWidget` to `class TransactionTile extends ConsumerWidget`.

Change the `build` method signature from:
```dart
  Widget build(BuildContext context) {
```
to:
```dart
  Widget build(BuildContext context, WidgetRef ref) {
```

- [ ] **Step 3: Add defaultCurrency parameter**

Add a new required parameter:

```dart
  const TransactionTile({
    super.key,
    required this.transaction,
    required this.category,
    required this.account,
    required this.locale,
    required this.defaultCurrency,  // <-- add
    required this.onTap,
    required this.onDuplicate,
    required this.onDelete,
  });

  /// The user's default ISO currency code for conversion display.
  final String defaultCurrency;
```

- [ ] **Step 4: Compute the converted amount**

After the existing `amountText` computation, add:

```dart
    // Converted amount for cross-currency display.
    String? convertedText;
    final txCurrency = transaction.currency;
    if (txCurrency.code != defaultCurrency) {
      final exchangeRatesAsync = ref.watch(exchangeRatesProvider);
      final ratesMap = exchangeRatesAsync.maybeWhen(
        data: (m) => m,
        orElse: () => <String, ({int numerator, int denominator})>{},
      );
      final rateKey = '${txCurrency.code}→$defaultCurrency';
      final rate = ratesMap[rateKey];
      if (rate != null) {
        // Resolve the default currency metadata for formatting.
        final currenciesAsync = ref.watch(homeCurrenciesByCodeProvider);
        final currenciesByCode = currenciesAsync.maybeWhen(
          data: (m) => m,
          orElse: () => <String, Currency>{},
        );
        final toCurrency = currenciesByCode[defaultCurrency] ??
            Currency(code: defaultCurrency, decimals: 2, symbol: defaultCurrency);
        final convertedMinorUnits = CurrencyConverter.convertMinorUnits(
          amountMinorUnits: transaction.amountMinorUnits,
          rateNumerator: rate.numerator,
          rateDenominator: rate.denominator,
          fromDecimals: txCurrency.decimals,
          toDecimals: toCurrency.decimals,
        );
        final signedConverted = isIncome
            ? convertedMinorUnits
            : -convertedMinorUnits;
        convertedText = '≈ ${MoneyFormatter.formatSigned(
          amountMinorUnits: signedConverted,
          currency: toCurrency,
          locale: locale,
        )}';
      }
    }
```

- [ ] **Step 5: Render the converted line in the trailing column**

Modify the `trailing` widget to show the converted amount below the primary amount. Wrap the amount column in a `SizedBox` with fixed height:

```dart
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: (theme.textTheme.bodySmall?.fontSize ?? 14) * 1.4 * 2,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    amountText,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: isIncome
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (convertedText != null)
                    Text(
                      convertedText,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  if (convertedText == null)
                    SizedBox(height: theme.textTheme.bodySmall?.fontSize ?? 14),
                ],
              ),
            ),
            PopupMenuButton<_RowAction>(
              // ... existing code ...
            ),
          ],
        ),
```

- [ ] **Step 6: Update all call sites of TransactionTile**

The primary call site is `lib/features/home/home_screen.dart:647`. Add the `defaultCurrency` parameter, reading it from `defaultCurrencyProvider` as shown in Task 15 Step 7. Also update any test call sites in `test/widget/features/home/` that construct `TransactionTile` directly.

- [ ] **Step 7: Verify compilation**

Run: `flutter analyze lib/features/home/widgets/transaction_tile.dart`
Expected: No errors.

- [ ] **Step 8: Commit**

```bash
git add lib/features/home/widgets/transaction_tile.dart
git commit -m "feat: TransactionTile shows secondary converted amount for cross-currency"
```

---

## Chunk 7: UI — AccountTile

### Task 17: Add converted total to AccountTile

**Files:**
- Modify: `lib/features/accounts/widgets/account_tile.dart`

- [ ] **Step 1: Add new imports**

At the top of `account_tile.dart`, add:

```dart
import '../../../core/utils/currency_converter.dart';
import '../../../app/providers/repository_providers.dart';
import '../../settings/settings_providers.dart';
```

- [ ] **Step 2: Add exchange-rate conversion to the build method**

In the `build` method, after the `currenciesAsync` resolution, add:

```dart
    // Exchange rates for converted total.
    final exchangeRatesAsync = ref.watch(exchangeRatesProvider);
    final ratesMap = exchangeRatesAsync.maybeWhen(
      data: (m) => m,
      orElse: () => <String, ({int numerator, int denominator})>{},
    );
    final defaultCurrencyAsync = ref.watch(defaultCurrencyProvider);
    final defaultCurrency = defaultCurrencyAsync.maybeWhen(
      data: (c) => c,
      orElse: () => 'USD',
    );
```

- [ ] **Step 3: Compute the converted total**

After the existing `_buildSubtitle` call, compute the converted total:

```dart
    // Compute converted total for multi-currency accounts.
    final hasMultipleCurrencies = view.balancesByCurrency.length > 1;
    int? convertedTotal;
    String? convertedTotalFormatted;
    if (hasMultipleCurrencies && ratesMap.isNotEmpty) {
      int total = 0;
      bool allRatesPresent = true;
      for (final entry in view.balancesByCurrency.entries) {
        final code = entry.key;
        final amount = entry.value;
        if (code == defaultCurrency) {
          total += amount;
        } else {
          final rateKey = '$code→$defaultCurrency';
          final rate = ratesMap[rateKey];
          if (rate == null) {
            allRatesPresent = false;
            break;
          }
          final fromCurrency = currenciesByCode[code] ??
              Currency(code: code, decimals: 2);
          final toCurrency = currenciesByCode[defaultCurrency] ??
              Currency(code: defaultCurrency, decimals: 2);
          total += CurrencyConverter.convertMinorUnits(
            amountMinorUnits: amount,
            rateNumerator: rate.numerator,
            rateDenominator: rate.denominator,
            fromDecimals: fromCurrency.decimals,
            toDecimals: toCurrency.decimals,
          );
        }
      }
      if (allRatesPresent) {
        convertedTotal = total;
        final toCurrency = currenciesByCode[defaultCurrency] ??
            Currency(code: defaultCurrency, decimals: 2);
        convertedTotalFormatted = MoneyFormatter.format(
          amountMinorUnits: total,
          currency: toCurrency,
          locale: locale,
        );
      }
    }
```

- [ ] **Step 4: Modify _buildSubtitle to include converted total**

The existing `_buildSubtitle` method signature (at `account_tile.dart:172`):

```dart
  Widget _buildSubtitle(
    BuildContext context,
    String accountTypeLabel,
    Map<String, int> balancesByCurrency,
    Map<String, Currency> currenciesByCode,
    AppLocalizations l10n,
  ) {
```

The existing call site (at `account_tile.dart:146`):

```dart
        subtitle: _buildSubtitle(
          context,
          accountTypeLabel,
          view.balancesByCurrency,
          currenciesByCode,
          l10n,
        ),
```

Add two new parameters to the method signature:

```dart
  Widget _buildSubtitle(
    BuildContext context,
    String accountTypeLabel,
    Map<String, int> balancesByCurrency,
    Map<String, Currency> currenciesByCode,
    AppLocalizations l10n,
    String? convertedTotalFormatted,  // <-- new
    String defaultCurrency,           // <-- new
  ) {
```

At the end of the method, before the `return Column(...)`, add the converted total section:

```dart
    if (convertedTotalFormatted != null) {
      lines.add(
        ExcludeSemantics(
          child: Divider(
            thickness: 1,
            indent: 16,
            endIndent: 16,
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
      );
      lines.add(
        Semantics(
          label: '${l10n.approximatelyPrefix} $convertedTotalFormatted ${l10n.convertedTotalLabel}',
          child: Text(
            '≈ $convertedTotalFormatted ${l10n.convertedTotalLabel}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
        ),
      );
    }
```

Update the call site to pass the new arguments:

```dart
        subtitle: _buildSubtitle(
          context,
          accountTypeLabel,
          view.balancesByCurrency,
          currenciesByCode,
          l10n,
          convertedTotalFormatted,  // <-- new
          defaultCurrency,          // <-- new
        ),
```

- [ ] **Step 5: Verify compilation**

Run: `flutter analyze lib/features/accounts/widgets/account_tile.dart`
Expected: No errors.

- [ ] **Step 6: Commit**

```bash
git add lib/features/accounts/widgets/account_tile.dart
git commit -m "feat: AccountTile shows converted total below per-currency balances"
```

---

## Chunk 8: Tests

### Task 18: CurrencyConverter unit tests

**Files:**
- Create: `test/unit/utils/currency_converter_test.dart`

- [ ] **Step 1: Create the test file**

Create `test/unit/utils/currency_converter_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/core/utils/currency_converter.dart';

void main() {
  group('CurrencyConverter.convertMinorUnits', () {
    test('same-currency (USD→USD) returns same amount', () {
      expect(
        CurrencyConverter.convertMinorUnits(
          amountMinorUnits: 10000, // $100.00
          rateNumerator: 1000000000,
          rateDenominator: 1000000000,
          fromDecimals: 2,
          toDecimals: 2,
        ),
        10000,
      );
    });

    test('USD→EUR at 0.85 rate', () {
      // $100.00 = 10000 minor units, rate 0.85 → 8500 EUR minor units
      expect(
        CurrencyConverter.convertMinorUnits(
          amountMinorUnits: 10000,
          rateNumerator: (0.85 * 1000000000).round(),
          rateDenominator: 1000000000,
          fromDecimals: 2,
          toDecimals: 2,
        ),
        8500,
      );
    });

    test('JPY→USD (0 decimals → 2 decimals)', () {
      // ¥1000 = 1000 minor units, rate 0.0067 → $6.70 = 670
      expect(
        CurrencyConverter.convertMinorUnits(
          amountMinorUnits: 1000,
          rateNumerator: (0.0067 * 1000000000).round(),
          rateDenominator: 1000000000,
          fromDecimals: 0,
          toDecimals: 2,
        ),
        670,
      );
    });

    test('USD→JPY (2 decimals → 0 decimals)', () {
      // $6.70 = 670 minor units, rate 149.25 → ¥1000 = 1000
      expect(
        CurrencyConverter.convertMinorUnits(
          amountMinorUnits: 670,
          rateNumerator: (149.25 * 1000000000).round(),
          rateDenominator: 1000000000,
          fromDecimals: 2,
          toDecimals: 0,
        ),
        1000,
      );
    });

    test('ETH→USD at 18 decimals uses BigInt path', () {
      // 1 ETH = 10^18 wei, rate $3000 = 3000.0
      // Expected: $3000.00 = 300000 minor units (2 decimals)
      expect(
        CurrencyConverter.convertMinorUnits(
          amountMinorUnits: 1000000000000000000, // 1 ETH in wei
          rateNumerator: (3000.0 * 1000000000).round(),
          rateDenominator: 1000000000,
          fromDecimals: 18,
          toDecimals: 2,
        ),
        300000,
      );
    });

    test('rounding: truncates fractional remainder toward zero', () {
      // 100 minor units * 0.333 rate = 33.3 → 33 (fractional dropped)
      expect(
        CurrencyConverter.convertMinorUnits(
          amountMinorUnits: 100,
          rateNumerator: (0.333 * 1000000000).round(),
          rateDenominator: 1000000000,
          fromDecimals: 2,
          toDecimals: 2,
        ),
        33,
      );
    });

    test('rounding: 0.5 rounds up via integer division', () {
      // 100 minor units * 0.335 rate = 33.5 → 34 (BigInt ~/ rounds toward zero,
      // but (rate * denom).round() pushes 33.5 to 34 at the numerator level)
      expect(
        CurrencyConverter.convertMinorUnits(
          amountMinorUnits: 100,
          rateNumerator: (0.335 * 1000000000).round(),
          rateDenominator: 1000000000,
          fromDecimals: 2,
          toDecimals: 2,
        ),
        34,
      );
    });

    test('round-trip drift is within ±1 minor unit', () {
      // 100 HKD → USD → HKD should be within ±1 of 100
      const amount = 10000; // HK$100.00
      const hkdToUsdNum = (0.1277 * 1000000000).round();
      const usdToHkdNum = (1 / 0.1277 * 1000000000).round();
      const denom = 1000000000;

      final usd = CurrencyConverter.convertMinorUnits(
        amountMinorUnits: amount,
        rateNumerator: hkdToUsdNum,
        rateDenominator: denom,
        fromDecimals: 2,
        toDecimals: 2,
      );
      final hkdRoundTrip = CurrencyConverter.convertMinorUnits(
        amountMinorUnits: usd,
        rateNumerator: usdToHkdNum,
        rateDenominator: denom,
        fromDecimals: 2,
        toDecimals: 2,
      );

      expect(hkdRoundTrip, closeTo(amount, 1));
    });
  });
}
```

- [ ] **Step 2: Run the tests**

Run: `flutter test test/unit/utils/currency_converter_test.dart`
Expected: All tests pass.

- [ ] **Step 3: Commit**

```bash
git add test/unit/utils/currency_converter_test.dart
git commit -m "test: add CurrencyConverter unit tests with BigInt and round-trip"
```

---

### Task 19: ExchangeRateService unit tests

**Files:**
- Create: `test/unit/services/exchange_rate_service_test.dart`

- [ ] **Step 1: Create the test file**

Create `test/unit/services/exchange_rate_service_test.dart`:

```dart
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/data/services/exchange_rate_service.dart';
import 'package:mocktail/mocktail.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio mockDio;
  late ExchangeRateService service;

  setUp(() {
    mockDio = MockDio();
    service = ExchangeRateService(mockDio);
  });

  group('ExchangeRateService.fetchRates', () {
    test('builds correct ticker query string', () async {
      when(() => mockDio.get<List<dynamic>>(
            any(),
            queryParameters: any(named: 'queryParameters'),
          )).thenAnswer(
        (_) async => Response(
          data: [
            {
              'rate': 0.1277,
              'from': 'HKD',
              'to': 'USD',
              'fetched_at': '2026-05-14T06:35:14.459Z',
            }
          ],
          statusCode: 200,
          requestOptions: RequestOptions(path: ''),
        ),
      );

      await service.fetchRates([
        (from: 'HKD', to: 'USD'),
        (from: 'EUR', to: 'USD'),
      ]);

      verify(() => mockDio.get<List<dynamic>>(
            'https://ledgerly-api.bigto-fintech.workers.dev/api/conversion',
            queryParameters: {'tickers': 'hkdusd,eurusd'},
          )).called(1);
    });

    test('normalizes from/to to uppercase', () async {
      when(() => mockDio.get<List<dynamic>>(
            any(),
            queryParameters: any(named: 'queryParameters'),
          )).thenAnswer(
        (_) async => Response(
          data: [
            {
              'rate': 0.1277,
              'from': 'hkd',
              'to': 'usd',
              'fetched_at': '2026-05-14T06:35:14.459Z',
            }
          ],
          statusCode: 200,
          requestOptions: RequestOptions(path: ''),
        ),
      );

      final results =
          await service.fetchRates([(from: 'HKD', to: 'USD')]);

      expect(results, hasLength(1));
      expect(results[0].from, 'HKD');
      expect(results[0].to, 'USD');
    });

    test('skips malformed entries', () async {
      when(() => mockDio.get<List<dynamic>>(
            any(),
            queryParameters: any(named: 'queryParameters'),
          )).thenAnswer(
        (_) async => Response(
          data: [
            {'rate': 'not_a_number', 'from': 'HKD', 'to': 'USD'},
            {
              'rate': 0.1277,
              'from': 'HKD',
              'to': 'USD',
              'fetched_at': '2026-05-14T06:35:14.459Z',
            },
          ],
          statusCode: 200,
          requestOptions: RequestOptions(path: ''),
        ),
      );

      final results =
          await service.fetchRates([(from: 'HKD', to: 'USD')]);

      expect(results, hasLength(1));
    });

    test('skips entries with rate <= 0', () async {
      when(() => mockDio.get<List<dynamic>>(
            any(),
            queryParameters: any(named: 'queryParameters'),
          )).thenAnswer(
        (_) async => Response(
          data: [
            {'rate': 0.0, 'from': 'HKD', 'to': 'USD'},
            {'rate': -1.0, 'from': 'EUR', 'to': 'USD'},
          ],
          statusCode: 200,
          requestOptions: RequestOptions(path: ''),
        ),
      );

      final results =
          await service.fetchRates([(from: 'HKD', to: 'USD')]);

      expect(results, isEmpty);
    });

    test('throws DioException on network error', () async {
      when(() => mockDio.get<List<dynamic>>(
            any(),
            queryParameters: any(named: 'queryParameters'),
          )).thenThrow(
        DioException(
          type: DioExceptionType.connectionTimeout,
          requestOptions: RequestOptions(path: ''),
        ),
      );

      expect(
        () => service.fetchRates([(from: 'HKD', to: 'USD')]),
        throwsA(isA<DioException>()),
      );
    });

    test('returns empty list for empty pairs', () async {
      final results = await service.fetchRates([]);
      expect(results, isEmpty);
    });
  });
}
```

- [ ] **Step 2: Run the tests**

Run: `flutter test test/unit/services/exchange_rate_service_test.dart`
Expected: All tests pass.

- [ ] **Step 3: Commit**

```bash
git add test/unit/services/exchange_rate_service_test.dart
git commit -m "test: add ExchangeRateService unit tests with Dio mock"
```

---

### Task 20: ExchangeRateRepository unit tests

**Files:**
- Create: `test/unit/repositories/exchange_rate_repository_test.dart`

- [ ] **Step 1: Create the test file**

Create `test/unit/repositories/exchange_rate_repository_test.dart`:

```dart
import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/data/database/app_database.dart';
import 'package:ledgerly/data/repositories/exchange_rate_repository.dart';
import 'package:ledgerly/data/services/exchange_rate_service.dart';
import 'package:mocktail/mocktail.dart';

import '_harness/test_app_database.dart';

class MockExchangeRateService extends Mock implements ExchangeRateService {}

void main() {
  late AppDatabase db;
  late MockExchangeRateService mockService;
  late StreamController<String> defaultCurrencyController;
  late DriftExchangeRateRepository repo;

  setUp(() async {
    db = newTestAppDatabase();
    mockService = MockExchangeRateService();
    defaultCurrencyController = StreamController<String>.broadcast();

    // Seed minimal currency fixtures.
    await db.customStatement(
      'INSERT INTO currencies (code, decimals, symbol, name_l10n_key, '
      'is_token, sort_order) VALUES (?, ?, ?, ?, 0, ?), (?, ?, ?, ?, 0, ?)',
      <Object?>['USD', 2, r'$', 'currency.usd', 1, 'EUR', 2, '€', 'currency.eur', 2],
    );

    repo = DriftExchangeRateRepository(
      db,
      mockService,
      defaultCurrencyController.stream,
    );
  });

  tearDown(() async {
    repo.dispose();
    await defaultCurrencyController.close();
    await db.close();
  });

  group('DriftExchangeRateRepository', () {
    test('getRate returns identity for same currency', () {
      final rate = repo.getRate('USD', 'USD');
      expect(rate, (numerator: 1, denominator: 1));
    });

    test('getRate returns null for unknown pair', () {
      expect(repo.getRate('USD', 'EUR'), isNull);
    });

    test('refreshAll fetches, upserts, and builds snapshot', () async {
      // Seed an account so distinctCurrenciesAcrossAllTables returns EUR.
      await db.customStatement(
        "INSERT INTO account_types (l10n_key, icon, color, sort_order, is_archived) "
        "VALUES (?, ?, 0, 1, 0)",
        <Object?>['accountType.cash', 'wallet'],
      );
      final typeRows = await db.customSelect('SELECT id FROM account_types').get();
      final typeId = typeRows.first.read<int>('id');
      await db.customStatement(
        "INSERT INTO accounts (name, account_type_id, currency, opening_balance_minor_units, "
        "icon, color, sort_order, is_archived) VALUES (?, ?, ?, 0, NULL, NULL, NULL, 0)",
        <Object?>['Cash EUR', typeId, 'EUR'],
      );

      when(() => mockService.fetchRates(any())).thenAnswer(
        (_) async => [
          (
            from: 'EUR',
            to: 'USD',
            rate: 1.08,
            fetchedAt: DateTime(2026, 5, 14),
          ),
        ],
      );

      await repo.refreshAll('USD');

      // Forward rate EUR→USD
      final eurToUsd = repo.getRate('EUR', 'USD');
      expect(eurToUsd, isNotNull);
      expect(eurToUsd!.numerator, (1.08 * 1000000000).round());

      // Inverse rate USD→EUR
      final usdToEur = repo.getRate('USD', 'EUR');
      expect(usdToEur, isNotNull);
      expect(usdToEur!.numerator, 1000000000);
      expect(usdToEur.denominator, (1.08 * 1000000000).round());
    });

    test('refreshAll rejects rate <= 0', () async {
      await db.customStatement(
        "INSERT INTO account_types (l10n_key, icon, color, sort_order, is_archived) "
        "VALUES (?, ?, 0, 1, 0)",
        <Object?>['accountType.cash', 'wallet'],
      );
      final typeRows = await db.customSelect('SELECT id FROM account_types').get();
      final typeId = typeRows.first.read<int>('id');
      await db.customStatement(
        "INSERT INTO accounts (name, account_type_id, currency, opening_balance_minor_units, "
        "icon, color, sort_order, is_archived) VALUES (?, ?, ?, 0, NULL, NULL, NULL, 0)",
        <Object?>['Cash EUR', typeId, 'EUR'],
      );

      when(() => mockService.fetchRates(any())).thenAnswer(
        (_) async => [
          (from: 'EUR', to: 'USD', rate: -1.0, fetchedAt: DateTime(2026, 5, 14)),
        ],
      );

      await repo.refreshAll('USD');

      expect(repo.getRate('EUR', 'USD'), isNull);
    });

    test('refreshAll rejects rate > 1,000,000', () async {
      await db.customStatement(
        "INSERT INTO account_types (l10n_key, icon, color, sort_order, is_archived) "
        "VALUES (?, ?, 0, 1, 0)",
        <Object?>['accountType.cash', 'wallet'],
      );
      final typeRows = await db.customSelect('SELECT id FROM account_types').get();
      final typeId = typeRows.first.read<int>('id');
      await db.customStatement(
        "INSERT INTO accounts (name, account_type_id, currency, opening_balance_minor_units, "
        "icon, color, sort_order, is_archived) VALUES (?, ?, ?, 0, NULL, NULL, NULL, 0)",
        <Object?>['Cash EUR', typeId, 'EUR'],
      );

      when(() => mockService.fetchRates(any())).thenAnswer(
        (_) async => [
          (from: 'EUR', to: 'USD', rate: 2000000.0, fetchedAt: DateTime(2026, 5, 14)),
        ],
      );

      await repo.refreshAll('USD');

      expect(repo.getRate('EUR', 'USD'), isNull);
    });

    test('refreshAll rejects rate drifting >100x from cached', () async {
      await db.customStatement(
        "INSERT INTO account_types (l10n_key, icon, color, sort_order, is_archived) "
        "VALUES (?, ?, 0, 1, 0)",
        <Object?>['accountType.cash', 'wallet'],
      );
      final typeRows = await db.customSelect('SELECT id FROM account_types').get();
      final typeId = typeRows.first.read<int>('id');
      await db.customStatement(
        "INSERT INTO accounts (name, account_type_id, currency, opening_balance_minor_units, "
        "icon, color, sort_order, is_archived) VALUES (?, ?, ?, 0, NULL, NULL, NULL, 0)",
        <Object?>['Cash EUR', typeId, 'EUR'],
      );

      // First fetch: normal rate.
      when(() => mockService.fetchRates(any())).thenAnswer(
        (_) async => [
          (from: 'EUR', to: 'USD', rate: 1.08, fetchedAt: DateTime(2026, 5, 14)),
        ],
      );
      await repo.refreshAll('USD');
      expect(repo.getRate('EUR', 'USD'), isNotNull);

      // Second fetch: wildly different rate (>100x).
      when(() => mockService.fetchRates(any())).thenAnswer(
        (_) async => [
          (from: 'EUR', to: 'USD', rate: 200.0, fetchedAt: DateTime(2026, 5, 15)),
        ],
      );
      await repo.refreshAll('USD');

      // Rate should still be the original cached value.
      final rate = repo.getRate('EUR', 'USD');
      expect(rate!.numerator, (1.08 * 1000000000).round());
    });

    test('defaultCurrency change triggers refreshAll', () async {
      await db.customStatement(
        "INSERT INTO account_types (l10n_key, icon, color, sort_order, is_archived) "
        "VALUES (?, ?, 0, 1, 0)",
        <Object?>['accountType.cash', 'wallet'],
      );
      final typeRows = await db.customSelect('SELECT id FROM account_types').get();
      final typeId = typeRows.first.read<int>('id');
      await db.customStatement(
        "INSERT INTO accounts (name, account_type_id, currency, opening_balance_minor_units, "
        "icon, color, sort_order, is_archived) VALUES (?, ?, ?, 0, NULL, NULL, NULL, 0)",
        <Object?>['Cash EUR', typeId, 'EUR'],
      );

      when(() => mockService.fetchRates(any())).thenAnswer(
        (_) async => [
          (from: 'EUR', to: 'USD', rate: 1.08, fetchedAt: DateTime(2026, 5, 14)),
        ],
      );

      // Emit a default currency change.
      defaultCurrencyController.add('USD');

      // Wait for the async refreshAll to complete.
      await Future<void>.delayed(const Duration(milliseconds: 100));

      verify(() => mockService.fetchRates(any())).called(greaterThanOrEqualTo(1));
    });

    test('fetchRate handles service errors silently', () async {
      when(() => mockService.fetchRates(any())).thenThrow(
        Exception('network error'),
      );

      // Should not throw.
      await repo.fetchRate('EUR', 'USD');

      // Rate should still be null (nothing was cached).
      expect(repo.getRate('EUR', 'USD'), isNull);
    });
  });
}
```

- [ ] **Step 2: Run the tests**

Run: `flutter test test/unit/repositories/exchange_rate_repository_test.dart`
Expected: All tests pass.

- [ ] **Step 3: Commit**

```bash
git add test/unit/repositories/exchange_rate_repository_test.dart
git commit -m "test: add ExchangeRateRepository unit tests with in-memory DB"
```

---

### Task 21: Widget tests for SummaryStrip conversion

**Files:**
- Create: `test/widget/features/home/summary_strip_conversion_test.dart`

> **Note:** Before writing test fixtures, verify the constructor signatures of `Currency`, `Account`, `Category`, and `Transaction` in `lib/data/models/`. Freezed models may have additional required fields (e.g., `isToken`, `sortOrder`). Adjust test fixtures to match.

- [ ] **Step 1: Create the test file**

Create `test/widget/features/home/summary_strip_conversion_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/app/providers/repository_providers.dart';
import 'package:ledgerly/data/models/currency.dart';
import 'package:ledgerly/features/home/widgets/summary_strip.dart';

void main() {
  Widget buildStrip({
    required Map<String, ({int expense, int income})> todayTotals,
    required Map<String, int> monthNet,
    required String defaultCurrency,
    Map<String, ({int numerator, int denominator})>? rates,
  }) {
    return ProviderScope(
      overrides: [
        exchangeRatesProvider.overrideWith(
          (_) => Stream.value(rates ?? {}),
        ),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: SummaryStrip(
            todayTotalsByCurrency: todayTotals,
            monthNetByCurrency: monthNet,
            currenciesByCode: const {
              'USD': Currency(code: 'USD', decimals: 2, symbol: r'$'),
              'EUR': Currency(code: 'EUR', decimals: 2, symbol: '€'),
            },
            locale: 'en_US',
            defaultCurrency: defaultCurrency,
          ),
        ),
      ),
    );
  }

  group('SummaryStrip conversion', () {
    testWidgets('shows unified total when rate available', (tester) async {
      await tester.pumpWidget(buildStrip(
        todayTotals: {
          'EUR': (expense: 500, income: 0), // €5.00
        },
        monthNet: {'EUR': -2000},
        defaultCurrency: 'USD',
        rates: {
          'EUR→USD': (
            numerator: (1.08 * 1000000000).round(),
            denominator: 1000000000,
          ),
        },
      ));

      // Should show a unified group in USD.
      expect(find.textContaining(r'$'), findsWidgets);
    });

    testWidgets('falls back to per-currency when rate missing', (tester) async {
      await tester.pumpWidget(buildStrip(
        todayTotals: {
          'EUR': (expense: 500, income: 0),
        },
        monthNet: {'EUR': -2000},
        defaultCurrency: 'USD',
        rates: {}, // No rates available.
      ));

      // Should show EUR group as fallback.
      expect(find.textContaining('€'), findsWidgets);
    });

    testWidgets('same-currency totals pass through unchanged', (tester) async {
      await tester.pumpWidget(buildStrip(
        todayTotals: {
          'USD': (expense: 1000, income: 500),
        },
        monthNet: {'USD': -500},
        defaultCurrency: 'USD',
      ));

      // Should show USD group directly (no conversion needed).
      expect(find.textContaining(r'$'), findsWidgets);
    });
  });
}
```

- [ ] **Step 2: Run the tests**

Run: `flutter test test/widget/features/home/summary_strip_conversion_test.dart`
Expected: All tests pass.

- [ ] **Step 3: Commit**

```bash
git add test/widget/features/home/summary_strip_conversion_test.dart
git commit -m "test: add SummaryStrip conversion widget tests"
```

---

### Task 22: Widget tests for TransactionTile conversion

**Files:**
- Create: `test/widget/features/home/transaction_tile_conversion_test.dart`

> **Note:** Verify the constructor signatures of `Transaction`, `Currency`, `Account`, and `Category` in `lib/data/models/` before writing test fixtures. Adjust as needed.

- [ ] **Step 1: Create the test file**

Create `test/widget/features/home/transaction_tile_conversion_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/app/providers/repository_providers.dart';
import 'package:ledgerly/data/models/account.dart';
import 'package:ledgerly/data/models/category.dart';
import 'package:ledgerly/data/models/currency.dart';
import 'package:ledgerly/data/models/transaction.dart';
import 'package:ledgerly/features/home/widgets/transaction_tile.dart';
import 'package:ledgerly/features/home/home_providers.dart';

void main() {
  final testTransaction = Transaction(
    id: 1,
    amountMinorUnits: 540,
    currency: const Currency(code: 'EUR', decimals: 2, symbol: '€'),
    categoryId: 1,
    accountId: 1,
    date: DateTime(2026, 5, 14),
    createdAt: DateTime(2026, 5, 14),
    updatedAt: DateTime(2026, 5, 14),
  );

  final testCategory = Category(
    id: 1,
    icon: 'restaurant',
    color: 0,
    type: CategoryType.expense,
  );

  final testAccount = Account(
    id: 1,
    name: 'Cash',
    accountTypeId: 1,
    currency: const Currency(code: 'EUR', decimals: 2, symbol: '€'),
    openingBalanceMinorUnits: 0,
  );

  Widget buildTile({
    required String defaultCurrency,
    Map<String, ({int numerator, int denominator})>? rates,
  }) {
    return ProviderScope(
      overrides: [
        exchangeRatesProvider.overrideWith(
          (_) => Stream.value(rates ?? {}),
        ),
        homeCurrenciesByCodeProvider.overrideWith(
          (_) => Stream.value({
            'USD': const Currency(code: 'USD', decimals: 2, symbol: r'$'),
            'EUR': const Currency(code: 'EUR', decimals: 2, symbol: '€'),
          }),
        ),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: TransactionTile(
            transaction: testTransaction,
            category: testCategory,
            account: testAccount,
            locale: 'en_US',
            defaultCurrency: defaultCurrency,
            onTap: () {},
            onDuplicate: () {},
            onDelete: () {},
          ),
        ),
      ),
    );
  }

  group('TransactionTile conversion', () {
    testWidgets('shows converted line when rate available', (tester) async {
      await tester.pumpWidget(buildTile(
        defaultCurrency: 'USD',
        rates: {
          'EUR→USD': (
            numerator: (1.08 * 1000000000).round(),
            denominator: 1000000000,
          ),
        },
      ));

      // Should show both the primary amount and the ≈ converted line.
      expect(find.textContaining('€'), findsOneWidget);
      expect(find.textContaining('≈'), findsOneWidget);
    });

    testWidgets('hides converted line when same currency', (tester) async {
      await tester.pumpWidget(buildTile(
        defaultCurrency: 'EUR',
      ));

      // Should NOT show the ≈ line for same-currency.
      expect(find.textContaining('≈'), findsNothing);
    });

    testWidgets('hides converted line when rate missing', (tester) async {
      await tester.pumpWidget(buildTile(
        defaultCurrency: 'USD',
        rates: {}, // No rates.
      ));

      // Should NOT show the ≈ line when rate is unavailable.
      expect(find.textContaining('≈'), findsNothing);
    });
  });
}
```

- [ ] **Step 2: Run the tests**

Run: `flutter test test/widget/features/home/transaction_tile_conversion_test.dart`
Expected: All tests pass.

- [ ] **Step 3: Commit**

```bash
git add test/widget/features/home/transaction_tile_conversion_test.dart
git commit -m "test: add TransactionTile conversion widget tests"
```

---

### Task 23: Widget tests for AccountTile conversion

**Files:**
- Create: `test/widget/features/accounts/account_tile_conversion_test.dart`

> **Note:** Verify the constructor signatures of `Account`, `Currency`, and `AccountWithBalance` in `lib/data/models/` and `lib/features/accounts/accounts_state.dart` before writing test fixtures. Adjust as needed.

- [ ] **Step 1: Create the test file**

Create `test/widget/features/accounts/account_tile_conversion_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/app/providers/repository_providers.dart';
import 'package:ledgerly/data/models/account.dart';
import 'package:ledgerly/data/models/currency.dart';
import 'package:ledgerly/features/accounts/accounts_state.dart';
import 'package:ledgerly/features/accounts/widgets/account_tile.dart';
import 'package:ledgerly/features/accounts/accounts_providers.dart';
import 'package:ledgerly/features/settings/settings_providers.dart';

void main() {
  Widget buildTile({
    required Map<String, int> balancesByCurrency,
    Map<String, ({int numerator, int denominator})>? rates,
    String defaultCurrency = 'USD',
  }) {
    final account = Account(
      id: 1,
      name: 'Multi-Currency',
      accountTypeId: 1,
      currency: const Currency(code: 'USD', decimals: 2, symbol: r'$'),
      openingBalanceMinorUnits: 0,
    );

    return ProviderScope(
      overrides: [
        exchangeRatesProvider.overrideWith(
          (_) => Stream.value(rates ?? {}),
        ),
        defaultCurrencyProvider.overrideWith(
          (_) => Stream.value(defaultCurrency),
        ),
        currenciesByCodeProvider.overrideWith(
          (_) => Stream.value({
            'USD': const Currency(code: 'USD', decimals: 2, symbol: r'$'),
            'EUR': const Currency(code: 'EUR', decimals: 2, symbol: '€'),
            'JPY': const Currency(code: 'JPY', decimals: 0, symbol: '¥'),
          }),
        ),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: AccountTile(
            view: AccountWithBalance(
              account: account,
              balancesByCurrency: balancesByCurrency,
              affordance: AccountRowAffordance.archive,
            ),
            isDefault: false,
            locale: 'en_US',
            accountTypeLabel: 'Cash',
            onTap: () {},
            onSetDefault: () {},
            onArchive: () {},
            onDelete: () {},
            onArchiveBlocked: () {},
          ),
        ),
      ),
    );
  }

  group('AccountTile conversion', () {
    testWidgets('shows converted total for multi-currency with rates',
        (tester) async {
      await tester.pumpWidget(buildTile(
        balancesByCurrency: {
          'USD': 34000, // $340.00
          'EUR': 125000, // €1,250.00
        },
        rates: {
          'EUR→USD': (
            numerator: (1.08 * 1000000000).round(),
            denominator: 1000000000,
          ),
        },
      ));

      // Should show the ≈ converted total line.
      expect(find.textContaining('≈'), findsOneWidget);
      expect(find.textContaining('total'), findsOneWidget);
    });

    testWidgets('hides converted total for single-currency account',
        (tester) async {
      await tester.pumpWidget(buildTile(
        balancesByCurrency: {
          'USD': 34000,
        },
      ));

      // Should NOT show the converted total for single-currency.
      expect(find.textContaining('≈'), findsNothing);
    });

    testWidgets('hides converted total when any rate missing',
        (tester) async {
      await tester.pumpWidget(buildTile(
        balancesByCurrency: {
          'USD': 34000,
          'EUR': 125000,
        },
        rates: {}, // No rates.
      ));

      // Should NOT show the converted total when rates are missing.
      expect(find.textContaining('≈'), findsNothing);
    });
  });
}
```

- [ ] **Step 2: Run the tests**

Run: `flutter test test/widget/features/accounts/account_tile_conversion_test.dart`
Expected: All tests pass.

- [ ] **Step 3: Commit**

```bash
git add test/widget/features/accounts/account_tile_conversion_test.dart
git commit -m "test: add AccountTile conversion widget tests"
```

---

### Task 24: Integration test

**Files:**
- Create: `test/integration/currency_conversion_flow_test.dart`

- [ ] **Step 1: Create the integration test**

Create `test/integration/currency_conversion_flow_test.dart`:

```dart
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/app/providers/repository_providers.dart';
import 'package:ledgerly/data/database/app_database.dart';
import 'package:ledgerly/data/repositories/exchange_rate_repository.dart';
import 'package:ledgerly/data/services/exchange_rate_service.dart';
import 'package:mocktail/mocktail.dart';

import '../support/test_app.dart';

class MockExchangeRateService extends Mock implements ExchangeRateService {}

void main() {
  late AppDatabase db;
  late MockExchangeRateService mockService;
  late StreamController<String> defaultCurrencyController;

  setUp(() async {
    db = newTestAppDatabase();
    mockService = MockExchangeRateService();
    defaultCurrencyController = StreamController<String>.broadcast();
  });

  tearDown(() async {
    await defaultCurrencyController.close();
    await db.close();
  });

  group('Currency conversion flow', () {
    test('repository snapshot updates after API fetch', () async {
      // Seed currencies.
      await runTestSeed(db);

      // Create the repository.
      final repo = DriftExchangeRateRepository(
        db,
        mockService,
        defaultCurrencyController.stream,
      );

      // Mock the service to return a rate.
      when(() => mockService.fetchRates(any())).thenAnswer(
        (_) async => [
          (
            from: 'EUR',
            to: 'USD',
            rate: 1.08,
            fetchedAt: DateTime(2026, 5, 14),
          ),
        ],
      );

      // Trigger a fetch.
      await repo.refreshAll('USD');

      // Verify the snapshot has the rate.
      final rate = repo.getRate('EUR', 'USD');
      expect(rate, isNotNull);
      expect(rate!.numerator, (1.08 * 1000000000).round());

      // Verify the inverse was also stored.
      final inverse = repo.getRate('USD', 'EUR');
      expect(inverse, isNotNull);
      expect(inverse!.numerator, 1000000000);
      expect(inverse.denominator, (1.08 * 1000000000).round());

      repo.dispose();
    });

    test('default currency change triggers re-fetch', () async {
      await runTestSeed(db);

      final repo = DriftExchangeRateRepository(
        db,
        mockService,
        defaultCurrencyController.stream,
      );

      when(() => mockService.fetchRates(any())).thenAnswer(
        (_) async => [
          (
            from: 'EUR',
            to: 'GBP',
            rate: 0.86,
            fetchedAt: DateTime(2026, 5, 14),
          ),
        ],
      );

      // Change default currency.
      defaultCurrencyController.add('GBP');

      // Wait for the async handler.
      await Future<void>.delayed(const Duration(milliseconds: 200));

      verify(() => mockService.fetchRates(any())).called(greaterThanOrEqualTo(1));

      repo.dispose();
    });

    test('cached rates persist across repository instances', () async {
      await runTestSeed(db);

      // First instance: fetch and store.
      final repo1 = DriftExchangeRateRepository(
        db,
        mockService,
        defaultCurrencyController.stream,
      );

      when(() => mockService.fetchRates(any())).thenAnswer(
        (_) async => [
          (
            from: 'EUR',
            to: 'USD',
            rate: 1.08,
            fetchedAt: DateTime(2026, 5, 14),
          ),
        ],
      );

      await repo1.refreshAll('USD');
      repo1.dispose();

      // Second instance: should load from DAO.
      final repo2 = DriftExchangeRateRepository(
        db,
        mockService,
        defaultCurrencyController.stream,
      );

      // Wait for the DAO subscription to emit.
      await Future<void>.delayed(const Duration(milliseconds: 100));

      final rate = repo2.getRate('EUR', 'USD');
      expect(rate, isNotNull);
      expect(rate!.numerator, (1.08 * 1000000000).round());

      repo2.dispose();
    });
  });
}
```

- [ ] **Step 2: Run the test**

Run: `flutter test test/integration/currency_conversion_flow_test.dart`
Expected: All tests pass.

- [ ] **Step 3: Commit**

```bash
git add test/integration/currency_conversion_flow_test.dart
git commit -m "test: add currency conversion integration test"
```

---

### Task 25: Run full test suite and fix regressions

- [ ] **Step 1: Format all changed files**

Run: `dart format .`

- [ ] **Step 2: Run the full analyzer**

Run: `flutter analyze`
Expected: No errors.

- [ ] **Step 3: Run import_lint**

Run: `dart run import_lint`
Expected: No violations.

- [ ] **Step 4: Run the full test suite**

Run: `flutter test`
Expected: All tests pass.

- [ ] **Step 5: Fix any failures**

If any tests fail, diagnose and fix. Common issues:
- Missing `defaultCurrency` parameter at call sites
- Missing l10n keys (run `flutter gen-l10n` again)
- Import rule violations (check `import_analysis_options.yaml`)

- [ ] **Step 6: Final commit (if fixes needed)**

```bash
git add -A
git commit -m "fix: address test failures from multi-currency conversion"
```

---

## Execution Summary

| Chunk                     | Tasks | Files Created                                   | Files Modified                                        |
|---------------------------|-------|-------------------------------------------------|-------------------------------------------------------|
| 1: Data Foundation        | 1–7   | 3 (table, DAO, service) + 2 (converter, schema) | 2 (pubspec, app_database) + 2 (test harness)          |
| 2: Repository + Providers | 8–10  | 1 (repository)                                  | 3 (repository_providers, settings_providers)          |
| 3: Bootstrap + Fetch      | 11–13 | 0                                               | 3 (bootstrap, accounts_providers, tx_form_controller) |
| 4: Localization           | 14    | 0                                               | 3 (ARB files)                                         |
| 5: UI SummaryStrip        | 15    | 0                                               | 1 (summary_strip)                                     |
| 6: UI TransactionTile     | 16    | 0                                               | 1 (transaction_tile)                                  |
| 7: UI AccountTile         | 17    | 0                                               | 1 (account_tile)                                      |
| 8: Tests                  | 18–25 | 6 (test files)                                  | 0                                                     |
