# Extended Multi-Currency Conversion — Design Spec

**Date:** 2026-05-14  
**Status:** Draft  
**PRD reference:** `PRD.md` § Phased Roadmap — Phase 2: "Extended multi-currency — fetch currency prices and auto-convert balances, summaries, and charts to the user's default currency"

---

## Summary

Fetch live exchange rates from a hosted API on app startup, cache them in-memory and in the local DB, and display auto-converted amounts in the user's default currency across all money-display surfaces. Conversion is purely additive display data — original transaction amounts and account balances are never modified.

---

## Prerequisites

- `dio` package must be added to `pubspec.yaml` (already listed in PRD as a Phase 2 dependency).

---

## Goals

- Fetch exchange rates for all non-default currencies in a single API call on startup.
- Persist rates to the local DB for instant display on next launch (in-memory + DB cache).
- Display converted amounts in the user's default currency on: SummaryStrip, TransactionTile, AccountTile.
- SummaryStrip simplifies from per-currency groups to a single unified total in the default currency.
- Fetch on demand when a new currency appears mid-session (e.g., user creates an account in a new currency).
- Rates never expire — cached rates are always usable, even if days or weeks old.

## Non-Goals

- Cross-rate chaining — the API supports arbitrary pairs directly.
- User-facing rate staleness indicators or expiration warnings.
- Persisting converted amounts into transaction or account rows.
- Analysis surfaces (CategorySearchTile, charts) in default currency — deferred to follow-up work. These require changes to `analysis_state.dart` / `analysis_controller.dart` to carry per-transaction currency data through to the search result model.

---

## API

**Endpoint:** `https://ledgerly-api.bigto-fintech.workers.dev/api/conversion?tickers={tickers}`

**Ticker format:** `{fromCurrency}{toCurrency}` in lowercase, comma-separated. Example: `hkdusd,eurusd,cnyusd`.

**Auth:** None required (for now).

**Response:**
```json
[
  {
    "rate": 0.12775442,
    "from": "HKD",
    "to": "USD",
    "fetched_at": "2026-05-14T06:35:14.459Z",
    "age_seconds": 39202,
    "fetch_from": "cache"
  }
]
```

The API accepts arbitrary pairs (e.g., `cnyusd`, `usdcny`) — no cross-rate chaining needed.

---

## Architecture

### Components

| Layer | File | Purpose |
|-------|------|---------|
| Model | `data/models/exchange_rate.dart` | Freezed domain model |
| Table | `data/database/tables/exchange_rates_table.dart` | Drift table with REAL rate column |
| DAO | `data/database/daos/exchange_rate_dao.dart` | `upsertAll()`, `findByPair()`, `findAll()` |
| Service | `data/services/exchange_rate_service.dart` | HTTP client via Dio, calls the conversion API |
| Repository | `data/repositories/exchange_rate_repository.dart` | Orchestrates DB + service + in-memory cache |
| Converter | `core/utils/currency_converter.dart` | Pure function for minor-unit conversion |
| Providers | `app/providers/repository_providers.dart` (extend) | `exchangeRateRepositoryProvider`, `exchangeRatesProvider` |

### Data Flow

```
Bootstrap (onFirstFrame, non-blocking)
  → ExchangeRateRepository.init(defaultCurrency)
    → load all rates from DB into in-memory cache
    → collect distinct currencies from accounts + transactions
    → build tickers: "{from}{default}" for each non-default currency
    → ExchangeRateService.fetchRates(tickers)
    → upsert results into DB + update in-memory cache + emit stream

New currency mid-session
  → Repository.fetchRate(from, defaultCurrency)
    → single-pair API call → DB + memory update + emit stream

UI (any surface)
  → subscribes to exchangeRatesProvider (Stream)
  → repo.getRate(from, to) → returns cached rate (or null)
  → CurrencyConverter.convertMinorUnits(amount, from, to, rate, fromDecimals, toDecimals)
  → MoneyFormatter.format(convertedMinorUnits, toCurrency)
```

---

## Data Model

### Freezed Model — `data/models/exchange_rate.dart`

```dart
@freezed
class ExchangeRate with _$ExchangeRate {
  const factory ExchangeRate({
    required String baseCurrency,
    required String quoteCurrency,
    required double rate,
    required DateTime fetchedAt,
  }) = _ExchangeRate;
}
```

### Drift Table — `data/database/tables/exchange_rates_table.dart`

| Column | Type | Constraints |
|--------|------|-------------|
| id | INTEGER | PRIMARY KEY AUTO |
| base_currency | TEXT | NOT NULL REFERENCES currencies(code) |
| quote_currency | TEXT | NOT NULL REFERENCES currencies(code) |
| rate | REAL | NOT NULL |
| fetched_at | DATETIME | NOT NULL |

Unique index on `(base_currency, quote_currency)` — one rate per pair. Upsert replaces on conflict.

**Design decision:** `rate` is stored as `REAL` (double) rather than the PRD's original integer-fraction design (`rate_numerator / rate_denominator`). Rationale: conversion is display-only, the API returns doubles, and floating-point precision is more than adequate for formatted output. The PRD should be updated to reflect this change.

---

## API Integration — `data/services/exchange_rate_service.dart`

Injects `Dio` via constructor. Single method:

```dart
Future<List<ExchangeRate>> fetchRates(List<({String from, String to})> pairs)
```

- Builds ticker string: `pairs.map((p) => '${p.from.toLowerCase()}${p.to.toLowerCase()}').join(',')`
- GETs the endpoint with `?tickers={tickers}`
- Parses response array into `List<ExchangeRate>`
- Throws on network or HTTP errors (`DioException` — caught by repository)

**Partial response handling:** The service returns only successfully parsed entries. The repository compares returned pairs against requested pairs to detect missing rates — missing pairs simply don't get updated in the cache or DB, preserving any existing cached rate.

---

## Repository — `data/repositories/exchange_rate_repository.dart`

### Abstract Contract

```dart
abstract class ExchangeRateRepository {
  Future<void> init(String defaultCurrency);
  Future<void> fetchRate(String from, String defaultCurrency);
  double? getRate(String from, String to);
  Stream<Map<String, double>> watchRates();
}
```

Rate map key format: `"FROM→TO"` (e.g., `"HKD→USD"`). This avoids Riverpod equality concerns with Dart record types.

### In-Memory Cache

`Map<String, double> _cache` — keyed by `"FROM→TO"` string.

**Inverse rates:** When the API returns `HKD→USD: 0.1277`, the repository also stores `USD→HKD: 1/0.1277 = 7.828`. This lets `getRate()` work for any direction without knowing which way the API returned.

**Same-currency:** `getRate("USD", "USD")` always returns `1.0` — no API call needed.

### Init Flow

1. `SELECT * FROM exchange_rates` → seed `_cache` with both directions
2. Collect distinct currencies: `{accounts.currency ∪ transactions.currency ∪ pending_transactions.currency} - {defaultCurrency}`
3. Build ticker pairs: `[(currency, defaultCurrency) for each currency]`
4. `service.fetchRates(pairs)` — catch errors silently
5. Upsert into DB + update `_cache` + emit on stream controller
6. If step 4 fails → app continues with cached rates from step 1

### On-Demand Fetch Flow

1. `service.fetchRates([(from, defaultCurrency)])` — catch errors silently
2. Upsert into DB + update `_cache` + emit on stream
3. If fails → no rate for this pair until next startup

---

## Conversion Logic — `core/utils/currency_converter.dart`

```dart
int? convertMinorUnits({
  required int amountMinorUnits,
  required String fromCurrency,
  required String toCurrency,
  required double rate,
  required int fromDecimals,
  required int toDecimals,
}) {
  final displayAmount = amountMinorUnits / pow(10, fromDecimals);
  final convertedDisplay = displayAmount * rate;
  return (convertedDisplay * pow(10, toDecimals)).round();
}
```

Decimal values come from existing `Currency.decimals` via `CurrencyRepository`. Formatting uses existing `MoneyFormatter.format(convertedMinorUnits, currency)`.

---

## Provider Wiring

All new providers follow the existing `@riverpod` annotation pattern with code generation (same as `repository_providers.dart:23-88`).

### Bootstrap — `lib/app/bootstrap.dart`

`init()` is called in `onFirstFrame` (non-blocking), same pattern as `RecurringGenerationUseCase`. It must not block `runApp`.

```dart
// In onFirstFrame callback:
final exchangeRateRepo = container.read(exchangeRateRepositoryProvider);
unawaited(exchangeRateRepo.init(defaultCurrency).catchError((_) {}));
```

The repository is constructed via its provider (auto-disposed by Riverpod) before `runApp`. The network fetch inside `init()` is deferred to `onFirstFrame`.

### Repository Provider — `lib/app/providers/repository_providers.dart`

```dart
@Riverpod(keepAlive: true, dependencies: [appDatabase, exchangeRateService])
ExchangeRateRepository exchangeRateRepository(ExchangeRateRepositoryRef ref) {
  return DriftExchangeRateRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(exchangeRateServiceProvider),
  );
}
```

### Exchange Rate Service Provider — `lib/app/providers/repository_providers.dart`

```dart
@Riverpod(keepAlive: true, dependencies: [])
ExchangeRateService exchangeRateService(ExchangeRateServiceRef ref) {
  return ExchangeRateService(Dio(BaseOptions(connectTimeout: Duration(seconds: 10))));
}
```

Adding this service import to `repository_providers.dart` requires verifying that `import_analysis_options.yaml` allows `data/services/` imports in `app/providers/`. If not, the service provider can be co-located with the service file.

### Exchange Rates Stream Provider — `lib/app/providers/repository_providers.dart`

```dart
@Riverpod(keepAlive: true, dependencies: [exchangeRateRepository])
Stream<Map<String, double>> exchangeRates(ExchangeRatesRef ref) {
  return ref.watch(exchangeRateRepositoryProvider).watchRates();
}
```

`watchRates()` uses a `StreamController` that emits the full current cache map on every mutation. New subscribers immediately receive the latest map (replay behavior) — the stream controller emits on listen via `onListen` or uses `addStream` with the current state.

Placed in `app/providers/` (not a feature slice) because it's consumed by multiple features (home, accounts).

### Default Currency Provider — `lib/features/settings/settings_providers.dart`

```dart
@Riverpod(keepAlive: true, dependencies: [userPreferencesRepository])
Stream<String> defaultCurrency(DefaultCurrencyRef ref) {
  return ref.watch(userPreferencesRepositoryProvider).watchDefaultCurrency();
}
```

`watchDefaultCurrency()` returns `Stream<String>` emitting the ISO code (e.g., `"USD"`). Defaults to `'USD'` when the preference hasn't been set yet (handled inside the repository).

### On-Demand Fetch — `AccountFormController` and `TransactionFormController`

After saving a new account or transaction in a non-default currency:

```dart
final repo = ref.read(exchangeRateRepositoryProvider);
final defaultCurrency = ref.read(defaultCurrencyProvider).valueOrNull ?? 'USD';
if (newCurrency != defaultCurrency) {
  unawaited(repo.fetchRate(newCurrency, defaultCurrency));
}
```

Controllers to modify:
- `lib/features/accounts/account_form_controller.dart` — after account creation when currency differs from default
- `lib/features/transactions/transaction_form_controller.dart` — after transaction save when currency differs from default

---

## UI Changes

### SummaryStrip — `lib/features/home/widgets/summary_strip.dart`

**Before:** Renders up to 2 currency groups with per-currency expense/income/month-net. Shows "Multiple currencies" note when >2 groups.

**After:** Single unified total in the default currency. All amounts aggregated through `CurrencyConverter.convertMinorUnits()`.

- `todayTotalsByCurrency` map iterated, each currency's amounts converted to default, then summed
- `monthNetByCurrency` same treatment
- Renders one group: `Default currency: −$X / +$Y` (today), `−$Z` (month)
- If no rates available yet → show original per-currency groups (MVP behavior) as fallback

### TransactionTile — `lib/features/home/widgets/transaction_tile.dart`

**After:** Original amount primary (unchanged). Converted amount as secondary line below:

```
−€5.40
≈ −$6.31
```

- Converted line hidden when rate is unavailable (returns null)
- Converted line uses muted color (`≈` prefix + smaller font)

### AccountTile — `lib/features/accounts/widgets/account_tile.dart`

**After:** Per-currency balances kept as-is. Converted total added below with dashed separator:

```
EUR: €1,250.00
USD: $340.00
─────────────
≈ $1,802.50 total
```

- Converted total sums all currency groups after conversion
- Hidden when no rates available
- Uses muted color + `≈` prefix

### "No Rate Available" Fallback

When `getRate()` returns null for a currency pair:
- SummaryStrip: fall back to per-currency MVP display
- TransactionTile / AccountTile: converted line is simply hidden (no "No rate available" text — avoids clutter)

---

## Error Handling

| Scenario | Behavior |
|----------|----------|
| API unreachable on startup | Silent catch (DioException), use cached rates from DB |
| HTTP 500 / 429 / non-200 | Treated same as network error — silent catch, use cached rates |
| Partial API response | Upsert available pairs; missing pairs retain any existing cached rate |
| Malformed response entry | Skip, log to debug console |
| First launch + no network | No conversions shown, app functions normally |
| Rate is 0 or negative | Skip, don't cache, keep existing cached rate |
| Currency not in `currencies` table | FK constraint rejects, skipped silently |

---

## Testing

### Unit Tests

| Test | File | Coverage |
|------|------|----------|
| `exchange_rate_service_test.dart` | `test/unit/services/` | HTTP call construction, ticker formatting, response parsing, error handling. Mock `Dio`. |
| `exchange_rate_repository_test.dart` | `test/unit/repositories/` | DB load on init, cache population, upsert, inverse rate computation, on-demand fetch, stream emissions, partial response handling. In-memory Drift DB + mock service. |
| `currency_converter_test.dart` | `test/unit/utils/` | Minor-unit conversion with different decimal pairs (USD→USD, JPY→USD, EUR→CNY), null when rate missing, rounding. |

### Widget Tests

| Test | File | Coverage |
|------|------|----------|
| `summary_strip_conversion_test.dart` | `test/widget/features/home/` | Unified total display, multi-currency aggregation, fallback to MVP behavior when no rates. |
| `transaction_tile_conversion_test.dart` | `test/widget/features/home/` | Secondary converted line appears, hidden when rate missing. |
| `account_tile_conversion_test.dart` | `test/widget/features/accounts/` | Converted total line below per-currency balances, hidden when no rates. |

### Integration Test

| Test | File | Coverage |
|------|------|----------|
| `currency_conversion_flow_test.dart` | `test/integration/` | Bootstrap → rates loaded from DB → API called → UI shows converted amounts → add new currency → on-demand fetch → UI updates. |

### Migration Test

Extend `test/unit/repositories/migration_test.dart` with v5 schema helpers:
- Generate v5 schema helper via `dart run drift_dev schema dump lib/data/database/app_database.dart drift_schemas/`
- Create `test/unit/repositories/_harness/generated/schema_v5.dart` from the dump
- Validate v4→v5 upgrade creates `exchange_rates` table and unique index
- Validate `PRAGMA foreign_keys` remains enabled after upgrade

### Mocking Strategy

- Service tests: mock `Dio`
- Repository tests: in-memory Drift DB + mock service
- Widget tests: override `exchangeRateRepositoryProvider` with a fake returning preset rates
- Integration test: mock service with fixture data, real in-memory Drift DB

---

## PRD Updates Required

The following sections of `PRD.md` should be updated to reflect this design:

1. **`exchange_rates` table schema** — change from integer-fraction (`rate_numerator` / `rate_denominator`) to `rate REAL NOT NULL`. Remove `rate_numerator`, `rate_denominator`, `provider` columns. Add unique index on `(base_currency, quote_currency)`.
2. **Folder structure** — update `exchange_rate_service.dart` and `exchange_rate_repository.dart` descriptions.
3. **Phase 2 roadmap** — mark this feature as "in progress" or "shipped".
4. **MVP Currency Policy** — update to note that Phase 2 conversion is now live.
5. **Dependencies table** — mark `dio` as in-use.

---

## Migration Strategy

Drift schema bump from `schemaVersion = 4` to `schemaVersion = 5`. `onUpgrade` creates the `exchange_rates` table for installs upgrading from v4:

```sql
CREATE TABLE exchange_rates (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  base_currency TEXT NOT NULL REFERENCES currencies(code),
  quote_currency TEXT NOT NULL REFERENCES currencies(code),
  rate REAL NOT NULL,
  fetched_at DATETIME NOT NULL
);
CREATE UNIQUE INDEX idx_exchange_rates_pair ON exchange_rates(base_currency, quote_currency);
```

Fresh installs at v5 get the table from the main schema creation. No data migration needed — new table, no existing data affected.
