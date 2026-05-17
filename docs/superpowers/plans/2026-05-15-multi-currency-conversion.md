# Multi-Currency Conversion Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fetch live exchange rates on startup, persist as fixed-scale integers in Drift, and display auto-converted amounts in the user's default currency on SummaryStrip, TransactionTile, and AccountTile.

**Architecture:** New `exchange_rates` Drift table stores forward rates only (no inverse) as a single `rate_scaled_e9` integer column (value × 10⁹). A concrete `ExchangeRateRepository` (no abstract base — single implementation) subscribes to the DAO's `watchAll()` stream to maintain an in-memory snapshot, and subscribes to `defaultCurrencyProvider` to re-fetch on currency change with a single-flight guard. Conversion uses int64 arithmetic in a new `CurrencyConverter` utility — fiat currencies (decimals ≤ 8) fit comfortably and avoid per-tile BigInt allocations. UI tiles read the snapshot via a Riverpod provider and render converted amounts as secondary muted lines with consistent accessibility semantics.

**Persistence rationale:** Rates are persisted (vs in-memory only) so cold-start UI shows last-known approximations before the network call returns, and so the on-device cache survives short network outages. Rates carry a `fetched_at` timestamp; the UI displays the `≈` qualifier to signal advisory accuracy.

**Tech Stack:** `dio` (HTTP), Drift (table + DAO), Riverpod (providers), int64 arithmetic (conversion), existing `MoneyFormatter` (formatting).

---

## File Structure

### New Files

| File                                                              | Responsibility                                                                             |
|-------------------------------------------------------------------|--------------------------------------------------------------------------------------------|
| `lib/data/database/tables/exchange_rates_table.dart`              | Drift table for `exchange_rates` (forward-only, scaled-e9 integer rates)                   |
| `lib/data/database/daos/exchange_rate_dao.dart`                   | DAO: `upsertAll()`, `watchAll()`, type-safe `distinctCurrenciesAcrossAllTables()`          |
| `lib/data/services/exchange_rate_service.dart`                    | HTTP client via Dio with ISO 4217 validation and `baseUrl` override                        |
| `lib/data/repositories/exchange_rate_repository.dart`             | Concrete repo (no abstract base): snapshot, single-flight, plausible-range sanity, onError |
| `lib/core/utils/currency_converter.dart`                          | Pure function: `convertMinorUnits()` using BigInt for overflow safety                      |
| `lib/app/providers/default_currency_provider.dart`                | `defaultCurrencyProvider` Stream + `initialDefaultCurrencyProvider` bootstrap override     |
| `test/unit/services/exchange_rate_service_test.dart`              | Service unit tests (mock Dio)                                                              |
| `test/unit/repositories/exchange_rate_repository_test.dart`       | Repository unit tests (in-memory DB + mock service, Drift companions, single-flight)       |
| `test/unit/utils/currency_converter_test.dart`                    | Converter unit tests                                                                       |
| `test/widget/features/home/summary_strip_conversion_test.dart`    | SummaryStrip conversion widget tests                                                       |
| `test/widget/features/home/transaction_tile_conversion_test.dart` | TransactionTile conversion widget tests                                                    |
| `test/widget/features/accounts/account_tile_conversion_test.dart` | AccountTile conversion widget tests                                                        |
| `test/integration/currency_conversion_flow_test.dart`             | End-to-end integration test                                                                |

### Modified Files

| File                                                         | Change                                                                                                    |
|--------------------------------------------------------------|-----------------------------------------------------------------------------------------------------------|
| `pubspec.yaml`                                               | Add `dio` dependency                                                                                      |
| `lib/data/database/app_database.dart`                        | Register table + DAO, bump schema to v5, add migration                                                    |
| `lib/app/providers/repository_providers.dart`                | Add `exchangeRateServiceProvider` (Dio inline), `exchangeRateRepositoryProvider`, `exchangeRatesProvider` |
| `lib/app/bootstrap.dart`                                     | Read default currency synchronously, override `initialDefaultCurrencyProvider`                            |
| `lib/app/app.dart`                                           | Add Consumer to early-instantiate `exchangeRateRepositoryProvider`                                        |
| `lib/features/accounts/accounts_providers.dart`              | Debounced post-save on-demand fetch in `AccountFormActions.save()`                                        |
| `lib/features/transactions/transaction_form_controller.dart` | Debounced post-save on-demand fetch in `save()`; update `@Riverpod` `dependencies:`                       |
| `lib/features/home/widgets/summary_strip.dart`               | Unified default-currency total with separator-led per-row fallback                                        |
| `lib/features/home/widgets/transaction_tile.dart`            | Secondary converted amount line with Semantics(approximatelyPrefix), reflow-tolerant layout               |
| `lib/features/home/home_screen.dart`                         | Pass `defaultCurrency` to `SummaryStrip` and `TransactionTile`                                            |
| `lib/features/accounts/widgets/account_tile.dart`            | Converted total below per-currency balances with Semantics                                                |
| `l10n/app_en.arb`                                            | Add `approximatelyPrefix`, `convertedTotalLabel`, `homeSummaryUnconvertedHeader`                          |
| `l10n/app_zh_CN.arb`                                         | Add zh_CN translations                                                                                    |
| `l10n/app_zh_TW.arb`                                         | Add zh_TW translations                                                                                    |
| `l10n/app_zh.arb`                                            | Keep as-is (4-line shim)                                                                                  |
| `test/unit/repositories/migration_test.dart`                 | Extend with v5 schema helpers (and v4 import) and upgrade tests                                           |

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
/// Stores forward exchange rates only (no inverse rows — UI always looks up
/// foreign→default direction). Rate is stored as `rate_scaled_e9` =
/// `round(rate × 10⁹)`, which fits any fiat rate comfortably in int64 (the
/// max representable rate is ≈9.2e9 before overflow on the int64 column).
/// We use a fixed scale rather than a numerator/denominator fraction
/// because the API returns rates as `double` — the fraction representation
/// would not preserve information that has already been lost at parse time.
///
/// See `docs/superpowers/specs/2026-05-14-multi-currency-conversion-design.md`.
@DataClassName('ExchangeRateRow')
@TableIndex(name: 'idx_exchange_rates_pair', columns: {#baseCurrency, #quoteCurrency}, unique: true)
class ExchangeRates extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get baseCurrency => text().named('base_currency').references(Currencies, #code)();
  TextColumn get quoteCurrency => text().named('quote_currency').references(Currencies, #code)();
  IntColumn get rateScaledE9 => integer().named('rate_scaled_e9').customConstraint('CHECK(rate_scaled_e9 > 0) NOT NULL')();
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
import '../tables/accounts_table.dart';
import '../tables/exchange_rates_table.dart';
import '../tables/pending_transactions_table.dart';
import '../tables/transactions_table.dart';

part 'exchange_rate_dao.g.dart';

/// Thin SQL wrapper for `exchange_rates`.
///
/// Provides bulk upsert, watch-all, and a cross-table query to discover
/// every currency code in use across accounts, transactions, and
/// pending_transactions. Business logic (sanity bounds, scaling,
/// snapshot management) lives in `ExchangeRateRepository`.
@DriftAccessor(
  tables: [ExchangeRates, Accounts, Transactions, PendingTransactions],
)
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
  /// `transactions`, and `pending_transactions`. Uses Drift's type-safe
  /// query API so any future column rename surfaces at compile time
  /// instead of failing silently at runtime.
  Future<Set<String>> distinctCurrenciesAcrossAllTables() async {
    final results = await Future.wait([
      (selectOnly(accounts, distinct: true)..addColumns([accounts.currency])).get(),
      (selectOnly(transactions, distinct: true)..addColumns([transactions.currency])).get(),
      (selectOnly(pendingTransactions, distinct: true)..addColumns([pendingTransactions.currency])).get(),
    ]);
    final codes = <String>{};
    codes.addAll(results[0].map((r) => r.read(accounts.currency)!));
    codes.addAll(results[1].map((r) => r.read(transactions.currency)!));
    codes.addAll(results[2].map((r) => r.read(pendingTransactions.currency)!));
    return codes;
  }
}
```

> **Note:** Before generating, confirm that `Transactions.currency` and `PendingTransactions.currency` Drift columns are typed as `text` (not foreign key references to a typed `Currency` column). If the symbol name differs (e.g., `currencyCode`), update both the column reads and the DAO `@DriftAccessor(tables: ...)` list accordingly.

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

> **Note:** Follow the established pattern in `app_database.dart` — every existing `@TableIndex` is created imperatively (`m.createIndex(idxRecurringActiveDue)`, `m.createIndex(idxPendingSource)`, etc., lines 87–98). Drift's `m.createTable` does NOT auto-create `@TableIndex` indexes, so `m.createIndex(idxExchangeRatesPair)` is required.

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
/// The endpoint URL is overridable via the [baseUrl] constructor parameter
/// so that staging/localhost dev and integration tests can target an
/// alternate host without mocking the entire Dio client. Currency codes
/// passed in [pairs] are validated against the ISO 4217 shape
/// (3 alphabetic chars) before being concatenated into the query string;
/// malformed codes are silently skipped to avoid corrupting the request.
///
/// See `docs/superpowers/specs/2026-05-14-multi-currency-conversion-design.md`.
class ExchangeRateService {
  ExchangeRateService(this._dio, {String? baseUrl})
      : _baseUrl = baseUrl ?? _defaultBaseUrl;

  final Dio _dio;
  final String _baseUrl;

  static const _defaultBaseUrl =
      'https://ledgerly-api.bigto-fintech.workers.dev/api/conversion';

  static final _iso4217 = RegExp(r'^[A-Za-z]{3}$');

  /// Fetches rates for the given currency pairs.
  ///
  /// [pairs] is a list of `(from, to)` records where each string is an
  /// ISO 4217 currency code. The method validates each code with
  /// `^[A-Za-z]{3}$`, builds the ticker query string (e.g. `hkdusd,eurusd`),
  /// calls the API, and returns successfully parsed entries. `from`/`to`
  /// are normalized to uppercase.
  ///
  /// Throws [DioException] on network or HTTP errors — the caller
  /// (repository) catches and logs only the exception type.
  Future<List<({String from, String to, double rate, DateTime fetchedAt})>>
      fetchRates(List<({String from, String to})> pairs) async {
    if (pairs.isEmpty) return const [];

    final validPairs = pairs
        .where((p) => _iso4217.hasMatch(p.from) && _iso4217.hasMatch(p.to))
        .toList();
    if (validPairs.isEmpty) return const [];

    final tickers = validPairs
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
      if (!_iso4217.hasMatch(from) || !_iso4217.hasMatch(to)) continue;
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
/// Pure scaled-integer minor-unit currency conversion.
///
/// Converts an amount in one currency's minor units to another using a
/// rate stored as `rate_scaled_e9` (rate × 10⁹). `BigInt` is used for the
/// intermediate multiplication because legitimate fiat amounts can push
/// the product past int64: a $1M balance (10⁸ minor units) at a rate
/// approaching the sanity ceiling (~10⁹ scaled) already produces 10¹⁷,
/// which is close enough to int64 max (≈9.2e18) that any tighter math
/// is fragile. BigInt allocations are O(1) per conversion; the perf
/// implications are documented and acceptable for the MVP's 10k-tx cap.
///
/// MVP scope: fiat only (decimals 0–8). 18-decimal token support is
/// deferred to a later phase; do not add ETH/wei tests here.
///
/// See `docs/superpowers/specs/2026-05-14-multi-currency-conversion-design.md`.
class CurrencyConverter {
  const CurrencyConverter._();

  static final BigInt _e9 = BigInt.from(1000000000);

  /// Converts [amountMinorUnits] from a currency with [fromDecimals]
  /// minor-unit digits to a currency with [toDecimals] minor-unit digits,
  /// using a rate scaled by 10⁹ (i.e., [rateScaledE9] = `round(rate × 1e9)`).
  ///
  /// Formula:
  ///   target = amount × rate × 10^(toDecimals − fromDecimals)
  ///          = amount × rateScaledE9 × 10^(toDecimals − fromDecimals) / 10⁹
  ///
  /// The result is truncated toward zero (BigInt `~/` semantics). The
  /// caller rounds at the API boundary by using `(rate × 1e9).round()`.
  static int convertMinorUnits({
    required int amountMinorUnits,
    required int rateScaledE9,
    required int fromDecimals,
    required int toDecimals,
  }) {
    final amount = BigInt.from(amountMinorUnits);
    final rate = BigInt.from(rateScaledE9);
    final shift = toDecimals - fromDecimals;

    if (shift >= 0) {
      final scale = BigInt.from(10).pow(shift);
      return ((amount * rate * scale) ~/ _e9).toInt();
    } else {
      final scale = BigInt.from(10).pow(-shift);
      return (amount * rate ~/ (_e9 * scale)).toInt();
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

- [ ] **Step 3: Update the GeneratedHelper switch and versions list**

Open `test/unit/repositories/_harness/generated/schema.dart`. The file uses the `databaseForVersion(QueryExecutor db, int version)` shape with a switch over `v1.DatabaseAtV1` through `v4.DatabaseAtV4`. After regeneration, both must include v5:

```dart
class GeneratedHelper implements SchemaInstantiationHelper {
  @override
  GeneratedDatabase databaseForVersion(QueryExecutor db, int version) {
    switch (version) {
      case 1: return v1.DatabaseAtV1(db);
      case 2: return v2.DatabaseAtV2(db);
      case 3: return v3.DatabaseAtV3(db);
      case 4: return v4.DatabaseAtV4(db);
      case 5: return v5.DatabaseAtV5(db);
      default:
        throw MissingSchemaException(version, versions);
    }
  }

  static const versions = const [1, 2, 3, 4, 5];
}
```

If either the switch case for 5 or the `5` entry in `versions` is missing after generation, add them manually. **Do not** replace the switch with a single-return method — that breaks every existing migration test.

- [ ] **Step 4: Extend migration_test.dart with v5 tests**

In `test/unit/repositories/migration_test.dart`, add the v4 and v5 imports at the top (the file currently only imports v1–v3; the v4 group uses `schemaAt(3)` so it doesn't need a v4 import, but Task 7's new code starts the legacy DB at v4 via `v4.DatabaseAtV4(...)`):

```dart
import '_harness/generated/schema_v4.dart' as v4;
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

Create `lib/data/repositories/exchange_rate_repository.dart`:

```dart
import 'dart:async';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';

import '../database/app_database.dart' as drift;
import '../database/daos/exchange_rate_dao.dart';
import '../database/tables/exchange_rates_table.dart';
import '../services/exchange_rate_service.dart';

/// Concrete Drift-backed exchange-rate repository.
///
/// Single implementation — no abstract base. If a second backend is ever
/// needed, extract an interface at that point at near-zero cost.
///
/// Responsibilities:
/// - Subscribes to `dao.watchAll()` and maintains an in-memory snapshot
///   for synchronous UI lookups.
/// - Subscribes to a `defaultCurrency$` stream and re-fetches rates for
///   every in-use currency when the default changes, with a single-flight
///   guard so concurrent triggers coalesce into one network request.
/// - Stores only forward rates (foreign → default). UI never looks up the
///   reverse direction; computing inverses on the fly would be possible
///   if needed.
/// - Sanity-checks every fetched rate against an absolute plausible-range
///   table (rejects negative/zero, rejects values outside `[1e-6, 1e6]`).
///   No "drift multiplier" check — legitimate currency moves should not be
///   blocked by stale cache. The plausible-range filter is the only guard.
/// - Sanitized logging: catches caught exceptions log only the runtime
///   type, never the exception object (which can contain URL + currency
///   pairs that violate CLAUDE.md's "no financial data in logs" rule).
final class ExchangeRateRepository {
  ExchangeRateRepository(
    this._db,
    this._service,
    Stream<String> defaultCurrency$,
  ) {
    _daoSub = _db.exchangeRateDao.watchAll().listen(
      _rebuildSnapshot,
      onError: (Object e, StackTrace s) {
        debugPrint('ExchangeRateRepository: DAO stream error '
            '(${e.runtimeType})');
      },
    );
    _currencySub = defaultCurrency$.listen((code) {
      unawaited(refreshAll(code));
    });
  }

  final drift.AppDatabase _db;
  final ExchangeRateService _service;

  ExchangeRateDao get _dao => _db.exchangeRateDao;

  late final StreamSubscription<List<ExchangeRateRow>> _daoSub;
  late final StreamSubscription<String> _currencySub;

  Map<String, int> _snapshot = const {};

  /// Single-flight guard: when a refresh for [defaultCurrency] is in
  /// flight, additional calls await the existing future instead of
  /// firing a parallel network request.
  Future<void>? _inFlight;
  String? _inFlightCurrency;

  /// Absolute plausible-range guard against malicious or buggy upstream
  /// responses. Applies on every fetch including cold-start (no cached
  /// baseline needed). Conservative envelope: covers normal fiat
  /// (e.g. JPY/USD ≈ 0.0067, BTC/USD ≈ 100000) without admitting
  /// nonsense values. Tightening per-pair is deferred.
  static const double _minRate = 1e-6;
  static const double _maxRate = 1e6;

  // ---------- Snapshot management ----------

  void _rebuildSnapshot(List<ExchangeRateRow> rows) {
    final map = <String, int>{};
    for (final row in rows) {
      final key = '${row.baseCurrency}→${row.quoteCurrency}';
      map[key] = row.rateScaledE9;
    }
    _snapshot = map;
  }

  // ---------- Reads ----------

  /// Synchronous lookup against the in-memory snapshot. Returns the
  /// scaled-e9 integer for forward (`from → to`) lookups, or `1e9`
  /// (i.e. 1.0 × 10⁹) for same-currency pairs. Returns null when no
  /// rate is known.
  ///
  /// **Snapshot timing note:** Drift's `watch()` delivers its first
  /// emission one microtask after subscription. A UI widget that builds
  /// in the same synchronous frame as repository construction may read
  /// an empty snapshot even when the DB has cached rates. Tiles
  /// gracefully degrade to no-conversion display when `getRate` returns
  /// null — see UI loading/error states (Tasks 15–17).
  int? getRate(String from, String to) {
    if (from == to) return 1000000000;
    final key = '${from.toUpperCase()}→${to.toUpperCase()}';
    return _snapshot[key];
  }

  /// Stream of the snapshot map (scaled-e9 ints keyed by `from→to`).
  /// Consumed by `exchangeRatesProvider` and surfaced to UI tiles.
  Stream<Map<String, int>> watchRates() {
    return _dao.watchAll().map((rows) {
      final map = <String, int>{};
      for (final row in rows) {
        final key = '${row.baseCurrency}→${row.quoteCurrency}';
        map[key] = row.rateScaledE9;
      }
      return map;
    });
  }

  // ---------- Writes ----------

  /// Fetches rates for every in-use currency (excluding [defaultCurrency])
  /// and upserts results. Caught exceptions are logged by runtime type
  /// only; on failure the cached DAO snapshot continues to back [getRate].
  ///
  /// **Single-flight:** if a refresh is already in flight for the same
  /// [defaultCurrency], the current call awaits that future. If a
  /// refresh is in flight for a different default currency, the current
  /// call awaits the existing future and then starts a new one — so a
  /// rapid USD → EUR → USD toggle still ends with exactly one EUR fetch
  /// and one USD fetch, not three overlapping requests.
  Future<void> refreshAll(String defaultCurrency) async {
    if (_inFlight != null && _inFlightCurrency == defaultCurrency) {
      return _inFlight;
    }
    if (_inFlight != null) {
      await _inFlight;
    }
    final fut = _doRefreshAll(defaultCurrency);
    _inFlight = fut;
    _inFlightCurrency = defaultCurrency;
    try {
      await fut;
    } finally {
      if (identical(_inFlight, fut)) {
        _inFlight = null;
        _inFlightCurrency = null;
      }
    }
  }

  Future<void> _doRefreshAll(String defaultCurrency) async {
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
      debugPrint('ExchangeRateRepository.refreshAll failed '
          '(${e.runtimeType})');
    }
  }

  /// Fetches a single pair on demand (used after creating a non-default-
  /// currency account or transaction). Errors swallowed with sanitized
  /// logging. Callers in form controllers should debounce to avoid 1:1
  /// timing correlation with financial actions (see Tasks 12–13).
  Future<void> fetchRate(String from, String defaultCurrency) async {
    try {
      final results =
          await _service.fetchRates([(from: from, to: defaultCurrency)]);
      await _upsertValidRates(results);
    } on Exception catch (e) {
      debugPrint('ExchangeRateRepository.fetchRate failed '
          '(${e.runtimeType})');
    }
  }

  Future<void> _upsertValidRates(
    List<({String from, String to, double rate, DateTime fetchedAt})> results,
  ) async {
    if (results.isEmpty) return;

    final companions = <drift.ExchangeRatesCompanion>[];
    for (final r in results) {
      if (!_passesSanityBounds(r.rate)) continue;
      // Forward rate only — UI never looks up the reverse direction.
      companions.add(drift.ExchangeRatesCompanion(
        baseCurrency: Value(r.from),
        quoteCurrency: Value(r.to),
        rateScaledE9: Value((r.rate * 1000000000).round()),
        fetchedAt: Value(r.fetchedAt),
      ));
    }

    await _dao.upsertAll(companions);
  }

  bool _passesSanityBounds(double rate) {
    if (rate <= 0) return false;
    if (rate < _minRate || rate > _maxRate) {
      // Sanitized: rate values and currency codes deliberately omitted.
      debugPrint('ExchangeRateRepository: rate outside plausible range');
      return false;
    }
    return true;
  }

  // ---------- Lifecycle ----------

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
git commit -m "feat: add ExchangeRateRepository with snapshot, single-flight, sanitized logging"
```

---

### Task 9: Add defaultCurrencyProvider in app/providers/

**Files:**
- Create: `lib/app/providers/default_currency_provider.dart`

> **Note:** This task MUST be completed before Task 10, because Task 10's `exchangeRateRepositoryProvider` depends on `defaultCurrencyProvider`. The provider is placed in `lib/app/providers/` (alongside `locale_provider.dart`) rather than `lib/features/settings/settings_providers.dart` to avoid a circular import: `settings_providers.dart` already imports `app/providers/repository_providers.dart`, and Task 10 will need `repository_providers.dart` to reference this provider — a reverse import from the same file would form a cycle.

- [ ] **Step 1: Create the provider file**

Create `lib/app/providers/default_currency_provider.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'repository_providers.dart';

part 'default_currency_provider.g.dart';

/// Stream of the user's default currency ISO code, backed by Drift's
/// `watchDefaultCurrency()`. The bootstrap-known initial value is
/// provided synchronously via `initialDefaultCurrencyProvider` (see
/// Task 11 / Task 18) so UI tiles do not flicker through a `'USD'`
/// fallback on cold start.
@Riverpod(keepAlive: true, dependencies: [userPreferencesRepository])
Stream<String> defaultCurrency(Ref ref) {
  return ref.watch(userPreferencesRepositoryProvider).watchDefaultCurrency();
}

/// Bootstrap-provided initial value of the default currency. Overridden
/// in `bootstrap.dart` with the value read from `UserPreferencesRepository`
/// before `runApp`, so UI tiles can synchronously resolve the default
/// currency on first frame without going through the AsyncValue
/// loading state.
@Riverpod(keepAlive: true, dependencies: [])
String initialDefaultCurrency(Ref ref) {
  throw UnimplementedError(
    'initialDefaultCurrencyProvider must be overridden in bootstrap',
  );
}
```

- [ ] **Step 2: Run build_runner**

Run: `dart run build_runner build --delete-conflicting-outputs`
Expected: Generates `default_currency_provider.g.dart`.

- [ ] **Step 3: Verify compilation**

Run: `flutter analyze lib/app/providers/default_currency_provider.dart`
Expected: No errors.

- [ ] **Step 4: Commit**

```bash
git add lib/app/providers/default_currency_provider.dart lib/app/providers/default_currency_provider.g.dart
git commit -m "feat: add defaultCurrencyProvider in app/providers (breaks cycle)"
```

---

### Task 10: Add providers to repository_providers.dart

**Files:**
- Modify: `lib/app/providers/repository_providers.dart`

- [ ] **Step 1: Add imports**

In `lib/app/providers/repository_providers.dart`, add these imports at the top of the file. `package:dio/dio.dart` is added even though `ExchangeRateService` owns the Dio construction — `repository_providers.dart` itself doesn't reference `Dio` directly, so this import is **not** required; only the relative imports below are.

```dart
import '../../data/repositories/exchange_rate_repository.dart';
import '../../data/services/exchange_rate_service.dart';
import 'default_currency_provider.dart';
```

- [ ] **Step 2: Add the providers**

At the end of the file, add:

```dart
/// Exchange-rate HTTP service. Constructs its own `Dio` with conservative
/// timeouts — there is no standalone `dioProvider`, since the rate service
/// is the only consumer of Dio in the codebase. If a second HTTP consumer
/// appears later, extract `dioProvider` at that point.
@Riverpod(keepAlive: true, dependencies: [])
ExchangeRateService exchangeRateService(Ref ref) {
  return ExchangeRateService(
    Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    )),
  );
}

/// Exchange-rate repository. The constructor subscribes to DAO changes
/// and default-currency changes immediately — so simply reading this
/// provider is enough to start the cache pipeline.
@Riverpod(
  keepAlive: true,
  dependencies: [appDatabase, exchangeRateService, defaultCurrency],
)
ExchangeRateRepository exchangeRateRepository(Ref ref) {
  final repo = ExchangeRateRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(exchangeRateServiceProvider),
    ref.watch(defaultCurrencyProvider.stream),
  );
  ref.onDispose(repo.dispose);
  return repo;
}

/// Stream of the exchange-rate snapshot map (scaled-e9 integer values
/// keyed by `from→to`). Consumed by UI tiles via `ref.watch`.
@Riverpod(keepAlive: true, dependencies: [exchangeRateRepository])
Stream<Map<String, int>> exchangeRates(Ref ref) {
  return ref.watch(exchangeRateRepositoryProvider).watchRates();
}
```

Also add at the top of the file (or wherever package imports live):

```dart
import 'package:dio/dio.dart';
```

since this file now constructs a `Dio` instance inline.

- [ ] **Step 3: Run build_runner**

Run: `dart run build_runner build --delete-conflicting-outputs`
Expected: Regenerates `repository_providers.g.dart` with the new providers.

- [ ] **Step 4: Verify compilation**

Run: `flutter analyze lib/app/providers/repository_providers.dart`
Expected: No errors. The import of `default_currency_provider.dart` is local to `app/providers/` so the layer-boundary rules in `import_analysis_options.yaml` are satisfied.

- [ ] **Step 5: Commit**

```bash
git add lib/app/providers/repository_providers.dart lib/app/providers/repository_providers.g.dart
git commit -m "feat: add exchange rate service, repository, and stream providers"
```

---

## Chunk 3: Bootstrap + On-Demand Fetch

### Task 11: Wire bootstrap to override initialDefaultCurrencyProvider and trigger early repo construction

**Files:**
- Modify: `lib/app/bootstrap.dart`
- Modify: `lib/app/app.dart`

> **No `ProviderScope` → `ProviderContainer` refactor.** The original plan replaced `ProviderScope` with `UncontrolledProviderScope` so it could call `container.read(...)` before `runApp`, but that refactor (a) breaks `test/unit/app/bootstrap_order_test.dart:78` and `test/integration/recurring_transaction_test.dart:451-454` which assert `isA<ProviderScope>()`, (b) breaks the `widget is ProviderScope` unwrap branch in `test/support/test_app.dart:113`, and (c) doesn't actually deliver "before first frame" guarantees — the chain through `watchDefaultCurrency()` is asynchronous regardless. The simpler approach below leaves `ProviderScope` intact and triggers repository construction from within the widget tree.

- [ ] **Step 1: Read the default currency synchronously in bootstrap**

In `lib/app/bootstrap.dart`, immediately after `preferencesRepo` is created and the existing pref reads, read the current default currency:

```dart
final initialDefaultCurrency =
    await preferencesRepo.readDefaultCurrency();
```

If `UserPreferencesRepository` does not yet expose a non-streaming `readDefaultCurrency()`, add it as a thin wrapper around the same Drift row read that backs `watchDefaultCurrency()`. Fall back to `'USD'` only if the row is absent (truly fresh install).

- [ ] **Step 2: Add the override to the existing ProviderScope overrides list**

In the existing `ProviderScope(overrides: [...])` block, add:

```dart
initialDefaultCurrencyProvider.overrideWithValue(initialDefaultCurrency),
```

Add the matching import:

```dart
import 'providers/default_currency_provider.dart';
```

- [ ] **Step 3: Trigger early repository construction from inside the widget tree**

In `lib/app/app.dart`, inside the `App` widget's `build`, wrap the existing top-level child in a `Consumer` that reads `exchangeRateRepositoryProvider` so the constructor runs on first build (and the DAO + currency subscriptions kick in immediately):

```dart
// At the top of App.build (or App.initState if App is stateful), inside
// a Consumer-equivalent — see existing patterns in lib/app/app.dart.
Consumer(
  builder: (context, ref, _) {
    // Force instantiation: reading the keep-alive provider here makes
    // the repository's constructor run (DAO + defaultCurrency listeners
    // register), but we discard the value.
    ref.watch(exchangeRateRepositoryProvider);
    return child;
  },
)
```

If `App` already contains a similar early-mount `Consumer` (e.g., for theme or locale), piggyback on it rather than adding a new wrapper.

- [ ] **Step 4: Verify compilation**

Run: `flutter analyze lib/app/bootstrap.dart lib/app/app.dart`
Expected: No errors.

- [ ] **Step 5: Run existing tests to verify no regression**

Run: `flutter test test/unit/app/bootstrap_order_test.dart test/integration/bootstrap_to_home_test.dart test/integration/recurring_transaction_test.dart`
Expected: All pass — no test changes required since `ProviderScope` is preserved.

- [ ] **Step 6: Run all integration tests**

Run: `flutter test test/integration/`
Expected: All pass.

- [ ] **Step 7: Commit**

```bash
git add lib/app/bootstrap.dart lib/app/app.dart
git commit -m "feat: override initialDefaultCurrencyProvider + early repo construction"
```

---

### Task 12: Add debounced on-demand fetch to AccountFormActions

**Files:**
- Modify: `lib/features/accounts/accounts_providers.dart`

> **Note:** The on-demand fetch is wrapped in a small debouncer to break the 1:1 timing correlation between a user's financial action (creating a non-default-currency account) and an outbound API request. A 30-second window is wide enough to absorb several rapid saves into one network call without making the new account's converted balance feel laggy.

- [ ] **Step 1: Add a debouncer to AccountFormActions**

In `lib/features/accounts/accounts_providers.dart`, modify the `AccountFormActions` class:

```dart
class AccountFormActions {
  AccountFormActions(this._accountRepository, this._ref);

  final AccountRepository _accountRepository;
  final Ref _ref;

  final _pendingCodes = <String>{};
  Timer? _debounce;
  static const _debounceWindow = Duration(seconds: 30);

  Future<int> save(Account draft) async {
    final id = await _accountRepository.save(draft);

    final initialDefault = _ref.read(initialDefaultCurrencyProvider);
    final currentDefault = _ref
        .read(defaultCurrencyProvider)
        .valueOrNull ?? initialDefault;

    if (draft.currency.code != currentDefault) {
      _pendingCodes.add(draft.currency.code);
      _debounce?.cancel();
      _debounce = Timer(_debounceWindow, () {
        final repo = _ref.read(exchangeRateRepositoryProvider);
        for (final code in _pendingCodes) {
          unawaited(repo.fetchRate(code, currentDefault));
        }
        _pendingCodes.clear();
      });
    }
    return id;
  }
}
```

- [ ] **Step 2: Update the provider to pass Ref and dispose the timer**

Change the `accountFormActionsProvider`:

```dart
final accountFormActionsProvider = Provider<AccountFormActions>((ref) {
  final actions = AccountFormActions(ref.read(accountRepositoryProvider), ref);
  ref.onDispose(() => actions._debounce?.cancel());
  return actions;
});
```

- [ ] **Step 3: Add missing imports**

Add these imports at the top of the file:

```dart
import 'dart:async';
import '../../app/providers/default_currency_provider.dart';
import '../../app/providers/repository_providers.dart';
```

- [ ] **Step 4: Verify compilation**

Run: `flutter analyze lib/features/accounts/accounts_providers.dart`
Expected: No errors. Note: `accountFormActionsProvider` is a plain `Provider` (not `@Riverpod` generated) so it has no `dependencies:` list to update — Riverpod's `scoped_providers_should_specify_dependencies` lint only fires on annotated providers.

- [ ] **Step 5: Commit**

```bash
git add lib/features/accounts/accounts_providers.dart
git commit -m "feat: debounced on-demand exchange-rate fetch after account save"
```

---

### Task 13: Add immediate on-demand fetch to TransactionFormController

**Files:**
- Modify: `lib/features/transactions/transaction_form_controller.dart`

- [ ] **Step 1: Add imports**

Add these imports at the top of the file:

```dart
import 'dart:async';
import '../../app/providers/default_currency_provider.dart';
```

(`exchangeRateRepositoryProvider` is accessible via `repository_providers.dart` which is already imported.)

- [ ] **Step 2: Update the `@Riverpod` `dependencies:` list**

The existing annotation on `TransactionFormController` declares its dependencies. Add the two new providers it reads:

```dart
@Riverpod(
  dependencies: [
    transactionRepository,
    accountRepository,
    categoryRepository,
    userPreferencesRepository,
    currencyRepository,
    shoppingListRepository,
    defaultCurrency,            // <-- add
    exchangeRateRepository,     // <-- add
    initialDefaultCurrency,     // <-- add
  ],
)
class TransactionFormController extends _$TransactionFormController { ... }
```

Re-run `dart run build_runner build --delete-conflicting-outputs` after the edit.

- [ ] **Step 3: Add post-save immediate fetch in the save() method**

In the `save()` method, after `final saved = await repo.save(tx);` and before `state = s.copyWith(isSaving: false);`, add:

```dart
      final initialDefault = ref.read(initialDefaultCurrencyProvider);
      final currentDefault = ref
          .read(defaultCurrencyProvider)
          .valueOrNull ?? initialDefault;
      if (tx.currency.code != currentDefault) {
        final repoX = ref.read(exchangeRateRepositoryProvider);
        unawaited(repoX.fetchRate(tx.currency.code, currentDefault));
      }
```

This fetch is intentionally fire-and-forget: it starts immediately after the
transaction save succeeds, but it does not block the navigation path back to
Home.

- [ ] **Step 4: Verify compilation**

Run: `flutter analyze lib/features/transactions/transaction_form_controller.dart`
Expected: No errors.

- [ ] **Step 5: Commit**

```bash
git add lib/features/transactions/transaction_form_controller.dart lib/features/transactions/transaction_form_controller.g.dart
git commit -m "feat: immediate on-demand exchange-rate fetch after transaction save"
```

---

## Chunk 4: Localization

### Task 14: Add l10n keys

**Files:**
- Modify: `l10n/app_en.arb`
- Modify: `l10n/app_zh_CN.arb`
- Modify: `l10n/app_zh_TW.arb`

> **Note:** The previously-planned `accountTileShowMore` key has been dropped from this plan — its consumer (an AccountTile "Show N more" overflow affordance when more than 4 currency groups exist) is not implemented in any task here and would be dead l10n code. The overflow affordance is deferred to a separate feature; the key will be added alongside that feature's UI code.

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
  "homeSummaryUnconvertedHeader": "Unconverted",
  "@homeSummaryUnconvertedHeader": {
    "description": "Label on the separator between SummaryStrip's unified converted total and the per-currency fallback groups (for currencies whose rates are not yet cached)."
  },
```

- [ ] **Step 2: Add keys to app_zh_CN.arb**

In `l10n/app_zh_CN.arb`, add before the closing `}`:

```json
  "approximatelyPrefix": "约",
  "convertedTotalLabel": "总计",
  "homeSummaryUnconvertedHeader": "未换算",
```

- [ ] **Step 3: Add keys to app_zh_TW.arb**

In `l10n/app_zh_TW.arb`, add before the closing `}`:

```json
  "approximatelyPrefix": "約",
  "convertedTotalLabel": "總計",
  "homeSummaryUnconvertedHeader": "未換算",
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
git commit -m "l10n: add approximatelyPrefix, convertedTotalLabel"
```

---

## Chunk 5: UI — SummaryStrip

### Task 15: Modify SummaryStrip for unified default-currency total

**Files:**
- Modify: `lib/features/home/widgets/summary_strip.dart`
- Modify: `lib/features/home/home_screen.dart` (call site)
- Modify: `test/widget/features/home/summary_strip_test.dart` (existing tests need migration)

> **UI state behavior:**
> - **Loading (no rates yet):** render per-currency groups exactly as today — no flicker through "USD" if the user's default is non-USD.
> - **Partial-success (some rates missing):** unified default-currency group on top, then a thin `Divider` + small `Text(l10n.homeSummaryUnconvertedHeader)` label, then the per-currency groups for the missing-rate currencies, in stable currency-code-ascending order.
> - **Network failure, cache stale:** identical to "rates available" — the cached snapshot continues to back the display. No visible error indicator (rates are advisory; the `≈` already signals approximation).
> - **AnimatedSize:** keep the wrap; 150ms is fast enough that the transition reads as polish, not jank.

- [ ] **Step 1: Add new imports**

At the top of `summary_strip.dart`, add:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/default_currency_provider.dart';
import '../../../app/providers/repository_providers.dart';
import '../../../core/utils/currency_converter.dart';
import '../../../data/models/currency.dart';
```

- [ ] **Step 2: Change SummaryStrip to ConsumerWidget and add defaultCurrency parameter**

Change `class SummaryStrip extends StatelessWidget` to `class SummaryStrip extends ConsumerWidget`. Add the new required parameter:

```dart
const SummaryStrip({
  super.key,
  required this.todayTotalsByCurrency,
  required this.monthNetByCurrency,
  required this.currenciesByCode,
  required this.locale,
  required this.defaultCurrency,
  this.showJumpToToday = false,
  this.onJumpToToday,
});

final String defaultCurrency;
```

Update `build` signature to `Widget build(BuildContext context, WidgetRef ref)`.

- [ ] **Step 3: Read rates and compute converted totals**

At the start of the `build` method (after `final theme = Theme.of(context);`), add:

```dart
final exchangeRatesAsync = ref.watch(exchangeRatesProvider);
final ratesMap = exchangeRatesAsync.valueOrNull ?? const <String, int>{};

final toCurrency = currenciesByCode[defaultCurrency] ??
    Currency(code: defaultCurrency, decimals: 2, symbol: defaultCurrency);

int convertedExpense = 0;
int convertedIncome = 0;
int convertedMonthNet = 0;
final missingRatesFor = <String>{};

int? convert(int amount, String fromCode) {
  if (fromCode == defaultCurrency) return amount;
  final rateScaledE9 = ratesMap['$fromCode→$defaultCurrency'];
  if (rateScaledE9 == null) return null;
  final fromCurrency = currenciesByCode[fromCode] ??
      Currency(code: fromCode, decimals: 2, symbol: fromCode);
  return CurrencyConverter.convertMinorUnits(
    amountMinorUnits: amount,
    rateScaledE9: rateScaledE9,
    fromDecimals: fromCurrency.decimals,
    toDecimals: toCurrency.decimals,
  );
}

final allCodes = <String>{
  ...todayTotalsByCurrency.keys,
  ...monthNetByCurrency.keys,
};

for (final code in allCodes) {
  final today = todayTotalsByCurrency[code];
  final month = monthNetByCurrency[code] ?? 0;
  final expenseConverted = today == null ? 0 : convert(today.expense, code);
  final incomeConverted = today == null ? 0 : convert(today.income, code);
  final monthConverted = convert(month, code);
  if (expenseConverted == null || incomeConverted == null || monthConverted == null) {
    missingRatesFor.add(code);
    continue;
  }
  convertedExpense += expenseConverted;
  convertedIncome += incomeConverted;
  convertedMonthNet += monthConverted;
}

final convertibleCount = allCodes.length - missingRatesFor.length;
final canShowUnified = convertibleCount > 0;
final missingRatesSorted = missingRatesFor.toList()..sort();
```

- [ ] **Step 4: Render unified group + ordered fallback with separator**

Replace the existing per-currency rendering logic. When `canShowUnified` is true, render a single `_CurrencyGroup` for the default currency with the converted totals. When `missingRatesSorted` is non-empty, render a thin separator and a small "unconverted" header before the fallback groups.

```dart
final Widget content;
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
        if (canShowUnified)
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
            isApproximate: convertibleCount > 1 || _hasAnyNonDefaultCode(allCodes, defaultCurrency),
          ),
        if (canShowUnified && missingRatesSorted.isNotEmpty) ...[
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                Expanded(child: Divider(thickness: 1, color: theme.colorScheme.outline.withOpacity(0.4))),
                const SizedBox(width: 8),
                Text(
                  l10n.homeSummaryUnconvertedHeader,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(child: Divider(thickness: 1, color: theme.colorScheme.outline.withOpacity(0.4))),
              ],
            ),
          ),
        ],
        for (final code in missingRatesSorted) ...[
          const SizedBox(height: 8),
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
            isApproximate: false,
          ),
        ],
      ],
    ),
  );
}
```

`_hasAnyNonDefaultCode` is a small file-private helper that returns true if any code in `allCodes` differs from `defaultCurrency` — used to decide whether the unified group should display the `≈` prefix.

> **Note on the new l10n key:** `homeSummaryUnconvertedHeader` ("Unconverted" / "未换算" / "未換算") must be added to Task 14's ARB edits. Add it now while editing.

- [ ] **Step 5: Add `isApproximate` and Semantics to `_CurrencyGroup`**

Extend `_CurrencyGroup` to accept an `isApproximate` bool. When true, prefix the displayed amounts with `≈ ` AND wrap each amount line in a `Semantics(label: '${l10n.approximatelyPrefix} <amount>')` so screen readers say "approximately ..." instead of reading the literal `≈` glyph. When false, render unchanged.

- [ ] **Step 6: Update the call site in home_screen.dart**

In `lib/features/home/home_screen.dart` (~line 414, the `SummaryStrip(...)` construction), add:

```dart
final initialDefault = ref.read(initialDefaultCurrencyProvider);
final defaultCurrency = ref
    .watch(defaultCurrencyProvider)
    .valueOrNull ?? initialDefault;
```

and pass `defaultCurrency: defaultCurrency` to the constructor. **Do not** fall back to a hardcoded `'USD'` — `initialDefaultCurrencyProvider` is overridden in bootstrap with the actual user value, so the synchronous read here never produces a wrong-currency frame.

- [ ] **Step 7: Migrate the existing summary_strip_test.dart**

The existing widget test has six `const SummaryStrip(...)` constructions and a multi-currency assertion (SS02) verifying both USD-formatted and JPY-formatted output. After this refactor:
  1. Remove `const` from every `SummaryStrip(...)` (no longer a `StatelessWidget`).
  2. Wrap each test in a `ProviderScope` with `exchangeRatesProvider.overrideWith((ref) => Stream.value({...}))` and pass an explicit `defaultCurrency: 'USD'`.
  3. **Update SS02** ("multi-currency — both currency groups rendered") to assert the *unified* behavior: when rates for JPY→USD are provided, the strip renders one USD group totaling the converted amount; when rates are absent, both groups render (the old assertion). Split into two test cases — `'rates available shows unified USD group'` and `'rates missing shows per-currency fallback'`.
  4. Leave SS01 (empty placeholder) and SS03 (single-currency) unchanged.

- [ ] **Step 8: Verify compilation**

Run: `flutter analyze lib/features/home/widgets/summary_strip.dart`
Expected: No errors.

- [ ] **Step 9: Commit**

```bash
git add lib/features/home/widgets/summary_strip.dart lib/features/home/home_screen.dart test/widget/features/home/summary_strip_test.dart
git commit -m "feat: SummaryStrip unified default-currency total with partial-success fallback"
```

---

## Chunk 6: UI — TransactionTile

### Task 16: Add converted amount line to TransactionTile

**Files:**
- Modify: `lib/features/home/widgets/transaction_tile.dart`
- Modify: `lib/features/home/home_screen.dart` (call site)

- [ ] **Step 1: Add new imports**

At the top of `transaction_tile.dart`, add:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/repository_providers.dart';
import '../../../core/utils/currency_converter.dart';
```

(`homeCurrenciesByCodeProvider` is already defined at `lib/features/home/home_providers.dart:23` — reuse it; no need to redefine.)

- [ ] **Step 2: Change TransactionTile to ConsumerWidget and add defaultCurrency**

Change `class TransactionTile extends StatelessWidget` to `class TransactionTile extends ConsumerWidget`. Add the required parameter:

```dart
const TransactionTile({
  super.key,
  required this.transaction,
  required this.category,
  required this.account,
  required this.locale,
  required this.defaultCurrency,
  required this.onTap,
  required this.onDuplicate,
  required this.onDelete,
});

final String defaultCurrency;
```

Update `build` signature to `Widget build(BuildContext context, WidgetRef ref)`.

- [ ] **Step 3: Compute the converted amount**

After the existing `amountText` computation, add:

```dart
String? convertedText;
final txCurrency = transaction.currency;
if (txCurrency.code != defaultCurrency) {
  final ratesMap = ref.watch(exchangeRatesProvider).valueOrNull ?? const <String, int>{};
  final rateScaledE9 = ratesMap['${txCurrency.code}→$defaultCurrency'];
  if (rateScaledE9 != null) {
    final currenciesByCode =
        ref.watch(homeCurrenciesByCodeProvider).valueOrNull ?? const <String, Currency>{};
    final toCurrency = currenciesByCode[defaultCurrency] ??
        Currency(code: defaultCurrency, decimals: 2, symbol: defaultCurrency);
    final convertedMinorUnits = CurrencyConverter.convertMinorUnits(
      amountMinorUnits: transaction.amountMinorUnits,
      rateScaledE9: rateScaledE9,
      fromDecimals: txCurrency.decimals,
      toDecimals: toCurrency.decimals,
    );
    final signedConverted = isIncome ? convertedMinorUnits : -convertedMinorUnits;
    convertedText = '≈ ${MoneyFormatter.formatSigned(
      amountMinorUnits: signedConverted,
      currency: toCurrency,
      locale: locale,
    )}';
  }
}
```

> **Note:** confirm `MoneyFormatter.formatSigned` exists in `lib/core/utils/money_formatter.dart` before relying on it. If only `format` exists, prepend `-` to the formatted string manually based on `isIncome`.

- [ ] **Step 4: Render the converted line with reflow-tolerant layout and Semantics**

Replace the fixed-height `SizedBox` with an `IntrinsicHeight`-wrapped column that lets the trailing region grow at 2× text scale. The previous design hard-coded `bodySmall.fontSize * 1.4 * 2` which overflows ListTile's 56dp minimum at large scales — replace it.

```dart
trailing: Row(
  mainAxisSize: MainAxisSize.min,
  crossAxisAlignment: CrossAxisAlignment.center,
  children: [
    Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          amountText,
          style: theme.textTheme.titleMedium?.copyWith(
            color: isIncome ? theme.colorScheme.primary : theme.colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (convertedText != null)
          Semantics(
            label: '${l10n.approximatelyPrefix} '
                '${convertedText.substring(2)}', // strip the leading "≈ "
            excludeSemantics: true,
            child: Text(
              convertedText,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ),
      ],
    ),
    PopupMenuButton<_RowAction>(
      // ... existing code ...
    ),
  ],
),
```

If the host `ListTile` has `isThreeLine: false`, set it to `isThreeLine: true` when `convertedText != null` (and/or override `minVerticalPadding`) so the row can grow without compressing the title/subtitle. The behavior at 2× text scale should be verified by running the app with `MediaQuery.textScalerOf(context)` at 2.0 — add a manual verification note to Task 25.

- [ ] **Step 5: Update the call site in home_screen.dart**

In `lib/features/home/home_screen.dart` (~line 647), pass `defaultCurrency` using the same synchronous read as Task 15 Step 6:

```dart
final initialDefault = ref.read(initialDefaultCurrencyProvider);
final defaultCurrency = ref
    .watch(defaultCurrencyProvider)
    .valueOrNull ?? initialDefault;
```

and pass `defaultCurrency: defaultCurrency` to each `TransactionTile(...)` construction. Update any test call sites in `test/widget/features/home/` that construct `TransactionTile` directly.

- [ ] **Step 6: Verify compilation**

Run: `flutter analyze lib/features/home/widgets/transaction_tile.dart`
Expected: No errors.

- [ ] **Step 7: Commit**

```bash
git add lib/features/home/widgets/transaction_tile.dart lib/features/home/home_screen.dart
git commit -m "feat: TransactionTile shows secondary converted amount with a11y semantics"
```

---

## Chunk 7: UI — AccountTile

### Task 17: Add converted total to AccountTile

**Files:**
- Modify: `lib/features/accounts/widgets/account_tile.dart`

> **Pre-condition:** `AccountTile` already extends `ConsumerWidget` (verified at `lib/features/accounts/widgets/account_tile.dart:28`) and already reads `currenciesByCodeProvider` from `accounts_providers.dart`. No widget-base change is needed for this task — only adding the rate read and the converted-total render.

- [ ] **Step 1: Add new imports**

At the top of `account_tile.dart`, add:

```dart
import '../../../app/providers/default_currency_provider.dart';
import '../../../app/providers/repository_providers.dart';
import '../../../core/utils/currency_converter.dart';
```

- [ ] **Step 2: Read rates and default currency (no USD flicker)**

In the `build` method, after the existing `currenciesAsync` resolution, add:

```dart
final ratesMap = ref.watch(exchangeRatesProvider).valueOrNull ?? const <String, int>{};
final initialDefault = ref.read(initialDefaultCurrencyProvider);
final defaultCurrency = ref
    .watch(defaultCurrencyProvider)
    .valueOrNull ?? initialDefault;
```

The `initialDefault` read comes from the bootstrap-provided synchronous override — there is no `'USD'` fallback path.

- [ ] **Step 3: Compute the converted total**

Replace the existing per-currency-only render path with the converted-total compute. Place this above the call to `_buildSubtitle`:

```dart
final hasMultipleCurrencies = view.balancesByCurrency.length > 1;
String? convertedTotalFormatted;
if (hasMultipleCurrencies) {
  int total = 0;
  bool allRatesPresent = true;
  for (final entry in view.balancesByCurrency.entries) {
    final code = entry.key;
    final amount = entry.value;
    if (code == defaultCurrency) {
      total += amount;
    } else {
      final rateScaledE9 = ratesMap['$code→$defaultCurrency'];
      if (rateScaledE9 == null) {
        allRatesPresent = false;
        break;
      }
      final fromCurrency = currenciesByCode[code] ??
          Currency(code: code, decimals: 2, symbol: code);
      final toCurrency = currenciesByCode[defaultCurrency] ??
          Currency(code: defaultCurrency, decimals: 2, symbol: defaultCurrency);
      total += CurrencyConverter.convertMinorUnits(
        amountMinorUnits: amount,
        rateScaledE9: rateScaledE9,
        fromDecimals: fromCurrency.decimals,
        toDecimals: toCurrency.decimals,
      );
    }
  }
  if (allRatesPresent) {
    final toCurrency = currenciesByCode[defaultCurrency] ??
        Currency(code: defaultCurrency, decimals: 2, symbol: defaultCurrency);
    convertedTotalFormatted = MoneyFormatter.format(
      amountMinorUnits: total,
      currency: toCurrency,
      locale: locale,
    );
  }
}
```

- [ ] **Step 4: Extend `_buildSubtitle` with the converted-total branch**

Add a new optional parameter to the existing `_buildSubtitle` signature (currently at `lib/features/accounts/widgets/account_tile.dart:172`):

```dart
Widget _buildSubtitle(
  BuildContext context,
  String accountTypeLabel,
  Map<String, int> balancesByCurrency,
  Map<String, Currency> currenciesByCode,
  AppLocalizations l10n, {
  String? convertedTotalFormatted,
}) {
```

At the end of the method, append the converted-total line when present:

```dart
if (convertedTotalFormatted != null) {
  lines.add(
    ExcludeSemantics(
      child: Divider(
        thickness: 1,
        indent: 16,
        endIndent: 16,
        color: Theme.of(context).colorScheme.outline.withOpacity(0.4),
      ),
    ),
  );
  lines.add(
    Semantics(
      label: '${l10n.approximatelyPrefix} $convertedTotalFormatted '
          '${l10n.convertedTotalLabel}',
      excludeSemantics: true,
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

Update the call site (`account_tile.dart:146`):

```dart
subtitle: _buildSubtitle(
  context,
  accountTypeLabel,
  view.balancesByCurrency,
  currenciesByCode,
  l10n,
  convertedTotalFormatted: convertedTotalFormatted,
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
          rateScaledE9: 1000000000,
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
          rateScaledE9: (0.85 * 1000000000).round(),
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
          rateScaledE9: (0.0067 * 1000000000).round(),
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
          rateScaledE9: (149.25 * 1000000000).round(),
          fromDecimals: 2,
          toDecimals: 0,
        ),
        1000,
      );
    });

    test('rounding: truncates fractional remainder toward zero', () {
      // 100 minor units * 0.333 rate = 33.3 → 33 (fractional dropped)
      expect(
        CurrencyConverter.convertMinorUnits(
          amountMinorUnits: 100,
          rateScaledE9: (0.333 * 1000000000).round(),
          fromDecimals: 2,
          toDecimals: 2,
        ),
        33,
      );
    });

    test('rounding: 0.5 rounds up via numerator scaling', () {
      // 100 minor units * 0.335 rate = 33.5 → 34. BigInt ~/ truncates,
      // but (rate * 1e9).round() pushes 0.335 × 1e9 = 335_000_000.0
      // so the input scaling already preserves the .5 round-half-up.
      expect(
        CurrencyConverter.convertMinorUnits(
          amountMinorUnits: 100,
          rateScaledE9: (0.335 * 1000000000).round(),
          fromDecimals: 2,
          toDecimals: 2,
        ),
        34,
      );
    });

    test('round-trip drift is within ±1 minor unit', () {
      // 100 HKD → USD → HKD should be within ±1 of 100
      const amount = 10000; // HK$100.00
      const hkdToUsdE9 = (0.1277 * 1000000000).round();
      const usdToHkdE9 = (1 / 0.1277 * 1000000000).round();

      final usd = CurrencyConverter.convertMinorUnits(
        amountMinorUnits: amount,
        rateScaledE9: hkdToUsdE9,
        fromDecimals: 2,
        toDecimals: 2,
      );
      final hkdRoundTrip = CurrencyConverter.convertMinorUnits(
        amountMinorUnits: usd,
        rateScaledE9: usdToHkdE9,
        fromDecimals: 2,
        toDecimals: 2,
      );

      expect(hkdRoundTrip, closeTo(amount, 1));
    });

    test('handles large fiat amounts without overflow', () {
      // $1M = 100_000_000 minor units; rate at upper sanity bound 1e6
      // = 1e15 scaled. Product is 1e23 — easily handled by BigInt path.
      expect(
        () => CurrencyConverter.convertMinorUnits(
          amountMinorUnits: 100000000,
          rateScaledE9: 1000000000000000, // 1e15
          fromDecimals: 2,
          toDecimals: 2,
        ),
        returnsNormally,
      );
    });
  });
}
```

> **Note:** the previous ETH/18-decimal test case was removed — it was out of scope for the fiat MVP and the BigInt overflow scenarios it exercised are now covered by the "large fiat amounts" test which uses the actual sanity ceiling.

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

import 'package:drift/drift.dart';
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
  late ExchangeRateRepository repo;

  /// Seed via Drift companions instead of raw SQL — survives schema changes.
  Future<int> seedAccount(String currency) async {
    final typeId = await db.into(db.accountTypes).insert(
          AccountTypesCompanion.insert(
            l10nKey: 'accountType.cash',
            icon: 'wallet',
            color: 0,
            sortOrder: const Value(1),
          ),
        );
    return db.into(db.accounts).insert(
          AccountsCompanion.insert(
            name: 'Cash $currency',
            accountTypeId: typeId,
            currency: currency,
            openingBalanceMinorUnits: const Value(0),
          ),
        );
  }

  setUp(() async {
    db = newTestAppDatabase();
    mockService = MockExchangeRateService();
    defaultCurrencyController = StreamController<String>.broadcast();

    // Seed minimal currency fixtures (USD, EUR) using companions.
    await db.into(db.currencies).insert(
          CurrenciesCompanion.insert(
            code: 'USD',
            decimals: 2,
            symbol: r'$',
            nameL10nKey: 'currency.usd',
            sortOrder: const Value(1),
          ),
        );
    await db.into(db.currencies).insert(
          CurrenciesCompanion.insert(
            code: 'EUR',
            decimals: 2,
            symbol: '€',
            nameL10nKey: 'currency.eur',
            sortOrder: const Value(2),
          ),
        );

    repo = ExchangeRateRepository(
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

  group('ExchangeRateRepository', () {
    test('getRate returns 1e9 (identity) for same currency', () {
      expect(repo.getRate('USD', 'USD'), 1000000000);
    });

    test('getRate returns null for unknown pair', () {
      expect(repo.getRate('USD', 'EUR'), isNull);
    });

    test('refreshAll fetches, upserts, and builds snapshot (forward only)',
        () async {
      await seedAccount('EUR');

      when(() => mockService.fetchRates(any())).thenAnswer(
        (_) async => [
          (from: 'EUR', to: 'USD', rate: 1.08, fetchedAt: DateTime(2026, 5, 14)),
        ],
      );

      await repo.refreshAll('USD');
      // Allow the DAO watch() to emit so the snapshot updates.
      await Future<void>.delayed(Duration.zero);

      // Forward rate present, scaled by 1e9.
      expect(repo.getRate('EUR', 'USD'), (1.08 * 1000000000).round());

      // Inverse not stored — UI never looks it up.
      expect(repo.getRate('USD', 'EUR'), isNull);
    });

    test('refreshAll rejects rate <= 0', () async {
      await seedAccount('EUR');
      when(() => mockService.fetchRates(any())).thenAnswer(
        (_) async => [
          (from: 'EUR', to: 'USD', rate: -1.0, fetchedAt: DateTime(2026, 5, 14)),
        ],
      );
      await repo.refreshAll('USD');
      await Future<void>.delayed(Duration.zero);
      expect(repo.getRate('EUR', 'USD'), isNull);
    });

    test('refreshAll rejects rate outside plausible range', () async {
      await seedAccount('EUR');
      // Above the 1e6 ceiling.
      when(() => mockService.fetchRates(any())).thenAnswer(
        (_) async => [
          (from: 'EUR', to: 'USD', rate: 2000000.0, fetchedAt: DateTime(2026, 5, 14)),
        ],
      );
      await repo.refreshAll('USD');
      await Future<void>.delayed(Duration.zero);
      expect(repo.getRate('EUR', 'USD'), isNull);

      // Below the 1e-6 floor.
      when(() => mockService.fetchRates(any())).thenAnswer(
        (_) async => [
          (from: 'EUR', to: 'USD', rate: 1e-9, fetchedAt: DateTime(2026, 5, 14)),
        ],
      );
      await repo.refreshAll('USD');
      await Future<void>.delayed(Duration.zero);
      expect(repo.getRate('EUR', 'USD'), isNull);
    });

    test('defaultCurrency change triggers refreshAll', () async {
      await seedAccount('EUR');
      when(() => mockService.fetchRates(any())).thenAnswer(
        (_) async => [
          (from: 'EUR', to: 'USD', rate: 1.08, fetchedAt: DateTime(2026, 5, 14)),
        ],
      );

      defaultCurrencyController.add('USD');
      await Future<void>.delayed(const Duration(milliseconds: 50));

      verify(() => mockService.fetchRates(any())).called(greaterThanOrEqualTo(1));
    });

    test('single-flight: concurrent refreshAll calls coalesce to one fetch',
        () async {
      await seedAccount('EUR');
      final completer = Completer<List<({String from, String to, double rate, DateTime fetchedAt})>>();
      when(() => mockService.fetchRates(any()))
          .thenAnswer((_) => completer.future);

      // Fire three refreshAll calls in parallel for the same default currency.
      final f1 = repo.refreshAll('USD');
      final f2 = repo.refreshAll('USD');
      final f3 = repo.refreshAll('USD');

      // Allow microtasks to run.
      await Future<void>.delayed(Duration.zero);

      completer.complete([
        (from: 'EUR', to: 'USD', rate: 1.08, fetchedAt: DateTime(2026, 5, 14)),
      ]);
      await Future.wait([f1, f2, f3]);

      // The mock was only invoked once thanks to single-flight.
      verify(() => mockService.fetchRates(any())).called(1);
    });

    test('fetchRate handles service errors silently (no rethrow)', () async {
      when(() => mockService.fetchRates(any())).thenThrow(
        Exception('network error'),
      );
      await repo.fetchRate('EUR', 'USD'); // must not throw
      expect(repo.getRate('EUR', 'USD'), isNull);
    });
  });
}
```

> **Schema note:** if `CurrenciesCompanion.insert` requires additional non-null fields (e.g. `isToken`), update the seed to pass them. Inspect `lib/data/database/tables/currencies_table.dart` once before writing the test. Same caveat for `AccountTypesCompanion.insert` and `AccountsCompanion.insert`.

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
    Map<String, int>? rates,
  }) {
    return ProviderScope(
      overrides: [
        exchangeRatesProvider.overrideWith(
          (_) => Stream.value(rates ?? const <String, int>{}),
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
        todayTotals: {'EUR': (expense: 500, income: 0)},
        monthNet: {'EUR': -2000},
        defaultCurrency: 'USD',
        rates: {'EUR→USD': (1.08 * 1000000000).round()},
      ));
      expect(find.textContaining(r'$'), findsWidgets);
    });

    testWidgets('falls back to per-currency when rate missing', (tester) async {
      await tester.pumpWidget(buildStrip(
        todayTotals: {'EUR': (expense: 500, income: 0)},
        monthNet: {'EUR': -2000},
        defaultCurrency: 'USD',
        rates: const {},
      ));
      expect(find.textContaining('€'), findsWidgets);
    });

    testWidgets('mixed: unified group + fallback group with separator',
        (tester) async {
      await tester.pumpWidget(buildStrip(
        todayTotals: {
          'EUR': (expense: 500, income: 0),
          'JPY': (expense: 1000, income: 0),
        },
        monthNet: {'EUR': -2000, 'JPY': -1000},
        defaultCurrency: 'USD',
        rates: {'EUR→USD': (1.08 * 1000000000).round()},
      ));
      // EUR was convertible → unified USD group.
      expect(find.textContaining(r'$'), findsWidgets);
      // JPY had no rate → shows as fallback.
      expect(find.textContaining('¥').evaluate().isNotEmpty ||
             find.textContaining('JPY').evaluate().isNotEmpty,
          isTrue);
    });

    testWidgets('same-currency totals pass through unchanged', (tester) async {
      await tester.pumpWidget(buildStrip(
        todayTotals: {'USD': (expense: 1000, income: 500)},
        monthNet: {'USD': -500},
        defaultCurrency: 'USD',
      ));
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
    Map<String, int>? rates,
  }) {
    return ProviderScope(
      overrides: [
        exchangeRatesProvider.overrideWith(
          (_) => Stream.value(rates ?? const <String, int>{}),
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
        rates: {'EUR→USD': (1.08 * 1000000000).round()},
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
    Map<String, int>? rates,
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
          (_) => Stream.value(rates ?? const <String, int>{}),
        ),
        defaultCurrencyProvider.overrideWith(
          (_) => Stream.value(defaultCurrency),
        ),
        initialDefaultCurrencyProvider.overrideWithValue(defaultCurrency),
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
        balancesByCurrency: {'USD': 34000, 'EUR': 125000},
        rates: {'EUR→USD': (1.08 * 1000000000).round()},
      ));
      expect(find.textContaining('≈'), findsOneWidget);
      expect(find.textContaining('total'), findsOneWidget);
    });

    testWidgets('hides converted total for single-currency account',
        (tester) async {
      await tester.pumpWidget(buildTile(balancesByCurrency: {'USD': 34000}));
      expect(find.textContaining('≈'), findsNothing);
    });

    testWidgets('hides converted total when any rate missing',
        (tester) async {
      await tester.pumpWidget(buildTile(
        balancesByCurrency: {'USD': 34000, 'EUR': 125000},
        rates: const {},
      ));
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

import 'package:flutter_test/flutter_test.dart';
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
    test('repository snapshot updates after API fetch (forward only)', () async {
      await runTestSeed(db);
      final repo = ExchangeRateRepository(
        db, mockService, defaultCurrencyController.stream,
      );
      when(() => mockService.fetchRates(any())).thenAnswer(
        (_) async => [
          (from: 'EUR', to: 'USD', rate: 1.08, fetchedAt: DateTime(2026, 5, 14)),
        ],
      );
      await repo.refreshAll('USD');
      await Future<void>.delayed(Duration.zero);

      expect(repo.getRate('EUR', 'USD'), (1.08 * 1000000000).round());
      // Inverse is NOT stored — UI never looks it up.
      expect(repo.getRate('USD', 'EUR'), isNull);

      repo.dispose();
    });

    test('default currency change triggers re-fetch', () async {
      await runTestSeed(db);
      final repo = ExchangeRateRepository(
        db, mockService, defaultCurrencyController.stream,
      );
      when(() => mockService.fetchRates(any())).thenAnswer(
        (_) async => [
          (from: 'EUR', to: 'GBP', rate: 0.86, fetchedAt: DateTime(2026, 5, 14)),
        ],
      );
      defaultCurrencyController.add('GBP');
      await Future<void>.delayed(const Duration(milliseconds: 200));

      verify(() => mockService.fetchRates(any())).called(greaterThanOrEqualTo(1));
      repo.dispose();
    });

    test('cached rates persist across repository instances', () async {
      await runTestSeed(db);

      final repo1 = ExchangeRateRepository(
        db, mockService, defaultCurrencyController.stream,
      );
      when(() => mockService.fetchRates(any())).thenAnswer(
        (_) async => [
          (from: 'EUR', to: 'USD', rate: 1.08, fetchedAt: DateTime(2026, 5, 14)),
        ],
      );
      await repo1.refreshAll('USD');
      await Future<void>.delayed(Duration.zero);
      repo1.dispose();

      // New instance reads the same DAO; first emission populates snapshot.
      final repo2 = ExchangeRateRepository(
        db, mockService, defaultCurrencyController.stream,
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(repo2.getRate('EUR', 'USD'), (1.08 * 1000000000).round());
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

### Task 25: Run full test suite, verify manually, and fix regressions

- [ ] **Step 1: Format all changed files**

Run: `dart format .`

- [ ] **Step 2: Run the full analyzer**

Run: `flutter analyze`
Expected: No errors. In particular, watch for `scoped_providers_should_specify_dependencies` from riverpod_lint on any @Riverpod whose `dependencies:` list does not match the actual `ref.read`/`ref.watch` graph (Task 13 updated `TransactionFormController`; verify no other consumer was missed).

- [ ] **Step 3: Run import_lint**

Run: `dart run import_lint`
Expected: No violations. The key risk is the relocation of `defaultCurrencyProvider` from `features/settings/` to `app/providers/` (Task 9) — if any feature module imports the old location, it now points nowhere.

- [ ] **Step 4: Run the full test suite**

Run: `flutter test`
Expected: All tests pass. Key existing tests to spot-check after the refactor:
- `test/unit/app/bootstrap_order_test.dart` — should pass unchanged (ProviderScope preserved).
- `test/integration/recurring_transaction_test.dart` — should pass unchanged.
- `test/unit/repositories/migration_test.dart` — must pass at schemaVersion 5.
- `test/widget/features/home/summary_strip_test.dart` — migrated per Task 15 Step 7.

- [ ] **Step 5: Manual verification (running app)**

Start the app on a device or simulator and verify:
  1. **Cold start, default currency = USD, no DB:** SummaryStrip renders without crashing; no `$` flicker before locale-driven default appears.
  2. **Cold start, default currency = HKD (override via Settings before relaunch):** UI renders HKD on first frame — no USD intermediate.
  3. **Network unavailable (airplane mode), cache present:** SummaryStrip + TransactionTile + AccountTile show cached converted totals; no error banner.
  4. **Network unavailable, no cache:** UI falls back to per-currency display; no crash.
  5. **2× text scale:** open the OS accessibility settings, set text scale to 2.0, and confirm TransactionTile rows do not overflow ListTile bounds and that the SummaryStrip remains scrollable.
  6. **Sanitized logs:** filter `flutter logs` for the literal string `→` (the previous failure log contained currency arrows). It must not appear. The repository's only log lines should match `ExchangeRateRepository.refreshAll failed (<type>)`, `ExchangeRateRepository.fetchRate failed (<type>)`, `ExchangeRateRepository: DAO stream error (<type>)`, or `ExchangeRateRepository: rate outside plausible range`.

- [ ] **Step 6: Fix any failures**

If any tests fail, diagnose and fix. Common issues:
- Missing `defaultCurrency` parameter at call sites
- Missing l10n keys (run `flutter gen-l10n` again)
- Import rule violations (check `import_analysis_options.yaml`)
- Old `({int numerator, int denominator})` rate type still referenced somewhere

- [ ] **Step 7: Final commit (if fixes needed)**

```bash
git add -A
git commit -m "fix: address test failures from multi-currency conversion"
```

---

## Operational Notes

These notes are not part of any single task but should be considered during implementation and code review.

### Persistence rationale

Rates are persisted (Drift table) rather than kept in-memory because:
1. **Cold-start UX:** on app launch the UI must display approximate converted totals before the network call returns. An in-memory cache would force a per-launch loading state.
2. **Offline survival:** brief network outages should not eliminate converted totals.
3. **Sharing across processes:** Drift's `.watch()` propagates changes across the app's provider graph for free; an in-memory map would require manual fanout.

Rates carry `fetched_at` but the plan does not enforce a TTL — the `≈` glyph and the absence of timestamps in the UI signal to users that values are advisory. TTL-based eviction is deferred to a later phase.

### First-launch and currency-change flows

| Scenario                                   | Behavior                                                                                                                                                               |
|--------------------------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Brand-new install, empty DB                | `distinctCurrenciesAcrossAllTables()` returns empty → `refreshAll` is a no-op. SummaryStrip shows the empty placeholder.                                               |
| First non-default-currency account created | `AccountFormActions.save()` queues a debounced on-demand fetch (Task 12). UI shows per-currency render until the debounce window fires; then ≈ converted line appears. |
| First non-default-currency transaction saved | `TransactionFormController.save()` starts an immediate on-demand fetch (Task 13). UI can continue to render the original currency right away; converted displays update when the fetched rate lands. |
| Default currency changed in Settings       | `defaultCurrencyProvider` stream emits → repo's `_currencySub` triggers `refreshAll` (single-flight). UI shows per-currency render until the new rates land.           |
| Network failure after some rates cached    | Cached rates remain in the snapshot; UI renders ≈ totals from cache. No error indicator.                                                                               |
| Network failure with no rates cached       | `_snapshot` stays empty; UI renders the per-currency fallback path (no ≈ totals).                                                                                      |

### TLS / certificate pinning

The Cloudflare Worker endpoint relies on the OS-managed CA trust store. **This is a deliberate decision** — the exchange rates are advisory and displayed with an `≈` qualifier; they are not used in financial settlement. A MITM attacker who replaced the response would corrupt the *displayed* total but not any persisted financial record. If the threat model later expands to include settlement-affecting use of the API response, add certificate pinning at that point. Document this acceptance in the API service file's class comment.

### Cloudflare Worker access control

The endpoint URL is hardcoded and publicly reachable. The Worker is expected to enforce:
- Reasonable Cloudflare-layer rate limiting per IP.
- Read-only behavior (no PII, no per-user data).

If the upstream rate provider that backs the Worker is a paid service, the Worker should add a bearer token (rotated server-side) and the client should be updated to send it. The plan does not ship that mechanism — it documents the gap as accepted for MVP because (a) the Worker only proxies public market data, (b) there is no per-user differentiation, and (c) the data is treated as advisory.

---

## Execution Summary

| Chunk                     | Tasks | Files Created                                                       | Files Modified                                                                |
|---------------------------|-------|---------------------------------------------------------------------|-------------------------------------------------------------------------------|
| 1: Data Foundation        | 1–7   | 3 (table, DAO, service) + 1 (converter) + 1 (v5 schema dump)        | 2 (pubspec, app_database) + 2 (test harness)                                  |
| 2: Repository + Providers | 8–10  | 1 (repository) + 1 (default_currency_provider)                      | 1 (repository_providers)                                                      |
| 3: Bootstrap + Fetch      | 11–13 | 0                                                                   | 4 (bootstrap, app, accounts_providers, tx_form_controller)                    |
| 4: Localization           | 14    | 0                                                                   | 3 (ARB files)                                                                 |
| 5: UI SummaryStrip        | 15    | 0                                                                   | 2 (summary_strip, home_screen call site) + 1 (summary_strip_test migration)   |
| 6: UI TransactionTile     | 16    | 0                                                                   | 2 (transaction_tile, home_screen call site)                                   |
| 7: UI AccountTile         | 17    | 0                                                                   | 1 (account_tile — already ConsumerWidget; no widget-base change)              |
| 8: Tests                  | 18–25 | 6 (test files)                                                      | 0                                                                             |
