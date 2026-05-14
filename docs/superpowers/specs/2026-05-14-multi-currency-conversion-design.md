# Extended Multi-Currency Conversion — Design Spec

**Date:** 2026-05-14  
**Status:** Draft  
**PRD reference:** `PRD.md` § Phased Roadmap — Phase 2: "Extended multi-currency — fetch currency prices and auto-convert balances, summaries, and charts to the user's default currency"

---

## Summary

Fetch live exchange rates from a hosted API on app startup, cache them in-memory and in the local DB, and display auto-converted amounts in the user's default currency across all money-display surfaces. Conversion is purely additive display data — original transaction amounts and account balances are never modified.

---

## Goals

- Fetch exchange rates for all non-default currencies in a single API call on startup.
- Persist rates to the local DB for instant display on next launch (in-memory + DB cache).
- Display converted amounts in the user's default currency on: SummaryStrip, TransactionTile, AccountTile, CategorySearchTile.
- SummaryStrip simplifies from per-currency groups to a single unified total in the default currency.
- Fetch on demand when a new currency appears mid-session (e.g., user creates an account in a new currency).
- Rates never expire — cached rates are always usable, even if days or weeks old.

## Non-Goals

- Cross-rate chaining — the API supports arbitrary pairs directly.
- User-facing rate staleness indicators or expiration warnings.
- Persisting converted amounts into transaction or account rows.
- Charts and analysis breakdowns in default currency (future work).

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
| Service | `data/services/exchange_rate_service.dart` | HTTP client, calls the conversion API |
| Repository | `data/repositories/exchange_rate_repository.dart` | Orchestrates DB + service + in-memory cache |
| Converter | `core/utils/currency_converter.dart` | Pure function for minor-unit conversion |
| Providers | `app/providers/repository_providers.dart` (extend) | `exchangeRateRepositoryProvider` |

### Data Flow

```
Bootstrap
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
  → calls CurrencyConverter.convertMinorUnits() with cached rate
  → formats via existing MoneyFormatter
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

Injects `Dio` (same pattern as `AnkrService`). Single method:

```dart
Future<List<ExchangeRate>> fetchRates(List<({String from, String to})> pairs)
```

- Builds ticker string: `pairs.map((p) => '${p.from.toLowerCase()}${p.to.toLowerCase()}').join(',')`
- GETs the endpoint with `?tickers={tickers}`
- Parses response array into `List<ExchangeRate>`
- Throws on network errors (caught by repository)

---

## Repository — `data/repositories/exchange_rate_repository.dart`

### Abstract Contract

```dart
abstract class ExchangeRateRepository {
  Future<void> init(String defaultCurrency);
  Future<void> fetchRate(String from, String defaultCurrency);
  double? getRate(String from, String to);
  Stream<Map<(String, String), double>> watchRates();
}
```

### In-Memory Cache

`Map<(String, String), double> _cache` — keyed by `(baseCurrency, quoteCurrency)`.

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

### Bootstrap — `lib/app/bootstrap.dart`

```dart
final exchangeRateRepo = DriftExchangeRateRepository(db, exchangeRateService);
await exchangeRateRepo.init(defaultCurrency);

// Inject as override in ProviderScope
exchangeRateRepositoryProvider.overrideWithValue(exchangeRateRepo),
```

### Repository Provider — `lib/app/providers/repository_providers.dart`

```dart
final exchangeRateRepositoryProvider = Provider<ExchangeRateRepository>((ref) {
  throw UnimplementedError('Must be overridden in bootstrap');
});
```

### Feature Provider — `lib/features/home/home_providers.dart`

```dart
final exchangeRatesProvider = StreamProvider<Map<(String, String), double>>((ref) {
  return ref.watch(exchangeRateRepositoryProvider).watchRates();
});
```

### On-Demand Fetch — in relevant controllers

After saving a new account or transaction in a non-default currency:

```dart
final repo = ref.read(exchangeRateRepositoryProvider);
final defaultCurrency = ref.read(defaultCurrencyProvider);
if (newCurrency != defaultCurrency) {
  unawaited(repo.fetchRate(newCurrency, defaultCurrency));
}
```

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

### CategorySearchTile — `lib/features/analysis/search/widgets/category_search_tile.dart`

Same pattern as TransactionTile — original primary, converted secondary with `≈` prefix.

### "No Rate Available" Fallback

When `getRate()` returns null for a currency pair:
- SummaryStrip: fall back to per-currency MVP display
- TransactionTile / AccountTile / CategorySearchTile: show "No rate available" in muted text below the original amount

---

## Error Handling

| Scenario | Behavior |
|----------|----------|
| API unreachable on startup | Silent catch, use cached rates from DB |
| Partial API response | Upsert available pairs, skip missing |
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
| `exchange_rate_repository_test.dart` | `test/unit/repositories/` | DB load on init, cache population, upsert, inverse rate computation, on-demand fetch, stream emissions. In-memory Drift DB + mock service. |
| `currency_converter_test.dart` | `test/unit/utils/` | Minor-unit conversion with different decimal pairs (USD→USD, JPY→USD, EUR→CNY), null when rate missing, rounding. |

### Widget Tests

| Test | File | Coverage |
|------|------|----------|
| `summary_strip_conversion_test.dart` | `test/widget/features/home/` | Unified total display, multi-currency aggregation, "No rate available" fallback to MVP behavior. |
| `transaction_tile_conversion_test.dart` | `test/widget/features/home/` | Secondary converted line appears, hidden when rate missing. |
| `account_tile_conversion_test.dart` | `test/widget/features/accounts/` | Converted total line below per-currency balances. |

### Integration Test

| Test | File | Coverage |
|------|------|----------|
| `currency_conversion_flow_test.dart` | `test/integration/` | Bootstrap → rates loaded from DB → API called → UI shows converted amounts → add new currency → on-demand fetch → UI updates. |

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

---

## Migration Strategy

Drift schema bump to `schemaVersion = 5`. `onUpgrade` creates the `exchange_rates` table:

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

No data migration needed — new table, no existing data affected.
